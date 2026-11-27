-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Themes.lua : les 5 habillages des cases, du plus moderne au plus « MMO ».
-- Un thème n'est qu'une liste de réglages visuels : pour en créer un, copiez un bloc et changez les valeurs.
--   texture    : image de la barre de vie
--   font/flags : police du nom et du texte ("OUTLINE" = contour)
--   bg         : couleur de fond (la vie manquante), rouge, vert, bleu, opacité
--   border     : couleur de la bordure, borderSize : son épaisseur
--   shade      : relief de la barre (ombre en bas, lumière en haut), 0 = aucun
--   incoming   : couleur des soins en route, incomingOnGreen : la même sur une barre de vie verte (contraste)
--   absorb     : couleur du bouclier
--   hot        : couleur de mes soins sur la durée (ce qui reste), le prochain coup en plus franc

local _, Z = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"

Z.themes = {
	{
		id = "NEON", name = "Néon", -- ultra moderne : aplats nets, aucun relief
		texture = WHITE, font = "Fonts\\ARIALN.TTF", flags = "",
		bg = { 0.02, 0.02, 0.04, 0.96 }, border = { 0, 0, 0 }, borderSize = 1,
		shade = { 0, 0 },
		incoming = { 0.20, 1.00, 0.85, 0.50 }, absorb = { 0.30, 0.90, 1.00, 1 },
		incomingOnGreen = { 0.85, 1.00, 1.00, 0.65 },
		hot = { 0.55, 0.95, 0.30, 0.40 },
	},
	{
		id = "PURE", name = "Épuré", -- moderne : aplat avec un léger relief
		texture = WHITE, font = STANDARD_TEXT_FONT, flags = "",
		bg = { 0.07, 0.07, 0.09, 1 }, border = { 0, 0, 0 }, borderSize = 1,
		shade = { 0.28, 0.10 },
		incoming = { 0.45, 1.00, 0.60, 0.42 }, absorb = { 0.55, 0.85, 1.00, 0.95 },
		incomingOnGreen = { 0.88, 1.00, 0.92, 0.60 },
		hot = { 0.35, 0.85, 0.85, 0.36 },
	},
	{
		id = "GLASS", name = "Verre", -- brillant et translucide
		texture = WHITE, font = STANDARD_TEXT_FONT, flags = "OUTLINE",
		bg = { 0.10, 0.12, 0.18, 0.70 }, border = { 0.30, 0.36, 0.50 }, borderSize = 1,
		shade = { 0.45, 0.28 },
		incoming = { 0.60, 1.00, 0.80, 0.42 }, absorb = { 0.75, 0.90, 1.00, 0.95 },
		incomingOnGreen = { 0.92, 1.00, 0.96, 0.56 },
		hot = { 0.50, 0.90, 0.95, 0.36 },
	},
	{
		id = "CLASSIC", name = "Classique", -- l'allure des cadres de raid du jeu
		texture = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill", font = "Fonts\\FRIZQT__.TTF", flags = "",
		bg = { 0.10, 0.10, 0.10, 1 }, border = { 0.35, 0.35, 0.35 }, borderSize = 1,
		shade = { 0.10, 0 },
		incoming = { 0.40, 0.95, 0.45, 0.45 }, absorb = { 0.80, 0.90, 1.00, 0.90 },
		incomingOnGreen = { 0.90, 1.00, 0.85, 0.60 },
		hot = { 0.35, 0.80, 0.75, 0.40 },
	},
	{
		id = "HEROIC", name = "Héroïque", -- purement MMO : barres texturées, bordure dorée
		texture = "Interface\\TargetingFrame\\UI-StatusBar", font = "Fonts\\FRIZQT__.TTF", flags = "OUTLINE",
		bg = { 0.12, 0.08, 0.05, 1 }, border = { 0.78, 0.62, 0.26 }, borderSize = 2,
		shade = { 0.30, 0.06 },
		incoming = { 0.55, 1.00, 0.40, 0.45 }, absorb = { 1.00, 0.92, 0.60, 0.95 },
		incomingOnGreen = { 1.00, 0.95, 0.70, 0.60 },
		hot = { 0.40, 0.85, 0.75, 0.40 },
	},
}

-- Mode contraste élevé (option) : fond noir, bordure blanche, texte plus gros avec contour
local contrast = {
	id = "CONTRAST", name = "Contraste élevé",
	texture = WHITE, font = STANDARD_TEXT_FONT, flags = "OUTLINE", fontBonus = 1,
	bg = { 0, 0, 0, 1 }, border = { 1, 1, 1 }, borderSize = 1,
	shade = { 0, 0 },
	incoming = { 0.20, 1.00, 0.20, 0.85 }, absorb = { 1.00, 1.00, 0.20, 1 },
	incomingOnGreen = { 1.00, 1.00, 1.00, 0.95 },
	hot = { 0.20, 0.85, 1.00, 0.70 },
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

-- Affaiblissements « Toujours montrés » : ceux de Data.lua que je n'ai pas décochés et ceux que j'ai cochés, avec
-- tous leurs rangs, par numéro (le jeu les trouve aussi en combat). Sans le sort bloqué de ma classe, déjà montré
-- au bout de mes soins. Gardés jusqu'au prochain Z:Refresh ou changement de sorts : lus à chaque relecture d'aura.
function Z.ShownIds()
	if Z.shownCache then return Z.shownCache end
	local set, chosen = {}, Z.db.shownDebuffs or {}
	local function Add(id) -- un numéro inconnu du jeu est ignoré (comme dans Data.lua)
		local name = Z.SpellName(id)
		if not name then return end
		set[id] = true
		for rank in pairs(Z.rankIds and Z.rankIds[name] or {}) do set[rank] = true end
	end
	for _, id in ipairs(Z.shownDebuffs) do
		if chosen[id] ~= false then Add(id) end
	end
	for id, on in pairs(chosen) do
		if on == true and type(id) == "number" then Add(id) end
	end
	if Z.ShowsLockouts() then
		for id in pairs(Z.lockoutIds) do set[id] = nil end
	end
	-- sorts de départ décochés : plus montrés du tout (Containers.lua, Auras.lua)
	local off = {}
	for id in pairs(Z.shownDefault) do
		if chosen[id] == false then off[id] = true end
	end
	Z.shownCache, Z.shownOffCache = set, off
	return set
end

-- Les sorts de départ décochés, gardés avec Z.ShownIds
function Z.ShownOff()
	if not Z.shownCache then Z.ShownIds() end
	return Z.shownOffCache
end

-- Une place pour eux en tête de la rangée : en « Utiles » et « Ceux que je dissipe » (sans elle, le mode les
-- écarterait), et en « Tous » quand la rangée montre au moins 3 affaiblissements (prise sur les autres). Avec moins,
-- en « Tous », ils restent parmi les autres : la rangée de départ, réglée pour chaque forme (C34), ne change pas.
function Z.ShownPlace()
	if next(Z.ShownIds()) == nil then return 0 end
	if Z.db.debuffMode == "ALL" and Z.db.debuffCount < 3 then return 0 end
	return 1
end

-- Places de la rangée des affaiblissements : ceux de ma liste « À mettre en avant » (deux au plus, quel que soit
-- le mode) et la place des « Toujours montrés », ceux à dissiper, puis les autres (« Tous » et « Utiles ») ;
-- « Ceux que je dissipe » : rien de plus. En « Tous » et « Utiles », la place des « Toujours montrés » est prise
-- sur les autres s'il leur en reste au moins une (la rangée garde sa longueur), sinon elle s'ajoute (« Utiles »).
-- Avec les conteneurs du jeu, seul un nom reconnu par son numéro compte (sinon le jeu ne peut pas le montrer).
-- Un sort bloqué (Âme affaiblie) ne compte jamais : il est montré au bout de mes soins.
local LISTED_MAX = 2
function Z.DebuffPlaces()
	local listed, boxes = 0, Z.HasAuraBoxes and Z.HasAuraBoxes()
	for name in pairs(Z.db.importantNames) do
		if listed >= LISTED_MAX then break end
		local known = Z.KnownAuraIds and Z.KnownAuraIds(name, true)
		if known or (known == nil and not boxes) then listed = listed + 1 end
	end
	local shown = Z.ShownPlace()
	local others = Z.db.debuffMode ~= "DISPEL" and Z.db.debuffCount - 1 or 0
	if others > 1 then others = others - shown end -- (« Ceux que je dissipe » : aucune autre place)
	return listed + shown, Z.DispelCount(), others
end

function Z.DebuffSlots()
	local listed, dispel, others = Z.DebuffPlaces()
	return listed + dispel + others
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
-- (Barre, Bandeau ; Tuile et Carré ont leurs bandes : FitBand)
local function Fit(n, size, line, maxH, canWrap)
	size = math.max(MIN_ICON, math.min(size, maxH))
	local perLine = math.max(1, math.floor((line + GAP) / (size + GAP)))
	if n <= perLine then return size, n, 1 end
	if canWrap and math.ceil(n / perLine) <= 2 then return size, perLine, 2 end
	local each = math.ceil(n / (canWrap and 2 or 1))
	local small = math.max(MIN_ICON, math.floor((line + GAP) / each - GAP))
	return math.min(size, small), each, math.ceil(n / each)
end

-- Tuile et Carré (C34) : une rangée qui tient dans sa bande (hauteur « cap ») et dans « line » pixels de large.
-- Sur une ligne, elle rapetisse jusqu'à tenir ; sur deux lignes (si elle peut passer à la ligne), chaque ligne
-- prend la moitié de la bande. La plus grande des deux l'emporte (une seule ligne à égalité).
-- Trop longue même à la plus petite taille, elle passe à la ligne si elle peut, quitte à sortir de sa bande.
local function FitBand(n, wanted, line, cap, canWrap)
	local one = math.max(MIN_ICON, math.min(wanted, cap, math.floor((line + GAP) / n - GAP)))
	if canWrap and n > 1 then
		local each = math.ceil(n / 2)
		local two = math.max(MIN_ICON, math.min(wanted, math.floor((cap - GAP) / 2), math.floor((line + GAP) / each - GAP)))
		if two > one or n * (one + GAP) - GAP > line then return two, each, 2 end
	end
	return one, n, 1
end

-- Hauteur des lettres et largeur du chiffre de vie, en tailles de police : ce que les places d'origine
-- laissent libre pour le nom et la vie (C34)
Z.LETTERS = 0.8
Z.DIGITS = 3.2

-- Une place d'origine : point de l'élément, cadre ("HP" la barre de vie, "CELL" la case), point du cadre,
-- décalage, largeur et hauteur
local function Home(point, relative, relPoint, x, y, w, h)
	return { point = point, relative = relative, relPoint = relPoint, x = x, y = y, w = w, h = h or w }
end

-- Les places d'origine pour une façon de ranger la case. Tuile et Carré (C34) : trois bandes. En haut, mes
-- soins depuis la gauche, le rôle et le chef à droite ; au milieu, le nom ; en bas, le buff à gauche et les
-- affaiblissements à droite. mode "LINE" : la vie sur sa propre ligne sous le nom ; "BAND" : la vie dans la bande
-- du bas, entre le buff et les affaiblissements. Barre et Bandeau : mode nil, tout sur la ligne du nom.
-- Rien de ce qui est toujours là (nom, vie, rôle, classe, chef, soins, affaiblissements, type à dissiper, buff)
-- ne se couvre ; une alerte (mana basse, grande icône, contrôle, icône centrale, défensifs) peut couvrir le nom,
-- la vie et les petites icônes, jamais mes soins, les affaiblissements ni le buff.
local function Build(W, H, mode)
	local db, theme = Z.db, Z:Theme()
	local shape = Z:Shape()
	local rules = shape.auras or Z.shapes.TILE.auras
	local inset = Z.UI.Inset(theme.borderSize, db.corners == "ROUND")
	local icon = math.max(10, math.floor(H * 0.30 + 0.5)) -- comme Z.IconSize, à la hauteur de cette case
	local sizes = { iconSize = icon }
	local function Shift(point) return Z.CornerShift(sizes, point) end
	local font = db.fontSize + (theme.fontBonus or 0)
	local nameL, textL = math.ceil(font * Z.LETTERS), math.ceil((font - 1) * Z.LETTERS)
	local textOn = db.text ~= "NONE"
	local digits = textOn and math.ceil(font * Z.DIGITS) or 0
	local want = math.max(MIN_ICON, math.floor(H * rules.size + 0.5))
	local inline = rules.inline
	local canWrap = rules.wrap and not inline and Z.CanWrapAuras()
	local roleOn, buffOn = db.showRole and true or false, db.missingBuffs and true or false
	local leaderOn = db.showLeader and true or false
	local classOn, dispelOn = db.showClassIcon and true or false, db.dispelIcon and true or false
	local hotsOn = (db.showHots and db.hotStyle ~= "BARS") and true or false
	local debuffsOn = db.showDebuffs and true or false
	local powerH = db.manaBars ~= "OFF" and Z.PowerHeight() + 1 or 0
	local hpH = H - 2 * inset - powerH -- la barre de vie la plus basse : celle d'une case avec sa barre de mana
	local rows = { mode = mode, homes = {} }
	local homes = rows.homes

	-- Bandes (Tuile, Carré) : la même hauteur en haut et en bas, autour du milieu (lettres du nom, plus celles de
	-- la vie en « LINE »), un pixel d'écart de chaque côté du milieu
	local band, mid, corner, line
	local nameY, textY = 0, 0
	if not inline then
		local need = nameL + ((mode == "LINE" and textOn) and textL + 1 or 0)
		band = math.max(MIN_ICON, math.floor((H - 4 - need - 2) / 2))
		mid = math.max(MIN_ICON, H - 4 - 2 * band - 2)
		-- la vie sous le nom : le bloc des deux lignes est centré dans le milieu
		if mode == "LINE" and textOn then nameY, textY = math.ceil((textL + 1) / 2), -math.ceil((nameL + 1) / 2) end
		corner = math.min(band, math.max(MIN_ICON, math.floor(W * 0.2))) -- rôle et chef : la ligne des soins garde sa place
		line = math.max(nameL, mid - 2 * nameY) -- hauteur libre autour de la ligne du nom
	end
	local function Cap(base, cap) return math.max(1, cap and math.min(base, cap) or base) end

	-- Icônes seules : leur taille d'origine, jamais plus haute que leur bande (Tuile, Carré), puis la taille
	-- choisie dans l'éditeur (Z.ElementSize)
	local roleBase = Cap(icon - 2, corner)
	local roleW = Z.ElementSize("role", roleBase)
	local leaderW = Z.ElementSize("leader", Cap(Z.BadgeSize(icon), corner))
	local buffW = Z.ElementSize("buff", Cap(icon, band and math.min(band, want))) -- pas plus grand qu'une rangée
	local classW = Z.ElementSize("class", Cap(icon - 2, line))
	local dispelW = Z.ElementSize("dispelType", Cap(icon, line))
	local lowW = Z.ElementSize("lowMana", roleBase) -- à la place de l'icône de rôle, à sa taille
	rows.leaderW, rows.buffW = leaderW, buffW

	-- Barre et Bandeau : l'icône de rôle remonte juste ce qu'il faut pour passer au-dessus du buff (bord gauche)
	local roleY = 0
	if inline and buffOn then
		roleY = math.max(0, math.ceil(3 + buffW + roleW / 2 - H / 2))
		roleY = math.min(roleY, math.max(0, math.floor((H - powerH) / 2 - inset - roleW / 2))) -- dans la barre de vie
	end
	local roleRight = W - 2 - Shift("TOPRIGHT")
	local role = inline and { inset + 3, inset + 3 + roleW } or { roleRight - roleW, roleRight }
	local buff = { 2 + Shift("BOTTOMLEFT"), 2 + Shift("BOTTOMLEFT") + buffW }
	local function Start(point)
		return point:find("LEFT") and 2 + Shift(point) or W - 2 - Shift(point)
	end
	-- Largeur permise à une rangée, et ce qui l'arrête ("ROLE", "BUFF", sinon nil : la case). Masqués (1.41.1),
	-- le rôle et le buff ne bornent plus rien. Tuile et Carré : la ligne des soins s'arrête aussi au chef, à gauche
	-- du rôle ; en « BAND », les affaiblissements laissent la place du chiffre de vie après le buff.
	local function Line(spec, point)
		if type(spec) == "number" then return math.floor(W * spec), nil end
		local obstacle, blocker
		if spec == "ROLE" then
			local leader = leaderOn and not inline
			if roleOn or leader then obstacle, blocker = { leader and role[1] - 1 - leaderW or role[1], role[2] }, "ROLE" end
		else
			if buffOn then obstacle, blocker = { buff[1], buff[2] }, "BUFF" end
			if mode == "BAND" and textOn then
				obstacle = { obstacle and obstacle[1] or 2, (obstacle and obstacle[2] + GAP or 2) + digits }
			end
		end
		if not obstacle then return point:find("LEFT") and W - 2 - Start(point) or Start(point) - 2, nil end
		if point:find("LEFT") then return obstacle[1] - GAP - Start(point), blocker end
		return Start(point) - obstacle[2] - GAP, blocker
	end

	-- Rangées montrées : en Barre et Bandeau, une rangée seule peut grandir sur toute la hauteur de la barre de vie
	-- (1.41.1) ; à sa taille d'origine, elle laisse libre la ligne du texte.
	local size, maxH = want, math.floor((H - 4) / (canWrap and 2 or 1)) - (canWrap and 1 or 0)
	local maxAlone
	if inline then
		local both = hotsOn and debuffsOn
		local room = inline == "EDGES" and math.floor((hpH - textL - 2) / 2)
			or (both and math.floor((hpH - 1) / 2) or hpH)
		size = math.max(MIN_ICON, math.min(want, room))
		maxH = math.max(MIN_ICON, math.floor((hpH - 1) / 2))
		maxAlone = math.max(MIN_ICON, hpH)
	else
		size = math.min(want, band)
	end
	local largest = Z.limits.placement.size[2] / 100
	local function Row(key, point, spec, n, alone)
		local scale = Z.ElementScale(key)
		local wanted = math.max(MIN_ICON, math.floor(size * scale + 0.5))
		local line, obstacle = Line(spec, point)
		local s, perLine, lines, blocker
		if inline then
			local high = (alone and maxAlone) or maxH
			s, perLine, lines = Fit(n, wanted, line, high, canWrap)
			-- Ce qui l'empêcherait de grandir encore (message de l'éditeur), vu à la plus grande taille permise : un
			-- obstacle qui raccourcit sa ligne, l'autre rangée qui partage la hauteur, sinon la case
			local most = Fit(n, high, line, high, canWrap)
			if obstacle and most < high then blocker = obstacle
			elseif not alone and most >= high then blocker = key == "hots" and "DEBUFFS" or "HOTS" end
		else
			-- Plus grande que sa taille d'origine (éditeur), elle peut sortir de sa bande, jamais de la case
			local cap = math.min(H - 4, math.max(band, math.floor(band * scale)))
			s, perLine, lines = FitBand(n, wanted, line, cap, canWrap)
			local high = math.min(H - 4, math.floor(band * largest))
			if obstacle and FitBand(n, high, line, high, canWrap) < high then blocker = obstacle end
		end
		local sign = SIGN[point]
		local x, y = sign[1] * (2 + Shift(point)), sign[2] * 2
		if inline then x, y = sign[1] * (2 + Shift(point) - inset), 0 end -- au bord de la barre de vie
		rows[key] = { point = point, relative = inline and "HP" or "CELL", x = x, y = y, size = s,
			perLine = perLine, lines = lines, dirX = sign[1], dirY = sign[2], blocker = blocker,
			width = perLine * (s + GAP) - GAP, height = lines * (s + GAP) - GAP }
	end
	Row("hots", rules.hots, rules.hotLine, Z.HotSlots(), inline and not debuffsOn)
	Row("debuffs", rules.debuffs, rules.debuffLine, Z.DebuffSlots(), inline and not hotsOn)

	if inline then
		-- Nom et chiffre de vie sur une ligne (Barre, Bandeau). Le nom part après l'icône de rôle, à sa taille
		-- choisie, et après le badge du chef posé sur son coin ; l'icône masquée, il prend sa place (1.41.1).
		local overhang = leaderOn and math.max(0, math.ceil(leaderW / 2) - 2) or 0
		local nameAfter = (roleOn or leaderOn) and roleW + 5 + overhang or 3
		-- jamais sur le buff, poussé vers la droite par un carré de coin
		if buffOn then nameAfter = math.max(nameAfter, buff[2] + 2 - inset) end
		local classX = nameAfter -- l'icône de classe (allumée) juste après l'icône de rôle
		if classOn then nameAfter = nameAfter + classW + 2 end
		local dispelX = nameAfter -- l'icône du type à dissiper (allumée) avant le nom
		if dispelOn then nameAfter = nameAfter + dispelW + 2 end
		-- le nom s'arrête avant le chiffre de vie (au bout de la barre de vie)
		local textX, textW = -4, W - 2 * inset - 8
		local nameW = math.max(font, W - 2 * inset - 4 - math.ceil(font * Z.DIGITS) - 2 - nameAfter)
		if inline == "BLOCK" then
			-- Le bloc fait la largeur de la plus longue rangée réglée (et montrée) ; le chiffre de vie se range à sa
			-- gauche, le nom s'arrête avant lui
			local left
			for key, n in pairs({ hots = hotsOn and Z.HotSlots() or 0, debuffs = debuffsOn and Z.DebuffSlots() or 0 }) do
				local row = rows[key]
				if n > 0 then
					local edge = Start(row.point) - (math.min(n, row.perLine) * (row.size + GAP) - GAP)
					left = math.min(left or edge, edge)
				end
			end
			if left then
				local textRight = math.max(inset + 1, left - 4)
				textW = math.max(1, math.min(math.ceil(font * Z.DIGITS), textRight - inset))
				textX = textRight - (W - inset)
				nameW = math.max(font, textRight - textW - 2 - (inset + nameAfter))
			end
		end
		rows.textX, rows.textW = textX, textW -- chiffre du bouclier, gros défensifs
		homes.role = Home("LEFT", "HP", "LEFT", 3, roleY, roleW)
		homes.lowMana = Home("LEFT", "HP", "LEFT", 3, roleY, lowW)
		homes.class = Home("LEFT", "HP", "LEFT", classX, 0, classW)
		homes.dispelType = Home("LEFT", "HP", "LEFT", dispelX, 0, dispelW)
		homes.name = Home("LEFT", "HP", "LEFT", nameAfter, 0, nameW, font + 2)
		homes.text = Home("RIGHT", "HP", "RIGHT", textX, 0, textW, font + 1)
	else
		-- Tuile, Carré : le nom au milieu, raccourci des deux côtés quand l'icône de classe et celle du type à
		-- dissiper (allumées) se posent au début de sa ligne ; la vie sous lui (« LINE ») ou dans la bande du bas
		local items = (classOn and classW + 2 or 0) + (dispelOn and dispelW + 2 or 0)
		homes.role = Home("TOPRIGHT", "CELL", "TOPRIGHT", -2 - Shift("TOPRIGHT"), -2, roleW)
		homes.lowMana = Home("TOPRIGHT", "CELL", "TOPRIGHT", -2 - Shift("TOPRIGHT"), -2, lowW)
		homes.class = Home("LEFT", "CELL", "LEFT", 3, nameY, classW)
		homes.dispelType = Home("LEFT", "CELL", "LEFT", 3 + (classOn and classW + 2 or 0), nameY, dispelW)
		homes.name = Home("CENTER", "CELL", "CENTER", 0, nameY, items > 0 and W - 2 * (3 + items) or W - 8, font + 2)
		if mode == "BAND" and textOn then
			local from = (buffOn and buff[2] or 2) + GAP
			local to = debuffsOn and Start(rules.debuffs) - rows.debuffs.width - GAP or W - 2
			local high = math.min(band, math.max(textL, buffOn and buffW or 0, debuffsOn and rows.debuffs.size or 0))
			homes.text = Home("CENTER", "CELL", "BOTTOMLEFT", math.floor((from + to) / 2), 2 + math.floor(high / 2),
				math.max(1, to - from), font + 1)
		else
			homes.text = Home("CENTER", "CELL", "CENTER", 0, textY, W - 8, font + 1)
		end
	end

	-- Alertes du milieu (grande icône, contrôle, icône centrale, gros défensifs) : jamais plus hautes que le milieu
	-- (Tuile, Carré). Barre et Bandeau : l'icône centrale et le contrôle passent entre mes soins et les
	-- affaiblissements quand ces rangées vont jusqu'au centre de la case.
	local centerCap, controlCap = mid, mid
	if inline then
		local topH, bottomH = 0, 0
		local function Reach(row, on, s) return on and W - 2 - Shift(row.point) - row.width < (W + s) / 2 end
		if Reach(rows.hots, hotsOn, icon + 8) then topH = rows.hots.height + 1 end
		if Reach(rows.debuffs, debuffsOn, icon + 8) then bottomH = rows.debuffs.height + 1 end
		centerCap = math.max(MIN_ICON, math.floor(2 * math.min(H / 2 - inset - powerH - bottomH, H / 2 - inset - topH)))
		controlCap = math.max(MIN_ICON, hpH - 2 * math.max(topH, bottomH) - 2)
	end
	-- Barre et Bandeau : la grande icône se pose après le buff, au bord gauche, et s'arrête avant les rangées
	local bigX, bigCap = (inline and buffOn) and buff[2] + 2 or 3, mid
	if inline then
		bigCap = hpH - 2
		if hotsOn then bigCap = math.min(bigCap, W - 2 - Shift(rows.hots.point) - rows.hots.width - GAP - bigX) end
		if debuffsOn then bigCap = math.min(bigCap, W - 2 - Shift(rows.debuffs.point) - rows.debuffs.width - GAP - bigX) end
		bigCap = math.max(MIN_ICON, bigCap)
	end
	local bigW = Z.ElementSize("big", Cap(math.floor(icon * 1.6 + 0.5), bigCap))
	homes.big = Home("LEFT", "CELL", "LEFT", bigX, 0, bigW)
	homes.center = Home("CENTER", "CELL", "CENTER", 0, 0, Z.ElementSize("center", Cap(icon + 8, centerCap)))

	-- Gros défensifs des joueurs (Z.DEFENSIVE_COUNT au plus) : Tuile et Carré, au milieu du bord droit ; Barre et
	-- Bandeau, sur la ligne du texte, juste avant le chiffre de vie. Ils partent du côté droit vers la gauche.
	-- « flow » : coin d'où le conteneur du jeu range ses icônes.
	-- Barre et Bandeau : ils s'arrêtent avant le buff, et passent entre les rangées qui vont jusqu'à eux.
	local n = Z.DEFENSIVE_COUNT
	local wanted = math.max(MIN_ICON, math.floor(Cap(size, mid) * Z.ElementScale("defensives") + 0.5))
	local x, defLine, defCap = -2, math.floor(W * 0.5), maxH
	if inline then
		x = rows.textX - (inline == "BLOCK" and rows.textW or math.ceil(font * Z.DIGITS)) - GAP
		local right = W - inset + x -- bord droit des défensifs, dans la case
		if buffOn then defLine = math.min(defLine, right - buff[2] - GAP) end
		local reach = 0
		for key, on in pairs({ hots = hotsOn, debuffs = debuffsOn }) do
			local row = rows[key]
			if on and W - 2 - Shift(row.point) - row.width < right then reach = math.max(reach, row.height + 1) end
		end
		defCap = math.max(MIN_ICON, hpH - 2 * reach - 2)
	end
	local s = Fit(n, wanted, math.max(MIN_ICON, defLine), defCap, false)
	rows.defensives = { point = "RIGHT", relative = inline and "HP" or "CELL", x = x, y = 0, size = s, perLine = n,
		lines = 1, dirX = -1, dirY = -1, flow = "TOPRIGHT", width = n * (s + GAP) - GAP, height = s }

	-- Contrôle subi (étourdi, apeuré, métamorphosé) : une icône au centre, un peu plus grande que les autres
	wanted = math.max(MIN_ICON, math.floor(Cap(math.floor(icon * 1.2 + 0.5), controlCap) * Z.ElementScale("controls") + 0.5))
	s = Fit(1, wanted, W - 4, inline and math.max(MIN_ICON, hpH - 2) or H - 4, false)
	rows.controls = { point = "CENTER", relative = inline and "HP" or "CELL", x = 0, y = 0, size = s, perLine = 1,
		lines = 1, dirX = 1, dirY = -1, flow = "TOPLEFT", width = s, height = s }
	return rows
end

-- Rend { hots, debuffs, defensives, controls (des rangées), homes (places d'origine des autres éléments) }.
-- Une rangée : point d'accroche, cadre ("CELL" la case, "HP" la barre de vie), décalage x et y, taille des
-- icônes, icônes par ligne, lignes, sens (dirX, dirY), largeur et hauteur. La taille choisie dans l'éditeur de
-- placement (Z.ElementScale) agrandit ou réduit chaque rangée ; trop grande, elle passe à la ligne ou rapetisse.
-- Tuile et Carré : les deux façons de ranger la case sont calculées, celle aux plus grandes icônes est gardée.
-- width, height : taille d'une case plus petite (familier), sinon celle des joueurs.
function Z.AuraRows(width, height)
	local W, H = Z.CellSize()
	W, H = width or W, height or H
	local rules = Z:Shape().auras or Z.shapes.TILE.auras
	if rules.inline then return Build(W, H, nil) end
	local line, band = Build(W, H, "LINE"), Build(W, H, "BAND")
	local function Score(rows)
		local db, best = Z.db, math.huge
		if db.showHots and db.hotStyle ~= "BARS" then best = math.min(best, rows.hots.size) end
		if db.showDebuffs then best = math.min(best, rows.debuffs.size) end
		return best
	end
	return Score(band) > Score(line) and band or line
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

-- Icône d'une classe (nom interne : PRIEST...) sur une texture : l'image du jeu (atlas « classicon- »), sinon les
-- cercles de classe du jeu. Classe inconnue ou secrète : texture cachée. Rend true si elle est montrée.
function Z.SetClassIcon(tex, class)
	if type(class) ~= "string" or Z.IsSecret(class) then tex:Hide() return false end
	local atlas = "classicon-" .. class:lower()
	if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
		tex:SetAtlas(atlas)
	elseif CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class] then
		tex:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
		tex:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
	else
		tex:Hide()
		return false
	end
	tex:Show()
	return true
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
