import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/model_config.dart';
import '../../../core/utils/format_utils.dart';
import '../../providers/app_providers.dart';
import '../onboarding/download_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late double _temperature;
  late int _maxTokens;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider);
    _temperature = settings.temperature;
    _maxTokens = settings.maxTokens;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsRepositoryProvider);
    final modelManager = ref.watch(modelManagerProvider);
    final activeModel = modelManager.activeDefinition;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          const _SectionHeader('Modèle'),
          ListTile(
            title: const Text('Modèle actif'),
            subtitle: Text(activeModel.displayName),
          ),
          ListTile(
            title: const Text('Taille'),
            subtitle:
                Text(FormatUtils.formatBytes(activeModel.expectedSizeBytes)),
          ),
          ListTile(
            title: const Text('Retélécharger le modèle'),
            subtitle: const Text('Utile en cas de fichier corrompu'),
            trailing: const Icon(Icons.download_outlined),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DownloadScreen()),
              );
            },
          ),
          const Divider(),
          const _SectionHeader('Génération'),
          ListTile(
            title: Text('Température (${_temperature.toStringAsFixed(1)})'),
            subtitle: Slider(
              value: _temperature,
              min: 0,
              max: 1.5,
              divisions: 15,
              onChanged: (v) async {
                setState(() => _temperature = v);
                await settings.setTemperature(v);
              },
            ),
          ),
          ListTile(
            title: Text('Tokens max ($_maxTokens)'),
            subtitle: Slider(
              value: _maxTokens.toDouble(),
              min: 128,
              max: 1024,
              divisions: 14,
              onChanged: (v) async {
                setState(() => _maxTokens = v.round());
                await settings.setMaxTokens(v.round());
              },
            ),
          ),
          const Divider(),
          const _SectionHeader('À propos'),
          const ListTile(
            title: Text('BeSmart AI'),
            subtitle: Text(
              'Assistant IA 100 % local · Qwen2.5 · llama.cpp\n'
              'Aucune donnée n\'est envoyée vers le cloud.',
            ),
          ),
          ListTile(
            title: const Text('Modèles disponibles'),
            subtitle: Text(
              ModelConfig.all.map((m) => m.displayName).join('\n'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
