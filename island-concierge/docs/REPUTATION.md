# Réputation et satisfaction des voyageurs — conception

> Statut : **conception validée sur le principe, non implémentée.**
> Lot de développement « R » (voir §10 et `docs/BACKLOG.md`).

La conciergerie maintient une **note moyenne sur 5**. Le seuil stratégique
d'**excellence est 4,80/5**. Chaque séjour terminé produit une évaluation sur
cinq critères pondérés, calculée **sans aucun tirage aléatoire** à partir de ce
qui s'est réellement passé pendant le séjour.

---

## 1. Principes

1. **Déterminisme** : mêmes faits de séjour + même configuration ⇒ même note,
   au centième près. Aucun `randf()` dans la chaîne de calcul.
2. **Configuration en données** : critères, pondérations, seuils, paliers,
   fenêtre de calcul et règles de déduction sont des `.tres` dans
   `data/reputation/`. Un test vérifie leur cohérence (somme des poids = 100 %).
3. **Avis immuables** : un avis publié est un instantané (notes, note globale,
   version des règles). Aucune API ne permet de le modifier ou de le supprimer ;
   changer la configuration ne recalcule jamais le passé.
4. **Historique conservé** : chaque séjour et chaque avis sont archivés et
   sauvegardés.
5. **Pas de blocage irréversible** : sous 4,80, le jeu devient plus difficile
   mais jamais impossible. Un contenu débloqué ne se reverrouille jamais, il
   reste toujours au moins une réservation proposée, et des missions de
   redressement sont proposées automatiquement.
6. **La note ne s'achète pas** : missions et bonus agissent sur la visibilité,
   la confiance ou les opportunités, **jamais** directement sur les notes.
   Seuls de meilleurs séjours font remonter la réputation.

---

## 2. Échelle et arithmétique

Toutes les notes sont des **entiers en centièmes** (`100` = 1,00 ; `500` = 5,00),
ce qui évite les erreurs d'arrondi des flottants au voisinage de 4,80.

| Règle | Valeur V0.x (configurable) |
|-------|-----------------------------|
| Plage d'une note de critère | 100 à 500 |
| Arrondi | **au centième inférieur** (troncature) — 4,7999 ⇒ 4,79 |
| Seuil d'excellence | `480` ; atteint si note **≥ 480** |

### Note d'un séjour

```
note_séjour = floor( Σ (poids_i × note_i) / 100 )      # poids en %, Σ poids = 100
```

| Critère | Identifiant | Poids |
|---------|-------------|------:|
| Propreté | `cleanliness` | 25 % |
| Communication et réactivité | `communication` | 20 % |
| Confort et décoration | `comfort` | 20 % |
| Qualité et fidélité de l'annonce/photos | `listing_accuracy` | 15 % |
| Expérience voyageur | `experience` | 20 % |

Exemple : 5,00 / 5,00 / 5,00 / 4,00 / 5,00 ⇒
(25×500 + 20×500 + 20×500 + 15×400 + 20×500) / 100 = **485 ⇒ 4,85**.

### Réputation de la conciergerie

```
réputation = floor( moyenne des notes globales des N derniers avis publiés )
```

- **Fenêtre glissante** `N = 20` avis : une mauvaise note finit toujours par
  sortir de la fenêtre, ce qui garantit mathématiquement la récupération.
- **Période d'essai** (décision produit) : les **5 premiers avis** sont
  enregistrés et comptent dans la moyenne, mais **aucun effet commercial**
  ne s'applique (statut « Nouvelle conciergerie », effets neutres).
- **Activation progressive** : du 6ᵉ au 10ᵉ avis, les effets du palier
  s'appliquent à 20 %, 40 %, 60 %, 80 % puis 100 % (interpolation entre
  l'effet neutre et l'effet du palier). Exemple : au palier *Correct*
  (visibilité ×0,8), le 7ᵉ avis donne ×(1 − 0,4 × 0,2) = ×0,92.
- Le tableau de bord affiche aussi la moyenne historique (tous les avis) et la
  moyenne par critère, à titre d'information.

Exemple de récupération (testé) : 4 avis à 5,00 puis 1 avis à 2,00 ⇒ 4,40.
Il faut `k` avis à 5,00 tels que (2 200 + 500k) / (5 + k) ≥ 480, soit
**k ≥ 10** pour revenir à l'excellence.

---

## 3. Paliers et effets

| Palier | Réputation | Visibilité (offres/jour) | Offres simultanées | Profils proposés | Confiance propriétaires / séjour |
|--------|-----------|--------------------------|--------------------|------------------|----------------------------------|
| Nouvelle conciergerie | ≤ 5 avis | ×1,0 | 2 | standard | +1 |
| **Excellence** | ≥ 4,80 | ×1,3 | 4 | standard + premium | +2 |
| Très bien | 4,50 – 4,79 | ×1,0 | 3 | standard | +1 |
| Correct | 4,00 – 4,49 | ×0,8 | 2 | standard (petits budgets) | 0 |
| Fragile | < 4,00 | ×0,6 | **1 (plancher)** | standard (petits budgets) | −1 (plancher 0) |

Influence sur les systèmes :

- **Visibilité des hébergements** : fréquence d'apparition des offres de
  réservation au bureau de conciergerie.
- **Nombre et type de réservations** : nombre d'offres simultanées et profils
  de voyageurs proposés (séjours premium mieux payés réservés à l'excellence).
- **Confiance des propriétaires** : score par propriétaire, qui monte ou
  baisse selon les séjours dans ses logements.
- **Logements premium** (ex. Bungalow Corail) : condition de déblocage
  = confiance suffisante **et** (réputation ≥ 4,80 **ou** mission
  « Dossier de confiance » réussie) — toujours un chemin alternatif.
- **Expansion et investissement** (ex. Côte Est, rénovations lourdes) :
  certaines opportunités n'apparaissent qu'en excellence ; d'autres, plus
  chères, restent accessibles dans tous les paliers.

Toutes les valeurs du tableau sont des données (`reputation_config.tres`).

---

## 4. Missions de redressement

Proposées automatiquement quand la réputation passe **sous 4,80** (et pas à
4,80 exactement). Elles ciblent le **critère le plus faible** de la fenêtre.

| Mission | Déclencheur | Objectif | Récompense |
|---------|-------------|----------|------------|
| Grand ménage | propreté moyenne < 4,50 | 3 séjours avec ménage complet avant arrivée | +visibilité temporaire |
| Réactivité | communication < 4,50 | répondre à 5 demandes en moins d'1 h (temps de jeu) | confiance +3 |
| Mise à jour de l'annonce | annonce/photos < 4,50 | refaire les photos conformes à la réalité | fin de la pénalité de visibilité |
| Séjours parfaits | réputation < 4,80 | 3 avis consécutifs ≥ 4,80 | confiance +5, offre premium ponctuelle |
| Dossier de confiance | logement premium verrouillé | série de séjours sans incident non résolu | déblocage alternatif du logement |

Les missions n'écrivent jamais dans le registre d'avis.

---

## 5. Du séjour à l'avis : calcul déterministe

```
Séjour ──► Journal de séjour (faits) ──► Règles par critère ──► Notes de critères
                                              ▲                        │
                              Profil voyageur (sensibilités)          ▼
                                                     Note globale (pondérée, tronquée)
                                                                       │
                                                      Avis publié (instantané immuable)
```

- **Faits** (`StayFact`) : enregistrés pendant le séjour, ex.
  `cleaned_before_arrival`, `welcome_basket`, `request_answered{delay}`,
  `incident{type, resolved, delay}`, `comfort_score`, `photo_gap`.
- **Règles** (`CriterionRuleDef`) : chaque critère part de 5,00 ; chaque règle
  applique un bonus/malus selon un fait (seuils en données), puis la note est
  bornée à [1,00 ; 5,00]. Exemples :
  - Propreté : logement non nettoyé avant arrivée −2,00.
  - Communication : réponse ≤ 1 h 0 ; ≤ 4 h −0,50 ; > 4 h −1,50 ; sans réponse −2,50.
  - Confort : (confort du logement − attente du profil) × 0,25 si négatif.
  - Annonce/photos : −0,75 par niveau d'écart si les photos embellissent la réalité.
  - Expérience : pas de panier d'accueil −0,75 ; incident non résolu −1,00.
- **Profils voyageurs** : multiplient la sensibilité aux malus par critère
  (ex. famille : propreté ×1,5) et fixent les attentes de confort. Ils ne
  changent pas les poids globaux des critères.
- **Texte de l'avis** : construit uniquement à partir des faits les plus
  marquants (tri par impact puis identifiant), avec des modèles i18n. Une
  variante de formulation peut être choisie par `hash(id_séjour)` : stable,
  et **sans effet sur la note**. Aucun fait n'est inventé.

---

## 6. Modèle de données

Configuration (`data/reputation/`, lecture seule) :

| Ressource | Champs principaux |
|-----------|-------------------|
| `ReviewCriterionDef` | `id`, `name_key`, `weight_percent` |
| `ReputationConfig` | `criteria[]`, `excellence_threshold = 480`, `window_size = 20`, `trial_reviews = 5`, `ramp_reviews = 5`, `tiers[]`, `rules_version` |
| `ReputationTierDef` | `id`, `min_score`, `visibility_percent`, `max_offers`, `profile_pool[]`, `owner_trust_delta` |
| `CriterionRuleDef` | `criterion_id`, `fact_id`, seuils, `delta` (centièmes) |
| `GuestProfileDef` | `id`, `name_key`, sensibilités par critère, attente de confort |
| `RecoveryMissionDef` | `id`, déclencheur, objectif, récompense |

État de partie (sauvegardé) :

| Objet | Contenu | Mutabilité |
|-------|---------|------------|
| `StayRecord` | id, logement, profil, début/fin, faits | figé à la fin du séjour |
| `Review` | id, id séjour, date, notes par critère, note globale, `rules_version`, poids utilisés, texte (clés + paramètres) | **immuable** |
| `ReviewLedger` | liste ordonnée des avis | ajout seulement |
| `OwnerTrust` | score par propriétaire | modifiable |
| `ActiveMission` | progression des missions | modifiable |

Classes du cœur (logique pure, `src/core/reputation/`) : `ReviewScoring`,
`ReviewLedger`, `ReputationPolicy` (paliers et effets), `StayLog`,
`ReviewWriter` (texte), `RecoveryMissions`.

---

## 7. Extensions prévues (à terme)

1. **Avis générés depuis les événements vécus** (§5, texte).
2. **Demandes et incidents** pendant le séjour, avec délai de réponse.
3. **Budget de rénovation par logement**.
4. **Décoration** : objets avec points de confort et d'esthétique.
5. **Photographie des logements** : la qualité perçue de l'annonce augmente
   la visibilité ; l'écart photos/réalité pénalise « annonce/photos ».
6. **Profils de voyageurs** aux attentes différentes.
7. **Tableau de bord de réputation** et historique des évaluations.

---

## 8. Tests prévus

- Somme des poids = 100 % ; configuration invalide détectée.
- Exemple chiffré du §2 (485) et cas extrêmes (tout à 1,00 ; tout à 5,00).
- **Frontières du seuil** : 479 ⇒ pas d'excellence ; 480 ⇒ excellence ;
  481 ⇒ excellence ; moyenne 479,99 ⇒ 479 (troncature).
- Paliers à leurs bornes exactes (400, 450, 480).
- Fenêtre glissante : le 21ᵉ avis fait sortir le 1ᵉʳ ; période d'essai : aucun effet jusqu'au 5ᵉ avis inclus, effet à 20 % au 6ᵉ, 100 % au 10ᵉ.
- **Récupération** : scénario du §2 (k = 10) ; après une note de 1,00, la
  réputation remonte à 4,80 en un nombre fini de séjours parfaits.
- Immuabilité : changer les poids après publication ne change aucun avis
  passé ; sauvegarde/rechargement conserve les valeurs publiées.
- Déterminisme : mêmes faits ⇒ même avis (notes et texte).
- Plancher : au palier Fragile, au moins une offre de réservation.
- Missions : proposées à 4,79, pas à 4,80 ; leurs récompenses ne modifient
  aucune note.

---

## 9. Performances

Calculs en entiers, déclenchés à la fin d'un séjour (pas par image). La
réputation est mise en cache et recalculée uniquement à la publication d'un
avis. L'historique affiché est paginé.

---

## 10. Découpage en étapes (lot R)

Chaque étape = un commit, avec ses critères d'acceptation vérifiables.

| # | Étape | Critères d'acceptation |
|---|-------|------------------------|
| R1 | **Configuration et note d'un séjour** : `ReviewCriterionDef`, `ReputationConfig`, `ReviewScoring` | Les 5 critères et poids sont en données ; un test échoue si Σ poids ≠ 100 ; exemple 485 exact ; troncature testée ; aucun flottant dans le calcul |
| R2 | **Registre d'avis et réputation** : `Review`, `ReviewLedger`, fenêtre, paliers | Tests 479/480/481 et bornes de paliers ; fenêtre de 20 ; période d'essai de 5 avis et activation progressive ; pas d'API de modification ; changer la config ne change pas les avis publiés |
| R3 | **Journal de séjour et règles** : `StayLog`, `CriterionRuleDef` | Chaque règle a son test ; notes bornées [1 ; 5] ; mêmes faits ⇒ même note |
| R4 | **Branchement sur la boucle de réservation** | En fin de séjour un avis est publié ; séjour parfait (ménage, panier, accueil) ⇒ 5,00 ; sans panier ⇒ note exacte attendue |
| R5 | **Effets de la réputation** sur les offres | Nombre et fréquence d'offres par palier testés ; jamais 0 offre ; profils premium seulement en excellence |
| R6 | **Missions de redressement** | Proposées à 4,79 et pas à 4,80 ; ciblent le critère le plus faible ; scénario de récupération (k = 10) passe ; aucune note modifiée par une mission |
| R7 | **Tableau de bord et historique** (UI) | Affiche réputation, palier, écart à 4,80, moyennes par critère, avis paginés ; capture fournie ; valeurs vérifiées par test |
| R8 | **Avis textuels** | Texte construit uniquement depuis les faits ; chaque malus important est mentionné ; texte identique à faits identiques |
| R9 | **Profils voyageurs** | Même séjour, profils différents ⇒ écarts documentés et testés |
| R10 | **Demandes et incidents** | Délai de réponse ⇒ communication ; incident non résolu ⇒ expérience ; tests avec horloge simulée |
| R11 | **Confiance des propriétaires et logements premium** | Déblocage du Corail par réputation ou mission ; jamais reverrouillé |
| R12 | **Budget de rénovation et décoration** | Budget jamais négatif ; points de confort pris en compte dans le critère confort |
| R13 | **Photographie** | Photos conformes ⇒ bonus de visibilité ; photos embellies ⇒ malus « annonce » seulement si réalité inférieure |
| R14 | **Expansion et investissement** | Opportunités filtrées par palier, avec au moins une alternative hors excellence |

Insertion recommandée dans le plan V0.1 (voir `ARCHITECTURE.md` §9) : R1–R2
juste après l'étape **Réservations** (logique pure, indépendante de l'UI),
R3–R4 après **Productions** (le panier d'accueil existe alors), R5–R6 après
**Sauvegarde**. R7 et suivantes : V0.2.
