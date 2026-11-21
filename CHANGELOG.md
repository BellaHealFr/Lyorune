# Journal des versions

Tous les changements notables de Lyorune, version par version. [English version](CHANGELOG.en.md)

Présentation inspirée de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) ; numérotation en [versions sémantiques](https://semver.org/lang/fr/).

<!-- Fichier généré par outils/publier.py à partir de Changes.lua. Ne pas le modifier à la main. -->

## [1.27.1] - 2026-11-21

### Corrigé

- Changer un réglage en combat ne provoque plus d'action refusée par le jeu : le sens des clics (dès l'appui ou au relâchement) attend la fin du combat.
- Les touches au survol lancent leur sort même quand « Lancer le sort dès l'appui » et le réglage « lancer à l'appui » du jeu ne vont pas dans le même sens.

## [1.27.0] - 2026-11-21

### Ajouté

- Taille de chaque icône dans « Placer les éléments de la case... » (chapitre Disposition) : « - » et « + » sous les flèches, ou la molette sur l'icône, de 50 à 200 % de sa taille d'origine, gardée pour chaque forme de case avec sa place et transmise par le partage de configuration. Une taille changée en combat s'applique dès la fin du combat.

### Amélioré

- Icônes à la mesure de chaque forme de case : en Tuile et en Carré, vos soins sur la durée en haut à gauche et les affaiblissements en bas à droite, à une taille tirée de la case (en Carré, une rangée trop longue passe à la ligne) ; en Barre, collés aux bords haut et bas de la barre de vie, côté droit, sans couvrir le nom ; en Bandeau, en bloc au bout de la case, le chiffre de vie rangé à leur gauche. Une rangée trop large rapetisse au lieu de sortir de la case. Les décalages de ces icônes (et du chiffre de vie en Bandeau) repartent une fois de zéro en Barre, Bandeau et Carré.
- Visite guidée et guide du joueur : la place des icônes selon la forme de case, et où régler leur taille.

### Corrigé

- Décompte en secondes des soins : les chiffres sont écrits à la taille de l'icône et ne débordent plus sur la voisine (ils se chevauchaient en Bandeau).

## [1.26.0] - 2026-11-20

### Ajouté

- Nouvelle fenêtre d'options, entièrement repensée et modernisée : onze chapitres rangés par tâche dans une barre latérale (Accueil, Disposition, Apparence, Vie et portée, Mes soins, Affaiblissements, Joueurs, Sorts et raccourcis, Alertes, Profils et partage, Fenêtre et aide), une page qui défile et se range par parties, et les réglages plus rares pliés sous « Réglages fins » pour garder l'essentiel sous les yeux.
- Case témoin à droite de la fenêtre : une fausse case agrandie montre chaque réglage en direct, sans fermer la fenêtre, avec un faux groupe de cinq dessous et les boutons du mode test (5, 10, 25, 40).
- Rune d'or à côté de chaque réglage que vous avez changé : son survol dit en mots la valeur d'installation, un clic la reprend. Dans la barre latérale, une pastille compte vos propres choix dans chaque chapitre.
- « Rétablir cette page » au bas de chaque chapitre, en deux clics : seule la page ouverte revient aux valeurs d'installation, vos listes, vos clics et vos profils restent tels quels.
- Au bas de la fenêtre, « Annuler mes changements » remet tout comme à l'ouverture de la fenêtre, en deux clics : réglages, clics, listes, textes d'annonce, joueurs épinglés et macros (une macro renommée ou supprimée retrouve son clic). « Enregistrer mes réglages » les garde sous un nom de profil.
- Accueil : votre profil actif, la liste de vos réglages changés, le tutoriel, l'assistant de départ et les nouveautés. La fenêtre s'ouvre sur l'Accueil à chaque connexion, puis sur le dernier chapitre utilisé.
- Effets magiques dans la fenêtre : une lumière de soin or et vert traverse l'en-tête, un cercle runique brille derrière le logo, la rune du chapitre ouvert s'allume et la case témoin s'illumine à chaque réglage changé. Jamais sur vos vraies cases de soin ; « Animations réduites » les coupe.
- Vos macros de Lyorune vont dans vos barres de sorts : glissez une macro de « Mes macros » sur une barre du jeu, hors combat. Lyorune en crée une copie « Lyo:Nom » dans /macro (onglet de votre personnage) qui soigne le joueur survolé, sinon votre cible ; elle suit chaque changement de texte ou de nom et part avec la macro. L'option « Créer une macro par sort de mes clics » vise de la même façon.

### Amélioré

- Recherche dans les noms des réglages et dans leurs explications, avec ou sans accents (« echelle » trouve « Échelle ») ; un clic sur un résultat ouvre le bon chapitre et fait clignoter le réglage. « Mode test » fait clignoter les boutons du mode test sous la case témoin, sans changer de chapitre.
- Réglages plus simples à manier : interrupteurs, choix côte à côte, nombres réglables au clavier ou à la molette (après un clic sur la valeur, ou avec Maj) ; la molette fait défiler la page sans changer un réglage au passage. Un réglage est grisé quand celui dont il dépend est coupé, et reste réglable.
- Fenêtres plus reposantes pour les yeux : gris très foncé au lieu du noir, texte blanc cassé, barre latérale d'un ton à part ; le contraste élevé reste très lisible sans noir ni blanc purs, et grise Thème et Texture des barres qu'il remplace (vos cases de soin ne changent pas).
- Les fenêtres s'adaptent à votre écran : une fenêtre trop grande est réduite pour tenir entière, une seule fenêtre s'ouvre à la fois à côté des options et ne les recouvre jamais (les options glissent sur le côté, ou s'effacent puis reviennent sur le même chapitre, au même endroit de la page).
- Le chapitre des clics s'appelle « Sorts et raccourcis » ; toutes ses lignes sont visibles, et ses boutons de bijou sont plus lisibles (icône d'emplacement du jeu, puis bordure d'or et icône de votre bijou) et n'apparaissent que si « Bijoux avec les sorts » est allumé.
- Guide du joueur et visite guidée refaits pour la nouvelle fenêtre, en français et en anglais : quatre cartes courtes la présentent zone par zone. Les cartes se posent à côté de vos cadres, jamais dessus ; lancée des options, la visite vous rend la fenêtre sur l'Accueil ; Échap l'arrête comme la croix ; vos cadres cachés sont remplacés le temps des cartes par le faux groupe du mode test ; ouvrir une autre fenêtre l'arrête proprement.
- Mes macros plus sûre et plus lisible : la macro ouverte est marquée dans chaque thème, la zone d'écriture défile, chaque zone garde sa place (texte entier en infobulle), « Enregistrer » affiche « Enregistrée », et l'assistant, l'import et le choix d'un sort s'ouvrent entiers par-dessus ; Échap ne ferme que la fenêtre du dessus.
- Mes macros : un sort écrit avec d'autres accents que dans votre grimoire est signalé avec sa bonne écriture, et « Corriger l'écriture » la reprend.
- Gestes sans retour à confirmer d'un second clic : supprimer une macro, « Tout remettre » du placement, « Vider le journal », « Reprendre les clics proposés pour ma classe ».
- Les fausses cases du mode test montrent les coins choisis ; mesure des performances avec les nombres à virgule en français et des textes qui ne se chevauchent plus.

### Corrigé

- Barre de mana bleue sous un guerrier, un voleur, un chasseur ou un druide en ours ou en félin : chaque joueur montre maintenant sa propre ressource aux couleurs du jeu (rage, énergie, focalisation), la barre change avec la forme du druide et elle est relue à la sortie du combat ; la teinte que vous choisissez s'applique à la mana. Mode test et case témoin compris.
- Annonce de mana remontée quand le jeu cache votre mana : avec un seuil bas, elle tardait ou ne partait jamais. Lyorune estime maintenant votre mana avec la régénération que le jeu donne hors combat, boisson comprise, et annonce dès que l'estimation atteint votre seuil, jamais trop tôt.
- Macros de plus de 255 caractères acceptées alors que le jeu ne les lance pas : la limite est maintenant de 255, un compteur l'affiche, une macro trop longue est signalée en rouge, et les bijoux ne sont plus ajoutés à un clic qui dépasserait.
- Placement des éléments : un élément poussé loin (nom, vie, icônes, marqueurs) pouvait sortir de la case, à l'écran comme dans l'exemple. Chaque décalage s'arrête maintenant au bord, selon la forme et la taille de vos cases : « Au bord de la case » s'affiche, le nom et le texte de vie rétrécissent près du bord, la couronne du chef reste dans la case, et un décalage ramené au bord retrouve sa place si vous agrandissez les cases.
- « /lyorune mesure » : erreur Lua (« iconSize ») et aucune mesure quand le mode test n'avait pas encore été ouvert dans la partie.
- Visite guidée : le verrou des cadres choisi avant la visite pouvait être perdu après un /reload ; les couleurs du bouclier et des soins en route citées par la visite sont maintenant celles de votre thème.
- Rapport de bug : un nom de joueur court abîmait le texte du rapport (il n'est plus remplacé que comme mot entier), et rappeler la fenêtre effaçait vos réponses. Journal des erreurs : titre traduit en anglais. Inscription runique coupée puis rallumée : elle reparaît sans /reload.
- Texture des barres : le clic s'arrêtait sur une texture en double quand d'autres textures étaient installées, il les parcourt maintenant toutes. Mes macros : un nom refusé (vide, trop long ou déjà pris) restait affiché dans le champ.

## [1.25.1] - 2026-11-20

### Amélioré

- Mode test : un bouton Fermer au bout du bandeau, plus besoin de commande.
- Mode test : le bandeau se déplace à la souris et emmène les vrais cadres avec lui (sauf si les cadres sont verrouillés).

### Corrigé

- Cases entièrement colorées (bleu, violet ou vert) quand un joueur avait un affaiblissement à dissiper : la vie reste visible sous un voile léger.
- Mode test : couleurs de classe teintées de rouge.

## [1.25.0] - 2026-11-19

### Ajouté

- Mana basse des soigneurs : une icône de boisson sur la case d'un soigneur à court de mana, même en combat (onglet Indicateurs).
- Bouclier au choix en bande ou à la suite de la vie, avec un trait lumineux quand il dépasse la vie manquante (onglet Apparence).

### Amélioré

- Nombre d'icônes au choix : de 1 à 6 soins, de 2 à 5 affaiblissements.
- Tous les rangs de vos soins sont reconnus en combat, même un rang inférieur lancé par macro.

### Corrigé

- Icônes de soins et d'affaiblissements de nouveau affichées, en combat comme hors combat, quelle que soit la taille du groupe.
- Le nom et la vie restent lisibles devant les icônes d'auras ; la grande icône d'affaiblissement suit de nouveau son placement.

## [1.24.0] - 2026-11-18

### Ajouté

- Annonce de mana remontée même quand le jeu cache votre mana (WoW Forever) : pendant que vous buvez, Lyorune note le moment où chacun de vos sorts redevient utilisable, en tire la vitesse de remontée et annonce quand votre mana atteint le seuil choisi.

### Amélioré

- Textes de l'interface relus en français et en anglais : vouvoiement partout, phrases plus claires, mêmes mots d'un écran à l'autre.

## [1.23.13] - 2026-11-18

### Ajouté

- Annonce et son de mana faible même quand le jeu cache votre mana (WoW Forever) : Lyorune prend dans votre grimoire le sort qui coûte à peu près votre seuil, et l'annonce part quand ce sort manque de mana, en combat aussi. Seuil approché ; l'onglet Alertes indique le sort choisi.

### Amélioré

- Un sort refusé en combat faute de mana déclenche aussi l'annonce de mana faible.
- Option « Masquer les cadres de groupe du jeu » retirée : Lyorune ne touche jamais aux cadres du jeu.

## [1.23.12] - 2026-11-18

### Amélioré

- Hauteur de la barre de mana réglable de 2 à 60 pixels (10 au plus auparavant) ; la barre de vie garde toujours au moins 10 pixels de la case.

## [1.23.11] - 2026-11-18

### Amélioré

- Profil prêt à l'emploi « Compact » : vos soins sur la durée restent en icônes (les barres fines ne s'affichent que si vous les choisissez).

## [1.23.10] - 2026-11-18

### Amélioré

- Journal d'erreurs plus précis : la pile d'appels est prise au moment de l'erreur, et chaque entrée dit où vous étiez (extérieur, donjon, raid...) et si le jeu cachait les auras.
- Le rapport de /lyorune bug indique aussi le lieu (extérieur, donjon, raid...).

## [1.23.9] - 2026-11-18

### Amélioré

- Journal d'erreurs plus complet : chaque événement des cases et chaque mise à jour régulière est surveillé par Lyorune lui-même, sans dépendre d'aucun autre addon.

### Corrigé

- En donjon, vos soins sur la durée, les affaiblissements et la dissipation s'affichent de nouveau sur les cases : le jeu y rend secret le détail des changements d'auras, ce qui provoquait des centaines d'erreurs.
- Annonces de mana et de résurrection dans un groupe trouvé par l'outil de recherche : envoyées sur le canal d'instance (elles étaient refusées).

## [1.23.8] - 2026-11-17

### Corrigé

- Mesure des performances : le marqueur de raid et la coche « Prêt ? » de votre personnage ne restent plus sur les cases du mode test ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).
- Assistant de départ : « Passer » ou la croix rendent la forme des cases d'avant ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).
- Visite guidée : les cadres verrouillés le redeviennent après l'étape « Placer les cadres » ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.7] - 2026-11-17

### Corrigé

- Coins de la case : la liste suit l'onglet Listes sans /reload, et le sort d'un coin reste affiché même retiré de la liste ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).
- « Reprendre les clics proposés » en 2e spécialisation remplace ses clics, sans effacer ceux de la 1re ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.6] - 2026-11-17

### Corrigé

- « Qui relève qui » : la liste ne se remplit plus pour toute la session quand des joueurs relevés quittent le groupe ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.5] - 2026-11-17

### Corrigé

- Barre ou anneau d'incantation : un sort refusé pendant l'incantation (clics répétés) ne les cache plus ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).
- La couronne du chef s'affiche dans le mode test et dans la fenêtre « Placer les éléments de la case ».
- Mes macros : effacer le mot avant « : » dans une condition ([:shift]) ne fait plus d'erreur.
- Importer de /macro : la fenêtre ne dit plus « aucune macro » quand des macros ont été créées depuis.

## [1.23.4] - 2026-11-17

### Corrigé

- « Son quand ma mana est faible » fonctionne aussi quand les annonces de mana sont décochées ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.3] - 2026-11-17

### Corrigé

- Un appel « Prêt ? » relancé moins de 5 secondes après le précédent garde ses réponses sur les cases.
- L'œil « hors de vue » ne reste plus sur une case quand le jeu la donne à un autre joueur.

## [1.23.2] - 2026-11-17

### Corrigé

- Fin du combat : si une modification remise à plus tard échoue, les autres (clics, disposition, profil) s'appliquent quand même ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).
- « Vider le journal » : /lyorune bug ne signale plus une erreur déjà effacée ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.1] - 2026-11-17

### Corrigé

- Mode test à 25 ou 40 joueurs : avec « Réduire les cases en grand raid », les cases rétrécissent comme dans un vrai raid ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.0] - 2026-11-17

### Ajouté

- Copier une partie d'un profil (onglet Profils, bouton « Copier... ») : Cadres, Apparence, Indicateurs ou Soins, au choix, d'un profil vers un autre ; le reste du profil d'arrivée ne bouge pas ([#44](https://github.com/BellaHealFr/Lyorune/issues/44)).
- Profils automatiques en champ de bataille et en arène, pour chaque spécialisation ; sans choix, le profil prévu pour la taille du groupe s'applique ([#44](https://github.com/BellaHealFr/Lyorune/issues/44)).

## [1.22.0] - 2026-11-17

### Ajouté

- Buffs à poser sur une seule personne : tant que votre Bouclier de terre (chaman) ou vos Épines (druide) ne sont sur personne, le panneau des buffs manquants propose une ligne pour le tank, ou pour le joueur choisi avec /lyorune porteur ([#43](https://github.com/BellaHealFr/Lyorune/issues/43)).
- Recharge globale et incantation (onglet Soins) : une fine barre sous les cadres, ou un anneau autour du curseur, montre le temps de recharge global et votre incantation en cours, même en combat ([#43](https://github.com/BellaHealFr/Lyorune/issues/43)).

## [1.21.0] - 2026-11-17

### Ajouté

- Bijou avec le sort : sur chaque ligne de l'onglet Clics, deux petites icônes utilisent votre bijou du haut ou du bas juste avant le sort, sur un joueur vivant ([#42](https://github.com/BellaHealFr/Lyorune/issues/42)).
- Arrêter l'incantation : un clic ou une touche peut interrompre le sort en cours ([#42](https://github.com/BellaHealFr/Lyorune/issues/42)).
- Clic pris aussi par le jeu : si le « clic pour lancer » du jeu utilise la même combinaison qu'un clic de Lyorune, un message le dit et la ligne passe en orange ; Lyorune ne touche jamais aux raccourcis du jeu ([#42](https://github.com/BellaHealFr/Lyorune/issues/42)).

## [1.20.0] - 2026-11-17

### Ajouté

- Joueurs épinglés : un petit cadre « Épinglés » pour garder à part un 2e tank ou un joueur à surveiller ; on épingle depuis la case survolée (/lyorune epingler), sa cible ou la liste de l'onglet Listes ([#41](https://github.com/BellaHealFr/Lyorune/issues/41)).
- Signal du jeu sur une case : survolez-la et appuyez sur la touche de signal, le joueur est marqué pour tout le groupe ([#41](https://github.com/BellaHealFr/Lyorune/issues/41)).
- Couronne du chef de groupe et drapeau des assistants du raid sur les cases, à placer dans l'éditeur de placement ([#41](https://github.com/BellaHealFr/Lyorune/issues/41)).

### Amélioré

- L'avis de nouvelle version donne l'adresse de la page de cette version, où chaque nouveauté est décrite.

## [1.19.0] - 2026-11-17

### Ajouté

- Distance en trois paliers, même en donjon et en raid : à portée de soin, proche (case estompée), très loin (case encore plus estompée, empreintes au centre) ([#31](https://github.com/BellaHealFr/Lyorune/issues/31)).
- Soin refusé car le joueur est hors de vue : un œil apparaît 3 secondes au centre de sa case ([#31](https://github.com/BellaHealFr/Lyorune/issues/31)).

### Amélioré

- /lyorune position vérifie aussi le palier « très loin », en donjon et en combat.

## [1.18.0] - 2026-11-17

### Ajouté

- Mode performance pour les grands raids ou un ordinateur modeste : portée vérifiée une fois par seconde, icônes des soins et des affaiblissements regroupées, rien ne disparaît ([#30](https://github.com/BellaHealFr/Lyorune/issues/30)).
- Mesure des performances (onglet Aide ou /lyorune mesure) : Lyorune tourne sur un faux groupe de 5, 25 et 40 joueurs et se compare aux autres addons de soin chargés ([#30](https://github.com/BellaHealFr/Lyorune/issues/30)).

## [1.17.0] - 2026-11-17

### Ajouté

- Qui relève qui : quand un soigneur commence une résurrection, son nom remplace « Mort » sur la case, en vert, chez tous ceux qui ont Lyorune ; deux soigneurs ne relèvent plus le même joueur ([#29](https://github.com/BellaHealFr/Lyorune/issues/29)).
- Joueurs du groupe qui ont Lyorune, avec leur version : dans l'onglet Profils (au survol) et avec /lyorune groupe ([#29](https://github.com/BellaHealFr/Lyorune/issues/29)).
- Annuler l'import : la configuration d'avant le dernier import revient en un clic (onglet Profils) ou avec /lyorune annuler ([#29](https://github.com/BellaHealFr/Lyorune/issues/29)).

### Amélioré

- Un interrupteur général « Synchronisation entre joueurs » coupe tous les messages invisibles ; un joueur qui en envoie trop est ignoré un moment ([#29](https://github.com/BellaHealFr/Lyorune/issues/29)).

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

[1.27.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.27.0...v1.27.1
[1.27.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.26.0...v1.27.0
[1.26.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.25.1...v1.26.0
[1.25.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.25.0...v1.25.1
[1.25.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.24.0...v1.25.0
[1.24.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.13...v1.24.0
[1.23.13]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.12...v1.23.13
[1.23.12]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.11...v1.23.12
[1.23.11]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.10...v1.23.11
[1.23.10]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.9...v1.23.10
[1.23.9]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.8...v1.23.9
[1.23.8]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.7...v1.23.8
[1.23.7]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.6...v1.23.7
[1.23.6]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.5...v1.23.6
[1.23.5]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.4...v1.23.5
[1.23.4]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.3...v1.23.4
[1.23.3]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.2...v1.23.3
[1.23.2]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.1...v1.23.2
[1.23.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.0...v1.23.1
[1.23.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.22.0...v1.23.0
[1.22.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.21.0...v1.22.0
[1.21.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.20.0...v1.21.0
[1.20.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.19.0...v1.20.0
[1.19.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.18.0...v1.19.0
[1.18.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.17.0...v1.18.0
[1.17.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.16.0...v1.17.0
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
