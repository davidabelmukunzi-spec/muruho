# Rapport de tests — BeSmart AI

> Modèle à compléter après tests sur appareils réels.

## Environnement de test

| Champ | Valeur |
|-------|--------|
| Version app | 1.0.0 |
| Date | |
| Testeur | |
| Flutter | |
| Build | release / debug |

## Appareils testés

| Appareil | Android | RAM | Modèle | Téléchargement | Chargement | Streaming (tok/s) | Mode avion | Verdict |
|----------|---------|-----|--------|----------------|------------|-------------------|------------|---------|
| | | | 1.5B | ☐ OK ☐ KO | ☐ OK ☐ KO | | ☐ OK | |
| | | | 0.5B | ☐ OK ☐ KO | ☐ OK ☐ KO | | ☐ OK | |

## Critères d'acceptation MVP

- [ ] Modèle téléchargé et chargé sans erreur sur ≥ 2 appareils
- [ ] Conversation complète sans crash
- [ ] Fonctionnement en mode avion après premier téléchargement
- [ ] Aucune donnée réseau hors téléchargement initial
- [ ] Vitesse ≥ 3 tok/s sur milieu de gamme (cible 5–8)
- [ ] Messages d'erreur clairs et actionnables

## Scénarios fonctionnels

### Téléchargement

- [ ] Progression affichée
- [ ] Reprise après interruption réseau
- [ ] Fichier partiel supprimé si échec définitif
- [ ] Vérification SHA-256

### Chat

- [ ] Envoi message utilisateur
- [ ] Streaming visible token par token
- [ ] Historique persisté après redémarrage app
- [ ] Nouvelle conversation
- [ ] Suppression conversation (swipe)

### UI

- [ ] Thème clair
- [ ] Thème sombre
- [ ] Retour haptique à l'envoi

## Problèmes connus

| ID | Description | Sévérité | Statut |
|----|-------------|----------|--------|
| | | | |

## Notes

_À compléter._
