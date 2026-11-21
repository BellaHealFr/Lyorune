-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Share.lua : échanger sa configuration avec un autre joueur, et profils prêts à l'emploi.
-- L'export produit un code (du texte simple) à copier : en chuchotement, sur Discord, dans un message...
-- L'autre joueur le colle dans l'onglet Profils et clique sur Importer. (Envoi direct en jeu : voir Comm.lua.)
--
-- Format : Lyorune2;cle=tVALEUR;...   avec t = n (nombre), b (oui/non) ou s (texte).
--   c.CLASSE.touche=sSort   un clic de souris        h.CLASSE.numero=sTOUCHE|Sort   une touche au survol
--   l.liste=sNom            une entrée d'une liste personnelle
--   p.FORME.element=sX,Y    un élément décalé dans l'éditeur de placement ; sX,Y,T avec sa taille T en %
--                           (absente à 100 % : un code sans taille reste lisible par les anciennes versions)
-- Les caractères spéciaux sont écrits %XX. A l'import, chaque valeur est contrôlée avec les tables
-- Z.defaults, Z.limits et Z.choices (Core.lua) : un code abîmé ou malveillant ne peut rien casser.
-- Un texte libre (les annonces dites dans le chat) n'est jamais partagé : un code reçu pourrait sinon faire dire
-- n'importe quoi en mon nom. Seuls circulent les textes choisis dans une liste (thème, texture, choix des options).

local _, Z = ...

local PREFIX = "Lyorune2"
local LISTS = { extraTracked = true, ignoredNames = true, importantNames = true }
local MAX_KEYS = 100 -- touches au survol reçues par spécialisation : sans limite dans les options, bornées à l'import

local function Encode(text)
	return (tostring(text):gsub("[^%w]", function(c) return ("%%%02X"):format(c:byte()) end))
end

-- Un réglage partagé : ni propre à ce personnage (Z.private), ni un texte libre
local function Shared(key)
	local default = Z.defaults[key]
	if default == nil or type(default) == "table" or Z.private[key] then return false end
	if key == "autoProfile" or key == "activeProfile" then return false end -- sans mes profils (jamais partagés), ils n'ont pas de sens
	return type(default) ~= "string" or Z.choices[key] ~= nil or key == "theme" or key == "texture"
end

-- Sauvegarde avant import (#29) : tout ce qu'un import peut remplacer, copié juste avant. Un seul niveau,
-- gardé dans mes réglages (Z.db.importBackup) : il survit à un /reload, le prochain import le remplace.
local BACKUP_TABLES = { "clicks", "hoverKeys", "clickTrinkets", "placement", "extraTracked", "ignoredNames", "importantNames" }

local function Backup()
	local copy = { settings = {} }
	for key in pairs(Z.defaults) do
		if Shared(key) then copy.settings[key] = Z.db[key] end
	end
	for _, key in ipairs(BACKUP_TABLES) do copy[key] = CopyTable(Z.db[key]) end
	return copy
end

local function Decode(text)
	return (text:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

function Z:Export()
	local parts = { PREFIX }
	local keys = {}
	for key, value in pairs(Z.defaults) do
		if Shared(key) then keys[#keys + 1] = key end
	end
	table.sort(keys)
	for _, key in ipairs(keys) do
		local value = Z.db[key]
		local kind = type(value) == "number" and "n" or type(value) == "boolean" and "b" or "s"
		parts[#parts + 1] = key .. "=" .. kind .. Encode(value)
	end
	for class, binds in pairs(Z.db.clicks) do
		for key, spell in pairs(binds) do
			if not Z.IsMacro(spell) and not Z.MacroRef(spell) then parts[#parts + 1] = "c." .. class .. "." .. Encode(key) .. "=s" .. Encode(spell) end
		end
	end
	for class, list in pairs(Z.db.hoverKeys) do
		local index = 0
		for _, entry in ipairs(list) do
			if not Z.IsMacro(entry.spell) and not Z.MacroRef(entry.spell) then
				index = index + 1
				parts[#parts + 1] = "h." .. class .. "." .. index .. "=s" .. Encode(entry.key .. "|" .. entry.spell)
			end
		end
	end
	-- bijoux d'un clic ou d'une touche (1, 2 ou 3), seulement s'il est partagé lui aussi
	for class, marks in pairs(Z.db.clickTrinkets or {}) do
		local binds = Z.db.clicks[class] or {}
		for id, mask in pairs(marks) do
			local key = id:match("^key:(.+)$")
			local value = binds[id]
			if key then
				for _, entry in ipairs(Z.db.hoverKeys[class] or {}) do
					if entry.key == key then value = entry.spell end
				end
			end
			if value and not Z.IsMacro(value) and not Z.MacroRef(value) then
				parts[#parts + 1] = "t." .. class .. "." .. Encode(id) .. "=n" .. mask
			end
		end
	end
	for list in pairs(LISTS) do
		for name in pairs(Z.db[list]) do
			parts[#parts + 1] = "l." .. list .. "=s" .. Encode(name)
		end
	end
	for shape, elements in pairs(Z.db.placement) do
		for key, at in pairs(elements) do
			local size = at[3] and ("," .. at[3]) or ""
			parts[#parts + 1] = "p." .. shape .. "." .. key .. "=s" .. Encode(at[1] .. "," .. at[2] .. size)
		end
	end
	return table.concat(parts, ";")
end

-- Contrôle une valeur importée. Renvoie la valeur acceptée, ou nil.
local function Validate(key, kind, raw)
	if not Shared(key) then return nil end
	local default = Z.defaults[key]
	if type(default) == "boolean" then
		if kind == "b" and raw == "true" then return true end
		if kind == "b" and raw == "false" then return false end
	elseif type(default) == "number" then
		local number, limit = kind == "n" and tonumber(raw), Z.limits[key]
		if number and limit then return math.max(limit[1], math.min(limit[2], number)) end
	elseif kind == "s" then
		if Z.choices[key] then
			for _, choice in ipairs(Z.choices[key]) do
				if choice[1] == raw then return raw end
			end
		elseif key == "theme" then
			for _, theme in ipairs(Z.themes) do
				if theme.id == raw then return raw end
			end
		elseif key == "texture" then -- celle du thème, ou une texture présente chez moi
			if raw == "THEME" then return raw end
			for _, name in ipairs(Z.UI.TextureList()) do
				if name == raw then return raw end
			end
		end
	end
	return nil
end

-- Un nom de sort reçu d'un autre joueur : jamais une macro, jamais de saut de ligne (il finirait dans une commande)
local function SafeSpell(raw)
	return #raw > 0 and #raw <= 80 and not Z.IsMacro(raw) and not Z.MacroRef(raw) and not raw:find("%c")
end

-- Renvoie true et un résumé, ou false et la raison du refus
function Z:Import(code)
	local L = Z.L
	code = (code or ""):gsub("%s+", "")
	if not code:match("^Lyorune%d;") then
		return false, L["Ce texte n'est pas un code Lyorune."]
	end

	local settings, clicks, hovers, lists, places, count = {}, {}, {}, {}, {}, 0
	local trinkets = {}
	for entry in code:gmatch("[^;]+") do
		local key, kind, raw = entry:match("^([%w%.%%]+)=(%a)(.*)$")
		if key then
			raw = Decode(raw)
			local class, click = key:match("^c%.(%u+%d?)%.(.+)$") -- PRIEST, ou PRIEST2 : seconde spécialisation
			local hoverClass, index = key:match("^h%.(%u+%d?)%.(%d+)$")
			local trinketClass, trinketId = key:match("^t%.(%u+%d?)%.(.+)$")
			local list = key:match("^l%.(%a+)$")
			local shape, element = key:match("^p%.(%u+)%.(%a+)$")
			if class then
				click = Decode(click)
				if kind == "s" and Z.ParseClickKey(click) and SafeSpell(raw) then
					clicks[class] = clicks[class] or {}
					clicks[class][click] = raw
					count = count + 1
				end
			elseif trinketClass then
				-- un masque de 1 à 3 sur un clic ou une touche valable : rien d'autre n'entre
				trinketId = Decode(trinketId)
				local mask, hoverKey = kind == "n" and tonumber(raw), trinketId:match("^key:(.+)$")
				local validId = hoverKey and Z.ValidKey(hoverKey) or not hoverKey and Z.ParseClickKey(trinketId)
				if (mask == 1 or mask == 2 or mask == 3) and validId then
					trinkets[trinketClass] = trinkets[trinketClass] or {}
					trinkets[trinketClass][trinketId] = mask
					count = count + 1
				end
			elseif hoverClass then
				local hoverKey, spell = raw:match("^([^|]+)|(.+)$")
				local taken = hovers[hoverClass] or {}
				if kind == "s" and Z.ValidKey(hoverKey) and SafeSpell(spell) and #taken < MAX_KEYS then
					hovers[hoverClass] = hovers[hoverClass] or {}
					table.insert(hovers[hoverClass], { key = hoverKey, spell = spell })
					count = count + 1
				end
			elseif shape then
				-- forme et élément connus, deux nombres entiers bornés, et la taille d'une icône : rien d'autre n'entre
				local x, y, size = raw:match("^(%-?%d+),(%-?%d+),?(%d*)$")
				local limit = Z.limits.placement
				if kind == "s" and x and Z.shapes[shape] and Z.IsPlaceElement(element) then
					x = math.max(limit[1], math.min(limit[2], tonumber(x)))
					y = math.max(limit[1], math.min(limit[2], tonumber(y)))
					size = tonumber(size)
					if size and Z.IsSizedElement(element) then
						size = math.max(limit.size[1], math.min(limit.size[2], size))
						if size == 100 then size = nil end
					else
						size = nil
					end
					places[shape] = places[shape] or {}
					places[shape][element] = { x, y, size }
					count = count + 1
				end

			elseif list then
				if kind == "s" and LISTS[list] and #raw > 0 and #raw <= 80 then
					lists[list] = lists[list] or {}
					lists[list][raw] = true
					count = count + 1
				end
			else
				local value = Validate(key, kind, raw)
				if value ~= nil then
					settings[key] = value
					count = count + 1
				end
			end
		end
	end
	if count == 0 then
		return false, L["Ce code ne contient aucun réglage valide."]
	end

	Z.db.importBackup = Backup() -- la configuration d'avant, pour /lyorune annuler
	for key, value in pairs(settings) do Z.db[key] = value end
	for class, binds in pairs(clicks) do Z.db.clicks[class] = binds end
	for class, list in pairs(hovers) do Z.db.hoverKeys[class] = list end
	-- les bijoux suivent les clics reçus : une classe dont les clics changent prend aussi ses bijoux
	Z.db.clickTrinkets = Z.db.clickTrinkets or {}
	for class in pairs(clicks) do Z.db.clickTrinkets[class] = trinkets[class] or {} end
	for class in pairs(hovers) do Z.db.clickTrinkets[class] = trinkets[class] or {} end
	for list, names in pairs(lists) do Z.db[list] = names end
	for shape, elements in pairs(places) do Z.db.placement[shape] = elements end
	Z:Refresh()
	Z:ApplyClicks()
	Z:RefreshAlerts()
	return true, (L["%d réglages importés. Pour revenir en arrière : /lyorune annuler."]):format(count)
end

-- Retour à la configuration d'avant le dernier import. La copie vient de mes propres réglages enregistrés :
-- chaque valeur est quand même contrôlée (type attendu), un fichier abîmé ne peut rien casser.
function Z:UndoImport()
	local L, copy = Z.L, Z.db.importBackup
	if type(copy) ~= "table" or type(copy.settings) ~= "table" then
		return false, L["Aucun import à annuler."]
	end
	for key, value in pairs(copy.settings) do
		if Shared(key) and type(value) == type(Z.defaults[key]) then Z.db[key] = value end
	end
	for _, key in ipairs(BACKUP_TABLES) do
		if type(copy[key]) == "table" then Z.db[key] = copy[key] end
	end
	Z.db.importBackup = nil
	Z:Refresh()
	Z:ApplyClicks()
	Z:RefreshAlerts()
	return true, L["Configuration d'avant l'import rétablie."]
end

function Z:CanUndoImport()
	return type(Z.db.importBackup) == "table"
end

----------------------------------------------------------------------------------------------------
-- Profils prêts à l'emploi : un point de départ en un clic, que l'on ajuste ensuite
----------------------------------------------------------------------------------------------------
Z.presets = {
	{ "DUNGEON", "Donjon (5 joueurs)", { width = 110, height = 50, fontSize = 12, spacing = 4, text = "DEFICIT", hotStyle = "ICONS", layout = "GROUP", autoShrink = false } },
	{ "RAID", "Raid", { width = 80, height = 38, fontSize = 10, spacing = 2, text = "DEFICIT", hotStyle = "ICONS", layout = "GROUP", autoShrink = true } },
	{ "COMPACT", "Compact", { width = 64, height = 30, fontSize = 9, spacing = 2, text = "NONE", hotStyle = "ICONS", layout = "GROUP", autoShrink = false } },
	{ "LARGE", "Grand et lisible", { width = 130, height = 60, fontSize = 14, spacing = 4, text = "PERCENT", hotStyle = "ICONS", layout = "ROLE", autoShrink = false } },
}

function Z:ApplyPreset(id)
	for _, preset in ipairs(Z.presets) do
		if preset[1] == id then
			for key, value in pairs(preset[3]) do Z.db[key] = value end
			Z:Refresh()
			return true
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Mes profils (#24) : mes réglages d'apparence enregistrés sous un nom. Les clics, les macros, les listes et les
-- annonces n'en font pas partie (Z.notInProfile, Core.lua) : ils restent les mêmes quel que soit le profil.
-- Le profil en cours est enregistré tout seul avant d'en changer et à la déconnexion : ce que l'on règle pendant
-- qu'il est actif lui appartient.
-- Profils automatiques : pour 5, 10, 25 et 40 joueurs, en champ de bataille et en arène (#44), le profil voulu,
-- pour chaque spécialisation. La seconde spécialisation reprend le choix de la première quand rien n'est choisi
-- pour elle ; en champ de bataille ou en arène sans choix, la règle de la taille du groupe s'applique. Le changement
-- se fait sans /reload, à la fin du combat si besoin.
-- Copie d'une partie (#44) : les réglages d'un chapitre des options (Disposition, Apparence, Vie et portée, Mes
-- soins, Affaiblissements, Joueurs) d'un profil vers un autre. La partie d'un réglage est le chapitre où il se règle
-- (Z.TabOfSetting, Options.lua) : un nouveau réglage suit tout seul son chapitre.
----------------------------------------------------------------------------------------------------
local MAX_PROFILES, MAX_NAME = 20, 24
Z.profileSizes = { "5", "10", "25", "40", "BG", "ARENA" }
Z.profileParts = { "Disposition", "Apparence", "Vie et portée", "Mes soins", "Affaiblissements", "Joueurs" }

local function InProfile(key)
	return Z.defaults[key] ~= nil and not Z.notInProfile[key]
end

-- Les réglages d'apparence du moment, copiés
local function Snapshot()
	local copy = {}
	for key in pairs(Z.defaults) do
		if InProfile(key) then
			local value = Z.db[key]
			copy[key] = type(value) == "table" and CopyTable(value) or value
		end
	end
	return copy
end

-- Une valeur d'un profil enregistré, contrôlée comme un réglage reçu : un profil d'une version plus ancienne ne
-- peut rien casser (choix disparu, nombre hors des limites).
local function Accept(key, value)
	local default = Z.defaults[key]
	if not InProfile(key) or type(value) ~= type(default) then return nil end
	if type(value) == "number" and Z.limits[key] then
		local limit = Z.limits[key]
		return math.max(limit[1], math.min(limit[2], value))
	end
	if Z.choices[key] then
		for _, choice in ipairs(Z.choices[key]) do
			if choice[1] == value then return value end
		end
		return nil
	end
	return type(value) == "table" and CopyTable(value) or value
end

-- Un nom de profil : 1 à 24 caractères, sans caractère de contrôle. Renvoie le nom nettoyé, ou nil.
function Z.ProfileName(text)
	text = tostring(text or ""):match("^%s*(.-)%s*$")
	if #text == 0 or #text > MAX_NAME or text:find("%c") then return nil end
	return text
end

-- Noms des profils, dans l'ordre alphabétique
function Z:ProfileNames()
	local names = {}
	for name in pairs(Z.db.profiles) do names[#names + 1] = name end
	table.sort(names)
	return names
end

-- Enregistre les réglages du moment sous ce nom (nouveau profil, ou remplacement). Renvoie true, ou false et la raison.
function Z:SaveProfile(text)
	local L = Z.L
	local name = Z.ProfileName(text)
	if not name then return false, L["Nom de profil vide ou trop long (24 caractères au plus)."] end
	if not Z.db.profiles[name] and #Z:ProfileNames() >= MAX_PROFILES then
		return false, (L["%d profils au plus : supprimez-en un d'abord."]):format(MAX_PROFILES)
	end
	Z.db.profiles[name] = Snapshot()
	Z.db.activeProfile = name
	return true, (L["Profil « %s » enregistré."]):format(name)
end

-- Charge un profil. Le profil en cours garde d'abord ce qui a été réglé pendant qu'il était actif.
function Z:LoadProfile(name)
	local profile = Z.db.profiles[name]
	if not profile then return false end
	local active = Z.db.activeProfile
	if active ~= name and Z.db.profiles[active] then Z.db.profiles[active] = Snapshot() end
	for key, value in pairs(profile) do
		local accepted = Accept(key, value)
		if accepted ~= nil then Z.db[key] = accepted end
	end
	Z.db.activeProfile = name
	Z:Refresh()
	return true
end

-- Partie d'un réglage du profil : le chapitre où il se règle. Ce qui n'est dans aucun de ces chapitres (forme,
-- bouton « Placer les éléments », mode performance du chapitre Fenêtre et aide) est rangé ici.
local OTHER_PART = { shape = "Apparence", placement = "Disposition", cornerSpells = "Mes soins", perfMode = "Disposition" }

function Z.ProfilePart(key)
	if not InProfile(key) then return nil end
	return OTHER_PART[key] or (Z.TabOfSetting and Z.TabOfSetting(key)) or "Apparence"
end

-- Copie les parties choisies (parts.Disposition = true...) du profil « from » vers le profil « to ». Le profil en cours
-- est lu et changé en direct. Renvoie true et le message, ou false et la raison.
function Z:CopyProfileParts(from, to, parts)
	local L = Z.L
	local profiles, active = Z.db.profiles, Z.db.activeProfile
	if not (from and profiles[from] and to and profiles[to]) then return false, L["Choisissez deux profils enregistrés."] end
	if from == to then return false, L["Choisissez deux profils différents."] end
	local any = false
	for _, part in ipairs(Z.profileParts) do any = any or parts[part] == true end
	if not any then return false, L["Cochez au moins une partie à copier."] end
	local source = from == active and Snapshot() or profiles[from]
	local count = 0
	for key in pairs(Z.defaults) do
		local part = Z.ProfilePart(key)
		if part and parts[part] then
			local value = Accept(key, source[key])
			if value == nil then value = Accept(key, Z.defaults[key]) end -- absent d'un profil ancien : valeur d'origine
			if to == active then Z.db[key] = value else profiles[to][key] = value end
			count = count + 1
		end
	end
	if to == active then Z:Refresh() end
	return true, (L["%d réglages copiés de « %s » vers « %s »."]):format(count, from, to)
end

function Z:DeleteProfile(name)
	if not Z.db.profiles[name] then return false end
	Z.db.profiles[name] = nil
	if Z.db.activeProfile == name then Z.db.activeProfile = "" end
	for _, rules in pairs(Z.db.autoProfiles) do -- plus aucune règle ne mène à un profil disparu
		for size, wanted in pairs(rules) do
			if wanted == name then rules[size] = nil end
		end
	end
	return true
end

-- Taille du groupe, en palier : « 5 » seul ou en groupe, puis « 10 », « 25 » ou « 40 » selon le raid
function Z.GroupSize()
	if not IsInRaid() then return "5" end
	local members = GetNumGroupMembers()
	return members <= 10 and "10" or members <= 25 and "25" or "40"
end

-- Combat entre joueurs : « BG » en champ de bataille, « ARENA » en arène, sinon nil
function Z.PvPKind()
	local _, kind = IsInInstance()
	return kind == "pvp" and "BG" or kind == "arena" and "ARENA" or nil
end

-- Où l'on est, pour les profils automatiques : le champ de bataille ou l'arène, sinon la taille du groupe
function Z.Situation()
	return Z.PvPKind() or Z.GroupSize()
end

-- Nom lisible d'une situation : « 25 joueurs », « champ de bataille », « arène »
function Z.SituationLabel(size)
	local L = Z.L
	if size == "BG" then return L["champ de bataille"] elseif size == "ARENA" then return L["arène"] end
	return (L["%s joueurs"]):format(size)
end

-- Règles d'une spécialisation (1 ou 2), créées au besoin
function Z:ProfileRules(group)
	local set = (group or 1) > 1 and Z.class .. group or Z.class
	Z.db.autoProfiles[set] = Z.db.autoProfiles[set] or {}
	return Z.db.autoProfiles[set]
end

-- Le profil voulu maintenant, ou nil (aucun choix : on garde les réglages du moment)
-- Ordre : ma spécialisation puis la 1re, d'abord pour le champ de bataille ou l'arène, puis pour la taille du groupe.
function Z:WantedProfile()
	local group, rules = Z:SpecGroup(), Z.db.autoProfiles
	local own, first = group > 1 and rules[Z.class .. group], rules[Z.class]
	for _, size in ipairs({ Z.PvPKind() or false, Z.GroupSize() }) do
		if size then
			for _, set in ipairs({ own or false, first or false }) do
				local name = set and set[size]
				if name and Z.db.profiles[name] then return name end
			end
		end
	end
end

-- Appelé quand le groupe change de taille, à la connexion et au changement de spécialisation
function Z:CheckAutoProfile()
	if not (Z.header and Z.db.autoProfile) then return end
	local name = Z:WantedProfile()
	if not name or name == Z.db.activeProfile then return end
	Z:Safe("profile", function()
		local wanted = Z:WantedProfile() -- le groupe a pu changer encore pendant le combat
		if wanted and wanted ~= Z.db.activeProfile and Z:LoadProfile(wanted) then
			Z:Print((Z.L["profil « %s » appliqué (%s)."]):format(wanted, Z.SituationLabel(Z.Situation())))
			if Z.RefreshProfiles then Z.RefreshProfiles() end
		end
	end)
end

do
	local lastSize
	-- Rien à faire tant que la situation ne change pas (palier du groupe, entrée ou sortie d'un champ de bataille)
	local function Changed()
		local size = Z.Situation()
		if size == lastSize then return end
		lastSize = size
		Z:CheckAutoProfile()
	end
	Z:On("GROUP_ROSTER_UPDATE", Changed)
	Z:On("PLAYER_ENTERING_WORLD", Changed)
	Z:On("ZONE_CHANGED_NEW_AREA", Changed)
	Z:On("PLAYER_LOGIN", function()
		lastSize = Z.Situation()
		Z:CheckAutoProfile()
	end)
	for _, event in ipairs({ "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED" }) do
		Z:On(event, function() Z:CheckAutoProfile() end)
	end
	-- Ce qui a été réglé pendant la session reste dans le profil en cours
	Z:On("PLAYER_LOGOUT", function()
		if Z.db and Z.db.profiles[Z.db.activeProfile] then Z.db.profiles[Z.db.activeProfile] = Snapshot() end
	end)
end
