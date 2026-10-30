# Export Android (debug)

Objectif : produire un APK debug installable sur un téléphone Android pour
valider le tactile, la lisibilité et les performances. Aucun paiement, aucune
publicité, aucune permission réseau (`permissions/internet=false`).

## Caractéristiques de l'APK

| Élément | Valeur |
|---------|--------|
| Preset | `Android Debug` (`export_presets.cfg`, versionné, sans secret) |
| Paquet | `fr.islandconcierge.prototype` — version 0.1.0 (code 1) |
| Architecture | `arm64-v8a` (tous les téléphones récents). Pour un émulateur x86_64, cocher `x86_64` dans le preset |
| SDK | min 21, cible 34 |
| Orientation | paysage, plein écran immersif |
| Build | sans Gradle (modèle APK précompilé de Godot) |
| Exclus | `tests/`, `tools/`, `docs/`, `addons/gut/` |

## Méthode 1 — depuis l'éditeur Godot (recommandée)

1. **Godot 4.4.1** et ses **modèles d'export** : *Éditeur → Gérer les modèles
   d'export → Télécharger et installer*.
2. **Android Studio** (ou les *command-line tools*) avec : *Android SDK
   Platform-Tools*, *Android SDK Build-Tools 34*, *Android SDK Platform 34*.
3. **JDK 17** (OpenJDK).
4. *Éditeur → Paramètres de l'éditeur → Export → Android* :
   - `Android Sdk Path` : dossier du SDK (ex. `~/Android/Sdk`, `%LOCALAPPDATA%\Android\Sdk`) ;
   - `Java Sdk Path` : dossier du JDK 17 ;
   - la clé debug est créée automatiquement par Godot.
5. *Projet → Exporter… → Android Debug → Exporter le projet* (cocher *Exporter
   avec débogage*) ⇒ `build/android/island-concierge-debug.apk`.

Astuce : avec un téléphone branché en USB (débogage USB activé), l'icône
Android en haut à droite de l'éditeur installe et lance directement le jeu.

## Méthode 2 — en ligne de commande

```bash
export ANDROID_HOME=~/Android/Sdk
# facultatif : clé debug personnalisée
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH=~/.android/debug.keystore
tools/export_android_debug.sh
```

Le script inscrit `ANDROID_HOME` dans les réglages de l'éditeur, exporte le
preset, vérifie la signature et affiche la taille de l'APK.

Créer une clé debug si besoin :

```bash
keytool -genkeypair -v -keystore ~/.android/debug.keystore -storepass android \
  -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 \
  -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
```

## Installer et observer

```bash
adb install -r build/android/island-concierge-debug.apk
adb logcat -s godot:V          # messages et erreurs du jeu
```

Sans câble : copier l'APK sur le téléphone et l'ouvrir (autoriser
l'installation d'applications de source inconnue pour le gestionnaire de
fichiers).

## Liste de vérification sur appareil

Colonne « Appareil réel » : résultat de la recette sur téléphone Android.
Colonne « Simulé » : couvert par les tests GUT ou les captures (gestes
rejoués, renderer de compatibilité) — **ce n'est pas une validation sur
appareil**.

Recette n°1 — APK 0.1.0 (commit `8f0f47d`), réalisée par l'équipe produit.
Modèle de téléphone et version d'Android : non communiqués.

| # | Vérification | Résultat attendu | Appareil réel | Simulé |
|---|--------------|------------------|---------------|--------|
| 1 | Lancement | Carte de Mahana en paysage, plein écran, sans écran noir | ✅ | — |
| 2 | Glisser à un doigt | La carte suit le doigt sans à-coup ; inertie naturelle au lâcher | ✅ (inertie non mentionnée) | ✅ |
| 3 | Pincer | Zoom centré entre les doigts, sans saut au début ni à la fin | ✅ | ✅ |
| 4 | Lever un doigt pendant un pincement | Pas de saut ; le glisser continue | ⏳ non vérifié | ✅ |
| 5 | Limites | Impossible de perdre l'île ; zoom min = île entière, max = ×2 | ✅ | ✅ |
| 6 | Tap sur le bungalow (sol et toit) | Panneau ouvert, contour jaune, carte immobile | ✅ (sol ; toit non précisé) | ✅ |
| 7 | Tap « imprécis » (doigt qui bouge un peu) | Toujours reconnu comme un tap | ⏳ non vérifié | ✅ |
| 8 | Boutons du panneau | Faciles à toucher, texte lisible sans zoomer | ✅ | — |
| 9 | Glisser sur le panneau | La carte ne bouge pas | ✅ | ✅ |
| 10 | Encoche / bords arrondis | Titre et panneau non masqués | ⏳ non vérifié | — |
| 11 | Mise en arrière-plan puis retour | Le jeu reprend sans erreur ; depuis 0.1.3, l'état est sauvegardé et le temps écoulé rattrapé | ⏳ non vérifié | — |
| 12 | Fluidité | Pas de saccade visible en déplaçant la carte au zoom min | ✅ | — |

Merci de noter le modèle de téléphone et la version d'Android.

Recette n°1 bis — APK 0.1.1 (retours visuels de l'équipe produit) :
barre de ressources lisible ✅ ; panneau du bungalow clair ✅ ; états
« Libre » et « Réservé » correctement affichés ✅ ; bouton d'action visible ✅.
Améliorations UX demandées : voir `BACKLOG.md`, section « UX ».

À vérifier lors de la prochaine recette : n° 4, 7, 10, 11, l'inertie au lâcher
et le tap sur le toit du bungalow.

## Construction dans l'environnement de développement de Claude

L'APK fourni a été produit dans un conteneur Linux sans accès au dépôt Google
du SDK Android. Le « SDK » y était un dossier minimal pointant vers les paquets
Ubuntu `apksigner`, `zipalign` et `adb` ; la signature a été vérifiée par
`apksigner verify`. Pour vos propres builds, utilisez la méthode 1 ou 2 avec un
SDK officiel.

## Recette n°3 — APK 0.1.4 (V0.1 presque complète)

À vérifier sur appareil réel ; rien de cette liste n'est encore validé sur
téléphone (tout est couvert par les tests automatisés et des captures
simulées).

| # | Vérification | Résultat attendu | Appareil réel |
|---|--------------|------------------|---------------|
| 1 | Ouverture | Tao parle dès le lancement (portrait, texte qui s'écrit) | |
| 2 | Dialogues | Toucher : texte complet puis réplique suivante ; « Passer » fonctionne | |
| 3 | Bandeau d'objectif | Lisible ; « Y aller » ouvre le bon bâtiment | |
| 4 | Tutoriel complet | 8 quêtes : caméra, réservation, ananas, panier, ménage, accueil, encaissement, tiki bar | |
| 5 | Personnages | Visibles, se balancent ; toucher = bulle de phrase | |
| 6 | Arrivée des voyageurs | Le bateau de Tao accoste, deux voyageurs marchent jusqu'au bungalow | |
| 7 | Animation de production | Plantation : pousses → plants → ananas ; anneau ; « +3 » | |
| 8 | Niveau | Badge « Niv. 2 » et message après le premier encaissement | |
| 9 | Tiki bar | 150 coquillages, 5 min, le chantier devient un tiki bar ; solde final 20 | |
| 10 | Sauvegarde | Fermer pendant un séjour ou une construction, rouvrir : tout est rattrapé, rien n'est payé deux fois | |
| 11 | Fluidité | Pas de ralentissement avec les animations | |

## Recette n°4 — APK 0.1.5 (fin de la V0.1, étape 12)

Reprend la recette n°3 (toujours à faire sur appareil) et ajoute les points
corrigés par l'audit UX et la recette de stabilité de l'étape 12
(`STABILITY_V0.1.md`). Rien n'est encore validé sur téléphone.

| # | Vérification | Résultat attendu | Appareil réel |
|---|--------------|------------------|---------------|
| 1 | Recette n°3, points 1 à 11 | Comme décrit ci-dessus | |
| 2 | Cadrage au lancement | Toute l'île visible, centrée, quel que soit le format du téléphone | |
| 3 | Étiquettes et pastilles | « Jungle de l'Ouest », cadenas, « ! », anneaux, bulles : même taille à l'écran en zoomant et dézoomant, et après « Y aller » | |
| 4 | Panneau et dialogue | Un dialogue qui commence ferme le panneau de bâtiment ; jamais les deux à l'écran | |
| 5 | Panneau long | Le panneau du bungalow occupé tient dans l'écran ; s'il défile, aucun blocage ni plantage en ouvrant / fermant vite plusieurs bâtiments | |
| 6 | Offres du bureau | La commission affichée est la vraie (jamais « 0 »), même si le bungalow est déjà réservé | |
| 7 | Ancienne sauvegarde | Installer 0.1.5 par-dessus 0.1.4 ou 0.1.3 : la partie continue (solde, séjour en cours), le tutoriel reprend | |
| 8 | Session longue | 15 min de jeu sans ralentissement ni fermeture inattendue | |
| 9 | Boutons d'action | Un toucher sur « Faire le ménage », « Encaisser », « Accepter » lance l'action une seule fois, sans délai perceptible | |
