-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Perf.lua : /lyorune mesure. Combien coûte Lyorune, sur cet ordinateur ?
--
-- 1. Le vrai code des cases tourne sur un faux groupe de 5, 25 et 40 joueurs (les cases du mode test, aucun
--    cadre de plus), chronométré. On en tire le coût d'un combat de raid chargé.
-- 2. La mémoire de Lyorune et celle des autres addons de soin chargés, et leur temps réel par image quand le
--    profileur du jeu est actif : la comparaison se fait dans les mêmes conditions, sur la même partie.
-- Rien ne tourne en permanence : la mesure ne se fait qu'à la demande, hors combat. Le mode performance
-- (réglage perfMode) est appliqué dans Frames.lua (portée) et Auras.lua (auras regroupées).

local ADDON, Z = ...

local SIZES = { 5, 25, 40 }
local ROUNDS = 10 -- chaque mise à jour est répétée pour une mesure stable
-- Combat de raid chargé : nombre de changements par joueur et par seconde (hypothèse plutôt haute)
local RATES = { health = 4, prediction = 3, auras = 3, power = 2 }
-- Autres addons de cadres de soin, comparés s'ils sont chargés (ElvUI : toute l'interface, pas seulement les cadres)
local OTHERS = { "VuhDo", "HealBot", "Grid2", "Cell", "ElvUI" }
local ADVICE_AT = 20 -- au-delà de 20 ms par seconde à 40 joueurs (2 %), le mode performance est conseillé
local KEEP = 10      -- mesures gardées dans LyoruneDB.perfDiag, relisibles hors du jeu

local function Loaded(name)
	if name == ADDON then return true end
	local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, name)
	return ok and loaded and true or false
end

local function Number(value)
	if type(value) ~= "number" or Z.IsSecret(value) then return nil end
	return value
end

local function Memory(name)
	if not GetAddOnMemoryUsage then return nil end
	local ok, value = pcall(GetAddOnMemoryUsage, name)
	return ok and Number(value) or nil
end

-- Le profileur du jeu (temps réel de chaque addon) : nil s'il manque ou s'il est désactivé
local function Profiler()
	local profiler = C_AddOnProfiler
	local metrics = Enum and Enum.AddOnProfilerMetric
	if type(profiler) ~= "table" or type(metrics) ~= "table" or not profiler.GetAddOnMetric then return nil end
	if profiler.IsEnabled then
		local ok, enabled = pcall(profiler.IsEnabled)
		if not ok or not enabled then return nil end
	end
	return function(name, metric)
		local id = metrics[metric]
		if id == nil then return nil end
		local ok, value
		if name then ok, value = pcall(profiler.GetAddOnMetric, name, id)
		elseif profiler.GetOverallMetric then ok, value = pcall(profiler.GetOverallMetric, id) end
		return ok and Number(value) or nil
	end
end

-- Temps moyen d'une mise à jour, en millisecondes par case
local function Time(update, cells, count)
	local start = debugprofilestop()
	for _ = 1, ROUNDS do
		for i = 1, count do update(cells[i]) end
	end
	return (debugprofilestop() - start) / (ROUNDS * count)
end

-- Le faux groupe : les cases suivent mon propre personnage, pour que le jeu réponde avec de vraies valeurs
local function Bench(cells, count)
	local updates = Z.cellUpdates
	for i = 1, count do cells[i].unit = "player" end
	local cost = {
		full = Time(function(b) updates.all(b) Z.UpdateAurasNow(b) end, cells, count),
		health = Time(updates.health, cells, count),
		prediction = Time(updates.prediction, cells, count),
		auras = Time(Z.UpdateAurasNow, cells, count),
		power = Time(updates.power, cells, count),
		range = Time(updates.range, cells, count),
	}
	for i = 1, count do
		local cell = cells[i]
		cell:UnregisterAllEvents() -- posés par la mise à jour du rôle (barre de mana)
		cell.unit = nil
		cell:SetAlpha(1)
		-- Ce que le mode test ne redessine pas : sans cela, le marqueur de raid ou la coche « Prêt ? » de mon
		-- personnage resterait sur toutes les fausses cases
		cell.marker:Hide()
		cell.center:Hide()
		cell.threatBar:Hide()
		cell.healAbsorb:SetValue(0)
	end
	local rangeChecks = Z.db.perfMode and 1 or 2
	local perSecond = count * (RATES.health * cost.health + RATES.prediction * cost.prediction
		+ RATES.auras * cost.auras + RATES.power * cost.power + rangeChecks * cost.range)
	return { count = count, full = cost.full * count, perSecond = perSecond }
end

-- La mesure complète. Renvoie le résultat, ou nil et la raison.
function Z:Measure()
	local L = Z.L
	if InCombatLockdown() then return nil, L["la mesure n'est pas disponible en combat."] end
	if not (debugprofilestop and Z.cellUpdates and Z.UpdateAurasNow) then
		return nil, L["ce client ne permet pas de chronométrer le code."]
	end

	-- Mémoire et temps réel d'abord, avant que la mesure n'ajoute quoi que ce soit
	if UpdateAddOnMemoryUsage then pcall(UpdateAddOnMemoryUsage) end
	local read = Profiler()
	local addons = {}
	for _, name in ipairs({ ADDON, unpack(OTHERS) }) do
		if Loaded(name) then
			addons[#addons + 1] = {
				name = name,
				memory = Memory(name),
				average = read and read(name, "SessionAverageTime"),
				recent = read and read(name, "RecentAverageTime"),
				peak = read and read(name, "PeakTime"),
			}
		end
	end
	local share
	local overall = read and read(nil, "SessionAverageTime")
	if overall and overall > 0 and addons[1].average then share = addons[1].average / overall * 100 end

	local cells = Z:PreviewCells(SIZES[#SIZES])
	local groups = {}
	for _, count in ipairs(SIZES) do groups[#groups + 1] = Bench(cells, count) end
	Z:RefreshPreview() -- le mode test, s'il est ouvert, retrouve ses faux joueurs

	local result = { groups = groups, addons = addons, profiler = read ~= nil, share = share, perfMode = Z.db.perfMode }

	-- Trace gardée pour pouvoir être relue hors du jeu
	local last = groups[#groups]
	local line = ("%s | %s | %d joueurs : %.2f ms/s | mémoire %s Ko | mode performance %s"):format(
		date("%Y-%m-%d %H:%M"), Z.version, last.count, last.perSecond,
		addons[1].memory and ("%.0f"):format(addons[1].memory) or "?", Z.db.perfMode and "oui" or "non")
	Z.db.perfDiag = type(Z.db.perfDiag) == "table" and Z.db.perfDiag or {}
	table.insert(Z.db.perfDiag, 1, line)
	while #Z.db.perfDiag > KEEP do table.remove(Z.db.perfDiag) end
	return result
end

----------------------------------------------------------------------------------------------------
-- Fenêtre des résultats
----------------------------------------------------------------------------------------------------
-- Nombres écrits pour le joueur (Z.Decimal, Core.lua) : virgule en français, point en anglais
local function Kilo(value)
	if not value then return "-" end
	if value >= 1024 then return Z.L["%s Mo"]:format(Z.Decimal(value / 1024, 1)) end
	return Z.L["%s Ko"]:format(Z.Decimal(value, 0))
end

local function Milli(value, digits)
	if not value then return "-" end
	return Z.Decimal(value, digits or 2) .. " ms"
end

local function Percent(value)
	return Z.Decimal(value, 2)
end

local COLUMNS_GROUP = { { 16, 120 }, { 140, 170 }, { 314, 130 }, { 448, 96 } }
local COLUMNS_ADDON = { { 16, 140 }, { 160, 110 }, { 274, 130 }, { 408, 136 } }
local ADDON_ROWS = 1 + #OTHERS

local window

local function Row(parent, columns, y, role)
	local row = {}
	for i, column in ipairs(columns) do
		local text = Z.UI.Label(parent, 12, nil, role)
		text:SetPoint("TOPLEFT", column[1], y)
		text:SetWidth(column[2])
		text:SetJustifyH(i == 1 and "LEFT" or "RIGHT")
		row[i] = text
	end
	return row
end

local function Fill(row, ...)
	for i, text in ipairs(row) do text:SetText((select(i, ...))) end
end

local function Note(parent, y)
	local note = Z.UI.Label(parent, 11, nil, "dim")
	note:SetPoint("TOPLEFT", 16, y)
	note:SetWidth(528)
	note:SetJustifyH("LEFT")
	return note
end

-- Les deux états colorés de la phrase du mode performance : écrits dans le texte, pour qu'un changement de
-- thème (qui repeint la phrase en gris) ne les efface pas
local GREEN, GOLD = "|cff73ff8c", "|cffffd14d"

local function Build()
	local UI, L = Z.UI, Z.L
	window = UI.Window("LyorunePerf", L["Performances de Lyorune"], 560, 450)
	window.beside = true -- à côté des options, jamais dessous ni par-dessus
	window:SetFrameStrata("FULLSCREEN_DIALOG")
	tinsert(UISpecialFrames, "LyorunePerf")

	local title = UI.Label(window, 13, nil, "accent")
	title:SetPoint("TOPLEFT", 16, -52)
	title:SetText(L["Coût en combat de raid chargé, mesuré sur votre ordinateur"])
	Fill(Row(window, COLUMNS_GROUP, -76, "accent"), L["Faux groupe"], L["Tout redessiner"], L["Par seconde"], L["Part du temps"])
	window.groups = {}
	for i = 1, #SIZES do window.groups[i] = Row(window, COLUMNS_GROUP, -76 - i * 19) end
	local hypothesis = Note(window, -160)
	hypothesis:SetText(L["Hypothèse : chaque joueur change de vie 4 fois par seconde, de soins en route 3 fois, d'auras 3 fois et de mana 2 fois. Le vrai code de Lyorune tourne sur des cases d'essai."])

	local compare = UI.Label(window, 13, nil, "accent")
	compare:SetPoint("TOPLEFT", 16, -206)
	compare:SetText(L["Comparé aux addons de soin chargés"])
	Fill(Row(window, COLUMNS_ADDON, -230, "accent"), L["Addon"], L["Mémoire"], L["Moyenne par image"], L["Pic"])
	window.addons = {}
	for i = 1, ADDON_ROWS do window.addons[i] = Row(window, COLUMNS_ADDON, -230 - i * 19) end
	window.profiler = Note(window, -362)

	-- Sous la note (souvent sur deux lignes), jamais dessus ; à gauche du bouton « Mesurer à nouveau »
	window.mode = UI.Label(window, 12, nil, "dim")
	window.mode:SetPoint("TOPLEFT", window.profiler, "BOTTOMLEFT", 0, -8)
	window.mode:SetWidth(360)
	window.mode:SetJustifyH("LEFT")
	local again = UI.Button(window, L["Mesurer à nouveau"], 150, 24, function() Z:ShowMeasure() end)
	again:SetPoint("BOTTOMRIGHT", -16, 16)
	again.label:SetJustifyH("CENTER")
end

local function Show(result)
	local L = Z.L
	for i, row in ipairs(window.groups) do
		local group = result.groups[i]
		Fill(row, L["%d joueurs"]:format(group.count), Milli(group.full), Milli(group.perSecond),
			Percent(group.perSecond / 10) .. " %")
	end
	for i, row in ipairs(window.addons) do
		local addon = result.addons[i]
		if addon then
			local name = addon.name == "ElvUI" and L["ElvUI (toute l'interface)"] or addon.name
			if addon.name == ADDON then name = "|cff33dd88" .. name .. "|r" end
			Fill(row, name, Kilo(addon.memory), Milli(addon.average, 3), Milli(addon.peak, 1))
		else
			Fill(row, "", "", "", "")
		end
	end
	local profiler
	if not result.profiler then
		profiler = L["Temps par image indisponible : le profileur du jeu est désactivé sur ce client."]
	elseif result.share then
		profiler = L["Depuis la connexion, Lyorune représente %s %% du temps de tous les addons."]:format(Z.Decimal(result.share, 1))
	else
		profiler = L["Temps par image : moyenne depuis la connexion, mesurée par le jeu."]
	end
	if #result.addons == 1 then profiler = profiler .. " " .. L["Aucun autre addon de soin chargé."] end
	window.profiler:SetText(profiler)

	local heavy = result.groups[#result.groups].perSecond > ADVICE_AT
	if result.perfMode then
		window.mode:SetText(GREEN .. L["Mode performance : activé (chapitre Fenêtre et aide)."] .. "|r")
	elseif heavy then
		window.mode:SetText(GOLD .. L["Conseil : activez le mode performance (chapitre Fenêtre et aide) pour les grands raids."] .. "|r")
	else
		window.mode:SetText(L["Mode performance : désactivé, inutile ici (chapitre Fenêtre et aide)."])
	end
end

-- /lyorune mesure et le bouton « Mesurer les performances » du chapitre Fenêtre et aide. Rappelée alors qu'elle
-- est ouverte, la fenêtre mesure à nouveau (c'est son rôle) et passe devant.
function Z:ShowMeasure()
	local result, reason = Z:Measure()
	if not result then return Z:Print(reason) end
	if not window then Build() end
	Show(result)
	Z.UI.Reopen(window)
	window:Raise()
	local last, mine = result.groups[#result.groups], result.addons[1]
	Z:Print(Z.L["mesure faite : %d joueurs, %s ms par seconde en combat chargé (%s %%), mémoire %s."]:format(
		last.count, Z.Decimal(last.perSecond, 2), Percent(last.perSecond / 10), Kilo(mine.memory)))
end

-- Pour les tests
function Z:MeasureWindow()
	return window
end
