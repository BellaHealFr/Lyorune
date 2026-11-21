-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Logo.lua : animation autour du logo de la fenêtre d'options, au choix du joueur (réglage
-- « logoAnimation », avec les effets magiques) :
--   Aurore  : une lueur par classe de soin dérive lentement autour du logo, un reflet glisse sur le médaillon,
--             des étincelles de soin montent du bord ;
--   Sceau   : un anneau doré fixe porte une gemme par classe de soin ; une traînée de lumière court d'une gemme à
--             la suivante, qui s'allume et teinte le halo derrière le logo ;
--   Souffle : une onde de soin part du bord du logo toutes les 4 s, chaque fois de la couleur de la classe suivante.
-- Bonnes pratiques suivies : boucles lentes, courbes douces, rien ne tourne sur lui-même, rien ne clignote, éclat
-- faible, coupées par « Animations réduites ». Seulement des textures et des animations du jeu : aucun code ne
-- tourne pendant que la fenêtre est ouverte. Une animation n'est construite qu'à son premier affichage.
-- Les attentes sont des animations éteintes (opacité 0 à 0), jamais des délais (règle C1, voir UI.lua).
-- Images : outils/runes.py.

local _, Z = ...
local UI = Z.UI
local MEDIA = "Interface\\AddOns\\Lyorune\\Media\\"
local LOGO = 13 -- rayon du logo de l'en-tête (26 pixels)
local SEAL = 17 -- rayon de l'anneau du sceau
local SEAL_DOTS = 9 -- points de lumière de la traînée entre deux gemmes

-- Couleurs des classes de soin : celles qui ont des soins suivis dans Data.lua (une classe ajoutée y entre seule),
-- dans l'ordre de leur nom interne pour que le cycle soit toujours le même
local function HealerColors()
	local classes, colors = {}, {}
	for class in pairs(Z.trackedSpells or {}) do classes[#classes + 1] = class end
	table.sort(classes)
	for _, class in ipairs(classes) do
		local c = C_ClassColor.GetClassColor(class)
		if c then colors[#colors + 1] = { c.r, c.g, c.b } end
	end
	if #colors == 0 then colors[1] = UI.HEAL_GREEN end
	return colors
end

-- Une animation : ses textures (montrées ou cachées ensemble) et ses groupes (lancés ou arrêtés ensemble)
local function NewStyle()
	return { regions = {}, groups = {} }
end

-- Texture de lumière centrée sur le logo (décalage x, y), en mode additif sauf « blend » donné
local function Light(s, w, logo, layer, file, size, color, alpha, x, y, blend)
	local t = w:CreateTexture(nil, layer)
	t:SetTexture(MEDIA .. file)
	t:SetSize(size, size)
	t:SetBlendMode(blend or "ADD")
	t:SetVertexColor(color[1], color[2], color[3], 1)
	t:SetAlpha(alpha or 0)
	t:SetPoint("CENTER", logo, "CENTER", x or 0, y or 0)
	s.regions[#s.regions + 1] = t
	return t
end

-- Boucle d'opacité : parts = { { de, à, durée, courbe }, ... }, une durée nulle est sautée.
-- move(group, ordre, partie, durée) ajoute un mouvement joué en même temps que la partie.
local function Timeline(s, region, parts, move)
	local group = region:CreateAnimationGroup()
	group:SetLooping("REPEAT")
	local order = 0
	for i, part in ipairs(parts) do
		if part[3] > 0 then
			order = order + 1
			UI.AlphaAnim(group, part[1], part[2], part[3], part[4] or "NONE", order)
			if move then move(group, order, i, part[3]) end
		end
	end
	s.groups[#s.groups + 1] = group
	return group
end

-- Mouvement d'une partie de boucle : déplacement, rotation (degrés) ou agrandissement
local function Translate(group, order, duration, x, y, smoothing)
	local a = group:CreateAnimation("Translation")
	a:SetOffset(x, y)
	a:SetDuration(duration)
	a:SetSmoothing(smoothing)
	a:SetOrder(order)
end

-- Fondu enchaîné d'une couleur à la suivante : la couleur i s'allume à (i - 1) × (fondu + pause) ; la dernière
-- commence allumée et s'éteint pendant que la première s'allume, la boucle n'a donc pas de couture. Courbes
-- IN_OUT symétriques en mode additif : l'éclat reste le même, seule la teinte glisse.
local function Crossfade(s, textures, peak, fade, hold)
	local n, step = #textures, fade + hold
	for i, t in ipairs(textures) do
		t:SetAlpha(i == n and peak or 0)
		if n > 1 then
			if i < n then
				Timeline(s, t, { { 0, 0, (i - 1) * step }, { 0, peak, fade, "IN_OUT" }, { peak, peak, hold },
					{ peak, 0, fade, "IN_OUT" }, { 0, 0, (n - i) * step - fade } })
			else
				Timeline(s, t, { { peak, 0, fade, "IN_OUT" }, { 0, 0, (n - 1) * step - fade },
					{ 0, peak, fade, "IN_OUT" }, { peak, peak, hold } })
			end
		end
	end
end

-- Couleur entre a et b (p de 0 à 1)
local function Mix(a, b, p)
	return { a[1] + (b[1] - a[1]) * p, a[2] + (b[2] - a[2]) * p, a[3] + (b[3] - a[3]) * p }
end

----------------------------------------------------------------------------------------------------
-- Aurore : les lueurs tournent autour du logo à des vitesses différentes (26 à 37 s par tour, sens alternés) ;
-- le médaillon, opaque, cache leur centre : on ne voit que la lumière qui déborde, mêlée et toujours changeante.
-- Un reflet glisse sur le médaillon toutes les 10 s (masque rond du jeu). Une étincelle par classe monte du bord,
-- une toutes les 2,5 s.
----------------------------------------------------------------------------------------------------
local AURORA_PERIODS, AURORA_ORBITS, AURORA_POINTS = { 26, 33, 29, 37 }, { 7, 9, 6, 8 }, 24

local function Aurora(w, logo, colors)
	local s, n = NewStyle(), #colors
	for i, c in ipairs(colors) do
		local orbit, phase = AURORA_ORBITS[(i - 1) % 4 + 1], (i - 1) * 2 * math.pi / n
		local dir = i % 2 == 1 and 1 or -1
		local ox, oy = orbit * math.cos(phase), orbit * math.sin(phase)
		local blob = Light(s, w, logo, "BORDER", "MagieLueur", 28, c, 0.42, ox, oy)
		local group = blob:CreateAnimationGroup()
		group:SetLooping("REPEAT")
		local path = group:CreateAnimation("Path")
		path:SetDuration(AURORA_PERIODS[(i - 1) % 4 + 1])
		-- Points reliés en ligne droite, jamais la courbe lissée du jeu : ouverte au point de départ, elle y ralentit
		-- puis accélère à chaque tour. 24 points égaux : vitesse constante, et aucun angle visible sur 6 à 9 pixels.
		path:SetCurveType("NONE")
		for k = 1, AURORA_POINTS do -- le dernier point revient au départ
			local a = phase + dir * k * 2 * math.pi / AURORA_POINTS
			local point = path:CreateControlPoint()
			point:SetOffset(orbit * math.cos(a) - ox, orbit * math.sin(a) - oy)
			point:SetOrder(k)
		end
		s.groups[#s.groups + 1] = group
	end

	local mask = w:CreateMaskTexture()
	mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetSize(2 * LOGO - 1, 2 * LOGO - 1)
	mask:SetPoint("CENTER", logo)
	local glint = Light(s, w, logo, "OVERLAY", "MagieReflet", 2 * LOGO, { 1, 0.97, 0.88 }, 0, -2 * LOGO, 0)
	glint:AddMaskTexture(mask)
	Timeline(s, glint, { { 0, 0, 2 }, { 0, 0.32, 0.7, "IN_OUT" }, { 0.32, 0, 0.7, "IN_OUT" }, { 0, 0, 6.6 } },
		function(group, order, part, duration)
			if part == 2 or part == 3 then Translate(group, order, duration, 2 * LOGO, 0, part == 2 and "IN" or "OUT") end
		end)

	local every = 2.5
	for i, c in ipairs(colors) do
		local a = math.rad((i - 1) * 137.5)
		local spark = Light(s, w, logo, "OVERLAY", "MagieEtincelle", 7, c, 0, (LOGO + 1.5) * math.cos(a), (LOGO + 1.5) * math.sin(a))
		Timeline(s, spark, { { 0, 0, (i - 1) * every }, { 0, 0.9, 0.36, "OUT" }, { 0.9, 0, 1.44, "IN_OUT" },
			{ 0, 0, (n - i + 1) * every - 1.8 } },
			function(group, order, part, duration)
				if part == 2 then Translate(group, order, duration, 0, 2.5, "NONE") end
				if part == 3 then Translate(group, order, duration, 0, 4.5, "OUT") end
			end)
	end
	return s
end

----------------------------------------------------------------------------------------------------
-- Sceau : l'anneau et les gemmes ne bougent pas. Toutes les 6 s, une traînée de lumière part de la gemme allumée
-- vers la suivante (2 s), dans le sens des aiguilles d'une montre ; la gemme d'arrivée s'allume et le halo derrière
-- le logo prend sa couleur, en fondu enchaîné, pendant le trajet.
-- La traînée est une rangée de points fixes sur l'anneau qui s'allument l'un après l'autre (lents au départ et à
-- l'arrivée) et s'éteignent plus doucement : la lumière semble glisser, avec sa queue. Seulement de l'opacité :
-- une animation de rotation sur ce client tournait bien plus vite que demandé (vu en jeu le 21 novembre 2026,
-- plusieurs tours en 1 s au lieu d'un quart de tour ; l'ancien cercle de runes, réglé sur 5 minutes par tour,
-- tournait déjà trop vite).
----------------------------------------------------------------------------------------------------
local function Seal(w, logo, colors)
	local s, n = NewStyle(), #colors
	local fade, hold = 2, 4
	local step = fade + hold
	local halos, lights = {}, {}
	for i, c in ipairs(colors) do halos[i] = Light(s, w, logo, "BORDER", "MagieLueur", 46, c) end
	Crossfade(s, halos, 0.5, fade, hold)
	Light(s, w, logo, "BORDER", "MagieSceau", math.floor(SEAL / 0.47 + 0.5), UI.HEAL_GOLD, 0.45)
	for i, c in ipairs(colors) do
		local a = math.pi / 2 - (i - 1) * 2 * math.pi / n -- la première en haut, puis vers la droite
		local x, y = SEAL * math.cos(a), SEAL * math.sin(a)
		lights[i] = Light(s, w, logo, "BORDER", "MagieLueur", 13, c, 0, x, y)
		Light(s, w, logo, "OVERLAY", "MagieGemme", 7, c, 0.7, x, y, "BLEND")
		Light(s, w, logo, "OVERLAY", "MagieGemmeSerti", 7, UI.HEAL_GOLD, 0.85, x, y, "BLEND")
	end
	Crossfade(s, lights, 0.8, fade, hold)
	for c = 1, n do -- traînée c : de la gemme c - 1 (la dernière pour la première) à la gemme c, pendant le fondu
		local from = (c + n - 2) % n + 1
		local start = math.pi / 2 - (from - 1) * 2 * math.pi / n
		for j = 1, SEAL_DOTS do
			local p = j / (SEAL_DOTS + 1)
			local a = start - p * 2 * math.pi / n
			local dot = Light(s, w, logo, "BORDER", "MagieLueur", 7, Mix(colors[from], colors[c], p), 0,
				SEAL * math.cos(a), SEAL * math.sin(a))
			local at = (c - 1) * step + fade * (0.5 - 0.5 * math.cos(math.pi * p)) -- courbe douce, comme IN_OUT
			Timeline(s, dot, { { 0, 0, at }, { 0, 0.85, 0.12 }, { 0.85, 0, 0.6, "OUT" }, { 0, 0, n * step - at - 0.72 } })
		end
	end
	return s
end

----------------------------------------------------------------------------------------------------
-- Souffle : l'onde naît sous le médaillon (cachée), sort de son bord et s'efface en s'élargissant (3,2 s) ; une
-- lueur de fond très douce prend la même couleur.
----------------------------------------------------------------------------------------------------
local function Breath(w, logo, colors)
	local s, n = NewStyle(), #colors
	local step = 4
	local glows = {}
	for i, c in ipairs(colors) do glows[i] = Light(s, w, logo, "BORDER", "MagieLueur", 42, c) end
	Crossfade(s, glows, 0.32, 1.5, step - 1.5)
	for i, c in ipairs(colors) do
		local wave = Light(s, w, logo, "BORDER", "MagieOnde", 50, c)
		Timeline(s, wave, { { 0, 0, (i - 1) * step }, { 0.55, 0, 3.2, "IN_OUT" }, { 0, 0, (n - i + 1) * step - 3.2 } },
			function(group, order, part, duration)
				if part ~= 2 then return end
				local grow = group:CreateAnimation("Scale")
				grow:SetScaleFrom(0.5, 0.5)
				grow:SetScaleTo(1, 1)
				grow:SetDuration(duration)
				grow:SetSmoothing("OUT")
				grow:SetOrder(order)
			end)
	end
	return s
end

local BUILDERS = { AURORA = Aurora, SEAL = Seal, BREATH = Breath }

-- Animation du logo d'une fenêtre. Update(on) montre celle du réglage et la lance (toutes ses boucles ensemble,
-- pour garder les fondus enchaînés), cache et arrête les autres ; Stop() arrête tout.
function UI.LogoMagic(w, logo)
	local m = { styles = {} }

	function m.Stop()
		for _, s in pairs(m.styles) do
			for _, group in ipairs(s.groups) do group:Stop() end
		end
	end

	function m.Update(on)
		local key = on and Z.db.logoAnimation or nil
		if key and BUILDERS[key] and not m.styles[key] then m.styles[key] = BUILDERS[key](w, logo, HealerColors()) end
		for name, s in pairs(m.styles) do
			local shown = name == key
			for _, region in ipairs(s.regions) do region:SetShown(shown) end
			if not shown then
				for _, group in ipairs(s.groups) do group:Stop() end
			elseif s.groups[1] and not s.groups[1]:IsPlaying() then
				for _, group in ipairs(s.groups) do group:Stop() group:Play() end
			end
		end
	end

	return m
end
