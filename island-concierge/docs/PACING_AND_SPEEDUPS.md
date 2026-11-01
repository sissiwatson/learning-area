# Rythme, accélérations, boutique et introduction

> Statut : **proposition à valider avant tout code.** Fait suite à la recette
> Android 0.1.5 (`ANDROID_EXPORT.md`, recette n°4). Rien de ce document n'est
> développé.

## 1. Bilan de la recette Android 0.1.5

| Constat (votre retour) | Nature | Bloquant ? |
|------------------------|--------|-----------|
| Le jeu fonctionne | — | — |
| Attentes trop longues pendant les séjours : plus de 6 min d'attente avec encore environ 5 min restantes | rythme (game design), pas un bug | **Oui pour l'expérience** : c'est le premier séjour du tutoriel, au moment où le joueur décide de continuer ou non |

Points de la liste n°4 non mentionnés dans votre retour (je ne les
considère pas comme validés) : cadrage selon le format du téléphone, taille
constante des étiquettes, panneau et dialogue, panneau long, commission des
offres, installation par-dessus 0.1.4, session de 15 min, boutons d'action.
Un simple « OK / pas OK » sur chacun suffira.

### Diagnostic chiffré (données actuelles)

| Séjour proposé | Nuits | Durée réelle (5 min par nuit) | Commission | Commission par minute |
|----------------|------:|------------------------------:|-----------:|----------------------:|
| Léa (1 voyageur) | 1 | 5 min | 50 | 10 |
| Camille et Noé (2) | 2 | 10 min | 120 | 12 |
| Amaru et ses amis (2) | 3 | 15 min | 168 | 11,2 |
| Famille Morel (4) | 2 | 10 min | — (Bungalow Corail verrouillé) | — |

Pendant le premier séjour du tutoriel (10 min), **rien d'utile n'est
disponible** : un seul logement, productions terminées, tiki bar réservé au
niveau 2 (atteint *après* le premier encaissement). Le tutoriel d'environ
20 minutes contient donc environ 10 minutes d'attente pure. Votre attente
(plus de 6 min, environ 5 restantes) correspond à un séjour de 2 ou 3 nuits.

**Conclusion** : la durée d'une nuit n'est pas le seul problème ; il manque
des choses à faire pendant un séjour. Les accélérations (§2) traitent le
symptôme tout de suite ; les activités (§5) traitent la cause en V0.2.

## 2. Accélération facultative des minuteurs

### 2.1 Règles

| Règle | Comment elle est garantie |
|-------|---------------------------|
| Toujours **facultative** | La boucle gratuite (récolte → panier → ménage → accueil → séjour → encaissement) reste jouable sans dépenser ; tests anti-blocage existants inchangés, plus un test « 10 séjours sans aucune accélération » |
| **Jamais de solde négatif** | Paiement par `Wallet.spend` (tout-ou-rien, refus si solde insuffisant) ; bouton désactivé avec « Il manque X coquillages » |
| **Jamais deux fois la commission** | L'accélération ne fait que rapprocher la fin du minuteur ; l'encaissement reste le seul à payer, déjà idempotent (`paid_bookings`) |
| **Jamais deux paiements pour un double toucher** | La demande porte la fin de minuteur affichée ; si elle ne correspond plus (déjà accéléré), refus sans paiement |
| **Sauvegarde correcte** | La fin du minuteur est déjà sauvegardée ; on ajoute la liste des accélérations du séjour (montant, gain de temps, horodatage) pour l'historique et la future comptabilité |
| **Horloge modifiée** | Nouvelle fin = max(maintenant, fin − réduction), avec le temps monotone existant : reculer l'horloge ne rend rien, avancer ne fait rien payer |
| **Tarifs configurables** | Barème en données (`SpeedupDef`) : prix par minute restante, paliers, plafonds, coût minimal |
| Aucune influence sur la satisfaction, les avis ou les relations | Les règles de réputation (V0.2.5) ne lisent pas les accélérations |

### 2.2 Paliers proposés (valeurs à équilibrer)

> **Remplacé** par le barème équilibré de [`PLAN_V0.1.6.md`](PLAN_V0.1.6.md) §2
> (20 % de la commission au plus, prix cumulatif, paliers « Une nuit passe » et
> « Fin du séjour »). Le texte ci-dessous est la première proposition.

Prix = **4 coquillages par minute restante entamée**, soit environ un tiers
de ce que le séjour rapporte par minute (10 à 12).

| Palier | Effet | Prix pour Camille et Noé, 10 min restantes |
|--------|-------|--------------------------------------------|
| « Une heure de plus au soleil » | −2 min | 8 |
| « La journée passe » | −50 % du temps restant | 20 |
| « Fin du séjour » | termine maintenant | 40 (commission 120 ⇒ gain net 80) |

Plusieurs accélérations successives sont permises sur le même séjour ;
chacune est payée au prix du temps qui reste alors.

**Cohérence économique.** Accélérer ne coûte jamais plus que ce que le séjour
rapporte (au maximum un tiers de la commission). L'accélération reste un
choix : gagner moins mais plus vite. Le rythme d'apparition des offres
(une par minute, deux au maximum) limite de toute façon les gains par heure,
donc pas d'emballement.

**Tutoriel.** Le joueur commence avec 50 coquillages et le tiki bar en
coûte 150 (solde final prévu : 20). Une accélération payante dans le
tutoriel fausserait ce budget. Proposition : pendant le premier séjour,
Hina offre **une accélération gratuite, une seule fois** (« Les nuits
passent vite à Mahana… »). Le joueur apprend que la fonction existe sans y
laisser ses coquillages. Les accélérations payantes s'ouvrent ensuite.

### 2.3 Ménage et constructions : une décision de gestion

Payer pour « faire passer le temps » n'a pas d'équivalent dans le vrai
métier. Payer **du renfort**, si. Je propose donc des habillages différents :

| Minuteur | Habillage | Effet (proposition) | Prix (proposition) | Ce que le joueur apprend |
|----------|-----------|---------------------|--------------------|--------------------------|
| Séjour | « Avancer le temps » (confort de jeu) | paliers du §2.2 | 4 / min | — (assumé comme confort, voir §2.4) |
| Ménage (2 min) | « Renfort de ménage » | terminé en 30 s | 15 | coût de la main-d'œuvre contre le délai (annonce le lot P, personnel) |
| Construction (tiki bar, 5 min) | « Équipe renforcée » | −50 % du temps restant | 10 par minute retirée | arbitrer coût et délai d'un chantier |
| Productions (30 s, 1 min) | aucune | — | — | trop courtes ; en V0.2, acheter au marché de Malia remplace l'accélération |

### 2.4 Où classer ces dépenses (cohérence avec la V0.2.5)

Le porte-monnaie de coquillages est la **trésorerie de la conciergerie**.
Dans le futur bilan financier :
- renfort de ménage et équipe renforcée = **charges d'exploitation** (réalistes) ;
- « Avancer le temps » = **ligne séparée, hors exploitation** (« confort de
  jeu »), pour ne pas fausser la marge que le jeu veut enseigner.

À valider.

### 2.5 Tests prévus

Refus si solde insuffisant (solde inchangé) ; paliers et arrondis ;
double toucher sans double paiement ; accélération puis sauvegarde puis
rechargement puis encaissement (une seule commission) ; horloge reculée ou
avancée ; accélération gratuite du tutoriel donnée une seule fois, même
après rechargement ; partie complète sans aucune accélération (anti-blocage) ;
joueur aléatoire de la recette de stabilité étendu aux accélérations.

## 3. Monétisation future : étude de boutique (rien à développer)

1. **Deux caisses séparées.**
   - **Coquillages** = trésorerie de l'entreprise, gagnés en jouant.
   - **Perles** = compte du joueur, premium, achetables plus tard et
     gagnables en jeu en petite quantité.
   - Les perles **ne se convertissent jamais en coquillages**. Sinon on
     achèterait la rentabilité et le bilan financier n'aurait plus de sens.
2. **Ce que les perles peuvent acheter** (proposition) :
   - modèles de décoration du mode express (le plan, pas les meubles, voir `DECORATION.md`) ;
   - variantes purement visuelles, aux effets identiques aux versions gratuites ;
   - conforts d'interface.
   - **Jamais** : réputation, avis, relations, confiance des propriétaires,
     meubles aux statistiques supérieures, coquillages.
3. **Accélérations** (décision du 01/11) :
   - en 0.1.6, coquillages seulement ;
   - **plus tard, les perles** pourront aussi payer les accélérations et
     certains conforts.
   - Les perles s'obtiennent **en jouant** ou dans des **packs facultatifs**.
     Aucun achat réel n'est développé maintenant.
   - Conception déjà compatible : un devis porte sa monnaie (`currency`), et
     un barème en perles pourra s'ajouter au barème en coquillages sans
     changer les règles (prix cumulatif, offerte, double toucher).
   - Une dépense en perles n'apparaîtra **jamais** dans la trésorerie de la
     conciergerie. Elle reste en « confort de jeu ».
   - Plafond quotidien proposé (`GAME_VISION.md` §6), à décider avec la boutique.
   - Dans les bilans financiers :
     - accélérations de confort = catégorie `comfort`, hors exploitation ;
     - renforts = `operating_charge`.
     - Le classement existe dans le journal depuis la 0.1.6 (lot 1).
4. **Boutique (architecture prévue)** :
   - catalogue de produits en données ;
   - un `StoreService` avec deux fournisseurs, un faux pour les tests et le
     développement (aucun paiement réel), et plus tard Google Play ;
   - crédit **idempotent** par identifiant d'achat, enregistré dans la sauvegarde ;
   - restauration des achats.
   - Une vérification des reçus côté serveur sera nécessaire avant toute
     vraie vente. C'est un chantier à part.
5. **Principes inchangés** :
   - aucun achat obligatoire ;
   - prix affichés en monnaie réelle ;
   - aucun coffre aléatoire payant ;
   - pas de compte à rebours pressant ;
   - respect du contrôle parental.
   - Sur Google Play, les biens numériques vendus dans l'application passent
     par la facturation Google Play.
   - Une étude juridique (consommateurs, mineurs, fiscalité) est à mener
     avant la V1.0.

## 4. Introduction

- **Confirmé : l'introduction n'est pas dans la 0.1.5.** Le jeu s'ouvre sur
  le dialogue de Tao, qui est le dialogue d'introduction de la quête 1
  (`data/quests/tutorial_01.tres`). Il n'y a ni scène d'introduction ni
  saisie du nom.
- **« Revoir l'introduction »** dans les Réglages : rejoue la scène en
  **mode lecture**. Ni l'état de la partie ni la sauvegarde ne sont
  modifiés (le nom actuel est affiché ; le changer reste une option séparée
  des Réglages).
  - Test : la sauvegarde est identique, octet pour octet, avant et après le
    visionnage.
  - Déjà prévu au lot 0.3 et au lot O2 de `PLAN_V0.2.md`.

## 5. Rythme : des choses utiles à faire pendant un séjour

**Objectif mesurable.** Sur les 30 premières minutes, **aucun temps mort de
plus de 90 secondes** sans action utile disponible. Les accélérations ne
comptent pas comme action utile. La mesure est faite par la simulation du
lot 0.2 (`PLAN_V0.2.md`), à chaque jalon.

Activités introduites progressivement, toutes rattachées à des lots existants :

| Pendant un séjour… | Ce que le joueur fait | Ce qu'il apprend | Lot / version |
|--------------------|-----------------------|------------------|---------------|
| **Demandes des voyageurs** | message des voyageurs (« Où dîner ce soir ? », « Le ventilateur fait du bruit ») avec 2 ou 3 réponses | réactivité, communication | version légère en V0.2 (commentaire et historique), notes en V0.2.5 (I1, S1) |
| **Expériences touristiques** | proposer la balade botanique ou la rencontre au marché **aux voyageurs présents** | vente de services, marge | T1–T2, V0.2 |
| **Préparer les prochains séjours** | stock de paniers, achats au marché, offre suivante | anticiper, gérer un stock | F1, A1, V0.2 |
| **Découvrir l'île** | parler aux habitants, débloquer des fiches du carnet | culture, réseau local | N6, V0.2 |
| **Gérer les prestataires** | planifier un renfort, comparer les tarifs | coûts, délais, qualité | P1–P2, F2, V0.3 |
| **Second logement** | Bungalow Corail : deux séjours en parallèle | gérer plusieurs biens | V0.3 (le déverrouiller plus tôt est une option à étudier) |

Garde-fou : chaque activité est une **décision** ou une **rencontre**, jamais
un tap répétitif (`GAME_VISION.md` §6 bis).

## 6. Ordre d'implémentation proposé

| # | Livraison | Contenu | APK de recette |
|---|-----------|---------|----------------|
| 1 | **0.1.6 « Rythme »** | Règles d'accélération (tests), « Avancer le temps » sur les séjours, accélération offerte une fois dans le tutoriel, renfort de ménage, équipe renforcée | 0.1.6 |
| 2 | V0.2, jalon 0 | Sauvegarde v2, mesure des temps morts et du mélange d'actions, Réglages avec « Revoir l'introduction » | — |
| 3 | V0.2, jalon 1 | Introduction et nom (voir `TRANSITION_3D.md` §8 sur l'interaction avec le prototype 3D) | 0.2.0-a1 |
| 4 | V0.2, jalons suivants | Demandes des voyageurs (version légère) avancées dans le jalon 4, avec les expériences : elles traitent directement les temps morts | à chaque jalon |
| 5 | V1.0 au plus tôt | Boutique (faux fournisseur d'abord) | — |

Je ne modifie pas la durée des nuits sans votre accord. Si les accélérations
ne suffisent pas à la recette 0.1.6, la valeur à revoir serait
`night_seconds` (300 s). C'est une donnée, sans changement de mécanique.
