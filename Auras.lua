-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Auras.lua : ce qui s'affiche sur une case à partir des auras du joueur.
--   en haut à gauche  : mes soins sur la durée (icônes ou barres fines)
--   en bas à droite   : ses affaiblissements
--   à gauche, en grand: un affaiblissement important (boss, ou liste personnelle)
--   en bas à gauche   : un buff de groupe qui lui manque (hors combat)
--   bordure colorée   : je peux dissiper quelque chose
-- Performance : plusieurs changements d'auras dans la même image ne déclenchent qu'une seule mise à jour.

local _, Z = ...
local UI = Z.UI
local issecret = Z.IsSecret

local GetUnitAuras = C_UnitAuras.GetUnitAuras
local GetAuraDuration = C_UnitAuras.GetAuraDuration
local GetAuraCount = C_UnitAuras.GetAuraApplicationDisplayCount
local GetDispelColor = C_UnitAuras.GetAuraDispelTypeColor
local SORT = Enum.UnitAuraSortRule and Enum.UnitAuraSortRule.Default
local REMAINING = Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime
local IMMEDIATE = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate

local MAX_HOTS, MAX_DEBUFFS = 4, 2
local BAR_COLORS = { { 0.35, 0.95, 0.45 }, { 0.30, 0.80, 1.00 }, { 1.00, 0.85, 0.30 }, { 1.00, 0.50, 0.85 } }

-- Liste des auras d'un joueur pour un filtre donné (nil si le client refuse le filtre)
local function Auras(unit, filter, count)
	local ok, list = pcall(GetUnitAuras, unit, filter, count, SORT, 1)
	return ok and list or nil
end

-- Couleur selon le type : 1 magie, 2 malédiction, 3 maladie, 4 poison. Le jeu fait la correspondance,
-- ce qui fonctionne même quand le type est une valeur secrète.
local dispelCurve

local function BuildCurve()
	dispelCurve = C_CurveUtil.CreateColorCurve()
	dispelCurve:SetType(Enum.LuaCurveType.Step)
	dispelCurve:AddPoint(0, CreateColor(0, 0, 0, 0))
	dispelCurve:AddPoint(1, CreateColor(0.20, 0.60, 1.00, 1)) -- magie : bleu
	dispelCurve:AddPoint(2, CreateColor(0.65, 0.20, 1.00, 1)) -- malédiction : violet
	dispelCurve:AddPoint(3, CreateColor(0.75, 0.50, 0.10, 1)) -- maladie : brun
	dispelCurve:AddPoint(4, CreateColor(0.10, 0.85, 0.20, 1)) -- poison : vert
	dispelCurve:AddPoint(5, CreateColor(0, 0, 0, 0))
end

----------------------------------------------------------------------------------------------------
-- Icônes et barres
----------------------------------------------------------------------------------------------------
local function NewIcon(b)
	local icon = CreateFrame("Frame", nil, b.over)
	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetAllPoints()
	icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon.border = UI.Border(icon, 1, 1)
	icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
	icon.cooldown:SetAllPoints()
	icon.cooldown:SetReverse(true)
	icon.cooldown:SetHideCountdownNumbers(true)
	icon.cooldown:SetDrawEdge(false)
	icon.count = UI.Text(icon.border, 9, "OUTLINE")
	icon.count:SetPoint("BOTTOMRIGHT", 2, -2)
	return icon
end

-- Icône numéro « index » d'une rangée, créée à la demande. direction : 1 vers la droite, -1 vers la gauche
local function GetIcon(b, list, index, point, x, y, direction, scale)
	local icon = list[index]
	if not icon then
		icon = NewIcon(b)
		list[index] = icon
	end
	local size = math.floor(b.iconSize * (scale or 1) + 0.5)
	icon:SetSize(size, size)
	icon:ClearAllPoints()
	icon:SetPoint(point, b.over, point, x + direction * (index - 1) * (size + 2), y)
	return icon
end
Z.GetAuraIcon = GetIcon

local function ShowAura(icon, unit, aura)
	local id = aura.auraInstanceID
	icon.texture:SetTexture(aura.icon)
	icon.texture:SetDesaturated(false)
	local duration = GetAuraDuration(unit, id)
	if duration then
		icon.cooldown:SetCooldownFromDurationObject(duration)
	else
		icon.cooldown:Clear()
	end
	icon.count:SetText(GetAuraCount(unit, id, 2, 99))
	icon:SetAlpha(1)
	icon:Show()
end

-- Barre fine numéro « index » : elle se vide avec la durée restante du soin
local function GetBar(b, index)
	local bar = b.hotBars[index]
	if not bar then
		bar = CreateFrame("StatusBar", nil, b.over)
		bar:SetStatusBarTexture(UI.WHITE)
		bar.bg = UI.Tex(bar, "BACKGROUND", 0, 0, 0, 0.6)
		bar.bg:SetAllPoints()
		local color = BAR_COLORS[index] or BAR_COLORS[1]
		bar:SetStatusBarColor(color[1], color[2], color[3])
		b.hotBars[index] = bar
	end
	bar:SetSize(math.floor(Z.CellSize() * 0.45), 3)
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", b.over, "TOPLEFT", 3, -3 - (index - 1) * 4)
	return bar
end
Z.GetHotBar = GetBar

local function ShowBar(bar, unit, aura)
	local duration = GetAuraDuration(unit, aura.auraInstanceID)
	if not (duration and bar.SetTimerDuration and pcall(bar.SetTimerDuration, bar, duration, IMMEDIATE, REMAINING)) then
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(1)
	end
	bar:Show()
end

-- Cache toutes les icônes d'une case (changement de style ou de taille)
function Z.HideAuras(b)
	for _, list in ipairs({ b.hots, b.hotBars, b.debuffs }) do
		for _, element in ipairs(list) do element:Hide() end
	end
	if b.bigIcon then b.bigIcon:Hide() end
	if b.buffIcon then b.buffIcon:Hide() end
end

----------------------------------------------------------------------------------------------------
-- Tri des auras
----------------------------------------------------------------------------------------------------
-- Un de mes sorts suivis ? Si le nom est secret (en combat), on l'affiche dans le doute.
local function IsTracked(aura)
	local name = aura.name
	if issecret(name) then return true end
	return Z.trackedNames[name] or Z.db.extraTracked[name]
end

local function IsIgnored(aura)
	local id, name = aura.spellId, aura.name
	if not issecret(id) and Z.ignoredDebuffs[id] then return true end
	return not issecret(name) and Z.db.ignoredNames[name]
end

-- Affaiblissement à montrer en grand : liste personnelle, ou marqué « boss » par le jeu
local function FindImportant(harmful)
	for i = 1, #harmful do
		local aura = harmful[i]
		local name, boss = aura.name, aura.isBossAura
		if not issecret(name) and Z.db.importantNames[name] then return aura end
		if not issecret(boss) and boss then return aura end
	end
	-- En combat ces informations peuvent être secrètes : on laisse le jeu décider de la visibilité
	local first = harmful[1]
	if first and issecret(first.isBossAura) then return first, true end
end

local lastSound = 0
local function DispelSound()
	if Z.db.soundDispel and GetTime() - lastSound > 2 then
		lastSound = GetTime()
		PlaySound(3081, "Master")
	end
end

-- Buff de groupe que je sais lancer et que ce joueur n'a pas. Lisible hors combat seulement.
local function FindMissingBuff(b, unit)
	if not Z.db.missingBuffs or #Z.buffChecks == 0 or b.status or InCombatLockdown() then return end
	local list = Auras(unit, "HELPFUL", 40)
	if not list then return end
	local present = {}
	for i = 1, #list do
		local name = list[i].name
		if issecret(name) then return end
		present[name] = true
	end
	for _, check in ipairs(Z.buffChecks) do
		local found = false
		for name in pairs(check.names) do
			if present[name] then found = true break end
		end
		if not found then return check end
	end
end

----------------------------------------------------------------------------------------------------
-- Mise à jour des auras d'une case
----------------------------------------------------------------------------------------------------
local function UpdateAuras(b)
	local unit = b.unit
	local db = Z.db

	-- 1. Mes soins sur la durée et boucliers
	local shown = 0
	local bars = db.hotStyle == "BARS"
	if db.showHots and (next(Z.trackedNames) or next(db.extraTracked)) then
		local list = Auras(unit, "HELPFUL|PLAYER", 16)
		if list then
			for i = 1, #list do
				if IsTracked(list[i]) then
					shown = shown + 1
					if bars then
						ShowBar(GetBar(b, shown), unit, list[i])
					else
						ShowAura(GetIcon(b, b.hots, shown, "TOPLEFT", 2, -2, 1), unit, list[i])
					end
					if shown == MAX_HOTS then break end
				end
			end
		end
	end
	for i = (bars and 1 or shown + 1), #b.hots do b.hots[i]:Hide() end
	for i = (bars and shown + 1 or 1), #b.hotBars do b.hotBars[i]:Hide() end

	-- 2. Affaiblissement que je peux dissiper : d'abord le filtre du jeu, sinon mes propres sorts
	local harmful = Auras(unit, "HARMFUL", 8)
	local dispellable = Auras(unit, "HARMFUL|RAID_PLAYER_DISPELLABLE", 1)
	local toDispel = dispellable and dispellable[1]
	if not toDispel and harmful then
		for i = 1, #harmful do
			local kind = harmful[i].dispelName
			if kind and not issecret(kind) and Z.canDispel[kind] then
				toDispel = harmful[i]
				break
			end
		end
	end

	local color = toDispel and db.showDispel and GetDispelColor(unit, toDispel.auraInstanceID, dispelCurve)
	if color then
		local r, g, bl, a = color:GetRGBA()
		b.dispel:SetColor(r, g, bl, a)
		b.dispel.fill:SetVertexColor(r, g, bl, a)
		if not b.dispel:IsShown() then DispelSound() end
		b.dispel:Show()
	else
		b.dispel:Hide()
	end

	-- 3. Icônes d'affaiblissements : celui à dissiper en premier
	shown = 0
	if db.showDebuffs and harmful then
		local firstId = toDispel and toDispel.auraInstanceID
		if issecret(firstId) then firstId = nil end
		if toDispel then
			shown = 1
			ShowAura(GetIcon(b, b.debuffs, 1, "BOTTOMRIGHT", -2, 2, -1), unit, toDispel)
		end
		if db.debuffMode == "ALL" then
			for i = 1, #harmful do
				if shown == MAX_DEBUFFS then break end
				local aura = harmful[i]
				local id = aura.auraInstanceID
				if not (firstId and not issecret(id) and id == firstId) and not IsIgnored(aura) then
					shown = shown + 1
					ShowAura(GetIcon(b, b.debuffs, shown, "BOTTOMRIGHT", -2, 2, -1), unit, aura)
				end
			end
		end
	end
	for i = shown + 1, #b.debuffs do b.debuffs[i]:Hide() end

	-- 4. Affaiblissement important, en grand sur la gauche
	local important, gameDecides
	if db.bossDebuffs and harmful then important, gameDecides = FindImportant(harmful) end
	if important then
		b.bigList = b.bigList or {}
		b.bigIcon = GetIcon(b, b.bigList, 1, "LEFT", 3, 0, 1, 1.6)
		ShowAura(b.bigIcon, unit, important)
		if gameDecides then b.bigIcon:SetAlphaFromBoolean(important.isBossAura, 1, 0) end
	elseif b.bigIcon then
		b.bigIcon:Hide()
	end

	-- 5. Buff de groupe manquant, hors combat
	local missing = FindMissingBuff(b, unit)
	if missing then
		b.buffList = b.buffList or {}
		b.buffIcon = GetIcon(b, b.buffList, 1, "BOTTOMLEFT", 2, 2, 1)
		b.buffIcon.texture:SetTexture(missing.icon)
		b.buffIcon.texture:SetDesaturated(true)
		b.buffIcon.border:SetColor(1, 0.2, 0.2, 1)
		b.buffIcon.cooldown:Clear()
		b.buffIcon.count:SetText("")
		b.buffIcon:Show()
	elseif b.buffIcon then
		b.buffIcon:Hide()
	end
end

----------------------------------------------------------------------------------------------------
-- File d'attente : une seule mise à jour par case et par image
----------------------------------------------------------------------------------------------------
local dirty = {}
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(self)
	self:Hide()
	if not dispelCurve then BuildCurve() end
	for b in pairs(dirty) do
		dirty[b] = nil
		if b.unit and b:IsVisible() then UpdateAuras(b) end
	end
end)

function Z.QueueAuras(b)
	dirty[b] = true
	driver:Show()
end
