-- Zenith (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Zenith - Share.lua : échanger sa configuration avec un autre joueur, et profils prêts à l'emploi.
-- L'export produit un code (du texte simple) à copier : en chuchotement, sur Discord, dans un message...
-- L'autre joueur le colle dans l'onglet Profils et clique sur Importer. (Envoi direct en jeu : voir Comm.lua.)
--
-- Format : Zenith2;cle=tVALEUR;...   avec t = n (nombre), b (oui/non) ou s (texte).
--   c.CLASSE.touche=sSort   un clic de souris        h.CLASSE.numero=sTOUCHE|Sort   une touche au survol
--   l.liste=sNom            une entrée d'une liste personnelle
-- Les caractères spéciaux sont écrits %XX. A l'import, chaque valeur est contrôlée avec les tables
-- Z.defaults, Z.limits et Z.choices (Core.lua) : un code abîmé ou malveillant ne peut rien casser.

local _, Z = ...

local PREFIX = "Zenith2"
local LISTS = { extraTracked = true, ignoredNames = true, importantNames = true }

local function Encode(text)
	return (tostring(text):gsub("[^%w]", function(c) return ("%%%02X"):format(c:byte()) end))
end

local function Decode(text)
	return (text:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

function Z:Export()
	local parts = { PREFIX }
	local keys = {}
	for key, value in pairs(Z.defaults) do
		if type(value) ~= "table" and not Z.private[key] then keys[#keys + 1] = key end
	end
	table.sort(keys)
	for _, key in ipairs(keys) do
		local value = Z.db[key]
		local kind = type(value) == "number" and "n" or type(value) == "boolean" and "b" or "s"
		parts[#parts + 1] = key .. "=" .. kind .. Encode(value)
	end
	for class, binds in pairs(Z.db.clicks) do
		for key, spell in pairs(binds) do
			parts[#parts + 1] = "c." .. class .. "." .. Encode(key) .. "=s" .. Encode(spell)
		end
	end
	for class, list in pairs(Z.db.hoverKeys) do
		for i, entry in ipairs(list) do
			parts[#parts + 1] = "h." .. class .. "." .. i .. "=s" .. Encode(entry.key .. "|" .. entry.spell)
		end
	end
	for list in pairs(LISTS) do
		for name in pairs(Z.db[list]) do
			parts[#parts + 1] = "l." .. list .. "=s" .. Encode(name)
		end
	end
	return table.concat(parts, ";")
end

-- Contrôle une valeur importée. Renvoie la valeur acceptée, ou nil.
local function Validate(key, kind, raw)
	local default = Z.defaults[key]
	if default == nil or type(default) == "table" or Z.private[key] then return nil end
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
		elseif #raw > 0 and #raw <= 120 then
			return raw
		end
	end
	return nil
end

-- Renvoie true et un résumé, ou false et la raison du refus
function Z:Import(code)
	local L = Z.L
	code = (code or ""):gsub("%s+", "")
	if not code:match("^Zenith%d;") then
		return false, L["Ce texte n'est pas un code Zenith."]
	end

	local settings, clicks, hovers, lists, count = {}, {}, {}, {}, 0
	for entry in code:gmatch("[^;]+") do
		local key, kind, raw = entry:match("^([%w%.%%]+)=(%a)(.*)$")
		if key then
			raw = Decode(raw)
			local class, click = key:match("^c%.(%u+)%.(.+)$")
			local hoverClass, index = key:match("^h%.(%u+)%.(%d)$")
			local list = key:match("^l%.(%a+)$")
			if class then
				click = Decode(click)
				if kind == "s" and click:match("^%a*%-?[1-5]$") and #raw > 0 and #raw <= 80 then
					clicks[class] = clicks[class] or {}
					clicks[class][click] = raw
					count = count + 1
				end
			elseif hoverClass then
				local hoverKey, spell = raw:match("^([%w%-]+)|(.+)$")
				if kind == "s" and hoverKey and #spell <= 80 then
					hovers[hoverClass] = hovers[hoverClass] or {}
					table.insert(hovers[hoverClass], { key = hoverKey, spell = spell })
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

	for key, value in pairs(settings) do Z.db[key] = value end
	for class, binds in pairs(clicks) do Z.db.clicks[class] = binds end
	for class, list in pairs(hovers) do Z.db.hoverKeys[class] = list end
	for list, names in pairs(lists) do Z.db[list] = names end
	Z:Refresh()
	Z:ApplyClicks()
	Z:RefreshAlerts()
	return true, (L["%d réglages importés."]):format(count)
end

----------------------------------------------------------------------------------------------------
-- Profils prêts à l'emploi : un point de départ en un clic, que l'on ajuste ensuite
----------------------------------------------------------------------------------------------------
Z.presets = {
	{ "DUNGEON", "Donjon (5 joueurs)", { width = 110, height = 50, fontSize = 12, spacing = 4, text = "DEFICIT", hotStyle = "ICONS", layout = "GROUP", autoShrink = false } },
	{ "RAID", "Raid", { width = 80, height = 38, fontSize = 10, spacing = 2, text = "DEFICIT", hotStyle = "ICONS", layout = "GROUP", autoShrink = true } },
	{ "COMPACT", "Compact", { width = 64, height = 30, fontSize = 9, spacing = 2, text = "NONE", hotStyle = "BARS", layout = "GROUP", autoShrink = false } },
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
