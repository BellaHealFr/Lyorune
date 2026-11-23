-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Clicks.lua : lancer un sort sur un joueur depuis sa case, à la souris ou au clavier.
--
-- CLICS DE SOURIS. Un clic est identifié par une clé : touches de modification + numéro du bouton.
--   "1" clic gauche, "2" clic droit, "3" clic milieu, "4" et "5" boutons latéraux
--   "shift-1" Maj + clic gauche, "ctrl-shift-2" Ctrl + Maj + clic droit, "alt-ctrl-shift-3"...
--   Les modifications s'écrivent toujours dans l'ordre du jeu : alt, ctrl, shift.
--   La valeur est un nom de sort, "@target" (cibler), "@menu" (menu du joueur), "@stop" (arrêter
--   l'incantation) ou "@macro:Nom" (une macro de ma bibliothèque, voir Macros.lua).
-- BIJOUX. Chaque raccourci peut utiliser un bijou (emplacement 13, 14 ou les deux) juste avant son sort :
--   clickTrinkets.PRIEST["shift-1"] = 1 (bijou du haut), 2 (bijou du bas) ou 3 (les deux). Une touche au survol
--   a pour identifiant « key:F ». Le bijou n'est utilisé que sur un joueur vivant.
-- CLIC POUR LANCER DU JEU. Le jeu peut lancer ses propres sorts au clic sur toutes les cases de soin, celles de
--   Lyorune comprises. Lyorune lit ces raccourcis (sans jamais les modifier) et signale ceux qui prennent la même
--   combinaison qu'un de ses clics (option « clickConflictAlert »).
-- TOUCHES AU SURVOL. Une touche du clavier (avec ou sans Alt, Ctrl, Maj), un bouton de souris à partir du 6e ou
--   la molette lance un sort sur la case que survole la souris. Elle ne remplace la touche habituelle que
--   pendant le survol d'une case. Leur nombre n'est pas limité.
-- UN SEUL ÉCRAN. L'onglet Clics montre clics et touches dans une même liste (Z:Bindings) : un raccourci,
--   « déclencheur », est { kind = "click", key = "ctrl-1" } ou { kind = "key", key = "CTRL-F" }.
-- SPÉCIALISATIONS. Sur WoW Forever, un personnage a deux groupes de talents. Avec l'option « clicksPerSpec »,
--   chacun a ses clics et ses touches : clicks.PRIEST pour le premier, clicks.PRIEST2 pour le second (copie du
--   premier au premier passage). Changer de talents change les clics tout seul.
-- Les clics n'existent que sur les cases de Lyorune : impossible de lancer un sort en cliquant dans le décor.

local _, Z = ...

Z.clickButtons = {
	{ "1", "Clic gauche" },
	{ "2", "Clic droit" },
	{ "3", "Clic milieu" },
	{ "4", "Bouton 4" },
	{ "5", "Bouton 5" },
}
-- Toutes les combinaisons possibles, dans l'ordre où le jeu les écrit (et où la liste les range)
Z.clickModifiers = {
	{ "", "Seul" },
	{ "shift-", "Maj" },
	{ "ctrl-", "Ctrl" },
	{ "alt-", "Alt" },
	{ "ctrl-shift-", "Ctrl + Maj" },
	{ "alt-shift-", "Alt + Maj" },
	{ "alt-ctrl-", "Alt + Ctrl" },
	{ "alt-ctrl-shift-", "Alt + Ctrl + Maj" },
}
local modifierRank = {}
for rank, entry in ipairs(Z.clickModifiers) do modifierRank[entry[1]] = rank end

-- Une clé de clic valable : "1" à "5", précédé d'une combinaison connue. Renvoie la combinaison et le bouton.
function Z.ParseClickKey(key)
	if type(key) ~= "string" then return nil end
	local modifier, button = key:match("^([%a%-]*)([1-5])$")
	if modifier and modifierRank[modifier] then return modifier, button end
end

-- Une touche valable pour le jeu : "F", "CTRL-SHIFT-F", "BUTTON6", "MOUSEWHEELUP", "ALT-," ... Jamais de
-- guillemet, d'antislash, de barre ni d'espace : la touche est écrite dans du code sécurisé et dans les codes de partage.
function Z.ValidKey(key)
	return type(key) == "string" and #key > 0 and #key <= 40 and key:match("^[%w%p]+$") ~= nil and not key:find('["\\|]')
end
-- Groupe de talents actif (1 ou 2). Le jeu sans double spécialisation répond toujours 1.
function Z:SpecGroup()
	local info = C_SpecializationInfo
	local ok, group = pcall(function() return info and info.GetActiveSpecGroup and info.GetActiveSpecGroup() end)
	return (ok and type(group) == "number" and group > 1) and group or 1
end

-- Nom du jeu de clics en cours : « PRIEST », ou « PRIEST2 » dans la seconde spécialisation
function Z:ClickSet()
	local group = Z.db.clicksPerSpec and Z:SpecGroup() or 1
	return group == 1 and Z.class or Z.class .. group
end

-- Tous les jeux de clics de ma classe
function Z:ClickSets()
	return { Z.class, Z.class .. "2" }
end

local function Set(store)
	local set = Z:ClickSet()
	if store[set] == nil and set ~= Z.class and store[Z.class] then
		store[set] = CopyTable(store[Z.class]) -- seconde spécialisation : on part des clics de la première
	end
	store[set] = store[set] or {}
	return store[set]
end

function Z:GetClicks()
	return Set(Z.db.clicks)
end

function Z:GetHoverKeys()
	return Set(Z.db.hoverKeys)
end

-- Bijoux des raccourcis de la spécialisation active (voir BIJOUX en haut du fichier)
function Z:GetTrinkets()
	Z.db.clickTrinkets = Z.db.clickTrinkets or {}
	return Set(Z.db.clickTrinkets)
end

Z.TRINKET_SLOTS = { 13, 14 } -- bijou 1 (masque 1) et bijou 2 (masque 2)

----------------------------------------------------------------------------------------------------
-- VARIANTES D'UN RACCOURCI (1.39.0). Un raccourci peut lancer autre chose selon la situation, sur la même ligne :
--   enemy : sur un ennemi (case Cible, Focalisation, allié sous Contrôle mental). Le bouton sécurisé du jeu passe
--           tout seul sur son « bouton ennemi » (harmbutton) quand l'unité peut être attaquée, au moment du clic,
--           en combat aussi ;
--   pvp   : en champ de bataille et en arène. Lyorune pose ce sort à l'entrée du lieu (hors combat : on y entre
--           toujours hors combat ; sinon à la fin du combat) et remet l'autre à la sortie ;
--   tank  : sur un tank (1.39.1). Le code sécurisé ne connaît pas le rôle en combat : chaque case reçoit sa
--           propre version des raccourcis. Les cases d'un cadre que le jeu trie sur le rôle (cadre « Tanks », un
--           cadre par rôle en raid) la gardent toujours, en combat aussi : l'en-tête la recopie sur ses nouvelles
--           cases. Les autres cases la reçoivent hors combat selon le rôle de leur joueur, reposée à chaque
--           changement (rôle, groupe, joueur de la case) et à la fin du combat. Rôle inconnu ou secret : la base ;
--   ooc   : hors combat, un sort seulement. Le jeu choisit au clic : macro « /cast [nocombat] A; B ».
-- Ordre : ennemi, puis JcJ, puis tank, puis hors combat (sur un tank, la variante tank part aussi hors combat).
-- Rangement, par jeu de clics comme les bijoux : clickVariants.PRIEST["shift-1"] = { enemy = "...", pvp = "...",
-- tank = "...", ooc = "..." } (identifiant Z.TriggerId : « key:F » pour une touche). Rien de propre à une classe.
-- GARDE « AUCUN SOIN SUR UN ENNEMI » (réglage enemyGuard, allumé au départ) : un raccourci sans variante ennemie
-- ne fait rien sur un ennemi (le jeu peut sinon renvoyer le soin sur vous) ; Cibler, Menu et Arrêter l'incantation
-- marchent partout.
----------------------------------------------------------------------------------------------------
Z.variantKinds = {
	{ "enemy", "Sur un ennemi" },
	{ "pvp", "En JcJ" },
	{ "tank", "Sur un tank" },
	{ "ooc", "Hors combat" },
}

-- Variantes des raccourcis de la spécialisation active
function Z:GetVariants()
	Z.db.clickVariants = Z.db.clickVariants or {}
	return Set(Z.db.clickVariants)
end

-- Variantes d'un raccourci : { enemy = ..., pvp = ..., ooc = ... } (table vide s'il n'en a pas)
function Z:VariantsOf(trigger)
	return Z:GetVariants()[Z.TriggerId(trigger)] or {}
end

-- Une valeur acceptée pour cette sorte de variante : « hors combat » ne prend qu'un sort (une macro ne peut pas en
-- lancer une autre)
function Z.ValidVariant(kind, value)
	if type(value) ~= "string" or value == "" then return false end
	if kind == "ooc" then return Z.TakesTrinket(value) and not Z.IsMacro(value) and not Z.MacroRef(value) end
	return kind == "enemy" or kind == "pvp" or kind == "tank"
end

-- Pose (ou retire, value nil) la variante « kind » d'un raccourci
function Z:SetVariant(trigger, kind, value, noApply)
	local list, id = Z:GetVariants(), Z.TriggerId(trigger)
	if value ~= nil and not Z.ValidVariant(kind, value) then return end
	local entry = list[id] or {}
	entry[kind] = value
	list[id] = next(entry) and entry or nil
	if not noApply then Z:ApplyClicks() end
end

-- Identifiant d'un raccourci dans la table des bijoux : « shift-1 » pour un clic, « key:F » pour une touche
function Z.TriggerId(trigger)
	return trigger.kind == "click" and trigger.key or "key:" .. trigger.key
end

-- Une action qui lance quelque chose sur le joueur : on peut y joindre un bijou (pas à « cibler », « menu »...)
function Z.TakesTrinket(value)
	return type(value) == "string" and value ~= "" and value ~= "@target" and value ~= "@menu" and value ~= "@stop"
end

-- Le masque contient-il le bijou « index » (1 ou 2) ?
function Z.MaskHas(mask, index)
	return math.floor((mask or 0) / index) % 2 == 1
end

function Z:HasTrinket(trigger, index)
	return Z.MaskHas(Z:GetTrinkets()[Z.TriggerId(trigger)], index)
end

function Z:ToggleTrinket(trigger, index)
	local list, id = Z:GetTrinkets(), Z.TriggerId(trigger)
	local mask = list[id] or 0
	mask = Z.MaskHas(mask, index) and mask - index or mask + index
	list[id] = mask > 0 and mask or nil
	Z:ApplyClicks()
end

-- Bouton « Copier l'autre spécialisation » : mes clics et touches deviennent ceux de l'autre groupe de talents
function Z:CopyOtherSpec()
	local set = Z:ClickSet()
	local other = set == Z.class and Z.class .. "2" or Z.class
	Z.db.clicks[set] = CopyTable(Z.db.clicks[other] or {})
	Z.db.hoverKeys[set] = CopyTable(Z.db.hoverKeys[other] or {})
	Z:GetTrinkets()
	Z.db.clickTrinkets[set] = CopyTable(Z.db.clickTrinkets[other] or {})
	Z:GetVariants()
	Z.db.clickVariants[set] = CopyTable(Z.db.clickVariants[other] or {})
	Z:ApplyClicks()
end

-- Bouton « Reprendre les clics proposés pour ma classe » : seuls les clics de la spécialisation en cours sont
-- remplacés. Dans la seconde, ceux de la première restent tels quels.
function Z:ResetClassClicks()
	local set = Z:ClickSet()
	local first = set ~= Z.class and Z.db.clicks[Z.class]
	Z.db.clicks[Z.class] = nil
	Z:BuildData() -- recrée les clics proposés dans Z.db.clicks[Z.class]
	if set ~= Z.class then
		local proposed = Z.db.clicks[Z.class]
		if proposed then Z.db.clicks[set] = CopyTable(proposed) end -- grimoire pas encore chargé : rien ne change
		Z.db.clicks[Z.class] = first or nil
	end
	Z:ApplyClicks()
end

-- Nom lisible d'une touche de modification, dans les clics ("shift") comme dans les touches ("SHIFT")
local MODIFIER_NAMES = { alt = "Alt", ctrl = "Ctrl", shift = "Maj", meta = "Cmd" }

-- Texte lisible d'une clé : "ctrl-shift-1" -> "Ctrl + Maj + Clic gauche"
function Z:ClickLabel(key)
	local L = Z.L
	local modifier, button = Z.ParseClickKey(key)
	if not modifier then return tostring(key) end
	local parts = {}
	for name in modifier:gmatch("(%a+)%-") do parts[#parts + 1] = L[MODIFIER_NAMES[name]] end
	parts[#parts + 1] = L[Z.clickButtons[tonumber(button)][2]]
	return table.concat(parts, " + ")
end

-- Noms lisibles des touches spéciales ; les autres restent telles que le jeu les nomme ("F", "NUMPAD1", ",")
local KEY_NAMES = {
	MOUSEWHEELUP = "Molette haut", MOUSEWHEELDOWN = "Molette bas", SPACE = "Espace", TAB = "Tab",
	ENTER = "Entrée", BACKSPACE = "Retour arrière", DELETE = "Suppr", INSERT = "Inser", HOME = "Début", END = "Fin",
	PAGEUP = "Page haut", PAGEDOWN = "Page bas", UP = "Haut", DOWN = "Bas", LEFT = "Gauche", RIGHT = "Droite",
}

-- Texte lisible d'une touche : "CTRL-SHIFT-F" -> "Ctrl + Maj + F", "BUTTON6" -> "Bouton 6"
function Z:KeyLabel(key)
	local L = Z.L
	if not Z.ValidKey(key) then return tostring(key) end
	local parts, rest = {}, key
	while true do
		local name, after = rest:match("^(%u+)%-(.+)$")
		if not (name and MODIFIER_NAMES[name:lower()]) then break end
		parts[#parts + 1] = L[MODIFIER_NAMES[name:lower()]]
		rest = after
	end
	local number = rest:match("^BUTTON(%d+)$")
	parts[#parts + 1] = number and L["Bouton %s"]:format(number) or (KEY_NAMES[rest] and L[KEY_NAMES[rest]]) or rest
	return table.concat(parts, " + ")
end

-- Texte lisible d'un déclencheur, clic ou touche
function Z:TriggerLabel(trigger)
	if trigger.kind == "click" then return Z:ClickLabel(trigger.key) end
	return Z:KeyLabel(trigger.key)
end

-- Tous mes raccourcis de la spécialisation active, dans l'ordre de l'onglet Clics : les clics (par bouton, puis
-- par combinaison), puis les touches dans l'ordre où je les ai ajoutées.
-- { { kind = "click", key = "shift-1", value = "Rénovation" }, { kind = "key", key = "F", value = "...", index = 1 } }
function Z:Bindings()
	local list = {}
	local clicks, trinkets, variants = Z:GetClicks(), Z:GetTrinkets(), Z:GetVariants()
	for _, button in ipairs(Z.clickButtons) do
		for _, modifier in ipairs(Z.clickModifiers) do
			local key = modifier[1] .. button[1]
			local value = clicks[key]
			if value and value ~= "" then
				list[#list + 1] = { kind = "click", key = key, value = value, trinkets = trinkets[key], variants = variants[key] }
			end
		end
	end
	for index, entry in ipairs(Z:GetHoverKeys()) do
		if entry.key then
			local id = "key:" .. entry.key
			list[#list + 1] = { kind = "key", key = entry.key, value = entry.spell or "", index = index, trinkets = trinkets[id], variants = variants[id] }
		end
	end
	return list
end

-- Ce que lance un déclencheur (nil s'il est libre)
function Z:GetBinding(trigger)
	if trigger.kind == "click" then return Z:GetClicks()[trigger.key] end
	for _, entry in ipairs(Z:GetHoverKeys()) do
		if entry.key == trigger.key then return entry.spell end
	end
end

-- Pose « value » sur un déclencheur (nil ou "" : retire le raccourci). Une touche déjà présente garde sa place.
function Z:SetBinding(trigger, value, noApply)
	if value == "" then value = nil end
	if not Z.TakesTrinket(value) then Z:GetTrinkets()[Z.TriggerId(trigger)] = nil end -- raccourci retiré : bijoux retirés
	if not value then Z:GetVariants()[Z.TriggerId(trigger)] = nil end -- et ses variantes
	if trigger.kind == "click" then
		if not Z.ParseClickKey(trigger.key) then return end
		Z:GetClicks()[trigger.key] = value
	else
		if not Z.ValidKey(trigger.key) then return end
		local keys = Z:GetHoverKeys()
		for index = #keys, 1, -1 do
			if keys[index].key == trigger.key then
				if value then keys[index].spell = value else table.remove(keys, index) end
				if not noApply then Z:ApplyClicks() end
				return
			end
		end
		if value then keys[#keys + 1] = { key = trigger.key, spell = value } end
	end
	if not noApply then Z:ApplyClicks() end
end

-- Change le déclencheur d'un raccourci. Si le nouveau était déjà pris, les deux actions sont échangées :
-- rien n'est perdu.
function Z:MoveBinding(from, to)
	if from.kind == to.kind and from.key == to.key then return end
	local moving, other = Z:GetBinding(from), Z:GetBinding(to)
	if to.kind == "key" and not Z.ValidKey(to.key) or to.kind == "click" and not Z.ParseClickKey(to.key) then return end
	-- les bijoux suivent leur sort
	local trinkets = Z:GetTrinkets()
	local fromId, toId = Z.TriggerId(from), Z.TriggerId(to)
	local fromMask, toMask = trinkets[fromId], trinkets[toId]
	-- les variantes aussi
	local variants = Z:GetVariants()
	local fromVariants, toVariants = variants[fromId], variants[toId]
	-- une touche garde sa place dans la liste : on la renomme au lieu de la retirer puis de l'ajouter
	if from.kind == "key" and to.kind == "key" and not other then
		for _, entry in ipairs(Z:GetHoverKeys()) do
			if entry.key == from.key then entry.key = to.key end
		end
		trinkets[fromId], trinkets[toId] = nil, fromMask
		variants[fromId], variants[toId] = nil, fromVariants
		Z:MoveClickStats(fromId, toId)
		return Z:ApplyClicks()
	end
	Z:SetBinding(from, other, true)
	Z:SetBinding(to, moving, true)
	trinkets[fromId] = Z.TakesTrinket(other) and toMask or nil
	trinkets[toId] = Z.TakesTrinket(moving) and fromMask or nil
	variants[fromId] = other and toVariants or nil
	variants[toId] = moving and fromVariants or nil
	Z:MoveClickStats(fromId, toId)
	Z:ApplyClicks()
end

----------------------------------------------------------------------------------------------------
-- STATISTIQUES DE MES CLICS (réglage clickStats, éteint au départ). Chaque clic et chaque touche au survol qui part
-- depuis une case est compté, après le clic du bouton sécurisé (Frames.lua, NoteClick) : le sort part comme
-- avant. Rien de secret n'est lu, seulement le bouton et les touches Alt, Ctrl, Maj. On compte les clics, pas les
-- sorts réussis. Un seul appel par appui : la souris et les touches au survol ont le même sens (C11).
-- Par personnage et par jeu de clics : LyoruneCharDB.clickStats.PRIEST = { since = date, lines = { ["shift-1"] =
-- { v = "Rénovation", n = 42 } } }. Le compte va au couple touche + sort : un autre sort sur la ligne repart de zéro.
----------------------------------------------------------------------------------------------------
local MOUSE_BUTTONS = { LeftButton = "1", RightButton = "2", MiddleButton = "3", Button4 = "4", Button5 = "5" }

-- Le raccourci qui vient de partir : son identifiant (Z.TriggerId) et ce qu'il lance
function Z:ClickedTrigger(button)
	if type(button) ~= "string" then return nil end
	local index = tonumber(button:match("^zh(%d+)$")) -- touche au survol : bouton virtuel « zh1 », « zh2 »...
	if index then
		local entry = Z:GetHoverKeys()[index]
		if entry and entry.key then return "key:" .. entry.key, entry.spell end
		return nil
	end
	local number = MOUSE_BUTTONS[button]
	if not number then return nil end
	local key = (IsAltKeyDown() and "alt-" or "") .. (IsControlKeyDown() and "ctrl-" or "")
		.. (IsShiftKeyDown() and "shift-" or "") .. number
	return key, Z:GetClicks()[key]
end

-- Les comptes du jeu de clics en cours (create : les crée s'il n'y en a pas encore)
local function StatsOf(create)
	local all = Z.char and Z.char.clickStats
	if not all then
		if not create or not Z.char then return nil end
		all = {}
		Z.char.clickStats = all
	end
	local set = Z:ClickSet()
	if not all[set] and create then all[set] = { since = time(), lines = {} } end
	return all[set]
end

function Z:CountClick(button)
	if not Z.db.clickStats or Z.db.externalClicks then return end
	local id, value = Z:ClickedTrigger(button)
	if not id or not value or value == "" then return end
	local lines = StatsOf(true).lines
	local line = lines[id]
	if not line or line.v ~= value then
		line = { v = value, n = 0 }
		lines[id] = line
	end
	line.n = line.n + 1
end

-- Nombre d'utilisations d'un raccourci avec ce qu'il lance aujourd'hui (0 si jamais, ou si le sort a changé)
function Z:ClickCount(trigger, value)
	local stats = StatsOf(false)
	local line = stats and stats.lines[Z.TriggerId(trigger)]
	return (line and line.v == value) and line.n or 0
end

-- Date du début des comptes du jeu de clics en cours, ou nil
function Z:ClickStatsSince()
	local stats = StatsOf(false)
	return stats and stats.since
end

-- Remise à zéro des comptes du jeu de clics en cours (l'autre spécialisation garde les siens)
function Z:ResetClickStats()
	local all = Z.char and Z.char.clickStats
	if all then all[Z:ClickSet()] = { since = time(), lines = {} } end
end

-- Deux raccourcis échangés ou une touche renommée : chaque sort garde son compte
function Z:MoveClickStats(fromId, toId)
	local stats = StatsOf(false)
	if stats then stats.lines[fromId], stats.lines[toId] = stats.lines[toId], stats.lines[fromId] end
end

-- Texte lisible de ce que fait un clic : sort, cibler, menu, ou macro (en jaune, en rouge si elle n'existe plus)
function Z:ActionText(value)
	local L = Z.L
	if value == "@target" then return L["Cibler"] end
	if value == "@menu" then return L["Menu du joueur"] end
	if value == "@stop" then return L["Arrêter l'incantation"] end
	local ref = Z.MacroRef(value)
	if ref then
		return (Z:FindMacro(ref) and "|cffffd060" or "|cffff6060") .. L["Macro"] .. "|r " .. ref
	end
	if Z.IsMacro(value) then return "|cffffd060" .. L["Macro"] .. "|r " .. (value:match("[^\n]*$") or "") end -- dernière ligne : le sort
	if Z.RankId(value) then return Z.RankLabel(value) end
	return value
end

-- Secondes de recharge d'un raccourci qui lance un sort (Cooldowns.lua), lisibles hors combat ; sinon nil
local function CooldownOf(value)
	if not (Z.SpellCooldownLeft and Z.TakesTrinket(value)) or Z.IsMacro(value) or Z.MacroRef(value) then return end
	local info = C_Spell.GetSpellInfo(Z.SpellOf(value))
	local id = info and info.spellID
	if id and not Z.IsSecret(id) then return Z.SpellCooldownLeft(id) end
end

-- Mes clics et touches au survol, dans l'ordre de l'onglet Clics : { { "Maj + Clic gauche", "Rénovation" }, ... }
-- Un sort en recharge porte ses secondes restantes (champ cooldown). Sert à l'infobulle d'une case.
function Z:ClickSummary()
	local list = {}
	for _, binding in ipairs(Z:Bindings()) do
		if binding.value ~= "" then
			local text = Z:ActionText(binding.value)
			if binding.trinkets and Z.TakesTrinket(binding.value) then text = text .. " + " .. Z.L["bijou"] end
			list[#list + 1] = { Z:TriggerLabel(binding), text, cooldown = CooldownOf(binding.value) }
			for _, kind in ipairs(Z.variantKinds) do -- ses variantes, en retrait
				local value = binding.variants and binding.variants[kind[1]]
				if value then list[#list + 1] = { "   " .. Z.L[kind[2]], Z:ActionText(value), cooldown = CooldownOf(value) } end
			end
		end
	end
	return list
end

-- Les macros du joueur (compte puis personnage), sans celles que Lyorune crée lui-même
function Z:GameMacros()
	local list = {}
	if not GetNumMacros then return list end
	local account, character = GetNumMacros()
	local first = MAX_ACCOUNT_MACROS or 120
	local function add(index)
		local name, icon = GetMacroInfo(index)
		if name and name ~= "" and name:sub(1, 4) ~= "Lyo:" then list[#list + 1] = { name = name, icon = icon, index = index } end
	end
	for index = 1, account do add(index) end
	for index = first + 1, first + character do add(index) end
	return list
end

function Z.IsMacro(value)
	return type(value) == "string" and value:sub(1, 1) == "/"
end

----------------------------------------------------------------------------------------------------
-- RANG CHOISI (1.38.0). Un raccourci lance « le plus haut » ou un rang fixe :
--   « Soins »  : le nom du sort, toujours le rang le plus haut appris (le jeu le baisse lui-même sur un joueur de
--                trop bas niveau) ; rien ne change pour les raccourcis d'avant ;
--   « #2054 »  : ce rang précis, lancé par son numéro. Un numéro que ce personnage ne connaît pas (code de
--                partage, autre personnage) part par le nom du sort, au rang le plus haut, et la ligne le dit.
-- Tout se lit dans le grimoire : rien à écrire par classe.
----------------------------------------------------------------------------------------------------
-- Numéro du rang fixe d'un raccourci, ou nil
function Z.RankId(value)
	local id = type(value) == "string" and value:match("^#(%d+)$")
	return id and tonumber(id) or nil
end

-- Ce que les fonctions du jeu (icône, bulle) acceptent pour ce raccourci : le numéro d'un rang fixe, sinon la valeur
function Z.SpellOf(value)
	return Z.RankId(value) or value
end

-- Ce rang précis est-il appris par ce personnage ?
function Z.KnowsRank(id)
	if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(id) then return true end
	return IsPlayerSpell ~= nil and IsPlayerSpell(id) == true
end

-- Texte du rang donné par le jeu (« Rang 2 »), ou "" (sort sans rang, texte pas encore chargé)
function Z.RankText(id)
	if not (C_Spell.GetSpellSubtext and id) then return "" end
	local ok, text = pcall(C_Spell.GetSpellSubtext, id)
	return ok and type(text) == "string" and text or ""
end

-- Ce que lance vraiment un raccourci : le numéro d'un rang fixe appris, sinon le nom ; puis le nom du sort,
-- et true si le rang fixe est inconnu de ce personnage
-- (« Choisir le rang des sorts » éteint : le rang choisi est gardé de côté, le nom part, au rang le plus haut)
function Z.CastOf(value)
	local id = Z.RankId(value)
	if not id then return value, value end
	local name = C_Spell.GetSpellName(id)
	if not Z.db.rankChoice then return name, name end
	if Z.KnowsRank(id) then return id, name end
	return name, name, true
end

-- Le sort écrit dans une macro : « Soins(Rang 2) » pour un rang fixe (texte du rang du jeu), le nom sinon
function Z.MacroSpell(value)
	local cast, name = Z.CastOf(value)
	if type(cast) ~= "number" then return cast end
	local rank = Z.RankText(cast)
	return rank ~= "" and ("%s(%s)"):format(name, rank) or name
end

-- Le rang d'un raccourci lisible sur sa ligne : « Soins supérieurs, rang 1 » ; en orange s'il est inconnu
function Z.RankLabel(value)
	local L = Z.L
	local cast, name, unknown = Z.CastOf(value)
	if not name then return "|cffff9933" .. value .. "|r" end
	if type(cast) ~= "number" and not unknown then return name end -- choix du rang éteint : le plus haut
	if unknown then return "|cffff9933" .. name .. ", " .. L["rang inconnu de ce personnage"] .. "|r" end
	local rank = Z.RankText(cast)
	return rank ~= "" and ("%s, %s"):format(name, rank:lower()) or name
end

-- Début de macro qui relève un joueur mort avec le même clic (option « résurrection automatique »)
local function ResPrefix()
	local res = Z.db.autoRes and Z.classRes[Z.class]
	if not res then return nil end
	local prefix = ""
	if res.combat and Z.Knows(res.combat) then
		prefix = "[@mouseover,help,dead,combat] " .. Z.SpellName(res.combat) .. "; "
	end
	if res[1] and Z.Knows(res[1]) then
		prefix = prefix .. "[@mouseover,help,dead] " .. Z.SpellName(res[1]) .. "; "
	end
	return prefix ~= "" and prefix or nil
end

-- Lignes de macro qui utilisent les bijoux du masque (1 : emplacement 13, 2 : 14, 3 : les deux), sur un vivant
function Z.TrinketLines(mask)
	local lines = ""
	for index, slot in ipairs(Z.TRINKET_SLOTS) do
		if Z.MaskHas(mask, index) then lines = lines .. ("/use [@mouseover,nodead] %d\n"):format(slot) end
	end
	return lines
end

-- Rangs fixes posés par ApplyClicks, que chaque case peut baisser selon le niveau de son joueur (Z:FitRanks) :
-- { { key = attribut, id = rang choisi }, ... } pour un attribut « spell » ; { key = attribut, parts = morceaux } pour
-- une macro : ses morceaux sont du texte ou le numéro d'un rang choisi (une macro hors combat en a deux).
-- Une liste par version des raccourcis (rankLists.base, rankLists.tank) ; fixedRanks : celle qu'on remplit.
local rankLists = { base = {}, tank = {} }
local fixedRanks = rankLists.base

-- Le sort d'un raccourci dans une macro, en morceau : le numéro d'un rang choisi et appris, sinon son texte
local function Piece(value)
	local cast = Z.CastOf(value)
	return type(cast) == "number" and cast or Z.MacroSpell(value)
end

-- Le texte d'une macro à partir de ses morceaux, chaque rang choisi adapté au niveau « level » (nil : tel quel)
local function Build(parts, level)
	local text = {}
	for index, part in ipairs(parts) do
		text[index] = type(part) == "number" and Z.MacroSpell("#" .. Z.FitRank(part, level)) or part
	end
	return table.concat(text)
end

local function NoteParts(key, parts)
	for _, part in ipairs(parts) do
		if type(part) == "number" then
			fixedRanks[#fixedRanks + 1] = { key = key, parts = parts }
			return
		end
	end
end

-- Ajoute à « attributes » ce qu'il faut pour que le bouton « suffix » lance « value ». Options :
-- res (début de macro de la résurrection automatique), trinkets (masque des bijoux), ooc (sort hors combat),
-- enemy (variante ennemie : ni résurrection, ni bijou, ni rang adapté au niveau d'un allié)
local function AddAction(attributes, prefix, suffix, value, options)
	options = options or {}
	local use = Z.TakesTrinket(value) and Z.TrinketLines(options.trinkets) or ""
	local ooc = options.ooc and Z.ValidVariant("ooc", options.ooc) and Z.CastOf(options.ooc) and Z.TakesTrinket(value) and options.ooc
	if value == "@target" then
		attributes[prefix .. "type" .. suffix] = "target"
	elseif value == "@menu" then
		attributes[prefix .. "type" .. suffix] = "togglemenu"
	elseif value == "@stop" then
		attributes[prefix .. "type" .. suffix] = "macro"
		attributes[prefix .. "macrotext" .. suffix] = "/stopcasting"
	elseif Z.MacroRef(value) or Z.IsMacro(value) then
		-- une macro de ma bibliothèque, ou écrite sur le clic (avant la 1.6.0), sans la résurrection automatique ;
		-- hors combat, le sort de la variante part et la macro s'arrête là
		local macro = Z.MacroRef(value) and Z:FindMacro(Z.MacroRef(value))
		local body = macro and macro.body or (Z.IsMacro(value) and value)
		if body and body:find("%S") then
			local parts = { use }
			if ooc then
				parts[#parts + 1] = "/cast [nocombat,@mouseover] "
				parts[#parts + 1] = Piece(ooc)
				parts[#parts + 1] = "\n/stopmacro [nocombat]\n"
			end
			parts[#parts + 1] = Z:ResolveMacro(body)
			if #Build(parts) > Z.MACRO_MAX then parts[1] = "" end -- 255 caractères au plus : sans les bijoux, elle part
			attributes[prefix .. "type" .. suffix] = "macro"
			attributes[prefix .. "macrotext" .. suffix] = Build(parts)
			if not options.enemy then NoteParts(prefix .. "macrotext" .. suffix, parts) end
		end
	elseif not Z.CastOf(value) then -- numéro de sort que le jeu ne connaît pas : rien
	elseif options.res or use ~= "" or ooc then
		local parts = { use .. "/cast " .. (options.res or "") }
		if ooc then
			parts[#parts + 1] = "[nocombat,@mouseover] "
			parts[#parts + 1] = Piece(ooc)
			parts[#parts + 1] = "; "
		end
		parts[#parts + 1] = "[@mouseover] "
		parts[#parts + 1] = Piece(value)
		attributes[prefix .. "type" .. suffix] = "macro"
		attributes[prefix .. "macrotext" .. suffix] = Build(parts)
		if not options.enemy then NoteParts(prefix .. "macrotext" .. suffix, parts) end
	else
		local cast = Z.CastOf(value)
		attributes[prefix .. "type" .. suffix] = "spell"
		attributes[prefix .. "spell" .. suffix] = cast -- un numéro : le jeu lance ce rang (CastSpellByID)
		if type(cast) == "number" and not options.enemy then fixedRanks[#fixedRanks + 1] = { key = prefix .. "spell" .. suffix, id = cast } end
	end
end

-- Sur un ennemi : le bouton du jeu passe sur « vbutton » (attribut « harmKey »), qui lance la variante ennemie ;
-- sans elle, la garde le fait passer sur un bouton sans action (rien ne part). « value » : ce que lance le raccourci.
local function AddEnemy(attributes, harmKey, vbutton, enemy, value)
	if enemy and enemy ~= "" then
		attributes[harmKey] = vbutton
		AddAction(attributes, "*", "-" .. vbutton, enemy, { enemy = true })
	elseif Z.db.enemyGuard and Z.TakesTrinket(value) then
		attributes[harmKey] = "zxnone"
	end
end

-- Le lieu compte-t-il comme JcJ pour les variantes ? (champ de bataille ou arène)
local appliedPvP = false
local function InPvP()
	return Z.PvPKind ~= nil and Z.PvPKind() ~= nil
end

-- Clique, ou le clic-soin du jeu, peuvent gérer les cases à la place de Lyorune (option)
function Z:RegisterExternalClicks(b)
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[b] = Z.db.externalClicks and true or nil
end

local applied = {} -- noms des attributs posés la dernière fois (des deux versions), à effacer avant d'en poser d'autres
local sets = {}    -- versions des raccourcis : sets.base, et sets.tank si un raccourci a une variante « Sur un tank »

-- La version qu'il faut à une case : « tank » dans un cadre que le jeu trie sur le rôle « TANK » (juste en combat
-- aussi), « base » dans le cadre d'un autre rôle ; ailleurs, selon le rôle de son joueur (lu hors combat seulement).
local function SetOf(b)
	if not sets.tank then return "base" end
	local header = b:GetParent()
	local filter = header and header.GetAttribute and header:GetAttribute("roleFilter")
	if filter then return filter == "TANK" and "tank" or "base" end
	local role = b.unit and UnitGroupRolesAssigned(b.unit)
	if role == nil or Z.IsSecret(role) then return "base" end -- rôle secret (match JcJ) : la base
	return role == "TANK" and "tank" or "base"
end
Z.ClickSetOf = SetOf -- pour les tests

-- Pose sur une case la version qu'il lui faut, si elle a changé (hors combat seulement)
local function PutSet(b)
	local name = SetOf(b)
	if b.zClickSet == name then return end
	for key in pairs(applied) do b:SetAttribute(key, nil) end
	for key, value in pairs(sets[name]) do b:SetAttribute(key, value) end
	b.zClickSet = name
end

-- Chaque en-tête recopie sur ses nouvelles cases, même en combat, la version de son rôle (la base hors des cadres
-- triés sur le rôle). Hors combat seulement.
local function PushHeaders()
	if not sets.base then return end
	for _, h in ipairs(Z.headers) do
		local name = sets.tank and h:GetAttribute("roleFilter") == "TANK" and "tank" or "base"
		if h.zClickSet ~= name then
			local count = 0
			for key, value in pairs(sets[name]) do
				if key:sub(1, 1) ~= "_" then -- les attributs « _ » passent par _initialAttribute (voir Frames.lua)
					count = count + 1
					h:SetAttribute("z-key" .. count, key)
					h:SetAttribute("z-value" .. count, value)
				end
			end
			h:SetAttribute("z-count", count)
			h.zClickSet = name
		end
	end
end

function Z:ApplyClicks()
	if InCombatLockdown() then
		Z:Safe("clicks", function() Z:ApplyClicks() end)
		return
	end

	local resPrefix = ResPrefix()
	local trinkets, variants = Z:GetTrinkets(), Z:GetVariants()
	local onEnter = "self:ClearBindings()"
	appliedPvP = InPvP()
	local anyTank = false
	if not Z.db.externalClicks then
		for _, entry in pairs(variants) do anyTank = anyTank or entry.tank ~= nil end
	end

	-- Une version des raccourcis ; « tank » prend la variante « Sur un tank » de chaque raccourci qui en a une
	local function MakeSet(set)
		local attributes = {}
		fixedRanks = {}
		rankLists[set] = fixedRanks
		-- Ce que lance un raccourci ici : sa variante JcJ en champ de bataille ou en arène, puis sa variante tank
		-- (le sort hors combat ne compte plus), sinon lui-même avec son sort hors combat
		local function Add(prefix, suffix, value, id, harmKey, vbutton)
			local v = variants[id] or {}
			local wanted, ooc = value, v.ooc
			if appliedPvP and v.pvp then wanted = v.pvp
			elseif set == "tank" and v.tank then wanted, ooc = v.tank, nil end
			AddAction(attributes, prefix, suffix, wanted, { res = resPrefix, trinkets = trinkets[id], ooc = ooc })
			AddEnemy(attributes, harmKey, vbutton, v.enemy, wanted)
		end
		if not Z.db.externalClicks then
			-- Clics de souris ; sur un ennemi, « shift-harmbutton1 » passe Maj + Clic gauche sur le bouton « zxshift1 »
			for key, value in pairs(Z:GetClicks()) do
				local modifier, button = Z.ParseClickKey(key)
				if modifier and value and value ~= "" then
					Add(modifier, button, value, key, modifier .. "harmbutton" .. button, "zx" .. modifier:gsub("%-", "") .. button)
				end
			end
			-- Touches au survol : à l'entrée de la souris, la touche « clique » un bouton virtuel de la case
			for i, entry in ipairs(Z:GetHoverKeys()) do
				local key = Z.ValidKey(entry.key) and entry.key -- jamais de guillemet ni d'antislash dans le code sécurisé
				if key and entry.spell and entry.spell ~= "" then
					Add("*", "-zh" .. i, entry.spell, "key:" .. key, "*harmbutton-zh" .. i, "zxh" .. i)
					if set == "base" then onEnter = onEnter .. (' self:SetBindingClick(true, "%s", self, "zh%d")'):format(key, i) end
				end
			end
		end
		return attributes
	end
	sets = { base = MakeSet("base") }
	if anyTank then sets.tank = MakeSet("tank") else rankLists.tank = {} end
	for _, attributes in pairs(sets) do
		attributes["_onenter"] = onEnter
		attributes["_onleave"] = "self:ClearBindings()"
	end

	-- Cases existantes : tout est effacé, puis chacune reçoit sa version (Z:FitAllRanks, plus bas)
	for _, b in ipairs(Z.buttons) do
		for name in pairs(applied) do b:SetAttribute(name, nil) end
		b.zClickSet = nil
		Z:RegisterExternalClicks(b)
	end
	applied = {}
	for _, attributes in pairs(sets) do
		for name in pairs(attributes) do applied[name] = true end
	end

	-- Cases à venir : chaque en-tête recopie sa version sur ses nouvelles cases, même en combat
	for _, h in ipairs(Z.headers) do
		h.zClickSet = nil
		h:SetAttribute("_initialAttribute-_onenter", onEnter)
	end
	Z:FitAllRanks(true)
	Z:SyncBarMacros()
	Z:WarnClickConflicts()
	if Z.RefreshClicks then Z.RefreshClicks() end
	if Z.RefreshCooldowns and Z.db.cooldownPanel then Z:RefreshCooldowns() end -- « Mes recharges » suit les raccourcis
end

-- Entrée ou sortie d'un champ de bataille ou d'une arène : les variantes JcJ suivent. On y entre hors combat ;
-- sinon tout est reposé à la fin du combat, sans message (rien n'a été demandé par le joueur).
local pvpAfterCombat
local function PvPChanged()
	if not (Z.db and Z.class) or InPvP() == appliedPvP then return end
	local any = false
	for _, entry in pairs(Z:GetVariants()) do any = any or entry.pvp ~= nil end
	if not any then
		appliedPvP = InPvP()
	elseif InCombatLockdown() then
		pvpAfterCombat = true
	else
		Z:ApplyClicks()
	end
end
Z:On("PLAYER_ENTERING_WORLD", PvPChanged)
Z:On("ZONE_CHANGED_NEW_AREA", PvPChanged)
Z:On("PLAYER_REGEN_ENABLED", function()
	if pvpAfterCombat then
		pvpAfterCombat = false
		PvPChanged()
	end
end)

----------------------------------------------------------------------------------------------------
-- CLIC POUR LANCER DU JEU : les combinaisons qu'il prend aussi. Lecture seule, jamais de modification.
----------------------------------------------------------------------------------------------------
local GAME_BUTTONS = { LeftButton = "1", RightButton = "2", MiddleButton = "3" }

-- Clé de clic Lyorune (« ctrl-shift-1 ») d'un raccourci du jeu, ou nil (bouton 6 et plus, format inconnu)
function Z.GameClickKey(button, modifiers)
	if type(button) ~= "string" then return nil end
	local number = GAME_BUTTONS[button] or button:match("^Button([1-5])$")
	if not number then return nil end
	local text = ""
	if modifiers and modifiers ~= 0 and GetStringFromModifiers then
		local ok, result = pcall(GetStringFromModifiers, modifiers)
		text = ok and type(result) == "string" and result:lower() or ""
	end
	local key = ""
	for _, name in ipairs({ "alt", "ctrl", "shift" }) do
		if text:find(name, 1, true) then key = key .. name .. "-" end
	end
	return key .. number
end

-- Mes clics que le clic pour lancer du jeu prend aussi : { ["shift-1"] = "Soins rapides", ... }
-- Seuls ses sorts et ses macros comptent : « cibler » et « menu » font la même chose que chez Lyorune.
function Z:GameClickConflicts()
	local found = {}
	local api = C_ClickBindings
	if Z.db.externalClicks or not (api and api.GetProfileInfo) then return found end
	local ok, profile = pcall(api.GetProfileInfo)
	if not ok or type(profile) ~= "table" then return found end
	local types = Enum and Enum.ClickBindingType or {}
	local clicks = Z:GetClicks()
	for _, info in ipairs(profile) do
		local kind = type(info) == "table" and info.type
		if kind and (kind == types.Spell or kind == types.Macro or kind == types.PetAction) then
			local key = Z.GameClickKey(info.button, info.modifiers)
			if key and clicks[key] and clicks[key] ~= "" then
				local name
				pcall(function()
					if kind == types.Macro then name = GetMacroInfo(info.actionID)
					else name = C_Spell.GetSpellName(info.actionID) end
				end)
				found[key] = type(name) == "string" and name or "?"
			end
		end
	end
	return found
end

-- Message dans le chat, une fois par combinaison et par session (option « clickConflictAlert »)
local warnedConflicts = {}
function Z:WarnClickConflicts()
	if not Z.db.clickConflictAlert then return end
	local list = {}
	for key, name in pairs(Z:GameClickConflicts()) do
		if not warnedConflicts[key] then
			warnedConflicts[key] = true
			list[#list + 1] = Z:ClickLabel(key) .. " (" .. name .. ")"
		end
	end
	if #list == 0 then return end
	table.sort(list)
	Z:Print(Z.L["le clic pour lancer du jeu prend aussi : %s. Il peut passer avant Lyorune : changez l'un des deux (chapitre Sorts et raccourcis, ligne en orange)."]:format(table.concat(list, ", ")))
end

----------------------------------------------------------------------------------------------------
-- MACROS POUR LES BARRES DE SORTS (option « actionBarMacros »). Pour chaque sort ou macro de mes clics, Lyorune
-- crée une vraie macro du jeu, rangée dans l'onglet du personnage de la fenêtre /macro, à glisser dans une
-- barre. Elle vise le joueur sous la souris (une case ou un personnage), sinon la cible, sinon moi.
-- Lyorune ne crée, ne modifie et ne retire que SES macros : leur nom commence par « Lyo: », et Lyorune les a
-- notées à leur création (LyoruneCharDB.barMacros). Une macro du joueur nommée « Lyo:... » n'est jamais touchée.
-- COPIES DE MES MACROS. Glisser une macro de Mes macros la copie aussi (« Lyo:Nom ») et la met en main, pour une
-- barre de sorts : sans l'option, et seulement celles que le joueur a glissées (LyoruneCharDB.barCopies, nom de la
-- macro de la bibliothèque -> nom de sa copie). La copie suit le texte et le nom, et part avec la macro.
-- Le jeu limite une macro à 255 caractères et interdit à une macro d'en lancer une autre (/click) depuis le patch
-- 11.0.2 : la copie porte donc tout le texte, jamais un relais vers nos boutons.
----------------------------------------------------------------------------------------------------
local MACRO_PREFIX = "Lyo:"
local MACRO_ICON = "INV_MISC_QUESTIONMARK" -- avec cette icône, le jeu affiche celle du sort de la macro
local macrosReady = false -- le jeu charge les macros un peu après la connexion : on attend, pour ne rien créer en double
local warnedFull

-- Nom d'une macro : 16 octets au plus pour le jeu, coupé sans abîmer une lettre accentuée
local function MacroName(label)
	return Z.CutText(MACRO_PREFIX .. label, 16)
end

-- Copies glissées depuis Mes macros, pour ce personnage : nom de la macro -> nom de sa copie dans /macro
local function Copies()
	local char = Z.char or {}
	char.barCopies = char.barCopies or {}
	return char.barCopies
end

-- Le texte d'une macro posée dans une barre vise le joueur survolé, sinon la cible (Z:BarText)
local function BarBody(value)
	if Z.IsMacro(value) then return Z:BarText(value) end
	local ref = Z.MacroRef(value)
	if ref then
		local macro = Z:FindMacro(ref)
		return macro and Z:BarText(macro.body) or ""
	end
	local _, name = Z.CastOf(value)
	local spell = Z.MacroSpell(value) -- rang fixe : « Soins(Rang 2) »
	if not spell then return "" end
	local state, fallback = "nodead", "[@player] "
	for _, id in pairs(Z.classRes[Z.class] or {}) do
		if Z.SpellName(id) == name then state, fallback = "dead", "" end -- une résurrection vise un mort, jamais moi
	end
	return ("#showtooltip %s\n/cast [@mouseover,help,%s][help,%s] %s%s"):format(spell, state, state, fallback, spell)
end

-- Les macros que Lyorune tient à jour : une par sort de mes clics et de mes touches au survol
function Z:BarMacros()
	local list, seen = {}, {}
	local function add(label, value)
		local ref = Z.MacroRef(value)
		if type(value) ~= "string" or value == "" or (value:sub(1, 1) == "@" and not ref) then return end
		local macro = Z.IsMacro(value)
		local rank = Z.db.rankChoice and Z.RankId(value) and Z.RankText(Z.RankId(value)):match("%d+")
		local shown = rank and ("%s %s"):format(rank, select(2, Z.CastOf(value)) or value) or value -- « 2 Soins » : jamais le nom du rang le plus haut
		local name = ref and Copies()[ref] or MacroName(ref or (macro and label) or shown) -- copie déjà glissée : la même
		local body = BarBody(value)
		if seen[name] or body == "" or #body > 255 then return end
		seen[name] = true
		local plain = not (macro or ref)
		list[#list + 1] = { name = name, body = body, spell = plain and value or nil, ref = ref,
			icon = plain and C_Spell.GetSpellTexture(Z.SpellOf(value)) or Z:MacroIcon(body) }
	end
	local clicks, keys = Z:GetClicks(), {}
	for key in pairs(clicks) do keys[#keys + 1] = key end
	table.sort(keys)
	for _, key in ipairs(keys) do add(key, clicks[key]) end
	for _, entry in ipairs(Z:GetHoverKeys()) do add(entry.key or "?", entry.spell) end
	return list
end

-- Les macros créées par Lyorune pour ce personnage : nom -> true
local function Owned()
	local char = Z.char or {}
	char.barMacros = char.barMacros or {}
	return char.barMacros
end

-- Avant la 1.8.1, la liste n'existait pas : on reprend une seule fois les macros « Lyo: » écrites comme Lyorune
-- les écrit (« #showtooltip » puis « /cast [@mouseover,help,... »), ou identiques à celles qu'il voudrait poser.
local function AdoptOldMacros(wanted)
	local char = Z.char
	if not char or char.barMacrosAdopted then return end
	char.barMacrosAdopted = true
	local owned, bodies = Owned(), {}
	for _, macro in ipairs(wanted) do bodies[macro.name] = macro.body end
	local first = MAX_ACCOUNT_MACROS or 120
	local _, count = GetNumMacros()
	for index = first + 1, first + count do
		local name, _, body = GetMacroInfo(index)
		if name and name:sub(1, #MACRO_PREFIX) == MACRO_PREFIX and type(body) == "string"
			and (body == bodies[name] or body:match("^#showtooltip [^\n]+\n/cast %[@mouseover,help,%a+%]%[help,%a+%] [^\n]+$")) then
			owned[name] = true
		end
	end
end

-- Parcourt les macros de personnage créées par Lyorune, de la dernière à la première (une suppression décale
-- les suivantes)
local function EachOwnMacro(fn)
	local first, owned = MAX_ACCOUNT_MACROS or 120, Owned()
	local _, count = GetNumMacros()
	for index = first + count, first + 1, -1 do
		local name = GetMacroInfo(index)
		if name and owned[name] and name:sub(1, #MACRO_PREFIX) == MACRO_PREFIX then fn(index, name) end
	end
end

-- Les copies de Mes macros rejoignent la liste voulue (renommées si la macro l'a été) ; une copie dont la macro
-- a disparu, ou que le joueur a retirée de /macro, est oubliée
local function AddCopies(wanted, names)
	local copies, owned = Copies(), Owned()
	for lib, name in pairs(copies) do
		local macro = Z:FindMacro(lib)
		if not macro or not owned[name] then
			copies[lib] = nil
		else
			local body = Z:BarText(macro.body)
			if #body > Z.MACRO_MAX or not macro.body:find("%S") then body = nil end -- trop longue : copie gardée telle quelle
			local better = MacroName(lib)
			-- (pas quand l'option la tient aussi pour un clic : elle garde le nom qu'elle connaît)
			if better ~= name and not names[name] and not names[better] and GetMacroIndexByName(better) == 0 then
				local index = GetMacroIndexByName(name)
				EditMacro(index, better, nil, body or GetMacroBody(index))
				owned[name], owned[better], copies[lib], name = nil, true, better, better
			end
			if not names[name] then
				names[name] = true
				wanted[#wanted + 1] = { name = name, body = body, copy = true }
			end
		end
	end
end

-- Nom libre pour une nouvelle copie : « Lyo:Nom », sinon « Lyo:No 2 », « Lyo:No 3 »...
local function FreeCopyName(lib)
	local taken = {}
	for _, name in pairs(Copies()) do taken[name] = true end
	for _, macro in ipairs(Z.db.actionBarMacros and Z:BarMacros() or {}) do
		if macro.ref ~= lib then taken[macro.name] = true end
	end
	local name = MacroName(lib)
	if not taken[name] and GetMacroIndexByName(name) == 0 then return name end
	for i = 2, 99 do
		name = Z.CutText(MACRO_PREFIX .. lib, 16 - #tostring(i) - 1) .. " " .. i
		if not taken[name] and GetMacroIndexByName(name) == 0 then return name end
	end
end

function Z:SyncBarMacros()
	if not macrosReady or not (CreateMacro and GetNumMacros) then return end
	if not Z.db.actionBarMacros and not next(Copies()) then return end
	if InCombatLockdown() then -- le jeu interdit de créer une macro en combat
		Z:Safe("macros", function() Z:SyncBarMacros() end)
		return
	end
	local wanted, names, created = Z.db.actionBarMacros and Z:BarMacros() or {}, {}, 0
	if Z.db.actionBarMacros then AdoptOldMacros(wanted) end
	local owned = Owned()
	for name in pairs(owned) do -- supprimée à la main dans /macro : plus à moi
		if GetMacroIndexByName(name) == 0 then owned[name] = nil end
	end
	for _, macro in ipairs(wanted) do names[macro.name] = true end
	AddCopies(wanted, names)
	EachOwnMacro(function(index, name)
		if not names[name] then -- sort retiré de mes clics, macro supprimée de Mes macros
			DeleteMacro(index)
			owned[name] = nil
		end
	end)
	for _, macro in ipairs(wanted) do
		local index = GetMacroIndexByName(macro.name)
		if index and index > 0 then
			-- une macro du joueur porte déjà ce nom : on la laisse telle quelle
			if macro.body and owned[macro.name] and GetMacroBody(index) ~= macro.body then EditMacro(index, macro.name, nil, macro.body) end
		elseif not macro.copy then -- une copie n'est créée qu'au glisser (Z:PickupGameCopy)
			local _, used = GetNumMacros()
			if used < (MAX_CHARACTER_MACROS or 30) and pcall(CreateMacro, macro.name, MACRO_ICON, macro.body, true) then
				owned[macro.name] = true
				created = created + 1
			elseif not warnedFull then
				warnedFull = true
				Z:Print(Z.L["plus de place pour une macro de personnage : supprimez-en une dans /macro, ou coupez l'option dans le chapitre Sorts et raccourcis."])
			end
		end
	end
	if created > 0 then
		Z:Print(Z.L["%d macro(s) créée(s) pour vos barres de sorts : chapitre Sorts et raccourcis des options, ou /macro, onglet de votre personnage."]:format(created))
	end
end

-- Bouton « Retirer les macros de Lyorune » : ne retire que les macros « Lyo: »
-- Renvoie vrai si les macros sont retirées (refusé en combat : l'option reste cochée)
function Z:RemoveBarMacros()
	if InCombatLockdown() then
		Z:Print(Z.L["impossible de modifier les macros en combat."])
		return false
	end
	if not GetNumMacros then return true end -- aucune macro à retirer
	AdoptOldMacros(Z:BarMacros())
	local owned, kept = Owned(), {}
	for _, name in pairs(Copies()) do kept[name] = true end -- les copies glissées depuis Mes macros restent
	EachOwnMacro(function(index, name)
		if kept[name] then return end
		DeleteMacro(index)
		owned[name] = nil
	end)
	return true
end

-- Glisser une macro de Mes macros : sa copie « Lyo: » est créée ou mise à jour, puis mise en main, à déposer dans
-- une barre de sorts. Renvoie true, ou false et la raison à dire au joueur (rien quand le jeu n'a pas ces fonctions).
function Z:PickupGameCopy(macro)
	if not (macro and CreateMacro and PickupMacro and GetNumMacros) then return false end
	local L = Z.L
	if InCombatLockdown() then return false, L["impossible de modifier les macros en combat."] end
	if not macrosReady then return false, L["les macros du jeu ne sont pas encore chargées : réessayez dans quelques secondes."] end
	if not macro.body:find("%S") then return false end
	local body = Z:BarText(macro.body)
	if #body > Z.MACRO_MAX then
		return false, L["« %s » est trop longue pour une barre de sorts du jeu : %d caractères, %d au plus."]:format(macro.name, #body, Z.MACRO_MAX)
	end
	local copies, owned = Copies(), Owned()
	local name = copies[macro.name]
	local index = name and owned[name] and GetMacroIndexByName(name) or 0
	if index == 0 then
		-- déjà créée pour un clic de cette macro par l'option « Créer une macro par sort de mes clics » : c'est la même
		name = nil
		for _, made in ipairs(Z.db.actionBarMacros and Z:BarMacros() or {}) do
			if made.ref == macro.name and owned[made.name] and GetMacroIndexByName(made.name) > 0 then name = made.name end
		end
		if not name then
			name = FreeCopyName(macro.name)
			local _, used = GetNumMacros()
			if not name or used >= (MAX_CHARACTER_MACROS or 30) then
				return false, L["plus de place pour une macro de personnage : supprimez-en une dans /macro."]
			end
			local ok = pcall(CreateMacro, name, MACRO_ICON, body, true)
			if not ok or GetMacroIndexByName(name) == 0 then return false end
			owned[name] = true
		end
		copies[macro.name] = name
		index = GetMacroIndexByName(name)
	end
	if GetMacroBody(index) ~= body then
		EditMacro(index, name, nil, body)
		index = GetMacroIndexByName(name)
	end
	PickupMacro(index)
	return true
end

-- Nom de la copie de cette macro dans /macro, si elle existe
function Z:GameCopy(macro)
	local name = macro and Copies()[macro.name]
	return name and Owned()[name] and GetMacroIndexByName and GetMacroIndexByName(name) > 0 and name or nil
end

-- La macro de la bibliothèque dont « name » est la copie (glissée, ou créée par l'option pour un clic)
function Z:CopyOwner(name)
	if not (name and Owned()[name]) then return nil end
	for lib, copy in pairs(Copies()) do
		if copy == name then return Z:FindMacro(lib) end
	end
	for _, macro in ipairs(Z.db.actionBarMacros and Z:BarMacros() or {}) do
		if macro.name == name and macro.ref then return Z:FindMacro(macro.ref) end
	end
end

-- Macro renommée dans Mes macros : sa copie la suit (nom de la copie changé à la prochaine synchronisation)
function Z:MoveGameCopy(old, new)
	local copies = Copies()
	if copies[old] then copies[new], copies[old] = copies[old], nil end
end

-- Appelé à la connexion : la première synchronisation attend que le jeu ait chargé les macros
function Z:StartBarMacros()
	local function Ready()
		if macrosReady then return end
		macrosReady = true
		-- La 1.5.1 créait ces macros d'office : on retire celles qu'elle a posées sans qu'on le lui demande
		if Z.db.barMacros ~= nil and not InCombatLockdown() then
			Z.db.barMacros = nil
			if not Z.db.actionBarMacros then Z:RemoveBarMacros() end
		end
		-- Avant la 1.6.0, un clic pouvait viser une macro de /macro : elle est copiée dans la bibliothèque
		if Z:MigrateMacros(true) then Z:ApplyClicks() end
		Z:SyncBarMacros()
	end
	Z:On("UPDATE_MACROS", Ready)
	C_Timer.After(5, Ready)
end

function Z:SetClick(key, value)
	Z:GetClicks()[key] = value
	Z:ApplyClicks()
end

-- Sorts de ma classe connus de Lyorune (Data.lua) : soins sans cible, buffs (sur moi, de groupe, à une personne,
-- auras, armes), dissipations, résurrections, sorts suivis, clics de départ. Ils sont proposés même quand le jeu
-- ne les dit pas « utilisables sur un allié » (Feu intérieur, boucliers du chaman, Tranquillité...).
-- Clé : nom du sort (tous ses rangs ont le même), valeur : un de ses numéros.
function Z:ClassSpellNames()
	local names, class = {}, Z.class
	local function add(id)
		local name = type(id) == "number" and Z.SpellName(id)
		if name and not names[name] then names[name] = id end
	end
	local function addAll(list)
		for _, id in pairs(list or {}) do
			if type(id) == "table" then addAll(id) else add(id) end
		end
	end
	addAll(Z.groupHeals[class])
	addAll(Z.dispelSpells[class])
	addAll(Z.classRes[class])
	addAll(Z.trackedSpells[class])
	addAll(Z.clickDefaults[class])
	addAll(Z.uniqueBuffs[class])
	for _, entry in ipairs(Z.raidBuffs[class] or {}) do addAll(Z.BuffIds(entry)) end
	return names
end

-- Sorts de mon grimoire : { { id, name, passive, offSpec }, ... } (vide si le jeu ne répond pas)
local function Grimoire()
	local items = {}
	pcall(function()
		local bank = Enum.SpellBookSpellBank.Player
		for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
			for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
				local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
				local id = item and item.itemType == Enum.SpellBookItemType.Spell and (item.spellID or item.actionID)
				local name = id and C_Spell.GetSpellName(id)
				if name then
					items[#items + 1] = { id = id, name = name, passive = item.isPassive, offSpec = item.isOffSpec,
						sub = item.subName }
				end
			end
		end
	end)
	return items
end

-- Le jeu dit-il ce sort utilisable sur un allié ? (sans réponse du jeu : oui, comme avant la 1.34.1)
local function Helpful(id)
	if not C_Spell.IsSpellHelpful then return true end
	local ok, helpful = pcall(C_Spell.IsSpellHelpful, id)
	return not ok or helpful == true
end

-- Sorts que « Sorts et raccourcis » propose : ceux de ma spécialisation active, ni passifs, que le jeu dit
-- utilisables sur un allié ou que Data.lua connaît pour ma classe. Un sort offensif n'est jamais proposé.
-- Chaque sort porte ses rangs lus dans le grimoire : ranks = { { id, n, sub }, ... } du plus bas au plus haut
-- (n : le chiffre du texte « Rang 2 »), et top : le numéro de son rang le plus haut, même si le grimoire ne
-- montre pas les autres (option du jeu « Tous les rangs » décochée).
local function RankNumber(sub, fallback)
	return tonumber(type(sub) == "string" and sub:match("%d+") or nil) or fallback
end

-- Le jeu dit-il ce sort offensif ? (variante « sur un ennemi » ; sans réponse du jeu : non)
local function Harmful(id)
	if not C_Spell.IsSpellHarmful then return false end
	local ok, harmful = pcall(C_Spell.IsSpellHarmful, id)
	return ok and harmful == true
end

-- side = "enemy" : les sorts pour un ennemi (variante « sur un ennemi ») : ceux que le jeu dit offensifs
function Z:KnownSpells(side)
	local spells, seen = {}, {}
	local function add(id, sub)
		local name = id and C_Spell.GetSpellName(id)
		if not name then return end
		local spell = seen[name]
		if not spell then
			spell = { name = name, icon = C_Spell.GetSpellTexture(id), id = id, ranks = {} }
			seen[name] = spell
			spells[#spells + 1] = spell
		end
		sub = sub or Z.RankText(id)
		local rank = { id = id, n = RankNumber(sub, #spell.ranks + 1), sub = sub }
		spell.ranks[#spell.ranks + 1] = rank
		if rank.n >= (spell.top or 0) then spell.top, spell.id = rank.n, id end -- la bulle montre le rang le plus haut
	end

	local mine = Z:ClassSpellNames()
	for _, item in ipairs(Grimoire()) do
		local wanted
		if side == "enemy" then wanted = Harmful(item.id) else wanted = mine[item.name] or Helpful(item.id) end
		if not item.passive and not item.offSpec and wanted then add(item.id, item.sub) end
	end
	for _, spell in ipairs(spells) do
		table.sort(spell.ranks, function(a, b) return a.n < b.n end)
		if #spell.ranks == 1 and not (spell.ranks[1].sub or ""):find("%d") then spell.top = nil end -- sort sans rang
	end

	-- Grimoire illisible : on propose au moins les sorts connus de la classe
	if #spells == 0 and side ~= "enemy" then
		for name, id in pairs(mine) do
			if Z.Knows(id) and not Z.IsPassive(id) then add(id) end
		end
	end
	table.sort(spells, function(a, b) return a.name < b.name end)
	return spells
end

-- Niveau d'apprentissage et coût en mana d'un rang (nil quand le jeu ne répond pas)
function Z.RankFacts(id)
	local level, cost
	if C_Spell.GetSpellLevelLearned then
		local ok, value = pcall(C_Spell.GetSpellLevelLearned, id)
		if ok and type(value) == "number" and value > 0 then level = value end
	end
	if C_Spell.GetSpellPowerCost then
		local ok, costs = pcall(C_Spell.GetSpellPowerCost, id)
		local first = ok and type(costs) == "table" and costs[1]
		if first and type(first.cost) == "number" and first.cost > 0 then cost = first.cost end
	end
	return level, cost
end

-- Les choix de rang d'un sort de KnownSpells : « le plus haut » (son nom), puis chaque rang du grimoire
-- (« #numéro »), avec son texte : { { value, text, id }, ... } ; hidden : vrai si le grimoire cache des rangs
function Z.RankChoices(spell)
	local L, list = Z.L, {}
	list[1] = { value = spell.name, text = L["Le plus haut (suit vos nouveaux rangs)"], id = spell.id }
	for _, rank in ipairs(spell.ranks or {}) do
		local level, cost = Z.RankFacts(rank.id)
		local text = (rank.sub and rank.sub ~= "") and rank.sub or L["Rang %d"]:format(rank.n)
		if level then text = text .. " · " .. L["niveau %d"]:format(level) end
		if cost then text = text .. " · " .. L["%d mana"]:format(cost) end
		list[#list + 1] = { value = "#" .. rank.id, text = text, id = rank.id }
	end
	return list, (spell.top or 0) > #(spell.ranks or {})
end

-- Un rang plus bas que mon rang le plus haut ? (lu sur le chiffre du texte du rang, pas sur la chaîne des rangs
-- du jeu, fausse pour quelques sorts de Forever). Sert au sort glissé depuis le grimoire.
function Z.IsLowRank(id)
	local name, n = C_Spell.GetSpellName(id), RankNumber(Z.RankText(id), nil)
	if not (name and n) then return false end
	for _, spell in ipairs(Z:KnownSpells()) do
		if spell.name == name then return n < (spell.top or 0) end
	end
	return false
end

----------------------------------------------------------------------------------------------------
-- RANG ADAPTÉ AU JOUEUR SOIGNÉ (1.38.1, réglage « rankAdapt »). Le rang le plus haut, lancé par son nom, est déjà
-- baissé par le jeu sur un joueur de bas niveau. Un rang choisi, lancé par son numéro, ne l'est pas : hors combat,
-- chaque case reçoit le meilleur de mes rangs que son joueur peut recevoir (règle du jeu : niveau d'apprentissage
-- du rang moins 10), jamais plus fort que le rang choisi. En combat, la case garde son rang ; tout est revu à la
-- fin du combat. Rien ne tourne quand aucun raccourci n'a de rang choisi.
----------------------------------------------------------------------------------------------------
local ranksByName -- mes rangs par nom de sort, relus après chaque ApplyClicks (le grimoire a pu changer)

-- Le rang à lancer sur un joueur de ce niveau, à partir du rang choisi « id »
function Z.FitRank(id, level)
	if type(level) ~= "number" or (Z.IsSecret and Z.IsSecret(level)) or level <= 0 then return id end -- niveau inconnu : le rang choisi
	local learned = Z.RankFacts(id)
	if not learned or level >= learned - 10 then return id end
	if not ranksByName then
		ranksByName = {}
		for _, spell in ipairs(Z:KnownSpells()) do ranksByName[spell.name] = spell.ranks end
	end
	local chosen, best = RankNumber(Z.RankText(id), nil), nil
	for _, rank in ipairs(ranksByName[C_Spell.GetSpellName(id)] or {}) do -- du plus bas au plus haut
		local need = Z.RankFacts(rank.id)
		if chosen and rank.n < chosen and need and level >= need - 10 then best = rank.id end
	end
	return best or id -- aucun rang assez bas : le rang choisi (le jeu dira « niveau trop bas »)
end

-- Pose sur une case la version de ses raccourcis (tank ou base, selon son rôle), puis le rang de chaque raccourci
-- à rang choisi, selon le niveau de son joueur
function Z:FitRanks(b)
	if InCombatLockdown() or not sets.base then return end
	PutSet(b)
	local list = rankLists[b.zClickSet] or rankLists.base
	if #list == 0 then return end
	local level = Z.db.rankAdapt and b.unit and UnitLevel(b.unit)
	for _, entry in ipairs(list) do
		b:SetAttribute(entry.key, entry.parts and Build(entry.parts, level) or Z.FitRank(entry.id, level))
	end
end

local fitAfterCombat
function Z:FitAllRanks(fresh)
	if fresh then ranksByName = nil end
	if not fresh and not sets.tank and #rankLists.base == 0 then return end
	if InCombatLockdown() then
		fitAfterCombat = true -- sans message : rien n'a été demandé par le joueur
		return
	end
	fitAfterCombat = false
	PushHeaders() -- un cadre devenu « Tanks » ou par rôle (disposition changée)
	for _, b in ipairs(Z.buttons) do Z:FitRanks(b) end
end
-- Un autre joueur dans la case, un niveau gagné, un rôle changé, une autre cible ou focalisation : sa version des
-- raccourcis et son rang suivent, hors combat (sinon à la fin du combat)
for _, event in ipairs({ "GROUP_ROSTER_UPDATE", "UNIT_LEVEL", "PLAYER_ROLES_ASSIGNED", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED" }) do
	Z:On(event, function() Z:FitAllRanks() end)
end
Z:On("PLAYER_REGEN_ENABLED", function()
	if fitAfterCombat then Z:FitAllRanks() end
end)

-- Ce que Lyorune voit (/lyorune sorts) : les sorts proposés, les sorts de ma classe absents avec leur raison
-- (« pas appris », « autre spécialisation », « passif »), et les sorts du grimoire écartés (offensifs, ou sans
-- effet sur un allié). Listes de noms triées.
function Z:SpellReport()
	local L, mine, book = Z.L, Z:ClassSpellNames(), {}
	for _, item in ipairs(Grimoire()) do
		local known = book[item.name] -- un rang lançable l'emporte sur un rang passif ou d'une autre spécialisation
		if not known or known.passive or known.offSpec then book[item.name] = item end
	end
	local proposed, missing, filtered = {}, {}, {}
	for _, spell in ipairs(Z:KnownSpells()) do proposed[#proposed + 1] = spell.name end
	for name in pairs(mine) do
		local item = book[name]
		local why = not item and "pas appris" or item.offSpec and "autre spécialisation" or item.passive and "passif"
		if why then missing[#missing + 1] = ("%s (%s)"):format(name, L[why]) end
	end
	for name, item in pairs(book) do
		if not mine[name] and not item.passive and not item.offSpec and not Helpful(item.id) then
			filtered[#filtered + 1] = name
		end
	end
	table.sort(missing)
	table.sort(filtered)
	return proposed, missing, filtered
end

function Z:SpellsCommand()
	local L = Z.L
	local proposed, missing, filtered = Z:SpellReport()
	Z:Print(L["%d sorts proposés dans « Sorts et raccourcis » : %s."]:format(#proposed, table.concat(proposed, ", ")))
	if #missing > 0 then
		Z:Print(L["Sorts de votre classe absents : %s."]:format(table.concat(missing, ", ")))
	end
	if #filtered > 0 then
		Z:Print(L["Écartés (offensifs ou sans effet sur un allié) : %s."]:format(table.concat(filtered, ", ")))
	end
end

----------------------------------------------------------------------------------------------------
-- NOUVEAU SORT SANS CLIC (option « newSpellAlert »). Quand le grimoire gagne un sort utilisable sur un allié
-- et qu'aucun de mes clics ni de mes touches ne le lance, Lyorune le signale une fois dans le chat et le garde
-- en haut de l'onglet Clics (bouton « Attribuer »), jusqu'à ce qu'il ait un raccourci ou que je l'écarte.
-- Lyorune retient les sorts déjà vus par personnage (LyoruneCharDB.knownSpells) : au tout premier passage, il
-- les note sans rien dire. Seules les classes qui ont des clics proposés (Data.lua) sont concernées.
----------------------------------------------------------------------------------------------------
-- Vrai si l'un de mes raccourcis (spécialisation active) lance ce sort, seul ou dans une macro
function Z:SpellIsBound(name)
	local function launches(value)
		if value == name or (Z.RankId(value) and C_Spell.GetSpellName(Z.RankId(value)) == name) then return true end
		local ref = Z.MacroRef(value)
		local macro = ref and Z:FindMacro(ref)
		local body = macro and macro.body or (Z.IsMacro(value) and value)
		return body and body:find(name, 1, true) and true or false
	end
	for _, binding in ipairs(Z:Bindings()) do
		if launches(binding.value) then return true end
		for _, value in pairs(binding.variants or {}) do -- une variante (JcJ, hors combat) le lance aussi
			if launches(value) then return true end
		end
	end
	return false
end

-- Sorts que l'alerte ne propose jamais : la résurrection (déjà sur le clic de soin) et les buffs de groupe
local function Excluded()
	local skip = {}
	for _, id in pairs(Z.classRes[Z.class] or {}) do
		local name = Z.SpellName(id)
		if name then skip[name] = true end
	end
	for _, entry in ipairs(Z.raidBuffs[Z.class] or {}) do
		for _, id in ipairs(Z.BuffIds(entry)) do
			local name = Z.SpellName(id)
			if name then skip[name] = true end
		end
	end
	return skip
end

-- Mes nouveaux sorts encore sans raccourci : { { name = "...", icon = ... }, ... } (les plus anciens d'abord)
function Z:NewSpells()
	local char = Z.char
	if not (char and char.newSpells and Z.db.newSpellAlert) then return {} end
	local list, known = {}, {}
	for _, spell in ipairs(Z:KnownSpells()) do known[spell.name] = spell end
	for index = #char.newSpells, 1, -1 do -- un sort oublié ou attribué depuis quitte la liste
		local name = char.newSpells[index]
		if not known[name] or Z:SpellIsBound(name) then table.remove(char.newSpells, index) end
	end
	for _, name in ipairs(char.newSpells) do list[#list + 1] = known[name] end
	return list
end

-- Écarte un sort de la liste sans lui donner de raccourci
function Z:DismissNewSpell(name)
	local list = Z.char and Z.char.newSpells or {}
	for index = #list, 1, -1 do
		if list[index] == name then table.remove(list, index) end
	end
	if Z.RefreshClicks then Z.RefreshClicks() end
end

function Z:CheckNewSpells()
	local char = Z.char
	if not char or not Z.clickDefaults[Z.class] then return end
	local spells = Z:KnownSpells()
	if #spells == 0 then return end -- grimoire pas encore chargé
	local first = char.knownSpells == nil
	char.knownSpells = char.knownSpells or {}
	char.newSpells = char.newSpells or {}
	local skip, found = Excluded(), {}
	for _, spell in ipairs(spells) do
		if not char.knownSpells[spell.name] then
			char.knownSpells[spell.name] = true
			if not first and not skip[spell.name] and not Z:SpellIsBound(spell.name) then
				char.newSpells[#char.newSpells + 1] = spell.name
				found[#found + 1] = spell.name
			end
		end
	end
	if #found > 0 and Z.db.newSpellAlert then
		Z:Print(Z.L["nouveau sort sans clic : %s. Chapitre Sorts et raccourcis des options, bouton « Attribuer »."]:format(table.concat(found, ", ")))
	end
	if #found > 0 and Z.RefreshClicks then Z.RefreshClicks() end
end

-- Le grimoire change souvent d'un coup (montée de niveau, talents) : on attend qu'il soit calme
local checkPending
function Z:QueueNewSpells()
	if checkPending then return end
	checkPending = true
	C_Timer.After(2, function()
		checkPending = false
		Z:CheckNewSpells()
	end)
end
