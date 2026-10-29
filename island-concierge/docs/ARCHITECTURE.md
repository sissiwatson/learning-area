# Island Concierge — Architecture et plan d'implémentation (V0.1)

> Statut : **validé** (avec les décisions du §10), en cours d'implémentation.
> Cible : Godot **4.4.1-stable** (figé dans `.godot-version`), GDScript typé,
> renderer *Mobile*, export Android, orientation paysage.

---

## 1. Principes directeurs

1. **La logique de jeu ne dépend pas des scènes.** Toutes les règles (monnaies,
   inventaire, minuteurs, réservations, XP, quêtes) vivent dans des classes
   `RefCounted` pures, testables en headless sans arbre de scènes.
2. **Les données sont dans des fichiers, pas dans le code.** Bâtiments,
   ressources, recettes, niveaux, quêtes et cartes sont des `Resource` (`.tres`)
   éditables dans l'inspecteur Godot. Ajouter un bâtiment = ajouter un fichier.
3. **Flux à sens unique.** L'interface envoie des *commandes* à `GameState`
   (ex. `bookings.accept(...)`), qui renvoient un `Result` (succès / code
   d'erreur). Les changements d'état sont diffusés par signaux via `EventBus` ;
   la présentation ne fait qu'écouter et afficher.
4. **Le temps est injecté.** Une interface `Clock` fournit l'heure Unix ; le jeu
   utilise l'horloge système, les tests une `FakeClock` qu'on avance à la main.
   Les minuteurs stockent des horodatages de fin → la production avance aussi
   quand l'application est fermée.
5. **Sauvegarde en JSON versionné**, jamais en `.tres` dans `user://`
   (charger une `Resource` arbitraire peut exécuter du code).

### Couches et dépendances

```
┌──────────────────────────────────────────────────────────┐
│ Présentation  scenes/  (carte iso, caméra, bâtiments, UI)│
└───────────────▲──────────────────────────┬───────────────┘
                │ signaux (EventBus)        │ commandes → Result
┌───────────────┴──────────────────────────▼───────────────┐
│ Services (autoloads)  GameState · Database · SaveManager │
│                       EventBus · GameClock               │
└───────────────▲──────────────────────────────────────────┘
                │ compose / délègue
┌───────────────┴──────────────────────────────────────────┐
│ Cœur (src/core, RefCounted pur) Wallet · Inventory ·     │
│ ProductionSlot · Lodging · BookingSystem · Progression · │
│ QuestTracker · Result · Clock                            │
└───────────────▲──────────────────────────────────────────┘
                │ lit
┌───────────────┴──────────────────────────────────────────┐
│ Définitions (src/defs + data/*.tres) en lecture seule     │
└──────────────────────────────────────────────────────────┘
```

Règle : une couche ne connaît que les couches **en dessous** d'elle.

---

## 2. Arborescence

```
island-concierge/
├── project.godot                 # autoloads, stretch mode, orientation, renderer Mobile
├── icon.svg
├── README.md                     # lancer le jeu, lancer les tests
├── CREDITS.md                    # licence de chaque asset tiers
├── .gutconfig.json               # configuration des tests GUT
├── addons/
│   └── gut/                      # Godot Unit Test (MIT), vendored
├── assets/                       # uniquement des fichiers originaux ou CC0/CC-BY
│   ├── tiles/                    # tuiles iso 128×64 (océan, sable, herbe, chemin, verrou)
│   ├── buildings/                # sprites des bâtiments + chantier
│   ├── ui/                       # icônes ressources/monnaies, boutons 9-patch
│   └── fonts/                    # police OFL
├── data/                         # ⚙️ données de jeu configurables (.tres)
│   ├── items/                    # pineapple.tres, welcome_basket.tres
│   ├── currencies/               # shells.tres (monnaie douce), pearls.tres (gagnée, jamais achetée)
│   ├── recipes/                  # harvest_pineapple.tres, craft_welcome_basket.tres
│   ├── buildings/                # concierge_office, bungalow_hibiscus, bungalow_corail,
│   │                             # pineapple_farm, amenities_workshop, tiki_bar_site, tiki_bar
│   ├── bookings/                 # modèles de réservation (voyageurs, durée, commission)
│   ├── quests/                   # tutorial_01..07.tres
│   ├── progression/levels.tres   # paliers d'XP
│   ├── maps/mahana.tres          # placements, zones verrouillées, état initial
│   └── balance/new_game.tres     # monnaies et stock de départ
├── src/
│   ├── defs/                     # classes Resource (class_name) décrivant les données
│   │   ├── item_def.gd
│   │   ├── currency_def.gd
│   │   ├── recipe_def.gd         # entrées, sorties, durée, XP
│   │   ├── building_def.gd       # id, nom, sprite, emprise, rôle, recettes, coût de déblocage
│   │   ├── lodging_def.gd        # capacité, besoin (panier), durée de séjour
│   │   ├── booking_template_def.gd
│   │   ├── quest_def.gd          # objectif (type d'événement + cible + quantité), récompenses
│   │   ├── level_table_def.gd
│   │   ├── map_def.gd            # taille, placements, zones
│   │   ├── placement_def.gd      # building_id, cellule, verrouillé ?, condition
│   │   └── new_game_def.gd
│   ├── core/narrative/           # conditions, effets, dialogues, quêtes, relations, carnet
│   ├── core/reputation/          # notes, registre d'avis, paliers, missions de redressement
│   ├── view/                     # logique de présentation pure (sans Node), testée
│   │   ├── camera_rig.gd         # déplacement, zoom centré, limites, inertie
│   │   └── touch_gestures.gd     # tap / glisser / pincer, changements de doigts
│   ├── core/                     # logique pure, sans Node — 100 % testée
│   │   ├── result.gd             # Result.ok(value) / Result.err(code, params)
│   │   ├── clock.gd              # Clock (système) — FakeClock dans tests/
│   │   ├── wallet.gd             # monnaies : can_afford / spend / earn
│   │   ├── inventory.gd          # stock d'items, capacité, add / remove / has_all
│   │   ├── production_slot.gd    # une recette en cours : start / progress / is_ready / collect
│   │   ├── lodging.gd            # machine à états d'un logement
│   │   ├── booking_system.gd     # offres disponibles, acceptation, commissions
│   │   ├── progression.gd        # XP, niveau, déblocages par niveau
│   │   ├── quest_tracker.gd      # avance les quêtes à partir des événements
│   │   └── building_state.gd     # état runtime d'un bâtiment posé (locked/built, slots)
│   └── autoload/
│       ├── event_bus.gd          # signaux globaux (voir §5)
│       ├── database.gd           # charge et indexe data/, valide les références
│       ├── game_clock.gd         # expose la Clock courante (remplaçable)
│       ├── game_state.gd         # compose le cœur, expose les commandes, to_dict/from_dict
│       └── save_manager.gd       # JSON versionné, écriture atomique, autosave, migrations
├── scenes/
│   ├── main.tscn / main.gd       # point d'entrée : charge la sauvegarde puis la carte
│   ├── world/
│   │   ├── mahana.tscn           # TileMapLayer sol / décor / zones + conteneur Y-sort
│   │   ├── iso_map.gd            # conversions cellule ↔ monde, pose des bâtiments
│   │   ├── map_camera.gd         # Camera2D : événements → TouchGestures → CameraRig
│   │   ├── building_view.tscn/.gd# sprite + zone tactile + badge d'état/minuteur
│   │   └── lock_overlay.tscn/.gd # voile + cadenas sur zones verrouillées
│   └── ui/
│       ├── theme.tres            # tailles tactiles ≥ 48 dp, police, couleurs
│       ├── hud.tscn/.gd          # monnaies, XP/niveau
│       ├── building_panel.tscn/.gd   # panneau contextuel selon le rôle du bâtiment
│       ├── booking_card.tscn/.gd
│       ├── quest_tracker.tscn/.gd
│       └── toast.tscn/.gd        # messages courts (erreurs Result, récompenses)
├── tests/
│   ├── helpers/
│   │   ├── fake_clock.gd
│   │   └── fixtures.gd           # petites définitions en mémoire pour les tests
│   ├── unit/
│   │   ├── test_wallet.gd
│   │   ├── test_inventory.gd
│   │   ├── test_production_slot.gd
│   │   ├── test_lodging.gd
│   │   ├── test_booking_system.gd
│   │   ├── test_progression.gd
│   │   └── test_quest_tracker.gd
│   ├── integration/
│   │   ├── test_data_integrity.gd    # toutes les références de data/ existent
│   │   ├── test_full_loop.gd         # boucle complète jusqu'au tiki bar, sans UI
│   │   └── test_save_load.gd         # aller-retour, version, fichier corrompu, hors-ligne
└── docs/
    ├── ARCHITECTURE.md           # ce document
    ├── ANDROID_EXPORT.md         # SDK, keystore debug, export_presets, adb install
    └── ADDING_CONTENT.md         # ajouter un bâtiment / une ressource / un territoire
```

`export_presets.cfg` est versionné : depuis Godot 4.3 les identifiants de
signature sont stockés à part (`.godot/export_credentials.cfg`) ou passés par
variables d'environnement.

---

## 3. Modèle de données

### Rôles de bâtiment

Un `BuildingDef` a un `role` qui détermine son panneau et son comportement ;
les paramètres spécifiques sont des sous-ressources optionnelles :

| Rôle            | Bâtiments V0.1                       | Paramètres                              |
|-----------------|--------------------------------------|-----------------------------------------|
| `OFFICE`        | Bureau de conciergerie               | modèles de réservation proposés          |
| `LODGING`       | Bungalow Hibiscus, Bungalow Corail   | `LodgingDef` (besoin, durée, capacité)   |
| `PRODUCER`      | Plantation d'ananas, Atelier         | liste de `RecipeDef`, nb de slots        |
| `CONSTRUCTION`  | Emplacement du tiki bar              | coût, niveau requis, durée, `builds_into`|
| `DECORATION`    | Tiki bar (V0.1 : bonus d'XP simple)  | —                                        |

Ajouter un bâtiment d'un rôle existant ne demande **aucun code**. Un nouveau
rôle demande un script cœur + un panneau UI.

### Exemple de valeurs initiales (toutes modifiables dans `data/`)

| Élément                  | Valeur proposée                                  |
|--------------------------|--------------------------------------------------|
| Départ                   | 50 coquillages, 0 ananas, niveau 1               |
| Récolte d'ananas         | 30 s → 3 ananas, +5 XP                           |
| Panier d'accueil         | 3 ananas, 45 s → 1 panier, +10 XP                |
| Réservation « Couple »   | Bungalow Hibiscus, séjour 2 min, commission 120  |
| Préparer le bungalow     | consomme 1 panier                                |
| Fin de séjour            | +120 coquillages, +25 XP                         |
| Chantier tiki bar        | 150 coquillages, niveau 2, construction 60 s     |
| Bungalow Corail          | 300 coquillages, niveau 3 (hors boucle V0.1)     |

Les durées sont courtes pour le prototype ; un multiplicateur global dans
`balance/` permet de les rallonger plus tard.

### Machine à états d'un logement

```
 LOCKED ──unlock──► VACANT ──accept booking──► BOOKED ──prepare (−1 panier)──► READY
                      ▲                                                          │
                      │                                                   welcome guests
              collect commission                                                 ▼
                      └──────────── STAY_COMPLETE ◄──── timer ──── OCCUPIED (séjour)
```

Chaque transition est une méthode de `Lodging` qui renvoie un `Result` ;
une transition invalide (ex. accueillir sans préparer) renvoie une erreur et
ne modifie rien.

### Quêtes guidées (tutoriel)

Une `QuestDef` = objectif `{event: StringName, target: StringName, amount: int}`
+ récompenses. `QuestTracker` écoute les événements du cœur, pas l'UI :

1. `booking_accepted` — Accepter une réservation
2. `item_collected:pineapple ×3` — Récolter des ananas
3. `item_collected:welcome_basket` — Fabriquer un panier d'accueil
4. `lodging_prepared` — Préparer le bungalow
5. `guests_welcomed` — Accueillir les voyageurs
6. `stay_completed` — Terminer le séjour et toucher la commission
7. `building_built:tiki_bar` — Construire le tiki bar

---

## 4. Carte Mahana et interactions

- **TileMapLayer** isométriques (Godot ≥ 4.3), tuiles 128×64, carte 32×32 :
  `Ground` (océan, sable, herbe, chemin), `Decor` (palmiers, rochers),
  `Zones` (voile des zones verrouillées). Les bâtiments sont des scènes
  instanciées dans un `Node2D` en *Y-sort*, positionnées depuis `mahana.tres`.
- **Caméra** : `InputEventScreenDrag` (1 doigt) pour déplacer ; deux doigts
  (distance entre `InputEventScreenTouch`) + `InputEventMagnifyGesture` pour
  zoomer ; molette et clic-glisser pour tester sur PC. Seuil de déplacement
  (~12 px) pour distinguer *tap* et *drag*. Caméra bornée à la carte.
- **Sélection** : un tap convertit la position écran → cellule → bâtiment ;
  le `BuildingPanel` s'ouvre avec les actions du rôle. Une zone verrouillée
  affiche sa condition de déblocage.
- **Écran** : paysage, base 1920×1080, `stretch_mode = canvas_items`,
  `aspect = expand`, marges sûres (encoches) dans le HUD.
- **Textes** : clés `tr()` dès le départ (fichier CSV FR, EN plus tard).

---

## 5. Signaux de l'EventBus

```gdscript
signal currency_changed(currency_id: StringName, amount: int)
signal inventory_changed(item_id: StringName, amount: int)
signal item_collected(item_id: StringName, amount: int)
signal production_started(building_uid: StringName, recipe_id: StringName, ends_at: int)
signal production_ready(building_uid: StringName)
signal booking_offered(offer_id: StringName)
signal booking_accepted(offer_id: StringName, lodging_uid: StringName)
signal lodging_state_changed(lodging_uid: StringName, state: int)
signal stay_completed(lodging_uid: StringName, commission: int)
signal xp_gained(amount: int)
signal level_up(new_level: int)
signal building_unlocked(building_uid: StringName)
signal building_built(building_uid: StringName, building_id: StringName)
signal quest_progressed(quest_id: StringName, progress: int, goal: int)
signal quest_completed(quest_id: StringName)
signal action_failed(error_code: StringName, params: Dictionary)
```

---

## 6. Sauvegarde

- Fichier `user://save.json`, écriture dans `save.json.tmp` puis renommage
  (pas de fichier corrompu en cas de coupure).
- Déclencheurs : après chaque commande réussie (avec un délai de 2 s pour
  regrouper), `NOTIFICATION_APPLICATION_PAUSED` (Android en arrière-plan) et
  `NOTIFICATION_WM_CLOSE_REQUEST`.
- Au chargement : migration si `version` < version courante ; fichier illisible
  → copie en `save.corrupt.json` + nouvelle partie (jamais de crash).
- Chaque classe du cœur implémente `to_dict()` / `from_dict()`.

```json
{
  "version": 1,
  "saved_at": 1793300000,
  "wallet": { "shells": 170, "pearls": 0 },
  "inventory": { "pineapple": 2, "welcome_basket": 0 },
  "progression": { "xp": 40 },
  "buildings": {
    "farm_1":     { "def": "pineapple_farm", "built": true,
                    "slots": [{ "recipe": "harvest_pineapple", "ends_at": 1793300030 }] },
    "hibiscus_1": { "def": "bungalow_hibiscus", "built": true,
                    "lodging": { "state": "OCCUPIED", "booking": "couple_01", "ends_at": 1793300120 } },
    "tiki_site":  { "def": "tiki_bar_site", "built": false }
  },
  "bookings": { "offers": ["couple_01"], "next_offer_at": 1793300300 },
  "quests": { "active": "tutorial_06", "progress": 0, "completed": ["tutorial_01", "..."] }
}
```

---

## 7. Tests

- Framework : **GUT** (MIT), vendored dans `addons/gut/`, exécutable en CLI :
  `godot --headless -s addons/gut/gut_cmdln.gd -gexit`.
- Le cœur n'utilise pas l'arbre de scènes → tests rapides et déterministes
  grâce à `FakeClock`.
- Règles économiques couvertes : pas de solde négatif, achat refusé sans fonds,
  inventaire atomique (une recette ne consomme rien si une entrée manque),
  minuteurs (avant/après échéance, progression hors-ligne), transitions de
  logement invalides refusées, commission versée une seule fois, montée de
  niveau à seuil exact et multiple, quêtes non comptées deux fois.
- Sauvegarde : aller-retour identique, minuteur qui expire pendant que le jeu
  est fermé, fichier corrompu, migration de version.
- `test_full_loop.gd` joue la boucle complète du brief, sans interface,
  jusqu'à la construction du tiki bar.

---

## 8. Ressources graphiques

- V0.1 : formes iso simples **créées pour le projet** (SVG/PNG originaux),
  éventuellement complétées par des packs **CC0** (ex. Kenney). Chaque asset
  tiers est listé dans `CREDITS.md` avec sa licence et sa source.
- Les sprites sont référencés uniquement depuis `data/` → remplacer les
  placeholders par l'art final ne touche pas le code.

---

## 9. Plan d'implémentation — petites étapes vérifiables

Chaque étape = un commit autonome, avec son critère de validation. Ordre
révisé : une **carte navigable et un bungalow interactif d'abord**, puis
l'économie, les réservations et les productions viennent s'y brancher.
Une étape n'est validée que si elle a été exécutée ou testée.

| #  | Étape | Contenu | Vérification | Statut |
|----|-------|---------|--------------|--------|
| 0  | **Squelette** | `project.godot` (Mobile, paysage, stretch), Godot figé, `EventBus`, GUT, i18n FR, outils de test et de capture | Tests GUT verts en headless ; scène principale capturée | ✅ |
| 1  | **Carte Mahana** | Tuiles iso placeholder, plan 32×32 en données, `TileMapLayer`, zones verrouillées | Tests du plan et des conversions cellule ↔ monde ; capture | ✅ |
| 2  | **Caméra tactile** | `CameraRig`, `TouchGestures`, `MapCamera` : glisser, pincer, molette, limites, inertie | Tests des calculs et des gestes simulés ; captures zoom min/initial/max | ✅ (non testé sur appareil) |
| 3  | **Bungalow interactif** | Bungalow Hibiscus, sélection au tap, panneau (nom, propriétaire, état, actions), `Lodging`, `GameState` | Tests de la machine à états et du tap simulé ; captures | ✅ (non testé sur appareil) |
| 4  | **Export Android debug** | `export_presets.cfg`, `ANDROID_EXPORT.md`, `tools/export_android_debug.sh` | APK construit et signature vérifiée ; recette sur appareil réel n°1 réussie | ✅ 📱 |
| 5  | **Économie de base** | `Clock`, `Wallet` (coquillages, extensible), `Inventory`, HUD | Tests unitaires ; HUD affiché | ✅ (non testé sur appareil) |
| 6  | **Données** | `Database` + validation de toutes les références de `data/` | `test_data_integrity` | à faire |
| 7  | **Réservations** | `BookingSystem`, bureau de conciergerie, durée de séjour, commission | Tests ; boucle réservation jouable | à faire |
| R1–R2 | **Réputation : calcul et registre** | voir `REPUTATION.md` §10 | Tests de frontière 4,80 et d'immuabilité | à faire |
| 8  | **Productions** | `ProductionSlot`, plantation d'ananas, atelier (panier) | Tests minuteurs / hors-ligne ; boucle complète jouable | à faire |
| R3–R4 | **Réputation : séjours notés** | journal de séjour, règles, avis publié en fin de séjour | Séjour parfait = 5,00 ; sans panier = note attendue | à faire |
| 9  | **Progression & tutoriel narratif** | XP, niveaux, toasts ; N1–N5 : conditions/effets, PNJ et relations, dialogues, quêtes narratives, tutoriel avec Hina (voir `NARRATIVE.md`) | Test de bout en bout du tutoriel ; partie jouée à la main | à faire |
| N6–N7 | **Carnet de voyage et validation de contenu** | 3 fiches de Mahana, test de cohérence des références | Récompenses uniques ; données cassées détectées | à faire |
| 10 | **Sauvegarde** | JSON versionné (avis inclus), autosave, migration | `test_save_load` ; relance conserve l'état | à faire |
| R5–R6 | **Réputation : effets et redressement** | offres par palier, missions | Jamais 0 offre ; scénario de récupération | à faire |
| 11 | **Tiki bar** | Chantier → construction → bâtiment | `test_full_loop` jusqu'au tiki bar | à faire |
| 12 | **Finitions V0.1** | `ADDING_CONTENT.md`, `CREDITS.md`, équilibrage, nouvel APK | Revue de la checklist du brief | à faire |

Le détail des tâches à venir est dans [`BACKLOG.md`](BACKLOG.md).

---

## 10. Décisions

1. **Orientation** : paysage (base 1920×1080).
2. **Godot** : 4.4.1-stable, figé dans `.godot-version` (vérifié par un test).
3. **Monnaie** : coquillages uniquement en V0.1 ; `Wallet` indexé par
   identifiant de monnaie pour ajouter les perles sans refonte.
4. **Langues** : français par défaut (locale de repli `fr`), tous les textes
   passent par des clés `tr()` dans `i18n/strings.csv` ; l'anglais s'ajoute
   comme une colonne `en`.
5. **Graphismes** : assets provisoires originaux, mais vraie carte isométrique
   navigable dès l'étape 1.

---

## 11. Réputation et satisfaction des voyageurs

Mécanique centrale décrite dans [`REPUTATION.md`](REPUTATION.md). En résumé :

- Note moyenne de la conciergerie sur 5 ; **seuil d'excellence 4,80**.
- Chaque séjour est noté sur 5 critères pondérés (propreté 25 %,
  communication 20 %, confort et décoration 20 %, annonce/photos 15 %,
  expérience 20 %), configurables dans `data/reputation/`.
- Calcul **déterministe en entiers (centièmes)**, troncature, à partir des
  faits réellement vécus pendant le séjour ; aucun tirage aléatoire.
- Avis **immuables** (instantané avec version des règles), registre en ajout
  seul, historique sauvegardé.
- La réputation (moyenne glissante des 20 derniers avis) influence la
  visibilité, le nombre et le type de réservations, la confiance des
  propriétaires, l'accès aux logements premium et les opportunités
  d'expansion. Sous 4,80 : difficultés accrues mais jamais de blocage
  (plancher d'offres, missions de redressement, contenu jamais reverrouillé).

Place dans l'architecture : configuration dans `src/defs/` + `data/reputation/`,
logique pure dans `src/core/reputation/`, état dans `GameState`, signaux
`review_published` et `reputation_changed` dans `EventBus`, tableau de bord
dans `scenes/ui/`.

---

## 12. Découverte culturelle, personnages et missions narratives

Conception dans [`NARRATIVE.md`](NARRATIVE.md), scénario du tutoriel dans
[`SCENARIO_TUTORIEL.md`](SCENARIO_TUTORIEL.md). En résumé :

- Destinations (`DestinationDef`) : Mahana (fictive) puis destinations
  inspirées de lieux réels, avec sources vérifiées et distinction visible
  fait / inspiré / fiction.
- PNJ récurrents (`NpcDef`) avec relation à 6 niveaux jamais perdus et
  services débloquables : Hina, Tao, Malia, Kimo.
- Dialogues, quêtes narratives, conditions, effets et fiches du carnet de
  voyage sont des **données** ; le moteur (`src/core/narrative/`) est
  générique et ses récompenses sont idempotentes.
- Les quêtes guidées du tutoriel sont des quêtes narratives données par Hina :
  un seul système de quêtes.
- Un test de données vérifie la cohérence de toutes les références
  (PNJ, lieux, quêtes, dialogues, fiches, i18n, sources).

---

## 13. Destinées de l'archipel (V0.3)

Conception dans [`ARCHIPELAGO_DESTINIES.md`](ARCHIPELAGO_DESTINIES.md).
Quatre indicateurs indépendants (rentabilité, réputation touristique,
patrimoine et communauté, équilibre environnemental), grandes décisions
narratives pilotées par des données (options exclusives, clauses, coûts,
conséquences immédiates et différées, modifications de carte, réactions des
PNJ), réparations toujours possibles, aucun choix dominant (vérifié par
simulation). Logique pure dans `src/core/destinies/`, réutilise le moteur de
conditions et d'effets du lot N ; la carte d'origine n'est jamais réécrite
(superposition de modifications sauvegardée). Première quête : « L'avenir de
la baie ».
