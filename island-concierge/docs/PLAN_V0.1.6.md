# Plan d'exécution — V0.1.6 « Rythme »

> Statut : **plan validé dans son principe** (votre retour du 30/10).
> Le **lot 1** est détaillé au §4 et attend votre accord avant implémentation.
> Conception : `PACING_AND_SPEEDUPS.md` ; le barème ci-dessous **remplace**
> son §2.2.

## 1. Objectifs et critères de sortie

1. **Moins d'attente sans payer.** Sur les 30 premières minutes d'une partie
   neuve, aucun temps mort de plus de 90 s.
   - Mesuré par une simulation « joueur raisonnable » **sans aucune
     accélération** (lot 4).
2. **Accélérations facultatives et équilibrées.**
   - Elles ne coûtent jamais plus de **20 % de ce que rapporte le séjour**.
   - Une accélération est offerte pendant le tutoriel.
   - Elles ne sont jamais nécessaires pour progresser.
3. **Confort et charges séparés.**
   - « Avancer le temps » est classé **confort de jeu, hors exploitation**.
   - Les renforts (ménage, chantier) sont des **charges d'exploitation**.
   - Les deux catégories sont distinguées dès maintenant dans le journal,
     pour le bilan financier de la V0.2.5.
4. **Non-régression.**
   - Les 310 tests existants restent verts, avec 0 erreur moteur.
   - Une vraie sauvegarde 0.1.5 se charge sans perte.
   - La recette de stabilité (aléatoire, singe, endurance) est étendue aux accélérations.
5. **Recettes Android** :
   - 0.1.6-a1 après les accélérations ;
   - 0.1.6 finale après les activités.

## 2. Barème équilibré (remplace `PACING_AND_SPEEDUPS.md` §2.2)

### Séjours — « Avancer le temps » (confort de jeu)

**Prix = 20 % de la commission du séjour × part du séjour retirée**, arrondi
à l'unité supérieure, au moins 1 coquillage.
- Le prix suit la valeur du séjour : un petit séjour coûte peu.
- Un séjour terminé d'un coup ne coûte jamais plus d'un cinquième de sa
  commission.

| Palier | Effet | Léa (1 nuit, commission 50) | Camille et Noé (2 nuits, 120) | Amaru (3 nuits, 168) |
|--------|-------|----------------------------:|------------------------------:|---------------------:|
| « Une nuit passe » | −1 nuit (ou le reste s'il en reste moins) | 10 | 12 | 12 |
| « Fin du séjour » au début du séjour | tout le temps restant | 10 | 24 | 34 |
| « Fin du séjour » à mi-séjour | la moitié restante | 5 | 12 | 17 |

Paliers enchaînables. Pour que les arrondis ne s'additionnent pas, le prix
est **cumulatif** : prix d'un palier = plafond(20 % × C × temps retiré
au total après ce palier / durée) − plafond(20 % × C × temps retiré
avant / durée). La somme payée sur un séjour vaut donc au plus
plafond(20 % × C).

Exemple, Amaru : « Une nuit passe » trois fois donne 12 + 11 + 11 = 34,
exactement le prix de « Fin du séjour » d'un coup. Avec un arrondi à chaque
palier, on aurait payé 36.

**Tutoriel** : la première accélération est **offerte**, une seule fois par
partie, y compris pour une ancienne sauvegarde.

### Renforts — charges d'exploitation (lot 3)

| Renfort | Effet | Prix (données) |
|---------|-------|---------------:|
| Renfort de ménage | le ménage en cours se termine 30 s après | 10 |
| Équipe renforcée (chantier) | −50 % du temps restant | 4 par minute retirée (10 pour le tiki bar juste lancé) |

Tous les prix sont des **données** (`data/balance/speedups.tres`), ajustables
sans code.

## 3. Lots

| # | Lot | Visible ? | Preuves | APK |
|---|-----|-----------|---------|-----|
| **1** | **Socle des accélérations** : barème en données, règles pures, commande dans `GameState`, catégories du journal, sauvegarde ; fixture d'une vraie sauvegarde 0.1.5 | non | tests unitaires et d'intégration, contre-épreuves, stabilité étendue | — |
| 2 | « Avancer le temps » dans le panneau du séjour (paliers, prix, « Il manque X ») ; accélération offerte présentée par Hina pendant le premier séjour | oui | tests d'interface, vrai toucher sous Xvfb, captures aux 3 formats | — |
| 3 | Renfort de ménage et équipe renforcée (charges d'exploitation) | oui | idem, plus un test « tutoriel complet sans aucune accélération, solde final 20 » | **0.1.6-a1** |
| 4 | **Mesure des temps morts** : simulation d'un joueur raisonnable sur 30 min (avec horloge simulée), rapport des intervalles sans action utile ; situation de départ chiffrée | non | rapport versionné ; test qui échouera au-delà de 90 s, activé au lot 6 | — |
| 5 | **Activités pendant le premier séjour** : deux quêtes parallèles du tutoriel — « Les habitants de Mahana » (parler à Tao, Malia et Kimo, une courte scène chacun) et « Un panier d'avance » (préparer le panier des prochains voyageurs) ; récompense en XP seulement (budget du tutoriel inchangé) | oui | quêtes testées ; ancienne sauvegarde : quêtes proposées sans rejouer le tutoriel ; mesure du lot 4 refaite | — |
| 6 | **Demandes des voyageurs** (version légère) : pendant le séjour, 1 ou 2 messages (« Où dîner ce soir ? ») avec 2 ou 3 réponses ; réponse notée dans l'historique du séjour, XP pour une réponse adaptée, aucun effet de réputation (V0.2.5) ; pastille « ! » sur le logement | oui | règles déterministes testées ; aucune demande après la fin du séjour ; sauvegarde | — |
| 7 | **Clôture** : recette de stabilité étendue, audit aux 3 formats, critère des 90 s activé, documentation, APK | — | `STABILITY_V0.1.6.md` | **0.1.6** |

Ce qui n'est **pas** dans la 0.1.6 :
- la durée des nuits ne change pas ;
- pas de nouveau bâtiment, pas de marché, pas de réputation ;
- pas d'accélération des productions.

Le Bungalow Corail reste verrouillé.

Les dialogues des lots 5 et 6 relèvent de la **fiction de Mahana** et sont
étiquetés comme tels ; aucun fait réel n'y est affirmé sans source.

## 4. Lot 1 — Socle des accélérations (à valider avant implémentation)

### 4.1 Ce qui change

Rien de visible pour le joueur. On ajoute les règles, les données et la
sauvegarde. L'interface viendra au lot 2.

| Fichier | Changement |
|---------|------------|
| `src/defs/speedup_def.gd` + `data/balance/speedups.tres` | barème : part de commission (0,20), paliers (`one_night`, `finish`), coût minimal (1), accélérations offertes (1), renforts (lot 3, déjà décrits mais non utilisés) |
| `src/core/speedup_rules.gd` (pur) | `quote_stay(tier, commission, total, remaining, night_seconds)` → réduction (s) et prix ; aucune dépendance au moteur de jeu |
| `src/core/lodging.gd` | `shorten(now, seconds, expected_end)` pendant un séjour (`OCCUPIED`) uniquement ; nouvelle fin = max(maintenant, fin − réduction) ; refus si la fin affichée ne correspond plus (double toucher) ; liste `speedups` (palier, secondes, prix, offert ou non, horodatage) sauvegardée avec le logement |
| `src/autoload/game_state.gd` | `speed_up_stay(uid, tier, expected_end)` : vérifie, paie (ou consomme l'accélération offerte), applique, journalise, émet `stay_sped_up` ; `quote_speedup(uid, tier)` pour l'interface ; `free_speedups` sauvegardé |
| Journal | motif `comfort:speedup:<réservation>` ; table des catégories en données (`comfort:` → « Confort de jeu, hors exploitation », `charge:` → « Charges d'exploitation ») et fonction pure qui classe un motif |
| Historique des séjours | chaque séjour garde ses accélérations : nombre, temps gagné, coquillages dépensés |
| `tests/fixtures/save_0_1_5.json` | vraie sauvegarde produite par le code actuel **avant** toute modification, en pleine partie (séjour en cours, chantier, quêtes) |

### 4.2 Règles garanties

| Règle | Mécanisme |
|-------|-----------|
| Solde jamais négatif | `Wallet.spend` tout-ou-rien avant toute modification ; refus `not_enough_currency` sans effet |
| Une seule commission | l'encaissement reste inchangé et idempotent (`paid_bookings`) |
| Pas de double paiement (double toucher) | la commande porte la fin affichée ; si elle a changé : refus `stale_quote`, rien n'est payé |
| Ordre sûr | prix calculé → paiement → raccourcissement ; si le raccourcissement échoue après paiement (impossible par construction, mais vérifié), remboursement et erreur |
| Horloge | réduction calculée sur le temps restant au temps de jeu monotone ; horloge reculée : rien à rembourser ni à rejouer |
| Accélération offerte | consommée une seule fois, compteur sauvegardé ; une ancienne sauvegarde en reçoit une |
| Anti-blocage | aucune règle existante ne dépend des accélérations ; les tests anti-blocage restent inchangés |

### 4.3 Sauvegarde

- Ajouts **facultatifs** (`speedups` par logement, `free_speedups`) : une
  sauvegarde sans ces clés se charge avec les valeurs par défaut.
- Format v1 conservé ; pas de migration. La version 2 viendra avec la V0.2.
- Preuves :
  - la fixture 0.1.5 se charge sans perte et l'état est identique hors
    nouveaux champs ;
  - aller-retour avec accélérations identique.

### 4.4 Tests prévus (environ 20)

- **Barème** :
  - paliers des trois séjours (tableau du §2) ;
  - arrondi supérieur et minimum 1 ;
  - réduction jamais supérieure au temps restant ;
  - prix jamais supérieur à 20 % de la commission ;
  - séjour presque fini.
- **Refus sans effet** :
  - logement libre, réservé, en ménage, séjour terminé ;
  - solde insuffisant ;
  - logement verrouillé ou inconnu ;
  - palier inconnu.
- **Double toucher** : deux commandes avec la même fin affichée ; un seul
  paiement, une seule réduction.
- **Paiements** :
  - « Fin du séjour » puis encaissement : une seule commission ;
  - deuxième encaissement refusé.
- **Paliers enchaînés** : « Une nuit passe » deux fois, puis « Fin du
  séjour » ; la somme des prix est égale au prix de « Fin du séjour » d'un
  coup (prix cumulatif), donc ≤ plafond(20 % de la commission).
- **Accélération offerte** :
  - utilisée une fois, la suivante est payante ;
  - toujours vraie après sauvegarde et rechargement.
- **Horloge** : reculée puis accélération ; avancée après accélération.
- **Sauvegarde** :
  - aller-retour avec accélérations ;
  - fixture 0.1.5 ;
  - ancienne sauvegarde sans nouvelles clés.
- **Journal** :
  - le motif est classé « confort » ;
  - aucun motif de dépense existant n'est sans catégorie (garde-fou).
- **Stabilité** : le joueur aléatoire (3 graines × 1 500 actions) tente aussi
  des accélérations ; les invariants restent vrais, avec un nouvel
  invariant : les dépenses de confort d'un séjour restent ≤ plafond(20 % de
  sa commission).

Contre-épreuves :
- sans la vérification de la fin affichée, le test du double toucher doit
  échouer ;
- avec un arrondi à chaque palier (au lieu du prix cumulatif), le test des
  paliers enchaînés doit échouer.

### 4.5 Critères d'acceptation du lot 1

1. Tous les tests verts (310 existants + environ 20 nouveaux), 0 erreur moteur.
2. Aucun changement visible : les captures existantes sont identiques.
3. La fixture 0.1.5 se charge, et la partie continue comme avant.
4. Recette de stabilité étendue réussie.
5. Un commit poussé, et un compte rendu de ce qui est réellement vérifié.

### 4.6 Points à confirmer avant de coder

1. **Taux de 20 %** de la commission pour un séjour entier : le garder, ou
   le baisser (15 %) ?
2. **Paliers** : « Une nuit passe » et « Fin du séjour » vous conviennent-ils ?
   Ils remplacent les trois paliers de la première proposition.
3. **Une accélération offerte** aussi aux sauvegardes existantes : d'accord ?

## 5. Prototype 3D (après la 0.1.6)

Conformément à votre ordre :
- **Validation technique** : formes simples suffisantes ; mesure des
  interactions, de la caméra par paliers de 90°, de l'intérieur et des
  performances.
- **Validation artistique** : distincte, sur des ressources représentatives
  du rendu visé.

L'étape P0 commencera par un **inventaire de ressources 3D libres ou sous
licence compatible**, sans aucune dépense, pour chacune :
- source et licence exacte, vérifiée sur la page officielle ;
- usage commercial permis ;
- attribution requise ;
- cohérence avec la direction artistique.

Rien ne sera intégré sans licence vérifiée et inscrite dans `CREDITS.md`.
Les portraits seront **illustrés**, avec plusieurs expressions.
