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
| 🔜 | 6 · Base de données et validation de `data/` | |
| ⬜ | 7 · Réservations (bureau, durée de séjour, commission) | |
| ⬜ | R1–R2 · Réputation : calcul de note, registre d'avis, paliers | |
| ⬜ | 8 · Productions (ananas, panier d'accueil) | |
| ⬜ | R3–R4 · Réputation : journal de séjour, avis en fin de séjour | |
| ⬜ | 9 · Progression et tutoriel narratif avec Hina (N1–N5) | |
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

## Points ouverts

- 💡 Retour haptique au tap sur Android (`Input.vibrate_handheld`), à évaluer sur appareil.
- 💡 Recentrer la caméra sur le bâtiment sélectionné quand le panneau le masque.
- 💡 Mettre à l'échelle le seuil de tap selon la densité de l'écran (`DisplayServer.screen_get_dpi`).
- 💡 Choix de la première destination réelle et des relecteurs culturels.
- 💡 Portraits des PNJ : style graphique à définir (originaux).
- 💡 Animation légère de l'eau (à mesurer en performances sur appareil d'entrée de gamme).
