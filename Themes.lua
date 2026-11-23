-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Themes.lua : les 5 habillages des cases, du plus moderne au plus « MMO ».
-- Un thème n'est qu'une liste de réglages visuels : pour en créer un, copiez un bloc et changez les valeurs.
--   texture    : image de la barre de vie
--   font/flags : police du nom et du texte ("OUTLINE" = contour)
--   bg         : couleur de fond (la vie manquante), rouge, vert, bleu, opacité
--   border     : couleur de la bordure, borderSize : son épaisseur
--   shade      : relief de la barre (ombre en bas, lumière en haut), 0 = aucun
--   incoming   : couleur des soins en route, absorb : couleur du bouclier

local _, Z = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"

Z.themes = {
	{
		id = "NEON", name = "Néon", -- ultra moderne : aplats nets, aucun relief
		texture = WHITE, font = "Fonts\\ARIALN.TTF", flags = "",
		bg = { 0.02, 0.02, 0.04, 0.96 }, border = { 0, 0, 0 }, borderSize = 1,
		shade = { 0, 0 },
		incoming = { 0.20, 1.00, 0.85, 0.65 }, absorb = { 0.30, 0.90, 1.00, 1 },
	},
	{
		id = "PURE", name = "Épuré", -- moderne : aplat avec un léger relief
		texture = WHITE, font = STANDARD_TEXT_FONT, flags = "",
		bg = { 0.07, 0.07, 0.09, 1 }, border = { 0, 0, 0 }, borderSize = 1,
		shade = { 0.28, 0.10 },
		incoming = { 0.45, 1.00, 0.60, 0.55 }, absorb = { 0.55, 0.85, 1.00, 0.95 },
	},
	{
		id = "GLASS", name = "Verre", -- brillant et translucide
		texture = WHITE, font = STANDARD_TEXT_FONT, flags = "OUTLINE",
		bg = { 0.10, 0.12, 0.18, 0.70 }, border = { 0.30, 0.36, 0.50 }, borderSize = 1,
		shade = { 0.45, 0.28 },
		incoming = { 0.60, 1.00, 0.80, 0.55 }, absorb = { 0.75, 0.90, 1.00, 0.95 },
	},
	{
		id = "CLASSIC", name = "Classique", -- l'allure des cadres de raid du jeu
		texture = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill", font = "Fonts\\FRIZQT__.TTF", flags = "",
		bg = { 0.10, 0.10, 0.10, 1 }, border = { 0.35, 0.35, 0.35 }, borderSize = 1,
		shade = { 0.10, 0 },
		incoming = { 0.40, 0.95, 0.45, 0.60 }, absorb = { 0.80, 0.90, 1.00, 0.90 },
	},
	{
		id = "HEROIC", name = "Héroïque", -- purement MMO : barres texturées, bordure dorée
		texture = "Interface\\TargetingFrame\\UI-StatusBar", font = "Fonts\\FRIZQT__.TTF", flags = "OUTLINE",
		bg = { 0.12, 0.08, 0.05, 1 }, border = { 0.78, 0.62, 0.26 }, borderSize = 2,
		shade = { 0.30, 0.06 },
		incoming = { 0.55, 1.00, 0.40, 0.60 }, absorb = { 1.00, 0.92, 0.60, 0.95 },
	},
}

-- Mode contraste élevé (option) : fond noir, bordure blanche, texte plus gros avec contour
local contrast = {
	id = "CONTRAST", name = "Contraste élevé",
	texture = WHITE, font = STANDARD_TEXT_FONT, flags = "OUTLINE", fontBonus = 1,
	bg = { 0, 0, 0, 1 }, border = { 1, 1, 1 }, borderSize = 1,
	shade = { 0, 0 },
	incoming = { 0.20, 1.00, 0.20, 0.85 }, absorb = { 1.00, 1.00, 0.20, 1 },
}

function Z:Theme()
	if Z.db.highContrast then return contrast end
	for _, theme in ipairs(Z.themes) do
		if theme.id == Z.db.theme then return theme end
	end
	return Z.themes[2]
end

-- Formes des cases. Choisir une forme règle la taille, le texte et la barre de mana d'un coup ; chaque valeur se
-- retouche ensuite dans les options. « inline » : nom à gauche et vie à droite, sur une seule ligne.
-- Les noms et les choix sont dans Z.choices.shape (Core.lua) ; pour en ajouter une, ajoutez les deux.
-- « auras » : place et taille d'origine des rangées de mes soins sur la durée et des affaiblissements
--   size        : taille des icônes, en part de la hauteur de la case
--   hots, debuffs : coin de départ de chaque rangée
--   hotLine, debuffLine : largeur permise à la rangée : "ROLE" jusqu'à l'icône de rôle, "BUFF" jusqu'au buff
--                 manquant, un nombre : part de la largeur de la case. Trop longue, la rangée rapetisse.
--   wrap        : la rangée trop longue passe d'abord à la ligne (2 lignes au plus)
--   inline      : "EDGES" rangées collées aux bords haut et bas de la barre de vie, à une taille qui laisse libre
--                 la ligne du texte ; "BLOCK" les deux rangées l'une sur l'autre au bout de la case, le chiffre
--                 de vie rangé à leur gauche. Ces deux rangées partent d'un coin de droite.
Z.shapes = {
	BAR    = { width = 124, height = 30, fontSize = 11, powerHeight = 3, inline = true,
		auras = { size = 0.34, hots = "TOPRIGHT", debuffs = "BOTTOMRIGHT", hotLine = 0.5, debuffLine = 0.5, inline = "EDGES" } },
	TILE   = { width = 86,  height = 42, fontSize = 11, powerHeight = 4,
		auras = { size = 0.26, hots = "TOPLEFT", debuffs = "BOTTOMRIGHT", hotLine = "ROLE", debuffLine = "BUFF" } },
	SQUARE = { width = 54,  height = 54, fontSize = 10, powerHeight = 4,
		auras = { size = 0.19, hots = "TOPLEFT", debuffs = "BOTTOMRIGHT", hotLine = "ROLE", debuffLine = "BUFF", wrap = true } },
	BANNER = { width = 170, height = 24, fontSize = 10, powerHeight = 2, inline = true,
		auras = { size = 0.38, hots = "TOPRIGHT", debuffs = "BOTTOMRIGHT", hotLine = 0.3, debuffLine = 0.3, inline = "BLOCK" } },
}
Z.shapeKeys = { "width", "height", "fontSize", "powerHeight" } -- les réglages qu'une forme décide

function Z:Shape()
	return Z.shapes[Z.db.shape] or Z.shapes.TILE
end

----------------------------------------------------------------------------------------------------
-- Rangées d'icônes de la forme choisie, à la taille de la case : un seul calcul, lu par les vraies cases
-- (Auras.lua, Containers.lua), le mode test, la case témoin et les bornes de l'éditeur (Placement.lua).
----------------------------------------------------------------------------------------------------
local GAP, MIN_ICON = 2, 5 -- écart entre deux icônes, icône la plus petite
local SIGN = { TOPLEFT = { 1, -1 }, TOPRIGHT = { -1, -1 }, BOTTOMLEFT = { 1, 1 }, BOTTOMRIGHT = { -1, 1 } }

-- Affaiblissements que je peux dissiper montrés avant les autres (1 à 3)
function Z.DispelCount()
	local limits = Z.limits.dispelCount
	return math.max(limits[1], math.min(limits[2], math.floor(tonumber(Z.db.dispelCount) or limits[1])))
end

-- Places de la rangée des affaiblissements : ceux à dissiper, puis les autres (« Tous ») ; ceux à dissiper
-- seulement (« Dissipables par moi »)
function Z.DebuffSlots()
	if Z.db.debuffMode == "ALL" then return Z.DispelCount() + Z.db.debuffCount - 1 end
	return Z.DispelCount()
end

-- Affaiblissements qui bloquent un de mes sorts (Âme affaiblie) : montrés au bout de la rangée de mes soins si
-- ma classe en a (Z.lockouts, Data.lua) et si le réglage est coché
function Z.ShowsLockouts()
	local db = Z.db
	return (db.showHots and db.showLockouts and Z.lockoutIds ~= nil and next(Z.lockoutIds) ~= nil) or false
end

-- Mes soins montrés dans la rangée : l'affaiblissement qui bloque un de mes sorts prend la dernière place (la
-- rangée garde sa taille, décidée pour chaque forme), sauf si un seul soin est réglé : il s'ajoute alors après lui
function Z.HotCount()
	return math.max(1, Z.db.hotCount - (Z.ShowsLockouts() and Z.LOCKOUT_COUNT or 0))
end

-- Places de la rangée de mes soins : mes soins, puis celle de l'affaiblissement qui bloque un de mes sorts
function Z.HotSlots()
	return Z.HotCount() + (Z.ShowsLockouts() and Z.LOCKOUT_COUNT or 0)
end

-- Une rangée de n icônes de taille « size », qui doit tenir dans « line » pixels de large : elle passe à la
-- ligne si elle peut (2 lignes au plus), sinon elle rapetisse. Rend la taille, les icônes par ligne, les lignes.
local function Fit(n, size, line, maxH, canWrap)
	size = math.max(MIN_ICON, math.min(size, maxH))
	local perLine = math.max(1, math.floor((line + GAP) / (size + GAP)))
	if n <= perLine then return size, n, 1 end
	if canWrap and math.ceil(n / perLine) <= 2 then return size, perLine, 2 end
	local each = math.ceil(n / (canWrap and 2 or 1))
	local small = math.max(MIN_ICON, math.floor((line + GAP) / each - GAP))
	return math.min(size, small), each, math.ceil(n / each)
end

-- Rend { hots, debuffs, defensives, controls (des rangées), textX, textW, nameX, nameW }. Une rangée : point d'accroche, cadre
-- ("CELL" la case, "HP" la barre de vie), décalage x et y, taille des icônes, icônes par ligne, lignes, sens
-- (dirX, dirY), largeur et hauteur. textX, textW, nameX, nameW : place du chiffre de vie et du nom, et leurs
-- largeurs (Barre, Bandeau). La taille choisie dans l'éditeur de placement (Z.ElementScale) agrandit ou réduit
-- chaque rangée ; trop grande, elle passe à la ligne ou rapetisse comme une rangée trop longue.
function Z.AuraRows()
	local db, theme = Z.db, Z:Theme()
	local shape = Z:Shape()
	local rules = shape.auras or Z.shapes.TILE.auras
	local W, H = Z.CellSize()
	local inset = Z.UI.Inset(theme.borderSize, db.corners == "ROUND")
	local icon = Z.IconSize()
	local sizes = { iconSize = icon }
	local function Shift(point) return Z.CornerShift(sizes, point) end
	local font = db.fontSize + (theme.fontBonus or 0)
	local want = math.max(MIN_ICON, math.floor(H * rules.size + 0.5))
	local inline = rules.inline
	local canWrap = rules.wrap and not inline and Z.CanWrapAuras()

	-- Ce qui borne une rangée : l'icône de rôle (en haut à droite, ou à gauche sur une ligne) et le buff manquant,
	-- à leur taille choisie dans l'éditeur. Masqués (1.41.1), ils ne bornent plus rien : la rangée va jusqu'au bord,
	-- et rend la place dès qu'ils reviennent.
	local roleOn, buffOn = db.showRole and true or false, db.missingBuffs and true or false
	local roleW, buffW = Z.ElementSize("role", icon - 2), Z.ElementSize("buff", icon)
	local role = shape.inline and { inset + 3, inset + 3 + roleW }
		or { W - 2 - Shift("TOPRIGHT") - roleW, W - 2 - Shift("TOPRIGHT") }
	local buff = { 2 + Shift("BOTTOMLEFT"), 2 + Shift("BOTTOMLEFT") + buffW }
	local function Start(point)
		return point:find("LEFT") and 2 + Shift(point) or W - 2 - Shift(point)
	end
	-- Largeur permise à une rangée, et ce qui l'arrête ("ROLE", "BUFF", sinon nil : la case)
	local function Line(spec, point)
		if type(spec) == "number" then return math.floor(W * spec), nil end
		local on = buffOn
		if spec == "ROLE" then on = roleOn end
		if not on then return point:find("LEFT") and W - 2 - Start(point) or Start(point) - 2, nil end
		local obstacle = spec == "ROLE" and role or buff
		if point:find("LEFT") then return obstacle[1] - GAP - Start(point), spec end
		return Start(point) - obstacle[2] - GAP, spec
	end

	-- Rangées montrées : en Barre et Bandeau, une rangée seule prend toute la hauteur de la barre de vie (1.41.1)
	local hotsOn = db.showHots and true or false
	local debuffsOn = db.showDebuffs and true or false
	local size, maxH = want, math.floor((H - 4) / (canWrap and 2 or 1)) - (canWrap and 1 or 0)
	local maxAlone
	if inline then
		-- La barre de vie la plus basse : celle d'une case avec sa barre de mana. Plus grandes que prévu (éditeur),
		-- les deux rangées se partagent la hauteur de la barre sans se recouvrir.
		local hpH = H - 2 * inset - (db.manaBars ~= "OFF" and Z.PowerHeight() + 1 or 0)
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
		local line, obstacle = Line(spec, point)
		local high = (alone and maxAlone) or maxH
		local s, perLine, lines = Fit(n, wanted, line, high, canWrap)
		-- Ce qui l'empêcherait de grandir encore (message de l'éditeur), vu à la plus grande taille permise : un
		-- obstacle qui raccourcit sa ligne, l'autre rangée qui partage la hauteur, sinon la case
		local most = Fit(n, high, line, high, canWrap)
		local blocker
		if obstacle and most < high then blocker = obstacle
		elseif inline and not alone and most >= high then blocker = key == "hots" and "DEBUFFS" or "HOTS" end
		local sign = SIGN[point]
		local x, y = sign[1] * (2 + Shift(point)), sign[2] * 2
		if inline then x, y = sign[1] * (2 + Shift(point) - inset), 0 end -- au bord de la barre de vie
		rows[key] = { point = point, relative = inline and "HP" or "CELL", x = x, y = y, size = s,
			perLine = perLine, lines = lines, dirX = sign[1], dirY = sign[2], blocker = blocker,
			width = perLine * (s + GAP) - GAP, height = lines * (s + GAP) - GAP }
	end
	Row("hots", rules.hots, rules.hotLine, Z.HotSlots(), inline and not debuffsOn)
	Row("debuffs", rules.debuffs, rules.debuffLine, Z.DebuffSlots(), inline and not hotsOn)

	-- Nom et chiffre de vie sur une ligne (Barre, Bandeau) : places d'origine, sauf en bloc (ci-dessous). Le nom
	-- part après l'icône de rôle, à sa taille choisie ; l'icône masquée, il prend sa place (1.41.1).
	local nameAfter = roleOn and roleW + 5 or 3
	-- l'icône du type à dissiper (allumée) se pose avant le nom, à sa taille choisie (Z.DispelTypeHome, Auras.lua)
	if db.dispelIcon then nameAfter = nameAfter + Z.ElementSize("dispelType", icon) + 2 end
	rows.nameX = nameAfter
	rows.textX, rows.textW, rows.nameW = -4, W - 2 * inset - 8, math.max(20, W - nameAfter - 43)
	if inline == "BLOCK" then
		-- Le bloc fait la largeur de la plus longue rangée réglée (et montrée) ; le chiffre de vie se range à sa
		-- gauche, le nom s'arrête avant lui
		local shown = {
			hots = (db.showHots and db.hotStyle ~= "BARS") and Z.HotSlots() or 0,
			debuffs = db.showDebuffs and Z.DebuffSlots() or 0,
		}
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

	-- Gros défensifs des joueurs (Z.DEFENSIVE_COUNT au plus) : Tuile et Carré, au milieu du bord droit, entre l'icône
	-- de rôle et les affaiblissements ; Barre et Bandeau, sur la ligne du texte, juste avant le chiffre de vie. Ils
	-- partent du côté droit vers la gauche. « flow » : coin d'où le conteneur du jeu range ses icônes.
	local n = Z.DEFENSIVE_COUNT
	local wanted = math.max(MIN_ICON, math.floor(size * Z.ElementScale("defensives") + 0.5))
	local hpH = H - 2 * inset - (db.manaBars ~= "OFF" and Z.PowerHeight() + 1 or 0)
	local s = Fit(n, wanted, math.floor(W * 0.5), inline and math.max(MIN_ICON, hpH - 2) or maxH, false)
	local x = -2
	if inline then
		x = rows.textX - (inline == "BLOCK" and rows.textW or math.ceil(font * 3.2)) - GAP
	end
	rows.defensives = { point = "RIGHT", relative = inline and "HP" or "CELL", x = x, y = 0, size = s, perLine = n,
		lines = 1, dirX = -1, dirY = -1, flow = "TOPRIGHT", width = n * (s + GAP) - GAP, height = s }

	-- Contrôle subi (étourdi, apeuré, métamorphosé) : une icône au centre, un peu plus grande que les autres
	wanted = math.max(MIN_ICON, math.floor(math.floor(icon * 1.2 + 0.5) * Z.ElementScale("controls") + 0.5))
	s = Fit(1, wanted, W - 4, inline and math.max(MIN_ICON, hpH - 2) or H - 4, false)
	rows.controls = { point = "CENTER", relative = inline and "HP" or "CELL", x = 0, y = 0, size = s, perLine = 1,
		lines = 1, dirX = 1, dirY = -1, flow = "TOPLEFT", width = s, height = s }
	return rows
end

-- Choisit une forme. L'état d'avant est gardé : « Revenir » le rétablit (Z:UndoShape).
function Z:ApplyShape(id)
	local shape = Z.shapes[id]
	if not shape then return end
	local undo = { shape = Z.db.shape }
	for _, key in ipairs(Z.shapeKeys) do undo[key] = Z.db[key] end
	Z.shapeUndo = undo
	Z.db.shape = id
	for _, key in ipairs(Z.shapeKeys) do Z.db[key] = shape[key] end
	Z:Refresh()
end

function Z:UndoShape()
	local undo = Z.shapeUndo
	if not undo then return end
	Z.shapeUndo = nil
	for key, value in pairs(undo) do Z.db[key] = value end
	Z:Refresh()
end

-- Couleur de classe, naturelle (celle du jeu) ou vive : plus saturée, sans perdre la teinte de la classe
function Z.ClassColor(class)
	local color = class and C_ClassColor.GetClassColor(class)
	if not color then return 0.6, 0.6, 0.6 end
	local r, g, b = color.r, color.g, color.b
	if Z.db.classIntensity ~= "VIVID" then return r, g, b end
	local gray = (r + g + b) / 3
	r, g, b = gray + (r - gray) * 1.35, gray + (g - gray) * 1.35, gray + (b - gray) * 1.35
	local top = math.max(r, g, b, 0.01)
	local lift = math.min(1 / top, 1.15) -- éclaircit sans dépasser le blanc
	return math.max(0, math.min(1, r * lift)), math.max(0, math.min(1, g * lift)), math.max(0, math.min(1, b * lift))
end
