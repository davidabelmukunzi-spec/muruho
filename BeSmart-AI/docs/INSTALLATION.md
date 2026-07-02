# Installation — BeSmart AI

## 1. Installer Flutter

Windows :

1. Télécharger Flutter stable : https://docs.flutter.dev/get-started/install/windows
2. Extraire (ex. `C:\src\flutter`)
3. Ajouter `C:\src\flutter\bin` au PATH
4. Vérifier : `flutter doctor`

## 2. Android Studio / SDK

1. Installer Android Studio
2. SDK Platform 34+ et Build-Tools
3. NDK r27+ via SDK Manager → SDK Tools → NDK
4. Configurer `ANDROID_HOME` (ex. `%LOCALAPPDATA%\Android\Sdk`)

## 3. Projet

```bash
cd C:\Users\david\BeSmart-AI
flutter pub get
```

Créer `android/local.properties` si absent (généré automatiquement par Flutter) :

```properties
sdk.dir=C:\\Users\\david\\AppData\\Local\\Android\\Sdk
flutter.sdk=C:\\src\\flutter
```

## 4. Lancer sur appareil

```bash
flutter devices
flutter run --release
```

**Important** : tester sur un **appareil ARM64 réel**. L'émulateur x86 n'est pas compatible avec les bibliothèques natives llama.cpp.

## 5. Premier lancement

1. L'app affiche l'écran de téléchargement du modèle (~900 Mo pour Qwen2.5-1.5B Q4_K_M)
2. Connexion internet requise **uniquement** pour ce téléchargement
3. Après validation, activer le mode avion et vérifier que le chat fonctionne

## 6. Build APK

```bash
flutter build apk --release
```

Pour un APK split par ABI (plus léger) :

```bash
flutter build apk --release --split-per-abi
```

## Dépannage

| Problème | Solution |
|----------|----------|
| Modèle ne charge pas | Vérifier RAM libre, essayer le modèle 0.5B |
| Téléchargement interrompu | Relancer — reprise automatique via HTTP Range |
| Gradle / NDK error | `flutter doctor --android-licenses`, mettre à jour NDK |
| Lenteur | GPU Vulkan activé automatiquement si supporté |
