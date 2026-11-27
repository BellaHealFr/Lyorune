# Captures du jeu

Deposez ici les captures prises en jeu, avec les noms attendus par `outils/captures.py`, puis lancez `python outils/captures.py`.

Ce sont toujours de vraies captures du jeu, prises par l'auteur : aucune image inventée ou retouchée pour montrer
ce que l'addon ne fait pas.

## Déjà là

| Fichier | Contenu |
|---|---|
| `banniere.jpg` | image d'en-tête des README et du site (placée à la main) |
| `cases.jpg` | les cases : vie, mana, soins et rôle |
| `options.png` | la fenêtre d'options |

## À faire

Format : `.jpg` (ou `.png` pour une fenêtre d'options), 1600 pixels de large au plus (`outils/captures.py` réduit
les images plus larges). Interface du jeu en français pour les README, ou deux versions si vous le voulez.

| Fichier | Contenu | Conseil | Affichage |
|---|---|---|---|
| `groupe.jpg` | en donjon, tout le groupe | groupe de 5, un blessé, un affaiblissement | galerie automatique |
| `raid.jpg` | raid à 40, toujours lisible | `/lyorune test` à 40 joueurs si pas de raid | galerie automatique |
| `dissipation.jpg` | une case colorée : à dissiper | affaiblissement magique sur un joueur | galerie automatique |
| `clics.png` | sorts posés sur les clics | chapitre Sorts et raccourcis | galerie automatique |
| `themes.jpg` | les 5 thèmes | même groupe, un thème par vignette, assemblées en une image | galerie automatique |
| `minicarte.jpg` | le bouton de la mini-carte | gros plan | galerie automatique |
| `runes.png` | les runes et leur traduction | souris sur les runes, en bas des options | galerie automatique |
| `jcj.jpg` | en champ de bataille | cases pendant un match | à placer à la main (absent de la liste de `outils/captures.py`) |
| `clic-soin.gif` | clic-soin en action, 5 à 10 secondes | 800 pixels de large environ, moins de 10 Mo (limite de GitHub) | à placer à la main (`outils/captures.py` ne prend pas les GIF) |

Les emplacements prévus sont marqués `<!-- TODO: ... -->` juste après la galerie, dans `README.md` et
`README.fr.md`.

## Ensuite

1. `pip install pillow`, puis `python outils/captures.py` : la galerie des deux README est réécrite.
2. Copier les meilleures dans `.previews/` (captures montrées par le Hub WowUp, voir `docs/PROPOSITION_WOWUP.md`).
3. Mettre à jour les images des pages CurseForge, Wago et WoWInterface (`docs/plateformes/`).
