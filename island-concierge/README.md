# Island Concierge

Prototype (V0.1) de jeu mobile Android de gestion en 2D isométrique, réalisé
avec **Godot 4.4.1** et GDScript. Le joueur gère une conciergerie touristique
sur l'île de Mahana.

L'architecture et le plan d'implémentation sont décrits dans
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Prérequis

- [Godot 4.4.1-stable](https://godotengine.org/download/archive/4.4.1-stable/)
  (version figée dans `.godot-version`).

## Lancer le jeu

1. Ouvrir Godot, *Importer* puis choisir `island-concierge/project.godot`.
2. Appuyer sur **F5** (ou ▶).

En ligne de commande : `godot --path island-concierge`

Sur PC, la souris émule le toucher (un doigt) ; la molette remplace le pincement.

## Lancer les tests

Les tests utilisent [GUT 9.4.0](https://github.com/bitwes/Gut) (licence MIT,
inclus dans `addons/gut/`).

```bash
tools/run_tests.sh                 # depuis island-concierge/, headless
GODOT=/chemin/vers/godot tools/run_tests.sh
```

Le script renvoie un code non nul si un test échoue. Les tests peuvent aussi
être lancés depuis l'éditeur via le panneau **GUT** en bas de l'écran.

## Capture d'écran d'une scène (Linux)

```bash
tools/capture.sh res://scenes/main.tscn capture.png
```

## Organisation

| Dossier        | Rôle |
|----------------|------|
| `src/core/`    | règles métier pures (sans scène), entièrement testées |
| `src/defs/`    | classes décrivant les données de jeu |
| `src/autoload/`| services globaux (`EventBus`, …) |
| `data/`        | données configurables (bâtiments, ressources, carte) |
| `scenes/`      | présentation : carte, caméra, bâtiments, interface |
| `i18n/`        | textes traduisibles (`strings.csv`, colonne par langue) |
| `tests/`       | tests GUT unitaires et d'intégration |
| `tools/`       | scripts de développement |

## Langues

Tous les textes affichés passent par une clé de traduction (`tr("CLE")`).
Pour ajouter l'anglais : ajouter une colonne `en` à `i18n/strings.csv`, puis
déclarer `res://i18n/strings.en.translation` dans
*Projet → Paramètres → Localisation*.
