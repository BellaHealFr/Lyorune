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
local function ClassColor(unit, extra)
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

-- Chiffre du bouclier (réglage absorbText) : le total de tous les boucliers posés, secret, écrit par le jeu.
-- Pour ne pas afficher « +0 » sans rien comparer, le texte est rangé dans un cadre qui le coupe, accroché au
-- remplissage d'une barre de 0 à 1 : le moindre bouclier la remplit, zéro la laisse vide et le texte disparaît.
local function UpdateAbsorbText(b, absorbs)
	local total = healCalculator.GetTotalDamageAbsorbs and healCalculator:GetTotalDamageAbsorbs() or absorbs
	if total == nil then return end
	b.absorbSwitch:SetValue(total)
	b.absorbText:SetFormattedText("+%s", AbbreviateNumbers(total))
end

-- Soins en route, bouclier, et absorption de soins : trois montants calculés par le jeu, lisibles en combat
local function UpdatePrediction(b)
	if not (db.showIncoming or db.showAbsorb or db.showHealAbsorb) then return end
	local unit = b.unit
	local max = UnitHealthMax(unit)
	UnitGetDetailedHealPrediction(unit, "player", healCalculator)
	b.incoming:SetMinMaxValues(0, max)
	b.incoming:SetValue((healCalculator:GetIncomingHeals()))
	b.absorb:SetMinMaxValues(0, max)
	local absorbs, clamped = healCalculator:GetDamageAbsorbs()
	b.absorb:SetValue(absorbs)
	-- Bouclier plus grand que la vie manquante : le jeu le dit par un booléen (secret), branché sur l'opacité
	if b.overAbsorb:IsShown() and clamped ~= nil then b.overAbsorb:SetAlphaFromBoolean(clamped, 1, 0) end
	if b.absorbSwitch:IsShown() then UpdateAbsorbText(b, absorbs) end
	if healCalculator.GetHealAbsorbs then
		b.healAbsorb:SetMinMaxValues(0, max)
		b.healAbsorb:SetValue((healCalculator:GetHealAbsorbs()))
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

	local r, g, bl = ClassColor(unit, b.extra)
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
			b.name:SetTextColor(1, 1, 1)
		else
			b.name:SetTextColor(r, g, bl)
		end
	end
end

-- Voile de vie basse : quelques battements (environ 3 secondes), relancés à chaque changement de vie. Rien n'est
-- comparé : au-dessus du seuil, le voile est invisible et ses battements ne se voient pas.
Z.LOW_BEATS = 6
function Z.PulseLow(low)
	low.pulse.beats = 0
	if not low.pulse:IsPlaying() then low.pulse:Play() end
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
		end
		if db.lowHealth then
			-- vie maximale lisible à 0 (joueur que le jeu ne connaît pas encore, en chargement) : pas de voile plein
			if not issecret(max) and (tonumber(max) or 0) <= 0 then
				b.low.fill:SetAlpha(0)
			else
				b.low.fill:SetAlpha(UnitHealthPercent(unit, true, lowHealthCurve).a) -- visible sous le seuil seulement
				Z.PulseLow(b.low)
			end
		end
		local fade = db.healthyFade and not b.hovered
		if db.text == "DEFICIT" then
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

local function UpdateName(b)
	b.name:SetText(UnitName(b.unit))
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

local function UpdateRange(b)
	local k = b.assignDim or 1
	local me = UnitIsUnit(b.unit, "player")
	if not issecret(me) and me then SetFar(b, false) return b:SetAlpha(1) end -- je suis toujours à portée de moi-même
	if IsFar(b.unit) then
		SetFar(b, true)
		return b:SetAlpha(math.max(0.1, rangeAlpha * 0.5) * k)
	end
	SetFar(b, false)
	local inRange, checked = UnitInRange(b.unit)
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

local function UpdateAll(b)
	if not b.unit or not UnitExists(b.unit) then return end
	UpdateName(b)
	UpdateState(b)
	UpdateHealth(b)
	UpdateRange(b)
	UpdateThreat(b)
	UpdateRole(b)
	UpdateLeader(b)
	UpdateMarker(b)
	UpdateCenter(b)
	UpdateTarget(b)
	UpdateAssign(b)
	Z.QueueAuras(b)
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
	UNIT_AURA = function(b, _, info) Z.QueueAuras(b) Z.NoteAuraChanges(b, info) end, -- la mise à jour d'abord
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
	if value then
		for event in pairs(unitEvents) do b:RegisterUnitEvent(event, value) end
		if b:IsVisible() then UpdateAll(b) end
	end
	Z.AnchorPrivateAuras(b) -- les auras privées suivent le joueur de la case
	Z.BindAuraBoxes(b) -- les conteneurs d'auras du jeu aussi (Containers.lua)
	if InCombatLockdown() then Z:FitAllRanks() else Z:FitRanks(b) end -- rang choisi : au niveau du nouveau joueur
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
	if not (db.showTooltip or clicks or healers) then return end
	GameTooltip_SetDefaultAnchor(GameTooltip, b)
	if db.showTooltip then
		GameTooltip:SetUnit(b.unit)
	else
		GameTooltip:SetText(UnitName(b.unit) or "", 1, 1, 1)
	end
	if healers then
		GameTooltip:AddLine(L["Soigneur prévu : %s"]:format(table.concat(healers, ", ")), UI.gold[1], UI.gold[2], UI.gold[3])
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
			GameTooltip:AddDoubleLine(line[1], line[2], 0.75, 0.78, 0.85, 1, 1, 1)
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
-- Le marqueur et l'icône centrale suivent aussi l'éditeur de placement. Ces places d'origine sont aussi
-- décrites dans Placement.lua (Origins), qui borne les décalages au bord de la case : à changer ensemble.
-- Largeur du nom et du texte de vie : Z.TextWidth, qui les fait rétrécir quand ils sont poussés vers un bord.
-- Chiffre du bouclier (absorbText) : sur la ligne du texte de vie, dont il suit le décalage de l'éditeur de
-- placement. Barre et Bandeau : au bout du texte de vie, qui recule d'autant ; Tuile et Carré : en bas à droite.
local function AbsorbSize()
	local size = math.max(7, db.fontSize + (Z:Theme().fontBonus or 0) - 2)
	return math.floor(size * 3.4), size + 4
end

local function PlaceAbsorbText(b, inline)
	local switch = b.absorbSwitch
	local width, height = AbsorbSize()
	local dx, dy = Z.Offset("text")
	switch:ClearAllPoints()
	switch:SetSize(width, height)
	if inline then
		switch:SetPoint("RIGHT", b.hp, "RIGHT", b.rows.textX + dx, dy)
	else
		switch:SetPoint("BOTTOMRIGHT", b.hp, "BOTTOMRIGHT", -2 - Z.CornerShift(b, "BOTTOMRIGHT"), 2 + dy)
	end
end

local function PlaceTexts(b, icon)
	local shield = db.showAbsorb and db.absorbText
	if Z:Shape().inline then
		Place(b.role, "role", "LEFT", b.hp, "LEFT", 3, 0)
		Place(b.name, "name", "LEFT", b.hp, "LEFT", b.rows.nameX, 0) -- après l'icône de rôle, à sa taille
		b.name:SetJustifyH("LEFT")
		-- en Bandeau, à gauche du bloc d'icônes (et du chiffre du bouclier)
		Place(b.text, "text", "RIGHT", b.hp, "RIGHT", b.rows.textX - (shield and AbsorbSize() + 2 or 0), 0)
		b.text:SetJustifyH("RIGHT")
		Place(b.leader, "leader", "CENTER", b.role, "TOPRIGHT", 0, 0) -- petit badge sur l'icône de rôle
	else
		Place(b.role, "role", "TOPRIGHT", b, "TOPRIGHT", -2 - Z.CornerShift(b, "TOPRIGHT"), -2)
		-- Accrochés à la barre de vie : ils remontent avec elle quand la barre de mana s'affiche
		Place(b.name, "name", "CENTER", b.hp, "CENTER", 0, 3)
		b.name:SetJustifyH("CENTER")
		Place(b.text, "text", "BOTTOM", b.hp, "BOTTOM", 0, 4)
		b.text:SetJustifyH("CENTER")
		Place(b.leader, "leader", "TOPRIGHT", b.role, "TOPLEFT", -1, 0) -- à gauche de l'icône de rôle
	end
	b.name:SetWidth(Z.TextWidth("name"))
	b.text:SetWidth(Z.TextWidth("text"))
	Place(b.marker, "marker", "CENTER", b.over, "TOP", 0, -1)
	Place(b.center, "center", "CENTER", b.over, "CENTER", 0, 0)
	Place(b.lowMana, "lowMana", "BOTTOMLEFT", b.hp, "BOTTOMLEFT", 2, 2)
	if shield then PlaceAbsorbText(b, Z:Shape().inline) end
end

local function Style(b)
	local theme = Z:Theme()
	local texture = UI.BarTexture()
	local width, height = Z.CellSize()
	local rounded = db.corners == "ROUND"
	local inset = UI.Inset(theme.borderSize, rounded)
	LayoutBars(b)
	b.hp:SetStatusBarTexture(texture)
	b.incoming:SetStatusBarTexture(texture)
	b.incoming:SetStatusBarColor(unpack(theme.incoming))
	b.incoming:SetWidth(width - 2 * inset)
	b.incoming:SetShown(db.showIncoming)
	b.absorb:SetStatusBarTexture(UI.WHITE)
	local follow = db.absorbStyle == "FOLLOW"
	local shield = theme.absorb
	b.absorb:SetStatusBarColor(shield[1], shield[2], shield[3], (shield[4] or 1) * (follow and 0.7 or 1))
	b.absorb:SetShown(db.showAbsorb)
	b.absorb:ClearAllPoints()
	if follow then
		-- À la suite des soins en route (ou de la vie s'ils sont coupés), comme les cadres du jeu
		local after = db.showIncoming and b.incoming:GetStatusBarTexture() or b.hp:GetStatusBarTexture()
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
	for _, veil in ipairs({ b.hover, b.low.fill, b.dispel.fill }) do Cover(veil, rounded and inset or 0) end
	-- Couleurs vives : un relief plus léger, pour ne pas ternir la couleur de la classe
	local shade = db.classIntensity == "VIVID" and 0.5 or 1
	b.shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, theme.shade[1] * shade), CreateColor(1, 1, 1, theme.shade[2]))
	b.dim:SetAlpha(1 - db.brightness / 100)
	b.low:SetShown(db.lowHealth)
	if not db.lowHealth then b.low.fill:SetAlpha(0) end
	b.assign:SetColorTexture(ASSIGN_COLOR[1], ASSIGN_COLOR[2], ASSIGN_COLOR[3], 0.95)
	b.assign:SetWidth(math.max(2, math.floor(height / 14)))

	local size = db.fontSize + (theme.fontBonus or 0)
	b.name:SetFont(theme.font, size, theme.flags)
	b.text:SetFont(theme.font, size - 1, theme.flags)
	if db.showAbsorb and db.absorbText then
		-- Couleur du bouclier du thème, éclaircie pour rester lisible sur la vie
		local shield = theme.absorb
		b.absorbText:SetFont(theme.font, (select(2, AbsorbSize())) - 4, theme.flags)
		b.absorbText:SetTextColor(shield[1] + (1 - shield[1]) * 0.4, shield[2] + (1 - shield[2]) * 0.4, shield[3] + (1 - shield[3]) * 0.4)
	end

	local icon = Z.IconSize()
	b.iconSize = icon
	b.rows = Z.AuraRows() -- rangées de mes soins et des affaiblissements, à la mesure de la forme (Themes.lua)
	PlaceTexts(b, icon)
	-- Tailles d'origine, fois la taille choisie dans l'éditeur de placement (Z.ElementSize, Placement.lua)
	local function Size(region, key, base)
		local size = Z.ElementSize(key, base)
		region:SetSize(size, size)
	end
	Size(b.role, "role", icon - 2)
	Size(b.leader, "leader", Z.BadgeSize(icon))
	Size(b.marker, "marker", icon)
	Size(b.center, "center", icon + 8)
	Size(b.lowMana, "lowMana", icon - 1)

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
	b.incoming = incoming

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
	b.absorb = absorb
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

	-- Vie basse : voile rouge (son opacité est calculée par le jeu à partir de la vie). Il bat quelques fois quand
	-- la vie change (Z.PulseLow), puis reste fixe : plus de clignotement sans fin sur un joueur resté bas.
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
	low.pulse:SetScript("OnLoop", function(self)
		self.beats = (self.beats or 0) + 1
		if self.beats >= Z.LOW_BEATS then self:Stop() end -- Stop remet le voile à pleine opacité
	end)
	low:SetScript("OnShow", function(self) Z.PulseLow(self) end)
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

	-- Chiffre du bouclier : barre de 0 à 1 invisible ; le cadre qui coupe le texte s'arrête au bout de son
	-- remplissage (UpdateAbsorbText). Aucun bouclier : remplissage nul, texte coupé en entier.
	local switch = CreateFrame("StatusBar", nil, top)
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
	b.absorbText = UI.Text(clip, 9)
	b.absorbText:SetAllPoints(switch)
	b.absorbText:SetJustifyH("RIGHT")
	b.absorbText:SetWordWrap(false)
	b.absorbSwitch = switch

	b.role = top:CreateTexture(nil, "ARTWORK")
	b.role:SetPoint("TOPRIGHT", -2, -2)

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
	panel:SetPoint("BOTTOMRIGHT", last or first, "BOTTOMRIGHT", PANEL_OUTSET, -PANEL_OUTSET)
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

-- Création d'une case : le jeu crée le bouton sécurisé, Lyorune l'habille.
local function InitButton(_, name)
	local b = _G[name]
	if not b or b.hp then return end
	buttons[#buttons + 1] = b
	Z.BuildVisuals(b)

	b:SetScript("OnEvent", OnEvent)
	b:HookScript("OnAttributeChanged", OnAttributeChanged)
	b:HookScript("OnShow", UpdateAll)
	b:HookScript("OnShow", MembersChanged)
	b:HookScript("OnHide", MembersChanged)
	b:HookScript("OnEnter", OnEnter)
	b:HookScript("OnLeave", OnLeave)
	b:HookScript("OnClick", NoteClick) -- après le clic, sans toucher au sort lancé

	Style(b)
	ApplyClickMode() -- en combat, attend la fin du combat
	Z:RegisterExternalClicks(b)
	OnAttributeChanged(b, "unit", b:GetAttribute("unit"))
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
frameDefs[#frameDefs + 1] = { key = "pets", name = "LyorunePets", template = "SecureGroupPetHeaderTemplate", pos = "petPos", label = "Familiers", option = "showPets", always = true }
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
local anchors = {}   -- un point d'attache invisible par position enregistrée (cadre principal, tanks, familiers)
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
	for i = 1, header:GetAttribute("z-count") or 0 do
		self:SetAttribute(header:GetAttribute("z-key" .. i), header:GetAttribute("z-value" .. i))
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

local function Members(h)
	local count, index = 0, 1
	local child = h:GetAttribute("child1")
	while child do
		if child:IsShown() then count = count + 1 end
		index = index + 1
		child = h:GetAttribute("child" .. index)
	end
	return count
end

-- Étiquette d'un cadre : visible si l'option est cochée, ou le temps de déplacer les cadres
local function UpdateHandle(h)
	local handle = h.handle
	local movable = CanMove()
	local wanted = (db.showGroupLabels or movable) and h.labelText ~= nil
	local occupied = Members(h) > 0
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
	h:SetAttribute("template", "SecureUnitButtonTemplate,SecureHandlerEnterLeaveTemplate" .. PING_TEMPLATE)
	h:SetAttribute("showPlayer", true)
	h:SetAttribute("showParty", not def.raid)
	h:SetAttribute("showRaid", def.key ~= "main") -- en raid, les cadres par groupe prennent le relais
	h:SetAttribute("sortMethod", "INDEX")
	h:SetAttribute("initialConfigFunction", CONFIG_SNIPPET)
	h:SetAttribute("_initialAttributeNames", "_onenter,_onleave")
	h:SetAttribute("_initialAttribute-_onenter", "self:ClearBindings()")
	h:SetAttribute("_initialAttribute-_onleave", "self:ClearBindings()")
	if def.key == "tanks" then h:SetAttribute("roleFilter", "TANK") end
	if def.raid then raidHeaders[def.raid] = h end
	return h
end

-- Quand afficher un cadre. La règle est confiée au jeu, qui l'applique seul, même en plein combat :
-- Lyorune n'a donc jamais à afficher ou masquer un cadre pendant un combat (le jeu le lui interdirait).
-- En mode test, les vrais cadres reviennent d'eux-mêmes si un combat commence.
local function VisibilityRule(def)
	if Z.framesHidden then return "hide" end -- masqués par le joueur (raccourci ou /lyorune cadres), même en combat
	local combat = Z.previewActive or db.visibility == "COMBAT"
	if def.raid then
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

local function ApplyLayout()
	local width, height = Z.CellSize()
	for _, b in ipairs(buttons) do
		b:ClearAllPoints()
		b:SetSize(width, height)
		if PING_TEMPLATE ~= "" then b:SetAttribute("ping-receiver", db.pingCells or nil) end
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

	for _, h in ipairs(Z.headers) do
		local def = h.def
		local enabled = not def.option or db[def.option]
		if def.extra then enabled = LayoutExtra(h, width, height) end
		if def.label then h.labelText = L[def.label] end -- suit le changement de langue
		h:SetAttribute("z-width", width)
		h:SetAttribute("z-height", height)
		h:SetAttribute("maxColumns", math.ceil(40 / perColumn))
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
		elseif def.key == "pets" then -- un familier n'a pas de classe de joueur : seulement le nom
			h:SetAttribute("groupBy", nil)
			h:SetAttribute("sortMethod", db.sortOrder == "INDEX" and "INDEX" or "NAME")
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
		h:SetAttribute("unitsPerColumn", perColumn) -- 5 par groupe, ou la taille choisie en grille

		-- Placement : les cadres de raid se suivent ; un groupe vide ne laisse pas de trou, sauf si chaque groupe
		-- garde sa place : il est alors posé à son rang, que les groupes d'avant soient remplis ou non.
		h:ClearAllPoints()
		local previous = def.raid and raidHeaders[def.raid - 1]
		local apart = db.spacing + (db.groupPanel and 2 * PANEL_OUTSET or 0) -- deux fonds de groupe ne se touchent pas
		local fixed = def.raid and db.keepGroupPlace and db.layout == "GROUP"
		if fixed and db.horizontal then
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

		if enabled then
			local rule = VisibilityRule(def)
			RegisterStateDriver(h, "visibility", rule)
			h:SetShown(SecureCmdOptionParse(rule) == "show") -- tout de suite, sans attendre le prochain contrôle du jeu
		else
			UnregisterStateDriver(h, "visibility")
			h:Hide()
		end
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
end

-- Relevé détaillé, rangé dans LyoruneDB.frameState à la connexion et à la déconnexion : il se lit dans le
-- fichier SavedVariables, sans que le joueur ait quoi que ce soit à recopier.
local function Describe(frame)
	local function call(method, ...)
		local ok, a, b = pcall(frame[method], frame, ...)
		return ok and a, ok and b
	end
	local width, height = call("GetSize")
	return ("shown=%s visible=%s taille=%sx%s gauche=%s haut=%s alpha=%s echelle=%s points=%s"):format(
		tostring(call("IsShown")), tostring(call("IsVisible")), tostring(width), tostring(height),
		tostring(call("GetLeft")), tostring(call("GetTop")), tostring(call("GetAlpha")),
		tostring(call("GetEffectiveScale")), tostring(call("GetNumPoints")))
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
			-- voile de vie basse (C12) : dit si la vie était inconnue (maximum 0) ou vraiment basse
			if b.low then
				local unit = b:GetAttribute("unit")
				local max = unit and UnitHealthMax(unit)
				local veil = b.low.fill:GetAlpha()
				lines[#lines + 1] = ("    vie basse : vie max=%s voile=%s bat=%s"):format(
					issecret(max) and "secret" or tostring(max), issecret(veil) and "secret" or tostring(veil),
					tostring(b.low.pulse:IsPlaying()))
			end
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
	local casts = CreateFrame("Frame") -- mes incantations seulement, pas celles de tout le raid
	for _, event in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_STOP",
		"UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_STOP" }) do
		pcall(casts.RegisterUnitEvent, casts, event, "player")
	end
	casts:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
			Z:Try(event, CastStarted, unit)
		else
			Z:Try(event, CastEnded, unit)
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
