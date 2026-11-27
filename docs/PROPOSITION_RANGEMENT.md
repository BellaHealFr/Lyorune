# Rangement des fichiers .lua : proposition

Relevé du 27 novembre 2026 (version 1.51.0). **Rien n'est déplacé** : ce plan attend l'accord de l'auteur, et
demande un essai en jeu complet avant publication.

## `PlacementOld.lua` est utilisé

- Il est chargé par le jeu : `Lyorune.toc`, ligne 54.
- Il définit `Z.OldPlacementOrigins`, appelé par `Placement.lua` (lignes 509 et 510) pour le passage des placements
  à la 1.49.0 (C34) : chaque élément déjà placé par un joueur garde, au pixel près, sa place d'avant.
- Les tests s'en servent (`tests/run.py`, vers la ligne 10878).

Ce passage se fait une seule fois par personnage, mais un joueur qui saute directement d'une version d'avant la 1.49.0
à une version récente en a encore besoin. **À garder.** On pourra le retirer plus tard, avec le passage dans
`Placement.lua` et son test, quand les versions d'avant la 1.49.0 ne seront plus en circulation : c'est une décision
de l'auteur.

## Aujourd'hui

37 fichiers .lua à la racine (26 555 lignes), plus `Containers.xml`, `Pets.xml`, `Bindings.xml`, `Lyorune.toc`, et
les dossiers `Locales/` et `Media/`.

## Plan proposé

L'ordre de chargement du `.toc` ne change pas d'une ligne : seuls les chemins changent.

| Dossier | Fichiers |
|---|---|
| (racine) | `Lyorune.toc`, `Bindings.xml` (le jeu le cherche à la racine), `LICENSE` |
| `Locales/` | inchangé |
| `Media/` | inchangé |
| `Base/` | `Core.lua`, `Log.lua`, `Changes.lua`, `About.lua`, `Data.lua`, `Perf.lua`, `Bug.lua` |
| `Cadres/` | `UI.lua`, `Logo.lua`, `Themes.lua`, `Pets.xml`, `Frames.lua`, `Containers.xml`, `Containers.lua`, `Preview.lua`, `Placement.lua`, `PlacementOld.lua`, `Minimap.lua` |
| `Auras/` | `Auras.lua`, `Buffs.lua`, `BuffMemory.lua`, `Cast.lua`, `Cooldowns.lua`, `Totems.lua`, `Mana.lua` |
| `Clics/` | `Clicks.lua`, `Macros.lua` |
| `Groupe/` | `Alerts.lua`, `Tally.lua`, `Channels.lua`, `Share.lua`, `Comm.lua`, `Assign.lua`, `BuffAssign.lua`, `GroupCooldowns.lua` |
| `Options/` | `Options.lua`, `Runes.lua`, `Wizard.lua`, `Tutorial.lua` |

Les noms de dossiers ne doivent croiser aucun dossier ignoré par `.pkgmeta` (`tests`, `outils`, `docs`, `site`,
`dist`).

## Ce qu'il faudrait changer

| Fichier | Changement |
|---|---|
| `Lyorune.toc` | chaque ligne de fichier prend son dossier, par exemple `Base\Core.lua`, dans le même ordre |
| `.pkgmeta` | rien : l'outil d'empaquetage reprend tout ce qui n'est pas ignoré, sous-dossiers compris |
| `tests/run.py` | ligne 18 : chemin de `Runes.lua` écrit en dur ; la ligne 21 lit déjà le `.toc` et accepte les sous-dossiers ; `tests/mock.lua` ligne 303 : chemin d'exemple, sans effet |
| `outils/publier.py` | chemins écrits en dur de `Core.lua` (version), `Changes.lua` et `About.lua` ; `addon_files()` et `check_zip()` lisent le `.toc` et suivent tout seuls |
| `outils/installer.bat` | **à réécrire** : il ne copie que les `.lua` et `.xml` de la racine ; sans changement, le jeu ne trouverait plus les fichiers rangés |
| `outils/runes.py` | chemin de `Runes.lua` |
| `outils/verifier_api.py` | chemin de `Log.lua` (le reste parcourt tous les dossiers) |
| `docs/MAINTENANCE.md`, notes locales, commentaires du code | chemins cités à mettre à jour |

Les fichiers `.xml` ne chargent aucun script (pas de `<Script file=...>` ni `<Include>`) : rien à y changer.

## Risques

- **Joueurs qui installent à la main** : s'ils copient le nouveau dossier par-dessus l'ancien sans le supprimer,
  les anciens `.lua` de la racine restent sur le disque. Le jeu ne les charge pas (le `.toc` ne les cite plus), mais
  le dossier devient confus. Le dire dans les notes de version : « supprimez l'ancien dossier `Lyorune` avant de
  copier le nouveau ». Les applications CurseForge, Wago et WowUp remplacent le dossier entier.
- **Oubli d'un chemin dans le `.toc`** : un fichier non chargé casse l'addon au démarrage. Les tests le verraient
  (ils chargent les fichiers cités par le `.toc`), mais seulement si `tests/run.py` est mis à jour en même temps.
- **Piles d'erreur** : les chemins des erreurs changent (`Lyorune/Base/Core.lua`). Rien dans `Log.lua`, `Bug.lua`
  ni `outils/erreurs.py` ne dépend du nom du fichier, mais les anciens rapports de bug ne correspondront plus aux
  chemins.
- **Branches en cours** (`builds`, `refonte-options`) : un déplacement de tous les fichiers rend leur fusion
  difficile. À faire seulement quand elles sont fusionnées ou abandonnées.
- **Gain** : uniquement pour la lecture du dépôt. Aucun effet pour les joueurs.

## Conseil

Attendre un moment calme, sans branche en cours, et tout faire en une seule étape : `git mv` de chaque fichier,
`.toc`, outils, tests, `installer.bat`, essai en jeu, puis une version.
