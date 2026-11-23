-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Cadres de soin pour WoW Forever
-- Core.lua : réglages, événements, commandes. Tout le reste s'appuie sur ce fichier.

local ADDON, Z = ...
_G.Lyorune = Z

Z.version = (C_AddOns and C_AddOns.GetAddOnMetadata(ADDON, "Version")) or "1.46.0"
Z.class = select(2, UnitClass("player"))

-- En combat, le client Forever rend certaines valeurs « secrètes » (vie, auras...) :
-- on peut les afficher, mais pas les comparer ni calculer avec.
local issecretvalue = issecretvalue or function() return false end
Z.IsSecret = issecretvalue

----------------------------------------------------------------------------------------------------
-- Réglages. Trois tables décrivent TOUT réglage, une seule fois :
--   Z.defaults : la valeur par défaut
--   Z.limits   : pour un nombre, { minimum, maximum, pas }
--   Z.choices  : pour un choix, la liste { valeur, "libellé" }
-- La fenêtre d'options, le partage et la réinitialisation s'appuient sur ces tables.
----------------------------------------------------------------------------------------------------
Z.defaults = {
	-- Cadres
	width = 86, height = 42, spacing = 3,
	scale = 100,               -- échelle générale de tous les cadres, en %
	placement = {},            -- place et taille de chaque élément de la case, par forme : placement.TILE.role = { 3, -2, 150 }
	                           -- (décalage en pixels, puis taille en %, absente à 100 %)
	layout = "GROUP",          -- rangement : par groupe de raid, par rôle, ou en une seule grille
	sortOrder = "INDEX",       -- ordre dans chaque bloc : celui du groupe, par nom, ou par classe puis nom
	keepGroupPlace = false,    -- en raid, chaque groupe garde sa place, même vide (rangement par groupe)
	gridSize = 5,              -- en grille : nombre de cases par colonne (ou par ligne)
	roleOrder = "TANK,HEALER,DAMAGER", -- ordre des rôles quand le rangement est « par rôle »
	horizontal = false,        -- false : groupes en colonnes, true : en lignes
	showSolo = true,           -- afficher mon cadre quand je suis seul
	visibility = "ALWAYS",     -- afficher les cadres : en permanence, ou seulement en combat
	showTanks = false,         -- cadre séparé pour les tanks
	showPets = false,          -- cadre séparé pour les familiers
	showTarget = false,        -- petite case de ma cible (cadre « Cible », déplaçable)
	showTargetTarget = false,  -- case de la cible de ma cible
	showFocus = false,         -- case de ma focalisation
	showPinned = true,         -- cadre « Épinglés » : les joueurs de ma liste (vide, il ne s'affiche pas)
	pinned = {},               -- joueurs épinglés, par nom : pinned["Nom-Royaume"] = true
	-- Répartition entre soigneurs (Assign.lua) : les joueurs dont je m'occupe portent un repère « pour moi »
	assignMark = true,         -- repère sur mes joueurs (rien ne s'affiche tant qu'aucun groupe ni joueur n'est choisi)
	assignGroups = {},         -- groupes de raid dont je m'occupe : assignGroups[3] = true
	assignPlayers = {},        -- joueurs dont je m'occupe (un tank...), par nom : assignPlayers["Nom-Royaume"] = true
	assignFade = false,        -- (éteint au départ) estomper un peu les autres joueurs
	autoShrink = false,        -- réduire les cases en grand raid
	lockMode = "FREE",         -- déplacement des cadres : libre, verrouillé, ou en maintenant Alt, Ctrl ou Maj
	showGroupLabels = true,    -- « Groupe 1 »... au-dessus de chaque colonne (ou le rôle en rangement par rôle)
	frameAlpha = 100,          -- opacité générale, en %
	perfMode = false,          -- mode performance (Perf.lua) : portée 1 fois par seconde, auras regroupées 10 fois par seconde au plus
	minimapButton = true,      -- bouton au bord de la mini-carte
	minimapAngle = 215,        -- sa place autour de la mini-carte, en degrés

	-- Apparence
	shape = "TILE",            -- forme des cases : Barre, Tuile, Carré, Bandeau (chacune règle taille, texte et mana)
	corners = "SHARP",         -- angles des cases : droits ou arrondis
	groupPanel = false,        -- fond et bordure autour de chaque groupe
	theme = "PURE", texture = "THEME",
	color = "CLASS",           -- couleur des barres : classe, ou vie restante
	text = "DEFICIT",          -- texte de vie
	fontSize = 11,
	smooth = true,             -- barres animées
	brightness = 100,          -- luminosité des barres, en %
	classIntensity = "VIVID",  -- couleurs de classe : naturelles (celles du jeu) ou vives
	highContrast = false,      -- mode contraste élevé
	rangeAlpha = 35,           -- opacité d'un joueur hors de portée, en %
	farHint = true,            -- joueur très loin (le jeu ne le voit plus) : case plus estompée, empreintes au centre
	losHint = true,            -- soin refusé car le joueur est hors de vue : œil au centre de sa case, 3 secondes
	healthyFade = false,       -- (éteint au départ) joueur en bonne santé : vie, mana et nom estompés au-dessus du seuil (Frames.lua)
	healthyFadeAt = 90,        -- seuil de bonne santé, en % de vie

	-- Indicateurs (chacun peut être coupé)
	showIncoming = true,       -- soins en route
	showAbsorb = true,         -- bouclier
	absorbStyle = "BAND",      -- place du bouclier : bande en bas de la case, ou à la suite de la vie (comme les cadres du jeu)
	absorbText = false,        -- chiffre du bouclier : ce qui reste à absorber (« +1,2k »), même en combat
	showThreat = true,         -- bordure rouge de menace
	showName = true,           -- nom du joueur sur la case
	showRole = true,           -- icône de rôle
	showDpsRole = false,       -- icône de rôle aussi pour les DPS (C25, éteinte au départ)
	showClassIcon = false,     -- icône de classe sur la case (éteinte au départ), placée par l'éditeur de placement
	showMarker = true,         -- marqueur de raid
	showLeader = true,         -- couronne du chef de groupe, drapeau des assistants en raid
	pingCells = true,          -- la touche « signal » du jeu marque le joueur de la case survolée
	showDispel = true,         -- cadre coloré de dissipation, et liseré de chaque icône d'affaiblissement à la couleur de son type
	dispelIcon = true,         -- icône du type à dissiper (goutte de magie, crâne de malédiction...), dessinée par le jeu
	showHots = true, hotStyle = "ICONS",
	hotCount = 4,              -- nombre de mes soins sur la durée affichés par case (icônes ou barres)
	hotSwipe = true,           -- icônes de mes soins : cercle qui se vide
	hotCountdown = false,      -- icônes de mes soins : secondes restantes, écrites par le jeu
	hotFade = false,           -- icônes de mes soins : l'icône s'assombrit vers la fin du soin
	hotCharges = true,         -- icônes de mes soins : nombre de charges
	showLockouts = true,       -- affaiblissement qui bloque un de mes sorts (Âme affaiblie, Longanimité, Z.lockouts) : assombri après mes soins
	lockoutCountdown = true,   -- ses secondes restantes, écrites par le jeu (même en combat)
	cornerSpells = {},         -- un de mes sorts par coin de case, par classe : cornerSpells.DRUID.TOPLEFT = "Récupération"
	threatBar = false,         -- barre fine de menace en haut de la vie (jaune, orange, rouge)
	showDebuffs = true, debuffMode = "ALL",
	debuffCountdown = true,    -- secondes restantes sur les affaiblissements, le contrôle subi et la grande icône
	debuffCount = 2,           -- nombre d'icônes d'affaiblissements par case (celui à dissiper d'abord, puis les autres)
	dispelCount = 2,           -- affaiblissements que je peux dissiper montrés avant les autres (le plus important d'abord)
	bossDebuffs = true,        -- affaiblissement important en grand
	showControls = true,       -- joueur sous contrôle (étourdi, apeuré, métamorphosé) : l'icône au centre de sa case
	showDefensives = true,     -- gros défensifs posés par n'importe qui (Z.defensives, Data.lua) : leur icône sur la case
	lowHealth = true, lowHealthAt = 25,
	missingBuffs = true,       -- buff de groupe manquant (hors combat)
	combatBuffs = true,        -- en combat (et boss hors combat), le jeu cache les buffs : mes buffs dessinés par le jeu, gris s'ils manquent (Containers.lua)
	pvpBuffs = true,           -- même chose en champ de bataille et en arène ; là, seul ce réglage décide (Z.BuffMarksOn)
	buffPanel = true,          -- panneau des buffs manquants, cliquable (hors combat, Buffs.lua), buffs uniques compris
	combatKey = true,          -- en combat, la touche du prochain buff relance mon buff unique sur son porteur (Buffs.lua)
	buffPlace = "FRAMES",      -- où : collé sous les cadres, à la forme des cases (départ), ou fenêtre posée où l'on veut
	buffWatch = {},            -- « Mes buffs » : buffWatch[numéro du buff] = { pve = bool, pvp = bool } ; absent : le départ de Data.lua
	buffRefresh = 2,           -- proposer à nouveau un buff qui finit dans moins de N minutes (0 : seulement s'il manque)
	buffGroupAt = 3,           -- joueurs d'un même groupe sans le buff à partir desquels la version de groupe est proposée
	buffGroups = {},           -- groupes de raid que je buffe : buffGroups[3] = false écarte le groupe 3 ; vide : tous (BuffAssign.lua)
	blessingPick = {},         -- bénédiction par type de joueur : blessingPick.TANK = numéro du sort, 0 = aucune ; absent : le départ
	castIndicator = "OFF",     -- temps de recharge global et incantation (Cast.lua) : aucun, barre sous les cadres, anneau au curseur
	cooldownPanel = false,     -- « Mes recharges » : rangée d'icônes de mes sorts à recharge sous les cadres, même en combat (Cooldowns.lua)
	cooldownShow = "ALL",      -- icônes montrées : tous mes sorts (prêts nets, en recharge grisés) ou seulement ceux qui rechargent
	cooldownIgnored = {},      -- sorts à ne pas montrer dans « Mes recharges » et les recharges du groupe, par leur nom
	totemPanel = false,        -- « Mes totems » : mes totems posés (Feu, Terre, Eau, Air) sous les cadres, même en combat (Totems.lua)
	groupCooldowns = false,    -- recharges du groupe : les gros sorts des alliés qui ont Lyorune, sous les cadres (GroupCooldowns.lua)
	channelMark = true,        -- soin canalisé sur un joueur (Pénitence) : un trait se vide sur sa case au rythme de la canalisation (Frames.lua)
	manaBars = "ALL",          -- barre de mana : personne, soigneurs, tous
	powerHeight = 4,           -- hauteur de la barre de mana, en pixels
	manaColor = "BLUE",        -- couleur de la barre de mana (teintes de Z.manaColors, Frames.lua)
	fiveSecondRule = false,    -- (éteint au départ, au choix du joueur) trait sur ma case pendant les 5 secondes sans régénération après un sort (Mana.lua)
	manaEdge = 20,             -- liseré bleu au bord de l'écran quand ma mana passe sous ce % (0 : jamais ; courbe du jeu)
	lowManaHealers = 20,       -- icône de boisson sur la case d'un soigneur sous ce % de mana (0 : jamais ; courbe du jeu, marche en combat)
	drinkHealers = true,       -- soigneur qui boit : l'icône de sa boisson à côté de sa mana basse (Z.drinkSpells, Data.lua)
	manaPercent = false,       -- pourcentage de mana écrit dans la barre (elle passe alors à 8 pixels au moins)
	showTooltip = true,
	clickTooltip = true,       -- mes clics et touches dans l'infobulle d'une case (hors combat)
	showHealAbsorb = true,     -- part de vie « mangée » par un affaiblissement avant que les soins comptent
	showCenter = true,         -- icône centrale (appel, résurrection, hors de vue, invocation, autre phase, très loin)
	showSummonPhase = true,    -- icône d'invocation en cours, ou de joueur dans une autre phase
	privateAuras = true,       -- auras privées des boss, dessinées par le jeu sur la case
	privateAuraSize = 20,      -- leur taille, en pixels
	privateAuraPoint = "CENTER", -- leur place sur la case
	importantGlow = true,      -- contour lumineux quand un affaiblissement important est posé
	importantSound = false,    -- son quand un affaiblissement de la liste « À mettre en avant » est posé

	-- Clics
	castOnDown = true,         -- lancer le sort dès l'appui
	newSpellAlert = true,      -- signaler un sort appris qui n'a encore aucun clic ni aucune touche
	actionBarMacros = false,   -- créer une macro du jeu par sort de mes clics, pour les barres de sorts (à la demande)
	autoRes = true,            -- le même clic relève un joueur mort
	externalClicks = false,    -- laisser Clique ou le clic-soin du jeu gérer les cases
	clicks = {},               -- clics de souris par classe : clicks.PRIEST["shift-1"] = "Rénovation" (PRIEST2 : 2e spécialisation)
	hoverKeys = {},            -- touches au survol par classe : hoverKeys.PRIEST[1] = { key = "F", spell = "Rénovation" }
	clickTrinkets = {},        -- bijoux utilisés avant le sort : clickTrinkets.PRIEST["shift-1"] = 1, 2 ou 3 (voir Clicks.lua)
	clickVariants = {},        -- variantes d'un raccourci : clickVariants.PRIEST["shift-1"] = { enemy = ..., pvp = ..., ooc = ... } (Clicks.lua)
	enemyGuard = true,         -- aucun soin sur un ennemi : un raccourci sans variante « sur un ennemi » n'y fait rien
	trinketButtons = false,    -- montrer les boutons « bijou avec le sort » sur chaque ligne de clic
	clickConflictAlert = true, -- signaler un clic que le « clic pour lancer » du jeu prend aussi
	clicksPerSpec = true,      -- des clics et des touches propres à chaque spécialisation (groupe de talents)
	clickStats = false,        -- (éteint au départ) compter mes clics et mes touches au survol, par personnage (Clicks.lua)
	rankChoice = false,        -- (éteint au départ) choisir le rang de chaque raccourci ; éteint : toujours le rang le plus haut
	rankAdapt = true,          -- un rang choisi trop fort pour un joueur de bas niveau est baissé sur sa case (hors combat)
	macros = {},               -- ma bibliothèque de macros, par classe : macros.PRIEST[1] = { name = "...", body = "..." }
	macroAutoTarget = true,    -- une commande de macro sans cible vise la case

	-- Les amis de Lyorune
	notebook = true,           -- tenir « Votre carnet » : mes soins, résurrections et buffs réussis, par personnage (Tally.lua)

	-- Listes personnelles (noms de sorts)
	extraTracked = {},         -- mes sorts à suivre en plus
	ignoredNames = {},         -- affaiblissements à ne jamais afficher
	importantNames = {},       -- affaiblissements à afficher en grand

	-- Alertes
	manaAlert = true, manaThreshold = 20, manaText = "Mana faible : {mana} % ! Laissez-moi boire.",
	regenAlert = true, regenThreshold = 90, regenText = "Mana remontée ({mana} %), prêt à repartir !",
	resAlert = true, resText = "Je ressuscite {nom}.",
	alertChannel = "SAY",
	soundDispel = false,       -- son quand une dissipation est possible
	soundMana = false,         -- son quand ma mana est faible

	-- Profils (Share.lua) : mes réglages d'apparence enregistrés sous un nom, et choisis seuls selon le groupe
	profiles = {},             -- profiles["Raid"] = { width = 80, ... } : seulement les réglages d'apparence
	activeProfile = "",        -- profil en cours ("" : aucun), enregistré tout seul avant d'en changer
	autoProfile = false,       -- changer de profil tout seul selon la taille du groupe et la spécialisation
	autoProfiles = {},         -- par classe et spécialisation : autoProfiles.PRIEST["25"] = "Raid" (PRIEST2 : 2e spécialisation)

	-- Divers
	language = "AUTO",
	showNews = true,           -- fenêtre des nouveautés après une mise à jour
	syncEnabled = true,        -- synchronisation entre joueurs (Comm.lua) : décochée, aucun message invisible ne part ni n'est lu
	versionNotice = true,      -- prévenir si un membre du groupe a une version plus récente
	acceptConfigs = true,      -- accepter qu'un joueur me propose sa configuration
	resSync = true,            -- qui relève qui : le nom du soigneur qui relève s'affiche sur la case du mort
	assignAccept = true,       -- appliquer la répartition envoyée par le chef ou un assistant (Assign.lua, BuffAssign.lua)
	cooldownShare = false,     -- partager mes recharges : mes gros sorts annoncés au groupe (éteint : au joueur de choisir)
	blessingSync = true,       -- entente entre paladins : chacun annonce ses bénédictions, aucun ne pose celle d'un autre
	showRunes = true,          -- inscription runique animée au bas de la fenêtre d'options
	windowTheme = "MODERN",    -- thème des fenêtres de Lyorune (pas des cases) : Moderne, Classique, MMORPG
	reduceMotion = false,      -- animations réduites : fondus courts seulement, rien en boucle
	magicEffects = true,       -- effets magiques des fenêtres : animation du logo, particules, étincelle de soin
	logoAnimation = "AURORA",  -- animation autour du logo des options (avec les effets magiques) : Aurore, Sceau, Souffle, Aucune
	errorNotice = true,        -- message discret (une fois par session) quand Lyorune rencontre une erreur
	tutorialDone = false,
	wizardDone = false,        -- assistant du premier lancement (Wizard.lua) déjà vu
}

Z.limits = {
	width = { 50, 180, 2 }, height = { 24, 90, 2 }, spacing = { 0, 12, 1 }, fontSize = { 8, 16, 1 },
	frameAlpha = { 30, 100, 5 }, brightness = { 40, 100, 5 }, rangeAlpha = { 10, 100, 5 },
	scale = { 50, 200, 5 }, gridSize = { 2, 20, 1 }, placement = { -40, 40, 1, size = { 50, 300, 10 } }, -- placement : décalage d'un élément dans chaque sens, et sa taille en % de sa taille d'origine
	lowHealthAt = { 10, 60, 5 }, healthyFadeAt = { 50, 100, 5 }, powerHeight = { 2, 60, 1 }, privateAuraSize = { 12, 40, 2 }, hotCount = { 1, 6, 1 }, debuffCount = { 2, 5, 1 }, dispelCount = { 1, 3, 1 }, manaThreshold = { 5, 80, 5 }, regenThreshold = { 50, 100, 5 },
	buffRefresh = { 0, 15, 1 }, buffGroupAt = { 2, 5, 1 },
}

Z.choices = {
	layout = { { "GROUP", "Par groupe" }, { "ROLE", "Par rôle" }, { "GRID", "Grille" } },
	sortOrder = { { "INDEX", "Ordre du groupe" }, { "NAME", "Par nom" }, { "CLASS", "Par classe, puis nom" } },
	roleOrder = {
		{ "TANK,HEALER,DAMAGER", "Tank, soin, dégâts" }, { "TANK,DAMAGER,HEALER", "Tank, dégâts, soin" },
		{ "HEALER,TANK,DAMAGER", "Soin, tank, dégâts" }, { "HEALER,DAMAGER,TANK", "Soin, dégâts, tank" },
		{ "DAMAGER,TANK,HEALER", "Dégâts, tank, soin" }, { "DAMAGER,HEALER,TANK", "Dégâts, soin, tank" },
	},
	horizontal = { { false, "En colonnes" }, { true, "En lignes" } },
	manaEdge = { { 0, "Non" }, { 10, "Sous 10 %" }, { 20, "Sous 20 %" }, { 30, "Sous 30 %" }, { 40, "Sous 40 %" } },
	lowManaHealers = { { 0, "Non" }, { 10, "Sous 10 %" }, { 20, "Sous 20 %" }, { 30, "Sous 30 %" }, { 40, "Sous 40 %" } },
	absorbStyle = { { "BAND", "Bande en bas" }, { "FOLLOW", "À la suite de la vie" } },
	shape = { { "BAR", "Barre" }, { "TILE", "Tuile" }, { "SQUARE", "Carré" }, { "BANNER", "Bandeau" } },
	corners = { { "SHARP", "Droits" }, { "ROUND", "Arrondis" } },
	classIntensity = { { "NATURAL", "Naturelles" }, { "VIVID", "Vives" } },
	lockMode = { { "FREE", "Libre" }, { "LOCKED", "Verrouillé" }, { "ALT", "Avec Alt" }, { "CTRL", "Avec Ctrl" }, { "SHIFT", "Avec Maj" } },
	visibility = { { "ALWAYS", "Toujours" }, { "COMBAT", "En combat seulement" } },
	color = { { "CLASS", "Classe" }, { "HEALTH", "Vie restante" } },
	text = { { "DEFICIT", "Vie manquante" }, { "PERCENT", "Pourcentage" }, { "NONE", "Aucun" } },
	hotStyle = { { "ICONS", "Icônes" }, { "BARS", "Barres fines" } },
	buffPlace = { { "FRAMES", "Avec les cadres" }, { "FREE", "Où vous voulez" } },
	castIndicator = { { "OFF", "Aucun" }, { "BAR", "Barre sous les cadres" }, { "RING", "Anneau au curseur" } },
	cooldownShow = { { "ALL", "Tous mes sorts" }, { "COOLING", "En recharge seulement" } },
	debuffMode = { { "ALL", "Tous" }, { "USEFUL", "Utiles" }, { "DISPEL", "Ceux que je dissipe" } },
	manaBars = { { "OFF", "Personne" }, { "HEALERS", "Soigneurs" }, { "ALL", "Tous" } },
	manaColor = { { "BLUE", "Bleu" }, { "SKY", "Bleu ciel" }, { "PURPLE", "Violet" }, { "TEAL", "Turquoise" }, { "WHITE", "Blanc" } },
	privateAuraPoint = { { "CENTER", "Au centre" }, { "TOP", "En haut" }, { "BOTTOM", "En bas" }, { "LEFT", "À gauche" }, { "RIGHT", "À droite" } },
	alertChannel = { { "SAY", "Dire" }, { "GROUP", "Groupe ou raid" } },
	windowTheme = { { "MODERN", "Moderne" }, { "CLASSIC", "Classique" }, { "MMO", "MMORPG" } },
	logoAnimation = { { "AURORA", "Aurore" }, { "SEAL", "Sceau" }, { "BREATH", "Souffle" }, { "OFF", "Aucune" } },
	language = { { "AUTO", "Automatique" }, { "frFR", "Français" }, { "enUS", "English" } },
}

-- Réglages propres à l'ordinateur ou au personnage : ni partagés, ni réinitialisés avec le reste
Z.private = { minimapAngle = true, tutorialDone = true, wizardDone = true, language = true,
	macros = true, -- mes macros : jamais partagées, jamais effacées par la réinitialisation
	pinned = true, -- mes joueurs épinglés : des noms, jamais partagés
	assignGroups = true, assignPlayers = true, -- ma part de la répartition : propre à chaque raid, jamais partagée
	buffGroups = true, -- mes groupes à buffer : idem
	profiles = true } -- mes profils enregistrés : idem (la réinitialisation quitte seulement le profil en cours)

-- Réglages qu'un profil ne change jamais : clics, listes, annonces, fenêtres de Lyorune, profils eux-mêmes.
-- Tous les autres (cadres, apparence, indicateurs, soins) suivent le profil. Un nouveau réglage d'apparence
-- n'a donc rien à faire ici ; un nouveau réglage d'une autre sorte doit y être ajouté.
Z.notInProfile = {
	minimapButton = true, minimapAngle = true,
	castOnDown = true, newSpellAlert = true, actionBarMacros = true, autoRes = true, externalClicks = true,
	clicks = true, hoverKeys = true, clicksPerSpec = true, macros = true, macroAutoTarget = true,
	clickTrinkets = true, clickConflictAlert = true, trinketButtons = true, clickStats = true,
	rankChoice = true, rankAdapt = true, clickVariants = true, enemyGuard = true, notebook = true,
	extraTracked = true, ignoredNames = true, importantNames = true, pinned = true,
	assignMark = true, assignGroups = true, assignPlayers = true, assignFade = true, assignAccept = true,
	manaAlert = true, manaThreshold = true, manaText = true, regenAlert = true, regenThreshold = true, regenText = true,
	resAlert = true, resText = true, alertChannel = true, soundDispel = true, soundMana = true,
	profiles = true, activeProfile = true, autoProfile = true, autoProfiles = true,
	language = true, showNews = true, syncEnabled = true, versionNotice = true, acceptConfigs = true, resSync = true, showRunes = true, windowTheme = true,
	reduceMotion = true, magicEffects = true, logoAnimation = true, errorNotice = true, tutorialDone = true, wizardDone = true,
	buffPanel = true, combatKey = true, buffPlace = true, castIndicator = true, buffWatch = true, buffRefresh = true, buffGroupAt = true,
	cooldownPanel = true, cooldownShow = true, cooldownIgnored = true, groupCooldowns = true, cooldownShare = true, totemPanel = true,
	buffGroups = true, blessingPick = true, blessingSync = true,
}

-- Position des cadres : gardée pour chaque personnage (LyoruneCharDB). Un personnage neuf part d'ici.
Z.charDefaults = {
	pos = { "CENTER", -320, 60 },
	tankPos = { "CENTER", -320, 200 },
	petPos = { "CENTER", -320, -160 },
	extraPos = { "CENTER", 120, 200 }, -- cible, cible de la cible, focalisation
	pinnedPos = { "CENTER", 120, 60 }, -- joueurs épinglés
	buffPos = { "CENTER", 360, 0 },    -- panneau des buffs manquants
	buffTarget = {},                   -- buffTarget.name : le joueur de /lyorune porteur (tous mes buffs uniques) ;
	                                   -- buffTarget.byId[numéro] = { mode = "TANK"/"ME"/"NAME", name } : choix par buff (Buffs.lua)
	-- lastChoice (sans valeur au départ) : lastChoice[ligne de buff] = dernier enchantement d'arme ou aura lancé (Data.lua)
}

----------------------------------------------------------------------------------------------------
-- Traduction : Z.L["texte français"] renvoie la traduction si elle existe, sinon le texte lui-même
----------------------------------------------------------------------------------------------------
Z.translations = {}
local activeTranslation = {}
Z.L = setmetatable({}, { __index = function(_, key) return activeTranslation[key] or key end })

function Z:SetLanguage()
	local wanted = Z.db.language
	if wanted == "AUTO" then wanted = (GetLocale() == "frFR") and "frFR" or "enUS" end
	activeTranslation = Z.translations[wanted] or {}
	Z.decimalPoint = Z.translations[wanted] ~= nil -- textes traduits (anglais) : 0.25 ; en français : 0,25
	Z.NameBindings()
end

-- Raccourcis du jeu (Bindings.xml, chargé tout seul par le jeu) : Échap, Options, Raccourcis, AddOns, Lyorune.
-- Aucune touche n'est posée au départ : le joueur choisit les siennes. Le jeu lit ces noms quand il affiche la liste.
Z.bindingNames = {
	LYORUNE_OPTIONS = "Ouvrir ou fermer les options",
	LYORUNE_FRAMES = "Afficher ou masquer les cadres (hors combat)",
	["CLICK LyoruneNextBuff:LeftButton"] = "Poser le prochain buff manquant (hors combat)",
	LYORUNE_TEST = "Mode test (faux groupe)",
}
function Z.NameBindings()
	_G.BINDING_HEADER_LYORUNE = "Lyorune"
	for name, text in pairs(Z.bindingNames) do _G["BINDING_NAME_" .. name] = Z.L[text] end
end

-- Appelée par les raccourcis de Bindings.xml (le prochain buff est un clic sur un bouton sécurisé, Buffs.lua)
function Lyorune_Binding(action)
	if not Z.header then return end -- Lyorune n'a pas pu démarrer
	if action == "OPTIONS" then
		Z:Try("raccourci : options", Z.ToggleOptions, Z)
	elseif action == "FRAMES" then
		Z:Try("raccourci : cadres", Z.ToggleFramesShown, Z)
	elseif action == "TEST" then
		Z:Try("raccourci : mode test", Z.TogglePreview, Z)
	end
end

-- Nombre à virgule écrit pour le joueur : « 0,25 » en français, « 0.25 » en anglais
function Z.Decimal(value, digits)
	local text = ("%." .. (digits or 0) .. "f"):format(value)
	return Z.decimalPoint and text or (text:gsub("%.", ","))
end

function Z:Print(msg)
	print("|cff33dd88Lyorune|r : " .. tostring(msg))
end

----------------------------------------------------------------------------------------------------
-- Événements : Z:On("EVENEMENT", fonction)
----------------------------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local handlers = {}

function Z:On(event, fn)
	if not handlers[event] then
		if not pcall(eventFrame.RegisterEvent, eventFrame, event) then return end -- événement inconnu du client
		handlers[event] = {}
	end
	table.insert(handlers[event], fn)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	local list = handlers[event]
	for i = 1, #list do Z:Try(event, list[i], ...) end -- une erreur n'empêche pas la suite, et elle est notée
end)

----------------------------------------------------------------------------------------------------
-- Actions interdites en combat (taille, disposition, clics) : remises à la fin du combat
----------------------------------------------------------------------------------------------------
local pending = {}

function Z:Safe(key, fn)
	if InCombatLockdown() then
		if not next(pending) then Z:Print(Z.L["modification appliquée à la fin du combat."]) end
		pending[key] = fn
	else
		Z:Try(tostring(key), fn) -- un arrêt est écrit au journal (C17), même si un autre addon tient les erreurs
	end
end

Z:On("PLAYER_REGEN_ENABLED", function()
	for key, fn in pairs(pending) do
		pending[key] = nil
		Z:Try("fin du combat : " .. tostring(key), fn) -- une action en erreur n'empêche pas les suivantes
	end
end)

----------------------------------------------------------------------------------------------------
-- Le groupe change (C17) : le jeu envoie GROUP_ROSTER_UPDATE en rafale (un raid qui se forme, un champ de bataille
-- qui se remplit). Lyorune l'écoute une seule fois et prévient chaque fichier en deux temps :
--   Z:OnRoster(fn)        : à l'image suivante, une fois pour toute la rafale de cette image (ce qui se voit) ;
--   Z:OnRosterSettled(fn) : quand le groupe ne bouge plus depuis un court instant (profil, réglages, listes),
--                           et toutes les 2 secondes au plus si le groupe ne cesse de bouger (grand champ de bataille).
----------------------------------------------------------------------------------------------------
local ROSTER_CALM, ROSTER_MAX = 0.4, 2 -- secondes sans changement avant le travail lourd ; attente la plus longue
local onRoster, onSettled = {}, {}
local rosterNext, rosterWave, burstStart = false, 0, nil

function Z:OnRoster(fn) onRoster[#onRoster + 1] = fn end
function Z:OnRosterSettled(fn) onSettled[#onSettled + 1] = fn end

local function RunAll(list, label)
	for i = 1, #list do Z:Try(label, list[i]) end
end

Z:On("GROUP_ROSTER_UPDATE", function()
	rosterWave = rosterWave + 1
	local wave = rosterWave
	burstStart = burstStart or GetTime()
	if not rosterNext then
		rosterNext = true
		C_Timer.After(0, function()
			rosterNext = false
			RunAll(onRoster, "groupe changé")
		end)
	end
	C_Timer.After(ROSTER_CALM, function()
		-- un autre changement est venu : il attend, sauf si la rafale dure depuis trop longtemps
		if wave == rosterWave or (burstStart and GetTime() - burstStart >= ROSTER_MAX) then
			burstStart = nil
			RunAll(onSettled, "groupe stable")
		end
	end)
end)

----------------------------------------------------------------------------------------------------
-- Démarrage
----------------------------------------------------------------------------------------------------
local function FillDefaults(db)
	for key, value in pairs(Z.defaults) do
		if db[key] == nil or type(db[key]) ~= type(value) then
			db[key] = type(value) == "table" and CopyTable(value) or value
		end
	end
	if db.rangeAlpha <= 1 then db.rangeAlpha = Z.defaults.rangeAlpha end -- ancien format (fraction)
end

-- "1.10.2" -> 11002, pour comparer deux versions
function Z.VersionNumber(text)
	local major, minor, patch = tostring(text):match("^(%d+)%.(%d+)%.?(%d*)")
	if not major then return 0 end
	return tonumber(major) * 10000 + tonumber(minor) * 100 + (tonumber(patch) or 0)
end

-- Réglages venus d'une version plus ancienne
local function Migrate(db)
	local last, now = db.lastVersion and Z.VersionNumber(db.lastVersion), Z.VersionNumber(Z.version)
	if db.locked ~= nil then -- avant la 1.7.0 : une simple case « verrouiller »
		if db.locked == true and db.lockMode == nil then db.lockMode = "LOCKED" end
		db.locked = nil
	end
	-- 1.7.0 : la barre de mana passe à « Tous » par défaut, une seule fois, pour ceux qui gardaient l'ancien défaut
	if last and last < 10700 and db.manaBars == "HEALERS" then db.manaBars = "ALL" end
	-- Visite guidée coupée sur la carte « Placer les cadres » (/reload, déconnexion) : le déplacement des cadres que
	-- le joueur avait choisi revient, sauf s'il en a pris un autre pendant la carte (Tutorial.lua). Champ hors de
	-- Z.defaults : jamais partagé, jamais copié dans un profil.
	if db.lockBeforeTutorial then
		if db.lockMode == "FREE" then db.lockMode = db.lockBeforeTutorial end
		db.lockBeforeTutorial = nil
	end
	-- 1.27.0 : les icônes ont une nouvelle place en Barre, Carré et Bandeau (Z.shapes, Themes.lua). Un ancien
	-- décalage les pousserait au mauvais endroit : il repart de zéro, une seule fois, pour ces trois formes
	-- (à la première connexion avec la 1.27.0 ou plus récente).
	if last and last < 12700 and now >= 12700
		and type(db.placement) == "table" then
		local reset = { BAR = { "hots", "debuffs" }, SQUARE = { "hots", "debuffs" }, BANNER = { "hots", "debuffs", "text" } }
		for shape, keys in pairs(reset) do
			local saved = db.placement[shape]
			if type(saved) == "table" then
				for _, key in ipairs(keys) do saved[key] = nil end
				if not next(saved) then db.placement[shape] = nil end
			end
		end
	end
	-- 1.29.1 : la règle des 5 secondes devient éteinte au départ (demande de l'auteur). La 1.29.0 l'avait allumée
	-- pour tous sans que le joueur la choisisse : elle repart du nouveau défaut, une seule fois.
	if last and last == 12900 and now >= 12901 then
		db.fiveSecondRule = nil
	end
	-- 1.33.7 : un buff est proposé 2 minutes avant sa fin (demande de l'auteur). Le départ était 0 de la 1.33.0 à la
	-- 1.33.6 : un joueur resté sur 0 passe au nouveau départ, une seule fois ; un autre choix est gardé.
	if last and last < 13307 and now >= 13307
		and db.buffRefresh == 0 then
		db.buffRefresh = nil
	end
	-- 1.44.0 : « Partager mes recharges » devient éteint au départ (demande de l'auteur : au joueur de choisir).
	-- Les 1.42.1 à 1.43.1 l'allumaient pour tous : il repart du nouveau défaut, une seule fois.
	if last and last >= 14201 and last < 14400
		and now >= 14400 then
		db.cooldownShare = nil
	end
	-- 1.44.0 : plus de profil « Arène » (WoW Forever n'a pas d'arène JcJ) : ses anciennes règles s'effacent
	if type(db.autoProfiles) == "table" then
		for _, rules in pairs(db.autoProfiles) do
			if type(rules) == "table" then rules.ARENA = nil end
		end
	end
end

-- Position par personnage. Le premier personnage connecté après la 1.7.0 garde l'ancienne position commune.
local function LoadCharacter(db)
	LyoruneCharDB = LyoruneCharDB or {}
	local char = LyoruneCharDB
	for key, value in pairs(Z.charDefaults) do
		if type(db[key]) == "table" and char[key] == nil then char[key] = db[key] end
		db[key] = nil
		if type(char[key]) ~= "table" then char[key] = CopyTable(value) end
	end
	char.optionChapter = nil -- avant la 1.26.0 : dernier chapitre des options, plus sauvé (Accueil à chaque connexion)
	Z.char = char
end

-- Textes des annonces proposés à un joueur dont le jeu n'est pas en français (il peut les réécrire)
Z.englishTexts = {
	manaText = "Low mana: {mana}%! Let me drink.",
	regenText = "Mana is back ({mana}%), ready to go!",
	resText = "Resurrecting {nom}.",
}

Z:On("ADDON_LOADED", function(name)
	if name ~= ADDON then return end
	LyoruneDB = LyoruneDB or {}
	if GetLocale() ~= "frFR" then
		for key, text in pairs(Z.englishTexts) do
			if LyoruneDB[key] == nil then LyoruneDB[key] = text end
		end
	end
	Migrate(LyoruneDB)
	FillDefaults(LyoruneDB)
	LoadCharacter(LyoruneDB)
	Z.db = LyoruneDB
	Z:SetLanguage()
	Z.UI.ApplySkin()
end)

Z:On("PLAYER_LOGIN", function()
	if not Z:CheckGame() then return end -- journal d'erreurs + contrôle de compatibilité (Log.lua)
	Z:BuildData()
	Z:CreateFrames()
	Z:MigrateMacros(false) -- macros écrites sur un clic avant la 1.6.0 : rangées dans la bibliothèque
	Z:ApplyClicks()
	Z:StartBarMacros()
	Z:RefreshAlerts()
	Z:StartComm()

	if not Z.db.tutorialDone then -- premier lancement : l'assistant (trois questions), puis la visite guidée
		C_Timer.After(3, function()
			if Z.db.wizardDone then Z:StartTutorial() else Z:StartWizard() end
		end)
	elseif Z.db.lastVersion ~= Z.version and Z.db.showNews then
		C_Timer.After(4, function() Z:ShowNews() end)
	end
	Z.db.lastVersion = Z.version

	-- Cohabitation : Lyorune ne modifie ni ne masque les cadres des autres addons. On prévient une seule fois.
	local others = {}
	for _, name in ipairs({ "ElvUI", "VuhDo", "HealBot", "Grid2", "Cell" }) do
		if C_AddOns.IsAddOnLoaded(name) then others[#others + 1] = name end
	end
	if #others > 0 and not Z.db.coexistHint then
		Z.db.coexistHint = true
		Z:Print(table.concat(others, ", ") .. Z.L[" affiche aussi des cadres de groupe. Les deux fonctionnent ensemble ; pour éviter les doublons, désactivez les cadres de groupe et de raid dans ses options."])
	end
end)

-- Sorts appris, changement de spécialisation ou de talents : Lyorune relit ce que le joueur sait faire
-- et repose ses clics, sans /reload (à la fin du combat si besoin).
local function SpellsChanged()
	if not Z.header then return end
	Z:BuildData()
	Z:ApplyClicks()
	Z:QueueNewSpells()
end
for _, event in ipairs({ "SPELLS_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE" }) do
	Z:On(event, SpellsChanged)
end

-- Remet tous les réglages d'origine (sauf la position, le journal d'erreurs et le tutoriel)
function Z:ResetAll()
	for key, value in pairs(Z.defaults) do
		if not Z.private[key] then
			Z.db[key] = type(value) == "table" and CopyTable(value) or value
		end
	end
	Z:BuildData() -- repropose les clics de la classe
	Z:Refresh()
	Z:ApplyClicks()
	Z:RefreshAlerts()
end

----------------------------------------------------------------------------------------------------
-- Commandes
----------------------------------------------------------------------------------------------------
SLASH_LYORUNE1, SLASH_LYORUNE2 = "/lyorune", "/lyo"
SlashCmdList.LYORUNE = function(msg) Z:Try("commande /lyorune", Z.Command, msg) end

function Z.Command(msg)
	msg = (msg or ""):match("^%s*(.-)%s*$")
	-- « épingler » est comparé tel quel : lower() ne sait pas mettre en minuscules une lettre accentuée
	local pinWord, pinName = msg:match("^(%S+)%s*(.-)$")
	local pin = pinWord == "épingler" or pinWord == "Épingler" or pinWord and (pinWord:lower() == "epingler" or pinWord:lower() == "pin")
	msg = msg:lower()
	if msg == "erreurs" or msg == "erreur" or msg == "log" then return Z:ShowLog() end
	if msg == "diag" then return Z:Diagnose() end
	if msg == "bug" then return Z:ShowBug() end
	if msg == "position" then return Z:DiagnosePosition() end
	if msg == "auras" then return Z.DiagnoseAuras() end
	if not Z.header then return end -- Lyorune n'a pas pu démarrer : seuls le journal et le diagnostic répondent
	if msg == "tuto" or msg == "tutoriel" or msg == "aide" then
		Z:StartTutorial()
	elseif msg == "assistant" or msg == "wizard" then
		Z:StartWizard()
	elseif msg == "verrou" or msg == "lock" then
		Z.db.lockMode = Z.db.lockMode == "LOCKED" and "FREE" or "LOCKED"
		Z:Refresh()
		Z:Print(Z.db.lockMode == "LOCKED" and Z.L["position verrouillée."] or Z.L["position déverrouillée : faites glisser une étiquette « Groupe »."])
	elseif msg == "reset" then
		for key, value in pairs(Z.charDefaults) do Z.char[key] = CopyTable(value) end
		Z:Refresh()
		Z:Print(Z.L["position réinitialisée."])
	elseif pin then
		Z:PinCommand(pinName) -- le nom garde ses majuscules
	elseif pinWord and (pinWord:lower() == "pourmoi" or pinWord:lower() == "mine") then
		Z:AssignCommand(pinName) -- répartition entre soigneurs : ajoute ou retire un de mes joueurs
	elseif msg == "repartir" or msg == "répartir" or msg == "assign" then
		Z:OpenAssign()
	elseif msg == "repartir buffs" or msg == "répartir buffs" or msg == "assign buffs" then
		Z:OpenBuffAssign()
	elseif msg == "porteur" or msg:match("^porteur ") or msg == "bearer" or msg:match("^bearer ") then
		Z:BuffTargetCommand(pinName) -- le nom garde ses majuscules
	elseif msg == "sorts" or msg == "spells" then
		Z:SpellsCommand()
	elseif msg == "buffs" then
		Z:BuffsCommand()
	elseif msg == "groupe" or msg == "group" then
		Z:PrintSyncMembers()
	elseif msg == "annuler" or msg == "undo" then
		Z:Print(select(2, Z:UndoImport()))
	elseif msg == "test" then
		Z:TogglePreview()
	elseif msg == "cadres" or msg == "frames" then
		Z:ToggleFramesShown()
	elseif msg == "mesure" or msg == "perf" or msg == "measure" then
		Z:ShowMeasure()
	elseif msg == "nouveautes" or msg == "nouveautés" or msg == "news" then
		Z:ShowNews()
	else
		Z:ToggleOptions()
	end
end

function Lyorune_OnAddonCompartmentClick()
	if Z.header then Z:ToggleOptions() end
end
