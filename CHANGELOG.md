# Journal des versions

Tous les changements notables de Lyorune, version par version. [English version](CHANGELOG.en.md)

Présentation inspirée de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) ; numérotation en [versions sémantiques](https://semver.org/lang/fr/).

<!-- Fichier généré par outils/publier.py à partir de Changes.lua. Ne pas le modifier à la main. -->

## [1.16.0] - 2026-11-17

### Ajouté

- Panneau des buffs manquants (onglet Soins) : hors combat, une petite fenêtre liste les joueurs sans votre buff de groupe ; un clic le leur lance, sans les cibler, et un groupe entier sans buff n'a qu'une ligne pour la version de groupe ([#27](https://github.com/BellaHealFr/Lyorune/issues/27)).
- Assistant de départ : au premier lancement, trois questions (rôle, taille de groupe, forme des cases sur vignettes) règlent Lyorune avant la visite guidée ; à revoir avec /lyorune assistant ou depuis l'onglet Aide ([#28](https://github.com/BellaHealFr/Lyorune/issues/28)).

## [1.15.0] - 2026-11-17

### Ajouté

- Rangement en grille (onglet Cadres) : tout le raid d'un seul bloc, sans trou entre les groupes, avec le nombre de cases par colonne au choix ([#26](https://github.com/BellaHealFr/Lyorune/issues/26)).
- Ordre dans chaque bloc : l'ordre du groupe, par nom, ou par classe puis par nom ; le jeu le tient à jour tout seul, même en combat ([#26](https://github.com/BellaHealFr/Lyorune/issues/26)).
- Chaque groupe garde sa place : en rangement par groupe, un groupe reste dans sa colonne même si le précédent est vide ([#26](https://github.com/BellaHealFr/Lyorune/issues/26)).

### Amélioré

- Le mode test montre la grille et l'ordre choisis ([#26](https://github.com/BellaHealFr/Lyorune/issues/26)).

## [1.14.0] - 2026-11-17

### Ajouté

- Mes profils (onglet Profils) : vos réglages d'apparence enregistrés sous un nom, chargés en un clic ; le profil en cours garde tout seul ce que vous y réglez. Clics, macros, listes et annonces n'en font pas partie ([#24](https://github.com/BellaHealFr/Lyorune/issues/24)).
- Profils automatiques : un profil pour 5, 10, 25 et 40 joueurs et pour chaque spécialisation, appliqué tout seul sans /reload, à la fin du combat si besoin ([#24](https://github.com/BellaHealFr/Lyorune/issues/24)).
- Cases de la cible, de la cible de la cible et de la focalisation, chacune avec son interrupteur (onglet Cadres), dans un petit cadre « Cible » déplaçable, avec vos clics ; un ennemi est en rouge ([#25](https://github.com/BellaHealFr/Lyorune/issues/25)).

## [1.13.0] - 2026-11-17

### Ajouté

- Onglet Clics : une seule liste pour la souris et le clavier, un raccourci par ligne, sans limite, avec toutes les combinaisons d'Alt, Ctrl et Maj ([#20](https://github.com/BellaHealFr/Lyorune/issues/20)).
- Bouton « Ajouter un clic ou une touche » : faites la combinaison voulue, puis choisissez le sort. Changer le raccourci d'une ligne échange les deux sorts s'il était déjà pris ([#20](https://github.com/BellaHealFr/Lyorune/issues/20)).
- Nouveau sort sans clic : un message, et le sort en haut de l'onglet Clics avec « Attribuer » (option « Signaler un nouveau sort sans clic ») ([#22](https://github.com/BellaHealFr/Lyorune/issues/22)).

## [1.12.0] - 2026-11-17

### Ajouté

- Échelle générale de tous les cadres, de 50 à 200 %, suivie par le mode test ([#18](https://github.com/BellaHealFr/Lyorune/issues/18)).
- Éditeur de placement (onglet Cadres) : sur une case d'exemple agrandie, glissez ou poussez au pixel près le nom, le texte de vie, les icônes de rôle, de marqueur et centrale, vos soins, les affaiblissements, le buff manquant et les auras privées ; chaque forme de case garde ses placements, partagés avec le code de configuration ([#18](https://github.com/BellaHealFr/Lyorune/issues/18)).

## [1.11.0] - 2026-11-17

### Ajouté

- Onglet Soins : vos soins sur la durée avec cercle, décompte en secondes, icône qui s'efface à la fin et charges, à combiner comme vous voulez ([#16](https://github.com/BellaHealFr/Lyorune/issues/16)).
- Coins de la case : un de vos sorts par coin, en petit carré de couleur qui se vide avec le temps, réglé pour chaque classe et reconnu même en combat ([#17](https://github.com/BellaHealFr/Lyorune/issues/17)).
- Barre fine de menace en haut de la vie : jaune, orange puis rouge ([#17](https://github.com/BellaHealFr/Lyorune/issues/17)).
- Pourcentage de mana écrit dans la barre de mana, lisible en combat ([#40](https://github.com/BellaHealFr/Lyorune/issues/40)).

### Corrigé

- Le texte de vie ne passe plus par-dessus la barre de mana en forme Tuile et Carré ([#40](https://github.com/BellaHealFr/Lyorune/issues/40)).

## [1.10.0] - 2026-11-17

### Ajouté

- Couleur de la barre de mana au choix (onglet Indicateurs) : bleu par défaut, bleu ciel, violet, turquoise ou blanc.
- Trois thèmes pour les fenêtres de Lyorune : Moderne (par défaut), Classique et MMORPG, changés en direct ; le contraste élevé s'y applique aussi ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).
- Inscription runique animée : les runes s'écrivent à l'ouverture, une lueur avec halo les parcourt, une vague de lumière au survol avant la traduction, couleurs selon le thème ([#33](https://github.com/BellaHealFr/Lyorune/issues/33)).
- Réglage « Animations réduites » : fondus courts seulement, runes et logo immobiles ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).
- Effets magiques (interrupteur dans Apparence) : cercle runique derrière le logo, particules de lumière dans l'en-tête, étincelle quand un réglage change, couleur du thème ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).

### Amélioré

- Fenêtres plus douces : ouverture en fondu, barre d'onglet qui glisse, survol lumineux, rune de confirmation, séparateurs runiques, logo dans l'en-tête ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).
- Visite guidée : les étapes glissent, une rune par étape, l'élément présenté est entouré de runes ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).
- Couleurs de l'interface accordées au bleu givre et à l'or du logo ([#19](https://github.com/BellaHealFr/Lyorune/issues/19)).

### Corrigé

- La barre de mana restait blanche au lieu de bleue.
- Le bord droit de certaines cases à cocher disparaissait selon l'échelle de l'interface : chaque trait de bordure garde au moins un pixel.
- Les fenêtres des macros, du rapport de bug, du journal et des nouveautés s'ouvrent à côté des options au lieu de les recouvrir.

## [1.9.0] - 2026-11-17

### Ajouté

- Forme des cases au choix : Barre, Tuile, Carré ou Bandeau, avec des vignettes dessinées en direct, un bouton « Revenir » et un bouton « Voir en vrai » ([#14](https://github.com/BellaHealFr/Lyorune/issues/14)).
- Angles des cases droits ou arrondis, pour toutes les formes et tous les thèmes ([#15](https://github.com/BellaHealFr/Lyorune/issues/15)).
- Fond et bordure par groupe, aux couleurs du thème ([#14](https://github.com/BellaHealFr/Lyorune/issues/14)).

### Amélioré

- Couleurs de classe plus vives par défaut, ou naturelles au choix ([#32](https://github.com/BellaHealFr/Lyorune/issues/32)).

## [1.8.1] - 2026-11-17

### Amélioré

- Contrôles de sécurité avant chaque publication : codes et messages abîmés, fonctions interdites, contenu de l'archive ([#38](https://github.com/BellaHealFr/Lyorune/issues/38)).

### Corrigé

- Configurations reçues : seulement d'un membre du groupe, de la guilde ou d'un ami, une par minute au plus, avec le royaume de l'expéditeur ; une fenêtre ouverte n'est plus remplacée et le bouton Importer attend deux secondes. Les phrases des annonces et les textures inconnues ne sont plus partagées ([#34](https://github.com/BellaHealFr/Lyorune/issues/34)).
- Avis de nouvelle version : il faut deux joueurs différents et un numéro vraisemblable ; le message cite la page officielle ([#35](https://github.com/BellaHealFr/Lyorune/issues/35)).
- Rapport de bug et journal d'erreurs : noms de personnages et de royaumes remplacés ([#36](https://github.com/BellaHealFr/Lyorune/issues/36)).
- Macros des barres de sorts : Lyorune ne touche plus qu'aux macros qu'il a créées, jamais à une macro du joueur nommée « Lyo: » ([#37](https://github.com/BellaHealFr/Lyorune/issues/37)).

## [1.8.0] - 2026-11-17

### Ajouté

- Auras privées des boss : le jeu les dessine lui-même sur la case, taille et place réglables ([#9](https://github.com/BellaHealFr/Lyorune/issues/9)).
- Absorption de soins : bande rouge sombre au bout de la vie, calculée par le jeu, juste en combat ([#10](https://github.com/BellaHealFr/Lyorune/issues/10)).
- Icônes d'invocation en cours et de joueur dans une autre phase ([#11](https://github.com/BellaHealFr/Lyorune/issues/11)).
- Infobulle au survol d'une case : la liste de vos clics et touches, hors combat ([#12](https://github.com/BellaHealFr/Lyorune/issues/12)).
- Contour lumineux pour un affaiblissement important, même en combat pour ceux des boss, et son pour ceux de votre liste ([#13](https://github.com/BellaHealFr/Lyorune/issues/13)).

## [1.7.0] - 2026-11-17

### Ajouté

- En raid, un cadre par groupe avec son numéro au-dessus (« Groupe 1 » à « Groupe 8 »), ou le nom du rôle en rangement par rôle ; réglage pour les masquer ([#6](https://github.com/BellaHealFr/Lyorune/issues/6)).
- Déplacement des cadres au choix : libre, verrouillé, ou en maintenant Alt, Ctrl ou Maj, par n'importe quelle étiquette de groupe ([#7](https://github.com/BellaHealFr/Lyorune/issues/7)).
- Position des cadres gardée pour chaque personnage ; un nouveau personnage part de la position par défaut ([#5](https://github.com/BellaHealFr/Lyorune/issues/5)).

### Amélioré

- Barre de mana affichée pour tous par défaut, hauteur réglable ([#8](https://github.com/BellaHealFr/Lyorune/issues/8)).
- Bouton de la mini-carte à la même taille que ceux des autres addons.

### Corrigé

- La couleur de dissipation ne cache plus le nom ni la vie : contour coloré et voile léger ([#4](https://github.com/BellaHealFr/Lyorune/issues/4)).

## [1.6.0] - 2026-11-17

### Ajouté

- Bibliothèque « Mes macros » : une macro écrite une fois, posée sur autant de clics et de touches que vous voulez ([#23](https://github.com/BellaHealFr/Lyorune/issues/23)).
- Assistant de macro à cases à cocher, import depuis /macro, glisser-déposer sur les cases.
- Vérification de la macro pendant la saisie, et aperçu du texte exact envoyé au jeu.
- Clics et touches propres à chaque spécialisation, qui changent tout seuls avec les talents ([#21](https://github.com/BellaHealFr/Lyorune/issues/21)).

### Amélioré

- Une commande de macro sans cible vise la case ; [@mouseover] marche tel quel.
- Vos anciennes macros sont rangées toutes seules dans la bibliothèque.

## [1.5.4] - 2026-11-17

### Ajouté

- Vos propres macros du jeu sur un clic : la fenêtre de choix d'un sort montre les macros que vous avez écrites dans /macro.

### Amélioré

- Les macros pour les barres de sorts ne sont plus créées d'office : cochez la case dans l'onglet Clics si vous les voulez. Celles créées par la 1.5.1 sont retirées.

## [1.5.3] - 2026-11-17

### Amélioré

- La fenêtre d'options est plus haute, pour que les macros des barres de sorts tiennent dans l'onglet Clics.
- Une erreur dans un onglet des options ne cache plus les autres réglages, et elle est notée au journal.

## [1.5.2] - 2026-11-17

### Corrigé

- Les cadres s'affichent de nouveau : le jeu refusait de créer les cases, seul comme en groupe.

## [1.5.1] - 2026-11-17

### Ajouté

- Macros pour vos barres de sorts : Lyorune crée et tient à jour une vraie macro du jeu pour chaque sort de vos clics. Onglet Clics : cliquez sur son icône puis déposez-la dans une barre.

### Amélioré

- Le rapport de /lyorune erreurs décrit maintenant l'état de chaque cadre.

## [1.5.0] - 2026-11-17

### Ajouté

- Macros : dans le choix d'un clic ou d'une touche au survol, le bouton « Macro... » propose trois modèles prêts (bijou puis soin, interrompre puis soigner, annonce puis soin) et une saisie libre.

### Amélioré

- Un code de configuration reçu d'un autre joueur ne peut contenir que des noms de sorts, jamais une commande.

## [1.4.2] - 2026-11-17

### Ajouté

- Réglage « Afficher les cadres » (onglet Cadres) : en permanence, ou seulement pendant les combats.
- La commande /lyorune diag décrit l'état de chaque cadre, pour comprendre un cadre resté vide.

### Amélioré

- L'affichage des cadres est confié au jeu lui-même : il reste fiable en plein combat.

### Corrigé

- Après le mode test, les vrais cadres reviennent dès le début du combat.
- Plus d'erreur quand on relâche la poignée d'un cadre pendant un combat.
- Les soins en route sont de nouveau accrochés au bout de la barre de vie.

## [1.4.1] - 2026-11-16

### Amélioré

- Lyorune parle anglais partout : visite guidée, nouveautés, messages du chat et noms des thèmes.
- Sur un jeu en anglais, les annonces proposées (mana, résurrection) sont en anglais dès l'installation.
- La fenêtre /lyorune bug donne le lien direct vers le formulaire de signalement, dans votre langue.

## [1.4.0] - 2026-11-16

### Ajouté

- Nouveau nom : Lyorune. Les commandes sont /lyorune et /lyo.
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

[1.16.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.15.0...v1.16.0
[1.15.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.14.0...v1.15.0
[1.14.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.13.0...v1.14.0
[1.13.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.12.0...v1.13.0
[1.12.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.11.0...v1.12.0
[1.11.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.10.0...v1.11.0
[1.10.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.9.0...v1.10.0
[1.9.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.8.1...v1.9.0
[1.8.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.8.0...v1.8.1
[1.8.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.5.4...v1.6.0
[1.5.4]: https://github.com/BellaHealFr/Lyorune/compare/v1.5.3...v1.5.4
[1.5.3]: https://github.com/BellaHealFr/Lyorune/compare/v1.5.2...v1.5.3
[1.5.2]: https://github.com/BellaHealFr/Lyorune/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.4.2...v1.5.0
[1.4.2]: https://github.com/BellaHealFr/Lyorune/compare/v1.4.1...v1.4.2
[1.4.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/BellaHealFr/Lyorune/releases/tag/v1.4.0
