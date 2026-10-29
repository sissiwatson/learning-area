# Découverte culturelle, personnages et missions narratives — conception

> Statut : **conception, non implémentée.** Lot de développement « N »
> (voir §10 et `docs/BACKLOG.md`). Scénario du tutoriel :
> [`SCENARIO_TUTORIEL.md`](SCENARIO_TUTORIEL.md).

Island Concierge est un jeu de gestion touristique qui fait aussi découvrir
l'histoire, le patrimoine, les traditions, les savoir-faire et la vie
quotidienne des territoires, à travers des personnages récurrents et des
missions narratives.

---

## 1. Principes éditoriaux

1. **Distinguer fait et fiction, toujours.** Chaque contenu culturel porte une
   nature explicite, visible par le joueur :

   | Nature | Signification | Sources |
   |--------|---------------|---------|
   | `FICTION` | Inventé pour le jeu (histoire de Mahana, ses fêtes, ses personnages) | aucune ; badge « Fiction du jeu » |
   | `INSPIRED` | Fiction inspirée d'une pratique réelle (ex. tressage de feuilles, navigation aux étoiles) | **obligatoires** pour la partie réelle, qui est séparée du récit |
   | `FACT` | Fait historique ou culturel réel | **obligatoires** |

2. **Sources fiables pour les lieux réels** (Zanzibar, Bali, Martinique…) :
   ouvrages universitaires, musées, archives, institutions patrimoniales
   (ex. UNESCO), offices culturels locaux. Chaque fiche `FACT`/`INSPIRED`
   référence au moins une source complète (auteur ou institution, titre,
   éditeur ou site, année, URL le cas échéant, date de consultation). Un test
   bloque toute fiche réelle sans source. **Aucune source n'est inventée** :
   tant qu'une source n'est pas vérifiée, la fiche reste en statut `DRAFT` et
   n'est pas livrée dans le jeu.
3. **Respect des cultures représentées** : pas de caricature, pas de
   pratiques sacrées utilisées comme simple décor ou mécanique de gain.
   Pour chaque destination réelle, relecture par des personnes du territoire
   ou des spécialistes, mentionnées dans `CREDITS.md`.
4. **Mahana est fictive**, mais son ambiance évoque les îles du Pacifique.
   Ses coutumes inventées ne doivent jamais être présentées comme des
   traditions polynésiennes réelles ; quand une mission s'appuie sur une
   pratique réelle du Pacifique, la fiche est `INSPIRED` et sa partie réelle
   est sourcée.
5. **Le contenu ne change pas les règles.** Personnages, dialogues, quêtes,
   destinations et fiches sont des données ; le moteur (conditions, effets,
   récompenses) est générique et testé une fois.

---

## 2. Destinations

| Destination | Nature | Statut |
|-------------|--------|--------|
| **Mahana** | Île fictive, histoire originale | V0.1 |
| Zanzibar, Bali, Martinique… | Inspirées de lieux réels, contenus sourcés | V0.3+ (à confirmer) |

### Mahana — éléments d'univers (fiction du jeu)

- Petite île volcanique entourée d'un lagon, au relief doux, avec une jungle à
  l'ouest et une côte est sauvage.
- Peuplée depuis des siècles par des familles de navigateurs et de
  cultivateurs ; aujourd'hui, environ quatre cents habitants vivent de la
  pêche, de la culture de l'ananas et des fruits, de l'artisanat et d'un
  tourisme encore discret.
- **Le panier de bienvenue** : coutume de l'île — tout visiteur reçoit des
  fruits du jardin de son hôte. C'est l'origine fictive du panier d'accueil
  de la boucle de jeu.
- **Le quai et son marché** : cœur de la vie quotidienne, où arrivent les
  bateaux et où l'on vend poisson, fruits et objets tressés.
- **La Fête des Lumières du Lagon** : festival annuel inventé, où les
  pirogues décorées de lanternes font le tour du lagon (événement saisonnier
  futur).
- **Le récif du Grand Banc** : protège l'île des houles ; sa santé est un
  enjeu (missions environnement).
- **La grande tempête** : il y a deux générations, une tempête a détruit une
  partie du village ; plusieurs bâtiments ont été reconstruits en bois flotté.
  Ce souvenir relie les personnages.

---

## 3. Personnages (PNJ)

Tous fictifs. Chacun a un rôle dans l'économie, une histoire, des dialogues,
des missions, un niveau de relation et des services à débloquer.

### Niveaux de relation (communs, configurables)

| Niveau | Nom | Points cumulés |
|--------|-----|---------------:|
| 0 | Inconnu | 0 |
| 1 | Connaissance | 10 |
| 2 | Voisin | 30 |
| 3 | Ami | 70 |
| 4 | Proche | 140 |
| 5 | Confident | 250 |

Les points viennent des missions, des dialogues et de l'usage des services.
**Un niveau atteint n'est jamais perdu** : pas de blocage irréversible.

La **relation** (personnelle, liée aux histoires) est distincte de la
**confiance propriétaire** (professionnelle, liée aux avis, voir
`REPUTATION.md` §3). Certains déblocages demandent l'une ou l'autre, avec
toujours un chemin alternatif.

### Hina Tehani — propriétaire, mentor du tutoriel

| | |
|---|---|
| Métier | Institutrice retraitée, propriétaire du **Bungalow Hibiscus** |
| Rôle économique | Première cliente de la conciergerie ; présente ensuite d'autres propriétaires |
| Personnalité | Chaleureuse, exigeante sur l'accueil, taquine, grande mémoire de l'île |
| Histoire | Le bungalow a été bâti par son grand-père en bois flotté après la grande tempête. Elle refuse de le voir devenir « une boîte à touristes » et cherche quelqu'un qui accueille les voyageurs comme on le faisait autrefois. |
| Missions | Tutoriel complet ; histoire et patrimoine (récits de la tempête, l'ancienne école) |
| Services | Niv. 2 : conseils d'accueil (bonus d'expérience) · Niv. 3 : présente le propriétaire du Bungalow Corail · Niv. 4 : récits du patrimoine (fiches) |

### Tao — pêcheur et guide maritime

| | |
|---|---|
| Métier | Pêcheur, pilote du bateau qui relie Mahana, guide du lagon |
| Rôle économique | Transport des voyageurs, poisson frais pour Malia, excursions |
| Personnalité | Calme, peu bavard, humour pince-sans-rire, d'une grande patience |
| Histoire | Fils de pêcheur, il a appris à lire la houle avec son oncle. Il s'inquiète du blanchissement du récif et rêve d'un tourisme qui protège le lagon. |
| Missions | Pêche et navigation, protection de l'environnement |
| Services | Niv. 1 : transport des voyageurs · Niv. 2 : excursion lagon (critère expérience) · Niv. 3 : sortie d'observation du récif · Niv. 4 : participation à la Fête des Lumières |

### Malia — cuisinière et commerçante

| | |
|---|---|
| Métier | Tient l'étal et la petite cantine du marché du quai |
| Rôle économique | Vend les produits locaux, achète les surplus de la plantation, cuisine pour les voyageurs |
| Personnalité | Énergique, bavarde, entrepreneuse, généreuse mais dure en affaires |
| Histoire | Elle a repris l'étal de sa tante et veut faire connaître la cuisine de l'île sans la transformer en folklore. |
| Missions | Marchés et produits locaux, cuisine et agriculture, festivals |
| Services | Niv. 1 : achat de produits · Niv. 2 : panier gourmand (panier d'accueil amélioré) · Niv. 3 : dîner chez Malia (critère expérience) · Niv. 4 : recettes (fiches) |

### Kimo — artisan et décorateur

| | |
|---|---|
| Métier | Artisan : bois flotté, tressage de feuilles, teintures végétales ; tient l'**atelier de produits d'accueil** |
| Rôle économique | Fabrique paniers tressés et objets de décoration ; conseille l'aménagement des logements |
| Personnalité | Perfectionniste, rêveur, timide, s'anime dès qu'il parle de matières |
| Histoire | Parti étudier les arts appliqués, revenu sur l'île pour reprendre l'atelier familial ; il cherche à concilier savoir-faire anciens et design contemporain. |
| Missions | Artisanat, décoration, rénovation |
| Services | Niv. 1 : paniers tressés · Niv. 2 : objets de décoration (critère confort) · Niv. 3 : rénovation d'un logement · Niv. 4 : pièces uniques (esthétique, photos) |

---

## 4. Missions culturelles

Chaque mission a : **prérequis**, **dialogue d'introduction**, **objectifs**,
**dialogue de conclusion**, **récompenses** (accordées une seule fois) et
éventuellement une **découverte culturelle** (fiche du carnet).

| Catégorie | Exemple à Mahana | PNJ | Découverte |
|-----------|------------------|-----|------------|
| Marchés et produits locaux | « Le marché du quai » : vendre 5 ananas à Malia | Malia | Le marché du quai (FICTION) |
| Cuisine et agriculture | « Le gâteau d'ananas » : récolter, fournir le sucre, goûter | Malia | La recette du gâteau d'ananas (FICTION) |
| Artisanat | « Tresser un panier » : apporter des feuilles, assister Kimo | Kimo | Le tressage des feuilles (INSPIRED, sourcé) |
| Pêche et navigation | « Lire la houle » : sortie à l'aube avec Tao | Tao | Naviguer aux étoiles (INSPIRED, sourcé) |
| Histoire et patrimoine | « La grande tempête » : retrouver trois photos anciennes | Hina | La grande tempête (FICTION) |
| Festivals et événements | « La Fête des Lumières » : décorer une pirogue | Tao, Kimo | La Fête des Lumières du Lagon (FICTION) |
| Protection de l'environnement | « Le Grand Banc » : nettoyer la plage, limiter les ancrages | Tao | Le récif du Grand Banc (FICTION) + fiche sur les récifs coralliens (FACT, sourcée) |

Les objectifs réutilisent les événements du jeu (`item_collected`,
`stay_completed`, `building_built`, `dialogue_finished`, `location_visited`…),
comme les quêtes du tutoriel.

---

## 5. Carnet de voyage

Collection de **fiches de découverte**, classées par destination, avec une
progression (ex. « Mahana 3/24 »).

| Champ | Description |
|-------|-------------|
| Titre | clé i18n |
| Destination | référence `DestinationDef` |
| Illustration | texture (originale ou sous licence compatible, créditée) |
| Texte | clé i18n ; pour `INSPIRED`, deux blocs séparés : récit du jeu / contexte réel |
| Nature | `FICTION`, `INSPIRED`, `FACT` (badge visible) |
| Sources | liste de références complètes (obligatoire hors `FICTION`) |
| Statut éditorial | `DRAFT` (non livré) ou `PUBLISHED` |
| Récompense | facultative (XP, coquillages, objet de décoration) |

Une fiche se débloque par une récompense de mission ou un événement (visite
d'un lieu, dialogue). Elle n'est débloquée qu'une fois et sauvegardée.

---

## 6. Architecture des données

Le contenu est **déclaratif** ; le moteur n'a pas à changer quand on ajoute un
PNJ, une quête, une fiche ou une destination.

### Définitions (`src/defs/narrative/`, données dans `data/`)

| Ressource | Champs principaux |
|-----------|-------------------|
| `DestinationDef` | `id`, `name_key`, `nature` (FICTIONAL / REAL), `map: MapDef`, `intro_key`, `sources[]` |
| `NpcDef` | `id`, `name`, `portrait`, `job_key`, `bio_key`, `traits[]`, `home_location`, `relationship_levels` (ou défaut commun), `services[]` |
| `NpcServiceDef` | `id`, `name_key`, `required_level`, effet (bonus de critère, recette, déblocage) |
| `DialogueDef` | `id`, `nodes[]` |
| `DialogueNodeDef` | `id`, `speaker` (PNJ ou joueur), `text_key`, `choices[]`, `next`, `effects[]` |
| `DialogueChoiceDef` | `text_key`, `conditions[]`, `effects[]`, `next` |
| `NarrativeQuestDef` | `id`, `category`, `giver` (PNJ), `prerequisites[]`, `intro_dialogue`, `objectives[]`, `outro_dialogue`, `rewards[]`, `discovery` |
| `ObjectiveDef` | `event`, `target`, `amount` |
| `ConditionDef` | `type` (quest_completed, quest_active, relationship_at_least, flag_set, level_at_least, reputation_at_least, item_at_least, discovery_unlocked), `ref`, `value` |
| `EffectDef` / `RewardDef` | `type` (currency, xp, item, relationship, flag, start_quest, unlock_discovery, unlock_service), `ref`, `amount` |
| `DiscoveryDef` | voir §5 |
| `SourceRef` | `author`, `title`, `publisher`, `year`, `url`, `accessed_on` |

Les textes sont des clés de traduction ; les dialogues ont leur propre fichier
(`i18n/dialogues.csv`) pour faciliter le travail d'écriture et de traduction.

### Moteur (logique pure, `src/core/narrative/`)

| Classe | Rôle |
|--------|------|
| `ConditionEvaluator` | évalue une liste de conditions sur l'état de partie (lecture seule) |
| `EffectApplier` | applique effets et récompenses via `GameState`, **une seule fois** par identifiant d'octroi (`quest:<id>`, `dialogue:<id>:<nœud>`) |
| `DialogueRunner` | parcourt un dialogue : nœud courant, choix disponibles, avance, fin |
| `QuestLog` | quêtes disponibles / actives / terminées, progression par événements, octroi des récompenses |
| `Relationships` | points et niveaux par PNJ, niveau jamais perdu |
| `TravelJournal` | fiches débloquées, progression par destination |

État sauvegardé : flags, quêtes (état, progression, récompenses octroyées),
relations, fiches débloquées, dialogues déjà vus. Signaux `EventBus` :
`dialogue_started/finished`, `quest_available/started/progressed/completed`,
`relationship_changed`, `discovery_unlocked`.

### Intégration avec l'existant

- Les quêtes guidées du plan (étape « Progression et quêtes ») deviennent des
  `NarrativeQuestDef` données par Hina : un seul système de quêtes.
- `LodgingDef.owner_name` deviendra une référence `owner: NpcDef` (Hina pour
  le Bungalow Hibiscus).
- Les services des PNJ produisent des **faits de séjour** (excursion de Tao,
  dîner chez Malia, décoration de Kimo) pris en compte par les règles de
  réputation, sans calcul aléatoire.
- Interface : panneau de dialogue (portrait, bulle, choix ≥ 96 px),
  journal de quêtes, carnet de voyage ; PNJ placés sur la carte (quai, marché,
  atelier) et sélectionnables au tap comme les bâtiments.

---

## 7. Tests prévus

- **Déblocage des missions** : une mission n'est disponible que si toutes ses
  conditions sont vraies ; chaque type de condition a ses cas vrais/faux ;
  conditions sur des quêtes terminées en chaîne.
- **Progression des dialogues** : ordre des nœuds, choix masqués si leurs
  conditions sont fausses, fin de dialogue, reprise après interruption,
  effets appliqués une seule fois même si le dialogue est rejoué.
- **Récompenses uniques** : terminer, recharger, rejouer un événement ⇒ pas de
  double octroi (monnaie, XP, relation, fiche).
- **Sauvegarde** : relations, flags, quêtes, fiches et dialogues vus survivent à
  un aller-retour de sauvegarde ; niveau de relation jamais perdu.
- **Cohérence des références** (test de données) : chaque PNJ, quête,
  dialogue, objectif, récompense, fiche, destination et lieu référencé existe ;
  pas d'identifiant en double ; toutes les clés i18n existent ; aucune quête
  inatteignable (graphe des prérequis sans cycle, chaque quête atteignable
  depuis le début) ; fiches `FACT`/`INSPIRED` publiées ⇒ sources complètes ;
  aucune fiche `DRAFT` livrée.
- **Tutoriel** : un test joue le scénario du tutoriel de bout en bout, sans
  interface, avec horloge simulée.

---

## 8. Processus éditorial (destinations réelles)

1. Recherche documentaire et fiche `DRAFT` avec sources complètes.
2. Relecture par une personne compétente (historien·ne, médiateur·rice
   culturel·le, habitant·e) ; corrections.
3. Passage en `PUBLISHED`, crédits ajoutés.
4. Revue périodique des fiches (sources mortes, connaissances mises à jour).

---

## 9. Performances et accessibilité

Dialogues et quêtes ne s'exécutent que sur événement (aucun traitement par
image). Textes lisibles sur téléphone (≥ 34 px en base 1920×1080), dialogue
passable et rejouable depuis le journal, pas de choix bloquant dans le
tutoriel.

---

## 10. Découpage en étapes (lot N)

| # | Étape | Critères d'acceptation |
|---|-------|------------------------|
| N1 | **Conditions et effets** (`ConditionDef`, `EffectDef`, évaluateur, applicateur idempotent) | Chaque type testé vrai/faux ; un même identifiant d'octroi n'applique jamais deux fois ses effets |
| N2 | **PNJ et relations** (`NpcDef`, `Relationships`), données des 4 PNJ | Paliers aux bornes exactes ; niveau jamais perdu ; test de références PNJ |
| N3 | **Dialogues** (`DialogueRunner`) + panneau de dialogue | Progression, choix conditionnels, effets uniques ; capture du panneau |
| N4 | **Quêtes narratives** (`QuestLog`) | Prérequis, objectifs par événements, récompenses uniques, chaînes de quêtes |
| N5 | **Tutoriel avec Hina** (scénario des dix minutes) | Test de bout en bout sans UI ; partie jouée à la main et capturée ; durée mesurée |
| N6 | **Carnet de voyage** (`DiscoveryDef`, `TravelJournal`, UI) | Fiches débloquées une fois ; badges de nature ; progression par destination |
| N7 | **Validation de contenu** (références, i18n, sources, graphe de quêtes) | Une donnée cassée fait échouer le test avec un message clair |
| N8 | **PNJ sur la carte** (quai, marché, atelier) | Tap sur un PNJ ⇒ dialogue ; tests de sélection |
| N9 | **Services débloqués** (excursion, dîner, décoration) | Service indisponible sous le niveau requis ; faits de séjour produits |
| N10 | **Missions culturelles de Mahana** (une par catégorie) | Toutes atteignables (test de graphe) ; fiches associées |
| N11 | **Cadre multi-destinations** (`DestinationDef`, changement de carte) | Une 2ᵉ destination de test se charge sans changer le code |
| N12 | **Première destination réelle** | Fiches sourcées et relues ; aucune fiche `DRAFT` livrée |

Insertion recommandée : N1–N5 remplacent l'étape « Progression et quêtes »
de la V0.1 (tutoriel avec Hina) ; N6–N7 dans la V0.1 avec 3 fiches ; N8–N10
en V0.2 ; N11–N12 en V0.3.
