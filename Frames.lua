-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Frames.lua : les cases des joueurs (vie, soins entrants, bouclier, mana, nom, rôle, portée...).
-- Performance : chaque case n'écoute que les événements de SON joueur, et ne redessine que ce qui a changé.

local _, Z = ...
local UI = Z.UI
local L = Z.L
local issecret = Z.IsSecret

local UnitHealth, UnitHealthMax, UnitHealthPercent, UnitHealthMissing = UnitHealth, UnitHealthMax, UnitHealthPercent, UnitHealthMissing
local UnitIsConnected, UnitIsDeadOrGhost, UnitIsGhost, UnitInRange = UnitIsConnected, UnitIsDeadOrGhost, UnitIsGhost, UnitInRange
local UnitGetDetailedHealPrediction, UnitPower, UnitPowerMax = UnitGetDetailedHealPrediction, UnitPower, UnitPowerMax

local db
local buttons = {}   -- toutes les cases, tous cadres confondus
Z.buttons = buttons
Z.headers = {}       -- cadre principal, tanks, familiers

local MANA = 0
local SMOOTH = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
local smoothing      -- SMOOTH ou nil selon l'option
local rangeAlpha = 0.35

----------------------------------------------------------------------------------------------------
-- Courbes : le jeu calcule la couleur à partir de la vie, même quand la valeur est secrète
----------------------------------------------------------------------------------------------------
local function ColorCurve(step, points)
	local curve = C_CurveUtil.CreateColorCurve()
	curve:SetType(step and Enum.LuaCurveType.Step or Enum.LuaCurveType.Linear)
	for i = 1, #points, 5 do
		curve:AddPoint(points[i], CreateColor(points[i + 1], points[i + 2], points[i + 3], points[i + 4]))
	end
	return curve
end

local healthCurve, hideWhenFullCurve, lowHealthCurve, healCalculator

-- Taille d'une case, réduite en grand raid si l'option est cochée
local function ShrinkFactor()
	if not db.autoShrink then return 1 end
	local members = GetNumGroupMembers()
	return members > 25 and 0.7 or members > 10 and 0.85 or 1
end

function Z.CellSize()
	local factor = Z.previewFactor or ShrinkFactor()
	return math.floor(db.width * factor + 0.5), math.floor(db.height * factor + 0.5)
end

----------------------------------------------------------------------------------------------------
-- Mises à jour d'une case. « b » est la case, b.unit son joueur ("raid7", "party2", "player"...)
----------------------------------------------------------------------------------------------------
local function ClassColor(unit)
	local _, class = UnitClass(unit)
	if class then
		local color = C_ClassColor.GetClassColor(class)
		if color then return color.r, color.g, color.b end
	end
	return 0.6, 0.6, 0.6
end

local function UpdatePrediction(b)
	if not (db.showIncoming or db.showAbsorb) then return end
	local unit = b.unit
	local max = UnitHealthMax(unit)
	UnitGetDetailedHealPrediction(unit, "player", healCalculator)
	b.incoming:SetMinMaxValues(0, max)
	b.incoming:SetValue((healCalculator:GetIncomingHeals()))
	b.absorb:SetMinMaxValues(0, max)
	b.absorb:SetValue((healCalculator:GetDamageAbsorbs()))
end

-- Mort, fantôme, hors ligne : la case devient grise et affiche l'état
local function UpdateState(b)
	local unit = b.unit
	local connected = UnitIsConnected(unit)
	if issecret(connected) then connected = true end
	local dead = UnitIsDeadOrGhost(unit)
	if issecret(dead) then dead = false end
	b.dead = dead

	local status
	if not connected then
		status = L["Déco"]
	elseif dead then
		local ghost = UnitIsGhost(unit)
		status = (not issecret(ghost) and ghost) and L["Fantôme"] or L["Mort"]
	end
	b.status = status

	local r, g, bl = ClassColor(unit)
	if status then
		b.hp:SetStatusBarColor(0.25, 0.25, 0.28)
		b.name:SetTextColor(0.65, 0.65, 0.68)
		b.text:SetText(status)
		b.text:SetTextColor(0.95, 0.35, 0.35)
		b.text:SetAlpha(1)
		b.low.fill:SetAlpha(0)
	else
		b.text:SetTextColor(1, 1, 1)
		if db.color == "CLASS" then
			b.hp:SetStatusBarColor(r, g, bl)
			b.name:SetTextColor(1, 1, 1)
		else
			b.name:SetTextColor(r, g, bl)
		end
	end
end

local function UpdateHealth(b)
	local unit = b.unit
	local dead = UnitIsDeadOrGhost(unit)
	if issecret(dead) then dead = false end
	if dead ~= b.dead then UpdateState(b) end

	local hp = b.hp
	hp:SetMinMaxValues(0, UnitHealthMax(unit))
	hp:SetValue(UnitHealth(unit), smoothing)

	if not b.status then
		if db.color == "HEALTH" then
			hp:SetStatusBarColor(UnitHealthPercent(unit, true, healthCurve):GetRGB())
		end
		if db.lowHealth then
			b.low.fill:SetAlpha(UnitHealthPercent(unit, true, lowHealthCurve).a) -- visible sous le seuil seulement
		end
		if db.text == "DEFICIT" then
			b.text:SetFormattedText("-%s", AbbreviateNumbers(UnitHealthMissing(unit)))
			b.text:SetAlpha(UnitHealthPercent(unit, true, hideWhenFullCurve).a) -- invisible à 100 %
		elseif db.text == "PERCENT" and CurveConstants and CurveConstants.ScaleTo100 then
			b.text:SetFormattedText("%.0f%%", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
			b.text:SetAlpha(1)
		else
			b.text:SetText("")
		end
	end
	UpdatePrediction(b)
end

local function UpdatePower(b)
	if not b.powerShown then return end
	b.power:SetMinMaxValues(0, UnitPowerMax(b.unit, MANA))
	b.power:SetValue(UnitPower(b.unit, MANA))
end

local function UpdateName(b)
	b.name:SetText(UnitName(b.unit))
end

-- Hors de portée : la case s'estompe
local function UpdateRange(b)
	local me = UnitIsUnit(b.unit, "player")
	if not issecret(me) and me then return b:SetAlpha(1) end -- je suis toujours à portée de moi-même
	local inRange, checked = UnitInRange(b.unit)
	if issecret(inRange) then
		b:SetAlphaFromBoolean(inRange, 1, rangeAlpha)
	elseif checked and not inRange then
		b:SetAlpha(rangeAlpha)
	else
		b:SetAlpha(1)
	end
end

-- Bordure rouge : ce joueur a l'attention d'un monstre
local function UpdateThreat(b)
	local situation = db.showThreat and UnitThreatSituation(b.unit)
	b.threat:SetShown(situation and not issecret(situation) and situation >= 2 or false)
end

-- Place la barre de vie selon le thème, et la barre de mana si elle est affichée
local function LayoutBars(b)
	local inset = Z:Theme().borderSize
	b.hp:ClearAllPoints()
	b.hp:SetPoint("TOPLEFT", inset, -inset)
	b.hp:SetPoint("BOTTOMRIGHT", -inset, inset + (b.powerShown and 4 or 0))
end

-- Rôle : icône, et barre de mana pour les soigneurs (ou tous) selon l'option
local function UpdateRole(b)
	local unit = b.unit
	local role = UnitGroupRolesAssigned(unit)
	if issecret(role) then role = nil end
	if db.showRole and role == "TANK" then
		b.role:SetAtlas("roleicon-tiny-tank")
		b.role:Show()
	elseif db.showRole and role == "HEALER" then
		b.role:SetAtlas("roleicon-tiny-healer")
		b.role:Show()
	else
		b.role:Hide()
	end

	local wanted = db.manaBars == "ALL" or (db.manaBars == "HEALERS" and role == "HEALER")
	if wanted then
		local powerType = UnitPowerType(unit)
		if not issecret(powerType) and powerType ~= MANA then wanted = false end
	end
	if wanted ~= b.powerShown then
		b.powerShown = wanted
		b.power:SetShown(wanted)
		LayoutBars(b)
		if wanted then
			b:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
			b:RegisterUnitEvent("UNIT_MAXPOWER", unit)
		else
			b:UnregisterEvent("UNIT_POWER_UPDATE")
			b:UnregisterEvent("UNIT_MAXPOWER")
		end
	end
	UpdatePower(b)
end

local function UpdateMarker(b)
	local index = db.showMarker and GetRaidTargetIndex(b.unit)
	if index and not issecret(index) then
		SetRaidTargetIconTexture(b.marker, index)
		b.marker:Show()
	else
		b.marker:Hide()
	end
end

-- Icône centrale : résurrection en cours, ou réponse à l'appel
local function UpdateCenter(b)
	local unit = b.unit
	local ready = b.readyCheck and GetReadyCheckStatus(unit)
	local res = UnitHasIncomingResurrection(unit)
	if ready == "ready" then
		b.center:SetTexture(READY_CHECK_READY_TEXTURE)
	elseif ready == "notready" then
		b.center:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
	elseif ready == "waiting" then
		b.center:SetTexture(READY_CHECK_WAITING_TEXTURE)
	elseif not issecret(res) and res then
		b.center:SetTexture("Interface\\RaidFrame\\Raid-Icon-Rez")
	else
		b.center:Hide()
		return
	end
	b.center:Show()
end

-- Bordure blanche : c'est ma cible
local function UpdateTarget(b)
	b.selected:SetAlphaFromBoolean(UnitIsUnit(b.unit, "target"), 1, 0)
end

local function UpdateAll(b)
	if not b.unit or not UnitExists(b.unit) then return end
	UpdateName(b)
	UpdateState(b)
	UpdateHealth(b)
	UpdateRange(b)
	UpdateThreat(b)
	UpdateRole(b)
	UpdateMarker(b)
	UpdateCenter(b)
	UpdateTarget(b)
	Z.QueueAuras(b)
end

----------------------------------------------------------------------------------------------------
-- Événements d'une case
----------------------------------------------------------------------------------------------------
local unitEvents = {
	UNIT_HEALTH = UpdateHealth,
	UNIT_MAXHEALTH = UpdateHealth,
	UNIT_HEAL_PREDICTION = UpdatePrediction,
	UNIT_ABSORB_AMOUNT_CHANGED = UpdatePrediction,
	UNIT_AURA = function(b) Z.QueueAuras(b) end,
	UNIT_CONNECTION = UpdateAll,
	UNIT_NAME_UPDATE = UpdateName,
	UNIT_FLAGS = UpdateState,
	UNIT_THREAT_SITUATION_UPDATE = UpdateThreat,
	INCOMING_RESURRECT_CHANGED = UpdateCenter,
}
local powerEvents = { UNIT_POWER_UPDATE = UpdatePower, UNIT_MAXPOWER = UpdatePower }

-- On retire de la liste les événements que ce client ne connaît pas
do
	local probe = CreateFrame("Frame")
	for event in pairs(unitEvents) do
		if not pcall(probe.RegisterEvent, probe, event) then unitEvents[event] = nil end
	end
	probe:UnregisterAllEvents()
end

local function OnEvent(b, event)
	if b.unit then (unitEvents[event] or powerEvents[event])(b) end
end

-- L'en-tête sécurisé du jeu attribue un joueur à la case en changeant son attribut « unit »
local function OnAttributeChanged(b, name, value)
	if name ~= "unit" or b.unit == value then return end
	b.unit = value
	b:UnregisterAllEvents()
	if b.powerShown then
		b.powerShown = false
		b.power:Hide()
		LayoutBars(b)
	end
	if value then
		for event in pairs(unitEvents) do b:RegisterUnitEvent(event, value) end
		if b:IsVisible() then UpdateAll(b) end
	end
end

local function OnEnter(b)
	b.hover:Show()
	if db.showTooltip and b.unit and not InCombatLockdown() then
		GameTooltip_SetDefaultAnchor(GameTooltip, b)
		GameTooltip:SetUnit(b.unit)
		GameTooltip:Show()
	end
end

local function OnLeave(b)
	b.hover:Hide()
	GameTooltip:Hide()
end

----------------------------------------------------------------------------------------------------
-- Apparence d'une case (appelé à la création et quand une option change)
----------------------------------------------------------------------------------------------------
local function Style(b)
	local theme = Z:Theme()
	local texture = UI.BarTexture()
	local width, height = Z.CellSize()
	LayoutBars(b)
	b.hp:SetStatusBarTexture(texture)
	b.incoming:SetStatusBarTexture(texture)
	b.incoming:SetStatusBarColor(unpack(theme.incoming))
	b.incoming:SetWidth(width - 2 * theme.borderSize)
	b.incoming:SetShown(db.showIncoming)
	b.absorb:SetStatusBarTexture(UI.WHITE)
	b.absorb:SetStatusBarColor(unpack(theme.absorb))
	b.absorb:SetShown(db.showAbsorb)
	b.power:SetStatusBarTexture(texture)
	b.bg:SetVertexColor(unpack(theme.bg))
	b.border:SetThickness(theme.borderSize)
	b.border:SetColor(theme.border[1], theme.border[2], theme.border[3], 1)
	b.shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, theme.shade[1]), CreateColor(1, 1, 1, theme.shade[2]))
	b.dim:SetAlpha(1 - db.brightness / 100)
	b.low:SetShown(db.lowHealth)
	if not db.lowHealth then b.low.fill:SetAlpha(0) end

	local size = db.fontSize + (theme.fontBonus or 0)
	b.name:SetFont(theme.font, size, theme.flags)
	b.text:SetFont(theme.font, size - 1, theme.flags)
	b.name:SetWidth(width - 8)

	local icon = math.floor(height * 0.30 + 0.5)
	b.iconSize = icon
	b.role:SetSize(icon - 2, icon - 2)
	b.marker:SetSize(icon, icon)
	b.center:SetSize(icon + 8, icon + 8)
	Z.HideAuras(b)
	if b.RegisterForClicks then b:RegisterForClicks(db.castOnDown and "AnyDown" or "AnyUp") end
end
Z.StyleButton = Style

----------------------------------------------------------------------------------------------------
-- Habillage d'une case : barres, textes, icônes, bordures. Sert aussi aux fausses cases du mode test.
----------------------------------------------------------------------------------------------------
function Z.BuildVisuals(b)
	b.bg = UI.Tex(b, "BACKGROUND", 0.07, 0.07, 0.09, 1)
	b.bg:SetAllPoints()

	-- Vie
	local hp = CreateFrame("StatusBar", nil, b)
	hp:SetClipsChildren(true)
	b.hp = hp

	-- Soins en route (les miens et ceux des autres), à la suite de la vie
	local incoming = CreateFrame("StatusBar", nil, hp)
	incoming:SetPoint("TOPLEFT", hp:GetStatusBarTexture(), "TOPRIGHT")
	incoming:SetPoint("BOTTOMLEFT", hp:GetStatusBarTexture(), "BOTTOMRIGHT")
	b.incoming = incoming

	-- Bouclier d'absorption : bande en bas de la barre de vie
	local absorb = CreateFrame("StatusBar", nil, hp)
	absorb:SetPoint("BOTTOMLEFT")
	absorb:SetPoint("BOTTOMRIGHT")
	absorb:SetHeight(3)
	b.absorb = absorb

	-- Mana (soigneurs ou tous, selon l'option) : sous la barre de vie
	local power = CreateFrame("StatusBar", nil, b)
	power:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, -1)
	power:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, -1)
	power:SetHeight(3)
	power:SetStatusBarColor(0.25, 0.50, 1)
	power:Hide()
	b.power = power
	b.powerShown = false

	-- Tout ce qui se pose par-dessus les barres
	local over = CreateFrame("Frame", nil, b)
	over:SetAllPoints()
	over:SetFrameLevel(hp:GetFrameLevel() + 3)
	b.over = over

	b.dim = UI.Tex(over, "BACKGROUND", 0, 0, 0, 1) -- voile sombre : réglage de luminosité
	b.dim:SetAllPoints(hp)
	b.shade = over:CreateTexture(nil, "BACKGROUND", nil, 1) -- léger dégradé pour le relief
	b.shade:SetTexture(UI.WHITE)
	b.shade:SetAllPoints(hp)

	b.hover = UI.Tex(over, "BORDER", 1, 1, 1, 0.10)
	b.hover:SetAllPoints()
	b.hover:Hide()

	-- Vie basse : voile rouge qui pulse (son opacité est calculée par le jeu à partir de la vie)
	local low = CreateFrame("Frame", nil, over)
	low:SetAllPoints()
	low.fill = UI.Tex(low, "ARTWORK", 1, 0.05, 0.05, 0.45)
	low.fill:SetAllPoints()
	low.fill:SetAlpha(0)
	low.pulse = low:CreateAnimationGroup()
	low.pulse:SetLooping("BOUNCE")
	local fade = low.pulse:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0.2)
	fade:SetDuration(0.45)
	low:SetScript("OnShow", function(self) self.pulse:Play() end)
	low:Hide()
	b.low = low

	b.name = UI.Text(over, 11)
	b.name:SetPoint("CENTER", 0, 3)
	b.name:SetWordWrap(false)

	b.text = UI.Text(over, 10)
	b.text:SetPoint("BOTTOM", 0, 5)

	b.role = over:CreateTexture(nil, "ARTWORK")
	b.role:SetPoint("TOPRIGHT", -2, -2)

	b.marker = over:CreateTexture(nil, "ARTWORK")
	b.marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	b.marker:SetPoint("CENTER", over, "TOP", 0, -1)
	b.marker:Hide()

	b.center = over:CreateTexture(nil, "OVERLAY")
	b.center:SetPoint("CENTER")
	b.center:Hide()

	-- Bordures : thème (toujours), rouge (menace), couleur du type (dissipation possible), blanche (ma cible)
	b.border = UI.Border(over, 1)
	b.threat = UI.Border(over, 1, 1)
	b.threat:SetColor(1, 0.15, 0.15, 1)
	b.threat:Hide()
	b.dispel = UI.Border(over, 2)
	b.dispel.fill = UI.Tex(b.dispel, "ARTWORK", 1, 1, 1, 0.30)
	b.dispel.fill:SetAllPoints()
	b.dispel:Hide()
	b.selected = UI.Border(over, 1)
	b.selected:SetColor(1, 1, 1, 1)
	b.selected:SetAlpha(0)

	b.hots, b.hotBars, b.debuffs = {}, {}, {}
end

-- Création d'une case : le jeu crée le bouton sécurisé, Lyorune l'habille.
local function InitButton(_, name)
	local b = _G[name]
	if not b or b.hp then return end
	buttons[#buttons + 1] = b
	Z.BuildVisuals(b)

	b:SetScript("OnEvent", OnEvent)
	b:HookScript("OnAttributeChanged", OnAttributeChanged)
	b:HookScript("OnShow", UpdateAll)
	b:HookScript("OnEnter", OnEnter)
	b:HookScript("OnLeave", OnLeave)

	Style(b)
	Z:RegisterExternalClicks(b)
	OnAttributeChanged(b, "unit", b:GetAttribute("unit"))
end

----------------------------------------------------------------------------------------------------
-- Les cadres. Chacun a une poignée de déplacement et un en-tête sécurisé du jeu, qui crée et range
-- une case par joueur, même en plein combat (aucun calcul de placement côté addon).
----------------------------------------------------------------------------------------------------
local frameDefs = {
	{ key = "main", name = "LyoruneHeader", template = "SecureGroupHeaderTemplate", pos = "pos", label = "Lyorune" },
	{ key = "tanks", name = "LyoruneTanks", template = "SecureGroupHeaderTemplate", pos = "tankPos", label = "Tanks", option = "showTanks" },
	{ key = "pets", name = "LyorunePets", template = "SecureGroupPetHeaderTemplate", pos = "petPos", label = "Familiers", option = "showPets" },
}

local CONFIG_SNIPPET = [[
	local header = self:GetParent()
	self:SetWidth(header:GetAttribute("z-width"))
	self:SetHeight(header:GetAttribute("z-height"))
	self:SetAttribute("*type1", "target")
	self:SetAttribute("*type2", "togglemenu")
	self:SetAttribute("toggleForVehicle", true)
	for i = 1, header:GetAttribute("z-count") or 0 do
		self:SetAttribute(header:GetAttribute("z-key" .. i), header:GetAttribute("z-value" .. i))
	end
	self:SetAttribute("_onenter", header:GetAttribute("z-onenter"))
	self:SetAttribute("_onleave", "self:ClearBindings()")
	header:CallMethod("InitButton", self:GetName())
]]

local function CreateAnchor(def)
	local anchor = CreateFrame("Frame", def.name .. "Anchor", UIParent)
	anchor:SetSize(86, 16)
	anchor:SetMovable(true)
	anchor:SetClampedToScreen(true)
	anchor:RegisterForDrag("LeftButton")
	anchor.bg = UI.Tex(anchor, "BACKGROUND", UI.bg[1], UI.bg[2], UI.bg[3], 0.9)
	anchor.bg:SetAllPoints()
	anchor.line = UI.Tex(anchor, "ARTWORK", UI.accent[1], UI.accent[2], UI.accent[3])
	anchor.line:SetPoint("BOTTOMLEFT")
	anchor.line:SetPoint("BOTTOMRIGHT")
	anchor.line:SetHeight(1)
	anchor.label = UI.Text(anchor, 10)
	anchor.label:SetPoint("CENTER", 0, 1)
	anchor.label:SetText(L[def.label])
	anchor:SetScript("OnDragStart", function(self)
		if InCombatLockdown() then
			Z:Print(L["impossible de déplacer les cadres en combat."])
		else
			self:StartMoving()
		end
	end)
	anchor:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, _, x, y = self:GetPoint(1)
		db[def.pos] = { point, x, y }
	end)
	anchor:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then Z:ToggleOptions() end
	end)
	anchor:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L[def.label], UI.accent[1], UI.accent[2], UI.accent[3])
		GameTooltip:AddLine(L["Glisser : déplacer les cadres"], 1, 1, 1)
		GameTooltip:AddLine(L["Clic droit : options"], 1, 1, 1)
		GameTooltip:Show()
	end)
	anchor:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return anchor
end

local function CreateHeader(def)
	local h = CreateFrame("Frame", def.name, UIParent, def.template)
	h:Hide() -- on règle tout avant d'afficher : les cases sont créées au premier affichage
	h.def = def
	h.anchor = CreateAnchor(def)
	h.InitButton = InitButton
	h:SetPoint("TOPLEFT", h.anchor, "BOTTOMLEFT", 0, -3)
	h:SetAttribute("template", "SecureUnitButtonTemplate,SecureHandlerEnterLeaveTemplate")
	h:SetAttribute("showPlayer", true)
	h:SetAttribute("showParty", true)
	h:SetAttribute("showRaid", true)
	h:SetAttribute("sortMethod", "INDEX")
	h:SetAttribute("initialConfigFunction", CONFIG_SNIPPET)
	if def.key == "tanks" then h:SetAttribute("roleFilter", "TANK") end
	Z.headers[#Z.headers + 1] = h
	return h
end

local function ApplyLayout()
	local width, height = Z.CellSize()
	for _, b in ipairs(buttons) do
		b:ClearAllPoints()
		b:SetSize(width, height)
	end

	for _, h in ipairs(Z.headers) do
		local def = h.def
		h:SetAttribute("z-width", width)
		h:SetAttribute("z-height", height)
		if def.key == "main" then
			if db.layout == "ROLE" then
				h:SetAttribute("groupBy", "ASSIGNEDROLE")
				h:SetAttribute("groupingOrder", db.roleOrder .. ",NONE")
			else
				h:SetAttribute("groupBy", "GROUP")
				h:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
			end
			h:SetAttribute("showSolo", db.showSolo)
		end
		if db.horizontal then
			h:SetAttribute("point", "LEFT")
			h:SetAttribute("xOffset", db.spacing)
			h:SetAttribute("yOffset", 0)
			h:SetAttribute("columnAnchorPoint", "TOP")
		else
			h:SetAttribute("point", "TOP")
			h:SetAttribute("xOffset", 0)
			h:SetAttribute("yOffset", -db.spacing)
			h:SetAttribute("columnAnchorPoint", "LEFT")
		end
		h:SetAttribute("columnSpacing", db.spacing)
		h:SetAttribute("unitsPerColumn", 5)
		h:SetAttribute("maxColumns", 8)

		local enabled = (not def.option or db[def.option]) and not Z.previewActive
		h:SetShown(enabled)
		h:SetAlpha(db.frameAlpha / 100)

		local pos = db[def.pos]
		h.anchor:ClearAllPoints()
		h.anchor:SetPoint(pos[1], UIParent, pos[1], pos[2], pos[3])
		local handle = (not def.option or db[def.option]) and not db.locked
		h.anchor:SetAlpha(handle and 1 or 0)
		h.anchor:EnableMouse(handle)
	end
end

-- Masque les cadres de groupe du jeu (option, expérimental). Un /reload les rétablit une fois l'option décochée.
local blizzardHidden
local function HideBlizzardFrames()
	if blizzardHidden or not db.hideBlizzard or InCombatLockdown() then return end
	blizzardHidden = CreateFrame("Frame")
	blizzardHidden:Hide()
	for _, name in ipairs({ "CompactRaidFrameManager", "CompactRaidFrameContainer", "CompactPartyFrame", "PartyFrame" }) do
		local frame = _G[name]
		if frame then
			frame:UnregisterAllEvents()
			frame:SetParent(blizzardHidden)
		end
	end
end

local function BuildCurves()
	healthCurve = healthCurve or ColorCurve(false, {
		0.0, 0.90, 0.15, 0.15, 1,
		0.5, 0.95, 0.80, 0.20, 1,
		1.0, 0.25, 0.80, 0.35, 1,
	})
	hideWhenFullCurve = hideWhenFullCurve or ColorCurve(true, {
		0.0, 1, 1, 1, 1,
		1.0, 1, 1, 1, 0,
	})
	lowHealthCurve = ColorCurve(true, {
		0.0, 1, 1, 1, 1,
		db.lowHealthAt / 100, 1, 1, 1, 0,
	})
end

-- Appelé après chaque changement d'option
function Z:Refresh()
	smoothing = db.smooth and SMOOTH or nil
	rangeAlpha = db.rangeAlpha / 100
	BuildCurves()
	Z:Safe("layout", ApplyLayout)
	Z:Safe("blizzard", HideBlizzardFrames)
	for _, b in ipairs(buttons) do
		Style(b)
		if b:IsVisible() then UpdateAll(b) end
	end
	if Z.RefreshPreview then Z:RefreshPreview() end
	if Z.RefreshMinimap then Z:RefreshMinimap() end
	if Z.RefreshRunes then Z:RefreshRunes() end
end

function Z:CreateFrames()
	db = Z.db
	smoothing = db.smooth and SMOOTH or nil
	rangeAlpha = db.rangeAlpha / 100
	BuildCurves()

	healCalculator = CreateUnitHealPredictionCalculator()
	if healCalculator.SetIncomingHealClampMode and Enum.UnitIncomingHealClampMode then
		healCalculator:SetIncomingHealClampMode(Enum.UnitIncomingHealClampMode.MissingHealth)
	end
	if healCalculator.SetDamageAbsorbClampMode and Enum.UnitDamageAbsorbClampMode then
		healCalculator:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MaximumHealth)
	end

	for _, def in ipairs(frameDefs) do CreateHeader(def) end
	Z.header = Z.headers[1]
	Z.anchor = Z.header.anchor
	ApplyLayout()
	HideBlizzardFrames()

	-- Événements communs à toutes les cases
	local function ForVisible(fn)
		return function()
			for _, b in ipairs(buttons) do
				if b.unit and b:IsVisible() then fn(b) end
			end
		end
	end
	local updateAll = ForVisible(UpdateAll)
	local lastFactor = ShrinkFactor()
	Z:On("GROUP_ROSTER_UPDATE", function()
		local factor = ShrinkFactor()
		if factor ~= lastFactor then -- le raid a changé de taille : on adapte les cases (option)
			lastFactor = factor
			Z:Refresh()
		else
			updateAll()
		end
	end)
	Z:On("PLAYER_ENTERING_WORLD", updateAll)
	Z:On("PLAYER_ROLES_ASSIGNED", ForVisible(UpdateRole))
	Z:On("PLAYER_TARGET_CHANGED", ForVisible(UpdateTarget))
	Z:On("RAID_TARGET_UPDATE", ForVisible(UpdateMarker))
	-- Entrée et sortie de combat : les buffs manquants ne se lisent que hors combat
	Z:On("PLAYER_REGEN_ENABLED", ForVisible(Z.QueueAuras))
	Z:On("PLAYER_REGEN_DISABLED", ForVisible(Z.QueueAuras))

	local function ReadyCheck(active)
		return function()
			for _, b in ipairs(buttons) do
				b.readyCheck = active
				if b.unit and b:IsVisible() then UpdateCenter(b) end
			end
		end
	end
	Z:On("READY_CHECK", ReadyCheck(true))
	Z:On("READY_CHECK_CONFIRM", ReadyCheck(true))
	Z:On("READY_CHECK_FINISHED", function() C_Timer.After(5, ReadyCheck(false)) end)

	-- Portée : le seul contrôle périodique de l'addon (2 fois par seconde, coût négligeable)
	C_Timer.NewTicker(0.5, ForVisible(UpdateRange))
end
