# Étape 12 — Audit UX et recette de stabilité de la V0.1

Légende : 🧪 vérifié par exécution (tests, captures, simulation) ·
📱 vérifié sur appareil réel. **Aucun point de ce document n'est encore 📱** :
la recette n°4 sur téléphone (`ANDROID_EXPORT.md`) reste à faire.

## 1. Audit UX (🧪 captures aux formats 16:9, 20:9 et 4:3)

Écrans audités : vue d'ensemble, panneaux de chaque rôle de bâtiment, bureau
avec offres, dialogues, bandeau d'objectif, messages, tiki bar construit.
Résolutions simulées : 1280×720, 1200×540 (20:9), 1024×768 (4:3), avec
`tools/visual_checks.sh` (renderer de compatibilité, pas le renderer mobile).

| # | Défaut constaté | Gravité | Correction | Preuve |
|---|-----------------|---------|------------|--------|
| D1 | Étiquettes de zone, cadenas, pastilles « ! » et anneaux grossissaient avec le zoom (illisibles dézoomé, énormes zoomé) | moyenne | Taille constante à l'écran (`screen_sized`, `WorldMap.set_camera_zoom`) | `test_overlays_keep_their_screen_size` |
| D2 | Cadrage initial : une partie de l'île hors de l'écran selon le format (U1) | moyenne | `frame_island` : toute la terre ferme visible et centrée | `test_initial_framing_shows_the_whole_island_on_every_screen_shape` |
| D4 | Panneau de bâtiment et dialogue affichés en même temps | moyenne | Un dialogue qui commence ferme le panneau | `test_a_starting_dialogue_closes_the_building_panel` |
| D5 | Bulles des personnages déformées par le zoom | faible | Même mécanisme que D1 | captures |
| D7 | Offre du bureau : « commission 0 » quand tous les logements sont réservés | moyenne | `GameState.commission_percent_for` | `test_offer_shows_the_real_commission_even_when_everything_is_booked` |
| D8 | Après « Y aller », étiquettes et pastilles gardaient l'ancienne taille | faible | Cadrages programmés via `MapCamera.apply_now` (signal de zoom) | `test_go_button_framing_keeps_overlays_screen_sized` (contre-épreuve : échoue sans le correctif) |
| D9 | Erreur moteur « instance is gone » si le panneau était libéré pendant son ajustement de hauteur | faible | Connexion unique à l'image suivante au lieu d'un `await` | 0 ligne `ERROR` dans les journaux |

Restent connus, sans gêne de jeu constatée : une bulle de personnage ou une
étiquette de zone peut passer sous le bandeau d'objectif ; pastille « ! » du
bureau visible pendant le premier dialogue ; marge réservée à droite des
panneaux pour la barre de défilement (conséquence du correctif S1).

## 2. Recette de stabilité

### 2.1 Joueur aléatoire sur l'économie (🧪 `tests/stability/test_soak_economy.gd`)

3 graines × 1 500 actions tirées au hasard (accepter une offre, produire,
préparer, accueillir, encaisser, construire, démarrer une quête, attendre de
1 s à 6 h, **reculer l'horloge** jusqu'à 2 h, **sauvegarder et recharger** via
JSON). Après **chaque** action, 15 invariants :

- temps de jeu monotone ; soldes jamais négatifs ; journal du portefeuille
  cohérent maillon par maillon et égal au solde ;
- inventaire ≤ capacité, quantités ≥ 0 ;
- logement verrouillé toujours libre ; logement occupé ⇒ une réservation
  compatible avec sa capacité ;
- **aucune commission encaissée deux fois** (historique des séjours et journal) ;
- offres bornées ; XP croissante ; récompenses de quête seulement pour les
  quêtes terminées ; producteurs dans leur nombre de créneaux ;
- **aller-retour de sauvegarde identique** à chaque rechargement.

Résultat : 4 500 actions, 221 rechargements, ≈ 2 570 actions refusées (normal),
33 séjours menés à terme, tiki bar construit dans chaque partie. Deux
contre-épreuves vérifient que le contrôle détecte un double encaissement, un
journal incohérent et un inventaire trop plein.

**Défaut trouvé et corrigé — S2** : après un rechargement, l'historique des
séjours gardait des nombres flottants (`120.0`) ; la sauvegarde suivante
différait de l'état d'origine. Corrigé (`_whole_numbers_as_int`), test
`test_stay_history_keeps_integers_across_several_reloads`.

### 2.2 « Singe » sur l'interface (🧪 `tests/stability/test_monkey_ui.gd`)

1 200 événements aléatoires sur la scène complète : touchers, glissés,
pincements à deux doigts, boutons visibles (dialogue, bandeau, panneaux),
avec le temps qui passe. Vérifie : aucune erreur moteur, panneau et dialogue
jamais ensemble, aucun nœud orphelin, pas d'accumulation de nœuds après la
fin des animations.

Résultat : 8 quêtes du tutoriel terminées par le hasard, 24 ouvertures de
panneau, nœuds 192 → 205 (bâtiments construits), orphelins 0 → 0.

**Défaut trouvé et corrigé — S1 (plantage)** : en rouvrant vite un panneau
pendant qu'il se mettait en page, la barre de défilement apparaissait et
disparaissait sans fin (la largeur change le retour à la ligne, donc la
hauteur, donc la barre) ; la file de messages du moteur saturait et le jeu
**plantait**. La place de la barre est désormais toujours réservée
(`SCROLL_MODE_RESERVE`). Contre-épreuve : sans ce réglage, le singe plante au
même endroit. Ce défaut pouvait toucher les téléphones, où les panneaux
défilent plus souvent.

### 2.3 Compatibilité des sauvegardes (🧪)

Une sauvegarde au format de l'APK 0.1.3 (sans progression, quêtes ni
chantiers) se charge : solde, inventaire et séjour en cours conservés,
progression à zéro, tutoriel disponible ; la sauvegarde suivante passe au
format complet (`test_save_from_0_1_3_without_progression_quests_or_constructions_loads`).

### 2.4 Endurance en temps réel (🧪 `tools/endurance_run.sh`)

Scène complète, horloge réelle accélérée ×20, joueur automatique (une action
toutes les 0,4 s : boutons, bâtiments, glissés, molette), vraie sauvegarde
sur fichier temporaire, mesures toutes les 10 s.

RESULTATS_ENDURANCE

### 2.5 Garde-fous ajoutés aux outils

- `tools/run_tests.sh` échoue sur toute ligne `ERROR:` du moteur (vérifié
  avec un test volontairement fautif).
- `tools/visual_checks.sh` et `tools/endurance_run.sh` échouent sur toute
  erreur de script ou du moteur ; une dépendance de classe qui provoquait
  des erreurs de compilation dans l'outil de captures a été supprimée.

## 3. Bilan chiffré

- Tests automatisés : 294 → **308**, tous verts, 0 ligne d'erreur moteur.
- Défauts corrigés à l'étape 12 : 7 d'ergonomie, 2 de stabilité (dont un
  plantage).
- Non vérifié : comportement sur téléphone (renderer mobile, tactile réel,
  clavier, mémoire de l'appareil) → recette n°4.
