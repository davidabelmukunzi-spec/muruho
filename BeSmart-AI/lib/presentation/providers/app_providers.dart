import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/database_service.dart';
import '../../data/services/inference_service.dart';
import '../../data/services/model_manager.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(sharedPreferencesProvider));
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository(ref.watch(databaseServiceProvider));
});

final modelManagerProvider = Provider<ModelManager>((ref) {
  final manager = ModelManager(ref.watch(settingsRepositoryProvider));
  ref.onDispose(manager.dispose);
  return manager;
});

final inferenceServiceProvider = Provider<InferenceService>((ref) {
  final service = InferenceService(
    ref.watch(settingsRepositoryProvider),
    ref.watch(modelManagerProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final conversationsProvider = FutureProvider((ref) async {
  return ref.watch(conversationRepositoryProvider).getAll();
});

final modelReadyProvider = Provider<bool>((ref) {
  return ref.watch(settingsRepositoryProvider).isModelReady;
});
