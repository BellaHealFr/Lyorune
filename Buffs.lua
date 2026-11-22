-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Buffs.lua : panneau des buffs manquants, hors combat seulement.
-- Une ligne par buff qui manque à un joueur (tous ses buffs manquants, pas seulement le premier) : un clic le
-- lui lance, sans le cibler. Seuls comptent les buffs de ma liste pour ce lieu (« Mes buffs », JcE ou JcJ).
-- Un buff unique (Bouclier de terre...) a sa ligne pour le tank, ou pour le joueur choisi, s'il n'est sur personne.
-- Quand je connais la version de groupe du buff et que N joueurs d'un même groupe en manquent (réglage
-- « buffGroupAt »), une seule ligne « Groupe N » lance la version de groupe : moins de clics, moins de mana.
-- Le panneau se cache à l'entrée en combat (avant que le jeu ne verrouille ses boutons) et revient après.
-- Il lit ce que les cases ont déjà trouvé (b.missingBuff, Auras.lua) : aucune lecture d'aura en plus.

local _, Z = ...
local UI = Z.UI
local issecret = Z.IsSecret

local MAX_ROWS = 10    -- au-delà, une ligne « et N autres »
local ROW_H = 22
local WIDTH = 230

local panel, more
local rows = {}
local queued = false
local closed = false   -- fermé par la croix : revient à la fin du prochain combat
local cooldownAt       -- fin de recharge d'un buff unique déjà attendue (UniqueRows)

-- Raccourci « Poser le prochain buff manquant » (Bindings.xml : CLICK LyoruneNextBuff:LeftButton). Un bouton
-- sécurisé caché, créé au chargement (hors combat), qui lance la première ligne du panneau. Il est vidé dès que
-- le panneau n'a plus rien à proposer et à l'entrée en combat : une touche ne lance jamais un ancien buff.
-- Il suit le panneau même fermé par la croix (le joueur n'a pas besoin de le voir pour appuyer).
local nextBuff = CreateFrame("Button", "LyoruneNextBuff", UIParent, "SecureActionButtonTemplate")
nextBuff:Hide()

local function SetNextBuff(entry)
	if InCombatLockdown() then return end
	-- une touche part selon « useOnKeyDown », posé au même sens que les clics (comme les cases, C11)
	local castOnDown = Z.db and Z.db.castOnDown
	nextBuff:RegisterForClicks(castOnDown and "AnyDown" or "AnyUp")
	nextBuff:SetAttribute("useOnKeyDown", castOnDown and true or false)
	nextBuff:SetAttribute("unit", entry and entry.unit)
	nextBuff:SetAttribute("type", entry and "spell")
	nextBuff:SetAttribute("spell", entry and entry.spell)
	nextBuff.entry = entry
end

-- Après l'appui : un mot quand rien n'est parti (combat, ou aucun buff à poser), pour que la touche ne semble
-- pas cassée
nextBuff:SetScript("PostClick", function(self)
	if InCombatLockdown() then
		Z:Print(Z.L["le prochain buff manquant se pose hors combat seulement."])
	elseif not self.entry then
		Z:Print(Z.L["aucun buff manquant à poser."])
	end
end)

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

-- Buffs qui manquent aux joueurs, lus sur les cases visibles (chaque joueur une seule fois) : une entrée par
-- joueur et par buff
local function Missing()
	local list, seen = {}, {}
	for _, b in ipairs(Z.buttons) do
		local unit = b.unit
		if unit and b.missingBuff and not b.extra and not seen[unit] and b:IsVisible() then
			local name = UnitName(unit)
			if name and not issecret(name) then
				seen[unit] = true
				local group, class = SubGroup(unit), select(2, UnitClass(unit))
				for _, missing in ipairs(b.missingBuffs or { b.missingBuff }) do
					list[#list + 1] = { unit = unit, check = missing.check, spell = missing.spell, icon = missing.icon,
						name = name, group = group, class = class }
				end
			end
		end
	end
	table.sort(list, function(a, b)
		if a.group ~= b.group then return a.group < b.group end
		return a.name < b.name
	end)
	return list
end

-- Sort en recharge (hors temps de recharge global) : secondes restantes, sinon nil. Lisible hors combat.
local function CooldownLeft(name)
	local info = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(name)
	if not info or issecret(info.startTime) or issecret(info.duration) or issecret(info.isOnGCD) then return end
	if info.isOnGCD or not info.startTime or info.startTime == 0 or (info.duration or 0) <= 1.5 then return end
	local left = info.startTime + info.duration - GetTime()
	return left > 0 and left or nil
end

-- Une ligne de buff unique pour son porteur, si elle est à proposer
local function UniqueRow(result, check, placed, target, why)
	local wanted = not placed[check.name] and Z.BuffWatched(check)
	local wait = wanted and CooldownLeft(check.spell)
	if wait then
		-- un seul rendez-vous à la fois : le panneau se relit souvent hors combat
		local at = GetTime() + wait
		if not (cooldownAt and cooldownAt > GetTime() and cooldownAt <= at) then
			cooldownAt = at
			C_Timer.After(wait + 0.2, function() Z:QueueBuffPanel() end)
		end
	elseif wanted then
		result[#result + 1] = { check = check, spell = check.spell, icon = check.icon, unit = target.unit,
			name = target.name, class = select(2, UnitClass(target.unit)), why = why }
	end
end

-- Sur qui poser un buff unique : « TANK » (départ), « ME » (moi) ou « NAME » (un joueur choisi, name). Choix par
-- buff dans « Mes buffs » (Z.char.buffTarget.byId), sinon le joueur de /lyorune porteur (buffTarget.name), sinon
-- le tank. Gardé pour ce personnage.
function Z.BuffBearer(id)
	local target = Z.char.buffTarget
	local chosen = target.byId and target.byId[id]
	if chosen then return chosen.mode, chosen.name end
	if target.name then return "NAME", target.name end
	return "TANK"
end

function Z.SetBuffBearer(id, mode, name)
	local target = Z.char.buffTarget
	target.byId = target.byId or {}
	target.byId[id] = { mode = mode, name = mode == "NAME" and name or nil }
	Z:QueueBuffPanel()
end

-- Buffs uniques (Bouclier de terre...) : une ligne par buff pour son porteur (Z.BuffBearer) : le joueur choisi,
-- moi, ou le tank ; joueur choisi absent (ou mort, ou déconnecté) : le tank ; pas de tank : moi. Seulement tant que le mien n'est posé sur
-- personne, s'il est dans ma liste et s'il n'est pas en recharge (le panneau se relit à la fin de la recharge).
-- Lu sur les cases visibles (b.myUniques, Auras.lua).
local function UniqueRows(result)
	if #Z.uniqueChecks == 0 then return end
	local placed, members, tank, me = {}, {}, nil, nil
	for _, b in ipairs(Z.buttons) do
		local unit = b.unit
		if unit and not b.extra and b:IsVisible() and not unit:find("pet", 1, true) then
			for name in (b.myUniques or ""):gmatch("[^,]+") do placed[name] = true end
			local name = Z.UnitPinName(unit)
			if name and not b.status then -- mort, fantôme ou déconnecté : ne peut pas recevoir le buff
				local player = { unit = unit, name = name }
				members[name] = members[name] or player
				local role = UnitGroupRolesAssigned(unit)
				if not issecret(role) and role == "TANK" then tank = tank or player end
				local isMe = UnitIsUnit(unit, "player")
				if not issecret(isMe) and isMe then me = me or player end
			end
		end
	end
	for _, check in ipairs(Z.uniqueChecks) do
		local mode, name = Z.BuffBearer(check.id)
		local target, why
		if mode == "NAME" and members[name] then target, why = members[name], Z.L["choisi"]
		elseif mode == "ME" and me then target, why = me, Z.L["vous"] end
		if not target and tank then target, why = tank, Z.L["tank"] end
		if not target and me then target, why = me, Z.L["vous"] end
		if target then UniqueRow(result, check, placed, target, why) end
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
		-- « Mes buffs » : version de groupe décochée = la version simple seulement ; version simple décochée = la
		-- version de groupe seulement, dès un joueur du groupe sans le buff (un familier seul, groupe 0 : rien).
		-- Sans le composant de la version de groupe : la version simple, comme si elle était seule cochée.
		local groupSpell = Z.GroupSpell(check)
		local simple = Z.BuffWatched(check) or not groupSpell
		local groupAt = simple and Z.db.buffGroupAt or 1
		for _, group in ipairs(order) do
			local players = byGroup[group]
			if groupSpell and group > 0 and #players >= groupAt then
				result[#result + 1] = { check = check, spell = groupSpell, icon = check.icon, unit = players[1].unit,
					group = group, count = #players, players = players }
			elseif simple then
				for _, entry in ipairs(players) do
					result[#result + 1] = { check = check, spell = entry.spell, spell2 = groupSpell, icon = entry.icon,
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
	local list = (Z.db.buffPanel and (#Z.buffChecks > 0 or #Z.uniqueChecks > 0)) and Z.BuffRows() or {}
	SetNextBuff(list[1])
	if closed then list = {} end
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
		row.icon:SetTexture(entry.icon or entry.check.icon)
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
	SetNextBuff(nil)
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
	target.byId = nil -- la commande vaut pour tous mes buffs uniques : les choix par buff s'effacent
	if not name or name == target.name then
		target.name = nil
		Z:Print(L["buffs uniques : de retour sur le tank."])
	else
		target.name = name
		Z:Print(L["buffs uniques : %s les recevra."]:format(name))
	end
	Z:QueueBuffPanel()
end
