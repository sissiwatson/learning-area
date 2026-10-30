# Scénario des dix premières minutes — « Le bungalow de Hina »

> **V0.1 : version allégée** — séquences 1 à 4, 6, 7, 9 et 10 ; la décoration
> (5), la demande des voyageurs (8) et l'avis détaillé arrivent en V0.2
> (`GAME_VISION.md` §8). L'économie du tutoriel (50 → 170 → 20) est inchangée.
>
> Statut : **principe validé ; version 2** (progression par actions, dialogues
> accélérables, décision de décoration, économie détaillée).
> Personnages et lieux fictifs. Conception générale : [`NARRATIVE.md`](NARRATIVE.md).

## Intentions

- Apprendre **toute la boucle** du brief en jouant : réservation → ananas →
  panier → **décoration** → préparation → accueil → fin de séjour et
  commission → tiki bar.
- Faire aimer **Hina** et l'île, présenter brièvement **Tao, Kimo et Malia**.
- Montrer, sans jargon, que **ce que vit le voyageur fait sa note**.
- Proposer **une première vraie décision**, avec un budget limité et des
  effets différents, sans mauvaise réponse.
- Débloquer **3 fiches** du carnet de voyage.

## Règles de rythme

### Le tutoriel avance selon les actions du joueur

- Chaque séquence se termine sur un **événement de jeu** (réservation acceptée,
  ananas récoltés, panier fabriqué, décoration choisie…), jamais sur un
  chronomètre. Les durées indiquées plus bas sont des **estimations**.
- Un **bandeau d'objectif** reste visible (« Récolter des ananas 1/3 ») avec un
  bouton « Y aller » qui centre la caméra sur la cible.
- Si le joueur ne fait rien pendant 20 s, une **aide contextuelle** (flèche,
  pulsation du bâtiment) apparaît. Elle n'avance jamais l'histoire à sa place.
- Les minuteurs sont **raccourcis** pendant le tutoriel seulement
  (récolte 5 s, panier 8 s, construction 10 s) ; hors tutoriel, ce sont les
  durées du prototype (`data/balance/timings.tres`, recettes, chantier : ananas
  30 s, panier 1 min, ménage 2 min, nuit 5 min, tiki bar 5 min). Aucun dialogue n'attend la
  fin d'un minuteur.
- Le séjour des voyageurs se termine quand le joueur a traité la demande puis
  touché « Deux nuits plus tard… » (transition), pas après un délai.

### Les dialogues peuvent être accélérés ou passés

| Geste | Effet |
|-------|-------|
| Toucher la bulle pendant l'écriture | Le texte s'affiche entièrement |
| Toucher la bulle ensuite | Bulle suivante |
| Bouton **Passer** | Va directement à la fin du dialogue ou au prochain choix |
| Paramètres | Vitesse du texte : lente, normale, rapide, instantanée |

- Passer un dialogue **applique quand même** tous ses effets (objectifs,
  récompenses, relations) : on ne perd rien à passer.
- Un **choix** n'est jamais fait automatiquement : « Passer » s'arrête dessus.
- Tous les dialogues restent relisibles dans le journal.
- Au plus 3 bulles par séquence ; aucune bulle de plus de 2 lignes.

## Déroulé

| # | Séquence | Se termine quand… | Mécanique apprise | Durée estimée | Découverte |
|---|----------|-------------------|-------------------|---------------|------------|
| 1 | Arrivée au quai | le joueur a glissé **et** pincé la carte | Glisser, pincer | 0:30 | — |
| 2 | Les clés du bungalow | la réservation est acceptée | Tap, panneau, réservation | 0:45 | — |
| 3 | Le panier de bienvenue | 3 ananas sont récoltés | Production, minuteur | 1:00 | *Le panier de bienvenue* (FICTION) |
| 4 | L'atelier de Kimo | le panier est fabriqué | Recette, inventaire | 1:00 | *Le tressage des feuilles* (INSPIRED) |
| 5 | **Les retouches de Kimo** | la décoration est choisie (ou refusée) | Budget, compromis | 1:15 | — |
| 6 | La visite d'Hina | le bungalow est préparé | États du logement, critères | 0:45 | — |
| 7 | Les premiers voyageurs | les voyageurs sont accueillis | Accueil | 0:45 | — |
| 8 | Une question de voyageurs | la demande est traitée | Demandes, faits de séjour | 1:15 | *Le marché du quai* (FICTION) |
| 9 | Le premier avis | la commission est encaissée | Commission, avis, réputation | 1:00 | — |
| 10 | Le tiki bar | la construction est lancée | Construction, objectif suivant | 1:00 | — |
| | **Total estimé** | | | **≈ 9 à 10 min** | 3 fiches |

À mesurer lors de la première partie jouée à la main ; viser 9 à 11 minutes
pour un joueur qui lit tout, moins pour un joueur qui passe les dialogues.

## Séquences détaillées

### 1. Arrivée au quai
Le bateau de Tao accoste au ponton (sud de l'île).

> **Tao** : On y est. Mahana. Hina t'attend… et elle n'aime pas attendre.
> **Tao** : Glisse ton doigt pour regarder l'île. Pince pour t'approcher.

### 2. Les clés du bungalow

> **Hina** : Te voilà ! Je suis Hina. Mon grand-père a construit ce bungalow
> avec le bois que la mer nous a rendu après la grande tempête.
> **Hina** : Je ne veux pas des touristes qui passent. Je veux des invités
> qu'on accueille. Un couple demande deux nuits : touche le bureau et accepte.

### 3. Le panier de bienvenue

> **Hina** : Ici, c'est l'hôte qui offre : chaque visiteur reçoit des fruits
> du jardin. Nos ananas t'attendent à la plantation. Trois suffiront.

Récompense : fiche **« Le panier de bienvenue »** (FICTION).

### 4. L'atelier de Kimo

> **Kimo** : Ah… bonjour. Hina t'envoie ? Le panier, je le tresse avec des
> feuilles de palmier séchées. Chaque brin passe sous deux, puis sur deux…

Récompense : fiche **« Le tressage des feuilles »** (INSPIRED : récit de Kimo
fictif ; le bloc « contexte réel » doit être rédigé à partir de sources
vérifiées avant publication).

### 5. Les retouches de Kimo — première décision

> **Kimo** : Hina m'a laissé **40 coquillages** pour arranger le bungalow.
> C'est peu… il faut choisir. Tu décides, c'est toi qui connais les voyageurs.

Le budget de 40 est le **budget de rénovation du logement**, fourni par Hina
(propriétaire). Il est distinct des coquillages du joueur.

| Amélioration | Coût | Effet | Durée |
|--------------|-----:|-------|-------|
| **Coussins et linge teints à la main** | 25 | Confort du bungalow 2 → 3 | Permanent |
| **Lampe en bois flotté** | 30 | Esthétique 2 → 3 : de plus belles photos, donc plus de demandes de réservation (visibilité) | Permanent |
| **Bouquet d'hibiscus et carte manuscrite** | 15 | « Attention personnelle » : +0,25 au critère expérience pour ce séjour | Un séjour (les fleurs fanent) |

Combinaisons possibles avec 40 : coussins + bouquet (40), coussins seuls (25),
lampe seule (30), bouquet seul (15), ou ne rien acheter. Le budget non
dépensé reste disponible pour une prochaine rénovation du Bungalow Hibiscus.
L'écran montre pour chaque objet son coût, son effet en une ligne et une
icône (confort, esthétique, satisfaction) ; le bungalow change d'aspect
(coussins sur la terrasse, lampe allumée, fleurs).

Réactions (aucune n'est un reproche) :
- Coussins : **Hina** : « Mes invités dormiront comme des rois. »
- Lampe : **Kimo** : « Elle va être magnifique sur les photos. »
- Bouquet : **Hina** : « Ma grand-mère faisait pareil. Ça ne coûte presque rien, et on s'en souvient. »
- Rien : **Kimo** : « Tu as raison, on garde pour plus tard. »

#### Effet sur le premier avis (calcul déterministe)

Bungalow au départ : confort 2, esthétique 2. Profil des voyageurs (couple) :
confort attendu 3. Règles du tutoriel (en centièmes, voir `REPUTATION.md`) :
confort −50 par niveau manquant ; réponse tardive à la demande : communication
−50 et expérience −25 ; attention personnelle : expérience +25 ; chaque
critère est plafonné à 500.

| Décoration | Réponse rapide | Réponse tardive |
|------------|---------------:|----------------:|
| Coussins + bouquet | **5,00** | **4,90** |
| Coussins seuls | 5,00 | 4,85 |
| Bouquet seul | 4,90 | 4,80 |
| Lampe seule | 4,90 | 4,75 |
| Rien | 4,90 | 4,75 |

Exemple (lampe seule, réponse tardive) : propreté 500, communication 450,
confort 450, annonce 500, expérience 475 ⇒
(25×500 + 20×450 + 20×450 + 15×500 + 20×475) / 100 = 475 ⇒ **4,75**.

Il n'y a pas de meilleur choix absolu : la lampe pénalise un peu ce premier
avis mais attire davantage de réservations ensuite ; le bouquet protège ce
séjour seulement ; les coussins améliorent tous les séjours futurs. Les cinq
premiers avis sont de toute façon en période d'essai (aucune pénalité commerciale).

### 6. La visite d'Hina

> **Hina** : Le sol est propre, le lit est fait… et le panier sur la table.
> **Hina** : Un voyageur remarque tout : la propreté, le confort, si on lui
> répond vite, si la maison ressemble aux photos.

### 7. Les premiers voyageurs
Tao ramène **Camille et Noé** au quai. Choix du mot d'accueil (les deux
conviennent, sans effet sur la note) :
- « Bienvenue à Mahana ! Votre panier vous attend. »
- « Bienvenue ! Demandez-moi tout ce dont vous avez besoin. »

### 8. Une question de voyageurs

> **Noé** : Où peut-on dîner ce soir ? Quelque chose d'ici, pas un hôtel.

Le joueur recommande **le marché du quai**.

> **Malia** : Des amis de Hina ? Ce soir, poisson de Tao et riz au coco. Et
> gardez de la place pour le gâteau d'ananas !

La demande est « rapide » si le joueur la traite avant d'avoir effectué deux
autres actions de jeu (règle déterministe, sans chronomètre), « tardive »
sinon. Elle ne peut pas échouer.
Récompense : fiche **« Le marché du quai »** (FICTION).

### 9. Le premier avis
Transition « Deux nuits plus tard… ». Action « Encaisser la commission » :
séjour de 2 nuits à 300 coquillages payé à Hina, commission de la
conciergerie 20 % ⇒ **+120 coquillages**. L'avis s'affiche, construit à partir
des faits du séjour (tableau du §5), puis :

> **Hina** : Mon grand-père aurait aimé lire ça. Vise 4,80 ou plus, et les
> meilleurs propriétaires viendront frapper à ta porte.

### 10. Le tiki bar

> **Hina** : L'emplacement près de la plage, c'était le petit bar de mon
> cousin. Avec tes coquillages, tu pourrais le rouvrir.

Le joueur lance la construction (**150 coquillages**, niveau 2 requis). Fin du
tutoriel : le carnet s'ouvre sur 3 fiches.

> **Tao** : Un jour, je t'emmènerai voir le Grand Banc. Le récif a besoin
> qu'on s'en occupe.

## Économie du tutoriel

### Coquillages du joueur

| # | Événement | Mouvement | Solde |
|---|-----------|----------:|------:|
| — | Nouvelle partie (`data/balance/new_game.tres`) | | **50** |
| 2 | Accepter la réservation | 0 | 50 |
| 3 | Récolter 3 ananas (plantation d'Hina, récolte gratuite) | 0 | 50 |
| 4 | Fabriquer le panier (feuilles fournies par Kimo) | 0 | 50 |
| 5 | Décoration (payée sur le budget du logement, pas par le joueur) | 0 | 50 |
| 6–8 | Préparation, accueil, demande | 0 | 50 |
| 9 | Commission : 20 % × (2 nuits × 300) | **+120** | **170** |
| 10 | Construction du tiki bar | **−150** | **20** |
| | **Solde final** | +70 net | **20** |

Pourquoi 20 : le joueur a gagné sa première commission (120) et l'a
réinvestie presque entièrement dans le tiki bar (150). Il finit le tutoriel
avec un nouvel objectif (refaire une réservation) mais **sans blocage** : la
réservation suivante est immédiatement disponible et la récolte est gratuite.
Il n'existe aucune autre dépense possible pendant le tutoriel, donc il a
toujours au moins 150 coquillages au moment de construire (vérifié par test).

### Budget de rénovation du Bungalow Hibiscus (argent d'Hina)

| Choix | Dépensé | Reste pour plus tard |
|-------|--------:|---------------------:|
| Coussins + bouquet | 40 | 0 |
| Lampe seule | 30 | 10 |
| Coussins seuls | 25 | 15 |
| Bouquet seul | 15 | 25 |
| Rien | 0 | 40 |

### Inventaire

| Objet | Départ | Produit | Consommé | Fin |
|-------|-------:|--------:|---------:|----:|
| Ananas | 0 | +3 (récolte) | −3 (panier) | 0 |
| Panier d'accueil | 0 | +1 (atelier) | −1 (préparation) | 0 |

### Expérience (niveau 2 à 50 XP)

V0.1 : l'XP vient des **actions** (`data/progression/progression.tres` et
recettes), les quêtes n'en donnent pas en plus. Sans les séquences 5 et 8
(V0.2), le total est **55 XP** ⇒ niveau 2 (testé : 5, 10, 20, 25, 30, 55).

| Événement | XP | Cumul |
|-----------|---:|------:|
| Réservation acceptée | 5 | 5 |
| Récolte | 5 | 10 |
| Panier fabriqué | 10 | 20 |
| Décoration choisie (même « rien ») | 5 | 25 |
| Bungalow préparé | 5 | 30 |
| Voyageurs accueillis | 5 | 35 |
| Demande traitée | 5 | 40 |
| Séjour terminé | 25 | **65 ⇒ niveau 2** |

Le niveau 2, requis pour le tiki bar, est atteint à la fin du séjour.

### Autres résultats

| Élément | Fin du tutoriel |
|---------|-----------------|
| Réputation | 1 avis entre 4,75 et 5,00 selon les choix (période d'essai) |
| Relations | Hina +15, Kimo +10, Malia +10, Tao +5 |
| Carnet | 3 fiches |

## Données à créer (étape N5)

- Quêtes `tutorial_01` à `tutorial_10` (`NarrativeQuestDef`), chaînées par
  prérequis ; objectifs = événements de jeu.
- Dialogues `dlg_tutorial_01` à `dlg_tutorial_10` (`i18n/dialogues.csv`).
- Décision `deco_hibiscus_first` : 3 améliorations (`DecorationDef` : coût,
  confort, esthétique, attention personnelle, durée) et budget du logement 40.
- PNJ `npc_hina`, `npc_tao`, `npc_kimo`, `npc_malia` ; voyageurs
  `guest_camille_noe` (profil « couple », confort attendu 3).
- Fiches `disc_mahana_welcome_basket`, `disc_leaf_weaving` (à sourcer),
  `disc_mahana_quay_market`.
- Réglages du tutoriel : minuteurs raccourcis, commission 20 %, prix 300/nuit.

## Tests associés

- **Progression par actions** : chaque quête se termine sur son événement et
  sur lui seul ; aucune ne se termine par le simple passage du temps
  (horloge simulée avancée de 24 h sans action ⇒ aucune progression).
- **Dialogues** : « Passer » applique les mêmes effets que la lecture complète ;
  « Passer » s'arrête sur un choix ; rejouer un dialogue n'accorde rien de plus.
- **Décoration** : chacune des 5 combinaisons possibles est acceptée, toute
  combinaison > 40 est refusée sans rien dépenser ; budget restant exact ;
  les 10 notes du tableau du §5 sont reproduites exactement.
- **Économie** : solde 50 → 170 → 20 pour toutes les combinaisons de choix ;
  le joueur a toujours ≥ 150 au moment du tiki bar ; inventaire final vide ;
  XP 65 et niveau 2.
- **Reprise** : interruption puis reprise (sauvegarde) au milieu de chaque séquence.
