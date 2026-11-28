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
local UnitPhaseReason = UnitPhaseReason
local UnitPowerPercent = UnitPowerPercent
local SummonStatus = C_IncomingSummon and C_IncomingSummon.IncomingSummonStatus

local db
local buttons = {}   -- toutes les cases, tous cadres confondus
Z.buttons = buttons
Z.headers = {}       -- cadre principal, tanks, familiers

local MANA = 0
-- Teintes de la barre de mana (réglage « manaColor ») : bleu par défaut, comme dans le jeu
Z.manaColors = {
	BLUE = { 0.25, 0.50, 1.00 }, SKY = { 0.40, 0.75, 1.00 }, PURPLE = { 0.62, 0.42, 1.00 },
	TEAL = { 0.20, 0.82, 0.82 }, WHITE = { 0.88, 0.90, 0.95 },
}

-- Couleur de la barre de ressource : la mana prend la teinte choisie (manaColor) ; rage, énergie, focalisation et les
-- autres prennent la couleur des barres du jeu (PowerBarColor), comme chez les autres cadres de soin
function Z.PowerColor(powerType, token)
	if powerType ~= MANA then
		local color = PowerBarColor and (PowerBarColor[token or ""] or PowerBarColor[powerType])
		if color and color.r then return color.r, color.g, color.b end
	end
	return unpack(Z.manaColors[Z.db.manaColor] or Z.manaColors.BLUE)
end
-- Signal du jeu (ping) : un modèle du jeu rend la case sensible à la touche de signal, qui marque alors le
-- joueur de la case pour tout le groupe. Absent d'un client plus ancien : les cases s'en passent.
local PING_TEMPLATE = PingableType_UnitFrameMixin and ",PingableUnitFrameTemplate" or ""
local SMOOTH = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
local smoothing      -- SMOOTH ou nil selon l'option

-- Ordre de dessin des segments dans la barre de vie. Elle rogne ses enfants : le jeu y ignore alors l'ordre des
-- cadres, seules comptent les couches (sous-niveaux d'ARTWORK). Des places restent libres pour les segments à
-- venir (mon soin séparé de celui des autres, soins sur la durée). Le relief du thème (b.shade) passe sur tout.
-- Les segments qui se suivent (mon soin, celui des autres, soins sur la durée) ne se recouvrent jamais : même couche.
-- Au-dessus de mon soin : la teinte du gaspillage (ambre puis cuivre), et tout en haut le voile de l'incantation.
-- Le prochain coup de mes soins sur la durée, plus franc, se pose sur le début de leur segment.
local LAYER = { health = 0, incoming = 1, others = 1, hot = 1, hotNext = 2, pending = 1, overheal = 2, overhealMore = 3, absorb = 4,
	stripes = 5, healAbsorb = 6, castFill = 7, landing = 7 }
-- Alerte de gaspillage : ambre, puis cuivre au-delà de 25 % de la vie. Jamais de rouge (il veut dire « en danger »).
local OVERHEAL_COLOR, OVERHEAL_MORE_COLOR = { 1.00, 0.76, 0.22, 0.70 }, { 0.86, 0.45, 0.20, 0.75 }
local OTHERS_ALPHA = 0.5 -- soins en route des autres : la teinte du mien, plus pâle
local PENDING_FILL = 0.35 -- soin en attente : la teinte de mes soins sur la durée, à peine remplie
Z.OTHERS_ALPHA = OTHERS_ALPHA -- (le mode test aussi)
-- Teinte des soins en route d'une case : le mien, puis ceux des autres plus pâles (cases et mode test)
function Z.SetIncomingColor(cell, c)
	cell.incoming:SetStatusBarColor(c[1], c[2], c[3], c[4])
	if cell.incomingOthers then cell.incomingOthers:SetStatusBarColor(c[1], c[2], c[3], (c[4] or 1) * OTHERS_ALPHA) end
end
local SHIELD_ATLAS = "RaidFrame-Shield-Overlay" -- rayures du bouclier des cadres du jeu
local SHIELD_STRIPES = "Interface\\RaidFrame\\Shield-Overlay" -- les mêmes, en image (client sans l'atlas)
-- Remplissage au demi-pixel près : sans le calage sur les pixels de l'écran, une barre étroite (mon soin en route,
-- son voile) avance d'un mouvement continu au lieu de petits sauts d'un pixel
local function Unsnap(tex)
	if tex.SetSnapToPixelGrid then tex:SetSnapToPixelGrid(false) end
	if tex.SetTexelSnappingBias then tex:SetTexelSnappingBias(0) end
end
Z.Unsnap = Unsnap
local function SetLayer(bar, sub)
	local tex = bar:GetStatusBarTexture()
	tex:SetDrawLayer("ARTWORK", sub)
	Unsnap(tex)
end

-- Soins en route sur une barre verte : la teinte de contraste du thème, sinon le vert du soin se fond dans
-- celui de la vie. Couleur lisible (classe, camp, mode test) : jamais une valeur secrète.
local incomingTheme -- thème courant, gardé par BuildCurves à chaque Refresh
local function IsGreen(r, g, bl) return g - math.max(r, bl) >= 0.15 end
function Z.IncomingColor(r, g, bl)
	local theme = incomingTheme or Z:Theme()
	return IsGreen(r, g, bl) and theme.incomingOnGreen or theme.incoming -- (thème sans contraste : couleur normale)
end
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

local healthCurve, hideWhenFullCurve, lowHealthCurve, lowManaCurve, healCalculator
local overCalculator -- alerte de gaspillage, second niveau : les soins en route dépassent la vie de plus de 25 %
local incomingCurve, othersCurve -- couleur des soins en route (le mien, ceux des autres) en « Vie restante » (BuildCurves)
local healthyCurve, healthyDeficitCurve -- joueur en bonne santé estompé (réglage healthyFade, BuildCurves)

-- Joueur en bonne santé estompé (réglage healthyFade, éteint au départ) : au-dessus du seuil, la vie, la mana, le
-- nom et le chiffre de vie passent à HEALTHY_ALPHA. L'opacité vient d'une courbe du jeu : la vie n'est jamais
-- comparée, ça marche en combat. Les icônes, la dissipation, la menace et le contour de ma cible restent nets :
-- un joueur en bonne santé mais à dissiper ressort quand même. La case survolée reste nette (b.hovered).
-- Ma cible n'a pas d'exception : « est-ce ma cible » peut être secret et ne se combine pas avec la courbe.
local HEALTHY_ALPHA = 0.5
Z.HEALTHY_ALPHA = HEALTHY_ALPHA -- le mode test estompe de la même façon
function Z.SetHealthyAlpha(b, alpha)
	b.hp:SetAlpha(alpha)
	b.power:SetAlpha(alpha)
	b.name:SetAlpha(alpha)
end

-- Taille d'une case, réduite en grand raid si l'option est cochée.
-- En mode test, on compte les faux joueurs : l'aperçu à 40 montre la vraie taille d'un raid de 40.
local function ShrinkFactor()
	if not db.autoShrink then return 1 end
	local members = Z.previewActive and Z:PreviewSize() or GetNumGroupMembers()
	return members > 25 and 0.7 or members > 10 and 0.85 or 1
end

function Z.CellSize()
	local factor = ShrinkFactor()
	return math.floor(db.width * factor + 0.5), math.floor(db.height * factor + 0.5)
end

-- Case d'un familier (C26) : une part de celle d'un joueur (réglage petSize, 60 % au départ), en face de son maître
function Z.PetSize()
	local width, height = Z.CellSize()
	local k = db.petSize / 100
	return math.max(30, math.floor(width * k + 0.5)), math.max(16, math.floor(height * k + 0.5))
end
-- Écart entre les joueurs et la colonne de leurs familiers : un vrai espace, plus large qu'entre deux cases
function Z.PetGap() return db.spacing + 8 end

-- Taille des icônes de la case (rôle, marqueur, grande icône...) : 30 % de sa hauteur, 10 pixels au moins.
-- Les rangées de mes soins et des affaiblissements ont leur propre taille, selon la forme (Z.AuraRows).
function Z.IconSize()
	local _, height = Z.CellSize()
	return math.max(10, math.floor(height * 0.30 + 0.5))
end

----------------------------------------------------------------------------------------------------
-- Mises à jour d'une case. « b » est la case, b.unit son joueur ("raid7", "party2", "player"...)
----------------------------------------------------------------------------------------------------
-- Couleur de classe, naturelle ou vive selon le réglage (Z.ClassColor, Themes.lua)
-- Sur les cases cible et focalisation (extra), un personnage non joueur prend la couleur de son camp.
local ENEMY_COLOR, FRIEND_COLOR = { 0.85, 0.20, 0.18 }, { 0.30, 0.75, 0.35 }

-- Maître d'un familier (C26) : pet -> player, partypet2 -> party2, raidpet7 -> raid7
local function OwnerUnit(unit)
	if unit == "pet" then return "player" end
	return (unit:gsub("pet", "", 1))
end
Z.OwnerUnit = OwnerUnit

-- Un familier prend la couleur de la classe de son maître (la sienne serait celle de la créature : un diablotin
-- compterait comme mage), pâlie pour ne jamais passer pour un joueur
local PET_PALE = 0.35
function Z.PetColor(class)
	local r, g, bl = Z.ClassColor(class)
	return r + (1 - r) * PET_PALE, g + (1 - g) * PET_PALE, bl + (1 - bl) * PET_PALE
end
local function ClassColor(unit, extra, pet)
	if pet then return Z.PetColor((select(2, UnitClass(OwnerUnit(unit))))) end
	if extra then
		local player = UnitIsPlayer(unit)
		if not issecret(player) and not player then
			local enemy = UnitCanAttack("player", unit)
			local color = (not issecret(enemy) and enemy) and ENEMY_COLOR or FRIEND_COLOR
			return color[1], color[2], color[3]
		end
	end
	local _, class = UnitClass(unit)
	return Z.ClassColor(class)
end

-- Petits chiffres (bouclier : absorbText, soins en route : incomingText) : montant secret, écrit par le jeu.
-- Pour ne pas afficher « +0 » sans rien comparer, le texte est rangé dans un cadre qui le coupe, accroché au
-- remplissage d'une barre de 0 à 1 : le moindre montant la remplit, zéro la laisse vide et le texte disparaît.
local function SetSmallText(switch, text, amount)
	if amount == nil then return end
	switch:SetValue(amount)
	text:SetFormattedText("+%s", AbbreviateNumbers(amount))
end

local function UpdateAbsorbText(b, absorbs)
	local total = healCalculator.GetTotalDamageAbsorbs and healCalculator:GetTotalDamageAbsorbs() or absorbs
	SetSmallText(b.absorbSwitch, b.absorbText, total)
end

-- Éclat à l'arrivée de mon soin (healLanding) : la barre de l'éclat garde mon soin en route, figée le temps de
-- l'éclat (PlayLanding), pour qu'il reste visible pendant que le soin passe dans la vie.
local landingFrozen = false

-- Soins en route, bouclier, et absorption de soins : montants calculés par le jeu, lisibles en combat.
-- Les soins en route : tous, le mien, ceux des autres, et « ça dépasse la vie qui manque » (booléen secret).
local function UpdateIncoming(b, max)
	local all, mine, others, over = healCalculator:GetIncomingHeals()
	b.incoming:SetMinMaxValues(0, max)
	-- (un « a and b or c » testerait la valeur, secrète en combat : deux appels distincts)
	if db.incomingSplit == "ALL" then b.incoming:SetValue(all, smoothing) else b.incoming:SetValue(mine, smoothing) end
	if b.incomingOthers:IsShown() then
		b.incomingOthers:SetMinMaxValues(0, max)
		b.incomingOthers:SetValue(others, smoothing)
	end
	-- Chiffre : ce que montrent les segments (le mien seul, ou tous)
	if b.incomingSwitch:IsShown() then
		if db.incomingSplit == "MINE" then
			SetSmallText(b.incomingSwitch, b.incomingText, mine)
		else
			SetSmallText(b.incomingSwitch, b.incomingText, all)
		end
	end
	if b.landing:IsShown() and not landingFrozen then
		b.landing:SetMinMaxValues(0, max)
		b.landing:SetValue(mine)
	end
	-- Gaspillage : aucun test sur la valeur, le booléen du jeu est branché sur l'opacité de la teinte
	if b.overheal:IsShown() then
		if over ~= nil then b.overheal:SetAlphaFromBoolean(over, 1, 0) else b.overheal:SetAlpha(0) end
		if b.overhealMore:IsShown() then
			if overCalculator.ResetPredictedValues then overCalculator:ResetPredictedValues() end
			UnitGetDetailedHealPrediction(b.unit, "player", overCalculator)
			local overMore = select(4, overCalculator:GetIncomingHeals())
			if overMore ~= nil then b.overhealMore:SetAlphaFromBoolean(overMore, 1, 0) else b.overhealMore:SetAlpha(0) end
		end
	end
end

-- Mes soins sur la durée (Hots.lua) : montants connus de Lyorune, lisibles ; seule la vie max est secrète.
-- Éclairci quand l'un d'eux vit ses 3 dernières secondes (à relancer). Ensuite, à part, le soin qui attend que le
-- joueur soit touché (Prière de guérison, hotPending).
local HOT_ENDING_ALPHA = 0.45
local function UpdateHots(b, max)
	if not b.hot:IsShown() then return end
	local left, soon, ending, waiting = Z.HotAmounts(b.unit)
	if b.pending:IsShown() then
		b.pending:SetMinMaxValues(0, max)
		b.pending:SetValue(waiting, smoothing)
	end
	local alpha = ending and HOT_ENDING_ALPHA or 1
	b.hot:SetAlpha(alpha)
	b.hotNext:SetAlpha(alpha)
	b.hot:SetMinMaxValues(0, max)
	b.hot:SetValue(left, smoothing)
	b.hotNext:SetMinMaxValues(0, max)
	b.hotNext:SetValue(soon, smoothing)
end

local function UpdatePrediction(b)
	UpdateHots(b, UnitHealthMax(b.unit))
	if not (db.showIncoming or db.showAbsorb or db.showHealAbsorb) then return end
	local unit = b.unit
	local max = UnitHealthMax(unit)
	if healCalculator.ResetPredictedValues then healCalculator:ResetPredictedValues() end -- rien de la case précédente
	UnitGetDetailedHealPrediction(unit, "player", healCalculator)
	if db.showIncoming then UpdateIncoming(b, max) end
	b.absorb:SetMinMaxValues(0, max)
	local absorbs, clamped = healCalculator:GetDamageAbsorbs()
	b.absorb:SetValue(absorbs, smoothing)
	-- Bouclier plus grand que la vie manquante : le jeu le dit par un booléen (secret), branché sur l'opacité
	if b.overAbsorb:IsShown() and clamped ~= nil then b.overAbsorb:SetAlphaFromBoolean(clamped, 1, 0) end
	if b.absorbSwitch:IsShown() then UpdateAbsorbText(b, absorbs) end
	if healCalculator.GetHealAbsorbs then
		b.healAbsorb:SetMinMaxValues(0, max)
		b.healAbsorb:SetValue((healCalculator:GetHealAbsorbs()), smoothing)
	end
end

-- Mort, fantôme, hors ligne : la case devient grise et affiche l'état
local function UpdateState(b)
	local unit = b.unit
	local connected = UnitIsConnected(unit)
	if issecret(connected) then connected = true end
	local dead = UnitIsDeadOrGhost(unit)
	if issecret(dead) then dead = false end
	if b.dead and not dead then Z.ClearResFor(unit) end -- relevé : le nom du soigneur ne sert plus
	if dead and not b.dead and not b.extra and Z.ForgetBuffs then Z.ForgetBuffs(unit) end -- ses buffs sont partis
	b.dead = dead

	local status, rezzer
	if not connected then
		status = L["Déco"]
	elseif dead then
		local ghost = UnitIsGhost(unit)
		status = (not issecret(ghost) and ghost) and L["Fantôme"] or L["Mort"]
		rezzer = Z.ResBy(unit) -- qui relève qui (Comm.lua) : le nom du soigneur remplace « Mort »
		if rezzer then status = rezzer end
	end
	-- mort, relevé, déconnecté : le panneau des buffs se relit (un buff à une personne change de porteur)
	if status ~= b.status and Z.QueueBuffPanel then Z:QueueBuffPanel() end
	b.status = status

	local r, g, bl = ClassColor(unit, b.extra, b.isPet)
	if status then
		b.hp:SetStatusBarColor(0.25, 0.25, 0.28)
		b.name:SetTextColor(0.65, 0.65, 0.68)
		b.text:SetText(status)
		if rezzer then b.text:SetTextColor(0.45, 1, 0.55) else b.text:SetTextColor(0.95, 0.35, 0.35) end
		b.text:SetAlpha(1)
		b.low.fill:SetAlpha(0)
	else
		b.text:SetTextColor(1, 1, 1)
		if db.color == "CLASS" then
			b.hp:SetStatusBarColor(r, g, bl)
			if db.showIncoming then
				Z.SetIncomingColor(b, Z.IncomingColor(r, g, bl))
			end
			b.name:SetTextColor(1, 1, 1)
		else
			b.name:SetTextColor(r, g, bl)
		end
	end
end

-- Vie basse (C32) : liseré rouge fixe sous le seuil, en combat seulement, jamais de battement. Son opacité vient
-- d'une courbe du jeu (rien n'est comparé). Recalculé à chaque changement de vie, au passage de la portée (2 fois
-- par seconde) et en entrant ou en sortant de combat : il ne reste jamais bloqué.
local fighting = InCombatLockdown() and true or false
-- Jamais sur un familier : sa vie basse n'aide pas le soigneur, et mort en combat (état parfois secret), il
-- restait cerclé de rouge.
local function UpdateLow(b)
	if not db.lowHealth then return end
	if b.status or b.isPet or not fighting then return b.low.fill:SetAlpha(0) end
	local max = UnitHealthMax(b.unit)
	-- vie maximale lisible à 0 (joueur que le jeu ne connaît pas encore, en chargement) : jamais de liseré
	if not issecret(max) and (tonumber(max) or 0) <= 0 then
		b.low.fill:SetAlpha(0)
	else
		b.low.fill:SetAlpha(UnitHealthPercent(b.unit, true, lowHealthCurve).a) -- visible sous le seuil seulement
	end
end

local function UpdateHealth(b)
	local unit = b.unit
	local dead = UnitIsDeadOrGhost(unit)
	if issecret(dead) then dead = false end
	if dead ~= b.dead then UpdateState(b) end

	local hp, max = b.hp, UnitHealthMax(unit)
	hp:SetMinMaxValues(0, max)
	hp:SetValue(UnitHealth(unit), smoothing)

	if not b.status then
		if db.color == "HEALTH" then
			hp:SetStatusBarColor(UnitHealthPercent(unit, true, healthCurve):GetRGB())
			if db.showIncoming then
				b.incoming:SetStatusBarColor(UnitHealthPercent(unit, true, incomingCurve):GetRGBA())
				if b.incomingOthers:IsShown() then b.incomingOthers:SetStatusBarColor(UnitHealthPercent(unit, true, othersCurve):GetRGBA()) end
			end
		end
		UpdateLow(b)
		local fade = db.healthyFade and not b.hovered
		if b.isPet then
			b.text:SetText("") -- familier : case étroite, le chiffre de vie cachait son nom (C35) ; « Mort » reste
		elseif db.text == "DEFICIT" then
			b.text:SetFormattedText("-%s", AbbreviateNumbers(UnitHealthMissing(unit)))
			-- invisible à 100 % ; estompé au-dessus du seuil de bonne santé (une seule courbe pour les deux)
			b.text:SetAlpha(UnitHealthPercent(unit, true, fade and healthyDeficitCurve or hideWhenFullCurve).a)
		elseif db.text == "PERCENT" and CurveConstants and CurveConstants.ScaleTo100 then
			b.text:SetFormattedText("%.0f%%", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
			if fade then b.text:SetAlpha(UnitHealthPercent(unit, true, healthyCurve).a) else b.text:SetAlpha(1) end
		else
			b.text:SetText("")
		end
	end
	if db.healthyFade and not b.status and not b.hovered then
		Z.SetHealthyAlpha(b, UnitHealthPercent(unit, true, healthyCurve).a)
	else
		Z.SetHealthyAlpha(b, 1)
	end
	UpdatePrediction(b)
end

-- Hauteur réelle de la barre de mana : 8 pixels au moins quand le pourcentage y est écrit, pour qu'il se lise.
-- Elle prend sa place dans la case : la barre de vie en garde toujours au moins MIN_HEALTH pixels.
local PERCENT_HEIGHT, MIN_HEALTH = 8, 10
function Z.PowerHeight()
	local height = db.manaPercent and math.max(db.powerHeight, PERCENT_HEIGHT) or db.powerHeight
	local _, cellHeight = Z.CellSize()
	return math.max(2, math.min(height, cellHeight - MIN_HEALTH))
end

local function UpdatePower(b)
	-- Icône de mana basse d'un soigneur : opacité donnée par la courbe du jeu, même quand la mana est secrète
	if b.lowManaShown then b.lowMana:SetAlpha(UnitPowerPercent(b.unit, MANA, false, lowManaCurve).a) end
	if not b.powerShown then return end
	local powerType = b.powerType or MANA -- la ressource du joueur : mana, rage, énergie...
	b.power:SetMinMaxValues(0, UnitPowerMax(b.unit, powerType))
	b.power:SetValue(UnitPower(b.unit, powerType))
	-- Le pourcentage est calculé par le jeu : il reste lisible en combat, même quand la mana est secrète
	if db.manaPercent and UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100 then
		b.powerText:SetFormattedText("%.0f%%", UnitPowerPercent(b.unit, powerType, false, CurveConstants.ScaleTo100))
		b.powerText:Show()
	else
		b.powerText:Hide()
	end
end

-- En raid, la colonne des familiers ne les met pas en face de leur maître : son nom remplace celui du familier
-- (C26), qui reste dans l'infobulle
local function UpdateName(b)
	local unit = b.unit
	if b.isPet and not b.owner then unit = OwnerUnit(unit) end -- (colonne du raid : seuls familiers sans maître collé)
	b.name:SetText(UnitName(unit))
end

-- Distance, en trois paliers, sans la position des joueurs (cachée par le jeu en donjon et en raid) :
--   à portée de soin (UnitInRange, environ 40 m) : case normale ;
--   proche mais hors de portée (le jeu voit encore le joueur, environ 100 m) : case estompée ;
--   loin (le jeu ne le voit plus) : case encore plus estompée, empreintes au centre (réglage « farHint »).
-- Si le jeu rend une réponse secrète, Lyorune s'en tient à l'estompage simple.
local UpdateCenter

local function IsFar(unit)
	if not db.farHint or not UnitIsVisible then return false end
	local visible, connected = UnitIsVisible(unit), UnitIsConnected(unit)
	if issecret(visible) or issecret(connected) or not connected then return false end
	return not visible
end

local function SetFar(b, far)
	if b.far == far then return end
	b.far = far
	UpdateCenter(b)
end

-- Le joueur d'un autre soigneur (réglage assignFade, UpdateAssign) : toute la case un peu plus estompée, la
-- portée garde ses paliers par-dessus (b.assignDim vaut 1 ou ASSIGN_DIM)
local ASSIGN_DIM = 0.6
Z.ASSIGN_DIM = ASSIGN_DIM -- le mode test estompe de la même façon

-- Portée d'un familier (C26) : le jeu ne répond pas pour lui avec UnitInRange (toujours « loin »). La portée du
-- sort de mon clic gauche d'abord, sinon celle de son maître (un familier reste près de lui). Le sort est relu
-- toutes les 5 secondes au plus (clics changés, sort appris).
local petSpell, petSpellAt = nil, -10
local function PetSpell()
	local now = GetTime()
	if now - petSpellAt > 5 then
		petSpellAt = now
		local value = Z.GetClicks and Z:GetClicks()["1"]
		petSpell = type(value) == "string" and value ~= "" and value:sub(1, 1) ~= "@"
			and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(value) and value or nil
	end
	return petSpell
end
local function PetRange(b)
	local spell = PetSpell()
	if spell and C_Spell.IsSpellInRange then
		local ok, inRange = pcall(C_Spell.IsSpellInRange, spell, b.unit)
		if ok and (issecret(inRange) or inRange ~= nil) then return inRange, true end
	end
	if b.unit == "pet" then return true, true end -- le mien, sans réponse : près de moi
	return UnitInRange(OwnerUnit(b.unit))
end

local function UpdateRange(b)
	local k = b.assignDim or 1
	if b.owner then k = k * db.frameAlpha / 100 end -- familier collé : sa propre portée, pas celle de son maître
	local me = UnitIsUnit(b.unit, "player")
	if not issecret(me) and me then SetFar(b, false) return b:SetAlpha(1) end -- je suis toujours à portée de moi-même
	if IsFar(b.unit) then
		SetFar(b, true)
		return b:SetAlpha(math.max(0.1, rangeAlpha * 0.5) * k)
	end
	SetFar(b, false)
	local inRange, checked
	if b.isPet then inRange, checked = PetRange(b) else inRange, checked = UnitInRange(b.unit) end
	if issecret(inRange) then
		b:SetAlphaFromBoolean(inRange, k, rangeAlpha * k)
	elseif checked and not inRange then
		b:SetAlpha(rangeAlpha * k)
	else
		b:SetAlpha(k)
	end
end

-- Répartition entre soigneurs (Assign.lua) : trait doré au bord gauche de mes joueurs ; les autres un peu
-- estompés (réglage assignFade). Réponse secrète (nom, groupe) : la case garde son état.
local function UpdateAssign(b)
	local mine, active = Z.AssignState(b.unit)
	if mine == nil then return end
	b.assign:SetShown((db.assignMark and active and mine) or false)
	local dim = (db.assignFade and active and not mine) and ASSIGN_DIM or 1
	if dim ~= (b.assignDim or 1) then
		b.assignDim = dim
		UpdateRange(b)
	end
end

-- Menace : bordure rouge quand ce joueur a l'attention d'un monstre, et barre fine en haut de la vie
-- (jaune : il monte dans la liste, orange : il va la prendre, rouge : il l'a)
local THREAT_COLORS = { { 1, 0.85, 0.25 }, { 1, 0.50, 0.10 }, { 1, 0.12, 0.12 } }
local function UpdateThreat(b)
	local situation = (db.showThreat or db.threatBar) and UnitThreatSituation(b.unit)
	if issecret(situation) then situation = nil end
	b.threat:SetShown(db.showThreat and situation and situation >= 2 or false)
	local color = db.threatBar and situation and THREAT_COLORS[situation]
	if color then b.threatBar:SetColorTexture(color[1], color[2], color[3], 0.95) end
	b.threatBar:SetShown(color and true or false)
end

-- Place la barre de vie selon le thème, et la barre de mana si elle est affichée
local function LayoutBars(b)
	local inset = UI.Inset(Z:Theme().borderSize, db.corners == "ROUND")
	b.hp:ClearAllPoints()
	b.hp:SetPoint("TOPLEFT", inset, -inset)
	b.hp:SetPoint("BOTTOMRIGHT", -inset, inset + (b.powerShown and Z.PowerHeight() + 1 or 0))
end

-- Rôle : icône, et barre de ressource pour les soigneurs (ou tous) selon l'option. Appelé aussi quand la
-- ressource change (UNIT_DISPLAYPOWER : druide en forme d'ours ou de félin, véhicule).
local function UpdateRole(b)
	local unit = b.unit
	local role = Z.UnitRole(unit) -- le rôle du jeu, ou celui des talents du druide (C43, Roles.lua) ; nil si secret
	local had = b.role:IsShown()
	if db.showRole and role == "TANK" then
		b.role:SetAtlas("roleicon-tiny-tank")
		b.role:Show()
	elseif db.showRole and role == "HEALER" then
		b.role:SetAtlas("roleicon-tiny-healer")
		b.role:Show()
	elseif db.showRole and db.showDpsRole and role == "DAMAGER" then -- (C25, éteint au départ)
		b.role:SetAtlas("roleicon-tiny-dps")
		b.role:Show()
	else
		b.role:Hide()
	end
	if b.role:IsShown() ~= had then Z.PlaceLeader(b) end -- l'icône de rôle est apparue ou partie (défini plus bas)

	-- La ressource montrée par le jeu pour ce joueur. Réponse secrète ou inconnue : celle déjà connue, sinon
	-- celle de sa classe (Data.lua), sinon la mana. Relue à la sortie de combat.
	local powerType, token = UnitPowerType(unit)
	if issecret(powerType) or type(powerType) ~= "number" then
		local _, class = UnitClass(unit)
		local guess = Z.classPower[not issecret(class) and class or ""]
		if b.powerType then
			powerType, token = b.powerType, b.powerToken
		elseif guess then
			powerType, token = guess[1], guess[2]
		else
			powerType, token = MANA, "MANA"
		end
	end
	if issecret(token) or type(token) ~= "string" then token = nil end
	local hasMana = powerType == MANA
	if powerType ~= b.powerType or token ~= b.powerToken then
		b.powerType, b.powerToken = powerType, token
		b.power:SetStatusBarColor(Z.PowerColor(powerType, token))
	end
	-- Tous : chaque joueur avec sa ressource ; Soigneurs : leur mana
	local wanted = db.manaBars == "ALL" or (db.manaBars == "HEALERS" and role == "HEALER" and hasMana)
	if wanted ~= b.powerShown then
		b.powerShown = wanted
		b.power:SetShown(wanted)
		LayoutBars(b)
	end
	-- Mana basse d'un soigneur (seulement si le jeu a UnitPowerPercent : jamais de comparaison de la mana)
	local drop = (hasMana and (tonumber(db.lowManaHealers) or 0) > 0 and role == "HEALER" and UnitPowerPercent ~= nil) or false
	if drop ~= b.lowManaShown then
		b.lowManaShown = drop
		b.lowMana:SetShown(drop)
	end
	-- Soigneur qui boit : sa boisson à côté de sa mana basse (conteneur du jeu, sinon lecture des auras)
	local drinks = (db.drinkHealers and role == "HEALER") or false
	if drinks ~= b.drinkShown then
		b.drinkShown = drinks
		if Z.ShowDrinkBox then Z.ShowDrinkBox(b) end
		if not drinks and b.drinkIcon then b.drinkIcon:Hide() end
		if drinks and not b.boxes and Z.QueueAuras then Z.QueueAuras(b) end
	end
	-- Les événements de mana servent à la barre comme à l'icône
	local listen = wanted or drop
	if listen ~= b.powerListen then
		b.powerListen = listen
		if listen then
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

-- Chef de groupe (couronne) ou assistant en raid (petit drapeau). En combat, une réponse secrète laisse l'icône
-- telle qu'elle était : le chef ne change pas en plein combat.
local LEADER_ICON = "Interface\\GroupFrame\\UI-Group-LeaderIcon"
local ASSIST_ICON = "Interface\\GroupFrame\\UI-Group-AssistantIcon"

-- Icône de classe : seulement pour un joueur, classe lisible (jamais secrète d'ordinaire)
local function UpdateClass(b)
	if not db.showClassIcon then return b.class:Hide() end
	local player = UnitIsPlayer(b.unit)
	if issecret(player) or not player then return b.class:Hide() end
	Z.SetClassIcon(b.class, (select(2, UnitClass(b.unit))))
end

local function UpdateLeader(b)
	if not db.showLeader then return b.leader:Hide() end
	local unit = b.unit
	local leader = UnitIsGroupLeader(unit)
	if issecret(leader) then return end
	local assist = not leader and IsInRaid() and UnitIsGroupAssistant(unit)
	if issecret(assist) then return end
	if leader then
		b.leader:SetTexture(LEADER_ICON)
	elseif assist then
		b.leader:SetTexture(ASSIST_ICON)
	end
	b.leader:SetShown(leader or assist or false)
end

-- Invocation en cours : 1 proposée, 2 acceptée, 3 refusée (0 : aucune)
local SUMMON_ATLAS = { "Raid-Icon-SummonPending", "Raid-Icon-SummonAccepted", "Raid-Icon-SummonDeclined" }

local function SummonAtlas(unit)
	local status = SummonStatus and SummonStatus(unit)
	if issecret(status) then return nil end
	return SUMMON_ATLAS[status or 0]
end

-- Dans une autre phase : à côté de moi en apparence, mais hors d'atteinte. Seulement pour un joueur connecté.
local function InOtherPhase(unit)
	if not UnitPhaseReason then return false end
	local player, connected = UnitIsPlayer(unit), UnitIsConnected(unit)
	if issecret(player) or issecret(connected) or not (player and connected) then return false end
	local reason = UnitPhaseReason(unit)
	return reason ~= nil and not issecret(reason)
end

-- Icône centrale : réponse à l'appel, résurrection en cours, soin refusé car hors de vue, invocation,
-- autre phase, joueur très loin
local LOS_ICON = "Interface\\Icons\\Ability_EyeOfTheOwl"
local FAR_ICON = "Interface\\Icons\\Ability_Tracking"

function UpdateCenter(b)
	if not db.showCenter then return b.center:Hide() end -- réglage « Icône au centre de la case »
	local unit = b.unit
	local ready = b.readyCheck and GetReadyCheckStatus(unit)
	local res = UnitHasIncomingResurrection(unit)
	local summon = db.showSummonPhase and SummonAtlas(unit)
	if ready == "ready" then
		b.center:SetTexture(READY_CHECK_READY_TEXTURE)
	elseif ready == "notready" then
		b.center:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
	elseif ready == "waiting" then
		b.center:SetTexture(READY_CHECK_WAITING_TEXTURE)
	elseif not issecret(res) and res then
		b.center:SetTexture("Interface\\RaidFrame\\Raid-Icon-Rez")
	elseif b.losUntil and GetTime() < b.losUntil then
		b.center:SetTexture(LOS_ICON)
	elseif summon then
		b.center:SetAtlas(summon)
	elseif db.showSummonPhase and InOtherPhase(unit) then
		b.center:SetTexture("Interface\\TargetingFrame\\UI-PhasingIcon")
	elseif b.far then
		b.center:SetTexture(FAR_ICON)
	else
		b.center:Hide()
		return
	end
	b.center:Show()
end

-- Bordure blanche : c'est ma cible
local function UpdateTarget(b)
	if b.unit == "target" then return b.selected:SetAlpha(0) end -- la case de ma cible n'a pas besoin de le dire
	b.selected:SetAlphaFromBoolean(UnitIsUnit(b.unit, "target"), 1, 0)
end

-- Barres animées (réglage smooth) : posées d'un coup à leur valeur, quand la case change de joueur
local SNAPPED = { "hp", "incoming", "incomingOthers", "hot", "hotNext", "pending", "absorb", "healAbsorb" }
local function SnapBars(b)
	-- joueur pas encore connu du jeu (UpdateAll n'a rien posé) : rien à sauter, on attend le prochain affichage
	local known = b.unit and UnitExists(b.unit)
	if issecret(known) or not known then return end
	b.snapPending = nil
	for _, key in ipairs(SNAPPED) do
		local bar = b[key]
		if bar.SetToTargetValue then bar:SetToTargetValue() end
	end
end

local function UpdateAll(b)
	if not b.unit or not UnitExists(b.unit) then return end
	UpdateName(b)
	UpdateState(b)
	UpdateHealth(b)
	UpdateRange(b)
	UpdateThreat(b)
	UpdateRole(b)
	UpdateClass(b)
	UpdateLeader(b)
	UpdateMarker(b)
	UpdateCenter(b)
	UpdateTarget(b)
	UpdateAssign(b)
	Z.QueueAuras(b)
end

-- Case affichée : tout est relu ; si elle a changé de joueur pendant qu'elle était cachée, ses barres sautent
local function ShownAgain(b)
	UpdateAll(b)
	if b.snapPending then SnapBars(b) end
end

-- Les mises à jour d'une case, pour la mesure des performances (Perf.lua) : le vrai code, chronométré
Z.cellUpdates = { all = UpdateAll, health = UpdateHealth, prediction = UpdatePrediction, power = UpdatePower, range = UpdateRange }

----------------------------------------------------------------------------------------------------
-- Événements d'une case
----------------------------------------------------------------------------------------------------
local unitEvents = {
	UNIT_HEALTH = UpdateHealth,
	UNIT_MAXHEALTH = UpdateHealth,
	UNIT_HEAL_PREDICTION = UpdatePrediction,
	UNIT_ABSORB_AMOUNT_CHANGED = UpdatePrediction,
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = UpdatePrediction,
	UNIT_PHASE = UpdateCenter,
	UNIT_AURA = function(b, _, info) -- la mise à jour d'abord
		Z.QueueAuras(b) Z.NoteAuraChanges(b, info)
		Z.CheckHots(b.unit, info) -- (rien à faire sans soin retenu : réglage éteint compris)
	end,
	UNIT_CONNECTION = UpdateAll,
	UNIT_NAME_UPDATE = UpdateName,
	UNIT_FLAGS = UpdateState,
	UNIT_THREAT_SITUATION_UPDATE = UpdateThreat,
	INCOMING_RESURRECT_CHANGED = UpdateCenter,
	UNIT_DISPLAYPOWER = UpdateRole, -- forme du druide : énergie, rage ou mana
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

-- Chaque événement d'une case passe par Z:Try : une erreur est notée au journal de Lyorune, même quand un autre
-- addon a pris le gestionnaire d'erreurs du jeu, et n'empêche pas les événements suivants.
local function OnEvent(b, event, ...)
	if b.unit then Z:Try(event, unitEvents[event] or powerEvents[event], b, ...) end
end

-- L'en-tête sécurisé du jeu attribue un joueur à la case en changeant son attribut « unit »
local function OnAttributeChanged(b, name, value)
	if name ~= "unit" or b.unit == value then return end
	b.unit = value
	b.losUntil = nil -- l'œil « hors de vue » concernait le joueur d'avant : il ne suit pas la case
	b.assign:Hide() -- le repère « pour moi » aussi (UpdateAssign repose celui du nouveau)
	b.assignDim = nil
	b:UnregisterAllEvents()
	if b.powerShown then
		b.powerShown = false
		b.power:Hide()
		LayoutBars(b)
	end
	b.powerListen, b.lowManaShown = false, false -- événements retirés ci-dessus : UpdateRole les reprendra
	b.drinkShown = nil -- le rôle du joueur d'avant : UpdateRole repose celui du nouveau
	b.powerType, b.powerToken = nil, nil -- la ressource du joueur d'avant : UpdateRole repose la sienne
	b.lowMana:Hide()
	if value and (not b.owner or b:IsShown()) then -- un familier collé caché n'écoute rien (PetShown)
		for event in pairs(unitEvents) do b:RegisterUnitEvent(event, value) end
		-- nouveau joueur : ses barres d'emblée, sans glisser depuis celles du joueur d'avant. Le jeu cache souvent la
		-- case pendant ce changement : le saut se fait alors à son affichage (ShownAgain).
		b.snapPending = true
		if b:IsVisible() then UpdateAll(b) SnapBars(b) end
	end
	Z.AnchorPrivateAuras(b) -- les auras privées suivent le joueur de la case
	Z.BindAuraBoxes(b) -- les conteneurs d'auras du jeu aussi (Containers.lua)
	if InCombatLockdown() then Z:FitAllRanks() else Z:FitRanks(b) end -- rang choisi : au niveau du nouveau joueur
end

-- Familier collé (C26) : il n'écoute ses événements que pendant qu'il est montré (pas appelé, ou familiers coupés :
-- caché). Montrer et cacher une case sont confiés au jeu ; ces abonnements, eux, sont permis en combat.
local function PetShown(b)
	if b.unit then
		for event in pairs(unitEvents) do b:RegisterUnitEvent(event, b.unit) end
	end
end
local function PetHidden(b)
	b:UnregisterAllEvents()
	b.powerListen, b.lowManaShown = false, false -- UpdateRole les reprend quand il revient
end

-- Infobulle hors combat : le joueur (infobulle du jeu), puis mes clics et touches (option)
local function OnEnter(b)
	b.hover:Show()
	b.hovered = true -- la case survolée n'est jamais estompée (réglage healthyFade)
	if db.healthyFade and b.unit then UpdateHealth(b) end
	Z.hovered = b -- /lyorune epingler : le joueur survolé
	if not b.unit or InCombatLockdown() then return end
	local clicks = db.clickTooltip and Z:ClickSummary()
	if clicks and #clicks == 0 then clicks = nil end
	local healers = Z.AssignHealers(b.unit) -- répartition reçue du chef : le soigneur prévu pour ce joueur
	local match = Z.InPvPMatch() -- match JcJ : le dire, une ligne (1.44.0)
	if not (db.showTooltip or clicks or healers or match) then return end
	GameTooltip_SetDefaultAnchor(GameTooltip, b)
	if db.showTooltip then
		GameTooltip:SetUnit(b.unit)
	else
		GameTooltip:SetText(UnitName(b.unit) or "", 1, 1, 1)
	end
	if healers then
		GameTooltip:AddLine(L["Soigneur prévu : %s"]:format(table.concat(healers, ", ")), UI.gold[1], UI.gold[2], UI.gold[3])
	end
	if match then
		GameTooltip:AddLine(L["Match JcJ : le jeu cache les buffs et bloque les messages entre addons."], 1, 0.82, 0.3, true)
	end
	if clicks then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Mes clics"], UI.frameAccent[1], UI.frameAccent[2], UI.frameAccent[3])
		local TOOLTIP_LINES = 16 -- les raccourcis ne sont pas limités, mais l'infobulle reste courte
		for i, line in ipairs(clicks) do
			if i > TOOLTIP_LINES then
				GameTooltip:AddLine(L["... et %d autre(s) : chapitre Sorts et raccourcis."]:format(#clicks - TOOLTIP_LINES), 0.6, 0.6, 0.65)
				break
			end
			if line.cooldown then -- sort en recharge : en rouge, avec ses secondes
				GameTooltip:AddDoubleLine(line[1], line[2] .. "  " .. L["(%d s)"]:format(math.ceil(line.cooldown)), 0.75, 0.78, 0.85, 1, 0.4, 0.35)
			else
				GameTooltip:AddDoubleLine(line[1], line[2], 0.75, 0.78, 0.85, 1, 1, 1)
			end
		end
	end
	GameTooltip:Show()
end

local function OnLeave(b)
	b.hover:Hide()
	b.hovered = nil
	if db.healthyFade and b.unit then UpdateHealth(b) end
	if Z.hovered == b then Z.hovered = nil end
	GameTooltip:Hide()
end

----------------------------------------------------------------------------------------------------
-- Apparence d'une case (appelé à la création et quand une option change)
----------------------------------------------------------------------------------------------------
local HEAL_ABSORB_COLOR = { 0.45, 0.02, 0.10, 0.75 } -- rouge sombre, si le thème n'en donne pas
local ASSIGN_COLOR = { 1.00, 0.80, 0.30 } -- repère « pour moi » : or, lisible sur toutes les couleurs de classe
local LOW_EDGE = 3 -- liseré de vie basse (C32), plus épais que le cadre de dissipation (2) : on ne les confond pas
Z.ASSIGN_COLOR = ASSIGN_COLOR

-- Voiles posés sur toute la case : à l'intérieur des angles quand ils sont arrondis
local function Cover(texture, inset)
	texture:ClearAllPoints()
	texture:SetPoint("TOPLEFT", inset, -inset)
	texture:SetPoint("BOTTOMRIGHT", -inset, inset)
end

-- Pose un élément à sa place d'origine, plus le décalage choisi dans l'éditeur de placement (Z.Offset)
local function Place(region, key, point, relative, relativePoint, x, y)
	local dx, dy = Z.Offset(key)
	region:ClearAllPoints()
	region:SetPoint(point, relative, relativePoint, x + dx, y + dy)
end

-- Nom, vie et rôle selon la forme : au centre (Tuile, Carré) ou sur une ligne (Barre, Bandeau).
-- Le marqueur et l'icône centrale suivent aussi l'éditeur de placement. Les places d'origine viennent de
-- Z.AuraRows (Themes.lua), lue aussi par Placement.lua (Origins) qui borne les décalages au bord de la case.
-- Largeur du nom et du texte de vie : Z.TextWidth, qui les fait rétrécir quand ils sont poussés vers un bord.
-- Petits chiffres (bouclier : absorbText, soins en route : incomingText) : sur la ligne du texte de vie, dont ils
-- suivent le décalage de l'éditeur de placement. Barre et Bandeau : au bout du texte de vie, qui recule d'autant ;
-- Tuile et Carré : en bas à droite. Le chiffre des soins se met à gauche de celui du bouclier (shift).
local function SmallTextSize()
	local size = math.max(7, db.fontSize + (Z:Theme().fontBonus or 0) - 2)
	return math.floor(size * 3.4), size + 4
end

local function PlaceSmallText(b, switch, inline, shift)
	local width, height = SmallTextSize()
	local dx, dy = Z.Offset("text")
	switch:ClearAllPoints()
	switch:SetSize(width, height)
	if inline then
		switch:SetPoint("RIGHT", b.hp, "RIGHT", b.rows.textX + dx + shift, dy)
	else
		switch:SetPoint("BOTTOMRIGHT", b.hp, "BOTTOMRIGHT", -2 - Z.CornerShift(b, "BOTTOMRIGHT") + shift, 2 + dy)
	end
end

-- Chef de groupe (C24). Barre et Bandeau : petit badge sur le coin de l'icône de rôle. Tuile et Carré : à gauche de
-- l'icône de rôle, plus le décalage de l'éditeur de placement ; si ce décalage le pose sur une icône de rôle
-- affichée (tank, soigneur, DPS), il revient à gauche d'elle, à la même hauteur. Revu quand le rôle change.
local function PlaceLeader(b)
	if Z:Shape().inline then
		return Place(b.leader, "leader", "CENTER", b.role, "TOPRIGHT", 0, 0)
	end
	local dx, dy = Z.Offset("leader")
	if b.role:IsShown() then
		local badge, width, height = b.leader:GetWidth(), b.role:GetWidth(), b.role:GetHeight()
		if dx > 1 and dx < width + badge + 1 and dy < badge and dy > -height then -- l'un sur l'autre
			local minX, maxX = Z.OffsetRange("leader") -- jamais hors de la case : à droite si la gauche en sort
			if minX <= 0 then dx = 0 elseif width + badge + 2 <= maxX then dx = width + badge + 2 end
		end
	end
	b.leader:ClearAllPoints()
	b.leader:SetPoint("TOPRIGHT", b.role, "TOPLEFT", -1 + dx, dy)
end
Z.PlaceLeader = PlaceLeader -- case d'exemple de l'éditeur de placement

-- Place d'origine d'un élément (Z.AuraRows, Themes.lua), plus le décalage de l'éditeur ; dx : un recul en plus
local function PlaceHome(b, region, key, home, dx)
	Place(region, key, home.point, home.relative == "HP" and b.hp or b, home.relPoint, home.x + (dx or 0), home.y)
end

local function PlaceTexts(b)
	local shield = db.showAbsorb and db.absorbText
	local heal = db.showIncoming and db.incomingText
	local inline = Z:Shape().inline
	local homes = b.rows.homes
	local step = SmallTextSize() + 2
	PlaceHome(b, b.role, "role", homes.role)
	PlaceHome(b, b.class, "class", homes.class)
	PlaceHome(b, b.name, "name", homes.name)
	-- Barre, Bandeau : le chiffre de vie recule devant ceux du bouclier et des soins
	PlaceHome(b, b.text, "text", homes.text, inline and -((shield and step or 0) + (heal and step or 0)) or 0)
	b.name:SetJustifyH(inline and "LEFT" or "CENTER")
	b.text:SetJustifyH(inline and "RIGHT" or "CENTER")
	b.name:SetWidth(Z.TextWidth("name"))
	b.text:SetWidth(Z.TextWidth("text"))
	Place(b.marker, "marker", "CENTER", b.over, "TOP", 0, -1)
	PlaceHome(b, b.center, "center", homes.center)
	PlaceHome(b, b.lowMana, "lowMana", homes.lowMana)
	if shield then PlaceSmallText(b, b.absorbSwitch, inline, 0) end
	if heal then PlaceSmallText(b, b.incomingSwitch, inline, shield and -step or 0) end
end

local function StyleSmallText(text, theme, c)
	text:SetFont(theme.font, (select(2, SmallTextSize())) - 4, theme.flags)
	text:SetTextColor(c[1] + (1 - c[1]) * 0.4, c[2] + (1 - c[2]) * 0.4, c[3] + (1 - c[3]) * 0.4)
end

local function Style(b)
	local theme = Z:Theme()
	local texture = UI.BarTexture()
	local width, height
	if b.isPet then width, height = Z.PetSize() else width, height = Z.CellSize() end
	local rounded = db.corners == "ROUND"
	local inset = UI.Inset(theme.borderSize, rounded)
	LayoutBars(b)
	b.hp:SetStatusBarTexture(texture)
	SetLayer(b.hp, LAYER.health)
	b.incoming:SetStatusBarTexture(texture)
	SetLayer(b.incoming, LAYER.incoming)
	b.incoming:SetStatusBarColor(unpack(theme.incoming)) -- teinte de contraste sur une barre verte : UpdateState, UpdateHealth
	b.incoming:SetWidth(width - 2 * inset)
	b.incoming:SetShown(db.showIncoming)
	-- Soins des autres, à la suite du mien, plus pâles (réglage incomingSplit)
	b.incomingOthers:SetStatusBarTexture(texture)
	SetLayer(b.incomingOthers, LAYER.others)
	local c = theme.incoming
	b.incomingOthers:SetStatusBarColor(c[1], c[2], c[3], (c[4] or 1) * OTHERS_ALPHA)
	b.incomingOthers:SetWidth(width - 2 * inset)
	b.incomingOthers:SetShown(db.showIncoming and db.incomingSplit == "SPLIT")
	b.incomingOthers:SetValue(0)
	-- Alerte de gaspillage et voile de l'incantation, sur mon soin
	local warn = db.showIncoming and db.overhealWarn and b.overheal.SetAlphaFromBoolean ~= nil
	b.overheal:SetShown(warn)
	b.overhealMore:SetShown(warn and overCalculator ~= nil)
	b.overheal:SetAlpha(0)
	b.overhealMore:SetAlpha(0)
	-- (voile et éclat pas en « Tous ensemble » : le segment y porte aussi les soins des autres, sur toutes les cases)
	b.castFill:SetShown(db.showIncoming and db.castFill and db.incomingSplit ~= "ALL")
	b.castFill:SetAlpha(0) -- (une case cachée pendant mon incantation ne garde pas le voile)
	b.landing:SetShown(db.showIncoming and db.healLanding and db.incomingSplit ~= "ALL")
	b.landing:SetWidth(width - 2 * inset)
	b.landingFlash:Stop()
	b.landing:SetAlpha(0)
	b.incomingSwitch:SetShown(db.showIncoming and db.incomingText)
	-- Mes soins sur la durée, à la suite des soins en route (ou de la vie s'ils sont coupés)
	local afterIncoming = b.incomingOthers:IsShown() and b.incomingOthers:GetStatusBarTexture()
		or db.showIncoming and b.incoming:GetStatusBarTexture() or b.hp:GetStatusBarTexture()
	local hotColor = theme.hot or theme.incoming
	for _, bar in ipairs({ b.hot, b.hotNext }) do
		bar:SetStatusBarTexture(texture)
		bar:SetWidth(width - 2 * inset)
		bar:SetShown(db.hotPrediction)
	end
	SetLayer(b.hot, LAYER.hot)
	SetLayer(b.hotNext, LAYER.hotNext)
	b.hot:SetStatusBarColor(hotColor[1], hotColor[2], hotColor[3], hotColor[4] or 1)
	b.hotNext:SetStatusBarColor(hotColor[1], hotColor[2], hotColor[3], math.min(1, (hotColor[4] or 1) * 1.9))
	b.hot:ClearAllPoints()
	b.hot:SetPoint("TOPLEFT", afterIncoming, "TOPRIGHT")
	b.hot:SetPoint("BOTTOMLEFT", afterIncoming, "BOTTOMRIGHT")
	-- en attente (Prière de guérison) : la même teinte, à peine remplie et bordée en haut et en bas
	b.pending:SetStatusBarTexture(texture)
	b.pending:SetWidth(width - 2 * inset)
	b.pending:SetShown(db.hotPrediction and db.hotPending)
	SetLayer(b.pending, LAYER.pending)
	b.pending:SetStatusBarColor(hotColor[1], hotColor[2], hotColor[3], (hotColor[4] or 1) * PENDING_FILL)
	for _, edge in ipairs(b.pendingEdges) do
		edge:SetColorTexture(hotColor[1], hotColor[2], hotColor[3], math.min(1, (hotColor[4] or 1) * 1.9))
	end
	b.absorb:SetStatusBarTexture(UI.WHITE)
	SetLayer(b.absorb, LAYER.absorb)
	local follow = db.absorbStyle == "FOLLOW"
	local shield = theme.absorb
	b.absorb:SetStatusBarColor(shield[1], shield[2], shield[3], (shield[4] or 1) * (follow and 0.45 or 1))
	-- à la suite de la vie : les rayures du bouclier du jeu, en mosaïque sur ce fond (jamais étirées)
	b.stripes:SetVertexColor(shield[1], shield[2], shield[3], shield[4] or 1)
	b.stripes:SetShown(db.showAbsorb and follow)
	b.absorb:SetShown(db.showAbsorb)
	b.absorb:ClearAllPoints()
	if follow then
		-- À la suite des soins en route et de mes soins sur la durée (ou de la vie), comme les cadres du jeu
		local after = b.pending:IsShown() and b.pending:GetStatusBarTexture()
			or db.hotPrediction and b.hot:GetStatusBarTexture() or afterIncoming
		b.absorb:SetPoint("TOPLEFT", after, "TOPRIGHT")
		b.absorb:SetPoint("BOTTOMLEFT", after, "BOTTOMRIGHT")
		b.absorb:SetWidth(width - 2 * inset)
	else
		b.absorb:SetPoint("BOTTOMLEFT")
		b.absorb:SetPoint("BOTTOMRIGHT")
		b.absorb:SetHeight(3)
	end
	b.overAbsorb:SetShown(db.showAbsorb and follow)
	b.overAbsorb:SetAlpha(0)
	b.absorbSwitch:SetShown(db.showAbsorb and db.absorbText)
	b.healAbsorb:SetStatusBarTexture(texture)
	SetLayer(b.healAbsorb, LAYER.healAbsorb)
	b.healAbsorb:SetStatusBarColor(unpack(theme.healAbsorb or HEAL_ABSORB_COLOR))
	b.healAbsorb:SetWidth(width - 2 * inset)
	b.healAbsorb:SetShown(db.showHealAbsorb)
	b.power:SetStatusBarTexture(texture)
	-- Couleur posée après la texture : le jeu remet en blanc toute nouvelle texture de barre
	b.power:SetStatusBarColor(Z.PowerColor(b.powerType or MANA, b.powerToken))
	b.power:SetHeight(Z.PowerHeight())
	b.powerText:SetFont(theme.font, PERCENT_HEIGHT, "OUTLINE")
	b.threatBar:SetHeight(math.max(2, math.floor(height / 18)))
	b.bg:SetVertexColor(unpack(theme.bg))
	b.bgRound:SetVertexColor(unpack(theme.bg))
	b.bg:SetShown(not rounded)
	b.bgRound:SetShown(rounded)
	b.border:SetThickness(theme.borderSize)
	b.border:SetColor(theme.border[1], theme.border[2], theme.border[3], 1)
	for _, border in ipairs({ b.border, b.threat, b.dispel, b.selected, b.glow and b.glow.border }) do border:SetRounded(rounded) end
	for _, veil in ipairs({ b.hover, b.dispel.fill }) do Cover(veil, rounded and inset or 0) end
	b.low.fill:SetRounded(rounded)
	-- Couleurs vives : un relief plus léger, pour ne pas ternir la couleur de la classe
	local shade = db.classIntensity == "VIVID" and 0.5 or 1
	b.shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, theme.shade[1] * shade), CreateColor(1, 1, 1, theme.shade[2]))
	b.dim:SetAlpha(1 - db.brightness / 100)
	local lowShown = db.lowHealth and not b.isPet
	b.low:SetShown(lowShown)
	if not lowShown then b.low.fill:SetAlpha(0) end
	b.assign:SetColorTexture(ASSIGN_COLOR[1], ASSIGN_COLOR[2], ASSIGN_COLOR[3], 0.95)
	b.assign:SetWidth(math.max(2, math.floor(height / 14)))

	local size = db.fontSize + (theme.fontBonus or 0)
	if b.isPet and db.petSize < 100 then size = math.max(8, size - 2) end -- case plus petite : texte un peu plus petit
	b.name:SetFont(theme.font, size, theme.flags)
	b.name:SetShown(db.showName) -- réglage « Nom du joueur » (vraies cases, mode test, case témoin)
	b.text:SetFont(theme.font, size - 1, theme.flags)
	-- Petits chiffres : couleur du bouclier ou des soins en route du thème, éclaircie pour rester lisible sur la vie
	if db.showAbsorb and db.absorbText then StyleSmallText(b.absorbText, theme, theme.absorb) end
	if db.showIncoming and db.incomingText then StyleSmallText(b.incomingText, theme, theme.incoming) end

	local icon = b.isPet and math.max(10, math.floor(height * 0.30 + 0.5)) or Z.IconSize()
	b.iconSize = icon
	b.rows = b.isPet and Z.AuraRows(width, height) or Z.AuraRows() -- rangées de mes soins et des affaiblissements, à la mesure de la forme (Themes.lua)
	PlaceTexts(b)
	if b.isPet then -- case étroite : le nom et le chiffre ne débordent pas
		b.name:SetWidth(math.min(b.name:GetWidth(), width - 6))
		b.text:SetWidth(math.min(b.text:GetWidth(), width - 6))
	end
	-- Tailles d'origine (Z.AuraRows), fois la taille choisie dans l'éditeur de placement (Z.ElementSize)
	local homes = b.rows.homes
	for _, key in ipairs({ "role", "class", "center", "lowMana" }) do b[key]:SetSize(homes[key].w, homes[key].w) end
	b.leader:SetSize(b.rows.leaderW, b.rows.leaderW)
	PlaceLeader(b) -- après les tailles : il mesure les deux icônes
	local marker = Z.ElementSize("marker", icon)
	b.marker:SetSize(marker, marker)

	Z.HideAuras(b)
	Z.AnchorPrivateAuras(b)
	Z.StyleAuraBoxes(b)
end
Z.StyleButton = Style

-- Sens des clics : dès l'appui ou au relâchement. Le jeu refuse ce réglage en combat sur une case sécurisée
-- (C10) : il n'est donné qu'à une case dont le sens change, et jamais en combat (la fin du combat le reprend).
-- Une touche au survol (SetBindingClick) part selon « useOnKeyDown », ou à défaut selon le réglage « lancer à
-- l'appui » du jeu : posé au même sens que la case, sinon la touche ne lance rien quand les deux diffèrent (C11).
-- Les clics de souris ne lisent pas cet attribut (SecureActionButton_OnClick du jeu).
local function ClickMode()
	return db.castOnDown and "AnyDown" or "AnyUp"
end

-- Une case déjà réglée a-t-elle un autre sens que celui voulu ? (une case créée en combat attend la fin du
-- combat sans compter ici : changer un autre réglage en combat n'affiche donc aucun message)
local function ClickModeChanged()
	local mode = ClickMode()
	for _, b in ipairs(buttons) do
		if b.clickMode and b.clickMode ~= mode then return true end
	end
	return false
end

local function ApplyClickMode()
	if InCombatLockdown() then return end
	local mode = ClickMode()
	for _, b in ipairs(buttons) do
		if b.clickMode ~= mode and b.RegisterForClicks then
			b:RegisterForClicks(mode)
			b:SetAttribute("useOnKeyDown", mode == "AnyDown")
			b.clickMode = mode
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Habillage d'une case : barres, textes, icônes, bordures. Sert aussi aux fausses cases du mode test.
----------------------------------------------------------------------------------------------------
-- Petit chiffre : barre de 0 à 1 invisible ; le cadre qui coupe le texte s'arrête au bout de son remplissage
-- (SetSmallText). Montant nul : remplissage nul, texte coupé en entier.
local function SmallText(parent)
	local switch = CreateFrame("StatusBar", nil, parent)
	switch:SetSize(30, 14)
	switch:SetStatusBarTexture(UI.WHITE)
	switch:SetStatusBarColor(0, 0, 0, 0)
	switch:SetMinMaxValues(0, 1)
	switch:SetValue(0)
	switch:Hide()
	local clip = CreateFrame("Frame", nil, switch)
	clip:SetPoint("TOPLEFT")
	clip:SetPoint("BOTTOMRIGHT", switch:GetStatusBarTexture(), "BOTTOMRIGHT")
	clip:SetClipsChildren(true)
	local text = UI.Text(clip, 9)
	text:SetAllPoints(switch)
	text:SetJustifyH("RIGHT")
	text:SetWordWrap(false)
	return switch, text
end

function Z.BuildVisuals(b)
	b.bg = UI.Tex(b, "BACKGROUND", 0.07, 0.07, 0.09, 1)
	b.bg:SetAllPoints()
	b.bgRound = UI.RoundTex(b, "BACKGROUND") -- le même fond, aux angles arrondis (réglage)
	b.bgRound:SetAllPoints()
	b.bgRound:Hide()

	-- Vie
	local hp = CreateFrame("StatusBar", nil, b)
	hp:SetStatusBarTexture(UI.WHITE) -- la texture doit exister avant d'y accrocher les soins en route
	hp:SetClipsChildren(true)
	b.hp = hp

	-- Soins en route (les miens et ceux des autres), à la suite de la vie
	local incoming = CreateFrame("StatusBar", nil, hp)
	incoming:SetPoint("TOPLEFT", hp:GetStatusBarTexture(), "TOPRIGHT")
	incoming:SetPoint("BOTTOMLEFT", hp:GetStatusBarTexture(), "BOTTOMRIGHT")
	incoming:SetStatusBarTexture(UI.WHITE) -- la texture doit exister avant d'y accrocher la suite
	b.incoming = incoming
	-- Ceux des autres soigneurs, à la suite du mien (réglage incomingSplit)
	local others = CreateFrame("StatusBar", nil, hp)
	others:SetPoint("TOPLEFT", incoming:GetStatusBarTexture(), "TOPRIGHT")
	others:SetPoint("BOTTOMLEFT", incoming:GetStatusBarTexture(), "BOTTOMRIGHT")
	others:SetStatusBarTexture(UI.WHITE)
	others:Hide()
	b.incomingOthers = others
	-- Mes soins sur la durée (hotPrediction) : ce qui reste à rendre, à la suite des soins en route (accroché dans
	-- Style), et par-dessus son début ce que rendent les prochains coups, plus franc
	local hot = CreateFrame("StatusBar", nil, hp)
	hot:SetStatusBarTexture(UI.WHITE)
	hot:Hide()
	b.hot = hot
	local hotNext = CreateFrame("StatusBar", nil, hp)
	hotNext:SetPoint("TOPLEFT", hot, "TOPLEFT")
	hotNext:SetPoint("BOTTOMLEFT", hot, "BOTTOMLEFT")
	hotNext:SetStatusBarTexture(UI.WHITE)
	hotNext:Hide()
	b.hotNext = hotNext
	-- Mon soin qui attend que le joueur soit touché (hotPending), à la suite des précédents : un cadre clair
	local pending = CreateFrame("StatusBar", nil, hp)
	pending:SetPoint("TOPLEFT", hot:GetStatusBarTexture(), "TOPRIGHT")
	pending:SetPoint("BOTTOMLEFT", hot:GetStatusBarTexture(), "BOTTOMRIGHT")
	pending:SetStatusBarTexture(UI.WHITE)
	pending:Hide()
	b.pending = pending
	b.pendingEdges = {}
	for _, side in ipairs({ "TOP", "BOTTOM" }) do
		local edge = pending:CreateTexture(nil, "OVERLAY")
		edge:SetPoint(side .. "LEFT", pending:GetStatusBarTexture(), side .. "LEFT")
		edge:SetPoint(side .. "RIGHT", pending:GetStatusBarTexture(), side .. "RIGHT")
		edge:SetHeight(1)
		Unsnap(edge)
		b.pendingEdges[#b.pendingEdges + 1] = edge
	end
	-- Alerte de gaspillage : deux teintes posées sur mon soin, allumées par un booléen du jeu
	b.overheal = incoming:CreateTexture(nil, "ARTWORK", nil, LAYER.overheal)
	b.overheal:SetColorTexture(unpack(OVERHEAL_COLOR))
	b.overheal:SetAllPoints(incoming:GetStatusBarTexture())
	b.overhealMore = incoming:CreateTexture(nil, "ARTWORK", nil, LAYER.overhealMore)
	b.overhealMore:SetColorTexture(unpack(OVERHEAL_MORE_COLOR))
	b.overhealMore:SetAllPoints(incoming:GetStatusBarTexture())
	Unsnap(b.overheal)
	Unsnap(b.overhealMore)
	-- Voile de mon incantation : se remplit sur mon soin, au rythme du jeu (aucune boucle, SetTimerDuration).
	-- Lancé sur toutes les cases : là où je ne soigne pas, mon soin a une largeur nulle et le voile ne se voit pas.
	local fill = CreateFrame("StatusBar", nil, hp)
	fill:SetAllPoints(incoming:GetStatusBarTexture())
	fill:SetStatusBarTexture(UI.WHITE)
	SetLayer(fill, LAYER.castFill)
	fill:SetStatusBarColor(1, 1, 1, 0.30)
	fill:SetAlpha(0) -- visible seulement pendant mon incantation
	b.castFill = fill
	-- Éclat à l'arrivée de mon soin (healLanding) : mon soin, compté depuis le bout de mon segment vers la gauche.
	-- Quand le soin arrive, la vie avance d'autant et mon segment se vide : ce bout ne bouge pas, l'éclat reste
	-- sur la part de vie que le soin vient de rendre. Joué sur toutes les cases : sans mon soin, largeur nulle.
	local landing = CreateFrame("StatusBar", nil, hp)
	landing:SetPoint("TOPRIGHT", incoming:GetStatusBarTexture(), "TOPRIGHT")
	landing:SetPoint("BOTTOMRIGHT", incoming:GetStatusBarTexture(), "BOTTOMRIGHT")
	landing:SetReverseFill(true)
	landing:SetStatusBarTexture(UI.WHITE)
	SetLayer(landing, LAYER.landing)
	landing:SetStatusBarColor(1, 1, 1, 0.95)
	landing:SetMinMaxValues(0, 1)
	landing:SetValue(0)
	landing:SetAlpha(0)
	-- (allumé un court instant, puis effacé doucement : un éclat trop bref passait inaperçu en jeu)
	local flash = landing:CreateAnimationGroup()
	local hold = flash:CreateAnimation("Alpha")
	hold:SetFromAlpha(1)
	hold:SetToAlpha(1)
	hold:SetDuration(0.25)
	hold:SetOrder(1)
	local fade = flash:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0)
	fade:SetDuration(0.6)
	fade:SetOrder(2)
	flash:SetScript("OnFinished", function() landing:SetAlpha(0) end)
	b.landing, b.landingFlash = landing, flash

	-- Absorption de soins : la part de vie qu'un affaiblissement « mange », au bout de la vie, vers la gauche
	local healAbsorb = CreateFrame("StatusBar", nil, hp)
	healAbsorb:SetPoint("TOPRIGHT", hp:GetStatusBarTexture(), "TOPRIGHT")
	healAbsorb:SetPoint("BOTTOMRIGHT", hp:GetStatusBarTexture(), "BOTTOMRIGHT")
	healAbsorb:SetReverseFill(true)
	b.healAbsorb = healAbsorb

	-- Bouclier d'absorption : bande en bas de la barre de vie
	local absorb = CreateFrame("StatusBar", nil, hp)
	absorb:SetPoint("BOTTOMLEFT")
	absorb:SetPoint("BOTTOMRIGHT")
	absorb:SetHeight(3)
	absorb:SetStatusBarTexture(UI.WHITE) -- la texture doit exister avant d'y poser les rayures
	b.absorb = absorb
	-- Rayures du bouclier : une texture en mosaïque calée sur le remplissage, le jeu la répète à sa taille
	-- (aucun calcul sur la largeur, qui suit une valeur secrète)
	local stripes = absorb:CreateTexture(nil, "ARTWORK", nil, LAYER.stripes)
	-- L'atlas du jeu en mosaïque, à son échelle (comme le bouclier des cadres du jeu) ; sinon l'image d'origine répétée
	local wrap = TextureKitConstants and TextureKitConstants.AddressModeWrap
	local atlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(SHIELD_ATLAS)
	if not (atlas and SetTextureWithAddressModeOptions and wrap and pcall(SetTextureWithAddressModeOptions, stripes,
		SHIELD_ATLAS, TextureKitConstants.IgnoreAtlasSize, wrap, wrap)) then
		stripes:SetTexture(SHIELD_STRIPES, "REPEAT", "REPEAT")
		if stripes.SetHorizTile then stripes:SetHorizTile(true) end
		if stripes.SetVertTile then stripes:SetVertTile(true) end
	end
	stripes:SetAllPoints(absorb:GetStatusBarTexture())
	Unsnap(stripes)
	stripes:Hide()
	b.stripes = stripes
	-- Bouclier plus grand que la vie manquante : trait lumineux au bout de la vie (style « à la suite de la vie »)
	local overAbsorb = hp:CreateTexture(nil, "OVERLAY")
	if not pcall(overAbsorb.SetAtlas, overAbsorb, "RaidFrame-Shield-Overshield") then
		overAbsorb:SetColorTexture(1, 1, 1, 0.9)
	end
	overAbsorb:SetBlendMode("ADD")
	overAbsorb:SetPoint("TOPRIGHT", hp, "TOPRIGHT", 3, 0)
	overAbsorb:SetPoint("BOTTOMRIGHT", hp, "BOTTOMRIGHT", 3, 0)
	overAbsorb:SetWidth(8)
	overAbsorb:Hide()
	b.overAbsorb = overAbsorb

	-- Mana (soigneurs ou tous, selon l'option) : sous la barre de vie
	local power = CreateFrame("StatusBar", nil, b)
	power:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, -1)
	power:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, -1)
	power:SetHeight(3)
	power:SetStatusBarColor(0.25, 0.50, 1)
	power:Hide()
	b.power = power
	b.powerShown = false
	-- Pourcentage de mana, écrit au milieu de la barre (réglage)
	b.powerText = power:CreateFontString(nil, "OVERLAY")
	b.powerText:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
	b.powerText:SetPoint("CENTER", power, "CENTER", 0, 0)
	b.powerText:Hide()

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

	-- Vie basse : liseré rouge fixe à l'intérieur de la case (opacité calculée par le jeu à partir de la vie),
	-- en combat seulement (UpdateLow)
	local low = CreateFrame("Frame", nil, over)
	low:SetAllPoints()
	low:SetFrameLevel(over:GetFrameLevel()) -- sous le cadre de dissipation et les repères des buffs : il ne les cache pas
	low.fill = UI.Border(low, LOW_EDGE)
	low.fill:SetColor(1, 0.08, 0.08, 1)
	low.fill:SetAlpha(0)
	low:Hide()
	b.low = low

	-- Premier plan : nom, vie et signes restent lisibles au-dessus des icônes d'auras
	-- (conteneurs du jeu jusqu'au niveau +4, auras privées des boss au niveau +6)
	local top = CreateFrame("Frame", nil, over)
	top:SetAllPoints()
	top:SetFrameLevel(over:GetFrameLevel() + 5)
	b.top = top

	b.name = UI.Text(top, 11)
	b.name:SetPoint("CENTER", hp, "CENTER", 0, 3)
	b.name:SetWordWrap(false)

	b.text = UI.Text(top, 10)
	b.text:SetPoint("BOTTOM", hp, "BOTTOM", 0, 4)
	b.text:SetWordWrap(false)

	-- Petits chiffres du bouclier et des soins en route (SetSmallText)
	b.absorbSwitch, b.absorbText = SmallText(top)
	b.incomingSwitch, b.incomingText = SmallText(top)

	b.role = top:CreateTexture(nil, "ARTWORK")
	b.role:SetPoint("TOPRIGHT", -2, -2)

	b.class = top:CreateTexture(nil, "ARTWORK") -- icône de classe (réglage showClassIcon)
	b.class:SetPoint("LEFT", 3, 0)
	b.class:Hide()

	b.leader = top:CreateTexture(nil, "OVERLAY") -- chef de groupe ou assistant
	b.leader:SetPoint("TOPLEFT", 2, -2)
	b.leader:Hide()

	b.marker = top:CreateTexture(nil, "ARTWORK")
	b.marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	b.marker:SetPoint("CENTER", over, "TOP", 0, -1)
	b.marker:Hide()

	b.center = top:CreateTexture(nil, "OVERLAY")
	b.center:SetPoint("CENTER")
	b.center:Hide()

	-- Mana basse d'un soigneur : une boisson, montrée par la courbe du jeu (UpdatePower)
	b.lowMana = top:CreateTexture(nil, "OVERLAY")
	b.lowMana:SetTexture("Interface\\Icons\\INV_Drink_07")
	b.lowMana:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.lowMana:Hide()

	-- Bordures : thème (toujours), rouge (menace), couleur du type (dissipation possible), blanche (ma cible)
	b.border = UI.Border(over, 1)
	b.threat = UI.Border(over, 1, 1)
	b.threat:SetColor(1, 0.15, 0.15, 1)
	b.threat:Hide()

	-- Barre fine de menace, collée en haut de la vie (réglage)
	b.threatBar = over:CreateTexture(nil, "ARTWORK")
	b.threatBar:SetPoint("TOPLEFT", hp, "TOPLEFT")
	b.threatBar:SetPoint("TOPRIGHT", hp, "TOPRIGHT")
	b.threatBar:SetHeight(2)
	b.threatBar:Hide()
	b.dispel = UI.Border(over, 2)
	b.dispel:Hide()
	-- Voile léger de la couleur du type, posé SOUS le nom et la vie : ils restent toujours lisibles
	b.dispel.fill = UI.Tex(over, "ARTWORK", 1, 1, 1, 1)
	b.dispel.fill:SetAllPoints()
	b.dispel.fill:Hide()
	b.selected = UI.Border(over, 1)
	b.selected:SetColor(1, 1, 1, 1)
	b.selected:SetAlpha(0)

	-- Un de mes joueurs (répartition entre soigneurs) : trait doré au bord gauche de la vie, au-dessus des bordures
	b.assign = top:CreateTexture(nil, "ARTWORK")
	b.assign:SetPoint("TOPLEFT", hp, "TOPLEFT")
	b.assign:SetPoint("BOTTOMLEFT", hp, "BOTTOMLEFT")
	b.assign:Hide()

	b.hots, b.hotBars, b.debuffs, b.defensives = {}, {}, {}, {}
end

-- Dissipation possible : contour et voile de la couleur du type (shown = false : rien).
-- Sur une texture, SetVertexColor remplace aussi l'opacité : le voile reçoit donc la sienne ici,
-- sinon il devient opaque et cache la vie.
function Z.ShowDispel(b, shown, r, g, bl, a)
	if shown then
		b.dispel:SetColor(r, g, bl, a)
		-- couleur venue du jeu en donjon : son opacité peut être secrète (aucun calcul permis), elle vaut alors 1
		b.dispel.fill:SetVertexColor(r, g, bl, issecret(a) and Z.DISPEL_VEIL or (a or 1) * Z.DISPEL_VEIL)
	end
	b.dispel:SetShown(shown)
	b.dispel.fill:SetShown(shown)
end

-- Fond et bordure d'un groupe (réglage « groupPanel ») : posé sous les cases, aux couleurs du thème.
-- Sert aux vrais cadres comme au mode test.
local PANEL_OUTSET = 3

function Z.BuildPanel(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetFrameLevel(parent:GetFrameLevel()) -- les cases, au-dessus, le recouvrent
	panel.bg = UI.Tex(panel, "BACKGROUND")
	panel.bg:SetAllPoints()
	panel.bgRound = UI.RoundTex(panel, "BACKGROUND")
	panel.bgRound:SetAllPoints()
	panel.border = UI.Border(panel, 1)
	panel:Hide()
	return panel
end

-- Place le fond autour de first (coin haut gauche) et last (coin bas droit), puis l'habille
function Z.StylePanel(panel, first, last)
	local theme, rounded = Z:Theme(), db.corners == "ROUND"
	panel:ClearAllPoints()
	panel:SetPoint("TOPLEFT", first, "TOPLEFT", -PANEL_OUTSET, PANEL_OUTSET)
	panel:SetPoint("BOTTOMRIGHT", last or first, "BOTTOMRIGHT", PANEL_OUTSET + ((last or first).petRoom or 0), -PANEL_OUTSET)
	local r, g, bl = theme.bg[1], theme.bg[2], theme.bg[3]
	panel.bg:SetVertexColor(r, g, bl, 0.75)
	panel.bgRound:SetVertexColor(r, g, bl, 0.75)
	panel.bg:SetShown(not rounded)
	panel.bgRound:SetShown(rounded)
	panel.border:SetColor(theme.border[1], theme.border[2], theme.border[3], 0.9)
	panel.border:SetRounded(rounded)
end

-- Une case apparaît ou disparaît : l'étiquette de son groupe suit (pas d'étiquette sur un groupe vide)
local function MembersChanged() if Z.UpdateHandles then Z.UpdateHandles() end end

-- Soin refusé car hors de vue (réglage « losHint ») : le jeu ne dit pas d'avance qu'un joueur est derrière un
-- pilier, mais il le dit quand il refuse le sort. Lyorune retient la case cliquée (clic ou touche au survol),
-- garde ce lien pendant l'incantation qui suit, et pose un œil au centre de cette case pendant 3 secondes.
local LOS_SECONDS, CLICK_WINDOW = 3, 0.5
local clicked, clickedAt, casting, castEndAt = nil, 0, false, nil

local function NoteClick(b, button)
	clicked, clickedAt, casting, castEndAt = b, GetTime(), false, nil
	if db.clickStats then Z:Try("compte des clics", Z.CountClick, Z, button) end -- statistiques de mes clics (Clicks.lua)
end

-- Joueur de la case cliquée dans la même image que ce moment (GetTime ne change pas pendant une image), ou à peine
-- avant : qui reçoit le sort annoncé par le jeu à ce moment (Z.CastReceiver, BuffMemory.lua). Un clic plus tard
-- (pendant l'incantation) ou plus ancien (un clic de ciblage avant une macro) ne compte pas.
local SAME_CLICK = 0.1
function Z.ClickedUnit(at)
	local ago = at - clickedAt
	if clicked and clicked.unit and ago >= 0 and ago <= SAME_CLICK then return clicked.unit end
end

-- Mes incantations : celle qui part juste après un clic sur une case est liée à cette case
local function CastStarted(unit)
	if unit == "player" and clicked then casting = GetTime() - clickedAt <= CLICK_WINDOW end
end

local function CastEnded(unit)
	if unit == "player" and casting then casting, castEndAt = false, GetTime() end
end

function Z.MarkOutOfSight(b)
	if not b or not b.unit or not db.losHint then return end
	b.losUntil = GetTime() + LOS_SECONDS
	UpdateCenter(b)
	C_Timer.After(LOS_SECONDS + 0.05, function()
		if b.losUntil and GetTime() >= b.losUntil then
			b.losUntil = nil
			if b.unit then Z:Try("hors de vue", UpdateCenter, b) end
		end
	end)
end

local function OnGameError(_, message)
	if not clicked or issecret(message) or message ~= SPELL_FAILED_LINE_OF_SIGHT then return end
	local now = GetTime()
	-- refus immédiat (sort instantané ou début d'incantation), ou à la fin d'une incantation partie de ce clic
	if now - clickedAt <= CLICK_WINDOW or casting or (castEndAt and now - castEndAt <= CLICK_WINDOW) then
		Z.MarkOutOfSight(clicked)
	end
end

-- Soin canalisé sur un joueur (réglage « channelMark », Pénitence) : la bande des soins en route du jeu ne montre
-- peut-être pas une canalisation. Quand une canalisation part juste après un clic sur une case (même lien que
-- l'œil hors de vue), un trait à la couleur d'accent des cadres se vide sur cette case au rythme de la
-- canalisation : l'objet durée du jeu (lisible en combat), sinon le début et la fin. Aucune quantité inventée.
-- Jamais pour un soin sans cible (Tranquillité, Z.untargetedNames) ni sur un ennemi. Vaut pour toute
-- canalisation : rien d'écrit par classe.
local channelCell

local function ChannelUpdate(mark)
	if mark.finish then mark:SetValue(math.max(0, mark.finish - GetTime())) end
end

local function ChannelMark(b)
	if b.channel then return b.channel end
	local mark = CreateFrame("StatusBar", nil, b.top)
	mark:SetStatusBarTexture(UI.WHITE)
	mark:SetPoint("TOPLEFT", b.hp, "TOPLEFT", 0, 0)
	mark:SetPoint("TOPRIGHT", b.hp, "TOPRIGHT", 0, 0)
	mark:SetHeight(3)
	mark.bg = UI.Tex(mark, "BACKGROUND", 0, 0, 0, 0.6)
	mark.bg:SetAllPoints()
	mark:Hide()
	b.channel = mark
	return mark
end

local function ChannelStopped()
	local b = channelCell
	channelCell = nil
	if b and b.channel then
		b.channel:SetScript("OnUpdate", nil)
		b.channel.finish = nil
		b.channel:Hide()
	end
end

-- Pose (ou remet à jour, update) le trait sur la case de la canalisation qui commence
local function ChannelStarted(update)
	local b = update and channelCell or clicked
	if not update then
		ChannelStopped()
		if not db.channelMark or not b or not b.unit or GetTime() - clickedAt > CLICK_WINDOW or not b:IsVisible() then return end
	end
	if not b or not b.unit then return end
	local _, _, _, startMS, endMS, _, _, spellID = UnitChannelInfo("player")
	if not issecret(spellID) and spellID then
		local name = C_Spell.GetSpellName(spellID)
		if not issecret(name) and name and Z.untargetedNames and Z.untargetedNames[name] then return end
	end
	local enemy = UnitCanAttack and UnitCanAttack("player", b.unit)
	if not issecret(enemy) and enemy then return end
	local mark = ChannelMark(b)
	local color = UI.frameAccent
	mark:SetStatusBarColor(color[1], color[2], color[3], 1)
	local duration = UnitChannelDuration and UnitChannelDuration("player")
	local readable = not issecret(startMS) and not issecret(endMS) and startMS and endMS and endMS > startMS
	mark.finish = nil
	mark:SetScript("OnUpdate", nil)
	if duration and mark.SetTimerDuration and Enum.StatusBarInterpolation and Enum.StatusBarTimerDirection then
		mark:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
	elseif readable then
		mark.finish = endMS / 1000
		mark:SetMinMaxValues(0, (endMS - startMS) / 1000)
		ChannelUpdate(mark)
		mark:SetScript("OnUpdate", ChannelUpdate) -- seulement le temps de la canalisation, trait visible
	else
		return
	end
	channelCell = b
	mark:Show()
end
Z.ChannelCell = function() return channelCell end -- pour les tests

-- Familier collé à son maître (C26, modèle LyoruneOwnerTemplate de Pets.xml) : le jeu le montre seulement s'il
-- existe, en suivant l'unité que le code sécurisé lui donne. Confié au jeu hors combat seulement : une case créée en
-- plein combat attend la fin du combat (petsAfterCombat).
local petsAfterCombat
local function WatchPet(pet)
	if InCombatLockdown() then petsAfterCombat = true return end
	if db.pets ~= "OFF" then
		RegisterUnitWatch(pet)
	else
		UnregisterUnitWatch(pet)
		pet:Hide()
	end
end
Z:On("PLAYER_REGEN_ENABLED", function()
	if not petsAfterCombat then return end
	petsAfterCombat = false
	for _, b in ipairs(buttons) do
		if b.owner then WatchPet(b) end
	end
end)

-- Création d'une case : le jeu crée le bouton sécurisé, Lyorune l'habille.
local function InitButton(h, name)
	local b = _G[name]
	if not b or b.hp then return end
	buttons[#buttons + 1] = b
	if h and h.def and h.def.key == "pets" then b.isPet = true end -- colonne des familiers du raid
	Z.BuildVisuals(b)

	b:SetScript("OnEvent", OnEvent)
	b:HookScript("OnAttributeChanged", OnAttributeChanged)
	if b.owner then -- avant UpdateAll : ses événements d'abord
		b:HookScript("OnShow", PetShown)
		b:HookScript("OnHide", PetHidden)
	end
	b:HookScript("OnShow", ShownAgain)
	b:HookScript("OnShow", MembersChanged)
	b:HookScript("OnHide", MembersChanged)
	b:HookScript("OnEnter", OnEnter)
	b:HookScript("OnLeave", OnLeave)
	b:HookScript("OnClick", NoteClick) -- après le clic, sans toucher au sort lancé

	Style(b)
	ApplyClickMode() -- en combat, attend la fin du combat
	Z:RegisterExternalClicks(b)
	OnAttributeChanged(b, "unit", b:GetAttribute("unit"))

	local pet = b.zPet -- sa case de familier, si le cadre en porte (cadre « Groupe », Pets.xml)
	if pet and not pet.hp then
		pet.isPet, pet.owner = true, b
		b.petCell = pet
		if pet.SetIgnoreParentAlpha then pet:SetIgnoreParentAlpha(true) end -- sa portée, pas celle de son maître
		InitButton(h, pet:GetName())
		WatchPet(pet)
	end
end

----------------------------------------------------------------------------------------------------
-- Les cadres. Chacun est un en-tête sécurisé du jeu, qui crée et range une case par joueur, même en plein
-- combat (aucun calcul de placement côté addon).
--   Seul ou en groupe : un seul cadre, « Groupe ».
--   En raid : un cadre par groupe (1 à 8), ou par rôle en rangement par rôle, chacun avec son étiquette.
-- Le jeu choisit lui-même lesquels afficher (règle de visibilité), même si le raid se forme en plein combat.
-- Les étiquettes servent de poignées : n'importe quel numéro de groupe déplace tout le cadre principal.
----------------------------------------------------------------------------------------------------
local RAID_GROUPS = 8
local LABEL_SPACE = 14 -- place gardée au-dessus des cases pour les étiquettes
local ROLE_LABELS = { TANK = "Tanks", HEALER = "Soigneurs", DAMAGER = "Dégâts", NONE = "Sans rôle" }

local frameDefs = {
	{ key = "main", name = "LyoruneHeader", template = "SecureGroupHeaderTemplate", pos = "pos", label = "Groupe" },
}
for i = 1, RAID_GROUPS do
	frameDefs[#frameDefs + 1] = { key = "raid" .. i, raid = i, name = "LyoruneRaid" .. i, template = "SecureGroupHeaderTemplate", pos = "pos" }
end
frameDefs[#frameDefs + 1] = { key = "tanks", name = "LyoruneTanks", template = "SecureGroupHeaderTemplate", pos = "tankPos", label = "Tanks", option = "showTanks", always = true }
-- Joueurs épinglés : un en-tête du jeu qui ne montre que les noms de la liste (attribut « nameList »). Le jeu
-- range lui-même ces joueurs quand ils rejoignent le groupe, même en combat ; la liste ne change que hors combat.
frameDefs[#frameDefs + 1] = { key = "pinned", name = "LyorunePinned", template = "SecureGroupHeaderTemplate", pos = "pinnedPos", label = "Épinglés", always = true }
-- Familiers (C26) : seul ou en groupe, chacun est collé à son maître (Pets.xml). En raid, une colonne
-- « Familiers » collée à droite des groupes (sous la première ligne si les groupes sont en lignes), qui les suit :
-- son étiquette déplace tout le cadre principal.
frameDefs[#frameDefs + 1] = { key = "pets", name = "LyorunePets", template = "SecureGroupPetHeaderTemplate", pos = "pos", label = "Familiers" }
-- Cadre « Cible » (#25) : trois cases fixes, chacune avec son interrupteur. Ce n'est pas un en-tête de groupe :
-- Lyorune crée lui-même les trois boutons sécurisés, et le jeu les montre ou les cache selon que l'unité existe.
frameDefs[#frameDefs + 1] = { key = "extra", extra = true, name = "LyoruneExtra", template = "SecureHandlerStateTemplate", pos = "extraPos", label = "Cible", always = true }
local EXTRA_SLOTS = {
	{ unit = "target", option = "showTarget" },
	{ unit = "targettarget", option = "showTargetTarget" }, -- aucun événement du jeu pour elle : revue avec la portée
	{ unit = "focus", option = "showFocus" },
}
local extraButtons = {}

local raidHeaders = {}
local anchors = {}   -- un point d'attache invisible par position enregistrée (cadre principal, tanks, épinglés...)
local unlockNote     -- mention discrète « déverrouillé »

-- La première ligne nomme Lyorune : le jeu la cite si ce code échoue, et le journal d'erreurs la reconnaît.
local CONFIG_SNIPPET = [[-- Lyorune
	local header = self:GetParent()
	self:SetWidth(header:GetAttribute("z-width"))
	self:SetHeight(header:GetAttribute("z-height"))
	self:SetAttribute("*type1", "target")
	self:SetAttribute("*type2", "togglemenu")
	self:SetAttribute("toggleForVehicle", true)
	self:SetAttribute("ping-receiver", header:GetAttribute("z-ping"))
	local pet -- case du familier collée à droite (cadre « Groupe », Pets.xml)
	local kids = newtable(self:GetChildren())
	for i = 1, #kids do
		if kids[i]:GetAttribute("z-pet") then pet = kids[i] end
	end
	if pet then
		pet:SetWidth(header:GetAttribute("z-petwidth") or 30)
		pet:SetHeight(header:GetAttribute("z-petheight") or 16)
		pet:ClearAllPoints()
		pet:SetPoint("LEFT", self, "RIGHT", header:GetAttribute("z-petgap") or 0, 0)
		pet:SetAttribute("*type1", "target")
		pet:SetAttribute("*type2", "togglemenu")
	end
	for i = 1, header:GetAttribute("z-count") or 0 do
		self:SetAttribute(header:GetAttribute("z-key" .. i), header:GetAttribute("z-value" .. i))
		if pet then pet:SetAttribute(header:GetAttribute("z-key" .. i), header:GetAttribute("z-value" .. i)) end
	end
	header:CallMethod("InitButton", self:GetName())
]]
-- Attention : dans ce code, le jeu refuse tout attribut dont le nom commence par « _ » (erreur « Invalid attribute
-- name », et plus aucune case n'est créée). Les attributs _onenter et _onleave des nouvelles cases passent donc par
-- la liste « _initialAttributeNames » de l'en-tête, que le jeu recopie lui-même (voir CreateHeader et Clicks.lua).

----------------------------------------------------------------------------------------------------
-- Verrou : libre, verrouillé, ou déplaçable en maintenant Alt, Ctrl ou Maj. Jamais en combat.
----------------------------------------------------------------------------------------------------
local MODIFIERS = { ALT = "IsAltKeyDown", CTRL = "IsControlKeyDown", SHIFT = "IsShiftKeyDown" }
local MODIFIER_NAMES = { ALT = "Alt", CTRL = "Ctrl", SHIFT = "Maj" }

local function CanMove()
	if InCombatLockdown() then return false end
	if db.lockMode == "FREE" then return true end
	local check = MODIFIERS[db.lockMode]
	return check and _G[check]() or false
end

-- Le jeu montre toujours ses cases à la suite, de la première à la dernière occupée : la première suffit
local function Occupied(h)
	local child = h:GetAttribute("child1")
	return child ~= nil and child:IsShown()
end

-- Étiquette d'un cadre : visible si l'option est cochée, ou le temps de déplacer les cadres
local function UpdateHandle(h)
	local handle = h.handle
	local movable = CanMove()
	local wanted = (db.showGroupLabels or movable) and h.labelText ~= nil
	local occupied = Occupied(h)
	if wanted and not h.def.always then wanted = occupied end
	handle:SetShown(wanted)
	h.panel:SetShown(db.groupPanel and occupied)
	handle:EnableMouse(db.lockMode ~= "LOCKED")
	handle.line:SetShown(movable)
end

local function UpdateHandles()
	if not db then return end
	local mainShown = false
	for _, h in ipairs(Z.headers) do
		UpdateHandle(h)
		if h.def.pos == "pos" and h.handle:IsVisible() then mainShown = true end
	end
	if unlockNote then
		unlockNote:SetShown(mainShown and db.lockMode == "FREE" and not InCombatLockdown() and not Z.previewActive)
	end
end
Z.UpdateHandles = UpdateHandles

local function GetAnchor(key)
	local anchor = anchors[key]
	if not anchor then
		anchor = CreateFrame("Frame", nil, UIParent)
		anchor:SetSize(1, 1)
		anchor:SetMovable(true)
		anchor:SetClampedToScreen(true)
		anchors[key] = anchor
	end
	return anchor
end

local function CreateHandle(h, def)
	local handle = CreateFrame("Frame", def.name .. "Label", h)
	handle:SetHeight(12)
	handle:SetPoint("BOTTOMLEFT", h, "TOPLEFT", 0, 2)
	handle.text = UI.Text(handle, 10)
	handle.text:SetAllPoints()
	handle.text:SetWordWrap(false)
	handle.text:SetTextColor(UI.frameAccent[1], UI.frameAccent[2], UI.frameAccent[3])
	handle.line = UI.Tex(handle, "ARTWORK", UI.frameAccent[1], UI.frameAccent[2], UI.frameAccent[3], 0.6) -- souligné : déplaçable
	handle.line:SetPoint("BOTTOMLEFT", 6, -1)
	handle.line:SetPoint("BOTTOMRIGHT", -6, -1)
	handle.line:SetHeight(1)
	Z.MakeDragHandle(handle, def.pos, function() return h.labelText or "" end)
	handle:Hide()
	return handle
end

-- Rend un cadre (étiquette « Groupe », bandeau du mode test) capable de déplacer une position enregistrée,
-- selon le verrou choisi (libre, verrouillé, ou avec Alt, Ctrl ou Maj). title() donne le titre de l'infobulle.
function Z.MakeDragHandle(handle, pos, title)
	handle:RegisterForDrag("LeftButton")
	handle:SetScript("OnDragStart", function()
		if InCombatLockdown() then return Z:Print(L["impossible de déplacer les cadres en combat."]) end
		if not CanMove() then return end
		local anchor = anchors[pos]
		anchor.moving = true
		anchor:StartMoving()
	end)
	handle:SetScript("OnDragStop", function()
		local anchor = anchors[pos]
		if not anchor.moving then return end -- glissement refusé : rien à arrêter
		anchor.moving = false
		if InCombatLockdown() then return end -- le combat a commencé pendant le glissement : le jeu a déjà figé le cadre
		anchor:StopMovingOrSizing()
		local point, _, _, x, y = anchor:GetPoint(1)
		Z.char[pos] = { point, x, y }
		if Z.QueueBuffPanel then Z:QueueBuffPanel() end -- les buffs manquants collés aux cadres suivent
	end)
	handle:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then Z:ToggleOptions() end
	end)
	handle:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(title(), UI.frameAccent[1], UI.frameAccent[2], UI.frameAccent[3])
		if db.lockMode == "FREE" then
			GameTooltip:AddLine(L["Glisser : déplacer les cadres"], 1, 1, 1)
		elseif MODIFIERS[db.lockMode] then
			GameTooltip:AddLine(L["Maintenir %s et glisser : déplacer les cadres"]:format(L[MODIFIER_NAMES[db.lockMode]]), 1, 1, 1)
		end
		GameTooltip:AddLine(L["Clic droit : options"], 1, 1, 1)
		GameTooltip:Show()
	end)
	handle:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function CreateHeader(def)
	local h = CreateFrame("Frame", def.name, UIParent, def.template)
	h:Hide() -- on règle tout avant d'afficher : les cases sont créées au premier affichage
	h.def = def
	h.labelText = def.label and L[def.label]
	h.handle = CreateHandle(h, def)
	h.panel = Z.BuildPanel(h)
	GetAnchor(def.pos)
	-- Une erreur pendant l'habillage d'une case est écrite au journal, même si un autre addon a pris la main
	-- sur le gestionnaire d'erreurs du jeu.
	h.InitButton = function(self, name) Z:Try("habillage d'une case", InitButton, self, name) end
	h:HookScript("OnShow", UpdateHandles)
	h:HookScript("OnHide", UpdateHandles)
	Z.headers[#Z.headers + 1] = h
	if def.extra then return h end -- ses cases sont créées à la première demande (LayoutExtra)
	-- Les cases du cadre « Groupe » portent la case de leur familier (Pets.xml)
	local owner = def.key == "main" and ",LyoruneOwnerTemplate" or ""
	h:SetAttribute("template", "SecureUnitButtonTemplate,SecureHandlerEnterLeaveTemplate" .. PING_TEMPLATE .. owner)
	h:SetAttribute("showPlayer", true)
	h:SetAttribute("showParty", not def.raid and def.key ~= "pets") -- familiers hors raid : collés à leur maître
	h:SetAttribute("showRaid", def.key ~= "main") -- en raid, les cadres par groupe prennent le relais
	h:SetAttribute("sortMethod", "INDEX")
	h:SetAttribute("initialConfigFunction", CONFIG_SNIPPET)
	h:SetAttribute("_initialAttributeNames", "_onenter,_onleave")
	h:SetAttribute("_initialAttribute-_onenter", "self:ClearBindings()")
	h:SetAttribute("_initialAttribute-_onleave", "self:ClearBindings()")
	if def.key == "tanks" then h:SetAttribute("roleFilter", "TANK") end
	if def.raid then
		raidHeaders[def.raid] = h
		-- Un groupe vide ne prend aucune place (sinon le jeu lui laisse celle d'une case) : les groupes suivants et la
		-- colonne des familiers se collent aux groupes remplis
		h:SetAttribute("minWidth", 0.1)
		h:SetAttribute("minHeight", 0.1)
	end
	return h
end

-- Quand afficher un cadre. La règle est confiée au jeu, qui l'applique seul, même en plein combat :
-- Lyorune n'a donc jamais à afficher ou masquer un cadre pendant un combat (le jeu le lui interdirait).
-- En mode test, les vrais cadres reviennent d'eux-mêmes si un combat commence.
local function VisibilityRule(def)
	if Z.framesHidden then return "hide" end -- masqués par le joueur (raccourci ou /lyorune cadres), même en combat
	local combat = Z.previewActive or db.visibility == "COMBAT"
	if def.raid or def.key == "pets" then
		return combat and "[group:raid,combat] show; hide" or "[group:raid] show; hide"
	elseif def.key == "main" then
		return combat and "[group:raid] hide; [combat] show; hide" or "[group:raid] hide; show"
	end
	return combat and "[combat] show; hide" or "show"
end

-- Cadre « Cible » : seules les cases cochées prennent une place, côte à côte (en lignes) ou l'une sous l'autre.
-- Chaque case cochée est confiée au jeu (RegisterUnitWatch) : il la montre quand l'unité existe, même en combat.
-- Renvoie true si au moins une case est cochée.
-- Une case du cadre « Cible », créée hors combat la première fois qu'elle est cochée. Mêmes réglages que les cases
-- du jeu (CONFIG_SNIPPET) : clic gauche cible, clic droit menu, puis mes clics (Z:ApplyClicks).
local function CreateExtraButton(h, i)
	local b = CreateFrame("Button", h.def.name .. i, h, "SecureUnitButtonTemplate,SecureHandlerEnterLeaveTemplate" .. PING_TEMPLATE)
	b.extra = true
	b:SetAttribute("*type1", "target")
	b:SetAttribute("*type2", "togglemenu")
	b:Hide()
	h:SetAttribute("child" .. i, b) -- comme un en-tête : l'étiquette et le diagnostic retrouvent ses cases
	extraButtons[i] = b
	h:InitButton(b:GetName())
	b:SetAttribute("unit", EXTRA_SLOTS[i].unit)
	if Z.ApplyClicks then Z:ApplyClicks() end
	return b
end

local function LayoutExtra(h, width, height)
	local count = 0
	for i, slot in ipairs(EXTRA_SLOTS) do
		local b = extraButtons[i]
		if db[slot.option] then
			b = b or CreateExtraButton(h, i)
			b:ClearAllPoints()
			b:SetSize(width, height)
			local x, y = 0, 0
			if db.horizontal then x = count * (width + db.spacing) else y = -count * (height + db.spacing) end
			b:SetPoint("TOPLEFT", h, "TOPLEFT", x, y)
			RegisterUnitWatch(b)
			count = count + 1
		elseif b then -- décochée : le jeu ne la montre plus
			UnregisterUnitWatch(b)
			b:Hide()
		end
	end
	local across = math.max(count, 1)
	if db.horizontal then
		h:SetSize(across * width + (across - 1) * db.spacing, height)
	else
		h:SetSize(width, across * height + (across - 1) * db.spacing)
	end
	return count > 0
end

-- Toutes les classes du jeu, dans l'ordre du jeu : lues au jeu lui-même, une classe ajoutée est donc rangée
-- sans rien changer ici. Le jeu ne montre pas un joueur dont la classe manque à la liste : elle doit être complète.
local classOrder
local function ClassOrder()
	if classOrder then return classOrder end
	local list, seen = {}, {}
	local function add(class)
		if class and not seen[class] then seen[class] = true; list[#list + 1] = class end
	end
	for i = 1, (GetNumClasses and GetNumClasses() or 0) do add(select(2, GetClassInfo(i))) end
	for _, class in ipairs(CLASS_SORT_ORDER or {}) do add(class) end
	for class in pairs(Z.dispelSpells or {}) do add(class) end -- classes décrites dans Data.lua
	classOrder = table.concat(list, ",")
	return classOrder
end
Z.ClassOrder = ClassOrder

-- Ordre des joueurs dans un cadre, confié au jeu : il le tient à jour seul, même en plein combat.
-- groupBy et groupingOrder rangent d'abord par paquets (groupe, rôle ou classe), sortMethod trie dans chaque paquet.
local function ApplySort(h, groupBy, groupingOrder)
	local sort = db.sortOrder
	if sort == "CLASS" and not groupBy then groupBy, groupingOrder = "CLASS", ClassOrder() end
	h:SetAttribute("groupBy", groupBy)
	h:SetAttribute("groupingOrder", groupingOrder)
	h:SetAttribute("sortMethod", sort == "INDEX" and "INDEX" or "NAME")
end

-- Réglages d'un cadre (taille, tri, filtres, sens) : appelée pendant que le cadre du jeu attend (_ignore).
-- Renvoie true si le cadre doit être affiché.
local function HeaderAttributes(h, width, height, petWidth, petHeight, grid, perColumn, roles)
	local def = h.def
	local enabled = not def.option or db[def.option]
	if def.extra then enabled = LayoutExtra(h, width, height) end
	if def.label then h.labelText = L[def.label] end -- suit le changement de langue
	local pets = def.key == "pets"
	h:SetAttribute("z-width", pets and petWidth or width)
	h:SetAttribute("z-height", pets and petHeight or height)
	h:SetAttribute("z-petwidth", petWidth) -- case du familier en face de son maître (cadre « Groupe », CONFIG_SNIPPET)
	h:SetAttribute("z-petheight", petHeight)
	h:SetAttribute("z-petgap", Z.PetGap())
	-- « Groupe » ne montre jamais plus de 5 joueurs : pas de colonnes en trop, donc pas de cases en trop
	h:SetAttribute("maxColumns", math.ceil((def.key == "main" and 5 or 40) / perColumn))
	if def.key == "main" then
		if db.layout == "ROLE" then -- le rôle d'abord ; « par classe » devient alors « par nom » dans chaque rôle
			ApplySort(h, "ASSIGNEDROLE", db.roleOrder .. ",NONE")
		elseif db.sortOrder == "INDEX" then
			ApplySort(h, "GROUP", "1,2,3,4,5,6,7,8")
		else
			ApplySort(h)
		end
		h:SetAttribute("showSolo", db.showSolo)
	elseif def.raid then
		if grid then -- une seule grille pour tout le raid : le premier cadre prend tout le monde
			enabled = def.raid == 1
			h:SetAttribute("roleFilter", nil)
			h:SetAttribute("groupFilter", "1,2,3,4,5,6,7,8")
			if db.sortOrder == "INDEX" then ApplySort(h, "GROUP", "1,2,3,4,5,6,7,8") else ApplySort(h) end
			h.labelText = L["Raid"]
		elseif roles then -- un cadre par rôle, dans l'ordre choisi
			local role = roles[def.raid]
			enabled = role ~= nil
			h:SetAttribute("groupFilter", nil)
			h:SetAttribute("roleFilter", role)
			ApplySort(h)
			h.labelText = role and L[ROLE_LABELS[role]]
		else
			h:SetAttribute("roleFilter", nil)
			h:SetAttribute("groupFilter", tostring(def.raid))
			h:SetAttribute("maxColumns", 1)
			ApplySort(h)
			h.labelText = L["Groupe %d"]:format(def.raid)
		end
	elseif def.key == "pets" then -- dans l'ordre des groupes de leurs maîtres, tenu à jour par le jeu même en combat
		enabled = db.pets == "RAID"
		h:SetAttribute("groupBy", "GROUP")
		h:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		h:SetAttribute("sortMethod", "INDEX")
	elseif def.key == "tanks" then
		ApplySort(h)
	elseif def.key == "pinned" then
		local names = Z:PinnedList()
		enabled = db.showPinned and #names > 0
		h:SetAttribute("groupFilter", nil)
		h:SetAttribute("roleFilter", nil)
		h:SetAttribute("nameList", table.concat(names, ","))
		ApplySort(h)
	end
	h:SetAttribute("z-ping", db.pingCells or nil) -- cases créées plus tard, même en combat (CONFIG_SNIPPET)
	-- Familiers : la place de leur colonne à droite de chaque joueur du cadre « Groupe »
	local petRoom = def.key == "main" and db.pets ~= "OFF" and Z.PetGap() + petWidth or 0
	h.petRoom = petRoom -- au-delà du bord droit du cadre (fond de groupe, barre sous les cadres)
	if db.horizontal then
		h:SetAttribute("point", "LEFT")
		h:SetAttribute("xOffset", db.spacing + petRoom)
		h:SetAttribute("yOffset", 0)
		h:SetAttribute("columnAnchorPoint", "TOP")
		-- colonne des familiers du raid : chaque rangée à la hauteur d'une ligne de joueurs
		h:SetAttribute("columnSpacing", db.spacing + (pets and height - petHeight or 0))
	else
		h:SetAttribute("point", "TOP")
		h:SetAttribute("xOffset", 0)
		-- colonne des familiers du raid : chacun à la hauteur d'une ligne de joueurs
		h:SetAttribute("yOffset", -db.spacing - (pets and height - petHeight or 0))
		h:SetAttribute("columnAnchorPoint", "LEFT")
		h:SetAttribute("columnSpacing", db.spacing + petRoom)
	end
	h:SetAttribute("unitsPerColumn", perColumn) -- 5 par groupe, ou la taille choisie en grille
	return enabled
end

-- Nombre de cases qu'un cadre peut avoir à montrer dans la disposition choisie. Le jeu crée une case quand un joueur
-- arrive ; en combat, cette création est refusée (« action bloquée ») et le joueur reste sans case jusqu'à la fin du
-- combat. Toutes ces cases sont donc créées d'avance, hors combat : 5 pour « Groupe » et pour un groupe de raid, une
-- par nom épinglé, un raid entier pour la grille, un rôle, les tanks et les familiers.
local function CellsNeeded(def, grid, roles)
	if def.key == "main" or (def.raid and not grid and not roles) then return 5 end
	if def.key == "pinned" then return #Z:PinnedList() end
	return MAX_RAID_MEMBERS or 40
end

-- Crée d'avance les cases d'un cadre visible ou caché : le jeu en prépare autant que de places quand la liste des
-- joueurs commence avant le premier (startingIndex négatif), puis le cadre revient à la normale. Rien n'est noté :
-- si l'interface était masquée (Alt+Z) ou si le jeu a refusé, les cases manquent encore et le prochain réglage
-- recommence. Renvoie true si le cadre visible vient d'être replacé.
local function PrepareCells(h, count)
	if count < 1 or InCombatLockdown() or h:GetAttribute("child" .. count) then return end
	local hidden = not h:IsShown()
	local ok, err = pcall(function()
		h:SetAttribute("startingIndex", 1 - count) -- cadre visible : le jeu crée les cases tout de suite
		if hidden then h:Show() end -- cadre caché : il les crée en s'affichant
	end)
	h:SetAttribute("startingIndex", 1) -- toujours, même après une erreur : sinon le cadre resterait vide
	if hidden then
		h:Hide()
		-- cadre caché : ses cases gardaient les joueurs du groupe et écoutaient leurs événements pour rien ;
		-- le jeu leur redonne un joueur quand le cadre apparaît
		local index, child = 1, h:GetAttribute("child1")
		while child do
			child:SetAttribute("unit", nil)
			index = index + 1
			child = h:GetAttribute("child" .. index)
		end
	end
	if not ok then error(err, 0) end
	return not hidden
end

-- Disposition de tous les cadres (C17). Un cadre de groupe du jeu replace toutes ses cases à chaque réglage
-- changé tant qu'il est visible : avec une vingtaine de réglages par cadre et 40 joueurs, l'interface gelait, et un
-- cadre de raid sans filtre le temps d'un réglage montrait tout le raid. Chaque cadre attend donc la fin de ses
-- réglages (_ignore), puis se replace une seule fois. Les cases ne perdent jamais leur place : elles ne sont
-- détachées que pendant cette attente, et le replacement a lieu même si un réglage échoue.
local layoutWave = 0
local function ApplyLayout()
	local width, height = Z.CellSize()
	local petWidth, petHeight = Z.PetSize()
	for _, b in ipairs(buttons) do
		if b.isPet then b:SetSize(petWidth, petHeight) else b:SetSize(width, height) end
		-- (pas sur un familier collé : son modèle n'est pas du type « signal » du jeu)
		if PING_TEMPLATE ~= "" and not b.owner then b:SetAttribute("ping-receiver", db.pingCells or nil) end
		if b.owner then -- familier collé à droite de son maître (C26)
			b:ClearAllPoints()
			b:SetPoint("LEFT", b.owner, "RIGHT", Z.PetGap(), 0) -- en face de son maître, après un vrai espace
			WatchPet(b)
		end
	end
	local gap = (db.showGroupLabels or db.lockMode == "FREE") and LABEL_SPACE or 0
	local grid = db.layout == "GRID"
	local perColumn = grid and db.gridSize or 5
	local roles
	if db.layout == "ROLE" then
		roles = {}
		for role in (db.roleOrder .. ",NONE"):gmatch("[^,]+") do roles[#roles + 1] = role end
	end

	for key, anchor in pairs(anchors) do
		local pos = Z.char[key]
		anchor:ClearAllPoints()
		anchor:SetPoint(pos[1], UIParent, pos[1], pos[2], pos[3])
	end

	layoutWave = layoutWave + 1
	local lastRaid -- dernier cadre de raid affiché : la colonne des familiers se colle à sa droite
	for _, h in ipairs(Z.headers) do
		local def = h.def
		local wasShown = h:IsVisible()
		h:SetAttribute("_ignore", true)
		-- Le jeu repose ses cases sans retirer leurs anciennes ancres : détachées ici, pendant l'attente, pour qu'un
		-- changement de sens (lignes ou colonnes) ne laisse pas deux ancres contraires
		local i, child = 1, h:GetAttribute("child1")
		while child do
			child:ClearAllPoints()
			i = i + 1
			child = h:GetAttribute("child" .. i)
		end
		local enabled = false
		Z:Try("disposition du cadre " .. tostring(def.key), function()
			enabled = HeaderAttributes(h, width, height, petWidth, petHeight, grid, perColumn, roles)
		end)
		h:SetAttribute("_ignore", nil)

		-- Placement : les cadres de raid se suivent ; un groupe vide ne laisse pas de trou, sauf si chaque groupe
		-- garde sa place : il est alors posé à son rang, que les groupes d'avant soient remplis ou non.
		h:ClearAllPoints()
		local previous = def.raid and raidHeaders[def.raid - 1]
		local apart = db.spacing + (db.groupPanel and 2 * PANEL_OUTSET or 0) -- deux fonds de groupe ne se touchent pas
		local fixed = def.raid and db.keepGroupPlace and db.layout == "GROUP"
		if def.key == "pets" and db.horizontal then -- à droite de la première ligne de groupes
			h:SetPoint("TOPLEFT", anchors[def.pos], "BOTTOMLEFT", perColumn * (width + db.spacing) - db.spacing + Z.PetGap(),
				-gap - math.floor((height - petHeight) / 2))
		elseif def.key == "pets" and lastRaid then -- au milieu de la première ligne de joueurs
			h:SetPoint("TOPLEFT", lastRaid, "TOPRIGHT", Z.PetGap(), -math.floor((height - petHeight) / 2))
		elseif fixed and db.horizontal then
			h:SetPoint("TOPLEFT", anchors[def.pos], "BOTTOMLEFT", 0, -gap - (def.raid - 1) * (height + apart + gap))
		elseif fixed then
			h:SetPoint("TOPLEFT", anchors[def.pos], "BOTTOMLEFT", (def.raid - 1) * (width + apart), -gap)
		elseif previous and db.horizontal then
			h:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -(apart + gap))
		elseif previous then
			h:SetPoint("TOPLEFT", previous, "TOPRIGHT", apart, 0)
		else
			h:SetPoint("TOPLEFT", anchors[def.pos], "BOTTOMLEFT", 0, -gap)
		end
		h.handle:SetWidth(width)
		h.handle.text:SetText(h.labelText or "")
		Z.StylePanel(h.panel, h)
		h.handle:SetPoint("BOTTOMLEFT", h, "TOPLEFT", 0, db.groupPanel and PANEL_OUTSET + 2 or 2)

		if enabled and def.raid then lastRaid = h end
		local replaced = false
		if enabled and not def.extra then
			Z:Try("cases d'avance du cadre " .. tostring(def.key), function()
				replaced = PrepareCells(h, CellsNeeded(def, grid, roles))
			end)
		end
		if enabled then
			local rule = VisibilityRule(def)
			RegisterStateDriver(h, "visibility", rule)
			h:SetShown(SecureCmdOptionParse(rule) == "show") -- tout de suite, sans attendre le prochain contrôle du jeu
		else
			UnregisterStateDriver(h, "visibility")
			h:Hide()
		end
		-- Le seul replacement : un cadre qui vient d'apparaître s'est déjà replacé en s'affichant (le jeu le fait seul),
		-- un cadre caché se replacera quand il apparaîtra
		if wasShown and not replaced and h:IsVisible() then h:SetAttribute("z-layout", layoutWave) end
		h:SetAlpha(db.frameAlpha / 100)
		h:SetScale(db.scale / 100) -- échelle générale : cases, icônes et étiquette grandissent ensemble
	end
	UpdateHandles()
	if Z.FitAllRanks then Z:FitAllRanks() end -- variante « Sur un tank » : un cadre a pu changer de rôle (Clicks.lua)
end

local function BuildCurves()
	healthCurve = healthCurve or ColorCurve(false, {
		0.0, 0.90, 0.15, 0.15, 1,
		0.5, 0.95, 0.80, 0.20, 1,
		1.0, 0.25, 0.80, 0.35, 1,
	})
	-- Soins en route en mode « Vie restante » : teinte de contraste là où la courbe de vie est verte (au-dessus
	-- d'environ 70 %), refaite seulement quand le thème change
	local theme = Z:Theme()
	if theme ~= incomingTheme then
		incomingTheme = theme
		local normal = theme.incoming
		local onGreen = theme.incomingOnGreen or normal
		local function Curve(alpha)
			return ColorCurve(false, {
				0.0, normal[1], normal[2], normal[3], (normal[4] or 1) * alpha,
				0.65, normal[1], normal[2], normal[3], (normal[4] or 1) * alpha,
				0.75, onGreen[1], onGreen[2], onGreen[3], (onGreen[4] or 1) * alpha,
				1.0, onGreen[1], onGreen[2], onGreen[3], (onGreen[4] or 1) * alpha,
			})
		end
		incomingCurve, othersCurve = Curve(1), Curve(OTHERS_ALPHA)
	end
	hideWhenFullCurve = hideWhenFullCurve or ColorCurve(true, {
		0.0, 1, 1, 1, 1,
		1.0, 1, 1, 1, 0,
	})
	-- Bonne santé : estompé à partir du seuil ; pour le chiffre de vie manquante, invisible aussi à 100 %
	local healthy = (tonumber(db.healthyFadeAt) or 90) / 100
	healthyCurve = ColorCurve(true, {
		0.0, 1, 1, 1, 1,
		healthy, 1, 1, 1, HEALTHY_ALPHA,
	})
	healthyDeficitCurve = healthy < 1 and ColorCurve(true, {
		0.0, 1, 1, 1, 1,
		healthy, 1, 1, 1, HEALTHY_ALPHA,
		1.0, 1, 1, 1, 0,
	}) or hideWhenFullCurve
	lowHealthCurve = ColorCurve(true, {
		0.0, 1, 1, 1, 1,
		db.lowHealthAt / 100, 1, 1, 1, 0,
	})
	-- Mana basse d'un soigneur : visible sous le seuil seulement (la mana peut être secrète : jamais comparée)
	lowManaCurve = ColorCurve(true, {
		0.0, 1, 1, 1, 1,
		(tonumber(db.lowManaHealers) or 0) / 100, 1, 1, 1, 0,
	})
	-- Bouclier à la suite de la vie : limité à la vie manquante, pour savoir quand il la dépasse
	if healCalculator and healCalculator.SetDamageAbsorbClampMode and Enum.UnitDamageAbsorbClampMode then
		local modes = Enum.UnitDamageAbsorbClampMode
		local mode = modes.MaximumHealth
		if db.absorbStyle == "FOLLOW" then
			mode = (not db.showIncoming and modes.MissingHealthWithoutIncomingHeals) or modes.MissingHealth
		end
		healCalculator:SetDamageAbsorbClampMode(mode)
	end
end

-- /lyorune diag : état de chaque cadre, pour comprendre un cadre vide sans avoir à deviner
function Z:DiagnoseFrames()
	for _, h in ipairs(Z.headers) do
		-- hors raid, les cadres par groupe restent vides : inutile de les citer ; « Cible » et « Épinglés » seulement s'ils servent
		if (not h.def.raid or IsInRaid()) and not (h.def.extra and not next(extraButtons))
			and not (h.def.key == "pinned" and not next(db.pinned)) then
			local created, shown, dressed = 0, 0, 0
			while h:GetAttribute("child" .. (created + 1)) do
				created = created + 1
				local b = h:GetAttribute("child" .. created)
				if b:IsShown() then shown = shown + 1 end
				if b.hp then dressed = dressed + 1 end
			end
			Z:Print(L["cadre %s : %s, cases créées %d, habillées %d, affichées %d."]:format(h.labelText or h.def.key,
				h:IsShown() and L["affiché"] or L["masqué"], created, dressed, shown))
		end
	end
	Z:SaveFrameState("frameStateDiag") -- relevé détaillé du moment, écrit dans le fichier de sauvegarde au /reload
end

-- Relevé détaillé, rangé dans LyoruneDB.frameState à la connexion et à la déconnexion : il se lit dans le
-- fichier SavedVariables, sans que le joueur ait quoi que ce soit à recopier.
-- Une valeur secrète (transparence réglée par la vie ou la mana) est écrite « secret » : un texte qui la
-- contiendrait deviendrait secret lui aussi, et le journal ne pourrait plus s'afficher (C23).
local function Describe(frame)
	local function call(method, ...)
		local ok, a, b = pcall(frame[method], frame, ...)
		return ok and a, ok and b
	end
	local function text(value) return issecret(value) and "secret" or tostring(value) end
	local width, height = call("GetSize")
	return ("shown=%s visible=%s taille=%sx%s gauche=%s haut=%s alpha=%s echelle=%s points=%s"):format(
		text(call("IsShown")), text(call("IsVisible")), text(width), text(height),
		text(call("GetLeft")), text(call("GetTop")), text(call("GetAlpha")),
		text(call("GetEffectiveScale")), text(call("GetNumPoints")))
end

-- Couches visibles qui couvrent au moins la moitié de la case (C38 : une case recouverte d'une couleur inconnue) :
-- chemin des champs de la case, calque, couleur et opacité vue à l'écran. Tout passe par pcall et « secret ».
local function BigLayers(b, lines)
	local function text(value)
		if issecret(value) then return "secret" end
		return type(value) == "number" and ("%.2f"):format(value) or tostring(value)
	end
	local names = {}
	for key, value in pairs(b) do
		if type(value) == "table" and type(value.GetObjectType) == "function" then names[value] = key end
	end
	local ok, W, H = pcall(b.GetSize, b)
	if not ok or issecret(W) or issecret(H) or not W or W * H <= 0 then return end
	local function Scan(frame, path, depth)
		local function Look(region, name)
			local okSize, w, h = pcall(region.GetSize, region)
			if not okSize or issecret(w) or issecret(h) or not w or w * h < W * H / 2 then return end
			local okShown, visible = pcall(region.IsVisible, region)
			if not okShown or (not issecret(visible) and not visible) then return end -- secrète : décrite quand même (C44)
			local _, r, g, bl, a = pcall(region.GetVertexColor, region)
			local _, alpha = pcall(region.GetEffectiveAlpha, region)
			local _, layer = pcall(region.GetDrawLayer, region)
			lines[#lines + 1] = ("    couche %s : %s %dx%d couleur=%s,%s,%s,%s opacite=%s"):format(name, tostring(layer),
				math.floor(w + 0.5), math.floor(h + 0.5), text(r), text(g), text(bl), text(a), text(alpha))
		end
		local okRegions, regions = pcall(function() return { frame:GetRegions() } end)
		for _, region in ipairs(okRegions and regions or {}) do
			local okType, texture = pcall(region.IsObjectType, region, "Texture")
			if okType and texture then Look(region, path .. "." .. (names[region] or "?")) end
		end
		local okChildren, children = pcall(function() return { frame:GetChildren() } end)
		if depth < 4 and okChildren then
			for _, child in ipairs(children) do Scan(child, path .. "/" .. (names[child] or "cadre"), depth + 1) end
		end
	end
	Scan(b, "case", 0)
end

function Z:FrameState()
	local lines = {
		("%s, Lyorune %s, combat=%s, groupe=%s, raid=%s, membres=%s, joueur existe=%s, cases habillees=%d"):format(
			date("%Y-%m-%d %H:%M:%S"), Z.version, tostring(InCombatLockdown()), tostring(IsInGroup()), tostring(IsInRaid()),
			tostring(GetNumGroupMembers()), tostring(UnitExists("player")), #buttons),
		("reglages : visibility=%s showSolo=%s lockMode=%s frameAlpha=%s test=%s"):format(tostring(db.visibility),
			tostring(db.showSolo), tostring(db.lockMode), tostring(db.frameAlpha), tostring(Z.previewActive)),
	}
	for _, h in ipairs(Z.headers) do
		lines[#lines + 1] = ("cadre %s : %s | showSolo=%s showPlayer=%s showParty=%s showRaid=%s groupBy=%s visibilite=%s"):format(
			h.def.key, Describe(h), tostring(h:GetAttribute("showSolo")), tostring(h:GetAttribute("showPlayer")),
			tostring(h:GetAttribute("showParty")), tostring(h:GetAttribute("showRaid")), tostring(h:GetAttribute("groupBy")),
			tostring(h:GetAttribute("state-visibility")))
		lines[#lines + 1] = "  etiquette : " .. Describe(h.handle)
		local index = 1
		while h:GetAttribute("child" .. index) and index <= 5 do
			local b = h:GetAttribute("child" .. index)
			lines[#lines + 1] = ("  case %d : %s | unit=%s habillee=%s"):format(index, Describe(b),
				tostring(b:GetAttribute("unit")), tostring(b.hp ~= nil))
			if b.hp then lines[#lines + 1] = "    barre de vie : " .. Describe(b.hp) end
			-- liseré de vie basse (C12, C32) : dit si la vie était inconnue (maximum 0) ou vraiment basse
			if b.low then
				local unit = b:GetAttribute("unit")
				local max = unit and UnitHealthMax(unit)
				local veil = b.low.fill:GetAlpha()
				lines[#lines + 1] = ("    vie basse : vie max=%s liseré=%s combat=%s"):format(
					issecret(max) and "secret" or tostring(max), issecret(veil) and "secret" or tostring(veil),
					tostring(fighting))
			end
			if b.hp and b:IsVisible() then BigLayers(b, lines) end
			index = index + 1
		end
		if index == 1 then lines[#lines + 1] = "  aucune case creee par le jeu" end
	end
	return lines
end

function Z:SaveFrameState(key)
	if Z.header then db[key or "frameState"] = Z:FrameState() end
end

-- Raccourci « Afficher ou masquer les cadres » et /lyorune cadres. Hors combat seulement : le jeu interdit de
-- changer la règle de visibilité en combat. Pour cette session : après /reload ou à la connexion, les cadres
-- reviennent (un joueur qui a oublié les avoir masqués ne croit pas l'addon cassé).
function Z:ToggleFramesShown()
	if InCombatLockdown() then return Z:Print(L["les cadres s'affichent ou se masquent hors combat seulement."]) end
	Z.framesHidden = not Z.framesHidden or nil
	Z:Safe("layout", ApplyLayout)
	Z:Print(Z.framesHidden and L["cadres masqués, même en combat. La même touche ou /lyorune cadres les ramène."]
		or L["cadres affichés."])
end

-- Appelé après chaque changement d'option
-- Répartition changée (mon choix, répartition reçue, réglage) : seulement le repère et l'estompage
function Z.RefreshAssign()
	for _, b in ipairs(buttons) do
		if b.unit and b:IsVisible() then UpdateAssign(b) end
	end
	if Z.RefreshPreview then Z:RefreshPreview() end
end

function Z:Refresh()
	Z.shownCache = nil -- affaiblissements « Toujours montrés » relus (Themes.lua)
	-- Thème des fenêtres en premier : il ne dépend pas des cases, une erreur plus bas ne doit pas l'empêcher
	if Z.UI.SkinChanged() then Z:Try("thème des fenêtres", Z.UI.ApplySkin) end
	Z.ForgetPlacementRanges() -- bornes du placement : la taille, la forme ou le thème ont pu changer
	smoothing = db.smooth and SMOOTH or nil
	rangeAlpha = db.rangeAlpha / 100
	BuildCurves()
	Z:Safe("layout", ApplyLayout)
	for _, b in ipairs(buttons) do
		Style(b)
		if b:IsVisible() then UpdateAll(b) end
	end
	if ClickModeChanged() then Z:Safe("sens des clics", ApplyClickMode) end
	if Z.RefreshPreview then Z:RefreshPreview() end
	if Z.RefreshMinimap then Z:RefreshMinimap() end
	if Z.RefreshRunes then Z:RefreshRunes() end
	if Z.RefreshShapes then Z:RefreshShapes() end
	if Z.RefreshPlacement then Z:RefreshPlacement() end
	if Z.QueueBuffPanel then Z:QueueBuffPanel() end
	if Z.RefreshCastIndicator then Z:RefreshCastIndicator() end
	if Z.RefreshHotPrediction then Z:RefreshHotPrediction() end
	if Z.RefreshCooldowns then Z:RefreshCooldowns() end
	if Z.RefreshTotems then Z:RefreshTotems() end
	if Z.RefreshGroupCooldowns then Z:RefreshGroupCooldowns() end
	if Z.RefreshManaEdge then Z:RefreshManaEdge() end
	if Z.RefreshFiveSecondRule then Z:RefreshFiveSecondRule() end
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
	if healCalculator.SetHealAbsorbClampMode and Enum.UnitHealAbsorbClampMode then
		healCalculator:SetHealAbsorbClampMode(Enum.UnitHealAbsorbClampMode.CurrentHealth) -- jamais plus que la vie
	end
	-- Alerte de gaspillage : le premier calculateur dit « dépasse la vie qui manque » ; le second, réglé sur 125 %,
	-- dit « la dépasse de plus d'un quart de la vie ». Sans la fonction du jeu, seul le premier niveau reste.
	if healCalculator.SetIncomingHealOverflowPercent then
		healCalculator:SetIncomingHealOverflowPercent(1.0)
		overCalculator = CreateUnitHealPredictionCalculator()
		if overCalculator.SetIncomingHealClampMode and Enum.UnitIncomingHealClampMode then
			overCalculator:SetIncomingHealClampMode(Enum.UnitIncomingHealClampMode.MissingHealth)
		end
		overCalculator:SetIncomingHealOverflowPercent(1.25)
	end
	BuildCurves() -- refait maintenant que le calculateur existe : il prend la limite du bouclier (réglage absorbStyle)

	for _, def in ipairs(frameDefs) do CreateHeader(def) end
	Z.header = Z.headers[1]
	Z.anchor = anchors.pos

	-- Mention discrète au-dessus des étiquettes tant que les cadres se déplacent librement
	unlockNote = CreateFrame("Frame", nil, UIParent)
	unlockNote:SetSize(120, 10)
	unlockNote:SetPoint("BOTTOMLEFT", Z.anchor, "TOPLEFT", 1, 0)
	unlockNote.text = UI.Text(unlockNote, 9)
	unlockNote.text:SetPoint("BOTTOMLEFT")
	unlockNote.text:SetText(L["déverrouillé"])
	unlockNote.text:SetTextColor(0.6, 0.64, 0.7)
	unlockNote:SetAlpha(0.8)
	unlockNote:Hide()

	ApplyLayout()

	-- Événements communs à toutes les cases
	local function ForVisible(fn)
		return function()
			for _, b in ipairs(buttons) do
				if b.unit and b:IsVisible() then fn(b) end
			end
		end
	end
	local updateAll = ForVisible(UpdateAll)
	-- Un de mes soins sur la durée posé, relu, tombé d'un coup ou fini (Hots.lua) : les cases de ce joueur seulement
	function Z.RedrawHots(key)
		if not db.hotPrediction then return end
		for _, b in ipairs(buttons) do
			if b.unit and b:IsVisible() and Z.PlayerKey(b.unit) == key then UpdateHots(b, UnitHealthMax(b.unit)) end
		end
	end
	local lastFactor = ShrinkFactor()
	-- Le groupe change (C17) : les cases visibles sont redessinées une fois par image ; la taille des cases (option)
	-- n'est revue qu'une fois le groupe stable, pour ne pas tout refaire à chaque joueur qui entre.
	Z:OnRoster(updateAll)
	Z:OnRosterSettled(function()
		local factor = ShrinkFactor()
		if factor ~= lastFactor then
			lastFactor = factor
			Z:Refresh()
		end
	end)
	Z:On("PLAYER_ENTERING_WORLD", updateAll)
	Z:On("PLAYER_ROLES_ASSIGNED", ForVisible(UpdateRole))
	Z.RefreshRoles = ForVisible(UpdateRole) -- rôle tiré des talents, le mien ou annoncé par un druide (Roles.lua)
	Z:On("PARTY_LEADER_CHANGED", ForVisible(UpdateLeader))
	Z:On("PLAYER_TARGET_CHANGED", ForVisible(UpdateTarget))
	-- Cases cible et focalisation : leur unité change de personne sans que la case se cache ni s'affiche
	local function RefreshExtra(...)
		local units = { ... }
		return function(unit)
			if unit and unit ~= "target" then return end -- UNIT_TARGET : seul le changement de cible de ma cible compte
			for _, b in ipairs(extraButtons) do
				for _, wanted in ipairs(units) do
					if b.unit == wanted and b:IsVisible() then UpdateAll(b) end
				end
			end
		end
	end
	Z:On("PLAYER_TARGET_CHANGED", RefreshExtra("target", "targettarget"))
	Z:On("PLAYER_FOCUS_CHANGED", RefreshExtra("focus"))
	Z:On("UNIT_TARGET", RefreshExtra("targettarget"))
	Z:On("RAID_TARGET_UPDATE", ForVisible(UpdateMarker))
	Z:On("INCOMING_SUMMON_CHANGED", ForVisible(UpdateCenter))
	Z.RefreshResBy = ForVisible(UpdateState) -- qui relève qui : une résurrection annoncée ou finie (Comm.lua)
	-- Entrée et sortie de combat : les buffs manquants ne se lisent que hors combat
	Z:On("PLAYER_REGEN_ENABLED", ForVisible(Z.QueueAuras))
	Z:On("PLAYER_REGEN_DISABLED", ForVisible(Z.QueueAuras))
	-- Vie basse : liseré en combat seulement (C32)
	local updateLow = ForVisible(UpdateLow)
	Z:On("PLAYER_REGEN_DISABLED", function() fighting = true updateLow() end)
	Z:On("PLAYER_REGEN_ENABLED", function() fighting = false updateLow() end)
	-- Sortie de combat : la ressource de chacun relue, si une forme a changé pendant une réponse secrète
	Z:On("PLAYER_REGEN_ENABLED", ForVisible(UpdateRole))
	-- Étiquettes : masquées pendant un combat si elles ne servaient qu'au déplacement, revenues ensuite ;
	-- en mode « Alt, Ctrl ou Maj », elles apparaissent le temps de maintenir la touche
	Z:On("PLAYER_REGEN_DISABLED", UpdateHandles)
	Z:On("PLAYER_REGEN_ENABLED", UpdateHandles)
	Z:On("PLAYER_REGEN_ENABLED", ApplyClickMode) -- cases créées pendant le combat (C10)
	Z:On("MODIFIER_STATE_CHANGED", function()
		if MODIFIERS[db.lockMode] then UpdateHandles() end
	end)

	-- Les réponses restent 5 secondes après la fin de l'appel. Un appel relancé entre-temps garde les siennes :
	-- chaque appel a son numéro, et l'effacement prévu pour un appel fini ne touche pas au suivant.
	local readyCheckNumber = 0
	local function ReadyCheck(active)
		return function()
			for _, b in ipairs(buttons) do
				b.readyCheck = active
				if b.unit and b:IsVisible() then UpdateCenter(b) end
			end
		end
	end
	local clearReadyCheck = ReadyCheck(false)
	Z:On("READY_CHECK", function() readyCheckNumber = readyCheckNumber + 1 ReadyCheck(true)() end)
	Z:On("READY_CHECK_CONFIRM", ReadyCheck(true))
	Z:On("READY_CHECK_FINISHED", function()
		local finished = readyCheckNumber
		C_Timer.After(5, function()
			if finished == readyCheckNumber then clearReadyCheck() end
		end)
	end)

	-- Soin refusé car hors de vue : message d'erreur du jeu, et mes incantations pour le relier au bon clic
	Z:On("UI_ERROR_MESSAGE", OnGameError)
	-- Voile de mon incantation sur mon soin en route (réglage castFill) : la durée vient du jeu, qui anime la barre.
	-- Fin, échec ou interruption : le voile s'efface (opacité nulle) ; il repart de zéro à l'incantation suivante.
	local castDuration
	local function CastFill(b)
		if not b.castFill:IsShown() then return end
		if castDuration and b.castFill.SetTimerDuration then
			b.castFill:SetTimerDuration(castDuration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.ElapsedTime)
			b.castFill:SetAlpha(1)
		else
			b.castFill:SetAlpha(0)
		end
	end
	local castFillAll = ForVisible(CastFill)
	local function castFillStart()
		if not (db.showIncoming and db.castFill and UnitCastingDuration and Enum.StatusBarTimerDirection
			and Enum.StatusBarInterpolation) then return end
		castDuration = UnitCastingDuration("player")
		castFillAll()
	end
	local function castFillStop()
		if not castDuration then return end
		castDuration = nil
		castFillAll()
	end
	-- Éclat à l'arrivée de mon soin (healLanding) : mon sort réussit, l'éclat part sur toutes les cases (seule celle
	-- de ma cible a mon soin en route, donc une largeur). La barre reste figée le temps de l'éclat.
	local function PlayLanding(b)
		if b.landing:IsShown() then b.landingFlash:Stop() b.landingFlash:Play() end -- (un 2e soin relance l'éclat)
	end
	local playLandingAll = ForVisible(PlayLanding)
	local landingCount = 0
	local function UpdateLanding(b)
		if not b.landing:IsShown() then return end
		if healCalculator.ResetPredictedValues then healCalculator:ResetPredictedValues() end
		UnitGetDetailedHealPrediction(b.unit, "player", healCalculator)
		b.landing:SetMinMaxValues(0, UnitHealthMax(b.unit))
		b.landing:SetValue((select(2, healCalculator:GetIncomingHeals()))) -- (une seule valeur : le jeu refuse une valeur secrète en 2e argument)
	end
	local refreshLandingAll = ForVisible(UpdateLanding)
	-- Seulement l'incantation qui réussit (même numéro qu'à son début) : pas un bijou ni un sort instantané lancé
	-- pendant elle. Un numéro secret ne se compare pas : l'éclat part alors comme avant.
	local castGUID
	local function landingStart(guid)
		if not (db.showIncoming and db.healLanding) or castGUID == nil then return end
		if not (issecret(guid) or issecret(castGUID)) and guid ~= castGUID then return end
		castGUID = nil
		landingCount = landingCount + 1
		local count = landingCount
		landingFrozen = true
		playLandingAll()
		C_Timer.After(0.9, function() -- (le dernier sort) : les barres reprennent mon soin du moment
			if count ~= landingCount then return end
			landingFrozen = false
			refreshLandingAll()
		end)
	end
	local casts = CreateFrame("Frame") -- mes incantations seulement, pas celles de tout le raid
	for _, event in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_STOP",
		"UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_STOP",
		"UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_SUCCEEDED" }) do
		pcall(casts.RegisterUnitEvent, casts, event, "player")
	end
	-- Un sort refusé pendant une incantation (clic répété) envoie aussi FAILED : l'incantation continue
	local function StillCasting()
		local name = UnitCastingInfo and UnitCastingInfo("player")
		return issecret(name) or name ~= nil
	end
	casts:SetScript("OnEvent", function(_, event, unit, guid)
		if event == "UNIT_SPELLCAST_SUCCEEDED" then return Z:Try(event, landingStart, guid) end
		if event == "UNIT_SPELLCAST_START" then castGUID = guid end
		if event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then -- canalisation retardée : le trait suit
			if channelCell then Z:Try(event, ChannelStarted, true) end
			return
		end
		if event == "UNIT_SPELLCAST_DELAYED" then return Z:Try(event, castFillStart) end -- incantation repoussée
		if event == "UNIT_SPELLCAST_START" then
			Z:Try(event, castFillStart)
		elseif not (event == "UNIT_SPELLCAST_FAILED" and StillCasting()) then
			Z:Try(event, castFillStop)
		end
		if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
			Z:Try(event, CastStarted, unit)
			if event == "UNIT_SPELLCAST_CHANNEL_START" then Z:Try(event, ChannelStarted) end
		else
			Z:Try(event, CastEnded, unit)
			if event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then ChannelStopped() end
		end
	end)

	-- Relevé de l'état des cadres : quelques secondes après la connexion, puis à la déconnexion
	C_Timer.After(6, function() Z:SaveFrameState() end)
	Z:On("PLAYER_LOGOUT", function() Z:SaveFrameState("frameStateLogout") end)

	-- Portée : le seul contrôle périodique de l'addon (2 fois par seconde, coût négligeable)
	-- Le même passage efface peu à peu les icônes de mes soins qui finissent (réglage « hotFade »), et revoit la
	-- case « cible de ma cible », pour laquelle le jeu n'envoie aucun événement.
	-- Mode performance : une fois par seconde seulement.
	local everyCell = ForVisible(function(b)
		if b.unit == "targettarget" then UpdateAll(b) end
		UpdateRange(b)
		if fighting then UpdateLow(b) end -- vie basse : jamais bloquée si le jeu tarde à envoyer un changement de vie (C32)
		if db.hotFade then Z.FadeHots(b) end
	end)
	local ticks = 0
	C_Timer.NewTicker(0.5, function()
		ticks = ticks + 1
		if db.perfMode and ticks % 2 == 0 then return end
		Z:Try("portée", everyCell)
	end)
end

----------------------------------------------------------------------------------------------------
-- Joueurs épinglés (réglage « pinned » : un nom par joueur, « Nom » ou « Nom-Royaume » comme le jeu les écrit)
----------------------------------------------------------------------------------------------------
-- Les noms épinglés, triés : c'est la liste confiée au cadre « Épinglés »
function Z:PinnedList()
	local names = {}
	for name in pairs(db.pinned) do names[#names + 1] = name end
	table.sort(names)
	return names
end

-- Les joueurs du groupe, avec leur nom complet (le royaume s'ajoute pour un joueur d'un autre royaume)
local function MemberNames()
	local units = { "player" }
	if IsInRaid() then
		units = {}
		for i = 1, GetNumGroupMembers() do units[i] = "raid" .. i end
	else
		for i = 1, 4 do units[#units + 1] = "party" .. i end
	end
	local names = {}
	for _, unit in ipairs(units) do
		local name = UnitExists(unit) and GetUnitName(unit, true)
		if name and not issecret(name) then names[#names + 1] = name end
	end
	return names
end

-- Un nom tapé à la main : sans espace ni virgule (la virgule sépare les noms pour le jeu). Si un joueur du groupe
-- porte ce nom, quelle que soit la casse, Lyorune prend son nom exact. Sinon, la première lettre en majuscule.
function Z.CleanPinName(text)
	if type(text) ~= "string" or issecret(text) then return nil end
	text = text:gsub("[,%s%c]", "")
	if text == "" or #text > 60 then return nil end
	local wanted = text:lower()
	for _, name in ipairs(MemberNames()) do
		if name:lower() == wanted or name:match("^[^-]+"):lower() == wanted then return name end
	end
	return text:sub(1, 1):upper() .. text:sub(2)
end

-- Le nom à épingler pour une unité (« target », « raid7 »...), ou nil si ce n'est pas un joueur
local function UnitPinName(unit)
	if not unit or not UnitExists(unit) then return nil end
	local player = UnitIsPlayer(unit)
	if issecret(player) or not player then return nil end
	local name = GetUnitName(unit, true)
	if not name or issecret(name) then return nil end
	return name
end
Z.UnitPinName = UnitPinName

-- Épingle le joueur, ou le retire s'il l'était. Renvoie le message à afficher.
function Z:TogglePin(name)
	if not name then return L["aucun joueur : survolez sa case ou ciblez-le."] end
	local added = not db.pinned[name]
	db.pinned[name] = added or nil
	if added then db.showPinned = true end -- épingler quelqu'un montre le cadre
	Z:Refresh()
	return (added and L["%s épinglé."] or L["%s retiré des épinglés."]):format(name)
end

-- /lyorune epingler [nom] : le nom donné, sinon le joueur de la case survolée, sinon ma cible
function Z:PinCommand(text)
	local name
	if text and text ~= "" then
		name = Z.CleanPinName(text)
	else
		local hovered = Z.hovered and Z.hovered:IsVisible() and Z.hovered.unit
		name = UnitPinName(hovered) or UnitPinName("target")
	end
	Z:Print(Z:TogglePin(name))
end
