# Direction artistique — 3D tropicale stylisée

> Statut : **proposition à valider.** Personnages : `NARRATIVE.md` §3 fait foi. Aucune scène du jeu n'est modifiée ; la
> faisabilité et le prototype sont décrits dans `TRANSITION_3D.md`.

## 1. Intention

Une île **lumineuse, chaleureuse, élégante et vivante**, en **3D stylisée
semi-réaliste** (pas de photoréalisme). On veut un monde où l'on a envie de
passer ses vacances, et des personnages auxquels on s'attache.

- **Environnements** : la richesse et la générosité des décors tropicaux,
  telles qu'on les trouve dans des jeux comme *Coral Island*.
- **Personnages** : des proportions naturelles, des expressions et des
  interactions quotidiennes lisibles, comme dans *Les Sims 4*.
- **Identité propre** : ces jeux sont des **repères d'ambiance**, jamais des
  modèles à reproduire (voir §11).

On abandonne progressivement le style actuel, géométrique et proche des
figurines.

> **Images de référence** : les deux images annoncées dans votre message ne
> me sont pas parvenues (aucune pièce jointe visible dans cette session).
> Merci de les renvoyer. Si elles proviennent de jeux commerciaux, elles
> restent un tableau d'ambiance privé : elles ne sont ni intégrées au jeu,
> ni versionnées dans un dépôt public.

## 2. Piliers visuels

| Pilier | Ce qu'il veut dire à l'écran |
|--------|------------------------------|
| **Chaleur** | lumière dorée, ombres douces et colorées (jamais noires), matériaux naturels (bois, fibres, pierre corallienne) |
| **Lisibilité** | sur un téléphone, on reconnaît chaque bâtiment, personnage et état en un coup d'œil : silhouettes nettes, contrastes de valeurs, pastilles d'état |
| **Vie** | quelque chose bouge toujours à l'écran (palmes, vagues, habitants, oiseaux), sans surcharge |
| **Élégance** | palette maîtrisée, peu de saturation criarde, interface sobre |
| **Respect culturel** | univers polynésien fictif (Mahana), inspiré sans caricature ; aucun motif sacré utilisé comme décoration (relecture prévue par `NARRATIVE.md`) |

## 3. Rendu et matériaux

- Formes **légèrement simplifiées et arrondies** : pas de détails
  microscopiques, des volumes généreux.
- Textures **peintes à la main ou simplifiées** : couleur de base plus
  rugosité, sans cartes complexes ; un atlas partagé par famille d'objets.
- Ombrage **réaliste mais doux** : éclairage précalculé là où c'est possible,
  occlusion ambiante, pas de contours noirs.
- **Eau** : dégradé de profondeur (turquoise clair vers bleu profond),
  écume animée sur le rivage, reflets stylisés. Pas de réfraction coûteuse
  sur mobile.
- **Végétation** : cocotiers, pandanus, hibiscus, frangipaniers, arbres à
  pain, fougères ; balancement léger au vent (shader de sommets).

## 4. Palette (proposition)

| Rôle | Couleurs |
|------|----------|
| Lagon | turquoise clair `#5FD3C6` → bleu lagon `#1E9BB0` → océan `#145A7A` |
| Sable et bois | sable `#F2DFB5`, bois clair `#C9A06B`, bois patiné `#8A6A4A` |
| Végétation | vert tendre `#7CC26B`, vert profond `#2F7A4A` |
| Accents | hibiscus `#E8445A`, frangipanier `#F7E6A0`, corail `#F08A6C` |
| Interface | crème `#FFF8EC`, texte `#22303A`, action `#1B8A9A` (le contraste de l'interface actuelle est conservé, ≥ 4,5:1) |

## 5. Lumière et moments de la journée

- Une lumière directionnelle chaude (soleil) avec ombres douces, un ciel en
  dégradé, une lumière d'ambiance bleutée venant du lagon.
- Quatre ambiances préréglées : matin, midi, fin d'après-midi (lumière
  dorée, pour les arrivées) et soirée (lanternes du tiki bar, pour les
  événements). Elles pourront plus tard suivre le calendrier D1.
- Sur mobile : un seul soleil avec ombres, lumières ponctuelles rares
  (lanternes) et éclairage précalculé pour les intérieurs.

## 6. Environnements et bâtiments

| Élément | Description |
|---------|-------------|
| **Bungalow Hibiscus** | sur pilotis au bord du lagon, toit en feuilles de pandanus, terrasse avec hamac, ponton privé, hibiscus rouges ; c'est le bâtiment « héros » du prototype |
| **Bungalow Corail** | plus grand (4 voyageurs), pierre corallienne et bois, côté Côte Est |
| **Bureau de conciergerie** | petite maison accueillante, enseigne au nom choisi par le joueur, tableau des réservations visible |
| **Atelier de Kimo** | auvent, établi, fibres qui sèchent, corbeilles empilées |
| **Plantation** | rangées d'ananas, outils, petite cabane |
| **Tiki bar** | bar en bambou sur la plage, lanternes, tabourets |
| **Étal de Malia** | sur le quai, paniers de fruits, tissus ombrageant |
| **Quai et pontons** | bateau de Tao, cordages, bouées |
| **Village** | maisons d'habitants, chemins de sable, potagers, linge qui sèche |

Échelle : 1 case de la grille logique actuelle = **2 m** dans le monde 3D
(à valider avec le prototype).

## 7. Personnages

- **Proportions naturelles** (environ 7 têtes), visages stylisés aux traits
  doux, grands yeux expressifs mais pas « manga ».
- **Diversité** : âges, corpulences, carnations, coiffures et styles
  vestimentaires variés, chez les habitants comme chez les voyageurs.
- **Expressions faciales** (formes du visage animées) : neutre, joie, rire,
  surprise, inquiétude, agacement, réflexion, tristesse.
- **Animations du quotidien** : marcher, attendre, parler avec gestes,
  porter un panier, s'asseoir, saluer, nager (voyageurs), travailler (Kimo
  tresse, Malia cuisine).

| Personnage | Silhouette et tenue (proposition) | Personnalité à l'écran |
|------------|-----------------------------------|------------------------|
| **Hina Tehani** | institutrice retraitée, la soixantaine, port droit, robe aux motifs floraux discrets, fleur d'hibiscus dans les cheveux | chaleureuse, exigeante, taquine (sourire en coin) |
| **Tao** | pêcheur et pilote du bateau, la trentaine, chemise délavée, casquette, mains marquées par la mer | calme, peu bavard, humour pince-sans-rire |
| **Malia** | cuisinière et commerçante, tablier coloré, foulard, bracelets | énergique, bavarde, généreuse mais dure en affaires |
| **Kimo** | artisan, la vingtaine, débardeur, fibres sur l'épaule, petites lunettes | perfectionniste, rêveur, timide ; s'anime en parlant de matières |
| **Voyageurs** | profils de `BOOKING_REQUESTS.md` : couples, familles, amis, voyageurs solo ; tenues de vacances variées | réactions visibles à l'accueil, au panier, au logement |

Tatouages, ornements et vêtements traditionnels : **aucun motif réel
copié**. Les éléments culturels suivent le processus de relecture de
`NARRATIVE.md`.

## 8. Portraits des dialogues

- Bustes **illustrés semi-réalistes**, lumière douce et cohérente,
  arrière-plan flou aux couleurs du lieu.
- **6 expressions au minimum** par personnage principal : neutre, joie,
  surprise, inquiétude, agacement, réflexion. Chaque réplique choisit son
  expression (champ ajouté à la ligne de dialogue).
- **Comment les produire** (décision à prendre, voir `TRANSITION_3D.md` §6) :
  - A. un illustrateur ;
  - B. des rendus des modèles 3D avec leurs expressions, retouchés
    (cohérence garantie, coût plus faible) ;
  - C. un outil génératif. C'est déconseillé sans vérification des droits
    et de l'originalité.

## 9. Caméras

**Mode Île**
- Vue 3D isométrique : inclinaison fixe d'environ 40°.
- Rotation par pas de 90° (deux boutons, ou rotation à deux doigts qui se
  cale sur le pas) ; une rotation libre reste une option à tester.
- Zoom par pincement (du village entier au bâtiment), glisser pour se déplacer.
- Mêmes règles de confort qu'aujourd'hui : limites de carte, inertie, tap
  précis (`TouchGestures` est réutilisé).

**Mode Intérieur**
- Orbite autour du centre de la pièce : glisser à un doigt pour tourner,
  pincer pour zoomer, double toucher pour recentrer.
- **Murs en coupe** : les murs face à la caméra s'abaissent automatiquement.
- En décoration, les gestes ne changent pas de sens :
  - toucher un meuble le sélectionne ;
  - le glisser le déplace, avec un aimant sur la grille ;
  - un bouton le fait pivoter de 45° ;
  - toucher le vide le désélectionne.
  - Jamais deux gestes différents pour la même action.

**Transition** : un fondu court (moins de 1 s) avec un zoom vers la porte
du logement ; le chargement de l'intérieur se fait pendant le fondu.

## 10. Interface

On garde le thème actuel (panneaux crème arrondis, contraste ≥ 4,5:1,
boutons ≥ 96 px de haut), enrichi :
- icônes illustrées ;
- miniatures des bâtiments dans les panneaux (lot U2) ;
- bulles de dialogue ancrées aux personnages 3D.

## 11. Originalité et droits

- Aucun asset, personnage, logo, texture, interface ou nom provenant de
  *Coral Island*, *Les Sims 4* ou d'un autre jeu.
- Pas de décalque ni de « refaire à l'identique ».
- Toute ressource tierce est listée dans `CREDITS.md` avec sa licence ;
  seules les licences compatibles avec un jeu commercial sont acceptées
  (CC0, licences commerciales achetées).
- Les références visuelles restent privées et servent à l'ambiance
  seulement.

## 12. Budgets techniques indicatifs (à confirmer par le prototype)

Hypothèses de départ pour un téléphone de milieu de gamme. **Aucune n'est
encore mesurée.**

| Élément | Budget de départ |
|---------|------------------|
| Personnage principal | 15 000 à 25 000 triangles, 1 texture 1024² (ou 2048² pour un héros), squelette d'environ 60 os, formes faciales pour les expressions |
| Voyageur ou habitant secondaire | 8 000 à 15 000 triangles, textures partagées par variantes |
| Bâtiment | 5 000 à 20 000 triangles, atlas partagé |
| Scène île visible à l'écran | moins de 300 000 triangles, moins de 150 appels de dessin |
| Personnages animés visibles | 10 à 15 au maximum |
| Mémoire totale | moins de 500 Mo sur l'appareil |
| Fluidité | 30 images/s stables (60 visées si l'appareil le permet) |
