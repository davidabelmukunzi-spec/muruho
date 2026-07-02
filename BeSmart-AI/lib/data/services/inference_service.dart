import 'dart:async';

import 'package:llama_flutter_android/llama_flutter_android.dart' as llama;

import '../../core/constants/app_constants.dart';
import '../models/chat_message.dart' as app;
import '../models/model_state.dart';
import '../repositories/settings_repository.dart';
import 'model_manager.dart';

/// Encapsule llama_flutter_android pour le chargement et la génération streaming.
class InferenceService {
  InferenceService(this._settings, this._modelManager);

  final SettingsRepository _settings;
  final ModelManager _modelManager;

  LlamaController? _controller;
  StreamSubscription<String>? _generationSub;
  Timer? _inactivityTimer;

  final _loadStateController = StreamController<ModelLoadState>.broadcast();
  ModelLoadState _loadState = const ModelLoadState(phase: ModelLoadPhase.idle);

  Stream<ModelLoadState> get loadStateStream => _loadStateController.stream;
  ModelLoadState get loadState => _loadState;

  bool get isLoaded => _loadState.isLoaded;

  Future<void> loadModel() async {
    if (_loadState.isLoading || _loadState.isLoaded) return;

    _setLoadState(
      const ModelLoadState(
        phase: ModelLoadPhase.checking,
        message: 'Préparation du modèle…',
      ),
    );

    final modelPath = await _modelManager.getDownloadedModelPath();
    if (modelPath == null) {
      _setLoadState(
        const ModelLoadState(
          phase: ModelLoadPhase.failed,
          error: 'Aucun modèle trouvé. Téléchargez-le d\'abord.',
        ),
      );
      return;
    }

    _setLoadState(
      const ModelLoadState(
        phase: ModelLoadPhase.loading,
        message: 'Chargement du modèle en mémoire…',
      ),
    );

    try {
      _controller?.dispose();
      _controller = LlamaController();

      final gpu = await _controller!.detectGpu();
      final freeRamMb = gpu.freeRamBytes ~/ (1024 * 1024);

      await _controller!.loadModel(
        modelPath: modelPath,
        threads: 4,
        contextSize: AppConstants.defaultContextSize,
        gpuLayers: gpu.recommendedGpuLayers,
      );

      _resetInactivityTimer();

      _setLoadState(
        ModelLoadState(
          phase: ModelLoadPhase.loaded,
          message: 'Modèle chargé.',
          modelId: _modelManager.activeDefinition.id,
          freeRamMb: freeRamMb,
        ),
      );
    } catch (e) {
      _setLoadState(
        const ModelLoadState(
          phase: ModelLoadPhase.failed,
          error: 'Le modèle n\'a pas pu être chargé. Réessayer ?',
        ),
      );
      rethrow;
    }
  }

  Future<void> unloadModel() async {
    if (_loadState.phase == ModelLoadPhase.unloading) return;

    _setLoadState(
      const ModelLoadState(
        phase: ModelLoadPhase.unloading,
        message: 'Libération de la mémoire…',
      ),
    );

    await _generationSub?.cancel();
    _generationSub = null;
    await _controller?.stop();
    await _controller?.dispose();
    _controller = null;
    _inactivityTimer?.cancel();

    _setLoadState(const ModelLoadState(phase: ModelLoadPhase.idle));
  }

  Stream<String> generateResponse({
    required List<app.ChatMessage> history,
  }) async* {
    if (_controller == null || !_loadState.isLoaded) {
      await loadModel();
    }

    if (_controller == null || !_loadState.isLoaded) {
      throw InferenceException(
        _loadState.error ?? 'Le modèle n\'est pas disponible.',
      );
    }

    _resetInactivityTimer();

    final messages = [
      llama.ChatMessage(
        role: 'system',
        content: _settings.systemPrompt,
      ),
      ...history
          .where((m) => m.role != app.MessageRole.system)
          .map(
            (m) => llama.ChatMessage(
              role: m.isUser ? 'user' : 'assistant',
              content: m.content,
            ),
          ),
    ];

    final stream = _controller!.generateChat(
      messages: messages,
      template: _modelManager.activeDefinition.chatTemplate,
      temperature: _settings.temperature,
      maxTokens: _settings.maxTokens,
    );

    await for (final token in stream) {
      _resetInactivityTimer();
      yield token;
    }
  }

  Future<void> stopGeneration() async {
    await _generationSub?.cancel();
    await _controller?.stop();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      Duration(minutes: AppConstants.modelInactivityUnloadMinutes),
      unloadModel,
    );
  }

  void _setLoadState(ModelLoadState state) {
    _loadState = state;
    if (!_loadStateController.isClosed) {
      _loadStateController.add(state);
    }
  }

  void dispose() {
    _inactivityTimer?.cancel();
    _generationSub?.cancel();
    _controller?.dispose();
    _loadStateController.close();
  }
}

class InferenceException implements Exception {
  InferenceException(this.message);
  final String message;

  @override
  String toString() => message;
}
