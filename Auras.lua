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
--   au bord droit     : un gros défensif posé par n'importe qui (Mur protecteur, Bouclier divin...)
--   au centre         : un contrôle subi (étourdi, apeuré, métamorphosé)
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

local BAR_COLORS = { { 0.35, 0.95, 0.45 }, { 0.30, 0.80, 1.00 }, { 1.00, 0.85, 0.30 }, { 1.00, 0.50, 0.85 } }
Z.BAR_COLORS = BAR_COLORS
-- Sort que je ne peux pas relancer (Âme affaiblie) : icône grise et assombrie, barre grise
Z.LOCKOUT_SHADE = 0.55
Z.LOCKOUT_BAR = { 0.45, 0.45, 0.50 }

-- Liste des auras d'un joueur pour un filtre donné (nil si le client refuse le filtre)
local function Auras(unit, filter, count)
	local ok, list = pcall(GetUnitAuras, unit, filter, count, SORT, 1)
	return ok and list or nil
end

-- Couleur selon le type : 1 magie, 2 malédiction, 3 maladie, 4 poison. Le jeu fait la correspondance,
-- ce qui fonctionne même quand le type est une valeur secrète.
local dispelCurve, veilCurve
Z.DISPEL_VEIL = 0.18 -- opacité du voile de dissipation posé sur la vie (la vie reste visible dessous)

local fadeCurve -- opacité d'une icône selon les secondes restantes : 1 jusqu'à 6 s, puis s'efface jusqu'à 0,3

local function BuildCurve()
	if C_CurveUtil.CreateCurve then
		fadeCurve = C_CurveUtil.CreateCurve()
		fadeCurve:SetType(Enum.LuaCurveType.Linear)
		fadeCurve:AddPoint(0, 0.3)
		fadeCurve:AddPoint(6, 1)
	end
	-- Le jeu pose la couleur ET l'opacité de la courbe sur la texture (son opacité propre est remplacée) :
	-- le voile a donc sa propre courbe, aux mêmes couleurs mais presque transparente
	local function Colors(alpha)
		local curve = C_CurveUtil.CreateColorCurve()
		curve:SetType(Enum.LuaCurveType.Step)
		curve:AddPoint(0, CreateColor(0, 0, 0, 0))
		curve:AddPoint(1, CreateColor(0.20, 0.60, 1.00, alpha)) -- magie : bleu
		curve:AddPoint(2, CreateColor(0.65, 0.20, 1.00, alpha)) -- malédiction : violet
		curve:AddPoint(3, CreateColor(0.75, 0.50, 0.10, alpha)) -- maladie : brun
		curve:AddPoint(4, CreateColor(0.10, 0.85, 0.20, alpha)) -- poison : vert
		curve:AddPoint(5, CreateColor(0, 0, 0, 0))
		return curve
	end
	dispelCurve = Colors(1)
	veilCurve = Colors(Z.DISPEL_VEIL)
end

-- Les mêmes courbes servent aux conteneurs d'auras du jeu (Containers.lua) : veil = true pour le voile
function Z.DispelCurve(veil)
	if not dispelCurve then BuildCurve() end
	return veil and veilCurve or dispelCurve
end

----------------------------------------------------------------------------------------------------
-- Icônes et barres
----------------------------------------------------------------------------------------------------
-- Police du décompte à la mesure de l'icône (6 à 12 points) : le chiffre tient dans son icône au lieu de mordre
-- sur la voisine (icônes de 8 à 10 pixels en Barre, Carré et Bandeau). Le jeu demande le nom d'une police : une
-- par hauteur, créée une seule fois.
local countdownFonts = {}
function Z.CountdownFont(size)
	local height = math.max(6, math.min(12, math.floor((size or 12) * 0.62 + 0.5)))
	if not countdownFonts[height] then
		local name = "LyoruneCountdown" .. height
		local font = _G[name] or CreateFont(name)
		font:SetFont(STANDARD_TEXT_FONT, height, "OUTLINE")
		countdownFonts[height] = name
	end
	return countdownFonts[height]
end

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
local function GetIcon(b, list, index, point, x, y, direction, size)
	local icon = list[index]
	if not icon then
		icon = NewIcon(b)
		list[index] = icon
	end
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
	icon.texture:SetVertexColor(1, 1, 1)
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
	if mine and db.hotCountdown and icon.cooldown.SetCountdownFont then
		local font = Z.CountdownFont(icon:GetWidth())
		if icon.countdownFont ~= font then
			icon.countdownFont = font
			icon.cooldown:SetCountdownFont(font)
		end
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
Z.CORNER_SIGN = CORNER_SIGN

-- Mes coins pour la classe jouée : { TOPLEFT = "Récupération", ... }
function Z.MyCorners()
	return Z.db.cornerSpells[Z.class] or {}
end

-- Taille des carrés, et place que les autres icônes laissent libre quand un coin est pris
local function CornerSize(b)
	return math.max(6, math.floor((b.iconSize or 12) * 0.55 + 0.5))
end
Z.CornerSize = CornerSize
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
Z.CornerSquare = GetCorner -- aussi pour les fausses cases (mode test, case témoin)

----------------------------------------------------------------------------------------------------
-- Place de chaque rangée d'icônes : celle d'origine, plus le décalage de l'éditeur de placement (Z.Offset).
-- Les vraies cases, le mode test et la case d'exemple de l'éditeur passent tous par ici.
----------------------------------------------------------------------------------------------------
-- Icône numéro « index » d'une rangée de Z.AuraRows (Themes.lua) : elle passe à la ligne après row.perLine icônes
local function RowIcon(b, list, index, row, dx, dy)
	local icon = list[index]
	if not icon then
		icon = NewIcon(b)
		list[index] = icon
	end
	local size = row.size
	local column, line = (index - 1) % row.perLine, math.floor((index - 1) / row.perLine)
	icon:SetSize(size, size)
	icon:ClearAllPoints()
	icon:SetPoint(row.point, row.relative == "HP" and b.hp or b.over, row.point,
		row.x + dx + row.dirX * column * (size + 2), row.y + dy + row.dirY * line * (size + 2))
	return icon
end

function Z.HotIcon(b, index)
	local dx, dy = Z.Offset("hots")
	return RowIcon(b, b.hots, index, (b.rows or Z.AuraRows()).hots, dx, dy)
end

function Z.HotBar(b, index)
	local dx, dy = Z.Offset("hots")
	return GetBar(b, index, 3 + Z.CornerShift(b, "TOPLEFT") + dx, dy)
end

function Z.DebuffIcon(b, index)
	local dx, dy = Z.Offset("debuffs")
	return RowIcon(b, b.debuffs, index, (b.rows or Z.AuraRows()).debuffs, dx, dy)
end

-- Boisson d'un soigneur : à droite de son icône de mana basse, à la même taille et avec le même décalage
-- (éditeur de placement). Poussée trop à droite, elle passe à gauche de l'icône. Rend x, y et la taille, depuis
-- le coin bas gauche de la barre de vie.
function Z.DrinkPlace()
	local dx, dy = Z.Offset("lowMana")
	local size = Z.ElementSize("lowMana", Z.IconSize() - 1)
	local x = 2 + dx + size + 2
	if x + size > Z.CellSize() - 4 then x = 2 + dx - size - 2 end
	return x, 2 + dy, size
end

function Z.DrinkIcon(b)
	b.drinkList = b.drinkList or {}
	local icon = b.drinkList[1]
	if not icon then
		icon = NewIcon(b)
		b.drinkList[1] = icon
	end
	local x, y, size = Z.DrinkPlace()
	icon:SetSize(size, size)
	icon:ClearAllPoints()
	icon:SetPoint("BOTTOMLEFT", b.hp, "BOTTOMLEFT", x, y)
	b.drinkIcon = icon
	return icon
end

-- Icône assombrie d'un sort que je ne peux pas relancer
function Z.DarkenIcon(icon)
	icon.texture:SetDesaturated(true)
	icon.texture:SetVertexColor(Z.LOCKOUT_SHADE, Z.LOCKOUT_SHADE, Z.LOCKOUT_SHADE)
end

-- Liseré des gros défensifs (bleu clair) et du contrôle subi (rouge) : on les distingue des affaiblissements
Z.DEFENSIVE_EDGE = { 0.45, 0.80, 1.00 }
Z.CONTROL_EDGE = { 1.00, 0.30, 0.20 }

function Z.DefensiveIcon(b, index)
	local dx, dy = Z.Offset("defensives")
	b.defensives = b.defensives or {}
	local icon = RowIcon(b, b.defensives, index, (b.rows or Z.AuraRows()).defensives, dx, dy)
	icon.border:SetColor(Z.DEFENSIVE_EDGE[1], Z.DEFENSIVE_EDGE[2], Z.DEFENSIVE_EDGE[3], 1)
	return icon
end

function Z.ControlIcon(b)
	local dx, dy = Z.Offset("controls")
	b.controlList = b.controlList or {}
	b.controlIcon = RowIcon(b, b.controlList, 1, (b.rows or Z.AuraRows()).controls, dx, dy)
	b.controlIcon.border:SetColor(Z.CONTROL_EDGE[1], Z.CONTROL_EDGE[2], Z.CONTROL_EDGE[3], 1)
	return b.controlIcon
end

function Z.BigIcon(b)
	local dx, dy = Z.Offset("big")
	b.bigList = b.bigList or {}
	b.bigIcon = GetIcon(b, b.bigList, 1, "LEFT", 3 + dx, dy, 1, Z.BigIconSize())
	return b.bigIcon
end

-- Place du buff manquant : coin bas gauche, après le carré de coin (x, y, taille). Les repères dessinés par le jeu
-- (Containers.lua) partent du même point, vers la droite.
function Z.BuffMarkPlace(b)
	local dx, dy = Z.Offset("buff")
	return 2 + Z.CornerShift(b, "BOTTOMLEFT") + dx, 2 + dy, Z.ElementSize("buff", Z.IconSize())
end

function Z.BuffIcon(b)
	local x, y, size = Z.BuffMarkPlace(b)
	b.buffList = b.buffList or {}
	b.buffIcon = GetIcon(b, b.buffList, 1, "BOTTOMLEFT", x, y, 1, size)
	return b.buffIcon
end

-- Repère numéro « index » d'un buff de ma liste quand le jeu cache les buffs : gris à bord rouge, sous le conteneur
-- du jeu qui dessine le buff par-dessus quand il est là (Containers.lua)
function Z.BuffMark(b, index, texture)
	local x, y, size = Z.BuffMarkPlace(b)
	b.markIcons = b.markIcons or {}
	local icon = GetIcon(b, b.markIcons, index, "BOTTOMLEFT", x, y, 1, size)
	icon:SetFrameLevel(b.over:GetFrameLevel() + 1)
	icon.texture:SetTexture(texture)
	icon.texture:SetDesaturated(true)
	icon.border:SetColor(1, 0.2, 0.2, 1)
	return icon
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

-- Appelé par la case à chaque UNIT_AURA, avec le détail des changements donné par le jeu.
-- En donjon, le jeu peut rendre ce détail secret (les listes elles-mêmes, ou chaque aura) : on ne le lit alors
-- pas, et la mise à jour des icônes se fait quand même (Frames.lua, UNIT_AURA).
function Z.NoteAuraChanges(b, info)
	if type(info) ~= "table" or issecret(info) then return end
	local removed, added = info.removedAuraInstanceIDs, info.addedAuras
	if type(removed) == "table" and not issecret(removed) then
		for _, id in ipairs(removed) do
			if not issecret(id) and known[id] then
				known[id] = nil
				knownCount = knownCount - 1
			end
		end
	end
	if type(added) == "table" and not issecret(added) then
		local recent = lastCast and GetTime() - lastCastTime <= CAST_WINDOW
		for _, aura in ipairs(added) do
			local id = type(aura) == "table" and not issecret(aura) and aura.auraInstanceID
			if not id then
				-- aura secrète : rien à retenir
			elseif not issecret(aura.name) then
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
local function OnMyCast(spellID)
	if not spellID or issecret(spellID) or not GetSpellName or not Z.db then return end
	-- enchantement d'arme lancé (chaman) : c'est lui que le panneau des buffs proposera ensuite
	-- enchantement d'arme ou aura lancé : c'est lui que le panneau des buffs proposera ensuite
	local line = Z.choiceIds and Z.choiceIds[spellID]
	if line and Z.char then
		Z.char.lastChoice = Z.char.lastChoice or {}
		Z.char.lastChoice[line] = spellID
	end
	local name = GetSpellName(spellID)
	if name and not issecret(name) and Wanted(name) then
		lastCast, lastCastTime = name, GetTime()
	end
end
castWatcher:SetScript("OnEvent", function(_, _, _, _, spellID) Z:Try("mes sorts lancés", OnMyCast, spellID) end)

-- Mon enchantement d'arme posé ou fini (chaman) : ma case relit ses buffs manquants. Événements absents d'un
-- client : ignorés sans erreur.
local weaponWatcher = CreateFrame("Frame")
pcall(weaponWatcher.RegisterEvent, weaponWatcher, "WEAPON_ENCHANT_CHANGED")
pcall(weaponWatcher.RegisterUnitEvent, weaponWatcher, "UNIT_INVENTORY_CHANGED", "player")
weaponWatcher:SetScript("OnEvent", function()
	if not (Z.weaponIds and next(Z.weaponIds) and Z.buttons) then return end
	for _, b in ipairs(Z.buttons) do
		local me = b.unit and UnitIsUnit(b.unit, "player")
		if not issecret(me) and me then Z.QueueAuras(b) end
	end
end)

-- Cache toutes les icônes d'une case (changement de style ou de taille)
function Z.HideAuras(b)
	if b.corners then for _, square in pairs(b.corners) do square:Hide() end end
	for _, list in ipairs({ b.hots, b.hotBars, b.debuffs, b.defensives or {} }) do
		for _, element in ipairs(list) do element:Hide() end
	end
	if b.controlIcon then b.controlIcon:Hide() end
	if b.bigIcon then b.bigIcon:Hide() end
	if b.buffIcon then b.buffIcon:Hide() end
	if b.drinkIcon then b.drinkIcon:Hide() end
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
		holder:SetFrameLevel(b.over:GetFrameLevel() + 6) -- au-dessus des icônes et des textes de la case
		b.privateHolder = holder
	end
	holder:SetSize(PRIVATE_SLOTS * (size + 2) - 2, size)
	holder:ClearAllPoints()
	holder:SetPoint(point, b.over, point, offset[1] + dx, offset[2] + dy)
	return holder, size
end
Z.PRIVATE_SLOTS = PRIVATE_SLOTS
Z.PRIVATE_OFFSETS = PRIVATE_OFFSETS -- pour borner leur décalage au bord de la case (Placement.lua)

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

-- Un gros défensif (Z.defensiveIds) ? Montré alors à part, quel que soit le lanceur (réglage « showDefensives »)
local function IsDefensive(aura)
	local id = aura.spellId
	return Z.db.showDefensives and not issecret(id) and Z.defensiveIds ~= nil and Z.defensiveIds[id] == true
end

-- Un affaiblissement qui bloque un de mes sorts (Âme affaiblie) ? Montré alors au bout de mes soins
local function IsLockout(aura)
	local id = aura.spellId
	return not issecret(id) and Z.lockoutIds ~= nil and Z.lockoutIds[id] == true
end

-- La boisson d'un soigneur (Z.drinkIds, Data.lua) ? Lisible hors combat seulement
local function FindDrink(unit)
	for _, aura in ipairs(Auras(unit, "HELPFUL", 40) or {}) do
		local id = aura.spellId
		if not issecret(id) and Z.drinkIds and Z.drinkIds[id] then return aura end
	end
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

-- Secondes restantes d'un buff : sans fin (ou inconnues) = toujours là
local function Remaining(aura, now)
	local expires = aura.expirationTime
	if issecret(expires) or not expires or expires == 0 then return math.huge end
	return expires - now
end

-- Secondes avant de proposer ce buff à nouveau : ce qui lui reste, moins le seuil « buffRefresh », plafonné au quart
-- de sa durée (un buff de 5 minutes n'est jamais proposé avant ses 75 dernières secondes : pas de mana perdue).
-- Durée secrète ou inconnue : le seuil entier.
local function Until(aura, now, margin)
	local left = Remaining(aura, now)
	local duration = aura.duration
	if margin > 0 and not issecret(duration) and type(duration) == "number" and duration > 0 then
		margin = math.min(margin, duration * 0.25)
	end
	return left - margin
end

-- Mon enchantement d'arme principale : secondes restantes (0 : aucun ; inconnu : toujours là)
local function WeaponLeft()
	if not GetWeaponEnchantInfo then return math.huge end
	local has, expiration = GetWeaponEnchantInfo()
	if issecret(has) or issecret(expiration) then return math.huge end
	if not has then return 0 end
	return (tonumber(expiration) or 0) / 1000
end

-- Relire la case quand un buff passe sous le seuil « buffRefresh » (aucun événement du jeu ne le dit) ; un seul
-- rendez-vous par case, le plus proche
local function Recheck(b, seconds)
	if seconds == math.huge then return end
	local now = GetTime()
	local at = now + seconds + 0.5
	if b.buffRecheckAt and b.buffRecheckAt > now and b.buffRecheckAt <= at then return end
	b.buffRecheckAt = at
	C_Timer.After(seconds + 0.5, function()
		if b.buffRecheckAt == at then
			b.buffRecheckAt = nil
			Z.QueueAuras(b)
		end
	end)
end

-- Ce buff de ma liste concerne-t-il ce joueur ? (sur moi seulement, joueurs à mana, pas les familiers, en raid
-- seulement mes groupes à buffer : BuffAssign.lua)
local function Concerns(check, unit, me)
	if check.self and not me then return false end
	if not me and not Z.BuffGroupOK(unit) then return false end
	if check.mana and not Z.UsesMana(unit) then return false end
	if check.blessing and unit:find("pet", 1, true) then return false end
	-- version de groupe seulement : un familier n'a pas de ligne « Groupe N », rien à lui proposer
	if unit:find("pet", 1, true) and not Z.BuffWatched(check) and Z.GroupSpell(check) then return false end
	return Z.BuffFollowed(check) -- version simple ou version de groupe cochée
end
Z.BuffConcerns = Concerns -- aussi pour les repères des buffs dessinés par le jeu (Containers.lua)

-- Buffs de ma liste que ce joueur n'a pas, tous, dans l'ordre de Data.lua : { { check, spell, icon }, ... }, et
-- une clé qui les résume. Hors combat seulement. Un buff qui finit dans moins de « buffRefresh » minutes
-- compte comme absent (au plus le quart de sa durée, Until).
-- Là où le jeu cache les buffs même hors combat (champ de bataille, arène) : un buff qui reste
-- lisible se lit, les autres viennent de la mémoire (BuffMemory.lua), et un buff inconnu compte comme absent.
local function FindMissingBuffs(b, unit)
	if not (Z.db.missingBuffs or Z.db.buffPanel) or #Z.buffChecks == 0 or b.status or InCombatLockdown() then return end
	local list = Auras(unit, "HELPFUL", 40)
	if not list then return end
	local now, margin = GetTime(), Z.db.buffRefresh * 60
	local present, mine, hidden = {}, nil, false
	for i = 1, #list do
		local name = list[i].name
		if issecret(name) then
			hidden = true
		else
			present[name] = math.max(present[name] or -math.huge, Until(list[i], now, margin))
		end
	end
	if not hidden then Z.NoteBuffs(unit, list, Z.buffNames, false) end
	local me = UnitIsUnit(unit, "player")
	if issecret(me) then me = false end
	local missing, key, soonest = {}, Z.buffGeneration .. "|", math.huge
	for _, check in ipairs(Z.buffChecks) do
		if Concerns(check, unit, me) then
			local left, choice = -math.huge, nil -- secondes avant de le proposer à nouveau (absent : jamais assez)
			local own = check.blessing or check.aura
			if check.weapon then
				local weapon = WeaponLeft()
				choice = Z.LastChoice(check)
				if weapon > 0 then
					left = weapon - margin
					soonest = math.min(soonest, weapon) -- l'arme ne prévient pas quand elle s'éteint
				end
			elseif own then
				-- seule une bénédiction ou une aura de moi compte : celle d'un autre paladin ne remplace pas la mienne
				if not mine then
					mine = {}
					local list2 = Auras(unit, "HELPFUL|PLAYER", 16)
					if not list2 then return end
					local hidden2 = false
					for i = 1, #list2 do
						local name = list2[i].name
						if issecret(name) then
							hidden2 = true
						else
							mine[name] = math.max(mine[name] or -math.huge, Until(list2[i], now, margin))
						end
					end
					if hidden2 then hidden = true else Z.NoteBuffs(unit, list2, Z.ownNames, true) end
				end
				for name in pairs(check.names) do left = math.max(left, mine[name] or -math.huge) end
				if check.blessing then
					-- bénédictions qu'un autre paladin lui a posées : jamais reprises, la suivante de sa ligne est proposée
					local taken
					for name in pairs(check.names) do
						if present[name] and not mine[name] then
							taken = taken or {}
							taken[name] = true
						end
					end
					choice = Z.BlessingFor(check, unit, taken)
					if not choice then left = math.huge end -- aucune choisie, ou toutes déjà posées par d'autres
				else
					choice = Z.LastChoice(check)
				end
			else
				for name in pairs(check.names) do left = math.max(left, present[name] or -math.huge) end
			end
			-- caché par le jeu : la mémoire (photo d'avant la restriction, mes sorts), relue à la fin du buff retenu
			local remembered = false
			if hidden and left <= 0 and not check.weapon and not Z.BuffReadable(check) then
				for name in pairs(check.names) do
					local memory = Z.BuffMemoryLeft(unit, name, own, now, margin)
					if memory then left, remembered = math.max(left, memory), true end
				end
			end
			if left <= 0 then
				local spell = choice and choice.name or check.spell
				missing[#missing + 1] = { check = check, spell = spell, icon = choice and choice.icon or check.icon }
				key = key .. check.id .. ":" .. spell .. ";"
			elseif margin > 0 or remembered then
				soonest = math.min(soonest, left)
			end
		end
	end
	Recheck(b, soonest)
	if #missing > 0 then return missing, key end
end

-- Mes buffs uniques (Bouclier de terre...) posés sur ce joueur : leur nom, ou nil. Hors combat seulement. Caché
-- par le jeu : ceux que je lui ai lancés et qui durent encore (BuffMemory.lua).
local function FindMyUniques(b, unit)
	if not Z.db.buffPanel or #Z.uniqueChecks == 0 or b.status or InCombatLockdown() then return end
	local list = Auras(unit, "HELPFUL|PLAYER", 16)
	if not list then return end
	local mine, hidden
	for i = 1, #list do
		local name = list[i].name
		if issecret(name) then
			hidden = true
		else
			for _, check in ipairs(Z.uniqueChecks) do
				if check.name == name then mine = (mine and mine .. "," or "") .. name end
			end
		end
	end
	if not hidden then
		Z.NoteBuffs(unit, list, Z.ownNames, true)
		return mine
	end
	return mine or Z.UniquesInMemory(unit)
end

----------------------------------------------------------------------------------------------------
-- Mise à jour des auras d'une case
----------------------------------------------------------------------------------------------------
local UpdateAuras, UpdateBuffs

-- Cases sans conteneurs (client qui n'en a pas) : Lyorune lit les auras et dessine lui-même les icônes
local function UpdateWithReading(b)
	local unit = b.unit
	local db = Z.db
	-- Case cible ou focalisation sur un ennemi : ni soins, ni dissipation, ni buffs à lui montrer
	local enemy = b.extra and UnitCanAttack("player", unit)
	if issecret(enemy) then enemy = false end

	-- 1. Mes soins sur la durée et boucliers ; un sort placé dans un coin n'est plus dans la rangée
	local shown = 0
	local bars = db.hotStyle == "BARS"
	local cornerOf, used = {}, {}
	for point, name in pairs(Z.MyCorners()) do
		if name ~= "" then cornerOf[name] = point end
	end
	local wantCorners = next(cornerOf) ~= nil
	local mine = Z.HotCount()
	if not enemy and ((db.showHots and (next(Z.trackedNames) or next(db.extraTracked))) or wantCorners) then
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
				elseif db.showHots and shown < mine and IsTracked(aura) and not IsDefensive(aura) then
					shown = shown + 1
					if bars then
						local bar, color = Z.HotBar(b, shown), BAR_COLORS[shown] or BAR_COLORS[1]
						bar:SetStatusBarColor(color[1], color[2], color[3])
						ShowBar(bar, unit, aura)
					else
						ShowAura(Z.HotIcon(b, shown), unit, aura, true)
					end
				end
			end
		end
	end
	-- Âme affaiblie (posée par n'importe qui) : au bout de mes soins, assombrie
	local harmful = not enemy and Auras(unit, "HARMFUL", 8)
	local lockouts = not enemy and harmful and Z.ShowsLockouts()
	if lockouts then
		local placed = 0
		for i = 1, #harmful do
			if placed >= Z.LOCKOUT_COUNT then break end
			if IsLockout(harmful[i]) then
				shown, placed = shown + 1, placed + 1
				if bars then
					local bar = Z.HotBar(b, shown)
					bar:SetStatusBarColor(Z.LOCKOUT_BAR[1], Z.LOCKOUT_BAR[2], Z.LOCKOUT_BAR[3])
					ShowBar(bar, unit, harmful[i])
				else
					local icon = Z.HotIcon(b, shown)
					ShowAura(icon, unit, harmful[i], false)
					Z.DarkenIcon(icon)
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

	-- 2. Affaiblissements que je peux dissiper moi-même (réglage « dispelCount ») : le filtre RAID du jeu ; mes
	-- propres sorts seulement si le jeu refuse le filtre (une liste vide veut dire « rien à dissiper » : un
	-- affaiblissement Magie que personne ne retire ne doit pas sonner)
	local dispelMax = Z.DispelCount()
	local dispellable = {}
	local mine = not enemy and Auras(unit, Z.DISPEL_MINE, dispelMax)
	for _, aura in ipairs(mine or {}) do
		if #dispellable < dispelMax then dispellable[#dispellable + 1] = aura end
	end
	if mine == nil and not enemy and harmful then
		for i = 1, #harmful do
			local kind = harmful[i].dispelName
			if #dispellable < dispelMax and kind and not issecret(kind) and Z.canDispel[kind] then
				dispellable[#dispellable + 1] = harmful[i]
			end
		end
	end
	local toDispel = dispellable[1]

	local color = toDispel and db.showDispel and GetDispelColor(unit, toDispel.auraInstanceID, dispelCurve)
	if color then
		if not b.dispel:IsShown() then DispelSound() end
		Z.ShowDispel(b, true, color:GetRGBA())
	else
		Z.ShowDispel(b, false)
	end

	-- 3. Icônes d'affaiblissements : ceux à dissiper en premier, puis les autres (comme les conteneurs du jeu :
	-- une place pour le premier à dissiper, « debuffCount - 1 » pour les autres)
	shown = 0
	if db.showDebuffs and harmful then
		local first = {}
		for _, aura in ipairs(dispellable) do
			shown = shown + 1
			ShowAura(Z.DebuffIcon(b, shown), unit, aura)
			local id = aura.auraInstanceID
			if id and not issecret(id) then first[id] = true end
		end
		if db.debuffMode == "ALL" then
			local others = 0
			for i = 1, #harmful do
				if others >= db.debuffCount - 1 then break end
				local aura = harmful[i]
				local id = aura.auraInstanceID
				if not (id and not issecret(id) and first[id]) and not IsIgnored(aura) and not (lockouts and IsLockout(aura)) then
					shown, others = shown + 1, others + 1
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

	-- 5. Gros défensifs, posés par n'importe qui, et contrôle subi (étourdi, apeuré, métamorphosé)
	shown = 0
	local helpful = not enemy and db.showDefensives and next(Z.defensiveIds or {}) and Auras(unit, "HELPFUL", 40)
	for i = 1, helpful and #helpful or 0 do
		if shown >= Z.DEFENSIVE_COUNT then break end
		if IsDefensive(helpful[i]) then
			shown = shown + 1
			ShowAura(Z.DefensiveIcon(b, shown), unit, helpful[i])
		end
	end
	for i = shown + 1, #(b.defensives or {}) do b.defensives[i]:Hide() end
	local control = not enemy and db.showControls and Auras(unit, "HARMFUL|CROWD_CONTROL", 1)
	if control and control[1] then
		ShowAura(Z.ControlIcon(b), unit, control[1])
	elseif b.controlIcon then
		b.controlIcon:Hide()
	end
	-- Soigneur qui boit (b.drinkShown, Frames.lua)
	local drink = not enemy and b.drinkShown and FindDrink(unit)
	if drink then
		ShowAura(Z.DrinkIcon(b), unit, drink)
	elseif b.drinkIcon then
		b.drinkIcon:Hide()
	end

	UpdateBuffs(b, unit, enemy)
end

-- Cases à conteneurs (Containers.lua) : le jeu dessine toutes les icônes. Lyorune lit les auras seulement quand
-- le jeu le permet (hors combat, ou en combat hors des zones protégées) : sons, numéros de sorts, buffs manquants.
local function Readable()
	local secret = C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret()
	if issecret(secret) then return false end
	return not secret
end

local function Learn(list)
	if not list then return end
	for i = 1, #list do Z.LearnAuraId(list[i].name, list[i].spellId) end
end

local function UpdateWithBoxes(b)
	local unit, db = b.unit, Z.db
	local enemy = b.extra and UnitCanAttack("player", unit)
	if issecret(enemy) then enemy = false end
	Z.ShowAuraBoxes(b, not enemy)
	if not enemy and Readable() then
		Learn(Auras(unit, "HELPFUL|PLAYER", 16))
		local harmful = Auras(unit, "HARMFUL", 8)
		Learn(harmful)
		local dispellable = db.showDispel and Auras(unit, Z.DISPEL_MINE, 1)
		local hasDispel = dispellable and dispellable[1] ~= nil or false
		if hasDispel and not b.dispelHeard then DispelSound() end
		b.dispelHeard = hasDispel
		local important, gameDecides, fromList
		if harmful and db.importantSound then important, gameDecides, fromList = FindImportant(harmful) end
		if gameDecides then important = nil end
		ImportantSound(b, important or {}, fromList)
	end
	UpdateBuffs(b, unit, enemy)
end

UpdateAuras = function(b)
	if b.boxes then return UpdateWithBoxes(b) end
	return UpdateWithReading(b)
end

-- Buffs manquants et mes buffs uniques, hors combat. Le panneau des buffs manquants (Buffs.lua) lit
-- b.missingBuffs (toutes les absences) ; b.missingBuff est la première, montrée sur la case.
UpdateBuffs = function(b, unit, enemy)
	local db = Z.db
	local list, key
	if not enemy then list, key = FindMissingBuffs(b, unit) end
	local uniques = not enemy and FindMyUniques(b, unit) or nil
	local changed = b.missingKey ~= key or b.myUniques ~= uniques or (b.missingBuff ~= nil) ~= (list ~= nil)
	b.missingBuffs, b.missingBuff, b.missingKey, b.myUniques = list, list and list[1], key, uniques
	if changed then Z:QueueBuffPanel() end
	local missing = b.missingBuff
	-- le jeu cache les buffs et dessine lui-même ceux de ma liste (Containers.lua) : ses repères remplacent celui-ci
	if missing and db.missingBuffs and not Z.BuffMarksShown(b) then
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
-- (mode performance : les changements sont regroupés, 10 passages par seconde au plus)
----------------------------------------------------------------------------------------------------
local PERF_WAIT = 0.1
local dirty = {}
local driver = CreateFrame("Frame")
driver:Hide()
driver.waited = 0
driver:SetScript("OnUpdate", function(self, elapsed)
	if Z.db.perfMode then
		self.waited = self.waited + (elapsed or 0)
		if self.waited < PERF_WAIT then return end
	end
	self.waited = 0
	self:Hide()
	if not dispelCurve then BuildCurve() end
	-- Une case en erreur est notée au journal sans arrêter les autres : sinon une seule case fautive
	-- laissait toutes les cases sans auras
	for b in pairs(dirty) do
		dirty[b] = nil
		if b.unit and b:IsVisible() then Z:Try("auras", UpdateAuras, b) end
	end
end)

function Z.QueueAuras(b)
	if b.hiddenSelf then return Z.UpdateHiddenSelf() end -- mon personnage sans case (plus bas)
	dirty[b] = true
	driver:Show()
end

-- Mon personnage quand ma case est cachée (seul, « Mon cadre quand je suis seul » décoché) : le panneau des buffs lit
-- les cases, il ne me verrait plus. Une petite fiche lue comme une case (mêmes règles, FindMissingBuffs et
-- FindMyUniques), seulement dans ce cas, sur mes propres événements : rien de plus à lire en groupe ni en raid.
-- (VuhDo et HealKit partent d'une liste d'unités qui me contient toujours ; HealBot lit ses cases et me perd.)
local hiddenSelf = { unit = "player", hiddenSelf = true }
Z.hiddenSelf = hiddenSelf

-- Seul, sans ma case ? En groupe, ma case est toujours là (le jeu la montre dans le groupe et le raid) ; seul,
-- elle porte l'unité « player ». Aucune valeur secrète lue (UnitIsUnit peut l'être en instance, d'après HealKit).
function Z.SelfHidden()
	if IsInGroup() then return false end
	for _, b in ipairs(Z.buttons or {}) do
		if b.unit == "player" and not b.extra and b:IsVisible() then return false end
	end
	return true
end

function Z.UpdateHiddenSelf()
	local b = hiddenSelf
	local list, key, uniques
	if Z.db and Z.SelfHidden() then
		local dead = UnitIsDeadOrGhost("player")
		b.status = (not issecret(dead) and dead) and "dead" or nil
		list, key = FindMissingBuffs(b, "player")
		uniques = FindMyUniques(b, "player")
	end
	local changed = b.missingKey ~= key or b.myUniques ~= uniques or (b.missingBuff ~= nil) ~= (list ~= nil)
	b.missingBuffs, b.missingBuff, b.missingKey, b.myUniques = list, list and list[1], key, uniques
	if changed then Z:QueueBuffPanel() end
end

local selfEvents = CreateFrame("Frame")
selfEvents:RegisterUnitEvent("UNIT_AURA", "player")
selfEvents:RegisterEvent("WEAPON_ENCHANT_CHANGED")
selfEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
selfEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
selfEvents:RegisterEvent("PLAYER_DEAD")
selfEvents:RegisterEvent("PLAYER_UNGHOST")
selfEvents:RegisterEvent("PLAYER_ALIVE")
selfEvents:SetScript("OnEvent", function()
	-- ma case visible : elle fait déjà ce travail ; une fiche encore pleine est vidée une fois
	if hiddenSelf.missingKey or hiddenSelf.myUniques or Z.SelfHidden() then Z:Try("auras", Z.UpdateHiddenSelf) end
end)

-- Mise à jour immédiate, hors file : pour la mesure des performances (Perf.lua)
function Z.UpdateAurasNow(b)
	if not dispelCurve then BuildCurve() end
	UpdateAuras(b)
end

----------------------------------------------------------------------------------------------------
-- Diagnostic (/lyorune auras) : ce que le jeu donne à Lyorune pour la case du joueur, étape par étape.
-- À taper en combat quand des icônes manquent ; le résultat va aussi au journal (lu par outils/erreurs.py).
----------------------------------------------------------------------------------------------------
local function Describe(value)
	if issecret(value) then return "secret" end
	return tostring(value)
end

local function Diagnose(Add)
	local b
	for _, button in ipairs(Z.buttons) do
		if button.unit and UnitIsUnit(button.unit, "player") then b = button break end
	end
	b = b or Z.buttons[1]
	Add("combat " .. tostring(InCombatLockdown()) .. ", auras lisibles " .. tostring(Readable()))
	local box = b and b.boxes
	Add("conteneurs du jeu : " .. (box and ("oui, joueur " .. Describe(box.hots.GetUnit and box.hots:GetUnit())
		.. ", visibles " .. Describe(box.slots:IsVisible())) or b and b.boxesFailed and "création refusée"
		or Z.HasAuraBoxes() and "pas encore créés" or "absents de ce client"))
	if box then
		local ok, err = pcall(Z.DescribeAuraBoxes, b, Add)
		if not ok then Add("description des conteneurs impossible : " .. tostring(err)) end
	end
	if not (b and b.unit) then Add("aucune case") else
		local unit, db = b.unit, Z.db
		local tracked = 0
		for _ in pairs(Z.trackedNames) do tracked = tracked + 1 end
		Add(("case %s, visible %s, showHots %s, showDebuffs %s, sorts suivis %d"):format(unit, tostring(b:IsVisible()),
			tostring(db.showHots), tostring(db.showDebuffs), tracked))
		for _, filter in ipairs({ "HELPFUL|PLAYER", "HARMFUL" }) do
			local ok, list = pcall(GetUnitAuras, unit, filter, 16, SORT, 1)
			if not ok then
				Add(filter .. " : erreur " .. tostring(list))
			elseif issecret(list) then
				Add(filter .. " : liste secrète")
			elseif type(list) ~= "table" then
				Add(filter .. " : " .. type(list))
			else
				Add(("%s : %d aura(s)"):format(filter, #list))
				for i = 1, math.min(#list, 3) do
					local aura = list[i]
					if issecret(aura) then Add("  aura secrète") else
						local okT, isTracked = pcall(IsTracked, aura)
						Add(("  nom %s, icône %s, sort %s, instance %s, suivie %s"):format(Describe(aura.name), Describe(aura.icon),
							Describe(aura.spellId), Describe(aura.auraInstanceID), okT and Describe(isTracked) or "erreur"))
					end
				end
			end
		end
		local hots, debuffs = 0, 0
		for _, icon in ipairs(b.hots) do if icon:IsShown() then hots = hots + 1 end end
		for _, icon in ipairs(b.debuffs) do if icon:IsShown() then debuffs = debuffs + 1 end end
		Add(("icônes affichées : soins %d, affaiblissements %d, opacité du calque %s"):format(hots, debuffs,
			Describe(b.over:GetEffectiveAlpha())))
		local ok, err = pcall(UpdateAuras, b)
		Add("mise à jour : " .. (ok and "sans erreur" or tostring(err)))
	end
end

-- Chaque ligne est gardée au fur et à mesure : un plantage n'efface pas ce qui a déjà été trouvé
function Z.DiagnoseAuras()
	local lines = {}
	-- une ligne devenue secrète (valeur du jeu mêlée au texte) est remplacée : rien ne doit planter
	local ok, err = pcall(Diagnose, function(text) lines[#lines + 1] = issecret(text) and "(ligne secrète)" or tostring(text) end)
	if not ok then lines[#lines + 1] = "diagnostic interrompu : " .. tostring(err) end
	for _, text in ipairs(lines) do Z:Print(text) end
	Z:Log("Diagnostic auras", table.concat(lines, " | "), "")
end
