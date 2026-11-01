# Prototype 3D indépendant — inventaire des ressources, composition, plan

> Statut : **proposition à valider avant réalisation**. Aucun achat, aucune
> modification du jeu existant. Complète `TRANSITION_3D.md` et
> `ART_DIRECTION.md`.

## 1. Ce que j'ai vérifié dans mon environnement (01/11)

| Moyen | Résultat | Conséquence |
|-------|----------|-------------|
| Sites des ressources (kenney.nl, quaternius.com, polyhaven.com, ambientcg.com, poly.pizza, itch.io, opengameart.org, mixamo.com, makehumancommunity.org) | **bloqués** par la politique réseau de l'environnement (refus du proxy), y compris en lecture web | je ne peux ni télécharger ni lire leurs pages ; licences vérifiées via les résultats de recherche citant les pages officielles (§2) |
| Dépôts GitHub publics | accessibles par Git ; à rattacher proprement à la session avant lecture | les créateurs qui publient sur GitHub (KayKit, avatars CC0, importeur VRM, MakeHuman/MPFB) sont utilisables |
| PyPI | accessible | **Blender 5.2.3 fonctionne ici sans écran** (module `bpy`) : modélisation par script et export glTF vérifiés |
| Godot 4.4.1 | importe le glTF nativement | chaîne Blender → glTF → Godot possible ici |
| Achat, compte Adobe, Epic ou Sketchfab | aucun (interdit) | Mixamo, Fab et Sketchfab exclus de mon côté |

**Point important** : avec Blender, je peux **modéliser moi-même** le décor
par script. C'est reproductible, d'origine connue, et les droits sont ceux du
projet. Les ressources libres complètent ce que je ne sais pas bien faire :
textures photographiques, personnages humains, animations.

## 2. Inventaire des ressources libres

Licence « vérifiée » = confirmée par la page officielle citée dans les
résultats de recherche. Je n'ai pas pu ouvrir la page moi-même, car le site
est bloqué. Chaque fichier intégré sera revérifié à la source et inscrit
dans les crédits du prototype.

| Source | Licence | Contenu utile | Style | Accès d'ici | Usage proposé |
|--------|---------|---------------|-------|-------------|---------------|
| **Poly Haven** | CC0 (FAQ officielle : « tout usage, y compris commercial ») | ciels HDRI, textures (bois, sable, pierre, chaume), quelques plantes | réaliste | ❌ bloqué | ciel et textures de matières, simplifiés par un shader stylisé |
| **ambientCG** | CC0 (plusieurs sources concordantes, page officielle non lue) | textures (bois, rotin, tissus, sable) | réaliste | ❌ bloqué | textures du bungalow et des meubles |
| **Quaternius** | CC0 pour les packs anciens ; **attention** : une « Quaternius Asset Licence (QAL v1.0) » s'appliquerait aux nouvelles sorties, et je n'en ai pas trouvé le texte | *Stylized Nature MegaKit* (CC0, plus de 110 modèles, glTF) ; *Universal Base Characters* (CC0, 6 personnages dont des proportions « Regular ») ; *Universal Animation Library* | stylisé, propre | ❌ bloqué | végétation complémentaire, base d'animations ; licence vérifiée pack par pack |
| **Kenney** | CC0 | *Nature Kit* (étiqueté « palm »), *Pirate Kit* (arbres, pontons), *Furniture Kit* | low poly très simple | ❌ site bloqué (dépôts « starter kits » sur GitHub, licence à vérifier) | éléments secondaires seulement : trop géométrique pour la direction artistique |
| **KayKit (Kay Lousberg)** | CC0, dépôts officiels GitHub | *Furniture Bits* (plus de 50 meubles, optimisés mobile) | low poly arrondi | ✅ GitHub | meubles de la chambre en attendant les miens |
| **100Avatars / Open Source Avatars** | CC0 par collection (vérifier chaque avatar dans le registre) | centaines d'avatars VRM **avec expressions faciales** | stylisé, souvent low poly | ✅ GitHub | voyageurs secondaires ; test technique des expressions |
| **godot-vrm (V-Sekai)** | MIT | importeur VRM pour Godot 4 : expressions (humeur, visèmes), shader MToon | — | ✅ GitHub | lire les avatars VRM et leurs expressions |
| **MakeHuman / MPFB** | ressources de base CC0 ; modèles exportés CC0 selon la FAQ officielle | humains aux **proportions naturelles**, squelette, morphologies variées | réaliste neutre | code ✅ GitHub ; packs de cheveux et de vêtements ❌ (site bloqué) | base de Hina et Kimo, stylisée par les matériaux et retouchée par script |
| **Blender (`bpy`)** | outil GPL ; ce qu'on produit appartient au projet | modélisation, matériaux, précalcul, export glTF | — | ✅ PyPI, testé | bungalow, pontons, palmiers, plantes, fleurs, meubles, intérieur |
| **Mixamo** | gratuit avec compte Adobe ; usage en jeu permis, pas de redistribution des fichiers bruts | animations, personnages | réaliste | ❌ compte requis | exclu de mon côté ; possible si vous téléchargez vous-même |
| **Sketchfab (CC-BY)** | attribution obligatoire, licence par modèle | très variable | variable | ❌ bloqué et compte requis | non retenu |
| Générateurs IA (« modèles communautaires CC0 ») | droits et originalité incertains | — | — | — | **exclu**, sauf décision explicite de votre part |
| Reallusion (bases gratuites) | contrat propriétaire, pas CC0 | 150 expressions faciales | réaliste | — | non retenu (licence à étudier) |

**Ce qu'aucune ressource libre ne fournit** :
- un personnage **semi-réaliste stylisé, expressif et original**, au niveau
  de la direction artistique ;
- les **portraits illustrés**.

Le prototype pourra montrer la direction (proportions, lumière, couleurs,
expressions de base), mais **pas la qualité finale de Hina**. Celle-ci
demandera un ou une artiste, ce qui implique une décision de budget plus
tard. Je le dis dès maintenant pour que la validation artistique porte sur
le bon objet.

## 3. Composition de la scène de démonstration

Un coin de Mahana d'environ 60 × 40 m, en **fin d'après-midi dorée**.

```
            horizon : motus lointains, ciel en dégradé, soleil bas
   ~~~~~~~~~~~~~~~~~~~~~~ océan bleu profond ~~~~~~~~~~~~~~~~~~~~~~~
   ~~~~~~~~~~~~ récif (écume) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   ~~~~~~~~ lagon turquoise ~~~~~~~ [BUNGALOW HIBISCUS sur pilotis] ~~
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  terrasse, hamac, échelle ~~~~~
   ~~~~~ ponton privé + kayak ~~~~~~~~~~~ ║ ponton principal ║ ~~~~~
   ..... plage en croissant, sable clair, vaguelettes, coquillages .....
   cocotiers penchés vers la mer · pandanus · hibiscus rouges · frangipaniers
   sentier de sable → atelier de Kimo (arrière-plan) · fougères · rochers
```

| Élément | Contenu | Fabrication |
|---------|---------|-------------|
| **Lagon** | dégradé de profondeur (turquoise clair → bleu lagon → océan), reflets doux, écume animée sur le rivage et au récif, vaguelettes | shader maison (profondeur lue dans une carte précalculée : pas de lecture de profondeur coûteuse sur mobile) |
| **Plage** | croissant de sable clair, transition humide vers l'eau | maillage Blender + shader |
| **Bungalow Hibiscus** | sur pilotis, plancher de bois, murs clairs, **toit en feuilles de pandanus** (épaisseur, bords irréguliers), porte et fenêtres, terrasse avec hamac, échelle vers l'eau, lanterne | Blender par script, matériaux stylisés |
| **Pontons** | ponton principal plage → bungalow, ponton privé, poteaux, cordages, kayak | Blender |
| **Végétation** | 8 à 12 cocotiers penchés (3 variantes, palmes qui ondulent au vent), pandanus, buissons d'hibiscus fleuris, frangipaniers, fougères, touffes d'herbe | Blender (palmes en cartes à transparence), `MultiMesh`, shader de vent |
| **Arrière-plan** | silhouette de l'atelier de Kimo, motus lointains, oiseaux | Blender, éléments simples |
| **Personnages** | **Hina** sur la terrasse (attente, salut, 3 expressions : sourire, surprise, réflexion) ; **Kimo** sur le ponton avec une corbeille ; **2 voyageurs** (arrivée avec valise, détente sur la terrasse) | MakeHuman/MPFB ou avatars VRM (§2), animations libres |
| **Lumière** | soleil chaud et bas, ombres douces, ciel en dégradé, légère brume de chaleur à l'horizon, lumière d'ambiance bleutée | réglages Godot (rendu Mobile) |
| **Chambre** | 4 × 5 m : lit en rotin avec moustiquaire, table de chevet, lampe tressée, fauteuil, plante, tapis, ventilateur de plafond, fenêtre sur le lagon | Blender (ou KayKit en attendant) |
| **Meubles déplaçables** | 5 : fauteuil, table de chevet, lampe, plante, tapis ; grille de 50 cm, rotation par 45°, pas de chevauchement | logique pure testée (modèle DEC1 de `DECORATION.md`) |

**Caméra** :
- vue isométrique (environ 40°), glisser pour se déplacer, pincer pour zoomer ;
- **rotation par pas de 90°**, par deux boutons ou par un geste à deux doigts ;
- toucher le bungalow puis « Entrer » : fondu court vers la chambre ;
- dans la chambre, orbite autour de la pièce et murs en coupe.

## 4. Organisation (sans toucher au jeu)

- **Projet Godot séparé** `prototype-3d/` à la racine du dépôt, avec :
  - son propre identifiant Android (`fr.islandconcierge.demo3d`), installable
    **à côté** du jeu ;
  - aucun fichier du jeu modifié ;
  - les 354 tests du jeu restent la référence.
- **Ressources reproductibles** :
  - les scripts Blender qui fabriquent les modèles sont versionnés
    (`prototype-3d/art_src/*.py`), et les fichiers glTF sont régénérables ;
  - chaque ressource tierce est listée dans `prototype-3d/CREDITS.md`
    (source, licence, date de vérification).
- **Mesureur intégré**, affichable par un bouton : images par seconde, temps
  par image, mémoire, appels de dessin. C'est vous qui lirez les chiffres
  sur votre téléphone.

## 5. Plan de réalisation et deux validations distinctes

| Étape | Contenu | Validation technique (📱 Android) | Validation artistique (votre regard) |
|-------|---------|-----------------------------------|--------------------------------------|
| **D0 · Préparation** | projet séparé, export Android, mesureur, acquisition des ressources autorisées (§6) | APK de démonstration qui s'installe à côté du jeu ; jeu inchangé | — |
| **D1 · Le lagon et le bungalow** 📱 | terrain, lagon, plage, ciel, lumière, bungalow, pontons, végétation, arrière-plan ; caméra fixe puis orbite simple | 30 images/s stables pendant 10 min, mémoire < 500 Mo, lancement < 8 s | **première impression** : ambiance, couleurs, eau, végétation, bungalow (grille §5 bis) |
| **D2 · Caméra isométrique** | déplacement, zoom, rotation par 90°, limites, toucher d'un bâtiment | aucun geste mal interprété sur 20 essais ; calculs testés sans écran | lisibilité à chaque angle |
| **D3 · Hina et les habitants** 📱 | Hina (3 expressions, attente, salut), Kimo, 2 voyageurs qui marchent | 4 personnages animés sans perte de fluidité | proportions, expressivité, cohérence avec le décor |
| **D4 · La chambre** 📱 | entrer/sortir (fondu, chargement en arrière-plan), chambre, orbite, murs en coupe, 5 meubles déplaçables et pivotables ; dialogue de Hina avec portrait (rendu du modèle 3D) | aller-retour 20 fois sans hausse de mémoire ; placer 5 meubles en < 2 min | confort et charme de la chambre ; plaisir de décorer |
| **D5 · Bilan** | mesures réelles, écarts avec la direction artistique, cahier des charges pour un ou une artiste si nécessaire | rapport chiffré | décision : migration, ajustements, ou non |

Je vous livre un **APK après D1** (le décor), puis après D3 et D4. Vous
jugez le rendu dès la première scène, sans attendre la fin.

### 5 bis. Grille de validation artistique (à remplir à chaque APK)

Notes de 1 à 5, avec un commentaire libre :
- lagon ;
- lumière ;
- végétation ;
- bungalow ;
- personnages ;
- intérieur ;
- impression générale : « donne envie d'y passer ses vacances » ;
- respect de l'identité : original, pas une copie.

## 6. Ce dont j'ai besoin de votre part

1. **Accès réseau (recommandé)** : autoriser, dans les réglages réseau de
   l'environnement, au minimum :
   - `polyhaven.com` et `dl.polyhaven.org` (ciels, textures) ;
   - `ambientcg.com` ;
   - `quaternius.com` ;
   - `makehumancommunity.org` (cheveux et vêtements CC0 pour Hina et Kimo).

   Sans cela, je fais tout avec Blender et GitHub. Le décor reste faisable ;
   les personnages seront plus pauvres.
2. **Autre option** : vous téléchargez vous-même certains packs (par exemple
   *Stylized Nature MegaKit*, un ciel Poly Haven) et vous les ajoutez au
   dépôt ; je vérifie la licence de chaque fichier.
3. **Accord pour rattacher en lecture** les dépôts GitHub publics :
   - `KayKit-Game-Assets/KayKit-Furniture-Bits-1.0` ;
   - `V-Sekai/godot-vrm` ;
   - `toxsam/open-source-avatars` ;
   - `makehumancommunity/mpfb2`.
4. **Le modèle de votre téléphone**, pour les objectifs de performance.
5. **Validation de cette proposition** : composition, projet séparé, ordre
   D0 à D5. Le lot 3 de la 0.1.6 reste en attente comme convenu.
