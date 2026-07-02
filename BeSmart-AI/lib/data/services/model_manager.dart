import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/model_config.dart';
import '../models/model_state.dart';
import '../repositories/settings_repository.dart';

/// Gère le téléchargement, la vérification et le stockage du modèle GGUF.
///
/// Un seul répertoire de stockage est résolu au démarrage via [initialize].
class ModelManager {
  ModelManager(this._settings);

  final SettingsRepository _settings;
  final _progressController =
      StreamController<ModelDownloadProgress>.broadcast();

  Directory? _modelsDir;
  ModelDefinition? _activeDefinition;

  Stream<ModelDownloadProgress> get progressStream =>
      _progressController.stream;

  ModelDefinition get activeDefinition =>
      _activeDefinition ?? ModelConfig.primary;

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _modelsDir = Directory(p.join(appDir.path, 'models'));
    if (!await _modelsDir!.exists()) {
      await _modelsDir!.create(recursive: true);
    }

    final savedId = _settings.activeModelId;
    if (savedId != null) {
      _activeDefinition = ModelConfig.all.firstWhere(
        (m) => m.id == savedId,
        orElse: () => ModelConfig.primary,
      );
    }
  }

  Future<String> getModelPath(ModelDefinition definition) async {
    await initialize();
    return p.join(_modelsDir!.path, definition.fileName);
  }

  Future<bool> isModelDownloaded(ModelDefinition definition) async {
    final path = await getModelPath(definition);
    final file = File(path);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > definition.expectedSizeBytes * 0.95;
  }

  Future<String?> getDownloadedModelPath() async {
    for (final definition in ModelConfig.all) {
      if (await isModelDownloaded(definition)) {
        _activeDefinition = definition;
        return getModelPath(definition);
      }
    }
    return null;
  }

  Future<void> downloadModel({
    ModelDefinition? definition,
    void Function(ModelDownloadProgress)? onProgress,
  }) async {
    final model = definition ?? ModelConfig.primary;
    _activeDefinition = model;
    await initialize();

    final targetPath = await getModelPath(model);
    final partialPath = '$targetPath.part';
    final targetFile = File(targetPath);
    final partialFile = File(partialPath);

    var received = 0;
    if (await partialFile.exists()) {
      received = await partialFile.length();
    }

    _emit(
      const ModelDownloadProgress(
        phase: ModelDownloadPhase.downloading,
        message: 'Le modèle est en cours de téléchargement.',
      ),
      onProgress,
    );

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 60),
        headers: received > 0 ? {'Range': 'bytes=$received-'} : null,
      ),
    );

    try {
      await _ensureFreeSpace(model.expectedSizeBytes);

      final response = await dio.get<ResponseBody>(
        model.downloadUrl,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && (status == 200 || status == 206),
        ),
      );

      final total = _parseContentLength(response.headers) ??
          model.expectedSizeBytes;
      final sink = partialFile.openWrite(mode: received > 0 ? FileMode.append : FileMode.write);

      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        _emit(
          ModelDownloadProgress(
            phase: ModelDownloadPhase.downloading,
            receivedBytes: received,
            totalBytes: total,
            message: 'Le modèle est en cours de téléchargement.',
          ),
          onProgress,
        );
      }

      await sink.flush();
      await sink.close();

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await partialFile.rename(targetPath);

      await _verifyModel(targetPath, model, onProgress);

      await _settings.setActiveModelId(model.id);
      await _settings.setModelReady(true);
      _emit(
        const ModelDownloadProgress(
          phase: ModelDownloadPhase.ready,
          message: 'Modèle prêt.',
        ),
        onProgress,
      );
    } on DioException catch (e) {
      await _cleanupPartial(partialFile);
      final message = _mapDownloadError(e);
      _emit(
        ModelDownloadProgress(
          phase: ModelDownloadPhase.failed,
          error: message,
        ),
        onProgress,
      );
      throw ModelManagerException(message);
    } on ModelManagerException catch (e) {
      await _cleanupPartial(partialFile);
      _emit(
        ModelDownloadProgress(
          phase: ModelDownloadPhase.failed,
          error: e.message,
        ),
        onProgress,
      );
      rethrow;
    } catch (e) {
      await _cleanupPartial(partialFile);
      const message = 'Le téléchargement a échoué. Réessayer ?';
      _emit(
        const ModelDownloadProgress(
          phase: ModelDownloadPhase.failed,
          error: message,
        ),
        onProgress,
      );
      throw ModelManagerException(message);
    }
  }

  Future<void> _verifyModel(
    String path,
    ModelDefinition model,
    void Function(ModelDownloadProgress)? onProgress,
  ) async {
    _emit(
      const ModelDownloadProgress(
        phase: ModelDownloadPhase.verifying,
        message: 'Vérification du fichier…',
      ),
      onProgress,
    );

    final file = File(path);
    final size = await file.length();
    if (size < model.expectedSizeBytes * 0.9) {
      await file.delete();
      throw const ModelManagerException(
        'Le fichier téléchargé semble incomplet. Réessayer ?',
      );
    }

    final hash = await _computeSha256(file);
    final expected = model.sha256.isNotEmpty
        ? model.sha256
        : _settings.storedSha256;

    if (expected != null && expected.isNotEmpty && hash != expected) {
      await file.delete();
      throw const ModelManagerException(
        'La vérification du fichier a échoué. Réessayer ?',
      );
    }

    await _settings.setStoredSha256(hash);
  }

  Future<String> _computeSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<void> _ensureFreeSpace(int requiredBytes) async {
    final dir = _modelsDir ?? await getApplicationDocumentsDirectory();
    if (!await dir.exists()) {
      throw const ModelManagerException('Espace de stockage insuffisant.');
    }
  }

  Future<void> _cleanupPartial(File partial) async {
    if (await partial.exists()) {
      await partial.delete();
    }
  }

  int? _parseContentLength(Headers headers) {
    final value = headers.value('content-length');
    if (value == null) return null;
    return int.tryParse(value);
  }

  String _mapDownloadError(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return 'Connexion impossible. Vérifiez votre réseau.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Le téléchargement a pris trop de temps. Réessayer ?';
    }
    return 'Le téléchargement a échoué. Réessayer ?';
  }

  void _emit(
    ModelDownloadProgress progress,
    void Function(ModelDownloadProgress)? onProgress,
  ) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
    onProgress?.call(progress);
  }

  void dispose() {
    _progressController.close();
  }
}

class ModelManagerException implements Exception {
  const ModelManagerException(this.message);
  final String message;

  @override
  String toString() => message;
}
