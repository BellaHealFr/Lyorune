-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Containers.lua : les icônes d'auras des vraies cases, dessinées par le jeu.
-- En combat, le jeu refuse à tout addon la lecture des auras (« auras secrètes »). Il prête en revanche des
-- conteneurs : Lyorune leur dit quoi montrer (filtres, numéros de sorts) et où, le jeu y dessine les auras,
-- leur durée et la couleur de dissipation. Rien n'est lu, rien ne tourne en boucle.
-- Quatre conteneurs par case :
--   hots    : mes soins sur la durée en icônes (en haut à gauche)
--   bars    : les mêmes en barres fines (style « Barres »)
--   debuffs : affaiblissements (en bas à droite), celui que je peux dissiper en premier
--   slots   : places fixes : un carré par coin, la bordure de dissipation, la grande icône et son contour
-- Si le jeu n'a pas ces conteneurs, Auras.lua garde l'ancien affichage (lecture des auras).

local _, Z = ...
local UI = Z.UI
local issecret = Z.IsSecret

local BASE = 16          -- taille de construction d'une icône ; le conteneur est ensuite mis à l'échelle
local SPACING = 2
local MAX_HOTS = 4
local BUTTON = "LyoruneAuraButton"

-- Les conteneurs existent-ils dans ce client ? (lu à chaque fois : un changement de version du jeu suffit)
function Z.HasAuraBoxes()
	return AuraContainerSortMethod ~= nil and AnchorUtil ~= nil and AnchorUtil.FlowDirection ~= nil
		and Enum.CustomAuraButtonDispelTypeTextureStyle ~= nil
end

-- Appel protégé d'une méthode du jeu : une erreur est notée une fois au journal, jamais avalée sans trace
local logged = {}
local function Call(object, method, ...)
	local f = object and object[method]
	if not f then return end
	local ok, result = pcall(f, object, ...)
	if ok then return result end
	if not logged[method] then
		logged[method] = true
		Z:Log("Conteneur d'auras", method .. " : " .. tostring(result), "")
	end
end

----------------------------------------------------------------------------------------------------
-- Numéros de sorts. Le jeu filtre par numéro, Lyorune connaît des noms (réglages, listes).
-- Un nom donne : le nombre tapé par le joueur, le sort de mon grimoire, et les numéros vus sur les auras
-- quand elles étaient lisibles (hors combat), gardés dans LyoruneDB.auraIds pour les sessions suivantes.
----------------------------------------------------------------------------------------------------
local function Seen()
	Z.db.auraIds = Z.db.auraIds or {}
	return Z.db.auraIds
end

local function AddIds(set, name)
	if type(name) ~= "string" or name == "" then return end
	local number = tonumber(name)
	if number then set[number] = true return end
	local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(name)
	if type(info) == "table" and info.spellID then set[info.spellID] = true end
	local seen = Seen()[name]
	if type(seen) == "table" then
		for id in pairs(seen) do set[id] = true end
	end
end

local function Empty(set) return next(set) == nil end

-- Les numéros voulus par chaque élément, selon les réglages et la classe jouée
local function Wanted()
	local db = Z.db
	local corners, inCorner = {}, {}
	for point, name in pairs(Z.MyCorners()) do
		if name ~= "" then
			local set = {}
			AddIds(set, name)
			if not Empty(set) then
				corners[point] = set
				for id in pairs(set) do inCorner[id] = true end
			end
		end
	end
	local hots = {}
	for _, id in ipairs(Z.trackedSpells[Z.class] or {}) do
		hots[id] = true
		AddIds(hots, Z.SpellName(id))
	end
	for name in pairs(db.extraTracked) do AddIds(hots, name) end
	for id in pairs(inCorner) do hots[id] = nil end -- un sort placé dans un coin n'est plus dans la rangée
	local ignored = {}
	for id in pairs(Z.ignoredDebuffs) do ignored[id] = true end
	for name in pairs(db.ignoredNames) do AddIds(ignored, name) end
	local important = {}
	for name in pairs(db.importantNames) do AddIds(important, name) end
	return hots, corners, ignored, important
end

-- Un nom qui intéresse Lyorune (soins suivis, coins, listes) : son numéro vaut la peine d'être retenu
local function Interesting(name)
	local db = Z.db
	if Z.trackedNames[name] or db.extraTracked[name] or db.ignoredNames[name] or db.importantNames[name] then
		return true
	end
	for _, wanted in pairs(Z.MyCorners()) do
		if wanted == name then return true end
	end
end

-- Appelé par Auras.lua quand une aura est lisible (hors combat) : un numéro nouveau met les filtres à jour
local refilterQueued
function Z.LearnAuraId(name, id)
	if not name or not id or issecret(name) or issecret(id) or not Z.HasAuraBoxes() then return end
	if not Interesting(name) then return end
	local seen = Seen()
	if type(seen[name]) ~= "table" then seen[name] = {} end
	if seen[name][id] then return end
	seen[name][id] = true
	if not refilterQueued then
		refilterQueued = true
		C_Timer.After(0, function()
			refilterQueued = false
			Z:Try("filtres des auras", Z.RefreshAuraBoxes)
		end)
	end
end

----------------------------------------------------------------------------------------------------
-- Habillage des boutons créés par le jeu. Chaque bouton reçoit ses textures une seule fois ;
-- les réglages (cercle, décompte, charges, fondu) sont repris à chaque changement d'options.
----------------------------------------------------------------------------------------------------
local function Silent(button)
	Call(button, "EnableMouse", false) -- les clics vont à la case (clic-soin), jamais aux icônes
	Call(button, "SetMouseClickEnabled", false)
	Call(button, "SetMouseMotionEnabled", false)
end

local function NewCooldown(parent)
	local cooldown = CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate")
	cooldown:SetAllPoints()
	cooldown:SetReverse(true)
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawEdge(false)
	return cooldown
end

-- Icône d'aura : image, bordure, cercle de durée, charges ; mine = un de mes soins
local function DressIcon(button, mine)
	Silent(button)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.lyoBorder = UI.Border(button, 1, 1)
	button.lyoCooldown = NewCooldown(button)
	button.lyoCount = UI.Text(button.lyoBorder, 9, "OUTLINE")
	button.lyoCount:SetPoint("BOTTOMRIGHT", 2, -2)
	button.lyoMine = mine
	Call(button, "SetIcon", icon)
	Call(button, "SetDurationCooldown", button.lyoCooldown)
	Call(button, "SetApplicationCount", button.lyoCount, {})
	if mine then
		-- Fin du soin : le jeu affiche ce voile pendant les derniers instants (réglage « hotFade »)
		button.lyoVeil = button:CreateTexture(nil, "OVERLAY")
		button.lyoVeil:SetAllPoints()
		button.lyoVeil:SetColorTexture(0, 0, 0, 0.55)
		Call(button, "AddPandemicRegion", button.lyoVeil)
	end
end

local function StyleIcon(button)
	local db, mine = Z.db, button.lyoMine
	local cooldown = button.lyoCooldown
	cooldown:SetDrawSwipe(not mine or db.hotSwipe)
	cooldown:SetHideCountdownNumbers(not (mine and db.hotCountdown))
	if mine and db.hotCountdown and cooldown.SetCountdownFont and not button.lyoSmall then
		button.lyoSmall = true
		cooldown:SetCountdownFont("GameFontHighlightSmallOutline")
	end
	button.lyoCount:SetAlpha((not mine or db.hotCharges) and 1 or 0)
	if button.lyoVeil then button.lyoVeil:SetAlpha(db.hotFade and 1 or 0) end
end

-- Barre fine : elle se vide avec la durée restante, couleur selon son rang
local function DressBar(button, index)
	Silent(button)
	local bar = CreateFrame("StatusBar", nil, button)
	bar:SetPoint("TOPLEFT")
	bar:SetHeight(3)
	bar:SetStatusBarTexture(UI.WHITE)
	local bg = UI.Tex(bar, "BACKGROUND", 0, 0, 0, 0.6)
	bg:SetAllPoints()
	local color = Z.BAR_COLORS[index] or Z.BAR_COLORS[1]
	bar:SetStatusBarColor(color[1], color[2], color[3])
	button.lyoBar = bar
	Call(button, "SetDurationBar", bar, { direction = Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime })
end

----------------------------------------------------------------------------------------------------
-- Construction des conteneurs d'une case (une fois, à l'arrivée de son premier joueur)
----------------------------------------------------------------------------------------------------
local function NewBox(b, level)
	local ok, box = pcall(CreateFrame, "AuraContainer", nil, b.over, "LyoruneAuraBox")
	if not ok or not box then return end
	Call(box, "EnableMouse", false)
	Call(box, "SetFrameLevel", b.over:GetFrameLevel() + level)
	return box
end

local function Flow(box, point, horizontal, vertical, axis)
	Call(box, "SetFlowLayoutAnchorPoint", point)
	Call(box, "SetFlowLayoutAxis", axis or AnchorUtil.FlowLayoutAxis.Horizontal)
	Call(box, "SetFlowLayoutGrowthDirection", horizontal, vertical)
	Call(box, "SetFlowLayoutPadding", 0, 0, 0, 0)
end

-- Groupe d'auras : le jeu crée les boutons à la demande et les range lui-même
local function Group(b, box, key, filter, max, index, width, height, dress)
	b.boxButtons[key] = {}
	local made = 0
	Call(box, "AddAuraGroup", key, filter, {
		maxFrameCount = max,
		sortMethod = AuraContainerSortMethod.Default,
		sortDirection = AuraContainerSortDirection and AuraContainerSortDirection.Normal,
		templateNames = { BUTTON },
		layout = { elementWidth = width, elementHeight = height, elementSpacing = SPACING, lineSpacing = SPACING, layoutIndex = index },
		initializeFrame = function(button)
			made = made + 1
			dress(button, made)
			table.insert(b.boxButtons[key], button)
		end,
	})
end

-- Place fixe : un seul bouton, que Lyorune place lui-même
local function Slot(b, key, filter, dress)
	local button = Call(b.boxes.slots, "AddAuraSlot", key, filter, {
		templateNames = { BUTTON },
		initializeFrame = function(button) dress(button) end,
	})
	b.slots[key] = button
	return button
end

local function DressCorner(point)
	return function(button)
		Silent(button)
		button.lyoFill = button:CreateTexture(nil, "ARTWORK")
		button.lyoFill:SetAllPoints()
		local color = Z.CORNER_COLORS[point]
		button.lyoFill:SetColorTexture(color[1], color[2], color[3], 1)
		local border = UI.Border(button, 1, 1)
		border:SetColor(0, 0, 0, 1)
		button.lyoCooldown = NewCooldown(button)
		Call(button, "SetDurationCooldown", button.lyoCooldown)
	end
end

-- Bordure et voile de dissipation : le jeu leur donne la couleur du type (courbe de Lyorune)
local function DressDispel(b)
	return function(button)
		Silent(button)
		button:SetAllPoints(b.over)
		local options = {
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
			showWhenHarmful = true, showWhenHelpful = false,
			customDispelColorCurve = Z.DispelCurve(),
		}
		local border = UI.Border(button, 2)
		border:SetRounded(true) -- crée l'image du contour arrondi, pour la confier au jeu elle aussi
		border:SetRounded(Z.db.corners == "ROUND")
		for i = 1, 4 do
			border[i]:SetVertexColor(1, 1, 1, 1)
			Call(button, "AddDispelTypeTexture", border[i], options)
		end
		Call(button, "AddDispelTypeTexture", border.round, options)
		local fill = button:CreateTexture(nil, "BACKGROUND")
		fill:SetAllPoints()
		fill:SetColorTexture(1, 1, 1, 1)
		fill:SetAlpha(0.18)
		Call(button, "AddDispelTypeTexture", fill, options)
		button.lyoBorder = border
	end
end

-- Affaiblissement important : grande icône à gauche, et contour lumineux qui pulse autour de la case
local function DressImportant(b)
	return function(button)
		Silent(button)
		button.lyoFace = CreateFrame("Frame", nil, button)
		button.lyoFace:SetAllPoints()
		local icon = button.lyoFace:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		UI.Border(button.lyoFace, 1, 1)
		local cooldown = NewCooldown(button.lyoFace)
		Call(button, "SetIcon", icon)
		Call(button, "SetDurationCooldown", cooldown)
		local glow = CreateFrame("Frame", nil, button)
		glow:SetAllPoints(b.over)
		local border = UI.Border(glow, 2, 2)
		border:SetColor(1, 0.82, 0.25, 1)
		local pulse = border:CreateAnimationGroup()
		pulse:SetLooping("BOUNCE")
		local fade = pulse:CreateAnimation("Alpha")
		fade:SetFromAlpha(1)
		fade:SetToAlpha(0.3)
		fade:SetDuration(0.6)
		pulse:Play()
		button.lyoGlow, button.lyoGlowBorder = glow, border
	end
end

local function Build(b)
	b.boxes, b.boxButtons, b.slots = {}, {}, {}
	local boxes = b.boxes
	boxes.hots = NewBox(b, 1)
	boxes.bars = NewBox(b, 1)
	boxes.debuffs = NewBox(b, 1)
	boxes.slots = NewBox(b, 4) -- au-dessus des icônes, sous les auras privées
	if not (boxes.hots and boxes.bars and boxes.debuffs and boxes.slots) then
		b.boxes = nil
		return false
	end
	local DIR = AnchorUtil.FlowDirection
	Flow(boxes.hots, "TOPLEFT", DIR.Right, DIR.Down)
	Flow(boxes.bars, "TOPLEFT", DIR.Right, DIR.Down, AnchorUtil.FlowLayoutAxis.Vertical)
	Flow(boxes.debuffs, "BOTTOMRIGHT", DIR.Left, DIR.Up)

	Group(b, boxes.hots, "hots", "HELPFUL|PLAYER", MAX_HOTS, 1, BASE, BASE, function(button) DressIcon(button, true) StyleIcon(button) end)
	Group(b, boxes.bars, "bars", "HELPFUL|PLAYER", MAX_HOTS, 1, 1, 3, function(button, index)
		DressBar(button, index)
		button.lyoBar:SetWidth(math.floor(Z.CellSize() * 0.45))
	end)
	-- Celui que je peux dissiper d'abord, puis un autre (le total reste de deux, comme avant)
	Group(b, boxes.debuffs, "dispellable", "HARMFUL|RAID_PLAYER_DISPELLABLE", 1, 1, BASE, BASE, function(button) DressIcon(button) StyleIcon(button) end)
	Group(b, boxes.debuffs, "others", "HARMFUL", 1, 2, BASE, BASE, function(button) DressIcon(button) StyleIcon(button) end)

	for _, point in ipairs(Z.CORNERS) do Slot(b, point, "HELPFUL|PLAYER", DressCorner(point)) end
	Slot(b, "dispel", "HARMFUL|RAID_PLAYER_DISPELLABLE", DressDispel(b))
	Slot(b, "boss", "HARMFUL", DressImportant(b))
	Slot(b, "listed", "HARMFUL", DressImportant(b))
	return true
end

----------------------------------------------------------------------------------------------------
-- Réglages : filtres (que montrer) et places (où). Refait à chaque changement d'options.
----------------------------------------------------------------------------------------------------
local function NilIfEmpty(set) if set and next(set) then return set end end

local function GroupFilter(box, key, filter, candidates)
	Call(box, "SetAuraGroupFilterString", key, filter)
	Call(box, "SetAuraGroupCandidateFilters", key, candidates)
end

local function SlotFilter(b, key, filter, candidates)
	Call(b.boxes.slots, "SetAuraSlotFilterString", key, filter)
	Call(b.boxes.slots, "SetAuraSlotCandidateFilters", key, candidates)
end

local function ApplyFilters(b)
	local db = Z.db
	local hots, corners, ignored, important = Wanted()
	local boxes = b.boxes
	local wantHots = db.showHots and not Empty(hots)
	local hotFilter = wantHots and "HELPFUL|PLAYER" or ""
	GroupFilter(boxes.hots, "hots", hotFilter, { includeSpellIDs = NilIfEmpty(hots) })
	GroupFilter(boxes.bars, "bars", hotFilter, { includeSpellIDs = NilIfEmpty(hots) })
	for _, point in ipairs(Z.CORNERS) do
		local set = corners[point]
		SlotFilter(b, point, set and "HELPFUL|PLAYER" or "", { includeSpellIDs = set })
	end

	local excluded = NilIfEmpty(ignored)
	local canDispel = {}
	for kind in pairs(Z.canDispel or {}) do canDispel[kind] = true end
	GroupFilter(boxes.debuffs, "dispellable", db.showDebuffs and "HARMFUL|RAID_PLAYER_DISPELLABLE" or "",
		{ excludeSpellIDs = excluded })
	GroupFilter(boxes.debuffs, "others", (db.showDebuffs and db.debuffMode == "ALL") and "HARMFUL" or "",
		{ excludeSpellIDs = excluded, excludeDispelTypes = NilIfEmpty(canDispel) })
	SlotFilter(b, "dispel", db.showDispel and "HARMFUL|RAID_PLAYER_DISPELLABLE" or "", nil)

	local wantImportant = db.bossDebuffs or db.importantGlow
	SlotFilter(b, "boss", wantImportant and "HARMFUL" or "", { isBossAura = true })
	SlotFilter(b, "listed", (wantImportant and not Empty(important)) and "HARMFUL" or "", { includeSpellIDs = NilIfEmpty(important) })
end

local function Place(b)
	local db = Z.db
	local boxes, size = b.boxes, b.iconSize or 12
	local scale = size / BASE

	-- Icônes : construites à 16 pixels, le conteneur est mis à l'échelle de la case.
	-- Les décalages d'une ancre sont dans l'échelle du conteneur : on les divise.
	local dx, dy = Z.Offset("hots")
	local x, y = 2 + Z.CornerShift(b, "TOPLEFT") + dx, -2 + dy
	boxes.hots:SetScale(scale)
	boxes.hots:ClearAllPoints()
	boxes.hots:SetPoint("TOPLEFT", b.over, "TOPLEFT", x / scale, y / scale)
	boxes.hots:SetSize(MAX_HOTS * (BASE + SPACING), BASE)

	boxes.bars:ClearAllPoints()
	boxes.bars:SetPoint("TOPLEFT", b.over, "TOPLEFT", 3 + Z.CornerShift(b, "TOPLEFT") + dx, dy - 3)
	boxes.bars:SetSize(math.floor(Z.CellSize() * 0.45), MAX_HOTS * 4)

	local bars = db.hotStyle == "BARS"
	boxes.hots:SetShown(not bars)
	boxes.bars:SetShown(bars)

	dx, dy = Z.Offset("debuffs")
	x, y = -2 - Z.CornerShift(b, "BOTTOMRIGHT") + dx, 2 + dy
	boxes.debuffs:SetScale(scale)
	boxes.debuffs:ClearAllPoints()
	boxes.debuffs:SetPoint("BOTTOMRIGHT", b.over, "BOTTOMRIGHT", x / scale, y / scale)
	boxes.debuffs:SetSize(2 * (BASE + SPACING), BASE)

	boxes.slots:SetAllPoints(b.over)
	local cornerSize = Z.CornerSize(b)
	for _, point in ipairs(Z.CORNERS) do
		local square, sign = b.slots[point], Z.CORNER_SIGN[point]
		if square then
			square:SetSize(cornerSize, cornerSize)
			square:ClearAllPoints()
			square:SetPoint(point, b.over, point, sign[1] * 2, sign[2] * 2)
		end
	end

	dx, dy = Z.Offset("big")
	local big = math.floor(size * 1.6 + 0.5)
	for _, key in ipairs({ "boss", "listed" }) do
		local button = b.slots[key]
		if button then
			button:SetSize(big, big)
			button:ClearAllPoints()
			button:SetPoint("LEFT", b.over, "LEFT", 3 + dx, dy)
			if button.lyoFace then
				button.lyoFace:SetAlpha(db.bossDebuffs and 1 or 0)
				button.lyoGlow:SetAlpha(db.importantGlow and 1 or 0)
				button.lyoGlowBorder:SetRounded(db.corners == "ROUND")
			end
		end
	end
	local dispel = b.slots.dispel
	if dispel and dispel.lyoBorder then dispel.lyoBorder:SetRounded(db.corners == "ROUND") end

	for _, button in ipairs(b.boxButtons.hots or {}) do StyleIcon(button) end
	for _, key in ipairs({ "dispellable", "others" }) do
		for _, button in ipairs(b.boxButtons[key] or {}) do StyleIcon(button) end
	end
	for _, button in ipairs(b.boxButtons.bars or {}) do button.lyoBar:SetWidth(math.floor(Z.CellSize() * 0.45)) end
end

local function EachBox(b, method, ...)
	for _, box in pairs(b.boxes) do Call(box, method, ...) end
end

----------------------------------------------------------------------------------------------------
-- Points d'entrée (Frames.lua, Auras.lua)
----------------------------------------------------------------------------------------------------
-- Le joueur de la case change : les conteneurs le suivent. Créés à la première fois.
function Z.BindAuraBoxes(b)
	if not b.boxes then
		if b.boxesFailed or not Z.HasAuraBoxes() or not b.unit then return end
		local ok, err = pcall(function()
			assert(Build(b), "création refusée")
			ApplyFilters(b)
			Place(b)
		end)
		if not ok then
			-- l'ancien affichage reste en place pour cette case
			for _, box in pairs(b.boxes or {}) do Call(box, "SetUnit", "none") Call(box, "Hide") end
			b.boxes, b.boxesFailed = nil, true
			Z:Log("Conteneur d'auras", tostring(err), "")
			return
		end
		Z.HideAuras(b)
		Z.ShowDispel(b, false)
	end
	EachBox(b, "SetUnit", b.unit or "none")
	EachBox(b, "SetEnabled", b.unit ~= nil)
	if b.unit then EachBox(b, "UpdateAllAuras") end
end

-- Réglages changés (Frames.lua, Style) : filtres et places refaits
function Z.StyleAuraBoxes(b)
	if not b.boxes then return end
	local ok, err = pcall(function()
		ApplyFilters(b)
		Place(b)
	end)
	if not ok then Z:Log("Conteneur d'auras", tostring(err), "") end
	if b.unit then EachBox(b, "UpdateAllAuras") end
end

-- Toutes les cases : nouveau numéro de sort appris, sorts de la classe changés
function Z.RefreshAuraBoxes()
	for _, b in ipairs(Z.buttons or {}) do Z.StyleAuraBoxes(b) end
end

-- Case cible ou focalisation sur un ennemi : rien à lui montrer.
-- Ces cases gardent le même nom d'unité (« target ») quand le joueur visé change : on redemande les auras.
function Z.ShowAuraBoxes(b, shown)
	if not b.boxes then return end
	if b.extra and shown then EachBox(b, "UpdateAllAuras") end
	b.boxes.slots:SetShown(shown)
	b.boxes.debuffs:SetShown(shown)
	local bars = Z.db.hotStyle == "BARS"
	b.boxes.hots:SetShown(shown and not bars)
	b.boxes.bars:SetShown(shown and bars)
end
