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
   - Elles ne coûtent jamais plus de **15 % de ce que rapporte le séjour**
     (arrondi à l'entier supérieur).
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

### Séjours — « Avancer le temps » (confort de jeu) — **validé le 01/11**

**Prix = 15 % de la commission du séjour × part du séjour retirée**,
arrondi à l'entier supérieur. Le prix est affiché avant confirmation
(lot 2).

| Palier (libellé validé) | Effet | Léa (1 nuit, commission 50) | Camille et Noé (2 nuits, 120) | Amaru (3 nuits, 168) |
|-------------------------|-------|----------------------------:|------------------------------:|---------------------:|
| « Passer une nuit » | −1 nuit (ou le reste s'il en reste moins) | 8 | 9 | 9 |
| « Terminer le séjour » au début du séjour | tout le temps restant | 8 | 18 | 26 |
| « Terminer le séjour » à mi-séjour | la moitié restante | 4 | 9 | 13 |

**Prix cumulatif** : prix d'un palier = plafond(15 % × C × temps retiré au
total après ce palier / durée) − plafond(15 % × C × temps retiré avant /
durée).
- Plusieurs accélérations partielles ne coûtent jamais plus qu'une
  accélération complète.
- Exemple, Amaru : « Passer une nuit » trois fois donne 9 + 8 + 9 = 26,
  exactement « Terminer le séjour » d'un coup. Avec un arrondi à chaque
  palier, on aurait payé 27.

**Accélération offerte** : une accélération complète (« Terminer le
séjour ») est offerte une seule fois par partie, y compris aux sauvegardes
existantes.
- Le compteur est sauvegardé : il n'est jamais réattribué au rechargement
  ni par une mise à jour.
- « Passer une nuit » ne la consomme pas.

**Cohérence des séjours** : une accélération ne modifie ni la durée
contractuelle, ni le prix payé par le voyageur, ni la commission, ni les
revenus du propriétaire. Seul le minuteur de jeu se termine plus tôt.

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

## 4. Lot 1 — Socle des accélérations (✅ 🧪 réalisé, résultats au §4.7)

### 4.1 Ce qui change

Rien de visible pour le joueur. On ajoute les règles, les données et la
sauvegarde. L'interface viendra au lot 2.

| Fichier | Changement |
|---------|------------|
| `src/defs/speedup_def.gd` + `data/balance/speedups.tres` | barème : pourcentage de la commission (15), accélérations offertes (1) ; les renforts viendront au lot 3 |
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
  - prix jamais supérieur à 15 % de la commission (arrondi) ;
  - séjour presque fini.
- **Refus sans effet** :
  - logement libre, réservé, en ménage, séjour terminé ;
  - solde insuffisant ;
  - logement verrouillé ou inconnu ;
  - palier inconnu.
- **Double toucher** : deux commandes avec la même fin affichée ; un seul
  paiement, une seule réduction.
- **Paiements** :
  - « Terminer le séjour » puis encaissement : une seule commission ;
  - deuxième encaissement refusé.
- **Paliers enchaînés** : « Passer une nuit » plusieurs fois, puis
  « Terminer le séjour » ; la somme des prix est égale au prix de
  « Terminer le séjour » d'un coup (prix cumulatif).
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
  invariant : les dépenses de confort d'un séjour restent ≤ plafond(15 % de
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

### 4.6 Décisions (01/11)

Taux de 15 %, prix cumulatif, paliers « Passer une nuit » et « Terminer le
séjour », une accélération complète offerte une fois par partie (sauvegardes
existantes comprises, jamais réattribuée). Coquillages seulement en 0.1.6 ;
perles prévues dans la conception (`PACING_AND_SPEEDUPS.md` §3).

### 4.7 Résultats du lot 1 (🧪 vérifié par exécution, rien de visible)

- **Tests** : 336 au vert (310 existants inchangés + 26 nouveaux), 0 erreur
  moteur, 0 erreur de script.
  - 7 tests de barème, dont 500 séjours tirés au hasard pour vérifier le
    prix cumulatif ;
  - 4 tests du logement ;
  - 15 tests d'intégration : devis, offerte, double toucher, solde,
    réservation inchangée, sauvegarde, horloge, vraie sauvegarde 0.1.5,
    catégories, sauvegarde immédiate.
- **Vraie sauvegarde 0.1.5** (`tests/fixtures/save_0_1_5.json`, produite
  avant toute modification, commit séparé) :
  - elle se charge ;
  - le séjour de Léa, le chantier et le niveau 2 sont conservés ;
  - elle reçoit une offerte, une seule fois ;
  - la commission est encaissée une fois.
- **Contre-épreuves** (défaut introduit puis retiré) :

  | Défaut introduit | Résultat |
  |------------------|----------|
  | contrôle du double toucher retiré | 1 test échoue |
  | arrondi à chaque palier | 2 tests unitaires échouent (les tests d'intégration ne le voient pas : le séjour de Camille ne comporte pas d'arrondi) |
  | offerte réattribuée à chaque chargement | 3 tests échouent |
  | accélération qui modifie la réservation | 3 tests échouent |
  | barème doublé | la recette de stabilité le détecte dès le pas 86 |

- **Recette de stabilité** : 3 graines × 1 500 actions, accélérations
  comprises.
  - 24 accélérations réussies, dont des doubles touchers refusés ;
  - nouveaux invariants vrais à chaque pas : durée contractuelle inchangée,
    plafond de 15 %, temps retiré ≤ durée, offerte bornée, chaque mouvement
    d'argent catégorisé.
- **Aucun changement visible** : les 31 captures ont été comparées à celles
  de l'étape 12.
  - Les écarts viennent uniquement des animations en temps réel
    (balancement des personnages, fondu des messages, « +120 »).
  - Deux passes sur le même code diffèrent déjà de 800 à 1 500 pixels ;
    les deux plus grands écarts ont été vérifiés à l'œil.
- **Non vérifié** : rien sur appareil (rien de visible dans ce lot).

## 4 bis. Lot 2 — « Avancer le temps » dans le panneau (✅ 🧪 réalisé, 📱 recette n°5)

### Ce qui a été fait

- **Panneau d'un séjour en cours** : section discrète « Avancer le temps ».
  - Deux boutons secondaires (fond crème, contour lagon, 96 px de haut) :
    - « Passer une nuit · 9 coquillages » ;
    - « Terminer le séjour · offert (offre unique) », puis son prix une fois
      l'offre utilisée.
  - Rappel « Facultatif : le séjour se termine aussi tout seul. »
  - Si le solde ne suffit pas, bouton grisé « il manque X coquillages ».
  - Prix mis à jour chaque seconde et à chaque changement de solde.
- **Confirmation** : fenêtre centrée sur fond assombri.
  - Elle affiche le temps gagné, le prix (ou « Offert »), le solde après
    paiement, et la mention « Offre unique : Hina vous offre ce coup de pouce
    une seule fois par partie ».
  - Elle rappelle que les voyageurs gardent leur séjour.
  - Boutons « Annuler » et « Confirmer » / « Utiliser l'offre » (104 px).
  - Annuler, toucher le fond ou Échap : aucun effet.
  - Un dialogue qui commence, ou la fermeture du panneau, l'annulent aussi.
- **Revalidation au moment de confirmer** :
  - le devis est refait ;
  - séjour terminé entre-temps : refus sans débit, avec explication ;
  - solde devenu insuffisant : refus sans débit, avec le montant manquant ;
  - prix plus élevé que celui affiché (offre déjà utilisée) : refus sans
    débit, nouveau prix affiché ;
  - double toucher : un seul paiement.
- **Hina**, au début du premier séjour (dialogue de la quête « Encaisser sa
  commission »), une réplique ajoutée : « Si un jour tu es pressé, tu peux
  avancer le temps depuis le bungalow. La première fois, c'est moi qui
  offre. Mais rien ne presse : un séjour se termine aussi tout seul. »
- **Retour discret** après une accélération : message « Le temps file à
  Mahana (X de gagné). »
- **Défaut trouvé et corrigé en chemin** : la barre de progression et
  « Nuit x/y » repartaient de zéro après une accélération (calcul sur le
  minuteur raccourci). Le temps retiré compte désormais comme écoulé.

### Preuves (🧪)

- **354 tests verts** (336 + 18), 0 erreur moteur.
  - 17 tests d'interface : section visible seulement pendant un séjour,
    style et taille des boutons, textes et prix, montant manquant, contenu
    de la confirmation, offre unique et consommation unique, annulation
    (trois façons), application et progression, double toucher sur
    « Confirmer » et sur le bouton du panneau, séjour terminé pendant la
    confirmation, solde modifié pendant la confirmation, prix devenu plus
    élevé, dialogue qui annule, carte bloquée derrière la confirmation,
    réplique de Hina, contraste du texte (≥ 4,5:1).
  - 1 test unitaire : progression avec temps retiré.
- **Contre-épreuves** (défaut introduit puis retiré, chacune détectée) :
  - prix non revérifié ;
  - barre de progression sans le temps retiré ;
  - confirmation non rafraîchie quand le solde change ;
  - « Annuler » qui confirmerait.
- **Aucun test intermittent** : 8 exécutions de suite sans échec.
- **Vrai toucher** (souris émulée puis toucher, comme Android), sous Xvfb :
  scénario `touch_speedup_confirm` (« Passer une nuit » puis « Confirmer » ;
  le prix payé est celui affiché, aucune erreur moteur).
- **Captures aux 3 formats** (16:9, 20:9, 4:3) : 36 scénarios × 3, aucune
  erreur ; panneau et confirmation lisibles, rien de coupé.
- **Endurance 5 min** (joueur automatique qui touche aussi ces boutons) :
  0 erreur, mémoire 33,4 à 33,9 Mo, sans dérive.

### Non vérifié

- Tout ce qui se passe sur appareil : recette n°5 dans `ANDROID_EXPORT.md`.
- Le bouton retour d'Android ferme l'application (comportement existant,
  non modifié) ; il ne sert donc pas à annuler la confirmation.

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
