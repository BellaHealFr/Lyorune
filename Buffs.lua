-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Buffs.lua : panneau des buffs manquants, hors combat seulement.
-- Une ligne par joueur à qui manque un de mes buffs de groupe : un clic le lui lance, sans le cibler.
-- Un buff unique (Bouclier de terre...) a sa ligne pour le tank, ou pour le joueur choisi, s'il n'est sur personne.
-- Quand je connais la version de groupe du buff et que 3 joueurs d'un même groupe en manquent, une seule ligne
-- « Groupe N » lance la version de groupe : moins de clics, moins de mana.
-- Le panneau se cache à l'entrée en combat (avant que le jeu ne verrouille ses boutons) et revient après.
-- Il lit ce que les cases ont déjà trouvé (b.missingBuff, Auras.lua) : aucune lecture d'aura en plus.

local _, Z = ...
local UI = Z.UI
local issecret = Z.IsSecret

local MAX_ROWS = 10    -- au-delà, une ligne « et N autres »
local ROW_H = 22
local GROUP_AT = 3     -- joueurs d'un même groupe sans le buff à partir desquels la version de groupe est proposée
local WIDTH = 230

local panel, more
local rows = {}
local queued = false
local closed = false   -- fermé par la croix : revient à la fin du prochain combat

-- Groupe de raid d'une unité (1 en groupe de 5 ; 0 pour un familier, toujours sur sa propre ligne)
local function SubGroup(unit)
	local index = unit:match("^raid(%d+)$")
	if index and GetRaidRosterInfo then
		local group = select(3, GetRaidRosterInfo(tonumber(index)))
		return tonumber(group) or 1
	end
	if unit:find("pet", 1, true) then return 0 end
	return 1
end

-- Joueurs à qui manque un buff, lus sur les cases visibles (chacun une seule fois)
local function Missing()
	local list, seen = {}, {}
	for _, b in ipairs(Z.buttons) do
		local unit, check = b.unit, b.missingBuff
		if unit and check and not b.extra and not seen[unit] and b:IsVisible() then
			local name = UnitName(unit)
			if name and not issecret(name) then
				seen[unit] = true
				list[#list + 1] = { unit = unit, check = check, name = name, group = SubGroup(unit),
					class = select(2, UnitClass(unit)) }
			end
		end
	end
	table.sort(list, function(a, b)
		if a.group ~= b.group then return a.group < b.group end
		return a.name < b.name
	end)
	return list
end

-- Buffs uniques (Bouclier de terre...) : une ligne pour le joueur choisi (/lyorune porteur), sinon pour le tank,
-- tant que le mien n'est posé sur personne. Lu sur les cases visibles (b.myUniques, Auras.lua).
local function UniqueRows(result)
	if #Z.uniqueChecks == 0 then return end
	local placed, chosen, tank = {}, nil, nil
	local wanted = Z.char.buffTarget.name
	for _, b in ipairs(Z.buttons) do
		local unit = b.unit
		if unit and not b.extra and b:IsVisible() and not unit:find("pet", 1, true) then
			for name in (b.myUniques or ""):gmatch("[^,]+") do placed[name] = true end
			local name = Z.UnitPinName(unit)
			if name and wanted and name == wanted then chosen = chosen or { unit = unit, name = name } end
			local role = UnitGroupRolesAssigned(unit)
			if name and not issecret(role) and role == "TANK" then tank = tank or { unit = unit, name = name } end
		end
	end
	local target, why = chosen, Z.L["choisi"]
	if not target then target, why = tank, Z.L["tank"] end
	if not target then return end
	for _, check in ipairs(Z.uniqueChecks) do
		if not placed[check.name] then
			result[#result + 1] = { check = check, spell = check.spell, unit = target.unit, name = target.name,
				class = select(2, UnitClass(target.unit)), why = why }
		end
	end
end

-- Lignes du panneau : un buff après l'autre (ordre de Data.lua), un joueur ou un groupe entier par ligne
function Z.BuffRows()
	local missing, result = Missing(), {}
	for _, check in ipairs(Z.buffChecks) do
		local byGroup, order = {}, {}
		for _, entry in ipairs(missing) do
			if entry.check == check then
				if not byGroup[entry.group] then
					byGroup[entry.group] = {}
					order[#order + 1] = entry.group
				end
				table.insert(byGroup[entry.group], entry)
			end
		end
		for _, group in ipairs(order) do
			local players = byGroup[group]
			if check.groupSpell and group > 0 and #players >= GROUP_AT then
				result[#result + 1] = { check = check, spell = check.groupSpell, unit = players[1].unit, group = group,
					count = #players, players = players }
			else
				for _, entry in ipairs(players) do
					result[#result + 1] = { check = check, spell = check.spell, spell2 = check.groupSpell,
						unit = entry.unit, name = entry.name, class = entry.class }
				end
			end
		end
	end
	UniqueRows(result)
	return result
end

-- Portée : une ligne hors de portée est estompée, comme sa case (le jeu ne dit rien en combat, le panneau
-- n'existe pas en combat)
local function UpdateRange()
	for _, row in ipairs(rows) do
		if row:IsShown() and row.unitToken then
			local inRange, checked = UnitInRange(row.unitToken)
			local far = not issecret(inRange) and checked and not inRange
			if UnitIsUnit(row.unitToken, "player") then far = false end
			row:SetAlpha(far and 0.4 or 1)
		end
	end
end

local function RowEnter(self)
	self.hover:Show()
	local L = Z.L
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(self.label:GetText() or "", 1, 1, 1)
	GameTooltip:AddLine(L["Clic : %s"]:format(self.spellName or ""), UI.accent[1], UI.accent[2], UI.accent[3])
	if self.why then
		GameTooltip:AddLine(Z.L["Un autre joueur : /lyorune porteur en survolant sa case."], 0.8, 0.8, 0.8, true)
	end
	if self.spell2Name then
		GameTooltip:AddLine(L["Clic droit : %s (tout son groupe)"]:format(self.spell2Name), 0.8, 0.8, 0.8)
	end
	GameTooltip:Show()
end

local function RowLeave(self)
	self.hover:Hide()
	GameTooltip:Hide()
end

-- Une ligne : bouton sécurisé du jeu (il lance le sort sur l'unité), créé hors combat
local function Row(index)
	if rows[index] then return rows[index] end
	local row = CreateFrame("Button", "LyoruneBuffsRow" .. index, panel, "SecureActionButtonTemplate")
	row:SetSize(WIDTH - 28, ROW_H)
	row:SetPoint("TOPLEFT", 14, -42 - (index - 1) * (ROW_H + 2))
	row.bg = UI.Paint(UI.Tex(row, "BACKGROUND"), "panel")
	row.bg:SetAllPoints()
	row.hover = UI.Paint(UI.Tex(row, "BORDER"), "accent", 0.18)
	row.hover:SetAllPoints()
	row.hover:Hide()
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ROW_H - 4, ROW_H - 4)
	row.icon:SetPoint("LEFT", 2, 0)
	row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	row.label = UI.Text(row, 12)
	row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	row.label:SetPoint("RIGHT", -4, 0)
	row.label:SetJustifyH("LEFT")
	row.label:SetWordWrap(false)
	row:SetScript("OnEnter", RowEnter)
	row:SetScript("OnLeave", RowLeave)
	rows[index] = row
	return row
end

local function SavePosition(self)
	self:StopMovingOrSizing()
	local point, _, relative, x, y = self:GetPoint()
	Z.char.buffPos = { point, math.floor(x + 0.5), math.floor(y + 0.5), relative }
end

local function Build()
	panel = UI.Window("LyoruneBuffs", Z.L["Buffs manquants"], WIDTH, 80)
	panel:SetFrameStrata("MEDIUM")
	panel:SetScript("OnDragStop", SavePosition)
	panel.close:SetScript("OnClick", function()
		closed = true
		panel:Close()
	end)
	more = UI.Label(panel, 11, nil, "dim")
	more:SetJustifyH("LEFT")
	local elapsed = 0
	panel:SetScript("OnUpdate", function(_, delta) -- portée seulement, et seulement panneau ouvert
		elapsed = elapsed + delta
		if elapsed >= 0.5 then
			elapsed = 0
			UpdateRange()
		end
	end)
	local pos = Z.char.buffPos
	panel:ClearAllPoints()
	panel:SetPoint(pos[1], UIParent, pos[4] or pos[1], pos[2], pos[3])
end

function Z:UpdateBuffPanel()
	queued = false
	if InCombatLockdown() then return end -- les boutons du jeu ne bougent plus en combat
	local list = (Z.db.buffPanel and not closed and (#Z.buffChecks > 0 or #Z.uniqueChecks > 0)) and Z.BuffRows() or {}
	if #list == 0 then
		if panel then panel:Hide() end
		return
	end
	if not panel then Build() end
	local L = Z.L
	local castOnDown = Z.db.castOnDown
	local shown = math.min(#list, MAX_ROWS)
	for i = 1, shown do
		local entry, row = list[i], Row(i)
		row:RegisterForClicks(castOnDown and "AnyDown" or "AnyUp")
		row:SetAttribute("unit", entry.unit)
		row:SetAttribute("type1", "spell")
		row:SetAttribute("spell1", entry.spell)
		row:SetAttribute("type2", entry.spell2 and "spell" or nil)
		row:SetAttribute("spell2", entry.spell2)
		row.unitToken, row.spellName, row.spell2Name, row.why = entry.unit, entry.spell, entry.spell2, entry.why
		row.icon:SetTexture(entry.check.icon)
		if entry.count then
			row.label:SetText(L["Groupe %d"]:format(entry.group) .. "  |cffb3b3b3(" .. entry.count .. ")|r")
			row.label:SetTextColor(unpack(UI.accent))
		elseif entry.why then
			row.label:SetText(entry.name .. "  |cffb3b3b3(" .. entry.why .. ")|r")
			row.label:SetTextColor(Z.ClassColor(entry.class))
		else
			row.label:SetText(entry.name)
			row.label:SetTextColor(Z.ClassColor(entry.class))
		end
		row:Show()
	end
	for i = shown + 1, #rows do
		rows[i]:Hide()
		rows[i].unitToken = nil
	end
	local height = 42 + shown * (ROW_H + 2) + 12
	more:ClearAllPoints()
	more:SetPoint("TOPLEFT", 16, -42 - shown * (ROW_H + 2) - 2)
	if #list > shown then
		more:SetText(L["et %d autres"]:format(#list - shown))
		more:Show()
		height = height + 16
	else
		more:Hide()
	end
	panel:SetHeight(height)
	UpdateRange()
	if not panel:IsShown() then panel:Show() end
end

-- Plusieurs cases qui changent dans la même seconde : une seule mise à jour du panneau
function Z:QueueBuffPanel()
	if queued then return end
	queued = true
	C_Timer.After(0.3, function() Z:Try("panneau des buffs", Z.UpdateBuffPanel, Z) end)
end

function Z:BuffPanel()
	return panel
end

-- Entrée en combat : le jeu verrouille les boutons juste après cet événement, on cache le panneau avant
Z:On("PLAYER_REGEN_DISABLED", function()
	if panel and not InCombatLockdown() then panel:Hide() end
end)
Z:On("PLAYER_REGEN_ENABLED", function()
	closed = false
	Z:QueueBuffPanel()
end)
Z:On("GROUP_ROSTER_UPDATE", function() Z:QueueBuffPanel() end)

-- /lyorune porteur [nom] : le joueur qui reçoit mes buffs uniques à la place du tank (le joueur survolé, ou ma
-- cible). Le même joueur une 2e fois, ou sans joueur : retour au tank. Gardé pour ce personnage.
function Z:BuffTargetCommand(text)
	local L, target = Z.L, Z.char.buffTarget
	local name
	if text and text ~= "" then
		name = Z.CleanPinName(text)
	else
		local hovered = Z.hovered and Z.hovered:IsVisible() and Z.hovered.unit
		name = Z.UnitPinName(hovered) or Z.UnitPinName("target")
	end
	if not name or name == target.name then
		target.name = nil
		Z:Print(L["buffs uniques : de retour sur le tank."])
	else
		target.name = name
		Z:Print(L["buffs uniques : %s les recevra."]:format(name))
	end
	Z:QueueBuffPanel()
end
