-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Mana.lua : ma mana, vue sans la lire.
--   1. Liseré de mana basse (réglage « manaEdge ») : un liseré bleu doux au bord de l'écran, de plus en plus net
--      à mesure que ma mana descend sous le seuil choisi.
--   2. Règle des 5 secondes (réglage « fiveSecondRule ») : après un sort qui coûte de la mana, le jeu coupe ma
--      régénération pendant 5 secondes. Un trait fin sur ma propre case se vide pendant ce temps : quand il a
--      disparu, ma mana remonte de nouveau.
-- Sur WoW Forever, ma mana est secrète, même hors combat : aucune comparaison possible. Le jeu calcule lui-même
-- l'opacité du liseré à partir d'une courbe (UnitPowerPercent), Lyorune la passe telle quelle à SetAlpha.
-- Le liseré est un cadre de Lyorune posé sur l'écran, jamais cliquable, sous toutes les fenêtres du jeu.
-- Rien ne tourne en boucle : le jeu signale chaque changement de ma mana.

local _, Z = ...
local issecret = Z.IsSecret

local MANA = 0               -- type de ressource « mana »
local EDGE_SIZE = 42         -- épaisseur du liseré, en points de l'écran
local EDGE_ALPHA = 0.5       -- opacité du liseré au plus fort (mana vide)
local EDGE_COLOR = { 0.35, 0.62, 1 } -- bleu doux

local edge, edgeCurve, edgeEvents

-- Ma classe a-t-elle de la mana ? (Z.classPower, Data.lua : les classes à rage, énergie...). Un druide en forme
-- d'ours ou de félin garde sa mana : le liseré la suit.
local function HasMana()
	return Z.class ~= nil and not (Z.classPower and Z.classPower[Z.class])
end

local function Threshold()
	return tonumber(Z.db and Z.db.manaEdge) or 0
end

-- Quatre bandes en dégradé, du bord de l'écran (opaque) vers l'intérieur (transparent). Couleur unie de
-- Lyorune : aucune image du jeu.
local function BuildEdge()
	edge = CreateFrame("Frame", "LyoruneManaEdge", UIParent)
	edge:SetAllPoints(UIParent)
	edge:SetFrameStrata("BACKGROUND")
	edge:EnableMouse(false)
	local r, g, b = EDGE_COLOR[1], EDGE_COLOR[2], EDGE_COLOR[3]
	local full, none = CreateColor(r, g, b, EDGE_ALPHA), CreateColor(r, g, b, 0)
	local function Band(point1, point2, orientation, from, to, w, h)
		local t = edge:CreateTexture(nil, "BACKGROUND")
		t:SetColorTexture(1, 1, 1, 1)
		t:SetPoint(point1)
		t:SetPoint(point2)
		if w then t:SetWidth(w) else t:SetHeight(h) end
		t:SetGradient(orientation, from, to)
		return t
	end
	-- « VERTICAL » : la première couleur en bas ; « HORIZONTAL » : la première à gauche
	edge.top = Band("TOPLEFT", "TOPRIGHT", "VERTICAL", none, full, nil, EDGE_SIZE)
	edge.bottom = Band("BOTTOMLEFT", "BOTTOMRIGHT", "VERTICAL", full, none, nil, EDGE_SIZE)
	edge.left = Band("TOPLEFT", "BOTTOMLEFT", "HORIZONTAL", full, none, EDGE_SIZE)
	edge.right = Band("TOPRIGHT", "BOTTOMRIGHT", "HORIZONTAL", none, full, EDGE_SIZE)
	edge:SetAlpha(0)
	edge:Hide()
end

-- Opacité : 1 à mana vide, 0 au seuil et au-dessus (courbe linéaire, calculée par le jeu)
local function BuildCurve()
	if not (C_CurveUtil and C_CurveUtil.CreateColorCurve) then return nil end
	local curve = C_CurveUtil.CreateColorCurve()
	curve:SetType(Enum.LuaCurveType.Linear)
	curve:AddPoint(0, CreateColor(1, 1, 1, 1))
	curve:AddPoint(Threshold() / 100, CreateColor(1, 1, 1, 0))
	curve:AddPoint(1, CreateColor(1, 1, 1, 0))
	return curve
end

local function UpdateEdge()
	if not edge or not edge:IsShown() or not edgeCurve then return end
	local dead = UnitIsDeadOrGhost("player")
	if not issecret(dead) and dead then
		edge:SetAlpha(0)
		return
	end
	local ok, color = pcall(UnitPowerPercent, "player", MANA, false, edgeCurve)
	edge:SetAlpha(ok and color and color.a or 0)
end

local EDGE_EVENTS = { "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER" }

-- Réglage changé : le liseré n'existe et n'écoute ma mana que s'il est voulu
function Z:RefreshManaEdge()
	local wanted = Threshold() > 0 and HasMana() and UnitPowerPercent ~= nil
	if not wanted then
		if edgeEvents then edgeEvents:UnregisterAllEvents() end
		if edge then edge:Hide() end
		return
	end
	if not edge then BuildEdge() end
	edgeCurve = BuildCurve()
	if not edgeEvents then
		edgeEvents = CreateFrame("Frame")
		edgeEvents:SetScript("OnEvent", function() Z:Try("liseré de mana", UpdateEdge) end)
	end
	for _, event in ipairs(EDGE_EVENTS) do pcall(edgeEvents.RegisterUnitEvent, edgeEvents, event, "player") end
	for _, event in ipairs({ "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_ENTERING_WORLD" }) do
		edgeEvents:RegisterEvent(event)
	end
	edge:Show()
	UpdateEdge()
end

-- Pour les tests et /lyorune diag
function Z:ManaEdge()
	return edge
end

----------------------------------------------------------------------------------------------------
-- 2. Règle des 5 secondes. Le numéro de mes sorts reste lisible en combat (vu en jeu le 21 novembre 2026) ;
-- s'il ne l'était pas, le sort est compté comme payé en mana : le trait part, il ne manque jamais.
-- Le trait se vide par une animation du jeu (échelle de 1 à 0 depuis la gauche) : aucune boucle de Lyorune.
----------------------------------------------------------------------------------------------------
local RULE_SECONDS = 5
local RULE_COLOR = { 0.78, 0.9, 1, 0.95 }
local RULE_HEIGHT = 2
local ruleEvents

-- Ce sort a-t-il coûté de la mana ? (baguette, objet, sort sans coût : non)
-- Seul un numéro ou un coût caché par le jeu compte comme payé (le trait ne manque jamais un soin en combat).
-- Un coût que le jeu ne donne pas (pêche, métiers, objets) compte comme gratuit : aucun trait (1.29.1).
local function PaidMana(spellID)
	if issecret(spellID) then return true end
	if not spellID then return false end
	local ok, costs = pcall(C_Spell.GetSpellPowerCost, spellID)
	if ok and issecret(costs) then return true end
	if not ok or type(costs) ~= "table" then return false end
	for _, cost in ipairs(costs) do
		if issecret(cost.type) or issecret(cost.cost) then return true end
		if cost.type == MANA and (cost.cost or 0) > 0 then return true end
	end
	return false
end

-- Le trait d'une case : juste au-dessus de la barre de mana si elle est montrée, sinon au bas de la vie
local function RuleLine(b)
	local line = b.fiveLine
	if not line then
		line = b.over:CreateTexture(nil, "OVERLAY", nil, 6)
		line:SetColorTexture(RULE_COLOR[1], RULE_COLOR[2], RULE_COLOR[3], RULE_COLOR[4])
		line:Hide()
		local group = line:CreateAnimationGroup()
		local drain = group:CreateAnimation("Scale")
		if drain.SetScaleFrom then
			drain:SetScaleFrom(1, 1)
			drain:SetScaleTo(0.001, 1)
		end
		if drain.SetOrigin then drain:SetOrigin("LEFT", 0, 0) end
		drain:SetDuration(RULE_SECONDS)
		group:SetScript("OnFinished", function() line:Hide() end)
		line.drain = group
		b.fiveLine = line
	end
	local bar = b.powerShown and b.power or b.hp
	line:ClearAllPoints()
	if b.powerShown then
		-- Juste au-dessus de la barre de mana, collé à elle, sans la recouvrir (demande de l'auteur, 1.29.1)
		line:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 0)
		line:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 0)
	else
		line:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
		line:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
	end
	line:SetHeight(RULE_HEIGHT)
	return line
end

-- Mes cases (le cadre principal, et un cadre épinglé s'il me montre aussi)
local function StartRule()
	for _, b in ipairs(Z.buttons or {}) do
		if b.unit and b.over and b:IsVisible() then
			local me = UnitIsUnit(b.unit, "player")
			if not issecret(me) and me then
				local line = RuleLine(b)
				line.drain:Stop()
				line:Show()
				line.drain:Play()
			end
		end
	end
end

local function StopRule()
	for _, b in ipairs(Z.buttons or {}) do
		if b.fiveLine then
			b.fiveLine.drain:Stop()
			b.fiveLine:Hide()
		end
	end
end

local function OnCast(_, _, _, _, spellID)
	if PaidMana(spellID) then StartRule() end
end

-- Réglage changé : mes sorts ne sont écoutés que si le trait est voulu (et si ma classe a de la mana)
function Z:RefreshFiveSecondRule()
	local wanted = Z.db and Z.db.fiveSecondRule and HasMana()
	if not wanted then
		if ruleEvents then ruleEvents:UnregisterAllEvents() end
		StopRule()
		return
	end
	if not ruleEvents then
		ruleEvents = CreateFrame("Frame")
		ruleEvents:SetScript("OnEvent", function(...) Z:Try("règle des 5 secondes", OnCast, ...) end)
	end
	pcall(ruleEvents.RegisterUnitEvent, ruleEvents, "UNIT_SPELLCAST_SUCCEEDED", "player")
end

Z:On("PLAYER_LOGIN", function()
	Z:RefreshManaEdge()
	Z:RefreshFiveSecondRule()
end)
