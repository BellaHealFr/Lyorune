# Lyorune : le guide du joueur

Tout ce qu'il faut savoir pour soigner avec Lyorune. Aucune connaissance technique n'est nécessaire.
En jeu, le même parcours existe en version courte : tapez `/lyorune tuto`.

Au tout premier lancement, un **assistant** pose trois questions avant la visite : votre rôle (soigneur, tank ou dégâts), la taille de groupe où vous jouez le plus (seul ou à 5, raid de 10 à 25, raid de 40) et la forme des cases, choisie sur des vignettes. Lyorune se règle d'après vos réponses ; tout se retouche ensuite dans les options. « Passer » ou la croix gardent vos réglages actuels, forme des cases comprise. Pour le revoir : `/lyorune assistant`, ou « Assistant de départ » dans l'Accueil des options.

[English version](GUIDE.en.md)

## 1. La fenêtre d'options

Tapez `/lyorune` (ou cliquez sur le bouton de Lyorune au bord de la mini-carte). La fenêtre a trois colonnes.

**À gauche, la barre latérale** : onze chapitres, chacun avec sa rune. Un clic ouvre un chapitre. À chaque connexion, la fenêtre s'ouvre sur l'Accueil ; pendant la partie, elle rouvre le dernier chapitre utilisé. Une petite pastille d'or compte, dans chaque chapitre, les réglages que vous avez choisis vous-même et qui diffèrent de l'installation : Lyorune ne change rien tout seul.

| Chapitre | Ce que vous y réglez |
|---|---|
| Accueil | Votre profil, vos réglages changés, le tutoriel, l'assistant et les nouveautés |
| Disposition | Taille des cases, rangement, position, cadres affichés (tanks, cible, joueurs épinglés...) |
| Apparence | Forme des cases, thème, couleurs, transparence, texte |
| Vie et portée | Soins en route, bouclier, vie basse, barre de mana, joueurs loin ou hors de vue |
| Mes soins | Vos soins sur la durée, les coins de la case, vos sorts suivis, la recharge globale |
| Affaiblissements | Dissipation, icônes, affaiblissements importants, auras privées des boss |
| Joueurs | Rôle, marqueur, chef, menace, buffs manquants, infobulle |
| Sorts et raccourcis | Vos sorts sur les clics et les touches, vos macros |
| Alertes | Annonces dans le chat et sons |
| Profils et partage | Profils, partage de configuration, échanges entre joueurs, remise à zéro |
| Fenêtre et aide | Thème de cette fenêtre, effets, langue, aide, lecture d'une case, commandes |

**Au milieu, le chapitre ouvert** : ses réglages sont rangés par parties (« Taille des cases », « Rangement »...) et la page défile à la molette.

**À droite, la case témoin** : une fausse case agrandie qui suit chaque réglage en direct, avec une petite phrase qui dit ce qu'elle montre (bouclier, coins, soins sur la durée...). Dessous, un faux groupe de cinq, puis les boutons du mode test (voir la partie 7).

**Régler** :

- **Interrupteur** : un clic l'allume ou le coupe (dans le thème Classique, il a l'allure d'une case à cocher du jeu).
- **Choix côte à côte** : cliquez sur celui que vous voulez. Une liste de choix plus longue passe au suivant à chaque clic (clic droit : au précédent).
- **Nombre** : boutons « - » et « + », molette sur la valeur, ou cliquez sur la valeur, tapez le nombre et appuyez sur Entrée.
- **Réglages fins (n)** : au bas de chaque partie, les réglages moins courants sont repliés. Un clic les déplie ; Lyorune retient ce que vous avez déplié.
- **Réglage grisé** : il dépend d'un autre réglage qui est coupé (par exemple la hauteur de la barre de mana quand la barre de mana est coupée). Il reste réglable et compte dès que l'autre est rallumé.

**Ce que vous avez changé** :

- **Rune d'or** : elle s'allume à côté de chaque réglage qui n'a plus sa valeur d'installation. Survolez-la pour voir cette valeur, cliquez dessus pour la reprendre.
- **« Rétablir cette page »** : au bas d'un chapitre où un réglage a changé. Deux clics, et chaque réglage du chapitre reprend sa valeur d'installation. Vos listes, vos clics et vos profils ne bougent pas.

**Retrouver un réglage** : en haut à droite, tapez un mot dans « Rechercher un réglage... » (« mana », « tank », « thème »...). Lyorune cherche dans le nom des réglages, puis dans leurs explications. Un clic sur un résultat ouvre le bon chapitre, déplie les réglages fins si besoin et fait clignoter le réglage.

**L'Accueil** montre :

- **Profil actif** : le profil en cours et comment il a été choisi, avec le bouton « Changer de profil » ;
- **Vos réglages changés** : tous vos réglages qui ne sont plus comme à l'installation. Un clic sur un nom vous y emmène ; un clic sur sa rune d'or le rétablit ;
- **Découvrir** : « Lancer le tutoriel », « Assistant de départ » et « Nouveautés de Lyorune ».

Au bas du chapitre Fenêtre et aide, « Lire une case » rappelle ce que veulent dire les couleurs principales d'une case, et « Commandes » liste les commandes `/lyorune`.

## 2. Les cases

Chaque joueur de votre groupe a une case. La barre colorée est sa vie : plus elle est courte, plus il est blessé.

| Ce que vous voyez | Ce que cela veut dire |
|---|---|
| Vert clair au bout de la barre | Des soins sont déjà en route |
| Bande claire en bas de la barre | Il a un bouclier (au choix, chapitre Vie et portée, « Place du bouclier » : à la suite de la vie, comme les cadres du jeu, avec un trait lumineux au bout quand le bouclier dépasse la vie manquante) |
| Une boisson en bas à gauche | Ce soigneur est à court de mana (seuil au choix dans le chapitre Vie et portée, « Mana basse des soigneurs ») : marche en combat, même quand le jeu cache la mana |
| Rouge sombre au bout de la vie | Un affaiblissement « mange » cette part de vie : vos soins la remplissent d'abord, avant de compter |
| Barre bleue sous la vie | Sa mana (pour tous, par défaut ; hauteur de 2 à 60 pixels et couleur réglables dans le chapitre Vie et portée, réglages fins de la partie Mana ; la vie garde toujours au moins 10 pixels de la case : bleu, bleu ciel, violet, turquoise ou blanc). Avec « Pourcentage de mana dans la barre », le % s'y écrit, même en combat |
| Voile rouge qui clignote | Sa vie est basse |
| Bordure rouge | Il est attaqué |
| Trait de couleur en haut de la vie (si vous l'allumez) | Sa menace : jaune, il prend de la menace sur un monstre ; orange, le monstre va se tourner vers lui ; rouge, le monstre s'en prend à lui |
| Petit carré de couleur dans un coin | Un sort que vous avez placé dans ce coin (chapitre Mes soins) : il se vide avec le temps |
| Bordure blanche | C'est votre cible |
| Contour et léger voile bleu, violet, brun ou vert | Une magie, une malédiction, une maladie ou un poison que VOUS pouvez retirer (le nom et la vie restent lisibles) |
| Case estompée | Il est hors de portée de vos soins |
| Case encore plus estompée, empreintes au centre | Il est très loin (plus de 100 mètres environ) : il faut vraiment vous déplacer. Marche aussi en donjon et en raid |
| Un œil au centre, pendant 3 secondes | Le jeu vient de refuser votre soin : il est hors de vue (derrière un pilier, un mur). Décalez-vous |
| « Mort », « Fantôme », « Déco » | Il est mort, en fantôme, ou déconnecté (sa case reste en place) |
| Petites icônes en haut à gauche | Vos soins sur la durée posés sur lui |
| Icônes en bas à droite | Ses affaiblissements |
| Grande icône à gauche | Un affaiblissement important (boss, ou votre liste) |
| Contour doré qui pulse | Un affaiblissement important est posé (avec un son pour ceux de votre liste, si vous l'allumez) |
| Icônes dessinées par le jeu (au centre, par défaut) | Des affaiblissements de boss que le jeu cache aux addons : il les montre lui-même sur la case |
| Icône grise en bas à gauche | Il lui manque votre buff de groupe (visible hors combat) |
| Icône de résurrection au centre | Quelqu'un est en train de le relever |
| Icône d'invocation au centre | Une invocation lui est proposée, ou il l'a acceptée ou refusée |
| Icône de phase au centre | Il est dans une autre phase : il semble proche, mais vos sorts ne l'atteignent pas |
| Couronne près de l'icône de rôle | C'est le chef du groupe (un petit drapeau : un assistant du raid) |

Les couleurs principales sont rappelées en jeu : chapitre Fenêtre et aide, « Lire une case ».

Survolez une case hors combat : l'infobulle montre le joueur, puis la liste de vos clics et touches avec le sort ou la macro de chacun.

**Signaler un joueur au groupe** : survolez sa case et appuyez sur la touche de signal du jeu (réglée dans les raccourcis du jeu). Le joueur est marqué pour tout le groupe, comme si vous visiez son personnage, mais sans le chercher dans la mêlée. À couper dans le chapitre Joueurs (« Signal du jeu sur une case », dans les réglages fins de la partie Au survol d'une case).

## 3. Soigner d'un clic

Cliquez sur une case : le sort part sur ce joueur, sans le cibler.

Pour choisir vos sorts : `/lyorune`, chapitre **Sorts et raccourcis**. Tous vos raccourcis sont sur une seule liste, un par ligne : à gauche le clic ou la touche, au milieu le sort, à droite « x » pour le retirer.

**Ajouter un raccourci :**

1. Cliquez sur « + Ajouter un clic ou une touche ».
2. Faites sur ce même bouton la combinaison voulue : un clic (gauche, droit, milieu, boutons 4 et 5), avec ou sans Alt, Ctrl, Maj, et même plusieurs à la fois (Ctrl + Maj + clic droit). Une touche du clavier, un bouton de souris supplémentaire ou la molette marchent aussi.
3. Choisissez le sort dans la fenêtre qui s'ouvre. Lyorune ne propose que les sorts que votre personnage connaît à son niveau.

Il n'y a pas de limite : ajoutez autant de lignes que vous voulez. Toutes les lignes restent visibles ; quand la liste est longue, faites défiler la page à la molette.

- **Changer le sort** : cliquez sur le sort de la ligne, ou glissez-y un sort de votre grimoire.
- **Changer le raccourci** : cliquez sur le clic ou la touche de la ligne, puis faites la nouvelle combinaison. Si elle était déjà prise, les deux sorts sont échangés : rien n'est perdu.
- **Utiliser un bijou avec le sort** : allumez d'abord « Bijoux avec les sorts » (réglages fins de Comportement). Chaque ligne a alors deux petits carrés au bout, vos bijoux du haut (1) et du bas (2) ; l'infobulle dit lequel. Cliquez sur l'un pour l'allumer (bordure d'or, icône de votre bijou) : le bijou est utilisé juste avant le sort, seulement si le joueur est vivant. Cliquez de nouveau pour l'éteindre. Si le bijou n'est pas prêt, le sort part quand même.
- **Arrêter l'incantation** : dans la fenêtre de choix du sort, ce bouton fait d'un clic un « stop » qui interrompt le sort en cours (un long soin devenu inutile, par exemple).
- Un clic gauche ou droit sans sort garde son rôle habituel : cibler le joueur, ouvrir son menu.

Les réglages du clic lui-même sont dans la partie **Comportement**, sous la liste : « Lancer le sort dès l'appui (plus rapide) », « Le même clic relève un joueur mort », puis dans ses réglages fins les clics par spécialisation, les deux signalements expliqués plus bas et « Laisser Clique ou le jeu gérer les clics ».

### Un clic que le jeu prend aussi

Le jeu a son propre « clic pour lancer » (dans le grimoire). S'il utilise la même combinaison qu'un clic de Lyorune, il peut passer avant. Lyorune vous le dit une fois dans la discussion, et la ligne apparaît en orange dans le chapitre **Sorts et raccourcis** : changez la combinaison d'un côté ou de l'autre. Lyorune ne modifie jamais les raccourcis du jeu. Pour ne plus être prévenu, coupez « Signaler un clic pris aussi par le jeu » (réglages fins de Comportement).

Exemple pour un prêtre : clic gauche pour Soins rapides, clic droit pour Rénovation, Maj + clic droit pour le bouclier, clic milieu pour dissiper, Ctrl + Maj + clic gauche pour Prière de soins.

### Un nouveau sort sans clic

Vous venez d'apprendre un sort utilisable sur un allié, et aucun de vos clics ni de vos touches ne le lance ? Lyorune vous le dit une fois dans la discussion, et le sort apparaît en haut du chapitre **Sorts et raccourcis** :

- « Attribuer » : faites ensuite sur le bouton « Ajouter » le clic ou la touche voulu, le sort y est posé directement ;
- « x » : Lyorune ne vous le propose plus.

Votre résurrection et vos buffs de groupe ne sont jamais signalés. Pour ne plus rien voir, coupez « Signaler un nouveau sort sans clic » (réglages fins de Comportement).

Vos clics sont enregistrés par classe : chaque personnage garde les siens.

### Une spécialisation, des clics

Votre personnage a deux spécialisations (deux groupes de talents) ? Chacune a ses propres clics et ses propres touches. Quand vous changez de talents, Lyorune passe tout seul aux bons clics, même pour une macro.

- Juste au-dessus de la liste du chapitre **Sorts et raccourcis**, Lyorune indique la spécialisation dont vous voyez les clics.
- La première fois, votre seconde spécialisation reprend les clics de la première. Changez ensuite ce que vous voulez.
- « Copier l'autre spécialisation », sur la même ligne, reprend tous les clics et les touches de l'autre.
- Vous voulez les mêmes clics partout ? Coupez « Clics propres à chaque spécialisation » (réglages fins de Comportement).

### Mes macros : plusieurs actions en un clic

Une macro fait plusieurs choses d'un seul clic : activer un bijou puis soigner, relever un mort ou soigner un vivant, attaquer un ennemi ou soigner un allié...

Lyorune garde vos macros dans une bibliothèque. Vous écrivez une macro une seule fois, puis vous la posez sur autant de clics et de touches que vous voulez, dans vos deux spécialisations. Si vous la modifiez, tous ses clics suivent. Elle ne prend aucune place dans la fenêtre `/macro` du jeu.

**Ouvrir la bibliothèque** : chapitre **Sorts et raccourcis**, bouton « Mes macros... » sous la liste (ou le même bouton dans la fenêtre de choix d'un sort).

**Trois façons de créer une macro :**

1. **L'assistant** (bouton « Assistant... ») : choisissez votre sort de soin, puis cochez ce que vous voulez : arrêter le sort en cours, utiliser un bijou, relever le joueur s'il est mort, lancer un sort offensif s'il s'agit d'un ennemi. Lyorune écrit la macro pour vous.
2. **Écrire vous-même** (bouton « Nouvelle »), comme une macro du jeu, une commande par ligne.
3. **Reprendre une macro du jeu** (bouton « Importer de /macro... »), ou la glisser depuis la fenêtre `/macro` sur la liste.

**Viser le joueur de la case.** Vous n'avez rien à écrire : une commande sans cible part sur le joueur de la case.

```
/use 13
/cast Récupération
```

Une macro trouvée sur Internet avec `[@mouseover]` marche telle quelle. Pour placer le joueur de la case vous-même, écrivez `{cible}` : `/cast [@cible,dead] Résurrection; [@cible] Soins rapides`. Une cible écrite (`[@player]`) est toujours respectée. Si vous préférez que vos macros partent exactement comme écrites, décochez « Une commande sans cible vise la case » dans la bibliothèque.

**Une seule macro pour vos deux spécialisations.** La condition du jeu `[spec:1]` ou `[spec:2]` choisit le sort selon vos talents :

```
/cast [spec:1] Soins rapides; [spec:2] Rénovation
```

**La vérification, pendant que vous écrivez.** Sous la macro, Lyorune signale :

- une faute dans une condition (`[mod:shfit]`, `[ded]`) ;
- un crochet oublié, une ligne trop longue ;
- un sort que votre spécialisation active ne connaît pas (c'est peut-être celui de l'autre) ;
- une commande qui exécute du code (`/run`, `/script`).

Juste dessous, « Envoyé au jeu » montre le texte exact qui partira au clic, et « Posée sur » les clics qui utilisent la macro.

**Poser la macro sur un clic :**

- glissez-la de la liste sur le sort d'une ligne du chapitre **Sorts et raccourcis** ;
- ou cliquez sur ce sort : vos macros sont listées sous vos sorts, à la ligne « Mes macros ».

Vos macros restent sur votre ordinateur : elles ne sont jamais envoyées ni reçues dans une configuration partagée, et « Tout réinitialiser » ne les efface pas. Quand un clic porte une macro, la résurrection automatique ne s'y ajoute pas : utilisez la case « Si le joueur est mort » de l'assistant.

Vous utilisiez déjà des macros avec une version précédente ? Elles sont rangées toutes seules dans la bibliothèque, sur les mêmes clics.

### Des macros toutes prêtes pour vos barres de sorts (facultatif)

Si vous le demandez, Lyorune crée une vraie macro du jeu pour chaque sort de vos clics. Rien n'est créé tant que le réglage n'est pas allumé.

1. Chapitre **Sorts et raccourcis**, partie « Macros pour vos barres de sorts » : allumez « Créer une macro par sort de mes clics ». Une icône par macro apparaît.
2. Cliquez sur une icône, puis déposez-la dans une barre de sorts. Vous les retrouvez aussi dans `/macro`, onglet de votre personnage : leur nom commence par « Lyo: ».

La macro soigne le joueur sous votre souris (une case ou un personnage), sinon votre cible, sinon vous. Elle se met à jour quand vous changez vos clics. Lyorune ne touche jamais à vos autres macros. Pour vous en passer, coupez « Créer une macro par sort de mes clics » ou cliquez sur « Retirer les macros de Lyorune ».

## 4. Touches au survol

Vous préférez le clavier, ou votre souris a beaucoup de boutons ? Les touches se règlent sur la même liste que les clics, chapitre **Sorts et raccourcis** :

1. Cliquez sur « + Ajouter un clic ou une touche ».
2. Appuyez sur la touche voulue : une lettre, un chiffre, un bouton de souris à partir du 6e, la molette, avec ou sans Maj, Ctrl, Alt (et leurs combinaisons). Échap annule.
3. Choisissez le sort.

Passez ensuite la souris sur une case et appuyez sur la touche : le sort part sur ce joueur. La touche ne change de rôle que pendant le survol d'une case. Le nombre de touches n'est pas limité.

## 5. Relever un joueur

Avec « Le même clic relève un joueur mort » (chapitre Sorts et raccourcis, partie Comportement, allumé par défaut), cliquez simplement sur un joueur mort avec votre clic de soin habituel : Lyorune lance votre résurrection à la place. Aucune touche supplémentaire.

## 6. Placer et dimensionner les cadres

Tout se règle dans le chapitre **Disposition**.

- **Déplacer** : faites glisser l'étiquette « Groupe » au-dessus des cases. En raid, chaque groupe a sa colonne et son numéro (« Groupe 1 » à « Groupe 8 »), ou le nom du rôle en rangement par rôle : n'importe quelle étiquette déplace l'ensemble.
- **Verrou** : « Déplacement des cadres » (partie Position) propose « Libre », « Verrouillé », ou « Avec Alt », « Avec Ctrl », « Avec Maj » : les cadres ne bougent alors que si vous maintenez la touche. Tant qu'ils sont libres, une petite mention « déverrouillé » apparaît au-dessus. On ne peut jamais les déplacer en combat. « Remettre les cadres au centre » les ramène au milieu de l'écran.
- **Chaque personnage a sa place** : la position est gardée pour chaque personnage, même après une déconnexion. Un nouveau personnage part de la position par défaut.
- **Sans étiquettes** : coupez « Numéro de groupe au-dessus des cases ». Elles reviennent seulement le temps de déplacer les cadres.
- **Taille** : partie Taille des cases, « Largeur » et « Hauteur » ; « Espacement » est dans les réglages fins.
- **Échelle générale** : « Échelle générale (%) », de 50 à 200 %. Tout grandit ou rapetisse ensemble (cases, icônes, textes, étiquettes), sans changer vos réglages de taille. Le mode test suit la même échelle. En combat, le changement attend la fin du combat.
- **Placer les éléments de la case** : bouton « Placer les éléments de la case... » (partie Taille des cases). Une case d'exemple agrandie montre tous les éléments : nom, texte de vie, icône de rôle, marqueur de raid, chef de groupe, icône centrale, vos soins sur la durée, affaiblissements, affaiblissement important, buff manquant et auras privées. Glissez un élément avec la souris, ou choisissez-le dans la liste et poussez-le avec « Gauche », « Haut », « Bas », « Droite » : un pixel par clic, cinq avec Maj. Le décalage s'affiche sous la case et vos vraies cases suivent aussitôt. « Remettre à sa place » annule pour l'élément choisi, « Tout remettre » pour tous. Chaque forme de case (Barre, Tuile, Carré, Bandeau) garde ses propres placements.
- **Rangement** : par groupe, par rôle ou en grille (partie Rangement). Par rôle, choisissez l'ordre (tank, soin, dégâts, ou une autre des six combinaisons) avec « Ordre des rôles », dans les réglages fins. En grille, tout le raid tient d'un seul bloc, sans trou entre les groupes : « Cases par colonne en grille » (réglages fins) règle sa hauteur (8 cases par colonne donnent 5 colonnes pour 40 joueurs). Un réglage qui ne sert pas avec le rangement choisi est grisé.
- **Ordre dans chaque bloc** : l'ordre du groupe, par nom, ou par classe puis par nom (tous les prêtres ensemble, puis tous les druides...). C'est le jeu qui tient cet ordre à jour, même en plein combat, quand quelqu'un arrive ou change de groupe. En rangement par rôle, « par classe » range par nom dans chaque rôle.
- **Chaque groupe garde sa place** (réglages fins) : en rangement par groupe, le groupe 3 reste toujours en 3e colonne, même si le groupe 2 est vide. Pratique pour retrouver un joueur d'un coup d'œil. Coupé, les groupes se resserrent.
- **Tanks et familiers** : chacun peut avoir son propre cadre, déplaçable séparément (partie Cadres affichés ; les familiers sont dans les réglages fins).
- **Joueurs épinglés** : un petit cadre « Épinglés » pour les joueurs que vous voulez garder à part (un 2e tank, un joueur à surveiller). Pour épingler quelqu'un : survolez sa case et tapez `/lyorune epingler` (pratique dans une macro sur une touche), ou ciblez-le et cliquez sur « Épingler ma cible », ou tapez son nom dans la liste « Joueurs épinglés » (ces deux-là sont dans les réglages fins de la partie Cadres affichés). Le même geste le retire. Le cadre n'apparaît que si un joueur de la liste est dans votre groupe ; il se déplace par son étiquette. En combat, un changement de la liste attend la fin du combat.
- **Cible, cible de la cible, focalisation** : partie Cadres affichés, « Case de ma cible », puis dans les réglages fins « Case de la cible de ma cible » et « Case de ma focalisation ». Elles apparaissent dans un petit cadre « Cible », que l'on déplace par son étiquette comme les autres. Chaque case a vos clics et la même apparence que celles du groupe. Elle n'apparaît que si la cible ou la focalisation existe, même en combat. Un ennemi est en rouge, un personnage non joueur amical en vert, et ni l'un ni l'autre n'affiche d'icônes de soins ou d'affaiblissements. La cible de votre cible (par exemple le joueur que le boss frappe) est revue deux fois par seconde, car le jeu ne prévient pas quand elle change.
- **Quand les afficher** : « Afficher les cadres » propose « Toujours » ou « En combat seulement ». « Toujours » garde les cadres à l'écran, en combat comme hors combat, y compris quand vous jouez seul en quête (avec « Mon cadre quand je suis seul » allumé). « En combat seulement » les fait apparaître au début de chaque combat et disparaître à la fin. Les étiquettes s'affichent avec les cadres.
- **Un cadre reste vide ?** Tapez `/lyorune diag` : Lyorune écrit dans le chat l'état de chaque cadre. Copiez ces lignes dans votre signalement (`/lyorune bug`).
- **Grand raid** : « Réduire les cases en grand raid » (réglages fins de Taille des cases) rétrécit les cases au-delà de 10 puis de 25 joueurs.

## 7. Essayer sans groupe : le mode test

Tapez `/lyorune test`, ou cliquez sur « 5 », « 10 », « 25 » ou « 40 » sous « Mode test », dans la colonne de droite de la fenêtre d'options (sous la case témoin). Un faux groupe apparaît, avec des blessés, des soins en route, des affaiblissements et les coins que vous avez choisis : réglez l'apparence à votre goût, tout change en direct. Faites glisser le bandeau « Mode test » pour déplacer le faux groupe : vos vrais cadres prendront la même place (même verrou que les étiquettes « Groupe »). Pour le quitter, cliquez une seconde fois sur le même nombre, ou sur « Fermer » au bout du bandeau « Mode test », au-dessus des cases (ou retapez `/lyorune test`). Il se ferme aussi tout seul si un combat commence.

## 8. Apparence

Chapitre **Apparence** :

- **Forme des cases** : quatre vignettes montrent chaque forme avec vos couleurs. **Barre** (le nom à gauche, la vie à droite), **Tuile** (la forme d'origine), **Carré** (petit, pour les grands raids) et **Bandeau** (une ligne longue et fine). Un clic suffit : la taille, le texte et la barre de mana suivent. Vous retouchez ensuite chaque valeur dans le chapitre Disposition. « Revenir » annule le dernier choix, « Voir en vrai » affiche un faux groupe de 10 joueurs.
- **Angles des cases** : droits ou arrondis, quelle que soit la forme.
- **Fond et bordure par groupe** (réglages fins) : chaque groupe est posé sur son propre fond, aux couleurs du thème.
- **Thème** : Néon, Épuré, Verre, Classique ou Héroïque.
- **Contraste élevé** : fond noir, bordure blanche, texte plus gros. Il vaut aussi pour les fenêtres de Lyorune. Il remplace le thème et la texture des barres : ces deux lignes restent grisées tant qu'il est allumé.
- **Couleurs de classe** : « Vives » (par défaut) pour des couleurs franches et lumineuses, ou « Naturelles » pour celles du jeu. Grisé si les barres ne sont pas aux couleurs de classe.
- **Transparence** : « Opacité des cadres (%) » et « Opacité hors de portée (%) ». Dans les réglages fins, « Luminosité des barres (%) » et trois préréglages en un clic : « Discret », « Semi-transparent », « Bien visible ».
- **Texte de vie** : vie manquante, pourcentage, ou rien ; avec la taille du texte.

### Les fenêtres de Lyorune

Chapitre **Fenêtre et aide**, partie « Fenêtres de Lyorune » : elle habille la fenêtre d'options, la visite guidée et les petites fenêtres, jamais les cases.

- **Thème des fenêtres** : trois habillages complets, chacun avec son cadre, ses boutons, ses interrupteurs et ses titres de rubrique. Le changement est immédiat, sans `/reload`, et l'en-tête (logo, nom, version) ne bouge pas.
  - **Moderne** (par défaut) : fond sombre et net aux angles arrondis, boutons plats, interrupteurs à pastille qui glisse, bleu givre et or du logo.
  - **Classique** : comme les fenêtres du jeu, avec le cadre de boîte de dialogue, les boutons rouges et les cases à cocher du jeu, et des champs de saisie creusés.
  - **MMORPG** : un grimoire, avec un fond de pierre voilé derrière le texte, une bordure dorée, une rune gravée dans chaque angle, des plaques de bronze au biseau doré en guise de boutons (elles s'enfoncent au clic), des champs de saisie creusés, des interrupteurs cerclés d'or et marqués d'une rune et des titres de rubrique en écriture ancienne.
- **Effets magiques** (allumés par défaut) : une lumière de soin, or et vert, traverse l'en-tête ; un cercle de runes tourne lentement derrière le logo et s'illumine à l'ouverture ; de petites particules de lumière montent dans l'en-tête ; la rune du chapitre ouvert s'allume dans la barre latérale ; et à chaque réglage changé, un éclat de soin passe sur la case témoin, dont la vie remonte. Le cercle et les particules prennent la couleur du thème (givre en Moderne, or en Classique, braise en MMORPG). Rien de tout cela ne touche aux cases de soin.
- **Animations réduites** : les fenêtres s'ouvrent en simple fondu, les runes et le logo restent immobiles, rien ne bouge en boucle, et les effets magiques sont coupés. Pratique si le mouvement vous gêne.

Les fenêtres des macros, du rapport de bug, du journal et des nouveautés s'ouvrent à côté de la fenêtre d'options, sans la recouvrir.

## 9. Choisir ce qui s'affiche

Chaque élément de la case a son interrupteur, rangé selon ce qu'il montre. Rien n'est obligatoire. Vous pouvez par exemple n'afficher que les affaiblissements que vous pouvez dissiper.

- **Vie et portée** : soins en route, bouclier, voile de vie basse (son seuil dans les réglages fins), absorption de soins, barre de mana, mana basse des soigneurs, et les deux indices de portée ci-dessous.
- **Mes soins** : vos soins sur la durée, les coins de la case, vos sorts suivis, la recharge globale.
- **Affaiblissements** : dissipation, icônes, affaiblissements importants, auras privées des boss.
- **Joueurs** : icône de rôle, marqueur de raid, chef de groupe, invocation et phase, menace, buffs manquants, infobulle.

### La portée (chapitre Vie et portée)

**Joueur très loin : empreintes** et **Soin refusé, hors de vue : un œil** : deux interrupteurs, partie Portée. Le jeu ne donne pas la position des joueurs en donjon ni en raid (pas de flèche possible) ; ces deux indices marchent partout, même en combat.

### Vos soins sur la durée (chapitre Mes soins)

Lyorune s'adapte à votre classe (prêtre, druide, paladin ou chaman) : il suit vos soins sur la durée et vos boucliers, plus les sorts de votre liste. Ces icônes, comme celles des affaiblissements, des coins et la bordure de dissipation, sont dessinées par le jeu lui-même : elles restent visibles en plein combat, même quand le jeu cache les auras aux addons. Le nom et la vie restent toujours lisibles par-dessus. Un sort de la liste des affaiblissements à ignorer ou importants peut s'écrire par son nom ou par son numéro ; un nom est reconnu en combat dès que Lyorune a vu l'affaiblissement une fois hors combat.

- **Nombre de soins affichés** : de 1 à 6 par case (4 au départ). Dans le chapitre Affaiblissements, **Nombre d'affaiblissements** (réglages fins de la partie Icônes) fait de même pour les affaiblissements : de 2 à 5 (2 au départ), celui que vous pouvez dissiper toujours en premier. Un changement fait en combat s'applique dès la fin du combat.
- **Icônes ou barres fines** : choisissez l'affichage. Sur les icônes, quatre réglages fins se combinent comme vous voulez :
  - **Cercle qui se vide** : un voile tourne à mesure que le temps passe ;
  - **Décompte en secondes** : les secondes restantes, écrites par le jeu ;
  - **Icône qui s'efface à la fin** : vers la fin du soin, l'icône s'assombrit. C'est le moment de relancer ;
  - **Nombre de charges** : un petit chiffre quand le soin en a plusieurs.
- **Coins de la case** : placez un de vos sorts dans chaque coin. Il devient un petit carré de couleur (vert, bleu, jaune, rose) qui se vide avec le temps, et quitte la rangée d'icônes. D'un coup d'œil, vous voyez qui n'a pas votre Rénovation ou votre Récupération. Chaque classe garde ses propres coins : votre druide et votre prêtre ne se mélangent pas. Les coins choisis se voient aussi sur la case témoin et dans le mode test.
- **Mes sorts à suivre** (partie Sorts suivis) : ajoutez un de vos sorts, il s'affiche avec vos soins sur la durée et vous est proposé pour les coins.
- **Recharge globale et incantation** (partie Temps de recharge global, coupé au départ) : une fine barre sous les cadres, ou un anneau autour du curseur, au choix. Blanc pendant le temps de recharge global, couleur d'accent pendant votre incantation. Vous voyez d'un coup d'œil quand le prochain soin peut partir, même en combat.

Tout marche en combat. Le jeu y cache le nom des auras, mais Lyorune reconnaît vos soins à leur numéro, ou au sort que vous venez de lancer. Un soin qu'il ne peut pas reconnaître reste dans la rangée d'icônes, jamais dans un mauvais coin.

### Les buffs (chapitre Joueurs)

- **Panneau des buffs manquants** (prêtre, druide, mage) : hors combat, une petite fenêtre liste les joueurs à qui manque votre buff de groupe (Robustesse, Marque du fauve, Intelligence des arcanes). Un clic sur un nom lui lance le buff, sans le cibler ; un clic droit lance la version de groupe. Quand trois joueurs d'un même groupe n'ont pas le buff, une seule ligne « Groupe N » lance directement la version de groupe. Un joueur hors de portée est estompé. Le panneau se cache en combat et revient après ; la croix le ferme jusqu'à la fin du prochain combat. Déplacez-le par son titre : sa place est gardée pour chaque personnage. Il a son propre interrupteur, séparé de la petite icône grise sur la case (« Buff de groupe manquant »).
- **Buffs à poser sur une seule personne** (chaman : Bouclier de terre ; druide : Épines) : tant que le vôtre n'est sur personne, le panneau des buffs manquants propose une ligne pour le tank, hors combat. Vous préférez un autre joueur ? Survolez sa case et tapez `/lyorune porteur` (ou `/lyorune porteur Nom`) : il passe avant le tank, pour ce personnage. La même commande sur le même joueur vous ramène au tank. Si votre buff est déjà sur quelqu'un, Lyorune ne vous demande rien.

### Les listes

Chaque liste est rangée dans son chapitre : « Mes sorts à suivre » dans Mes soins (partie Sorts suivis), « À ignorer » (affaiblissements à ne jamais afficher) dans Affaiblissements, partie Icônes, et « À mettre en avant » (affaiblissements à montrer en grand) dans Affaiblissements, partie Importants. Tapez le nom exact, puis Entrée. Cliquez sur un nom pour le retirer.

### En donjon et en raid

- **Auras privées des boss** (chapitre Affaiblissements) : certains affaiblissements de boss sont cachés aux addons. Le jeu accepte pourtant de les dessiner lui-même sur la case : choisissez leur taille et leur place (au centre, en haut, en bas, à gauche ou à droite) dans les réglages fins. Deux au plus par joueur.
- **Absorption de soins** (chapitre Vie et portée, réglages fins de la partie Vie) : la bande rouge sombre au bout de la vie montre ce qu'un affaiblissement « mange ». Vos soins la remplissent d'abord. Le montant vient du jeu, il reste juste en combat.
- **Contour lumineux et son** (chapitre Affaiblissements, partie Importants) : un affaiblissement de votre liste « À mettre en avant », ou d'un boss, entoure la case d'un contour doré. Le son, à allumer dans les réglages fins, part pour ceux de votre liste.
  À savoir : en combat, le jeu cache souvent le nom des affaiblissements de boss. Lyorune ne peut alors pas savoir lequel est posé : le contour reste possible (le jeu décide lui-même s'il s'agit d'un boss), le son non.

## 10. Annonces et sons

Chapitre **Alertes** : Lyorune peut annoncer que votre mana est faible, qu'elle est remontée, et que vous relevez un joueur. Chaque annonce s'allume séparément et son texte est le vôtre. Écrivez `{mana}` pour votre pourcentage de mana et `{nom}` pour le joueur relevé. Les seuils se règlent avec « Seuil de mana faible (%) » et « Seuil de mana remontée (%) ».

À savoir : hors des donjons et des raids, le jeu interdit à un addon d'écrire en /dire tout seul. L'annonce part alors dans le canal du groupe.

**Mana faible sur WoW Forever** : le jeu cache votre mana aux addons, même hors combat. Il les laisse l'afficher (la barre bleue), mais pas la comparer à un seuil. Lyorune s'en sort ainsi : le jeu dit encore si un sort manque de mana. Lyorune prend dans votre grimoire le sort qui coûte à peu près votre seuil : quand ce sort manque de mana, votre mana est sous le seuil, et l'annonce part toute seule, en combat aussi. Le seuil est donc approché (par exemple 19 % pour 20 %) ; le chapitre Alertes indique le sort choisi, au bas de la partie Sons. Un sort refusé en combat avec « Pas assez de mana » déclenche aussi l'annonce. **Mana remontée sur WoW Forever** : aucun sort ne coûte 90 % de votre mana, alors Lyorune mesure la remontée. Pendant que vous buvez, vos sorts redeviennent utilisables l'un après l'autre, du moins cher au plus cher : à chaque fois, Lyorune sait que votre mana vient d'atteindre le coût de ce sort. Deux de ces paliers donnent la vitesse de remontée, boisson comprise, et l'annonce part au moment où votre mana atteint le seuil choisi (90 % par défaut). Le moment est estimé ; si vous lancez un sort pendant la remontée, Lyorune attend la prochaine alerte de mana faible. Pendant certains combats de boss, le jeu bloque tous les messages d'addon : rien ne peut partir.

## 11. Profils et partage

Chapitre **Profils et partage** (le profil actif se voit aussi sur l'Accueil, avec le bouton « Changer de profil ») :

- **Mes profils** : réglez l'apparence comme vous l'aimez, tapez un nom (par exemple « Donjon ») et cliquez sur « Enregistrer sous ». Un profil garde la taille, la forme, les couleurs, les indicateurs, vos soins sur la durée et le placement des éléments. Il ne touche jamais à vos clics, vos macros, vos listes ni vos annonces. Choisissez un profil dans la liste, puis « Charger » ou « Supprimer » (deux clics). « Copier... » ouvre une petite fenêtre pour copier seulement une partie d'un profil vers un autre : choisissez « De » et « Vers », cochez Disposition, Apparence, Vie et portée, Mes soins, Affaiblissements ou Joueurs (les réglages du chapitre du même nom), puis « Copier ». Le reste du profil d'arrivée ne bouge pas. Ce que vous réglez pendant qu'un profil est en cours lui appartient : Lyorune l'enregistre tout seul avant de changer de profil et à la déconnexion. Jusqu'à 20 profils.
- **Profils automatiques** : allumez « Changer de profil tout seul », puis remplissez le petit tableau. Une ligne par situation (seul ou à 5, raid de 10, de 25, de 40, champ de bataille, arène) et une colonne par spécialisation : cliquez sur une case pour passer au profil suivant, clic droit pour revenir en arrière. « - » veut dire « garder les réglages du moment ». Dans la colonne de la 2e spécialisation, « comme 1 » reprend le choix de la 1re. En champ de bataille ou en arène, « selon la taille » applique le profil prévu pour la taille du groupe. Le changement se fait sans /reload, dès que le groupe change de taille, que vous entrez en champ de bataille ou en arène (ou en sortez), ou que vous changez de spécialisation ; en combat, il attend la fin du combat. Un message dans le chat dit quel profil vient d'être appliqué.
- **Profils prêts à l'emploi** : Donjon, Raid, Compact, Grand et lisible. Un clic change la taille et la disposition ; vos clics sont conservés.
- **Donner ma configuration** : copiez le code affiché et envoyez-le à un ami, qui le colle dans « Recevoir une configuration ». Le code contient l'apparence (placements des éléments compris), les clics et les listes, mais jamais vos macros ni les phrases de vos annonces (mana, résurrection) : personne ne peut vous faire dire quelque chose dans le chat.
- **Envoi direct** : tapez le nom d'un joueur qui a Lyorune. Il reçoit une demande et choisit d'accepter ou non. Une demande n'arrive que d'un membre de votre groupe, de votre guilde ou de votre liste d'amis, une fois par minute au plus. La fenêtre affiche le nom et le royaume de l'expéditeur, et le bouton « Importer » ne s'active qu'au bout de deux secondes.
- **Remise à zéro**, en bas du chapitre :
  - **Annuler l'import** : un code collé ou une configuration reçue ne vous plaît pas ? Ce bouton (ou `/lyorune annuler`) remet vos réglages d'avant le dernier import : apparence, clics, touches et listes. Lyorune garde cette sauvegarde même après un /reload, jusqu'au prochain import.
  - **Tout réinitialiser** : deux clics pour revenir aux réglages d'origine. Vos profils enregistrés et la position des cadres sont gardés. Pour un seul chapitre, utilisez plutôt « Rétablir cette page » au bas de ce chapitre.

## 12. Entre joueurs qui ont Lyorune

Lyorune se parle de façon invisible avec les autres joueurs du groupe qui l'utilisent. Tout se règle dans le chapitre Profils et partage, partie « Entre joueurs » :

- **Synchronisation entre joueurs** : l'interrupteur général. Coupé, rien ne part et rien n'est lu ; les réglages du dessous sont grisés.
- **Qui relève qui** (« Montrer qui relève qui ») : quand un soigneur commence une résurrection, son nom s'affiche en vert à la place de « Mort » sur la case du joueur, chez tous ceux qui ont Lyorune. Vous voyez d'un coup d'œil qui est déjà pris en charge : deux soigneurs ne relèvent plus le même joueur pendant qu'un autre attend. Le nom reste le temps du sort, puis une minute pendant que le joueur décide d'accepter. Pendant un combat de boss, le jeu bloque ces messages : seule l'icône de résurrection du jeu reste.
- **Qui a Lyorune** : sous ces réglages, Lyorune compte les joueurs du groupe qui l'utilisent. Passez la souris dessus pour la liste, avec la version de chacun, ou tapez `/lyorune groupe`.
- **Configurations** (« Accepter qu'on me propose une configuration », dans les réglages fins) : vous recevez seulement celles que vous acceptez (voir « Envoi direct » plus haut).
- **Nouvelle version** (« Me prévenir si une version plus récente existe », dans les réglages fins) : Lyorune vous prévient une fois si une version plus récente existe, avec l'adresse de sa page officielle, où chaque nouveauté est décrite. Après la mise à jour, la fenêtre des nouveautés les détaille aussi en jeu.

Rien n'est jamais appliqué sans votre accord. Un joueur qui envoie trop de messages est ignoré un moment.

Une nouvelle version n'est signalée que si deux joueurs différents l'annoncent. Téléchargez Lyorune uniquement sur sa page officielle : [github.com/BellaHealFr/Lyorune](https://github.com/BellaHealFr/Lyorune/releases/latest). Un autre site, ou un joueur qui vous envoie un fichier, n'est pas une source sûre.

## 13. Le bouton de la mini-carte

Un petit bouton rond aux couleurs de Lyorune se trouve au bord de la mini-carte.

- **Clic gauche** : ouvrir ou fermer les options.
- **Clic droit** : lancer ou fermer le mode test.
- **Glisser** : le déplacer autour de la mini-carte.

Vous n'en voulez pas ? Coupez « Bouton sur la mini-carte » (chapitre Fenêtre et aide, réglages fins de la partie Fenêtres de Lyorune). La commande `/lyorune` ouvre toujours les options.

## 14. L'inscription runique

Au bas de la fenêtre d'options, sous un trait fin, une ligne de runes s'écrit à l'ouverture, une rune après l'autre, puis une lueur la parcourt de temps en temps, de gauche à droite. Passez la souris dessus : une vague de lumière part du centre, puis la traduction apparaît. Ses couleurs suivent le thème des fenêtres : bleu givre, or doux, ou braise avec quelques étincelles. C'est la phrase que Muradin déchiffre sur le socle de Deuillegivre dans Warcraft III.

Elle ne sert à rien d'autre qu'au plaisir des yeux. Pour la retirer, coupez « Inscription runique au bas de cette fenêtre » (chapitre Fenêtre et aide).

## 15. Un problème ?

Tapez `/lyorune bug` (ou « Signaler un bug », chapitre Fenêtre et aide, partie Aide). Répondez aux trois questions, cliquez sur « Tout sélectionner », copiez avec Ctrl+C, puis collez le rapport à l'adresse affichée dans la fenêtre. Le nom de votre personnage, de votre royaume et des membres de votre groupe y est remplacé par « (joueur) » et « (royaume) » : le rapport est public. Pour un défaut d'affichage, joignez une capture d'écran.

Le pas à pas complet, avec la création du compte GitHub et l'envoi d'une image, est dans [SIGNALER_UN_BUG.md](SIGNALER_UN_BUG.md).

Lyorune ne vous dérange pas pour ses erreurs : au plus un message discret par session, que vous pouvez couper avec « Me prévenir quand Lyorune rencontre une erreur » (chapitre Fenêtre et aide, réglages fins de la partie Aide).

### Le jeu ralentit en grand raid ?

Lyorune ne travaille que lorsqu'un joueur change (vie, soins, affaiblissements). Seule la portée est revue deux fois par seconde. Sur un ordinateur modeste ou en raid de 40, allumez **Mode performance** (chapitre Fenêtre et aide, réglages fins de la partie Aide) : la portée n'est plus revue qu'une fois par seconde, et les icônes de soins et d'affaiblissements sont regroupées (un dixième de seconde de retard au plus). Rien ne disparaît de vos cases. Ce réglage peut être gardé dans un profil de raid.

Pour en avoir le cœur net, cliquez sur **Mesurer les performances** (même endroit) ou tapez `/lyorune mesure`, hors combat. Lyorune fait tourner ses cases sur un faux groupe de 5, 25 et 40 joueurs et affiche :
- le temps qu'il prendrait chaque seconde dans un combat chargé, pour chaque taille de groupe ;
- sa mémoire, à côté de celle des autres addons de soin ou d'interface chargés ;
- leur temps réel, si le profileur du jeu est actif.

Joignez ce résultat à votre signalement si le jeu ralentit avec Lyorune.

## Les commandes

Cette liste se retrouve en jeu : chapitre Fenêtre et aide, « Commandes ».

| Commande | Effet |
|---|---|
| `/lyorune` | Ouvrir les options |
| `/lyorune test` | Mode test |
| `/lyorune tuto` | Tutoriel en jeu |
| `/lyorune assistant` | Assistant de départ (trois questions) |
| `/lyorune verrou` | Verrouiller ou libérer la position |
| `/lyorune reset` | Remettre les cadres au centre |
| `/lyorune epingler` | Épingler ou retirer le joueur survolé (ou votre cible, ou le nom tapé après) |
| `/lyorune porteur` | Le joueur survolé (ou votre cible, ou le nom tapé après) reçoit vos buffs uniques à la place du tank ; une 2e fois : retour au tank |
| `/lyorune groupe` | Joueurs du groupe qui ont Lyorune |
| `/lyorune annuler` | Revenir à la configuration d'avant le dernier import |
| `/lyorune mesure` | Mesurer les performances (hors combat) |
| `/lyorune bug` | Signaler un problème |
| `/lyorune nouveautes` | Voir les nouveautés de la version |
