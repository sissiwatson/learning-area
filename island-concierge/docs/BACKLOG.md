# Backlog — Island Concierge

Légende : ✅ fait · 🔜 prochaine étape · ⬜ à faire · 💡 idée à préciser.
Une tâche n'est cochée que si elle a été exécutée ou testée ; ce qui reste à
valider sur appareil est indiqué explicitement.

## V0.1 — boucle de réservation jouable

| Statut | Étape | Reste à valider |
|--------|-------|-----------------|
| ✅ | 0 · Squelette du projet, GUT, i18n | — |
| ✅ | 1 · Carte isométrique de Mahana | Rendu avec le renderer Mobile (captures faites en compatibilité OpenGL) |
| ✅ | 2 · Caméra tactile (glisser, pincer, molette, limites, inertie) | Gestes réels sur appareil Android ; réglage du seuil de tap et de l'inertie au doigt |
| ✅ | 3 · Bungalow Hibiscus interactif | Lisibilité du panneau et taille des boutons sur un vrai téléphone |
| ✅ | 4 · Export Android debug (APK construit, signé, vérifié) | **Installation et liste de vérification sur appareil** (`ANDROID_EXPORT.md`) |
| 🔜 | 5 · Économie de base (coquillages, inventaire, HUD) | |
| ⬜ | 6 · Base de données et validation de `data/` | |
| ⬜ | 7 · Réservations (bureau, durée de séjour, commission) | |
| ⬜ | R1–R2 · Réputation : calcul de note, registre d'avis, paliers | |
| ⬜ | 8 · Productions (ananas, panier d'accueil) | |
| ⬜ | R3–R4 · Réputation : journal de séjour, avis en fin de séjour | |
| ⬜ | 9 · Progression et quêtes guidées | |
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

## Points ouverts

- 💡 Retour haptique au tap sur Android (`Input.vibrate_handheld`), à évaluer sur appareil.
- 💡 Recentrer la caméra sur le bâtiment sélectionné quand le panneau le masque.
- 💡 Mettre à l'échelle le seuil de tap selon la densité de l'écran (`DisplayServer.screen_get_dpi`).
- 💡 Animation légère de l'eau (à mesurer en performances sur appareil d'entrée de gamme).
