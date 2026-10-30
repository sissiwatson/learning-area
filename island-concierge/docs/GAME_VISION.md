# Island Concierge — vision et identité

> Statut : **document de référence du game design.** Les systèmes décrits
> ici ne sont pas développés ; leur découpage est au §8 et dans `BACKLOG.md`.

## 1. Promesse

> *Commencer comme concierge indépendant, apprendre les réalités du terrain,
> développer une entreprise rentable, recruter, négocier des mandats, puis
> devenir propriétaire-investisseur sur plusieurs destinations.*

Island Concierge est un **jeu de simulation entrepreneuriale et de gestion
locative** dans des îles chaleureuses. Ce n'est pas un jeu de ferme : la
récolte et les productions sont des **mécaniques secondaires**, au service
de l'accueil des voyageurs.

## 2. Piliers

| Pilier | Ce que fait le joueur | Ce que le jeu doit produire |
|--------|-----------------------|-----------------------------|
| **Décider** | choisir entre plusieurs solutions à des situations réalistes | des compromis lisibles : coût, délai, qualité, relation, risque |
| **Accueillir** | préparer, communiquer, résoudre, faire plaisir | des avis qui racontent ce qui s'est vraiment passé |
| **Rentabiliser** | suivre commissions, charges, trésorerie, marge | une entreprise qui gagne ou perd de l'argent pour des raisons compréhensibles |
| **Développer** | recruter, négocier, investir, s'étendre | une progression visible : du concierge seul à l'investisseur |
| **Vivre l'île** | rencontrer, soutenir, découvrir | un monde qui réagit aux choix du joueur |

Règle de conception : toute nouvelle fonctionnalité doit servir au moins un
pilier, et la boucle principale doit rester **décision → accueil →
résultat économique → développement**. Une mécanique qui ne fait
qu'occuper (attendre, taper) doit être raccourcie, automatisée ou retirée.

## 3. Place de la production

- La production (ananas, panier) sert un **objectif d'accueil** : le panier
  améliore l'expérience des voyageurs ; il n'est pas une fin en soi.
- À terme, elle peut être **déléguée** (personnel, prestataires, achat au
  marché de Malia) : le joueur choisit entre faire lui-même (gratuit, prend du
  temps) et payer (coûte, libère du temps). C'est une décision de gestion.
- Les durées restent courtes et les taps peu nombreux ; une animation donne
  le retour visuel attendu (V0.1).
- **Faire, déléguer ou acheter** (§4.10) : pour chaque production ou service,
  le joueur choisit entre le faire lui-même, le confier à un habitant
  rémunéré, ou l'acheter. La production devient une décision de gestion,
  jamais une corvée obligatoire.

## 4. Axes de simulation

### 4.1 Gestion financière (lot E)
Chiffre d'affaires des propriétaires (hors trésorerie du joueur),
commissions, frais par séjour (ménage, linge, consommables), prestataires,
charges fixes (local, assurance, logiciel, déplacements), trésorerie, marge
par séjour et par logement, bénéfice. Chaque mouvement porte une catégorie ;
un tableau de bord explique « d'où vient l'argent et où il part ».

### 4.2 Personnel (lot P)
Recrutement (profils fictifs), tarif horaire ou à la mission, compétences
(ménage, accueil, bricolage, langues), disponibilités (planning), qualité
des interventions (influence la propreté et l'expérience), absences et
remplacements, paiements (charges du lot E). Déterministe : la qualité vient
des compétences, du temps alloué et de la charge de travail, pas du hasard.

### 4.3 Relations propriétaires (lot M)
Prospection de nouveaux propriétaires, présentation de l'offre,
**négociation de la commission** et des services inclus, **mandats** (durée,
exclusivité, préavis), exigences propres à chaque propriétaire (prix minimum,
animaux, travaux), fidélisation (satisfaction propriétaire distincte de
celle des voyageurs), perte possible d'un mandat avec préavis, jamais sans
avertissement.

### 4.4 Incidents voyageurs (lot I)
Réclamations, retards (arrivée tardive, ménage en retard), pannes (eau
chaude, climatisation, Wi-Fi), casse, nuisances, surréservation,
remboursements, gestes commerciaux, relogements. Chaque incident est une
**situation à options** (§5) avec des conséquences sur les critères d'avis
(`REPUTATION.md`), la trésorerie et les relations.

### 4.5 Développement de l'entreprise (lot X)
Nouveaux logements en gestion, nouveaux services (transferts, courses,
excursions avec Tao, dîners chez Malia, décoration par Kimo), partenariats
(bateau, restaurants, artisans), investissements (boîte à clés, véhicule,
outillage, linge de qualité), puis **acquisition de biens** : le joueur
devient propriétaire-investisseur (revenus locatifs complets, mais travaux,
vacance et risques à sa charge).

### 4.6 Vie de l'île (lot V) — dès la V0.1

Décision produit : l'île doit sembler vivante dès les premières versions.
V0.1 : personnages visibles, phrases d'ambiance, bateau de Tao, voyageurs qui
débarquent et marchent jusqu'au logement. V0.2 : promeneurs, autres bateaux,
étal de Malia, voyageurs visibles pendant leur séjour. Toutes ces animations
sont purement visuelles (aucune règle de jeu) et peu coûteuses.

Habitants avec leurs propres histoires (`NARRATIVE.md`), commerces qui
ouvrent ou ferment, bateaux qui arrivent au quai, voyageurs qui se promènent,
événements culturels (Fête des Lumières), activités ; conséquences des grandes
décisions (`ARCHIPELAGO_DESTINIES.md`).

### 4.7 Monétisation future (lot $)
Voir §6 : principes non négociables.

> Les sections 4.8 à 4.11 sont des **propositions à valider** (extension du
> game design, aucune implémentation) ; découpage au §8 et dans `BACKLOG.md`.

### 4.8 Introduction et identité du joueur (lot O)
- **Introduction interactive courte** (environ 90 s) : le bateau de Tao
  approche Mahana, Tao présente l'île, Hina accueille le joueur sur le quai
  et lui confie sa mission. Script dans `NARRATIVE.md` §11.
- **La mission en quatre idées**, montrées en cartes illustrées : créer une
  conciergerie rentable, accueillir les voyageurs, collaborer avec les
  habitants, préserver l'île.
- **Nom de la conciergerie** choisi par le joueur (proposition par défaut,
  modifiable plus tard dans les réglages) ; il apparaît dans les dialogues,
  les avis et le tableau de bord. **Avatar** personnalisable plus tard.
- **Passable** à tout moment (le nom par défaut s'applique) et **jouée une
  seule fois** (marqueur sauvegardé) ; rejouable depuis les réglages sans
  toucher à la progression. Elle remplace le premier dialogue de Tao et
  enchaîne sur la quête « Arrivée au quai ».

### 4.9 Accueil : les paniers repensés (lot A)
Le panier d'accueil devient un **produit composé**, cohérent et gradué :
contenant tressé, fruits, fleurs, produits artisanaux.

| Gamme | Composition (proposition) | Coût des matières* | Temps | Effet sur la satisfaction (critère « expérience ») | Vente possible en supplément |
|-------|---------------------------|-------------------:|-------|-------------------------|-----------------------------|
| **Panier de fruits** | 1 corbeille tressée + 3 fruits (ananas) | 0 si récolté | 1 min | évite le malus « pas de panier » | non |
| **Bienvenue** | 1 corbeille tressée, 2 fruits, 1 fleur | 12 | 2 min | +0,10 | non |
| **Découverte** | corbeille, 3 fruits, 2 fleurs, 1 savon | 30 | 3 min | +0,20 | oui (50 ⇒ marge 20) |
| **Prestige** | corbeille, fruits, couronne de fleurs, huile parfumée, carte manuscrite | 60 | 4 min | +0,30 ; attendu par les profils premium | oui (100 ⇒ marge 40) |

\* équivalent en coquillages si les matières sont achetées ; valeurs à
équilibrer. Les bonus compensent des malus d'autres faits du séjour sans
jamais dépasser 5,00 (`REPUTATION.md`).

**Transition sans casser la V0.1** : la recette « 3 ananas → 1 panier »
(qui confond fruits et matériau) reste en place jusqu'à la V0.2, où elle est
remplacée par « corbeille tressée (fibres) + fruits → panier garni » ; l'objet
`welcome_basket` des sauvegardes existantes est converti par une migration
de sauvegarde testée (version 1 → 2).

### 4.10 Ressources, artisanat et « faire / déléguer / acheter » (lots C et F)
- **Nouvelles ressources** : noix de coco, papayes, fleurs (hibiscus,
  frangipanier), fibres végétales séchées ; **produits artisanaux** :
  corbeille tressée, couronne de fleurs, savon, huile parfumée.
- **Activités** : vannerie, couronnes de fleurs, savons, huiles parfumées,
  compositions d'accueil. Chacune a une **fiche pédagogique** (origine,
  usage, fabrication) avec sa nature FICTION / INSPIRED / FACT et des
  **sources fiables** pour tout fait culturel (`NARRATIVE.md` §12).
- **Peu de bâtiments de production** : une cocoteraie et un jardin de fleurs
  au plus en V0.3 ; le reste s'achète ou se délègue.
- **Faire / déléguer / acheter**, pour chaque production ou service :

| Choix | Coût | Temps du joueur | Qualité | Autres effets |
|-------|------|-----------------|---------|---------------|
| Faire soi-même | matières seulement | minuteur + taps | standard | XP |
| Déléguer (ex. Kimo) | rémunération à l'unité | aucun | supérieure | relation + ; capacité limitée par jour |
| Acheter (ex. marché de Malia) | prix de vente | aucun | standard | stock limité, renouvelé avec le temps ; économie locale + |

  Introduction progressive : matériel, rémunérations, stocks, capacités de
  production, bénéfices, partenariats locaux (contrats à prix fixe).

### 4.11 Expériences touristiques (lot T)
Activités vendues aux voyageurs en option de leur séjour. Chacune a un
**tarif**, un **coût**, un **prestataire** éventuel, une **durée**, une
**marge** et un **effet** sur la satisfaction ; capacité limitée par jour.

| Activité (proposition) | Prestataire | Durée | Tarif | Coût | Marge | Effet |
|------------------------|-------------|-------|------:|-----:|------:|-------|
| Balade botanique | Hina | 3 min | 60 | 20 | 40 | expérience +0,15 ; fiche botanique |
| Rencontre au marché | Malia | 2 min | 0 | 0 | 0 | patrimoine et communauté + ; relation + |
| Atelier de vannerie | Kimo | 3 min | 80 | 50 | 30 | expérience +0,20 |
| Dîner chez Malia | Malia | 4 min | 100 | 60 | 40 | expérience +0,25 |
| Excursion au lagon | Tao | 5 min | 150 | 90 | 60 | expérience +0,30 |
| Massage aux huiles parfumées | praticienne (nouveau personnage fictif, V0.4) | 2 min | 120 | 70 | 50 | confort +0,10, expérience +0,10 |

Toutes les valeurs sont des données à équilibrer ; les activités réutilisent
les services des PNJ (`NARRATIVE.md` §3) et le moteur de réservation (une
option s'ajoute à une réservation, pas de système parallèle).

## 5. Situations réalistes à plusieurs solutions

Moteur unique de **situations** (données) : déclencheur, contexte, options
avec coûts, délais, conséquences immédiates et différées, effets sur les
critères d'avis, la trésorerie, les relations. Même moteur que les grandes
décisions des Destinées (D4–D5) et que les négociations de mandats : pas de
systèmes parallèles. Aucune issue ne dépend d'un tirage : les risques sont
des conséquences **conditionnelles** (ex. « la réparation de fortune lâche au
séjour suivant ») annoncées à demi-mot.

| Situation | Options (coût) | Conséquences |
|-----------|----------------|--------------|
| **Le chauffe-eau en panne** (arrivée dans 2 h) | A. Plombier en urgence (120) · B. Kimo répare provisoirement (30) · C. Reloger au Corail si libre (perte de la commission du Corail pour la nuit) · D. Prévenir et offrir un dîner chez Malia (40) | A : rien à signaler · B : panne réapparaît au séjour suivant (incident garanti, connu du joueur s'il a écouté Kimo) · C : voyageurs ravis (expérience +), propriétaire du Corail mécontent si non prévenu · D : propreté/confort −, communication + |
| **Arrivée à 23 h** | A. Attendre soi-même (temps, gratuit) · B. Payer l'agent d'accueil en heure tardive (25) · C. Installer une boîte à clés (investissement 60, une fois) | A : impossible de faire autre chose ce soir-là · B : coût par occurrence · C : les arrivées tardives suivantes sont gérées automatiquement |
| **Le ménage n'est pas fini** (prestataire en retard) | A. Finir soi-même · B. Prestataire en renfort (×1,5) · C. Décaler l'arrivée avec un cocktail au tiki bar (15) | propreté selon l'option ; C améliore l'expérience si le tiki bar existe |
| **Hina veut passer à 15 % de commission** | A. Accepter · B. Refuser · C. Proposer 18 % + ménage premium inclus | A : revenus −, fidélité + · B : fidélité − (préavis si déjà basse) · C : équilibre, mais charge de ménage + |
| **Surréservation** (deux demandes acceptées pour la même date via deux canaux) | A. Reloger chez un voisin (coût de la différence) · B. Annuler la plus récente avec remboursement + geste · C. Proposer une autre date avec remise | réputation : A ≥ C > B ; trésorerie : B ≥ C > A |
| **Avis injuste** (voyageur se plaint d'un bruit hors de votre contrôle) | A. Répondre publiquement avec courtoisie · B. Contester auprès de la plateforme (délai) · C. Ignorer | A : visibilité + (réponse appréciée) · B : avis éventuellement retiré si le fait est hors de votre contrôle (règle déterministe) · C : rien |
| **Linge taché, verre cassé** | A. Absorber le coût · B. Retenir sur la caution (communication −) · C. Facturer au propriétaire (relation propriétaire −) | trésorerie / relation / avis |
| **Recruter une aide au ménage** | 3 candidats fictifs aux tarifs, compétences et disponibilités différents | qualité et coût de tous les ménages suivants |
| **Demande spéciale** (anniversaire, panier sans gluten) | A. Organiser avec Malia (30, relation +) · B. Décliner poliment · C. Promettre sans moyens | A : expérience + · B : neutre · C : incident garanti à l'arrivée |

Ces situations s'ajoutent progressivement (§8) ; chacune a ses tests.

## 6. Monétisation : principes

Aucune monétisation dans la V0.x de prototype. Quand elle viendra :

1. **Jamais obligatoire** : tout le contenu de progression est atteignable
   sans payer, à un rythme raisonnable (vérifié par simulation).
2. **Jamais de réputation achetée** : aucun achat ne modifie une note, un
   avis, la confiance d'un propriétaire ou une relation.
3. **Perles premium** : gagnées en jeu aussi ; utilisables pour des
   **accélérations limitées** (plafond quotidien, jamais sur les décisions ni
   les conséquences narratives), des **packs décoratifs** (esthétique),
   des **conforts** (emplacements de production supplémentaires, raccourcis
   d'interface) et des **extensions** (destinations, histoires).
4. **Transparence** : prix affichés en monnaie réelle, pas de coffres
   aléatoires payants, pas de compte à rebours pressant.
5. **Mineurs et dépenses** : contrôle parental et limites de dépense
   respectés ; aucun achat dans le prototype ni dans les tests.

## 6 bis. Contraintes de conception (proposition)

Règles vérifiables, à respecter par chaque extension :

1. **Pas un clone de FarmVille** : sur une session type de 10 minutes, la
   production (lancer, attendre, récolter) représente au plus un tiers des
   actions ; mesuré par simulation à chaque version.
2. **Décisions plutôt que récoltes répétitives** : toute matière première
   peut être achetée ou déléguée dès qu'elle devient nécessaire ; pas
   d'arrosage, pas de récolte qui pourrit, pas de vente de récoltes comme
   boucle principale.
3. **Production au service de l'accueil** : chaque ressource sert un panier,
   une décoration ou une expérience vendue.
4. **Fiction étiquetée** : aucune tradition inventée n'est présentée comme
   un fait historique ; faits sourcés, fiches non sourcées jamais livrées.
5. **Pas de pay-to-win** (§6) : aucune accélération sur les expériences, les
   avis, la réputation ou les relations.
6. **Non-régression** : les fonctionnalités existantes et leurs tests (294 à
   la fin de la V0.1) restent verts ; toute conversion de données passe par
   une migration de sauvegarde testée.

## 7. Architecture

- **Données** : situations, options, personnel, propriétaires, mandats,
  charges, services, biens à acquérir sont des fichiers de `data/`, validés
  par `DataValidator`.
- **Moteurs génériques, testés une fois** : conditions et effets (N1),
  situations et décisions (D4–D5), calendrier de simulation (D1), journal
  comptable (E1). Les systèmes de ce document les **réutilisent**.
- **Déterminisme** : mêmes choix et même temps écoulé ⇒ même résultat.
- **Tests** : chaque nouvelle règle métier arrive avec ses tests GUT (cas
  nominal, refus, bornes, pas de double gain, sauvegarde) et une
  contre-épreuve de régression.

## 8. Découpage par versions

> **Feuille de route validée** (V0.2 « Immersion et découverte », V0.2.5
> « Réalités du métier », V0.3 « Développement de l'entreprise ») : voir
> `BACKLOG.md`, qui fait foi. Le tableau ci-dessous reste la vision d'origine.

| Version | Thème | Contenu | Ce qu'on garde hors champ |
|---------|-------|---------|---------------------------|
| **V0.1** « Premier séjour » | Une boucle simple et jouable, une île qui vit déjà | Carte, caméra, bungalow, réservations, productions, sauvegarde, XP et niveaux, quêtes de Hina (dialogues passables), **personnages visibles et bavards, bateau de Tao, voyageurs qui arrivent**, animation de production, tiki bar, finitions | réputation, charges, incidents, personnel ; dans le tutoriel, la décoration, la demande de voyageurs et l'avis détaillé passent en V0.2 |
| **V0.2** « Le métier de concierge » | Apprendre les réalités du terrain | **Introduction interactive et nom de la conciergerie** ; **gammes de paniers « fruits » et « Bienvenue »** (migration testée) ; **achat au marché de Malia** ; **2 expériences simples** (balade botanique, rencontre au marché) ; île plus vivante (promeneurs, autres bateaux, étal de Malia, voyageurs sur la terrasse pendant le séjour) ; moteur de situations ; 3 premiers incidents (chauffe-eau, arrivée tardive, ménage en retard) ; charges par séjour (ménage, linge, consommables) et marge par séjour ; réputation (avis, période d'essai de 5 avis) ; décision de décoration ; cartes de demande de réservation | personnel, mandats, investissements |
| **V0.3** « L'entreprise » | Développer une entreprise rentable | Paniers « Découverte » et « Prestige » et leurs effets ; noix de coco, papayes, fleurs, fibres ; ateliers de Kimo (vannerie, couronnes) ; **délégation** et comparateur faire / déléguer / acheter ; expériences vannerie, dîner, excursion ; fiches pédagogiques sourcées ; personnel (recrutement, planning, qualité, paiements) ; relations propriétaires (prospection, négociation, mandats, fidélisation) ; charges fixes, trésorerie et tableau de bord ; services (excursion avec Tao, dîners chez Malia) ; Bungalow Corail et Côte Est | acquisition de biens, Destinées |
| **V0.4** « L'investisseur et l'île vivante » | Devenir propriétaire-investisseur | Savons et huiles parfumées, stocks et capacités, partenariats locaux ; massage (nouvelle praticienne) ; avatar du joueur ; investissements et acquisition de biens ; partenariats ; vie de l'île (bateaux, habitants, événements) ; Destinées de l'archipel (« L'avenir de la baie ») | multi-destinations |
| **V0.5** « L'archipel » | Plusieurs destinations | Seconde destination ; première destination inspirée d'un lieu réel (fiches sourcées) | — |
| **V1.0** | Équilibrage, accessibilité, monétisation éthique (si décidée) | Perles, packs décoratifs, conforts, extensions selon §6 | — |

Chaque version n'est validée qu'avec : tests GUT verts, contre-épreuves,
captures et **recette sur Android réel**.
