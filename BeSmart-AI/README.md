# BeSmart AI

Application Android d'assistant IA **100 % local** — Qwen2.5 via llama.cpp, interface type iMessage.

## Fonctionnalités MVP

- Chat streaming token par token (hors ligne après téléchargement du modèle)
- Téléchargement résumable avec vérification SHA-256
- Historique des conversations (SQLite)
- Nouvelle conversation / suppression par swipe
- Thème clair / sombre (système)
- Modèle principal 1.5B + fallback 0.5B

## Prérequis

- Flutter 3.24+
- Android SDK (API 26+)
- NDK r27+
- Appareil ARM64 physique recommandé (4 Go RAM minimum)

## Installation rapide

```bash
cd C:\Users\david\BeSmart-AI
flutter pub get
flutter run
```

Build APK release :

```bash
flutter build apk --release
```

L'APK se trouve dans `build/app/outputs/flutter-apk/app-release.apk`.

## Documentation

- [docs/INSTALLATION.md](docs/INSTALLATION.md) — setup développeur
- [docs/MODEL_LOADING.md](docs/MODEL_LOADING.md) — gestion du modèle GGUF
- [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md) — versions des dépendances
- [docs/TEST_REPORT.md](docs/TEST_REPORT.md) — modèle de rapport de tests

## Choix technique du binding

Le cahier des charges recommande `llama_cpp_dart`. Pour le MVP, **BeSmart AI utilise `llama_flutter_android`** :

| Critère | llama_flutter_android |
|---------|----------------------|
| Licence | MIT (Play Store OK) |
| Streaming | Oui (EventChannel) |
| Chat templates | ChatML (Qwen) |
| Foreground service | Intégré |
| GPU Vulkan | Détection automatique |
| Maturité Android | Package dédié, maintenu |

Une migration vers `llama_cpp_dart` reste possible si besoin de multimodal ou d'un contrôle FFI plus fin.

## Structure

```
lib/
├── core/           # thème, constantes, utils
├── data/           # modèles, repositories, services
└── presentation/   # écrans, widgets, providers
```

## Licence

Code applicatif : à définir. Modèle Qwen2.5 : Apache 2.0.
