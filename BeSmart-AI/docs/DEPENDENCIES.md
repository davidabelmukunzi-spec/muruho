# Dépendances — BeSmart AI v1.0.0

| Package | Version | Rôle |
|---------|---------|------|
| flutter | SDK | Framework UI |
| cupertino_icons | ^1.0.8 | Icônes |
| flutter_riverpod | ^2.6.1 | State management |
| llama_flutter_android | ^0.2.0 | Inférence llama.cpp (Android) |
| sqflite | ^2.4.2 | Base SQLite conversations |
| path | ^1.9.1 | Manipulation chemins |
| path_provider | ^2.1.5 | Répertoire documents app |
| shared_preferences | ^2.5.3 | Réglages + état modèle |
| dio | ^5.8.0+1 | Téléchargement HTTP résumable |
| crypto | ^3.0.6 | SHA-256 |
| uuid | ^4.5.1 | IDs conversations/messages |
| intl | ^0.20.2 | Formatage dates |
| flutter_animate | ^4.5.2 | Animations UI |
| flutter_lints | ^5.0.0 | Lint (dev) |

## Natif (transitif via llama_flutter_android)

- llama.cpp b8201 (mars 2026)
- Kotlin coroutines + Pigeon
- JNI → llama.cpp ARM64 NEON
- Vulkan GPU (optionnel)

## Android

| Composant | Version |
|-----------|---------|
| minSdk | 26 (Android 8.0) |
| compileSdk | Flutter default |
| Gradle | 8.10.2 |
| AGP | 8.7.0 |
| Kotlin | 2.1.0 |
| Java | 17 |
| NDK | r27+ (requis plugin) |

## Modèle IA

| Composant | Détail |
|-----------|--------|
| Modèle | Qwen2.5-1.5B-Instruct |
| Format | GGUF Q4_K_M |
| Licence | Apache 2.0 |
| Source | huggingface.co/Qwen |

## Mise à jour

```bash
flutter pub outdated
flutter pub upgrade
```

Vérifier les breaking changes de `llama_flutter_android` avant upgrade majeur.
