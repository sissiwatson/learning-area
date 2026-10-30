# Transition progressive vers la 3D — architecture, faisabilité, prototype

> Statut : **proposition technique à valider.** Aucune scène du jeu n'est
> modifiée et la refonte 3D n'est pas commencée. Direction artistique :
> `ART_DIRECTION.md` ; décoration : `DECORATION.md`.

## 1. Recommandation en bref

1. **Garder le cœur métier tel quel.** Économie, réservations, productions,
   quêtes, progression, sauvegarde et la majorité des tests ne dépendent pas
   du rendu.
2. **Faire passer le jeu par un contrat de présentation** (`IslandView`),
   d'abord implémenté par la 2D actuelle, sans changement visible. Une
   implémentation 3D vient ensuite se brancher à côté.
3. **Valider d'abord un prototype 3D isolé**, en deux parties :
   - un prototype **technique**, que je peux réaliser : performances,
     caméra, tactile, intérieur, décoration, dialogue ;
   - une validation **artistique** sur un personnage et un bâtiment « héros »
     au niveau de qualité visé. Elle demande un ou une artiste 3D, ou des
     ressources achetées (§6).
4. **Décision « on y va / on n'y va pas »** après la recette Android du
   prototype, sur des critères chiffrés (§7).

## 2. Inventaire : ce qui se réutilise, ce qui est lié à la 2D

### Réutilisable sans changement

| Couche | Contenu | Taille |
|--------|---------|--------|
| Logique pure (`src/core`) et autoloads | portefeuille, inventaire, logements, réservations, productions, chantiers, progression, quêtes, dialogues, validation des données, sauvegarde et migrations | environ 2 300 lignes |
| Données (`data/`) | bâtiments (rôles, recettes, coûts), réservations, quêtes, dialogues, réglages d'équilibrage | — |
| Grille logique de la carte | `MapDef` (plan 32×32, zones), emplacements des bâtiments, emprises, chemins d'arrivée, positions des personnages : ce sont des **cases**, pas des pixels | — |
| Interface (`scenes/ui`) | panneaux, barre de ressources, bandeau, messages, dialogues : des `Control` qui s'affichent au-dessus d'une scène 3D comme d'une scène 2D | environ 800 lignes |
| `TouchGestures` | reconnaissance tap, glisser, pincer, inertie, en coordonnées d'écran | 133 lignes |
| Tests | environ 230 tests sur 310 : logique, données, économie, sauvegarde, anti-blocage, recette de stabilité de l'économie | — |

### Lié à la 2D (à remplacer par un équivalent 3D)

| Composant | Pourquoi | Équivalent 3D |
|-----------|----------|---------------|
| `WorldMap` (`TileMapLayer` isométrique 128×64, décor) | tuiles 2D | terrain en maillages, eau, végétation en `MultiMesh` |
| `BuildingView` (sprite, test de toucher par transparence des pixels) | image 2D | modèle 3D, toucher par rayon sur la grille et des volumes simples |
| `NpcView`, `ArrivalAnimation`, `FloatingReward`, `LockBadge` | `Node2D`, positions en pixels | personnages animés, bateau, étiquettes ancrées à des points 3D |
| `MapCamera` et `CameraRig` (zoom et déplacement en pixels d'écran) | `Camera2D` | caméra isométrique 3D : point visé, rotation, zoom ; la logique d'inertie et de limites se transpose |
| Champs visuels des définitions (`texture`, `texture_anchor`, `stage_textures`, `sprite`, `sprite_anchor`) | images 2D | ressource visuelle séparée (§3) |
| Environ 80 tests sur 310 (13 fichiers) | ils touchent la scène 2D (positions à l'écran, sprites) | réécrits contre le contrat `IslandView` |
| `tools/visual_checks` | captures de la scène 2D | scénarios 3D équivalents |

### Ce que la sauvegarde contient

Uniquement de l'**état métier** (soldes, logements, minuteurs, quêtes…),
aucune donnée d'affichage. Changer de rendu ne demande **aucune migration**.
Les ajouts liés à la 3D (aménagements, réglages de caméra) arriveront par
une nouvelle version de format, avec une migration testée.

## 3. Architecture cible

```
data/  ─►  src/core (logique pure, inchangée)  ─►  autoloads (GameState, EventBus…)
                                                        │
                                   scenes/main.gd  ◄────┘   (ne connaît que le contrat)
                                        │
                     ┌──────── IslandView (contrat) ────────┐
                     │                                      │
              Island2D (existant adapté)            Island3D (nouveau)
              TileMapLayer, sprites                 maillages, personnages, eau
                     │                                      │
                     └──── CameraRig commun (logique) ──────┘
                           + TouchGestures (inchangé)
```

- **Contrat `IslandView`** : uniquement ce dont `main.gd` et le directeur de
  quêtes se servent aujourd'hui.
  - Signaux : bâtiment touché, personnage touché, sol touché.
  - Méthodes : `focus_building`, `play_arrival`, `float_reward`,
    `set_attention`, `refresh_production_visuals`, `screen_position_of(uid)`
    (pour ancrer l'interface), `set_story_marker`.
- **Caméra** :
  - La logique (point visé, zoom, limites, inertie) devient indépendante de
    la projection.
  - Le 3D ajoute la rotation (geste à deux doigts, ou boutons, calé par pas
    de 90°).
  - Le toucher sur un bâtiment se calcule par **rayon vers le plan du sol,
    puis case de la grille**. C'est du calcul pur, testable sans écran, sans
    moteur physique.
- **Visuels en données** :
  - `BuildingVisualDef` et `CharacterVisualDef` : modèle (`PackedScene`),
    portraits par expression.
  - Ils sont référencés à côté des champs 2D, qui restent pendant la
    transition ; `DataValidator` vérifie que chaque bâtiment a un visuel
    pour le rendu actif.
- **Vie de l'île** :
  - La logique des personnages (emploi du temps, destination, chemin sur
    les cases) vit dans `src/core`.
  - La 2D et la 3D ne font qu'**afficher**. Le lot V1b de la V0.2 peut donc
    être développé maintenant sans être perdu.
- **Intérieurs** :
  - `RoomDef` et le modèle de décoration (`DECORATION.md`) sont purs.
  - La scène d'intérieur se charge en arrière-plan
    (`ResourceLoader.load_threaded_request`) pendant le fondu de transition.
- **Préparé pour un futur marché communautaire** :
  - documents d'aménagement autonomes et versionnés ;
  - identifiants de catalogue stables ;
  - auteur, licence et empreinte ;
  - validation à l'import (`DECORATION.md` §6).

## 4. Adaptations dans Godot 4.4.1

| Sujet | Choix proposé | À vérifier par le prototype |
|-------|---------------|-----------------------------|
| Rendu | **Mobile** (Vulkan), déjà configuré dans le projet | proportion d'appareils sans Vulkan ; repli vers le rendu Compatibilité (OpenGL ES 3) et différences d'aspect |
| Éclairage | 1 soleil avec ombres sur une distance courte ; éclairage précalculé (`LightmapGI`) pour les intérieurs et les bâtiments fixes ; ciel en dégradé | coût des ombres ; prise en charge du précalcul selon le rendu |
| Résolution 3D | rendu 3D à résolution réduite (`scaling_3d_scale` 0,75, FSR 1), interface à pleine résolution | netteté perçue sur votre téléphone |
| Végétation | `MultiMeshInstance3D`, niveaux de détail automatiques à l'import, distances de visibilité | coût de la transparence des feuilles (surdessin) |
| Eau | shader stylisé maison (dégradé de profondeur, écume, vaguelettes de sommets), sans réfraction | coût en pixels sur tout l'écran |
| Personnages | glTF depuis Blender ; squelette ; formes faciales pour les expressions ; `AnimationTree` | nombre de personnages animés visibles |
| Textures | compression ETC2/ASTC (déjà activée), atlas | mémoire |
| Format des ressources | glTF 2.0 (`.glb`) ; pas d'import `.blend` direct (Blender n'est pas disponible dans mon environnement) | — |
| Version de Godot | rester en 4.4.1 (figée) ; changer de version seulement pour une raison mesurée | — |

## 5. Risques Android

| Risque | Gravité | Parade |
|--------|---------|--------|
| **Production des ressources 3D au niveau visé** (personnages semi-réalistes expressifs) | **élevée** | §6 : décision sur la source ; prototype artistique limité à 1 personnage et 1 bâtiment |
| Fluidité (surdessin de la végétation, eau plein écran, ombres) | élevée | budgets d'`ART_DIRECTION.md` §12, résolution 3D réduite, mesures sur l'appareil à chaque étape |
| Surchauffe et batterie sur une session de 15 min | moyenne | limiter à 30 images/s par défaut ; mesurer la baisse de fluidité dans le temps |
| Mémoire et temps de chargement | moyenne | chargement en arrière-plan, textures compressées, déchargement des intérieurs |
| Taille de l'application (27 Mo aujourd'hui) | moyenne | atlas, compression ; surveillance à chaque APK |
| Pilotes Vulkan instables sur certains appareils | moyenne | tests sur plusieurs appareils avant toute diffusion ; repli Compatibilité |
| Commandes tactiles de décoration trop complexes | moyenne | règles du §9 d'`ART_DIRECTION.md`, test d'utilisabilité pendant la recette |
| Tests automatiques du rendu 3D | faible | logique testée sans écran ; captures sous Xvfb en rendu Compatibilité (pas le rendu Mobile) ; fluidité mesurée sur appareil seulement |

**Information nécessaire** : le modèle de votre téléphone (et, si possible,
d'un second appareil plus modeste), pour fixer les budgets.

## 6. Faisabilité du prototype et compromis

**Ce que je peux faire** :
- le code (caméra, tactile, intérieur, décoration, transition, dialogues) ;
- les shaders (eau, végétation, ciel) ;
- la composition des scènes, le mesureur de performances intégré ;
- les tests et les APK.

**Ce que je ne peux pas produire seul au niveau visé** : des personnages 3D
semi-réalistes expressifs, des bâtiments et meubles détaillés, des portraits
illustrés. Je n'ai pas d'outil de modélisation ici ; je peux seulement
générer des formes simples depuis Godot.

Options pour les ressources du prototype :

| Option | Qualité | Coût | Remarques |
|--------|---------|------|-----------|
| A. Formes simples générées (blocs, cylindres) | maquette grise | nul | suffit pour mesurer caméra, tactile et décoration ; ne montre pas le style |
| B. Ressources libres CC0 (packs de nature, de meubles et de personnages stylisés) | correcte, style hétérogène, souvent « low poly » | nul | licences à vérifier une par une et à lister dans `CREDITS.md` ; rarement semi-réaliste |
| C. Personnages générés par un outil de création d'humains (export libre de droits), puis stylisés | proportions naturelles | temps de retouche | expressions et vêtements limités ; vérifier la licence de l'outil |
| D. Artiste 3D (commande) ou ressources achetées sous licence commerciale | conforme à la direction | budget | seule voie fiable pour la qualité « héros » ; je prépare le cahier des charges et intègre |

**Recommandation** :
- prototype technique avec **A + B** ;
- en parallèle, **une commande D limitée** (Hina et le Bungalow Hibiscus)
  pour valider l'identité visuelle ;
- portraits obtenus par rendu des modèles 3D avec expressions, puis retouche
  (option B d'`ART_DIRECTION.md` §8).

**Isolation du prototype** (« ne pas casser la V0.1 ») :
- Recommandé : un dossier `prototypes/poc3d/` dans le même projet, avec
  - sa scène principale ;
  - son propre préréglage d'export (identifiant `fr.islandconcierge.poc3d`,
    installable **à côté** du jeu) ;
  - le dossier exclu de l'export du jeu ;
  - aucune écriture dans la sauvegarde du jeu.
- Garde-fous :
  - les 310 tests restent verts ;
  - le contenu de l'APK du jeu est vérifié sans fichier du prototype.
- À vérifier en P0 : qu'un préréglage peut lancer une autre scène principale.
  Sinon, solution de repli : un projet Godot séparé, plus étanche mais qui
  copie les scripts réutilisés.

## 7. Prototype : étapes testables et critères d'acceptation

Chaque étape donne un commit et des tests ; les étapes marquées 📱 donnent
un APK du prototype pour votre recette. Le prototype affiche en permanence
un **mesureur** : images par seconde, temps par image, mémoire, appels de
dessin.

| Étape | Contenu | Critères d'acceptation |
|-------|---------|------------------------|
| **P0** Préparation | décisions du §9 ; dossier isolé ; préréglage d'export séparé ; mesureur | APK du jeu inchangé (même liste de fichiers hors version) ; 310 tests verts ; APK du prototype installable à côté du jeu |
| **P1** Extérieur 📱 | terrain de la grille de Mahana (une partie), lagon (shader), plage, végétation, Bungalow Hibiscus (maquette ou ressource libre), lumière de fin d'après-midi | 30 images/s stables pendant 10 min sur votre téléphone ; mémoire < 500 Mo ; lancement < 5 s ; votre avis sur l'ambiance |
| **P2** Caméra isométrique | déplacement, pincement, rotation par pas de 90° (deux doigts ou boutons), limites, inertie ; toucher → case → bâtiment | tests sans écran : calculs de la caméra et du toucher (mêmes cas que la caméra 2D actuelle) ; sur appareil, aucun geste mal interprété sur 20 essais |
| **P3** Personnages 📱 | Hina, Kimo, 2 voyageurs : attente, marche sur un chemin de cases, une expression jouée | logique de déplacement testée ; 4 personnages animés sans perte de fluidité ; lisibles au zoom par défaut |
| **P4** Intérieur et transition | entrer et sortir du bungalow (fondu < 1 s, chargement en arrière-plan), chambre, caméra en orbite, murs en coupe | aucun gel de l'image pendant la transition ; aller-retour 20 fois sans hausse de mémoire |
| **P5** Décoration libre 📱 | 5 meubles : sélectionner, déplacer sur la grille, pivoter de 45°, annuler ; refus de chevauchement et de porte bloquée | règles de placement testées (modèle pur DEC1) ; sur appareil, placer 5 meubles en moins de 2 min sans aide |
| **P6** Styles en un toucher | 2 styles (par exemple « Écolodge naturel » et « Hibiscus coloré ») : aperçu, devis, application, retouche | le devis est égal à la somme des objets ; styles et mode libre donnent les mêmes effets ; aller-retour de sauvegarde identique |
| **P7** Dialogue | bulle et portrait illustré avec 2 expressions, dialogue de Hina dans la chambre | lisible sur téléphone ; réutilise la boîte de dialogue existante |
| **P8** Bilan 📱 | recette complète du prototype, mesures, rapport | rapport avec mesures réelles ; décision **on y va / on ajuste / on reste en 2D** |

## 8. Après le prototype (si décision positive)

| Étape | Contenu | Garde-fou |
|-------|---------|-----------|
| M1 | Contrat `IslandView` et adaptation de la 2D | **aucun changement visible** ; tous les tests verts ; tests de scène réécrits contre le contrat |
| M2 | Logique de la vie de l'île dans `src/core` (sert à la 2D comme à la 3D) | tests sans écran |
| M3 | `Island3D` à parité avec la V0.1 (tous les bâtiments, quêtes, arrivée, productions), choisie dans les Réglages | mêmes scénarios de recette en 2D et en 3D ; sauvegarde commune |
| M4 | 3D par défaut après recette Android | la 2D reste disponible une version de plus (repli) |
| M5 | Retrait de la 2D | suppression des tests 2D remplacés |

### Interaction avec la V0.2 (ordre proposé)

1. **0.1.6 « Rythme »** (`PACING_AND_SPEEDUPS.md`) : logique et interface,
   indépendantes du rendu.
2. **V0.2 jalon 0** (sauvegarde v2, mesures, Réglages) : indépendant du rendu.
3. **V0.2 jalon 1, introduction** :
   - la scène est décrite **en termes logiques** (bâtiment visé, case,
     personnage, réplique, carte), jamais en pixels ;
   - mise en scène en 2D pour l'APK de recette ;
   - si la 3D est adoptée, seule la mise en scène sera refaite, pas le
     contenu.
4. **Prototype 3D P0 à P8**, puis décision.
5. **V0.2 jalons 3 et 4** (marché, paniers, expériences, carnet) : surtout
   de la logique et de l'interface, peu exposés au changement de rendu.
6. **V0.2 jalon 2** (vie de l'île) **après la décision** : sa logique peut
   avancer avant, mais son affichage se fera dans le rendu retenu, pour ne
   pas le faire deux fois.

## 9. Décisions à prendre avant P0

1. Source des ressources du prototype (§6 : A + B, et une commande D limitée ?).
2. Modèle de votre téléphone (et d'un second appareil si possible).
3. Rotation de caméra : par pas de 90° (proposé) ou libre ?
4. Mode de production des portraits (`ART_DIRECTION.md` §8).
5. Ordre proposé ci-dessus, en particulier le jalon 2 de la V0.2 déplacé après le prototype.
