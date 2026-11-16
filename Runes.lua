-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Runes.lua : l'inscription runique au bas de la fenêtre d'options. Facultative (réglage « showRunes »).
-- Les runes épellent la phrase gravée sur le socle de Deuillegivre, que Muradin déchiffre dans Warcraft III.
-- Une lueur les parcourt de gauche à droite ; au survol, elles s'illuminent et leur traduction s'affiche.
-- Les runes sont celles de l'ancien futhark, dessinées par outils/runes.py (Media/Runes.tga).
-- Tout est animé par le jeu lui-même : aucun calcul à chaque image.

local _, Z = ...
local ATLAS = "Interface\\AddOns\\Lyorune\\Media\\Runes"
local TEXT = "whomsoever takes up this blade shall wield power eternal"
local COLUMNS, ROWS = 8, 4       -- grille de Media/Runes.tga
local SIZE, STEP, SPACE = 12, 10, 7 -- taille d'une rune, avance par rune, largeur d'une espace
local WAVE, PAUSE = 0.05, 7      -- décalage de la lueur d'une rune à la suivante, repos entre deux passages

-- Position de chaque rune dans la grille (même ordre que dans outils/runes.py)
local letters = {
	f = 1, u = 2, th = 3, a = 4, r = 5, k = 6, g = 7, w = 8, h = 9, n = 10, i = 11, j = 12,
	p = 13, s = 14, t = 15, b = 16, e = 17, m = 18, l = 19, ng = 20, d = 21, o = 22, z = 23, y = 24,
	c = 6, q = 6, v = 2, x = 6,
}

local GOLD, DIM, LIGHT = { 0.93, 0.75, 0.35 }, 0.45, { 0.62, 0.84, 1 }
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

local function Cut(texture, index)
	local column, row = (index - 1) % COLUMNS, math.floor((index - 1) / COLUMNS)
	texture:SetTexture(ATLAS)
	texture:SetTexCoord(column / COLUMNS, (column + 1) / COLUMNS, row / ROWS, (row + 1) / ROWS)
	texture:SetSize(SIZE, SIZE)
end

local function Build(window)
	local L = Z.L
	local runes = Spell(TEXT)
	local width = 0
	for _, index in ipairs(runes) do width = width + (index and STEP or SPACE) end

	strip = CreateFrame("Frame", nil, window)
	strip:SetSize(width, SIZE + 4)
	strip:SetPoint("BOTTOM", 0, 3)
	strip:EnableMouse(true)
	strip.base, strip.waves, strip.falls = {}, {}, {}

	local x, count = 0, 0
	for _, index in ipairs(runes) do
		if index then
			count = count + 1
			-- La rune elle-même, dorée et discrète
			local base = strip:CreateTexture(nil, "ARTWORK")
			Cut(base, index)
			base:SetPoint("LEFT", x, 0)
			base:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], DIM)
			strip.base[count] = base

			-- Sa lueur bleutée, invisible au repos, allumée à son tour par l'animation
			local glow = strip:CreateTexture(nil, "OVERLAY")
			Cut(glow, index)
			glow:SetPoint("CENTER", base)
			glow:SetBlendMode("ADD")
			glow:SetVertexColor(LIGHT[1], LIGHT[2], LIGHT[3])
			glow:SetAlpha(0)
			local wave = glow:CreateAnimationGroup()
			wave:SetLooping("REPEAT")
			local rise = wave:CreateAnimation("Alpha")
			rise:SetOrder(1)
			rise:SetFromAlpha(0)
			rise:SetToAlpha(1)
			rise:SetDuration(0.35)
			rise:SetStartDelay(count * WAVE)
			rise:SetSmoothing("OUT")
			local fall = wave:CreateAnimation("Alpha")
			fall:SetOrder(2)
			fall:SetFromAlpha(1)
			fall:SetToAlpha(0)
			fall:SetDuration(1.1)
			fall:SetSmoothing("IN")
			strip.waves[count], strip.falls[count] = wave, fall
			x = x + STEP
		else
			x = x + SPACE
		end
	end
	-- Toutes les lueurs repartent ensemble : chaque boucle dure le même temps, repos compris
	for i, fall in ipairs(strip.falls) do fall:SetEndDelay((count - i) * WAVE + PAUSE) end

	strip:SetScript("OnShow", function(self)
		for _, wave in ipairs(self.waves) do wave:Play() end
	end)
	strip:SetScript("OnHide", function(self)
		for _, wave in ipairs(self.waves) do wave:Stop() end
	end)
	strip:SetScript("OnEnter", function(self)
		for _, base in ipairs(self.base) do base:SetVertexColor(1, 0.93, 0.7, 1) end
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Inscription runique"], GOLD[1], GOLD[2], GOLD[3])
		GameTooltip:AddLine(L["« Quiconque s'emparera de cette lame détiendra un pouvoir éternel. »"], 1, 1, 1, true)
		GameTooltip:AddLine(L["Runes du socle de Deuillegivre, déchiffrées par Muradin (Warcraft III)."], 0.6, 0.64, 0.7, true)
		GameTooltip:Show()
	end)
	strip:SetScript("OnLeave", function(self)
		for _, base in ipairs(self.base) do base:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], DIM) end
		GameTooltip:Hide()
	end)
end

-- Appelée à la création de la fenêtre d'options, puis à chaque changement de réglage
function Z:RefreshRunes(window)
	if window and Z.db.showRunes and not strip then Build(window) end
	if not strip then return end
	strip:SetShown(Z.db.showRunes)
end

-- Pour les tests
function Z:RuneStrip()
	return strip
end
