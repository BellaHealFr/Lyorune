# Lyorune : le guide du joueur

Tout ce qu'il faut savoir pour soigner avec Lyorune. Aucune connaissance technique n'est nécessaire.
En jeu, le même parcours existe en version courte : tapez `/lyorune tuto`.

Au tout premier lancement, un **assistant** pose trois questions avant la visite : votre rôle (soigneur, tank ou dégâts), la taille de groupe où vous jouez le plus (seul ou à 5, raid de 10 à 25, raid de 40) et la forme des cases, choisie sur des vignettes. Lyorune se règle d'après vos réponses ; tout se retouche ensuite dans les options. « Passer » ou la croix gardent vos réglages actuels, forme des cases comprise. Pour le revoir : `/lyorune assistant`, ou « Assistant de départ » dans l'Accueil des options.

[English version](GUIDE.en.md)

## 1. La fenêtre d'options

Tapez `/lyorune` (ou cliquez sur le bouton de Lyorune au bord de la mini-carte). La fenêtre a trois colonnes.

**À gauche, la barre latérale** : douze chapitres, chacun avec sa rune. Un clic ouvre un chapitre. À chaque connexion, la fenêtre s'ouvre sur l'Accueil ; pendant la partie, elle rouvre le dernier chapitre utilisé. Une petite pastille d'or compte, dans chaque chapitre, les réglages que vous avez choisis vous-même et qui diffèrent de l'installation : Lyorune ne change rien tout seul.

| Chapitre | Ce que vous y réglez |
|---|---|
| Accueil | Votre profil, vos réglages changés, le tutoriel, l'assistant et les nouveautés |
| Disposition | Taille des cases, rangement, position, cadres affichés (tanks, cible, joueurs épinglés...) |
| Apparence | Forme des cases, thème, couleurs, transparence, texte |
| Vie et portée | Soins en route, bouclier, vie basse, barre de mana, joueurs loin ou hors de vue |
| Mes soins | Vos soins sur la durée, les coins de la case, vos sorts suivis, la recharge globale, vos recharges et celles du groupe, vos totems, le trait de canalisation |
| Affaiblissements | Dissipation et image du type, icônes et leurs secondes, affaiblissements importants, joueur sous contrôle, auras privées des boss |
| Joueurs | Rôle, marqueur, chef, gros défensifs, menace, buffs manquants, infobulle |
| Sorts et raccourcis | Vos sorts sur les clics et les touches, vos macros |
| Alertes | Annonces dans le chat et sons |
| Profils et partage | Profils, partage de configuration, échanges entre joueurs, remise à zéro |
| Fenêtre et aide | Thème de cette fenêtre, effets, langue, aide, lecture d'une case, commandes |

**Au milieu, le chapitre ouvert** : ses réglages sont rangés par parties (« Taille des cases », « Rangement »...) et la page défile à la molette.

**À droite, la case témoin** : une fausse case agrandie qui suit chaque réglage en direct, avec une petite phrase qui dit ce qu'elle montre (bouclier, coins, soins sur la durée...). Dessous, un faux groupe de cinq, puis les boutons du mode test (voir la partie 7).

**Régler** :

- **Interrupteur** : un clic l'allume ou le coupe (dans le thème Classique, il a l'allure d'une case à cocher du jeu).
- **Choix côte à côte** : cliquez sur celui que vous voulez. Une liste de choix plus longue passe au suivant à chaque clic (clic droit : au précédent).
- **Nombre** : boutons « - » et « + », ou cliquez sur la valeur : tapez le nombre et appuyez sur Entrée, ou ajustez-le à la molette. Maj + molette change la valeur sans clic ; sinon la molette fait défiler la page, sans changer un réglage au passage.
- **Réglages fins (n)** : au bas de chaque partie, les réglages moins courants sont repliés. Un clic les déplie ; Lyorune retient ce que vous avez déplié.
- **Réglage grisé** : il dépend d'un autre réglage qui est coupé (par exemple la hauteur de la barre de mana quand la barre de mana est coupée). Il reste réglable et compte dès que l'autre est rallumé.

**Ce que vous avez changé** : tout s'enregistre tout seul, dès que vous touchez un réglage. Pour revenir en arrière :

- **Rune d'or** : elle s'allume à côté de chaque réglage qui n'a plus sa valeur d'installation. Survolez-la pour voir cette valeur, cliquez dessus pour la reprendre.
- **« Rétablir cette page »** : au bas d'un chapitre où un réglage a changé. Deux clics, et chaque réglage du chapitre reprend sa valeur d'installation. Vos listes, vos textes d'annonce, vos clics et vos profils ne bougent pas.
- **« Annuler mes changements »** : en bas à droite de la fenêtre, dès que vous avez changé quelque chose depuis son ouverture. Deux clics, et tout reprend la valeur qu'il avait quand vous avez ouvert la fenêtre : réglages, clics, listes (joueurs épinglés compris), macros de votre bibliothèque, textes d'annonce et placement des éléments. Vos profils enregistrés ne bougent pas. Ouvrir une autre fenêtre de Lyorune, lancer la visite ou l'assistant ne compte pas comme une fermeture ; fermer la fenêtre, si. En combat, vos clics reviennent dès la fin du combat.
- **« Enregistrer mes réglages »** : en bas à gauche, sous les chapitres. Tapez un nom et appuyez sur Entrée (Échap annule) : vos réglages du moment deviennent un profil, que vous retrouverez dans Profils et partage (voir la partie 11).

**Retrouver un réglage** : en haut à droite, tapez un mot dans « Rechercher un réglage... » (« mana », « tank », « thème »...). Lyorune cherche dans le nom des réglages, puis dans leurs explications. Majuscules et accents ne comptent pas : « echelle » trouve « Échelle générale ». Un clic sur un résultat ouvre le bon chapitre, déplie les réglages fins si besoin et fait clignoter le réglage. « Mode test » fait clignoter les boutons 5, 10, 25 et 40 sous la case témoin, sans quitter la page.

**L'Accueil** montre :

- **Profil actif** : le profil en cours et comment il a été choisi, avec le bouton « Changer de profil » ;
- **Vos réglages changés** : tous vos réglages qui ne sont plus comme à l'installation. Un clic sur un nom vous y emmène ; un clic sur sa rune d'or le rétablit ;
- **Découvrir** : « Lancer le tutoriel », « Assistant de départ » et « Nouveautés de Lyorune ». Les nouveautés se rouvrent aussi à tout moment par le bouton « Nouveautés » en haut de la fenêtre, à gauche de la recherche, par Maj + clic sur le bouton de la mini-carte ou par `/lyorune nouveautes` ; après une mise à jour, une ligne dans la discussion le rappelle quand vous les fermez. Dans les nouveautés, « Me montrer » au bout d'une ligne ouvre les options sur son réglage, mis en lumière. La visite ferme la fenêtre le temps de montrer les cases, présente ensuite la fenêtre zone par zone (barre latérale, page du chapitre, case témoin, recherche), puis vous rend la fenêtre sur le chapitre où vous étiez. Ses cartes se posent à côté de vos cadres, jamais dessus ; si vos cadres sont cachés (« En combat seulement », ou seul sans votre propre cadre), elle ouvre le faux groupe du mode test pour vous montrer les cases, puis le referme. Échap ou la croix arrêtent la visite à tout moment, et la fenêtre revient de la même façon. Une fenêtre ouverte à côté des options (Mes macros, Placement, Signaler un bug...) est fermée au départ de la visite ; en ouvrir une pendant la visite l'arrête, et les options restent sur la page où vous êtes. L'assistant ferme aussi la fenêtre le temps de ses trois questions et vous la rend sur l'Accueil.

Au bas du chapitre Fenêtre et aide, « Lire une case » rappelle ce que veulent dire les couleurs principales d'une case, et « Commandes » liste les commandes `/lyorune`.

## 2. Les cases

Chaque joueur de votre groupe a une case. La barre colorée est sa vie : plus elle est courte, plus il est blessé.

| Ce que vous voyez | Ce que cela veut dire |
|---|---|
| Vert clair au bout de la barre | Des soins sont déjà en route |
| Bande claire en bas de la barre | Il a un bouclier (au choix, chapitre Vie et portée, « Place du bouclier » : à la suite de la vie, comme les cadres du jeu, avec un trait lumineux au bout quand le bouclier dépasse la vie manquante) |
| Petit chiffre « +1,2k » à la couleur du bouclier | Ce qui reste à absorber, tous boucliers comptés, même en combat ; il s'efface quand le dernier bouclier est cassé ou fini (« Chiffre du bouclier », chapitre Vie et portée, éteint au départ) |
| Une boisson en bas à gauche | Ce soigneur est à court de mana (seuil au choix dans le chapitre Vie et portée, « Mana basse des soigneurs ») : marche en combat, même quand le jeu cache la mana |
| Une deuxième boisson juste à droite, qui se vide | Ce soigneur est en train de boire (« Soigneur qui boit », même partie) : attendez qu'il ait fini avant d'avancer |
| Rouge sombre au bout de la vie | Un affaiblissement « mange » cette part de vie : vos soins la remplissent d'abord, avant de compter |
| Barre sous la vie | Sa ressource, à la couleur du jeu : mana en bleu, rage en rouge, énergie en jaune, focalisation en orange ; elle suit la forme du druide (pour tous, par défaut ; « Soigneurs » ne montre que leur mana ; hauteur de 2 à 60 pixels et couleur réglables dans le chapitre Vie et portée, réglages fins de la partie Mana ; la vie garde toujours au moins 10 pixels de la case ; couleur de la mana : bleu, bleu ciel, violet, turquoise ou blanc). Avec « Pourcentage de mana dans la barre », le % s'y écrit, même en combat |
| Liseré rouge fixe, en combat | Sa vie est basse |
| Bordure rouge | Il est attaqué |
| Trait de couleur en haut de la vie (si vous l'allumez) | Sa menace : jaune, il prend de la menace sur un monstre ; orange, le monstre va se tourner vers lui ; rouge, le monstre s'en prend à lui |
| Petit carré de couleur dans un coin | Un sort que vous avez placé dans ce coin (chapitre Mes soins) : il se vide avec le temps |
| Bordure blanche | C'est votre cible |
| Contour et léger voile bleu, violet, brun ou vert | Une magie, une malédiction, une maladie ou un poison que VOUS pouvez retirer (le nom et la vie restent lisibles) |
| Case estompée | Il est hors de portée de vos soins |
| Vie, mana et nom pâles (si vous l'allumez) | Il est en bonne santé, au-dessus de votre seuil (90 % au départ) : ceux qui ont besoin de soins ressortent. Ses icônes, la dissipation et la menace restent nettes, et la case survolée redevient nette. Interrupteur « Estomper les joueurs en bonne santé », chapitre Vie et portée, éteint au départ |
| Trait doré au bord gauche | C'est un de vos joueurs : un groupe de raid ou un joueur dont vous vous occupez (chapitre Joueurs, partie Mes joueurs), ou votre part de la répartition envoyée par le chef. Rien ne s'affiche tant que vous n'avez rien choisi |
| Case encore plus estompée, empreintes au centre | Il est très loin (plus de 100 mètres environ) : il faut vraiment vous déplacer. Marche aussi en donjon et en raid |
| Un œil au centre, pendant 3 secondes | Le jeu vient de refuser votre soin : il est hors de vue (derrière un pilier, un mur). Décalez-vous |
| « Mort », « Fantôme », « Déco » | Il est mort, en fantôme, ou déconnecté (sa case reste en place) |
| Petites icônes en haut à gauche (Tuile, Carré), en haut à droite de la vie (Barre) ou en haut du bloc au bout de la case (Bandeau) | Vos soins sur la durée posés sur lui |
| Icônes en bas à droite (Tuile, Carré), en bas à droite de la vie (Barre) ou en bas du bloc au bout de la case (Bandeau) | Ses affaiblissements |
| Grande icône à gauche | Un affaiblissement important (boss, ou votre liste) |
| Petite image à gauche, à côté de la place de la grande icône ; en Barre et Bandeau, juste avant le nom (goutte bleue, crâne violet, fiole verte...) | Le type de l'affaiblissement que vous pouvez dissiper : magie, malédiction, poison, maladie |
| Contour doré qui pulse | Un affaiblissement important est posé (avec un son pour ceux de votre liste, si vous l'allumez) |
| Icône à liseré bleu au bord droit (Tuile, Carré), ou juste avant le chiffre de vie (Barre, Bandeau) | Un gros défensif posé sur lui, par n'importe qui : Mur protecteur, Bouclier divin, Bénédiction de protection, Écorce, Évasion, Bloc de glace... (deux au plus) |
| Icône à liseré rouge au centre | Il est sous contrôle : étourdi, apeuré, métamorphosé, endormi... |
| Icônes dessinées par le jeu (au centre, par défaut) | Des affaiblissements de boss que le jeu cache aux addons : il les montre lui-même sur la case |
| Rangée de petites icônes en bas à gauche | Vos buffs à reposer sur ce joueur, gris à bord rouge : absent, perdu ou bientôt fini. Un buff posé ne se montre pas. Seule exception : votre buff unique (Bouclier de terre...), en couleur avec ses charges sur son porteur, gris dès qu'il tombe. La même rangée hors combat, en combat et en champ de bataille |
| Icône de résurrection au centre | Quelqu'un est en train de le relever |
| Icône d'invocation au centre | Une invocation lui est proposée, ou il l'a acceptée ou refusée |
| Icône de phase au centre | Il est dans une autre phase : il semble proche, mais vos sorts ne l'atteignent pas |
| Couronne près de l'icône de rôle | C'est le chef du groupe (un petit drapeau : un assistant du raid). Elle ne se pose jamais sur l'icône de rôle : si vous l'avez poussée dessus dans l'éditeur de placement, elle revient juste à côté chez un tank ou un soigneur |

Les couleurs principales sont rappelées en jeu : chapitre Fenêtre et aide, « Lire une case ».

Survolez une case hors combat : l'infobulle montre le joueur, puis la liste de vos clics et touches avec le sort ou la macro de chacun.

**Signaler un joueur au groupe** : survolez sa case et appuyez sur la touche de signal du jeu (réglée dans les raccourcis du jeu). Le joueur est marqué pour tout le groupe, comme si vous visiez son personnage, mais sans le chercher dans la mêlée. À couper dans le chapitre Joueurs (« Signal du jeu sur une case », dans les réglages fins de la partie Au survol d'une case).

## 3. Soigner d'un clic

Cliquez sur une case : le sort part sur ce joueur, sans le cibler.

**Cibler un joueur** : Alt + clic gauche sur sa case ; Alt + clic droit ouvre son menu. Ces deux clics sont posés au départ (et ajoutés à la mise à jour s'ils étaient libres, chez Lyorune comme dans le clic pour lancer du jeu) et se changent comme les autres : « Cibler » et « Menu du joueur » sont en haut de la fenêtre de choix du sort, pour n'importe quel clic ou touche au survol. Pour vous cibler vous-même ou cibler un membre du groupe sans la souris, le jeu a déjà ses raccourcis : Échap, Options, Raccourcis, rubrique Ciblage (« Cibler soi-même », puis chaque membre du groupe).

Pour choisir vos sorts : `/lyorune`, chapitre **Sorts et raccourcis**. Tous vos raccourcis sont sur une seule liste, un par ligne : à gauche le clic ou la touche, au milieu le sort, à droite « x » pour le retirer.

**Ajouter un raccourci :**

1. Cliquez sur « + Ajouter un clic ou une touche ».
2. Faites sur ce même bouton la combinaison voulue : un clic (gauche, droit, milieu, boutons 4 et 5), avec ou sans Alt, Ctrl, Maj, et même plusieurs à la fois (Ctrl + Maj + clic droit). Une touche du clavier, un bouton de souris supplémentaire ou la molette marchent aussi.
3. Choisissez le sort dans la fenêtre qui s'ouvre. Lyorune ne propose que les sorts que votre personnage connaît à son niveau.

**Quels sorts sont proposés ?** Tous vos soins, dissipations, résurrections et buffs, même ceux qui n'ont pas de cible : Feu intérieur, boucliers et armes du chaman, auras et Fureur vertueuse du paladin, Nova sacrée, Tranquillité, totems de soins. Un sort offensif n'est jamais proposé. Un sort manque ? Tapez `/lyorune sorts` : Lyorune écrit dans la discussion les sorts qu'il propose, ceux de votre classe qui manquent et pourquoi (pas appris, autre spécialisation, passif), et ceux qu'il écarte.

**Choisir le rang d'un sort** (pour garder de la mana, ou un petit soin rapide en champ de bataille) : au départ, tous vos raccourcis lancent le rang le plus haut. Pour choisir, cochez « Choisir le rang des sorts » (partie Comportement) ; décochée de nouveau, tout repart au rang le plus haut, et les rangs que vous aviez choisis reviennent si vous la recochez. Ensuite, dans la fenêtre de choix, un petit chiffre dans le coin d'une icône dit que ce sort a plusieurs rangs. Un clic prend le rang le plus haut, qui suit vos nouveaux rangs quand vous montez de niveau. Un **clic droit** ouvre la liste de ses rangs, avec le niveau où chacun s'apprend et ce qu'il coûte en mana ; la bulle du jeu, au survol, donne ses chiffres exacts. La ligne du raccourci dit alors le rang (« Soins supérieurs, rang 1 »). Vous pouvez aussi glisser un rang depuis votre grimoire : un rang bas reste ce rang, le rang le plus haut devient « le plus haut ». Le grimoire du jeu cache parfois les rangs bas : la liste le dit, et une option des réglages du grimoire les montre. Un rang que ce personnage ne connaît pas (code de partage d'un autre joueur, autre personnage) est écrit en orange et lance le rang le plus haut. Les macros « Lyo: » des barres de sorts et les codes de partage gardent le rang.

**Un joueur de bas niveau ?** Rien à régler : pour un buff ou un soin sur la durée lancé au rang le plus haut, le jeu lance tout seul le rang le plus fort que ce joueur peut recevoir. Un rang que vous avez choisi s'adapte lui aussi : sur la case d'un joueur de trop bas niveau, Lyorune pose le meilleur de vos rangs qu'il peut recevoir, jamais plus fort que celui choisi (« Rang adapté au niveau du joueur soigné », réglages fins, coché au départ). C'est calculé hors combat, à chaque changement de groupe, de niveau, de cible ou de focalisation ; en combat, la case garde son rang jusqu'à la fin du combat. Si aucun de vos rangs n'est assez bas, le rang choisi part et le jeu peut le refuser.

**Un autre sort selon la situation (variantes)** : le petit « + » au bout d'une ligne ajoute une variante de ce raccourci, montrée juste en dessous, en retrait. Le même clic lance alors autre chose :
- **Sur un ennemi** : sur une case qui montre un ennemi (Cible, Focalisation, un allié sous Contrôle mental), par exemple Châtiment ou Dissipation de la magie au lieu de votre soin. La fenêtre de choix propose alors vos sorts offensifs. Le jeu choisit au moment du clic, même en combat.
- **En JcJ** : en champ de bataille, par exemple un rang plus bas ou un soin plus rapide. Lyorune pose ce sort à votre entrée et remet l'autre à votre sortie (si vous sortez en combat, à la fin du combat).
- **Sur un tank** : par exemple Soins supérieurs au rang le plus haut sur le tank, et un rang économe sur les autres, avec le même clic. Toujours juste dans le cadre « Tanks » et dans les cadres par rôle (disposition « Par rôle » en raid), même si le groupe change en plein combat. Ailleurs, Lyorune la pose hors combat selon le rôle de chaque joueur ; si un rôle change en combat, la case suit à la fin du combat. Pour un rang sûr à tout moment, affichez le cadre « Tanks ». Sur un tank, cette variante passe aussi avant celle « Hors combat » ; en JcJ, celle « En JcJ » passe avant elle.
- **Hors combat** : un sort seulement, par exemple un buff hors combat et votre soin en combat. Le jeu choisit au moment du clic.

Une variante a son « x » pour la retirer seule ; retirer le raccourci retire aussi ses variantes, et changer sa combinaison les emmène avec lui. Elles passent dans les codes de partage et dans l'infobulle « Mes clics » des cases.

**Aucun soin sur un ennemi** (partie Comportement, coché au départ) : sur une case qui montre un ennemi, un raccourci sans variante « Sur un ennemi » ne fait rien, au lieu d'envoyer votre soin vers lui (le jeu peut sinon le lancer sur vous). Cibler, Menu du joueur et Arrêter l'incantation marchent partout.

**Ce qui est impossible** : choisir un sort selon la vie ou la mana du joueur. Le jeu cache ces valeurs en combat et aucune macro ne peut les lire.

Il n'y a pas de limite : ajoutez autant de lignes que vous voulez. Toutes les lignes restent visibles ; quand la liste est longue, faites défiler la page à la molette.

- **Changer le sort** : cliquez sur le sort de la ligne, ou glissez-y un sort de votre grimoire.
- **Changer le raccourci** : cliquez sur le clic ou la touche de la ligne, puis faites la nouvelle combinaison. Si elle était déjà prise, les deux sorts sont échangés : rien n'est perdu.
- **Utiliser un bijou avec le sort** : allumez d'abord « Bijoux avec les sorts » (réglages fins de Comportement). Chaque ligne a alors deux petits carrés au bout, vos bijoux du haut (1) et du bas (2) ; l'infobulle dit lequel. Cliquez sur l'un pour l'allumer (bordure d'or, icône de votre bijou) : le bijou est utilisé juste avant le sort, seulement si le joueur est vivant. Cliquez de nouveau pour l'éteindre. Si le bijou n'est pas prêt, le sort part quand même.
- **Savoir quels clics servent** : allumez « Compter mes clics » (partie Comportement). Un nombre apparaît à côté de chaque ligne : combien de fois vous l'avez utilisée, pour ce personnage et cette spécialisation (l'infobulle dit depuis quand). Une ligne jamais utilisée est grisée : un clic que vous pouvez peut-être libérer. Chaque clic compte, même si le sort échoue (hors de portée, en recharge). Changer le sort d'une ligne remet son compte à zéro ; échanger deux raccourcis garde le compte de chaque sort. « Remettre mes comptes à zéro » repart de zéro pour la spécialisation affichée.
- **Arrêter l'incantation** : dans la fenêtre de choix du sort, ce bouton fait d'un clic un « stop » qui interrompt le sort en cours (un long soin devenu inutile, par exemple).
- Un clic gauche ou droit sans sort, seul ou avec Maj, Ctrl, Alt, garde son rôle habituel : cibler le joueur, ouvrir son menu.

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

Lyorune garde vos macros dans une bibliothèque. Vous écrivez une macro une seule fois, puis vous la posez sur autant de clics et de touches que vous voulez, dans vos deux spécialisations. Si vous la modifiez, tous ses clics suivent. Elle ne prend aucune place dans la fenêtre `/macro` du jeu, sauf si vous la glissez dans une barre de sorts (voir plus bas).

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
- un crochet oublié, une macro trop longue : le jeu n'accepte pas plus de 255 caractères, cible comprise (le compteur sous la macro les compte) ;
- une macro qui tient sur un clic mais pas dans une barre de sorts du jeu, où la cible prend un peu plus de place (en jaune : elle reste bonne pour vos clics) ;
- un sort que votre spécialisation active ne connaît pas (c'est peut-être celui de l'autre) ;
- un sort écrit avec d'autres accents que dans votre grimoire : le jeu écrit parfois un nom sans accent (« Epines ») et `/cast Épines` ne lance alors rien. Lyorune donne la bonne écriture, et « Corriger l'écriture », à côté du titre « Vérification », la reprend dans la macro ;
- une commande qui exécute du code (`/run`, `/script`).

Les trois premiers constats sont écrits, le nombre des suivants est donné au bout du titre « Vérification ». Juste dessous, « Envoyé au jeu » montre le texte exact qui partira au clic, et « Posée sur » les clics qui utilisent la macro, puis sa copie dans `/macro` si vous l'avez glissée dans une barre. Un texte trop long pour sa place se lit en entier en passant la souris dessus.

La macro s'enregistre toute seule quand vous changez de macro ou fermez la fenêtre. « Enregistrer » le fait tout de suite et l'écrit deux secondes sur le bouton : « Enregistrée ».

L'assistant, l'import et le choix d'un sort s'ouvrent toujours par-dessus Mes macros, entiers.

**Poser la macro sur un clic :**

- glissez-la de la liste sur le sort d'une ligne du chapitre **Sorts et raccourcis** ;
- ou cliquez sur ce sort : vos macros sont listées sous vos sorts, à la ligne « Mes macros ».

Sur un petit écran, la fenêtre d'options s'efface tant que la bibliothèque est ouverte : fermez la bibliothèque, les options reviennent, puis cliquez sur le sort d'une ligne.

**Poser la macro dans une barre de sorts du jeu :** hors combat, glissez-la de la liste dans une barre de sorts. Lyorune en fait une vraie macro du jeu, rangée dans `/macro`, onglet de votre personnage, sous le nom « Lyo: » suivi du sien. Dans une barre, il n'y a pas de case : la macro vise le joueur sous votre souris (une case ou un personnage), sinon votre cible, sinon vous si le jeu lance les sorts sur vous quand rien n'est ciblé. Elle marche donc au clic sur la barre comme avec un raccourci.

La copie suit la macro : quand vous changez son texte ou son nom, elle change aussi (à la fin du combat si vous êtes en combat), et elle part quand vous supprimez la macro. Seules les macros que vous glissez prennent une place dans `/macro` ; s'il n'en reste plus, Lyorune le dit. Une macro trop longue pour une barre est refusée avec la raison, et reste bonne pour vos clics. Si vous retirez la copie vous-même dans `/macro`, Lyorune ne la recrée pas. Il ne touche jamais à vos autres macros.

**Supprimer une macro** demande un second clic : la macro part avec tous ses clics et ses touches. Changé d'avis ? « Annuler mes changements », au bas de la fenêtre d'options, rend la macro et ses clics.

Vos macros restent sur votre ordinateur : elles ne sont jamais envoyées ni reçues dans une configuration partagée, et « Tout réinitialiser » ne les efface pas. Quand un clic porte une macro, la résurrection automatique ne s'y ajoute pas : utilisez la case « Si le joueur est mort » de l'assistant.

Vous utilisiez déjà des macros avec une version précédente ? Elles sont rangées toutes seules dans la bibliothèque, sur les mêmes clics.

### Des macros toutes prêtes pour vos barres de sorts (facultatif)

Si vous le demandez, Lyorune crée une vraie macro du jeu pour chaque sort de vos clics. Rien n'est créé tant que le réglage n'est pas allumé.

1. Chapitre **Sorts et raccourcis**, partie « Macros pour vos barres de sorts » : allumez « Créer une macro par sort de mes clics ». Une icône par macro apparaît.
2. Cliquez sur une icône, puis déposez-la dans une barre de sorts. Vous les retrouvez aussi dans `/macro`, onglet de votre personnage : leur nom commence par « Lyo: ».

La macro soigne le joueur sous votre souris (une case ou un personnage), sinon votre cible, sinon vous, même quand le clic porte une macro de votre bibliothèque. Elle se met à jour quand vous changez vos clics. Lyorune ne touche jamais à vos autres macros. Pour vous en passer, coupez « Créer une macro par sort de mes clics » ou cliquez sur « Retirer les macros de Lyorune » : les macros que vous avez glissées depuis Mes macros restent dans vos barres.

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
- **Placer les éléments de la case** : bouton « Placer les éléments de la case... » (partie Taille des cases). Une case d'exemple, agrandie pour remplir toute la zone à droite de la liste, montre tous les éléments : nom, texte de vie, icône de rôle, icône de classe, marqueur de raid, chef de groupe, icône centrale, vos soins sur la durée, affaiblissements, affaiblissement important, joueur sous contrôle, gros défensifs, mes buffs (un posé, un à relancer) et auras privées. La case à cocher devant chaque élément l'affiche ou le masque sur vos cases : c'est le même réglage que dans les options (le nom et l'icône centrale ont le leur, chapitre Joueurs). Un élément masqué reste sur la case d'exemple, en transparence, et grisé dans la liste : il garde sa place et sa taille, et les retrouve quand vous le recochez ; vous pouvez même le placer avant de le réafficher. Sa place profite aux autres pendant qu'il est masqué : sans icône de rôle, vos soins sur la durée vont jusqu'au bord (Tuile, Carré) et le nom commence tout à gauche (Barre, Bandeau) ; sans mes buffs, les affaiblissements aussi ; en Barre et Bandeau, une rangée seule (soins ou affaiblissements) peut prendre toute la hauteur de la barre de vie. Les autres rendent la place quand il revient. « Tout afficher » les fait tous revenir d'un coup. Sous la liste, « Aussi sur la case » affiche ou masque la barre de mana, le bouclier, les soins en route, le liseré de vie basse, la bordure de menace et le cadre de dissipation (un réglage à choix, comme la barre de mana ou le texte de vie, reprend en revenant le choix que vous aviez). Glissez un élément avec la souris, ou choisissez-le dans la liste et poussez-le avec « Gauche », « Haut », « Bas », « Droite » : un pixel par clic, cinq avec Maj. Le décalage s'affiche sous la case et vos vraies cases suivent aussitôt. Pour la taille, « - » et « + » sous les flèches, ou la molette sur une icône de la case, la rapetissent ou la grandissent de 10 % par cran, de 50 à 300 % de sa taille d'origine ; vos soins sur la durée et les affaiblissements changent de taille ensemble, et leur rangée passe à la ligne ou rapetisse si elle ne tient plus. Une icône ne devient jamais plus grande que la case : « Au plus grand pour cette case » s'affiche alors. Si c'est un voisin qui la bloque, le message le nomme (« L'icône de rôle bloque : décochez-la pour lui laisser sa place »). « Remplir la place », à côté de « Tout afficher », donne d'un clic à l'élément choisi la plus grande taille qui tient. Le nom et le texte de vie suivent « Taille du texte », les auras privées « Taille des auras privées », et les barres fines de vos soins gardent leur épaisseur. Une taille changée en combat s'applique aux icônes d'auras dès la fin du combat. « Remettre à sa place » rend sa place et sa taille d'origine à l'élément choisi, « Tout remettre » à tous (un second clic confirme). Un élément s'arrête au bord de la case : il n'en sort jamais, ni sur la case d'exemple ni sur vos vraies cases, quelles que soient la forme et la taille des cases. Le nom et le texte de vie rétrécissent près du bord au lieu d'en sortir (un nom long finit alors par « ... »). Vos soins sur la durée et les affaiblissements sont montrés avec le nombre d'icônes que vous avez réglé : c'est la rangée entière qui reste dans la case. Quand une flèche ne peut plus pousser, « Au bord de la case » s'affiche sous la case. Le marqueur de raid, posé à cheval sur le haut de la case, peut descendre mais pas monter. Si vous réduisez ensuite la taille des cases, un élément poussé loin revient au bord tout seul, et retrouve sa place si les cases regrandissent. Chaque forme de case (Barre, Tuile, Carré, Bandeau) garde ses propres placements et ses propres tailles. Au départ, rien ne se couvre : vos soins sur la durée en haut à gauche, l'icône de rôle et le chef en haut à droite, le nom au milieu, mes buffs en bas à gauche et les affaiblissements en bas à droite (Tuile, Carré), le tout à la mesure de la case. **Chaque personnage a ses propres placements** : régler les éléments sur votre prêtre ne change rien sur votre paladin. Un nouveau personnage part des derniers placements utilisés. « Copier les placements de... », sous « Tout afficher », propose vos autres personnages qui ont placé un élément : choisissez-en un, ses placements et ses tailles, pour toutes les formes, remplacent ceux du personnage connecté. Les placements ne font pas partie des profils : ceux qu'un de vos profils gardait avant la 1.49.0, s'ils différaient des vôtres, restent proposés dans cette liste sous « Profil : son nom ». Un code de partage d'une version plus ancienne est converti à l'import : ses éléments arrivent là où son auteur les voyait. À la mise à jour vers la 1.49.0, un élément que vous aviez déplacé ou agrandi reste exactement là où vous l'aviez mis, à la même taille ; seule une rangée de vos soins ou d'affaiblissements qui couvrirait la couronne du chef ou mes buffs peut perdre un pixel ou deux.
- **Rangement** : par groupe, par rôle ou en grille (partie Rangement). Par rôle, choisissez l'ordre (tank, soin, dégâts, ou une autre des six combinaisons) avec « Ordre des rôles », dans les réglages fins. En grille, tout le raid tient d'un seul bloc, sans trou entre les groupes : « Cases par colonne en grille » (réglages fins) règle sa hauteur (8 cases par colonne donnent 5 colonnes pour 40 joueurs). Un réglage qui ne sert pas avec le rangement choisi est grisé.
- **Ordre dans chaque bloc** : l'ordre du groupe, par nom, ou par classe puis par nom (tous les prêtres ensemble, puis tous les druides...). C'est le jeu qui tient cet ordre à jour, même en plein combat, quand quelqu'un arrive ou change de groupe. En rangement par rôle, « par classe » range par nom dans chaque rôle.
- **Chaque groupe garde sa place** (réglages fins) : en rangement par groupe, le groupe 3 reste toujours en 3e colonne, même si le groupe 2 est vide. Pratique pour retrouver un joueur d'un coup d'œil. Coupé, les groupes se resserrent.
- **Tanks** : un cadre à part, déplaçable séparément (partie Cadres affichés).
- **Familiers** : « Familiers » (partie Cadres affichés) : Non, En groupe (le départ) ou En groupe et en raid. Seul ou en groupe, les familiers forment une colonne à part, à droite du groupe, chacun en face de son maître : vous voyez tout de suite à qui il est. En raid, une colonne « Familiers » se place à droite des groupes, rangée dans l'ordre des groupes ; chaque case porte le nom du maître (celui du familier est dans l'infobulle). Un familier a la couleur de la classe de son maître, en plus pâle, et sa case est estompée quand il est hors de portée de votre sort du clic gauche. Leurs cases sont plus petites (« Taille des familiers », 60 % au départ, dans les réglages fins). Un familier appelé en combat apparaît aussitôt. Le mode test en montre aussi.
- **Joueurs épinglés** : un petit cadre « Épinglés » pour les joueurs que vous voulez garder à part (un 2e tank, un joueur à surveiller). Pour épingler quelqu'un : survolez sa case et tapez `/lyorune epingler` (pratique dans une macro sur une touche), ou ciblez-le et cliquez sur « Épingler ma cible », ou tapez son nom dans la liste « Joueurs épinglés » (ces deux-là sont dans les réglages fins de la partie Cadres affichés). Le même geste le retire. Le cadre n'apparaît que si un joueur de la liste est dans votre groupe ; il se déplace par son étiquette. En combat, un changement de la liste attend la fin du combat.
- **Cible, cible de la cible, focalisation** : partie Cadres affichés, « Case de ma cible », puis dans les réglages fins « Case de la cible de ma cible » et « Case de ma focalisation ». Elles apparaissent dans un petit cadre « Cible », que l'on déplace par son étiquette comme les autres. Chaque case a vos clics et la même apparence que celles du groupe. Elle n'apparaît que si la cible ou la focalisation existe, même en combat. Un ennemi est en rouge, un personnage non joueur amical en vert, et ni l'un ni l'autre n'affiche d'icônes de soins ou d'affaiblissements. La cible de votre cible (par exemple le joueur que le boss frappe) est revue deux fois par seconde, car le jeu ne prévient pas quand elle change.
- **Quand les afficher** : « Afficher les cadres » propose « Toujours » ou « En combat seulement ». « Toujours » garde les cadres à l'écran, en combat comme hors combat, y compris quand vous jouez seul en quête (avec « Mon cadre quand je suis seul » allumé). Même sans votre cadre, Lyorune vous propose vos propres buffs quand vous jouez seul. « En combat seulement » les fait apparaître au début de chaque combat et disparaître à la fin. Les étiquettes s'affichent avec les cadres.
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
- **Contraste élevé** : cases sur fond noir, bordure blanche, texte plus gros. Il vaut aussi pour les fenêtres de Lyorune, en gris très foncé et texte clair (plus reposant pour les yeux que le noir et le blanc purs). Il remplace le thème et la texture des barres : ces deux lignes restent grisées tant qu'il est allumé.
- **Couleurs de classe** : « Vives » (par défaut) pour des couleurs franches et lumineuses, ou « Naturelles » pour celles du jeu. Grisé si les barres ne sont pas aux couleurs de classe.
- **Transparence** : « Opacité des cadres (%) » et « Opacité hors de portée (%) ». Dans les réglages fins, « Luminosité des barres (%) » et trois préréglages en un clic : « Discret », « Semi-transparent », « Bien visible ».
- **Texte de vie** : vie manquante, pourcentage, ou rien ; avec la taille du texte.

### Les fenêtres de Lyorune

Chapitre **Fenêtre et aide**, partie « Fenêtres de Lyorune » : elle habille la fenêtre d'options, la visite guidée et les petites fenêtres, jamais les cases.

- **Thème des fenêtres** : trois habillages complets, chacun avec son cadre, ses boutons, ses interrupteurs et ses titres de rubrique. Le changement est immédiat, sans `/reload`, et l'en-tête (logo, nom, version) ne bouge pas.
  - **Moderne** (par défaut) : fond sombre et net aux angles arrondis, boutons plats, interrupteurs à pastille qui glisse, bleu givre et or du logo.
  - **Classique** : comme les fenêtres du jeu, avec le cadre de boîte de dialogue, les boutons rouges et les cases à cocher du jeu, et des champs de saisie creusés.
  - **MMORPG** : un grimoire, avec un fond de pierre voilé derrière le texte, une bordure dorée, une rune gravée dans chaque angle, des plaques de bronze au biseau doré en guise de boutons (elles s'enfoncent au clic), des champs de saisie creusés, des interrupteurs cerclés d'or et marqués d'une rune et des titres de rubrique en écriture ancienne.
- **Effets magiques** (allumés par défaut) : une lumière de soin, or et vert, traverse l'en-tête ; une animation entoure le logo, aux couleurs des classes de soin (druide, paladin, prêtre, chaman) ; de petites particules de lumière montent dans l'en-tête ; la rune du chapitre ouvert s'allume dans la barre latérale ; et à chaque réglage changé, un éclat de soin passe sur la case témoin, dont la vie remonte. Les particules prennent la couleur du thème (givre en Moderne, or en Classique, braise en MMORPG). Rien de tout cela ne touche aux cases de soin.
- **Animation du logo** (avec les effets magiques) : à choisir parmi trois, toutes lentes et douces, sans rien qui clignote.
  - **Aurore** (par défaut) : une lueur par classe de soin dérive autour du logo, les couleurs se mêlent ; un reflet glisse sur le médaillon toutes les 10 secondes et de petites étincelles de soin montent du bord.
  - **Sceau** : un anneau doré porte une gemme par classe ; une traînée de lumière court d'une gemme à la suivante, qui s'allume et donne sa couleur au halo derrière le logo.
  - **Souffle** : toutes les 4 secondes, une onde de soin sort du bord du logo et s'efface en s'élargissant, chaque fois de la couleur de la classe suivante.
  - **Aucune** : le logo seul, les autres effets magiques restent.
- **Animations réduites** : les fenêtres s'ouvrent en simple fondu, les runes et le logo restent immobiles, rien ne bouge en boucle, et les effets magiques sont coupés. Pratique si le mouvement vous gêne.

Les fenêtres des macros, du placement des éléments, du rapport de bug, du journal, des nouveautés et des performances s'ouvrent à côté de la fenêtre d'options, sans jamais la recouvrir. Si la place manque, la fenêtre d'options glisse sur le côté ; sur un petit écran, elle s'efface le temps que l'autre fenêtre est ouverte et revient ensuite, sur le même chapitre. Une fenêtre plus grande que votre écran est réduite pour tenir entière. Une seule de ces fenêtres est ouverte à la fois : en ouvrir une ferme la précédente. Rappelée alors qu'elle est déjà ouverte, une fenêtre passe devant sans rien perdre : vos réponses au rapport de bug restent.

## 9. Choisir ce qui s'affiche

Chaque élément de la case a son interrupteur, rangé selon ce qu'il montre. Rien n'est obligatoire. Vous pouvez par exemple n'afficher que les affaiblissements que vous pouvez dissiper.

- **Vie et portée** : soins en route, bouclier et son chiffre (éteint au départ), liseré de vie basse, en combat seulement et jamais sur les familiers (son seuil dans les réglages fins), absorption de soins, joueurs en bonne santé estompés (éteint au départ, leur seuil dans les réglages fins), barre de mana, mana basse des soigneurs, et les deux indices de portée ci-dessous.
- **Mes soins** : vos soins sur la durée, les coins de la case, vos sorts suivis, la recharge globale, vos recharges et celles du groupe, vos totems, le trait de canalisation.
- **Affaiblissements** : dissipation et image du type, icônes et leurs secondes, affaiblissements importants, joueur sous contrôle, auras privées des boss.
- **Joueurs** : nom du joueur, icône de rôle, icône des DPS (épée, éteinte au départ), icône de classe (éteinte au départ), marqueur de raid, chef de groupe, gros défensifs, icône au centre de la case (appel, résurrection, hors de vue, invocation, très loin), invocation et phase, menace, buffs manquants, mes joueurs (répartition entre soigneurs), infobulle.

### La portée (chapitre Vie et portée)

**Joueur très loin : empreintes** et **Soin refusé, hors de vue : un œil** : deux interrupteurs, partie Portée. Le jeu ne donne pas la position des joueurs en donjon ni en raid (pas de flèche possible) ; ces deux indices marchent partout, même en combat.

### Vos soins sur la durée (chapitre Mes soins)

Lyorune s'adapte à votre classe (prêtre, druide, paladin ou chaman) : il suit vos soins sur la durée et vos boucliers (prêtre : Mot de pouvoir : Bouclier et Égide divine ; paladin : Veille de la Lumière et Serment de lumière, avec ses bénédictions de protection), plus les sorts de votre liste. Le chiffre du bouclier allumé, l'icône de votre bouclier dit aussi ce qui lui reste quand le jeu le laisse lire ; sinon, elle garde son décompte et le chiffre de la case dit ce qui reste. Ces icônes, comme celles des affaiblissements, des coins et la bordure de dissipation, sont dessinées par le jeu lui-même : elles restent visibles en plein combat, même quand le jeu cache les auras aux addons. Le nom et la vie restent toujours lisibles par-dessus. Un sort de la liste des affaiblissements à ignorer ou importants peut s'écrire par son nom ou par son numéro ; un nom est reconnu en combat dès que Lyorune a vu l'affaiblissement une fois hors combat.

- **Nombre de soins affichés** : de 1 à 6 par case (4 au départ). Dans le chapitre Affaiblissements, **Nombre d'affaiblissements** (réglages fins de la partie Icônes) fait de même pour les affaiblissements : de 2 à 5 (2 au départ). Ceux que vous pouvez dissiper passent toujours en premier, le plus important d'abord : **Affaiblissements à dissiper** (partie Icônes) en montre de 1 à 3 (2 au départ), et la rangée s'allonge d'autant. Un changement fait en combat s'applique dès la fin du combat.
- **Icônes ou barres fines** : choisissez l'affichage. Sur les icônes, quatre réglages fins se combinent comme vous voulez :
  - **Cercle qui se vide** : un voile tourne à mesure que le temps passe ;
  - **Décompte en secondes** : les secondes restantes, écrites par le jeu, à la taille de l'icône (elles ne débordent jamais sur la voisine) ;
  - **Icône qui s'efface à la fin** : vers la fin du soin, l'icône s'assombrit. C'est le moment de relancer ;
  - **Nombre de charges** : un petit chiffre quand le soin en a plusieurs.
- **Coins de la case** : placez un de vos sorts dans chaque coin. Il devient un petit carré de couleur (vert, bleu, jaune, rose) qui se vide avec le temps, et quitte la rangée d'icônes. D'un coup d'œil, vous voyez qui n'a pas votre Rénovation ou votre Récupération. Chaque classe garde ses propres coins : votre druide et votre prêtre ne se mélangent pas. Les coins choisis se voient aussi sur la case témoin et dans le mode test.
- **Mes sorts à suivre** (partie Sorts suivis) : ajoutez un de vos sorts, il s'affiche avec vos soins sur la durée et vous est proposé pour les coins. Infusion de puissance (prêtre) et Innervation (druide) sont déjà suivies : vous voyez sur qui elles sont posées.
- **Sort que je ne peux pas relancer** (prêtre et paladin, allumé au départ) : après un Mot de pouvoir : Bouclier, le vôtre ou celui d'un autre prêtre, Âme affaiblie empêche un nouveau bouclier sur ce joueur. Chez le paladin, Longanimité (après Bouclier divin, Protection divine ou Bénédiction de protection) empêche les trois. Son icône, grise et assombrie, prend la dernière place de la rangée de vos soins (avec 4 soins réglés : 3 soins, puis elle), et quitte la rangée des affaiblissements. Elle marche en combat, avec ses secondes restantes (« Ses secondes restantes », réglages fins).
- **Recharge globale et incantation** (partie Recharges et canalisation, coupé au départ) : une fine barre sous les cadres, ou un anneau autour du curseur, au choix. Blanc pendant le temps de recharge global, couleur d'accent pendant votre incantation. Vous voyez d'un coup d'œil quand le prochain soin peut partir, même en combat.
- **Mes recharges** (même partie, éteint au départ) : une rangée d'icônes sous vos cadres, sous le bandeau des buffs manquants quand il est là. On y trouve les sorts de vos raccourcis dont la recharge dépasse la recharge globale (Prière de guérison, Prompte guérison, Remous...), et vos gros sorts même lancés d'une barre (Pénitence, Innervation, Rapidité de la nature, Imposition des mains, Totem de vague de mana...). Le jeu dessine lui-même le balayage et les secondes, en plein combat aussi ; l'icône est grisée tant que le sort recharge, nette dès qu'il est prêt. Survolez une icône : son raccourci, et s'il est prêt. **Icônes montrées** : « Tous mes sorts » (vous voyez aussi ce qui est prêt) ou « En recharge seulement » (la rangée n'apparaît que quand un sort recharge). Un sort que vous ne voulez pas y voir : tapez son nom dans **Recharges à ne pas montrer**. Hors combat, l'infobulle « Mes clics » d'une case écrit en rouge un sort en recharge, avec ses secondes.
- **Mes totems** (même partie, éteint au départ, pour le chaman) : une rangée sous vos recharges, un emplacement par élément (Feu, Terre, Eau, Air). Le totem posé montre son image et son temps qui tourne, même en combat ; un emplacement vide reste pâle, et quand rien n'est posé la rangée disparaît. Survolez une icône : le totem et son élément.
- **Recharges du groupe** (même partie, éteint au départ) : sous vos recharges, une ligne par gros sort de vos alliés : résurrection en combat (Renaissance), mana (Innervation, Infusion de puissance, Totem de vague de mana), protections posées sur un autre (Imposition des mains, Bénédictions de protection et de sacrifice, Gardien de peur, Intervention divine), gros soin de groupe (Tranquillité). Sur chaque ligne, le nom de chacun à la couleur de sa classe : net quand son sort est prêt, pâle avec ses secondes sinon (écrites par le jeu). Survolez un nom : le sort et dans combien de temps il est prêt. **Seuls les joueurs qui ont Lyorune y figurent** : le jeu cache aux addons les sorts lancés par les autres. Pendant un combat de boss ou un match JcJ, le jeu bloque les messages entre addons : la ligne garde le dernier état connu (le titre dit « avant le boss ») et se met à jour à la fin. Un sort que vous ne voulez pas voir : même liste, **Recharges à ne pas montrer**. Vos propres sorts partent chez les autres avec « Partager mes recharges » (chapitre Profils et partage).
- **Trait de canalisation** (même partie, allumé au départ) : quand vous canalisez un soin sur un joueur (Pénitence du prêtre), un trait à la couleur d'accent se vide en haut de sa case au rythme de la canalisation. Vous voyez qui le reçoit et quand il finit, même en combat. Il suit le clic ou la touche au survol qui a lancé le sort ; jamais pour un soin sans cible (Tranquillité), ni sur un ennemi.

Tout marche en combat. Le jeu y cache le nom des auras, mais Lyorune reconnaît vos soins à leur numéro, ou au sort que vous venez de lancer. Un soin qu'il ne peut pas reconnaître reste dans la rangée d'icônes, jamais dans un mauvais coin.

### Mes joueurs : la répartition entre soigneurs (chapitre Joueurs)

En raid, chaque soigneur s'occupe souvent de quelques groupes ou d'un tank. Partie « Mes joueurs » :

- **Groupes de raid dont je m'occupe** : cliquez sur les numéros (1 à 8). Ils ne comptent qu'en raid.
- **Joueurs dont je m'occupe** : un tank, un joueur à surveiller. Tapez son nom puis Entrée, ou survolez sa case et tapez `/lyorune pourmoi` (une 2e fois pour le retirer). En groupe de cinq, seuls ces joueurs comptent.
- **Repère sur mes joueurs** (allumé au départ) : un trait doré au bord gauche de leur case. Rien ne s'affiche tant que vous n'avez rien choisi.
- **Estomper un peu les autres** (réglages fins, éteint au départ) : les joueurs dont vous ne vous occupez pas deviennent un peu plus transparents. Votre propre case reste nette, et la portée continue d'estomper ceux qui sont loin.

Tout marche sans aucun message, même si vous êtes le seul à avoir Lyorune. Pour que le chef répartisse tout le monde d'un coup, voir « Répartition du chef » au chapitre 12.

### Les buffs (chapitre Joueurs)

- **Buffs manquants à poser** (prêtre, paladin, chaman, druide, mage) : hors combat, chaque buff qui manque à un joueur vous est proposé, un par un : un joueur sans Robustesse ni Esprit divin en a deux. Un clic lui lance le buff, sans le cibler ; un clic droit lance la version de groupe. Quand trois joueurs d'un même groupe, à portée du sort, n'ont pas le buff, une seule proposition « Groupe N » lance directement la version de groupe, et leurs cases montrent l'icône de cette version (Prière de robustesse...) : vous voyez d'un coup d'oeil qu'un seul sort suffit. Ce nombre se règle juste sous « Mes buffs » : « Sort de groupe dès (joueurs sans le buff) », de 2 à 5. Un joueur trop loin ne compte pas, puisque le sort de groupe ne le toucherait pas : il garde sa propre ligne, estompée, en fin de liste. Les familiers ne sont jamais proposés (la version de groupe les couvre). Vos propres buffs passent en premier. Un buff posé par un autre joueur n'est jamais remplacé avant sa fin ; un buff unique presque fini (Épines...) est proposé de nouveau sur celui qui le porte. Si le jeu refuse le buff sur un joueur (buff plus fort déjà là, avantage de camp, trop loin, hors de vue), Lyorune passe au suivant et le repropose plus tard. Un joueur de bas niveau reçoit un rang qu'il peut porter. Rien n'est proposé tant que vous êtes mort. Tout se cache en combat et revient après, et disparaît quand tout est posé. Une touche peut aussi lancer le premier : choisissez-la dans les raccourcis du jeu (voir « Les raccourcis du jeu », plus bas). Ce réglage a son propre interrupteur, séparé de la rangée de vos buffs sur la case (« Mes buffs sur la case »).
- **Mes buffs sur la case** (allumé au départ) : en bas à gauche de chaque case, seulement vos buffs **à reposer** sur ce joueur, une petite icône **grise à bord rouge** chacun : absent, perdu (fini, dissipé, joueur mort) ou bientôt fini (sous « Proposer à nouveau sous »). **Un buff posé ne se montre pas** : la case reste propre, rien à faire. Tous vos buffs à la fois (un prêtre en a jusqu'à quatre), et la même rangée partout : hors combat, en combat, en donjon et en champ de bataille. Votre buff unique (Bouclier de terre, Gardien de peur, Épines, Serment de lumière) a sa place au début de la rangée, sur son porteur : **en couleur avec ses charges** tant qu'il est là, dessiné par le jeu en temps réel, même en combat ; dès qu'il tombe (charges épuisées, dissipé, fini), son repère gris apparaît à la même place, sans attendre la fin du combat. Il ne se montre plus dans la rangée de vos soins (interrupteur « Buffs uniques en temps réel », allumé au départ). La rangée ne dépasse jamais le bord de la case. Elle se déplace et s'agrandit dans « Placer les éléments de la case » (élément « Mes buffs »).
- **En combat** et **En champ de bataille** (deux interrupteurs sous « Mes buffs sur la case », allumés au départ) : en combat, le jeu cache les buffs aux addons : Lyorune garde ce qu'il a lu juste avant le combat et retient vos sorts réussis. Un buff revient en gris quand il passe sous le seuil, ou si le joueur meurt ; celui que vous reposez en combat disparaît aussitôt. Seule limite : un buff dissipé en plein combat se voit à la fin du combat (sauf votre buff unique, vu tout de suite). Éteint, rien n'apparaît sur les cases en combat (ou en combat pendant un match) ; hors combat, les buffs à reposer sont toujours montrés. « En combat » vaut aussi contre un boss. Sur un joueur qu'aucun de vos buffs ne concerne (buff décoché, groupe que vous ne buffez pas, aucune bénédiction prévue pour lui), rien n'apparaît. Un clic sur la case (ou la touche au survol) le relance, même en combat. Si le groupe change en plein combat, les icônes s'effacent jusqu'à la fin du combat, le temps que Lyorune sache de nouveau qui est qui. **La touche en combat** (« En combat, la touche relance mon buff unique », réglages fins) : en combat, la touche « Poser le prochain buff manquant » relance votre buff unique (Bouclier de terre, Gardien de peur...) sur son porteur. Elle est préparée juste avant le combat, par le nom du joueur : si le raid se réorganise, elle ne part jamais sur quelqu'un d'autre.
- **Emplacement des buffs manquants** : **Avec les cadres** (au départ), ils se collent sous votre dernier groupe, alignés sur la première colonne, à la taille, à l'échelle, au thème, à la texture et aux angles de vos cases. Un seul bandeau fin, le même pour toutes les formes de cases, exactement de la largeur d'une case, qui suit vos changements de taille et d'échelle : l'icône du buff à gauche, puis le joueur sur la première ligne (« Vous », un nom ou « Groupe 3 », en couleur de classe) et, dessous, « +2 autres » s'il en reste après lui, sinon le nom court du sort en gris (« Robustesse »). Case trop étroite pour le texte (en Carré) : l'icône seule, avec « +2 » dans son coin, le joueur et le sort dans l'infobulle. Sa hauteur suit la taille du texte. Le nom complet du sort est dans l'infobulle. Le bandeau montre le prochain buff à poser, le même que lance la touche : cliquez, il passe au suivant, jusqu'à ce que tout soit posé. Vos cadres trop bas à l'écran : ils passent au-dessus. Déplacez vos cadres, ils suivent. Un buff que vous venez de lancer n'est plus proposé pendant quelques secondes, le temps que le jeu le pose : appuyer deux fois sur la touche ne le relance pas sur le même joueur. Options ouvertes sur le chapitre Joueurs et rien à poser : une case d'exemple vous montre où ils apparaîtront (elle ne lance rien). **Où vous voulez** : une petite fenêtre à déplacer par son titre, qui en montre jusqu'à dix (sa place est gardée pour chaque personnage) ; sa croix la ferme jusqu'à la fin du prochain combat.
- **Les buffs de chaque classe** : prêtre, Robustesse, Esprit divin (seulement pour les joueurs à mana), Protection contre l'Ombre, Feu intérieur sur vous, et vos sorts de race (Toucher de faiblesse, Garde de l'ombre), seulement si votre personnage les a ; paladin, une bénédiction de vous par joueur (au départ : Rois pour le tank et le chasseur, Sagesse pour les joueurs à mana, Puissance pour les autres ; à changer dans la grille « Bénédiction par joueur », plus bas) Fureur vertueuse et votre aura sur vous (Dévotion, Concentration... : la dernière que vous avez lancée ; celle d'un autre paladin ne compte pas) ; chaman, Bouclier d'eau ou de foudre sur vous et l'enchantement de votre arme (le dernier que vous avez lancé) ; druide, Marque du fauve, et Augure de clarté sur vous s'il se lance sur ce client (un sort passif n'est jamais proposé) ; mage, Intelligence des arcanes (joueurs à mana).
- **Mes buffs** : une ligne par buff de votre classe, avec deux cases . La version de groupe (Prière de robustesse, Prière d'Esprit, Don du fauve...) a sa propre ligne, juste en dessous, avec la mention « (groupe) ». Les deux se cochent séparément : les deux cochées, le panneau choisit selon le nombre de joueurs sans le buff ; seulement la version simple, il propose le buff joueur par joueur, sans dépenser de composant ; seulement la version de groupe, il propose une ligne « Groupe N » dès qu'un joueur du groupe n'a pas le buff ; aucune, le buff n'est pas surveillé. Sans le composant de la version de groupe (Chandelle sacrée...), le panneau propose la version simple, pour que vous ayez toujours quelque chose à lancer. « JcE » compte en donjon, en raid et dans le monde ; « JcJ » en champ de bataille. Au départ, tout est coché : décochez ce qui ne vous sert pas. Un sort pas encore appris est grisé, mais vous pouvez déjà le régler. Chaque icône est celle de votre grimoire, donnée par le jeu. En champ de bataille et pendant un boss, le jeu cache les buffs aux addons, même hors combat. Lyorune continue quand même : un buff que le jeu laisse lisible se lit toujours ; les autres, Lyorune les a notés juste avant le début du match, et il retient chaque buff que vous lancez (clic sur une case, sur les buffs manquants, macro ou cible), pendant sa durée. Un joueur mort perd ses buffs : au cimetière, ils vous sont proposés de nouveau. Les buffs posés par un autre joueur pendant le match restent inconnus : un buff dont Lyorune ne sait rien vous est proposé, mieux vaut une fois de trop que jamais. Un message le rappelle au début du match, et l'infobulle des buffs manquants aussi. Même quand le jeu refuse toute lecture, ou cache le nom d'un joueur (montré alors par son groupe), le joueur reste proposé, en combat ou non. `/lyorune buffs` dit, buff par buff, s'il est lisible ici et la durée que Lyorune connaît, puis combien de joueurs sont au panneau et pourquoi les autres n'y sont pas (morts, en combat, case cachée, lecture refusée).
- **Proposer à nouveau sous (secondes)** : un buff qui finit dans moins de secondes que ce nombre est proposé comme s'il manquait (gris sur la case, et sous vos cadres), pratique avant un boss. Au départ : 75 secondes avant sa fin, de 0 à 15 minutes par pas de 15 secondes (un ancien réglage en minutes est converti). Jamais avant le dernier quart d'un buff court : une bénédiction de 5 minutes attend ses 75 dernières secondes, pour ne pas gaspiller de mana. À 0, seulement quand il manque. Un buff sans fin n'est jamais proposé à nouveau. En donjon, le jeu cache parfois l'heure de fin d'un buff : Lyorune se souvient alors des buffs que vous avez lancés et de leur durée, et les propose quand même à temps ; un buff posé par un autre reste compté comme là (`/lyorune buffs` dit combien de joueurs sont dans ce cas).
- **Buffs à poser sur une seule personne** (chaman : Bouclier de terre ; druide : Épines ; prêtre : Gardien de peur, proposé quand sa recharge est finie ; paladin : Serment de lumière) : tant que le vôtre n'est sur personne, le panneau des buffs manquants propose une ligne pour son porteur, hors combat. **Choisissez le porteur de chaque buff dans « Mes buffs »**, sur la ligne « Sur : » juste en dessous du buff : **Tank** (au départ), **Moi**, ou **Un joueur** (tapez son nom puis Entrée, ou ciblez-le et cliquez sur « Ma cible »). Un joueur choisi absent du groupe : le buff va au tank ; sans tank, à vous. Raccourci : survolez une case et tapez `/lyorune porteur` (ou `/lyorune porteur Nom`) pour donner tous vos buffs uniques à ce joueur ; la même commande sur le même joueur vous ramène au tank. Si votre buff est déjà sur quelqu'un, Lyorune ne vous demande rien.
- **Groupes de raid que je buffe** : en raid, les buffs manquants ne sont proposés que pour les groupes allumés (tous au départ). Pratique quand deux prêtres se partagent le raid : l'un garde les groupes 1 à 4, l'autre 5 à 8. « Comme mes soins » reprend d'un clic les groupes que vous soignez (partie Mes joueurs). Vos propres buffs vous sont toujours proposés. Si le chef vous envoie une répartition des buffs avec des groupes, elle choisit pour vous tant qu'elle dure.
- **Bénédiction par joueur** (paladin) : une ligne par type de joueur, tanks, soigneurs, puis chaque classe. Cliquez sur le bouton d'une ligne pour passer à la bénédiction suivante (clic droit : la précédente), jusqu'à « Aucune ». « (départ) » montre le choix de Lyorune. **Plusieurs paladins** : une bénédiction déjà posée par un autre paladin n'est jamais reprise, même s'il n'a pas Lyorune ; Lyorune vous propose la suivante de la ligne (jamais Sagesse à un joueur sans mana). Avec « Entente entre paladins » (chapitre Profils et partage), les paladins qui ont Lyorune s'annoncent aussi leurs choix avant le combat, pour ne pas se marcher dessus avant même le premier sort.

### Les listes

Chaque liste est rangée dans son chapitre : « Mes sorts à suivre » dans Mes soins (partie Sorts suivis), « À ignorer » (affaiblissements à ne jamais afficher) dans Affaiblissements, partie Icônes, et « À mettre en avant » (affaiblissements à toujours montrer, en grand, avec contour et son) dans Affaiblissements, partie Importants.

**Toujours montrés** (chapitre Affaiblissements, partie Icônes) : les affaiblissements utiles à un soigneur, même s'ils ne se dissipent pas, montrés dans les trois modes, en combat aussi, sans son ni contour. Au départ, pour toutes les classes : Âme affaiblie (pas de nouveau Mot de pouvoir : Bouclier) et Longanimité (pas de nouvelle Bulle). Le bouton « Choisir parmi... » ouvre une liste déroulante : cochez ceux à montrer, elle reste ouverte pour en cocher plusieurs. Elle propose aussi les affaiblissements déjà vus sur votre groupe. Tapez un nom ou un numéro dans le champ à côté pour filtrer la liste ; Entrée, ou Maj-clic sur un sort, en ajoute un jamais vu. Les noms sont ceux de votre jeu, en français ou en anglais : vos choix restent les mêmes si vous changez de langue. Tapez le nom exact ou le numéro du sort, puis Entrée ; ou, le champ actif, faites Maj-clic sur un sort (discussion, grimoire, infobulle) : il entre dans la liste avec son numéro. Cliquez sur un nom pour le retirer.

En combat, le jeu cache le nom des affaiblissements : Lyorune ne les reconnaît qu'à leur numéro. Dans « À mettre en avant », un nom en gris n'est pas encore reconnu (survolez-le) : il le sera la première fois qu'il est vu hors combat, ou tout de suite si vous tapez son numéro ou faites Maj-clic sur le sort. Un nom normal marche aussi en combat.

### En donjon et en raid

- **Auras privées des boss** (chapitre Affaiblissements) : certains affaiblissements de boss sont cachés aux addons. Le jeu accepte pourtant de les dessiner lui-même sur la case : choisissez leur taille et leur place (au centre, en haut, en bas, à gauche ou à droite) dans les réglages fins. Deux au plus par joueur.
- **Absorption de soins** (chapitre Vie et portée, réglages fins de la partie Vie) : la bande rouge sombre au bout de la vie montre ce qu'un affaiblissement « mange ». Vos soins la remplissent d'abord. Le montant vient du jeu, il reste juste en combat.
- **Secondes restantes** (chapitre Affaiblissements, partie Icônes, allumé au départ) : sur les icônes d'affaiblissements, celle du contrôle subi et la grande icône des affaiblissements importants, les secondes restantes, écrites par le jeu, même en combat. Vous voyez s'il vaut mieux dissiper tout de suite ou attendre la fin.
- **Icône du type à dissiper** (chapitre Affaiblissements, partie Dissipation, allumé au départ) : en plus de la couleur, l'image du type de l'affaiblissement que vous pouvez dissiper (goutte de magie, crâne de malédiction, fiole de poison...), posée par le jeu à gauche de la case, juste à droite de la place de la grande icône (en Barre et Bandeau : après l'icône de rôle, le nom part après elle), même en combat. Sa place et sa taille se règlent dans « Placer les éléments de la case... » (élément « Type à dissiper »). Avec « Cadre coloré quand je peux dissiper », le liseré de chaque icône d'affaiblissement prend aussi la couleur de son type : deux types différents se voient ensemble.
- **Affaiblissements affichés** (chapitre Affaiblissements, partie Icônes) : trois choix. « Tous » : tout ce que porte le joueur. « Utiles » : ceux que le jeu montre sur ses propres cadres de raid, et rien de plus de 5 minutes (Déserteur, Épuisement, fêtes) ; un affaiblissement de boss plus long reste dans la grande icône. « Ceux que je dissipe » : seulement ce que vous pouvez retirer. Dans les trois cas, un affaiblissement de vos listes « À mettre en avant » et « Toujours montrés » passe en tête de la rangée, même s'il est aussi dans « À ignorer » (en « Tous », ceux de « Toujours montrés » passent en tête à partir de 3 affaiblissements, sinon ils restent parmi les autres).
- **Joueur sous contrôle** (chapitre Affaiblissements, partie Importants) : un joueur étourdi, apeuré, métamorphosé ou endormi montre l'icône du contrôle au centre de sa case, avec un liseré rouge. C'est le jeu qui reconnaît les contrôles : ça marche en plein combat.

- **Gros défensifs des joueurs** (chapitre Joueurs, partie Sur la case) : Mur protecteur, Dernier rempart, Bouclier divin, Protection divine, Bénédictions de protection et de sacrifice, Évasion, Écorce, Bloc de glace, Dissuasion et Forme de pierre montrent leur icône, avec un liseré bleu, sur la case du joueur qui les porte, quel que soit celui qui les a lancés. Deux au plus, au bord droit de la case (juste avant le chiffre de vie en Barre et en Bandeau). Vous savez ainsi qui encaisse sans risque et qui a besoin de vos soins. Si vous lancez vous-même un de ces sorts (Bénédiction de protection), il quitte la rangée de vos soins pour ne pas être montré deux fois.

- **Contour lumineux et son** (chapitre Affaiblissements, partie Importants) : un affaiblissement de votre liste « À mettre en avant », ou d'un boss, entoure la case d'un contour doré (ceux de votre liste prennent aussi la première place de la rangée des affaiblissements). Le son, à allumer dans les réglages fins, part pour ceux de votre liste.
  À savoir : en combat, le jeu cache souvent le nom des affaiblissements de boss. Lyorune ne peut alors pas savoir lequel est posé : le contour reste possible (le jeu décide lui-même s'il s'agit d'un boss), le son non.

## 10. Annonces et sons

Chapitre **Alertes** : Lyorune peut annoncer que votre mana est faible, qu'elle est remontée, et que vous relevez un joueur. Chaque annonce s'allume séparément et son texte est le vôtre. Écrivez `{mana}` pour votre pourcentage de mana et `{nom}` pour le joueur relevé. Les seuils se règlent avec « Seuil de mana faible (%) » et « Seuil de mana remontée (%) ».

À savoir : hors des donjons et des raids, le jeu interdit à un addon d'écrire en /dire tout seul. L'annonce part alors dans le canal du groupe.

**Liseré de ma mana basse** (chapitre Vie et portée, partie Mana) : sans rien annoncer, un liseré bleu doux s'allume au bord de l'écran quand votre mana passe sous le seuil choisi (20 % au départ), de plus en plus net à mesure qu'elle descend. Le jeu le calcule lui-même : il marche en combat, même quand la mana est cachée. Il ne couvre aucune fenêtre et ne gêne aucun clic.

**Règle des 5 secondes sur ma case** (même partie, éteinte au départ : à vous de l'allumer) : après un sort qui coûte de la mana, le jeu coupe votre régénération pendant 5 secondes. Un trait fin, juste au-dessus de la barre de mana de votre propre case, se vide pendant ce temps : quand il a disparu, votre mana remonte de nouveau. Attendre sa fin avant le soin suivant, quand le groupe le permet, fait durer votre mana. Une baguette ou un objet ne le relancent pas.

**Mana faible sur WoW Forever** : le jeu cache votre mana aux addons, même hors combat. Il les laisse l'afficher (la barre bleue), mais pas la comparer à un seuil. Lyorune s'en sort ainsi : le jeu dit encore si un sort manque de mana. Lyorune prend dans votre grimoire le sort qui coûte à peu près votre seuil : quand ce sort manque de mana, votre mana est sous le seuil, et l'annonce part toute seule, en combat aussi. Le seuil est donc approché (par exemple 19 % pour 20 %) ; le chapitre Alertes indique le sort choisi, au bas de la partie Sons. Un sort refusé en combat avec « Pas assez de mana » déclenche aussi l'annonce. **Mana remontée sur WoW Forever** : aucun sort ne coûte 90 % de votre mana, alors Lyorune estime la remontée. Hors combat, le jeu donne votre régénération de mana par seconde, boisson comprise : Lyorune l'additionne au fil du temps, en partant du coût du sort le plus cher que vous pouvez encore lancer. Vos sorts gardent l'estimation dans le vrai : jamais en dessous d'un sort lançable, jamais au-dessus d'un sort qui manque de mana. L'annonce part quand l'estimation atteint le seuil choisi (90 % par défaut), jamais trop tôt : en combat rien n'est ajouté, et un sort lancé pendant la remontée fait repartir le calcul de plus bas. Pendant certains combats de boss, le jeu bloque tous les messages d'addon : rien ne peut partir.

## 11. Profils et partage

Chapitre **Profils et partage** (le profil actif se voit aussi sur l'Accueil, avec le bouton « Changer de profil ») :

- **Mes profils** : réglez l'apparence comme vous l'aimez, tapez un nom (par exemple « Donjon ») et cliquez sur « Enregistrer sous ». Un profil garde la taille, la forme, les couleurs, les indicateurs et vos soins sur la durée (le placement des éléments est propre à chaque personnage). Il ne touche jamais à vos clics, vos macros, vos listes ni vos annonces. Choisissez un profil dans la liste, puis « Charger » ou « Supprimer » (deux clics). « Copier... » ouvre une petite fenêtre pour copier seulement une partie d'un profil vers un autre : choisissez « De » et « Vers », cochez Disposition, Apparence, Vie et portée, Mes soins, Affaiblissements ou Joueurs (les réglages du chapitre du même nom), puis « Copier ». Le reste du profil d'arrivée ne bouge pas. Ce que vous réglez pendant qu'un profil est en cours lui appartient : Lyorune l'enregistre tout seul avant de changer de profil et à la déconnexion. Jusqu'à 20 profils.
- **Profils automatiques** : allumez « Changer de profil tout seul », puis remplissez le petit tableau. Une ligne par situation (seul ou à 5, raid de 10, de 25, de 40, champ de bataille) et une colonne par spécialisation : cliquez sur une case pour passer au profil suivant, clic droit pour revenir en arrière. « - » veut dire « garder les réglages du moment ». Dans la colonne de la 2e spécialisation, « comme 1 » reprend le choix de la 1re. En champ de bataille, « selon la taille » applique le profil prévu pour la taille du groupe. Le changement se fait sans /reload, dès que le groupe change de taille, que vous entrez en champ de bataille (ou en sortez), ou que vous changez de spécialisation ; en combat, il attend la fin du combat. Un message dans le chat dit quel profil vient d'être appliqué.
- **Profils prêts à l'emploi** : Donjon, Raid, Compact, Grand et lisible. Un clic change la taille et la disposition ; vos clics sont conservés.
- **Donner ma configuration** : copiez le code affiché et envoyez-le à un ami, qui le colle dans « Recevoir une configuration ». Le code contient l'apparence (placements des éléments compris), les clics et les listes, mais jamais vos macros ni les phrases de vos annonces (mana, résurrection) : personne ne peut vous faire dire quelque chose dans le chat.
- **Envoi direct** : tapez le nom d'un joueur qui a Lyorune. Il reçoit une demande et choisit d'accepter ou non. Une demande n'arrive que d'un membre de votre groupe, de votre guilde ou de votre liste d'amis, une fois par minute au plus. La fenêtre affiche le nom et le royaume de l'expéditeur, et le bouton « Importer » ne s'active qu'au bout de deux secondes.
- **Remise à zéro**, en bas du chapitre :
  - **Annuler l'import** : un code collé ou une configuration reçue ne vous plaît pas ? Ce bouton (ou `/lyorune annuler`) remet vos réglages d'avant le dernier import : apparence, clics, touches et listes. Lyorune garde cette sauvegarde même après un /reload, jusqu'au prochain import.
  - **Reprendre les clics proposés pour ma classe** : deux clics, et les clics et touches de votre spécialisation redeviennent ceux proposés pour votre classe. Changé d'avis ? « Annuler mes changements » vous les rend.
  - **Tout réinitialiser** : deux clics pour revenir aux réglages d'origine. Vos profils enregistrés et la position des cadres sont gardés. Pour un seul chapitre, utilisez plutôt « Rétablir cette page » au bas de ce chapitre.

## 12. Entre joueurs qui ont Lyorune

Lyorune se parle de façon invisible avec les autres joueurs du groupe qui l'utilisent. Tout se règle dans le chapitre Profils et partage, partie « Entre joueurs » :

- **Synchronisation entre joueurs** : l'interrupteur général. Coupé, rien ne part et rien n'est lu ; les réglages du dessous sont grisés. Pendant un combat de boss ou un match JcJ, le jeu bloque les messages entre addons : qui relève qui et la répartition se taisent, les recharges du groupe gardent leur dernier état jusqu'à la fin. En match JcJ, l'infobulle d'une case le rappelle en une ligne (« Match JcJ : le jeu cache les buffs et bloque les messages entre addons »). WoW Forever n'a pas d'arène JcJ : Lyorune ne propose rien pour elle.
- **Qui relève qui** (« Montrer qui relève qui ») : quand un soigneur commence une résurrection, son nom s'affiche en vert à la place de « Mort » sur la case du joueur, chez tous ceux qui ont Lyorune. Vous voyez d'un coup d'œil qui est déjà pris en charge : deux soigneurs ne relèvent plus le même joueur pendant qu'un autre attend. Le nom reste le temps du sort, puis une minute pendant que le joueur décide d'accepter. Pendant un combat de boss, le jeu bloque ces messages : seule l'icône de résurrection du jeu reste.
- **Répartition du chef** : le chef du groupe ou un assistant ouvre « Répartir les soigneurs... » (chapitre Joueurs, partie Mes joueurs, ou `/lyorune repartir`). Une ligne par soigneur du groupe (en vert : ceux qui ont Lyorune), une colonne par groupe de raid et par tank : il coche, puis « Envoyer au groupe ». Chez chaque soigneur qui a Lyorune, sa part remplace son propre choix : ses repères changent tout de suite, une ligne dans la discussion le dit, et au survol d'une case (hors combat) le soigneur prévu s'affiche. Elle reste valable jusqu'au prochain envoi, jusqu'à « Effacer pour tous », ou jusqu'à ce que vous quittiez le groupe (votre choix revient alors), même après un /reload. Envoyez-la **avant le combat** : pendant un combat de boss ou un match JcJ, le jeu bloque ces messages et Lyorune refuse l'envoi avec un message. Une fois reçue, elle ne demande plus aucun message : elle tient tout le combat. Un soigneur qui quitte le groupe disparaît de la répartition : ses joueurs n'ont plus de soigneur prévu, et celui qui l'a envoyée est prévenu pour en renvoyer une. Un soigneur qui arrive avec Lyorune la reçoit tout seul. Pour l'ignorer : décochez « Appliquer la répartition du chef ».
- **Répartition des buffs** : de la même façon, le chef ou un assistant ouvre « Répartir les buffs... » (chapitre Joueurs, partie Buffs, bouton de la fenêtre des soigneurs, ou `/lyorune repartir buffs`). Une ligne par joueur qui pose des buffs de groupe (prêtre, druide, mage, paladin), une colonne par groupe de raid, et pour chaque paladin la bénédiction qu'il pose en premier (clic : la suivante). Chez chacun, ses groupes et sa bénédiction suivent tout de suite, avec une ligne dans la discussion. Mêmes règles que la répartition des soigneurs : avant le combat, valable jusqu'au prochain envoi, et la même case « Appliquer la répartition du chef » pour l'ignorer.
- **Entente entre paladins** : chaque paladin qui a Lyorune annonce aux autres sa bénédiction pour chaque type de joueur. Si deux veulent la même, celle imposée par le chef passe d'abord, puis celle choisie dans la grille, puis le choix de départ ; à égalité, le premier nom dans l'ordre alphabétique la garde, l'autre passe à la suivante. Annoncé avant le combat, valable ensuite sans aucun message. `/lyorune buffs` dit ce que chacun a annoncé.
- **Partager mes recharges** (éteint au départ, à vous de l'allumer) : vos gros sorts (Renaissance, Innervation, Imposition des mains, Totem de vague de mana...) sont annoncés au groupe quand vous les lancez et quand ils sont prêts, plus un état complet quand vous rejoignez un groupe. Vos alliés qui suivent les « Recharges du groupe » les voient sans rien vous demander. Aucun message régulier, aucun pendant un combat de boss (le jeu les bloque : votre état part à la fin).
- **Qui a Lyorune** : sous ces réglages, Lyorune compte les joueurs du groupe qui l'utilisent. Passez la souris dessus pour la liste, avec la version de chacun, ou tapez `/lyorune groupe`.
- **Configurations** (« Accepter qu'on me propose une configuration », dans les réglages fins) : vous recevez seulement celles que vous acceptez (voir « Envoi direct » plus haut).
- **Nouvelle version** (« Me prévenir si une version plus récente existe », dans les réglages fins) : Lyorune vous prévient une fois si une version plus récente existe, avec l'adresse de sa page officielle, où chaque nouveauté est décrite. Après la mise à jour, la fenêtre des nouveautés les détaille aussi en jeu.

Rien n'est jamais appliqué sans votre accord, sauf la répartition du chef si « Appliquer la répartition du chef » reste coché : elle ne change que vos repères. Un joueur qui envoie trop de messages est ignoré un moment.

Une nouvelle version n'est signalée que si deux joueurs différents l'annoncent. Téléchargez Lyorune uniquement sur sa page officielle : [github.com/BellaHealFr/Lyorune](https://github.com/BellaHealFr/Lyorune/releases/latest). Un autre site, ou un joueur qui vous envoie un fichier, n'est pas une source sûre.

## 13. Le bouton de la mini-carte

Un petit bouton rond aux couleurs de Lyorune se trouve au bord de la mini-carte.

- **Clic gauche** : ouvrir ou fermer les options.
- **Clic droit** : lancer ou fermer le mode test.
- **Maj + clic gauche** : relire les nouveautés.
- **Glisser** : le déplacer autour de la mini-carte.

Vous n'en voulez pas ? Coupez « Bouton sur la mini-carte » (chapitre Fenêtre et aide, réglages fins de la partie Fenêtres de Lyorune). La commande `/lyorune` ouvre toujours les options.

## 14. L'inscription runique

Au bas de la fenêtre d'options, sous un trait fin, une ligne de runes s'écrit à l'ouverture, une rune après l'autre, puis une lueur la parcourt de temps en temps, de gauche à droite. Passez la souris dessus : une vague de lumière part du centre, puis la traduction apparaît. Ses couleurs suivent le thème des fenêtres : bleu givre, or doux, ou braise avec quelques étincelles. C'est la phrase que Muradin déchiffre sur le socle de Deuillegivre dans Warcraft III.

Elle ne sert à rien d'autre qu'au plaisir des yeux. Pour la retirer, coupez « Inscription runique au bas de cette fenêtre » (chapitre Fenêtre et aide).

## 15. Les amis de Lyorune

Le dernier chapitre de la fenêtre d'options, en bas de la barre de gauche. Vous y trouvez :

- **Lyorune en chiffres** : le nombre de mises à jour, de téléchargements (GitHub et CurseForge) et de membres du Discord. Un addon n'a pas accès à internet : ces chiffres sont ceux du jour où votre version a été publiée, et la date est écrite dessous. Le lien du Discord se copie avec Ctrl+C.
- **Canal des soigneurs** : deux cases, « Canal en français » et « Canal en anglais », éteintes au départ. Cochée, Lyorune rejoint le canal du jeu « LyoruneFR » ou « LyoruneEN », ouvert à tous quelle que soit la langue de votre jeu : prenez le français, l'anglais ou les deux. C'est un lieu pour que les soigneurs échangent entre eux : leurs façons de jouer, leurs spécialisations et leurs talents, leurs astuces, leurs difficultés comme leurs réussites, et Lyorune bien sûr. Débutant ou vétéran, chacun y apprend des autres. Le jeu sépare l'Alliance et la Horde : vous y retrouvez les soigneurs de votre faction. Vous y écrivez avec son numéro, comme dans tout canal (la page vous le donne, par exemple `/5 Bonjour`). Lyorune n'y écrit jamais à votre place ; un gêneur se règle avec les outils du jeu (clic droit sur son nom : Ignorer ou Signaler). Décochée, Lyorune quitte le canal ; si vous le quittez vous-même (`/leave`), la case se décoche. Si un inconnu a verrouillé le canal, Lyorune passe à « LyoruneFR2 », puis « LyoruneFR3 ».
- **Votre carnet** : vos soins, vos résurrections et vos buffs réussis, pour chaque personnage, d'où qu'ils partent (cases, barres, macros, touches). Les dissipations ne comptent pas. Le carnet reste sur votre ordinateur : rien n'est envoyé. Deux colonnes : « En tout » et « Aujourd'hui », depuis votre connexion (gardée après un /reload). « Bilan en sortant d'un donjon » (allumé au départ) écrit dans la discussion, en sortant d'un donjon ou d'un raid, une ligne avec son nom, sa durée, vos chiffres dedans puis ceux du jour (rien si vous sortez mort, pour revenir après un wipe). Dans les nouveautés, les versions sorties depuis votre dernière lecture portent une rune d'or « Nouveau pour vous ». « Tenir mon carnet » l'arrête (vos chiffres sont gardés) ; « Remettre mon carnet à zéro » demande un second clic.
- **Un mot de l'auteur**, et le **mur de remerciements** : les joueurs qui font grandir Lyorune (leur nom à la couleur de leur classe, avec leur mode de jeu), en proposant des améliorations, en signalant des bugs régulièrement pour le rendre le plus parfait possible, ou en le faisant connaître autour d'eux. Vous en êtes ? Dites-le sur le Discord ou sur GitHub : un nom n'y figure qu'avec l'accord de son joueur.

## 16. Un problème ?

Tapez `/lyorune bug` (ou « Signaler un bug », chapitre Fenêtre et aide, partie Aide). Répondez aux trois questions, cliquez sur « Tout sélectionner », copiez avec Ctrl+C, puis collez le rapport à l'adresse affichée dans la fenêtre. Le nom de votre personnage, de votre royaume et des membres de votre groupe y est remplacé par « (joueur) » et « (royaume) » : le rapport est public. Pour un défaut d'affichage, joignez une capture d'écran.

Le pas à pas complet, avec la création du compte GitHub et l'envoi d'une image, est dans [SIGNALER_UN_BUG.md](SIGNALER_UN_BUG.md).

Lyorune ne vous dérange pas pour ses erreurs : au plus un message discret par session, que vous pouvez couper avec « Me prévenir quand Lyorune rencontre une erreur » (chapitre Fenêtre et aide, réglages fins de la partie Aide). Le « Journal d'erreurs » (même partie, ou `/lyorune erreurs`) se copie de la même façon ; « Vider le journal » demande un second clic.

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
| `/lyorune cadres` | Afficher ou masquer les cadres (hors combat) |
| `/lyorune epingler` | Épingler ou retirer le joueur survolé (ou votre cible, ou le nom tapé après) |
| `/lyorune porteur` | Le joueur survolé (ou votre cible, ou le nom tapé après) reçoit vos buffs uniques à la place du tank ; une 2e fois : retour au tank |
| `/lyorune pourmoi` | Ajouter ou retirer le joueur survolé (ou votre cible, ou le nom tapé après) de vos joueurs |
| `/lyorune repartir` | Répartir les soigneurs (chef ou assistant) |
| `/lyorune repartir buffs` | Répartir les buffs : groupes et bénédictions (chef ou assistant) |
| `/lyorune sorts` | Les sorts proposés dans Sorts et raccourcis, et pourquoi un sort manque |
| `/lyorune buffs` | Pour chacun de vos buffs : lisible ici ou caché par le jeu, et sa durée connue ; pourquoi un joueur manque au panneau ; vos groupes buffés et les bénédictions annoncées par les autres paladins |
| `/lyorune groupe` | Joueurs du groupe qui ont Lyorune |
| `/lyorune annuler` | Revenir à la configuration d'avant le dernier import |
| `/lyorune mesure` | Mesurer les performances (hors combat) |
| `/lyorune bug` | Signaler un problème |
| `/lyorune nouveautes` | Voir les nouveautés, avec « Me montrer » pour aller au réglage |

## Les raccourcis du jeu

Quatre actions de Lyorune peuvent recevoir une touche : Échap, Options, Raccourcis, rubrique AddOns, Lyorune. Aucune touche n'est posée au départ : vous choisissez les vôtres.

| Raccourci | Effet |
|---|---|
| Ouvrir ou fermer les options | Comme `/lyorune` |
| Afficher ou masquer les cadres | Hors combat. Masqués, ils le restent même en combat, jusqu'au prochain appui (ou `/lyorune cadres`). Ils reviennent d'eux-mêmes après un `/reload` ou à la prochaine connexion. |
| Poser le prochain buff manquant | Hors combat : lance le premier buff manquant proposé (sous vos cadres, ou première ligne de la fenêtre, même fermée). Appuyez autant de fois qu'il reste de buffs. En combat : relance votre buff unique sur son porteur. |
| Mode test | Comme `/lyorune test` |
