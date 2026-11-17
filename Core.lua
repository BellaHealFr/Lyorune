-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Cadres de soin pour WoW Forever
-- Core.lua : réglages, événements, commandes. Tout le reste s'appuie sur ce fichier.

local ADDON, Z = ...
_G.Lyorune = Z

Z.version = (C_AddOns and C_AddOns.GetAddOnMetadata(ADDON, "Version")) or "1.6.0"
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
	layout = "GROUP",          -- rangement : par groupe de raid ou par rôle
	roleOrder = "TANK,HEALER,DAMAGER", -- ordre des rôles quand le rangement est « par rôle »
	horizontal = false,        -- false : groupes en colonnes, true : en lignes
	showSolo = true,           -- afficher mon cadre quand je suis seul
	visibility = "ALWAYS",     -- afficher les cadres : en permanence, ou seulement en combat
	showTanks = false,         -- cadre séparé pour les tanks
	showPets = false,          -- cadre séparé pour les familiers
	autoShrink = false,        -- réduire les cases en grand raid
	hideBlizzard = false,      -- masquer les cadres de groupe du jeu
	locked = false,
	frameAlpha = 100,          -- opacité générale, en %
	pos = { "CENTER", -320, 60 },
	tankPos = { "CENTER", -320, 200 },
	petPos = { "CENTER", -320, -160 },
	minimapButton = true,      -- bouton au bord de la mini-carte
	minimapAngle = 215,        -- sa place autour de la mini-carte, en degrés

	-- Apparence
	theme = "PURE", texture = "THEME",
	color = "CLASS",           -- couleur des barres : classe, ou vie restante
	text = "DEFICIT",          -- texte de vie
	fontSize = 11,
	smooth = true,             -- barres animées
	brightness = 100,          -- luminosité des barres, en %
	highContrast = false,      -- mode contraste élevé
	rangeAlpha = 35,           -- opacité d'un joueur hors de portée, en %

	-- Indicateurs (chacun peut être coupé)
	showIncoming = true,       -- soins en route
	showAbsorb = true,         -- bouclier
	showThreat = true,         -- bordure rouge de menace
	showRole = true,           -- icône de rôle
	showMarker = true,         -- marqueur de raid
	showDispel = true,         -- cadre coloré de dissipation
	showHots = true, hotStyle = "ICONS",
	showDebuffs = true, debuffMode = "ALL",
	bossDebuffs = true,        -- affaiblissement important en grand
	lowHealth = true, lowHealthAt = 25,
	missingBuffs = true,       -- buff de groupe manquant (hors combat)
	manaBars = "HEALERS",      -- barre de mana : personne, soigneurs, tous
	showTooltip = true,

	-- Clics
	castOnDown = true,         -- lancer le sort dès l'appui
	actionBarMacros = false,   -- créer une macro du jeu par sort de mes clics, pour les barres de sorts (à la demande)
	autoRes = true,            -- le même clic relève un joueur mort
	externalClicks = false,    -- laisser Clique ou le clic-soin du jeu gérer les cases
	clicks = {},               -- clics de souris par classe : clicks.PRIEST["shift-1"] = "Rénovation" (PRIEST2 : 2e spécialisation)
	hoverKeys = {},            -- touches au survol par classe : hoverKeys.PRIEST[1] = { key = "F", spell = "Rénovation" }
	clicksPerSpec = true,      -- des clics et des touches propres à chaque spécialisation (groupe de talents)
	macros = {},               -- ma bibliothèque de macros, par classe : macros.PRIEST[1] = { name = "...", body = "..." }
	macroAutoTarget = true,    -- une commande de macro sans cible vise la case

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

	-- Divers
	language = "AUTO",
	showNews = true,           -- fenêtre des nouveautés après une mise à jour
	versionNotice = true,      -- prévenir si un membre du groupe a une version plus récente
	acceptConfigs = true,      -- accepter qu'un joueur me propose sa configuration
	showRunes = true,          -- inscription runique animée au bas de la fenêtre d'options
	errorNotice = true,        -- message discret (une fois par session) quand Lyorune rencontre une erreur
	tutorialDone = false,
}

Z.limits = {
	width = { 50, 180, 2 }, height = { 24, 90, 2 }, spacing = { 0, 12, 1 }, fontSize = { 8, 16, 1 },
	frameAlpha = { 30, 100, 5 }, brightness = { 40, 100, 5 }, rangeAlpha = { 10, 100, 5 },
	lowHealthAt = { 10, 60, 5 }, manaThreshold = { 5, 80, 5 }, regenThreshold = { 50, 100, 5 },
}

Z.choices = {
	layout = { { "GROUP", "Par groupe" }, { "ROLE", "Par rôle" } },
	roleOrder = {
		{ "TANK,HEALER,DAMAGER", "Tank, soin, dégâts" }, { "TANK,DAMAGER,HEALER", "Tank, dégâts, soin" },
		{ "HEALER,TANK,DAMAGER", "Soin, tank, dégâts" }, { "HEALER,DAMAGER,TANK", "Soin, dégâts, tank" },
		{ "DAMAGER,TANK,HEALER", "Dégâts, tank, soin" }, { "DAMAGER,HEALER,TANK", "Dégâts, soin, tank" },
	},
	horizontal = { { false, "En colonnes" }, { true, "En lignes" } },
	visibility = { { "ALWAYS", "Toujours" }, { "COMBAT", "En combat seulement" } },
	color = { { "CLASS", "Classe" }, { "HEALTH", "Vie restante" } },
	text = { { "DEFICIT", "Vie manquante" }, { "PERCENT", "Pourcentage" }, { "NONE", "Aucun" } },
	hotStyle = { { "ICONS", "Icônes" }, { "BARS", "Barres fines" } },
	debuffMode = { { "ALL", "Tous" }, { "DISPEL", "Dissipables par moi" } },
	manaBars = { { "OFF", "Personne" }, { "HEALERS", "Soigneurs" }, { "ALL", "Tous" } },
	alertChannel = { { "SAY", "Dire" }, { "GROUP", "Groupe ou raid" } },
	language = { { "AUTO", "Automatique" }, { "frFR", "Français" }, { "enUS", "English" } },
}

-- Réglages propres à l'ordinateur ou au personnage : ni partagés, ni réinitialisés avec le reste
Z.private = { pos = true, tankPos = true, petPos = true, minimapAngle = true, tutorialDone = true, language = true,
	macros = true } -- mes macros : jamais partagées, jamais effacées par la réinitialisation

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
		fn()
	end
end

Z:On("PLAYER_REGEN_ENABLED", function()
	for key, fn in pairs(pending) do
		pending[key] = nil
		fn()
	end
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
	FillDefaults(LyoruneDB)
	Z.db = LyoruneDB
	Z:SetLanguage()
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

	if not Z.db.tutorialDone then
		C_Timer.After(3, function() Z:StartTutorial() end)
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
	msg = (msg or ""):lower():match("^%s*(.-)%s*$")
	if msg == "erreurs" or msg == "erreur" or msg == "log" then return Z:ShowLog() end
	if msg == "diag" then return Z:Diagnose() end
	if msg == "bug" then return Z:ShowBug() end
	if msg == "position" then return Z:DiagnosePosition() end
	if not Z.header then return end -- Lyorune n'a pas pu démarrer : seuls le journal et le diagnostic répondent
	if msg == "tuto" or msg == "tutoriel" or msg == "aide" then
		Z:StartTutorial()
	elseif msg == "verrou" or msg == "lock" then
		Z.db.locked = not Z.db.locked
		Z:Refresh()
		Z:Print(Z.db.locked and Z.L["position verrouillée."] or Z.L["position déverrouillée : faites glisser la poignée « Lyorune »."])
	elseif msg == "reset" then
		for _, key in ipairs({ "pos", "tankPos", "petPos" }) do Z.db[key] = CopyTable(Z.defaults[key]) end
		Z:Refresh()
		Z:Print(Z.L["position réinitialisée."])
	elseif msg == "test" then
		Z:TogglePreview()
	elseif msg == "nouveautes" or msg == "nouveautés" or msg == "news" then
		Z:ShowNews()
	else
		Z:ToggleOptions()
	end
end

function Lyorune_OnAddonCompartmentClick()
	if Z.header then Z:ToggleOptions() end
end
