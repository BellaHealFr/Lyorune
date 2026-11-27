# Publier Lyorune

Comment sort une version, et comment elle est suivie sur GitHub puis sur CurseForge.

## Numérotation des versions

Lyorune suit les [versions sémantiques](https://semver.org/lang/fr/) : `MAJEUR.MINEUR.CORRECTIF`.

| Changement | Exemple | Quand |
|---|---|---|
| Correctif | 1.3.0 → 1.3.1 | Uniquement des corrections |
| Mineur | 1.3.1 → 1.4.0 | Des fonctions en plus ; les réglages des joueurs restent valables |
| Majeur | 1.4.0 → 2.0.0 | Un changement qui oblige les joueurs à refaire des réglages |

## Sortir une version

1. Vérifier que les demandes GitHub traitées sont rattachées au jalon de la version.
2. Lancer la publication, avec une ligne par changement, rangée dans sa rubrique :

   ```
   python outils/publier.py 1.4.0 --nouveau "Éditeur de placement des icônes." --ameliore "Recherche plus rapide." --corrige "Case vide après un changement de groupe (#12)."
   ```

   La commande lance les tests, met le numéro dans `Lyorune.toc` et `Core.lua`, ajoute la version à `Changes.lua`
   (affichée en jeu), régénère `CHANGELOG.md` et crée l'archive dans `dist/`. `(#12)` devient un lien vers la demande.

   Pour les joueurs anglophones, faites suivre chaque changement de sa traduction avec `--en` :

   ```
   python outils/publier.py 1.4.2 --corrige "Case vide après un changement de groupe." --en "Empty frame after a group change."
   ```

   La traduction est rangée dans `Locales/enUS.lua` (nouveautés affichées en jeu) et sert au journal anglais
   `CHANGELOG.en.md` et à la partie anglaise des notes de publication. Si vous l'oubliez, la commande liste les
   changements sans traduction : ajoutez-les dans `Locales/enUS.lua`, puis relancez `python outils/publier.py`.

   Les badges « version » et « téléchargements » des README se mettent à jour tout seuls, toutes les heures et
   après chaque publication (`.github/workflows/badges.yml`, branche `badges`).
3. Essayer la version en jeu (`outils\installer.bat`, puis `/reload`).
4. Enregistrer et étiqueter :

   ```
   git add -A
   git commit -m "Lyorune 1.4.0"
   git tag v1.4.0
   git push --follow-tags
   ```

5. GitHub fait le reste : les tests tournent, l'étiquette est comparée à la version de `Lyorune.toc`, les notes de la
   version sont extraites du journal, et la « release » est créée avec l'archive.
6. Fermer le jalon de la version sur GitHub.

## Ce que voit le joueur

- **En jeu** : à la première connexion après la mise à jour, la fenêtre « Nouveautés » liste ce qui est nouveau,
  amélioré et corrigé. Elle se coupe dans l'onglet Aide et se rouvre avec `/lyorune nouveautes`.
- **Sur GitHub** : la page de la version reprend ces mêmes notes ; `CHANGELOG.md` garde tout l'historique, avec un
  lien de comparaison du code entre deux versions.
- **Entre joueurs** : si un membre du groupe a une version plus récente, Lyorune le signale une fois par session.

## Suivi des demandes sur GitHub

| Étiquette | Usage |
|---|---|
| `bug` | Quelque chose ne fonctionne pas |
| `idée` | Une fonction demandée |
| `à confirmer` | Il manque une information pour reproduire |
| `confirmé` | Reproduit, en attente de correction |
| `en jeu` | Ne se vérifie que dans le jeu (boutons sécurisés, valeurs secrètes) |
| `compatibilité` | Lié à une version du jeu ou à un autre addon |
| `traduction` | Texte manquant ou mal traduit |
| `doublon`, `refusé` | Déjà signalé, ou hors du périmètre de Lyorune |

Chaque demande retenue est rattachée à un jalon (la version où elle sera livrée). La correction cite le numéro de la
demande dans le message de commit (`Corrige #12`), ce qui la ferme automatiquement, et dans la ligne du journal.

## CurseForge

Règles vérifiées en novembre 2026 sur le support de CurseForge
([création d'un projet](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project),
[règles de modération](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies)).
À relire avant de soumettre : elles évoluent.

### Point bloquant : le nom

Un addon nommé **Lyorune** existe déjà sur CurseForge (une barre d'informations, d'un autre auteur). Or CurseForge
exige un nom unique. Et au-delà de CurseForge, deux addons dont le dossier s'appelle `Lyorune` ne peuvent pas être
installés ensemble : ils s'écraseraient, et leurs réglages aussi.

Avant toute publication sur CurseForge, il faut donc choisir un nom distinct pour le projet, le dossier de l'addon et
ses données sauvegardées. Ce changement touche tous les fichiers : il se décide une fois, avant la première
publication publique.

### Ce que CurseForge exige

| Élément | Exigence |
|---|---|
| Compte | Compte CurseForge, puis portail des auteurs (authors.curseforge.com) |
| Nom | Unique, en anglais, sans le nom du jeu ni numéro de version |
| Résumé | Une phrase, en anglais, différente du début de la description |
| Description | En anglais d'abord (le français peut suivre). Elle doit expliquer concrètement ce que fait l'addon. |
| Logo | Image de 400 × 400 pixels, pas une couleur unie, pas d'image protégée, pas de format WebP |
| Licence | À choisir dans une liste ; « Custom License » permet de coller le texte de `LICENSE` |
| Catégories | Une principale et jusqu'à quatre autres, toutes pertinentes |
| Fichier | Une vraie archive `.zip`, avec la version du jeu (variante Forever, 1.60.1) et un journal des changements |
| Type | « Release » pour que le fichier soit proposé par l'application CurseForge |
| Liens | Pas de lien de téléchargement externe. Les liens vers GitHub ou un site personnel vont en bas de page. |
| Images | Si une image d'aperçu est retouchée ou générée, elle doit le dire clairement |

Chaque fichier passe en revue (« Under Review ») avant d'être visible. Le support ne donne pas de délai.

### État (20 novembre 2026)

Projet **Lyorune Healing**, numéro **1815533** : seul le nom affiché sur CurseForge change, le dossier et l'addon
restent `Lyorune`. Projet **accepté** : les versions 1.24.0 et 1.25.0 (envoyées à la main) sont « Approved ».
Description bilingue (anglais d'abord, puis français complet) et résumé à jour. `Lyorune.toc` porte
`## X-Curse-Project-ID: 1815533` et le secret `CF_API_KEY` est en place : chaque étiquette de version publie aussi sur
CurseForge. À vérifier au premier envoi automatique (1.25.1) : version du jeu « 1.60.1 » sur la page « Files ».

| Page | Adresse |
|---|---|
| Fichiers et état de la modération | https://authors.curseforge.com/#/projects/1815533/files |
| Aperçu de la page publique | https://www.curseforge.com/wow/addons/lyorune-healing/preview |
| Page publique (après validation) | https://www.curseforge.com/wow/addons/lyorune-healing |

### Suivre la modération

CurseForge n'offre pas d'accès public pour suivre un projet en attente : le suivi se fait dans le portail.

1. Ouvrir la page « Fichiers » ci-dessus, connecté avec GitHub. La colonne « Status » passe par Uploading,
   Processing, Under Review, puis **Approved** (accepté) ou **Rejected** (refusé, avec un message du modérateur).
2. La cloche en haut à droite du portail et l'adresse e-mail du compte reçoivent la décision.
3. Tant que le bandeau « This is a new project » reste affiché, le projet n'est visible que de l'auteur.

En cas de refus : lire le motif, corriger (nom, description, logo, archive), puis renvoyer depuis le même projet.
Les motifs les plus courants sont listés dans les règles de modération (lien en haut de cette section).

### Mettre à jour le projet une fois accepté

Une fois le projet accepté, les nouvelles versions partent automatiquement :

1. Ajouter dans `Lyorune.toc` la ligne `## X-Curse-Project-ID: 1815533`.
2. Dans le portail (Author Settings, onglet « API Tokens »), créer un jeton, puis l'ajouter dans les secrets du dépôt
   GitHub sous le nom `CF_API_KEY` (Settings, Secrets and variables, Actions).
3. Publier comme d'habitude (`python outils/publier.py X.Y.Z "nouveauté"`, puis l'étiquette). L'action
   « Publication » envoie alors la même archive et les mêmes notes sur GitHub et sur CurseForge.
4. **À la première version automatique**, ouvrir la page « Fichiers » et vérifier que la version du jeu est bien
   « WoW Forever 1.60.1 ». Si l'outil de publication choisit une autre variante, corriger la version du fichier
   dans le portail, puis régler l'outil avant la version suivante.
5. Quand le jeu change de version (nouvelle valeur d'`Interface`), vérifier que CurseForge propose la nouvelle
   version de Forever dans sa liste.

Sans automatisation, la mise à jour à la main reste possible : page « Fichiers », « Add File », archive de `dist/`,
version « WoW Forever 1.60.1 », type « Release », notes de la version en anglais.

La description du projet (onglet « Description » du portail, en Markdown) suit les changements de l'addon, comme le
README : la mettre à jour à chaque nouveauté visible. Le texte est dans `dist/curseforge/description.md` : partie
anglaise d'abord (exigée par CurseForge), puis la version française complète. Le résumé d'une ligne (onglet
« General ») doit rester en anglais ; il précise que l'addon existe en français.

Ce que voient les joueurs sur CurseForge : la description bilingue, et pour chaque version les notes de `RELEASE.md`
(français puis anglais), envoyées par l'outil de publication avec l'archive.

### Plan

1. Choisir le nom définitif (voir ci-dessus) et l'appliquer partout.
2. Créer le logo 400 × 400 et faire trois captures d'écran en jeu : cases en groupe, options, mode test.
3. Créer le compte CurseForge et le projet : nom, résumé et description en anglais (le texte de `README.md`, en anglais, sert
   de base), catégories « Unit Frames » et « Healer », licence personnalisée avec le texte de `LICENSE`.
4. Envoyer à la main l'archive de `dist/` pour la première version, avec la variante Forever et les notes de version.
5. Attendre la validation. Corriger si la modération demande des changements.
6. Automatiser ensuite : noter l'identifiant du projet dans `Lyorune.toc` (`## X-Curse-Project-ID:`), créer un jeton
   d'accès dans le portail des auteurs et l'ajouter aux secrets GitHub sous le nom `CF_API_KEY`. Chaque étiquette de
   version publiera alors aussi sur CurseForge. À vérifier au premier envoi : que l'outil de publication reconnaît
   bien la variante Forever.
7. Ajouter le lien CurseForge au README, et le compteur de téléchargements CurseForge à côté de celui de GitHub.
8. Même démarche pour Wago, avec `## X-Wago-ID:` et le secret `WAGO_API_TOKEN`.
