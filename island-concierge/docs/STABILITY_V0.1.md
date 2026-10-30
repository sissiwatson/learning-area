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

Résultat : 445 touchers (dont 265 sur la carte, les autres sur l'interface),
387 boutons, 146 ouvertures de panneau, 7 quêtes du tutoriel terminées par
le hasard, nœuds 192 → 207 (bâtiments construits), orphelins 0 → 0.

Correction honnête de l'outil : une première version injectait les touchers
avec des coordonnées fausses en mode headless (fenêtre 0×0, étirement non
identité) ; les touchers arrivaient bien à la caméra mais loin de l'île
(25 panneaux ouverts au lieu de 146). Corrigé ; les chiffres ci-dessus sont
ceux de la version corrigée.

**Défaut trouvé et corrigé — S1 (plantage)** : en rouvrant vite un panneau
pendant qu'il se mettait en page, la barre de défilement apparaissait et
disparaissait sans fin (la largeur change le retour à la ligne, donc la
hauteur, donc la barre) ; la file de messages du moteur saturait et le jeu
**plantait**. La place de la barre est désormais toujours réservée
(`SCROLL_MODE_RESERVE`). Contre-épreuve (faite avec la première version du
singe) : sans ce réglage, il plante au même endroit. Ce défaut pouvait toucher les téléphones, où les panneaux
défilent plus souvent.

### 2.3 Vrais touchers sur les boutons du panneau (🧪 Xvfb, pas encore 📱)

**Défaut trouvé par l'endurance et corrigé — S3** : un vrai toucher (Android
envoie la souris émulée puis le toucher) sur un bouton d'action du panneau
(« Faire le ménage », « Encaisser », « Accepter »…) reconstruisait le panneau
et retirait le bouton **avant** la fin du toucher ; le moteur livrait alors
la fin du toucher à un bouton sorti de l'arbre et écrivait une erreur
(`!is_inside_tree`). L'action était bien faite, mais l'erreur se serait
produite **à chaque toucher** sur téléphone. Les tests ne la voyaient pas :
ils appuient sur les boutons par programme.

Correction : les actions du panneau sont exécutées juste après le toucher
(connexion différée) ; chaque bouton garde le bâtiment pour lequel il a été
créé, donc l'action s'applique même si le panneau se ferme dans la même
image (`test_action_still_applies_when_the_panel_closes_in_the_same_frame`).
Preuve par le vrai chemin des entrées : scénario `touch_panel_action` de
`tools/visual_checks.sh` (échoue sans le correctif, contre-épreuve faite).

### 2.4 Compatibilité des sauvegardes (🧪)

Une sauvegarde au format de l'APK 0.1.3 (sans progression, quêtes ni
chantiers) se charge : solde, inventaire et séjour en cours conservés,
progression à zéro, tutoriel disponible ; la sauvegarde suivante passe au
format complet (`test_save_from_0_1_3_without_progression_quests_or_constructions_loads`).

### 2.5 Endurance en temps réel (🧪 `tools/endurance_run.sh`)

Scène complète, horloge réelle accélérée ×20, joueur automatique (une action
toutes les 0,4 s : boutons, bâtiments, glissés, molette), vraie sauvegarde
sur fichier temporaire, mesures toutes les 10 s.

Résultat de la version finale (10 min réelles = 3 h 20 de jeu, 61 mesures) :

| Mesure | Début | Min | Max | Fin |
|--------|------:|----:|----:|----:|
| Mémoire statique (Mo) | 32,8 | 32,7 | 33,1 | 33,0 |
| Objets | 1 854 | 1 826 | 1 899 | 1 853 |
| Nœuds | 119 | 112 | 133 | 117 |
| Orphelins (transitoires, mesurés dans l'image d'une action) | 5 | 0 | 13 | 5 |

- 1 501 actions (577 boutons, 610 touchers, 134 glissés, 180 crans de
  molette) ; les **8 quêtes du tutoriel** terminées, tiki bar compris ;
  niveau 5, 6 séjours encaissés ; sauvegarde réelle écrite sans échec.
- **Aucune dérive** de mémoire, d'objets ni de nœuds ; **0 erreur moteur**.
- Images par seconde (40 à 135) : sans valeur pour un téléphone (rendu
  logiciel llvmpipe, renderer de compatibilité) ; la fluidité reste à
  vérifier sur appareil.

Les premières exécutions ont trouvé le défaut S3 (§2.3). Elles ont aussi
montré deux limites du joueur automatique, corrigées dans l'outil : des
coordonnées de fenêtre mal converties, et des glissés fusionnés par le
moteur (aucun déplacement de carte reconnu).

### 2.6 Garde-fous ajoutés aux outils

- `tools/run_tests.sh` échoue sur toute ligne `ERROR:` du moteur (vérifié
  avec un test volontairement fautif).
- `tools/visual_checks.sh` et `tools/endurance_run.sh` échouent sur toute
  erreur de script ou du moteur ; une dépendance de classe qui provoquait
  des erreurs de compilation dans l'outil de captures a été supprimée.

## 3. Bilan chiffré

- Tests automatisés : 294 → **310**, tous verts, 0 ligne d'erreur moteur ;
  plus 31 scénarios de captures et l'endurance, hors suite GUT.
- Défauts corrigés à l'étape 12 : 7 d'ergonomie, 3 de stabilité (dont un
  plantage).
- Non vérifié : comportement sur téléphone (renderer mobile, tactile réel,
  clavier, mémoire de l'appareil) → recette n°4.
