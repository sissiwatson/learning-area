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
| 🔜 | 11 · Tiki bar (construction, niveau 2, 150 coquillages) | |
| ⬜ | 12 · Finitions V0.1 (cadrage initial U1, crédits, équilibrage, recette Android) | |

Reporté en V0.2 : réputation R1–R6, carnet N6–N7, décision de décoration,
demande de voyageurs et avis détaillé du tutoriel (séquences 5 et 8).

## UX — retours de recette (APK 0.1.1)

Non bloquants pour les étapes 6 à 9 ; à traiter dans une passe UX dédiée.

| Statut | Amélioration | Notes |
|--------|--------------|-------|
| ⬜ | U1 · Cadrage initial mettant en valeur l'île et le bungalow | zoom et centre de départ en données ; capture avant/après |
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
| ⬜ | X1 · Services vendus aux voyageurs (excursion avec Tao, dîner chez Malia, transferts) | N9, E1 |
| ⬜ | X2 · Investissements (boîte à clés, linge de qualité, véhicule, outillage) | E1 |
| ⬜ | X3 · Partenariats (bateau, restaurants, artisans) | X1, M1 |
| ⬜ | X4 · Acquisition de biens : propriétaire-investisseur (revenus, travaux, vacance) | E4, M2 |

### Vie de l'île (lot V)

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| 🟡 | V1 · Animations d'ambiance : **commencé en V0.1** (personnages qui se balancent, bateau de Tao, voyageurs qui marchent) ; à poursuivre en V0.2 (promeneurs, autres bateaux, eau) — mesurées sur appareil d'entrée de gamme | — |
| ⬜ | V2 · Habitants et commerces qui évoluent selon les choix | N2, D3 |
| ⬜ | V3 · Événements culturels (Fête des Lumières) et activités | D1, N10 |

### Monétisation future (lot $) — V1.0 au plus tôt

Principes : [`GAME_VISION.md`](GAME_VISION.md) §6 (jamais obligatoire, jamais de
réputation achetée, accélérations plafonnées, transparence).

| Statut | Étape | Dépend de |
|--------|-------|-----------|
| ⬜ | $1 · Perles gagnées en jeu (monnaie déjà extensible) | 5 |
| ⬜ | $2 · Accélérations limitées (plafond quotidien, exclues des décisions) | $1 |
| ⬜ | $3 · Packs décoratifs, conforts, extensions | $1 |
| ⬜ | $4 · Simulation : progression complète atteignable sans achat | $2–$3 |

## Feuille de route des versions

| Version | Contenu | Condition de passage |
|---------|---------|----------------------|
| **V0.1** « Premier séjour » | Étapes 0–12 ci-dessus : boucle simple, XP et niveaux, quêtes de Hina, animation de production, tiki bar | Tests verts + recette Android |
| **V0.2** « Le métier de concierge » | S1–S3, I1, E1–E2 (charges par séjour, marge), R1–R6, B1–B4, décoration, N6–N7 | Tests verts + recette Android |
| **V0.3** « L'entreprise » | P1–P4, M1–M4, E3–E4 (charges fixes, trésorerie, tableau de bord), X1, I2–I5, Bungalow Corail | Tests verts + recette Android |
| **V0.4** « L'investisseur et l'île vivante » | X2–X4, V1–V3, D1–D10 (« L'avenir de la baie »), R7–R13, N8–N10 | Tests verts dont non-dominance + recette Android |
| **V0.5** « L'archipel » | N11–N12, R14 | Relecture culturelle des fiches |
| **V1.0** | Équilibrage, accessibilité, monétisation éthique ($1–$4) si décidée | Simulation sans achat validée |

## Points ouverts

- 💡 Retour haptique au tap sur Android (`Input.vibrate_handheld`), à évaluer sur appareil.
- 💡 Recentrer la caméra sur le bâtiment sélectionné quand le panneau le masque.
- 💡 Mettre à l'échelle le seuil de tap selon la densité de l'écran (`DisplayServer.screen_get_dpi`).
- 💡 Bulles des personnages : éviter qu'elles passent sous le bandeau d'objectif.
- 💡 Message au joueur après une sauvegarde récupérée ou réinitialisée (toast), quand le système de notifications existera.
- 💡 Destinées : durée d'un jour de jeu (temps réel ou cycles d'activité) à décider avant D1.
- 💡 Choix de la première destination réelle et des relecteurs culturels.
- 💡 Portraits des PNJ : style graphique à définir (originaux).
- 💡 Animation légère de l'eau (à mesurer en performances sur appareil d'entrée de gamme).
