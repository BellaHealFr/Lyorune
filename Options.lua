-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Options.lua : la fenêtre /lyorune.
-- Neuf onglets, un sujet par onglet, chaque réglage à un seul endroit :
--   Cadres       où et comment les cases sont rangées
--   Apparence    à quoi elles ressemblent
--   Indicateurs  ce qui s'affiche dessus
--   Soins        mes soins sur la durée (icônes, décompte, fondu) et les coins de la case
--   Listes       mes sorts à suivre, les affaiblissements à ignorer ou à mettre en avant
--   Clics        souris, touches au survol
--   Alertes      annonces dans le chat et sons
--   Profils      profils prêts à l'emploi, partage, réinitialisation
--   Aide         tutoriel, légende, journal, langue
-- Les onglets simples sont décrits par une liste (table TABS) : ajouter un réglage = ajouter une ligne.
-- La recherche (en haut à droite) retrouve un réglage par son nom.

local _, Z = ...
local UI = Z.UI
local L = Z.L

local WIDTH, HEIGHT = 700, 650
local COLUMN = 310          -- largeur d'une colonne de réglages
local window, picker
local tabs
local searchIndex = {}      -- { texte en minuscules, numéro d'onglet, élément, libellé }

----------------------------------------------------------------------------------------------------
-- Lecture et écriture d'un réglage. Après chaque changement, les cadres sont rafraîchis.
----------------------------------------------------------------------------------------------------
local CLICK_OPTIONS = { castOnDown = true, autoRes = true, externalClicks = true, actionBarMacros = true, clicksPerSpec = true }

local function Option(key)
	return function() return Z.db[key] end, function(value)
		Z.db[key] = value
		Z:Refresh()
		Z:RefreshAlerts()
		if CLICK_OPTIONS[key] then Z:ApplyClicks() end
	end
end

local function Register(tabIndex, label, widget)
	searchIndex[#searchIndex + 1] = { label:lower(), tabIndex, widget, label }
end

local function Heading(parent, text)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(COLUMN, 24)
	local label = UI.Heading(f, 13)
	label:SetPoint("BOTTOMLEFT", 0, 6)
	label:SetText(L[text])
	local divider = UI.Divider(f) -- trait fin coupé par une rune
	divider:SetPoint("BOTTOMLEFT", 0, -4)
	divider:SetPoint("BOTTOMRIGHT", 0, -4)
	return f
end

local function Note(parent, text, x, y, width)
	local note = UI.Text(parent, 11)
	note:SetPoint("TOPLEFT", x, y)
	note:SetWidth(width or (WIDTH - 48))
	note:SetJustifyH("LEFT")
	note:SetSpacing(3)
	UI.Paint(note, "dim")
	note:SetText(L[text])
	return note
end

local function Tip(widget, text)
	if not text then return end
	local target = widget.button or widget
	target.tip = L[text]
	if target ~= widget.button and not target:GetScript("OnEnter") then
		target:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(self.tip, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		target:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
end

----------------------------------------------------------------------------------------------------
-- Construction d'un onglet à partir de sa description
--   { "head", "Titre" }                       titre de section
--   { "check", cle, "Libellé", "aide" }       case à cocher
--   { "step", cle, "Libellé" }                nombre (limites dans Z.limits)
--   { "cycle", cle, "Libellé", choix }        choix (liste dans Z.choices, ou fournie)
--   { "button", "Libellé", fonction, "aide" } bouton
--   { "note", "Texte", hauteur }              explication
--   { "custom", fonction }                    élément dessiné à part : fonction(page) renvoie le cadre
----------------------------------------------------------------------------------------------------
local function BuildItem(page, item)
	local kind, widget = item[1], nil
	if kind == "head" then
		widget = Heading(page, item[2])
	elseif kind == "check" then
		widget = UI.Check(page, L[item[3]], Option(item[2]))
		Tip(widget, item[4])
		Register(page.tabIndex, L[item[3]], widget)
	elseif kind == "step" then
		local limit = Z.limits[item[2]]
		widget = UI.Stepper(page, L[item[3]], limit[1], limit[2], limit[3], Option(item[2]))
		Register(page.tabIndex, L[item[3]], widget)
	elseif kind == "cycle" then
		local choices = {}
		for _, choice in ipairs(item[4] or Z.choices[item[2]]) do choices[#choices + 1] = { choice[1], L[choice[2]] } end
		widget = UI.Cycle(page, L[item[3]], choices, Option(item[2]))
		Tip(widget, item[5])
		Register(page.tabIndex, L[item[3]], widget)
	elseif kind == "button" then
		widget = UI.Button(page, L[item[2]], 200, 24, item[3])
		widget.label:SetJustifyH("CENTER")
		widget.tip = item[4] and L[item[4]]
		Register(page.tabIndex, L[item[2]], widget)
	elseif kind == "note" then
		widget = CreateFrame("Frame", nil, page)
		widget:SetSize(COLUMN, item[3] or 30)
		Note(widget, item[2], 0, 0, COLUMN)
	elseif kind == "custom" then
		widget = item[2](page)
	end
	if widget.SetWidth and kind ~= "button" then widget:SetWidth(COLUMN) end
	return widget
end

local function BuildColumns(page, columns)
	for index, column in ipairs(columns) do
		local x, y = (index - 1) * (COLUMN + 32), 0
		for _, item in ipairs(column) do
			-- Un réglage qui échoue est noté au journal et ne cache pas les suivants
			Z:Try("option " .. tostring(item[2]), function()
				local widget = BuildItem(page, item)
				widget:SetPoint("TOPLEFT", page, "TOPLEFT", x, y)
				y = y - widget:GetHeight() - 7
			end)
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Onglets décrits par une liste
----------------------------------------------------------------------------------------------------
local function ThemeChoices()
	local list = {}
	for _, theme in ipairs(Z.themes) do list[#list + 1] = { theme.id, theme.name } end
	return list
end

local function TextureChoices()
	local list = { { "THEME", "Celle du thème" } }
	for _, name in ipairs(UI.TextureList()) do list[#list + 1] = { name, name } end
	return list
end

local function PreviewButton(count)
	return { "button", count .. " " .. L["joueurs"], function() Z:TogglePreview(count) end }
end

-- Les valeurs affichées suivent un changement fait par un bouton
local function RefreshShownPages()
	for _, tab in ipairs(tabs) do
		if tab.page and tab.page:IsShown() then tab.page:Hide() tab.page:Show() end
	end
end

-- Préréglage de transparence : opacité des cadres et opacité hors de portée
local function OpacityButton(label, frameAlpha, rangeAlpha)
	return { "button", label, function()
		Z.db.frameAlpha, Z.db.rangeAlpha = frameAlpha, rangeAlpha
		Z:Refresh()
		RefreshShownPages()
	end }
end

----------------------------------------------------------------------------------------------------
-- Forme des cases : une vignette par forme, dessinée en direct avec le thème, les angles et les couleurs
-- choisis. Un clic choisit la forme ; « Revenir » rétablit l'état d'avant ; « Voir en vrai » lance le mode test.
----------------------------------------------------------------------------------------------------
local THUMB_W, THUMB_H = 150, 62
local thumbs = {}

-- Une fausse case à la taille réelle de la forme, réduite pour tenir dans la vignette
local function DrawThumb(thumb)
	local shape, db, theme = Z.shapes[thumb.id], Z.db, Z:Theme()
	local rounded = db.corners == "ROUND"
	local inset = UI.Inset(theme.borderSize, rounded)
	local cell = thumb.cell
	cell:SetSize(shape.width, shape.height)
	cell:SetScale(math.min(1, (THUMB_W - 20) / shape.width, (THUMB_H - 22) / shape.height))
	cell.bg:SetVertexColor(unpack(theme.bg))
	cell.bgRound:SetVertexColor(unpack(theme.bg))
	cell.bg:SetShown(not rounded)
	cell.bgRound:SetShown(rounded)
	cell.border:SetThickness(theme.borderSize)
	cell.border:SetColor(theme.border[1], theme.border[2], theme.border[3], 1)
	cell.border:SetRounded(rounded)

	local mana = db.manaBars ~= "OFF"
	cell.hp:ClearAllPoints()
	cell.hp:SetPoint("TOPLEFT", inset, -inset)
	cell.hp:SetPoint("BOTTOMRIGHT", -inset, inset + (mana and shape.powerHeight + 1 or 0))
	cell.hp:SetStatusBarTexture(UI.BarTexture())
	cell.hp:SetStatusBarColor(Z.ClassColor(Z.class))
	cell.power:SetStatusBarTexture(UI.BarTexture())
	cell.power:SetStatusBarColor(unpack(Z.manaColors[db.manaColor] or Z.manaColors.BLUE))
	cell.power:SetHeight(shape.powerHeight)
	cell.power:SetShown(mana)

	local size = shape.fontSize + (theme.fontBonus or 0)
	cell.name:SetFont(theme.font, size, theme.flags)
	cell.text:SetFont(theme.font, size - 1, theme.flags)
	cell.name:ClearAllPoints()
	cell.text:ClearAllPoints()
	if shape.inline then
		cell.name:SetPoint("LEFT", cell.hp, "LEFT", 4, 0)
		cell.text:SetPoint("RIGHT", cell.hp, "RIGHT", -4, 0)
	else
		cell.name:SetPoint("CENTER", cell.hp, "CENTER", 0, 3)
		cell.text:SetPoint("BOTTOM", cell.hp, "BOTTOM", 0, 4)
	end
	cell.name:SetWidth(shape.inline and shape.width - 46 or shape.width - 8)
	cell.name:SetJustifyH(shape.inline and "LEFT" or "CENTER")
	cell.text:SetShown(db.text ~= "NONE")

	local chosen = db.shape == thumb.id
	thumb.chosen = chosen
	thumb.border:SetColor(unpack(chosen and UI.accent or UI.line))
	thumb.label:SetTextColor(unpack(chosen and UI.accent or UI.dim))
end

local function BuildThumb(parent, id, label, onClick)
	local thumb = CreateFrame("Button", nil, parent)
	thumb:SetSize(THUMB_W, THUMB_H)
	thumb.id = id
	thumb.bg = UI.Paint(UI.Tex(thumb, "BACKGROUND"), "panel")
	thumb.bg:SetAllPoints()
	thumb.border = UI.Border(thumb, 1)
	thumb.label = UI.Text(thumb, 11)
	thumb.label:SetPoint("BOTTOMLEFT", 6, 4)
	thumb.label:SetText(L[label])

	local cell = CreateFrame("Frame", nil, thumb)
	cell:SetPoint("CENTER", 0, 6)
	cell.bg = UI.Tex(cell, "BACKGROUND")
	cell.bg:SetAllPoints()
	cell.bgRound = UI.RoundTex(cell, "BACKGROUND")
	cell.bgRound:SetAllPoints()
	cell.hp = CreateFrame("StatusBar", nil, cell)
	cell.hp:SetStatusBarTexture(UI.WHITE)
	cell.hp:SetMinMaxValues(0, 100)
	cell.hp:SetValue(72)
	cell.power = CreateFrame("StatusBar", nil, cell)
	cell.power:SetStatusBarTexture(UI.WHITE)
	cell.power:SetPoint("TOPLEFT", cell.hp, "BOTTOMLEFT", 0, -1)
	cell.power:SetPoint("TOPRIGHT", cell.hp, "BOTTOMRIGHT", 0, -1)
	cell.power:SetMinMaxValues(0, 100)
	cell.power:SetValue(60)
	local over = CreateFrame("Frame", nil, cell)
	over:SetAllPoints()
	over:SetFrameLevel(cell.hp:GetFrameLevel() + 3)
	cell.border = UI.Border(over, 1)
	cell.name = UI.Text(over, 11)
	cell.name:SetWordWrap(false)
	cell.name:SetText(UnitName("player") or L["Joueur"])
	cell.text = UI.Text(over, 10)
	cell.text:SetText("-2,4K")
	thumb.cell = cell

	thumb:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
		Z:ApplyShape(self.id)
		if onClick then onClick(self) else RefreshShownPages() end
	end)
	thumb:SetScript("OnEnter", function(self)
		local shape = Z.shapes[self.id]
		self.border:SetColor(unpack(UI.accent))
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L[label], UI.accent[1], UI.accent[2], UI.accent[3])
		GameTooltip:AddLine(L["Cases de %d x %d, texte %d."]:format(shape.width, shape.height, shape.fontSize), 1, 1, 1)
		GameTooltip:AddLine(L["Chaque valeur se retouche ensuite dans l'onglet Cadres."], 0.6, 0.64, 0.7, true)
		GameTooltip:Show()
	end)
	thumb:SetScript("OnLeave", function(self)
		self.border:SetColor(unpack(self.chosen and UI.accent or UI.line))
		GameTooltip:Hide()
	end)
	return thumb
end

local function ShapePicker(page)
	local picker = CreateFrame("Frame", nil, page)
	picker:SetSize(COLUMN, 2 * THUMB_H + 6 + 30)
	for index, choice in ipairs(Z.choices.shape) do
		local thumb = BuildThumb(picker, choice[1], choice[2])
		thumb:SetPoint("TOPLEFT", ((index - 1) % 2) * (THUMB_W + 10), -math.floor((index - 1) / 2) * (THUMB_H + 6))
		thumbs[#thumbs + 1] = thumb
	end
	local undo = UI.Button(picker, L["Revenir"], THUMB_W, 24, function()
		Z:UndoShape()
		RefreshShownPages()
	end)
	undo:SetPoint("BOTTOMLEFT")
	undo.label:SetJustifyH("CENTER")
	undo.tip = L["Rétablit la forme et les tailles d'avant le dernier choix."]
	local real = UI.Button(picker, L["Voir en vrai"], THUMB_W, 24, function()
		Z:TogglePreview(not Z.previewActive and 10 or nil)
	end)
	real:SetPoint("BOTTOMLEFT", THUMB_W + 10, 0)
	real.label:SetJustifyH("CENTER")
	real.tip = L["Affiche un faux groupe de 10 joueurs avec la forme choisie. Recliquez pour le fermer."]
	picker.Update = function()
		for _, thumb in ipairs(thumbs) do DrawThumb(thumb) end
		undo:SetAlpha(Z.shapeUndo and 1 or 0.4)
		undo:EnableMouse(Z.shapeUndo ~= nil)
	end
	picker:SetScript("OnShow", picker.Update)
	picker.thumbs, picker.undo, picker.real = thumbs, undo, real
	Z.shapePicker = picker
	picker:Update()
	Register(page.tabIndex, L["Forme des cases"], picker)
	return picker
end

-- Vignette de forme pour une autre fenêtre (assistant du premier lancement) : thumb:Draw() la redessine,
-- onClick(thumb) suit le choix de la forme
function Z.ShapeThumb(parent, id, label, onClick)
	local thumb = BuildThumb(parent, id, label, onClick)
	thumb.Draw = DrawThumb
	return thumb
end

-- Appelé après chaque changement d'option : les vignettes suivent le thème, les angles et les couleurs
function Z:RefreshShapes()
	if Z.shapePicker and Z.shapePicker:IsVisible() then Z.shapePicker:Update() end
end

-- Choix d'un coin : « Aucun », puis mes sorts suivis (ceux de ma classe et ma liste), par ordre alphabétique.
-- Le réglage est gardé par classe : un prêtre et un druide ont chacun leurs coins.
local function CornerPicker(point, label)
	return { "custom", function(page)
		local names = {}
		for name in pairs(Z.trackedNames or {}) do names[#names + 1] = name end
		for name in pairs(Z.db.extraTracked) do
			if not (Z.trackedNames and Z.trackedNames[name]) then names[#names + 1] = name end
		end
		table.sort(names)
		local choices = { { "", L["Aucun"] } }
		for _, name in ipairs(names) do choices[#choices + 1] = { name, name } end
		local widget = UI.Cycle(page, L[label], choices,
			function() return Z.MyCorners()[point] or "" end,
			function(value)
				local all = Z.db.cornerSpells
				all[Z.class] = all[Z.class] or {}
				all[Z.class][point] = value ~= "" and value or nil
				Z:Refresh()
			end)
		local color = Z.CORNER_COLORS[point]
		widget.label:SetTextColor(color[1], color[2], color[3])
		Register(page.tabIndex, L[label], widget)
		return widget
	end }
end

local function SimpleTabs()
	return {
		Cadres = {
			{
				{ "head", "Taille des cases" },
				{ "step", "width", "Largeur" },
				{ "step", "height", "Hauteur" },
				{ "step", "spacing", "Espacement" },
				{ "step", "scale", "Échelle générale (%)" },
				{ "button", "Placer les éléments de la case...", function() Z:OpenPlacement() end, "Nom, texte de vie, icônes : décalez chaque élément au pixel près sur une case d'exemple agrandie." },
				{ "check", "autoShrink", "Réduire les cases en grand raid", "Au-delà de 10 joueurs les cases rétrécissent de 15 %, au-delà de 25 de 30 %." },
				{ "head", "Rangement" },
				{ "cycle", "layout", "Rangement des joueurs", nil, "Par groupe : un bloc par groupe de raid. Par rôle : un bloc par rôle. Grille : tout le raid d'un seul tenant, sans trou entre les groupes." },
				{ "cycle", "sortOrder", "Ordre dans chaque bloc", nil, "Le jeu tient l'ordre à jour tout seul, même en combat. En rangement par rôle, « par classe » range par nom." },
				{ "cycle", "roleOrder", "Ordre des rôles", nil, "Utilisé quand le rangement est « Par rôle »." },
				{ "check", "keepGroupPlace", "Chaque groupe garde sa place", "Rangement par groupe : le groupe 3 reste en 3e colonne même si le groupe 2 est vide. Décoché, les groupes se resserrent." },
				{ "step", "gridSize", "Cases par colonne en grille" },
				{ "cycle", "horizontal", "Sens des groupes" },
				{ "head", "Position" },
				{ "cycle", "lockMode", "Déplacement des cadres", nil, "Libre : glisser une étiquette « Groupe ». Verrouillé : rien ne bouge. Avec Alt, Ctrl ou Maj : maintenir la touche puis glisser. Jamais en combat." },
				{ "check", "showGroupLabels", "Numéro de groupe au-dessus des cases", "« Groupe 1 » à « Groupe 8 » en raid, ou le rôle en rangement par rôle. Décoché, l'étiquette ne revient que pour déplacer les cadres." },
				{ "button", "Remettre les cadres au centre", function() SlashCmdList.LYORUNE("reset") end },
			},
			{
				{ "head", "Cadres affichés" },
				{ "cycle", "visibility", "Afficher les cadres", nil, "En permanence (pratique pour se soigner en quête, en combat comme hors combat), ou seulement pendant les combats : les cadres apparaissent alors tout seuls au début du combat." },
				{ "check", "showSolo", "Mon cadre quand je suis seul" },
				{ "check", "showTanks", "Cadre séparé pour les tanks", "Un second cadre, déplaçable, qui ne montre que les tanks." },
				{ "check", "showPets", "Cadre séparé pour les familiers" },
				{ "check", "showTarget", "Case de ma cible", "Dans un petit cadre « Cible », déplaçable : mêmes clics et même apparence que les autres cases. Un ennemi est en rouge, sans icônes." },
				{ "check", "showTargetTarget", "Case de la cible de ma cible", "Par exemple le joueur que le boss frappe. Revue deux fois par seconde : le jeu ne prévient pas quand elle change." },
				{ "check", "showFocus", "Case de ma focalisation" },
				{ "check", "hideBlizzard", "Masquer les cadres de groupe du jeu", "Expérimental. Pour les faire revenir, décochez puis tapez /reload." },
				{ "head", "Mode test" },
				{ "note", "Affiche un faux groupe pour régler l'apparence. Recliquez pour le fermer.", 30 },
				PreviewButton(5), PreviewButton(10), PreviewButton(25), PreviewButton(40),
			},
		},
		Apparence = {
			{
				{ "head", "Forme des cases" },
				{ "custom", ShapePicker },
				{ "cycle", "corners", "Angles des cases", nil, "Droits ou arrondis, pour toutes les formes et tous les thèmes." },
				{ "check", "groupPanel", "Fond et bordure par groupe", "Chaque groupe (ou chaque rôle) est posé sur un fond aux couleurs du thème." },
				{ "head", "Style" },
				{ "cycle", "theme", "Thème", ThemeChoices() },
				{ "cycle", "texture", "Texture des barres", TextureChoices() },
				{ "check", "highContrast", "Contraste élevé", "Fond noir, bordure blanche, texte plus gros : pour une lecture facile. S'applique aussi aux fenêtres de Lyorune." },
				{ "check", "smooth", "Barres animées" },
				{ "head", "Texte" },
				{ "cycle", "text", "Texte de vie" },
				{ "step", "fontSize", "Taille du texte" },
			},
			{
				{ "head", "Couleurs et transparence" },
				{ "cycle", "color", "Couleur des barres" },
				{ "cycle", "classIntensity", "Couleurs de classe", nil, "Naturelles : celles du jeu. Vives : plus franches et plus lumineuses, chaque classe garde sa teinte." },
				{ "step", "brightness", "Luminosité des barres (%)" },
				{ "step", "frameAlpha", "Opacité des cadres (%)" },
				{ "step", "rangeAlpha", "Opacité hors de portée (%)" },
				{ "head", "Préréglages de transparence" },
				{ "note", "Un rendu en un clic, à ajuster ensuite avec les trois réglages ci-dessus.", 30 },
				OpacityButton("Discret", 55, 25),
				OpacityButton("Semi-transparent", 80, 35),
				OpacityButton("Bien visible", 100, 45),
				{ "head", "Fenêtres de Lyorune" },
				{ "cycle", "windowTheme", "Thème des fenêtres", nil, "Options, visite guidée et petites fenêtres (pas les cases). Moderne : net, bleu givre et or. Classique : comme les fenêtres du jeu. MMORPG : pierre sombre, cadre doré et runes gravées." },
				{ "check", "reduceMotion", "Animations réduites", "Seulement des fondus courts : runes fixes, logo immobile, rien ne bouge en boucle. La lueur au survol reste." },
				{ "check", "magicEffects", "Effets magiques", "Cercle runique qui tourne derrière le logo, particules de lumière dans l'en-tête, étincelle quand un réglage change. Couleur du thème, jamais sur les cases de soin. Coupés par « Animations réduites »." },
			},
		},
		Indicateurs = {
			{
				{ "head", "Vie et mana" },
				{ "check", "showIncoming", "Soins en route" },
				{ "check", "showAbsorb", "Bouclier d'absorption" },
				{ "check", "showHealAbsorb", "Absorption de soins", "Bande rouge sombre au bout de la vie : la part qu'un affaiblissement « mange » avant que vos soins comptent. Calculée par le jeu, visible en combat." },
				{ "check", "lowHealth", "Voile rouge clignotant quand la vie est basse" },
				{ "step", "lowHealthAt", "Seuil de vie basse (%)" },
				{ "cycle", "manaBars", "Barre de mana" },
				{ "step", "powerHeight", "Hauteur de la barre de mana" },
				{ "cycle", "manaColor", "Couleur de la barre de mana" },
				{ "check", "manaPercent", "Pourcentage de mana dans la barre", "Le % de mana écrit au milieu de la barre, lisible en combat. La barre passe alors à 8 pixels de haut au moins." },
				{ "head", "Joueur" },
				{ "check", "showRole", "Icône de rôle (tank, soigneur)" },
				{ "check", "showMarker", "Marqueur de raid" },
				{ "check", "showThreat", "Bordure rouge quand il est attaqué" },
				{ "check", "threatBar", "Barre fine de menace", "Trait de couleur en haut de la vie : jaune quand il monte dans la liste d'un monstre, orange juste avant qu'il le prenne, rouge quand il l'a." },
				{ "check", "showSummonPhase", "Invocation en cours, autre phase", "Icône au centre de la case : invocation proposée, acceptée ou refusée, ou joueur dans une autre phase (proche en apparence, mais hors d'atteinte)." },
				{ "check", "showTooltip", "Infobulle au survol (hors combat)" },
				{ "check", "clickTooltip", "Mes clics dans l'infobulle", "Au survol d'une case, hors combat : chaque clic et chaque touche avec son sort ou sa macro." },
			},
			{
				{ "head", "Affaiblissements" },
				{ "check", "showDispel", "Cadre coloré quand je peux dissiper" },
				{ "check", "showDebuffs", "Icônes des affaiblissements" },
				{ "cycle", "debuffMode", "Affaiblissements affichés" },
				{ "check", "bossDebuffs", "Affaiblissement important en grand", "Ceux des boss, et ceux de votre liste (onglet Listes)." },
				{ "check", "importantGlow", "Contour lumineux si important", "La case s'entoure d'un contour doré qui pulse. Marche en combat pour les affaiblissements de boss : le jeu décide lui-même." },
				{ "check", "importantSound", "Son pour ceux de ma liste", "Un son d'alerte quand un affaiblissement de la liste « À mettre en avant » est posé. En combat, le jeu cache souvent le nom des affaiblissements de boss : le son ne peut alors pas partir." },
				{ "head", "Auras privées des boss" },
				{ "check", "privateAuras", "Afficher les auras privées", "Certains affaiblissements de boss sont cachés aux addons : le jeu les dessine lui-même sur la case, à la place choisie ici (deux au plus)." },
				{ "step", "privateAuraSize", "Taille des auras privées" },
				{ "cycle", "privateAuraPoint", "Place des auras privées" },
			},
		},
		Soins = {
			{
				{ "head", "Mes soins sur la durée" },
				{ "check", "showHots", "Mes soins sur la durée" },
				{ "cycle", "hotStyle", "Affichage des soins sur la durée" },
				{ "note", "Sur les icônes, à combiner comme vous voulez :", 22 },
				{ "check", "hotSwipe", "Cercle qui se vide", "Sur les icônes de vos soins : un voile tourne et découvre l'icône à mesure que le temps passe." },
				{ "check", "hotCountdown", "Décompte en secondes", "Sur les icônes de vos soins : les secondes restantes, écrites par le jeu (visibles en combat)." },
				{ "check", "hotFade", "Icône qui s'efface à la fin", "Pendant les 6 dernières secondes, l'icône pâlit peu à peu : c'est le moment de relancer." },
				{ "check", "hotCharges", "Nombre de charges", "Petit chiffre en bas de l'icône quand votre soin a plusieurs charges." },
				{ "head", "Buffs" },
				{ "check", "missingBuffs", "Buff de groupe manquant (hors combat)", "Icône grise en bas à gauche quand un joueur n'a pas votre buff de groupe." },
				{ "check", "buffPanel", "Panneau des buffs manquants", "Hors combat, une petite fenêtre liste les joueurs sans votre buff de groupe : un clic le leur lance. Un groupe entier sans buff : une seule ligne pour la version de groupe. Elle se cache en combat." },
			},
			{
				{ "head", "Coins de la case" },
				{ "note", "Un de vos sorts par coin : un carré de couleur qui se vide avec le temps. Le sort quitte alors la rangée d'icônes. Chaque classe garde ses propres coins ; la liste propose les sorts de votre classe et ceux de l'onglet Listes.", 74 },
				CornerPicker("TOPLEFT", "En haut à gauche"),
				CornerPicker("TOPRIGHT", "En haut à droite"),
				CornerPicker("BOTTOMLEFT", "En bas à gauche"),
				CornerPicker("BOTTOMRIGHT", "En bas à droite"),
				{ "note", "En combat, le jeu cache le nom des auras : Lyorune reconnaît vos soins à leur numéro, ou au sort que vous venez de lancer. Un soin qu'il ne peut pas reconnaître reste dans la rangée d'icônes, jamais dans un mauvais coin.", 74 },
			},
		},
	}
end

----------------------------------------------------------------------------------------------------
-- Onglet Listes : trois listes de noms de sorts
----------------------------------------------------------------------------------------------------
local function ListEditor(page, x, title, hint, key)
	local width = 208
	local head = Heading(page, title)
	head:SetWidth(width)
	head:SetPoint("TOPLEFT", x, 0)
	Note(page, hint, x, -30, width)
	local rows = {}
	local function Fill()
		local names = {}
		for name in pairs(Z.db[key]) do names[#names + 1] = name end
		table.sort(names)
		for i, row in ipairs(rows) do
			row.name = names[i]
			row.label:SetText(names[i] or "")
			row:SetShown(names[i] ~= nil)
		end
	end
	local edit = UI.Edit(page, width, function(text)
		if text ~= "" then
			Z.db[key][text] = true
			Z:Refresh()
		end
	end)
	edit:SetPoint("TOPLEFT", x, -84)
	edit:HookScript("OnEnterPressed", function(self)
		self:SetText("")
		Fill()
	end)
	for i = 1, 11 do
		local row = UI.Button(page, "", width, 22, function(self)
			Z.db[key][self.name] = nil
			Z:Refresh()
			Fill()
		end)
		row:SetPoint("TOPLEFT", x, -112 - (i - 1) * 25)
		row.tip = L["Cliquez pour retirer de la liste."]
		rows[i] = row
	end
	Register(page.tabIndex, L[title], edit)
	return Fill
end

local function BuildLists(page)
	local fills = {
		ListEditor(page, 0, "Mes sorts à suivre", "Sorts à vous, affichés avec vos soins sur la durée. Tapez le nom exact puis Entrée.", "extraTracked"),
		ListEditor(page, 222, "À ignorer", "Affaiblissements à ne jamais afficher.", "ignoredNames"),
		ListEditor(page, 444, "À mettre en avant", "Affaiblissements affichés en grand, avec contour lumineux et son (onglet Indicateurs).", "importantNames"),
	}
	local function FillAll() for _, fill in ipairs(fills) do fill() end end
	page:SetScript("OnShow", FillAll)
	FillAll()
end

----------------------------------------------------------------------------------------------------
-- Onglet Clics
----------------------------------------------------------------------------------------------------
local rows, barIcons = {}, {}
local VISIBLE_ROWS = 13     -- lignes de raccourcis visibles ; la molette fait défiler les autres
local scroll = 0

local function SpellText(value)
	return Z:ActionText(value)
end

local RefreshClicks -- définie plus bas
local specLabel, specCopy, banner, listTop, more, empty

function RefreshClicks()
	-- Nouveau sort sans clic : le plus ancien en haut de la liste
	if banner then
		local spell = Z:NewSpells()[1]
		banner.spell = spell
		banner:SetShown(spell ~= nil)
		if spell then
			banner.icon:SetTexture(spell.icon)
			banner.text:SetText(L["Nouveau sort sans clic :"] .. " |cffffffff" .. spell.name .. "|r")
		end
		listTop:ClearAllPoints()
		listTop:SetPoint("TOPLEFT", 0, spell and -104 or -74)
	end
	-- Une ligne par clic ou par touche
	local bindings = Z:Bindings()
	scroll = math.max(0, math.min(scroll, #bindings - VISIBLE_ROWS))
	for i, row in ipairs(rows) do
		local binding = bindings[i + scroll]
		row.binding = binding
		row:SetShown(binding ~= nil)
		if binding then
			row.key.label:SetText(Z:TriggerLabel(binding))
			row.spell.label:SetText(binding.value ~= "" and SpellText(binding.value) or "|cff555a63" .. L["Sort"] .. "|r")
		end
	end
	if more then
		local hidden = math.max(0, #bindings - VISIBLE_ROWS - scroll)
		more:SetText((scroll + hidden > 0) and L["Molette : %d autre(s) raccourci(s)"]:format(scroll + hidden) or "")
		empty:SetShown(#bindings == 0)
	end
	-- Macros pour les barres de sorts : une icône par macro tenue à jour par Lyorune
	local macros = Z.db.actionBarMacros and Z:BarMacros() or {}
	for i, icon in ipairs(barIcons) do
		local macro = macros[i]
		icon.macro = macro
		icon:SetShown(macro ~= nil)
		if macro then icon.texture:SetTexture(macro.icon or "Interface\\Icons\\INV_Misc_QuestionMark") end
	end
	-- Spécialisation dont on voit les clics
	if specLabel then
		local perSpec = Z.db.clicksPerSpec
		specLabel:SetText(perSpec and L["Clics de la spécialisation %d"]:format(Z:SpecGroup()) or L["Mêmes clics dans toutes les spécialisations"])
		specCopy:SetShown(perSpec)
	end
end
-- Appelé aussi par ApplyClicks : la liste suit les changements faits ailleurs (macros, partage), si elle est visible
Z.RefreshClicks = function()
	if listTop and listTop:IsVisible() then RefreshClicks() end
end

-- Prend une macro de Lyorune « en main », pour la déposer dans une barre de sorts
local function PickupBarMacro(icon)
	if not icon.macro then return end
	if InCombatLockdown() then return Z:Print(L["impossible de modifier les macros en combat."]) end
	local index = GetMacroIndexByName(icon.macro.name)
	if index and index > 0 then
		PickupMacro(index)
	else
		Z:Print(L["cette macro n'existe pas encore : elle sera créée dans quelques secondes."])
	end
end

local function BuildBarIcons(page, x, y)
	local size, perRow = 28, 9
	for i = 1, perRow * 2 do
		local icon = CreateFrame("Button", nil, page)
		icon:SetSize(size, size)
		icon:SetPoint("TOPLEFT", x + ((i - 1) % perRow) * (size + 4), y - math.floor((i - 1) / perRow) * (size + 4))
		icon.texture = icon:CreateTexture(nil, "ARTWORK")
		icon.texture:SetAllPoints()
		icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		icon.border = UI.Border(icon, 1)
		icon:RegisterForDrag("LeftButton")
		icon:SetScript("OnClick", PickupBarMacro)
		icon:SetScript("OnDragStart", PickupBarMacro)
		icon:SetScript("OnEnter", function(self)
			self.border:SetColor(UI.accent[1], UI.accent[2], UI.accent[3])
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.macro.name, UI.accent[1], UI.accent[2], UI.accent[3])
			GameTooltip:AddLine(self.macro.body, 1, 1, 1)
			GameTooltip:AddLine(L["Cliquez, puis déposez dans une barre de sorts."], 0.6, 0.6, 0.65)
			GameTooltip:Show()
		end)
		icon:SetScript("OnLeave", function(self)
			self.border:SetColor(0, 0, 0)
			GameTooltip:Hide()
		end)
		icon:Hide()
		barIcons[i] = icon
	end
	return 2 * (size + 4)
end

-- Fenêtre de choix d'un sort : une icône par sort connu. onChoose(valeur) reçoit le choix.
-- spellsOnly : seulement les sorts (pour l'assistant de macro), sans « Cibler », « Menu » ni macros.
local function OpenPicker(title, onChoose, current, spellsOnly)
	if not picker then
		picker = UI.Window("LyorunePicker", "", 372, 200)
		picker:SetFrameStrata("FULLSCREEN_DIALOG")
		tinsert(UISpecialFrames, "LyorunePicker")
		picker.icons = {}
		local function Choose(value)
			picker.onChoose(value)
			picker:Hide()
			RefreshClicks()
		end
		picker.Choose = Choose
		picker.actions = CreateFrame("Frame", nil, picker)
		picker.actions:SetPoint("TOPLEFT", 14, -42)
		picker.actions:SetSize(344, 22)
		local target = UI.Button(picker.actions, L["Cibler"], 70, 22, function() Choose("@target") end)
		target:SetPoint("TOPLEFT")
		local menu = UI.Button(picker.actions, L["Menu du joueur"], 110, 22, function() Choose("@menu") end)
		menu:SetPoint("LEFT", target, "RIGHT", 6, 0)
		local none = UI.Button(picker.actions, L["Vider"], 60, 22, function() Choose(nil) end)
		none:SetPoint("LEFT", menu, "RIGHT", 6, 0)
		local macro = UI.Button(picker.actions, L["Mes macros..."], 92, 22, function()
			picker:Hide()
			Z:OpenMacros()
		end)
		macro:SetPoint("LEFT", none, "RIGHT", 6, 0)
		macro.label:SetJustifyH("CENTER")
		macro.tip = L["Plusieurs actions en un clic : écrivez vos macros une fois, posez-les sur autant de clics que vous voulez."]
		picker.hint = UI.Text(picker, 11)
		picker.hint:SetPoint("BOTTOMLEFT", 14, 44)
		UI.Paint(picker.hint, "dim")
		picker.hint:SetText(L["Ou tapez le nom exact d'un sort, puis Entrée :"])
		picker.edit = UI.Edit(picker, 344, function(text)
			if text ~= "" then Choose(text) end
		end)
		picker.edit:SetPoint("BOTTOMLEFT", 14, 14)
	end

	picker.onChoose = onChoose
	picker.current = current
	picker.title:SetText(title)
	picker.edit:SetText("")
	picker.actions:SetShown(not spellsOnly)

	-- Les sorts connus, puis les macros de ma bibliothèque
	local spells, macros = Z:KnownSpells(), spellsOnly and {} or Z:GetMacros()
	local perRow, size = 10, 32
	local function Place(index, slot, top)
		local icon = picker.icons[index]
		if not icon then
			icon = CreateFrame("Button", nil, picker)
			icon:SetSize(size, size)
			icon.texture = icon:CreateTexture(nil, "ARTWORK")
			icon.texture:SetAllPoints()
			icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			icon.border = UI.Border(icon, 1)
			icon:SetScript("OnEnter", function(self)
				self.border:SetColor(UI.accent[1], UI.accent[2], UI.accent[3])
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				if self.spell then
					GameTooltip:SetSpellByID(self.spell.id)
				else
					GameTooltip:SetText(self.macro.name, UI.accent[1], UI.accent[2], UI.accent[3])
					GameTooltip:AddLine(self.macro.body, 1, 1, 1)
				end
				GameTooltip:Show()
			end)
			icon:SetScript("OnLeave", function(self)
				self.border:SetColor(0, 0, 0)
				GameTooltip:Hide()
			end)
			icon:SetScript("OnClick", function(self)
				picker.Choose(self.spell and self.spell.name or "@macro:" .. self.macro.name)
			end)
			picker.icons[index] = icon
		end
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", 14 + ((slot - 1) % perRow) * (size + 2.5), top - math.floor((slot - 1) / perRow) * (size + 3))
		icon:Show()
		return icon
	end

	local top = -74
	for i, spell in ipairs(spells) do
		local icon = Place(i, i, top)
		icon.spell, icon.macro = spell, nil
		icon.texture:SetTexture(spell.icon)
	end
	top = top - math.ceil(#spells / perRow) * (size + 3)

	if not picker.macroHead then
		picker.macroHead = UI.Text(picker, 11)
		UI.Paint(picker.macroHead, "accent")
		picker.macroHead:SetText(L["Mes macros :"])
	end
	local shown = math.min(#macros, 40)
	picker.macroHead:SetShown(shown > 0)
	if shown > 0 then
		picker.macroHead:ClearAllPoints()
		picker.macroHead:SetPoint("TOPLEFT", 14, top - 6)
		top = top - 24
		for i = 1, shown do
			local icon = Place(#spells + i, i, top)
			icon.spell, icon.macro = nil, macros[i]
			icon.texture:SetTexture(Z:MacroIcon(macros[i].body))
		end
		top = top - math.ceil(shown / perRow) * (size + 3)
	end
	for i = #spells + shown + 1, #picker.icons do picker.icons[i]:Hide() end

	picker:SetHeight(-top + 72)
	picker:ClearAllPoints()
	picker:SetPoint("CENTER", (spellsOnly or not window) and UIParent or window, "CENTER")
	picker:Show()
	picker:Raise()
	return picker
end
Z.OpenPicker = OpenPicker

-- Une case de clic accepte un sort glissé du grimoire, une macro glissée de /macro ou de ma bibliothèque
local function Droppable(button, setValue)
	button.dropValue = setValue
	button:SetScript("OnReceiveDrag", function()
		local value = Z:TakeCursor()
		if value then
			setValue(value)
			RefreshClicks()
		end
	end)
end

-- Attend le prochain raccourci, à la souris ou au clavier, et le renvoie à onTrigger({ kind, key }) :
--   un bouton de souris de 1 à 5 sur ce bouton-ci   -> un clic   ("ctrl-shift-1")
--   un bouton à partir du 6e, la molette, une touche -> une touche au survol ("CTRL-SHIFT-F", "BUTTON6")
-- Alt, Ctrl et Maj seuls ne font qu'attendre la suite ; Échap annule.
local MODIFIER_KEYS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, LMETA = true, RMETA = true }
local MOUSE_CLICKS = { LeftButton = "1", RightButton = "2", MiddleButton = "3", Button4 = "4", Button5 = "5" }

local function CaptureTrigger(button, onTrigger)
	local function Finish(trigger)
		button.capturing = nil
		button.ignoreUntil = GetTime() + 0.3 -- le relâchement du clic capturé ne relance pas l'attente
		button:EnableKeyboard(false)
		button:EnableMouseWheel(false)
		button:SetScript("OnKeyDown", nil)
		button:SetScript("OnMouseWheel", nil)
		button:SetScript("OnMouseDown", nil)
		if button.idle then button.label:SetText(button.idle) end
		RefreshClicks()
		if trigger then onTrigger(trigger) end
	end
	local function Upper()
		return (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "")
	end
	button.capturing = true
	button.label:SetText("|cff" .. UI.Hex("accent") .. L["Cliquez ici ou appuyez sur une touche..."] .. "|r")
	button:EnableKeyboard(true)
	button:EnableMouseWheel(true)
	button:SetScript("OnKeyDown", function(_, key)
		if MODIFIER_KEYS[key] then return end
		if key == "ESCAPE" then return Finish(nil) end
		local full = Upper() .. key
		Finish(Z.ValidKey(full) and { kind = "key", key = full } or nil)
	end)
	button:SetScript("OnMouseWheel", function(_, delta)
		Finish({ kind = "key", key = Upper() .. (delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") })
	end)
	button:SetScript("OnMouseDown", function(_, mouse)
		local click = MOUSE_CLICKS[mouse]
		if click then return Finish({ kind = "click", key = Upper():lower() .. click }) end
		local number = mouse and mouse:match("^Button(%d+)$") -- boutons supplémentaires des souris MMO
		if number then Finish({ kind = "key", key = Upper() .. "BUTTON" .. number }) end
	end)
end

-- Ouvre la fenêtre de choix pour un raccourci ; « value » est posé directement s'il est donné
local function ChooseAction(trigger, value)
	if value then
		Z:SetBinding(trigger, value)
		return RefreshClicks()
	end
	OpenPicker(Z:TriggerLabel(trigger), function(chosen) Z:SetBinding(trigger, chosen) end, Z:GetBinding(trigger))
end

local function Trigger(row)
	return { kind = row.binding.kind, key = row.binding.key }
end

local function BuildClicks(page)
	Note(page, "Un clic ou une touche par ligne, autant que vous voulez, avec Alt, Ctrl, Maj ou leurs combinaisons. Le sort part sur la case survolée.", 0, 0, COLUMN)

	-- Spécialisation dont on voit les clics, et copie depuis l'autre
	local x = COLUMN + 32
	specLabel = UI.Text(page, 11)
	specLabel:SetPoint("TOPLEFT", x, 0)
	UI.Paint(specLabel, "accent")
	specCopy = UI.Button(page, L["Copier l'autre spécialisation"], 200, 18, function()
		Z:CopyOtherSpec()
		RefreshClicks()
	end)
	specCopy:SetPoint("TOPLEFT", x, -15)
	specCopy.label:SetJustifyH("CENTER")
	specCopy.tip = L["Remplace les clics et les touches de cette spécialisation par ceux de l'autre."]

	-- Ajouter : on clique sur le bouton, puis on fait la combinaison voulue (clic, touche ou molette)
	local add = UI.Button(page, "", COLUMN, 28, function(self)
		if self.capturing or GetTime() < (self.ignoreUntil or 0) then return end
		local preset = self.preset
		self.preset = nil
		CaptureTrigger(self, function(trigger) ChooseAction(trigger, preset) end)
	end)
	add.idle = "+ " .. L["Ajouter un clic ou une touche"]
	add.label:SetText(add.idle)
	add.label:SetJustifyH("CENTER")
	add.tip = L["Cliquez, puis faites la combinaison voulue sur ce bouton : un clic (avec Alt, Ctrl, Maj...), une touche du clavier, un bouton de souris supplémentaire ou la molette. Échap : annuler."]
	add:SetPoint("TOPLEFT", 0, -40)
	Register(page.tabIndex, L["Ajouter un clic ou une touche"], add)
	Register(page.tabIndex, L["Touches au survol"], add)
	page.add = add

	-- Nouveau sort appris, sans aucun raccourci (option « newSpellAlert »)
	banner = CreateFrame("Frame", nil, page)
	banner:SetSize(COLUMN, 26)
	banner:SetPoint("TOPLEFT", 0, -74)
	banner.icon = banner:CreateTexture(nil, "ARTWORK")
	banner.icon:SetSize(22, 22)
	banner.icon:SetPoint("LEFT", 2, 0)
	banner.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	banner.text = UI.Text(banner, 11)
	banner.text:SetPoint("LEFT", banner.icon, "RIGHT", 6, 0)
	banner.text:SetPoint("RIGHT", -104, 0)
	banner.text:SetJustifyH("LEFT")
	banner.text:SetWordWrap(false)
	UI.Paint(banner.text, "accent")
	banner.dismiss = UI.Button(banner, "x", 22, 22, function()
		if banner.spell then Z:DismissNewSpell(banner.spell.name) end
	end)
	banner.dismiss:SetPoint("RIGHT")
	banner.dismiss.label:SetJustifyH("CENTER")
	banner.dismiss.tip = L["Ne plus proposer ce sort."]
	banner.assign = UI.Button(banner, L["Attribuer"], 74, 22, function()
		if not banner.spell then return end
		add.preset = banner.spell.name
		add:GetScript("OnClick")(add, "LeftButton")
	end)
	banner.assign:SetPoint("RIGHT", banner.dismiss, "LEFT", -4, 0)
	banner.assign.label:SetJustifyH("CENTER")
	banner.assign.tip = L["Puis faites sur le bouton « Ajouter » le clic ou la touche qui lancera ce sort."]
	banner:Hide()
	page.banner = banner

	-- La liste : déclencheur, action, retirer. La molette fait défiler.
	listTop = CreateFrame("Frame", nil, page)
	listTop:SetSize(COLUMN, VISIBLE_ROWS * 27)
	listTop:SetPoint("TOPLEFT", 0, -74)
	listTop:EnableMouseWheel(true)
	listTop:SetScript("OnMouseWheel", function(_, delta)
		scroll = scroll - delta
		RefreshClicks()
	end)
	for i = 1, VISIBLE_ROWS do
		local row = CreateFrame("Frame", nil, listTop)
		row:SetSize(COLUMN, 24)
		row:SetPoint("TOPLEFT", 0, -(i - 1) * 27)
		row.key = UI.Button(row, "", 132, 24, function(self)
			if self.capturing or GetTime() < (self.ignoreUntil or 0) or not row.binding then return end
			local from = Trigger(row)
			CaptureTrigger(self, function(to)
				Z:MoveBinding(from, to)
				RefreshClicks()
			end)
		end)
		row.key:SetPoint("LEFT")
		row.key.label:SetJustifyH("CENTER")
		row.key.tip = L["Changer ce raccourci : cliquez, puis faites la nouvelle combinaison. S'il était déjà pris, les deux sorts sont échangés."]
		row.spell = UI.Button(row, "", COLUMN - 132 - 30, 24, function()
			if not row.binding then return end
			ChooseAction(Trigger(row), Z:TakeCursor()) -- un sort ou une macro tenu sous la souris est posé directement
		end)
		row.spell:SetPoint("LEFT", row.key, "RIGHT", 4, 0)
		row.spell.label:SetJustifyH("CENTER")
		Droppable(row.spell, function(value)
			if row.binding then Z:SetBinding(Trigger(row), value) end
		end)
		row.clear = UI.Button(row, "x", 22, 24, function()
			if not row.binding then return end
			Z:SetBinding(Trigger(row), nil)
			RefreshClicks()
		end)
		row.clear:SetPoint("LEFT", row.spell, "RIGHT", 4, 0)
		row.clear.label:SetJustifyH("CENTER")
		row.clear.tip = L["Retirer ce raccourci"]
		rows[i] = row
	end
	empty = UI.Text(listTop, 11)
	empty:SetPoint("TOPLEFT", 4, -6)
	empty:SetWidth(COLUMN - 8)
	empty:SetJustifyH("LEFT")
	UI.Paint(empty, "dim")
	empty:SetText(L["Aucun raccourci pour l'instant : cliquez sur « Ajouter », puis faites un clic ou appuyez sur une touche."])
	more = UI.Text(page, 11)
	more:SetPoint("TOPLEFT", listTop, "BOTTOMLEFT", 0, -2)
	UI.Paint(more, "dim")
	local free = UI.Text(page, 11)
	free:SetPoint("TOPLEFT", listTop, "BOTTOMLEFT", 0, -18)
	free:SetWidth(COLUMN)
	free:SetJustifyH("LEFT")
	UI.Paint(free, "dim")
	free:SetText(L["Clic gauche libre : cibler. Clic droit libre : menu du joueur. Glissez un sort du grimoire sur une ligne pour le poser."])

	-- Spécialisations, macros et comportement, à droite
	local perSpec = BuildItem(page, { "check", "clicksPerSpec", "Clics propres à chaque spécialisation",
		"Chaque groupe de talents a ses clics et ses touches ; ils changent tout seuls avec vos talents. Décoché : les mêmes partout." })
	perSpec:SetPoint("TOPLEFT", x, -42)
	local library = BuildItem(page, { "button", "Mes macros...", function() Z:OpenMacros() end,
		"Votre bibliothèque de macros : écrire, vérifier, importer de /macro, puis glisser sur un clic." })
	library:SetPoint("TOPLEFT", x, -72)
	local options = {
		{ "head", "Comportement" },
		{ "check", "castOnDown", "Lancer le sort dès l'appui (plus rapide)" },
		{ "check", "autoRes", "Le même clic relève un joueur mort", "Si la cible est morte, votre sort de soin est remplacé par votre résurrection." },
		{ "check", "newSpellAlert", "Signaler un nouveau sort sans clic", "Quand vous apprenez un sort utilisable sur un allié qui n'a encore ni clic ni touche : un message, et le sort en haut de cet onglet avec le bouton « Attribuer »." },
		{ "check", "externalClicks", "Laisser Clique ou le jeu gérer les clics", "À cocher seulement si vous préférez Clique ou le clic-soin du jeu : les clics de Lyorune sont alors coupés." },
		{ "head", "Macros pour vos barres de sorts" },
		{ "check", "actionBarMacros", "Créer une macro par sort de mes clics", "Lyorune crée et tient à jour de vraies macros du jeu (leur nom commence par « Lyo: »), rangées dans /macro, onglet de votre personnage. Il ne touche à aucune autre macro." },
		{ "note", "Cliquez sur une icône, puis déposez-la dans une barre de sorts. La macro vise le joueur sous la souris, sinon votre cible, sinon vous.", 44 },
	}
	local y = -104
	for _, item in ipairs(options) do
		local widget = BuildItem(page, item)
		widget:SetPoint("TOPLEFT", x, y)
		y = y - widget:GetHeight() - 7
	end
	y = y - BuildBarIcons(page, x, y) - 4
	local remove = BuildItem(page, { "button", "Retirer les macros de Lyorune", function()
		Z:RemoveBarMacros()
		Z.db.actionBarMacros = false
		page:Hide() page:Show() -- la case à cocher et les icônes suivent
	end, "Supprime les macros « Lyo: » et décoche l'option. Vos autres macros ne sont pas touchées." })
	remove:SetPoint("TOPLEFT", x, y)

	page:SetScript("OnShow", function()
		Z:CheckNewSpells()
		RefreshClicks()
	end)
	RefreshClicks()
end

----------------------------------------------------------------------------------------------------
-- Onglet Alertes
----------------------------------------------------------------------------------------------------
local function BuildAlerts(page)
	local edits = {}
	local function Block(y, label, enableKey, textKey, thresholdKey, test)
		local check = UI.Check(page, L[label], Option(enableKey))
		check:SetPoint("TOPLEFT", 0, y)
		Register(page.tabIndex, L[label], check)
		if thresholdKey then
			local limit = Z.limits[thresholdKey]
			local stepper = UI.Stepper(page, L["Seuil (%)"], limit[1], limit[2], limit[3], Option(thresholdKey))
			stepper:SetPoint("TOPLEFT", COLUMN + 32, y)
		end
		local edit = UI.Edit(page, 540)
		edit:SetPoint("TOPLEFT", 0, y - 26)
		edit:SetMaxLetters(120)
		edit:HookScript("OnTextChanged", function(self, byUser)
			if byUser and self:GetText():match("%S") then Z.db[textKey] = self:GetText() end
		end)
		edits[textKey] = edit
		local button = UI.Button(page, L["Tester"], 80, 22, test)
		button:SetPoint("LEFT", edit, "RIGHT", 10, 0)
		button.label:SetJustifyH("CENTER")
	end

	local head = Heading(page, "Annonces dans le chat")
	head:SetPoint("TOPLEFT")
	local channel = BuildItem(page, { "cycle", "alertChannel", "Canal des annonces" })
	channel:SetPoint("TOPLEFT", 0, -32)

	Block(-66, "Annoncer quand ma mana est faible", "manaAlert", "manaText", "manaThreshold",
		function() Z:Announce(Z:ManaText(Z.db.manaThreshold), true) end)
	Block(-128, "Annoncer quand ma mana est remontée", "regenAlert", "regenText", "regenThreshold",
		function() Z:Announce(Z:RegenText(Z.db.regenThreshold), true) end)
	Block(-190, "Annoncer quand je ressuscite un joueur", "resAlert", "resText", nil,
		function() Z:Announce(Z:ResText(UnitName("player")), true) end)

	Note(page, "Dans les textes, {mana} est remplacé par votre pourcentage de mana et {nom} par le joueur relevé. Les annonces ne partent qu'en groupe. Règle du jeu : hors instance, un addon ne peut pas écrire en /dire tout seul ; l'annonce part alors dans le canal du groupe ou du raid.", 0, -252)

	local sounds = Heading(page, "Sons")
	sounds:SetPoint("TOPLEFT", 0, -312)
	local dispel = BuildItem(page, { "check", "soundDispel", "Son quand je peux dissiper un affaiblissement" })
	dispel:SetPoint("TOPLEFT", 0, -344)
	local mana = BuildItem(page, { "check", "soundMana", "Son quand ma mana est faible" })
	mana:SetPoint("TOPLEFT", COLUMN + 32, -344)

	local function Fill()
		for key, edit in pairs(edits) do edit:SetText(Z.db[key]) end
	end
	page:SetScript("OnShow", Fill)
	Fill()
end

----------------------------------------------------------------------------------------------------
-- Onglet Profils
----------------------------------------------------------------------------------------------------
local function BuildProfiles(page)
	local right = COLUMN + 32
	local result

	-- Colonne de gauche, 1 : mes profils (#24)
	local mine = Heading(page, "Mes profils")
	mine:SetPoint("TOPLEFT")
	Register(page.tabIndex, L["Mes profils"], mine)
	Note(page, "Vos réglages d'apparence, enregistrés sous un nom. Clics, macros, listes et annonces n'en font pas partie : ils ne changent jamais avec le profil.", 0, -30, COLUMN)

	local choices, selected = { { false, L["(aucun)"] } }, false -- remplie par Refresh
	local picker = UI.Cycle(page, L["Profil"], choices, function() return selected end, function(value) selected = value end)
	picker:SetWidth(COLUMN)
	picker:SetPoint("TOPLEFT", 0, -66)
	local status = Note(page, "", 0, -158, COLUMN)
	local cells = {}
	local function Refresh()
		wipe(choices)
		for _, name in ipairs(Z:ProfileNames()) do choices[#choices + 1] = { name, name } end
		if #choices == 0 then choices[1] = { false, L["(aucun)"] } end
		if not (selected and Z.db.profiles[selected]) then
			selected = Z.db.profiles[Z.db.activeProfile] and Z.db.activeProfile or choices[1][1]
		end
		picker:Update()
		local active = Z.db.activeProfile ~= "" and Z.db.activeProfile or L["aucun"]
		status:SetText(L["Profil en cours : %s"]:format("|cffffffff" .. active .. "|r"))
		for _, cell in ipairs(cells) do cell:Update() end
	end
	Z.RefreshProfiles = Refresh

	local load = UI.Button(page, L["Charger"], 100, 24, function()
		if selected and Z:LoadProfile(selected) then
			RefreshShownPages()
			result:SetText("|cff33dd88" .. L["Profil « %s » chargé."]:format(selected) .. "|r")
		end
		Refresh()
	end)
	load:SetPoint("TOPLEFT", 0, -94)
	load.label:SetJustifyH("CENTER")
	local delete
	delete = UI.Button(page, L["Supprimer"], 100, 24, function(self)
		if not selected then return end
		if not self.armed then -- un premier clic arme le bouton, le second confirme
			self.armed = true
			self.label:SetText("|cffff5555" .. L["Confirmer"] .. "|r")
			C_Timer.After(4, function()
				delete.armed = false
				delete.label:SetText(L["Supprimer"])
			end)
			return
		end
		self.armed = false
		self.label:SetText(L["Supprimer"])
		Z:DeleteProfile(selected)
		result:SetText("|cff33dd88" .. L["Profil « %s » supprimé."]:format(selected) .. "|r")
		selected = nil
		Refresh()
	end)
	delete:SetPoint("TOPLEFT", 106, -94)
	delete.label:SetJustifyH("CENTER")

	local name
	local function Save()
		local ok, message = Z:SaveProfile(name:GetText())
		result:SetText((ok and "|cff33dd88" or "|cffff5555") .. message .. "|r")
		if ok then
			selected = Z.ProfileName(name:GetText())
			name:SetText("")
		end
		Refresh()
	end
	name = UI.Edit(page, COLUMN - 116, Save)
	name:SetPoint("TOPLEFT", 0, -126)
	local save = UI.Button(page, L["Enregistrer sous"], 110, 22, Save)
	save:SetPoint("LEFT", name, "RIGHT", 6, 0)
	save.label:SetJustifyH("CENTER")
	save.tip = L["Tapez un nom, puis Enregistrer sous : vos réglages d'apparence du moment deviennent ce profil (nouveau, ou remplacé)."]
	Register(page.tabIndex, L["Enregistrer sous"], save)

	-- Colonne de gauche, 2 : profils automatiques, pour chaque taille de groupe et chaque spécialisation
	local auto = Heading(page, "Profils automatiques")
	auto:SetPoint("TOPLEFT", 0, -180)
	Register(page.tabIndex, L["Profils automatiques"], auto)
	local enable = BuildItem(page, { "check", "autoProfile", "Changer de profil tout seul", "Selon la taille du groupe et votre spécialisation, sans /reload. En combat, le changement attend la fin du combat." })
	enable:SetPoint("TOPLEFT", 0, -212)
	local LABEL_W, CELL_W = 74, 56
	for i, size in ipairs(Z.profileSizes) do
		local head = UI.Label(page, 11, nil, "accent")
		head:SetPoint("TOPLEFT", LABEL_W + (i - 1) * (CELL_W + 4), -240)
		head:SetWidth(CELL_W)
		head:SetJustifyH("CENTER")
		head:SetText(size == "5" and L["Seul, 5"] or size)
	end
	for group = 1, 2 do
		local y = -256 - (group - 1) * 26
		local label = UI.Label(page, 11)
		label:SetPoint("TOPLEFT", 0, y - 5)
		label:SetText(L["Spé. %d"]:format(group))
		for i, size in ipairs(Z.profileSizes) do
			local cell = UI.Button(page, "", CELL_W, 22, function(self, mouseButton)
				local rules = Z:ProfileRules(group)
				local list = { false } -- false : aucun profil
				for _, n in ipairs(Z:ProfileNames()) do list[#list + 1] = n end
				local at = 1
				for k, n in ipairs(list) do if n == rules[size] then at = k end end
				at = at + (mouseButton == "RightButton" and -1 or 1)
				if at > #list then at = 1 elseif at < 1 then at = #list end
				rules[size] = list[at] or nil
				self:Update()
				UI.Confirm(self)
				Z:CheckAutoProfile()
			end)
			cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			cell:SetPoint("TOPLEFT", LABEL_W + (i - 1) * (CELL_W + 4), y)
			cell.label:SetJustifyH("CENTER")
			cell.Update = function(self)
				local wanted = Z:ProfileRules(group)[size]
				self.label:SetText(wanted or (group == 2 and L["comme 1"] or "-"))
				if wanted then
					self.tip = wanted
				elseif group == 2 then
					self.tip = L["Rien de choisi : le profil de la spécialisation 1 s'applique."]
				else
					self.tip = L["Aucun profil : les réglages du moment restent."]
				end
			end
			cell.size, cell.group = size, group
			cells[#cells + 1] = cell
		end
	end
	page.profileCells = cells
	Note(page, "Clic : profil suivant, clic droit : précédent.", 0, -312, COLUMN)

	-- Colonne de gauche, 3 : points de départ
	local presets = Heading(page, "Profils prêts à l'emploi")
	presets:SetPoint("TOPLEFT", 0, -340)
	Register(page.tabIndex, L["Profils prêts à l'emploi"], presets)
	Note(page, "Un point de départ en un clic. Seules la taille et la disposition changent ; vos clics sont conservés.", 0, -370, COLUMN)
	for i, preset in ipairs(Z.presets) do
		local button = UI.Button(page, L[preset[2]], 150, 24, function() Z:ApplyPreset(preset[1]) end)
		button:SetPoint("TOPLEFT", ((i - 1) % 2) * 156, -406 - math.floor((i - 1) / 2) * 29)
		button.label:SetJustifyH("CENTER")
	end

	-- Colonne de droite, 2 et 3 : remise à zéro, entre joueurs
	local clicksHead = Heading(page, "Remise à zéro")
	clicksHead:SetPoint("TOPLEFT", right, -262)
	local clicks = UI.Button(page, L["Reprendre les clics proposés pour ma classe"], COLUMN, 24, function()
		Z.db.clicks[Z.class] = nil
		Z:BuildData()
		Z:ApplyClicks()
		result:SetText("|cff33dd88" .. L["Clics de la classe rétablis."] .. "|r")
	end)
	clicks:SetPoint("TOPLEFT", right, -294)
	clicks.label:SetJustifyH("CENTER")
	local reset
	reset = UI.Button(page, L["Tout réinitialiser"], COLUMN, 24, function(self)
		if not self.armed then -- un premier clic arme le bouton, le second confirme
			self.armed = true
			self.label:SetText("|cffff5555" .. L["Cliquez encore pour confirmer"] .. "|r")
			C_Timer.After(4, function()
				reset.armed = false
				reset.label:SetText(L["Tout réinitialiser"])
			end)
			return
		end
		Z:ResetAll()
		Refresh()
		result:SetText("|cff33dd88" .. L["Tous les réglages sont revenus à l'origine."] .. "|r")
	end)
	reset:SetPoint("TOPLEFT", right, -324)
	reset.label:SetJustifyH("CENTER")
	reset.tip = L["Remet tous les réglages d'origine. La position des cadres et vos profils enregistrés sont conservés."]
	Register(page.tabIndex, L["Tout réinitialiser"], reset)

	local sync = Heading(page, "Entre joueurs")
	sync:SetPoint("TOPLEFT", right, -366)
	local accept = BuildItem(page, { "check", "acceptConfigs", "Accepter qu'on me propose une configuration", "Seulement d'un membre du groupe, de la guilde ou d'un ami. Rien n'est appliqué sans votre accord : une fenêtre vous demande." })
	accept:SetPoint("TOPLEFT", right, -398)
	local notice = BuildItem(page, { "check", "versionNotice", "Me prévenir si une version plus récente existe" })
	notice:SetPoint("TOPLEFT", right, -425)

	-- Colonne de droite : partage
	local exportHead = Heading(page, "Donner ma configuration")
	exportHead:SetPoint("TOPLEFT", right, 0)
	Register(page.tabIndex, L["Donner ma configuration"], exportHead)
	Note(page, "Code à copier (Ctrl+C) et à envoyer : chuchotement, Discord...", right, -30, COLUMN)
	local export = UI.Edit(page, COLUMN)
	export:SetPoint("TOPLEFT", right, -52)
	local function FillExport()
		export:SetText(Z:Export())
		export:SetCursorPosition(0)
	end
	export:HookScript("OnTextChanged", function(_, byUser)
		if byUser then FillExport() end -- le code n'est pas modifiable à la main
	end)

	Note(page, "Ou envoi direct à un joueur qui a Lyorune (il devra accepter) :", right, -84, COLUMN)
	local target = UI.Edit(page, COLUMN - 96)
	target:SetPoint("TOPLEFT", right, -106)
	local send = UI.Button(page, L["Envoyer"], 90, 22, function()
		local ok, message = Z:SendConfig(target:GetText())
		result:SetText((ok and "|cff33dd88" or "|cffff5555") .. message .. "|r")
	end)
	send:SetPoint("LEFT", target, "RIGHT", 6, 0)
	send.label:SetJustifyH("CENTER")

	local importHead = Heading(page, "Recevoir une configuration")
	importHead:SetPoint("TOPLEFT", right, -140)
	Register(page.tabIndex, L["Recevoir une configuration"], importHead)
	Note(page, "Collez le code reçu (Ctrl+V), puis Importer. Votre position à l'écran est conservée.", right, -170, COLUMN)
	local import
	local function DoImport()
		local ok, message = Z:Import(import:GetText())
		result:SetText((ok and "|cff33dd88" or "|cffff5555") .. message .. "|r")
		if ok then
			import:SetText("")
			FillExport()
		end
	end
	import = UI.Edit(page, COLUMN - 96, DoImport)
	import:SetPoint("TOPLEFT", right, -202)
	local button = UI.Button(page, L["Importer"], 90, 22, DoImport)
	button:SetPoint("LEFT", import, "RIGHT", 6, 0)
	button.label:SetJustifyH("CENTER")

	result = Note(page, "", right, -234, COLUMN)
	page:SetScript("OnShow", function()
		FillExport()
		Refresh()
	end)
	FillExport()
	Refresh()
end

----------------------------------------------------------------------------------------------------
-- Onglet Aide
----------------------------------------------------------------------------------------------------
local function BuildHelp(page)
	local legend = {
		{ { 0.45, 1.00, 0.60 }, "Vert clair au bout de la barre : soins en route" },
		{ { 0.55, 0.85, 1.00 }, "Bande claire en bas : bouclier d'absorption" },
		{ { 0.25, 0.50, 1.00 }, "Barre bleue sous la vie : mana" },
		{ { 1.00, 0.15, 0.15 }, "Bordure rouge : le joueur est attaqué" },
		{ { 1.00, 1.00, 1.00 }, "Bordure blanche : votre cible" },
		{ { 0.20, 0.60, 1.00 }, "Cadre bleu : magie que vous pouvez dissiper" },
		{ { 0.65, 0.20, 1.00 }, "Cadre violet : malédiction" },
		{ { 0.75, 0.50, 0.10 }, "Cadre brun : maladie" },
		{ { 0.10, 0.85, 0.20 }, "Cadre vert : poison" },
		{ { 0.35, 0.35, 0.38 }, "Case estompée : joueur hors de portée" },
	}
	local head = Heading(page, "Lire une case")
	head:SetPoint("TOPLEFT")
	for i, entry in ipairs(legend) do
		local square = UI.Tex(page, "ARTWORK", entry[1][1], entry[1][2], entry[1][3])
		square:SetSize(12, 12)
		square:SetPoint("TOPLEFT", 2, -12 - i * 21)
		local text = UI.Text(page, 12)
		text:SetPoint("LEFT", square, "RIGHT", 10, 0)
		text:SetText(L[entry[2]])
	end

	local commands = Heading(page, "Commandes")
	commands:SetPoint("TOPLEFT", 0, -256)
	local list = UI.Label(page, 12)
	list:SetPoint("TOPLEFT", commands, "BOTTOMLEFT", 0, -8)
	list:SetJustifyH("LEFT")
	list:SetSpacing(4)
	local function Commands() -- les commandes prennent la couleur d'accent du thème de fenêtre
		local c = "|cff" .. UI.Hex("accent")
		list:SetText(c .. "/lyorune|r  " .. L["ouvrir cette fenêtre"] .. "\n" .. c .. "/lyorune test|r  " .. L["mode test (faux groupe)"]
			.. "\n" .. c .. "/lyorune tuto|r  " .. L["relancer le tutoriel"] .. "\n" .. c .. "/lyorune assistant|r  " .. L["assistant de départ"] .. "\n" .. c .. "/lyorune verrou|r  " .. L["verrouiller ou libérer la position"]
			.. "\n" .. c .. "/lyorune bug|r  " .. L["signaler un bug"] .. "\n" .. c .. "/lyorune diag|r  " .. L["compatibilité avec le jeu"])
	end
	Commands()
	UI.OnSkin(Commands)

	local items = {
		{ "head", "Découvrir" },
		{ "button", "Lancer le tutoriel", function() window:Hide() Z:StartTutorial() end },
		{ "button", "Assistant de départ", function() window:Hide() Z:StartWizard() end, "Trois questions (rôle, taille de groupe, forme des cases) pour régler Lyorune d'un coup." },
		{ "button", "Nouveautés de Lyorune", function() Z:ShowNews() end },
		{ "check", "showNews", "Montrer les nouveautés après une mise à jour" },
		{ "head", "Autour de Lyorune" },
		{ "check", "minimapButton", "Bouton sur la mini-carte", "Clic gauche : options. Clic droit : mode test. Faites-le glisser pour le déplacer." },
		{ "check", "showRunes", "Inscription runique au bas de cette fenêtre", "Passez la souris sur les runes pour lire leur traduction." },
		{ "head", "Un souci ?" },
		{ "button", "Signaler un bug", function() Z:ShowBug() end, "Trois questions, et un rapport prêt à copier. Fonctionne aussi pour un défaut d'affichage." },
		{ "button", "Journal d'erreurs", function() Z:ShowLog() end, "Le journal note chaque erreur avec son contexte. Copiez-le pour obtenir de l'aide." },
		{ "check", "errorNotice", "Me prévenir quand Lyorune rencontre une erreur", "Un seul message discret par session, jamais de fenêtre." },
		{ "head", "Langue" },
		{ "cycle", "language", "Langue de Lyorune", nil, "Le changement s'applique après /reload." },
	}
	local y = 0
	for _, item in ipairs(items) do
		local widget = BuildItem(page, item)
		widget:SetPoint("TOPLEFT", COLUMN + 32, y)
		y = y - widget:GetHeight() - 7
	end
end

----------------------------------------------------------------------------------------------------
-- Fenêtre, onglets et recherche
----------------------------------------------------------------------------------------------------
local function BuildPage(index)
	local tab = tabs[index]
	if tab.page then return end
	tab.page = CreateFrame("Frame", nil, window)
	tab.page:SetPoint("TOPLEFT", 24, -92)
	tab.page:SetPoint("BOTTOMRIGHT", -24, 30)
	tab.page.tabIndex = index
	tab.page:Hide()
	if tab.columns then
		BuildColumns(tab.page, tab.columns)
	else
		Z:Try("onglet " .. tab.name, tab.build, tab.page)
	end
end

-- Barre lumineuse sous l'onglet actif : elle glisse de l'ancien onglet au nouveau (0,2 s)
local function MoveIndicator(index)
	local bar, from = window.indicator, window.indicator.index
	bar.slide:Stop()
	bar.index = index
	local start = tabs[from or index].button
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", start, "BOTTOMLEFT", 0, -1)
	bar:SetPoint("TOPRIGHT", start, "BOTTOMRIGHT", 0, -1)
	if from and from ~= index and not UI.Calm() and window:IsShown() then
		bar.move:SetOffset((index - from) * window.tabStep, 0)
		bar.slide:Play()
	else
		bar.slide:GetScript("OnFinished")()
	end
end

local current
local function Select(index, quiet)
	if type(index) == "string" then -- par nom : Z:ToggleOptions("Clics")
		for i, tab in ipairs(tabs) do
			if tab.name == index then index = i end
		end
		if type(index) == "string" then index = 1 end
	end
	BuildPage(index)
	local changed = current ~= index
	current = index
	for i, tab in ipairs(tabs) do
		if tab.page then tab.page:SetShown(i == index) end
		tab.button.bg:SetVertexColor(unpack(i == index and UI.line or UI.panel))
		tab.button.label:SetTextColor(unpack(i == index and UI.accent or UI.btext))
		UI.SetTab(tab.button, i == index) -- image d'onglet (normal ou actif) en Classique et MMORPG
	end
	-- La barre lumineuse appartient au thème Moderne : les onglets texturés montrent eux-mêmes l'actif
	local kit = UI.Kit()
	window.indicator:SetShown(kit == "MODERN" or kit == "FLAT")
	MoveIndicator(index)
	-- La page entre en fondu en montant de 6 pixels (0,2 s) ; simple fondu en animations réduites
	local page = tabs[index].page
	if changed and not quiet then
		if not page.enter then
			page.enter = page:CreateAnimationGroup()
			page.drop = page.enter:CreateAnimation("Translation")
			page.drop:SetDuration(0)
			page.drop:SetOrder(1)
			page.rise = page.enter:CreateAnimation("Translation")
			page.rise:SetDuration(0.2)
			page.rise:SetSmoothing("OUT")
			page.rise:SetOrder(2)
			page.fade = UI.AlphaAnim(page.enter, 0, 1, 0.2, "OUT", 2)
		end
		local calm = UI.Calm()
		page.drop:SetOffset(0, calm and 0 or -6)
		page.rise:SetOffset(0, calm and 0 or 6)
		page.fade:SetDuration(calm and 0.15 or 0.2)
		page.enter:Stop()
		page.enter:Play()
	end
	if picker then picker:Hide() end
end

-- Recherche : liste les réglages dont le nom contient le texte tapé ; un clic y mène
local function BuildSearch()
	local results = CreateFrame("Frame", nil, window)
	results:SetFrameStrata("FULLSCREEN_DIALOG")
	results:SetSize(260, 10)
	results.bg = UI.Paint(UI.Tex(results, "BACKGROUND"), "bg", 0.98)
	results.bg:SetAllPoints()
	results.border = UI.Border(results, 1)
	UI.Paint(results.border, "line")
	results.rows = {}
	results:Hide()

	local flash = UI.Paint(UI.Tex(window, "OVERLAY"), "accent", 0.35)
	flash:Hide()

	local edit = UI.Edit(window, 170)
	edit:SetPoint("TOPRIGHT", -44, -12)
	edit.placeholder = UI.Text(edit, 11)
	edit.placeholder:SetPoint("LEFT", 6, 0)
	UI.Paint(edit.placeholder, "dim")
	edit.placeholder:SetText(L["Rechercher un réglage..."])
	results:SetPoint("TOPRIGHT", edit, "BOTTOMRIGHT", 0, -2)

	local function Go(entry)
		results:Hide()
		edit:SetText("")
		edit:ClearFocus()
		Select(entry[2])
		flash:ClearAllPoints()
		flash:SetPoint("TOPLEFT", entry[3], "TOPLEFT", -4, 3)
		flash:SetPoint("BOTTOMRIGHT", entry[3], "BOTTOMRIGHT", 4, -3)
		flash:Show()
		C_Timer.After(1.5, function() flash:Hide() end)
	end

	edit:HookScript("OnTextChanged", function(self)
		local text = self:GetText():lower():match("^%s*(.-)%s*$")
		self.placeholder:SetShown(text == "")
		if #text < 2 then return results:Hide() end
		for i = 1, #tabs do BuildPage(i) end -- la recherche couvre tous les onglets
		local count = 0
		for _, entry in ipairs(searchIndex) do
			if count < 8 and entry[1]:find(text, 1, true) then
				count = count + 1
				local row = results.rows[count]
				if not row then
					row = UI.Button(results, "", 252, 22, function(button) Go(button.entry) end)
					row:SetPoint("TOPLEFT", 4, -4 - (count - 1) * 24)
					results.rows[count] = row
				end
				row.entry = entry
				row.label:SetText(entry[4] .. "  |cff8a8f99" .. L[tabs[entry[2]].name] .. "|r")
				row:Show()
			end
		end
		for i = count + 1, #results.rows do results.rows[i]:Hide() end
		results:SetHeight(count * 24 + 8)
		results:SetShown(count > 0)
	end)
	window.search = edit
end

local function Build()
	window = UI.Window("LyoruneOptions", "Lyorune  |cff8a8f99" .. Z.version .. "|r", WIDTH, HEIGHT)
	tinsert(UISpecialFrames, "LyoruneOptions")
	UI.main = window -- les fenêtres secondaires s'ouvrent à côté d'elle (UI.PlaceBeside)

	local simple = SimpleTabs()
	tabs = {
		{ name = "Cadres", columns = simple.Cadres },
		{ name = "Apparence", columns = simple.Apparence },
		{ name = "Indicateurs", columns = simple.Indicateurs },
		{ name = "Soins", columns = simple.Soins },
		{ name = "Listes", build = BuildLists },
		{ name = "Clics", build = BuildClicks },
		{ name = "Alertes", build = BuildAlerts },
		{ name = "Profils", build = BuildProfiles },
		{ name = "Aide", build = BuildHelp },
	}
	local tabWidth = math.floor((WIDTH - 48 - (#tabs - 1) * 4) / #tabs)
	window.tabStep = tabWidth + 4
	for i, tab in ipairs(tabs) do
		tab.button = UI.Button(window, L[tab.name], tabWidth, 26, function() Select(i) end)
		tab.button:SetPoint("TOPLEFT", 24 + (i - 1) * (tabWidth + 4), -50)
		tab.button.label:SetJustifyH("CENTER")
	end

	-- Barre lumineuse de l'onglet actif
	local bar = UI.Paint(UI.Tex(window, "OVERLAY"), "accent")
	bar:SetHeight(2)
	bar.slide = bar:CreateAnimationGroup()
	bar.move = bar.slide:CreateAnimation("Translation")
	bar.move:SetDuration(0.2)
	bar.move:SetSmoothing("OUT")
	bar.slide:SetScript("OnFinished", function()
		local target = tabs[bar.index].button
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", target, "BOTTOMLEFT", 0, -1)
		bar:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", 0, -1)
	end)
	window.indicator = bar

	-- Logo dans l'en-tête : il respire lentement (coupé par « Animations réduites »)
	local logo = window:CreateTexture(nil, "ARTWORK")
	logo:SetTexture("Interface\\AddOns\\Lyorune\\Media\\Logo")
	logo:SetSize(26, 26)
	logo:SetPoint("TOPLEFT", 16, -11)
	window.title:SetPoint("TOPLEFT", 48, -16)
	window.logo, window.breath = logo, UI.Breathe(logo, 0.85, 12) -- souffle doux et lent : 12 s par respiration
	window:HookScript("OnShow", function() if not UI.Calm() then window.breath:Play() end end)
	window:HookScript("OnHide", function() window.breath:Stop() end)

	-- Changement de thème : l'onglet actif reprend ses couleurs, sans rejouer d'animation
	UI.OnSkin(function() if current then Select(current, true) end end)

	BuildSearch()
	window.magic = UI.HeaderMagic(window, logo, window.search)
	if Z.RefreshRunes then Z:RefreshRunes(window) end
	window.Select = Select
	Select(1, true)
end

-- Z:ToggleOptions() ouvre ou ferme. Z:ToggleOptions("Clics") ouvre sur un onglet.
function Z:ToggleOptions(tab)
	if not window then Build() end
	if tab then
		Select(tab)
		window:Show()
	else
		window:SetShown(not window:IsShown())
	end
end

-- Pour les tests : les icônes des macros de barre, une case de clic
function Z:BarIcons()
	return barIcons
end

-- La ligne d'un raccourci dans l'onglet Clics (bouton du sort, puis la ligne) ; kind : "click" ou "key"
function Z:ClickCell(key, kind)
	for _, row in ipairs(rows) do
		if row.binding and row.binding.key == key and row.binding.kind == (kind or "click") then return row.spell, row end
	end
end

-- Pour les tests : les onglets et leurs boutons
function Z:OptionsTabs()
	return tabs
end

function Z:OptionsWindow()
	return window
end

-- Pour les tests : libellés de tous les réglages, après construction de tous les onglets
function Z:OptionLabels()
	if not window then Build() end
	for i = 1, #tabs do BuildPage(i) end
	local labels = {}
	for _, entry in ipairs(searchIndex) do labels[#labels + 1] = entry[4] end
	return labels
end
