import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/chat_message.dart';
import '../../../data/models/model_state.dart';
import '../../providers/app_providers.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();

  List<ChatMessage> _messages = [];
  String _conversationTitle = 'Conversation';
  bool _isLoadingHistory = true;
  bool _isGenerating = false;
  String _streamingContent = '';
  String? _error;
  ModelLoadState _modelState = const ModelLoadState(phase: ModelLoadPhase.idle);

  StreamSubscription<String>? _generationSub;
  StreamSubscription<ModelLoadState>? _loadSub;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _prepareModel();
  }

  Future<void> _loadHistory() async {
    final repo = ref.read(conversationRepositoryProvider);
    final conversation = await repo.getById(widget.conversationId);
    final messages = await repo.getMessages(widget.conversationId);
    if (mounted) {
      setState(() {
        _conversationTitle = conversation?.title ?? 'Conversation';
        _messages = messages;
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _prepareModel() async {
    final inference = ref.read(inferenceServiceProvider);
    _loadSub = inference.loadStateStream.listen((state) {
      if (mounted) setState(() => _modelState = state);
    });

    try {
      await inference.loadModel();
    } catch (_) {
      // State is reflected via stream.
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    HapticFeedback.lightImpact();
    _inputController.clear();
    setState(() {
      _error = null;
      _isGenerating = true;
      _streamingContent = '';
    });

    final repo = ref.read(conversationRepositoryProvider);
    final userMessage = await repo.addMessage(
      conversationId: widget.conversationId,
      role: MessageRole.user,
      content: text,
    );

    setState(() => _messages = [..._messages, userMessage]);
    _scrollToBottom();

    final assistantMessage = await repo.addMessage(
      conversationId: widget.conversationId,
      role: MessageRole.assistant,
      content: '',
    );

    setState(() => _messages = [..._messages, assistantMessage]);

    final inference = ref.read(inferenceServiceProvider);

    try {
      final buffer = StringBuffer();
      await for (final token in inference.generateResponse(
        history: _messages.where((m) => m.id != assistantMessage.id).toList(),
      )) {
        buffer.write(token);
        if (mounted) {
          setState(() => _streamingContent = buffer.toString());
          _scrollToBottom();
        }
      }

      final finalContent = buffer.toString().trim().isEmpty
          ? 'Je n\'ai pas pu générer de réponse.'
          : buffer.toString();

      await repo.updateMessageContent(assistantMessage.id, finalContent);
      if (mounted) {
        setState(() {
          _messages = _messages.map((m) {
            if (m.id == assistantMessage.id) {
              return m.copyWith(content: finalContent);
            }
            return m;
          }).toList();
          _streamingContent = '';
          _isGenerating = false;
        });
      }
    } catch (e) {
      await repo.updateMessageContent(
        assistantMessage.id,
        'Erreur lors de la génération.',
      );
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isGenerating = false;
          _streamingContent = '';
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _generationSub?.cancel();
    _loadSub?.cancel();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_conversationTitle),
        actions: [
          if (_modelState.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_modelState.phase == ModelLoadPhase.failed)
            MaterialBanner(
              content: Text(
                _modelState.error ?? 'Le modèle n\'a pas pu être chargé.',
              ),
              actions: [
                TextButton(
                  onPressed: _prepareModel,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              actions: [
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('OK'),
                ),
              ],
            ),
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length + (_isGenerating ? 0 : 0),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isStreaming = _isGenerating &&
                          message.isAssistant &&
                          message.content.isEmpty;

                      return MessageBubble(
                        message: isStreaming
                            ? message.copyWith(content: _streamingContent)
                            : message,
                        showTypingIndicator:
                            isStreaming && _streamingContent.isEmpty,
                      );
                    },
                  ),
          ),
          if (_isGenerating && _streamingContent.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TypingIndicator(),
              ),
            ),
          ChatInputBar(
            controller: _inputController,
            enabled: !_isGenerating && _modelState.isLoaded,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
