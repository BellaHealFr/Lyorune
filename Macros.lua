-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Macros.lua : ma bibliothèque de macros, posées sur les clics et les touches au survol.
--
-- RANGEMENT. Les macros sont rangées par classe, communes à toutes les spécialisations :
--   Z.db.macros.PRIEST = { { name = "Bijou et soin", body = "/use 13\n/cast Soins rapides" }, ... }
--   Un clic ou une touche qui en utilise une porte la valeur « @macro:Nom ». Modifier la macro change
--   tous ses clics, dans chaque spécialisation. Rien n'est écrit dans la fenêtre /macro du jeu, sauf une copie
--   « Lyo:Nom » quand le joueur glisse la macro vers une barre de sorts (voir Clicks.lua, Z:PickupGameCopy).
-- VISER LA CASE. Le joueur de la case s'écrit {cible} ou @cible. Avec l'option « macroAutoTarget »
--   (cochée d'origine), une commande sans cible (/cast Récupération) vise la case toute seule, et
--   [@mouseover] marche tel quel : sur une case, le joueur survolé est celui de la case.
-- SPÉCIALISATIONS. Chaque spécialisation a ses propres clics (Clicks.lua) : elle pose les macros qu'elle veut.
--   Une même macro peut aussi s'adapter d'elle-même avec la condition du jeu [spec:1] ou [spec:2].
-- PARTAGE. Une macro n'est jamais exportée ni importée par un code de partage (voir Share.lua).

local _, Z = ...
local UI = Z.UI
local L = Z.L

Z.MACRO_LINE = 255   -- longueur d'une ligne de commande acceptée par le jeu
Z.MACRO_MAX = 255    -- longueur totale d'une macro : depuis le patch 11.0.2, le texte d'un bouton sécurisé
                     -- (« macrotext ») ne dépasse pas 255 caractères, comme une macro de /macro
local EDIT_MAX = 1023 -- la zone d'écriture garde le texte d'une ancienne macro plus longue (signalée en rouge)
Z.MACRO_NAME = 32    -- longueur d'un nom de macro, en octets
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

----------------------------------------------------------------------------------------------------
-- La bibliothèque
----------------------------------------------------------------------------------------------------
function Z:GetMacros()
	local all = Z.db.macros
	all[Z.class] = all[Z.class] or {}
	return all[Z.class]
end

-- « @macro:Nom » -> « Nom »
function Z.MacroRef(value)
	return type(value) == "string" and value:match("^@macro:(.+)$") or nil
end

-- Coupe un texte à « bytes » octets sans abîmer une lettre accentuée
function Z.CutText(text, bytes)
	if #text <= bytes then return text end
	local cut = bytes
	while cut > 0 and text:byte(cut + 1) >= 128 and text:byte(cut + 1) < 192 do cut = cut - 1 end
	return text:sub(1, cut)
end

local function CleanName(name)
	name = tostring(name or ""):gsub("%c", ""):match("^%s*(.-)%s*$")
	return Z.CutText(name, Z.MACRO_NAME)
end

function Z:FindMacro(name)
	if not name then return nil end
	local wanted = name:lower()
	for index, macro in ipairs(Z:GetMacros()) do
		if macro.name:lower() == wanted then return macro, index end
	end
end

-- Un nom libre : « Soins », sinon « Soins 2 », « Soins 3 »...
function Z:FreeMacroName(base)
	base = CleanName(base)
	if base == "" then base = L["Macro"] end
	if not Z:FindMacro(base) then return base end
	local i = 2
	while Z:FindMacro(Z.CutText(base, Z.MACRO_NAME - 3) .. " " .. i) do i = i + 1 end
	return Z.CutText(base, Z.MACRO_NAME - 3) .. " " .. i
end

function Z:NewMacro(name, body)
	local macro = { name = Z:FreeMacroName(name), body = body or "" }
	table.insert(Z:GetMacros(), macro)
	return macro
end

-- Chaque clic et touche de ma classe (toutes spécialisations) qui porte « value » reçoit « newValue »
local function ReplaceValue(value, newValue)
	for _, set in ipairs(Z:ClickSets()) do
		local clicks = Z.db.clicks[set] or {}
		for key, v in pairs(clicks) do
			if v == value then clicks[key] = newValue end
		end
		for _, entry in ipairs(Z.db.hoverKeys[set] or {}) do
			if entry.spell == value then entry.spell = newValue or "" end
		end
	end
end

-- Renvoie true, ou false et la raison du refus
function Z:RenameMacro(macro, newName)
	newName = CleanName(newName)
	if newName == "" or newName == macro.name then return true end
	local other = Z:FindMacro(newName)
	if other and other ~= macro then return false, L["Une autre macro porte déjà ce nom."] end
	ReplaceValue("@macro:" .. macro.name, "@macro:" .. newName)
	Z:MoveGameCopy(macro.name, newName) -- sa copie de /macro suit (Clicks.lua)
	macro.name = newName
	Z:ApplyClicks()
	return true
end

function Z:RemoveMacro(macro)
	local _, index = Z:FindMacro(macro.name)
	if not index then return end
	table.remove(Z:GetMacros(), index)
	ReplaceValue("@macro:" .. macro.name, nil)
	Z:ApplyClicks()
end

-- Où la macro est posée, dans la spécialisation active : { "Maj + Clic droit", "touche F" }
function Z:MacroUses(macro)
	local value, uses, keys = "@macro:" .. macro.name, {}, {}
	for key, v in pairs(Z:GetClicks()) do
		if v == value then keys[#keys + 1] = key end
	end
	table.sort(keys)
	for _, key in ipairs(keys) do uses[#uses + 1] = Z:ClickLabel(key) end
	for _, entry in ipairs(Z:GetHoverKeys()) do
		if entry.spell == value and entry.key then uses[#uses + 1] = L["touche"] .. " " .. Z:KeyLabel(entry.key) end
	end
	return uses
end

----------------------------------------------------------------------------------------------------
-- Texte envoyé au jeu
----------------------------------------------------------------------------------------------------
-- Commandes qui visent un joueur : sans cible écrite, elles visent la case (option « macroAutoTarget »)
local AIMED = { cast = true, use = true, castsequence = true, castrandom = true, userandom = true,
	lancer = true, utiliser = true, target = true, tar = true, focus = true, assist = true,
	cibler = true, focaliser = true, assister = true }
local UNIT_COMMANDS = { target = true, tar = true, focus = true, assist = true, cibler = true, focaliser = true, assister = true }

-- « [help] Soins » -> « [help,@mouseover] Soins » ; « Soins » -> « [@mouseover] Soins »
local function AimClause(clause, unitCommand, first)
	local lead, rest = clause:match("^(%s*)(.*)$")
	if first and lead == "" then lead = " " end
	local groups, found = "", false
	while true do
		local group, after = rest:match("^(%b[])%s*(.*)$")
		if not group then break end
		found = true
		if not (group:find("@", 1, true) or group:lower():find("target%s*=")) then
			local inner = group:sub(2, -2):match("^%s*(.-)%s*$")
			group = "[" .. (inner == "" and "@mouseover" or inner .. ",@mouseover") .. "]"
		end
		groups = groups .. group
		rest = after
	end
	if not found then
		-- rien à viser, un emplacement d'objet (/use 13), ou un joueur déjà nommé (/focus mouseover)
		if (rest == "" and not unitCommand) or rest:match("^%d+$") or (unitCommand and rest ~= "") then return clause end
		groups = "[@mouseover]"
	end
	return lead .. groups .. (rest ~= "" and " " .. rest or "")
end

function Z:ResolveMacro(body)
	local text = tostring(body or "")
	text = text:gsub("@{cible}", "@mouseover"):gsub("@{target}", "@mouseover"):gsub("@cible%f[^%w_]", "@mouseover")
	text = text:gsub("%b[]", function(group) return (group:gsub("{cible}", "@mouseover"):gsub("{target}", "@mouseover")) end)
	text = text:gsub("{cible}", "mouseover"):gsub("{target}", "mouseover")
	if not Z.db.macroAutoTarget then return text end
	local lines = {}
	for line in (text .. "\n"):gmatch("([^\n]*)\n") do
		local slash, command, rest = line:match("^(%s*/)(%S+)(.*)$")
		if command and AIMED[command:lower()] then
			local clauses, unitCommand = {}, UNIT_COMMANDS[command:lower()]
			for clause in (rest .. ";"):gmatch("([^;]*);") do
				clauses[#clauses + 1] = AimClause(clause, unitCommand, #clauses == 0)
			end
			line = slash .. command .. table.concat(clauses, ";")
		end
		lines[#lines + 1] = line
	end
	return table.concat(lines, "\n")
end

----------------------------------------------------------------------------------------------------
-- Vérification en direct : renvoie une liste de { "err" ou "warn", texte }
----------------------------------------------------------------------------------------------------
local CONDITIONS = {}
for word in ([[help harm exists dead combat mod modifier button btn channeling equipped worn flying flyable
	advflyable indoors outdoors mounted swimming stealth stance form group party raid pet actionbar bar bonusbar
	extrabar overridebar possessbar shapeshift vehicleui unithasvehicleui canexitvehicle petbattle spec talent
	known resting cursor pvptalent]]):gmatch("%S+") do CONDITIONS[word] = true end
local MODIFIERS = { shift = true, ctrl = true, alt = true, lshift = true, rshift = true, lctrl = true, rctrl = true, lalt = true, ralt = true }
local CODE = { run = true, script = true, console = true }
local CASTS = { cast = true, lancer = true, castsequence = true, castrandom = true }

-- Le personnage connaît-il ce sort, dans sa spécialisation active ? (sans réponse du jeu : on ne signale rien)
local function KnowsName(name)
	if not (C_Spell and C_Spell.GetSpellInfo) then return true end
	local ok, info = pcall(C_Spell.GetSpellInfo, name)
	return not ok or info ~= nil
end

-- Nom du grimoire (spécialisation active) qui ne diffère de name que par les accents ou les majuscules : le client
-- écrit parfois un sort sans accent (« Epines »), et /cast Épines ne lance alors rien
local function GrimoireSpelling(name)
	local plain = Z.SearchText and Z.SearchText(name)
	if not plain then return end
	local found
	pcall(function()
		local bank = Enum.SpellBookSpellBank.Player
		for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
			for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
				local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
				local id = item and item.itemType == Enum.SpellBookItemType.Spell and not item.isPassive
					and not item.isOffSpec and item.spellID
				local spell = id and C_Spell.GetSpellName(id)
				if spell and spell ~= name and Z.SearchText(spell) == plain then
					found = spell
					return
				end
			end
		end
	end)
	return found
end

local function Split(text)
	local lines = {}
	for line in (text .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
	return lines
end

function Z:CheckMacro(body)
	local problems = {}
	local function add(level, text, ...) problems[#problems + 1] = { level, L[text]:format(...) } end
	body = body or ""
	if not body:find("%S") then
		add("err", "La macro est vide.")
		return problems
	end
	local resolved = Z:ResolveMacro(body)
	if #resolved > Z.MACRO_MAX then
		add("err", "Trop longue : %d caractères, %d au plus.", #resolved, Z.MACRO_MAX)
	elseif #Z:BarText(body) > Z.MACRO_MAX then -- la copie pour une barre ajoute la cible : elle peut dépasser
		add("warn", "Trop longue pour une barre de sorts du jeu : %d caractères, %d au plus. Elle reste bonne pour vos clics.", #Z:BarText(body), Z.MACRO_MAX)
	end
	local real, commands = Split(resolved), 0
	for n, line in ipairs(Split(body)) do
		if real[n] and #real[n] > Z.MACRO_LINE then
			add("err", "Ligne %d trop longue : %d caractères, %d au plus.", n, #real[n], Z.MACRO_LINE)
		end
		if select(2, line:gsub("%[", "")) ~= select(2, line:gsub("%]", "")) then
			add("err", "Ligne %d : un crochet [ ] n'est pas fermé.", n)
		end
		local command, rest = line:match("^%s*/(%S+)%s*(.*)$")
		if command then
			commands = commands + 1
			command = command:lower()
			if CODE[command] then
				add("warn", "Ligne %d : /%s exécute du code. Gardez-la seulement si vous savez d'où elle vient.", n, command)
			end
			-- Conditions entre crochets : un mot inconnu est sans doute une faute de frappe
			for group in line:gmatch("%[([^%]]*)%]") do
				for token in group:gmatch("[^,]+") do
					token = token:match("^%s*(.-)%s*$")
					if token ~= "" and token:sub(1, 1) ~= "@" and not token:lower():find("^target%s*=") then
						-- « [:shift] » (mot effacé pendant la frappe) : mot vide, signalé comme inconnu
						local word = token:lower():match("^([^:]*)"):match("^%s*(.-)%s*$")
						local base = word:match("^no(.+)$")
						if not CONDITIONS[word] and not (base and CONDITIONS[base]) then
							add("warn", "Ligne %d : condition « %s » inconnue (faute de frappe ?).", n, token)
						elseif word == "mod" or word == "modifier" or base == "mod" or base == "modifier" then
							for value in (token:match(":(.+)$") or ""):gmatch("[^/]+") do
								value = value:match("^%s*(.-)%s*$")
								if not MODIFIERS[value:lower()] and not value:match("^[%u_]+$") then
									add("warn", "Ligne %d : touche « %s » inconnue (shift, ctrl ou alt).", n, value)
								end
							end
						end
					end
				end
			end
			-- Sorts lancés : un sort inconnu est peut-être celui de l'autre spécialisation
			if CASTS[command] then
				for clause in (rest .. ";"):gmatch("([^;]*);") do
					clause = clause:gsub("%b[]", ""):gsub("reset=%S+", "")
					for spell in clause:gmatch("[^,]+") do
						spell = spell:match("^%s*!?(.-)%s*$"):gsub("%(.-%)$", "")
						if spell ~= "" and not tonumber(spell) and not KnowsName(spell) then
							local right = GrimoireSpelling(spell)
							if right then -- même nom, autres accents : corrigé par « Corriger l'écriture »
								add("warn", "Ligne %d : « %s » s'écrit « %s » dans votre grimoire.", n, spell, right)
								problems.fixes = problems.fixes or {}
								problems.fixes[#problems.fixes + 1] = { spell, right }
							else
								add("warn", "Ligne %d : « %s » n'est pas connu dans votre spécialisation active.", n, spell)
							end
						end
					end
				end
			end
		elseif line:find("%S") and not line:match("^%s*#") then
			add("err", "Ligne %d : une commande commence par une barre oblique, par exemple /cast.", n)
		end
	end
	if commands == 0 then add("err", "Aucune commande : une macro commence par une barre oblique, par exemple /cast.") end
	return problems
end

-- Macro où chaque nom de sort mal écrit (accents, majuscules) prend l'écriture du grimoire, comme mot entier
function Z:FixMacroSpelling(body)
	for _, fix in ipairs(Z:CheckMacro(body).fixes or {}) do body = Z.ReplaceWord(body, fix[1], fix[2]) end
	return body
end

-- Icône : celle du premier sort ou objet de la macro
function Z:MacroIcon(body)
	for line in ((body or "") .. "\n"):gmatch("([^\n]*)\n") do
		local command, rest = line:match("^%s*/(%S+)%s*(.*)$")
		command = command and command:lower()
		if command and (CASTS[command] or command == "use" or command == "utiliser") then
			local first = rest:gsub("%b[]", ""):gsub("reset=%S+", ""):match("^%s*!?([^;,]+)")
			first = first and first:match("^(.-)%s*$")
			if first and first ~= "" then
				local slot = tonumber(first)
				local icon = slot and GetInventoryItemTexture and GetInventoryItemTexture("player", slot)
					or not slot and C_Spell.GetSpellTexture(first)
				if icon then return icon end
			end
		end
	end
	return QUESTION
end

----------------------------------------------------------------------------------------------------
-- Copie pour une barre de sorts du jeu : là, il n'y a pas de case. Chaque groupe qui vise le joueur survolé est
-- suivi du même groupe sans lui, qui vise la cible (sinon vous, selon le réglage du jeu « lancer sur soi »).
--   « [@mouseover,harm] Châtiment »  -> « [@mouseover,harm][harm] Châtiment »
--   « [@mouseover] Soins rapides »   -> « [@mouseover,help][] Soins rapides » (un soin ne vise pas un ennemi)
--   « [@mouseover] 13 » (/use)       -> « [@mouseover,exists][] 13 »
----------------------------------------------------------------------------------------------------
local function Hovered(item)
	item = item:lower()
	return item == "@mouseover" or item:match("^target%s*=%s*mouseover$") ~= nil
end

-- Le sort d'une clause aide-t-il un allié ? (sans réponse du jeu : non, la clause vise alors tout joueur survolé)
local function Helpful(clause)
	local name = clause:gsub("%b[]", ""):gsub("reset=%S+", ""):match("^%s*!?([^,]+)")
	name = name and name:match("^(.-)%s*$")
	if not (name and name ~= "" and not tonumber(name) and C_Spell and C_Spell.IsSpellHelpful) then return false end
	local ok, helpful = pcall(C_Spell.IsSpellHelpful, name)
	return ok and helpful == true
end

local function BarClause(clause, cast)
	local lead, rest = clause:match("^(%s*)(.*)$")
	local out, pending, seen = "", {}, {}
	local alone = cast and Helpful(rest) and "help" or "exists"
	local function Add(group)
		if not seen[group] then
			seen[group] = true
			out = out .. group
		end
	end
	local function Flush()
		for _, group in ipairs(pending) do Add(group) end
		pending = {}
	end
	while true do
		local group, after = rest:match("^(%b[])%s*(.*)$")
		if not group then break end
		local items, others, hovered = {}, {}, false
		for item in group:sub(2, -2):gmatch("[^,]+") do
			item = item:match("^%s*(.-)%s*$")
			if item ~= "" then
				items[#items + 1] = item
				if Hovered(item) then hovered = true else others[#others + 1] = item end
			end
		end
		if hovered then
			if #others == 0 then items[#items + 1] = alone end
			Add("[" .. table.concat(items, ",") .. "]")
			pending[#pending + 1] = "[" .. table.concat(others, ",") .. "]"
		else
			Flush()
			Add(group)
		end
		rest = after
	end
	Flush()
	if out == "" then return clause end
	return lead .. out .. (rest ~= "" and " " .. rest or "")
end

function Z:BarText(body)
	local lines = {}
	for line in (Z:ResolveMacro(body) .. "\n"):gmatch("([^\n]*)\n") do
		local slash, command, rest = line:match("^(%s*/)(%S+)(.*)$")
		local lower = command and command:lower()
		if lower and AIMED[lower] and not UNIT_COMMANDS[lower] then
			local clauses = {}
			for clause in (rest .. ";"):gmatch("([^;]*);") do clauses[#clauses + 1] = BarClause(clause, CASTS[lower]) end
			line = slash .. command .. table.concat(clauses, ";")
		end
		lines[#lines + 1] = line
	end
	local text = table.concat(lines, "\n")
	-- l'icône « ? » de la copie montre alors le sort en cours et son infobulle, si la place le permet
	if not text:find("^%s*#show") and #text + 13 <= Z.MACRO_MAX then text = "#showtooltip\n" .. text end
	return text
end

----------------------------------------------------------------------------------------------------
-- Assistant : une macro écrite à partir de cases à cocher
--   opts = { spell = "Soins rapides", stop = true, trinket1 = true, trinket2 = false, res = true, harm = "Châtiment" }
----------------------------------------------------------------------------------------------------
function Z:MacroFromWizard(opts)
	local lines, parts = {}, {}
	if opts.stop then lines[#lines + 1] = "/stopcasting" end
	if opts.trinket1 then lines[#lines + 1] = "/use 13" end
	if opts.trinket2 then lines[#lines + 1] = "/use 14" end
	local res = opts.res and Z.classRes[Z.class]
	if res then
		if res.combat and Z.Knows(res.combat) then parts[#parts + 1] = "[@cible,help,dead,combat] " .. Z.SpellName(res.combat) end
		if res[1] and Z.Knows(res[1]) then parts[#parts + 1] = "[@cible,help,dead] " .. Z.SpellName(res[1]) end
	end
	local harm = opts.harm and opts.harm:match("^%s*(.-)%s*$")
	if harm and harm ~= "" then parts[#parts + 1] = "[@cible,harm,nodead] " .. harm end
	if opts.spell and opts.spell ~= "" then parts[#parts + 1] = "[@cible] " .. opts.spell end
	if #parts > 0 then lines[#lines + 1] = "/cast " .. table.concat(parts, "; ") end
	return table.concat(lines, "\n")
end

----------------------------------------------------------------------------------------------------
-- Venues d'ailleurs : la fenêtre /macro du jeu, le grimoire, les anciennes versions
----------------------------------------------------------------------------------------------------
-- Copie une macro de la fenêtre /macro dans la bibliothèque (la même déjà copiée est réutilisée)
function Z:ImportGameMacro(index)
	local name, _, body = GetMacroInfo(index)
	if not name or not body then return nil end
	local mine = Z:CopyOwner(name) -- la copie « Lyo: » d'une macro de la bibliothèque : c'est elle
	if mine then return mine end
	local same = Z:FindMacro(name)
	if same and same.body == body then return same end
	return Z:NewMacro(name, body)
end

-- Ce que le joueur tient sous la souris (sort du grimoire, macro de /macro) devient une valeur de clic
function Z:TakeCursor()
	if not GetCursorInfo then return nil end
	local kind, a, _, spellID = GetCursorInfo()
	local value
	if kind == "spell" then
		value = spellID and C_Spell.GetSpellName(spellID)
		if value and Z.IsLowRank(spellID) then value = "#" .. spellID end -- un rang inférieur glissé reste ce rang
	elseif kind == "macro" then
		local macro = Z:ImportGameMacro(a)
		value = macro and "@macro:" .. macro.name
	end
	if value and ClearCursor then ClearCursor() end
	return value
end

-- Avant la 1.6.0 : une macro écrite sur un clic (« /... ») ou le nom d'une macro de /macro (« @macro:Nom »).
-- Les deux rejoignent la bibliothèque. withGame : les macros du jeu sont chargées, on peut les lire.
function Z:MigrateMacros(withGame)
	local changed = false
	local function Convert(value, label)
		if Z.IsMacro(value) then
			changed = true
			return "@macro:" .. Z:NewMacro(label, value).name
		end
		local ref = Z.MacroRef(value)
		if ref and withGame and not Z:FindMacro(ref) and GetMacroIndexByName then
			local index = GetMacroIndexByName(ref)
			local body = index and index > 0 and GetMacroBody(index)
			if body and body ~= "" then
				changed = true
				return "@macro:" .. Z:NewMacro(ref, body).name
			end
		end
		return value
	end
	for _, set in ipairs(Z:ClickSets()) do
		local clicks = Z.db.clicks[set]
		for key, value in pairs(clicks or {}) do clicks[key] = Convert(value, Z:ClickLabel(key)) end
		for _, entry in ipairs(Z.db.hoverKeys[set] or {}) do
			entry.spell = Convert(entry.spell, L["Touche"] .. " " .. tostring(entry.key))
		end
	end
	return changed
end

----------------------------------------------------------------------------------------------------
-- Fenêtre « Mes macros »
----------------------------------------------------------------------------------------------------
local win, wizard, importer, dragIcon
local ROWS = 13
local LINE = 13 -- hauteur d'une ligne de texte de 11 avec l'interligne de 2

local function Refresh() if win and win:IsShown() then win.Refresh() end end
-- Les clics suivent, et « Annuler mes changements » paraît (Z.RefreshClicks prévient le bas des options)
local function ClicksChanged() if Z.RefreshClicks then Z.RefreshClicks() end end
local function Dim(text) return "|cff" .. UI.Hex("dim") .. text .. "|r" end

-- Glisser une macro de la liste sur une case de l'onglet Clics (ou une touche au survol)
local function StopDrag()
	if not (dragIcon and dragIcon:IsShown()) then return end
	dragIcon:Hide()
	dragIcon:SetScript("OnUpdate", nil)
	local foci = GetMouseFoci and GetMouseFoci() or { GetMouseFocus and GetMouseFocus() }
	for _, focus in ipairs(foci) do
		local target, depth = focus, 0
		while target and not target.dropValue and depth < 3 do
			target, depth = target.GetParent and target:GetParent(), depth + 1
		end
		if target and target.dropValue then
			target.dropValue("@macro:" .. dragIcon.name)
			ClicksChanged()
			Refresh()
			return true
		end
	end
end

-- Hors combat, la macro part en main comme une macro de /macro (sa copie « Lyo: », créée ou mise à jour) : elle se
-- dépose dans une barre de sorts du jeu, ou sur une ligne de Lyorune qui la reconnaît (Z:CopyOwner). Sinon, ou
-- quand la copie est refusée (combat, trop longue, plus de place), seules les lignes de Lyorune la prennent.
local function StartDrag(row)
	if not row.macro then return end
	if win then win.SaveCurrent() end -- la copie part avec le texte en cours d'écriture
	local held, why = Z:PickupGameCopy(row.macro)
	if held then return end
	if why then Z:Print(why) end
	if not dragIcon then
		dragIcon = CreateFrame("Frame", nil, UIParent)
		dragIcon:SetSize(30, 30)
		dragIcon:SetFrameStrata("TOOLTIP")
		dragIcon.texture = dragIcon:CreateTexture(nil, "ARTWORK")
		dragIcon.texture:SetAllPoints()
		dragIcon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	dragIcon.name = row.macro.name
	dragIcon.texture:SetTexture(Z:MacroIcon(row.macro.body))
	dragIcon:SetScript("OnUpdate", function(self)
		local x, y = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		self:ClearAllPoints()
		self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
	end)
	dragIcon:Show()
end

local function Field(parent, text, x, y)
	local label = UI.Text(parent, 11)
	label:SetPoint("TOPLEFT", x, y)
	UI.Paint(label, "accent")
	label:SetText(L[text])
	return label
end

local function Block(parent, x, y, width, size)
	local text = UI.Text(parent, size or 11)
	text:SetPoint("TOPLEFT", x, y)
	text:SetWidth(width)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	text:SetSpacing(2)
	return text
end

-- Zone de texte de hauteur fixe (« lines » lignes) : le texte en trop est coupé par le jeu et se lit en entier
-- dans l'infobulle. Jamais de texte qui passe sur la zone suivante.
local function Zone(parent, x, y, width, lines)
	local text = Block(parent, x, y, width)
	text:SetHeight(lines * LINE)
	text:SetMaxLines(lines)
	text.lines = lines
	local hover = CreateFrame("Frame", nil, parent)
	hover:SetAllPoints(text)
	hover:EnableMouse(true)
	hover:SetScript("OnEnter", function(self)
		local full = text:GetText() or ""
		if not (text:IsTruncated() or select(2, full:gsub("\n", "")) >= lines) then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(full, UI.text[1], UI.text[2], UI.text[3], 1, true)
		GameTooltip:Show()
	end)
	hover:SetScript("OnLeave", function() GameTooltip:Hide() end)
	text.hover = hover
	return text
end

-- Ce que dit la consigne sous la liste : glisser une macro sur une ligne des options, sauf quand les options
-- sont effacées le temps de cette fenêtre (écran trop étroit pour les deux) : aucune ligne où la glisser
local function HintText()
	return UI.Away() and L["Glissez une macro dans une barre de sorts du jeu. Pour un clic, fermez cette fenêtre : les options reviennent, cliquez alors sur le sort d'une ligne."]
		or L["Glissez une macro sur une ligne du chapitre Sorts et raccourcis ou dans une barre de sorts du jeu, ou cliquez sur le sort d'une ligne."]
end

local function BuildWindow()
	win = UI.Window("LyoruneMacros", L["Mes macros"], 620, 530)
	win:SetFrameStrata("FULLSCREEN_DIALOG")
	win.beside = true -- à côté des options, sans les recouvrir
	tinsert(UISpecialFrames, "LyoruneMacros")
	win.offset = 0

	-- Colonne de gauche : la liste
	local new = UI.Button(win, L["Nouvelle"], 84, 22, function()
		win.SaveCurrent()
		win.Select(Z:NewMacro(L["Macro"], "/cast [@cible] "))
	end)
	new:SetPoint("TOPLEFT", 14, -44)
	new.label:SetJustifyH("CENTER")
	local assistant = UI.Button(win, L["Assistant..."], 96, 22, function() Z:OpenMacroWizard() end)
	assistant:SetPoint("LEFT", new, "RIGHT", 6, 0)
	assistant.label:SetJustifyH("CENTER")
	assistant.tip = L["Une macro écrite pour vous : cochez ce que vous voulez, Lyorune écrit le texte."]
	local import = UI.Button(win, L["Importer de /macro..."], 186, 22, function() Z:OpenMacroImport() end)
	import:SetPoint("TOPLEFT", 14, -70)
	import.label:SetJustifyH("CENTER")
	import.tip = L["Copie une macro de la fenêtre /macro du jeu. Vous pouvez aussi la glisser depuis /macro sur cette liste."]

	local list = CreateFrame("Frame", nil, win)
	list:SetPoint("TOPLEFT", 14, -98)
	list:SetSize(186, ROWS * 24)
	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", function(_, delta)
		win.offset = math.max(0, math.min(win.offset - delta, #Z:GetMacros() - ROWS))
		win.Refresh()
	end)
	local function ReceiveGameMacro()
		local kind, index = GetCursorInfo and GetCursorInfo()
		if kind ~= "macro" then return end
		local macro = Z:ImportGameMacro(index)
		if ClearCursor then ClearCursor() end
		if macro then win.Select(macro) end
	end
	list:SetScript("OnReceiveDrag", ReceiveGameMacro)
	win.rows = {}
	for i = 1, ROWS do
		local row = UI.Button(list, "", 186, 22, function(self)
			if GetCursorInfo and GetCursorInfo() == "macro" then return ReceiveGameMacro() end
			if self.macro then
				win.SaveCurrent()
				win.Select(self.macro)
			end
		end)
		row:SetPoint("TOPLEFT", 0, -(i - 1) * 24)
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(16, 16)
		row.icon:SetPoint("LEFT", 4, 0)
		row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.label:ClearAllPoints()
		row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
		row.label:SetPoint("RIGHT", -4, 0)
		-- Macro ouverte : bordure d'or à part (le fond d'un bouton est caché en Classique et MMORPG, et repeint à
		-- chaque changement de thème)
		row.mark = UI.Paint(UI.Border(row, 1), "accent")
		row.mark:Hide()
		row:RegisterForDrag("LeftButton")
		row:SetScript("OnDragStart", StartDrag)
		row:SetScript("OnDragStop", StopDrag)
		row:SetScript("OnReceiveDrag", ReceiveGameMacro)
		win.rows[i] = row
	end
	-- Aucune macro : une phrase sous les boutons, pas un bouton qui ne fait rien
	win.empty = Block(win, 14, -98, 186)
	UI.Paint(win.empty, "dim")
	win.empty:SetText(L["Aucune macro : cliquez sur Nouvelle."])
	-- Plus de macros que de lignes : la molette fait défiler la liste
	win.more = Block(win, 14, -98 - ROWS * 24 - 4, 186)
	UI.Paint(win.more, "dim")
	win.hint = Block(win, 14, -98 - ROWS * 24 - 22, 186)
	win.hint:SetMaxLines(5)
	UI.Paint(win.hint, "dim")
	win.hint:SetText(HintText())

	-- Colonne de droite : la macro choisie. Chaque zone a sa hauteur, posée sous la précédente.
	local x, width = 216, 390
	Field(win, "Nom", x, -46)
	win.name = UI.Edit(win, width - 50, function(text)
		if not win.macro then return end
		local ok, why = Z:RenameMacro(win.macro, text)
		if not ok then Z:Print(why) end
		win.name:SetText(win.macro.name) -- nom vide, coupé ou refusé : le champ montre le vrai nom
		win.Refresh()
		ClicksChanged()
	end)
	win.name:SetPoint("TOPLEFT", x + 50, -42)

	-- Zone où l'on écrit : elle défile, le curseur reste visible
	local box = CreateFrame("Frame", nil, win)
	box:SetPoint("TOPLEFT", x, -72)
	box:SetSize(width, 120)
	box.bg = UI.Paint(UI.Tex(box, "BACKGROUND"), "panel")
	box.bg:SetAllPoints()
	box.border = UI.Border(box, 1)
	UI.Paint(box.border, "line")
	UI.Field(box, box.bg, box.border) -- zone de texte habillée selon le thème
	local scroll = CreateFrame("ScrollFrame", nil, box)
	scroll:SetPoint("TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", -6, 6)
	scroll:SetSize(width - 12, 120 - 12)
	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetAutoFocus(false)
	edit:SetFont(UI.Font(), 12, "")
	UI.Paint(edit, "text") -- sans couleur, le jeu écrit en blanc pur
	edit:SetMaxLetters(EDIT_MAX)
	edit:SetWidth(width - 12)
	edit:SetHeight(120 - 12)
	scroll:SetScrollChild(edit)
	edit:SetScript("OnEscapePressed", edit.ClearFocus)
	edit:SetScript("OnHide", edit.ClearFocus) -- fenêtre fermée pendant la frappe : le clavier revient au jeu
	edit:SetScript("OnCursorChanged", function(_, _, y, _, h)
		local top, view = scroll:GetVerticalScroll() or 0, scroll:GetHeight() or 0
		y = -(y or 0)
		if y < top then
			scroll:SetVerticalScroll(y)
		elseif y + (h or 0) > top + view then
			scroll:SetVerticalScroll(y + (h or 0) - view)
		end
	end)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local range = self:GetVerticalScrollRange() or 0
		self:SetVerticalScroll(math.max(0, math.min(range, (self:GetVerticalScroll() or 0) - delta * 2 * LINE)))
	end)
	box:EnableMouse(true)
	box:SetScript("OnMouseDown", function() edit:SetFocus() end)
	win.edit, win.scroll = edit, scroll
	win.count = UI.Text(win, 11)
	win.count:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 0, -4)
	UI.Paint(win.count, "dim")
	win.help = Zone(win, x, -198, width - 70, 2)
	UI.Paint(win.help, "dim")

	Field(win, "Vérification", x, -230)
	win.others = UI.Text(win, 11) -- « et 3 autres » : au bout du titre, hors de la zone
	win.others:SetPoint("TOPRIGHT", win, "TOPLEFT", x + width, -230)
	UI.Paint(win.others, "dim")
	win.problems = Zone(win, x, -246, width, 6)
	-- Un sort écrit avec d'autres accents que dans le grimoire : un clic le corrige
	win.fix = UI.Button(win, L["Corriger l'écriture"], 150, 18, function()
		edit:SetText(Z:FixMacroSpelling(edit:GetText()))
		win.Live()
		win.SaveCurrent()
		win.Refresh()
	end)
	win.fix:SetPoint("TOPLEFT", x + 96, -227)
	win.fix.label:SetJustifyH("CENTER")
	win.fix.tip = L["Écrit chaque sort signalé comme dans votre grimoire, accents compris."]
	win.fix:Hide()
	Field(win, "Envoyé au jeu", x, -330)
	win.preview = Zone(win, x, -346, width, 5)
	UI.Paint(win.preview, "text")
	Field(win, "Posée sur", x, -417)
	win.uses = Zone(win, x, -433, width, 2)
	UI.Paint(win.uses, "text")

	win.auto = UI.Check(win, L["Une commande sans cible vise la case"],
		function() return Z.db.macroAutoTarget end,
		function(value) Z.db.macroAutoTarget = value Z:ApplyClicks() win.Live() win.Help() end)
	win.auto:SetPoint("TOPLEFT", x, -463)
	win.auto.tip = L["Décochez pour que vos macros partent exactement comme écrites, comme dans la fenêtre /macro."]

	-- L'aide suit la case : décochée, une commande sans cible ne vise plus la case
	function win.Help()
		win.help:SetText(Z.db.macroAutoTarget and L["{cible} est le joueur de la case. Une commande sans cible vise la case."]
			or L["{cible} est le joueur de la case."])
	end

	-- Mise à jour en direct pendant la frappe : longueur, fautes (3 au plus, puis « et N autres »), texte envoyé
	local SHOWN = 3
	function win.Live()
		local body = edit:GetText()
		local resolved = Z:ResolveMacro(body)
		win.count:SetText(#resolved .. " / " .. Z.MACRO_MAX)
		local lines = {}
		local problems = Z:CheckMacro(body)
		win.fix:SetShown(problems.fixes ~= nil)
		for _, problem in ipairs(problems) do
			lines[#lines + 1] = (problem[1] == "err" and "|cffff6060" or "|cffffd060") .. problem[2] .. "|r"
		end
		win.problems:SetText(#lines > 0 and table.concat(lines, "\n", 1, math.min(#lines, SHOWN)) or "|cff33dd88" .. L["Aucune faute trouvée."] .. "|r")
		win.others:SetText(#lines > SHOWN and L["et %d autres"]:format(#lines - SHOWN) or "")
		win.preview:SetText(resolved)
	end
	edit:SetScript("OnTextChanged", function() win.Live() end)

	function win.SaveCurrent()
		if not win.macro then return end
		if win.name:GetText() ~= win.macro.name then
			local ok, why = Z:RenameMacro(win.macro, win.name:GetText())
			if not ok then Z:Print(why) end -- nom déjà pris : on garde l'ancien, et on le dit
			win.name:SetText(win.macro.name)
		end
		local body = edit:GetText()
		if body ~= win.macro.body then
			win.macro.body = body
			Z:ApplyClicks()
			ClicksChanged()
		end
	end

	-- La macro s'enregistre aussi toute seule à la fermeture ; le bouton dit deux secondes que c'est fait
	local save
	save = UI.Button(win, L["Enregistrer"], 120, 24, function()
		win.SaveCurrent()
		win.Refresh()
		local token = {}
		save.token = token
		save.label:SetText(L["Enregistrée"])
		C_Timer.After(2, function()
			if save.token == token then save.label:SetText(L["Enregistrer"]) end
		end)
	end)
	save:SetPoint("BOTTOMLEFT", x, 14)
	save.label:SetJustifyH("CENTER")
	win.save = save
	-- Supprimer vide aussi tous les clics et touches de la macro : à confirmer d'un second clic
	local remove = Z.ArmedButton(win, "Supprimer", "Cliquez encore pour confirmer", 200, function()
		if not win.macro then return end
		Z:RemoveMacro(win.macro)
		win.macro = nil
		win.Select(Z:GetMacros()[1])
		ClicksChanged()
	end)
	remove:SetPoint("LEFT", save, "RIGHT", 6, 0)
	remove.tip = L["Supprime la macro et vide les clics qui l'utilisaient."]
	win.remove = remove

	function win.Select(macro)
		win.macro = macro
		win.position = macro and select(2, Z:FindMacro(macro.name)) or nil
		win.remove.Disarm() -- armé pour une autre macro : le second clic ne la supprime pas
		win.save.token = nil -- « Enregistrée » était dit pour l'autre macro
		win.save.label:SetText(L["Enregistrer"])
		win.name:SetText(macro and macro.name or "")
		edit:SetText(macro and macro.body or "")
		win.scroll:SetVerticalScroll(0)
		win.Live()
		win.Refresh()
		ClicksChanged() -- macro créée, importée ou supprimée : « Annuler mes changements » paraît
	end

	function win.Refresh()
		local macros = Z:GetMacros()
		win.offset = math.max(0, math.min(win.offset, #macros - ROWS))
		for i, row in ipairs(win.rows) do
			local macro = macros[i + win.offset]
			row.macro = macro
			row:SetShown(macro ~= nil)
			row.icon:SetTexture(macro and Z:MacroIcon(macro.body) or nil)
			row.label:SetText(macro and macro.name or "")
			row.mark:SetShown(macro ~= nil and macro == win.macro)
		end
		win.empty:SetShown(#macros == 0)
		win.more:SetShown(#macros > ROWS)
		win.more:SetText(L["Molette : %d de plus"]:format(math.max(0, #macros - ROWS)))
		local uses = win.macro and Z:MacroUses(win.macro) or {}
		local copy = Z:GameCopy(win.macro)
		if copy then uses[#uses + 1] = L["copie dans /macro : %s"]:format(copy) end
		win.uses:SetText(#uses > 0 and table.concat(uses, ", ") or Dim(L["aucun clic ni touche, dans cette spécialisation"]))
		win.save:SetShown(win.macro ~= nil)
		win.remove:SetShown(win.macro ~= nil)
		win.name:SetShown(win.macro ~= nil)
		win.auto:Update()
		win.Help()
		win.Placed()
	end

	-- Consigne refaite à l'ouverture, quand l'écran change (UI.lua, Refit) et à chaque rafraîchissement
	function win.Placed()
		win.hint:SetText(HintText())
	end
	win:HookScript("OnShow", win.Placed) -- après UI.Appear, qui a placé la fenêtre (et effacé les options ou non)

	win:HookScript("OnHide", function() -- garde le retour des options (UI.Window)
		win.SaveCurrent()
		-- Une macro tenue au curseur quand la fenêtre se ferme : l'icône part, rien n'est déposé
		if dragIcon then
			dragIcon:Hide()
			dragIcon:SetScript("OnUpdate", nil)
		end
	end)
	-- Changement de thème : les gris écrits dans un texte suivent
	UI.OnSkin(function()
		if win:IsShown() then win.Refresh() end
		if wizard and wizard:IsShown() then wizard.Update() end
	end)
end

-- Ouvre la bibliothèque, sur une macro (nom) ou sur la première
function Z:OpenMacros(name)
	if not win then BuildWindow() end
	local options = Z.OptionsWindow and Z:OptionsWindow()
	if not win:IsShown() and not (options and options:IsShown()) then
		win:ClearAllPoints()
		win:SetPoint("CENTER") -- options fermées : au milieu ; ouvertes, UI.Appear la pose à côté
	end
	win:Show()
	win.SaveCurrent()
	win.Select(name and Z:FindMacro(name) or win.macro or Z:GetMacros()[1])
	return win
end

-- « Annuler mes changements » a remis la bibliothèque d'avant (Options.lua) : la macro ouverte est une ancienne
-- table, plus rien ne doit y être écrit. La fenêtre ouverte reprend la macro à la même place de la liste.
function Z.MacrosUndone()
	if not win then return end
	local position = win.position
	win.macro = nil
	if win:IsShown() then
		local macros = Z:GetMacros()
		win.Select(position and macros[position] or macros[1])
	end
end

----------------------------------------------------------------------------------------------------
-- Copie depuis la fenêtre /macro
----------------------------------------------------------------------------------------------------
function Z:OpenMacroImport()
	if not importer then
		importer = UI.Window("LyoruneMacroImport", L["Importer de /macro"], 372, 120)
		importer:SetFrameStrata("FULLSCREEN_DIALOG")
		tinsert(UISpecialFrames, "LyoruneMacroImport")
		UI.OnTop(importer) -- Échap ferme seulement cette fenêtre, pas Mes macros ni les options
		importer.note = Block(importer, 14, -42, 344)
		UI.Paint(importer.note, "dim")
		importer.icons = {}
	end
	local macros, perRow, size = Z:GameMacros(), 10, 32
	for i, game in ipairs(macros) do
		local icon = importer.icons[i]
		if not icon then
			icon = CreateFrame("Button", nil, importer)
			icon:SetSize(size, size)
			icon.texture = icon:CreateTexture(nil, "ARTWORK")
			icon.texture:SetAllPoints()
			icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			icon.border = UI.Border(icon, 1)
			icon:SetScript("OnEnter", function(self)
				self.border:SetColor(UI.accent[1], UI.accent[2], UI.accent[3])
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(self.game.name, UI.accent[1], UI.accent[2], UI.accent[3])
				GameTooltip:AddLine(GetMacroBody(self.game.index) or "", 1, 1, 1)
				GameTooltip:Show()
			end)
			icon:SetScript("OnLeave", function(self)
				self.border:SetColor(0, 0, 0)
				GameTooltip:Hide()
			end)
			icon:SetScript("OnClick", function(self)
				local macro = Z:ImportGameMacro(self.game.index)
				importer:Hide()
				if macro then Z:OpenMacros(macro.name) end
			end)
			importer.icons[i] = icon
		end
		icon.game = game
		icon.texture:SetTexture(game.icon or QUESTION)
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", 14 + ((i - 1) % perRow) * (size + 3), -76 - math.floor((i - 1) / perRow) * (size + 3))
		icon:Show()
	end
	for i = #macros + 1, #importer.icons do importer.icons[i]:Hide() end
	importer.note:SetText(#macros == 0 and L["Aucune macro dans la fenêtre /macro du jeu."]
		or L["Cliquez sur une macro : elle est copiée dans votre bibliothèque. [@mouseover] y vise la case."])
	importer:SetHeight(96 + math.ceil(math.max(#macros, 1) / perRow) * (size + 3))
	importer:ClearAllPoints()
	importer:SetPoint("CENTER", win or UIParent, "CENTER")
	importer:Show()
	UI.Lift(importer) -- déjà ouverte : repasse au-dessus
	return importer
end

----------------------------------------------------------------------------------------------------
-- Assistant
----------------------------------------------------------------------------------------------------
local WIZARD_H = 360

function Z:OpenMacroWizard()
	if not wizard then
		wizard = UI.Window("LyoruneMacroWizard", L["Assistant de macro"], 400, WIZARD_H)
		wizard:SetFrameStrata("FULLSCREEN_DIALOG")
		tinsert(UISpecialFrames, "LyoruneMacroWizard")
		UI.OnTop(wizard) -- Échap ferme seulement l'assistant, pas Mes macros ni les options
		local opts = { stop = false, trinket1 = false, trinket2 = false, res = true }
		wizard.opts = opts
		local y = -46
		Field(wizard, "Sort lancé sur le joueur", 14, y)
		wizard.spell = UI.Button(wizard, "", 200, 22, function()
			Z.OpenPicker(L["Sort lancé sur le joueur"], function(value)
				if value and value:sub(1, 1) ~= "@" then opts.spell = value end
				wizard.Update()
			end, true)
		end)
		wizard.spell:SetPoint("TOPLEFT", 186, y + 4)
		wizard.spell.label:SetJustifyH("CENTER")
		y = y - 30
		local function Option(key, label)
			local check = UI.Check(wizard, L[label], function() return opts[key] end, function(value)
				opts[key] = value
				wizard.Update()
			end)
			check:SetPoint("TOPLEFT", 14, y)
			check:SetWidth(370)
			y = y - 24
			return check
		end
		Option("stop", "Arrêter le sort en cours")
		Option("trinket1", "Utiliser mon bijou du haut")
		Option("trinket2", "Utiliser mon bijou du bas")
		wizard.res = Option("res", "Si le joueur est mort : le relever")
		-- La suite est posée sous un repère qui remonte d'une ligne quand la classe n'a pas de résurrection
		wizard.tailY = y - 4
		wizard.tail = CreateFrame("Frame", nil, wizard)
		wizard.tail:SetSize(1, 1)
		wizard.tail:SetPoint("TOPLEFT", 0, wizard.tailY)
		local harmLabel = Field(wizard, "Si c'est un ennemi, lancer (facultatif)", 14, 0)
		harmLabel:ClearAllPoints()
		harmLabel:SetPoint("TOPLEFT", wizard.tail, "TOPLEFT", 14, 0)
		wizard.harm = UI.Edit(wizard, 170, function(text)
			opts.harm = text
			wizard.Update()
		end)
		wizard.harm:SetPoint("TOPLEFT", wizard.tail, "TOPLEFT", 216, 4)
		wizard.harm:SetScript("OnTextChanged", function(self)
			opts.harm = self:GetText()
			wizard.Update()
		end)
		local previewLabel = Field(wizard, "Votre macro", 14, 0)
		previewLabel:ClearAllPoints()
		previewLabel:SetPoint("TOPLEFT", wizard.tail, "TOPLEFT", 14, -32)
		wizard.preview = Zone(wizard, 14, 0, 372, 6)
		wizard.preview:ClearAllPoints()
		wizard.preview:SetPoint("TOPLEFT", wizard.tail, "TOPLEFT", 14, -48)
		UI.Paint(wizard.preview, "text")
		local create = UI.Button(wizard, L["Créer la macro"], 150, 24, function()
			local body = Z:MacroFromWizard(opts)
			if body == "" then return end
			local macro = Z:NewMacro(opts.spell or L["Macro"], body)
			wizard:Hide()
			Z:OpenMacros(macro.name)
		end)
		create:SetPoint("BOTTOMLEFT", 14, 14)
		create.label:SetJustifyH("CENTER")
		wizard.create = create
		function wizard.Update()
			wizard.spell.label:SetText(opts.spell or Dim(L["Choisir..."]))
			wizard.preview:SetText(Z:MacroFromWizard(opts))
		end
	end
	local known = Z:KnownSpells()[1]
	wizard.opts.spell = wizard.opts.spell or (known and known.name)
	-- Classe sans résurrection : la case est cachée et la suite remonte, la fenêtre raccourcit d'autant
	local res = Z.classRes[Z.class] ~= nil
	wizard.res:SetShown(res)
	wizard.tail:SetPoint("TOPLEFT", 0, wizard.tailY + (res and 0 or 24))
	wizard:SetHeight(WIZARD_H - (res and 0 or 24))
	wizard.Update()
	wizard:ClearAllPoints()
	wizard:SetPoint("CENTER", win or UIParent, "CENTER")
	wizard:Show()
	UI.Lift(wizard) -- déjà ouvert : repasse au-dessus
	return wizard
end

-- Pour les tests
function Z:MacroWindow() return win end
function Z:MacroDragStart(row) StartDrag(row) end
function Z:MacroDragStop() return StopDrag() end
