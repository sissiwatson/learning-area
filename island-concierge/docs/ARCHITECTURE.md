# Island Concierge — Architecture et plan d'implémentation (V0.1)

> Statut : **proposition à valider** avant tout développement.
> Cible : Godot 4.4+ (GDScript typé), renderer *Mobile*, export Android.

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
│   │   ├── camera_controller.gd  # glisser un doigt, pincer pour zoomer, bornes, inertie
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

`export_presets.cfg` n'est pas versionné tel quel (il peut contenir des chemins
de keystore) ; un modèle `export_presets.example.cfg` sera fourni.

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

Chaque étape = un commit (ou une PR) autonome, avec son critère de validation.
Les étapes 1 à 5 livrent **toute la boucle de jeu, testée, sans graphismes** ;
la carte et l'interface viennent ensuite se brancher dessus.

| # | Étape | Contenu | Vérification |
|---|-------|---------|--------------|
| 0 | **Squelette** | `project.godot` (renderer Mobile, paysage, stretch), dossiers, autoloads vides, GUT, README | Le projet s'ouvre dans Godot ; `gut_cmdln` passe avec un test témoin |
| 1 | **Économie de base** | `Result`, `Clock`/`FakeClock`, `Wallet`, `Inventory` | Tests unitaires verts (soldes, refus, atomicité) |
| 2 | **Données** | classes `defs/`, fichiers `data/*.tres` de Mahana, `Database` + validation | `test_data_integrity` vert ; une donnée invalide fait échouer le test |
| 3 | **Production & progression** | `ProductionSlot`, `Progression` (XP/niveaux) | Tests : minuteurs, hors-ligne, montée de niveau |
| 4 | **Réservations & logements** | `Lodging`, `BookingSystem`, `BuildingState`, `GameState` (commandes) | `test_full_loop` : réservation → ananas → panier → préparation → accueil → commission → tiki bar |
| 5 | **Sauvegarde** | `to_dict`/`from_dict`, `SaveManager`, autosave, migration | `test_save_load` vert ; relancer le jeu conserve l'état |
| 6 | **Carte Mahana** | Tuiles placeholder, TileMapLayer 32×32, `CameraController` | Lancement PC : carte visible, glisser/zoomer à la souris et en touch émulé |
| 7 | **Bâtiments & panneau** | `BuildingView`, sélection au tap, `BuildingPanel`, zones verrouillées | La boucle complète se joue à la main sur PC |
| 8 | **HUD & quêtes** | `QuestTracker`, HUD, toasts, quêtes tutoriel | Un nouveau joueur est guidé jusqu'au tiki bar ; tests quêtes verts |
| 9 | **Android** | `ANDROID_EXPORT.md`, preset, réglages tactiles, pause/reprise | APK debug installé via `adb`, partie sauvegardée après mise en arrière-plan |
| 10 | **Finitions V0.1** | `ADDING_CONTENT.md`, `CREDITS.md`, équilibrage, feedbacks visuels | Revue de la checklist du brief point par point |

---

## 10. Questions ouvertes (à trancher avant l'étape 0)

1. **Orientation** : paysage (proposé, plus confortable pour une carte iso) ou portrait ?
2. **Version de Godot** : 4.4+ proposé (TileMapLayer, GDScript typé) — une version imposée ?
3. **Monnaies** : coquillages seuls en V0.1, ou aussi des perles (gagnées en jeu uniquement) ?
4. **Langue** : interface en français seulement, ou FR + EN dès la V0.1 ?
5. **Direction artistique** : placeholders géométriques suffisants pour la V0.1, ou un style cible à respecter dès maintenant ?
