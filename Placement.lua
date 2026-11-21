-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Placement.lua : l'éditeur de placement.
-- Chaque élément de la case (nom, texte de vie, icônes...) se décale au pixel près sur une case d'exemple
-- agrandie : on le glisse à la souris, ou on le pousse avec les flèches. Le décalage est gardé pour chaque
-- forme de case (Barre, Tuile, Carré, Bandeau), car chaque forme a sa propre disposition d'origine.
-- Les icônes se grandissent ou se rapetissent aussi (molette, « - » et « + »), de 50 à 200 % de leur taille
-- d'origine, gardée par forme avec le décalage. Le nom et le texte de vie suivent la taille de la police, les auras
-- privées leur propre réglage en pixels (un seul réglage pour chaque taille).
-- Un seul réglage : Z.db.placement (Core.lua). Frames.lua, Auras.lua et Themes.lua lisent Z.Offset et
-- Z.ElementSize en posant chaque élément.

local _, Z = ...
local UI = Z.UI
local L = Z.L

-- Les éléments que l'on peut placer, dans l'ordre de la liste
Z.placeElements = {
	{ "name", "Nom" },
	{ "text", "Texte de vie" },
	{ "role", "Icône de rôle" },
	{ "marker", "Marqueur de raid" },
	{ "leader", "Chef de groupe" },
	{ "center", "Icône centrale" },
	{ "lowMana", "Mana basse d'un soigneur" },
	{ "hots", "Mes soins sur la durée" },
	{ "debuffs", "Affaiblissements" },
	{ "big", "Affaiblissement important" },
	{ "controls", "Joueur sous contrôle" },
	{ "defensives", "Gros défensifs" },
	{ "buff", "Buff manquant" },
	{ "private", "Auras privées" },
}
local KNOWN = {}
for _, element in ipairs(Z.placeElements) do KNOWN[element[1]] = true end
-- Ceux dont la taille se règle ici : les icônes (le nom, le texte de vie et les auras privées ont leur réglage)
local SIZED = { role = true, marker = true, leader = true, center = true, lowMana = true, hots = true,
	debuffs = true, big = true, buff = true, controls = true, defensives = true }

function Z.IsPlaceElement(key)
	return KNOWN[key] == true
end

-- Un décalage entier, borné par Z.limits.placement
local function Limit(value)
	local limit = Z.limits.placement
	value = math.floor((tonumber(value) or 0) + 0.5)
	return math.max(limit[1], math.min(limit[2], value))
end

-- Une taille en %, entière, bornée par Z.limits.placement.size
local function LimitSize(value)
	local limit = Z.limits.placement.size
	value = math.floor((tonumber(value) or 100) + 0.5)
	return math.max(limit[1], math.min(limit[2], value))
end

-- Entrée enregistrée d'un élément, pour la forme choisie ou une autre
local function Entry(key, shape)
	local db = Z.db
	local all = db and type(db.placement) == "table" and db.placement[shape or db.shape]
	local at = type(all) == "table" and all[key]
	return type(at) == "table" and at or nil
end

-- Décalage enregistré, tel quel (seulement borné par Z.limits.placement)
local function Saved(key)
	local at = Entry(key)
	if not at then return 0, 0 end
	return Limit(at[1]), Limit(at[2])
end

-- Taille enregistrée, en % (100 : taille d'origine)
local function SavedSize(key, shape)
	local at = Entry(key, shape)
	return (at and at[3]) and LimitSize(at[3]) or 100
end

-- Élément dont la taille se règle dans l'éditeur (code de partage)
function Z.IsSizedElement(key)
	return SIZED[key] == true
end

-- La taille de cet élément se règle-t-elle dans l'éditeur ? Les barres fines des soins gardent leurs 3 pixels.
function Z.CanSize(key)
	return SIZED[key] == true and not (key == "hots" and Z.db.hotStyle == "BARS")
end

-- Facteur de taille d'un élément pour la forme choisie (1 : taille d'origine)
function Z.ElementScale(key)
	if not SIZED[key] then return 1 end
	return SavedSize(key) / 100
end

-- Taille d'un élément carré : sa taille d'origine (base) fois sa taille dans l'éditeur, jamais plus grande que
-- la case. Les rangées de soins et d'affaiblissements ont leur propre calcul (Z.AuraRows, Themes.lua).
function Z.ElementSize(key, base)
	local W, H = Z.CellSize()
	return math.max(1, math.min(math.floor(base * Z.ElementScale(key) + 0.5), W, H))
end

-- Taille d'origine de la couronne du chef : un petit badge sur une ligne (Barre, Bandeau), sinon une icône
function Z.BadgeSize(icon)
	return Z:Shape().inline and math.max(8, math.floor(icon * 0.7)) or icon - 2
end

-- Grande icône d'affaiblissement (vraies cases, conteneurs du jeu, éditeur)
function Z.BigIconSize()
	return Z.ElementSize("big", math.floor(Z.IconSize() * 1.6 + 0.5))
end

----------------------------------------------------------------------------------------------------
-- Jamais hors de la case : chaque décalage est borné par la place qui reste entre l'élément, à sa place
-- d'origine, et le bord de la case. Calcul fait à partir des tailles, sans mesure à l'écran (les vraies cases
-- sont protégées, et la largeur d'un nom change d'un joueur à l'autre). Un élément déjà en partie dehors à sa
-- place d'origine (le marqueur de raid, à cheval sur le haut) ne va pas plus loin de ce côté.
-- Le nom et le texte de vie rétrécissent près du bord au lieu d'en sortir (un nom long finit par « ... »).
-- Les places d'origine ci-dessous sont celles posées par PlaceTexts (Frames.lua), Auras.lua et Containers.lua ;
-- les rangées d'icônes et le chiffre de vie en Bandeau viennent tous de Z.AuraRows (Themes.lua). Elles changent ensemble. La sauvegarde n'est jamais réécrite : un ancien décalage trop grand est ramené au bord
-- à la lecture, et retrouve sa valeur si la case grandit.
----------------------------------------------------------------------------------------------------
local ICON_GAP = 2 -- écart entre deux icônes d'une rangée (Auras.lua, Containers.lua)
local TEXT_MIN = 3 -- largeur la plus petite d'un texte poussé au bord, en tailles de police

-- Rectangle { gauche, droite, bas, haut } d'un élément de taille w × h dont le point « point » est en (x, y).
-- Coordonnées de la case : (0, 0) en bas à gauche.
local function Box(point, x, y, w, h)
	local left = point:find("LEFT") and x or point:find("RIGHT") and x - w or x - w / 2
	local bottom = point:find("BOTTOM") and y or point:find("TOP") and y - h or y - h / 2
	return { left, left + w, bottom, bottom + h }
end

-- Position d'un point d'un rectangle
local function Spot(rect, point, x, y)
	local px = point:find("LEFT") and rect[1] or point:find("RIGHT") and rect[2] or (rect[1] + rect[2]) / 2
	local py = point:find("BOTTOM") and rect[3] or point:find("TOP") and rect[4] or (rect[3] + rect[4]) / 2
	return px + (x or 0), py + (y or 0)
end

-- Place d'origine de chaque élément, avec ou sans barre de mana sous la barre de vie. roleRect : rectangle de
-- l'icône de rôle, où s'accroche le chef de groupe (absent : pas de chef de groupe). Chaque entrée :
-- { point, x, y, largeur, hauteur }, plus « text » pour un texte qui peut rétrécir.
local function Origins(power, roleRect)
	local db, theme = Z.db, Z:Theme()
	local W, H = Z.CellSize()
	local inset = UI.Inset(theme.borderSize, db.corners == "ROUND")
	local icon = Z.IconSize()
	local sizes = { iconSize = icon }
	local function Shift(point) return Z.CornerShift(sizes, point) end
	local font = db.fontSize + (theme.fontBonus or 0)
	local hp = { inset, W - inset, inset + (power and Z.PowerHeight() + 1 or 0), H - inset }
	local cell = { 0, W, 0, H }
	local rows = Z.AuraRows() -- rangées d'icônes et textes sur une ligne, selon la forme (Themes.lua)
	local o = {}
	local function Put(key, point, rect, relative, x, y, w, h, text)
		local ax, ay = Spot(rect, relative, x, y)
		o[key] = { point, ax, ay, w, h, text = text }
	end

	local role, badge = Z.ElementSize("role", icon - 2), Z.ElementSize("leader", Z.BadgeSize(icon))
	if Z:Shape().inline then
		Put("role", "LEFT", hp, "LEFT", 3, 0, role, role)
		Put("name", "LEFT", hp, "LEFT", rows.nameX, 0, rows.nameW, font + 2, true)
		Put("text", "RIGHT", hp, "RIGHT", rows.textX, 0, rows.textW, font + 1, true)
		if roleRect then Put("leader", "CENTER", roleRect, "TOPRIGHT", 0, 0, badge, badge) end
	else
		Put("role", "TOPRIGHT", cell, "TOPRIGHT", -2 - Shift("TOPRIGHT"), -2, role, role)
		Put("name", "CENTER", hp, "CENTER", 0, 3, W - 8, font + 2, true)
		Put("text", "BOTTOM", hp, "BOTTOM", 0, 4, W - 8, font + 1, true)
		if roleRect then Put("leader", "TOPRIGHT", roleRect, "TOPLEFT", -1, 0, badge, badge) end
	end
	local marker, center = Z.ElementSize("marker", icon), Z.ElementSize("center", icon + 8)
	local lowMana = Z.ElementSize("lowMana", icon - 1)
	Put("marker", "CENTER", cell, "TOP", 0, -1, marker, marker)
	Put("center", "CENTER", cell, "CENTER", 0, 0, center, center)
	Put("lowMana", "BOTTOMLEFT", hp, "BOTTOMLEFT", 2, 2, lowMana, lowMana)

	-- Rangées : toutes les icônes réglées (la rangée la plus longue que la case montrera), sur une ou deux lignes
	local function Row(key, row)
		Put(key, row.point, row.relative == "HP" and hp or cell, row.point, row.x, row.y, row.width, row.height)
	end
	if db.hotStyle == "BARS" then
		Put("hots", "TOPLEFT", cell, "TOPLEFT", 3 + Shift("TOPLEFT"), -3, math.floor(W * 0.45), db.hotCount * 4)
	else
		Row("hots", rows.hots)
	end
	Row("debuffs", rows.debuffs)
	Row("defensives", rows.defensives)
	Row("controls", rows.controls)
	local big, buff = Z.BigIconSize(), Z.ElementSize("buff", icon)
	Put("big", "LEFT", cell, "LEFT", 3, 0, big, big)
	Put("buff", "BOTTOMLEFT", cell, "BOTTOMLEFT", 2 + Shift("BOTTOMLEFT"), 2, buff, buff)
	local size, point = db.privateAuraSize, db.privateAuraPoint
	local spot = Z.PRIVATE_OFFSETS[point] or Z.PRIVATE_OFFSETS.CENTER
	if not Z.PRIVATE_OFFSETS[point] then point = "CENTER" end
	Put("private", point, cell, point, spot[1], spot[2], Z.PRIVATE_SLOTS * (size + ICON_GAP) - ICON_GAP, size)
	return o
end

-- Bornes { gauche, droite, bas, haut } du décalage d'un élément : jusqu'au bord de la case, sans dépasser
-- Z.limits.placement. Un texte peut s'approcher du bord tant qu'il garde TEXT_MIN tailles de police de large.
-- home : la place d'origine quand elle diffère de spec (le chef de groupe, quand l'icône de rôle a bougé) ; la
-- zone permise est la case, agrandie de la place d'origine si l'élément y dépasse déjà. Le décalage peut alors
-- devoir être positif pour rentrer dans la case (chef de groupe poussé dehors par l'icône de rôle).
local function Range(spec, W, H, home)
	local point, x, y, w, h = spec[1], spec[2], spec[3], spec[4], spec[5]
	local rect = Box(point, x, y, w, h)
	local origin = home and Box(home[1], home[2], home[3], home[4], home[5]) or rect
	local lowX, highX = math.min(0, origin[1]) - rect[1], math.max(W, origin[2]) - rect[2]
	local lowY, highY = math.min(0, origin[3]) - rect[3], math.max(H, origin[4]) - rect[4]
	if spec.text then
		local least = math.min(w, TEXT_MIN * (h - 2))
		if point:find("LEFT") then
			highX = math.max(0, W - x - least)
		elseif point:find("RIGHT") then
			lowX = math.min(0, least - x)
		else
			lowX, highX = math.min(0, least / 2 - x), math.max(0, W - x - least / 2)
		end
	end
	-- Dans les limites du réglage, et jamais à l'envers
	local limit = Z.limits.placement
	local function Within(low, high)
		low = math.max(limit[1], math.min(limit[2], math.ceil(low)))
		return low, math.max(low, math.min(limit[2], math.floor(high)))
	end
	lowX, highX = Within(lowX, highX)
	lowY, highY = Within(lowY, highY)
	return { lowX, highX, lowY, highY }
end

-- Garde la partie commune de deux bornes (jamais à l'envers : la borne basse l'emporte)
local function Common(a, b)
	if not a then return b end
	local low, lowY = math.max(a[1], b[1]), math.max(a[3], b[3])
	return { low, math.max(low, math.min(a[2], b[2])), lowY, math.max(lowY, math.min(a[4], b[4])) }
end

local function Clamp(range, x, y)
	return math.max(range[1], math.min(range[2], x)), math.max(range[3], math.min(range[4], y))
end

-- Bornes de tous les éléments, gardées jusqu'au prochain changement (Z:Refresh, placement, taille des cases)
local cache
local function Ranges()
	local db = Z.db
	local W, H = Z.CellSize()
	if cache and cache.db == db and cache.shape == db.shape and cache.W == W and cache.H == H then return cache end
	-- Une case a sa barre de mana ou non selon le joueur : les bornes valent pour les deux
	local powers = db.manaBars ~= "OFF" and { false, true } or { false }
	local ranges, specs = {}, nil
	for _, power in ipairs(powers) do
		specs = Origins(power)
		for key, spec in pairs(specs) do ranges[key] = Common(ranges[key], Range(spec, W, H)) end
	end
	-- Le chef de groupe s'accroche à l'icône de rôle, là où son propre décalage l'a posée
	local roleX, roleY = Clamp(ranges.role, Saved("role"))
	for _, power in ipairs(powers) do
		local role = Origins(power).role
		local home = Box(role[1], role[2], role[3], role[4], role[5])
		local moved = Box(role[1], role[2] + roleX, role[3] + roleY, role[4], role[5])
		ranges.leader = Common(ranges.leader, Range(Origins(power, moved).leader, W, H, Origins(power, home).leader))
	end
	cache = { db = db, shape = db.shape, W = W, H = H, ranges = ranges, specs = specs }
	return cache
end

-- À appeler quand un réglage change (Z:Refresh le fait)
function Z.ForgetPlacementRanges()
	cache = nil
end

-- Bornes du décalage d'un élément : gauche, droite, bas, haut (pour l'éditeur et les tests)
function Z.OffsetRange(key)
	local range = Ranges().ranges[key]
	if not range then return 0, 0, 0, 0 end
	return range[1], range[2], range[3], range[4]
end

-- Décalage d'un élément pour la forme choisie, en pixels de la case (0, 0 : place d'origine), ramené dans la case
function Z.Offset(key)
	local range = KNOWN[key] and Ranges().ranges[key]
	if not range then return 0, 0 end
	return Clamp(range, Saved(key))
end

-- Largeur du nom ou du texte de vie, décalage compris : il rétrécit près du bord au lieu d'en sortir
function Z.TextWidth(key)
	local all = Ranges()
	local spec = all.specs[key]
	local point, x, w = spec[1], spec[2] + Z.Offset(key), spec[4]
	if point:find("LEFT") then return math.min(w, all.W - x) end
	if point:find("RIGHT") then return math.min(w, x) end
	return math.min(w, 2 * x, 2 * (all.W - x))
end

-- Écrit l'entrée d'un élément : { x, y } ou { x, y, taille }. Place et taille d'origine effacent l'entrée : le
-- réglage reste léger.
local function Store(shape, key, x, y, size)
	local all = Z.db.placement
	all[shape] = all[shape] or {}
	if size == 100 then size = nil end
	all[shape][key] = (x ~= 0 or y ~= 0 or size) and { x, y, size } or nil
	if not next(all[shape]) then all[shape] = nil end
	cache = nil
end

-- Enregistre un décalage, la taille reste. Pour la forme choisie, le décalage s'arrête au bord de la case ;
-- pour une autre forme (code de partage), seulement aux limites du réglage.
function Z.SetOffset(key, x, y, shape)
	if not KNOWN[key] then return end
	shape = shape or Z.db.shape
	x, y = Limit(x), Limit(y)
	if shape == Z.db.shape then x, y = Clamp(Ranges().ranges[key], x, y) end
	Store(shape, key, x, y, SavedSize(key, shape))
end

-- Enregistre une taille en % (bornée par Z.limits.placement.size), le décalage reste
function Z.SetElementSize(key, size, shape)
	if not SIZED[key] then return end
	shape = shape or Z.db.shape
	local at = Entry(key, shape)
	Store(shape, key, at and Limit(at[1]) or 0, at and Limit(at[2]) or 0, LimitSize(size))
end

-- Taille enregistrée d'un élément, en % (pour l'éditeur, le partage et les tests)
function Z.GetElementSize(key, shape)
	return SIZED[key] and SavedSize(key, shape) or 100
end


-- Tous les éléments de la forme choisie reviennent à leur place d'origine
function Z.ResetPlacement()
	Z.db.placement[Z.db.shape] = nil
	cache = nil
end

----------------------------------------------------------------------------------------------------
-- La fenêtre : la liste des éléments à gauche, la case d'exemple à droite, les flèches dessous
----------------------------------------------------------------------------------------------------
local WIDTH, HEIGHT = 580, 512
local STAGE_W, STAGE_H = 352, 232
local win, stage, cell, highlight
local selected = "name"
local drag

local SAMPLE_ICONS = {
	debuffs = { "Interface\\Icons\\Spell_Shadow_CurseOfTounges", "Interface\\Icons\\Spell_Nature_Slow" },
	big = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
	defensives = { "Interface\\Icons\\Ability_Warrior_ShieldWall", "Interface\\Icons\\Spell_Holy_DivineIntervention" },
	controls = "Interface\\Icons\\Spell_Nature_Polymorph",
	buff = "Interface\\Icons\\Spell_Holy_WordFortitude",
	private = "Interface\\Icons\\INV_Misc_QuestionMark",
}

local function SampleIcon(icon, texture)
	icon.texture:SetTexture(texture)
	icon.texture:SetDesaturated(false)
	icon.border:SetColor(0, 0, 0, 1)
	icon.cooldown:Clear()
	icon.count:SetText("")
	icon:SetAlpha(1)
	icon:Show()
end

-- Les morceaux qui forment un élément sur la case d'exemple (les rangées entières, comme réglées)
local function Row(list, count)
	local row = {}
	for index = 1, count do row[index] = list[index] end
	return row
end

local function Regions(key)
	if key == "hots" then
		return Row(Z.db.hotStyle == "BARS" and cell.hotBars or cell.hots, Z.db.hotCount)
	elseif key == "debuffs" then
		return Row(cell.debuffs, Z.db.debuffCount)
	elseif key == "big" then
		return { cell.bigIcon }
	elseif key == "defensives" then
		return Row(cell.defensives, Z.DEFENSIVE_COUNT)
	elseif key == "controls" then
		return { cell.controlIcon }
	elseif key == "buff" then
		return { cell.buffIcon }
	elseif key == "private" then
		return { cell.privateHolder }
	end
	return { cell[key] }
end

-- Rectangle d'un élément (gauche, droite, haut, bas), en coordonnées de la case
local function Bounds(key)
	local left, right, top, bottom
	for _, region in ipairs(Regions(key)) do
		local l, r, t, b = region:GetLeft(), region:GetRight(), region:GetTop(), region:GetBottom()
		if l and r and t and b then
			left, right = math.min(left or l, l), math.max(right or r, r)
			top, bottom = math.max(top or t, t), math.min(bottom or b, b)
		end
	end
	return left, right, top, bottom
end

-- Contour d'accent autour de l'élément choisi
local function ShowHighlight()
	local left, right, top, bottom = Bounds(selected)
	local cellLeft, cellTop = cell:GetLeft(), cell:GetTop()
	if not (left and cellLeft and cellTop) then return highlight:Hide() end
	highlight:ClearAllPoints()
	highlight:SetPoint("TOPLEFT", cell, "TOPLEFT", left - cellLeft - 1, top - cellTop + 1)
	highlight:SetSize(right - left + 2, top - bottom + 2)
	highlight.border:SetColor(UI.accent[1], UI.accent[2], UI.accent[3], 1)
	highlight:Show()
end

local function ShapeName(id)
	for _, choice in ipairs(Z.choices.shape) do
		if choice[1] == id then return L[choice[2]] end
	end
	return id
end

-- Agrandissement de la case d'exemple : la case et le décalage le plus grand de chaque côté tiennent dans la
-- scène (un élément poussé au bout reste visible), jamais plus de 3 fois, jamais sous la taille réelle
local function StageScale(width, height)
	local limit = Z.limits.placement
	local room = 2 * math.max(-limit[1], limit[2])
	return math.max(1, math.min(3, (STAGE_W - 24) / (width + room), (STAGE_H - 24) / (height + room)))
end

-- Dessine la case d'exemple avec TOUS les éléments, même ceux coupés dans les options : on peut les placer
-- d'avance. Les vraies cases, le mode test et cette case passent par les mêmes fonctions de placement.
local function Draw()
	local db = Z.db
	local width, height = Z.CellSize()
	cell:SetSize(width, height)
	cell:SetScale(StageScale(width, height))
	cell.powerShown = db.manaBars ~= "OFF"
	cell.power:SetShown(cell.powerShown)
	Z.StyleButton(cell)

	cell.hp:SetMinMaxValues(0, 100)
	cell.hp:SetValue(68)
	cell.hp:SetStatusBarColor(Z.ClassColor(Z.class))
	cell.power:SetMinMaxValues(0, 100)
	cell.power:SetValue(60)
	cell.name:SetText(UnitName("player") or L["Joueur"])
	cell.name:SetTextColor(1, 1, 1)
	cell.text:SetText(db.text == "PERCENT" and "68%" or "-1240")
	cell.text:SetTextColor(1, 1, 1)
	cell.role:SetAtlas("roleicon-tiny-healer")
	cell.role:Show()
	SetRaidTargetIconTexture(cell.marker, 1)
	cell.marker:Show()
	cell.leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
	cell.leader:Show()
	cell.center:SetTexture(READY_CHECK_READY_TEXTURE)
	cell.center:Show()
	cell.lowMana:SetAlpha(1)
	cell.lowMana:Show()

	-- Rangées entières, avec le nombre d'icônes réglé : c'est la rangée la plus longue qui reste dans la case
	local spells = Z.trackedSpells[Z.class] or { 139, 774 }
	for _, list in ipairs({ cell.hots, cell.hotBars, cell.debuffs }) do
		for _, region in ipairs(list) do region:Hide() end
	end
	for index = 1, db.hotCount do
		if db.hotStyle == "BARS" then
			local bar = Z.HotBar(cell, index)
			bar:SetMinMaxValues(0, 1)
			bar:SetValue(1 - (index - 1) * 0.2)
			bar:Show()
		else
			SampleIcon(Z.HotIcon(cell, index), C_Spell.GetSpellTexture(spells[(index - 1) % #spells + 1]))
		end
	end
	for index = 1, db.debuffCount do
		SampleIcon(Z.DebuffIcon(cell, index), SAMPLE_ICONS.debuffs[(index - 1) % #SAMPLE_ICONS.debuffs + 1])
	end
	SampleIcon(Z.BigIcon(cell), SAMPLE_ICONS.big)
	-- Gros défensifs et contrôle : leur liseré de couleur, comme sur les vraies cases
	local function Edge(icon, color) icon.border:SetColor(color[1], color[2], color[3], 1) end
	for index = 1, Z.DEFENSIVE_COUNT do
		local icon = Z.DefensiveIcon(cell, index)
		SampleIcon(icon, SAMPLE_ICONS.defensives[(index - 1) % #SAMPLE_ICONS.defensives + 1])
		Edge(icon, Z.DEFENSIVE_EDGE)
	end
	SampleIcon(Z.ControlIcon(cell), SAMPLE_ICONS.controls)
	Edge(cell.controlIcon, Z.CONTROL_EDGE)
	local buff = Z.BuffIcon(cell)
	SampleIcon(buff, SAMPLE_ICONS.buff)
	buff.texture:SetDesaturated(true)
	buff.border:SetColor(1, 0.2, 0.2, 1)

	-- Auras privées : le jeu les dessine lui-même, la case d'exemple montre deux points d'interrogation
	local holder, size = Z.PrivateHolder(cell)
	holder.sample = holder.sample or {}
	for index = 1, Z.PRIVATE_SLOTS do
		local sample = holder.sample[index] or holder:CreateTexture(nil, "ARTWORK")
		holder.sample[index] = sample
		sample:SetTexture(SAMPLE_ICONS.private)
		sample:SetSize(size, size)
		sample:ClearAllPoints()
		sample:SetPoint("LEFT", holder, "LEFT", (index - 1) * (size + 2), 0)
	end
	holder:Show()

	local x, y = Z.Offset(selected)
	win.coords:SetText(L["Décalage : %d, %d"]:format(x, y))
	-- Taille : les icônes seulement ; le nom, le texte de vie et les auras privées renvoient à leur réglage
	local sized = Z.CanSize(selected)
	for _, button in ipairs({ win.smaller, win.bigger }) do
		button:SetEnabled(sized)
		button:SetAlpha(sized and 1 or 0.4)
	end
	if sized then
		win.size:SetText(L["Taille : %d %%"]:format(Z.GetElementSize(selected)))
	elseif selected == "hots" then
		win.size:SetText(L["Les barres fines gardent leur épaisseur."])
	else
		local setting = selected == "private" and "Taille des auras privées" or "Taille du texte"
		win.size:SetText(L["Taille : réglage « %s »"]:format(L[setting]))
	end
	win.shape:SetText(L["Forme : %s"]:format(ShapeName(db.shape)))
	for _, button in ipairs(win.list) do UI.SetTab(button, button.key == selected) end
	ShowHighlight()
end

-- Un changement fait dans l'éditeur : vraies cases, mode test et case d'exemple (Z:RefreshPlacement)
local function Changed()
	Z:Refresh()
end

local function Select(key)
	selected = key
	Draw()
end

-- Pousse l'élément choisi d'un pixel (Maj : 5 pixels). Au bord de la case, il s'arrête et le dit.
local function Nudge(dx, dy)
	local step = IsShiftKeyDown() and 5 or 1
	local x, y = Z.Offset(selected)
	Z.SetOffset(selected, x + dx * step, y + dy * step)
	Changed()
	local newX, newY = Z.Offset(selected)
	if newX == x and newY == y then win.coords:SetText(L["Au bord de la case : %d, %d"]:format(x, y)) end
end

-- Taille de l'élément sur la case : celle d'une icône de la rangée, ou la largeur de l'icône
local function Measure(key)
	local row = Z.AuraRows()[key]
	if row then return row.size end
	local spec = Ranges().specs[key]
	if spec then return spec[4] end
	return Z.ElementSize(key, Z.BadgeSize(Z.IconSize())) -- la couronne, accrochée à l'icône de rôle
end


-- Grandit (+1) ou rapetisse (-1) l'élément choisi de 10 %. Il s'arrête quand la case est pleine et le dit (une
-- taille qui ne gagne pas un pixel, par arrondi, n'arrête rien : on regarde si la plus grande taille gagnerait).
local function Resize(delta)
	if not Z.CanSize(selected) then return end
	local limit = Z.limits.placement.size
	local old, before = Z.GetElementSize(selected), Measure(selected)
	Z.SetElementSize(selected, old + delta * limit[3])
	local full = false
	if delta > 0 and Z.GetElementSize(selected) ~= old and Measure(selected) <= before then
		local wanted = Z.GetElementSize(selected)
		Z.SetElementSize(selected, limit[2])
		full = Measure(selected) <= before
		Z.SetElementSize(selected, full and old or wanted)
	end
	Changed()
	local size = Z.GetElementSize(selected)
	if full or (delta > 0 and size == old) then
		win.size:SetText(L["Au plus grand pour cette case : %d %%"]:format(size))
	elseif delta < 0 and size == old then
		win.size:SetText(L["Au plus petit : %d %%"]:format(size))
	end
end

-- L'élément sous la souris ; s'ils se recouvrent, le plus petit (une icône posée sur le nom)
local function ElementAt()
	local x, y = GetCursorPosition()
	local scale = cell:GetEffectiveScale()
	x, y = x / scale, y / scale
	local found, area
	for _, element in ipairs(Z.placeElements) do
		local left, right, top, bottom = Bounds(element[1])
		if left and x >= left and x <= right and y >= bottom and y <= top then
			local size = (right - left) * (top - bottom)
			if not area or size < area then found, area = element[1], size end
		end
	end
	return found
end

-- Glisser : la souris ne sert qu'à l'intérieur de la case d'exemple, et seulement pendant le glissement
local function Dragging()
	local x, y = GetCursorPosition()
	local scale = cell:GetEffectiveScale()
	local wantX = drag.offsetX + (x - drag.x) / scale
	local wantY = drag.offsetY + (y - drag.y) / scale
	local oldX, oldY = Z.Offset(drag.key)
	Z.SetOffset(drag.key, wantX, wantY)
	local newX, newY = Z.Offset(drag.key)
	if newX ~= oldX or newY ~= oldY then Draw() end
end

local function StopDrag()
	stage:SetScript("OnUpdate", nil)
	if drag then
		drag = nil
		Z:Refresh()
	end
end

local function StartDrag(_, button)
	if button ~= "LeftButton" then return end
	local key = ElementAt()
	if not key then return end
	Select(key)
	local x, y = GetCursorPosition()
	local offsetX, offsetY = Z.Offset(key)
	drag = { key = key, x = x, y = y, offsetX = offsetX, offsetY = offsetY }
	stage:SetScript("OnUpdate", Dragging)
end

local function Arrow(label, dx, dy)
	local button = UI.Button(win, L[label], 64, 22, function() Nudge(dx, dy) end)
	button.label:SetJustifyH("CENTER")
	button.tip = L["Un pixel par clic, cinq avec Maj."]
	return button
end

local function BuildWindow()
	win = UI.Window("LyorunePlacement", L["Placement des éléments"], WIDTH, HEIGHT)
	win:SetFrameStrata("FULLSCREEN_DIALOG")
	win.beside = true -- à côté des options, sans les recouvrir
	tinsert(UISpecialFrames, "LyorunePlacement")

	-- Liste des éléments
	win.list = {}
	for index, element in ipairs(Z.placeElements) do
		local button = UI.Button(win, L[element[2]], 186, 24, function(self) Select(self.key) end)
		button.key = element[1]
		button:SetPoint("TOPLEFT", 16, -48 - (index - 1) * 27)
		win.list[index] = button
	end

	-- Case d'exemple, agrandie, sur un fond
	stage = CreateFrame("Frame", nil, win)
	stage:SetSize(STAGE_W, STAGE_H)
	stage:SetPoint("TOPLEFT", 214, -48)
	stage:SetClipsChildren(true) -- en filet : rien ne déborde de la scène, ni sur la liste ni hors de la fenêtre
	stage.bg = UI.Paint(UI.Tex(stage, "BACKGROUND"), "panel")
	stage.bg:SetAllPoints()
	stage.border = UI.Paint(UI.Border(stage, 1), "line")
	stage:EnableMouse(true)
	stage:SetScript("OnMouseDown", StartDrag)
	stage:SetScript("OnMouseUp", StopDrag)
	stage:SetScript("OnHide", StopDrag)
	-- Molette : l'élément sous la souris (sinon celui choisi) grandit ou rapetisse
	stage:EnableMouseWheel(true)
	stage:SetScript("OnMouseWheel", function(_, delta)
		if drag then return end
		local key = ElementAt()
		if key and key ~= selected then Select(key) end
		Resize(delta > 0 and 1 or -1)
	end)

	cell = CreateFrame("Frame", nil, stage)
	cell:SetPoint("CENTER")
	Z.BuildVisuals(cell)
	highlight = CreateFrame("Frame", nil, cell)
	highlight:SetFrameLevel(cell.over:GetFrameLevel() + 10)
	highlight.border = UI.Border(highlight, 1)
	highlight:Hide()
	win.cell, win.stage = cell, stage

	win.shape = UI.Label(win, 11, nil, "dim")
	win.shape:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -8)
	win.coords = UI.Label(win, 12, nil, "accent")
	win.coords:SetPoint("TOPRIGHT", stage, "BOTTOMRIGHT", 0, -8)

	-- Flèches : un pixel, cinq avec Maj
	win.left = Arrow("Gauche", -1, 0)
	win.left:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -30)
	win.up = Arrow("Haut", 0, 1)
	win.up:SetPoint("LEFT", win.left, "RIGHT", 6, 0)
	win.down = Arrow("Bas", 0, -1)
	win.down:SetPoint("LEFT", win.up, "RIGHT", 6, 0)
	win.right = Arrow("Droite", 1, 0)
	win.right:SetPoint("LEFT", win.down, "RIGHT", 6, 0)

	-- Taille : 10 % par clic, ou la molette sur la case
	local function SizeButton(label, delta, tip)
		local button = UI.Button(win, label, 64, 22, function() Resize(delta) end)
		button.label:SetJustifyH("CENTER")
		button.tip = L[tip]
		return button
	end
	win.smaller = SizeButton("-", -1, "Plus petit : 10 % par clic, ou la molette sur la case.")
	win.smaller:SetPoint("TOPLEFT", win.left, "BOTTOMLEFT", 0, -8)
	win.bigger = SizeButton("+", 1, "Plus grand : 10 % par clic, ou la molette sur la case.")
	win.bigger:SetPoint("LEFT", win.smaller, "RIGHT", 6, 0)
	win.size = UI.Label(win, 12, nil, "accent")
	win.size:SetPoint("LEFT", win.bigger, "RIGHT", 10, 0)
	win.size:SetPoint("RIGHT", stage, "RIGHT", 0, 0)
	win.size:SetJustifyH("LEFT")

	win.reset = UI.Button(win, L["Remettre à sa place"], 172, 22, function()
		Z.SetOffset(selected, 0, 0)
		Z.SetElementSize(selected, 100)
		Changed()
	end)
	win.reset:SetPoint("TOPLEFT", win.smaller, "BOTTOMLEFT", 0, -8)
	win.reset.label:SetJustifyH("CENTER")
	win.reset.tip = L["Place et taille d'origine de cet élément."]
	-- Tous les éléments d'un coup : un second clic confirme (Options.lua)
	win.resetAll = Z.ArmedButton(win, "Tout remettre", "Confirmer", 172, function()
		Z.ResetPlacement()
		Changed()
	end)
	win.resetAll:SetHeight(22)
	win.resetAll:SetPoint("LEFT", win.reset, "RIGHT", 8, 0)
	win:HookScript("OnHide", win.resetAll.Disarm)
	win.resetAll.tip = L["Tous les éléments de cette forme de case reviennent à leur place et à leur taille d'origine."]

	local note = UI.Label(win, 11, nil, "dim")
	note:SetPoint("TOPLEFT", 16, -436)
	note:SetPoint("RIGHT", -16, 0)
	note:SetJustifyH("LEFT")
	note:SetSpacing(3)
	note:SetText(L["Glissez un élément sur la case, ou choisissez-le dans la liste et poussez-le avec les flèches (Maj : 5 pixels). La molette sur une icône, ou « - » et « + », change sa taille. Rien ne sort de la case. Chaque forme de case garde ses propres placements. Tous les éléments sont montrés ici, même ceux coupés dans les options."])


	win:HookScript("OnShow", Draw)
	win.StageScale = StageScale -- pour les tests
end

-- Rappelée alors qu'elle est ouverte, la fenêtre passe devant sans se fermer (OnShow la dessine)
function Z:OpenPlacement()
	if not win then BuildWindow() end
	UI.Reopen(win)
	win:Raise()
end

-- Appelé après chaque changement d'option : la case d'exemple suit la forme, le thème et les tailles
function Z:RefreshPlacement()
	if win and win:IsShown() and not drag then Draw() end
end

-- Pour les tests
function Z:PlacementWindow()
	return win
end
