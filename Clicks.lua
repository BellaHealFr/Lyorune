-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Clicks.lua : lancer un sort sur un joueur depuis sa case, à la souris ou au clavier.
--
-- CLICS DE SOURIS. Un clic est identifié par une clé : touche de modification + numéro du bouton.
--   "1" clic gauche, "2" clic droit, "3" clic milieu, "4" et "5" boutons latéraux
--   "shift-1" Maj + clic gauche, "ctrl-2" Ctrl + clic droit, "alt-3" Alt + clic milieu...
--   La valeur est un nom de sort, ou "@target" (cibler), ou "@menu" (menu du joueur).
-- TOUCHES AU SURVOL. Une touche du clavier lance un sort sur la case que survole la souris.
--   Elle ne remplace la touche habituelle que pendant le survol d'une case.
-- MACROS. Une valeur qui commence par « / » est une macro, écrite comme dans le jeu (une commande par ligne).
--   {cible} y désigne le joueur de la case : « /cast [{cible}] Récupération ».
--   Une macro n'est jamais partagée ni importée : chacun écrit les siennes (voir Share.lua).
-- Les clics n'existent que sur les cases de Lyorune : impossible de lancer un sort en cliquant dans le décor.

local _, Z = ...

Z.clickButtons = {
	{ "1", "Clic gauche" },
	{ "2", "Clic droit" },
	{ "3", "Clic milieu" },
	{ "4", "Bouton 4" },
	{ "5", "Bouton 5" },
}
Z.clickModifiers = {
	{ "", "Seul" },
	{ "shift-", "Maj" },
	{ "ctrl-", "Ctrl" },
	{ "alt-", "Alt" },
}
Z.MAX_HOVER_KEYS = 8

function Z:GetClicks()
	local clicks = Z.db.clicks
	clicks[Z.class] = clicks[Z.class] or {}
	return clicks[Z.class]
end

function Z:GetHoverKeys()
	local keys = Z.db.hoverKeys
	keys[Z.class] = keys[Z.class] or {}
	return keys[Z.class]
end

-- Texte lisible d'une clé : "shift-1" -> "Maj + Clic gauche"
function Z:ClickLabel(key)
	local L = Z.L
	local modifier, button = key:match("^(.-)(%d)$")
	local label
	for _, entry in ipairs(Z.clickButtons) do
		if entry[1] == button then label = L[entry[2]] end
	end
	for _, entry in ipairs(Z.clickModifiers) do
		if entry[1] == modifier and modifier ~= "" then label = L[entry[2]] .. " + " .. label end
	end
	return label
end

function Z.IsMacro(value)
	return type(value) == "string" and value:sub(1, 1) == "/"
end

-- Texte envoyé au jeu : {cible} devient la case survolée (celle sur laquelle on clique)
local function MacroText(value)
	local text = value:gsub("@?{cible}", "@mouseover")
	text = text:gsub("@?{target}", "@mouseover")
	return text
end

-- Modèles proposés dans l'éditeur de macro. {sort} est remplacé par le sort du clic au moment du choix.
Z.macroTemplates = {
	{ "Bijou puis soin", "/use 13\n/cast [{cible}] {sort}" },
	{ "Interrompre puis soigner", "/stopcasting\n/cast [{cible}] {sort}" },
	{ "Annonce puis soin", "/p {sort} en cours !\n/cast [{cible}] {sort}" },
}
Z.MACRO_MAX = 240 -- le jeu refuse au-delà de 255 caractères ; on garde une marge pour {cible}

function Z:MacroFromTemplate(index, spell)
	local text = Z.macroTemplates[index][2]:gsub("{sort}", function() return spell end)
	return text
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
	elseif Z.IsMacro(value) then -- macro du joueur : envoyée telle quelle, sans la résurrection automatique
		attributes[prefix .. "type" .. suffix] = "macro"
		attributes[prefix .. "macrotext" .. suffix] = MacroText(value)
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
			local modifier, button = key:match("^(.-)(%d)$")
			if modifier and value and value ~= "" then
				AddAction(attributes, modifier, button, value, resPrefix)
			end
		end
		-- Touches au survol : à l'entrée de la souris, la touche « clique » un bouton virtuel de la case
		for i, entry in ipairs(Z:GetHoverKeys()) do
			local key = entry.key and entry.key:match("^[%w%-]+$") -- jamais autre chose que lettres, chiffres, tirets
			if key and entry.spell and entry.spell ~= "" then
				AddAction(attributes, "*", "-zh" .. i, entry.spell, resPrefix)
				onEnter = onEnter .. (' self:SetBindingClick(true, "%s", self, "zh%d")'):format(key, i)
			end
		end
	end
	attributes["_onenter"] = onEnter

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
			if name ~= "_onenter" then
				count = count + 1
				h:SetAttribute("z-key" .. count, name)
				h:SetAttribute("z-value" .. count, value)
			end
		end
		h:SetAttribute("z-count", count)
		h:SetAttribute("z-onenter", onEnter)
	end
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
