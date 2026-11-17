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
	local clicks, trinkets = Z:GetClicks(), Z:GetTrinkets()
	for _, button in ipairs(Z.clickButtons) do
		for _, modifier in ipairs(Z.clickModifiers) do
			local key = modifier[1] .. button[1]
			local value = clicks[key]
			if value and value ~= "" then list[#list + 1] = { kind = "click", key = key, value = value, trinkets = trinkets[key] } end
		end
	end
	for index, entry in ipairs(Z:GetHoverKeys()) do
		if entry.key then
			list[#list + 1] = { kind = "key", key = entry.key, value = entry.spell or "", index = index, trinkets = trinkets["key:" .. entry.key] }
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
	-- une touche garde sa place dans la liste : on la renomme au lieu de la retirer puis de l'ajouter
	if from.kind == "key" and to.kind == "key" and not other then
		for _, entry in ipairs(Z:GetHoverKeys()) do
			if entry.key == from.key then entry.key = to.key end
		end
		trinkets[fromId], trinkets[toId] = nil, fromMask
		return Z:ApplyClicks()
	end
	Z:SetBinding(from, other, true)
	Z:SetBinding(to, moving, true)
	trinkets[fromId] = Z.TakesTrinket(other) and toMask or nil
	trinkets[toId] = Z.TakesTrinket(moving) and fromMask or nil
	Z:ApplyClicks()
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
	return value
end

-- Mes clics et touches au survol, dans l'ordre de l'onglet Clics : { { "Maj + Clic gauche", "Rénovation" }, ... }
-- Sert à l'infobulle d'une case.
function Z:ClickSummary()
	local list = {}
	for _, binding in ipairs(Z:Bindings()) do
		if binding.value ~= "" then
			local text = Z:ActionText(binding.value)
			if binding.trinkets and Z.TakesTrinket(binding.value) then text = text .. " + " .. Z.L["bijou"] end
			list[#list + 1] = { Z:TriggerLabel(binding), text }
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

-- Ajoute à « attributes » ce qu'il faut pour que le bouton « suffix » lance « value » (avec ses bijoux)
local function AddAction(attributes, prefix, suffix, value, resPrefix, trinkets)
	local use = Z.TakesTrinket(value) and Z.TrinketLines(trinkets) or ""
	if value == "@target" then
		attributes[prefix .. "type" .. suffix] = "target"
	elseif value == "@menu" then
		attributes[prefix .. "type" .. suffix] = "togglemenu"
	elseif value == "@stop" then
		attributes[prefix .. "type" .. suffix] = "macro"
		attributes[prefix .. "macrotext" .. suffix] = "/stopcasting"
	elseif Z.MacroRef(value) then -- une macro de ma bibliothèque, sans la résurrection automatique
		local macro = Z:FindMacro(Z.MacroRef(value))
		if macro and macro.body:find("%S") then
			attributes[prefix .. "type" .. suffix] = "macro"
			attributes[prefix .. "macrotext" .. suffix] = use .. Z:ResolveMacro(macro.body)
		end
	elseif Z.IsMacro(value) then -- macro écrite sur le clic (avant la 1.6.0, rangée ensuite dans la bibliothèque)
		attributes[prefix .. "type" .. suffix] = "macro"
		attributes[prefix .. "macrotext" .. suffix] = use .. Z:ResolveMacro(value)
	elseif resPrefix or use ~= "" then
		attributes[prefix .. "type" .. suffix] = "macro"
		attributes[prefix .. "macrotext" .. suffix] = use .. "/cast " .. (resPrefix or "") .. "[@mouseover] " .. value
	else
		attributes[prefix .. "type" .. suffix] = "spell"
		attributes[prefix .. "spell" .. suffix] = value
	end
end

-- Clique, ou le clic-soin du jeu, peuvent gérer les cases à la place de Lyorune (option)
function Z:RegisterExternalClicks(b)
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[b] = Z.db.externalClicks and true or nil
end

local applied = {} -- attributs posés la dernière fois, à effacer avant d'en poser de nouveaux

function Z:ApplyClicks()
	if InCombatLockdown() then
		Z:Safe("clicks", function() Z:ApplyClicks() end)
		return
	end

	local attributes = {}
	local resPrefix = ResPrefix()
	local trinkets = Z:GetTrinkets()
	local onEnter = "self:ClearBindings()"

	if not Z.db.externalClicks then
		-- Clics de souris
		for key, value in pairs(Z:GetClicks()) do
			local modifier, button = Z.ParseClickKey(key)
			if modifier and value and value ~= "" then
				AddAction(attributes, modifier, button, value, resPrefix, trinkets[key])
			end
		end
		-- Touches au survol : à l'entrée de la souris, la touche « clique » un bouton virtuel de la case
		for i, entry in ipairs(Z:GetHoverKeys()) do
			local key = Z.ValidKey(entry.key) and entry.key -- jamais de guillemet ni d'antislash dans le code sécurisé
			if key and entry.spell and entry.spell ~= "" then
				AddAction(attributes, "*", "-zh" .. i, entry.spell, resPrefix, trinkets["key:" .. key])
				onEnter = onEnter .. (' self:SetBindingClick(true, "%s", self, "zh%d")'):format(key, i)
			end
		end
	end
	attributes["_onenter"] = onEnter
	attributes["_onleave"] = "self:ClearBindings()"

	-- Cases existantes
	for _, b in ipairs(Z.buttons) do
		for name in pairs(applied) do b:SetAttribute(name, nil) end
		for name, value in pairs(attributes) do b:SetAttribute(name, value) end
		Z:RegisterExternalClicks(b)
	end
	applied = attributes

	-- Cases à venir : chaque en-tête recopie cette liste sur ses nouvelles cases, même en combat
	for _, h in ipairs(Z.headers) do
		local count = 0
		for name, value in pairs(attributes) do
			if name:sub(1, 1) ~= "_" then -- les attributs « _ » passent par _initialAttribute (voir Frames.lua)
				count = count + 1
				h:SetAttribute("z-key" .. count, name)
				h:SetAttribute("z-value" .. count, value)
			end
		end
		h:SetAttribute("z-count", count)
		h:SetAttribute("_initialAttribute-_onenter", onEnter)
	end
	Z:SyncBarMacros()
	Z:WarnClickConflicts()
	if Z.RefreshClicks then Z.RefreshClicks() end
end

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
	Z:Print(Z.L["le clic pour lancer du jeu prend aussi : %s. Il peut passer avant Lyorune : changez l'un des deux (onglet Clics, ligne en orange)."]:format(table.concat(list, ", ")))
end

----------------------------------------------------------------------------------------------------
-- MACROS POUR LES BARRES DE SORTS (option « actionBarMacros »). Pour chaque sort ou macro de mes clics, Lyorune
-- crée une vraie macro du jeu, rangée dans l'onglet du personnage de la fenêtre /macro, à glisser dans une
-- barre. Elle vise le joueur sous la souris (une case ou un personnage), sinon la cible, sinon moi.
-- Lyorune ne crée, ne modifie et ne retire que SES macros : leur nom commence par « Lyo: », et Lyorune les a
-- notées à leur création (LyoruneCharDB.barMacros). Une macro du joueur nommée « Lyo:... » n'est jamais touchée.
----------------------------------------------------------------------------------------------------
local MACRO_PREFIX = "Lyo:"
local MACRO_ICON = "INV_MISC_QUESTIONMARK" -- avec cette icône, le jeu affiche celle du sort de la macro
local macrosReady = false -- le jeu charge les macros un peu après la connexion : on attend, pour ne rien créer en double
local warnedFull

-- Nom d'une macro : 16 octets au plus pour le jeu, coupé sans abîmer une lettre accentuée
local function MacroName(label)
	return Z.CutText(MACRO_PREFIX .. label, 16)
end

local function BarBody(value)
	if Z.IsMacro(value) then return Z:ResolveMacro(value) end
	local ref = Z.MacroRef(value)
	if ref then
		local macro = Z:FindMacro(ref)
		return macro and Z:ResolveMacro(macro.body) or ""
	end
	local state, fallback = "nodead", "[@player] "
	for _, id in pairs(Z.classRes[Z.class] or {}) do
		if Z.SpellName(id) == value then state, fallback = "dead", "" end -- une résurrection vise un mort, jamais moi
	end
	return ("#showtooltip %s\n/cast [@mouseover,help,%s][help,%s] %s%s"):format(value, state, state, fallback, value)
end

-- Les macros que Lyorune tient à jour : une par sort de mes clics et de mes touches au survol
function Z:BarMacros()
	local list, seen = {}, {}
	local function add(label, value)
		local ref = Z.MacroRef(value)
		if type(value) ~= "string" or value == "" or (value:sub(1, 1) == "@" and not ref) then return end
		local macro = Z.IsMacro(value)
		local name = MacroName(ref or (macro and label) or value)
		local body = BarBody(value)
		if seen[name] or body == "" or #body > 255 then return end
		seen[name] = true
		local plain = not (macro or ref)
		list[#list + 1] = { name = name, body = body, spell = plain and value or nil,
			icon = plain and C_Spell.GetSpellTexture(value) or Z:MacroIcon(body) }
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

function Z:SyncBarMacros()
	if not macrosReady or not Z.db.actionBarMacros or not (CreateMacro and GetNumMacros) then return end
	if InCombatLockdown() then -- le jeu interdit de créer une macro en combat
		Z:Safe("macros", function() Z:SyncBarMacros() end)
		return
	end
	local wanted, names, created = Z:BarMacros(), {}, 0
	AdoptOldMacros(wanted)
	local owned = Owned()
	for _, macro in ipairs(wanted) do names[macro.name] = true end
	EachOwnMacro(function(index, name)
		if not names[name] then -- sort retiré de mes clics
			DeleteMacro(index)
			owned[name] = nil
		end
	end)
	for name in pairs(owned) do -- supprimée à la main dans /macro : plus à moi
		if GetMacroIndexByName(name) == 0 then owned[name] = nil end
	end
	for _, macro in ipairs(wanted) do
		local index = GetMacroIndexByName(macro.name)
		if index and index > 0 then
			-- une macro du joueur porte déjà ce nom : on la laisse telle quelle
			if owned[macro.name] and GetMacroBody(index) ~= macro.body then EditMacro(index, macro.name, nil, macro.body) end
		else
			local _, used = GetNumMacros()
			if used < (MAX_CHARACTER_MACROS or 30) and pcall(CreateMacro, macro.name, MACRO_ICON, macro.body, true) then
				owned[macro.name] = true
				created = created + 1
			elseif not warnedFull then
				warnedFull = true
				Z:Print(Z.L["plus de place pour une macro de personnage : supprimez-en une dans /macro, ou décochez l'option dans l'onglet Clics."])
			end
		end
	end
	if created > 0 then
		Z:Print(Z.L["%d macro(s) créée(s) pour vos barres de sorts : onglet Clics des options, ou /macro, onglet de votre personnage."]:format(created))
	end
end

-- Bouton « Retirer les macros de Lyorune » : ne retire que les macros « Lyo: »
function Z:RemoveBarMacros()
	if InCombatLockdown() then return Z:Print(Z.L["impossible de modifier les macros en combat."]) end
	if not GetNumMacros then return end
	AdoptOldMacros(Z:BarMacros())
	local owned = Owned()
	EachOwnMacro(function(index, name)
		DeleteMacro(index)
		owned[name] = nil
	end)
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

-- Sorts du grimoire que l'on peut lancer sur un allié, pour la fenêtre de choix
function Z:KnownSpells()
	local spells, seen = {}, {}
	local function add(id)
		local name = id and C_Spell.GetSpellName(id)
		if name and not seen[name] then
			seen[name] = true
			spells[#spells + 1] = { name = name, icon = C_Spell.GetSpellTexture(id), id = id }
		end
	end

	pcall(function()
		local bank = Enum.SpellBookSpellBank.Player
		for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
			for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
				local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
				if item and item.itemType == Enum.SpellBookItemType.Spell and not item.isPassive and not item.isOffSpec then
					local id = item.spellID or item.actionID
					if id and (not C_Spell.IsSpellHelpful or C_Spell.IsSpellHelpful(id)) then add(id) end
				end
			end
		end
	end)

	-- Grimoire illisible : on propose au moins les sorts connus de la classe
	if #spells == 0 then
		for _, ids in pairs(Z.clickDefaults[Z.class] or {}) do
			for _, id in ipairs(ids) do
				if Z.Knows(id) then add(id) end
			end
		end
	end
	table.sort(spells, function(a, b) return a.name < b.name end)
	return spells
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
	for _, binding in ipairs(Z:Bindings()) do
		local value = binding.value
		if value == name then return true end
		local ref = Z.MacroRef(value)
		local macro = ref and Z:FindMacro(ref)
		local body = macro and macro.body or (Z.IsMacro(value) and value)
		if body and body:find(name, 1, true) then return true end
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
	for _, pair in ipairs(Z.raidBuffs[Z.class] or {}) do
		for _, id in ipairs(pair) do
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
		Z:Print(Z.L["nouveau sort sans clic : %s. Onglet Clics des options, bouton « Attribuer »."]:format(table.concat(found, ", ")))
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
