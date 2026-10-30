# Backlog — Island Concierge

Légende : ✅ fait · 🔜 prochaine étape · ⬜ à faire · 💡 idée à préciser.
Une tâche n'est cochée que si elle a été exécutée ou testée ; ce qui reste à
valider sur appareil est indiqué explicitement. 📱 = validé sur Android réel
(recette n°1, APK 0.1.0) ; 🧪 = vérifié par tests automatisés ou simulation.

## V0.1 — boucle de réservation jouable

| Statut | Étape | Reste à valider |
|--------|-------|-----------------|
| ✅ 🧪 | 0 · Squelette du projet, GUT, i18n | — |
| ✅ 🧪 📱 | 1 · Carte isométrique de Mahana | — (affichage validé sur appareil) |
| ✅ 🧪 📱 | 2 · Caméra tactile (glisser, pincer, molette, limites, inertie) | Sur appareil : lever un doigt pendant un pincement, tap imprécis, inertie |
| ✅ 🧪 📱 | 3 · Bungalow Hibiscus interactif | Sur appareil : tap sur le toit |
| ✅ 🧪 📱 | 4 · Export Android debug | Sur appareil : encoche, mise en arrière-plan |
| ✅ 🧪 | 5 · Économie de base (coquillages, inventaire, HUD) | Sur appareil : lisibilité de la barre de ressources (APK 0.1.1) |
| ✅ 🧪 | 6 · Base de données et validation de `data/` (tous les bâtiments de Mahana sur la carte) | Sur appareil : panneaux des nouveaux bâtiments |
| 🔜 | 7 · Réservations (bureau, durée de séjour, commission) | |
| ⬜ | R1–R2 · Réputation : calcul de note, registre d'avis, paliers | |
| ⬜ | 8 · Productions (ananas, panier d'accueil) | |
| ⬜ | R3–R4 · Réputation : journal de séjour, avis en fin de séjour | |
| ⬜ | 9 · Progression et tutoriel narratif avec Hina (N1–N5) — scénario v2 : progression par actions, dialogues passables, décision de décoration | |
| ⬜ | N6–N7 · Carnet de voyage (3 fiches) et validation du contenu | |
| ⬜ | 10 · Sauvegarde et chargement | |
| ⬜ | R5–R6 · Réputation : effets et missions de redressement | |
| ⬜ | 11 · Tiki bar | |
| ⬜ | 12 · Finitions V0.1 | |

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

## Feuille de route des versions

| Version | Contenu | Condition de passage |
|---------|---------|----------------------|
| V0.1 | Boucle de gestion complète (étapes 0–12), tutoriel avec Hina (N1–N5), réputation de base (R1–R6), carnet (N6–N7) | Tests verts + recette Android de la boucle complète |
| V0.2 | Réputation avancée (R7–R13), narration (N8–N10) | Tests verts + recette Android |
| V0.3 | Destinées de l'archipel (D1–D10), cadre multi-destinations (N11) | Tests verts dont non-dominance + recette Android |
| V0.4+ | Première destination réelle (N12), expansion (R14) | Relecture culturelle des fiches |

## Points ouverts

- 💡 Retour haptique au tap sur Android (`Input.vibrate_handheld`), à évaluer sur appareil.
- 💡 Recentrer la caméra sur le bâtiment sélectionné quand le panneau le masque.
- 💡 Mettre à l'échelle le seuil de tap selon la densité de l'écran (`DisplayServer.screen_get_dpi`).
- 💡 Destinées : durée d'un jour de jeu (temps réel ou cycles d'activité) à décider avant D1.
- 💡 Choix de la première destination réelle et des relecteurs culturels.
- 💡 Portraits des PNJ : style graphique à définir (originaux).
- 💡 Animation légère de l'eau (à mesurer en performances sur appareil d'entrée de gamme).
