-- Zenith (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Zenith - Themes.lua : les 5 habillages des cases, du plus moderne au plus « MMO ».
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
