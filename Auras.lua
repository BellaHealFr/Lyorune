-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Auras.lua : ce qui s'affiche sur une case à partir des auras du joueur.
--   en haut à gauche  : mes soins sur la durée (icônes ou barres fines)
--   dans les coins    : un carré de couleur par sort choisi (un de mes soins, réglage par classe)
--   en bas à droite   : ses affaiblissements
--   à gauche, en grand: un affaiblissement important (boss, ou liste personnelle)
--   en bas à gauche   : un buff de groupe qui lui manque (hors combat)
--   bordure colorée   : je peux dissiper quelque chose
--   contour lumineux  : un affaiblissement important est posé (avec un son pour ceux de ma liste)
--   auras privées     : affaiblissements de boss cachés aux addons, que le jeu dessine lui-même sur la case
-- Performance : plusieurs changements d'auras dans la même image ne déclenchent qu'une seule mise à jour.

local _, Z = ...
local UI = Z.UI
local issecret = Z.IsSecret

local GetUnitAuras = C_UnitAuras.GetUnitAuras
local GetAuraDuration = C_UnitAuras.GetAuraDuration
local GetAuraCount = C_UnitAuras.GetAuraApplicationDisplayCount
local GetDispelColor = C_UnitAuras.GetAuraDispelTypeColor
local AddPrivateAnchor = C_UnitAuras.AddPrivateAuraAnchor
local RemovePrivateAnchor = C_UnitAuras.RemovePrivateAuraAnchor
local SORT = Enum.UnitAuraSortRule and Enum.UnitAuraSortRule.Default
local REMAINING = Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime
local IMMEDIATE = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate
local IsFilteredOut = C_UnitAuras.IsAuraFilteredOutByInstanceID
local GetSpellName = C_Spell and C_Spell.GetSpellName

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

local fadeCurve -- opacité d'une icône selon les secondes restantes : 1 jusqu'à 6 s, puis s'efface jusqu'à 0,3

local function BuildCurve()
	if C_CurveUtil.CreateCurve then
		fadeCurve = C_CurveUtil.CreateCurve()
		fadeCurve:SetType(Enum.LuaCurveType.Linear)
		fadeCurve:AddPoint(0, 0.3)
		fadeCurve:AddPoint(6, 1)
	end
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

-- mine : icône d'un de mes soins, qui suit les réglages cercle, décompte, fondu et charges
local function ShowAura(icon, unit, aura, mine)
	local id = aura.auraInstanceID
	local db = Z.db
	icon.texture:SetTexture(aura.icon)
	icon.texture:SetDesaturated(false)
	local duration = GetAuraDuration(unit, id)
	icon.duration = mine and duration or nil
	if duration then
		icon.cooldown:SetCooldownFromDurationObject(duration)
	else
		icon.cooldown:Clear()
	end
	-- Cercle et décompte sont dessinés par le jeu : ils marchent en combat, même sur une durée secrète
	icon.cooldown:SetDrawSwipe(not mine or db.hotSwipe)
	icon.cooldown:SetHideCountdownNumbers(not (mine and db.hotCountdown))
	if mine and db.hotCountdown and icon.cooldown.SetCountdownFont and not icon.smallNumbers then
		icon.smallNumbers = true
		icon.cooldown:SetCountdownFont("GameFontHighlightSmallOutline")
	end
	icon.count:SetText((not mine or db.hotCharges) and GetAuraCount(unit, id, 2, 99) or "")
	icon:SetAlpha(1)
	if mine and db.hotFade then Z.FadeIcon(icon) end
	icon:Show()
end

-- Icône qui s'efface : le jeu donne l'opacité à partir des secondes restantes (valeur parfois secrète)
function Z.FadeIcon(icon)
	local duration = icon.duration
	if duration and fadeCurve and duration.EvaluateRemainingDuration then
		local ok, alpha = pcall(duration.EvaluateRemainingDuration, duration, fadeCurve)
		if ok and alpha then icon:SetAlpha(alpha) end
	end
end

-- Appelé 2 fois par seconde avec le contrôle de portée, seulement si le réglage est coché
function Z.FadeHots(b)
	for _, icon in ipairs(b.hots) do
		if icon:IsShown() then Z.FadeIcon(icon) end
	end
end

-- Barre fine numéro « index » : elle se vide avec la durée restante du soin
local function GetBar(b, index, x, y)
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
	bar:SetPoint("TOPLEFT", b.over, "TOPLEFT", x or 3, (y or 0) - 3 - (index - 1) * 4)
	return bar
end

local function ShowBar(bar, unit, aura)
	local duration = GetAuraDuration(unit, aura.auraInstanceID)
	if not (duration and bar.SetTimerDuration and pcall(bar.SetTimerDuration, bar, duration, IMMEDIATE, REMAINING)) then
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(1)
	end
	bar:Show()
end

----------------------------------------------------------------------------------------------------
-- Coins : un carré de couleur par sort choisi. Il se vide avec la durée du soin, comme un sablier.
----------------------------------------------------------------------------------------------------
local CORNERS = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }
Z.CORNERS = CORNERS
local CORNER_COLORS = {
	TOPLEFT = { 0.35, 0.95, 0.45 }, TOPRIGHT = { 0.30, 0.80, 1.00 },
	BOTTOMLEFT = { 1.00, 0.85, 0.30 }, BOTTOMRIGHT = { 1.00, 0.50, 0.85 },
}
Z.CORNER_COLORS = CORNER_COLORS
local CORNER_SIGN = { TOPLEFT = { 1, -1 }, TOPRIGHT = { -1, -1 }, BOTTOMLEFT = { 1, 1 }, BOTTOMRIGHT = { -1, 1 } }

-- Mes coins pour la classe jouée : { TOPLEFT = "Récupération", ... }
function Z.MyCorners()
	return Z.db.cornerSpells[Z.class] or {}
end

-- Taille des carrés, et place que les autres icônes laissent libre quand un coin est pris
local function CornerSize(b)
	return math.max(6, math.floor((b.iconSize or 12) * 0.55 + 0.5))
end
function Z.CornerShift(b, point)
	local name = Z.MyCorners()[point]
	return (name and name ~= "") and CornerSize(b) + 2 or 0
end

local function GetCorner(b, point)
	b.corners = b.corners or {}
	local square = b.corners[point]
	if not square then
		square = CreateFrame("Frame", nil, b.over)
		square:SetFrameLevel(b.over:GetFrameLevel() + 4)
		square.fill = square:CreateTexture(nil, "ARTWORK")
		square.fill:SetAllPoints()
		square.border = UI.Border(square, 1, 1)
		square.border:SetColor(0, 0, 0, 1)
		square.cooldown = CreateFrame("Cooldown", nil, square, "CooldownFrameTemplate")
		square.cooldown:SetAllPoints()
		square.cooldown:SetReverse(true)
		square.cooldown:SetHideCountdownNumbers(true)
		square.cooldown:SetDrawEdge(false)
		b.corners[point] = square
	end
	local size, sign = CornerSize(b), CORNER_SIGN[point]
	local color = CORNER_COLORS[point]
	square.fill:SetColorTexture(color[1], color[2], color[3], 1)
	square:SetSize(size, size)
	square:ClearAllPoints()
	square:SetPoint(point, b.over, point, sign[1] * 2, sign[2] * 2)
	return square
end

----------------------------------------------------------------------------------------------------
-- Place de chaque rangée d'icônes : celle d'origine, plus le décalage de l'éditeur de placement (Z.Offset).
-- Les vraies cases, le mode test et la case d'exemple de l'éditeur passent tous par ici.
----------------------------------------------------------------------------------------------------
function Z.HotIcon(b, index)
	local dx, dy = Z.Offset("hots")
	return GetIcon(b, b.hots, index, "TOPLEFT", 2 + Z.CornerShift(b, "TOPLEFT") + dx, -2 + dy, 1)
end

function Z.HotBar(b, index)
	local dx, dy = Z.Offset("hots")
	return GetBar(b, index, 3 + Z.CornerShift(b, "TOPLEFT") + dx, dy)
end

function Z.DebuffIcon(b, index)
	local dx, dy = Z.Offset("debuffs")
	return GetIcon(b, b.debuffs, index, "BOTTOMRIGHT", -2 - Z.CornerShift(b, "BOTTOMRIGHT") + dx, 2 + dy, -1)
end

function Z.BigIcon(b)
	local dx, dy = Z.Offset("big")
	b.bigList = b.bigList or {}
	b.bigIcon = GetIcon(b, b.bigList, 1, "LEFT", 3 + dx, dy, 1, 1.6)
	return b.bigIcon
end

function Z.BuffIcon(b)
	local dx, dy = Z.Offset("buff")
	b.buffList = b.buffList or {}
	b.buffIcon = GetIcon(b, b.buffList, 1, "BOTTOMLEFT", 2 + Z.CornerShift(b, "BOTTOMLEFT") + dx, 2 + dy, 1)
	return b.buffIcon
end

local function ShowCorner(square, unit, aura)
	local duration = GetAuraDuration(unit, aura.auraInstanceID)
	if duration then square.cooldown:SetCooldownFromDurationObject(duration) else square.cooldown:Clear() end
	square:Show()
end

----------------------------------------------------------------------------------------------------
-- Reconnaître mes soins en combat. Le jeu y cache le nom des auras, mais pas leur numéro (auraInstanceID) :
--   1. un nom lu une fois (hors combat, ou sort resté lisible) est retenu pour ce numéro ;
--   2. quand je lance un de mes sorts (mon propre sort reste lisible), les auras à moi qui apparaissent
--      dans le même instant sur un joueur reçoivent ce nom.
-- Rien n'est lu en boucle : seulement à l'arrivée d'une aura.
----------------------------------------------------------------------------------------------------
local known, knownCount = {}, 0       -- numéro d'aura -> nom de mon sort
local lastCast, lastCastTime = nil, 0
local CAST_WINDOW = 0.3               -- secondes entre mon sort et l'aura qu'il pose

local function Remember(id, name)
	if not id or not name or issecret(id) or issecret(name) then return end
	if not known[id] then
		knownCount = knownCount + 1
		if knownCount > 400 then wipe(known) knownCount = 1 end -- garde-fou : jamais plus de 400 numéros
	end
	known[id] = name
end

-- Nom d'une de mes auras : lisible, sinon retrouvé par son numéro, sinon nil (secret et inconnu)
local function AuraName(aura)
	local name, id = aura.name, aura.auraInstanceID
	if not issecret(name) then
		Remember(id, name)
		return name
	end
	if id and not issecret(id) then return known[id] end
end
Z.AuraName = AuraName

local function IsMine(unit, id)
	if not IsFilteredOut or not id or issecret(id) then return false end
	local ok, out = pcall(IsFilteredOut, unit, id, "HELPFUL|PLAYER")
	return ok and out == false
end

-- Appelé par la case à chaque UNIT_AURA, avec le détail des changements donné par le jeu
function Z.NoteAuraChanges(b, info)
	if type(info) ~= "table" then return end
	if info.removedAuraInstanceIDs then
		for _, id in ipairs(info.removedAuraInstanceIDs) do
			if not issecret(id) and known[id] then
				known[id] = nil
				knownCount = knownCount - 1
			end
		end
	end
	if info.addedAuras then
		local recent = lastCast and GetTime() - lastCastTime <= CAST_WINDOW
		for _, aura in ipairs(info.addedAuras) do
			local id = aura.auraInstanceID
			if not issecret(aura.name) then
				Remember(id, aura.name)
			elseif recent and IsMine(b.unit, id) then
				Remember(id, lastCast)
			end
		end
	end
end

-- Mes sorts lancés : seul le nom de ceux que je suis (soins suivis ou coins) est gardé
local function Wanted(name)
	if Z.trackedNames[name] or Z.db.extraTracked[name] then return true end
	for _, wanted in pairs(Z.MyCorners()) do
		if wanted == name then return true end
	end
end

local castWatcher = CreateFrame("Frame")
castWatcher:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
castWatcher:SetScript("OnEvent", function(_, _, _, _, spellID)
	if not spellID or issecret(spellID) or not GetSpellName or not Z.db then return end
	local name = GetSpellName(spellID)
	if name and not issecret(name) and Wanted(name) then
		lastCast, lastCastTime = name, GetTime()
	end
end)

-- Cache toutes les icônes d'une case (changement de style ou de taille)
function Z.HideAuras(b)
	if b.corners then for _, square in pairs(b.corners) do square:Hide() end end
	for _, list in ipairs({ b.hots, b.hotBars, b.debuffs }) do
		for _, element in ipairs(list) do element:Hide() end
	end
	if b.bigIcon then b.bigIcon:Hide() end
	if b.buffIcon then b.buffIcon:Hide() end
	if b.glow then b.glow:Hide() end
end

-- Contour lumineux qui pulse autour de la case. Le cadre porteur reçoit l'opacité décidée par le jeu,
-- la bordure à l'intérieur porte l'animation : les deux ne se gênent pas.
local function GetGlow(b)
	if b.glow then return b.glow end
	local glow = CreateFrame("Frame", nil, b.over)
	glow:SetAllPoints()
	glow:SetFrameLevel(b.over:GetFrameLevel() + 2)
	local border = UI.Border(glow, 2, 2)
	border:SetColor(1, 0.82, 0.25, 1)
	border:SetRounded(Z.db.corners == "ROUND")
	glow.border = border
	local pulse = border:CreateAnimationGroup()
	pulse:SetLooping("BOUNCE")
	local fade = pulse:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0.3)
	fade:SetDuration(0.6)
	glow:SetScript("OnShow", function() pulse:Play() end)
	pulse:Play()
	b.glow = glow
	return glow
end

----------------------------------------------------------------------------------------------------
-- Auras privées : le jeu cache certains affaiblissements de boss aux addons, mais accepte de les dessiner
-- lui-même à une place qu'on lui indique (une « ancre »). Lyorune ne sait ni lesquels ni combien : il réserve
-- deux emplacements. Les ancres suivent le joueur de la case et sont refaites quand un réglage change.
----------------------------------------------------------------------------------------------------
local PRIVATE_SLOTS = 2
local PRIVATE_OFFSETS = { CENTER = { 0, 0 }, TOP = { 0, -2 }, BOTTOM = { 0, 2 }, LEFT = { 2, 0 }, RIGHT = { -2, 0 } }

-- Le cadre qui reçoit les auras privées : place choisie dans les options, plus le décalage de l'éditeur
function Z.PrivateHolder(b)
	local db = Z.db
	local size, point = db.privateAuraSize, db.privateAuraPoint
	local offset = PRIVATE_OFFSETS[point] or PRIVATE_OFFSETS.CENTER
	local dx, dy = Z.Offset("private")
	local holder = b.privateHolder
	if not holder then
		holder = CreateFrame("Frame", nil, b.over)
		holder:SetFrameLevel(b.over:GetFrameLevel() + 5) -- au-dessus des icônes de Lyorune
		b.privateHolder = holder
	end
	holder:SetSize(PRIVATE_SLOTS * (size + 2) - 2, size)
	holder:ClearAllPoints()
	holder:SetPoint(point, b.over, point, offset[1] + dx, offset[2] + dy)
	return holder, size
end
Z.PRIVATE_SLOTS = PRIVATE_SLOTS

function Z.AnchorPrivateAuras(b)
	if b.privateAnchors then
		for _, id in ipairs(b.privateAnchors) do pcall(RemovePrivateAnchor, id) end
		b.privateAnchors = nil
	end
	local db = Z.db
	if not (b.unit and db.privateAuras and AddPrivateAnchor and RemovePrivateAnchor) then
		if b.privateHolder then b.privateHolder:Hide() end
		return
	end

	local holder, size = Z.PrivateHolder(b)
	holder:Show()

	b.privateAnchors = {}
	for index = 1, PRIVATE_SLOTS do
		local ok, id = pcall(AddPrivateAnchor, {
			unitToken = b.unit,
			auraIndex = index,
			parent = holder,
			showCountdownFrame = true,
			showCountdownNumbers = false,
			iconInfo = {
				iconWidth = size,
				iconHeight = size,
				iconAnchor = { point = "LEFT", relativeTo = holder, relativePoint = "LEFT", offsetX = (index - 1) * (size + 2), offsetY = 0 },
			},
		})
		if ok and id then b.privateAnchors[#b.privateAnchors + 1] = id end
	end
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

-- Affaiblissement important : d'abord ceux de ma liste (nom lisible), puis ceux marqués « boss » par le jeu.
-- Renvoie l'aura, « le jeu décide » (marque secrète en combat), et « de ma liste ».
local function FindImportant(harmful)
	for i = 1, #harmful do
		local name = harmful[i].name
		if not issecret(name) and Z.db.importantNames[name] then return harmful[i], false, true end
	end
	for i = 1, #harmful do
		local boss = harmful[i].isBossAura
		if not issecret(boss) and boss then return harmful[i] end
	end
	-- En combat ces informations peuvent être secrètes : on laisse le jeu décider de la visibilité
	local first = harmful[1]
	if first and issecret(first.isBossAura) then return first, true end
end

-- Son d'alerte : une fois par affaiblissement de ma liste posé sur un joueur, au plus toutes les 2 secondes
local lastAlert = 0
local function ImportantSound(b, aura, fromList)
	local name = fromList and aura.name or nil
	if name and name ~= b.alertedName and Z.db.importantSound and GetTime() - lastAlert > 2 then
		lastAlert = GetTime()
		PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
	end
	b.alertedName = name
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

	-- 1. Mes soins sur la durée et boucliers ; un sort placé dans un coin n'est plus dans la rangée
	local shown = 0
	local bars = db.hotStyle == "BARS"
	local cornerOf, used = {}, {}
	for point, name in pairs(Z.MyCorners()) do
		if name ~= "" then cornerOf[name] = point end
	end
	local wantCorners = next(cornerOf) ~= nil
	if (db.showHots and (next(Z.trackedNames) or next(db.extraTracked))) or wantCorners then
		local list = Auras(unit, "HELPFUL|PLAYER", 16)
		if list then
			for i = 1, #list do
				local aura = list[i]
				local name = wantCorners and AuraName(aura)
				local point = name and cornerOf[name]
				if point then
					if not used[point] then
						used[point] = true
						ShowCorner(GetCorner(b, point), unit, aura)
					end
				elseif db.showHots and shown < MAX_HOTS and IsTracked(aura) then
					shown = shown + 1
					if bars then
						ShowBar(Z.HotBar(b, shown), unit, aura)
					else
						ShowAura(Z.HotIcon(b, shown), unit, aura, true)
					end
				end
			end
		end
	end
	if b.corners then
		for point, square in pairs(b.corners) do
			if not used[point] then square:Hide() end
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
		if not b.dispel:IsShown() then DispelSound() end
		Z.ShowDispel(b, true, color:GetRGBA())
	else
		Z.ShowDispel(b, false)
	end

	-- 3. Icônes d'affaiblissements : celui à dissiper en premier
	shown = 0
	if db.showDebuffs and harmful then
		local firstId = toDispel and toDispel.auraInstanceID
		if issecret(firstId) then firstId = nil end
		if toDispel then
			shown = 1
			ShowAura(Z.DebuffIcon(b, 1), unit, toDispel)
		end
		if db.debuffMode == "ALL" then
			for i = 1, #harmful do
				if shown == MAX_DEBUFFS then break end
				local aura = harmful[i]
				local id = aura.auraInstanceID
				if not (firstId and not issecret(id) and id == firstId) and not IsIgnored(aura) then
					shown = shown + 1
					ShowAura(Z.DebuffIcon(b, shown), unit, aura)
				end
			end
		end
	end
	for i = shown + 1, #b.debuffs do b.debuffs[i]:Hide() end

	-- 4. Affaiblissement important : en grand sur la gauche, contour lumineux, son
	local important, gameDecides, fromList
	if harmful and (db.bossDebuffs or db.importantGlow or db.importantSound) then
		important, gameDecides, fromList = FindImportant(harmful)
	end
	if important and db.bossDebuffs then
		ShowAura(Z.BigIcon(b), unit, important)
		if gameDecides then b.bigIcon:SetAlphaFromBoolean(important.isBossAura, 1, 0) end
	elseif b.bigIcon then
		b.bigIcon:Hide()
	end
	if important and db.importantGlow then
		local glow = GetGlow(b)
		if gameDecides then glow:SetAlphaFromBoolean(important.isBossAura, 1, 0) else glow:SetAlpha(1) end
		glow:Show()
	elseif b.glow then
		b.glow:Hide()
	end
	ImportantSound(b, important or {}, fromList)

	-- 5. Buff de groupe manquant, hors combat
	local missing = FindMissingBuff(b, unit)
	if missing then
		Z.BuffIcon(b)
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
