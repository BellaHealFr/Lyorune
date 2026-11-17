-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - UI.lua : le style visuel et les petits éléments d'interface (boutons, cases, fenêtres).
-- Tout est dessiné avec les éléments natifs du jeu : rien de plus léger.

local _, Z = ...
local UI = {}
Z.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"
UI.WHITE = WHITE

-- Palette des fenêtres de Lyorune (options, visite guidée, petites fenêtres). Jamais celle des cases de soin.
-- Ces tables sont remplies par UI.ApplySkin() selon le thème de fenêtre choisi, et modifiées sur place :
-- un élément qui lit UI.accent au moment d'un survol suit donc le thème sans rien faire de plus.
UI.accent = {}  -- couleur d'accent (titres, valeurs, survol)
UI.gold   = {}  -- second accent (runes, séparateurs)
UI.bg     = {}  -- fond des fenêtres
UI.panel  = {}  -- fond des boutons et des champs
UI.line   = {}  -- traits et bordures discrètes
UI.edge   = {}  -- cadre des fenêtres
UI.text   = {}  -- texte
UI.dim    = {}  -- texte secondaire
UI.btext  = {}  -- texte des boutons
UI.ROLES = { "accent", "gold", "bg", "panel", "line", "edge", "text", "dim", "btext" }

-- Couleur fixe des cadres de soin (étiquettes « Groupe N », infobulle des clics) : hors thème de fenêtre
UI.frameAccent = { 0.20, 0.87, 0.53 }

-- LibSharedMedia est facultatif : s'il est installé (ElvUI, SharedMedia...), ses textures sont proposées.
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local builtinTextures = {
	{ "Lyorune", WHITE },
	{ "Blizzard", "Interface\\TargetingFrame\\UI-StatusBar" },
	{ "Raid", "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
}

function UI.TextureList()
	local list = {}
	for _, entry in ipairs(builtinTextures) do list[#list + 1] = entry[1] end
	if LSM then
		for _, name in ipairs(LSM:List("statusbar")) do list[#list + 1] = name end
	end
	return list
end

function UI.BarTexture()
	local wanted = Z.db.texture
	if wanted == "THEME" then return Z:Theme().texture end
	for _, entry in ipairs(builtinTextures) do
		if entry[1] == wanted then return entry[2] end
	end
	return (LSM and LSM:Fetch("statusbar", wanted, true)) or WHITE
end

function UI.Font()
	return STANDARD_TEXT_FONT
end

----------------------------------------------------------------------------------------------------
-- Thèmes des fenêtres : Moderne, Classique, MMORPG (réglage « windowTheme »)
-- Chaque thème donne une couleur par rôle, la police des titres, le cadre et les couleurs des runes.
-- Les cases de soin ne sont jamais concernées : seuls les éléments notés avec UI.Paint sont repeints.
----------------------------------------------------------------------------------------------------
-- Un thème complet = un ensemble cohérent : cadre de fenêtre, boutons, cases à cocher, rubriques et runes.
--   kit       : famille des éléments (MODERN plat et net, CLASSIC textures du jeu, MMO pierre et or)
--   headFont  : police des titres de rubrique (la police décorative est réservée aux titres)
--   L'en-tête des fenêtres (logo, nom, version) garde la même police et la même taille dans tous les thèmes.
UI.skins = {
	MODERN = { -- net, sombre, bleu givre et or du logo ; angles arrondis, éléments plats
		accent = { 0.45, 0.78, 1.00 }, gold = { 0.93, 0.75, 0.35 },
		bg = { 0.05, 0.06, 0.08 }, panel = { 0.10, 0.11, 0.14 }, line = { 0.22, 0.25, 0.32 }, edge = { 0.26, 0.30, 0.38 },
		text = { 0.92, 0.94, 0.97 }, dim = { 0.62, 0.66, 0.72 }, btext = { 0.92, 0.94, 0.97 },
		bgAlpha = 0.92, kit = "MODERN", headFont = "STANDARD", headSize = 13,
		runeBase = { 0.62, 0.84, 1.00 }, runeGlow = { 0.80, 0.93, 1.00 },
	},
	CLASSIC = { -- les fenêtres du jeu : cadre de boîte de dialogue, boutons rouges, cases à cocher du jeu
		accent = { 1.00, 0.82, 0.00 }, gold = { 1.00, 0.82, 0.00 },
		bg = { 0.06, 0.06, 0.06 }, panel = { 0.14, 0.14, 0.14 }, line = { 0.34, 0.34, 0.34 }, edge = { 1, 1, 1 },
		text = { 1.00, 1.00, 1.00 }, dim = { 0.70, 0.70, 0.70 }, btext = { 1.00, 0.82, 0.00 },
		bgAlpha = 1, kit = "CLASSIC", headFont = "Fonts\\FRIZQT__.TTF", headSize = 13,
		runeBase = { 0.93, 0.75, 0.35 }, runeGlow = { 1.00, 0.90, 0.60 },
	},
	MMO = { -- grimoire runique : fond de pierre, bordure dorée, runes aux angles, plaques dorées, braise
		accent = { 1.00, 0.78, 0.30 }, gold = { 1.00, 0.78, 0.30 },
		bg = { 0.08, 0.07, 0.06 }, panel = { 0.16, 0.12, 0.08 }, line = { 0.55, 0.42, 0.20 }, edge = { 1, 1, 1 },
		text = { 0.96, 0.92, 0.84 }, dim = { 0.74, 0.68, 0.58 }, btext = { 1.00, 0.88, 0.62 },
		bgAlpha = 0.78, kit = "MMO", headFont = "Fonts\\MORPHEUS.TTF", headSize = 15,
		runeBase = { 1.00, 0.78, 0.30 }, runeGlow = { 1.00, 0.50, 0.15 }, sparks = true,
	},
}
-- Contraste élevé : appliqué par-dessus le thème choisi (cadre plat, fond noir, bordure blanche)
local CONTRAST = { bg = { 0, 0, 0 }, text = { 1, 1, 1 }, btext = { 1, 1, 1 }, dim = { 0.86, 0.86, 0.86 }, line = { 0.75, 0.75, 0.75 }, edge = { 1, 1, 1 }, bgAlpha = 1 }

-- Textures du jeu lui-même (présentes sur Forever) pour les thèmes Classique et MMORPG
local GAME = {
	dialogBg = "Interface\\DialogFrame\\UI-DialogBox-Background",
	dialogEdge = "Interface\\DialogFrame\\UI-DialogBox-Border",
	goldEdge = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
	rock = "Interface\\FrameGeneral\\UI-Background-Rock",
	button = "Interface\\Buttons\\UI-Panel-Button-Up",
	buttonDown = "Interface\\Buttons\\UI-Panel-Button-Down",
	buttonHighlight = "Interface\\Buttons\\UI-Panel-Button-Highlight",
	checkBox = "Interface\\Buttons\\UI-CheckBox-Up",
	check = "Interface\\Buttons\\UI-CheckBox-Check",
}
UI.GAME = GAME
local BACKDROPS = {
	CLASSIC = { bgFile = GAME.dialogBg, edgeFile = GAME.dialogEdge, tile = true, tileSize = 32, edgeSize = 24,
		insets = { left = 6, right = 6, top = 6, bottom = 6 } },
	MMO = { bgFile = GAME.rock, edgeFile = GAME.goldEdge, tile = true, tileSize = 128, edgeSize = 24,
		insets = { left = 6, right = 6, top = 6, bottom = 6 } },
}

-- Famille d'éléments en vigueur (le contraste élevé ramène toujours au cadre plat, le plus lisible)
function UI.Kit()
	if Z.db and Z.db.highContrast then return "FLAT" end
	return UI.skin.kit
end

-- Éléments notés, gardés par une référence forte : un élément retenu seulement ici (un titre de rubrique, par
-- exemple) ne doit jamais disparaître de la liste, sinon il ne serait plus repeint au changement de thème.
local painted, paintOrder = {}, {} -- élément -> { rôle, opacité, facteur } ; éléments dans l'ordre de création
local windows, hooks = {}, {}
UI.skin = UI.skins.MODERN

local function Paint(obj, role, alpha, factor)
	local c, f = UI[role], factor or 1
	if alpha == "bgAlpha" then alpha = UI.bgAlpha or UI.skin.bgAlpha end
	local r, g, b, a = c[1] * f, c[2] * f, c[3] * f, alpha or 1
	if obj.isBorder then
		obj:SetColor(r, g, b, a)
	elseif obj:GetObjectType() == "FontString" then
		obj:SetTextColor(r, g, b, a)
	else
		obj:SetVertexColor(r, g, b, a)
	end
end

-- Note un élément de fenêtre (texture, texte ou bordure) et lui donne la couleur d'un rôle.
-- alpha : nombre, ou nom d'un champ du thème (« bgAlpha ») ; factor : assombrit (0,45 = 45 %).
function UI.Paint(obj, role, alpha, factor)
	if not painted[obj] then paintOrder[#paintOrder + 1] = obj end
	painted[obj] = { role, alpha, factor }
	Paint(obj, role, alpha, factor)
	return obj
end

-- Titre d'une fenêtre : police et taille fixes dans tous les thèmes (l'en-tête ne bouge jamais)
function UI.Title(parent, size)
	return UI.Paint(UI.Text(parent, size), "accent")
end

-- Habillage des éléments selon le thème : UI.Style(élément, "button" | "check" | "heading" | "divider").
-- Chaque famille construit ses textures à la première utilisation, puis seulement les montre ou les cache.
local styled = {}
UI.styles = {}

function UI.Style(widget, kind)
	styled[#styled + 1] = { widget, kind }
	UI.styles[kind](widget, UI.Kit())
	return widget
end

-- Police des titres de rubrique. Seul un refus explicite (false) ramène la police par défaut.
local function HeadFont(fs)
	local skin = UI.skin
	local file = (skin.headFont == "STANDARD" or UI.Kit() == "FLAT") and STANDARD_TEXT_FONT or skin.headFont
	if fs:SetFont(file, skin.headSize, "") == false then fs:SetFont(STANDARD_TEXT_FONT, 13, "") end
end

function UI.styles.heading(fs)
	HeadFont(fs)
end

-- Appelée à chaque changement de thème (fonction(skin)) : pour ce qui n'est pas une simple couleur
function UI.OnSkin(fn)
	hooks[#hooks + 1] = fn
end

-- Texte coloré dans une chaîne : "|cff" .. UI.Hex("accent")
function UI.Hex(role)
	local c = UI[role]
	return string.format("%02x%02x%02x", c[1] * 255 + 0.5, c[2] * 255 + 0.5, c[3] * 255 + 0.5)
end

-- Remplit la palette selon le réglage, puis repeint une fois tout ce qui a été noté. Aucun coût en jeu.
function UI.ApplySkin()
	local db = Z.db or {}
	local skin = UI.skins[db.windowTheme] or UI.skins.MODERN
	UI.skin = skin
	UI.skinName = UI.skins[db.windowTheme] and db.windowTheme or "MODERN"
	UI.applied = { db.windowTheme, db.highContrast and true or false }
	for _, role in ipairs(UI.ROLES) do
		local c = db.highContrast and CONTRAST[role] or skin[role]
		UI[role][1], UI[role][2], UI[role][3] = c[1], c[2], c[3]
	end
	UI.bgAlpha = db.highContrast and CONTRAST.bgAlpha or skin.bgAlpha
	-- Chaque élément est repeint à part : une erreur sur l'un (notée dans le journal) n'arrête pas les autres
	local failed
	for _, obj in ipairs(paintOrder) do
		local entry = painted[obj]
		local ok, err = pcall(Paint, obj, entry[1], entry[2], entry[3])
		if not ok and not failed then failed = err end
	end
	for _, w in ipairs(windows) do
		if Z.Try then Z:Try("thème des fenêtres", UI.Decorate, w) else UI.Decorate(w) end
	end
	local kit = UI.Kit()
	for _, entry in ipairs(styled) do
		local ok, err = pcall(UI.styles[entry[2]], entry[1], kit)
		if not ok and not failed then failed = err end
	end
	if failed and Z.Log and Z.db then Z:Log("Erreur Lua", "thème des fenêtres : " .. tostring(failed), "") end
	for _, fn in ipairs(hooks) do
		if Z.Try then Z:Try("thème des fenêtres", fn, skin) else fn(skin) end
	end
end

-- Pour les tests
function UI.Painted()
	return painted, paintOrder
end

-- Vrai si le thème ou le contraste élevé a changé depuis le dernier UI.ApplySkin()
function UI.SkinChanged()
	local db = Z.db or {}
	return not UI.applied or UI.applied[1] ~= db.windowTheme or UI.applied[2] ~= (db.highContrast and true or false)
end

-- Animations réduites : seulement des fondus courts, rien en boucle
function UI.Calm()
	return Z.db and Z.db.reduceMotion
end

----------------------------------------------------------------------------------------------------
-- Briques de base
----------------------------------------------------------------------------------------------------
function UI.Tex(parent, layer, r, g, b, a)
	local t = parent:CreateTexture(nil, layer or "BACKGROUND")
	t:SetTexture(WHITE)
	t:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
	return t
end

function UI.Text(parent, size, flags)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(UI.Font(), size or 12, flags or "")
	fs:SetShadowColor(0, 0, 0, 1)
	fs:SetShadowOffset(1, -1)
	fs:SetTextColor(0.92, 0.94, 0.97)
	return fs
end

-- Texte d'une fenêtre de Lyorune : sa couleur suit le thème de fenêtre (rôle « text » par défaut)
function UI.Label(parent, size, flags, role)
	return UI.Paint(UI.Text(parent, size, flags), role or "text")
end

-- Angles arrondis : une petite image (Media/Angle*.tga, dessinée par outils/angles.py) dont le jeu étire le milieu
-- en gardant les coins à leur taille. Aucun masque, aucun calcul : une seule texture de plus par élément.
local MEDIA = "Interface\\AddOns\\Lyorune\\Media\\"
local CORNER = 6 -- marge des coins dans l'image, en pixels (MARGE dans outils/angles.py)
UI.ROUND = MEDIA .. "Angle"

-- Texture aux coins arrondis : file = UI.ROUND (plein), ou UI.ROUND .. "1" / "2" (contour)
function UI.RoundTex(parent, layer, file)
	local t = parent:CreateTexture(nil, layer or "BACKGROUND")
	t:SetTexture(file or UI.ROUND)
	if t.SetTextureSliceMargins then t:SetTextureSliceMargins(CORNER, CORNER, CORNER, CORNER) end
	return t
end

-- Retrait des barres à l'intérieur d'une case : leurs coins carrés ne dépassent jamais d'un angle arrondi
function UI.Inset(borderSize, rounded)
	return rounded and math.max(borderSize, 2) or borderSize
end

-- Bordure de « size » pixels autour de parent, décalée de « outset » vers l'extérieur
local function BorderSetColor(self, r, g, b, a)
	for i = 1, 4 do self[i]:SetVertexColor(r, g, b, a or 1) end
	if self.round then self.round:SetVertexColor(r, g, b, a or 1) end
	self.color = { r, g, b, a or 1 }
end

-- Trait d'au moins « size » vrais pixels : à une échelle d'interface non entière, un trait de 1 posé entre deux
-- pixels de l'écran serait arrondi à zéro par le jeu et disparaîtrait (bord droit des cases à cocher).
local function Line(t, horizontal, size)
	if PixelUtil and PixelUtil.SetWidth then
		if horizontal then PixelUtil.SetHeight(t, size, size) else PixelUtil.SetWidth(t, size, size) end
	elseif horizontal then
		t:SetHeight(size)
	else
		t:SetWidth(size)
	end
end

local function BorderSetThickness(self, size)
	self.size = size
	Line(self[1], true, size)
	Line(self[2], true, size)
	self[3]:SetPoint("TOPLEFT", 0, -size) self[3]:SetPoint("BOTTOMLEFT", 0, size) Line(self[3], false, size)
	self[4]:SetPoint("TOPRIGHT", 0, -size) self[4]:SetPoint("BOTTOMRIGHT", 0, size) Line(self[4], false, size)
	if self.round then self.round:SetTexture(UI.ROUND .. (size >= 2 and "2" or "1")) end
end

-- Angles droits (quatre traits) ou arrondis (une image de contour)
local function BorderSetRounded(self, rounded)
	rounded = rounded and true or false
	if rounded and not self.round then
		self.round = UI.RoundTex(self, "OVERLAY", UI.ROUND .. "1")
		self.round:SetAllPoints()
		if self.color then self.round:SetVertexColor(unpack(self.color)) end
		BorderSetThickness(self, self.size)
	end
	for i = 1, 4 do self[i]:SetShown(not rounded) end
	if self.round then self.round:SetShown(rounded) end
	self.rounded = rounded
end

function UI.Border(parent, size, outset)
	local f = CreateFrame("Frame", nil, parent)
	outset = outset or 0
	f:SetPoint("TOPLEFT", parent, "TOPLEFT", -outset, outset)
	f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", outset, -outset)
	for i = 1, 4 do f[i] = UI.Tex(f, "OVERLAY", 0, 0, 0, 1) end
	f[1]:SetPoint("TOPLEFT") f[1]:SetPoint("TOPRIGHT")
	f[2]:SetPoint("BOTTOMLEFT") f[2]:SetPoint("BOTTOMRIGHT")
	f.isBorder = true
	f.SetColor = BorderSetColor
	f.SetThickness = BorderSetThickness
	f.SetRounded = BorderSetRounded
	f:SetThickness(size)
	return f
end

local function Click()
	PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
end

----------------------------------------------------------------------------------------------------
-- Runes et animations (toutes jouées par le jeu : aucun calcul à chaque image)
----------------------------------------------------------------------------------------------------
UI.RUNES = MEDIA .. "Runes"      -- atlas de 8 colonnes sur 4 lignes (outils/runes.py)
UI.HALOS = MEDIA .. "RunesHalo"  -- les mêmes runes, floues, pour leur halo
local RUNE_COLUMNS, RUNE_ROWS = 8, 4

-- Découpe une rune de l'atlas (index 1 à 24, ordre de outils/runes.py) dans une texture
function UI.CutRune(texture, index, size, file)
	local column, row = (index - 1) % RUNE_COLUMNS, math.floor((index - 1) / RUNE_COLUMNS)
	texture:SetTexture(file or UI.RUNES)
	texture:SetTexCoord(column / RUNE_COLUMNS, (column + 1) / RUNE_COLUMNS, row / RUNE_ROWS, (row + 1) / RUNE_ROWS)
	texture:SetSize(size, size)
	return texture
end

function UI.Rune(parent, layer, index, size)
	return UI.CutRune(parent:CreateTexture(nil, layer or "ARTWORK"), index, size or 12)
end

-- Ajoute une animation d'opacité à un groupe. Courbe OUT par défaut : jamais IN pour répondre au joueur.
function UI.AlphaAnim(group, from, to, duration, smoothing, order, delay)
	local a = group:CreateAnimation("Alpha")
	a:SetFromAlpha(from)
	a:SetToAlpha(to)
	a:SetDuration(duration)
	a:SetSmoothing(smoothing or "OUT")
	a:SetOrder(order or 1)
	if delay then a:SetStartDelay(delay) end
	return a
end
local AlphaAnim = UI.AlphaAnim

-- Respiration lente et sans fin (logo, rune de l'étape en cours) : coupée par « Animations réduites »
function UI.Breathe(region, low, period)
	local group = region:CreateAnimationGroup()
	group:SetLooping("BOUNCE")
	AlphaAnim(group, 1, low, period / 2, "IN_OUT")
	return group
end

-- Petite rune qui s'allume à côté d'un réglage qu'on vient de changer (0,4 s), puis s'éteint
function UI.Confirm(widget)
	if not widget.confirm then
		local rune = UI.Paint(UI.Rune(widget, "OVERLAY", 20, 10), "gold")
		rune:SetPoint("RIGHT", widget, "LEFT", -5, 0)
		rune:SetAlpha(0)
		widget.confirm = rune:CreateAnimationGroup()
		AlphaAnim(widget.confirm, 0, 1, 0.1, "OUT", 1)
		AlphaAnim(widget.confirm, 1, 0, 0.3, "IN_OUT", 2)
		widget.confirm:SetToFinalAlpha(true) -- la rune finit éteinte, quoi qu'il arrive
		widget.confirm:SetScript("OnFinished", function() rune:SetAlpha(0) end)
	end
	widget.confirm:Stop()
	widget.confirm:Play()
	UI.SoothingSpark(widget)
end

----------------------------------------------------------------------------------------------------
-- Effets magiques (réglage « magicEffects ») : cercle runique derrière le logo, particules de lumière dans
-- l'en-tête, étincelle de soin avec la rune de confirmation. Couleur de la lueur du thème (givre, or, braise).
-- Jamais sur les cases de soin. Coupés par « Animations réduites ». Images : outils/runes.py.
----------------------------------------------------------------------------------------------------
UI.MAGIC_CIRCLE = MEDIA .. "MagieCercle"
UI.MAGIC_SPARK = MEDIA .. "MagieEtincelle"
local FLASHES = 3 -- au plus 3 éclairs par seconde, toutes fenêtres confondues
local flashes = {}

function UI.Magic()
	return Z.db and Z.db.magicEffects and not Z.db.reduceMotion and true or false
end

-- Vrai si un éclair peut partir maintenant (sinon il est simplement sauté)
function UI.Flash()
	local now = GetTime()
	while flashes[1] and now - flashes[1] >= 1 do table.remove(flashes, 1) end
	if #flashes >= FLASHES then return false end
	flashes[#flashes + 1] = now
	return true
end

local function MagicColor(texture, alpha)
	local c = UI.skin.runeGlow
	texture:SetVertexColor(c[1], c[2], c[3], alpha or 1)
end

-- Étincelle qui monte au-dessus de la rune de confirmation (0,5 s), puis s'éteint
function UI.SoothingSpark(widget)
	if not UI.Magic() or not UI.Flash() then return end
	if not widget.spark then
		local spark = widget:CreateTexture(nil, "OVERLAY")
		spark:SetTexture(UI.MAGIC_SPARK)
		spark:SetSize(12, 12)
		spark:SetBlendMode("ADD")
		spark:SetPoint("CENTER", widget, "LEFT", -10, 0) -- sur la rune de confirmation
		spark:SetAlpha(0)
		local group = spark:CreateAnimationGroup()
		AlphaAnim(group, 0, 1, 0.1, "OUT", 1)
		AlphaAnim(group, 1, 0, 0.4, "IN", 2)
		for order, rise in ipairs({ { 3, 0.1 }, { 9, 0.4 } }) do
			local up = group:CreateAnimation("Translation")
			up:SetOffset(0, rise[1])
			up:SetDuration(rise[2])
			up:SetSmoothing("OUT")
			up:SetOrder(order)
		end
		group:SetToFinalAlpha(true)
		group:SetScript("OnFinished", function() spark:SetAlpha(0) end)
		widget.spark, widget.sparkRise = spark, group
	end
	MagicColor(widget.spark)
	widget.sparkRise:Stop()
	widget.sparkRise:Play()
end

-- Particule de l'en-tête : apparaît, monte de 22 pixels en s'effaçant, puis attend son tour
local function Mote(field, x, delay, rest)
	local mote = field:CreateTexture(nil, "ARTWORK")
	mote:SetTexture(UI.MAGIC_SPARK)
	mote:SetSize(7, 7)
	mote:SetBlendMode("ADD")
	mote:SetPoint("BOTTOM", field, "BOTTOM", x, 2)
	mote:SetAlpha(0)
	local group = mote:CreateAnimationGroup()
	group:SetLooping("REPEAT")
	AlphaAnim(group, 0, 0.8, 0.8, "OUT", 1, delay)
	AlphaAnim(group, 0.8, 0, 2.2, "IN", 2):SetEndDelay(rest)
	for order, rise in ipairs({ { 6, 0.8, delay }, { 16, 2.2 } }) do
		local up = group:CreateAnimation("Translation")
		up:SetOffset(0, rise[1])
		up:SetDuration(rise[2])
		if rise[3] then up:SetStartDelay(rise[3]) end
		up:SetOrder(order)
	end
	return mote, group
end

-- Effets de l'en-tête d'une fenêtre : cercle runique derrière « logo », particules entre le titre et « right »
-- (le champ de recherche). La zone des particules coupe tout ce qui en sort : rien ne passe derrière le texte.
function UI.HeaderMagic(w, logo, right)
	local m = { motes = {}, rises = {} }
	m.circle = w:CreateTexture(nil, "BORDER")
	m.circle:SetTexture(UI.MAGIC_CIRCLE)
	m.circle:SetSize(38, 38)
	m.circle:SetPoint("CENTER", logo)
	m.circle:SetBlendMode("ADD")
	m.spin = m.circle:CreateAnimationGroup()
	m.spin:SetLooping("REPEAT")
	local turn = m.spin:CreateAnimation("Rotation")
	turn:SetDegrees(-360)
	turn:SetDuration(300) -- un tour toutes les 5 minutes : à peine perceptible
	-- Éclat à l'ouverture : le cercle s'allume doucement, puis retombe lentement à son éclat de repos
	m.burst = m.circle:CreateAnimationGroup()
	AlphaAnim(m.burst, 0, 0.75, 1.2, "IN_OUT", 1)
	AlphaAnim(m.burst, 0.75, 0.35, 2.5, "IN_OUT", 2)
	m.burst:SetToFinalAlpha(true)

	m.field = CreateFrame("Frame", nil, w)
	m.field:SetPoint("TOPLEFT", w.title, "TOPRIGHT", 12, 12)
	m.field:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", -12, 0)
	m.field:SetClipsChildren(true)
	for i, spot in ipairs({ { -90, 0, 1.6 }, { -35, 1.3, 0.9 }, { 20, 0.6, 2.1 }, { 70, 2.0, 1.2 }, { 115, 2.9, 0.4 } }) do
		m.motes[i], m.rises[i] = Mote(m.field, spot[1], spot[2], spot[3])
	end

	function m.Paint()
		MagicColor(m.circle, m.circle:GetAlpha())
		for _, mote in ipairs(m.motes) do MagicColor(mote) end
	end

	function m.Stop()
		m.spin:Stop()
		m.burst:Stop()
		for _, group in ipairs(m.rises) do group:Stop() end
	end

	-- À l'ouverture et à chaque changement de réglage : tout part, ou tout s'arrête et se cache
	function m.Update(opening)
		local on = UI.Magic()
		m.circle:SetShown(on)
		m.field:SetShown(on)
		if not on or not w:IsShown() then return m.Stop() end
		m.Paint()
		if opening and UI.Flash() then
			m.burst:Stop()
			m.burst:Play()
		elseif not m.burst:IsPlaying() then
			m.circle:SetAlpha(0.35)
		end
		if not m.spin:IsPlaying() then m.spin:Play() end
		for _, group in ipairs(m.rises) do
			if not group:IsPlaying() then group:Play() end
		end
	end

	w:HookScript("OnShow", function() m.Update(true) end)
	w:HookScript("OnHide", m.Stop)
	UI.OnSkin(m.Paint)
	m.Update()
	return m
end

-- Bordure qui s'allume en douceur au survol d'un bouton (créée au premier survol seulement).
-- Thème Classique : le bouton du jeu a déjà son reflet au survol, la bordure n'est pas ajoutée.
local function Glow(button, on)
	if button.gameLook then return end
	if not button.glow then
		button.glow = UI.Paint(UI.Border(button, 1), "accent")
		button.glow:SetAlpha(0)
		button.glowIn = button.glow:CreateAnimationGroup()
		AlphaAnim(button.glowIn, 0, 1, 0.15)
		button.glowIn:SetToFinalAlpha(true)
		button.glowOut = button.glow:CreateAnimationGroup()
		AlphaAnim(button.glowOut, 1, 0, 0.15)
		button.glowOut:SetToFinalAlpha(true)
	end
	button.glowIn:Stop()
	button.glowOut:Stop()
	if on then button.glowIn:Play() else button.glowOut:Play() end
end

----------------------------------------------------------------------------------------------------
-- Styles des éléments, un par famille de thème
----------------------------------------------------------------------------------------------------
-- Images des thèmes, dessinées par outils/habillage.py, découpées en 9 (les bords gardent leur taille)
local SLICE = 6 -- MARGE dans outils/habillage.py
local SKIN = {
	MMO = { plate = MEDIA .. "ThemeMMOPlaque", plateDown = MEDIA .. "ThemeMMOPlaqueClic", tab = MEDIA .. "ThemeMMOOnglet",
		tabActive = MEDIA .. "ThemeMMOOngletActif", field = MEDIA .. "ThemeMMOChamp", box = MEDIA .. "ThemeMMOCase" },
	CLASSIC = { tab = MEDIA .. "ThemeClassiqueOnglet", tabActive = MEDIA .. "ThemeClassiqueOngletActif",
		field = MEDIA .. "ThemeClassiqueChamp" },
}
UI.SKIN = SKIN

-- Calque d'habillage d'un élément : créé à la première utilisation, puis seulement montré ou caché.
-- Un seul calque visible à la fois par élément (« key » = celui à montrer, nil = aucun).
local function Layer(owner, key, file, layer, sliced, region)
	owner.layers = owner.layers or {}
	local t = owner.layers[key]
	if not t then
		t = owner:CreateTexture(nil, layer or "BACKGROUND", nil, 1)
		t:SetTexture(file)
		if sliced and t.SetTextureSliceMargins then t:SetTextureSliceMargins(SLICE, SLICE, SLICE, SLICE) end
		t:SetAllPoints(region or owner)
		owner.layers[key] = t
	end
	return t
end

local function ShowLayer(owner, key)
	for name, t in pairs(owner.layers or {}) do t:SetShown(name == key) end
end

-- Bouton. Moderne : plat, bordure fine. Classique : bouton rouge du jeu, son reflet et son état enfoncé.
-- MMORPG : plaque de bronze au biseau doré (image), qui s'enfonce au clic.
-- Un onglet (b.isTab) prend l'image d'onglet du thème, plus claire quand il est actif (UI.SetTab).
function UI.styles.button(b, kit)
	local key
	if b.isTab and SKIN[kit] then
		-- Onglet : une image par thème et par état (normal, actif), gardée sous son propre nom
		key = kit .. (b.active and "TabActive" or "Tab")
		Layer(b, key, SKIN[kit][b.active and "tabActive" or "tab"], "BACKGROUND", true)
	elseif kit == "CLASSIC" then
		if not b.gameLight then
			for _, name in ipairs({ "gameUp", "gameDown" }) do
				local t = Layer(b, name, name == "gameUp" and GAME.button or GAME.buttonDown)
				t:SetTexCoord(0, 0.625, 0, 0.6875)
			end
			b.gameLight = b:CreateTexture(nil, "HIGHLIGHT")
			b.gameLight:SetTexture(GAME.buttonHighlight)
			b.gameLight:SetTexCoord(0, 0.625, 0, 0.6875)
			b.gameLight:SetBlendMode("ADD")
			b.gameLight:SetAllPoints()
		end
		key = "gameUp"
	elseif kit == "MMO" then
		Layer(b, "plate", SKIN.MMO.plate, "BACKGROUND", true)
		Layer(b, "plateDown", SKIN.MMO.plateDown, "BACKGROUND", true)
		key = "plate"
	end
	if not b.pressHooked then
		b.pressHooked = true
		b:HookScript("OnMouseDown", function(self)
			if self.restKey == "gameUp" then ShowLayer(self, "gameDown")
			elseif self.restKey == "plate" then ShowLayer(self, "plateDown") end
		end)
		b:HookScript("OnMouseUp", function(self) ShowLayer(self, self.restKey) end)
	end
	b.restKey = key
	ShowLayer(b, key)
	local textured = key ~= nil
	b.gameLook = kit == "CLASSIC" and not b.isTab
	b.bg:SetShown(not textured)
	b.border:SetShown(not textured)
	if b.gameLight then b.gameLight:SetShown(b.gameLook) end
	if b.glow then b.glow:SetAlpha(0) end
end

-- Onglet actif ou non : change d'image dans les thèmes Classique et MMORPG
function UI.SetTab(b, active)
	b.isTab, b.active = true, active and true or false
	UI.styles.button(b, UI.Kit())
end

-- Case à cocher. Moderne : carré plat et marque pleine. Classique : case et coche du jeu.
-- MMORPG : creux cerclé d'or (image), la marque est une rune.
function UI.styles.check(c, kit)
	c.box:ClearAllPoints()
	c.mark:ClearAllPoints()
	if kit == "CLASSIC" or kit == "MMO" then
		local classic = kit == "CLASSIC"
		c.box:SetTexture(classic and GAME.checkBox or SKIN.MMO.box)
		c.box:SetTexCoord(0, 1, 0, 1)
		c.box:SetVertexColor(1, 1, 1, 1)
		c.box:SetSize(classic and 22 or 18, classic and 22 or 18)
		c.box:SetPoint("LEFT", classic and -3 or -1, 0)
		c.border:Hide()
		if classic then
			c.mark:SetTexture(GAME.check)
			c.mark:SetTexCoord(0, 1, 0, 1)
			c.mark:SetVertexColor(1, 1, 1, 1)
			c.mark:SetAllPoints(c.box)
		else
			UI.CutRune(c.mark, 20, 12)
			c.mark:SetPoint("CENTER", c.box)
		end
	else
		c.box:SetTexture(WHITE)
		c.box:SetTexCoord(0, 1, 0, 1)
		c.box:SetSize(16, 16)
		c.box:SetPoint("LEFT")
		c.border:Show()
		c.mark:SetTexture(WHITE)
		c.mark:SetTexCoord(0, 1, 0, 1)
		c.mark:SetPoint("TOPLEFT", c.box, 3, -3)
		c.mark:SetPoint("BOTTOMRIGHT", c.box, -3, 3)
	end
	c.label:ClearAllPoints()
	c.label:SetPoint("LEFT", c.box, "LEFT", 24, 0)
end

-- Champ de saisie, liste ou zone de texte (élément avec .bg et, s'il en a une, .border).
-- Moderne : fond uni et bordure fine. Classique et MMORPG : champ creusé (image).
function UI.styles.field(f, kit)
	local file = SKIN[kit] and SKIN[kit].field
	if file then
		Layer(f, kit, file, "BACKGROUND", true, f.bg)
	end
	ShowLayer(f, file and kit or nil)
	f.bg:SetAlpha(file and 0 or 1)
	if f.border then f.border:SetShown(not file or f.focused) end
end

-- Pour un fond de zone (texture seule, sans cadre) : habillé comme un champ
function UI.Field(frame, bg, border)
	frame.bg, frame.border = bg, border
	return UI.Style(frame, "field")
end

-- Séparateur de rubrique. Moderne et MMORPG : trait coupé par une rune. Classique : simple trait doré du jeu.
function UI.styles.divider(f, kit)
	local rune = kit ~= "CLASSIC"
	f.rune:SetShown(rune)
	f.left:ClearAllPoints()
	f.left:SetPoint("LEFT")
	f.left:SetPoint("RIGHT", rune and f.rune or f, rune and "LEFT" or "RIGHT", rune and -5 or 0, 0)
	f.right:SetShown(rune)
end

----------------------------------------------------------------------------------------------------
-- Éléments des fenêtres
----------------------------------------------------------------------------------------------------
function UI.Button(parent, text, width, height, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(width, height)
	b.bg = UI.Paint(UI.Tex(b, "BACKGROUND"), "panel")
	b.bg:SetAllPoints()
	b.border = UI.Paint(UI.Border(b, 1), "line")
	b.label = UI.Label(b, 12, nil, "btext")
	b.label:SetPoint("LEFT", 6, 0)
	b.label:SetPoint("RIGHT", -6, 0)
	b.label:SetWordWrap(false)
	b.label:SetText(text or "")
	b:SetScript("OnEnter", function(self)
		Glow(self, true)
		if self.tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(self.tip, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end
	end)
	b:SetScript("OnLeave", function(self)
		Glow(self, false)
		GameTooltip:Hide()
	end)
	b:SetScript("OnClick", function(self, button)
		Click()
		if onClick then onClick(self, button) end
	end)
	return UI.Style(b, "button")
end

-- Case à cocher : get() donne l'état, set(valeur) l'enregistre
function UI.Check(parent, label, get, set)
	local c = CreateFrame("Button", nil, parent)
	c:SetSize(250, 20)
	c.box = UI.Paint(UI.Tex(c, "BACKGROUND"), "panel")
	c.border = UI.Paint(UI.Border(c, 1), "line")
	c.border:ClearAllPoints()
	c.border:SetAllPoints(c.box)
	c.mark = UI.Paint(UI.Tex(c, "ARTWORK"), "accent")
	c.label = UI.Label(c, 12)
	c.label:SetText(label)
	c.Update = function(self) self.mark:SetShown(get() and true or false) end
	c:SetScript("OnClick", function(self)
		Click()
		set(not get())
		self:Update()
		UI.Confirm(self)
	end)
	c:SetScript("OnShow", c.Update)
	UI.Style(c, "check")
	c:Update()
	return c
end

-- Valeur numérique avec boutons - et +
function UI.Stepper(parent, label, min, max, step, get, set)
	local s = CreateFrame("Frame", nil, parent)
	s:SetSize(250, 22)
	s.label = UI.Label(s, 12)
	s.label:SetPoint("LEFT")
	s.label:SetText(label)
	s.value = UI.Label(s, 12, nil, "accent")
	s.value:SetPoint("RIGHT", -30, 0)
	s.value:SetWidth(40)
	s.Update = function(self) self.value:SetText(get()) end
	local function change(delta)
		set(math.max(min, math.min(max, get() + delta)))
		s:Update()
		UI.Confirm(s)
	end
	s.plus = UI.Button(s, "+", 22, 22, function() change(step) end)
	s.plus:SetPoint("RIGHT")
	s.plus.label:SetJustifyH("CENTER")
	s.minus = UI.Button(s, "-", 22, 22, function() change(-step) end)
	s.minus:SetPoint("RIGHT", -74, 0)
	s.minus.label:SetJustifyH("CENTER")
	s:SetScript("OnShow", s.Update)
	s:Update()
	return s
end

-- Choix parmi une liste : chaque clic passe au choix suivant (clic droit : précédent).
-- choices = { { valeur, "libellé" }, ... }
function UI.Cycle(parent, label, choices, get, set)
	local c = CreateFrame("Frame", nil, parent)
	c:SetSize(250, 22)
	c.label = UI.Label(c, 12)
	c.label:SetPoint("LEFT")
	c.label:SetText(label)
	local function index()
		local current = get()
		for i, choice in ipairs(choices) do
			if choice[1] == current then return i end
		end
		return 1
	end
	c.button = UI.Button(c, "", 130, 22, function(_, mouseButton)
		local i = index() + (mouseButton == "RightButton" and -1 or 1)
		if i > #choices then i = 1 elseif i < 1 then i = #choices end
		set(choices[i][1])
		c:Update()
		UI.Confirm(c)
	end)
	c.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	c.button:SetPoint("RIGHT")
	c.button.label:SetJustifyH("CENTER")
	UI.Paint(c.button.label, "accent")
	c.Update = function(self) self.button.label:SetText(choices[index()][2]) end
	c:SetScript("OnShow", c.Update)
	c:Update()
	return c
end

-- Champ de saisie. onEnter(texte) est appelé à la touche Entrée.
function UI.Edit(parent, width, onEnter)
	local e = CreateFrame("EditBox", nil, parent)
	e:SetSize(width, 22)
	e:SetAutoFocus(false)
	e:SetFont(UI.Font(), 12, "")
	e:SetTextInsets(6, 6, 0, 0)
	e.bg = UI.Paint(UI.Tex(e, "BACKGROUND"), "panel")
	e.bg:SetAllPoints()
	e.border = UI.Paint(UI.Border(e, 1), "line")
	e:SetScript("OnEscapePressed", e.ClearFocus)
	-- Champ actif : bordure d'accent, montrée aussi par-dessus les champs creusés des thèmes texturés
	e:SetScript("OnEditFocusGained", function(self)
		self.focused = true
		self.border:SetColor(UI.accent[1], UI.accent[2], UI.accent[3])
		self.border:Show()
		self:HighlightText()
	end)
	e:SetScript("OnEditFocusLost", function(self)
		self.focused = false
		self.border:SetColor(UI.line[1], UI.line[2], UI.line[3])
		UI.styles.field(self, UI.Kit())
		self:HighlightText(0, 0)
	end)
	e:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		if onEnter then onEnter((self:GetText():match("^%s*(.-)%s*$"))) end
	end)
	return UI.Style(e, "field")
end

-- Séparateur de rubrique : un trait fin coupé en son milieu par une petite rune dorée
function UI.Divider(parent)
	local f = CreateFrame("Frame", nil, parent)
	f:SetHeight(9)
	f.rune = UI.Paint(UI.Rune(f, "ARTWORK", 20, 9), "gold", 0.8)
	f.rune:SetPoint("CENTER")
	f.left = UI.Paint(UI.Tex(f, "ARTWORK"), "line")
	f.left:SetHeight(1)
	f.right = UI.Paint(UI.Tex(f, "ARTWORK"), "line")
	f.right:SetPoint("LEFT", f.rune, "RIGHT", 5, 0)
	f.right:SetPoint("RIGHT")
	f.right:SetHeight(1)
	return UI.Style(f, "divider")
end

-- Titre de rubrique : sa police suit le thème (police décorative en MMORPG, celle du jeu en Classique)
function UI.Heading(parent, size)
	return UI.Style(UI.Label(parent, size or 13, nil, "accent"), "heading")
end

----------------------------------------------------------------------------------------------------
-- Fenêtres
----------------------------------------------------------------------------------------------------
local HEADER = 44 -- hauteur de l'en-tête (titre, recherche, fermeture), identique dans tous les thèmes

-- Habille une fenêtre selon le thème. Moderne : fond uni aux angles arrondis, bordure fine, liseré givre.
-- Classique : cadre et fond de boîte de dialogue du jeu. MMORPG : fond de pierre assombri derrière le texte,
-- bordure dorée du jeu, une rune gravée dans chaque angle. Les calques sont construits une fois.
function UI.Decorate(w)
	local kit = UI.Kit()
	local flat, framed = kit == "MODERN" or kit == "FLAT", kit == "CLASSIC" or kit == "MMO"
	local rounded = kit == "MODERN"
	w.bg:SetShown(kit == "FLAT")
	w.round:SetShown(rounded)
	w.border:SetShown(flat)
	w.border:SetThickness(kit == "FLAT" and 2 or 1)
	w.border:SetRounded(rounded)
	if w.SetBackdrop then
		w:SetBackdrop(framed and BACKDROPS[kit] or nil)
		if framed then
			w:SetBackdropColor(1, 1, 1, 1)
			w:SetBackdropBorderColor(1, 1, 1, 1)
		end
	end
	-- Voile uni derrière le texte : la pierre reste visible mais ne gêne jamais la lecture
	w.shade:SetShown(kit == "MMO")
	w.accent:ClearAllPoints()
	if framed then
		w.accent:SetPoint("TOPLEFT", 12, -HEADER)
		w.accent:SetPoint("TOPRIGHT", -12, -HEADER)
		w.accent:SetHeight(1)
	else
		local inset = rounded and 6 or 2
		w.accent:SetPoint("TOPLEFT", inset, -1)
		w.accent:SetPoint("TOPRIGHT", -inset, -1)
		w.accent:SetHeight(2)
	end
	if kit == "MMO" and not w.ornate then
		w.ornate = CreateFrame("Frame", nil, w)
		w.ornate:SetAllPoints()
		w.ornate.runes = {}
		for i, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
			local rune = UI.Paint(UI.Rune(w.ornate, "OVERLAY", ({ 4, 9, 17, 22 })[i], 12), "gold", 0.9)
			rune:SetPoint("CENTER", w, corner, corner:find("LEFT") and 8 or -8, corner:find("TOP") and -8 or 8)
			w.ornate.runes[i] = rune
		end
	end
	if w.ornate then w.ornate:SetShown(kit == "MMO") end
end

-- Une fenêtre secondaire (macros, rapport de bug, journal, nouveautés) s'ouvre à côté de la fenêtre d'options
-- au lieu de la recouvrir : à droite s'il y a la place, sinon à gauche, sinon contre le bord le plus dégagé.
local GAP = 8
function UI.PlaceBeside(w)
	local main = UI.main
	if not main or main == w or not main:IsShown() then return end
	local left, right, screen = main:GetLeft(), main:GetRight(), UIParent:GetWidth()
	if not left or not right or not screen then return end
	local width = w:GetWidth()
	w:ClearAllPoints()
	if screen - right >= width + GAP then
		w:SetPoint("TOPLEFT", main, "TOPRIGHT", GAP, 0)
	elseif left >= width + GAP then
		w:SetPoint("TOPRIGHT", main, "TOPLEFT", -GAP, 0)
	elseif screen - right >= left then
		w:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, main:GetTop() - UIParent:GetHeight())
	else
		w:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, main:GetTop() - UIParent:GetHeight())
	end
end

-- Apparition : fondu et léger grossissement (0,25 s), ou simple fondu de 0,15 s en animations réduites
function UI.Appear(w)
	if w.beside then UI.PlaceBeside(w) end
	w.outro:Stop()
	if UI.Calm() then w.calm:Play() else w.intro:Play() end
end

-- Fermeture par la croix : fondu de 0,15 s (Échap ferme sans attendre)
local function WindowClose(self)
	if UI.Calm() or not self:IsShown() then return self:Hide() end
	self.outro:Play()
end

-- Fenêtre déplaçable avec titre et bouton de fermeture. Titre et croix ont la même place dans tous les thèmes,
-- en retrait des cadres épais (Classique, MMORPG).
function UI.Window(name, title, width, height)
	local w = CreateFrame("Frame", name, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	w:SetSize(width, height)
	w:SetPoint("CENTER")
	w:SetFrameStrata("DIALOG")
	w:SetClampedToScreen(true)
	w:EnableMouse(true)
	w:SetMovable(true)
	w:RegisterForDrag("LeftButton")
	w:SetScript("OnDragStart", w.StartMoving)
	w:SetScript("OnDragStop", w.StopMovingOrSizing)
	w.bg = UI.Paint(UI.Tex(w, "BACKGROUND"), "bg", "bgAlpha")
	w.bg:SetAllPoints()
	w.round = UI.Paint(UI.RoundTex(w, "BACKGROUND"), "bg", "bgAlpha")
	w.round:SetAllPoints()
	w.shade = UI.Paint(UI.Tex(w, "BACKGROUND", 0, 0, 0, 1), "bg", "bgAlpha")
	w.shade:SetDrawLayer("BACKGROUND", 2)
	w.shade:SetPoint("TOPLEFT", 7, -7)
	w.shade:SetPoint("BOTTOMRIGHT", -7, 7)
	w.border = UI.Paint(UI.Border(w, 1), "edge")
	w.accent = UI.Paint(UI.Tex(w, "ARTWORK"), "accent")
	w.title = UI.Title(w, 15)
	w.title:SetPoint("TOPLEFT", 18, -16)
	w.title:SetText(title)
	w.Close = WindowClose
	w.close = UI.Button(w, "x", 22, 22, function() w:Close() end)
	w.close:SetPoint("TOPRIGHT", -12, -12)
	w.close.label:SetJustifyH("CENTER")

	w.intro = w:CreateAnimationGroup()
	AlphaAnim(w.intro, 0, 1, 0.25)
	local grow = w.intro:CreateAnimation("Scale")
	if grow.SetScaleFrom then
		grow:SetScaleFrom(0.96, 0.96)
		grow:SetScaleTo(1, 1)
	end
	grow:SetDuration(0.25)
	grow:SetSmoothing("OUT")
	w.calm = w:CreateAnimationGroup()
	AlphaAnim(w.calm, 0, 1, 0.15)
	w.outro = w:CreateAnimationGroup()
	AlphaAnim(w.outro, 1, 0, 0.15)
	w.outro:SetScript("OnFinished", function() w:Hide() end)
	w:HookScript("OnShow", UI.Appear)

	windows[#windows + 1] = w
	UI.Decorate(w)
	w:Hide()
	return w
end

-- Pour les tests
function UI.Windows()
	return windows
end

UI.ApplySkin() -- palette de départ (Moderne) ; reprise avec les réglages du joueur au chargement
