# Plan de développement — V0.2 « Immersion et découverte »

> Statut : **proposition à valider**. Rien n'est commencé ; la V0.2 démarre
> seulement après validation de l'étape 12 (fin de la V0.1, APK 0.1.5).

Références : feuille de route validée (`BACKLOG.md`), introduction
(`GAME_VISION.md` §4.8, `NARRATIVE.md` §11), paniers (§4.9), ressources et
marché (§4.10), expériences (§4.11), contraintes (§6 bis), fiches
(`NARRATIVE.md` §12).

## 1. Objectif et critères de sortie

Donner envie de jouer dès la première minute et faire vivre Mahana, sans
transformer le jeu en ferme : introduction interactive, nom de la
conciergerie, île animée, marché de Malia, paniers cohérents, premières
expériences vendues aux voyageurs, premières fiches du carnet.

La V0.2 est terminée quand :

1. tous les tests sont verts, y compris **tous ceux de la V0.1** (non-régression) ;
2. la recette de stabilité de l'étape 12 (aléatoire, singe, endurance) passe
   sur le nouveau contenu ;
3. une **sauvegarde 0.1.x** se charge sans perte (migration v1 → v2 testée) ;
4. la simulation « session type de 10 min » montre une **production ≤ un tiers
   des actions** (§6 bis) ;
5. la recette Android de fin de version est faite sur votre téléphone.

## 2. Principes de découpage

- **Un lot = un commit poussé**, testable seul : tests GUT, contre-épreuve
  (le test échoue si on retire le correctif), captures aux trois formats
  (16:9, 20:9, 4:3) quand l'écran change.
- Chaque lot laisse le jeu **jouable de bout en bout** ; aucune fonctionnalité
  à moitié visible n'est livrée (drapeau de données si besoin).
- Les durées restent celles du prototype ; toutes les valeurs (prix, stocks,
  marges) sont des **données** à équilibrer.
- Pas de finance détaillée en V0.2 (elle arrive en V0.2.5) : achats et ventes
  passent par le portefeuille existant, chaque mouvement porte une **raison**
  (`market:…`, `activity:…`) que le journal comptable E1 reprendra.
- Sur appareil : trois APK intermédiaires (jalons 1 à 3), chacun avec une
  courte liste de vérification ; rien n'est déclaré validé sur téléphone
  avant votre retour.

## 3. Lots

Taille : **S** ≈ un petit lot (une demi-journée de développement), **M** ≈ deux
ou trois lots S.

### Jalon 0 — Fondations (aucun changement visible)

| Lot | Contenu | Tests et preuves | Taille |
|-----|---------|------------------|--------|
| **0.1** Sauvegarde v2 | Version de format 2 ; cadre de migration v1 → v2 (vide au départ) ; une sauvegarde v1 réelle (exportée de 0.1.5) versée aux tests comme fixture | Chargement de la fixture v1 ; migration idempotente ; sauvegarde future toujours mise de côté | S |
| **0.2** Mesure du mélange d'actions | Outil de simulation : un joueur « raisonnable » scripté joue 10 min de jeu ; classe chaque action (production, accueil, gestion, découverte) | Rapport chiffré sur la V0.1 (point de départ) ; test qui échouera si production > ⅓ | S |
| **0.3** Réglages | Écran Réglages minimal (bouton dans la barre) : réduire les animations, rejouer l'introduction (désactivé tant que O2 n'existe pas), crédits | Tests d'interface ; sauvegarde des réglages ; captures | S |

### Jalon 1 — Introduction et identité (APK 0.2.0-a1)

| Lot | Contenu | Tests et preuves | Taille |
|-----|---------|------------------|--------|
| **O1** Lecteur de scènes | `CutsceneDef` en données (étapes : mouvement de caméra, dialogue, cartes, saisie) ; lecteur générique ; un toucher accélère, « Passer » termine proprement | Lecteur testé étape par étape (horloge simulée) ; passer à chaque étape laisse un état cohérent ; aucune erreur moteur | M |
| **O2** Introduction de Mahana | Script §11 : bateau de Tao, survol de l'île, Hina au quai, 4 cartes de mission (rentable, accueillir, collaborer, préserver) ; environ 90 s ; jouée une fois (marqueur sauvegardé) ; remplace le premier dialogue de Tao et enchaîne sur « Arrivée au quai » | Partie neuve : intro → quête 01 ; passer → même état ; ancienne sauvegarde : intro **non** rejouée ; « Rejouer » depuis les réglages sans toucher à la progression ; captures de chaque plan | M |
| **O3** Nom de la conciergerie | Saisie (3 à 24 caractères, filtre de mots, proposition « Conciergerie du Lagon ») ; nom utilisé dans les dialogues (`{agency}`) et le bandeau ; modifiable dans les réglages ; aucun avantage de jeu | Validation des noms (cas limites, accents, emoji refusés) ; traduction avec variable ; ancienne sauvegarde → nom par défaut | S |

Recette Android 1 : durée ressentie de l'intro, clavier virtuel Android
(saisie du nom, encoche, rotation bloquée), « Passer ».

### Jalon 2 — Une île vivante (APK 0.2.0-a2)

| Lot | Contenu | Tests et preuves | Taille |
|-----|---------|------------------|--------|
| **V1b** Promeneurs et ambiance | 2 à 4 habitants qui marchent sur les chemins (graphe des cases « chemin » de la carte) ; un bateau au loin ; mouettes ; tout désactivable (réduire les animations) ; jamais d'obstacle aux touchers | Chemins valides (jamais dans l'eau ni dans un bâtiment) ; nombre de nœuds borné ; endurance : pas de croissance mémoire ; budget mesuré sur appareil d'entrée de gamme | M |
| **V1c** Étal de Malia et voyageurs visibles | Étal de Malia sur le quai (point d'entrée du marché) ; voyageurs visibles sur la terrasse du bungalow pendant le séjour, qui repartent au départ | États du séjour ↔ présence des voyageurs (y compris après rechargement) ; captures | S |

### Jalon 3 — Marché, ressources et paniers cohérents (APK 0.2.0-a3)

| Lot | Contenu | Tests et preuves | Taille |
|-----|---------|------------------|--------|
| **C1** Ressources | Objets en données : noix de coco, papaye, fleur d'hibiscus, fibres de pandanus séchées, corbeille tressée ; icônes originales ; inventaire et barre de ressources adaptés (seuls les objets possédés ou utiles sont affichés) | DataValidator ; barre lisible à 20:9 ; capacité d'inventaire inchangée | S |
| **F1** Marché de Malia | Panneau du marché (étal de V1c) : prix, stock limité **renouvelé en temps réel** (comme les offres) ; achat tout-ou-rien ; jamais de revente (pas de boucle d'achat-revente) | Achat refusé sans coquillages ou inventaire plein, sans perte ; stock rattrapé après fermeture de l'app ; horloge reculée sans stock gratuit ; anti-blocage | M |
| **A1** Gammes de paniers | « Panier de fruits » = **1 corbeille tressée + 3 fruits** (les fruits sont le contenu, la corbeille le contenant) ; la corbeille se tresse à l'atelier de Kimo ou s'achète au marché (premier « faire ou acheter ») ; l'ancienne recette « 3 ananas → panier » disparaît | Recettes cohérentes (test de données : aucun panier sans contenant) ; boucle complète toujours possible **sans dépenser** (anti-blocage) ; quêtes du tutoriel adaptées | M |
| **A2** Migration v1 → v2 | `welcome_basket` → « Panier de fruits » (quantités conservées) ; production en cours de l'ancienne recette terminée normalement ; quête 04 adaptée | Fixtures 0.1.3, 0.1.4, 0.1.5 : chargement sans perte, aucune quête rejouée ni récompense payée deux fois ; aller-retour v2 identique | S |
| **A3** Gamme « Bienvenue » | Corbeille + 2 fruits + 1 fleur ; le joueur choisit la gamme au moment du ménage ; effet en V0.2 : commentaire du voyageur et trace dans l'historique du séjour (la satisfaction chiffrée arrive avec la réputation, V0.2.5) | Choix de gamme ; historique du séjour ; contre-épreuve sans fleur | S |

Recette Android 3 : marché (lisibilité des prix, stock qui revient), choix du
panier, ancienne sauvegarde 0.1.5 installée par-dessus.

### Jalon 4 — Premières expériences et carnet (APK 0.2.0)

| Lot | Contenu | Tests et preuves | Taille |
|-----|---------|------------------|--------|
| **T1** Activités en option de séjour | `ActivityDef` (tarif, coût, prestataire, durée, capacité par jour, effet) ; proposées pendant le séjour, ajoutées à la réservation (pas de système parallèle) ; gain = marge, avec sa raison | Une seule vente par voyageur et par activité ; capacité respectée ; idempotence après rechargement ; aucune accélération possible | M |
| **T2** Balade botanique et rencontre au marché | Hina (balade, marge 40) ; Malia (rencontre gratuite, relation +) ; scènes courtes réutilisant le lecteur O1 ; ouvre la fiche correspondante | Parcours complet ; captures ; temps total ≤ durée du séjour | S |
| **N6 + C4 partiel** Carnet | Carnet de voyage minimal : fiches débloquées par les découvertes ; badge de nature (FICTION / INSPIRED / FACT) ; fiche « Le panier de bienvenue » (fiction) ; une fiche en `DRAFT` n'est **jamais** livrée (test bloquant) | Validation des fiches ; déblocage idempotent ; lisibilité | S |
| **Clôture V0.2** | Simulation du mélange d'actions (≤ ⅓ production), recette de stabilité étendue au nouveau contenu, audit UX aux 3 formats, documentation, APK 0.2.0 | Rapport `STABILITY_V0.2.md` | S |

## 4. Ordre et dépendances

```
0.1 ─┬─ O1 ─ O2 ─ O3            (jalon 1)
0.2  │
0.3 ─┘
V1b ─ V1c                        (jalon 2, indépendant du jalon 1)
C1 ─ F1 (besoin de V1c) ─ A1 ─ A2 ─ A3      (jalon 3)
T1 ─ T2 (besoin de O1, V1c) ─ N6/C4 ─ clôture   (jalon 4)
```

Environ 17 lots, quatre APK. Le jalon 2 peut passer avant le jalon 1 si vous
préférez voir l'île s'animer d'abord.

## 5. Risques identifiés

| Risque | Mesure |
|--------|--------|
| Saisie de texte sur Android (clavier virtuel, encoche) | Lot O3 isolé, testé tôt sur appareil (recette 1) |
| Performances des promeneurs sur téléphone d'entrée de gamme | Nombre borné, désactivable, endurance mesurée ; recette 2 |
| Migration des paniers (productions en cours, quêtes) | Fixtures réelles de chaque version 0.1.x ; tests d'aller-retour |
| Retour d'une ferme (trop de production) | Simulation 0.2 dès le jalon 0, vérifiée à chaque jalon |
| Contenu culturel non sourcé | Fiches FACT et INSPIRED bloquées en `DRAFT` tant que les sources ne sont pas vérifiées |

## 6. Questions à trancher avant le jalon 3

1. **Origine de la corbeille** : proposition — Kimo la tresse gratuitement à
   l'atelier à partir de fibres qu'il prépare lui-même (1 min, aucune matière
   à acheter), ou on l'achète au marché pour gagner du temps. La boucle
   reste ainsi jouable à 0 coquillage. Autre option : fibres achetées au
   marché (plus « gestion », mais il faut alors un filet de sécurité
   anti-blocage).
2. **Effet de la gamme « Bienvenue » avant la réputation** : commentaire et
   historique seulement (proposition), ou petit pourboire dès la V0.2 ?
3. **Fiches FACT / INSPIRED** (botanique, vannerie) : je ne livre aucune
   source inventée. Souhaitez-vous fournir ou valider des sources, ou
   limiter la V0.2 aux fiches de fiction (badge « Fiction du jeu ») ?
4. **Ordre des jalons 1 et 2** : introduction d'abord (proposition) ou île
   animée d'abord ?
