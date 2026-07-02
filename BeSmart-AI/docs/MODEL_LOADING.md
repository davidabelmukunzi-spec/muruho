# Gestion du modèle GGUF — BeSmart AI

## Emplacement de stockage

Un **seul répertoire** est utilisé, résolu au runtime :

```
{ApplicationDocumentsDirectory}/models/
```

Exemple Android : `/data/user/0/com.besmart.ai/app_flutter/models/`

Aucun chemin n'est codé en dur ni affiché à l'utilisateur.

## Modèles supportés

| ID | Fichier | Taille ~ | RAM min |
|----|---------|----------|---------|
| qwen2.5-1.5b-instruct-q4_k_m | qwen2.5-1.5b-instruct-q4_k_m.gguf | 986 Mo | 4 Go |
| qwen2.5-0.5b-instruct-q4_k_m | qwen2.5-0.5b-instruct-q4_k_m.gguf | 398 Mo | 3 Go |

Source : [Qwen/Qwen2.5-*-Instruct-GGUF](https://huggingface.co/Qwen) sur Hugging Face.

## Flux de téléchargement

```
Premier lancement
    → ModelManager.initialize()
    → Choix du modèle (1.5B ou 0.5B)
    → Téléchargement vers {models}/{fileName}.part
    → Reprise HTTP Range si .part existant
    → Renommage en {fileName}
    → Vérification taille + SHA-256
    → Stockage hash dans SharedPreferences
    → isModelReady = true
```

## Vérification d'intégrité

1. **Taille** : le fichier doit atteindre ≥ 90 % de la taille attendue
2. **SHA-256** :
   - Si `ModelConfig.*.sha256` est renseigné → comparaison stricte
   - Sinon → hash calculé et stocké pour les vérifications futures

Pour obtenir le hash officiel :

```bash
sha256sum qwen2.5-1.5b-instruct-q4_k_m.gguf
```

Puis mettre à jour `lib/core/constants/model_config.dart`.

## Chargement en mémoire

Géré par `InferenceService` via `llama_flutter_android` :

1. `detectGpu()` — RAM libre + couches GPU recommandées
2. `loadModel(modelPath, threads: 4, contextSize: 2048, gpuLayers: auto)`
3. État exposé via `ModelLoadState` (checking → loading → loaded / failed)

## Libération mémoire

- `dispose()` à la fermeture du service
- Déchargement automatique après **30 min** d'inactivité (`AppConstants.modelInactivityUnloadMinutes`)
- Fichiers `.part` supprimés en cas d'échec

## Messages utilisateur

| Situation | Message |
|-----------|---------|
| Téléchargement | « Le modèle est en cours de téléchargement. » |
| Vérification | « Vérification du fichier… » |
| Échec chargement | « Le modèle n'a pas pu être chargé. Réessayer ? » |
| Fichier incomplet | « Le fichier téléchargé semble incomplet. Réessayer ? » |
| Hash invalide | « La vérification du fichier a échoué. Réessayer ? » |

## Génération (streaming)

Template **ChatML** pour Qwen2.5 :

```dart
controller.generateChat(
  messages: [...],
  template: 'chatml',
  temperature: 0.7,
  maxTokens: 512,
).listen((token) { ... });
```

Le foreground service natif du plugin maintient l'inférence si Android suspend l'app en arrière-plan.

## Fallback appareil faible

Si le modèle 1.5B échoue au chargement :

1. Aller dans Réglages → Retélécharger
2. Choisir **Qwen2.5 0.5B Instruct (léger)**

Une détection RAM automatique avant téléchargement peut être ajoutée en v2 via `detectGpu().freeRamBytes`.
