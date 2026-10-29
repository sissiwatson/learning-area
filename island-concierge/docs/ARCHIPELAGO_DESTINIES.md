# Destinées de l'archipel — conception

> Statut : **conception, non développée.** Intégration prévue en **V0.3**,
> après validation de la boucle de gestion (V0.1) puis de la réputation et de
> la narration (V0.2). Lot de développement « D » (§11, `BACKLOG.md`).

## 1. Vision

Le joueur ne fait pas que développer une conciergerie : ses décisions
façonnent l'avenir des îles, de leurs habitants, de leur économie, de leur
patrimoine et de leur environnement. Chaque île évolue selon ses choix, et
chaque partie raconte une histoire différente.

**Ton** : chaleureux, accessible, ludique. Les décisions font réfléchir sans
transformer le jeu en simulation politique ou en cours magistral :

- les enjeux sont portés par des **personnages** qu'on aime (Hina, Tao, Malia,
  Kimo), avec humour et émotion, pas par des tableaux de chiffres ;
- chaque option tient en **trois lignes** (ce qu'on gagne, ce que ça coûte,
  ce qui inquiète quelqu'un) et des icônes ;
- les conséquences se **voient sur la carte** avant de se lire dans un menu ;
- **il n'y a pas de mauvaise fin** : chaque trajectoire a ses réussites, ses
  difficultés et ses façons de réparer.

## 2. Principes de conception

1. **Pas de choix dominant** : chaque option est la meilleure sur au moins un
   indicateur et moins bonne sur au moins un autre (vérifié par test, §10).
2. **Déterminisme** : mêmes choix + même déroulé ⇒ mêmes conséquences. Les
   surprises viennent de **conséquences différées et conditionnelles**
   (annoncées à demi-mot par les PNJ), jamais d'un tirage au sort.
3. **Rien d'irréversible** : indicateurs bornés avec planchers, contenu jamais
   reverrouillé, actions de réparation toujours disponibles, projets
   révisables à des « points d'étape ».
4. **Écouter avant de décider** : consulter les habitants révèle des
   informations, débloque des clauses de négociation et améliore la réaction
   des PNJ, même s'ils sont en désaccord.
5. **Données, pas code** : décisions, options, clauses, conséquences,
   modifications de carte et réactions des PNJ sont des fichiers de données.

## 3. Quatre indicateurs stratégiques

Indépendants, chacun sur une échelle de **0 à 100**, affichés sous forme de
jauge avec un état lisible (*Fragile < 30*, *Stable 30–69*, *Florissant ≥ 70*).

| Indicateur | Ce qu'il mesure | Calculé à partir de |
|------------|-----------------|---------------------|
| 💰 **Rentabilité** | santé financière de la conciergerie | trésorerie, résultat net des 7 derniers jours (revenus − charges), valeur du patrimoine immobilier |
| ⭐ **Réputation touristique** | satisfaction des voyageurs | réputation de `REPUTATION.md` (moyenne glissante), qualité des logements |
| 🌺 **Patrimoine et communauté** | vie et traditions de l'île | relations avec les habitants, commerces locaux actifs, lieux patrimoniaux préservés, fêtes maintenues |
| 🌿 **Équilibre environnemental** | santé des milieux naturels | espaces naturels restants (cellules de la carte), pollution, pression sur l'eau et le récif, impact des constructions |

Rentabilité et réputation sont **calculées** à partir des systèmes existants.
Patrimoine et environnement combinent un **calcul** (cellules, commerces,
relations) et des **effets de décisions** (points ajoutés ou retirés, avec
une date et une cause, conservés dans un journal pour l'affichage
« Pourquoi cette valeur ? »).

### Influence des indicateurs

| Indicateur élevé | Indicateur bas (jamais bloquant) |
|------------------|----------------------------------|
| 💰 projets d'investissement plus grands, prêts à meilleur taux | projets plus petits, aide de la coopérative (mission) |
| ⭐ voyageurs premium, propriétaires prestigieux | moins d'offres (plancher), missions de redressement (`REPUTATION.md`) |
| 🌺 fêtes, services des PNJ, artisans et commerces nouveaux | PNJ plus réservés, quêtes de réconciliation |
| 🌿 activités nature (plongée, observation), écovoyageurs | événements (algues, eau trouble), projets de restauration |

## 4. Système de décisions narratives

### Cycle d'une grande décision

```
Déclenchement ─► Découverte du projet ─► Consultations (facultatives, révélatrices)
      ─► Négociation (clauses) ─► Décision (options exclusives) ─► Conséquences immédiates
      ─► Conséquences différées (jours de jeu) ─► Point d'étape (révision possible)
      ─► Réparations / nouvelles opportunités
```

- **Jours de jeu** : horloge de jeu dérivée de `Clock` (durée d'un jour
  configurable). Les conséquences différées sont planifiées au jour N et
  appliquées une seule fois, même si le jeu était fermé (rattrapage au
  chargement, dans l'ordre).
- **Report** : le joueur peut prendre son temps. Le projet reste ouvert un
  nombre de jours configurable ; au-delà, l'issue « statu quo » s'applique
  (elle aussi a ses avantages et ses coûts) et une seconde chance est
  proposée plus tard.
- **Point d'étape** : quelques jours après la décision, des **révisions**
  sont proposées (ex. ajouter une clause environnementale au resort). Ce
  n'est pas un retour en arrière : on corrige, on ne rembobine pas.

### Réactions des PNJ

Chaque PNJ a des **valeurs** (pondérations sur les quatre indicateurs), des
**préoccupations** précises et une **position** sur chaque option :
*soutient*, *conteste* ou *propose une alternative* (une clause). La relation
évolue selon la décision **et** selon l'écoute : avoir consulté un PNJ
adoucit sa réaction en cas de désaccord.

| PNJ | Valeurs principales | Préoccupation typique |
|-----|---------------------|-----------------------|
| Hina | 🌺 patrimoine, ⭐ accueil | « Les jeunes partent faute de travail… mais pas au prix de notre histoire. » |
| Tao | 🌿 environnement | « Le récif ne se plaint pas. Il meurt en silence. » |
| Malia | 💰 économie locale, 🌺 | « Des clients, oui ! Un buffet à volonté qui vide mon marché, non. » |
| Kimo | 🌺 savoir-faire, création | « Je veux bien décorer un hôtel. Pas vendre des souvenirs fabriqués ailleurs. » |

## 5. Conséquences visibles sur la carte

Les décisions modifient le monde par des **modifications de carte**
appliquées par-dessus la carte de base (la carte d'origine n'est jamais
réécrite ; la sauvegarde stocke la liste des modifications appliquées) :

| Type | Exemples |
|------|----------|
| Bâtiments | apparition d'un resort, d'éco-lodges, d'une maison de la coopérative ; transformation d'une aile |
| Paysage | plage aménagée, palmiers retirés ou replantés, passerelle en bois, bouées de mouillage, pépinière de corail |
| Activités | club nautique, excursions de Tao, sentier patrimonial, scène de festival |
| Commerces | étal de Malia agrandi, réduit ou déplacé ; boutique d'artisans |
| Événements | algues, eau trouble, retour des tortues, festival, afflux de visiteurs |

Les modifications peuvent être **progressives** (chantier ⇒ bâtiment ⇒
extension) et **différées** de plusieurs jours de jeu.

## 6. Réparation

Toute conséquence négative a au moins une **action de réparation**, avec un
coût et un délai :

| Problème | Réparations possibles |
|----------|-----------------------|
| Environnement bas | replanter, pépinière de corail avec Tao, limiter les mouillages, station d'eau |
| Patrimoine bas | rouvrir un sentier, soutenir la Fête des Lumières, charte « fournisseurs locaux » |
| Rentabilité basse | phases d'expansion, partenariats, services premium, réduction des charges |
| Relation dégradée | quête de réconciliation, écoute, compensation (ex. stand pour Malia dans le resort) |

## 7. Première grande quête : « L'avenir de la baie »

### Contexte

L'**Anse aux Tortues**, sur la Côte Est de Mahana, est une plage sauvage où
les tortues viennent pondre, où passe l'ancien sentier des pêcheurs et où se
dresse la petite stèle de la grande tempête. Une société de développement
fictive, **Cap Émeraude Développement**, représentée par **Solène Marchetti**
(fictive, cordiale et très convaincante), propose d'y construire un grand
complexe touristique et cherche un partenaire local : la conciergerie.

### Prérequis

| Condition | Valeur |
|-----------|--------|
| Tutoriel terminé | oui |
| Tiki bar construit | oui |
| Jour de jeu | ≥ 7 |
| Avis publiés | ≥ 5 (sortie de la période d'essai) |
| Relation avec Hina | ≥ Voisin (niv. 2) |

### Déroulé

| Étape | Contenu | Objectif / fin |
|-------|---------|----------------|
| 1. Le bateau blanc | Solène arrive au quai avec une maquette ; Tao la regarde en silence. | Lire la proposition |
| 2. Le dossier | Plans, chiffres et promesses (« 40 emplois », « deux fois plus de voyageurs »). | Examiner le dossier (révèle les trois orientations) |
| 3. La visite de l'anse | Le joueur se rend sur la plage avec Hina : la stèle, le sentier, les traces de tortues. | Visiter l'Anse aux Tortues (fiche *La stèle de la grande tempête*, FICTION) |
| 4. Les avis de l'île | Quatre conversations facultatives, chacune révèle une information et une clause. | Consulter 0 à 4 habitants |
| 5. La négociation | Le joueur ajuste l'option choisie avec les clauses débloquées. | Composer sa proposition |
| 6. La réunion au quai | Tous les PNJ sont présents ; le joueur annonce sa décision. Chaque PNJ réagit. | Décider (A, B ou C) ou reporter |
| 7. Les premiers jours | Conséquences immédiates, chantier sur la carte. | — |
| 8. Le point d'étape (jour +10) | Bilan avec les PNJ, révision possible. | Réviser ou confirmer |
| 9. La nouvelle baie (jour +30) | Épilogue selon la trajectoire ; nouvelles quêtes. | — |

### Ce que disent les habitants (étape 4)

> **Hina** : Mon neveu est parti travailler à la ville l'an dernier. Des
> emplois ici, j'en rêve. Mais la stèle… c'est là que mon grand-père a
> attendu son frère, le soir de la tempête.
> → révèle : le sentier et la stèle peuvent être **classés** (clause « sentier préservé »).

> **Tao** : Tu as vu les traces sur le sable ? Elles reviennent chaque année
> depuis que je suis gamin. Des bateaux à moteur dans l'anse, et c'est fini.
> → révèle : la saison de ponte ; clause « zone protégée des tortues ».

> **Malia** : Un hôtel, c'est des clients ! Sauf s'ils mangent tout sur place.
> Ma tante a vu ça sur une autre île : le marché a fermé en deux ans.
> → révèle : le risque pour le marché ; clause « fournisseurs locaux ».

> **Kimo** : S'ils veulent de la déco « locale », qu'ils l'achètent aux gens
> d'ici. Je pourrais former deux apprentis, avec un vrai atelier.
> → révèle : clause « atelier d'artisans » (boutique et apprentis).

Avoir consulté un PNJ : +5 relation, et sa réaction finale est adoucie d'un
cran s'il est en désaccord (« Je ne suis pas d'accord… mais tu m'as écouté. »).

### Les trois orientations

Valeurs indicatives à équilibrer par simulation (§10) ; « jour » = jour de jeu
après la décision. Investissement en coquillages du joueur.

| | **A — Le grand resort** | **B — L'écotourisme** | **C — Le partenariat communautaire** |
|---|---|---|---|
| En une phrase | Gros investissement, gros retour, forte pression | Petits pas, nature préservée, démarrage lent | On partage tout : la mise, les revenus et les réunions |
| Investissement | 2 500 | 3 × 300 (phases aux jours 0, 10, 20) | 600 (+ 600 des habitants) |
| Revenus | +400/jour dès le jour 7 | +100/jour dès le jour 3, +50/jour par phase | +220/jour dès le jour 12 (part du joueur 50 %) |
| Charges | entretien 60/jour | entretien 20/jour | coordination 40/jour |
| Capacité d'accueil | +20 voyageurs | +6 voyageurs | +10 voyageurs |
| 💰 Rentabilité | ++ | − puis + | + |
| ⭐ Réputation | + (voyageurs premium) ; risque d'affluence | + (écovoyageurs, avis enthousiastes) | + (expériences locales) |
| 🌺 Patrimoine | −15 (sentier fermé), stèle déplacée | +5 | +15 (fête, atelier, marché) |
| 🌿 Environnement | −20 (chantier) ; −10 de plus au jour 14 | +10 ; pépinière de corail au jour 14 | −5 (chantier léger) |
| Hina | conteste | soutient | soutient |
| Tao | conteste fortement | soutient fortement | soutient avec réserve (« pas de jet-skis ») |
| Malia | partagée (soutient avec la clause fournisseurs) | réservée (« peu de clients ») | soutient |
| Kimo | partagé (soutient avec la clause atelier) | soutient | soutient |
| Sur la carte | 3 grands bâtiments, plage aménagée, ponton à moteurs | 4 éco-lodges, passerelle, bouées, panneaux de ponte | maison de la coopérative, marché agrandi, jardin partagé, scène |
| Conséquences différées | jour 14 : pression sur l'eau ; jour 21 : algues **si** 🌿 < 40 ; jour 30 : Malia ferme son étal **sauf** clause fournisseurs | jour 14 : retour des tortues (activité d'observation) ; jour 25 : un tour-opérateur propose un partenariat | jour 12 : réunion difficile (mini-décision) ; jour 20 : première Fête des Lumières élargie ; jour 30 : Kimo forme ses apprentis |
| Risque principal | environnement et patrimoine | rentabilité lente | coordination et délais |

### Clauses de négociation (débloquées par les consultations)

| Clause | Applicable à | Effet | Coût |
|--------|--------------|-------|------|
| Sentier préservé (Hina) | A, C | patrimoine : annule −10 | revenus A −40/jour |
| Zone protégée des tortues (Tao) | A, C | environnement : annule l'événement du jour 14 | capacité −4 |
| Fournisseurs locaux (Malia) | A, B, C | l'étal de Malia prospère ; patrimoine +5 | charges +30/jour |
| Atelier d'artisans (Kimo) | A, B, C | boutique d'artisans sur la carte ; patrimoine +5 | investissement +300 |

Les clauses ne rendent aucune option « parfaite » : elles déplacent le
compromis (moins de revenus, plus de charges, moins de capacité).

### Statu quo (report jusqu'à l'échéance)

Rien n'est construit : Tao est soulagé, Hina partagée (« et les jeunes ? »),
Malia déçue. Environnement inchangé, pas de nouveaux revenus. Cap Émeraude
revient plus tard avec un projet différent.

### Point d'étape (jour +10) — révisions possibles

| Trajectoire | Révisions proposées |
|-------------|---------------------|
| A | ajouter une clause manquante (à coût majoré) ; convertir une aile en atelier d'artisans |
| B | accélérer les phases (coût immédiat) ; partenariat de transport avec Tao |
| C | désigner Hina médiatrice (moins de réunions difficiles) ; ouvrir le capital à Cap Émeraude (revenus +, patrimoine −) |

### Épilogues (jour +30)

- **A** : la baie est animée, les coquillages affluent ; selon les clauses, le
  marché de Malia vit ou ferme, les tortues reviennent ou non. Nouvelles
  quêtes : « Le club nautique », « Une place pour le marché ».
- **B** : la baie est calme, les voyageurs y viennent pour la nature. Nouvelles
  quêtes : « Le retour des tortues », « La nuit des étoiles avec Tao ».
- **C** : la baie est devenue le lieu de vie de l'île. Nouvelles quêtes : « La
  grande Fête des Lumières », « Les apprentis de Kimo ».

## 8. Modèle de données

Dépend du moteur de conditions et d'effets du lot N (`NARRATIVE.md` §6).

| Ressource | Champs principaux |
|-----------|-------------------|
| `IndicatorDef` | `id`, `name_key`, `icon`, `min`, `max`, `floor`, `bands[]`, source de calcul |
| `DecisionDef` | `id` (unique), `title_key`, `trigger_conditions[]`, `deadline_days`, `consultations[]`, `options[]`, `status_quo: DecisionOptionDef`, `review_after_days`, `revisions[]` |
| `ConsultationDef` | `npc`, `dialogue`, `reveals_clauses[]`, `relationship_bonus` |
| `DecisionOptionDef` | `id`, `title_key`, `summary_keys[3]`, `costs`, `immediate_effects[]`, `consequences[]`, `map_changes[]`, `npc_stances[]`, `unlocks[]` (quêtes, événements), `allowed_clauses[]` |
| `ClauseDef` | `id`, `title_key`, `effects[]`, `costs`, `cancels_consequences[]` |
| `ConsequenceDef` | `id` (unique), `delay_days`, `conditions[]`, `effects[]`, `map_changes[]`, `event`, `repairs[]` |
| `MapChangeDef` | `id`, `type` (add_placement, remove_placement, replace_placement, terrain_patch, decor_patch, unlock_zone), données |
| `NpcStanceDef` | `npc`, `stance` (SUPPORT, CONTEST, ALTERNATIVE), `relationship_delta`, `softened_delta` (si consulté), `dialogue` |
| `RepairActionDef` | `id`, `conditions[]`, `costs`, `duration_days`, `effects[]` |

État sauvegardé (`DecisionLog`) : décision prise (option, clauses, jour),
consultations faites, conséquences planifiées (id, jour prévu, appliquée ou
non), modifications de carte appliquées, révisions, journal des indicateurs.

Moteur (logique pure, `src/core/destinies/`) : `Indicators`, `DecisionLog`,
`ConsequenceScheduler` (application idempotente par identifiant, rattrapage
dans l'ordre), `MapOverlay` (carte de base + modifications), `StanceResolver`.

## 9. Interface

- **Carnet de projet** : une page par décision ; options en trois lignes,
  icônes des indicateurs (↑ ↓ ?) — les effets différés sont annoncés comme
  des risques ou des espoirs, pas comme des chiffres exacts.
- **Jauges** des quatre indicateurs dans un écran « Mon archipel », avec
  « Pourquoi cette valeur ? » (journal des causes).
- **Réunion au quai** : les quatre PNJ réagissent en bulles courtes, avec leur
  portrait et leur humeur.

## 10. Tests prévus

- **Choix exclusifs** : une seule option par décision ; impossible de choisir
  deux fois ; clauses refusées si non débloquées ou incompatibles.
- **Conséquences différées** : appliquées au bon jour, une seule fois, dans
  l'ordre, y compris après une longue fermeture du jeu ; conditionnelles
  (ex. algues seulement si 🌿 < 40) ; annulées par la bonne clause.
- **Sauvegarde** : décision, clauses, consultations, calendrier, modifications
  de carte et indicateurs survivent à un aller-retour ; la carte reconstruite
  est identique.
- **Pas de récompense dupliquée** : rejouer une consultation, recharger au jour
  d'une conséquence, réviser une décision ⇒ aucun double gain.
- **Réparation** : depuis l'état le plus bas atteignable de chaque indicateur,
  une suite d'actions permet de revenir à *Stable* ; aucun indicateur ne
  descend sous son plancher ; aucun contenu n'est reverrouillé.
- **Pas de choix dominant** : simulation de chaque trajectoire (avec et sans
  clauses) sur 30 et 90 jours ; aucune n'est supérieure ou égale à une autre
  sur les quatre indicateurs à la fois.
- **Déterminisme** : deux simulations identiques donnent le même état final.
- **Cohérence des données** : références (PNJ, quêtes, bâtiments, cellules,
  clauses) valides ; chaque conséquence négative a au moins une réparation.

## 11. Découpage en étapes (lot D)

| # | Étape | Dépend de | Critères d'acceptation |
|---|-------|-----------|------------------------|
| D1 | **Jours de jeu** (calendrier dérivé de `Clock`) | étape 5 | Jour courant déterministe ; rattrapage après fermeture testé |
| D2 | **Indicateurs** (calcul + journal des causes, planchers) | 5, 7, R2, N2 | Valeurs aux bornes ; planchers ; journal explicable |
| D3 | **Modifications de carte** (`MapOverlay`) | 1, 10 (sauvegarde) | Ajouts/retraits/patchs appliqués et rejoués à l'identique après chargement |
| D4 | **Décisions et clauses** (choix exclusifs, coûts) | N1 | Tests de choix exclusifs et de clauses |
| D5 | **Conséquences différées** (`ConsequenceScheduler`) | D1, D4 | Une seule application, ordre, conditions, annulation par clause |
| D6 | **Réactions des PNJ** (positions, consultation, adoucissement) | N2, N3 | Deltas de relation exacts selon consultation |
| D7 | **Réparations et points d'étape** | D2, D5 | Retour à *Stable* possible depuis le pire état ; révisions sans double gain |
| D8 | **Interface** (carnet de projet, jauges, réunion au quai) | D2–D6 | Captures ; lisible sur téléphone (recette Android) |
| D9 | **Quête « L'avenir de la baie »** (contenu) | D1–D8, N4 | Test de bout en bout des 3 options + statu quo ; test de non-dominance |
| D10 | **Équilibrage par simulation** | D9 | Rapport de simulation 30/90 jours joint ; non-dominance vérifiée |

Version cible : **V0.3**. Prérequis de version : V0.1 validée sur appareil
(boucle de gestion, sauvegarde) et V0.2 validée (réputation R1–R6, narration
N1–N7).
