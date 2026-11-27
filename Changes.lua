-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Changes.lua : ce qui change à chaque version, affiché en jeu après une mise à jour.
-- Ce fichier est la SEULE source du journal des versions : outils/publier.py y ajoute la nouvelle version
-- et régénère CHANGELOG.md à partir de lui. La version la plus récente est en premier.
-- Trois rubriques par version : added (nouveau), improved (amélioré), fixed (corrigé).

local _, Z = ...

Z.changes = {
	{
		version = "1.51.1", date = "2026-11-27",
		added = {
		},
		improved = {
		},
		fixed = {
			"Druide : l'icône de rôle ne reste plus en DPS ou en tank après un passage en forme de félin ou d'ours. Le rôle vient de l'arbre de talents le plus rempli (Restauration : soigneur, Équilibre : DPS) et passe aux autres joueurs qui ont Lyorune. Réglage « Rôle du druide d'après ses talents » dans Joueurs, essai avec la commande /lyorune role.",
			"Plus d'erreur au relevé de la position des cadres quand le jeu garde secrète la visibilité d'un élément.",
		},
	},
	{
		version = "1.51.0", date = "2026-11-27",
		added = {
			"Liste « Toujours montrés » : Âme affaiblie et Longanimité visibles pour toutes les classes, aussi en « Utiles » et « Ceux que je dissipe », avec une liste déroulante à cocher qui propose les affaiblissements vus sur le groupe.",
		},
		improved = {
		},
		fixed = {
			"La bénédiction supérieure d'un autre paladin est reconnue : la simple n'est plus proposée par-dessus.",
		},
	},
	{
		version = "1.50.2", date = "2026-11-25",
		added = {
		},
		improved = {
		},
		fixed = {
			"Buffs manquants : le panneau et les repères gris des cases sont de nouveau cochés, une seule fois, pour ceux qui les avaient décochés sans le vouloir (ils semblaient ne plus marcher en instance). Les cases cachées ne suivent plus les joueurs du groupe pour rien, et /lyorune buffs compte toujours la case visible.",
		},
	},
	{
		version = "1.50.1", date = "2026-11-25",
		added = {
		},
		improved = {
		},
		fixed = {
			"Plus d'« action bloquée » quand un joueur rejoint le groupe ou le raid pendant un combat : sa case apparaît tout de suite, au lieu d'attendre la fin du combat.",
		},
	},
	{
		version = "1.50.0", date = "2026-11-24",
		added = {
			"Canal des soigneurs, en français et en anglais : sur la page « Les amis de Lyorune », deux cases (éteintes au départ) font rejoindre le canal du jeu LyoruneFR ou LyoruneEN, ouvert à tous quelle que soit la langue de votre jeu, pour échanger entre soigneurs sur vos façons de jouer, vos spécialisations, vos astuces et vos difficultés. Lyorune vous donne le numéro à taper et n'y écrit jamais à votre place ; chaque faction a son canal.",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.49.0", date = "2026-11-24",
		added = {
			"Placements propres à chaque personnage : chaque personnage garde la place et la taille de ses éléments, qui ne suivent plus les profils. Un nouveau personnage part de vos derniers placements, et le bouton « Copier les placements de... » de la fenêtre Placement des éléments reprend ceux d'un autre personnage.",
		},
		improved = {
			"Icônes mieux placées par défaut : rien ne se couvre plus aux tailles d'origine des quatre formes. En Tuile et en Carré, trois bandes (soins sur la durée, affaiblissements, rôle et buff) laissent le nom et la vie lisibles. Les éléments que vous aviez déplacés ou agrandis restent exactement à leur place.",
		},
		fixed = {
		},
	},
	{
		version = "1.48.1", date = "2026-11-24",
		added = {
		},
		improved = {
			"Nouveautés toujours à portée : un bouton Nouveautés en haut de la fenêtre d'options, à gauche de la recherche, et Maj + clic sur le bouton de la mini-carte. Après une mise à jour, une ligne dans la discussion rappelle comment les relire.",
		},
		fixed = {
			"Familiers : un familier mort n'est plus cerclé de rouge, le liseré de vie basse ne se montre jamais sur un familier.",
		},
	},
	{
		version = "1.48.0", date = "2026-11-24",
		added = {
			"Buffs uniques en temps réel : votre Bouclier de terre, Gardien de peur ou buff unique se voit en couleur sur le porteur, avec ses charges, et passe en gris dès qu'il tombe, même en combat (épuisé ou dissipé). Un buff unique d'un autre soigneur est reconnu.",
		},
		improved = {
			"Vie basse : un liseré rouge fixe, sans clignotement, en combat seulement ; le cadre de dissipation reste visible par-dessus.",
		},
		fixed = {
			"Familiers : le chiffre de vie ne recouvre plus leur nom.",
		},
	},
	{
		version = "1.47.0", date = "2026-11-24",
		added = {
			"Bilan en sortant d'un donjon ou d'un raid : une ligne dans la discussion donne son nom, sa durée, vos soins, résurrections et buffs dedans, puis ceux du jour. Le carnet a une colonne Aujourd'hui, depuis votre connexion.",
			"Nouveautés : un lien Me montrer mène au réglage de chaque nouveauté, et une rune d'or Nouveau pour vous marque les versions pas encore lues.",
		},
		improved = {
			"Buffs sur les cases : un buff posé ne se montre plus, la case reste propre. Il revient en gris seulement quand il faut le reposer (absent, perdu, bientôt fini, joueur mort), hors combat comme en combat, en JcE et en JcJ. En combat, Lyorune garde ce qu'il a lu avant le combat et retient vos sorts réussis.",
		},
		fixed = {
		},
	},
	{
		version = "1.46.5", date = "2026-11-24",
		added = {
		},
		improved = {
			"Familiers repensés : en groupe, une colonne à part, chacun en face de son maître, en cases plus petites (taille réglable) ; en raid, une colonne après les groupes, rangée par groupe, avec le nom du maître. Couleur du maître en plus pâle, portée juste, réglage à trois choix (Non, En groupe, En groupe et en raid), familiers aussi dans le mode test.",
		},
		fixed = {
		},
	},
	{
		version = "1.46.4", date = "2026-11-24",
		added = {
		},
		improved = {
		},
		fixed = {
			"Buffs manquants, version de groupe : seuls les joueurs à portée du sort comptent pour la ligne « Groupe N » (un joueur trop loin garde sa propre ligne), leurs cases montrent l'icône de la version de groupe, et le réglage « Sort de groupe dès » est toujours visible, sous « Mes buffs ».",
		},
	},
	{
		version = "1.46.3", date = "2026-11-24",
		added = {
		},
		improved = {
		},
		fixed = {
			"Buff presque fini : proposé de nouveau 75 secondes avant sa fin, en donjon aussi.",
			"Sur la case : tous les buffs qui manquent, en JcE comme en JcJ, et un buff perdu en gris.",
			"Bandeau des buffs manquants : un clic lance de nouveau le buff, quel que soit le réglage « lancer à l'appui ».",
			"Les familiers ne sont plus proposés aux buffs.",
			"Épines, Bouclier de terre et Gardien de peur de nouveau proposés dès qu'ils tombent, en donjon aussi.",
			"Buff refusé par le jeu (buff plus fort, avantage de camp, niveau trop bas, trop loin, hors de vue) : le joueur est mis de côté et le bandeau passe au suivant. Rang adapté au niveau, buff d'un autre jamais remplacé, buffs uniques renouvelés sur leur porteur, arme du chaman lue correctement, rien proposé quand vous êtes mort.",
		},
	},
	{
		version = "1.46.2", date = "2026-11-24",
		added = {
		},
		improved = {
		},
		fixed = {
			"Cibler un joueur : Alt + clic gauche cible le joueur et Alt + clic droit ouvre son menu, deux lignes de la liste des clics, ajoutées à la mise à jour si ces clics sont libres (dans Lyorune et dans le clic pour lancer du jeu). La visite guidée et le guide disent comment cibler.",
		},
	},
	{
		version = "1.46.1", date = "2026-11-24",
		added = {
			"Icône des DPS au choix : l'épée des DPS sur leur case, à côté des tanks et des soigneurs (chapitre Joueurs, éteinte au départ).",
		},
		improved = {
		},
		fixed = {
			"Groupe qui change (champ de bataille, raid de 40) : l'interface ne gèle plus et les cases ne perdent plus leur place. Chaque cadre est réglé d'un coup puis replacé une seule fois, et les changements en rafale sont regroupés.",
			"Le journal d'erreurs s'ouvre de nouveau en donjon et en combat, même quand le jeu cache certaines valeurs.",
			"La couronne du chef ne se pose plus sur l'icône de rôle d'un tank ou d'un soigneur, même déplacée dans l'éditeur de placement.",
		},
	},
	{
		version = "1.46.0", date = "2026-11-23",
		added = {
			"Mes totems (chaman) : vos totems posés sous les cadres, un emplacement par élément, avec leur temps, même en combat (éteint au départ).",
			"Icône de classe sur la case, placée et réglée dans l'éditeur de placement (éteinte au départ).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.45.0", date = "2026-11-23",
		added = {
			"Les amis de Lyorune : un nouveau chapitre des options avec Lyorune en chiffres (mises à jour, téléchargements, Discord), votre carnet de soigneur (soins, résurrections et buffs réussis, par personnage, avec son interrupteur), un mot de l'auteur et un mur de remerciements.",
		},
		improved = {
		},
		fixed = {
			"Nouveautés de la 1.44.1 : la ligne sur /lyorune buffs s'affiche correctement.",
		},
	},
	{
		version = "1.44.1", date = "2026-11-23",
		added = {
		},
		improved = {
			"/lyorune buffs dit aussi ce que le jeu cache ici et pourquoi un joueur manque au panneau (mort, en combat, case cachée, lecture refusée).",
		},
		fixed = {
			"Buffs manquants en champ de bataille : le panneau ne restait plus vide. Quand le jeu refuse de lire les buffs pendant un match ou un boss, Lyorune s'appuie sur ce qu'il a retenu (avant le match, vos sorts) et propose un buff dont il ne sait rien ; joueurs en combat et noms cachés gardés.",
		},
	},
	{
		version = "1.44.0", date = "2026-11-23",
		added = {
			"Match JcJ : hors combat pendant un match, l'infobulle d'une case dit en une ligne que le jeu cache les buffs et bloque les messages entre addons.",
		},
		improved = {
			"Partager mes recharges est éteint au départ : à vous de l'allumer (chapitre Profils et partage). Il s'éteint une fois pour ceux qui l'avaient eu allumé d'office depuis la 1.42.1.",
			"Plus de profil « Arène » ni de mention de l'arène : WoW Forever n'a pas d'arène JcJ. Les profils automatiques gardent la taille du groupe et le champ de bataille.",
			"Aides de la synchronisation, de « Qui relève qui » et de la répartition : le jeu bloque les messages entre addons pendant un combat de boss ou un match JcJ.",
		},
		fixed = {
		},
	},
	{
		version = "1.43.1", date = "2026-11-23",
		added = {
			"Affaiblissements affichés : nouveau choix « Utiles », ceux que le jeu montre sur ses propres cadres de raid, sans ceux de plus de 5 minutes (Déserteur, Épuisement), même en combat.",
			"Liste « À mettre en avant » : Maj-clic sur un sort pour l'ajouter avec son numéro ; un nom en gris n'est pas encore reconnu en combat (survolez-le).",
		},
		improved = {
			"Les affaiblissements de votre liste « À mettre en avant » sont toujours montrés en tête de la rangée (deux au plus), quel que soit le mode, même s'ils sont aussi dans « À ignorer ».",
		},
		fixed = {
		},
	},
	{
		version = "1.43.0", date = "2026-11-23",
		added = {
			"Secondes restantes sur les affaiblissements, le contrôle subi et la grande icône des affaiblissements importants, écrites par le jeu, même en combat (chapitre Affaiblissements, allumé au départ).",
			"Paladin : Longanimité grisée au bout de vos soins, comme Âme affaiblie pour le prêtre ; toutes deux avec leurs secondes restantes.",
			"Icône du type à dissiper (goutte de magie, crâne de malédiction...) posée par le jeu sur la case, même en combat, nouvel élément du placement ; le liseré de chaque icône d'affaiblissement prend la couleur de son type.",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.42.1", date = "2026-11-23",
		added = {
			"Recharges du groupe : sous vos recharges, une ligne par gros sort de vos alliés qui ont Lyorune (Renaissance, Innervation, Infusion de puissance, Imposition des mains, Bénédictions de protection et de sacrifice, Gardien de peur, Totem de vague de mana, Tranquillité...) : le nom de chacun à la couleur de sa classe, net quand le sort est prêt, avec ses secondes sinon. Pendant un combat de boss ou un match JcJ, le jeu bloque les messages : la ligne garde le dernier état connu et se met à jour à la fin (chapitre Mes soins, éteint au départ).",
			"Partager mes recharges : vos gros sorts sont annoncés au groupe quand vous les lancez et quand ils sont prêts, sans aucun message régulier (chapitre Profils et partage, allumé au départ).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.42.0", date = "2026-11-23",
		added = {
			"Mes recharges : une rangée d'icônes sous les cadres (sous les buffs manquants s'ils sont là) avec vos sorts de raccourcis dont la recharge dépasse la recharge globale et vos gros sorts (Pénitence, Innervation, Imposition des mains, Rapidité de la nature...). Le jeu y dessine le balayage et les secondes, même en combat ; grisée en recharge, nette quand le sort est prêt. Tous vos sorts ou seulement ceux en recharge, et une liste des sorts à ne pas montrer (chapitre Mes soins, éteint au départ).",
			"Trait de canalisation : quand vous canalisez un soin sur un joueur (Pénitence), un trait se vide en haut de sa case au rythme de la canalisation, même en combat (jamais pour un soin sans cible comme Tranquillité).",
		},
		improved = {
			"Infobulle « Mes clics » : hors combat, un sort en recharge s'écrit en rouge avec ses secondes.",
		},
		fixed = {
		},
	},
	{
		version = "1.41.1", date = "2026-11-23",
		added = {
		},
		improved = {
			"Placement des éléments : la place d'un élément masqué profite aux autres (sans icône de rôle, vos soins sur la durée vont jusqu'au bord et le nom commence tout à gauche ; sans buff manquant, les affaiblissements aussi ; en Barre et Bandeau, une rangée seule prend toute la hauteur de la barre de vie) et revient quand il est recoché. Taille de 50 à 300 %, bouton « Remplir la place » (la plus grande taille qui tient), et un message qui nomme le voisin qui bloque.",
		},
		fixed = {
		},
	},
	{
		version = "1.41.0", date = "2026-11-23",
		added = {
			"Placement des éléments : une case à cocher devant chaque élément l'affiche ou le masque sur vos cases, avec le même réglage que dans les options. Un élément masqué reste sur la case d'exemple, en transparence, et retrouve sa place et sa taille quand il revient. Bouton « Tout afficher », et « Aussi sur la case » pour la barre de mana, le bouclier, les soins en route, la vie basse, la menace et la dissipation.",
			"Deux nouveaux interrupteurs, chapitre Joueurs : « Nom du joueur » et « Icône au centre de la case » (appel, résurrection, hors de vue, invocation, joueur très loin).",
		},
		improved = {
		},
		fixed = {
			"Placement des éléments : la case d'exemple remplit toute la zone à droite de la liste, avec un contour d'un pixel autour de l'élément choisi.",
		},
	},
	{
		version = "1.40.1", date = "2026-11-22",
		added = {
		},
		improved = {
		},
		fixed = {
			"Buffs manquants sous les cadres : le bandeau fait exactement la largeur d'une case, en Tuile et en Carré aussi, et suit vos changements de taille et d'échelle. Case trop étroite pour le texte (Carré) : l'icône seule, avec « +N » dans son coin ; le joueur et le sort restent dans l'infobulle.",
		},
	},
	{
		version = "1.40.0", date = "2026-11-22",
		added = {
			"Chiffre du bouclier : ce qui reste à absorber (« +1,2k »), tous boucliers comptés, même en combat ; il s'efface quand le dernier bouclier est cassé ou fini (chapitre Vie et portée, éteint au départ).",
			"Boucliers suivis sur les cases : Égide divine pour le prêtre, Veille de la Lumière et Serment de lumière pour le paladin.",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.39.1", date = "2026-11-22",
		added = {
			"Variante « Sur un tank » : le « + » d'une ligne donne au même clic un autre sort ou un autre rang sur un tank (par exemple le rang le plus haut sur lui, un rang économe sur les autres). Toujours juste dans le cadre « Tanks » et les cadres par rôle, même en combat ; ailleurs, posée hors combat selon le rôle de chacun et reposée à la fin du combat.",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.39.0", date = "2026-11-22",
		added = {
			"Variantes d'un raccourci : le « + » au bout d'une ligne (chapitre Sorts et raccourcis) lui donne un autre sort sur un ennemi (case Cible, Focalisation, allié sous Contrôle mental), en champ de bataille et en arène, ou hors combat. Chaque variante est une sous-ligne, réglable et retirable ; elles suivent le raccourci, l'infobulle « Mes clics » et les codes de partage.",
			"Aucun soin sur un ennemi (partie Comportement, coché au départ) : un raccourci sans variante « Sur un ennemi » ne fait rien sur un ennemi, au lieu d'envoyer votre soin. Cibler, Menu du joueur et Arrêter l'incantation marchent partout.",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.38.1", date = "2026-11-22",
		added = {
		},
		improved = {
			"Choix du rang activable : « Choisir le rang des sorts » (chapitre Sorts et raccourcis, éteint au départ). Éteint, tous vos raccourcis lancent le rang le plus haut ; les rangs déjà choisis sont gardés et reviennent si vous le rallumez.",
			"Rang adapté au niveau du joueur soigné : un rang choisi trop fort pour un joueur de bas niveau est remplacé, sur sa case, par le meilleur de vos rangs qu'il peut recevoir, jamais plus fort que celui choisi (réglage fin, allumé au départ). Calculé hors combat.",
		},
		fixed = {
		},
	},
	{
		version = "1.38.0", date = "2026-11-22",
		added = {
			"Rang choisi sur chaque raccourci : dans la fenêtre de choix, un petit chiffre signale un sort à plusieurs rangs ; clic, le rang le plus haut (il suit vos nouveaux rangs) ; clic droit, la liste de ses rangs avec le niveau d'apprentissage, le coût en mana et la bulle du jeu. La ligne dit le rang (« Soins supérieurs, rang 1 »).",
		},
		improved = {
			"Un rang glissé depuis le grimoire reste ce rang ; le rang le plus haut devient « le plus haut ». Les macros « Lyo: » des barres et les codes de partage gardent le rang ; un rang inconnu de ce personnage est écrit en orange et lance le rang le plus haut.",
		},
		fixed = {
		},
	},
	{
		version = "1.37.1", date = "2026-11-22",
		added = {
		},
		improved = {
			"Buffs manquants sous les cadres : un bandeau fin, le même pour toutes les formes de cases, de la largeur d'une case (jamais trop étroit) : l'icône, puis le joueur (« Vous », un nom, « Groupe 3 ») et, dessous, « +N autres » ou le nom court du sort. Sa hauteur suit la taille du texte ; le nom complet est dans l'infobulle.",
			"Buffs dessinés par le jeu sur les cases : deux interrupteurs, « En combat » et « En champ de bataille et en arène » (tous deux allumés, comme avant). Rien n'apparaît sur un joueur qu'aucun de vos buffs ne concerne.",
		},
		fixed = {
		},
	},
	{
		version = "1.37.0", date = "2026-11-22",
		added = {
			"Qui buffe qui : vos groupes de raid à buffer (Mes buffs), avec un bouton « Comme mes soins ».",
			"Paladin : grille « Bénédiction par joueur », une bénédiction par type de joueur (tanks, soigneurs, chaque classe), ou aucune.",
			"Plusieurs paladins : une bénédiction déjà posée par un autre paladin n'est jamais reprise, la suivante est proposée ; entente entre les paladins qui ont Lyorune, annoncée avant le combat.",
			"Répartir les buffs : le chef ou un assistant envoie à chacun ses groupes et la bénédiction qu'il pose en premier (/lyorune repartir buffs). /lyorune buffs dit qui buffe qui.",
		},
		improved = {
		},
		fixed = {
			"Les textes ne parlent plus de clé mythique : il n'y en a pas sur WoW Forever.",
		},
	},
	{
		version = "1.36.0", date = "2026-11-22",
		added = {
			"Buffs en combat : là où le jeu cache les buffs (combat, champ de bataille, arène), il dessine vos buffs en bas à gauche des cases, en couleur s'ils sont posés, gris à bord rouge s'ils manquent (tous les rangs, même posés par un autre joueur).",
			"En combat, la touche « Poser le prochain buff manquant » relance votre buff unique (Bouclier de terre, Gardien de peur...) sur son porteur, par son nom.",
		},
		improved = {
			"Mes buffs : la description explique les buffs cachés par le jeu en champ de bataille et en arène.",
		},
		fixed = {
		},
	},
	{
		version = "1.35.0", date = "2026-11-22",
		added = {
			"/lyorune buffs : pour chacun de vos buffs, lisible ici ou caché par le jeu, et la durée connue. Un message au début du match et une ligne dans l'infobulle disent ce que Lyorune sait.",
		},
		improved = {
		},
		fixed = {
			"Buffs manquants en champ de bataille et en arène : le jeu y cache les buffs, même hors combat, et le panneau restait vide. Lyorune lit les buffs que le jeu laisse lisibles, note ceux de chacun juste avant le match, retient les buffs que vous lancez pendant leur durée et les oublie à la mort (au cimetière, ils sont proposés de nouveau).",
		},
	},
	{
		version = "1.34.1", date = "2026-11-22",
		added = {
			"/lyorune sorts : les sorts proposés, ceux de votre classe qui manquent et pourquoi (pas appris, autre spécialisation, passif), et ceux qui sont écartés.",
		},
		improved = {
			"Sorts et raccourcis propose tous vos soins et buffs, même sans cible : Feu intérieur, boucliers et armes du chaman, auras et Fureur vertueuse du paladin, Nova sacrée, Prière de soins, Tranquillité, totems de soins. Jamais un sort offensif. Même liste dans Mes macros.",
			"Buffs manquants sous les cadres : une seule case, comme une touche, qui passe au buff suivant après chaque sort (plus de cases en dessous) ; « + N » dans son coin dit combien il en reste ; icône deux fois plus petite.",
		},
		fixed = {
		},
	},
	{
		version = "1.34.0", date = "2026-11-22",
		added = {
			"Buffs manquants collés sous vos cadres, à la forme de vos cases (Barre, Tuile, Carré, Bandeau), avec leur taille, leur thème, leur texture et leurs angles : le premier est celui que lance votre touche, puis jusqu'à 3 suivants cliquables. Ils suivent vos cadres, passent au-dessus s'ils sont trop bas, disparaissent en combat et quand tout est posé. Réglage « Emplacement des buffs manquants » : avec les cadres, ou où vous voulez (l'ancienne fenêtre).",
			"Options ouvertes sur le chapitre Joueurs et rien à poser : une case d'exemple montre où apparaîtront vos buffs manquants.",
		},
		improved = {
			"Un buff que vous venez de lancer n'est plus proposé pendant quelques secondes, le temps que le jeu le pose : la touche ne le relance pas sur le même joueur.",
		},
		fixed = {
			"Un joueur hors de portée de votre sort ou hors de vue passe en fin de liste (la portée habituelle est cachée aux addons sur WoW Forever), et un joueur déjà en combat, dont le jeu cache les buffs, n'est plus proposé à tort.",
		},
	},
	{
		version = "1.33.7", date = "2026-11-22",
		added = {
		},
		improved = {
			"Mes buffs : la version simple et la version de groupe se cochent séparément. Seulement la version de groupe : des lignes « Groupe N » dès qu'un joueur du groupe n'a pas le buff ; seulement la version simple : un joueur à la fois, jamais de Prière. Toutes les lignes sont alignées, la version de groupe porte la mention « (groupe) ».",
			"Un buff est proposé à nouveau 2 minutes avant sa fin (réglage « Proposer à nouveau sous », qui passe de 0 à 2 pour ceux qui ne l'avaient pas changé), jamais avant le dernier quart d'un buff court.",
		},
		fixed = {
			"Sans son composant, la version de groupe n'est plus proposée : le panneau propose la version simple.",
			"Un buff à une personne (Épines, Bouclier de terre, Gardien de peur, Serment de lumière) n'est plus proposé à un joueur mort ou déconnecté : il va au suivant (tank, sinon vous), et revient quand le joueur est relevé.",
			"Seul avec « Mon cadre quand je suis seul » décoché, le panneau des buffs manquants vous propose de nouveau vos propres buffs (il ne voyait plus votre case).",
		},
	},
	{
		version = "1.33.6", date = "2026-11-22",
		added = {
		},
		improved = {
			"Mes buffs : la version de groupe de chaque buff (Prière de robustesse, Prière d'Esprit, Prière de protection contre l'Ombre, Don du fauve, Illumination des arcanes) a sa propre ligne, en retrait sous le buff, avec ses cases JcE et JcJ. Décochée, le panneau ne propose que la version simple, joueur par joueur, sans dépenser de composant. Tout reste coché au départ.",
		},
		fixed = {
		},
	},
	{
		version = "1.33.5", date = "2026-11-22",
		added = {
		},
		improved = {
		},
		fixed = {
			"Prêtre : Forme d'ombre n'est plus proposée dans vos buffs. C'est un sort de prêtre Ombre (dégâts), et on ne peut plus soigner sous cette forme : un addon de soin n'a pas à la proposer.",
		},
	},
	{
		version = "1.33.4", date = "2026-11-22",
		added = {
			"Prêtre : Forme d'ombre rejoint vos buffs sur vous (prêtre Ombre), comme dans HealBot.",
			"Paladin : votre aura (Dévotion, Concentration, Châtiment, Sainteté, résistances) rejoint vos buffs sur vous, la dernière que vous avez lancée. Druide : Augure de clarté aussi, s'il se lance sur ce client (un sort passif n'est jamais proposé).",
		},
		improved = {
			"Buffs à une personne (Bouclier de terre, Épines, Gardien de peur, Serment de lumière) : choisissez leur porteur dans « Mes buffs », chacun le sien, sur la ligne « Sur : » sous le buff : Tank (au départ), Moi, ou Un joueur (son nom, ou le bouton « Ma cible »). Le panneau dit à qui il va ; joueur choisi absent : le tank, sans tank : vous. /lyorune porteur reste comme raccourci pour tous à la fois.",
			"Mes buffs : la version de groupe de chaque buff est écrite sur sa ligne (Mot de pouvoir : Robustesse + Prière de robustesse, Esprit divin + Prière d'Esprit, Protection contre l'Ombre + Prière de protection contre l'Ombre) : un seul réglage pour les deux.",
		},
		fixed = {
		},
	},
	{
		version = "1.33.3", date = "2026-11-22",
		added = {
		},
		improved = {
			"Mes buffs : tous les buffs sont actifs au départ, en JcE comme en JcJ (Protection contre l'Ombre, Fureur vertueuse et Gardien de peur compris). Décochez ce qui ne vous sert pas ; vos choix déjà faits restent les vôtres.",
		},
		fixed = {
		},
	},
	{
		version = "1.33.2", date = "2026-11-22",
		added = {
		},
		improved = {
		},
		fixed = {
			"Mes buffs (options, chapitre Joueurs), panneau et cases : chaque buff montre l'icône de votre grimoire, celle que le jeu donne au sort que vous connaissez, pour le prêtre, le paladin, le chaman et le druide. Les sorts de race d'une autre race (Toucher de faiblesse, Garde de l'ombre) ne sont plus proposés à un prêtre qui ne les a pas.",
		},
	},
	{
		version = "1.33.1", date = "2026-11-22",
		added = {
		},
		improved = {
			"Le réglage « Sort de groupe dès (joueurs sans le buff) » (anciennement « Version de groupe dès ») est expliqué par un exemple sous son nom.",
		},
		fixed = {
			"Options, chapitre Joueurs, « Mes buffs » : les cases JcE et JcJ sont alignées sur les interrupteurs du dessus, et chaque titre de colonne est centré sur ses cases, dans les trois thèmes.",
		},
	},
	{
		version = "1.33.0", date = "2026-11-22",
		added = {
			"Buffs complets des soigneurs : prêtre (Robustesse, Esprit divin pour les joueurs à mana, Protection contre l'Ombre, Feu intérieur et sorts de race sur vous), paladin (une bénédiction de vous par joueur : Rois pour le tank et le chasseur, Sagesse pour les joueurs à mana, Puissance pour les autres ; Fureur vertueuse au choix), chaman (Bouclier d'eau ou de foudre, enchantement de votre arme), druide (Marque du fauve). Gardien de peur et Serment de lumière rejoignent les buffs à poser sur une seule personne.",
			"Mes buffs (chapitre Joueurs) : choisissez les buffs à surveiller, une liste pour les donjons, raids et le monde (JcE), une autre pour les champs de bataille et l'arène (JcJ). Au départ, Protection contre l'Ombre ne compte qu'en JcJ ; Fureur vertueuse et Gardien de peur sont éteints.",
		},
		improved = {
			"Le panneau des buffs manquants montre tous les buffs qui manquent à chaque joueur, une ligne par buff, et plus seulement le premier. Nouveaux réglages : proposer à nouveau un buff qui finit dans moins de N minutes (pratique avant un boss), et le nombre de joueurs à partir duquel la version de groupe est proposée.",
		},
		fixed = {
		},
	},
	{
		version = "1.32.1", date = "2026-11-22",
		added = {
		},
		improved = {
		},
		fixed = {
			"Affaiblissements : ceux qu'aucun joueur ne peut retirer (souvent de type Magie chez un boss) n'apparaissaient nulle part chez un soigneur qui dissipe ce type ; et un affaiblissement qu'un autre joueur du raid pouvait retirer colorait votre case et sonnait comme si vous pouviez le dissiper. La rangée « à dissiper », le cadre coloré et le son ne montrent plus que ce que vous pouvez dissiper vous-même ; tous les autres affaiblissements vont dans la rangée suivante, sans trou ni doublon. Pour les quatre classes de soigneurs.",
			"Le voile rouge de vie basse ne clignote plus sans fin : il bat quelques secondes quand la vie change, puis reste fixe. Il ne couvre plus la case d'un joueur que le jeu ne connaît pas encore (vie maximale à 0, en chargement de champ de bataille).",
		},
	},
	{
		version = "1.32.0", date = "2026-11-21",
		added = {
			"Répartition entre soigneurs (chapitre Joueurs, partie Mes joueurs) : vos groupes de raid et vos joueurs choisis (un tank, /lyorune pourmoi) portent un trait doré au bord gauche de leur case ; au choix, les autres s'estompent un peu. Marche même si vous êtes seul à avoir Lyorune.",
			"Le chef ou un assistant envoie qui soigne quoi à tous les soigneurs qui ont Lyorune (« Répartir les soigneurs... », /lyorune repartir), avant le combat : leurs repères suivent tout de suite, et le soigneur prévu s'affiche au survol d'une case. Pendant un combat de boss, le jeu bloque ces messages : l'envoi est refusé avec un message clair.",
		},
		improved = {
			"Guide du joueur et visite guidée : la répartition entre soigneurs.",
		},
		fixed = {
			"Un message entre joueurs freiné par le jeu passait pour envoyé : Lyorune lit maintenant la réponse du jeu.",
		},
	},
	{
		version = "1.31.0", date = "2026-11-21",
		added = {
			"Joueurs en bonne santé estompés (chapitre Vie et portée, éteint au départ) : au-dessus d'un seuil réglable (90 % au départ), leur vie, leur mana et leur nom pâlissent, ceux qui ont besoin de soins ressortent. Icônes, dissipation et menace restent nettes, la case survolée aussi.",
			"Compter mes clics (chapitre Sorts et raccourcis, éteint au départ) : à côté de chaque ligne, combien de fois vous l'avez utilisée, par personnage et par spécialisation ; une ligne jamais utilisée est grisée, un bouton remet les comptes à zéro.",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.30.0", date = "2026-11-21",
		added = {
			"Animation du logo au choix (chapitre Fenêtre et aide) : Aurore, Sceau ou Souffle, aux couleurs des classes de soin, ou Aucune. Le cercle de runes qui tournait disparaît.",
		},
		improved = {
			"Règle des 5 secondes : éteinte au départ, à allumer dans la partie Mana ; son trait se pose juste au-dessus de la barre de mana, sans la cacher.",
		},
		fixed = {
			"Règle des 5 secondes : la pêche et les sorts dont le jeu ne donne pas le coût ne lancent plus le trait.",
		},
	},
	{
		version = "1.29.0", date = "2026-11-21",
		added = {
			"Jusqu'à 3 affaiblissements à dissiper par case, le plus important d'abord (chapitre Affaiblissements, 2 au départ).",
			"Vos sorts externes sur la case (Infusion de puissance, Innervation), et Âme affaiblie en gris à la dernière place de vos soins (chapitre Mes soins).",
			"Soigneur qui boit : l'icône de sa boisson à côté de sa mana basse, avec le temps qui reste (partie Mana).",
			"Liseré bleu doux au bord de l'écran quand votre mana baisse (sous 20 % au départ, réglable ou coupé, partie Mana).",
			"Règle des 5 secondes : après un sort payé en mana, un trait fin sur votre case se vide jusqu'au retour de la régénération.",
		},
		improved = {
			"Guide du joueur et visite guidée : ces nouveautés.",
		},
		fixed = {
		},
	},
	{
		version = "1.28.0", date = "2026-11-21",
		added = {
			"Gros défensifs des joueurs sur leur case (chapitre Joueurs, partie Sur la case) : Mur protecteur, Bouclier divin, Bénédiction de protection, Écorce, Évasion, Bloc de glace..., posés par n'importe qui, avec un liseré bleu, visibles en combat, deux au plus.",
			"Joueurs étourdis, apeurés ou métamorphosés : l'icône du contrôle au centre de leur case, avec un liseré rouge, reconnue par le jeu même en combat (chapitre Affaiblissements, partie Importants).",
			"Raccourcis du jeu (Échap, Options, Raccourcis, AddOns, Lyorune) : ouvrir les options, afficher ou masquer les cadres, poser le prochain buff manquant, mode test. Aucune touche au départ. Aussi /lyorune cadres pour afficher ou masquer les cadres.",
		},
		improved = {
			"Les deux nouvelles icônes se placent et se dimensionnent dans « Placer les éléments de la case... », et se voient sur la case témoin et dans le mode test.",
			"Guide du joueur et visite guidée : les nouvelles icônes, les raccourcis du jeu, et le rang des sorts sur un joueur de bas niveau (le jeu choisit déjà le bon).",
		},
		fixed = {
		},
	},
	{
		version = "1.27.1", date = "2026-11-21",
		added = {
		},
		improved = {
		},
		fixed = {
			"Changer un réglage en combat ne provoque plus d'action refusée par le jeu : le sens des clics (dès l'appui ou au relâchement) attend la fin du combat.",
			"Les touches au survol lancent leur sort même quand « Lancer le sort dès l'appui » et le réglage « lancer à l'appui » du jeu ne vont pas dans le même sens.",
		},
	},
	{
		version = "1.27.0", date = "2026-11-21",
		added = {
			"Taille de chaque icône dans « Placer les éléments de la case... » (chapitre Disposition) : « - » et « + » sous les flèches, ou la molette sur l'icône, de 50 à 200 % de sa taille d'origine, gardée pour chaque forme de case avec sa place et transmise par le partage de configuration. Une taille changée en combat s'applique dès la fin du combat.",
		},
		improved = {
			"Icônes à la mesure de chaque forme de case : en Tuile et en Carré, vos soins sur la durée en haut à gauche et les affaiblissements en bas à droite, à une taille tirée de la case (en Carré, une rangée trop longue passe à la ligne) ; en Barre, collés aux bords haut et bas de la barre de vie, côté droit, sans couvrir le nom ; en Bandeau, en bloc au bout de la case, le chiffre de vie rangé à leur gauche. Une rangée trop large rapetisse au lieu de sortir de la case. Les décalages de ces icônes (et du chiffre de vie en Bandeau) repartent une fois de zéro en Barre, Bandeau et Carré.",
			"Visite guidée et guide du joueur : la place des icônes selon la forme de case, et où régler leur taille.",
		},
		fixed = {
			"Décompte en secondes des soins : les chiffres sont écrits à la taille de l'icône et ne débordent plus sur la voisine (ils se chevauchaient en Bandeau).",
		},
	},
	{
		version = "1.26.0", date = "2026-11-20",
		added = {
			"Nouvelle fenêtre d'options, entièrement repensée et modernisée : onze chapitres rangés par tâche dans une barre latérale (Accueil, Disposition, Apparence, Vie et portée, Mes soins, Affaiblissements, Joueurs, Sorts et raccourcis, Alertes, Profils et partage, Fenêtre et aide), une page qui défile et se range par parties, et les réglages plus rares pliés sous « Réglages fins » pour garder l'essentiel sous les yeux.",
			"Case témoin à droite de la fenêtre : une fausse case agrandie montre chaque réglage en direct, sans fermer la fenêtre, avec un faux groupe de cinq dessous et les boutons du mode test (5, 10, 25, 40).",
			"Rune d'or à côté de chaque réglage que vous avez changé : son survol dit en mots la valeur d'installation, un clic la reprend. Dans la barre latérale, une pastille compte vos propres choix dans chaque chapitre.",
			"« Rétablir cette page » au bas de chaque chapitre, en deux clics : seule la page ouverte revient aux valeurs d'installation, vos listes, vos clics et vos profils restent tels quels.",
			"Au bas de la fenêtre, « Annuler mes changements » remet tout comme à l'ouverture de la fenêtre, en deux clics : réglages, clics, listes, textes d'annonce, joueurs épinglés et macros (une macro renommée ou supprimée retrouve son clic). « Enregistrer mes réglages » les garde sous un nom de profil.",
			"Accueil : votre profil actif, la liste de vos réglages changés, le tutoriel, l'assistant de départ et les nouveautés. La fenêtre s'ouvre sur l'Accueil à chaque connexion, puis sur le dernier chapitre utilisé.",
			"Effets magiques dans la fenêtre : une lumière de soin or et vert traverse l'en-tête, un cercle runique brille derrière le logo, la rune du chapitre ouvert s'allume et la case témoin s'illumine à chaque réglage changé. Jamais sur vos vraies cases de soin ; « Animations réduites » les coupe.",
			"Vos macros de Lyorune vont dans vos barres de sorts : glissez une macro de « Mes macros » sur une barre du jeu, hors combat. Lyorune en crée une copie « Lyo:Nom » dans /macro (onglet de votre personnage) qui soigne le joueur survolé, sinon votre cible ; elle suit chaque changement de texte ou de nom et part avec la macro. L'option « Créer une macro par sort de mes clics » vise de la même façon.",
		},
		improved = {
			"Recherche dans les noms des réglages et dans leurs explications, avec ou sans accents (« echelle » trouve « Échelle ») ; un clic sur un résultat ouvre le bon chapitre et fait clignoter le réglage. « Mode test » fait clignoter les boutons du mode test sous la case témoin, sans changer de chapitre.",
			"Réglages plus simples à manier : interrupteurs, choix côte à côte, nombres réglables au clavier ou à la molette (après un clic sur la valeur, ou avec Maj) ; la molette fait défiler la page sans changer un réglage au passage. Un réglage est grisé quand celui dont il dépend est coupé, et reste réglable.",
			"Fenêtres plus reposantes pour les yeux : gris très foncé au lieu du noir, texte blanc cassé, barre latérale d'un ton à part ; le contraste élevé reste très lisible sans noir ni blanc purs, et grise Thème et Texture des barres qu'il remplace (vos cases de soin ne changent pas).",
			"Les fenêtres s'adaptent à votre écran : une fenêtre trop grande est réduite pour tenir entière, une seule fenêtre s'ouvre à la fois à côté des options et ne les recouvre jamais (les options glissent sur le côté, ou s'effacent puis reviennent sur le même chapitre, au même endroit de la page).",
			"Le chapitre des clics s'appelle « Sorts et raccourcis » ; toutes ses lignes sont visibles, et ses boutons de bijou sont plus lisibles (icône d'emplacement du jeu, puis bordure d'or et icône de votre bijou) et n'apparaissent que si « Bijoux avec les sorts » est allumé.",
			"Guide du joueur et visite guidée refaits pour la nouvelle fenêtre, en français et en anglais : quatre cartes courtes la présentent zone par zone. Les cartes se posent à côté de vos cadres, jamais dessus ; lancée des options, la visite vous rend la fenêtre sur l'Accueil ; Échap l'arrête comme la croix ; vos cadres cachés sont remplacés le temps des cartes par le faux groupe du mode test ; ouvrir une autre fenêtre l'arrête proprement.",
			"Mes macros plus sûre et plus lisible : la macro ouverte est marquée dans chaque thème, la zone d'écriture défile, chaque zone garde sa place (texte entier en infobulle), « Enregistrer » affiche « Enregistrée », et l'assistant, l'import et le choix d'un sort s'ouvrent entiers par-dessus ; Échap ne ferme que la fenêtre du dessus.",
			"Mes macros : un sort écrit avec d'autres accents que dans votre grimoire est signalé avec sa bonne écriture, et « Corriger l'écriture » la reprend.",
			"Gestes sans retour à confirmer d'un second clic : supprimer une macro, « Tout remettre » du placement, « Vider le journal », « Reprendre les clics proposés pour ma classe ».",
			"Les fausses cases du mode test montrent les coins choisis ; mesure des performances avec les nombres à virgule en français et des textes qui ne se chevauchent plus.",
		},
		fixed = {
			"Barre de mana bleue sous un guerrier, un voleur, un chasseur ou un druide en ours ou en félin : chaque joueur montre maintenant sa propre ressource aux couleurs du jeu (rage, énergie, focalisation), la barre change avec la forme du druide et elle est relue à la sortie du combat ; la teinte que vous choisissez s'applique à la mana. Mode test et case témoin compris.",
			"Annonce de mana remontée quand le jeu cache votre mana : avec un seuil bas, elle tardait ou ne partait jamais. Lyorune estime maintenant votre mana avec la régénération que le jeu donne hors combat, boisson comprise, et annonce dès que l'estimation atteint votre seuil, jamais trop tôt.",
			"Macros de plus de 255 caractères acceptées alors que le jeu ne les lance pas : la limite est maintenant de 255, un compteur l'affiche, une macro trop longue est signalée en rouge, et les bijoux ne sont plus ajoutés à un clic qui dépasserait.",
			"Placement des éléments : un élément poussé loin (nom, vie, icônes, marqueurs) pouvait sortir de la case, à l'écran comme dans l'exemple. Chaque décalage s'arrête maintenant au bord, selon la forme et la taille de vos cases : « Au bord de la case » s'affiche, le nom et le texte de vie rétrécissent près du bord, la couronne du chef reste dans la case, et un décalage ramené au bord retrouve sa place si vous agrandissez les cases.",
			"« /lyorune mesure » : erreur Lua (« iconSize ») et aucune mesure quand le mode test n'avait pas encore été ouvert dans la partie.",
			"Visite guidée : le verrou des cadres choisi avant la visite pouvait être perdu après un /reload ; les couleurs du bouclier et des soins en route citées par la visite sont maintenant celles de votre thème.",
			"Rapport de bug : un nom de joueur court abîmait le texte du rapport (il n'est plus remplacé que comme mot entier), et rappeler la fenêtre effaçait vos réponses. Journal des erreurs : titre traduit en anglais. Inscription runique coupée puis rallumée : elle reparaît sans /reload.",
			"Texture des barres : le clic s'arrêtait sur une texture en double quand d'autres textures étaient installées, il les parcourt maintenant toutes. Mes macros : un nom refusé (vide, trop long ou déjà pris) restait affiché dans le champ.",
		},
	},
	{
		version = "1.25.1", date = "2026-11-20",
		added = {
		},
		improved = {
			"Mode test : un bouton Fermer au bout du bandeau, plus besoin de commande.",
			"Mode test : le bandeau se déplace à la souris et emmène les vrais cadres avec lui (sauf si les cadres sont verrouillés).",
		},
		fixed = {
			"Cases entièrement colorées (bleu, violet ou vert) quand un joueur avait un affaiblissement à dissiper : la vie reste visible sous un voile léger.",
			"Mode test : couleurs de classe teintées de rouge.",
		},
	},
	{
		version = "1.25.0", date = "2026-11-19",
		added = {
			"Mana basse des soigneurs : une icône de boisson sur la case d'un soigneur à court de mana, même en combat (onglet Indicateurs).",
			"Bouclier au choix en bande ou à la suite de la vie, avec un trait lumineux quand il dépasse la vie manquante (onglet Apparence).",
		},
		improved = {
			"Nombre d'icônes au choix : de 1 à 6 soins, de 2 à 5 affaiblissements.",
			"Tous les rangs de vos soins sont reconnus en combat, même un rang inférieur lancé par macro.",
		},
		fixed = {
			"Icônes de soins et d'affaiblissements de nouveau affichées, en combat comme hors combat, quelle que soit la taille du groupe.",
			"Le nom et la vie restent lisibles devant les icônes d'auras ; la grande icône d'affaiblissement suit de nouveau son placement.",
		},
	},
	{
		version = "1.24.0", date = "2026-11-18",
		added = {
			"Annonce de mana remontée même quand le jeu cache votre mana (WoW Forever) : pendant que vous buvez, Lyorune note le moment où chacun de vos sorts redevient utilisable, en tire la vitesse de remontée et annonce quand votre mana atteint le seuil choisi.",
		},
		improved = {
			"Textes de l'interface relus en français et en anglais : vouvoiement partout, phrases plus claires, mêmes mots d'un écran à l'autre.",
		},
		fixed = {
		},
	},
	{
		version = "1.23.13", date = "2026-11-18",
		added = {
			"Annonce et son de mana faible même quand le jeu cache votre mana (WoW Forever) : Lyorune prend dans votre grimoire le sort qui coûte à peu près votre seuil, et l'annonce part quand ce sort manque de mana, en combat aussi. Seuil approché ; l'onglet Alertes indique le sort choisi.",
		},
		improved = {
			"Un sort refusé en combat faute de mana déclenche aussi l'annonce de mana faible.",
			"Option « Masquer les cadres de groupe du jeu » retirée : Lyorune ne touche jamais aux cadres du jeu.",
		},
		fixed = {
		},
	},
	{
		version = "1.23.12", date = "2026-11-18",
		added = {
		},
		improved = {
			"Hauteur de la barre de mana réglable de 2 à 60 pixels (10 au plus auparavant) ; la barre de vie garde toujours au moins 10 pixels de la case.",
		},
		fixed = {
		},
	},
	{
		version = "1.23.11", date = "2026-11-18",
		added = {
		},
		improved = {
			"Profil prêt à l'emploi « Compact » : vos soins sur la durée restent en icônes (les barres fines ne s'affichent que si vous les choisissez).",
		},
		fixed = {
		},
	},
	{
		version = "1.23.10", date = "2026-11-18",
		added = {
		},
		improved = {
			"Journal d'erreurs plus précis : la pile d'appels est prise au moment de l'erreur, et chaque entrée dit où vous étiez (extérieur, donjon, raid...) et si le jeu cachait les auras.",
			"Le rapport de /lyorune bug indique aussi le lieu (extérieur, donjon, raid...).",
		},
		fixed = {
		},
	},
	{
		version = "1.23.9", date = "2026-11-18",
		added = {
		},
		improved = {
			"Journal d'erreurs plus complet : chaque événement des cases et chaque mise à jour régulière est surveillé par Lyorune lui-même, sans dépendre d'aucun autre addon.",
		},
		fixed = {
			"En donjon, vos soins sur la durée, les affaiblissements et la dissipation s'affichent de nouveau sur les cases : le jeu y rend secret le détail des changements d'auras, ce qui provoquait des centaines d'erreurs.",
			"Annonces de mana et de résurrection dans un groupe trouvé par l'outil de recherche : envoyées sur le canal d'instance (elles étaient refusées).",
		},
	},
	{
		version = "1.23.8", date = "2026-11-17",
		added = {
		},
		improved = {
		},
		fixed = {
			"Mesure des performances : le marqueur de raid et la coche « Prêt ? » de votre personnage ne restent plus sur les cases du mode test (#46).",
			"Assistant de départ : « Passer » ou la croix rendent la forme des cases d'avant (#46).",
			"Visite guidée : les cadres verrouillés le redeviennent après l'étape « Placer les cadres » (#46).",
		},
	},
	{
		version = "1.23.7", date = "2026-11-17",
		added = {
		},
		improved = {
		},
		fixed = {
			"Coins de la case : la liste suit l'onglet Listes sans /reload, et le sort d'un coin reste affiché même retiré de la liste (#46).",
			"« Reprendre les clics proposés » en 2e spécialisation remplace ses clics, sans effacer ceux de la 1re (#46).",
		},
	},
	{
		version = "1.23.6", date = "2026-11-17",
		added = {
		},
		improved = {
		},
		fixed = {
			"« Qui relève qui » : la liste ne se remplit plus pour toute la session quand des joueurs relevés quittent le groupe (#46).",
		},
	},
	{
		version = "1.23.5", date = "2026-11-17",
		added = {
		},
		improved = {
		},
		fixed = {
			"Barre ou anneau d'incantation : un sort refusé pendant l'incantation (clics répétés) ne les cache plus (#46).",
			"La couronne du chef s'affiche dans le mode test et dans la fenêtre « Placer les éléments de la case ».",
			"Mes macros : effacer le mot avant « : » dans une condition ([:shift]) ne fait plus d'erreur.",
			"Importer de /macro : la fenêtre ne dit plus « aucune macro » quand des macros ont été créées depuis.",
		},
	},
	{
		version = "1.23.4", date = "2026-11-17",
		added = {
		},
		improved = {
		},
		fixed = {
			"« Son quand ma mana est faible » fonctionne aussi quand les annonces de mana sont décochées (#46).",
		},
	},
	{
		version = "1.23.3", date = "2026-11-17",
		added = {
		},
		improved = {
		},
		fixed = {
			"Un appel « Prêt ? » relancé moins de 5 secondes après le précédent garde ses réponses sur les cases.",
			"L'œil « hors de vue » ne reste plus sur une case quand le jeu la donne à un autre joueur.",
		},
	},
	{
		version = "1.23.2", date = "2026-11-17",
		added = {
		},
		improved = {
		},
		fixed = {
			"Fin du combat : si une modification remise à plus tard échoue, les autres (clics, disposition, profil) s'appliquent quand même (#46).",
			"« Vider le journal » : /lyorune bug ne signale plus une erreur déjà effacée (#46).",
		},
	},
	{
		version = "1.23.1", date = "2026-11-17",
		added = {
		},
		improved = {
		},
		fixed = {
			"Mode test à 25 ou 40 joueurs : avec « Réduire les cases en grand raid », les cases rétrécissent comme dans un vrai raid (#46).",
		},
	},
	{
		version = "1.23.0", date = "2026-11-17",
		added = {
			"Copier une partie d'un profil (onglet Profils, bouton « Copier... ») : Cadres, Apparence, Indicateurs ou Soins, au choix, d'un profil vers un autre ; le reste du profil d'arrivée ne bouge pas (#44).",
			"Profils automatiques en champ de bataille et en arène, pour chaque spécialisation ; sans choix, le profil prévu pour la taille du groupe s'applique (#44).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.22.0", date = "2026-11-17",
		added = {
			"Buffs à poser sur une seule personne : tant que votre Bouclier de terre (chaman) ou vos Épines (druide) ne sont sur personne, le panneau des buffs manquants propose une ligne pour le tank, ou pour le joueur choisi avec /lyorune porteur (#43).",
			"Recharge globale et incantation (onglet Soins) : une fine barre sous les cadres, ou un anneau autour du curseur, montre le temps de recharge global et votre incantation en cours, même en combat (#43).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.21.0", date = "2026-11-17",
		added = {
			"Bijou avec le sort : sur chaque ligne de l'onglet Clics, deux petites icônes utilisent votre bijou du haut ou du bas juste avant le sort, sur un joueur vivant (#42).",
			"Arrêter l'incantation : un clic ou une touche peut interrompre le sort en cours (#42).",
			"Clic pris aussi par le jeu : si le « clic pour lancer » du jeu utilise la même combinaison qu'un clic de Lyorune, un message le dit et la ligne passe en orange ; Lyorune ne touche jamais aux raccourcis du jeu (#42).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.20.0", date = "2026-11-17",
		added = {
			"Joueurs épinglés : un petit cadre « Épinglés » pour garder à part un 2e tank ou un joueur à surveiller ; on épingle depuis la case survolée (/lyorune epingler), sa cible ou la liste de l'onglet Listes (#41).",
			"Signal du jeu sur une case : survolez-la et appuyez sur la touche de signal, le joueur est marqué pour tout le groupe (#41).",
			"Couronne du chef de groupe et drapeau des assistants du raid sur les cases, à placer dans l'éditeur de placement (#41).",
		},
		improved = {
			"L'avis de nouvelle version donne l'adresse de la page de cette version, où chaque nouveauté est décrite.",
		},
		fixed = {
		},
	},
	{
		version = "1.19.0", date = "2026-11-17",
		added = {
			"Distance en trois paliers, même en donjon et en raid : à portée de soin, proche (case estompée), très loin (case encore plus estompée, empreintes au centre) (#31).",
			"Soin refusé car le joueur est hors de vue : un œil apparaît 3 secondes au centre de sa case (#31).",
		},
		improved = {
			"/lyorune position vérifie aussi le palier « très loin », en donjon et en combat.",
		},
		fixed = {
		},
	},
	{
		version = "1.18.0", date = "2026-11-17",
		added = {
			"Mode performance pour les grands raids ou un ordinateur modeste : portée vérifiée une fois par seconde, icônes des soins et des affaiblissements regroupées, rien ne disparaît (#30).",
			"Mesure des performances (onglet Aide ou /lyorune mesure) : Lyorune tourne sur un faux groupe de 5, 25 et 40 joueurs et se compare aux autres addons de soin chargés (#30).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.17.0", date = "2026-11-17",
		added = {
			"Qui relève qui : quand un soigneur commence une résurrection, son nom remplace « Mort » sur la case, en vert, chez tous ceux qui ont Lyorune ; deux soigneurs ne relèvent plus le même joueur (#29).",
			"Joueurs du groupe qui ont Lyorune, avec leur version : dans l'onglet Profils (au survol) et avec /lyorune groupe (#29).",
			"Annuler l'import : la configuration d'avant le dernier import revient en un clic (onglet Profils) ou avec /lyorune annuler (#29).",
		},
		improved = {
			"Un interrupteur général « Synchronisation entre joueurs » coupe tous les messages invisibles ; un joueur qui en envoie trop est ignoré un moment (#29).",
		},
		fixed = {
		},
	},
	{
		version = "1.16.0", date = "2026-11-17",
		added = {
			"Panneau des buffs manquants (onglet Soins) : hors combat, une petite fenêtre liste les joueurs sans votre buff de groupe ; un clic le leur lance, sans les cibler, et un groupe entier sans buff n'a qu'une ligne pour la version de groupe (#27).",
			"Assistant de départ : au premier lancement, trois questions (rôle, taille de groupe, forme des cases sur vignettes) règlent Lyorune avant la visite guidée ; à revoir avec /lyorune assistant ou depuis l'onglet Aide (#28).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.15.0", date = "2026-11-17",
		added = {
			"Rangement en grille (onglet Cadres) : tout le raid d'un seul bloc, sans trou entre les groupes, avec le nombre de cases par colonne au choix (#26).",
			"Ordre dans chaque bloc : l'ordre du groupe, par nom, ou par classe puis par nom ; le jeu le tient à jour tout seul, même en combat (#26).",
			"Chaque groupe garde sa place : en rangement par groupe, un groupe reste dans sa colonne même si le précédent est vide (#26).",
		},
		improved = {
			"Le mode test montre la grille et l'ordre choisis (#26).",
		},
		fixed = {
		},
	},
	{
		version = "1.14.0", date = "2026-11-17",
		added = {
			"Mes profils (onglet Profils) : vos réglages d'apparence enregistrés sous un nom, chargés en un clic ; le profil en cours garde tout seul ce que vous y réglez. Clics, macros, listes et annonces n'en font pas partie (#24).",
			"Profils automatiques : un profil pour 5, 10, 25 et 40 joueurs et pour chaque spécialisation, appliqué tout seul sans /reload, à la fin du combat si besoin (#24).",
			"Cases de la cible, de la cible de la cible et de la focalisation, chacune avec son interrupteur (onglet Cadres), dans un petit cadre « Cible » déplaçable, avec vos clics ; un ennemi est en rouge (#25).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.13.0", date = "2026-11-17",
		added = {
			"Onglet Clics : une seule liste pour la souris et le clavier, un raccourci par ligne, sans limite, avec toutes les combinaisons d'Alt, Ctrl et Maj (#20).",
			"Bouton « Ajouter un clic ou une touche » : faites la combinaison voulue, puis choisissez le sort. Changer le raccourci d'une ligne échange les deux sorts s'il était déjà pris (#20).",
			"Nouveau sort sans clic : un message, et le sort en haut de l'onglet Clics avec « Attribuer » (option « Signaler un nouveau sort sans clic ») (#22).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.12.0", date = "2026-11-17",
		added = {
			"Échelle générale de tous les cadres, de 50 à 200 %, suivie par le mode test (#18).",
			"Éditeur de placement (onglet Cadres) : sur une case d'exemple agrandie, glissez ou poussez au pixel près le nom, le texte de vie, les icônes de rôle, de marqueur et centrale, vos soins, les affaiblissements, le buff manquant et les auras privées ; chaque forme de case garde ses placements, partagés avec le code de configuration (#18).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.11.0", date = "2026-11-17",
		added = {
			"Onglet Soins : vos soins sur la durée avec cercle, décompte en secondes, icône qui s'efface à la fin et charges, à combiner comme vous voulez (#16).",
			"Coins de la case : un de vos sorts par coin, en petit carré de couleur qui se vide avec le temps, réglé pour chaque classe et reconnu même en combat (#17).",
			"Barre fine de menace en haut de la vie : jaune, orange puis rouge (#17).",
			"Pourcentage de mana écrit dans la barre de mana, lisible en combat (#40).",
		},
		improved = {
		},
		fixed = {
			"Le texte de vie ne passe plus par-dessus la barre de mana en forme Tuile et Carré (#40).",
		},
	},
	{
		version = "1.10.0", date = "2026-11-17",
		added = {
			"Couleur de la barre de mana au choix (onglet Indicateurs) : bleu par défaut, bleu ciel, violet, turquoise ou blanc.",
			"Trois thèmes pour les fenêtres de Lyorune : Moderne (par défaut), Classique et MMORPG, changés en direct ; le contraste élevé s'y applique aussi (#39).",
			"Inscription runique animée : les runes s'écrivent à l'ouverture, une lueur avec halo les parcourt, une vague de lumière au survol avant la traduction, couleurs selon le thème (#33).",
			"Réglage « Animations réduites » : fondus courts seulement, runes et logo immobiles (#39).",
			"Effets magiques (interrupteur dans Apparence) : cercle runique derrière le logo, particules de lumière dans l'en-tête, étincelle quand un réglage change, couleur du thème (#39).",
		},
		improved = {
			"Fenêtres plus douces : ouverture en fondu, barre d'onglet qui glisse, survol lumineux, rune de confirmation, séparateurs runiques, logo dans l'en-tête (#39).",
			"Visite guidée : les étapes glissent, une rune par étape, l'élément présenté est entouré de runes (#39).",
			"Couleurs de l'interface accordées au bleu givre et à l'or du logo (#19).",
		},
		fixed = {
			"La barre de mana restait blanche au lieu de bleue.",
			"Le bord droit de certaines cases à cocher disparaissait selon l'échelle de l'interface : chaque trait de bordure garde au moins un pixel.",
			"Les fenêtres des macros, du rapport de bug, du journal et des nouveautés s'ouvrent à côté des options au lieu de les recouvrir.",
		},
	},
	{
		version = "1.9.0", date = "2026-11-17",
		added = {
			"Forme des cases au choix : Barre, Tuile, Carré ou Bandeau, avec des vignettes dessinées en direct, un bouton « Revenir » et un bouton « Voir en vrai » (#14).",
			"Angles des cases droits ou arrondis, pour toutes les formes et tous les thèmes (#15).",
			"Fond et bordure par groupe, aux couleurs du thème (#14).",
		},
		improved = {
			"Couleurs de classe plus vives par défaut, ou naturelles au choix (#32).",
		},
		fixed = {
		},
	},
	{
		version = "1.8.1", date = "2026-11-17",
		added = {
		},
		improved = {
			"Contrôles de sécurité avant chaque publication : codes et messages abîmés, fonctions interdites, contenu de l'archive (#38).",
		},
		fixed = {
			"Configurations reçues : seulement d'un membre du groupe, de la guilde ou d'un ami, une par minute au plus, avec le royaume de l'expéditeur ; une fenêtre ouverte n'est plus remplacée et le bouton Importer attend deux secondes. Les phrases des annonces et les textures inconnues ne sont plus partagées (#34).",
			"Avis de nouvelle version : il faut deux joueurs différents et un numéro vraisemblable ; le message cite la page officielle (#35).",
			"Rapport de bug et journal d'erreurs : noms de personnages et de royaumes remplacés (#36).",
			"Macros des barres de sorts : Lyorune ne touche plus qu'aux macros qu'il a créées, jamais à une macro du joueur nommée « Lyo: » (#37).",
		},
	},
	{
		version = "1.8.0", date = "2026-11-17",
		added = {
			"Auras privées des boss : le jeu les dessine lui-même sur la case, taille et place réglables (#9).",
			"Absorption de soins : bande rouge sombre au bout de la vie, calculée par le jeu, juste en combat (#10).",
			"Icônes d'invocation en cours et de joueur dans une autre phase (#11).",
			"Infobulle au survol d'une case : la liste de vos clics et touches, hors combat (#12).",
			"Contour lumineux pour un affaiblissement important, même en combat pour ceux des boss, et son pour ceux de votre liste (#13).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.7.0", date = "2026-11-17",
		added = {
			"En raid, un cadre par groupe avec son numéro au-dessus (« Groupe 1 » à « Groupe 8 »), ou le nom du rôle en rangement par rôle ; réglage pour les masquer (#6).",
			"Déplacement des cadres au choix : libre, verrouillé, ou en maintenant Alt, Ctrl ou Maj, par n'importe quelle étiquette de groupe (#7).",
			"Position des cadres gardée pour chaque personnage ; un nouveau personnage part de la position par défaut (#5).",
		},
		improved = {
			"Barre de mana affichée pour tous par défaut, hauteur réglable (#8).",
			"Bouton de la mini-carte à la même taille que ceux des autres addons.",
		},
		fixed = {
			"La couleur de dissipation ne cache plus le nom ni la vie : contour coloré et voile léger (#4).",
		},
	},
	{
		version = "1.6.0", date = "2026-11-17",
		added = {
			"Bibliothèque « Mes macros » : une macro écrite une fois, posée sur autant de clics et de touches que vous voulez (#23).",
			"Assistant de macro à cases à cocher, import depuis /macro, glisser-déposer sur les cases.",
			"Vérification de la macro pendant la saisie, et aperçu du texte exact envoyé au jeu.",
			"Clics et touches propres à chaque spécialisation, qui changent tout seuls avec les talents (#21).",
		},
		improved = {
			"Une commande de macro sans cible vise la case ; [@mouseover] marche tel quel.",
			"Vos anciennes macros sont rangées toutes seules dans la bibliothèque.",
		},
		fixed = {
		},
	},
	{
		version = "1.5.4", date = "2026-11-17",
		added = {
			"Vos propres macros du jeu sur un clic : la fenêtre de choix d'un sort montre les macros que vous avez écrites dans /macro.",
		},
		improved = {
			"Les macros pour les barres de sorts ne sont plus créées d'office : cochez la case dans l'onglet Clics si vous les voulez. Celles créées par la 1.5.1 sont retirées.",
		},
		fixed = {
		},
	},
	{
		version = "1.5.3", date = "2026-11-17",
		added = {
		},
		improved = {
			"La fenêtre d'options est plus haute, pour que les macros des barres de sorts tiennent dans l'onglet Clics.",
			"Une erreur dans un onglet des options ne cache plus les autres réglages, et elle est notée au journal.",
		},
		fixed = {
		},
	},
	{
		version = "1.5.2", date = "2026-11-17",
		added = {
		},
		improved = {
		},
		fixed = {
			"Les cadres s'affichent de nouveau : le jeu refusait de créer les cases, seul comme en groupe.",
		},
	},
	{
		version = "1.5.1", date = "2026-11-17",
		added = {
			"Macros pour vos barres de sorts : Lyorune crée et tient à jour une vraie macro du jeu pour chaque sort de vos clics. Onglet Clics : cliquez sur son icône puis déposez-la dans une barre.",
		},
		improved = {
			"Le rapport de /lyorune erreurs décrit maintenant l'état de chaque cadre.",
		},
		fixed = {
		},
	},
	{
		version = "1.5.0", date = "2026-11-17",
		added = {
			"Macros : dans le choix d'un clic ou d'une touche au survol, le bouton « Macro... » propose trois modèles prêts (bijou puis soin, interrompre puis soigner, annonce puis soin) et une saisie libre.",
		},
		improved = {
			"Un code de configuration reçu d'un autre joueur ne peut contenir que des noms de sorts, jamais une commande.",
		},
		fixed = {
		},
	},
	{
		version = "1.4.2", date = "2026-11-17",
		added = {
			"Réglage « Afficher les cadres » (onglet Cadres) : en permanence, ou seulement pendant les combats.",
			"La commande /lyorune diag décrit l'état de chaque cadre, pour comprendre un cadre resté vide.",
		},
		improved = {
			"L'affichage des cadres est confié au jeu lui-même : il reste fiable en plein combat.",
		},
		fixed = {
			"Après le mode test, les vrais cadres reviennent dès le début du combat.",
			"Plus d'erreur quand on relâche la poignée d'un cadre pendant un combat.",
			"Les soins en route sont de nouveau accrochés au bout de la barre de vie.",
		},
	},
	{
		version = "1.4.1", date = "2026-11-16",
		added = {
		},
		improved = {
			"Lyorune parle anglais partout : visite guidée, nouveautés, messages du chat et noms des thèmes.",
			"Sur un jeu en anglais, les annonces proposées (mana, résurrection) sont en anglais dès l'installation.",
			"La fenêtre /lyorune bug donne le lien direct vers le formulaire de signalement, dans votre langue.",
		},
		fixed = {
		},
	},
	{
		version = "1.4.0", date = "2026-11-16",
		added = {
			"Nouveau nom : Lyorune. Les commandes sont /lyorune et /lyo.",
			"Bouton sur la mini-carte : clic gauche pour les options, clic droit pour le mode test. Il se déplace et se désactive dans l'onglet Aide.",
			"Logo de Lyorune dans la liste des addons.",
			"Inscription runique animée au bas de la fenêtre d'options : passez la souris dessus pour la traduire.",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.3.0", date = "2026-11-16",
		added = {
			"Signaler un bug en trois questions avec /lyorune bug : un rapport prêt à copier.",
			"Trois préréglages de transparence : discret, semi-transparent, bien visible.",
			"Diagnostic de position avec /lyorune position, en vue de la flèche de direction.",
		},
		improved = {
			"Changement de spécialisation ou de talents pris en compte sans /reload.",
			"Un joueur déconnecté reste visible avec la mention « Déco ».",
			"Notification d'erreur réglable, une seule par session.",
		},
		fixed = {
		},
	},
	{
		version = "1.2.0", date = "2026-11-16",
		added = {
			"Mode test : un faux groupe de 5 à 40 joueurs pour régler l'apparence (/lyorune test).",
			"Cadres séparés pour les tanks et les familiers, ordre des rôles au choix.",
			"Barre de mana des soigneurs, alerte visuelle de vie basse, buffs de groupe manquants.",
			"Soins sur la durée en icônes ou en barres fines, affaiblissements importants en grand.",
			"Touches au survol, résurrection automatique sur le clic de soin.",
			"Listes personnelles : sorts à suivre, affaiblissements à ignorer ou à mettre en avant.",
			"Luminosité, opacité, contraste élevé, réduction automatique des cases en grand raid.",
			"Profils prêts à l'emploi, envoi direct de sa configuration à un joueur, tout réinitialiser.",
			"Traduction anglaise des options.",
			"Avertissement quand un membre du groupe a une version plus récente.",
		},
		improved = {
			"Options rangées en huit onglets, avec une recherche.",
		},
		fixed = {
			"Votre propre case n'est plus estompée comme si vous étiez hors de portée.",
		},
	},
	{
		version = "1.1.0", date = "2026-11-16",
		added = {
			"Cinq thèmes, annonces de mana et de résurrection, partage de configuration par code.",
			"Journal d'erreurs (/lyorune erreurs) et contrôle de compatibilité (/lyorune diag).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.0.0", date = "2026-11-16",
		added = {
			"Première version pour WoW Forever : cadres, clic-soin, soins en route, dissipation, tutoriel.",
		},
		improved = {
		},
		fixed = {
		},
	},
}

-- « Me montrer » : la nouveauté qui a un réglage mène à lui dans les options (Z:GoToOption).
-- Par version, puis par rubrique : le réglage de chaque ligne, dans l'ordre des lignes (false : pas de réglage).
-- Une clé qui n'a plus de ligne dans les options est simplement ignorée. Tenu à la main, vérifié par les tests.
Z.changeShows = {
	["1.50.0"] = { added = { "channelFR" } },
	["1.48.1"] = { improved = { false }, fixed = { "lowHealth" } },
	["1.48.0"] = { added = { "uniqueLive" }, improved = { "lowHealth" }, fixed = { "pets" } },
	["1.47.0"] = { added = { "tallyExit", false }, improved = { "missingBuffs" } },
	["1.46.5"] = { improved = { "pets" } },
	["1.46.1"] = { added = { "showDpsRole" } },
	["1.46.0"] = { added = { "totemPanel", "showClassIcon" } },
	["1.45.0"] = { added = { "notebook" } },
	["1.44.0"] = { improved = { "cooldownShare" } },
	["1.43.0"] = { added = { "debuffCountdown", false, "dispelIcon" } },
	["1.42.1"] = { added = { "groupCooldowns", "cooldownShare" } },
	["1.42.0"] = { added = { "cooldownPanel", "channelMark" }, improved = { "clickTooltip" } },
	["1.41.0"] = { added = { false, "showName" } },
	["1.40.0"] = { added = { "absorbText" } },
	["1.39.0"] = { added = { false, "enemyGuard" } },
	["1.38.1"] = { improved = { "rankChoice", "rankAdapt" } },
	["1.37.1"] = { improved = { false, "combatBuffs" } },
	["1.36.0"] = { added = { "combatBuffs", "combatKey" } },
	["1.34.0"] = { added = { "buffPanel" } },
	["1.33.7"] = { improved = { false, "buffRenew" } },
	["1.33.1"] = { improved = { "buffGroupAt" } },
	["1.32.0"] = { added = { "assignMark" } },
	["1.31.0"] = { added = { "healthyFade", "clickStats" } },
	["1.30.0"] = { added = { "logoAnimation" }, improved = { "fiveSecondRule" } },
	["1.29.0"] = { added = { "dispelCount", false, "drinkHealers", "manaEdge", "fiveSecondRule" } },
	["1.28.0"] = { added = { "showDefensives", "showControls" } },
	["1.25.0"] = { added = { "lowManaHealers", "absorbStyle" }, improved = { "hotCount" } },
	["1.24.0"] = { added = { "regenAlert" } },
	["1.23.13"] = { added = { "manaAlert" } },
	["1.23.12"] = { improved = { "powerHeight" } },
	["1.23.0"] = { added = { false, "autoProfile" } },
	["1.22.0"] = { added = { false, "castIndicator" } },
	["1.21.0"] = { added = { "trinketButtons", false, "clickConflictAlert" } },
	["1.20.0"] = { added = { "showPinned", "pingCells", "showLeader" } },
	["1.19.0"] = { added = { "farHint", "losHint" } },
	["1.18.0"] = { added = { "perfMode" } },
	["1.17.0"] = { added = { "resSync" }, improved = { "syncEnabled" } },
	["1.16.0"] = { added = { "buffPanel" } },
	["1.15.0"] = { added = { "layout", "sortOrder", "keepGroupPlace" } },
	["1.14.0"] = { added = { false, "autoProfile", "showTarget" } },
	["1.12.0"] = { added = { "scale" } },
	["1.11.0"] = { added = { "showHots", false, "threatBar", "manaPercent" } },
	["1.10.0"] = { added = { "manaColor", "windowTheme", false, "reduceMotion", "magicEffects" } },
	["1.9.0"] = { added = { "shape", "corners", "groupPanel" }, improved = { "classIntensity" } },
	["1.8.0"] = { added = { "privateAuras", "showHealAbsorb", "showSummonPhase", "showTooltip", "importantGlow" } },
	["1.7.0"] = { added = { false, "lockMode" }, improved = { "manaBars" } },
	["1.6.0"] = { added = { false, false, false, "clicksPerSpec" } },
	["1.5.1"] = { added = { "actionBarMacros" } },
	["1.4.2"] = { added = { "visibility" } },
	["1.4.0"] = { added = { false, "minimapButton", false, "showRunes" } },
	["1.3.0"] = { improved = { false, false, "errorNotice" } },
	["1.2.0"] = { added = { false, "showTanks", "lowHealth", false, false, false, "highContrast", false, false, "versionNotice" } },
}

-- Rubriques, dans l'ordre d'affichage
Z.changeSections = { { "added", "Nouveau" }, { "improved", "Amélioré" }, { "fixed", "Corrigé" } }

local window

-- Première rune de l'atlas (128 x 64 pixels, runes de 16), en or, dans le texte
local NEW_RUNE = "|TInterface\\AddOns\\Lyorune\\Media\\Runes:14:14:0:0:128:64:0:16:0:16:255:210:77|t"

-- Le réglage d'une ligne des nouveautés, s'il a encore sa ligne dans les options
function Z.ChangeShow(version, section, index)
	local shows = Z.changeShows[version]
	local key = shows and shows[section] and shows[section][index]
	if key and Z.TabOfSetting and Z.TabOfSetting(key) then return key end
end

function Z:NewsText()
	local L = Z.L
	local lines = {}
	local link = " |Hlyorune:show:%s|h|cff" .. Z.UI.Hex("accent") .. "[" .. L["Me montrer"] .. "]|r|h"
	-- versions sorties depuis la dernière lecture de cette fenêtre : une rune d'or et « Nouveau pour vous »
	local seen = Z.db.newsSeen and Z.VersionNumber(Z.db.newsSeen)
	local fresh = "  " .. NEW_RUNE .. " |cffffd24d" .. L["Nouveau pour vous"] .. "|r"
	for _, entry in ipairs(Z.changes) do
		lines[#lines + 1] = "|cff" .. Z.UI.Hex("accent") .. "Lyorune " .. entry.version .. "|r  |cff" .. Z.UI.Hex("dim") .. entry.date .. "|r"
			.. ((seen and Z.VersionNumber(entry.version) > seen) and fresh or "")
		for _, section in ipairs(Z.changeSections) do
			local notes = entry[section[1]]
			if notes and #notes > 0 then
				lines[#lines + 1] = "  |cffffd24d" .. L[section[2]] .. "|r"
				for i, note in ipairs(notes) do
					local key = Z.ChangeShow(entry.version, section[1], i)
					lines[#lines + 1] = "    - " .. L[note] .. (key and link:format(key) or "")
				end
			end
		end
		lines[#lines + 1] = ""
	end
	return table.concat(lines, "\n")
end

-- « Me montrer » : le lien mène au réglage dans les options, ouvertes à côté de cette fenêtre
local function LinkClick(_, data)
	local key = type(data) == "string" and data:match("^lyorune:show:(.+)$")
	if key and Z:GoToOption(key) and window and window:IsShown() then
		Z.UI.PlaceBeside(window) -- options ouvertes par le lien : cette fenêtre se range à côté, sans cacher le réglage
	end
end

local function LinkEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	GameTooltip:SetText(Z.L["Mène au réglage de cette nouveauté dans les options."], 1, 1, 1, 1, true)
	GameTooltip:Show()
end

function Z:ShowNews()
	local UI = Z.UI
	if not window then
		window = UI.Window("LyoruneNews", Z.L["Nouveautés de Lyorune"], 560, 400)
		window.beside = true -- à côté des options, jamais dessous ni par-dessus
		window:SetFrameStrata("FULLSCREEN_DIALOG")
		tinsert(UISpecialFrames, "LyoruneNews")
		local scroll = CreateFrame("ScrollFrame", nil, window)
		scroll:SetPoint("TOPLEFT", 16, -46)
		scroll:SetPoint("BOTTOMRIGHT", -16, 16)
		scroll:EnableMouseWheel(true)
		scroll:SetScript("OnMouseWheel", function(self, delta)
			local position = self:GetVerticalScroll() - delta * 40
			self:SetVerticalScroll(math.max(0, math.min(position, self:GetVerticalScrollRange())))
		end)
		local content = CreateFrame("Frame", nil, scroll)
		content:SetSize(520, 10)
		content:EnableMouse(true) -- la molette reste au cadre qui défile
		content:SetHyperlinksEnabled(true) -- liens « Me montrer » du texte
		content:SetScript("OnHyperlinkClick", LinkClick)
		content:SetScript("OnHyperlinkEnter", LinkEnter)
		content:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
		scroll:SetScrollChild(content)
		window.text = UI.Label(content, 12)
		window.text:SetPoint("TOPLEFT")
		window.text:SetWidth(520)
		window.text:SetJustifyH("LEFT")
		window.text:SetSpacing(4)
		window.content, window.scroll = content, scroll
		window:HookScript("OnHide", function() -- lue : plus rien de nouveau pour vous
			-- Première fermeture après une mise à jour : dire où les relire
			if Z.db.newsSeen ~= Z.version then
				Z:Print(Z.L["Pour relire les nouveautés : bouton Nouveautés en haut des options, Maj + clic sur le bouton de la mini-carte, ou /lyorune nouveautes."])
			end
			Z.db.newsSeen = Z.version
		end)
	end
	-- Relu à chaque appel (couleurs du thème en cours), depuis le haut ; ouverte, elle passe devant
	window.text:SetText(Z:NewsText())
	window.content:SetHeight(window.text:GetStringHeight() + 10)
	window.scroll:SetVerticalScroll(0)
	UI.Reopen(window)
	window:Raise()
end
