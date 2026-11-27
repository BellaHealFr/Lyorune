# Lyorune dans WowUp : essai à la main

WowUp est un gestionnaire d'addons. Son Hub liste les addons publiés en releases sur GitHub. L'état de conformité de
Lyorune est dans [PROPOSITION_WOWUP.md](PROPOSITION_WOWUP.md).

## 1. Installer Lyorune depuis son adresse GitHub

1. Ouvrir WowUp et choisir le jeu **WoW Forever**.
2. Onglet **Get Addons**, puis **Install from URL** (installer depuis une adresse).
3. Coller `https://github.com/BellaHealFr/Lyorune` et valider.
4. WowUp doit trouver la dernière release et son archive dont le nom finit par `-forever`
   (par exemple `Lyorune-v1.51.0-forever.zip`), puis installer le dossier `Lyorune`.
5. Vérifier dans **My Addons** : nom Lyorune, auteur BellaDroode, bonne version. En jeu, `/lyorune` ouvre les
   options.

Cette installation exige une release étiquetée avec un zip : c'est le cas à chaque version, grâce à la publication
automatique.

Si WowUp ne trouve rien : noter le message affiché et vérifier sur
https://github.com/BellaHealFr/Lyorune/releases/latest que l'archive `-forever` est bien jointe.

## 2. Vérifier la présence dans le Hub

1. Aller sur https://wowup.io/addons, choisir le jeu **WoW Forever**.
2. Chercher « Lyorune ».
3. Si Lyorune apparaît : vérifier l'icône (logo sur fond étoilé), les captures, les catégories (Unit Frames, Buffs
   & Debuffs, Combat, classes) et la version.
4. Sinon : poster le message ci-dessous sur le Discord de WowUp (https://discord.gg/rk4F5aD).

## 3. Message pour le Discord de WowUp

À poster dans le salon prévu pour les auteurs d'addons. Demander aussi si le client WoW Forever est bien pris en
charge par le Hub pour Lyorune.

### Français

> Bonjour ! Je suis BellaDroode, l'auteur de **Lyorune**, des cadres de soin pour **WoW Forever** (interface 16001).
> Dépôt : https://github.com/BellaHealFr/Lyorune
> Chaque version est une release GitHub étiquetée (par exemple `v1.51.0`) avec une archive `Lyorune-vX.Y.Z-forever.zip`
> (dossier `Lyorune/` à la racine) et le `release.json` de l'outil d'empaquetage BigWigs (`flavor: forever`).
> Les topics, l'image de partage et le dossier `.previews` sont en place.
> Pourriez-vous l'ajouter au Hub, ou me dire ce qui manque ? Et le Hub prend-il bien en charge le client WoW Forever
> pour cet addon ? Merci !

### English

> Hi! I'm BellaDroode, the author of **Lyorune**, healing frames for **WoW Forever** (interface 16001).
> Repository: https://github.com/BellaHealFr/Lyorune
> Every version is a tagged GitHub release (for example `v1.51.0`) with a `Lyorune-vX.Y.Z-forever.zip` archive
> (`Lyorune/` folder at the root) and the BigWigs packager's `release.json` (`flavor: forever`).
> Topics, social preview image and `.previews` folder are in place.
> Could you add it to the Hub, or tell me what is missing? And does the Hub support the WoW Forever client for this
> addon? Thank you!
