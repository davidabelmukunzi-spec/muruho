import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/model_manager.dart';
import '../providers/app_providers.dart';
import 'home/conversations_screen.dart';
import 'onboarding/download_screen.dart';

class SplashRouter extends ConsumerStatefulWidget {
  const SplashRouter({super.key});

  @override
  ConsumerState<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends ConsumerState<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final modelManager = ref.read(modelManagerProvider);
    await modelManager.initialize();

    if (!mounted) return;

    final settings = ref.read(settingsRepositoryProvider);
    final hasFile = await modelManager.getDownloadedModelPath() != null;

    if (!settings.isModelReady && !hasFile) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DownloadScreen()),
      );
      return;
    }

    if (hasFile && !settings.isModelReady) {
      await settings.setModelReady(true);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ConversationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 48),
            SizedBox(height: 16),
            Text('BeSmart AI'),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
