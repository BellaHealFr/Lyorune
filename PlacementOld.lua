-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - PlacementOld.lua : passage des placements à la 1.49.0, une seule fois.
-- La 1.49.0 change les places d'origine des éléments de la case (Z.AuraRows, Themes.lua). Un décalage enregistré
-- part de la place d'origine : sans rien faire, un élément déplacé par le joueur bougerait. Ce fichier garde une
-- copie figée des règles d'avant (1.48.1), qui ne sert qu'à ce passage : pour chaque élément enregistré, la place
-- et la taille qu'il avait à l'écran sont retrouvées, puis le décalage et la taille en % sont recalculés pour que
-- l'élément reste au pixel près là où le joueur l'avait mis (aux tailles de cases réglées). Un élément jamais
-- touché prend sa nouvelle place d'origine.
-- Ne jamais changer ce fichier pour suivre une évolution des places d'origine : il décrit la 1.48.1.

local _, Z = ...

local GAP, MIN_ICON = 2, 5
local SIGN = { TOPLEFT = { 1, -1 }, TOPRIGHT = { -1, -1 }, BOTTOMLEFT = { 1, 1 }, BOTTOMRIGHT = { -1, 1 } }
-- Règles des rangées de la 1.48.1, pour chaque forme
local RULES = {
	BAR    = { size = 0.34, hots = "TOPRIGHT", debuffs = "BOTTOMRIGHT", hotLine = 0.5, debuffLine = 0.5, inline = "EDGES" },
	TILE   = { size = 0.26, hots = "TOPLEFT", debuffs = "BOTTOMRIGHT", hotLine = "ROLE", debuffLine = "BUFF" },
	SQUARE = { size = 0.19, hots = "TOPLEFT", debuffs = "BOTTOMRIGHT", hotLine = "ROLE", debuffLine = "BUFF", wrap = true },
	BANNER = { size = 0.38, hots = "TOPRIGHT", debuffs = "BOTTOMRIGHT", hotLine = 0.3, debuffLine = 0.3, inline = "BLOCK" },
}

local function Fit(n, size, line, maxH, canWrap)
	size = math.max(MIN_ICON, math.min(size, maxH))
	local perLine = math.max(1, math.floor((line + GAP) / (size + GAP)))
	if n <= perLine then return size, n, 1 end
	if canWrap and math.ceil(n / perLine) <= 2 then return size, perLine, 2 end
	local each = math.ceil(n / (canWrap and 2 or 1))
	local small = math.max(MIN_ICON, math.floor((line + GAP) / each - GAP))
	return math.min(size, small), each, math.ceil(n / each)
end

-- Rangées et textes sur une ligne, comme Z.AuraRows de la 1.48.1
local function OldRows()
	local db, theme = Z.db, Z:Theme()
	local rules = RULES[db.shape] or RULES.TILE
	local W, H = Z.CellSize()
	local inset = Z.UI.Inset(theme.borderSize, db.corners == "ROUND")
	local icon = Z.IconSize()
	local sizes = { iconSize = icon }
	local function Shift(point) return Z.CornerShift(sizes, point) end
	local font = db.fontSize + (theme.fontBonus or 0)
	local want = math.max(MIN_ICON, math.floor(H * rules.size + 0.5))
	local inline = rules.inline
	local canWrap = rules.wrap and not inline and Z.CanWrapAuras()
	local roleOn, buffOn = db.showRole and true or false, db.missingBuffs and true or false
	local roleW, buffW = Z.ElementSize("role", icon - 2), Z.ElementSize("buff", icon)
	local role = inline and { inset + 3, inset + 3 + roleW } or { W - 2 - Shift("TOPRIGHT") - roleW, W - 2 - Shift("TOPRIGHT") }
	local buff = { 2 + Shift("BOTTOMLEFT"), 2 + Shift("BOTTOMLEFT") + buffW }
	local function Start(point)
		return point:find("LEFT") and 2 + Shift(point) or W - 2 - Shift(point)
	end
	local function Line(spec, point)
		if type(spec) == "number" then return math.floor(W * spec) end
		local on = buffOn
		if spec == "ROLE" then on = roleOn end
		if not on then return point:find("LEFT") and W - 2 - Start(point) or Start(point) - 2 end
		local obstacle = spec == "ROLE" and role or buff
		if point:find("LEFT") then return obstacle[1] - GAP - Start(point) end
		return Start(point) - obstacle[2] - GAP
	end
	local hotsOn, debuffsOn = db.showHots and true or false, db.showDebuffs and true or false
	local size, maxH = want, math.floor((H - 4) / (canWrap and 2 or 1)) - (canWrap and 1 or 0)
	local maxAlone
	local hpH = H - 2 * inset - (db.manaBars ~= "OFF" and Z.PowerHeight() + 1 or 0)
	if inline then
		local both = hotsOn and debuffsOn
		local room = inline == "EDGES" and math.floor((hpH - math.ceil(font * 0.72)) / (both and 2 or 1))
			or (both and math.floor((hpH - 1) / 2) or hpH)
		size = math.max(MIN_ICON, math.min(want, room))
		maxH = math.max(MIN_ICON, math.floor((hpH - 1) / 2))
		maxAlone = math.max(MIN_ICON, hpH)
	end
	local rows = {}
	local function Row(key, point, spec, n, alone)
		local wanted = math.max(MIN_ICON, math.floor(size * Z.ElementScale(key) + 0.5))
		local s, perLine, lines = Fit(n, wanted, Line(spec, point), (alone and maxAlone) or maxH, canWrap)
		local sign = SIGN[point]
		local x, y = sign[1] * (2 + Shift(point)), sign[2] * 2
		if inline then x, y = sign[1] * (2 + Shift(point) - inset), 0 end
		rows[key] = { point = point, relative = inline and "HP" or "CELL", x = x, y = y, size = s, perLine = perLine,
			width = perLine * (s + GAP) - GAP, height = lines * (s + GAP) - GAP }
	end
	Row("hots", rules.hots, rules.hotLine, Z.HotSlots(), inline and not debuffsOn)
	Row("debuffs", rules.debuffs, rules.debuffLine, Z.DebuffSlots(), inline and not hotsOn)

	local nameAfter = roleOn and roleW + 5 or 3
	rows.classX = nameAfter
	if db.showClassIcon then nameAfter = nameAfter + Z.ElementSize("class", icon - 2) + 2 end
	if db.dispelIcon then nameAfter = nameAfter + Z.ElementSize("dispelType", icon) + 2 end
	rows.nameX = nameAfter
	rows.textX, rows.textW, rows.nameW = -4, W - 2 * inset - 8, math.max(20, W - nameAfter - 43)
	if inline == "BLOCK" then
		local shown = { hots = (db.showHots and db.hotStyle ~= "BARS") and Z.HotSlots() or 0,
			debuffs = db.showDebuffs and Z.DebuffSlots() or 0 }
		local left
		for key, n in pairs(shown) do
			local row = rows[key]
			if n > 0 then
				local edge = Start(row.point) - (math.min(n, row.perLine) * (row.size + GAP) - GAP)
				left = math.min(left or edge, edge)
			end
		end
		if left then
			local textRight = math.max(inset + 1, left - 4)
			rows.textW = math.max(1, math.min(math.ceil(font * 3.2), textRight - inset))
			rows.textX = textRight - (W - inset)
			rows.nameW = math.max(20, textRight - rows.textW - 2 - (inset + rows.nameX))
		end
	end

	local n = Z.DEFENSIVE_COUNT
	local wanted = math.max(MIN_ICON, math.floor(size * Z.ElementScale("defensives") + 0.5))
	local s = Fit(n, wanted, math.floor(W * 0.5), inline and math.max(MIN_ICON, hpH - 2) or maxH, false)
	local x = -2
	if inline then x = rows.textX - (inline == "BLOCK" and rows.textW or math.ceil(font * 3.2)) - GAP end
	rows.defensives = { point = "RIGHT", relative = inline and "HP" or "CELL", x = x, y = 0, size = s,
		width = n * (s + GAP) - GAP, height = s }
	wanted = math.max(MIN_ICON, math.floor(math.floor(icon * 1.2 + 0.5) * Z.ElementScale("controls") + 0.5))
	s = Fit(1, wanted, W - 4, inline and math.max(MIN_ICON, hpH - 2) or H - 4, false)
	rows.controls = { point = "CENTER", relative = inline and "HP" or "CELL", x = 0, y = 0, size = s, width = s, height = s }
	return rows
end

local function Spot(rect, point, x, y)
	local px = point:find("LEFT") and rect[1] or point:find("RIGHT") and rect[2] or (rect[1] + rect[2]) / 2
	local py = point:find("BOTTOM") and rect[3] or point:find("TOP") and rect[4] or (rect[3] + rect[4]) / 2
	return px + (x or 0), py + (y or 0)
end

-- Places d'origine de la 1.48.1, au format de Origins (Placement.lua) : { point, x, y, largeur, hauteur } en
-- pixels de la case. roleRect : l'icône de rôle, où s'accroche le chef de groupe.
function Z.OldPlacementOrigins(power, roleRect)
	local db, theme = Z.db, Z:Theme()
	local W, H = Z.CellSize()
	local inset = Z.UI.Inset(theme.borderSize, db.corners == "ROUND")
	local icon = Z.IconSize()
	local sizes = { iconSize = icon }
	local function Shift(point) return Z.CornerShift(sizes, point) end
	local font = db.fontSize + (theme.fontBonus or 0)
	local hp = { inset, W - inset, inset + (power and Z.PowerHeight() + 1 or 0), H - inset }
	local cell = { 0, W, 0, H }
	local rows = OldRows()
	local o = {}
	local function Put(key, point, rect, relative, x, y, w, h)
		local ax, ay = Spot(rect, relative, x, y)
		o[key] = { point, ax, ay, w, h, text = key == "name" or key == "text" }
	end
	local inline = (RULES[db.shape] or RULES.TILE).inline
	local role, badge = Z.ElementSize("role", icon - 2), Z.ElementSize("leader", Z.BadgeSize(icon))
	local class = Z.ElementSize("class", icon - 2)
	local big = Z.ElementSize("big", math.floor(icon * 1.6 + 0.5))
	local dispel = Z.ElementSize("dispelType", icon)
	if inline then
		Put("role", "LEFT", hp, "LEFT", 3, 0, role, role)
		Put("class", "LEFT", hp, "LEFT", rows.classX, 0, class, class)
		Put("name", "LEFT", hp, "LEFT", rows.nameX, 0, rows.nameW, font + 2)
		Put("text", "RIGHT", hp, "RIGHT", rows.textX, 0, rows.textW, font + 1)
		if roleRect then Put("leader", "CENTER", roleRect, "TOPRIGHT", 0, 0, badge, badge) end
		local x = db.showRole and role + 5 or 3
		if db.showClassIcon then x = x + class + 2 end
		Put("dispelType", "LEFT", hp, "LEFT", x, 0, dispel, dispel)
	else
		Put("role", "TOPRIGHT", cell, "TOPRIGHT", -2 - Shift("TOPRIGHT"), -2, role, role)
		Put("class", "LEFT", hp, "LEFT", 3, 3, class, class)
		Put("name", "CENTER", hp, "CENTER", 0, 3, db.showClassIcon and W - 2 * (class + 5) or W - 8, font + 2)
		Put("text", "BOTTOM", hp, "BOTTOM", 0, 4, W - 8, font + 1)
		if roleRect then Put("leader", "TOPRIGHT", roleRect, "TOPLEFT", -1, 0, badge, badge) end
		local x = db.bossDebuffs and 3 + big + 2 or 3
		if db.showClassIcon then x = math.max(x, 3 + class + 2) end
		Put("dispelType", "LEFT", cell, "LEFT", x, 0, dispel, dispel)
	end
	local marker, center = Z.ElementSize("marker", icon), Z.ElementSize("center", icon + 8)
	local lowMana = Z.ElementSize("lowMana", icon - 1)
	Put("marker", "CENTER", cell, "TOP", 0, -1, marker, marker)
	Put("center", "CENTER", cell, "CENTER", 0, 0, center, center)
	Put("lowMana", "BOTTOMLEFT", hp, "BOTTOMLEFT", 2, 2, lowMana, lowMana)
	local function Row(key, row)
		Put(key, row.point, row.relative == "HP" and hp or cell, row.point, row.x, row.y, row.width, row.height)
	end
	if db.hotStyle == "BARS" then
		Put("hots", "TOPLEFT", cell, "TOPLEFT", 3 + Shift("TOPLEFT"), -3, math.floor(W * 0.45), Z.HotSlots() * 4)
	else
		Row("hots", rows.hots)
	end
	Row("debuffs", rows.debuffs)
	Row("defensives", rows.defensives)
	Row("controls", rows.controls)
	Put("big", "LEFT", cell, "LEFT", 3, 0, big, big)
	local buff = Z.ElementSize("buff", icon)
	Put("buff", "BOTTOMLEFT", cell, "BOTTOMLEFT", 2 + Shift("BOTTOMLEFT"), 2, buff, buff)
	-- taille d'une icône des rangées (la mesure que la migration doit retrouver)
	o.rowSize = { hots = rows.hots.size, debuffs = rows.debuffs.size, defensives = rows.defensives.size,
		controls = rows.controls.size, leader = badge }
	return o
end
