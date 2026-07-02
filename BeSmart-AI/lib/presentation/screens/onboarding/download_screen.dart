import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/model_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/models/model_state.dart';
import '../../../data/services/model_manager.dart';
import '../../providers/app_providers.dart';
import '../../widgets/progress_card.dart';
import '../home/conversations_screen.dart';

class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  ModelDownloadProgress _progress = const ModelDownloadProgress(
    phase: ModelDownloadPhase.idle,
  );
  bool _isWorking = false;
  ModelDefinition _selectedModel = ModelConfig.primary;

  Future<void> _startDownload() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    HapticFeedback.lightImpact();

    final manager = ref.read(modelManagerProvider);

    try {
      await manager.downloadModel(
        definition: _selectedModel,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ConversationsScreen()),
      );
    } on ModelManagerException catch (e) {
      if (mounted) {
        setState(() {
          _progress = _progress.copyWith(
            phase: ModelDownloadPhase.failed,
            error: e.message,
          );
          _isWorking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _progress = const ModelDownloadProgress(
            phase: ModelDownloadPhase.failed,
            error: 'Une erreur est survenue. Réessayer ?',
          );
          _isWorking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.shield_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Assistant 100 % local',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Téléchargez le modèle une fois, puis utilisez BeSmart AI '
                'sans connexion internet. Vos conversations restent sur '
                'votre appareil.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _ModelSelector(
                selected: _selectedModel,
                onChanged: _isWorking
                    ? null
                    : (model) => setState(() => _selectedModel = model),
              ),
              const SizedBox(height: 24),
              if (_progress.phase != ModelDownloadPhase.idle)
                ProgressCard(
                  title: _progress.message ?? 'Téléchargement',
                  fraction: _progress.fraction,
                  subtitle: _progress.totalBytes > 0
                      ? '${FormatUtils.formatBytes(_progress.receivedBytes)} / '
                          '${FormatUtils.formatBytes(_progress.totalBytes)}'
                      : null,
                  error: _progress.error,
                ),
              const Spacer(),
              FilledButton(
                onPressed: _isWorking ? null : _startDownload,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _progress.phase == ModelDownloadPhase.failed
                      ? 'Réessayer'
                      : 'Télécharger le modèle',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Environ ${FormatUtils.formatBytes(_selectedModel.expectedSizeBytes)} · '
                'RAM recommandée : ${_selectedModel.minRamMb ~/ 1024} Go',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelSelector extends StatelessWidget {
  const _ModelSelector({
    required this.selected,
    required this.onChanged,
  });

  final ModelDefinition selected;
  final ValueChanged<ModelDefinition>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ModelConfig.all.map((model) {
        final isSelected = model.id == selected.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onChanged == null ? null : () => onChanged!(model),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            FormatUtils.formatBytes(model.expectedSizeBytes),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
