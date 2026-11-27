# Pages CurseForge, Wago et WoWInterface : mode d'emploi

Ce dossier contient les textes à coller à la main sur les trois plateformes. Aucun outil ne les envoie tout seul :
la publication automatique envoie seulement l'archive et les notes de version.

| Fichier | Plateforme | Format |
|---|---|---|
| `curseforge.md` | CurseForge, projet « Lyorune Healing » | Markdown, anglais d'abord puis français |
| `wago.md` | Wago | Markdown, français puis anglais |
| `wowinterface.txt` | WoWInterface | BBCode, français puis anglais |

En tête de chaque fichier : le résumé d'une ligne, en français et en anglais (160 caractères au plus). Le commentaire
d'en-tête (`<!-- ... -->` ou les lignes au-dessus de « à coller ci-dessous ») ne se colle pas.

**Quand coller :** après la fusion de la branche dans `main`. Les liens « Toutes les fonctionnalités en détail »
pointent vers `docs/FONCTIONNALITES.md` et `docs/FEATURES.en.md` sur `main` ; les images pointent vers des fichiers
déjà présents sur `main`.

**Captures à venir :** clic-soin en action, raid à 40, JcJ, les 5 thèmes (liste dans
`docs/images/captures/LISEZMOI.md`). Les ajouter dans les trois textes, après « Les options », quand elles existent.

## CurseForge

1. https://authors.curseforge.com, projet « Lyorune Healing ».
2. Onglet **General** : champ « Summary », le résumé **anglais** (il doit rester en anglais, voir
   `docs/PUBLICATION.md`).
3. Onglet **Description** : choisir le format **Markdown**, puis coller tout `curseforge.md` à partir de la ligne
   « **English first...** ».
4. Enregistrer, puis ouvrir la page publique pour vérifier que les images s'affichent.

## Wago

1. https://addons.wago.io/addons/lyorune, puis la page de gestion du projet.
2. Champ du résumé : le résumé français ou anglais (un seul champ : l'anglais touche plus de joueurs).
3. Champ **Description** : coller `wago.md` à partir de la première image.
4. Vérifier l'aperçu : images, listes, liens.

## WoWInterface

1. https://www.wowinterface.com/downloads/info27323-Lyorune.html, puis « Upload & Update » et la fiche de
   l'addon.
2. Champ **Description** : coller `wowinterface.txt` à partir de la ligne `[center]`.
3. Utiliser l'aperçu avant d'enregistrer : si une balise apparaît telle quelle (par exemple `[size=5]`), la
   retirer en gardant le texte.

## Champs à vérifier sur chaque site

| Champ | CurseForge | Wago | WoWInterface |
|---|---|---|---|
| Résumé | anglais | à choisir | à choisir |
| Description | `curseforge.md` | `wago.md` | `wowinterface.txt` |
| Captures | les mêmes que `.previews/` | idem | idem |
| Catégories | Unit Frames et Healer (prévues dans `docs/PUBLICATION.md`, à vérifier) | Unit Frames, Buffs & Debuffs (déjà posées) | à vérifier |
| Logo | `dist/curseforge/logo-400.png` (400 × 400, fichier local non publié) | idem | idem |
| Lien vers le code source | https://github.com/BellaHealFr/Lyorune | idem | idem |
| Lien vers le suivi des bugs | https://github.com/BellaHealFr/Lyorune/issues | idem | idem |
| Version du jeu | WoW Forever 1.60.1 | idem | 1.60.1 seulement (12.1.5 affiché aussi : à retirer si c'est toujours le cas) |
| Notes de version | envoyées avec l'archive | idem | idem (si l'envoi automatique marche) |

## À chaque version

Les quatre pages officielles (GitHub, CurseForge, Wago, WoWInterface) doivent rester synchronisées :

1. La publication automatique envoie l'archive et les notes partout.
2. Si une nouveauté change ce que l'addon sait faire, mettre à jour le README, `docs/FONCTIONNALITES.md`,
   `docs/FEATURES.en.md`, puis ces trois fichiers, et les recoller sur chaque site.
3. Vérifier sur chaque page que la version affichée est la nouvelle.
