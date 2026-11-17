-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Cast.lua : temps de recharge global et incantation en cours (réglage « castIndicator »).
-- Au choix : une fine barre sous les cadres, ou un anneau autour du curseur. Rien n'est créé tant que le réglage
-- reste sur « Aucun ». Pas de boucle permanente : les événements de mes sorts allument l'indicateur, il suit le
-- temps (et le curseur pour l'anneau) seulement pendant qu'il est affiché, une seconde et demie le plus souvent.
-- Incantation : couleur d'accent ; temps de recharge global seul : blanc doux.
-- Le jeu donne le temps de recharge global par le sort 61304. En combat, si une valeur est secrète, l'objet
-- « durée » du jeu est confié tel quel à la barre ou à l'anneau (ils savent l'afficher sans calcul de Lyorune).

local _, Z = ...
local UI = Z.UI
local issecret = Z.IsSecret

local GCD_SPELL = 61304
local RING = "Interface\\AddOns\\Lyorune\\Media\\Anneau"
local BAR_HEIGHT, RING_SIZE = 4, 40
local GCD_COLOR = { 0.9, 0.92, 0.95 }

local events, bar, ring
local casting = false   -- une incantation (ou canalisation) est en cours
local token = 0         -- change à chaque affichage : un ancien minuteur ne cache pas le nouvel affichage
local startAt, endAt    -- temps du jeu, quand ils sont lisibles (sinon l'objet « durée » fait le travail)

local function Mode()
	return Z.db and Z.db.castIndicator or "OFF"
end

----------------------------------------------------------------------------------------------------
-- La barre : sous les cadres de groupe, de leur largeur
----------------------------------------------------------------------------------------------------
local function BarUpdate(self)
	if startAt then self:SetValue(math.min(GetTime(), endAt)) end
end

local function BuildBar()
	bar = CreateFrame("StatusBar", "LyoruneCastBar", UIParent)
	bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	bar:SetFrameStrata("MEDIUM")
	bar.bg = UI.Tex(bar, "BACKGROUND", 0, 0, 0, 0.55)
	bar.bg:SetPoint("TOPLEFT", -1, 1)
	bar.bg:SetPoint("BOTTOMRIGHT", 1, -1)
	bar:Hide()
end

-- Bas, gauche et droite des cadres de groupe affichés (cadre principal et cadres de raid)
local function PlaceBar()
	local uiScale = UIParent:GetEffectiveScale()
	local left, right, bottom
	for _, h in ipairs(Z.headers or {}) do
		if h.def and h.def.pos == "pos" and h:IsVisible() then
			local l, r, b = h:GetLeft(), h:GetRight(), h:GetBottom()
			if l and r and b and not issecret(l) and r > l then
				local ratio = h:GetEffectiveScale() / uiScale
				l, r, b = l * ratio, r * ratio, b * ratio
				left = left and math.min(left, l) or l
				right = right and math.max(right, r) or r
				bottom = bottom and math.min(bottom, b) or b
			end
		end
	end
	bar:ClearAllPoints()
	if left then
		bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, bottom - 3)
		bar:SetSize(right - left, BAR_HEIGHT)
	else -- aucun cadre visible : sous la place des cadres
		bar:SetPoint("TOPLEFT", Z.anchor or UIParent, "BOTTOMLEFT", 0, -3)
		bar:SetSize(Z.CellSize and Z.CellSize() or 86, BAR_HEIGHT)
	end
end

----------------------------------------------------------------------------------------------------
-- L'anneau : autour du curseur, il se vide à mesure que le temps passe
----------------------------------------------------------------------------------------------------
local function FollowCursor(self)
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	self:ClearAllPoints()
	self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

local function BuildRing()
	ring = CreateFrame("Frame", "LyoruneCastRing", UIParent)
	ring:SetSize(RING_SIZE, RING_SIZE)
	ring:SetFrameStrata("TOOLTIP")
	ring:EnableMouse(false)
	ring.bg = ring:CreateTexture(nil, "BACKGROUND")
	ring.bg:SetAllPoints()
	ring.bg:SetTexture(RING)
	ring.bg:SetVertexColor(0, 0, 0, 0.45)
	ring.swipe = CreateFrame("Cooldown", nil, ring)
	ring.swipe:SetAllPoints()
	ring.swipe:SetSwipeTexture(RING)
	ring.swipe:SetDrawEdge(false)
	ring.swipe:SetDrawBling(false)
	ring.swipe:SetHideCountdownNumbers(true)
	ring.swipe:SetReverse(true)
	ring:SetScript("OnUpdate", FollowCursor)
	ring:Hide()
end

----------------------------------------------------------------------------------------------------
-- Affichage
----------------------------------------------------------------------------------------------------
local function HideAll()
	token = token + 1
	startAt, endAt = nil, nil
	if bar then bar:Hide() end
	if ring then ring:Hide() end
end

-- Affiche une durée : start et finish en secondes du jeu (lisibles), ou duration, l'objet « durée » du jeu
local function Display(start, finish, duration, color)
	local mode = Mode()
	if mode == "OFF" then return HideAll() end
	token = token + 1
	local readable = start and finish and not issecret(start) and not issecret(finish) and finish > start
	startAt, endAt = nil, nil
	if readable then startAt, endAt = start, finish end
	if not readable and not duration then return HideAll() end
	if mode == "BAR" then
		if not bar then BuildBar() end
		if ring then ring:Hide() end
		PlaceBar()
		bar:SetStatusBarColor(color[1], color[2], color[3], 1)
		if readable then
			bar:SetScript("OnUpdate", BarUpdate)
			bar:SetMinMaxValues(start, finish)
			bar:SetValue(GetTime())
		elseif bar.SetTimerDuration and Enum.StatusBarInterpolation and Enum.StatusBarTimerDirection then
			bar:SetScript("OnUpdate", nil)
			bar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.ElapsedTime)
		else
			return HideAll()
		end
		bar:Show()
	else
		if not ring then BuildRing() end
		if bar then bar:Hide() end
		ring.swipe:SetSwipeColor(color[1], color[2], color[3], 0.95)
		if readable then
			ring.swipe:SetCooldown(start, finish - start)
		elseif ring.swipe.SetCooldownFromDurationObject then
			ring.swipe:SetCooldownFromDurationObject(duration)
		else
			return HideAll()
		end
		FollowCursor(ring)
		ring:Show()
	end
	return token
end

-- Cache l'indicateur après « seconds », sauf si un autre affichage l'a remplacé entre-temps
local function HideAfter(mine, seconds)
	if not mine then return end
	C_Timer.After(seconds + 0.03, function()
		if token == mine and not casting then HideAll() end
	end)
end

-- Temps de recharge global, s'il court (une incantation reste prioritaire : elle dure plus longtemps)
local function ShowGCD()
	if casting then return end
	local info = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(GCD_SPELL)
	if not info then return end
	local start, length = info.startTime, info.duration
	if not issecret(start) and not issecret(length) then
		if not length or length <= 0 then return end
		HideAfter(Display(start, start + length, nil, GCD_COLOR), start + length - GetTime())
	elseif C_Spell.GetSpellCooldownDuration then
		HideAfter(Display(nil, nil, C_Spell.GetSpellCooldownDuration(GCD_SPELL), GCD_COLOR), 1.5)
	end
end

-- Incantation ou canalisation en cours
local function ShowCast(channel)
	local _, startMS, endMS
	local info = channel and UnitChannelInfo or UnitCastingInfo
	if info then _, _, _, startMS, endMS = info("player") end
	local duration
	if not startMS or issecret(startMS) or issecret(endMS) then
		local getter = channel and UnitChannelDuration or UnitCastingDuration
		duration = getter and getter("player")
		startMS, endMS = nil, nil
		if not duration then return end
	end
	casting = true
	local start, finish = startMS and startMS / 1000, endMS and endMS / 1000
	local mine = Display(start, finish, duration, UI.accent)
	if not mine then casting = false end
end

local function CastEnded()
	casting = false
	HideAll()
	ShowGCD()
end

local handlers = {
	UNIT_SPELLCAST_START = function() ShowCast(false) end,
	UNIT_SPELLCAST_DELAYED = function() ShowCast(false) end,
	UNIT_SPELLCAST_CHANNEL_START = function() ShowCast(true) end,
	UNIT_SPELLCAST_CHANNEL_UPDATE = function() ShowCast(true) end,
	UNIT_SPELLCAST_STOP = CastEnded,
	UNIT_SPELLCAST_CHANNEL_STOP = CastEnded,
	UNIT_SPELLCAST_FAILED = CastEnded,
	UNIT_SPELLCAST_INTERRUPTED = CastEnded,
	UNIT_SPELLCAST_SUCCEEDED = function() if not casting then ShowGCD() end end,
}

-- Réglage changé : on n'écoute mes sorts que si l'indicateur est voulu
function Z:RefreshCastIndicator()
	local mode = Mode()
	if mode == "OFF" then
		if events then events:UnregisterAllEvents() end
		casting = false
		HideAll()
		return
	end
	if not events then
		events = CreateFrame("Frame")
		events:SetScript("OnEvent", function(_, event)
			Z:Try("temps de recharge global", handlers[event])
		end)
	end
	for event in pairs(handlers) do
		pcall(events.RegisterUnitEvent, events, event, "player")
	end
	if (mode == "BAR" and ring and ring:IsShown()) or (mode == "RING" and bar and bar:IsShown()) then HideAll() end
end

function Z:CastIndicator()
	return bar, ring
end

Z:On("PLAYER_LOGIN", function() Z:RefreshCastIndicator() end)
