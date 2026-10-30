# Décoration et aménagement des logements

> Statut : **proposition à valider.** Rien n'est développé. Direction
> artistique : `ART_DIRECTION.md` ; rendu 3D et prototype : `TRANSITION_3D.md`.

## 1. Pourquoi c'est un système de gestion

En conciergerie, l'aménagement d'un logement est un **investissement du
propriétaire**, conseillé par le concierge. Il change le confort des
voyageurs, la qualité de l'annonce, le prix possible des nuitées et les
charges d'entretien.

Le jeu doit faire vivre cet arbitrage : une belle décoration hors budget,
fragile ou inadaptée au climat est une **mauvaise décision**, même si elle
plaît à l'œil.

## 2. Deux modes, mêmes résultats possibles

| | **Mode libre** (gratuit) | **Mode express** (débloqué en jouant, ou premium) |
|---|---|---|
| Principe | le joueur choisit, place, fait pivoter, colore | le joueur choisit un **style** et voit la pièce transformée |
| Étapes | catalogue → placement → couleurs et matériaux → validation | style → aperçu complet → **devis** → application en un toucher → retouches en mode libre |
| Meubles | achetés avec les ressources du jeu | **identiques**, achetés aussi avec les ressources du jeu ; le style ne fournit que le **plan** |
| Effets économiques | tous atteignables | les mêmes, ni plus ni moins |
| Créations | plusieurs propositions par logement, bibliothèque personnelle réutilisable | le résultat s'enregistre comme une création libre |

Collections du mode express (proposition) :
- **Bohème tropical** : rotin, macramé, coussins colorés ;
- **Lagon chic** : blanc, bois clair, bleu lagon, lignes épurées ;
- **Écolodge naturel** : bois brut, fibres, plantes, lumière douce ;
- **Hibiscus coloré** : rouge, corail et jaune, motifs floraux.

Comment débloquer le mode express en jouant :
- via la relation avec Kimo : objets de décoration au niveau 2, rénovation
  au niveau 3 (`NARRATIVE.md` §3) ;
- puis via des quêtes de décoration ;
- une collection peut aussi être achetée en perles. C'est un raccourci,
  jamais un avantage (§8).

## 3. Ce que fait un aménagement

Chaque objet du catalogue (`FurnitureDef`) porte des **données**. Toutes
les valeurs sont à équilibrer.

| Donnée | Effet en jeu | Rattachement |
|--------|--------------|--------------|
| Prix | dépense sur le budget du propriétaire (ou sur la trésorerie, si le joueur offre l'objet) | lot E |
| Confort | « confort du logement », comparé aux attentes du profil voyageur | critère **Confort et décoration** (20 %) de `REPUTATION.md` |
| Style (étiquettes) | **cohérence** de la pièce : un mélange incohérent rapporte moins | attractivité |
| Fonction | besoins de base couverts (couchage pour la capacité, rangement, éclairage, ventilation, moustiquaire) | un besoin manquant = malus garanti |
| Climat | résistance à l'humidité et au sel ; consommation électrique (climatisation contre ventilateur) | entretien ; indicateur Environnement (D2) |
| Entretien | coût par séjour, usure (durabilité en nombre de séjours) | charges par séjour (V0.2.5) |
| Photogénie | contribution à la qualité des **photos d'annonce** | attractivité des demandes (lot B) |

Grandeurs calculées, toutes déterministes et affichées avant validation :
- **confort** et **cohérence de style** de la pièce ;
- **attractivité** du logement : fréquence et profil des demandes de réservation ;
- **tarif recommandé par nuit** : c'est le propriétaire qui décide, le concierge conseille ;
- **charges d'entretien par séjour** ;
- **retour sur investissement** pour le propriétaire, et effet sur la
  commission du concierge.

### Photos d'annonce

En mode Intérieur, le joueur **photographie** la pièce. Le cadrage, la
lumière (moment de la journée) et la cohérence donnent une note de photo ;
la meilleure photo illustre l'annonce. C'est un vrai savoir-faire du métier,
appris en jouant.

## 4. Exemple pédagogique : le budget de Hina

Hina confie **500 coquillages** pour améliorer la chambre du Bungalow
Hibiscus. Cet argent est au propriétaire : il ne passe pas par la trésorerie
de la conciergerie.

| Proposition du joueur | Coût | Confort | Effet attendu |
|-----------------------|-----:|--------:|---------------|
| Lit en rotin, moustiquaire, ventilateur de plafond, lampe tressée, plantes (Écolodge) | 460 | +1 palier | tarif recommandé 300 → 330 par nuit |
| Même chose avec climatiseur au lieu du ventilateur | 620 | +1 palier | **hors budget** : il faut demander l'accord de Hina (négociation, lot M) ; entretien et consommation plus élevés |
| Décor « Lagon chic » avec mobilier laqué blanc | 490 | +1 palier | joli, mais **peu résistant au sel** : entretien ×2, usure rapide |

Avec la première proposition (exemple chiffré, valeurs fictives) :
- **Hina** gagne +30 par nuit × 80 % = **+24 par nuit**. Elle rentre dans
  son investissement de 460 en environ **19 nuits**.
- **La conciergerie** gagne +30 × 20 % = **+6 par nuit** de commission, et
  des demandes plus fréquentes.
- L'entretien ajoute environ +2 par séjour.

Le jeu affiche ces chiffres avant validation. Le joueur apprend à
argumenter un investissement auprès d'un propriétaire.

## 5. Règles

1. **Budget** : jamais dépassé sans l'accord explicite du propriétaire
   (situation de négociation).
   - La trésorerie de la conciergerie ne devient jamais négative.
   - Toute dépense passe par une transaction tout-ou-rien.
2. **Travaux** : appliquer un aménagement prend du temps (Kimo, ou un
   prestataire) et **rend le logement indisponible** pendant ce temps, comme
   dans la réalité.
   - Pas pendant un séjour en cours.
   - Le renfort (`PACING_AND_SPEEDUPS.md` §2.3) peut raccourcir les travaux contre paiement.
3. **Placement** : grille de pièce (cases de 50 cm).
   - Un objet n'en chevauche pas un autre et reste dans la pièce.
   - Les portes et passages restent libres.
   - Rotation par pas de 45°.
   - Annuler et rétablir.
4. **Déterminisme** : mêmes objets, mêmes effets. Aucun tirage.
5. **Gratuité** : chaque niveau de confort et chaque effet économique est
   atteignable en mode libre, avec les ressources du jeu.

## 6. Données et sauvegarde

- `FurnitureDef` (catalogue) : identifiant **stable**, catégorie, emprise
  sur la grille, données du §3, variantes de couleur et de matériau, modèle
  3D, conditions de déblocage.
- `RoomDef` : dimensions de la grille, murs, ouvertures, emplacements imposés
  (porte, salle d'eau).
- `StyleCollectionDef` : plan par type de pièce (objets, positions,
  variantes, palette), avec des remplacements si un objet n'est pas débloqué.
- **Document d'aménagement**, autonome et versionné. C'est le même format
  pour la sauvegarde, la bibliothèque personnelle et un futur marché
  communautaire :

```json
{
  "format": "island-concierge.design", "version": 1,
  "id": "d-2f6c…", "name": "Écolodge pour Hina",
  "room_template": "bungalow_room_a", "catalog_version": 1,
  "items": [{"item": "bed_rattan_double", "cell": [2, 3], "rot": 90, "variant": "natural"}],
  "palette": {"walls": "sand", "floor": "teak"},
  "meta": {"author": "local", "created": 1800000000, "license": "private"},
  "hash": "sha256:…"
}
```

- Au chargement, chaque document est **validé** :
  - objets inconnus ou verrouillés signalés, jamais créés gratuitement ;
  - emprises vérifiées ;
  - taille limitée.
- Sauvegarde de la partie : aménagement appliqué à chaque logement et
  bibliothèque personnelle. Ce sont des ajouts, introduits par une version
  de format et une migration testée.

## 7. Tests prévus

- Placement : chevauchement, sortie de pièce, porte bloquée, rotation, annulation.
- Calcul des effets (cas nominal, bornes, besoin manquant) ; budget jamais
  dépassé sans accord ; solde jamais négatif.
- Devis du mode express (objets possédés, à acheter, verrouillés).
- Aller-retour d'un document : sauvegarde, fichier, rechargement, aménagement identique.
- Document modifié ou corrompu refusé.
- Mode express et mode libre donnent les **mêmes effets** pour le même aménagement.

## 8. Premium : ce qui est permis

- **Permis** :
  - un plan de collection (gain de temps) ;
  - des variantes purement visuelles (couleurs, motifs), aux effets
    **identiques** aux variantes gratuites ;
  - des emplacements de bibliothèque supplémentaires.
- **Interdit** :
  - un meuble aux statistiques supérieures ;
  - un meuble gratuit ;
  - un effet sur la réputation, les avis ou la confiance du propriétaire.

## 9. Découpage (proposition)

| Étape | Contenu | Dépend de | Rendu |
|-------|---------|-----------|-------|
| DEC1 | Modèle pur : catalogue, grille de pièce, validation du placement, calcul des effets, devis (tests seulement) | — | aucun |
| DEC2 | Budget du propriétaire et décision d'aménagement depuis un panneau (choix parmi 3 propositions), effets sur le confort et le tarif recommandé | DEC1, E1, R3 | 2D actuel possible (V0.2.5) |
| DEC3 | Mode libre en 3D : placer, pivoter, colorer | DEC1, prototype 3D validé | 3D |
| DEC4 | Bibliothèque de créations, réutilisation dans un autre logement | DEC3 | 3D |
| DEC5 | Mode express : collections, aperçu, devis, application, retouches | DEC3 | 3D |
| DEC6 | Photos d'annonce et attractivité | DEC3, lot B | 3D |
| DEC7 | Travaux : durée, indisponibilité, renfort | DEC2, S1 | tous |
