# Demandes de réservation & profils voyageurs — conception

> Statut : **conception, non développée** (interface comprise).
> Lot « B » (voir §9 et `BACKLOG.md`). S'appuie sur le moteur de
> réservation de l'étape 7 : **un seul système de réservation**.

## 1. Objectif

Remplacer à terme le simple bouton « Accepter » par une **carte de demande
de séjour** : un voyageur fictif, avec son portrait, son message et ses
préférences, demande un logement précis pour une durée donnée. Le joueur lit,
compare et décide : accepter ou refuser. Certaines demandes expirent.

## 2. Principe d'architecture : pas de système concurrent

La carte n'est qu'une **présentation** des données du moteur existant :

| Existant (étape 7) | Évolution prévue (lot B) |
|--------------------|--------------------------|
| `BookingTemplateDef` (voyageurs, nuits, prix) | enrichi : profil voyageur, message, préférences, logement demandé, délai d'expiration |
| Offre de `BookingSystem` (`id`, modèle) | devient la **demande** : statut, dates, logement visé ; même identifiant |
| `Booking` (montants figés) | inchangé : créé à l'acceptation, comme aujourd'hui |
| `GameState.accept_offer` | inchangé ; s'ajoute `refuse_request` ; l'expiration est traitée par `tick` |
| Panneau du bureau (liste + « Accepter ») | remplacé par des cartes ; mêmes commandes |

Aucune règle de calcul n'est dupliquée : la commission affichée sur la carte
est celle que `Booking.commission()` versera.

## 3. Données

| Donnée | Où | Remarque |
|--------|----|----------|
| Identifiant unique | demande (`offer_0001`) puis réservation (`bk_0001`) | séquence déjà sauvegardée |
| Identité fictive, portrait | `GuestProfileDef` (`id`, `display_name`, `portrait`) | personnages fictifs, portraits originaux |
| Nombre de voyageurs | modèle | ≤ capacité du logement |
| Préférences | `GuestProfileDef.preferences` (ex. calme, cuisine locale, nature) et attentes de confort | alimentent les missions d'accueil et la satisfaction (`REPUTATION.md` §5) |
| Hébergement demandé | modèle (`lodging_building`) ou « indifférent » | si demandé : seul ce logement est proposé |
| Durée du séjour | modèle (`nights`) | |
| Prix par nuit et total | modèle / `Booking.revenue()` | |
| Taux et montant de commission | `LodgingDef.commission_percent` / `Booking.commission()` | affichés **avant** acceptation |
| Message du voyageur | clé i18n du modèle | |
| Statut | `PENDING`, `ACCEPTED`, `REFUSED`, `EXPIRED` | historique conservé |
| Délai d'expiration | modèle (`expires_after_seconds`, 0 = jamais) | temps réel |
| Demande du tutoriel | `tutorial = true` | n'expire jamais |

## 4. Règles

1. Commission **déterministe**, affichée avant acceptation ; identique au
   montant versé.
2. **Revenus séparés** : part du propriétaire et commission de la
   conciergerie sont enregistrées séparément (déjà le cas dans
   `stay_history`).
3. Voyageurs ≤ capacité du logement : sinon la demande ne peut pas être
   acceptée (déjà `capacity_exceeded`).
4. Une demande ne peut être acceptée **qu'une fois** (déjà `unknown_offer`
   après acceptation).
5. **Refus** et **expiration** ne génèrent **aucun revenu** et libèrent la place.
6. Les demandes du tutoriel **n'expirent pas**.
7. Les préférences et le message peuvent créer des **faits de séjour**
   (missions d'accueil, satisfaction), sans calcul aléatoire.
8. À terme, une demande peut **expirer au profit d'une conciergerie
   concurrente** (message explicite, aucun revenu, aucune pénalité de
   réputation).

## 5. Transitions

```
            accepter (logement libre adapté)
PENDING ───────────────────────────────────► ACCEPTED ─► Booking (étape 7)
   │  refuser
   ├────────────────────────────────────────► REFUSED
   │  délai écoulé (sauf tutoriel)
   └────────────────────────────────────────► EXPIRED
```

Toute autre transition est refusée sans changement (ex. refuser une demande
expirée, accepter une demande refusée).

## 6. Carte de demande (interface, plus tard)

Portrait et nom ; nombre de voyageurs et préférences (icônes) ; logement
demandé ; « 2 nuits · 300/nuit · 600 au total » ; « Votre commission : 120
(20 %) » ; message entre guillemets ; temps restant avant expiration ;
boutons « Accepter » / « Refuser » (≥ 96 px). Une carte par demande,
défilement horizontal si plusieurs.

## 7. Tests prévus

- **Calculs** : commission affichée = commission versée ; part du propriétaire
  distincte ; arrondi ; montants figés à l'acceptation.
- **Transitions** : chaque transition valide ; toutes les invalides refusées
  sans changement.
- **Demandes invalides** : capacité dépassée, logement demandé occupé ou
  verrouillé, demande inconnue, déjà acceptée, refusée ou expirée.
- **Expirations** : à la seconde près (horloge simulée), y compris
  application fermée ; demande du tutoriel jamais expirée.
- **Pas de double commission** ; refus et expiration sans revenu.
- **Sauvegarde** : statuts et délais restaurés.

## 8. Dépendances

| Dépend de | Pourquoi |
|-----------|----------|
| Étape 7 (réservations) | moteur réutilisé |
| Étape 9 (sauvegarde) | statuts et délais persistants |
| N2 (PNJ) | portraits et fiches voyageurs réutilisent le format des personnages |
| R3–R4 (séjours notés) | préférences → faits de séjour → satisfaction |

## 9. Découpage (lot B)

| # | Étape | Critères d'acceptation |
|---|-------|------------------------|
| B1 | **Statuts et refus** dans `BookingSystem` | Transitions testées ; refus sans revenu |
| B2 | **Expiration** (délai, tutoriel jamais) | Tests à la seconde, application fermée comprise |
| B3 | **Profils voyageurs** (`GuestProfileDef`, préférences, message, logement demandé) + validation des données | Références vérifiées par `DataValidator` |
| B4 | **Carte de demande** (interface) | Captures ; recette Android |
| B5 | **Préférences → faits de séjour** | Effet déterministe sur la satisfaction (avec R3) |
| B6 | **Conciergeries concurrentes** | Expiration expliquée, aucun revenu, aucune pénalité |
