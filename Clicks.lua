-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Clicks.lua : lancer un sort sur un joueur depuis sa case, à la souris ou au clavier.
--
-- CLICS DE SOURIS. Un clic est identifié par une clé : touches de modification + numéro du bouton.
--   "1" clic gauche, "2" clic droit, "3" clic milieu, "4" et "5" boutons latéraux
--   "shift-1" Maj + clic gauche, "ctrl-shift-2" Ctrl + Maj + clic droit, "alt-ctrl-shift-3"...
--   Les modifications s'écrivent toujours dans l'ordre du jeu : alt, ctrl, shift.
--   La valeur est un nom de sort, "@target" (cibler), "@menu" (menu du joueur) ou "@macro:Nom" (une macro
--   de ma bibliothèque, voir Macros.lua).
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

-- Bouton « Copier l'autre spécialisation » : mes clics et touches deviennent ceux de l'autre groupe de talents
function Z:CopyOtherSpec()
	local set = Z:ClickSet()
	local other = set == Z.class and Z.class .. "2" or Z.class
	Z.db.clicks[set] = CopyTable(Z.db.clicks[other] or {})
	Z.db.hoverKeys[set] = CopyTable(Z.db.hoverKeys[other] or {})
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
	local clicks = Z:GetClicks()
	for _, button in ipairs(Z.clickButtons) do
		for _, modifier in ipairs(Z.clickModifiers) do
			local key = modifier[1] .. button[1]
			local value = clicks[key]
			if value and value ~= "" then list[#list + 1] = { kind = "click", key = key, value = value } end
		end
	end
	for index, entry in ipairs(Z:GetHoverKeys()) do
		if entry.key then list[#list + 1] = { kind = "key", key = entry.key, value = entry.spell or "", index = index } end
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
	-- une touche garde sa place dans la liste : on la renomme au lieu de la retirer puis de l'ajouter
	if from.kind == "key" and to.kind == "key" and not other then
		for _, entry in ipairs(Z:GetHoverKeys()) do
			if entry.key == from.key then entry.key = to.key end
		end
		return Z:ApplyClicks()
	end
	Z:SetBinding(from, other, true)
	Z:SetBinding(to, moving, true)
	Z:ApplyClicks()
end

-- Texte lisible de ce que fait un clic : sort, cibler, menu, ou macro (en jaune, en rouge si elle n'existe plus)
function Z:ActionText(value)
	local L = Z.L
	if value == "@target" then return L["Cibler"] end
	if value == "@menu" then return L["Menu du joueur"] end
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
		if binding.value ~= "" then list[#list + 1] = { Z:TriggerLabel(binding), Z:ActionText(binding.value) } end
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

-- Ajoute à « attributes » ce qu'il faut pour que le bouton « suffix » lance « value »
local function AddAction(attributes, prefix, suffix, value, resPrefix)
	if value == "@target" then
		attributes[prefix .. "type" .. suffix] = "target"
	elseif value == "@menu" then
		attributes[prefix .. "type" .. suffix] = "togglemenu"
	elseif Z.MacroRef(value) then -- une macro de ma bibliothèque, sans la résurrection automatique
		local macro = Z:FindMacro(Z.MacroRef(value))
		if macro and macro.body:find("%S") then
			attributes[prefix .. "type" .. suffix] = "macro"
			attributes[prefix .. "macrotext" .. suffix] = Z:ResolveMacro(macro.body)
		end
	elseif Z.IsMacro(value) then -- macro écrite sur le clic (avant la 1.6.0, rangée ensuite dans la bibliothèque)
		attributes[prefix .. "type" .. suffix] = "macro"
		attributes[prefix .. "macrotext" .. suffix] = Z:ResolveMacro(value)
	elseif resPrefix then
		attributes[prefix .. "type" .. suffix] = "macro"
		attributes[prefix .. "macrotext" .. suffix] = "/cast " .. resPrefix .. "[@mouseover] " .. value
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
	local onEnter = "self:ClearBindings()"

	if not Z.db.externalClicks then
		-- Clics de souris
		for key, value in pairs(Z:GetClicks()) do
			local modifier, button = Z.ParseClickKey(key)
			if modifier and value and value ~= "" then
				AddAction(attributes, modifier, button, value, resPrefix)
			end
		end
		-- Touches au survol : à l'entrée de la souris, la touche « clique » un bouton virtuel de la case
		for i, entry in ipairs(Z:GetHoverKeys()) do
			local key = Z.ValidKey(entry.key) and entry.key -- jamais de guillemet ni d'antislash dans le code sécurisé
			if key and entry.spell and entry.spell ~= "" then
				AddAction(attributes, "*", "-zh" .. i, entry.spell, resPrefix)
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
	if Z.RefreshClicks then Z.RefreshClicks() end
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
