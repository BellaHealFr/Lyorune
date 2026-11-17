-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Preview.lua : le mode test. Affiche un faux groupe (5, 10, 25 ou 40 joueurs) pour régler
-- l'apparence sans être en groupe. Les fausses cases utilisent exactement le même habillage que les vraies.
-- Le mode test se ferme tout seul à l'entrée en combat.

local _, Z = ...
local UI = Z.UI

local container
local cells = {}
local size = 10

local CLASSES = { "WARRIOR", "PRIEST", "DRUID", "MAGE", "PALADIN", "ROGUE", "SHAMAN", "HUNTER", "WARLOCK" }
local HEALTH = { 100, 62, 100, 18, 85, 100, 0, 45, 100, 73 } -- vie des faux joueurs, en %
local DISPEL_COLORS = { { 0.20, 0.60, 1.00 }, { 0.65, 0.20, 1.00 }, { 0.10, 0.85, 0.20 } }

-- Remplit une fausse case avec un état d'exemple
local function Fill(cell, index)
	local db, L = Z.db, Z.L
	local class = CLASSES[(index - 1) % #CLASSES + 1]
	local r, g, b = Z.ClassColor(class)
	local health = HEALTH[(index - 1) % #HEALTH + 1]
	local dead = health == 0

	cell.hp:SetMinMaxValues(0, 100)
	cell.hp:SetValue(health)
	cell.name:SetText(L["Joueur"] .. " " .. index)
	if dead then
		cell.hp:SetStatusBarColor(0.25, 0.25, 0.28)
		cell.name:SetTextColor(0.65, 0.65, 0.68)
		cell.text:SetText(L["Mort"])
		cell.text:SetTextColor(0.95, 0.35, 0.35)
	else
		if db.color == "CLASS" then
			cell.hp:SetStatusBarColor(r, g, b)
			cell.name:SetTextColor(1, 1, 1)
		else
			cell.hp:SetStatusBarColor(1 - health / 100, health / 100 * 0.8, 0.2)
			cell.name:SetTextColor(r, g, b)
		end
		cell.text:SetTextColor(1, 1, 1)
		if db.text == "DEFICIT" then
			cell.text:SetText(health < 100 and ("-" .. (100 - health) * 40) or "")
		elseif db.text == "PERCENT" then
			cell.text:SetText(health .. "%")
		else
			cell.text:SetText("")
		end
	end
	cell.text:SetAlpha(1)

	-- Soins en route et bouclier sur quelques joueurs blessés
	cell.incoming:SetMinMaxValues(0, 100)
	cell.incoming:SetValue((not dead and health < 90 and index % 2 == 0) and 15 or 0)
	cell.absorb:SetMinMaxValues(0, 100)
	cell.absorb:SetValue((not dead and index % 5 == 2) and 30 or 0)

	-- Rôles : un tank et un soigneur par groupe de cinq
	local slot = (index - 1) % 5
	local role = slot == 0 and "TANK" or slot == 1 and "HEALER" or nil
	cell.role:SetShown(db.showRole and role ~= nil)
	if role then cell.role:SetAtlas(role == "TANK" and "roleicon-tiny-tank" or "roleicon-tiny-healer") end
	-- Chef de groupe sur la première case, un assistant par groupe de cinq en raid
	local leader = db.showLeader and (index == 1 and "LeaderIcon" or size > 5 and slot == 0 and "AssistantIcon")
	if leader then cell.leader:SetTexture("Interface\\GroupFrame\\UI-Group-" .. leader) end
	cell.leader:SetShown(leader and true or false)
	local mana = db.manaBars == "ALL" or (db.manaBars == "HEALERS" and role == "HEALER")
	if mana ~= cell.powerShown then
		cell.powerShown = mana
		cell.power:SetShown(mana)
		Z.StyleButton(cell)
	end
	cell.power:SetMinMaxValues(0, 100)
	cell.power:SetValue(65)

	cell.threat:SetShown(db.showThreat and slot == 0 and not dead)
	cell.low.fill:SetAlpha((db.lowHealth and not dead and health <= db.lowHealthAt) and 1 or 0)
	cell.selected:SetAlpha(index == 2 and 1 or 0)
	cell:SetAlpha(index % 10 == 9 and db.rangeAlpha / 100 or 1)

	-- Dissipation possible sur un joueur sur six
	local dispel = db.showDispel and not dead and index % 6 == 3 and DISPEL_COLORS[math.floor(index / 6) % #DISPEL_COLORS + 1]
	if dispel then
		Z.ShowDispel(cell, true, dispel[1], dispel[2], dispel[3], 1)
	else
		Z.ShowDispel(cell, false)
	end

	-- Soins sur la durée d'exemple, avec les icônes de mes vrais sorts
	Z.HideAuras(cell)
	if db.showHots and not dead and index % 3 ~= 0 then
		local shown = 0
		for _, id in ipairs(Z.trackedSpells[Z.class] or { 139, 774 }) do
			if shown == 2 then break end
			shown = shown + 1
			if db.hotStyle == "BARS" then
				local bar = Z.HotBar(cell, shown)
				bar:SetMinMaxValues(0, 1)
				bar:SetValue(shown == 1 and 0.8 or 0.4)
				bar:Show()
			else
				local icon = Z.HotIcon(cell, shown)
				icon.texture:SetTexture(C_Spell.GetSpellTexture(id))
				icon.cooldown:Clear()
				icon.count:SetText("")
				icon:Show()
			end
		end
	end
	if db.showDebuffs and (dispel or index % 7 == 5) and not dead then
		local icon = Z.DebuffIcon(cell, 1)
		icon.texture:SetTexture("Interface\\Icons\\Spell_Shadow_CurseOfTounges")
		icon.cooldown:Clear()
		icon.count:SetText("")
		icon:Show()
	end
end

-- Ordre des faux joueurs, comme le jeu le ferait : trié dans chaque groupe de cinq, ou dans toute la grille.
-- Renvoie la liste des numéros de faux joueurs, place par place.
local function Order()
	local db, L = Z.db, Z.L
	local classRank, rank = {}, 0
	for class in Z.ClassOrder():gmatch("[^,]+") do rank = rank + 1; classRank[class] = rank end
	local function name(i) return L["Joueur"] .. " " .. i end
	local function before(a, b)
		if db.sortOrder == "CLASS" then
			local ca = classRank[CLASSES[(a - 1) % #CLASSES + 1]] or 99
			local cb = classRank[CLASSES[(b - 1) % #CLASSES + 1]] or 99
			if ca ~= cb then return ca < cb end
		end
		if db.sortOrder == "INDEX" then return a < b end
		return name(a) < name(b)
	end
	local order, block = {}, db.layout == "GRID" and size or 5
	for first = 1, size, block do
		local chunk = {}
		for i = first, math.min(first + block - 1, size) do chunk[#chunk + 1] = i end
		table.sort(chunk, before)
		for _, i in ipairs(chunk) do order[#order + 1] = i end
	end
	return order
end

-- Range les fausses cases comme le ferait le jeu : par paquets de cinq, chaque paquet sur son fond (réglage),
-- ou en une seule grille de la hauteur choisie
local function Layout()
	local db = Z.db
	local width, height = Z.CellSize()
	local grid = db.layout == "GRID"
	local perColumn = grid and db.gridSize or 5
	local apart = (db.groupPanel and not grid) and 6 or 0 -- même écart que les vrais cadres entre deux fonds de groupe
	local order = Order()
	for place, cell in ipairs(cells) do
		local shown = place <= size
		cell:SetShown(shown)
		if shown then
			local group, slot = math.floor((place - 1) / perColumn), (place - 1) % perColumn
			local x, y
			if db.horizontal then
				x, y = slot * (width + db.spacing), -group * (height + db.spacing + apart)
			else
				x, y = group * (width + db.spacing + apart), -slot * (height + db.spacing)
			end
			cell:ClearAllPoints()
			cell:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)
			cell:SetSize(width, height)
			Z.StyleButton(cell)
			Fill(cell, order[place])
		end
	end
	for group = 1, 8 do
		local first = cells[(group - 1) * 5 + 1]
		local wanted = db.groupPanel and first and first:IsShown()
		local last = cells[math.min(group * 5, size)]
		if grid then -- un seul fond pour toute la grille, posé sur un cadre invisible de sa taille
			wanted = wanted and group == 1
			local columns, rows = math.ceil(size / perColumn), math.min(size, perColumn)
			if db.horizontal then columns, rows = rows, columns end
			container.box = container.box or CreateFrame("Frame", nil, container)
			container.box:ClearAllPoints()
			container.box:SetPoint("TOPLEFT", container, "TOPLEFT")
			container.box:SetSize(columns * width + (columns - 1) * db.spacing, rows * height + (rows - 1) * db.spacing)
			first, last = container.box, container.box
		end
		local panel = container.panels[group]
		if wanted and not panel then
			panel = Z.BuildPanel(container)
			container.panels[group] = panel
		end
		if panel then
			if wanted then Z.StylePanel(panel, first, last) end
			panel:SetShown(wanted and true or false)
		end
	end
	container:SetAlpha(db.frameAlpha / 100)
	container:SetScale(db.scale / 100) -- même échelle générale que les vrais cadres
end

function Z:RefreshPreview()
	if Z.previewActive then Layout() end
end

local function Stop()
	if not Z.previewActive then return end
	Z.previewActive = false
	container:Hide()
	Z:Refresh() -- réaffiche les vrais cadres (à la fin du combat si besoin)
end

function Z:PreviewSize()
	return size
end

-- Le cadre du mode test et ses fausses cases, créés une seule fois, au premier besoin
local function EnsureCells(count)
	if not container then
		container = CreateFrame("Frame", "LyorunePreview", UIParent)
		container:SetSize(10, 10)
		container:SetPoint("TOPLEFT", Z.anchor, "BOTTOMLEFT", 0, -3)
		container.panels = {}
		container.label = UI.Text(container, 11)
		container.label:SetPoint("BOTTOMLEFT", Z.anchor, "TOPLEFT", 0, 3)
		container.label:SetTextColor(UI.frameAccent[1], UI.frameAccent[2], UI.frameAccent[3])
		Z:On("PLAYER_REGEN_DISABLED", Stop)
		container:Hide()
	end
	for index = #cells + 1, count do
		local cell = CreateFrame("Frame", nil, container)
		Z.BuildVisuals(cell)
		cells[index] = cell
	end
	return cells
end

-- La mesure des performances (Perf.lua) prête ces mêmes cases : aucun cadre de plus en mémoire
function Z:PreviewCells(count)
	return EnsureCells(count)
end

-- Z:TogglePreview() ouvre ou ferme. Z:TogglePreview(25) ouvre avec 25 faux joueurs.
function Z:TogglePreview(wanted)
	if Z.previewActive and (not wanted or wanted == size) then return Stop() end
	if InCombatLockdown() then
		return Z:Print(Z.L["le mode test n'est pas disponible en combat."])
	end
	size = wanted or size
	EnsureCells(size)
	container.label:SetText(Z.L["Mode test : faux groupe. /lyorune test pour quitter."])
	Z.previewActive = true
	container:Show()
	Z:Refresh() -- masque les vrais cadres et dessine les faux
end
