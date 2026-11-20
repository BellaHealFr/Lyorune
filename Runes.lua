-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Runes.lua : l'inscription runique au bas de la fenêtre d'options. Facultative (réglage « showRunes »).
-- Les runes épellent la phrase gravée sur le socle de Deuillegivre, que Muradin déchiffre dans Warcraft III.
-- À l'ouverture, elles s'écrivent une à une ; puis une lueur les parcourt de gauche à droite, et l'inscription
-- respire doucement. Au survol, une vague de lumière part du centre, puis la traduction s'affiche.
-- Les runes sont celles de l'ancien futhark, dessinées par outils/runes.py (Media/Runes.tga, Media/RunesHalo.tga).
-- Tout est animé par le jeu lui-même (groupes d'animation) : aucun calcul à chaque image.
-- Règles sûres : chaque texture n'est animée que par ses propres groupes (jamais d'animation visant une autre
-- texture), et un groupe ne fait jamais deux fondus dans le même temps.
-- « Animations réduites » : runes fixes, lueur au survol seulement.

local _, Z = ...
local UI = Z.UI
local TEXT = "whomsoever takes up this blade shall wield power eternal"
local SIZE, STEP, SPACE = 12, 10, 7 -- taille d'une rune, avance par rune, largeur d'une espace
local WRITE = 0.035                 -- écriture : décalage d'une rune à la suivante
local WAVE, PAUSE = 0.05, 7         -- lueur : décalage d'une rune à la suivante, repos entre deux passages
local RISE, FALL = 0.35, 1.1        -- lueur : montée, puis descente
local SPREAD = 0.15                 -- survol : la vague met 0,15 s du centre aux bords (+ 0,15 s d'allumage)
local DIM = 0.5                     -- éclat des runes au repos

-- Position de chaque rune dans la grille (même ordre que dans outils/runes.py)
local letters = {
	f = 1, u = 2, th = 3, a = 4, r = 5, k = 6, g = 7, w = 8, h = 9, n = 10, i = 11, j = 12,
	p = 13, s = 14, t = 15, b = 16, e = 17, m = 18, l = 19, ng = 20, d = 21, o = 22, z = 23, y = 24,
	c = 6, q = 6, v = 2, x = 6,
}

local strip

-- Découpe le texte en runes : « th » et « ng » n'en font qu'une, une espace vaut false
local function Spell(text)
	local runes, i = {}, 1
	while i <= #text do
		local pair = letters[text:sub(i, i + 1)]
		local index = pair or letters[text:sub(i, i)]
		if index then runes[#runes + 1] = index elseif text:sub(i, i) == " " then runes[#runes + 1] = false end
		i = i + (pair and 2 or 1)
	end
	return runes
end

-- Lueur en boucle d'une texture : montée (temps 1), descente (temps 2), puis repos pour rester alignée
local function Wave(region, peak, delay, rest, lift)
	local group = region:CreateAnimationGroup()
	group:SetLooping("REPEAT")
	UI.AlphaAnim(group, 0, peak, RISE, "OUT", 1, delay)
	local fall = UI.AlphaAnim(group, peak, 0, FALL, "IN_OUT", 2)
	if lift then -- monte d'un pixel pendant qu'elle brille, puis redescend
		local up = group:CreateAnimation("Translation")
		up:SetOffset(0, lift)
		up:SetDuration(RISE)
		up:SetStartDelay(delay)
		up:SetOrder(1)
		local down = group:CreateAnimation("Translation")
		down:SetOffset(0, -lift)
		down:SetDuration(FALL)
		down:SetOrder(2)
	end
	fall:SetEndDelay(rest)
	return group
end

-- Allumage au survol (reste allumé jusqu'au départ de la souris)
local function Light(region, peak, delay)
	local group = region:CreateAnimationGroup()
	group:SetToFinalAlpha(true)
	UI.AlphaAnim(group, 0, peak, 0.15, "OUT", 1, delay)
	return group
end

-- Couleurs du thème de fenêtre : bleu givre (Moderne), or doux (Classique), braise (MMORPG)
local function Paint()
	local skin = UI.skin
	local base, glow = skin.runeBase, skin.runeGlow
	for i, rune in ipairs(strip.base) do
		rune:SetVertexColor(base[1], base[2], base[3], strip.lit and 1 or DIM)
		strip.glows[i]:SetVertexColor(glow[1], glow[2], glow[3])
		strip.halos[i]:SetVertexColor(glow[1], glow[2], glow[3])
	end
	for _, spark in ipairs(strip.sparks) do
		spark:SetVertexColor(glow[1], glow[2] * 0.9, glow[3])
		spark:SetShown(skin.sparks and true or false)
	end
end

local function PlayAll(list, play)
	for _, group in ipairs(list) do
		if play then group:Play() else group:Stop() end
	end
end

-- Repos : aussi à la fermeture de la fenêtre, la souris encore sur les runes (le jeu peut ne pas envoyer OnLeave à un
-- cadre caché) : l'éclat du survol et l'infobulle partent avec elle
local function Quiet(self)
	PlayAll(self.writes, false)
	PlayAll(self.waves, false)
	PlayAll(self.hovers, false)
	self.breath:Stop()
	for i, rune in ipairs(self.base) do
		rune:SetAlpha(1)
		self.glows[i]:SetAlpha(0)
		self.halos[i]:SetAlpha(0)
	end
	if self.lit then
		self.lit = false
		Paint()
	end
	if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end

-- Joue les animations à l'ouverture de la fenêtre (ou seulement fixe les runes en animations réduites)
local function Start(self)
	Quiet(self)
	if UI.Calm() then return end
	for _, rune in ipairs(self.base) do rune:SetAlpha(0) end
	PlayAll(self.writes, true)
	PlayAll(self.waves, true)
	self.breath:Play()
end

-- Traduction dans l'infobulle du jeu (affichée normalement : Lyorune ne modifie jamais les cadres du jeu)
local function Tooltip(self)
	local L = Z.L
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:AddLine(L["Inscription runique"], UI.gold[1], UI.gold[2], UI.gold[3])
	GameTooltip:AddLine(L["« Quiconque s'emparera de cette lame détiendra un pouvoir éternel. »"], 1, 1, 1, true)
	GameTooltip:AddLine(L["Runes du socle de Deuillegivre, déchiffrées par Muradin (Warcraft III)."], 0.6, 0.64, 0.7, true)
	GameTooltip:Show()
end

local function Build(window)
	local runes = Spell(TEXT)
	local positions, x = {}, 0
	for _, index in ipairs(runes) do
		if index then positions[#positions + 1] = x end
		x = x + (index and STEP or SPACE)
	end
	local count, center = #positions, (#positions + 1) / 2

	strip = CreateFrame("Frame", nil, window)
	strip:SetSize(x, SIZE + 4)
	strip:SetPoint("BOTTOM", 0, 9) -- au milieu de la bande du bas de la fenêtre d'options, sous son trait
	strip:EnableMouse(true)
	strip.base, strip.glows, strip.halos, strip.sparks = {}, {}, {}, {}
	strip.writes, strip.waves, strip.hovers = {}, {}, {}
	strip.breath = UI.Breathe(strip, 0.8, 5) -- respiration presque invisible

	local i = 0
	for _, index in ipairs(runes) do
		if index then
			i = i + 1
			local left = positions[i]
			-- Le halo flou, la rune, puis sa lueur : chacune placée sur l'inscription elle-même
			local halo = UI.CutRune(strip:CreateTexture(nil, "BACKGROUND"), index, SIZE * 2, UI.HALOS)
			halo:SetPoint("CENTER", strip, "LEFT", left + SIZE / 2, 0)
			halo:SetBlendMode("ADD")
			halo:SetAlpha(0)
			local base = UI.CutRune(strip:CreateTexture(nil, "ARTWORK"), index, SIZE)
			base:SetPoint("CENTER", strip, "LEFT", left + SIZE / 2, 0)
			local glow = UI.CutRune(strip:CreateTexture(nil, "OVERLAY"), index, SIZE)
			glow:SetPoint("CENTER", strip, "LEFT", left + SIZE / 2, 0)
			glow:SetBlendMode("ADD")
			glow:SetAlpha(0)
			strip.base[i], strip.glows[i], strip.halos[i] = base, glow, halo

			-- 1. Écriture à l'ouverture : chaque rune apparaît comme gravée
			local write = base:CreateAnimationGroup()
			write:SetToFinalAlpha(true)
			UI.AlphaAnim(write, 0, 1, 0.25, "OUT", 1, (i - 1) * WRITE)
			local grow = write:CreateAnimation("Scale")
			if grow.SetScaleFrom then
				grow:SetScaleFrom(0.6, 0.6)
				grow:SetScaleTo(1, 1)
			end
			grow:SetDuration(0.25)
			grow:SetStartDelay((i - 1) * WRITE)
			grow:SetSmoothing("OUT")
			strip.writes[i] = write

			-- 2. La lueur parcourt la phrase (toutes les boucles durent le même temps, repos compris)
			local rest = (count - i) * WAVE + PAUSE
			strip.waves[#strip.waves + 1] = Wave(glow, 1, i * WAVE, rest, 1)
			strip.waves[#strip.waves + 1] = Wave(halo, 0.7, i * WAVE, rest)

			-- 4. Survol : toutes les runes s'allument, du centre vers les bords
			local spread = math.abs(i - center) / center * SPREAD
			strip.hovers[#strip.hovers + 1] = Light(glow, 1, spread)
			strip.hovers[#strip.hovers + 1] = Light(halo, 0.8, spread)
		end
	end

	-- 5. Thème MMORPG : trois étincelles montent pendant le passage de la lueur
	for n, at in ipairs({ math.floor(count * 0.2), math.floor(count * 0.55), math.floor(count * 0.85) }) do
		local spark = strip:CreateTexture(nil, "OVERLAY")
		spark:SetTexture(UI.WHITE)
		spark:SetSize(2, 2)
		spark:SetBlendMode("ADD")
		spark:SetPoint("CENTER", strip, "LEFT", positions[at] + SIZE / 2 + (n - 2), SIZE / 2)
		spark:SetAlpha(0)
		strip.waves[#strip.waves + 1] = Wave(spark, 1, at * WAVE, (count - at) * WAVE + PAUSE, 9)
		strip.sparks[n] = spark
	end

	strip:SetScript("OnShow", Start)
	strip:SetScript("OnHide", Quiet)
	strip:SetScript("OnEnter", function(self)
		PlayAll(self.waves, false)
		self.lit = true
		Paint()
		if UI.Calm() then
			for n, glow in ipairs(self.glows) do glow:SetAlpha(1) self.halos[n]:SetAlpha(0.8) end
			Tooltip(self)
		else
			PlayAll(self.hovers, true)
			-- La traduction apparaît une fois la vague passée
			C_Timer.After(SPREAD + 0.15, function()
				if self.lit and self:IsVisible() and self:IsMouseOver() then Tooltip(self) end
			end)
		end
	end)
	strip:SetScript("OnLeave", function(self)
		PlayAll(self.hovers, false)
		for n, glow in ipairs(self.glows) do glow:SetAlpha(0) self.halos[n]:SetAlpha(0) end
		self.lit = false
		Paint()
		GameTooltip:Hide()
		if not UI.Calm() then PlayAll(self.waves, true) end
	end)
	UI.OnSkin(Paint)
	Paint()
end

-- Appelée à la création de la fenêtre d'options, puis à chaque changement de réglage (sans la fenêtre : on la prend
-- ici, pour construire l'inscription rallumée après avoir été coupée à la première ouverture)
function Z:RefreshRunes(window)
	window = window or Z.OptionsWindow and Z:OptionsWindow()
	if window and Z.db.showRunes and not strip then Build(window) end
	-- Logo de l'en-tête et inscription suivent « Animations réduites » sans attendre la prochaine ouverture
	local options = Z.OptionsWindow and Z:OptionsWindow()
	if options and options.breath then
		if UI.Calm() then options.breath:Stop() elseif options:IsShown() then options.breath:Play() end
	end
	if options and options.magic then options.magic.Update() end
	if not strip then return end
	local wasCalm = strip.calm
	strip.calm = UI.Calm() and true or false
	strip:SetShown(Z.db.showRunes)
	if strip:IsVisible() and wasCalm ~= nil and wasCalm ~= strip.calm then Start(strip) end
end

-- Pour les tests
function Z:RuneStrip()
	return strip
end

function Z:SpellRunes(text)
	return Spell(text or TEXT)
end
