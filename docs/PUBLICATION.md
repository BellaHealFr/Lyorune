# Publier Zenith

Comment sort une version, et comment elle est suivie sur GitHub puis sur CurseForge.

## Numérotation des versions

Zenith suit les [versions sémantiques](https://semver.org/lang/fr/) : `MAJEUR.MINEUR.CORRECTIF`.

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

   La commande lance les tests, met le numéro dans `Zenith.toc` et `Core.lua`, ajoute la version à `Changes.lua`
   (affichée en jeu), régénère `CHANGELOG.md` et crée l'archive dans `dist/`. `(#12)` devient un lien vers la demande.
3. Essayer la version en jeu (`outils\installer.bat`, puis `/reload`).
4. Enregistrer et étiqueter :

   ```
   git add -A
   git commit -m "Zenith 1.4.0"
   git tag v1.4.0
   git push --follow-tags
   ```

5. GitHub fait le reste : les tests tournent, l'étiquette est comparée à la version de `Zenith.toc`, les notes de la
   version sont extraites du journal, et la « release » est créée avec l'archive.
6. Fermer le jalon de la version sur GitHub.

## Ce que voit le joueur

- **En jeu** : à la première connexion après la mise à jour, la fenêtre « Nouveautés » liste ce qui est nouveau,
  amélioré et corrigé. Elle se coupe dans l'onglet Aide et se rouvre avec `/zenith nouveautes`.
- **Sur GitHub** : la page de la version reprend ces mêmes notes ; `CHANGELOG.md` garde tout l'historique, avec un
  lien de comparaison du code entre deux versions.
- **Entre joueurs** : si un membre du groupe a une version plus récente, Zenith le signale une fois par session.

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
| `doublon`, `refusé` | Déjà signalé, ou hors du périmètre de Zenith |

Chaque demande retenue est rattachée à un jalon (la version où elle sera livrée). La correction cite le numéro de la
demande dans le message de commit (`Corrige #12`), ce qui la ferme automatiquement, et dans la ligne du journal.

## CurseForge

Règles vérifiées en novembre 2026 sur le support de CurseForge
([création d'un projet](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project),
[règles de modération](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies)).
À relire avant de soumettre : elles évoluent.

### Point bloquant : le nom

Un addon nommé **Zenith** existe déjà sur CurseForge (une barre d'informations, d'un autre auteur). Or CurseForge
exige un nom unique. Et au-delà de CurseForge, deux addons dont le dossier s'appelle `Zenith` ne peuvent pas être
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

### Plan

1. Choisir le nom définitif (voir ci-dessus) et l'appliquer partout.
2. Créer le logo 400 × 400 et faire trois captures d'écran en jeu : cases en groupe, options, mode test.
3. Créer le compte CurseForge et le projet : nom, résumé et description en anglais (le texte de `README.en.md` sert
   de base), catégories « Unit Frames » et « Healer », licence personnalisée avec le texte de `LICENSE`.
4. Envoyer à la main l'archive de `dist/` pour la première version, avec la variante Forever et les notes de version.
5. Attendre la validation. Corriger si la modération demande des changements.
6. Automatiser ensuite : noter l'identifiant du projet dans `Zenith.toc` (`## X-Curse-Project-ID:`), créer un jeton
   d'accès dans le portail des auteurs et l'ajouter aux secrets GitHub sous le nom `CF_API_KEY`. Chaque étiquette de
   version publiera alors aussi sur CurseForge. À vérifier au premier envoi : que l'outil de publication reconnaît
   bien la variante Forever.
7. Ajouter le lien CurseForge au README, et le compteur de téléchargements CurseForge à côté de celui de GitHub.
8. Même démarche pour Wago, avec `## X-Wago-ID:` et le secret `WAGO_API_TOKEN`.
