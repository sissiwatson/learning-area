# Backlog — Island Concierge

Légende : ✅ fait · 🟡 commencé · 🔜 prochaine étape · ⬜ à faire · 💡 idée à préciser.
Une tâche n'est cochée que si elle a été exécutée ou testée ; ce qui reste à
valider sur appareil est indiqué explicitement. 📱 = validé sur Android réel
(recette n°1, APK 0.1.0) ; 🧪 = vérifié par tests automatisés ou simulation.

## V0.1 « Premier séjour » — boucle simple et jouable

Identité et découpage complet : [`GAME_VISION.md`](GAME_VISION.md) §8.
La V0.1 reste volontairement simple : réputation, charges, incidents et
personnel sont en V0.2 et au-delà.

| Statut | Étape | Reste à valider |
|--------|-------|-----------------|
| ✅ 🧪 | 0 · Squelette du projet, GUT, i18n | — |
| ✅ 🧪 📱 | 1 · Carte isométrique de Mahana | — (affichage validé sur appareil) |
| ✅ 🧪 📱 | 2 · Caméra tactile (glisser, pincer, molette, limites, inertie) | Sur appareil : lever un doigt pendant un pincement, tap imprécis, inertie |
| ✅ 🧪 📱 | 3 · Bungalow Hibiscus interactif | Sur appareil : tap sur le toit |
| ✅ 🧪 📱 | 4 · Export Android debug | Sur appareil : encoche, mise en arrière-plan |
| ✅ 🧪 📱 | 5 · Économie de base (coquillages, inventaire, HUD) | — (barre de ressources lisible, APK 0.1.1) |
| ✅ 🧪 | 6 · Base de données et validation de `data/` (tous les bâtiments de Mahana sur la carte) | Sur appareil : panneaux des nouveaux bâtiments |
| ✅ 🧪 | 7 · Réservations (bureau, ménage, accueil, fin automatique, commission, versement) | Sur appareil : parcours complet, pastilles « ! » |
| ✅ 🧪 | 8 · Productions (ananas 30 s, panier 1 min, panier exigé pour préparer, livraison automatique, inventaire plein sans perte) | Sur appareil : parcours production → ménage ; boutons désactivés |
| ✅ 🧪 | 9 · Sauvegarde locale versionnée (arrière-plan, rattrapage, corruption, migrations, horloge modifiée) | Sur appareil : fermeture pendant un séjour, arrêt forcé, changement d'heure |
| ✅ 🧪 | 10a · XP et niveaux (gains par action en données, paliers, badge et barre d'XP, message « Niveau atteint », sauvegarde) | Sur appareil : lisibilité du badge |
| ✅ 🧪 | 10b · Quêtes de Hina : moteur de conditions et d'effets (N1), quêtes et dialogues passables (N3–N4), tutoriel guidé par les actions — version allégée (séquences 1–4, 6–7, 9–10 de `SCENARIO_TUTORIEL.md`) ; personnages visibles, phrases d'ambiance, bateau de Tao et arrivée des voyageurs | Sur appareil : lisibilité des dialogues, taille des personnages, « Passer » |
| ✅ 🧪 | 10c · Première animation de production (plantation en 3 stades, anneau de progression, « +3 » et « +120 » flottants, rebond) | Sur appareil : fluidité et lisibilité |
| ✅ 🧪 | 11 · Tiki bar (niveau 2, 150 coquillages, 5 min, chantier remplacé par le tiki bar, fin du tutoriel) | Sur appareil : parcours complet du tutoriel |
| ✅ 🧪 | 12 · Finitions V0.1 : audit UX (3 formats d'écran), recette de stabilité (aléatoire, singe, endurance), cadrage initial U1, crédits — voir `STABILITY_V0.1.md` | **Validation technique provisoire** (votre décision), sous réserve de la recette n°4. Retour 0.1.5 : le jeu fonctionne ; attentes trop longues pendant les séjours → 0.1.6 « Rythme ». Points de la recette n°4 non encore renseignés |
| 🔜 | 0.1.6 · Rythme : accélérations équilibrées et activités pendant les séjours (lots 1 à 7) — plan d'exécution `PLAN_V0.1.6.md` | Lot 1 présenté, en attente de votre accord |

Reporté en V0.2 : réputation R1–R6, carnet N6–N7, décision de décoration,
demande de voyageurs et avis détaillé du tutoriel (séquences 5 et 8).

## UX — retours de recette (APK 0.1.1)

Non bloquants pour les étapes 6 à 9 ; à traiter dans une passe UX dédiée.

| Statut | Amélioration | Notes |
|--------|--------------|-------|
| ✅ 🧪 | U1 · Cadrage initial mettant en valeur l'île et le bungalow | toute l'île visible en 16:9, 20:9 et 4:3 (étape 12, testé) |
| ⬜ | U2 · Panneau de bâtiment plus compact, avec miniature du bâtiment et portrait du propriétaire | portraits : dépend de N2 |
| ⬜ | U3 · Vraie carte de demande de réservation (voyageurs, durée, prix total, commission attendue, message) | = lot B, étape B4 |
| ⬜ | U4 · Apparition progressive des personnages et éléments narratifs dans les interactions | dépend de N2–N3 |
| ⬜ | U5 · Grille de construction discrète, masquée hors du mode construction | parcelles en pointillés aujourd'hui ; dépend de l'étape 11 |
| ⬜ | U6 · Pendant un séjour, le joueur continue à produire, récolter et gérer ses autres activités | garanti par l'étape 8 (productions indépendantes des séjours, testé) |

## Demandes de réservation & profils voyageurs (lot B)

Conception : [`BOOKING_REQUESTS.md`](BOOKING_REQUESTS.md). Évolution du
moteur de réservation de l'étape 7 (pas de second système).

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| ⬜ | B1 · Statuts (en attente, acceptée, refusée, expirée) et refus | 7 |
| ⬜ | B2 · Expiration (jamais pour le tutoriel) | 7, 9 |
| ⬜ | B3 · Profils voyageurs, préférences, message, logement demandé | N2 |
| ⬜ | B4 · Carte de demande (interface) | B1–B3 |
| ⬜ | B5 · Préférences → faits de séjour → satisfaction | R3 |
| ⬜ | B6 · Conciergeries concurrentes (expiration expliquée) | B2 |

## Économie de la conciergerie (lot E) — version future

Distinguer quatre grandeurs, sans les développer avant validation de la boucle :

| Grandeur | Définition | Aujourd'hui |
|----------|------------|-------------|
| Chiffre d'affaires des propriétaires | prix des séjours payés par les voyageurs, reversé aux propriétaires (hors commission) | enregistré par séjour (`stay_history.owner_share`) |
| Commissions encaissées | part de la conciergerie | versée au porte-monnaie, motif `commission:<réservation>` |
| Charges de conciergerie | ménage, linge, consommables, entretien, personnel, frais de plateformes | non modélisées |
| Bénéfice net | commissions − charges | = commissions tant qu'il n'y a pas de charges |

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| ⬜ | E1 · Journal comptable : chaque mouvement porte une catégorie (commission, charge, investissement, récompense) | 5 (journal du porte-monnaie) |
| ⬜ | E2 · Charges par séjour (ménage, linge, consommables) en données, prélevées à l'encaissement | 7 |
| ⬜ | E3 · Charges récurrentes (entretien, personnel, plateformes) au calendrier de simulation | D1 |
| ⬜ | E4 · Tableau de bord : chiffre d'affaires propriétaires, commissions, charges, bénéfice net | E1–E3 |
| ⬜ | E5 · Indicateur « Rentabilité » des Destinées branché sur E4 | D2 |

Règle anti-blocage maintenue : les charges ne peuvent jamais rendre une
réservation déficitaire au point d'empêcher la suivante (testé avec E2).

## Réputation et satisfaction (lot R)

Conception : [`REPUTATION.md`](REPUTATION.md) ; critères d'acceptation au §10.

| Statut | Étape |
|--------|-------|
| ⬜ | R1 · Configuration des critères et note d'un séjour |
| ⬜ | R2 · Registre d'avis immuable, réputation glissante, paliers |
| ⬜ | R3 · Journal de séjour et règles déterministes |
| ⬜ | R4 · Avis publié en fin de séjour |
| ⬜ | R5 · Effets de la réputation sur les réservations |
| ⬜ | R6 · Missions de redressement |
| ⬜ | R7 · Tableau de bord de réputation et historique (V0.2) |
| ⬜ | R8 · Avis textuels générés depuis les événements (V0.2) |
| ⬜ | R9 · Profils de voyageurs (V0.2) |
| ⬜ | R10 · Demandes et incidents (V0.2) |
| ⬜ | R11 · Confiance des propriétaires et logements premium (V0.2) |
| ⬜ | R12 · Budget de rénovation et décoration (V0.2) |
| ⬜ | R13 · Photographie des logements (V0.2) |
| ⬜ | R14 · Expansion et investissement (V0.2+) |

## Découverte culturelle et narration (lot N)

Conception : [`NARRATIVE.md`](NARRATIVE.md) ; critères d'acceptation au §10.
Tutoriel : [`SCENARIO_TUTORIEL.md`](SCENARIO_TUTORIEL.md) (proposition à valider).

| Statut | Étape |
|--------|-------|
| ⬜ | N1 · Conditions et effets (récompenses idempotentes) |
| ⬜ | N2 · PNJ et relations (Hina, Tao, Malia, Kimo) |
| ⬜ | N3 · Dialogues et panneau de dialogue |
| ⬜ | N4 · Quêtes narratives |
| ⬜ | N5 · Tutoriel « Le bungalow de Hina » |
| ⬜ | N6 · Carnet de voyage |
| ⬜ | N7 · Validation du contenu (références, i18n, sources, graphe de quêtes) |
| ⬜ | N8 · PNJ sur la carte (V0.2) |
| ⬜ | N9 · Services débloqués par la relation (V0.2) |
| ⬜ | N10 · Missions culturelles de Mahana, une par catégorie (V0.2) |
| ⬜ | N11 · Cadre multi-destinations (V0.3) |
| ⬜ | N12 · Première destination réelle, fiches sourcées et relues (V0.3) |

## Destinées de l'archipel (lot D) — V0.3

Conception : [`ARCHIPELAGO_DESTINIES.md`](ARCHIPELAGO_DESTINIES.md) ; critères
d'acceptation au §11. **Non développé** : intégration après validation de la
boucle de gestion (V0.1) puis de la réputation et de la narration (V0.2).

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| ⬜ | D1 · Jours de jeu (calendrier) | 5 |
| ⬜ | D2 · Quatre indicateurs (rentabilité, réputation, patrimoine et communauté, environnement) | 5, 7, R2, N2 |
| ⬜ | D3 · Modifications de carte (superposition sauvegardée) | 1, 10 |
| ⬜ | D4 · Décisions et clauses (choix exclusifs) | N1 |
| ⬜ | D5 · Conséquences différées | D1, D4 |
| ⬜ | D6 · Réactions des PNJ (soutien, contestation, alternative) | N2, N3 |
| ⬜ | D7 · Réparations et points d'étape | D2, D5 |
| ⬜ | D8 · Interface (carnet de projet, jauges, réunion au quai) | D2–D6 |
| ⬜ | D9 · Quête « L'avenir de la baie » | D1–D8, N4 |
| ⬜ | D10 · Équilibrage par simulation (non-dominance des options) | D9 |

## Simulation entrepreneuriale (vision)

Conception : [`GAME_VISION.md`](GAME_VISION.md). Non développé. Tous ces
systèmes réutilisent les moteurs génériques (conditions/effets N1,
situations/décisions D4–D5, calendrier D1, journal comptable E1).

### Situations réalistes (lot S) — moteur commun

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| ⬜ | S1 · Moteur de situations à options (déclencheur, options, coûts, conséquences immédiates et différées, sans tirage) — partagé avec D4–D5 | N1 |
| ⬜ | S2 · Panneau de situation (contexte, options en 3 lignes, coûts visibles) | S1 |
| ⬜ | S3 · Premières situations : chauffe-eau, arrivée tardive, ménage en retard | S1, E2 |

### Incidents voyageurs (lot I)

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| ⬜ | I1 · Pannes et retards (situations S3) avec effets sur les critères d'avis | S3, R3 |
| ⬜ | I2 · Réclamations, remboursements, gestes commerciaux | I1, E1 |
| ⬜ | I3 · Relogement et surréservation | I1, B1 |
| ⬜ | I4 · Casse, caution, facturation au propriétaire | I2, M1 |
| ⬜ | I5 · Réponses aux avis (publique, contestation) | R2 |

### Personnel (lot P)

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| ⬜ | P1 · Profils de personnel (compétences, tarif, disponibilités) et recrutement | S1, E1 |
| ⬜ | P2 · Planning des interventions (ménage, accueil) et délégation des productions | P1, D1 |
| ⬜ | P3 · Qualité des interventions → critères d'avis (déterministe) | P2, R3 |
| ⬜ | P4 · Absences, remplacements, paiements | P2, E3 |

### Relations propriétaires (lot M)

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| ⬜ | M1 · Fiches propriétaires (exigences, satisfaction propriétaire) | N2 |
| ⬜ | M2 · Mandats (commission négociée, durée, exclusivité, préavis) | M1, S1 |
| ⬜ | M3 · Prospection et négociation de nouveaux logements | M2 |
| ⬜ | M4 · Fidélisation, renégociation, perte de mandat avec préavis | M2, R2 |

### Développement de l'entreprise (lot X)

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| ⬜ | X1 · Services vendus aux voyageurs — détaillé par le lot T | N9, E1 |
| ⬜ | X2 · Investissements (boîte à clés, linge de qualité, véhicule, outillage) | E1 |
| ⬜ | X3 · Partenariats (bateau, restaurants, artisans) | X1, M1 |
| ⬜ | X4 · Acquisition de biens : propriétaire-investisseur (revenus, travaux, vacance) | E4, M2 |

### Vie de l'île (lot V)

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| 🟡 | V1 · Animations d'ambiance : **commencé en V0.1** (personnages qui se balancent, bateau de Tao, voyageurs qui marchent) ; à poursuivre en V0.2 (promeneurs, autres bateaux, eau) — mesurées sur appareil d'entrée de gamme | — |
| ⬜ | V2 · Habitants et commerces qui évoluent selon les choix | N2, D3 |
| ⬜ | V3 · Événements culturels (Fête des Lumières) et activités | D1, N10 |

### Introduction et identité du joueur (lot O) — proposition

Conception : `GAME_VISION.md` §4.8, script `NARRATIVE.md` §11.

| Statut | Étape | Dépend de | Version |
|--------|-------|-----------|---------|
| ⬜ | O1 · Lecteur de scènes (`CutsceneDef` : caméra, dialogue, cartes, saisie) | 10b | V0.2 |
| ⬜ | O2 · Introduction de Mahana (passable, jouée une fois, rejouable, marqueur sauvegardé) | O1, 9 | V0.2 |
| ⬜ | O3 · Nom de la conciergerie (saisie, validation, affichage, modification) | O1 | V0.2 |
| ⬜ | O4 · Avatar du joueur | O3 | V0.4 |

### Accueil : gammes de paniers (lot A) — proposition

Conception : `GAME_VISION.md` §4.9. La recette V0.1 reste en place.

| Statut | Étape | Dépend de | Version |
|--------|-------|-----------|---------|
| ⬜ | A1 · Gammes de paniers en données ; la recette actuelle devient « Panier de fruits » | 8 | V0.2 |
| ⬜ | A2 · Migration de sauvegarde v1 → v2 (`welcome_basket` → gamme « fruits »), testée | A1, 9 | V0.2 |
| ⬜ | A3 · Gamme « Bienvenue » (corbeille, fruits, fleur) | A1, C1, F1 | V0.2 |
| ⬜ | A4 · Effets des gammes sur la satisfaction | A1, R3 | V0.3 |
| ⬜ | A5 · Gammes « Découverte » et « Prestige », vente en supplément (marge) | A4, B1, C2 | V0.3 |
| ⬜ | A6 · Attentes de gamme selon les profils voyageurs | A4, B3 | V0.3 |

### Ressources et artisanat (lot C) — proposition

Conception : `GAME_VISION.md` §4.10 ; fiches `NARRATIVE.md` §12.

| Statut | Étape | Dépend de | Version |
|--------|-------|-----------|---------|
| ⬜ | C1 · Ressources : noix de coco, papayes, fleurs, fibres (achat au marché d'abord) | F1 | V0.2 |
| ⬜ | C2 · Ateliers de Kimo : corbeille tressée, couronne de fleurs | C1 | V0.3 |
| ⬜ | C3 · Savons et huiles parfumées (nouveau lieu) | C2 | V0.4 |
| ⬜ | C4 · Fiches pédagogiques sourcées (N13), jamais livrées en `DRAFT` | N6 | V0.3 |
| ⬜ | C5 · Stocks et capacités de production | C2, D1 | V0.4 |

### Faire / déléguer / acheter (lot F) — proposition

| Statut | Étape | Dépend de | Version |
|--------|-------|-----------|---------|
| ⬜ | F1 · Marché de Malia : achat de matières (prix, stock renouvelé en temps réel comme les offres) | E1 | V0.2 |
| ⬜ | F2 · Délégation à un habitant (rémunération, capacité, qualité, relation) | F1, N2 | V0.3 |
| ⬜ | F3 · Comparateur dans le panneau : coût, temps, qualité, effets | F1–F2 | V0.3 |
| ⬜ | F4 · Partenariats locaux (contrats à prix fixe) | F3, X3 | V0.4 |

### Expériences touristiques (lot T) — proposition

Conception : `GAME_VISION.md` §4.11. Détaille et remplace X1.

| Statut | Étape | Dépend de | Version |
|--------|-------|-----------|---------|
| ⬜ | T1 · Activités en données (tarif, coût, prestataire, durée, marge, effet, capacité) vendues en option d'une réservation | 7, E1 | V0.2 |
| ⬜ | T2 · Balade botanique (Hina) et rencontre au marché (Malia) | T1 | V0.2 |
| ⬜ | T3 · Atelier de vannerie (Kimo) et dîner chez Malia | T1, C2 | V0.3 |
| ⬜ | T4 · Excursion au lagon (Tao) | T1 | V0.3 |
| ⬜ | T5 · Massage aux huiles parfumées (nouvelle praticienne fictive) | T1, C3 | V0.4 |
| ⬜ | T6 · Effets des expériences sur la satisfaction | T1, R3 | V0.3 |

### Vie de l'île — suite (lot V)

| Statut | Étape | Version |
|--------|-------|---------|
| ⬜ | V1b · Promeneurs sur les chemins, autres bateaux au loin, mouettes | V0.2 |
| ⬜ | V1c · Étal de Malia sur le quai, voyageurs visibles sur la terrasse pendant le séjour | V0.2 |
| ⬜ | V1d · Habitants qui vont et viennent selon l'heure (calendrier D1) | V0.3 |

### Monétisation future (lot $) — V1.0 au plus tôt

Principes : [`GAME_VISION.md`](GAME_VISION.md) §6 (jamais obligatoire, jamais de
réputation achetée, accélérations plafonnées, transparence).

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| ⬜ | $0 · Étude de boutique : packs de perles, caisse premium séparée de la trésorerie, faux fournisseur de paiement — `PACING_AND_SPEEDUPS.md` §3 | — |
| ⬜ | $1 · Perles gagnées en jeu (monnaie déjà extensible), jamais convertibles en coquillages | 5 |
| ⬜ | $2 · Accélérations en perles : seulement si décidé (plafond quotidien) ; les accélérations en coquillages sont le lot Z | $1, Z1 |
| ⬜ | $3 · Packs décoratifs, conforts, extensions | $1 |
| ⬜ | $4 · Simulation : progression complète atteignable sans achat | $2–$3 |

### Rythme et accélérations (lot Z) — proposition, 0.1.6

Conception : [`PACING_AND_SPEEDUPS.md`](PACING_AND_SPEEDUPS.md).

| Statut | Étape | Dépend de | Version |
|--------|-------|-----------|---------|
| ⬜ | Z1 · Règles d'accélération pures (barème en données, paliers, refus, idempotence, sauvegarde, horloge) | 7, 9 | 0.1.6 |
| ⬜ | Z2 · « Avancer le temps » dans le panneau du séjour ; accélération offerte une seule fois dans le tutoriel | Z1 | 0.1.6 |
| ⬜ | Z3 · Renfort de ménage et équipe renforcée (chantiers) | Z1 | 0.1.6 |
| ⬜ | Z4 · Mesure des temps morts (≤ 90 s sur 30 min) dans une simulation de session | — | 0.1.6 (avancé) |
| ⬜ | Z5 · Demandes des voyageurs pendant le séjour, version légère (commentaire et historique) | Z4, N1 | 0.1.6 (avancé) |
| ⬜ | Z6 · Quêtes parallèles du premier séjour : « Les habitants de Mahana », « Un panier d'avance » | Z4, 10b | 0.1.6 |

### Direction artistique 3D et prototype (lot G) — proposition

Conception : [`ART_DIRECTION.md`](ART_DIRECTION.md), [`TRANSITION_3D.md`](TRANSITION_3D.md).
Rien n'est commencé ; le jeu existant n'est pas modifié.

| Statut | Étape | Critère principal |
|--------|-------|-------------------|
| ⬜ | G-P0 · Préparation : décisions, dossier isolé, export séparé, mesureur | APK du jeu inchangé, 310 tests verts |
| ⬜ | G-P1 · Extérieur (bungalow, lagon, plage, végétation) 📱 | 30 i/s stables 10 min, < 500 Mo |
| ⬜ | G-P2 · Caméra isométrique 3D (déplacer, zoomer, pivoter, toucher) | calculs testés sans écran |
| ⬜ | G-P3 · Hina, Kimo, 2 voyageurs animés 📱 | 4 personnages sans perte de fluidité |
| ⬜ | G-P4 · Intérieur et transition | pas de gel, pas de fuite mémoire |
| ⬜ | G-P5 · Décoration libre : 5 meubles 📱 | 5 meubles placés en < 2 min |
| ⬜ | G-P6 · Deux styles en un toucher, devis | mêmes effets qu'en mode libre |
| ⬜ | G-P7 · Dialogue avec portrait illustré | lisible sur téléphone |
| ⬜ | G-P8 · Bilan et décision 📱 | rapport chiffré |
| ⬜ | G-M1 à G-M5 · Migration progressive (contrat `IslandView`, logique de la vie de l'île, parité 3D, 3D par défaut, retrait de la 2D) | après décision positive seulement |

### Décoration et aménagement (lot DEC) — proposition

Conception : [`DECORATION.md`](DECORATION.md) (§9 pour le découpage DEC1–DEC7).
DEC1 (modèle pur) et DEC2 (décision d'aménagement depuis un panneau) ne
dépendent pas de la 3D ; DEC3–DEC6 suivent le prototype.

### Marché communautaire de créations (lot K) — fonctionnalité future, non développée

Publier, consulter, prévisualiser, débloquer des modèles de décoration ;
suivre des décorateurs.

| Statut | Étape |
|--------|-------|
| ⬜ | K0 · Architecture compatible : documents d'aménagement autonomes, versionnés, avec auteur, licence et empreinte ; identifiants de catalogue stables ; validation à l'import (`DECORATION.md` §6) — **à respecter dès DEC1** (conception seulement) |
| ⬜ | K1 · Service en ligne (comptes, stockage, modération) — étude à faire |
| ⬜ | K2 · Publier et consulter des créations, favoris, décorateurs suivis |
| ⬜ | K3 · Aperçu d'un modèle dans son logement (aucun meuble offert) |
| ⬜ | K4 · Échange contre monnaie virtuelle |
| ⬜ | K5 · Collections premium de créateurs |
| 💡 | K6 · Rémunération réelle des créateurs : étude technique, juridique, fiscale, modération et règles des plateformes **obligatoire** avant toute décision |

Trois notions à ne jamais confondre : monnaie virtuelle du jeu, achats
réels, rémunération réelle éventuelle des créateurs.

## Feuille de route des versions (validée)

Plan détaillé de la V0.2 en lots testables (proposition) : [`PLAN_V0.2.md`](PLAN_V0.2.md).

| Version | Thème | Contenu | Condition de passage |
|---------|-------|---------|----------------------|
| **V0.1** « Premier séjour » | Boucle simple et jouable | Étapes 0–12 | Tests verts + recette de stabilité + recette Android |
| **0.1.6** « Rythme » (validé) | Moins d'attente, sans devoir payer | Z1–Z6 (`PLAN_V0.1.6.md`) | Tests verts + critère des 90 s + recettes Android 0.1.6-a1 et 0.1.6 |
| **Prototype 3D** (proposé, isolé) | Valider la direction artistique | G-P0 à G-P8 | Recette Android du prototype + décision |
| **V0.2** « Immersion et découverte » | Donner envie de jouer, faire vivre l'île | O1–O3 (introduction, nom), V1b–V1c (habitants et voyageurs qui se déplacent), F1 (marché de Malia), A1–A3 (paniers réalistes, migration), C1 (ressources achetées au marché), T1–T2 (premières expériences), C4 partiel + N6 (premières fiches pédagogiques) | Tests verts (non-régression V0.1) + simulation « production ≤ un tiers des actions » + recette Android |
| **V0.2.5** « Réalités du métier » | La gestion au centre | S1–S3 et I1 (premiers incidents), R1–R6 (avis et réputation), E1–E2 (charges par séjour), bilan financier (chiffre d'affaires propriétaires, commission, coûts, marge), premières décisions à conséquences (décoration, situations), B1–B4 | Tests verts + recette Android |
| **V0.3** « Développement de l'entreprise » | Grandir | P1–P4 et F2–F3 (recrutement, délégation, prestataires), M1–M4 (mandats et négociations), A4–A6, C2, T3–T6 (artisanat et activités avancés), E3–E4, D1, V1d, I2–I5, Bungalow Corail | Tests verts + recette Android |
| **V0.4** « L'investisseur et l'île vivante » | Investir | C3, C5, F4, O4, X2–X4, V2–V3, D2–D10, R7–R13, N8–N10 | Tests verts dont non-dominance + recette Android |
| **V0.5** « L'archipel » | Plusieurs destinations | N11–N12, R14 | Relecture culturelle des fiches |
| **V1.0** | Finition | Équilibrage, accessibilité, monétisation éthique ($1–$4) si décidée | Simulation sans achat validée |

Exigences transverses (validées) :

1. Introduction **interactive, courte et passable**, qui donne envie de jouer immédiatement.
2. Recettes **cohérentes et pédagogiques** : les fruits sont le **contenu** du panier,
   jamais son matériau ; le contenant est une corbeille tressée en fibres végétales.
3. **Gestion financière dès la V0.2.5** : mécanique centrale.
4. Animations **au service de l'immersion ou du jeu**, sans actions répétitives inutiles.
5. **Sauvegardes existantes, tests automatisés et compatibilité Android préservés** à chaque version.

## Points ouverts

- 💡 Retour haptique au tap sur Android (`Input.vibrate_handheld`), à évaluer sur appareil.
- 💡 Recentrer la caméra sur le bâtiment sélectionné quand le panneau le masque.
- 💡 Mettre à l'échelle le seuil de tap selon la densité de l'écran (`DisplayServer.screen_get_dpi`).
- 💡 Bulles des personnages : éviter qu'elles passent sous le bandeau d'objectif.
- 💡 Message au joueur après une sauvegarde récupérée ou réinitialisée (toast), quand le système de notifications existera.
- 💡 Destinées : durée d'un jour de jeu (temps réel ou cycles d'activité) à décider avant D1.
- 💡 Choix de la première destination réelle et des relecteurs culturels.
- 💡 Portraits des PNJ : semi-réalistes illustrés, 6 expressions (`ART_DIRECTION.md` §8) ; mode de production à décider.
- 💡 Animation légère de l'eau (à mesurer en performances sur appareil d'entrée de gamme).
