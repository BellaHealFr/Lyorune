# Journal des versions

Tous les changements notables de Lyorune, version par version. [English version](CHANGELOG.en.md)

Présentation inspirée de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) ; numérotation en [versions sémantiques](https://semver.org/lang/fr/).

<!-- Fichier généré par outils/publier.py à partir de Changes.lua. Ne pas le modifier à la main. -->

## [1.4.1] - 2026-11-16

### Amélioré

- Lyorune parle anglais partout : visite guidée, nouveautés, messages du chat et noms des thèmes.
- Sur un jeu en anglais, les annonces proposées (mana, résurrection) sont en anglais dès l'installation.
- La fenêtre /lyorune bug donne le lien direct vers le formulaire de signalement, dans votre langue.

## [1.4.0] - 2026-11-16

### Ajouté

- Nouveau nom : Zenith devient Lyorune. Les commandes sont /lyorune et /lyo.
- Bouton sur la mini-carte : clic gauche pour les options, clic droit pour le mode test. Il se déplace et se désactive dans l'onglet Aide.
- Logo de Lyorune dans la liste des addons.
- Inscription runique animée au bas de la fenêtre d'options : passez la souris dessus pour la traduire.

## 1.3.0 - 2026-11-16

### Ajouté

- Signaler un bug en trois questions avec /lyorune bug : un rapport prêt à copier.
- Trois préréglages de transparence : discret, semi-transparent, bien visible.
- Diagnostic de position avec /lyorune position, en vue de la flèche de direction.

### Amélioré

- Changement de spécialisation ou de talents pris en compte sans /reload.
- Un joueur déconnecté reste visible avec la mention « Déco ».
- Notification d'erreur réglable, une seule par session.

## 1.2.0 - 2026-11-16

### Ajouté

- Mode test : un faux groupe de 5 à 40 joueurs pour régler l'apparence (/lyorune test).
- Cadres séparés pour les tanks et les familiers, ordre des rôles au choix.
- Barre de mana des soigneurs, alerte visuelle de vie basse, buffs de groupe manquants.
- Soins sur la durée en icônes ou en barres fines, affaiblissements importants en grand.
- Touches au survol, résurrection automatique sur le clic de soin.
- Listes personnelles : sorts à suivre, affaiblissements à ignorer ou à mettre en avant.
- Luminosité, opacité, contraste élevé, réduction automatique des cases en grand raid.
- Profils prêts à l'emploi, envoi direct de sa configuration à un joueur, tout réinitialiser.
- Traduction anglaise des options.
- Avertissement quand un membre du groupe a une version plus récente.

### Amélioré

- Options rangées en huit onglets, avec une recherche.

### Corrigé

- Votre propre case n'est plus estompée comme si vous étiez hors de portée.

## 1.1.0 - 2026-11-16

### Ajouté

- Cinq thèmes, annonces de mana et de résurrection, partage de configuration par code.
- Journal d'erreurs (/lyorune erreurs) et contrôle de compatibilité (/lyorune diag).

## 1.0.0 - 2026-11-16

### Ajouté

- Première version pour WoW Forever : cadres, clic-soin, soins en route, dissipation, tutoriel.

[1.4.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/BellaHealFr/Lyorune/releases/tag/v1.4.0
