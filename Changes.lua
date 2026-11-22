-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Changes.lua : ce qui change à chaque version, affiché en jeu après une mise à jour.
-- Ce fichier est la SEULE source du journal des versions : outils/publier.py y ajoute la nouvelle version
-- et régénère CHANGELOG.md à partir de lui. La version la plus récente est en premier.
-- Trois rubriques par version : added (nouveau), improved (amélioré), fixed (corrigé).

local _, Z = ...

Z.changes = {
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
			"Buffs complets des soigneurs : prêtre (Robustesse, Esprit divin pour les joueurs à mana, Protection contre l'ombre, Feu intérieur et sorts de race sur vous), paladin (une bénédiction de vous par joueur : Rois pour le tank et le chasseur, Sagesse pour les joueurs à mana, Puissance pour les autres ; Fureur vertueuse au choix), chaman (Bouclier d'eau ou de foudre, enchantement de votre arme), druide (Marque du fauve). Gardien de peur et Serment de lumière rejoignent les buffs à poser sur une seule personne.",
			"Mes buffs (chapitre Joueurs) : choisissez les buffs à surveiller, une liste pour les donjons, raids et le monde (JcE), une autre pour les champs de bataille et l'arène (JcJ). Au départ, Protection contre l'ombre ne compte qu'en JcJ ; Fureur vertueuse et Gardien de peur sont éteints.",
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

-- Rubriques, dans l'ordre d'affichage
Z.changeSections = { { "added", "Nouveau" }, { "improved", "Amélioré" }, { "fixed", "Corrigé" } }

local window

function Z:NewsText()
	local L = Z.L
	local lines = {}
	for _, entry in ipairs(Z.changes) do
		lines[#lines + 1] = "|cff" .. Z.UI.Hex("accent") .. "Lyorune " .. entry.version .. "|r  |cff" .. Z.UI.Hex("dim") .. entry.date .. "|r"
		for _, section in ipairs(Z.changeSections) do
			local notes = entry[section[1]]
			if notes and #notes > 0 then
				lines[#lines + 1] = "  |cffffd24d" .. L[section[2]] .. "|r"
				for _, note in ipairs(notes) do lines[#lines + 1] = "    - " .. L[note] end
			end
		end
		lines[#lines + 1] = ""
	end
	return table.concat(lines, "\n")
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
		scroll:SetScrollChild(content)
		window.text = UI.Label(content, 12)
		window.text:SetPoint("TOPLEFT")
		window.text:SetWidth(520)
		window.text:SetJustifyH("LEFT")
		window.text:SetSpacing(4)
		window.content, window.scroll = content, scroll
	end
	-- Relu à chaque appel (couleurs du thème en cours), depuis le haut ; ouverte, elle passe devant
	window.text:SetText(Z:NewsText())
	window.content:SetHeight(window.text:GetStringHeight() + 10)
	window.scroll:SetVerticalScroll(0)
	UI.Reopen(window)
	window:Raise()
end
