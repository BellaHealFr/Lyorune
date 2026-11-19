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
local issecret = Z.IsSecret

local BASE = 16          -- taille de construction d'une icône ; le conteneur est ensuite mis à l'échelle
local SPACING = 2
local MAX_HOTS = 4

-- Les conteneurs existent-ils dans ce client ? (lu à chaque fois : un changement de version du jeu suffit)
function Z.HasAuraBoxes()
	return AuraContainerSortMethod ~= nil and AnchorUtil ~= nil and AnchorUtil.FlowDirection ~= nil
		and Enum.CustomAuraButtonDispelTypeTextureStyle ~= nil
end

-- Appel protégé d'une méthode du jeu : une erreur est notée une fois au journal, jamais avalée sans trace
local logged = {}
local function Call(object, method, ...)
	local f = type(object) == "table" and object[method]
	if not f then return end
	local ok, result = pcall(f, object, ...)
	if ok then return result end
	if not logged[method] then
		logged[method] = true
		Z:Log("Conteneur d'auras", method .. " : " .. tostring(result), "")
		Z:Print("Conteneur d'auras, " .. method .. " : " .. tostring(result))
	end
end

-- Pour /lyorune auras : l'état de chaque conteneur de la case, tel que le jeu le voit
local function Show(value)
	if issecret(value) then return "secret" end
	return tostring(value)
end

function Z.DescribeAuraBoxes(b, Add)
	for _, name in ipairs({ "hots", "bars", "debuffs", "slots" }) do
		local box = b.boxes[name]
		local ok, text = pcall(function()
			local point, relative, _, x, y = box:GetPoint()
			return ("%s : montré %s, visible %s, actif %s, joueur %s, taille %dx%d, échelle %.2f, opacité %.2f, ancre %s %s %d %d"):format(
				name, Show(box:IsShown()), Show(box:IsVisible()), Show(Call(box, "IsEnabled")), Show(Call(box, "GetUnit")),
				box:GetWidth(), box:GetHeight(), box:GetScale(), box:GetEffectiveAlpha(), tostring(point),
				tostring(relative and relative.GetName and relative:GetName() or relative), x or 0, y or 0)
		end)
		Add(ok and text or (name .. " : " .. tostring(text)))
	end
	-- Les boutons dessinés par le jeu peuvent répondre par des valeurs secrètes : tout passe par Show et pcall
	local function Frame(button)
		if not button then return "aucun" end
		local ok, text = pcall(function()
			return "montré " .. Show(button:IsShown()) .. ", visible " .. Show(button:IsVisible())
				.. ", taille " .. Show(button:GetWidth()) .. " x " .. Show(button:GetHeight())
				.. ", opacité " .. Show(button:GetEffectiveAlpha())
		end)
		return ok and text or ("illisible : " .. tostring(text))
	end
	for key, list in pairs(b.boxButtons) do
		local box = (key == "hots" and b.boxes.hots) or (key == "bars" and b.boxes.bars) or b.boxes.debuffs
		Add(("  groupe %s : boutons habillés %d, comptés par le jeu %s, premier %s"):format(key, #list,
			Show(Call(box, "GetAuraGroupFrameCount", key)), Frame(Call(box, "GetAuraGroupFrame", key, 1))))
	end
	for key, button in pairs(b.slots) do Add("  place " .. key .. " : " .. Frame(button)) end
	for method in pairs(logged) do Add("  erreur notée : " .. method) end
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
-- Habillage des boutons créés par le jeu. Ce sont des objets protégés : leurs textures viennent toutes de
-- Containers.xml. Lyorune ne les touche que pendant leur création (le jeu l'y autorise), ou plus tard quand
-- le jeu répond qu'ils sont accessibles (CanBeAccessedInContext). Tout passe par Call : jamais d'erreur.
----------------------------------------------------------------------------------------------------
-- Élément déclaré dans Containers.xml (nil s'il manque)
local function Part(object, key)
	return type(object) == "table" and object[key] or nil
end

local function Open(button)
	return button ~= nil and Call(button, "CanBeAccessedInContext") == true
end

local function Silent(button)
	Call(button, "EnableMouse", false) -- les clics vont à la case (clic-soin), jamais aux icônes
	Call(button, "SetMouseClickEnabled", false)
	Call(button, "SetMouseMotionEnabled", false)
end

-- Réglages d'une icône : cercle, décompte, charges, voile de fin (seulement pour mes soins)
local function StyleIcon(button, mine)
	local db = Z.db
	local cooldown = button.Cooldown
	Call(cooldown, "SetDrawSwipe", not mine or db.hotSwipe)
	Call(cooldown, "SetHideCountdownNumbers", not (mine and db.hotCountdown))
	if mine and db.hotCountdown then Call(cooldown, "SetCountdownFont", "GameFontHighlightSmallOutline") end
	Call(button.Texts, "SetAlpha", (not mine or db.hotCharges) and 1 or 0)
	Call(button.Veil, "SetAlpha", (mine and db.hotFade) and 1 or 0)
end

-- Icône d'aura ; mine = un de mes soins
local function DressIcon(button, mine)
	Silent(button)
	Call(button.Texts, "SetFrameLevel", (Call(button.Cooldown, "GetFrameLevel") or 1) + 1)
	Call(button, "SetIcon", button.Icon)
	Call(button, "SetDurationCooldown", button.Cooldown)
	Call(button, "SetApplicationCount", Part(button.Texts, "Count"), {})
	-- Fin du soin : le jeu montre ce voile pendant les derniers instants (réglage « hotFade »)
	if mine then Call(button, "AddPandemicRegion", button.Veil) end
	StyleIcon(button, mine)
end

-- Barre fine : couleur selon son rang, largeur selon la case
local function DressBar(button, index)
	Silent(button)
	local color = Z.BAR_COLORS[index] or Z.BAR_COLORS[1]
	Call(button.Bar, "SetStatusBarColor", color[1], color[2], color[3])
	Call(button.Bar, "SetWidth", math.floor(Z.CellSize() * 0.45))
	Call(button, "SetDurationBar", button.Bar, { direction = Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime })
end

-- Places fixes : position et taille, refaites à chaque changement d'options quand le jeu l'autorise
local function PlaceCorner(b, button, point)
	local size, sign = Z.CornerSize(b), Z.CORNER_SIGN[point]
	Call(button, "SetSize", size, size)
	Call(button, "ClearAllPoints")
	Call(button, "SetPoint", point, b.boxes.slots, point, sign[1] * 2, sign[2] * 2)
end

local function PlaceBig(b, button)
	local db = Z.db
	local dx, dy = Z.Offset("big")
	local big = math.floor((b.iconSize or 12) * 1.6 + 0.5)
	Call(button, "SetAllPoints", b.boxes.slots)
	Call(button.Face, "SetSize", big, big)
	Call(button.Face, "ClearAllPoints")
	Call(button.Face, "SetPoint", "LEFT", button, "LEFT", 3 + dx, dy)
	Call(button.Face, "SetShown", db.bossDebuffs)
	Call(button.Glow, "SetShown", db.importantGlow)
end

local function DressCorner(b, point)
	return function(button)
		Silent(button)
		local color = Z.CORNER_COLORS[point]
		Call(button.Fill, "SetVertexColor", color[1], color[2], color[3], 1)
		Call(button, "SetDurationCooldown", button.Cooldown)
		PlaceCorner(b, button, point)
	end
end

local function DressDispel(b)
	return function(button)
		Silent(button)
		Call(button, "SetAllPoints", b.boxes.slots)
		local options = {
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
			showWhenHarmful = true, showWhenHelpful = false,
			customDispelColorCurve = Z.DispelCurve(),
		}
		for _, key in ipairs({ "Top", "Bottom", "Left", "Right", "Fill" }) do
			Call(button, "AddDispelTypeTexture", button[key], options)
		end
	end
end

local function DressBig(b)
	return function(button)
		Silent(button)
		Call(button, "SetIcon", Part(button.Face, "Icon"))
		Call(button, "SetDurationCooldown", Part(button.Face, "Cooldown"))
		Call(Part(button.Glow, "Pulse"), "Play")
		PlaceBig(b, button)
	end
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
local function Group(b, box, key, filter, max, index, template, width, height, dress)
	b.boxButtons[key] = {}
	local made = 0
	Call(box, "AddAuraGroup", key, filter, {
		maxFrameCount = max,
		sortMethod = AuraContainerSortMethod.Default,
		sortDirection = AuraContainerSortDirection and AuraContainerSortDirection.Normal,
		templateNames = { template },
		layout = { elementWidth = width, elementHeight = height, elementSpacing = SPACING, lineSpacing = SPACING, layoutIndex = index },
		initializeFrame = function(button)
			made = made + 1
			dress(button, made)
			table.insert(b.boxButtons[key], button)
		end,
	})
end

-- Place fixe : un seul bouton, que Lyorune place lui-même
local function Slot(b, key, filter, template, dress)
	local button = Call(b.boxes.slots, "AddAuraSlot", key, filter, {
		templateNames = { template },
		initializeFrame = function(button) dress(button) end,
	})
	b.slots[key] = button
	return button
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
	Call(boxes.slots, "SetAllPoints", b.over)
	local DIR = AnchorUtil.FlowDirection
	Flow(boxes.hots, "TOPLEFT", DIR.Right, DIR.Down)
	Flow(boxes.bars, "TOPLEFT", DIR.Right, DIR.Down, AnchorUtil.FlowLayoutAxis.Vertical)
	Flow(boxes.debuffs, "BOTTOMRIGHT", DIR.Left, DIR.Up)

	Group(b, boxes.hots, "hots", "HELPFUL|PLAYER", MAX_HOTS, 1, "LyoruneAuraIcon", BASE, BASE,
		function(button) DressIcon(button, true) end)
	Group(b, boxes.bars, "bars", "HELPFUL|PLAYER", MAX_HOTS, 1, "LyoruneAuraBar", 1, 3, DressBar)
	-- Celui que je peux dissiper d'abord, puis un autre (le total reste de deux, comme avant)
	Group(b, boxes.debuffs, "dispellable", "HARMFUL|RAID_PLAYER_DISPELLABLE", 1, 1, "LyoruneAuraIcon", BASE, BASE,
		function(button) DressIcon(button, false) end)
	Group(b, boxes.debuffs, "others", "HARMFUL", 1, 2, "LyoruneAuraIcon", BASE, BASE,
		function(button) DressIcon(button, false) end)

	for _, point in ipairs(Z.CORNERS) do Slot(b, point, "HELPFUL|PLAYER", "LyoruneAuraSquare", DressCorner(b, point)) end
	Slot(b, "dispel", "HARMFUL|RAID_PLAYER_DISPELLABLE", "LyoruneAuraCover", DressDispel(b))
	Slot(b, "boss", "HARMFUL", "LyoruneAuraBig", DressBig(b))
	Slot(b, "listed", "HARMFUL", "LyoruneAuraBig", DressBig(b))
	return true
end

----------------------------------------------------------------------------------------------------
-- Réglages : filtres (que montrer) et places (où). Refait à chaque changement d'options.
----------------------------------------------------------------------------------------------------
local function NilIfEmpty(set) if set and next(set) then return set end end

-- Groupe coupé : aucune icône permise (le jeu ne connaît pas de filtre vide pour un groupe)
local GROUP_MAX = { hots = MAX_HOTS, bars = MAX_HOTS, dispellable = 1, others = 1 }
local function GroupFilter(box, key, filter, candidates)
	if filter == "" then
		Call(box, "SetAuraGroupMaxFrameCount", key, 0)
		return
	end
	Call(box, "SetAuraGroupFilterString", key, filter)
	Call(box, "SetAuraGroupCandidateFilters", key, candidates)
	Call(box, "SetAuraGroupMaxFrameCount", key, GROUP_MAX[key])
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
	Call(boxes.hots, "SetScale", scale)
	Call(boxes.hots, "ClearAllPoints")
	Call(boxes.hots, "SetPoint", "TOPLEFT", b.over, "TOPLEFT", x / scale, y / scale)
	Call(boxes.hots, "SetSize", MAX_HOTS * (BASE + SPACING), BASE)

	Call(boxes.bars, "ClearAllPoints")
	Call(boxes.bars, "SetPoint", "TOPLEFT", b.over, "TOPLEFT", 3 + Z.CornerShift(b, "TOPLEFT") + dx, dy - 3)
	Call(boxes.bars, "SetSize", math.floor(Z.CellSize() * 0.45), MAX_HOTS * 4)

	local bars = db.hotStyle == "BARS"
	Call(boxes.hots, "SetShown", not bars)
	Call(boxes.bars, "SetShown", bars)

	dx, dy = Z.Offset("debuffs")
	x, y = -2 - Z.CornerShift(b, "BOTTOMRIGHT") + dx, 2 + dy
	Call(boxes.debuffs, "SetScale", scale)
	Call(boxes.debuffs, "ClearAllPoints")
	Call(boxes.debuffs, "SetPoint", "BOTTOMRIGHT", b.over, "BOTTOMRIGHT", x / scale, y / scale)
	Call(boxes.debuffs, "SetSize", 2 * (BASE + SPACING), BASE)

	-- Boutons déjà créés par le jeu : seulement s'il nous laisse y toucher (sinon, à la prochaine occasion)
	for _, point in ipairs(Z.CORNERS) do
		if Open(b.slots[point]) then PlaceCorner(b, b.slots[point], point) end
	end
	for _, key in ipairs({ "boss", "listed" }) do
		if Open(b.slots[key]) then PlaceBig(b, b.slots[key]) end
	end
	for _, button in ipairs(b.boxButtons.hots or {}) do
		if Open(button) then StyleIcon(button, true) end
	end
	for _, key in ipairs({ "dispellable", "others" }) do
		for _, button in ipairs(b.boxButtons[key] or {}) do
			if Open(button) then StyleIcon(button, false) end
		end
	end
	for _, button in ipairs(b.boxButtons.bars or {}) do
		if Open(button) then Call(button.Bar, "SetWidth", math.floor(Z.CellSize() * 0.45)) end
	end
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
	Call(b.boxes.slots, "SetShown", shown)
	Call(b.boxes.debuffs, "SetShown", shown)
	local bars = Z.db.hotStyle == "BARS"
	Call(b.boxes.hots, "SetShown", shown and not bars)
	Call(b.boxes.bars, "SetShown", shown and bars)
end
