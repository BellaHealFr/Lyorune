-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Options.lua : la fenêtre /lyorune.
-- Une barre latérale de douze chapitres, un sujet par chapitre, chaque réglage à un seul endroit :
--   Accueil             de quoi bien commencer
--   Disposition         où et comment les cases sont rangées
--   Apparence           à quoi elles ressemblent
--   Vie et portée       barre de vie, barre de mana, portée
--   Mes soins           mes soins sur la durée, les coins de la case, la recharge globale
--   Affaiblissements    dissipation, icônes, importants, auras privées, listes
--   Joueurs             rôle, menace, buffs, survol
--   Sorts et raccourcis souris, touches au survol, macros (ancien nom : Clics)
--   Alertes             annonces dans le chat et sons
--   Profils et partage  profils, partage, synchronisation
--   Fenêtre et aide     cette fenêtre, la langue, l'aide
-- Chaque chapitre est une page qui défile, décrite par une liste (Chapters) : ajouter un réglage = ajouter une
-- ligne. Les réglages fins de chaque partie sont repliés sous « Réglages fins (n) ».
-- La recherche (en haut à droite) retrouve un réglage par son nom ou son explication.
-- Au bas de la fenêtre, de chaque côté de l'inscription runique : « Enregistrer mes réglages » et « Annuler mes
-- changements » (retour à l'ouverture de la fenêtre).

local _, Z = ...
local UI = Z.UI
local L = Z.L

local WIDTH, HEIGHT = 1080, 708
local SIDE = 212            -- largeur de la barre latérale
local HEAD = 58             -- en-tête : logo, titre, recherche
local FOOT = 34             -- bas de la fenêtre : inscription runique, Enregistrer et Annuler
local ROW = 520             -- largeur d'une ligne de réglage
local FINE = 14             -- retrait des réglages fins
local WITNESS = 290         -- largeur de la colonne de la case témoin, à droite
local window, picker, witness
local chapters
local searchIndex = {}      -- { text, more, chapter, widget, label, key } : nom, explications, chapitre, élément
local AfterChange           -- après un changement : pastilles, réglages dépendants, « Rétablir cette page » (plus bas)
local UpdateFoot            -- après un changement : « Annuler mes changements » paraît ou disparaît (plus bas)
local DIMMED = 0.42         -- transparence d'un réglage sans effet (son réglage parent est coupé)

----------------------------------------------------------------------------------------------------
-- Lecture et écriture d'un réglage. Après chaque changement, les cadres sont rafraîchis.
----------------------------------------------------------------------------------------------------
local CLICK_OPTIONS = { castOnDown = true, autoRes = true, externalClicks = true, actionBarMacros = true, clicksPerSpec = true,
	clickConflictAlert = true, rankChoice = true, rankAdapt = true, enemyGuard = true }

-- Après un ou plusieurs réglages changés (keys : leurs clés) : cadres, alertes, clics, pastilles
local function Applied(keys)
	Z:Refresh()
	Z:RefreshAlerts()
	local clicks = false
	for _, key in ipairs(keys) do clicks = clicks or CLICK_OPTIONS[key] == true end
	if clicks then Z:ApplyClicks() elseif Z.RefreshClicks then Z.RefreshClicks() end -- liste des clics à l'écran
	if AfterChange then AfterChange() end
	if witness then witness.Spark() end -- éclat de soin sur la case témoin (effets magiques)
end

local function Option(key)
	return function() return Z.db[key] end, function(value)
		Z.db[key] = value
		Applied({ key })
	end
end

-- Texte de la recherche : minuscules, accents retirés. Lua ne change que les lettres sans accent : sans cela,
-- « échelle » ne trouve pas « Échelle », et un mot tapé sans accent (« reglage ») ne trouve rien.
-- Le texte tapé et l'index passent tous deux par ici.
local PLAIN = {}
for to, from in pairs({ a = "àâäáãÀÂÄÁÃ", e = "éèêëÉÈÊË", i = "îïíìÎÏÍÌ", o = "ôöóòõÔÖÓÒÕ", u = "ùûüúÙÛÜÚ",
	c = "çÇ", n = "ñÑ", y = "ÿŸ", oe = "œŒ", ae = "æÆ" }) do
	for letter in from:gmatch("[\192-\255][\128-\191]*") do PLAIN[letter] = to end
end

-- Les accents d'abord : selon la langue du système, lower() peut changer les octets d'une lettre accentuée
local function Plain(text)
	local plain = (text or ""):gsub("[\192-\255][\128-\191]*", PLAIN)
	return plain:lower()
end
Z.SearchText = Plain

-- Un réglage retrouvable par la recherche. page : la page du chapitre ;
-- more : ses explications (phrase visible et infobulle), cherchées aussi.
local function Register(page, label, widget, more)
	local entry = { text = Plain(label), more = Plain(more), chapter = page.tabIndex, widget = widget,
		label = label }
	searchIndex[#searchIndex + 1] = entry
	return entry
end

local function Heading(parent, text)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(ROW, 24)
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
	note:SetWidth(width or ROW)
	note:SetJustifyH("LEFT")
	note:SetSpacing(3)
	UI.Paint(note, "dim")
	note:SetText(L[text])
	return note
end

-- Texte d'attente gris dans un champ de saisie vide
local function Placeholder(edit, text)
	edit.placeholder = UI.Label(edit, 11, nil, "dim")
	edit.placeholder:SetPoint("LEFT", 6, 0)
	edit.placeholder:SetText(L[text])
	edit:HookScript("OnTextChanged", function(self) self.placeholder:SetShown(self:GetText() == "") end)
	return edit.placeholder
end

local function Tip(widget, text)
	if not text then return end
	local target = widget.button or widget
	target.tip = L[text]
	if target ~= widget.button and not target:GetScript("OnEnter") then
		target:EnableMouse(true) -- choix côte à côte : la ligne entière montre l'aide
		target:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(self.tip, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		target:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
end

----------------------------------------------------------------------------------------------------
-- Construction d'une ligne de réglage à partir de sa description
--   { "head", "Titre" }                       titre (pages dessinées à part ; ailleurs, le titre de la partie)
--   { "check", cle, "Libellé", "aide" }       interrupteur
--   { "seg", cle, "Libellé", nil, "aide" }    choix côte à côte, 2 à 4 possibilités (liste dans Z.choices)
--   { "step", cle, "Libellé" }                nombre (limites dans Z.limits)
--   { "cycle", cle, "Libellé", choix, "aide" } choix (liste dans Z.choices, ou fournie)
--   { "button", "Libellé", fonction, "aide" } bouton
--   { "buttons", { bouton, bouton... } }      boutons côte à côte (même description que « button »)
--   { "note", "Texte", hauteur }              explication
--   { "custom", fonction }                    élément dessiné à part : fonction(page, largeur) renvoie le cadre ;
--                                             son Update() le remet à jour à l'ouverture du chapitre, Fit(cadre, h)
--                                             change sa hauteur et range de nouveau la page
-- Champs nommés, tous facultatifs :
--   desc = "Phrase"     une phrase visible sous le nom, quand le nom ne suffit pas (l'aide reste en infobulle)
--   fine = true         réglage fin : replié sous « Réglages fins (n) »
--   dep = { cle, v }    réglage qui n'a d'effet que si le réglage cle vaut v ("!v" : tout sauf v) : grisé sinon
-- Chaque ligne de réglage reçoit sa rune d'or (réglage changé) entre son nom et sa commande.
----------------------------------------------------------------------------------------------------
local SETTING_KINDS = { check = true, seg = true, step = true, cycle = true } -- lignes qui portent un réglage

local function TranslatedChoices(list)
	local choices = {}
	for _, choice in ipairs(list) do choices[#choices + 1] = { choice[1], L[choice[2]] } end
	return choices
end

-- Valeur d'un réglage en mots : le libellé du choix (liste propre au réglage, comme Thème et Texture, ou
-- Z.choices), « Activé », « Coupé » ou le nombre. Sert à la liste de l'Accueil et à l'infobulle des runes d'or.
local function ValueText(item, value)
	if item[1] == "cycle" and item[4] then
		for _, choice in ipairs(item[4]) do
			if choice[1] == value then return L[choice[2]] end
		end
	end
	return UI.Describe(item[2], value) or ""
end

local function Describe(widget, text, width)
	local desc = UI.Label(widget, 11, nil, "dim")
	desc:SetPoint("TOPLEFT", widget, "BOTTOMLEFT", 0, -1)
	desc:SetWidth(width - 70)
	desc:SetJustifyH("LEFT")
	desc:SetSpacing(2)
	desc:SetText(L[text])
	widget.desc = desc
end

local function BuildButton(page, item)
	local button = UI.Button(page, L[item[2]], item.width or 200, 24, item[3])
	button.label:SetJustifyH("CENTER")
	button.tip = item[4] and L[item[4]]
	Register(page, L[item[2]], button, item[4] and L[item[4]])
	return button
end

local function BuildItem(page, item, width)
	local kind, widget = item[1], nil
	width = width or ROW
	local tip = item[(kind == "seg" or kind == "cycle") and 5 or 4]
	local more = (item.desc and L[item.desc] or "") .. " " .. (type(tip) == "string" and L[tip] or "")
	if kind == "head" then
		widget = Heading(page, item[2])
	elseif kind == "check" then
		widget = UI.Switch(page, L[item[3]], Option(item[2]))
		Tip(widget, item[4])
		Register(page, L[item[3]], widget, more).key = item[2]
	elseif kind == "seg" then
		widget = UI.Segmented(page, L[item[3]], TranslatedChoices(Z.choices[item[2]]), Option(item[2]))
		Tip(widget, item[5])
		Register(page, L[item[3]], widget, more).key = item[2]
	elseif kind == "step" then
		local limit = Z.limits[item[2]]
		widget = UI.Stepper(page, L[item[3]], limit[1], limit[2], limit[3], Option(item[2]))
		Register(page, L[item[3]], widget, more).key = item[2]
	elseif kind == "cycle" then
		widget = UI.Cycle(page, L[item[3]], TranslatedChoices(item[4] or Z.choices[item[2]]), Option(item[2]))
		Tip(widget, item[5])
		Register(page, L[item[3]], widget, more).key = item[2]
	elseif kind == "button" then
		widget = BuildButton(page, item)
	elseif kind == "buttons" then
		widget = CreateFrame("Frame", nil, page)
		widget:SetSize(width, 24)
		widget.buttons = {}
		local each = math.floor((width - 6 * (#item[2] - 1)) / #item[2])
		for i, sub in ipairs(item[2]) do
			sub.width = math.min(each, 160)
			local button = BuildButton(page, sub)
			button:SetParent(widget)
			button:SetPoint("TOPLEFT", (i - 1) * (sub.width + 6), 0)
			widget.buttons[i] = button
		end
	elseif kind == "note" then
		widget = CreateFrame("Frame", nil, page)
		widget:SetSize(width, item[3] or 30)
		Note(widget, item[2], 0, 0, width)
	elseif kind == "custom" then
		widget = item[2](page, width)
	end
	if SETTING_KINDS[kind] then -- un outil de la page peut retrouver un réglage (page.settings.syncEnabled)
		page.settings = page.settings or {}
		page.settings[item[2]] = widget
		-- Rune d'or entre le nom et la commande quand le réglage n'est plus celui de l'installation
		if Z.defaults[item[2]] ~= nil then
			local get, set = Option(item[2])
			UI.ChangedRune(widget, item[2], get, set, widget.box or widget.strip or widget.minus or widget.button,
				function(value) return ValueText(item, value) end)
		end
	end
	if widget.SetWidth and kind ~= "button" then widget:SetWidth(width) end
	if item.desc then Describe(widget, item.desc, width) end
	return widget
end

----------------------------------------------------------------------------------------------------
-- Chapitres décrits par une liste
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

-- Chaque ligne affichée d'une page se remet à jour
local function RefreshPage(page)
	for _, part in ipairs(page.parts) do
		local widget = part.widget
		if widget.Update and widget:IsShown() then widget:Update() end
	end
end

-- Les valeurs affichées suivent un changement fait par un bouton (page ouverte seulement)
local function RefreshShownPages()
	for _, chapter in ipairs(chapters or {}) do
		local page = chapter.page
		if page and page.scroll:IsShown() then RefreshPage(page) end
	end
	if AfterChange then AfterChange() end -- profil chargé, configuration reçue : pastilles et grisage suivent
end
Z.RefreshOptionPages = RefreshShownPages -- numéro d'un nom de liste appris en jeu (Containers.lua)

-- Réglages changés hors de la fenêtre d'options, par une autre fenêtre (l'éditeur de placement) : même suite
-- qu'un changement fait ici, et les interrupteurs des pages ouvertes suivent. values : { clé = valeur }.
function Z.SetOptions(values)
	local keys = {}
	for key, value in pairs(values) do
		Z.db[key] = value
		keys[#keys + 1] = key
	end
	if #keys == 0 then return end
	Applied(keys)
	RefreshShownPages()
end

-- Un élément dessiné à part change de hauteur (liste qui s'allonge) : la page se range de nouveau
local function Fit(widget, height)
	if math.abs((widget:GetHeight() or 0) - height) < 0.5 then return end
	widget:SetHeight(height)
	if widget.Relayout then widget.Relayout() end
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
		GameTooltip:AddLine(L["Chaque valeur se retouche ensuite dans le chapitre Disposition."], 0.6, 0.64, 0.7, true)
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
	picker:SetSize(ROW, 2 * THUMB_H + 6 + 30)
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
	Register(page, L["Forme des cases"], picker).key = "shape"
	return picker
end

-- Vignette de forme pour une autre fenêtre (assistant du premier lancement) : thumb:Draw() la redessine,
-- onClick(thumb) suit le choix de la forme
function Z.ShapeThumb(parent, id, label, onClick)
	local thumb = BuildThumb(parent, id, label, onClick)
	thumb.Draw = DrawThumb
	return thumb
end

-- Appelé après chaque changement d'option (Z:Refresh) : les vignettes et la case témoin suivent le thème, les
-- angles, les couleurs et chaque indicateur. Rien n'est redessiné fenêtre fermée.
function Z:RefreshShapes()
	if Z.shapePicker and Z.shapePicker:IsVisible() then Z.shapePicker:Update() end
	if witness and witness:IsVisible() then Z:Try("case témoin", witness.Update) end
	if UpdateFoot then UpdateFoot() end -- changement fait ailleurs (placement, liste, profil automatique)
end

-- Choix d'un coin : « Aucun », puis mes sorts suivis (ceux de ma classe et ma liste), par ordre alphabétique.
-- Le réglage est gardé par classe : un prêtre et un druide ont chacun leurs coins.
-- La liste est refaite à chaque mise à jour : un sort ajouté à « Mes sorts à suivre » y entre aussitôt, et le sort
-- du coin reste affiché même s'il a quitté la liste (sinon « Aucun » s'afficherait alors que le coin est pris).
function Z.CornerChoices(point)
	local names, seen = {}, {}
	local function Add(name)
		if name and name ~= "" and not seen[name] then
			seen[name] = true
			names[#names + 1] = name
		end
	end
	for name in pairs(Z.trackedNames or {}) do Add(name) end
	for name in pairs(Z.db.extraTracked) do Add(name) end
	Add(Z.MyCorners()[point])
	table.sort(names)
	local choices = { { "", L["Aucun"] } }
	for _, name in ipairs(names) do choices[#choices + 1] = { name, name } end
	return choices
end

local function CornerPicker(point, label)
	return { "custom", function(page)
		local choices = Z.CornerChoices(point)
		local widget = UI.Cycle(page, L[label], choices,
			function() return Z.MyCorners()[point] or "" end,
			function(value)
				local all = Z.db.cornerSpells
				all[Z.class] = all[Z.class] or {}
				all[Z.class][point] = value ~= "" and value or nil
				Z:Refresh()
				if witness then witness.Spark() end -- éclat sur la case témoin, comme pour les autres réglages
			end)
		local show = widget.Update
		local color = Z.CORNER_COLORS[point]
		widget.Update = function(self)
			wipe(choices)
			for _, choice in ipairs(Z.CornerChoices(point)) do choices[#choices + 1] = choice end
			show(self)
			-- le nom est peint en couleur de texte (UI.Label) : chaque changement de thème le repeint, la couleur
			-- du coin est donc remise ici (appelé aussi au changement de thème, Recolor)
			self.label:SetTextColor(color[1], color[2], color[3])
		end
		widget:SetScript("OnShow", widget.Update)
		widget:Update()
		Register(page, L[label], widget)
		return widget
	end }
end

----------------------------------------------------------------------------------------------------
-- Listes de sorts et de joueurs : une ligne par liste, dans le chapitre qu'elle concerne. On tape un nom puis
-- Entrée ; un clic sur un nom le retire. La ligne s'allonge avec la liste.
----------------------------------------------------------------------------------------------------
local CHIPS, CHIP_H = 3, 25 -- noms par rangée, hauteur d'une rangée

-- Lien de sort (Maj-clic dans la discussion, le grimoire ou une infobulle) : son nom et son numéro
function Z.SpellFromLink(text)
	if type(text) ~= "string" then return end
	local id = tonumber(text:match("|Hspell:(%d+)") or "")
	local name = text:match("|h%[(.-)%]|h")
	if id and name and name ~= "" then return name, id end
end

-- Ajoute un nom tapé, ou un lien de sort (le numéro du lien est retenu pour ce nom : reconnu même en combat)
function Z.AddToList(key, text, clean)
	local name, id = Z.SpellFromLink(text)
	if name then
		text = name
		if Z.RememberAuraId then Z.RememberAuraId(name, id) end
	end
	if clean then text = clean(text) end
	if not text or text == "" then return end
	Z.db[key][text] = true
	Z:Refresh()
	return text
end

-- Maj-clic sur un sort pendant qu'un champ de liste est actif : le sort entre dans la liste. Le jeu passe tous
-- les liens par ChatFrameUtil.InsertLink (ChatEdit_InsertLink sur les clients plus anciens) ; on ne fait que
-- lire le lien après lui, sans rien changer à la discussion.
local linkTarget
local SPELL_LISTS = { extraTracked = true, cooldownIgnored = true, ignoredNames = true, importantNames = true } -- pas les joueurs
local function WatchLinks()
	if Z.linksWatched then return end
	local function OnLink(link)
		local edit = linkTarget
		if not (edit and edit:IsVisible() and edit:HasFocus() and Z.SpellFromLink(link)) then return end
		Z.AddToList(edit.listKey, link, edit.clean)
		RefreshShownPages()
	end
	if ChatFrameUtil and ChatFrameUtil.InsertLink then
		hooksecurefunc(ChatFrameUtil, "InsertLink", OnLink)
	elseif ChatEdit_InsertLink then
		hooksecurefunc("ChatEdit_InsertLink", OnLink)
	else
		return
	end
	Z.linksWatched = true
end

local function ListBox(key, title, hint, clean, fields, status)
	local item = { "custom", function(page, width)
		local box = CreateFrame("Frame", nil, page)
		box:SetSize(width, 60)
		box.label = UI.Label(box, 12)
		box.label:SetPoint("TOPLEFT", 0, -5)
		box.label:SetText(L[title])
		box.hint = UI.Label(box, 11, nil, "dim")
		box.hint:SetPoint("TOPLEFT", 0, -28)
		box.hint:SetWidth(width)
		box.hint:SetJustifyH("LEFT")
		box.hint:SetText(L[hint])
		local edit = UI.Edit(box, 210, function(text) Z.AddToList(key, text, clean) end)
		edit:SetPoint("TOPRIGHT")
		Placeholder(edit, "Nom exact, puis Entrée")
		edit.listKey, edit.clean = key, clean
		if SPELL_LISTS[key] then
			edit:HookScript("OnEditFocusGained", function(self)
				WatchLinks()
				linkTarget = self
			end)
		end
		edit:HookScript("OnEnterPressed", function(self)
			self:SetText("")
			RefreshShownPages() -- la liste, et les coins qui proposent les sorts suivis
		end)
		box.edit, box.key = edit, key
		box.empty = UI.Label(box, 11, nil, "dim")
		box.empty:SetText(L["Liste vide."])
		box.chips = {}
		local chipWidth = math.floor((width - 6 * (CHIPS - 1)) / CHIPS)
		box.Update = function(self)
			local names = {}
			for name in pairs(Z.db[key]) do names[#names + 1] = name end
			table.sort(names)
			local top = 28 + math.ceil(self.hint:GetStringHeight()) + 8
			for i, name in ipairs(names) do
				local chip = self.chips[i]
				if not chip then
					chip = UI.Button(self, "", chipWidth, 22, function(button)
						Z.db[key][button.name] = nil
						Z:Refresh()
						RefreshShownPages()
					end)
					self.chips[i] = chip
				end
				chip:ClearAllPoints()
				chip:SetPoint("TOPLEFT", ((i - 1) % CHIPS) * (chipWidth + 6), -top - math.floor((i - 1) / CHIPS) * CHIP_H)
				chip.name = name
				chip.label:SetText(name)
				-- État d'un nom (liste « À mettre en avant ») : gris tant qu'il n'est pas reconnu en combat
				local tip = status and status(name)
				UI.Paint(chip.label, tip and tip.dim and "dim" or "btext")
				local remove = L["Cliquez pour retirer de la liste."]
				chip.tip = tip and tip.text .. "\n" .. remove or remove
				chip:Show()
			end
			for i = #names + 1, #self.chips do self.chips[i]:Hide() end
			self.empty:ClearAllPoints()
			self.empty:SetPoint("TOPLEFT", 4, -top - 4)
			self.empty:SetShown(#names == 0)
			Fit(self, top + math.max(1, math.ceil(#names / CHIPS)) * CHIP_H - 3)
		end
		box:SetScript("OnShow", box.Update)
		box:Update()
		Register(page, L[title], box, L[hint]).list = key
		return box
	end }
	for field, value in pairs(fields or {}) do item[field] = value end -- fine, dep
	return item
end

-- État d'un nom de « À mettre en avant » : en combat le nom est secret, le jeu ne le trouve que par son numéro
local function ImportantStatus(name)
	if Z.KnownAuraIds and Z.KnownAuraIds(name) then
		return { text = L["Reconnu par son numéro : le jeu le trouve aussi en combat."] }
	end
	return { dim = true, text = L["Pas encore reconnu : il sera appris la première fois qu'il est vu hors combat. Ou tapez son numéro, ou faites Maj-clic sur le sort."] }
end

-- Épingler ma cible : sous la liste des joueurs épinglés
local function PinTarget()
	local name = Z.UnitPinName("target")
	if name and Z.db.pinned[name] then return Z:Print(L["%s est déjà épinglé."]:format(name)) end
	Z:Print(Z:TogglePin(name))
	RefreshShownPages()
end

----------------------------------------------------------------------------------------------------
-- Répartition entre soigneurs (Assign.lua) : mes groupes de raid, et la répartition reçue du chef
----------------------------------------------------------------------------------------------------
local function AssignGroups(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 54)
	box.label = UI.Label(box, 12)
	box.label:SetPoint("TOPLEFT", 0, -5)
	box.label:SetText(L["Groupes de raid dont je m'occupe"])
	box.buttons = {}
	for g = 1, 8 do
		local button = UI.Button(box, tostring(g), 36, 22, function()
			Z.db.assignGroups[g] = not Z.db.assignGroups[g] or nil
			Z.RefreshAssign()
			box:Update()
			if AfterChange then AfterChange() end
		end)
		button:SetPoint("TOPLEFT", (g - 1) * 42, -28)
		button.label:SetJustifyH("CENTER")
		box.buttons[g] = button
	end
	box.Update = function(self)
		for g, button in ipairs(self.buttons) do UI.SetTab(button, Z.db.assignGroups[g] == true) end
	end
	box:SetScript("OnShow", box.Update)
	box:Update()
	Register(page, L["Groupes de raid dont je m'occupe"], box, L["Les groupes ne comptent qu'en raid ; en groupe de cinq, seuls les joueurs choisis."])
	return box
end

-- « Mes buffs » : une ligne par buff de ma classe (Data.lua), deux cases : JcE (donjons, raids, monde) et JcJ
-- (champ de bataille, arène). Écrit Z.db.buffWatch[numéro] ; un choix égal au départ de Data.lua est effacé.
local WATCH_ROW = 24
local WATCH_GAP = 60 -- écart entre les colonnes JcE et JcJ
-- Bord droit d'une case à cocher dans sa ligne : +4 met le bord droit de la case contre celui de la ligne, comme
-- la case des interrupteurs au-dessus (même résultat dans les trois thèmes : la case est collée à gauche du bouton)
local WATCH_RIGHT = 4
local function BuffWatchList(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 40)
	box.label = UI.Label(box, 12)
	box.label:SetPoint("TOPLEFT", 0, -5)
	box.label:SetText(L["Mes buffs"])
	box.columns = {}
	for i, text in ipairs({ "JcE", "JcJ" }) do
		local column = UI.Label(box, 11, nil, "dim")
		column:SetText(L[text]) -- accroché au centre de sa colonne de cases (Update)
		box.columns[i] = column
	end
	box.empty = Note(box, "Votre classe n'a aucun buff à surveiller.", 0, -28, width)
	box.lines = {}
	-- Nom affiché : le sort, « ou » ses autres sorts qui comptent aussi ; un mot pour les bénédictions et l'arme
	local function Entries()
		local list = {}
		for _, entry in ipairs(Z.raidBuffs[Z.class] or {}) do
			local ids, known, icon = Z.BuffIds(entry), false, nil
			for _, id in ipairs(ids) do
				if Z.Knows(id) then
					known = true
					icon = icon or Z.SpellIcon(id) -- la bénédiction, l'arme ou le bouclier que je connais
				end
			end
			local name = Z.SpellName(ids[1]) or ("#" .. ids[1])
			if entry.blessing then name = L["Bénédictions (une de vous par joueur)"]
			elseif entry.weapon then name = L["Enchantement de l'arme"]
			elseif entry.aura then name = L["Aura (la dernière lancée)"]
			else
				for _, id in ipairs(entry.any or {}) do name = name .. L[" ou "] .. (Z.SpellName(id) or "#" .. id) end
				if entry.self then name = name .. "  |cffb3b3b3(" .. L["sur vous"] .. ")|r" end
			end
			local passive = not (entry.blessing or entry.weapon or entry.aura) and Z.IsPassive(ids[1])
			if (known or not entry.racial) and not passive then -- sort de race d'une autre race, sort passif : rien à régler
				list[#list + 1] = { id = ids[1], pve = entry.pve, pvp = entry.pvp, name = name, known = known,
					icon = icon or Z.SpellIcon(ids[1]) }
				-- sa version de groupe (Prière de robustesse...) : sa propre ligne, juste en dessous, reconnue à sa
				-- mention « (groupe) » (icônes et noms alignés sur les autres lignes)
				local group = entry[2] and Z.SpellName(entry[2])
				if group then
					list[#list + 1] = { id = entry[2], group = true, known = Z.Knows(entry[2]), icon = Z.SpellIcon(entry[2]),
						name = group .. "  |cffb3b3b3(" .. L["groupe"] .. ")|r" }
				end
			end
		end
		for _, entry in ipairs(Z.uniqueBuffs[Z.class] or {}) do
			entry = type(entry) == "table" and entry or { entry }
			list[#list + 1] = { id = entry[1], pve = entry.pve, pvp = entry.pvp, known = Z.Knows(entry[1]), icon = Z.SpellIcon(entry[1]), unique = true,
				name = (Z.SpellName(entry[1]) or "#" .. entry[1]) .. "  |cffb3b3b3(" .. L["une personne"] .. ")|r" }
		end
		return list
	end
	local function Toggle(row, context)
		return function() return Z.BuffWatched(row.entry, context) end, function(value)
			local chosen = Z.db.buffWatch[row.entry.id] or {}
			chosen[context] = value
			if value == (row.entry[context] ~= false) then chosen[context] = nil end -- retour au départ
			Z.db.buffWatch[row.entry.id] = next(chosen) and chosen or nil
			Z:Refresh()
			if AfterChange then AfterChange() end
		end
	end
	-- Buff à une personne : une 2e ligne « Sur : Tank / Moi / Un joueur », le nom et « Ma cible » (Z.SetBuffBearer)
	local MODES = { { "TANK", "Tank" }, { "ME", "Moi" }, { "NAME", "Un joueur" } }
	local function Bearer(row)
		row.on = UI.Label(row, 11, nil, "dim")
		row.on:SetPoint("TOPLEFT", 28, -WATCH_ROW - 4)
		row.on:SetText(L["Sur :"])
		row.modes = {}
		for m, mode in ipairs(MODES) do
			local button = UI.Button(row, L[mode[2]], 70, 20, function()
				local _, name = Z.BuffBearer(row.entry.id)
				Z.SetBuffBearer(row.entry.id, mode[1], name)
				box:Update()
				if AfterChange then AfterChange() end
			end)
			button:SetPoint("TOPLEFT", 62 + (m - 1) * 74, -WATCH_ROW)
			row.modes[m] = button
		end
		row.edit = UI.Edit(row, 120, function(text)
			local name = Z.CleanPinName(text)
			Z.SetBuffBearer(row.entry.id, name and "NAME" or "TANK", name)
			box:Update()
			if AfterChange then AfterChange() end
		end)
		row.edit:SetPoint("TOPLEFT", 62 + 3 * 74 + 4, -WATCH_ROW - 1)
		Placeholder(row.edit, "Nom, puis Entrée")
		row.pick = UI.Button(row, L["Ma cible"], 74, 20, function()
			local name = Z.UnitPinName("target")
			if not name then
				Z:Print(L["ciblez d'abord le joueur qui doit recevoir ce buff."])
				return
			end
			Z.SetBuffBearer(row.entry.id, "NAME", name)
			box:Update()
			if AfterChange then AfterChange() end
		end)
		row.pick:SetPoint("LEFT", row.edit, "RIGHT", 6, 0)
		row.pick.tip = L["Le joueur que vous ciblez reçoit ce buff."]
	end
	local function ShowBearer(row)
		local unique = row.entry.unique
		if unique and not row.modes then Bearer(row) end
		if not row.modes then return end
		local mode, name = Z.BuffBearer(row.entry.id)
		row.on:SetShown(unique)
		for m, button in ipairs(row.modes) do
			UI.SetTab(button, MODES[m][1] == mode)
			button:SetShown(unique)
		end
		local named = unique and mode == "NAME"
		row.edit:SetShown(named)
		row.pick:SetShown(named)
		if named and not row.edit.focused then row.edit:SetText(name or "") end
	end
	box.Update = function(self)
		local entries = Entries()
		local y = 28
		for i, entry in ipairs(entries) do
			local row = self.lines[i]
			if not row then
				row = CreateFrame("Frame", nil, self)
				row:SetSize(width, WATCH_ROW)
				row.icon = row:CreateTexture(nil, "ARTWORK")
				row.icon:SetSize(18, 18)
				row.icon:SetPoint("TOPLEFT", 2, -(WATCH_ROW - 18) / 2) -- en haut : un buff à une personne a une 2e ligne
				row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				row.name = UI.Label(row, 12)
				row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
				row.name:SetJustifyH("LEFT")
				row.name:SetWordWrap(false)
				row.entry = entry -- avant les cases : elles lisent leur état dès leur création
				row.checks = {}
				for c, context in ipairs({ "pve", "pvp" }) do
					local check = UI.Check(row, "", Toggle(row, context))
					check:SetSize(20, 20)
					check:SetPoint("TOPRIGHT", WATCH_RIGHT - (2 - c) * WATCH_GAP, -(WATCH_ROW - 20) / 2)
					row.checks[c] = check
				end
				row.name:SetPoint("RIGHT", row.checks[1], "LEFT", -12, 0)
				self.lines[i] = row
			end
			row.entry = entry
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 0, -y)
			row:SetHeight(entry.unique and WATCH_ROW * 2 + 2 or WATCH_ROW)
			y = y + row:GetHeight()
			ShowBearer(row)
			row.icon:SetTexture(entry.icon)
			row.name:SetText(entry.name)
			row.name:SetAlpha(entry.known and 1 or DIMMED) -- pas encore appris : grisé, mais réglable
			for _, check in ipairs(row.checks) do check:Update() end
			row:Show()
		end
		for i = #entries + 1, #self.lines do self.lines[i]:Hide() end
		self.empty:SetShown(#entries == 0)
		for c, column in ipairs(self.columns) do
			local first = self.lines[1]
			column:ClearAllPoints()
			if first then column:SetPoint("BOTTOM", first.checks[c].box, "TOP", 0, 6) end -- centré sur ses cases
			column:SetShown(#entries > 0)
		end
		Fit(self, math.max(y, 28 + WATCH_ROW))
	end
	box:SetScript("OnShow", box.Update)
	box:Update()
	Z.buffWatchBox = box
	Register(page, L["Mes buffs"], box, L["Les buffs de votre classe à surveiller : une liste pour les donjons, raids et le monde (JcE), une autre pour les champs de bataille (JcJ)."]
		.. " " .. L["La version simple et la version de groupe se cochent séparément."]
		.. " " .. L["En champ de bataille, le jeu cache les buffs : Lyorune retient ceux que vous lancez (/lyorune buffs)."]
		.. " " .. L["Un buff à poser sur une seule personne se règle juste en dessous : le tank, vous, ou un joueur choisi (son nom, ou votre cible)."])
	return box
end

-- Qui buffe qui (BuffAssign.lua) : mes groupes de raid à buffer. Un bouton par groupe, tous allumés au départ ;
-- « Comme mes soins » recopie mes groupes de soin. Une répartition du chef qui me donne des groupes les remplace.
local function BuffGroups(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 54)
	box.label = UI.Label(box, 12)
	box.label:SetPoint("TOPLEFT", 0, -5)
	box.label:SetText(L["Groupes de raid que je buffe"])
	box.buttons = {}
	for g = 1, 8 do
		local button = UI.Button(box, tostring(g), 36, 22, function()
			if Z.db.buffGroups[g] == false then Z.db.buffGroups[g] = nil else Z.db.buffGroups[g] = false end
			Z.RecheckAllBuffs()
			box:Update()
			if AfterChange then AfterChange() end
		end)
		button:SetPoint("TOPLEFT", (g - 1) * 42, -28)
		button.label:SetJustifyH("CENTER")
		box.buttons[g] = button
	end
	box.like = UI.Button(box, L["Comme mes soins"], 130, 22, function()
		if not Z.BuffGroupsLikeHealing() then Z:Print(L["choisissez d'abord vos groupes de soin (Mes joueurs)."]) end
		box:Update()
		if AfterChange then AfterChange() end
	end)
	box.like:SetPoint("TOPLEFT", 8 * 42 + 6, -28)
	box.like.label:SetJustifyH("CENTER")
	box.like.tip = L["Vos groupes de soin (Mes joueurs) deviennent vos groupes à buffer."]
	box.chief = Note(box, "", 0, -56, width)
	box.Update = function(self)
		local groups, chief = Z.BuffGroupsChoice()
		for g, button in ipairs(self.buttons) do UI.SetTab(button, groups[g] == true) end
		self.chief:SetText(chief and L["La répartition des buffs du chef choisit vos groupes pour l'instant."] or "")
		Fit(self, chief and 74 or 54)
	end
	box:SetScript("OnShow", box.Update)
	box:Update()
	Z.buffGroupsBox = box -- (pour les tests)
	Register(page, L["Groupes de raid que je buffe"], box, L["En raid, les buffs manquants ne sont proposés que pour ces groupes. Tous au départ. Vos propres buffs restent toujours proposés."])
	return box
end

-- Grille « Bénédiction par joueur » (paladin) : une ligne par type de joueur (Z.blessingSlots), un bouton qui
-- passe d'une bénédiction à l'autre (clic droit : en arrière). Départ, chaque bénédiction connue, puis Aucune.
local function BlessingGrid(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 40)
	box.label = UI.Label(box, 12)
	box.label:SetPoint("TOPLEFT", 0, -5)
	box.label:SetText(L["Bénédiction par joueur"])
	box.empty = Note(box, "Réservé aux paladins.", 0, -28, width)
	box.rows = {}
	local half = math.floor((width - 12) / 2)
	local function Blessings()
		for _, check in ipairs(Z.buffChecks or {}) do
			if check.blessing then return check end
		end
	end
	local function Choices(check)
		local list = { false } -- départ
		for _, choice in ipairs(check.choices) do list[#list + 1] = choice.id end
		list[#list + 1] = 0 -- aucune
		return list
	end
	box.Update = function(self)
		local check = Blessings()
		self.empty:SetShown(not check)
		for _, row in ipairs(self.rows) do row:Hide() end
		if not check then return Fit(self, 48) end
		for i, slot in ipairs(Z.blessingSlots) do
			local row = self.rows[i]
			if not row then
				row = CreateFrame("Frame", nil, self)
				row:SetSize(half, 24)
				row.name = UI.Label(row, 12)
				row.name:SetPoint("LEFT")
				row.name:SetWidth(80)
				row.name:SetJustifyH("LEFT")
				row.name:SetWordWrap(false)
				row.pick = UI.Button(row, "", half - 86, 22, function(_, mouse)
					local list = Choices(Blessings())
					local now = Z.BlessingPick(row.slot)
					local at = 1
					for k, id in ipairs(list) do if id == (now == nil and false or now) then at = k end end
					at = mouse == "RightButton" and (at - 2) % #list + 1 or at % #list + 1
					local value = list[at]
					Z.db.blessingPick[row.slot] = value ~= false and value or nil
					Z.BlessingsChanged()
					self:Update()
					if AfterChange then AfterChange() end
				end)
				row.pick:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				row.pick:SetPoint("LEFT", 84, 0)
				row.pick.label:SetJustifyH("CENTER")
				row.pick.tip = L["Clic : la bénédiction suivante. Clic droit : la précédente."]
				self.rows[i] = row
			end
			row.slot = slot
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", ((i - 1) % 2) * (half + 12), -28 - math.floor((i - 1) / 2) * 26)
			row.name:SetText(L[Z.blessingSlotNames[slot]])
			local pick = Z.BlessingPick(slot)
			local text
			if pick == 0 then
				text = L["Aucune"]
			elseif pick then
				text = Z.SpellName(pick) or ("#" .. pick)
			else
				local mana = slot == "HEALER" or (slot ~= "TANK" and not Z.classPower[slot])
				local first = (Z.blessingFor[slot] or (slot == "HEALER" or mana) and Z.blessingFor.MANA or Z.blessingFor.OTHER)
				local name
				for _, id in ipairs(first) do
					for _, choice in ipairs(check.choices) do
						if not name and choice.id == id then name = choice.name end
					end
				end
				text = (name or check.choices[1].name) .. "  |cffb3b3b3(" .. L["départ"] .. ")|r"
			end
			row.pick.label:SetText(text)
			row:Show()
		end
		Fit(self, 28 + math.ceil(#Z.blessingSlots / 2) * 26 + 4)
	end
	box:SetScript("OnShow", box.Update)
	box:Update()
	Z.blessingGridBox = box -- (pour les tests)
	Register(page, L["Bénédiction par joueur"], box, L["Paladin : la bénédiction à poser à chaque type de joueur (tanks, soigneurs, puis chaque classe)."]
		.. " " .. L["Une bénédiction déjà posée par un autre paladin n'est jamais reprise : la suivante est proposée."])
	return box
end

-- La répartition reçue du chef, si elle compte : elle remplace mon choix
local function AssignStatus(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 18)
	box.text = Note(box, "", 0, -2, width)
	box.Update = function(self)
		local groups, players, shared = Z.AssignChoice()
		if shared then
			self.text:SetText(L["Répartition reçue de %s : vous soignez %s. Elle remplace votre choix jusqu'à la sortie du groupe."]:format(shared.by, Z.AssignDescribe(groups, players)))
		else
			self.text:SetText(L["Aucune répartition reçue : votre choix ci-dessus compte."])
		end
		Fit(self, math.ceil(self.text:GetStringHeight()) + 4)
	end
	box:SetScript("OnShow", box.Update)
	Z.assignStatus = box
	box:Update()
	return box
end

----------------------------------------------------------------------------------------------------
-- Page des clics (chapitre Sorts et raccourcis)
----------------------------------------------------------------------------------------------------
local rows, barIcons = {}, {}
local ROW_H = 27            -- hauteur d'une ligne de raccourci ; toutes sont visibles, la page défile
local COUNT_W = 44          -- largeur du nombre d'utilisations d'une ligne (statistiques de mes clics)
local clickList, specLine, barBox -- lignes du chapitre Sorts et raccourcis, créées à sa première ouverture

local function SpellText(value)
	return Z:ActionText(value)
end

local RefreshClicks -- définie plus bas

-- Icône d'un bouton de bijou : le bijou porté quand il est choisi, sinon l'emplacement Bijou vide du jeu
local TRINKET_SLOT_NAMES = { [13] = "Trinket0Slot", [14] = "Trinket1Slot" }
local function TrinketIcon(slot, chosen)
	local worn = chosen and GetInventoryItemTexture and GetInventoryItemTexture("player", slot)
	if worn then return worn end
	local empty
	if GetInventorySlotInfo then empty = select(2, GetInventorySlotInfo(TRINKET_SLOT_NAMES[slot])) end
	return empty or "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket"
end
local NewRow        -- une ligne de raccourci de plus (définie plus bas)

-- Bulle de la situation d'une sous-ligne de variante
local VARIANT_TIPS = {
	enemy = "Sur une case qui montre un ennemi (Cible, Focalisation, allié sous Contrôle mental), ce raccourci lance ceci. Le jeu choisit au moment du clic, en combat aussi.",
	pvp = "En champ de bataille, ce raccourci lance ceci. Posé à l'entrée du lieu, retiré à la sortie.",
	tank = "Sur un tank, ce raccourci lance ceci (par exemple le rang le plus haut, et un rang économe sur les autres). Toujours juste dans le cadre « Tanks » et les cadres par rôle, même en combat ; ailleurs, posé hors combat selon le rôle de chacun.",
	ooc = "Hors combat, ce raccourci lance ce sort ; en combat, le sort de la ligne du dessus. Le jeu choisit au moment du clic.",
}

function RefreshClicks()
	if clickList then
		-- Nouveau sort sans clic : le plus ancien, sous le bouton « Ajouter »
		local banner = clickList.banner
		local spell = Z:NewSpells()[1]
		banner.spell = spell
		banner:SetShown(spell ~= nil)
		if spell then
			banner.icon:SetTexture(spell.icon)
			banner.text:SetText(L["Nouveau sort sans clic :"] .. " |cff" .. UI.Hex("text") .. spell.name .. "|r")
		end
		local top = spell and 66 or 36
		clickList.list:ClearAllPoints()
		clickList.list:SetPoint("TOPLEFT", 0, -top)
		-- Une ligne par clic ou par touche, suivie d'une sous-ligne par variante (sur un ennemi, en JcJ, sur un tank, hors combat)
		local bindings = Z:Bindings()
		local conflicts = Z.db.clickConflictAlert and Z:GameClickConflicts() or {}
		local lines = {}
		for _, binding in ipairs(bindings) do
			lines[#lines + 1] = { binding = binding }
			for _, kind in ipairs(Z.variantKinds) do
				local value = binding.variants and binding.variants[kind[1]]
				if value then lines[#lines + 1] = { binding = binding, variant = kind, value = value } end
			end
		end
		for i = #rows + 1, #lines do rows[i] = NewRow(i) end
		for i, row in ipairs(rows) do
			local line = lines[i]
			local binding = line and line.binding
			row.binding, row.variant = binding, line and line.variant
			row:SetShown(binding ~= nil)
			row.add:SetShown(line ~= nil and not line.variant)
			if line and line.variant then
				-- sous-ligne : la situation, en retrait, puis ce que lance la variante
				row.key.label:SetText("|cff" .. UI.Hex("dim") .. L[line.variant[2]] .. "|r")
				row.key.tip = L[VARIANT_TIPS[line.variant[1]]]
				row.spell.label:SetText(SpellText(line.value))
				for _, toggle in ipairs(row.trinkets) do toggle:Hide() end
				row.count:Hide()
				row.spell:SetPoint("LEFT", row.key, "RIGHT", 4, 0)
				row.spell:SetPoint("RIGHT", row.clear, "LEFT", -4, 0)
				row.key:SetAlpha(1)
				row.spell:SetAlpha(1)
				row.clear.tip = L["Retirer cette variante"]
			elseif binding then
				row.clear.tip = L["Retirer ce raccourci"]
				-- en orange : le clic pour lancer du jeu prend aussi cette combinaison
				local game = binding.kind == "click" and conflicts[binding.key]
				row.key.label:SetText((game and "|cffff9933" or "") .. Z:TriggerLabel(binding))
				row.key.tip = game and L["Le clic pour lancer du jeu lance aussi %s avec cette combinaison, et peut passer avant Lyorune. Changez l'un des deux : cliquez ici pour une autre combinaison, ou retirez-la dans le clic pour lancer du jeu."]:format(game)
					or L["Changer ce raccourci : cliquez, puis faites la nouvelle combinaison. S'il était déjà pris, les deux sorts sont échangés."]
				row.spell.label:SetText(binding.value ~= "" and SpellText(binding.value) or "|cff" .. UI.Hex("dim") .. L["Sort"] .. "|r")
				-- Bijoux : montrés si « Bijoux avec les sorts » est allumé, ou si la ligne a déjà un bijou
				local trinkets = Z.TakesTrinket(binding.value) and (Z.db.trinketButtons or (binding.trinkets or 0) > 0)
				for index, toggle in ipairs(row.trinkets) do
					local on = Z.MaskHas(binding.trinkets, index)
					toggle:SetShown(trinkets)
					toggle.icon:SetTexture(TrinketIcon(Z.TRINKET_SLOTS[index], on))
					toggle.icon:SetAlpha(on and 1 or 0.6)
					toggle.chosen:SetShown(on)
				end
				row.spell:SetPoint("RIGHT", trinkets and row.trinkets[1] or row.add, "LEFT", -4, 0)
				-- Statistiques de mes clics (réglage clickStats) : nombre d'utilisations, ligne grisée si jamais utilisée
				local stats = Z.db.clickStats and not Z.db.externalClicks and binding.value ~= ""
				local count = stats and Z:ClickCount(binding, binding.value) or 0
				row.count:SetShown(stats)
				row.count.label:SetText(count)
				row.count.n = count
				row.spell:SetPoint("LEFT", stats and row.count or row.key, "RIGHT", 4, 0)
				row.key:SetAlpha((stats and count == 0) and 0.5 or 1)
				row.spell:SetAlpha((stats and count == 0) and 0.5 or 1)
			end
		end
		clickList.empty:SetShown(#bindings == 0)
		local height = math.max(1, #lines) * ROW_H
		clickList.list:SetHeight(height)
		Fit(clickList, top + height)
	end
	-- Macros pour les barres de sorts : une icône par macro tenue à jour par Lyorune
	if barBox then
		local macros = Z.db.actionBarMacros and Z:BarMacros() or {}
		for i = #barIcons + 1, #macros do barIcons[i] = barBox:NewIcon(i) end
		for i, icon in ipairs(barIcons) do
			local macro = macros[i]
			icon.macro = macro
			icon:SetShown(macro ~= nil)
			if macro then icon.texture:SetTexture(macro.icon or "Interface\\Icons\\INV_Misc_QuestionMark") end
		end
		Fit(barBox, #macros > 0 and math.ceil(#macros / barBox.perRow) * 32 - 4 or 1)
	end
	-- Spécialisation dont on voit les clics
	if specLine then
		local perSpec = Z.db.clicksPerSpec
		specLine.label:SetText(perSpec and L["Clics de la spécialisation %d"]:format(Z:SpecGroup()) or L["Mêmes clics dans toutes les spécialisations"])
		specLine.copy:SetShown(perSpec)
	end
	if UpdateFoot then UpdateFoot() end -- un clic changé, même en combat
end
-- Appelé aussi par ApplyClicks : la liste suit les changements faits ailleurs (macros, partage), si elle est visible
Z.RefreshClicks = function()
	if clickList and clickList:IsVisible() then RefreshClicks() end
	if UpdateFoot then UpdateFoot() end
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

-- Ligne des icônes de macros : une icône par macro de Lyorune, autant de rangées que nécessaire
local function BarIcons(page, width)
	barBox = CreateFrame("Frame", nil, page)
	barBox:SetSize(width, 1)
	barBox.perRow = math.max(1, math.floor((width + 4) / 32))
	barBox.NewIcon = function(self, i)
		local icon = CreateFrame("Button", nil, self)
		icon:SetSize(28, 28)
		icon:SetPoint("TOPLEFT", ((i - 1) % self.perRow) * 32, -math.floor((i - 1) / self.perRow) * 32)
		icon.texture = icon:CreateTexture(nil, "ARTWORK")
		icon.texture:SetAllPoints()
		icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		icon.border = UI.Border(icon, 1)
		icon:RegisterForDrag("LeftButton")
		icon:SetScript("OnClick", PickupBarMacro)
		icon:SetScript("OnDragStart", PickupBarMacro)
		icon:SetScript("OnEnter", function(button)
			button.border:SetColor(UI.accent[1], UI.accent[2], UI.accent[3])
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
			GameTooltip:SetText(button.macro.name, UI.accent[1], UI.accent[2], UI.accent[3])
			GameTooltip:AddLine(button.macro.body, 1, 1, 1)
			GameTooltip:AddLine(L["Cliquez, puis déposez dans une barre de sorts."], 0.6, 0.6, 0.65)
			GameTooltip:Show()
		end)
		icon:SetScript("OnLeave", function(button)
			button.border:SetColor(0, 0, 0)
			GameTooltip:Hide()
		end)
		return icon
	end
	barBox.Update = function() RefreshClicks() end
	barBox:SetScript("OnShow", barBox.Update)
	return barBox
end

-- Liste des rangs d'un sort (clic droit sur son icône dans la fenêtre de choix) : « le plus haut », puis chaque
-- rang appris avec son niveau d'apprentissage et son coût en mana ; la bulle du jeu au survol donne ses chiffres.
local ranks
local function OpenRanks(icon)
	if not ranks then
		ranks = UI.Window("LyoruneRanks", "", 280, 120)
		ranks:SetFrameStrata("FULLSCREEN_DIALOG")
		tinsert(UISpecialFrames, "LyoruneRanks")
		UI.OnTop(ranks)
		ranks.rows = {}
		ranks.hint = UI.Label(ranks, 11, nil, "dim")
		ranks.hint:SetWidth(252)
		ranks.hint:SetJustifyH("LEFT")
		picker:HookScript("OnHide", function() ranks:Hide() end)
	end
	local spell = icon.spell
	local list, hidden = Z.RankChoices(spell)
	ranks.title:SetText(spell.name)
	for i, choice in ipairs(list) do
		local row = ranks.rows[i]
		if not row then
			row = UI.Button(ranks, "", 252, 22, function(self) picker.Choose(self.value) end)
			row:SetPoint("TOPLEFT", 14, -42 - (i - 1) * 25)
			row:HookScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetSpellByID(self.id)
				GameTooltip:Show()
			end)
			ranks.rows[i] = row
		end
		row.value, row.id = choice.value, choice.id
		row.label:SetText(i == 1 and "|cff" .. UI.Hex("accent") .. choice.text .. "|r" or choice.text)
		row:Show()
	end
	for i = #list + 1, #ranks.rows do ranks.rows[i]:Hide() end
	local height = 42 + #list * 25
	-- rangs cachés par le grimoire du jeu : on dit comment les voir
	ranks.hint:SetShown(hidden)
	if hidden then
		ranks.hint:ClearAllPoints()
		ranks.hint:SetPoint("TOPLEFT", 14, -height - 4)
		ranks.hint:SetText(L["Les autres rangs sont cachés par le grimoire du jeu : dans le menu des réglages du grimoire, cochez l'option qui montre tous les rangs, puis rouvrez cette liste."])
		height = height + 8 + ranks.hint:GetStringHeight()
	end
	ranks:SetHeight(height + 16)
	ranks:ClearAllPoints()
	ranks:SetPoint("TOPLEFT", picker, "TOPRIGHT", 4, 0)
	ranks:Show()
	UI.Lift(ranks)
end

-- Fenêtre de choix d'un sort : une icône par sort connu. onChoose(valeur) reçoit le choix.
-- spellsOnly : seulement les sorts (pour l'assistant de macro), sans « Cibler », « Menu » ni macros.
-- side = "enemy" : les sorts offensifs (variante « Sur un ennemi »)
local function OpenPicker(title, onChoose, spellsOnly, side)
	if not picker then
		picker = UI.Window("LyorunePicker", "", 372, 200)
		picker:SetFrameStrata("FULLSCREEN_DIALOG")
		tinsert(UISpecialFrames, "LyorunePicker")
		UI.OnTop(picker) -- Échap ferme seulement cette fenêtre, pas les options ni Mes macros
		picker.icons = {}
		local function Choose(value)
			picker.onChoose(value)
			picker:Hide()
			RefreshClicks()
		end
		picker.Choose = Choose
		picker.actions = CreateFrame("Frame", nil, picker)
		picker.actions:SetPoint("TOPLEFT", 14, -42)
		picker.actions:SetSize(344, 48)
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
		local stop = UI.Button(picker.actions, L["Arrêter l'incantation"], 186, 22, function() Choose("@stop") end)
		stop:SetPoint("TOPLEFT", target, "BOTTOMLEFT", 0, -4)
		stop.label:SetJustifyH("CENTER")
		stop.tip = L["Interrompt le sort en cours, par exemple un long soin devenu inutile."]
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
	picker.title:SetText(title)
	picker.edit:SetText("")
	picker.actions:SetShown(not spellsOnly)

	-- Les sorts connus, puis les macros de ma bibliothèque
	local spells, macros = Z:KnownSpells(side), spellsOnly and {} or Z:GetMacros()
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
					if Z.db.rankChoice and (self.spell.top or 0) > 1 then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(L["Clic : le rang le plus haut. Clic droit : choisir un rang."], UI.accent[1], UI.accent[2], UI.accent[3], true)
						GameTooltip:Show()
					end
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
			icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			icon:SetScript("OnClick", function(self, mouse)
				-- clic droit sur un sort à plusieurs rangs : la liste des rangs ; sinon le rang le plus haut
				if mouse == "RightButton" and Z.db.rankChoice and self.spell and (self.spell.top or 0) > 1 then return OpenRanks(self) end
				picker.Choose(self.spell and self.spell.name or "@macro:" .. self.macro.name)
			end)
			-- chiffre du rang le plus haut, dans le coin : ce sort a plusieurs rangs (clic droit)
			icon.rank = UI.Text(icon, 10, "OUTLINE")
			icon.rank:SetPoint("BOTTOMRIGHT", -1, 2)
			picker.icons[index] = icon
		end
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", 14 + ((slot - 1) % perRow) * (size + 3), top - math.floor((slot - 1) / perRow) * (size + 3))
		icon:Show()
		return icon
	end

	local top = spellsOnly and -74 or -100 -- 2e ligne d'actions : « Arrêter l'incantation »
	for i, spell in ipairs(spells) do
		local icon = Place(i, i, top)
		icon.spell, icon.macro = spell, nil
		icon.texture:SetTexture(spell.icon)
		icon.rank:SetText(Z.db.rankChoice and (spell.top or 0) > 1 and spell.top or "")
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
			icon.rank:SetText("")
		end
		top = top - math.ceil(shown / perRow) * (size + 3)
	end
	for i = #spells + shown + 1, #picker.icons do picker.icons[i]:Hide() end

	picker:SetHeight(-top + 72)
	picker:ClearAllPoints()
	picker:SetPoint("CENTER", (spellsOnly or not window) and UIParent or window, "CENTER")
	picker:Show()
	UI.Lift(picker) -- déjà ouverte : repasse au-dessus
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
	-- Bouton caché pendant l'attente (autre chapitre, croix, options effacées) : l'attente est annulée et le
	-- clavier rendu, sinon la première touche tapée au retour deviendrait le raccourci
	button.cancelCapture = function() Finish(nil) end
	if not button.captureHooked then
		button.captureHooked = true
		button:HookScript("OnHide", function(self)
			if self.capturing then self.cancelCapture() end
		end)
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
	OpenPicker(Z:TriggerLabel(trigger), function(chosen) Z:SetBinding(trigger, chosen) end)
end

local function Trigger(row)
	return { kind = row.binding.kind, key = row.binding.key }
end

-- Ouvre la fenêtre de choix pour la variante « kind » d'un raccourci ; « value » est posé directement s'il est donné.
-- Sur un ennemi : les sorts offensifs ; hors combat : un sort seulement (une macro ne peut pas en lancer une autre).
local function ChooseVariant(trigger, kind, value)
	if value then
		if not Z.ValidVariant(kind[1], value) then return Z:Print(L["hors combat : un sort seulement, pas de macro."]) end
		Z:SetVariant(trigger, kind[1], value)
		return RefreshClicks()
	end
	OpenPicker(Z:TriggerLabel(trigger) .. " : " .. L[kind[2]]:lower(), function(chosen)
		if chosen == nil or Z.ValidVariant(kind[1], chosen) then Z:SetVariant(trigger, kind[1], chosen) end
	end, kind[1] == "ooc", kind[1] == "enemy" and "enemy" or nil)
end

-- Le « + » d'une ligne : la liste des variantes qu'elle n'a pas encore (menu du jeu ; sans lui, la première)
local function AddVariant(row)
	local trigger, have = Trigger(row), row.binding.variants or {}
	local missing = {}
	for _, kind in ipairs(Z.variantKinds) do
		local onPlayer = kind[1] == "ooc" or kind[1] == "tank" -- hors combat, sur un tank : un raccourci qui lance un sort
		if not have[kind[1]] and (not onPlayer or Z.TakesTrinket(row.binding.value)) then missing[#missing + 1] = kind end
	end
	if #missing == 0 then return end
	if not (MenuUtil and MenuUtil.CreateContextMenu) or #missing == 1 then return ChooseVariant(trigger, missing[1]) end
	MenuUtil.CreateContextMenu(row.add, function(_, root)
		root:CreateTitle(L["Ajouter une variante"])
		for _, kind in ipairs(missing) do
			root:CreateButton(L[kind[2]], function() ChooseVariant(trigger, kind) end)
		end
	end)
end

-- Une ligne de raccourci : déclencheur, sort, bijoux, retirer
function NewRow(i)
	local width = clickList.width
	local row = CreateFrame("Frame", nil, clickList.list)
	row:SetSize(width, 24)
	row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
	row.key = UI.Button(row, "", 150, 24, function(self)
		if self.capturing or GetTime() < (self.ignoreUntil or 0) or not row.binding or row.variant then return end
		local from = Trigger(row)
		CaptureTrigger(self, function(to)
			Z:MoveBinding(from, to)
			RefreshClicks()
		end)
	end)
	row.key:SetPoint("LEFT")
	row.key.label:SetJustifyH("CENTER")
	row.key.tip = L["Changer ce raccourci : cliquez, puis faites la nouvelle combinaison. S'il était déjà pris, les deux sorts sont échangés."]
	-- Nombre d'utilisations (statistiques de mes clics), caché sans le réglage
	row.count = CreateFrame("Frame", nil, row)
	row.count:SetSize(COUNT_W, 24)
	row.count:SetPoint("LEFT", row.key, "RIGHT", 4, 0)
	row.count.label = UI.Label(row.count, 11, nil, "dim")
	row.count.label:SetAllPoints()
	row.count.label:SetJustifyH("CENTER")
	row.count:SetScript("OnEnter", function(self)
		local since = Z:ClickStatsSince()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Utilisé %d fois"]:format(self.n or 0), 1, 1, 1)
		if since then GameTooltip:AddLine(L["Depuis le %s"]:format(date(L["%d/%m/%Y"], since)), 0.6, 0.64, 0.7) end
		GameTooltip:AddLine(L["Chaque clic compte, même si le sort échoue (hors de portée, en recharge)."], 0.6, 0.64, 0.7, true)
		GameTooltip:Show()
	end)
	row.count:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row.count:Hide()
	row.spell = UI.Button(row, "", width - 150 - 4 - 4 - 22, 24, function() -- bord droit : RefreshClicks
		if not row.binding then return end
		-- un sort ou une macro tenu sous la souris est posé directement
		if row.variant then return ChooseVariant(Trigger(row), row.variant, Z:TakeCursor()) end
		ChooseAction(Trigger(row), Z:TakeCursor())
	end)
	row.spell:SetPoint("LEFT", row.key, "RIGHT", 4, 0)
	row.spell.label:SetJustifyH("CENTER")
	Droppable(row.spell, function(value)
		if row.variant then
			if row.binding and Z.ValidVariant(row.variant[1], value) then Z:SetVariant(Trigger(row), row.variant[1], value) end
		elseif row.binding then
			Z:SetBinding(Trigger(row), value)
		end
	end)
	row.clear = UI.Button(row, "x", 22, 24, function()
		if not row.binding then return end
		if row.variant then Z:SetVariant(Trigger(row), row.variant[1], nil) else Z:SetBinding(Trigger(row), nil) end
		RefreshClicks()
	end)
	row.clear:SetPoint("RIGHT")
	-- « + » : ajouter une variante (sur un ennemi, en JcJ, sur un tank, hors combat)
	row.add = UI.Button(row, "+", 22, 24, function()
		if row.binding and not row.variant then AddVariant(row) end
	end)
	row.add:SetPoint("RIGHT", row.clear, "LEFT", -2, 0)
	row.add.label:SetJustifyH("CENTER")
	row.add.tip = L["Ajouter une variante : un autre sort sur un ennemi, en champ de bataille ou hors combat."]
	-- Bijou 1 (emplacement 13) et bijou 2 (emplacement 14), utilisés juste avant le sort : deux carrés à la hauteur
	-- de la ligne, posés de droite à gauche devant « x » ; bordure d'or quand le bijou est choisi
	row.trinkets = {}
	local anchor = row.add
	for index = #Z.TRINKET_SLOTS, 1, -1 do
		local slot = Z.TRINKET_SLOTS[index]
		local toggle = UI.Button(row, "", 24, 24, function()
			if row.binding then Z:ToggleTrinket(Trigger(row), index) RefreshClicks() end
		end)
		toggle:SetPoint("RIGHT", anchor, "LEFT", index == #Z.TRINKET_SLOTS and -4 or -2, 0)
		toggle.icon = toggle:CreateTexture(nil, "ARTWORK")
		toggle.icon:SetPoint("TOPLEFT", 2, -2)
		toggle.icon:SetPoint("BOTTOMRIGHT", -2, 2)
		toggle.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		toggle.chosen = UI.Paint(UI.Border(toggle, 2), "gold")
		toggle.chosen:Hide()
		toggle.tip = L["Bijou %d (emplacement %d) : utilisé juste avant le sort, sur un joueur vivant. Cliquez pour l'ajouter ou le retirer."]:format(index, slot)
		row.trinkets[index] = toggle
		anchor = toggle
	end
	row.clear.label:SetJustifyH("CENTER")
	row.clear.tip = L["Retirer ce raccourci"]
	return row
end

-- Spécialisation dont on voit les clics, et copie depuis l'autre
local function SpecLine(page, width)
	specLine = CreateFrame("Frame", nil, page)
	specLine:SetSize(width, 22)
	specLine.label = UI.Label(specLine, 12, nil, "accent")
	specLine.label:SetPoint("LEFT")
	specLine.copy = UI.Button(specLine, L["Copier l'autre spécialisation"], 220, 22, function()
		Z:CopyOtherSpec()
		RefreshClicks()
	end)
	specLine.copy:SetPoint("RIGHT")
	specLine.copy.label:SetJustifyH("CENTER")
	specLine.copy.tip = L["Remplace les clics et les touches de cette spécialisation par ceux de l'autre."]
	specLine.Update = function() RefreshClicks() end
	specLine:SetScript("OnShow", specLine.Update)
	return specLine
end

-- Mes clics : « Ajouter », le nouveau sort sans clic, puis une ligne par raccourci
local function ClickList(page, width)
	clickList = CreateFrame("Frame", nil, page)
	clickList:SetSize(width, 64)
	clickList.width = width

	-- Ajouter : on clique sur le bouton, puis on fait la combinaison voulue (clic, touche ou molette)
	local add = UI.Button(clickList, "", width, 28, function(self)
		if self.capturing or GetTime() < (self.ignoreUntil or 0) then return end
		local preset = self.preset
		self.preset = nil
		CaptureTrigger(self, function(trigger) ChooseAction(trigger, preset) end)
	end)
	add.idle = "+ " .. L["Ajouter un clic ou une touche"]
	add.label:SetText(add.idle)
	add.label:SetJustifyH("CENTER")
	add.tip = L["Cliquez, puis faites la combinaison voulue sur ce bouton : un clic (avec Alt, Ctrl, Maj...), une touche du clavier, un bouton de souris supplémentaire ou la molette. Échap : annuler."]
	add:SetPoint("TOPLEFT")
	Register(page, L["Ajouter un clic ou une touche"], add)
	Register(page, L["Touches au survol"], add)
	clickList.add = add

	-- Nouveau sort appris, sans aucun raccourci (option « newSpellAlert »)
	local banner = CreateFrame("Frame", nil, clickList)
	banner:SetSize(width, 26)
	banner:SetPoint("TOPLEFT", 0, -34)
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
	banner.assign.tip = L["Puis, sur le bouton « Ajouter », faites le clic ou la touche qui lancera ce sort."]
	banner:Hide()
	clickList.banner = banner

	-- La liste : toutes les lignes, la page défile
	clickList.list = CreateFrame("Frame", nil, clickList)
	clickList.list:SetSize(width, ROW_H)
	clickList.list:SetPoint("TOPLEFT", 0, -36)
	local empty = UI.Label(clickList.list, 11, nil, "dim")
	empty:SetPoint("TOPLEFT", 4, -6)
	empty:SetWidth(width - 8)
	empty:SetJustifyH("LEFT")
	empty:SetText(L["Aucun raccourci pour l'instant : cliquez sur « Ajouter », puis faites un clic ou appuyez sur une touche."])
	clickList.empty = empty

	clickList.Update = function()
		Z:CheckNewSpells()
		RefreshClicks()
	end
	clickList:SetScript("OnShow", clickList.Update)
	RefreshClicks()
	return clickList
end

----------------------------------------------------------------------------------------------------
-- Annonces et sons (chapitre Alertes) : le texte d'une annonce et son essai, la règle de la mana
----------------------------------------------------------------------------------------------------
local function AlertText(textKey, test, dep)
	return { "custom", function(page, width)
		local line = CreateFrame("Frame", nil, page)
		line:SetSize(width, 22)
		local edit = UI.Edit(line, width - 90)
		edit:SetPoint("LEFT")
		edit:SetMaxLetters(120)
		edit:HookScript("OnTextChanged", function(self, byUser)
			if byUser and self:GetText():match("%S") then
				Z.db[textKey] = self:GetText()
				UpdateFoot() -- « Annuler mes changements » paraît (texte à part, hors de Option)
			end
		end)
		local button = UI.Button(line, L["Tester"], 80, 22, test)
		button:SetPoint("RIGHT")
		button.label:SetJustifyH("CENTER")
		line.edit, line.test = edit, button
		line.Update = function()
			if not edit.focused then edit:SetText(Z.db[textKey]) end
		end
		line:SetScript("OnShow", line.Update)
		line:Update()
		return line
	end, dep = dep }
end

-- WoW Forever cache ma mana aux addons : le sort qui sert de règle (Alerts.lua)
local function RulerNote(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 20)
	box.text = UI.Label(box, 11, nil, "dim")
	box.text:SetPoint("TOPLEFT")
	box.text:SetWidth(width)
	box.text:SetJustifyH("LEFT")
	box.text:SetSpacing(3)
	box.Update = function(self)
		self.text:SetText(Z:ManaRulerText())
		Fit(self, math.ceil(self.text:GetStringHeight()) + 2)
	end
	box:SetScript("OnShow", box.Update)
	box:Update()
	return box
end

----------------------------------------------------------------------------------------------------
-- Chapitre Profils et partage : une ligne dessinée à part par outil, en une colonne. Chaque outil écrit sa
-- réussite ou son échec juste dessous.
----------------------------------------------------------------------------------------------------
local GOOD, BAD = "|cff33dd88", "|cffff5555"

local function Say(label, ok, message)
	label:SetText((ok and GOOD or BAD) .. message .. "|r")
end

-- Ligne de message sous un outil
local function Result(box, y, width)
	local result = UI.Label(box, 11)
	result:SetPoint("TOPLEFT", 0, y)
	result:SetWidth(width)
	result:SetJustifyH("LEFT")
	return result
end

-- Bouton à confirmer : un premier clic l'arme (texte rouge pendant 4 secondes), le second agit.
-- Chaque armement a son numéro : un délai ne désarme que le sien (armé, confirmé puis réarmé avant la fin des
-- 4 secondes, le bouton reste armé ses 4 secondes). Donné aussi aux autres fenêtres (Z.ArmedButton).
local function ArmedButton(parent, text, armed, width, onConfirm)
	local button
	button = UI.Button(parent, L[text], width, 24, function(self)
		self.arming = (self.arming or 0) + 1
		if not self.armed then
			self.armed = true
			self.label:SetText(BAD .. L[armed] .. "|r")
			local mine = self.arming
			C_Timer.After(4, function()
				if button.arming ~= mine then return end -- confirmé ou réarmé depuis
				button.armed = false
				button.label:SetText(L[text])
			end)
			return
		end
		self.armed = false
		self.label:SetText(L[text])
		onConfirm()
	end)
	button.label:SetJustifyH("CENTER")
	-- Désarme tout de suite (la chose visée a changé : une autre macro choisie)
	function button.Disarm()
		button.arming = (button.arming or 0) + 1
		button.armed = false
		button.label:SetText(L[text])
	end
	return button
end
Z.ArmedButton = ArmedButton

-- Fenêtre « Copier une partie » (#44) : de quel profil, vers lequel, et quelles parties (un chapitre chacune)
local copyWindow
local function OpenCopyWindow(onDone)
	if copyWindow then
		if copyWindow:IsShown() then return copyWindow:Close() end
		copyWindow:Show()
		return
	end
	local w = UI.Window("LyoruneProfileCopy", L["Copier une partie d'un profil"], 320, 300)
	w:SetFrameStrata("FULLSCREEN_DIALOG")
	w.beside = true -- à côté des options, sans les recouvrir
	tinsert(UISpecialFrames, "LyoruneProfileCopy")
	copyWindow = w
	local from, to, parts = false, false, {}
	local fromChoices, toChoices = {}, {}
	local function Fill(list)
		wipe(list)
		for _, name in ipairs(Z:ProfileNames()) do list[#list + 1] = { name, name } end
		if #list == 0 then list[1] = { false, L["(aucun)"] } end
	end
	Fill(fromChoices) Fill(toChoices) -- jamais vides : le sélecteur affiche tout de suite un choix
	w.from = UI.Cycle(w, L["De"], fromChoices, function() return from end, function(value) from = value end)
	w.from:SetWidth(288)
	w.from:SetPoint("TOPLEFT", 16, -48)
	w.to = UI.Cycle(w, L["Vers"], toChoices, function() return to end, function(value) to = value end)
	w.to:SetWidth(288)
	w.to:SetPoint("TOPLEFT", 16, -78)
	local hint = UI.Label(w, 11, nil, "dim")
	hint:SetPoint("TOPLEFT", 16, -112)
	hint:SetWidth(288)
	hint:SetJustifyH("LEFT")
	hint:SetText(L["Parties à copier : les réglages du chapitre du même nom."])
	w.parts = {}
	for i, part in ipairs(Z.profileParts) do
		local check = UI.Check(w, L[part], function() return parts[part] end, function(value) parts[part] = value or nil end)
		check:SetWidth(140)
		check:SetPoint("TOPLEFT", 16 + ((i - 1) % 2) * 148, -136 - math.floor((i - 1) / 2) * 26)
		w.parts[part] = check
	end
	local result = UI.Label(w, 11)
	result:SetPoint("TOPLEFT", 16, -256)
	result:SetWidth(288)
	result:SetJustifyH("LEFT")
	w.result = result
	w.copy = UI.Button(w, L["Copier"], 288, 24, function()
		local ok, message = Z:CopyProfileParts(from, to, parts)
		Say(result, ok, message)
		if ok and onDone then onDone() end
	end)
	w.copy:SetPoint("TOPLEFT", 16, -222)
	w.copy.label:SetJustifyH("CENTER")
	w.copy.tip = L["Le profil d'arrivée prend ces réglages ; ses autres parties ne changent pas. Si c'est le profil en cours, les cadres changent tout de suite."]
	w:HookScript("OnShow", function()
		Fill(fromChoices) Fill(toChoices)
		local names = Z:ProfileNames()
		if not (from and Z.db.profiles[from]) then from = Z.db.profiles[Z.db.activeProfile] and Z.db.activeProfile or names[1] or false end
		if not (to and Z.db.profiles[to]) or to == from then
			to = false
			for _, name in ipairs(names) do if name ~= from then to = name break end end
		end
		w.from:Update() w.to:Update()
		for _, check in pairs(w.parts) do check:Update() end
		result:SetText("")
	end)
	w:Show()
end

-- Pour les tests
function Z:ProfileCopyWindow()
	return copyWindow
end

-- Un profil chargé tout seul (Share.lua) : la page ouverte suit
Z.RefreshProfiles = function() RefreshShownPages() end

-- Mes profils (#24) : choisir, charger, supprimer, copier une partie, enregistrer sous un nom
local function ProfileBox(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 136)
	local choices, selected = { { false, L["(aucun)"] } }, false -- remplie par Update
	local picker = UI.Cycle(box, L["Profil"], choices, function() return selected end, function(value) selected = value end)
	picker:SetWidth(width)
	picker:SetPoint("TOPLEFT")
	local result = Result(box, -118, width)

	local load = UI.Button(box, L["Charger"], 120, 24, function()
		if selected and Z:LoadProfile(selected) then
			RefreshShownPages()
			Say(result, true, L["Profil « %s » chargé."]:format(selected))
		end
	end)
	load:SetPoint("TOPLEFT", 0, -32)
	load.label:SetJustifyH("CENTER")
	local delete = ArmedButton(box, "Supprimer", "Confirmer", 120, function()
		if not selected then return end
		Z:DeleteProfile(selected)
		Say(result, true, L["Profil « %s » supprimé."]:format(selected))
		selected = nil
		RefreshShownPages()
	end)
	delete:SetPoint("TOPLEFT", 126, -32)
	local copy = UI.Button(box, L["Copier..."], 160, 24, function() OpenCopyWindow(RefreshShownPages) end)
	copy:SetPoint("TOPLEFT", 252, -32)
	copy.label:SetJustifyH("CENTER")
	copy.tip = L["Copier seulement une partie d'un profil vers un autre : un ou plusieurs chapitres, de Disposition à Joueurs."]
	Register(page, L["Copier une partie d'un profil"], copy)
	box.copyButton = copy

	local name
	local function Save()
		local ok, message = Z:SaveProfile(name:GetText())
		Say(result, ok, message)
		if ok then
			selected = Z.ProfileName(name:GetText())
			name:SetText("")
		end
		RefreshShownPages()
	end
	name = UI.Edit(box, 246, Save)
	name:SetPoint("TOPLEFT", 0, -64)
	Placeholder(name, "Nom du profil")
	box.edit = name
	local save = UI.Button(box, L["Enregistrer sous"], 160, 22, Save)
	save:SetPoint("LEFT", name, "RIGHT", 6, 0)
	save.label:SetJustifyH("CENTER")
	save.tip = L["Tapez un nom, puis Enregistrer sous : vos réglages d'apparence du moment deviennent ce profil (nouveau, ou remplacé)."]
	Register(page, L["Enregistrer sous"], save)

	local status = Note(box, "", 0, -96, width)
	box.Update = function()
		wipe(choices)
		for _, n in ipairs(Z:ProfileNames()) do choices[#choices + 1] = { n, n } end
		if #choices == 0 then choices[1] = { false, L["(aucun)"] } end
		if not (selected and Z.db.profiles[selected]) then
			selected = Z.db.profiles[Z.db.activeProfile] and Z.db.activeProfile or choices[1][1]
		end
		picker:Update()
		local active = Z.db.activeProfile ~= "" and Z.db.activeProfile or L["aucun"]
		status:SetText(L["Profil en cours : %s"]:format("|cff" .. UI.Hex("text") .. active .. "|r"))
	end
	box:SetScript("OnShow", box.Update)
	box:Update()
	Register(page, L["Mes profils"], box)
	return box
end

-- Profils automatiques : une ligne par situation (taille du groupe, champ de bataille), une colonne par
-- spécialisation. Clic : profil suivant, clic droit : précédent.
local SIZE_LABELS = { ["5"] = "Seul, 5", ["10"] = "10 joueurs", ["25"] = "25 joueurs", ["40"] = "40 joueurs", BG = "Champ de bataille" }

local function ProfileGrid(page, width)
	local grid = CreateFrame("Frame", nil, page)
	local LABEL_W = 150
	local CELL_W = math.floor((width - LABEL_W - 6) / 2)
	grid:SetSize(width, 18 + #Z.profileSizes * 24)
	for group = 1, 2 do
		local head = UI.Label(grid, 11, nil, "accent")
		head:SetPoint("TOPLEFT", LABEL_W + (group - 1) * (CELL_W + 6), 0)
		head:SetWidth(CELL_W)
		head:SetJustifyH("CENTER")
		head:SetText(L["Spé. %d"]:format(group))
	end
	local CLICK_HINT = L["Clic : profil suivant, clic droit : précédent."]
	local cells = {}
	for i, size in ipairs(Z.profileSizes) do
		local y = -16 - (i - 1) * 24
		local label = UI.Label(grid, 11)
		label:SetPoint("TOPLEFT", 0, y - 5)
		label:SetText(L[SIZE_LABELS[size]])
		for group = 1, 2 do
			local cell = UI.Button(grid, "", CELL_W, 22, function(self, mouseButton)
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
				UpdateFoot() -- « Annuler mes changements » paraît, même si aucun profil ne change tout de suite
			end)
			cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			cell:SetPoint("TOPLEFT", LABEL_W + (group - 1) * (CELL_W + 6), y)
			cell.label:SetJustifyH("CENTER")
			cell.Update = function(self)
				local wanted = Z:ProfileRules(group)[size]
				local pvp = size == "BG"
				self.label:SetText(wanted or (group == 2 and L["comme 1"] or pvp and L["selon la taille"] or "-"))
				if wanted then
					self.tip = wanted
				elseif group == 2 then
					self.tip = L["Rien de choisi : le profil de la spécialisation 1 s'applique."]
				elseif pvp then
					self.tip = L["Rien de choisi : le profil prévu pour la taille du groupe s'applique."]
				else
					self.tip = L["Aucun profil : les réglages du moment restent."]
				end
				self.tip = self.tip .. "\n|cff" .. UI.Hex("dim") .. CLICK_HINT .. "|r" -- suit le thème
			end
			cell.size, cell.group = size, group
			cells[#cells + 1] = cell
		end
	end
	grid.profileCells = cells
	grid.Update = function()
		for _, cell in ipairs(cells) do cell:Update() end
	end
	grid:SetScript("OnShow", grid.Update)
	grid:Update()
	Register(page, L["Profils automatiques"], grid)
	return grid
end

-- Profils prêts à l'emploi : trois boutons par rangée
local function PresetButtons(page, width)
	local box = CreateFrame("Frame", nil, page)
	local each = math.floor((width - 12) / 3)
	box:SetSize(width, math.ceil(#Z.presets / 3) * 29 - 5)
	for i, preset in ipairs(Z.presets) do
		local button = UI.Button(box, L[preset[2]], each, 24, function()
			Z:ApplyPreset(preset[1])
			RefreshShownPages()
		end)
		button:SetPoint("TOPLEFT", ((i - 1) % 3) * (each + 6), -math.floor((i - 1) / 3) * 29)
		button.label:SetJustifyH("CENTER")
	end
	Register(page, L["Profils prêts à l'emploi"], box)
	return box
end

-- Donner ma configuration : le code à copier, ou l'envoi direct à un joueur qui a Lyorune
local function ExportBox(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 118)
	Note(box, "Code à copier (Ctrl+C) et à envoyer : chuchotement, Discord...", 0, 0, width)
	local export = UI.Edit(box, width)
	export:SetPoint("TOPLEFT", 0, -20)
	box.Update = function()
		export:SetText(Z:Export())
		export:SetCursorPosition(0)
	end
	export:HookScript("OnTextChanged", function(_, byUser)
		if byUser then box:Update() end -- le code n'est pas modifiable à la main
	end)
	Note(box, "Ou envoi direct à un joueur qui a Lyorune (il devra accepter) :", 0, -52, width)
	local target = UI.Edit(box, 246)
	target:SetPoint("TOPLEFT", 0, -72)
	Placeholder(target, "Nom du joueur")
	local result = Result(box, -102, width)
	local send = UI.Button(box, L["Envoyer"], 160, 22, function()
		Say(result, Z:SendConfig(target:GetText()))
	end)
	send:SetPoint("LEFT", target, "RIGHT", 6, 0)
	send.label:SetJustifyH("CENTER")
	box:SetScript("OnShow", box.Update)
	box:Update()
	Register(page, L["Donner ma configuration"], box)
	return box
end

-- Recevoir une configuration : coller le code, puis Importer
local function ImportBox(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 66)
	Note(box, "Collez le code reçu (Ctrl+V), puis Importer. Votre position à l'écran est conservée.", 0, 0, width)
	local result = Result(box, -50, width)
	local import
	local function DoImport()
		local ok, message = Z:Import(import:GetText())
		if ok then
			import:SetText("")
			RefreshShownPages() -- le code à donner, la synchronisation, « Annuler l'import »
		end
		Say(result, ok, message)
	end
	import = UI.Edit(box, width - 166, DoImport)
	import:SetPoint("TOPLEFT", 0, -20)
	local button = UI.Button(box, L["Importer"], 160, 22, DoImport)
	button:SetPoint("LEFT", import, "RIGHT", 6, 0)
	button.label:SetJustifyH("CENTER")
	box.import = import
	Register(page, L["Recevoir une configuration"], box)
	return box
end

-- Entre joueurs (#29) : les joueurs du groupe qui ont Lyorune (le nombre, et la liste au survol). Les réglages
-- placés sous l'interrupteur général sont grisés quand il est coupé, comme tout réglage dépendant (dep).
local function SyncWho(page, width)
	local who = CreateFrame("Frame", nil, page)
	who:SetSize(width, 18)
	who.text = Note(who, "", 0, -2, width)
	who:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L["Avec Lyorune dans le groupe"], 1, 1, 1)
		for _, entry in ipairs(Z:SyncMembers()) do GameTooltip:AddDoubleLine(entry.name, entry.version, 0.8, 0.8, 0.8, 0.45, 1, 0.55) end
		GameTooltip:Show()
	end)
	who:SetScript("OnLeave", function() GameTooltip:Hide() end)
	who.Update = function()
		local on = Z.db.syncEnabled
		local count = on and IsInGroup() and #Z:SyncMembers() or 0
		who.text:SetText(not on and L["Synchronisation coupée."] or count == 0 and L["Pas de groupe : personne avec qui se synchroniser."]
			or (L["Avec Lyorune dans le groupe : %d (survolez)."]):format(count))
	end
	local master = page.settings and page.settings.syncEnabled
	if master then master:HookScript("OnClick", who.Update) end
	who:SetScript("OnShow", who.Update)
	-- Le groupe change, ou un joueur annonce sa version (Comm.lua), page ouverte : le nombre suit.
	-- Rien n'est fait quand la ligne n'est pas à l'écran.
	Z.RefreshSyncWho = function() if who:IsVisible() then who:Update() end end
	Z:OnRosterSettled(Z.RefreshSyncWho)
	who:Update()
	return who
end

-- Remise à zéro : clics de la classe, tous les réglages, ou l'annulation du dernier import (#29)
local function ResetBox(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 76)
	local result = Result(box, -60, width)
	local HALF = 240
	-- Remplace tous les clics de la spécialisation : à confirmer, et « Annuler mes changements » paraît
	local clicks = ArmedButton(box, "Reprendre les clics proposés pour ma classe", "Cliquez encore pour confirmer", 2 * HALF + 6,
		function()
			Z:ResetClassClicks()
			RefreshShownPages()
			Say(result, true, L["Clics de la classe rétablis."])
		end)
	clicks:SetPoint("TOPLEFT")
	box.classClicks = clicks
	Register(page, L["Reprendre les clics proposés pour ma classe"], clicks)
	local reset = ArmedButton(box, "Tout réinitialiser", "Cliquez encore pour confirmer", HALF, function()
		Z:ResetAll()
		RefreshShownPages()
		Say(result, true, L["Tous les réglages sont revenus à l'origine."])
	end)
	reset:SetPoint("TOPLEFT", 0, -30)
	reset.tip = L["Remet tous les réglages d'origine. La position des cadres et vos profils enregistrés sont conservés."]
	Register(page, L["Tout réinitialiser"], reset)
	-- Sauvegarde avant import : grisé tant qu'aucun import n'a eu lieu
	local undo = UI.Button(box, L["Annuler l'import"], HALF, 24, function()
		local ok, message = Z:UndoImport()
		if ok then RefreshShownPages() end
		Say(result, ok, message)
	end)
	undo:SetPoint("LEFT", reset, "RIGHT", 6, 0)
	undo.label:SetJustifyH("CENTER")
	undo.tip = L["Remet la configuration d'avant le dernier import (code collé ou configuration reçue). Aussi : /lyorune annuler."]
	Register(page, L["Annuler l'import"], undo)
	box.undo = undo
	box.Update = function()
		undo:SetAlpha(Z:CanUndoImport() and 1 or 0.4)
		undo:EnableMouse(Z:CanUndoImport())
	end
	box:SetScript("OnShow", box.Update)
	box:Update()
	return box
end

----------------------------------------------------------------------------------------------------
-- Lire une case et commandes (chapitre Fenêtre et aide)
----------------------------------------------------------------------------------------------------
local LEGEND = {
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

local function Legend(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, #LEGEND * 21)
	for i, entry in ipairs(LEGEND) do
		local square = UI.Tex(box, "ARTWORK", entry[1][1], entry[1][2], entry[1][3])
		square:SetSize(12, 12)
		square:SetPoint("TOPLEFT", 2, -4 - (i - 1) * 21)
		local text = UI.Text(box, 12)
		text:SetPoint("LEFT", square, "RIGHT", 10, 0)
		text:SetText(L[entry[2]])
	end
	Register(page, L["Lire une case"], box)
	return box
end

-- Les commandes prennent la couleur d'accent du thème de fenêtre
local COMMANDS = {
	{ "", "ouvrir cette fenêtre" }, { " test", "mode test (faux groupe)" }, { " tuto", "relancer le tutoriel" },
	{ " assistant", "assistant de départ" }, { " verrou", "verrouiller ou libérer la position" },
	{ " epingler", "épingler ou retirer le joueur survolé" }, { " porteur", "le joueur survolé reçoit mes buffs uniques" },
	{ " pourmoi", "ajouter ou retirer le joueur survolé de mes joueurs" }, { " repartir", "répartir les soigneurs (chef ou assistant)" },
	{ " cadres", "afficher ou masquer les cadres" }, { " sorts", "quels sorts Lyorune propose, et pourquoi un sort manque" }, { " buffs", "buffs lisibles ici, ou cachés par le jeu" }, { " groupe", "qui a Lyorune dans le groupe" }, { " annuler", "annuler le dernier import" },
	{ " mesure", "mesurer les performances" }, { " bug", "signaler un bug" }, { " diag", "compatibilité avec le jeu" },
}

local function CommandList(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 20)
	local list = UI.Label(box, 12)
	list:SetPoint("TOPLEFT")
	list:SetWidth(width)
	list:SetJustifyH("LEFT")
	list:SetSpacing(4)
	box.list = list
	box.Update = function()
		local c, lines = "|cff" .. UI.Hex("accent"), {}
		for i, command in ipairs(COMMANDS) do lines[i] = c .. "/lyorune" .. command[1] .. "|r  " .. L[command[2]] end
		-- les raccourcis du jeu (Bindings.xml) : où les trouver, aucune touche n'étant posée au départ
		lines[#lines + 1] = "\n" .. L["Touches au choix dans les raccourcis du jeu (Échap, Options, Raccourcis, AddOns, Lyorune) : ouvrir les options, afficher ou masquer les cadres, poser le prochain buff manquant, mode test. Aucune touche au départ."]
		list:SetText(table.concat(lines, "\n"))
		Fit(box, math.ceil(list:GetStringHeight()) + 2)
	end
	UI.OnSkin(box.Update)
	box:Update()
	Register(page, L["Commandes"], box)
	return box
end

----------------------------------------------------------------------------------------------------
-- Accueil : le profil en cours, les réglages changés, de quoi bien commencer
----------------------------------------------------------------------------------------------------
-- Chaque réglage décrit dans les chapitres : fonction(ligne, numéro du chapitre, chapitre)
local function EachSetting(list, fn)
	for i, chapter in ipairs(list) do
		for _, section in ipairs(chapter.sections) do
			for _, item in ipairs(section[2]) do
				if SETTING_KINDS[item[1]] then fn(item, i, chapter) end
			end
		end
	end
end

-- Un réglage n'est plus celui de l'installation (rune d'or, pastille, liste de l'Accueil)
local function IsChanged(key)
	return Z.defaults[key] ~= nil and not UI.Same(Z.db[key], Z.defaults[key])
end

-- Un réglage dépendant a-t-il un effet ? dep = { cle, v } : le réglage cle vaut v ("!v" : tout sauf v)
local function DepOk(dep)
	local want, have = dep[2], Z.db[dep[1]]
	if type(want) == "string" and want:sub(1, 1) == "!" then return have ~= want:sub(2) end
	return have == want
end

-- Nombre de réglages changés d'un chapitre (pastille de la barre latérale)
local function ChapterChanges(chapter)
	local count = 0
	EachSetting({ chapter }, function(item) if IsChanged(item[2]) then count = count + 1 end end)
	return count
end

-- Profil actif : son nom, comment il a été choisi, et un bouton vers le chapitre Profils et partage
local function ActiveProfile(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 44)
	box.rune = UI.Paint(UI.Rune(box, "ARTWORK", 20, 30), "gold")
	box.rune:SetPoint("LEFT", 2, 0)
	box.name = UI.Label(box, 13)
	box.name:SetPoint("TOPLEFT", 44, -4)
	box.desc = UI.Label(box, 11, nil, "dim")
	box.desc:SetPoint("TOPLEFT", 44, -24)
	box.desc:SetWidth(width - 44 - 166)
	box.desc:SetJustifyH("LEFT")
	box.go = UI.Button(box, L["Changer de profil"], 160, 24, function() Z:ToggleOptions("Profils et partage") end)
	box.go:SetPoint("RIGHT")
	box.go.label:SetJustifyH("CENTER")
	box.Update = function(self)
		local active = Z.db.activeProfile
		if active ~= "" and Z.db.profiles[active] then
			self.name:SetText(active)
			self.desc:SetText(L[Z.db.autoProfile and "Changé tout seul selon la taille du groupe et votre spécialisation."
				or "Choisi à la main : il ne change que si vous en chargez un autre."])
		else
			self.name:SetText(L["Aucun profil"])
			self.desc:SetText(L["Vos réglages du moment ne portent aucun nom."])
		end
	end
	box:SetScript("OnShow", box.Update)
	box:Update()
	Register(page, L["Profil actif"], box)
	return box
end

-- Vos réglages changés : un clic sur le nom mène au réglage, un clic sur la rune d'or le rétablit
local CHANGED_H = 24

local function ChangedRow(box, width)
	local row = UI.Button(box, "", width - 24, 22, function(self) window.GoToSetting(self.key, self.chapter) end)
	row.label:ClearAllPoints()
	row.label:SetPoint("LEFT", 6, 0)
	row.label:SetWidth(270)
	row.label:SetJustifyH("LEFT")
	row.value = UI.Label(row, 11, nil, "accent")
	row.value:SetPoint("LEFT", 282, 0)
	row.value:SetWidth(104) -- s'arrête à 386 : le nom du chapitre commence à 390 (ligne de 496)
	row.value:SetJustifyH("LEFT")
	row.value:SetWordWrap(false)
	row.where = UI.Label(row, 11, nil, "dim")
	row.where:SetPoint("RIGHT", -6, 0)
	row.where:SetWidth(100)
	row.where:SetJustifyH("RIGHT")
	row.where:SetWordWrap(false)
	row.tip = L["Aller au réglage"]
	local function Get() return Z.db[row.key] end
	local function Set(value) select(2, Option(row.key))(value) end
	row.rune = UI.ChangedRune(row, row.key, Get, Set, nil, function(value) return ValueText(row.item, value) end)
	row.Update = function() box:Update() end -- rétabli : la liste se range de nouveau
	return row
end

local function ChangedList(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 40)
	box.empty = Note(box, "Aucun pour l'instant : Lyorune est réglé comme à l'installation. Changez un réglage dans un chapitre, il apparaîtra ici.", 0, -2, width)
	box.rows = {}
	box.Update = function(self)
		local list = {}
		EachSetting(chapters, function(item, index)
			if IsChanged(item[2]) then
				list[#list + 1] = { item = item, chapter = index }
			end
		end)
		for i, entry in ipairs(list) do
			local row = self.rows[i] or ChangedRow(self, width)
			self.rows[i] = row
			row.key, row.chapter, row.item = entry.item[2], entry.chapter, entry.item
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 24, -(i - 1) * CHANGED_H)
			row.label:SetText(L[entry.item[3]])
			row.value:SetText(ValueText(entry.item, Z.db[row.key]))
			row.where:SetText(L[chapters[entry.chapter].name])
			row.rune.key = row.key
			row.rune:Update()
			row:Show()
		end
		for i = #list + 1, #self.rows do self.rows[i]:Hide() end
		self.empty:SetShown(#list == 0)
		self.count = #list
		Fit(self, #list == 0 and 40 or #list * CHANGED_H)
	end
	box:SetScript("OnShow", box.Update)
	box:Update()
	Register(page, L["Vos réglages changés"], box)
	return box
end

----------------------------------------------------------------------------------------------------
-- Les amis de Lyorune : chiffres du projet (About.lua, écrits à chaque publication), mon carnet (Tally.lua),
-- un mot de l'auteur et le mur de remerciements (noms donnés par l'auteur, joueurs d'accord seulement)
----------------------------------------------------------------------------------------------------
local DISCORD = "discord.gg/uRaEPTGePu"

local Grouped = Z.Grouped -- 12345 -> "12 345" (Tally.lua)

-- "2026-11-23" -> "23/11/2026"
local function Day(iso)
	local y, m, d = tostring(iso or ""):match("^(%d+)-(%d+)-(%d+)$")
	return y and (d .. "/" .. m .. "/" .. y) or tostring(iso or "")
end

-- Une plaque : rune dorée, chiffre, mot
local PLAQUE_H = 74
local function Plaque(box, rune, label, width)
	local p = CreateFrame("Frame", nil, box)
	p:SetSize(width, PLAQUE_H)
	p.bg = UI.Paint(UI.Tex(p, "BACKGROUND"), "panel")
	p.bg:SetAllPoints()
	p.border = UI.Paint(UI.Border(p, 1), "line")
	p.rune = UI.Paint(UI.Rune(p, "ARTWORK", rune, 22), "gold")
	p.rune:SetPoint("TOP", 0, -8)
	p.value = UI.Label(p, 18, nil, "accent")
	p.value:SetPoint("TOP", 0, -32)
	p.label = UI.Label(p, 11, nil, "dim")
	p.label:SetPoint("TOP", 0, -55)
	p.label:SetText(L[label])
	return p
end

local function FriendsNumbers(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, PLAQUE_H + 62)
	local each = math.floor((width - 20) / 3)
	box.updates = Plaque(box, 12, "mises à jour", each)
	box.updates:SetPoint("TOPLEFT")
	box.downloads = Plaque(box, 6, "téléchargements", each)
	box.downloads:SetPoint("TOPLEFT", each + 10, 0)
	box.discord = Plaque(box, 8, "sur le Discord", each)
	box.discord:SetPoint("TOPLEFT", 2 * (each + 10), 0)
	box.when = UI.Label(box, 11, nil, "dim")
	box.when:SetPoint("TOPLEFT", 0, -PLAQUE_H - 8)
	box.when:SetWidth(width)
	box.when:SetJustifyH("LEFT")
	-- Lien du Discord à copier (un addon ne peut pas ouvrir de page)
	box.linkLabel = UI.Label(box, 12)
	box.linkLabel:SetPoint("TOPLEFT", 0, -PLAQUE_H - 34)
	box.linkLabel:SetText(L["Discord de Lyorune (Ctrl+C) :"])
	box.link = UI.Edit(box, 220)
	box.link:SetPoint("LEFT", box.linkLabel, "RIGHT", 8, 0)
	box.link:SetText(DISCORD)
	box.link:SetScript("OnTextChanged", function(self)
		if self:GetText() ~= DISCORD then self:SetText(DISCORD) self:HighlightText() end
	end)
	box.Update = function(self)
		local about = Z.about or {}
		self.updates.value:SetText(Grouped(#(Z.changes or {})))
		self.downloads.value:SetText(Grouped((about.github or 0) + (about.curseforge or 0)))
		self.discord.value:SetText(Grouped(about.discord or 0))
		self.when:SetText(L["Chiffres du %s (GitHub et CurseForge), mis à jour à chaque version de Lyorune."]:format(Day(about.date)))
	end
	box:SetScript("OnShow", box.Update)
	box:Update()
	Register(page, L["Lyorune en chiffres"], box)
	return box
end

-- Canal des soigneurs (Channels.lua) : à quoi il sert, les règles en trois lignes, puis où écrire dans chaque canal rejoint
local CHANNEL_RULES = {
	"Ouverts à tous, quelle que soit la langue de votre jeu : le français, l'anglais ou les deux, à votre choix.",
	"Entraide et bienveillance entre soigneurs de tous niveaux, et Lyorune bien sûr. Ni publicité, ni vente, ni insulte.",
	"Lyorune n'y écrit jamais à votre place. Un gêneur ? Clic droit sur son nom : Ignorer ou Signaler, comme partout dans le jeu.",
}

local function ChannelBox(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 20)
	box.intro = UI.Label(box, 12)
	box.intro:SetPoint("TOPLEFT", 4, 0)
	box.intro:SetWidth(width - 8)
	box.intro:SetJustifyH("LEFT")
	box.intro:SetSpacing(3)
	box.intro:SetText(L["Un lieu pour que les soigneurs échangent entre eux : vos façons de jouer, vos spécialisations et vos talents, vos astuces de placement ou de mana, vos difficultés comme vos réussites. Débutant ou vétéran, chacun y apprend des autres."])
	box.rules = UI.Label(box, 11, nil, "dim")
	box.rules:SetPoint("TOPLEFT", box.intro, "BOTTOMLEFT", 0, -8)
	box.rules:SetWidth(width - 8)
	box.rules:SetJustifyH("LEFT")
	box.rules:SetSpacing(3)
	local lines = {}
	for i, rule in ipairs(CHANNEL_RULES) do lines[i] = "- " .. L[rule] end
	box.rules:SetText(table.concat(lines, "\n"))
	box.where = UI.Label(box, 12, nil, "accent")
	box.where:SetPoint("TOPLEFT", box.rules, "BOTTOMLEFT", 0, -8)
	box.where:SetWidth(width - 8)
	box.where:SetJustifyH("LEFT")
	box.Update = function(self)
		local parts, numbers = {}, Z.ChannelNumbers()
		for _, lang in ipairs({ "FR", "EN" }) do
			local here = numbers[lang]
			if here and here.number then parts[#parts + 1] = ("/%d %s"):format(here.number, here.name) end
		end
		self.where:SetText(#parts > 0 and L["Pour y écrire : %s."]:format(table.concat(parts, L[" ou "])) or L["Aucun canal rejoint pour l'instant."])
		Fit(self, math.ceil(self.intro:GetStringHeight() + self.rules:GetStringHeight() + self.where:GetStringHeight()) + 20)
	end
	box:SetScript("OnShow", box.Update)
	Z.ChannelsChanged = function() if box:IsVisible() then box:Update() end end
	box:Update()
	return box
end

-- Votre carnet : trois chiffres en tout et aujourd'hui (depuis la connexion), depuis quand, et la remise à zéro
local TALLY_LINES = { { "heals", "Soins lancés" }, { "res", "Résurrections" }, { "buffs", "Buffs posés" } }
local TALLY_H = 22
local TALLY_ROWS = #TALLY_LINES + 1 -- les titres des deux colonnes, puis une ligne par chiffre

local function NotebookBox(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, TALLY_ROWS * TALLY_H + 52)
	box.tallyRows, box.tonightRows = {}, {}
	for x, title in pairs({ [200] = "En tout", [300] = "Aujourd'hui" }) do
		local head = UI.Label(box, 11, nil, "dim")
		head:SetPoint("TOPLEFT", x, 0)
		head:SetText(L[title])
	end
	for i, line in ipairs(TALLY_LINES) do
		local name = UI.Label(box, 12)
		name:SetPoint("TOPLEFT", 4, -i * TALLY_H)
		name:SetText(L[line[2]])
		local value = UI.Label(box, 13, nil, "accent")
		value:SetPoint("TOPLEFT", 200, -i * TALLY_H)
		box.tallyRows[line[1]] = value
		local tonight = UI.Label(box, 13, nil, "accent")
		tonight:SetPoint("TOPLEFT", 300, -i * TALLY_H)
		box.tonightRows[line[1]] = tonight
	end
	box.since = UI.Label(box, 11, nil, "dim")
	box.since:SetPoint("TOPLEFT", 4, -TALLY_ROWS * TALLY_H - 2)
	box.since:SetWidth(width - 4)
	box.since:SetJustifyH("LEFT")
	box.reset = ArmedButton(box, "Remettre mon carnet à zéro", "Cliquez encore pour confirmer", 240, function()
		Z.ResetTally()
		box:Update()
	end)
	box.reset:SetPoint("TOPLEFT", 0, -TALLY_ROWS * TALLY_H - 24)
	Register(page, L["Remettre mon carnet à zéro"], box.reset)
	box.Update = function(self)
		local tally, tonight = Z.Tally(), Z.Tonight()
		for _, line in ipairs(TALLY_LINES) do
			local key = line[1]
			self.tallyRows[key]:SetText(Grouped(tally[key]))
			self.tonightRows[key]:SetText(Grouped(tonight[key]))
		end
		self.since:SetText(Z.db.notebook
			and L["En tout depuis le %s, aujourd'hui depuis votre connexion, pour ce personnage. Tous vos sorts réussis comptent : cases, barres, macros et touches."]:format(Day(tally.since))
			or L["Carnet éteint : plus rien n'est compté, vos chiffres sont gardés."])
		self:SetAlpha(Z.db.notebook and 1 or 0.6)
	end
	box:SetScript("OnShow", box.Update)
	Z.TallyChanged = function() if box:IsVisible() then box:Update() end end
	box:Update()
	Register(page, L["Votre carnet"], box)
	return box
end

-- Un mot de l'auteur, signé
local function AuthorWord(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 20)
	box.text = UI.Label(box, 12)
	box.text:SetPoint("TOPLEFT", 4, 0)
	box.text:SetWidth(width - 8)
	box.text:SetJustifyH("LEFT")
	box.text:SetSpacing(4)
	box.text:SetText(L["Soigner, c'est le plus beau rôle de Warcraft. C'est voir une barre de vie plonger et la relever d'un geste, tenir tout un raid debout quand le boss frappe fort, sentir le groupe avancer parce que vous êtes là. J'aime ce jeu de tout mon cœur, et j'ai créé Lyorune pour que chaque soigneur vive ces instants pleinement, les yeux sur ses alliés et non sur ses cadres. Merci à vous qui le faites vivre, qui proposez des idées et signalez les bugs : chaque version vous doit un peu. Bons soins, et que la Lumière, la nature ou les esprits guident vos mains !"])
	box.sign = UI.Label(box, 12, nil, "gold")
	box.sign:SetPoint("TOPRIGHT", box.text, "BOTTOMRIGHT", 0, -6)
	box.sign:SetText("BellaDroode")
	box.Update = function(self) Fit(self, math.ceil(self.text:GetStringHeight()) + 26) end
	box:Update()
	return box
end

-- Un ami du mur : son nom à la couleur de sa classe, puis sa classe et son mode de jeu (traduits mot par mot)
local function FriendLine(friend)
	if type(friend) == "string" then return friend end
	local text = friend.name or ""
	if friend.class and friend.class ~= "" then
		local r, g, b = Z.ClassColor(friend.class)
		text = ("|cff%02x%02x%02x%s|r"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), text)
	end
	local about = {}
	if Z.blessingSlotNames[friend.class or ""] then about[1] = L[Z.blessingSlotNames[friend.class]] end
	for word in tostring(friend.mode or ""):gmatch("[^,]+") do
		word = word:match("^%s*(.-)%s*$")
		if word ~= "" then about[#about + 1] = L[word] end
	end
	if #about > 0 then text = text .. "  |cff" .. UI.Hex("dim") .. table.concat(about, ", ") .. "|r" end
	return text
end

-- Mur de remerciements : les noms donnés par l'auteur (About.lua), sinon une invitation
local function ThanksWall(page, width)
	local box = CreateFrame("Frame", nil, page)
	box:SetSize(width, 20)
	box.thanks = UI.Label(box, 13, nil, "gold")
	box.thanks:SetPoint("TOPLEFT", 4, 0)
	box.thanks:SetWidth(width - 8)
	box.thanks:SetJustifyH("CENTER")
	box.thanks:SetSpacing(6)
	box.how = UI.Label(box, 11, nil, "dim")
	box.how:SetPoint("TOPLEFT", box.thanks, "BOTTOMLEFT", 0, -10)
	box.how:SetWidth(width - 8)
	box.how:SetJustifyH("LEFT")
	box.how:SetSpacing(3)
	box.how:SetText(L["Ce mur remercie les joueurs qui font grandir Lyorune : en proposant des améliorations, en signalant des bugs régulièrement pour le rendre le plus parfait possible, ou en le faisant connaître autour d'eux. Vous en êtes ? Dites-le sur le Discord ou sur GitHub : un nom n'y figure qu'avec l'accord de son joueur."])
	box.Update = function(self)
		local lines = {}
		for i, friend in ipairs(Z.about and Z.about.names or {}) do lines[i] = FriendLine(friend) end
		self.thanks:SetText(#lines > 0 and table.concat(lines, "\n") or L["Votre nom ici ?"])
		Fit(self, math.ceil(self.thanks:GetStringHeight() + self.how:GetStringHeight()) + 14)
	end
	box:Update()
	Register(page, L["Merci"], box)
	return box
end

----------------------------------------------------------------------------------------------------
-- Les chapitres : nom, rune de l'atlas (1 à 24, ordre de outils/runes.py), phrase sous le titre, anciens noms
-- d'onglet encore acceptés (Z:ToggleOptions("Clics") du tutoriel), parties { titre, lignes }.
-- Tout est en une colonne ; les outils (listes, clics, profils, légende) sont des lignes « custom ».
----------------------------------------------------------------------------------------------------
local function Chapters()
	return {
		{ name = "Accueil", rune = 19, intro = "Votre profil, vos réglages changés et de quoi bien commencer.", sections = {
			{ "Profil actif", {
				{ "custom", ActiveProfile },
			} },
			{ "Vos réglages changés", {
				{ "note", "Un clic sur un nom mène au réglage ; un clic sur sa rune d'or le remet comme à l'installation.", 30 },
				{ "custom", ChangedList },
			} },
			{ "Découvrir", {
				{ "buttons", {
					{ "button", "Lancer le tutoriel", function() Z:StartTutorial() end }, -- la fenêtre revient à la fin
					{ "button", "Assistant de départ", function() Z:StartWizard() end, "Trois questions (rôle, taille de groupe, forme des cases) pour régler Lyorune d'un coup." }, -- la fenêtre revient sur l'Accueil à la fin
					{ "button", "Nouveautés de Lyorune", function() Z:ShowNews() end },
				} },
			} },
		} },
		{ name = "Disposition", rune = 5, old = { "Cadres" }, intro = "Où et comment les cases sont rangées à l'écran.", sections = {
			{ "Taille des cases", {
				{ "step", "width", "Largeur" },
				{ "step", "height", "Hauteur" },
				{ "step", "scale", "Échelle générale (%)" },
				{ "button", "Placer les éléments de la case...", function() Z:OpenPlacement() end, "Nom, texte de vie, icônes : décalez chaque élément au pixel près sur une case d'exemple agrandie." },
				{ "step", "spacing", "Espacement", fine = true },
				{ "check", "autoShrink", "Réduire les cases en grand raid", desc = "Au-delà de 10 joueurs les cases rétrécissent de 15 %, au-delà de 25 de 30 %.", fine = true },
			} },
			{ "Rangement", {
				{ "seg", "layout", "Rangement des joueurs", nil, "Par groupe : un bloc par groupe de raid. Par rôle : un bloc par rôle. Grille : tout le raid d'un seul tenant, sans trou entre les groupes." },
				{ "cycle", "sortOrder", "Ordre dans chaque bloc", nil, "Le jeu tient l'ordre à jour tout seul, même en combat. En rangement par rôle, « par classe » range par nom." },
				{ "cycle", "roleOrder", "Ordre des rôles", desc = "Utilisé quand le rangement est « Par rôle ».", fine = true, dep = { "layout", "ROLE" } },
				{ "check", "keepGroupPlace", "Chaque groupe garde sa place", "Rangement par groupe : le groupe 3 reste en 3e colonne même si le groupe 2 est vide. Décoché, les groupes se resserrent.", fine = true, dep = { "layout", "GROUP" } },
				{ "step", "gridSize", "Cases par colonne en grille", fine = true, dep = { "layout", "GRID" } },
				{ "seg", "horizontal", "Sens des groupes", fine = true },
			} },
			{ "Position", {
				{ "cycle", "lockMode", "Déplacement des cadres", nil, "Libre : glisser une étiquette « Groupe ». Verrouillé : rien ne bouge. Avec Alt, Ctrl ou Maj : maintenir la touche puis glisser. Jamais en combat.", desc = "Jamais en combat." },
				{ "check", "showGroupLabels", "Numéro de groupe au-dessus des cases", "« Groupe 1 » à « Groupe 8 » en raid, ou le rôle en rangement par rôle. Décoché, l'étiquette ne revient que pour déplacer les cadres." },
				{ "button", "Remettre les cadres au centre", function() SlashCmdList.LYORUNE("reset") end },
			} },
			{ "Cadres affichés", {
				{ "seg", "visibility", "Afficher les cadres", nil, "En permanence (pratique pour se soigner en quête, en combat comme hors combat), ou seulement pendant les combats : les cadres apparaissent alors tout seuls au début du combat." },
				{ "check", "showSolo", "Mon cadre quand je suis seul" },
				{ "check", "showTanks", "Cadre séparé pour les tanks", desc = "Un second cadre, déplaçable, qui ne montre que les tanks." },
				{ "check", "showTarget", "Case de ma cible", "Dans un petit cadre « Cible », déplaçable : mêmes clics et même apparence que les autres cases. Un ennemi est en rouge, sans icônes." },
				{ "seg", "pets", "Familiers", nil, "En groupe : les familiers forment une colonne à part, à droite du groupe, chacun en face de son maître, aux couleurs de son maître en plus pâle. En raid aussi : une colonne « Familiers » à droite des groupes, rangée dans l'ordre des groupes, chaque case portant le nom du maître. Un familier apparaît dès qu'il est appelé, même en combat.", desc = "En groupe : en face de leur maître. En raid : une colonne à droite des groupes." },
				{ "step", "petSize", "Taille des familiers (%)", "Taille de leurs cases, par rapport à celle d'un joueur.", fine = true, dep = { "pets", "!OFF" } },
				{ "check", "showTargetTarget", "Case de la cible de ma cible", "Par exemple le joueur que le boss frappe. Revue deux fois par seconde : le jeu ne prévient pas quand elle change.", fine = true },
				{ "check", "showFocus", "Case de ma focalisation", fine = true },
				{ "check", "showPinned", "Cadre des joueurs épinglés", "Un petit cadre « Épinglés » avec les joueurs de la liste ci-dessous, par exemple un 2e tank. Pour épingler : survolez sa case et tapez /lyorune epingler.", desc = "Pour épingler : survolez une case et tapez /lyorune epingler.", fine = true },
				ListBox("pinned", "Joueurs épinglés", "Montrés dans le cadre « Épinglés ». Tapez un nom puis Entrée.", Z.CleanPinName, { fine = true, dep = { "showPinned", true } }),
				{ "button", "Épingler ma cible", PinTarget, "Aussi : survolez une case et tapez /lyorune epingler (une macro sur une touche, par exemple).", fine = true },
			} },
		} },
		{ name = "Apparence", rune = 14, intro = "À quoi ressemblent les cases.", sections = {
			{ "Forme des cases", {
				{ "custom", ShapePicker },
				{ "seg", "corners", "Angles des cases", nil, "Droits ou arrondis, pour toutes les formes et tous les thèmes." },
				{ "check", "groupPanel", "Fond et bordure par groupe", "Chaque groupe (ou chaque rôle) est posé sur un fond aux couleurs du thème.", fine = true },
			} },
			{ "Style", {
				-- Le contraste élevé remplace le thème et la texture : grisés tant qu'il est allumé (retour d'essai)
				{ "cycle", "theme", "Thème", ThemeChoices(), desc = "Sans effet quand « Contraste élevé » est allumé : il le remplace.", dep = { "highContrast", false } },
				{ "check", "highContrast", "Contraste élevé", "Cases sur fond noir, bordure blanche, texte plus gros : pour une lecture facile. Les fenêtres de Lyorune passent aussi en contraste élevé (gris très foncé, texte clair).", desc = "Fond noir, bordure blanche, texte plus gros." },
				{ "cycle", "texture", "Texture des barres", TextureChoices(), desc = "Sans effet quand « Contraste élevé » est allumé : il le remplace.", fine = true, dep = { "highContrast", false } },
				{ "check", "smooth", "Barres animées", fine = true },
			} },
			{ "Couleurs et transparence", {
				{ "seg", "color", "Couleur des barres" },
				{ "seg", "classIntensity", "Couleurs de classe", nil, "Naturelles : celles du jeu. Vives : plus franches et plus lumineuses, chaque classe garde sa teinte.", dep = { "color", "CLASS" } },
				{ "step", "frameAlpha", "Opacité des cadres (%)" },
				{ "step", "rangeAlpha", "Opacité hors de portée (%)" },
				{ "step", "brightness", "Luminosité des barres (%)", fine = true },
				{ "note", "Un rendu en un clic, à ajuster ensuite avec les trois réglages ci-dessus.", 22, fine = true },
				{ "buttons", { OpacityButton("Discret", 55, 25), OpacityButton("Semi-transparent", 80, 35), OpacityButton("Bien visible", 100, 45) }, fine = true },
			} },
			{ "Texte", {
				{ "seg", "text", "Texte de vie" },
				{ "step", "fontSize", "Taille du texte" },
			} },
		} },
		{ name = "Vie et portée", rune = 16, old = { "Indicateurs" }, intro = "Ce que la barre de vie et la barre de mana vous disent.", sections = {
			{ "Vie", {
				{ "check", "showIncoming", "Soins en route", desc = "La part de vie que les soins en cours vont rendre." },
				{ "check", "showAbsorb", "Bouclier d'absorption" },
				{ "seg", "absorbStyle", "Place du bouclier", nil, "Bande en bas : un trait fin sous la vie. À la suite de la vie : comme les cadres du jeu, le bouclier prolonge la vie, et un trait lumineux s'allume au bout quand il dépasse la vie manquante.", dep = { "showAbsorb", true } },
				{ "check", "absorbText", "Chiffre du bouclier", "Ce qui reste à absorber, tous boucliers comptés (le vôtre, celui d'un autre prêtre ou d'un paladin, Barrière de glace...), en petit à la couleur du bouclier : « +1,2k ». Écrit par le jeu, il marche en combat. Il s'efface quand le dernier bouclier est cassé ou fini. Il suit le texte de vie dans l'éditeur de placement.", desc = "Ce qui reste à absorber, même en combat.", dep = { "showAbsorb", true } },
				{ "check", "lowHealth", "Liseré rouge quand la vie est basse", "En combat, sous le seuil, un liseré rouge fixe entoure la case, sans clignoter. Hors combat, rien : la vie remonte toute seule. Le jeu le calcule lui-même, et Lyorune le revoit deux fois par seconde : il ne reste jamais affiché à tort. Le mode test le montre même hors combat, pour le voir." },
				{ "step", "lowHealthAt", "Seuil de vie basse (%)", fine = true, dep = { "lowHealth", true } },
				{ "check", "healthyFade", "Estomper les joueurs en bonne santé", "Au-dessus du seuil, la vie, la mana et le nom d'un joueur s'estompent : ceux qui ont besoin de soins ressortent. Ses icônes, la dissipation et la menace restent nettes. La case survolée reste nette. Le jeu le calcule lui-même : ça marche en combat.", desc = "Ceux qui ont besoin de soins ressortent." },
				{ "step", "healthyFadeAt", "Seuil de bonne santé (%)", fine = true, dep = { "healthyFade", true } },
				{ "check", "showHealAbsorb", "Absorption de soins", "Bande rouge sombre au bout de la vie : la part qu'un affaiblissement « mange » avant que vos soins comptent. Calculée par le jeu, visible en combat.", desc = "Bande rouge sombre : la part qu'un affaiblissement mange avant vos soins.", fine = true },
			} },
			{ "Mana", {
				{ "seg", "manaBars", "Barre de mana", nil, "Tous : chaque joueur avec sa ressource, à la couleur du jeu (mana, rage, énergie, focalisation...), qui suit la forme du druide. Soigneurs : leur mana seulement." },
				{ "cycle", "lowManaHealers", "Mana basse des soigneurs", nil, "Une icône de boisson sur la case d'un soigneur dont la mana passe sous ce seuil. Le jeu la calcule lui-même : elle marche en combat, même quand la mana est cachée.", desc = "Une icône de boisson, même en combat." },
				{ "check", "drinkHealers", "Soigneur qui boit", "Un soigneur qui boit montre l'icône de sa boisson sur sa case, à côté de sa mana basse, avec le temps qui reste. Utile pour attendre qu'il ait fini avant d'avancer.", desc = "L'icône de sa boisson, à côté de sa mana basse." },
				{ "check", "fiveSecondRule", "Règle des 5 secondes sur ma case", "Après un sort qui coûte de la mana, le jeu coupe votre régénération pendant 5 secondes. Un trait fin sur votre case se vide pendant ce temps : quand il a disparu, votre mana remonte de nouveau.", desc = "Un trait qui se vide jusqu'au retour de la régénération." },
				{ "cycle", "manaEdge", "Liseré de ma mana basse", nil, "Un liseré bleu doux au bord de l'écran, de plus en plus net à mesure que votre mana descend sous ce seuil. Le jeu le calcule lui-même : il marche en combat, même quand la mana est cachée.", desc = "Un liseré bleu doux au bord de l'écran." },
				{ "step", "powerHeight", "Hauteur de la barre de mana", fine = true, dep = { "manaBars", "!OFF" } },
				{ "cycle", "manaColor", "Couleur de la barre de mana", nil, "Seulement pour la mana : rage, énergie et les autres ressources gardent la couleur du jeu.", fine = true, dep = { "manaBars", "!OFF" } },
				{ "check", "manaPercent", "Pourcentage de mana dans la barre", "Le % de mana écrit au milieu de la barre, lisible en combat. La barre passe alors à 8 pixels de haut au moins.", fine = true, dep = { "manaBars", "!OFF" } },
			} },
			{ "Portée", {
				{ "check", "farHint", "Joueur très loin : empreintes", "Trois paliers, même en donjon et en raid : à portée de soin, proche (case estompée), très loin (plus de 100 mètres environ : case encore plus estompée, empreintes au centre).", desc = "Au-delà de 100 mètres environ, la case s'estompe encore et montre des empreintes." },
				{ "check", "losHint", "Soin refusé, hors de vue : un œil", "Quand le jeu refuse votre soin parce que le joueur est derrière un pilier ou un mur, un œil apparaît 3 secondes au centre de sa case.", dep = { "showCenter", true } },
			} },
		} },
		{ name = "Mes soins", rune = 23, old = { "Soins" }, intro = "Ce que vous voyez de vos soins posés sur les joueurs.", sections = {
			{ "Mes soins sur la durée", {
				{ "check", "showHots", "Mes soins sur la durée" },
				{ "seg", "hotStyle", "Affichage des soins sur la durée", dep = { "showHots", true } },
				{ "step", "hotCount", "Nombre de soins affichés", dep = { "showHots", true } },
				{ "check", "hotSwipe", "Cercle qui se vide", "Sur les icônes de vos soins : un voile tourne et découvre l'icône à mesure que le temps passe.", fine = true, dep = { "showHots", true } },
				{ "check", "hotCountdown", "Décompte en secondes", "Sur les icônes de vos soins : les secondes restantes, écrites par le jeu (visibles en combat).", fine = true, dep = { "showHots", true } },
				{ "check", "hotFade", "Icône qui s'efface à la fin", "Vers la fin du soin, l'icône s'assombrit : c'est le moment de relancer.", fine = true, dep = { "showHots", true } },
				{ "check", "hotCharges", "Nombre de charges", "Petit chiffre en bas de l'icône quand votre soin a plusieurs charges.", fine = true, dep = { "showHots", true } },
				{ "check", "showLockouts", "Sort que je ne peux pas relancer", "Prêtre : Âme affaiblie, après un Mot de pouvoir : Bouclier (le vôtre ou celui d'un autre prêtre), pas de nouveau bouclier tant qu'elle est là. Paladin : Longanimité, après Bouclier divin, Protection divine ou Bénédiction de protection, aucun des trois tant qu'elle est là. Son icône assombrie prend la dernière place de la rangée de vos soins.", desc = "Âme affaiblie (prêtre), Longanimité (paladin), assombries après vos soins.", dep = { "showHots", true } },
				{ "check", "lockoutCountdown", "Ses secondes restantes", "Sur l'icône assombrie : les secondes avant de pouvoir relancer votre sort sur ce joueur, écrites par le jeu, même en combat.", fine = true, dep = { "showLockouts", true } },
			} },
			{ "Coins de la case", {
				{ "note", "Un de vos sorts par coin : un carré de couleur qui se vide avec le temps. Le sort quitte alors la rangée d'icônes. Chaque classe garde ses propres coins ; la liste propose les sorts de votre classe et ceux de « Mes sorts à suivre », plus bas.", 46 },
				CornerPicker("TOPLEFT", "En haut à gauche"),
				CornerPicker("TOPRIGHT", "En haut à droite"),
				CornerPicker("BOTTOMLEFT", "En bas à gauche"),
				CornerPicker("BOTTOMRIGHT", "En bas à droite"),
				{ "note", "En combat, le jeu cache le nom des auras : Lyorune reconnaît vos soins à leur numéro, ou au sort que vous venez de lancer. Un soin qu'il ne peut pas reconnaître reste dans la rangée d'icônes, jamais dans un mauvais coin.", 46, fine = true },
			} },
			{ "Sorts suivis", {
				ListBox("extraTracked", "Mes sorts à suivre", "Vos sorts affichés avec vos soins sur la durée, et proposés pour les coins. Tous leurs rangs sont suivis."),
			} },
			{ "Recharges et canalisation", {
				{ "cycle", "castIndicator", "Recharge globale et incantation", nil, "Une fine barre sous les cadres, ou un anneau autour du curseur, qui suit le temps de recharge global (blanc) et votre incantation en cours (couleur d'accent) : vous savez quand le prochain soin peut partir, même en combat." },
				{ "check", "cooldownPanel", "Mes recharges", "Une rangée d'icônes sous les cadres (sous les buffs manquants s'ils sont là) : vos sorts de raccourcis dont la recharge dépasse la recharge globale, et vos gros sorts (Pénitence, Innervation, Imposition des mains, Rapidité de la nature...). Le jeu y dessine le balayage et les secondes, même en combat ; l'icône est grisée tant que le sort recharge, nette quand il est prêt. Survolez une icône : son raccourci.", desc = "Vos sorts à recharge sous les cadres, même en combat." },
				{ "seg", "cooldownShow", "Icônes montrées", "Tous mes sorts : vous voyez aussi ce qui est prêt. En recharge seulement : la rangée n'apparaît que quand un sort recharge.", dep = { "cooldownPanel", true } },
				{ "check", "totemPanel", "Mes totems (chaman)", "Une rangée sous vos recharges : un emplacement par élément (Feu, Terre, Eau, Air), avec l'image du totem posé et le temps qui tourne, même en combat. Un emplacement vide reste pâle ; rien de posé, la rangée disparaît. Sans effet pour une autre classe.", desc = "Vos totems posés et leur temps, sous les cadres." },
				{ "check", "groupCooldowns", "Recharges du groupe", "Sous vos recharges, une ligne par gros sort de vos alliés (Renaissance, Innervation, Imposition des mains, Totem de vague de mana...) : le nom de chacun, net quand le sort est prêt, avec ses secondes sinon. Seuls les joueurs qui ont Lyorune y figurent (le jeu cache les sorts des autres) ; pendant un combat de boss ou un match JcJ, le jeu bloque les messages : la ligne garde le dernier état connu, marqué « avant le boss », et se met à jour à la fin.", desc = "Les gros sorts de vos alliés qui ont Lyorune.", dep = { "syncEnabled", true } },
				ListBox("cooldownIgnored", "Recharges à ne pas montrer", "Un sort de « Mes recharges » ou des recharges du groupe que vous ne voulez pas voir : son nom exact."),
				{ "check", "channelMark", "Trait de canalisation", "Quand vous canalisez un soin sur un joueur (Pénitence), un trait à la couleur d'accent se vide en haut de sa case au rythme de la canalisation : vous voyez qui reçoit le soin et quand il finit, même en combat. Jamais pour un soin sans cible (Tranquillité).", desc = "Pénitence : un trait se vide sur la case soignée." },
			} },
		} },
		{ name = "Affaiblissements", rune = 3, old = { "Listes" }, intro = "Les affaiblissements à voir, à dissiper ou à surveiller.", sections = {
			{ "Dissipation", {
				{ "check", "showDispel", "Cadre coloré quand je peux dissiper", "Bleu magie, violet malédiction, vert poison, brun maladie, autour de la case. Le liseré de chaque icône d'affaiblissement prend aussi la couleur de son type : deux types différents se voient ensemble.", desc = "Bleu magie, violet malédiction, vert poison, brun maladie." },
				{ "check", "dispelIcon", "Icône du type à dissiper", "Goutte de magie, crâne de malédiction, fiole de poison... : l'image du type de l'affaiblissement que vous pouvez dissiper, posée par le jeu sur la case, même en combat. Utile si les couleurs se distinguent mal. Sa place et sa taille se règlent dans le placement des éléments.", desc = "L'image du type, en plus de la couleur." },
			} },
			{ "Icônes", {
				{ "check", "showDebuffs", "Icônes des affaiblissements" },
				{ "check", "debuffCountdown", "Secondes restantes", "Sur les icônes d'affaiblissements, celle du contrôle subi et la grande icône des affaiblissements importants : les secondes restantes, écrites par le jeu, même en combat. Vous voyez s'il faut dissiper ou attendre la fin.", desc = "Dissiper tout de suite, ou attendre la fin ?" },
				{ "seg", "debuffMode", "Affaiblissements affichés", "Tous : tout ce que porte le joueur. Utiles : ceux que le jeu montre sur ses propres cadres de raid, rien de plus de 5 minutes (Déserteur, Épuisement) ; un affaiblissement de boss plus long reste dans la grande icône. Ceux que je dissipe : seulement ce que vous pouvez retirer. Dans les trois cas, ceux de votre liste « À mettre en avant » passent en tête.", desc = "Tous, Utiles, ou seulement ceux que je dissipe.", dep = { "showDebuffs", true } },
				ListBox("ignoredNames", "À ignorer", "Affaiblissements à ne jamais afficher, sauf s'ils sont dans « À mettre en avant ». Un nom, un numéro, ou Maj-clic sur un sort."),
				{ "step", "dispelCount", "Affaiblissements à dissiper", desc = "Montrés avant les autres, le plus important d'abord.", dep = { "showDebuffs", true } },
				{ "step", "debuffCount", "Nombre d'affaiblissements", fine = true, dep = { "showDebuffs", true } },
			} },
			{ "Importants", {
				{ "check", "bossDebuffs", "Affaiblissement important en grand", "Ceux des boss, et ceux de votre liste « À mettre en avant », plus bas." },
				{ "check", "importantGlow", "Contour lumineux si important", "La case s'entoure d'un contour doré qui pulse. Marche en combat pour les affaiblissements de boss : le jeu décide lui-même." },
				{ "check", "showControls", "Joueur sous contrôle", "Étourdi, apeuré, métamorphosé, endormi... : l'icône du contrôle au centre de la case, avec un liseré rouge. Le jeu le reconnaît lui-même, même en combat.", desc = "Étourdi, apeuré, métamorphosé : son icône au centre de la case." },
				ListBox("importantNames", "À mettre en avant", "Toujours montrés en tête de la rangée, quel que soit le mode, même s'ils sont dans « À ignorer » ; en grand comme ceux des boss, avec contour lumineux et son. Un nom, un numéro, ou Maj-clic sur un sort. Un nom en gris n'est pas encore reconnu en combat : survolez-le.", nil, nil, ImportantStatus),
				{ "check", "importantSound", "Son pour ceux de ma liste", "Un son d'alerte quand un affaiblissement de la liste « À mettre en avant » est posé. En combat, le jeu cache souvent le nom des affaiblissements de boss : le son ne peut alors pas partir.", fine = true },
			} },
			{ "Auras privées des boss", {
				{ "check", "privateAuras", "Afficher les auras privées", "Certains affaiblissements de boss sont cachés aux addons : le jeu les dessine lui-même sur la case, à la place choisie ici (deux au plus).", desc = "Le jeu les dessine lui-même sur la case." },
				{ "step", "privateAuraSize", "Taille des auras privées", fine = true, dep = { "privateAuras", true } },
				{ "cycle", "privateAuraPoint", "Place des auras privées", fine = true, dep = { "privateAuras", true } },
			} },
		} },
		{ name = "Joueurs", rune = 18, intro = "Qui est qui dans le groupe, et ce qui leur manque.", sections = {
			{ "Sur la case", {
				{ "check", "showName", "Nom du joueur" },
				{ "check", "showRole", "Icône de rôle (tank, soigneur)" },
				{ "check", "showDpsRole", "Icône des DPS aussi", "L'épée des DPS sur leur case, à la place de l'icône de rôle. Éteinte : seuls les tanks et les soigneurs ont une icône, les cases restent plus lisibles.", desc = "L'épée des DPS, à côté des tanks et des soigneurs.", dep = { "showRole", true } },
				{ "check", "showClassIcon", "Icône de classe", "Une petite icône de la classe du joueur sur sa case : après l'icône de rôle en Barre et en Bandeau, au bord gauche de la ligne du nom en Tuile et en Carré. Sa place et sa taille se règlent dans l'éditeur de placement.", desc = "La classe de chaque joueur, en image." },
				{ "check", "showMarker", "Marqueur de raid" },
				{ "check", "showLeader", "Chef de groupe et assistants", desc = "Une couronne sur la case du chef, un petit drapeau sur celles des assistants en raid." },
				{ "check", "showDefensives", "Gros défensifs des joueurs", "Mur protecteur, Bouclier divin, Bénédiction de protection, Écorce, Évasion, Bloc de glace... : posés par n'importe qui, avec un liseré bleu, même en combat. Deux au plus, au bord droit de la case (juste avant le chiffre de vie en Barre et en Bandeau). Un de vos sorts de la liste quitte alors la rangée de vos soins.", desc = "Mur protecteur, Bouclier divin, Écorce... : posés par n'importe qui." },
				{ "check", "showCenter", "Icône au centre de la case", "Réponse à l'appel, résurrection en cours, soin refusé car hors de vue, invocation, autre phase, joueur très loin. Éteinte : aucune de ces icônes (un joueur très loin reste estompé).", desc = "Appel, résurrection, hors de vue, invocation, joueur très loin." },
				{ "check", "showSummonPhase", "Invocation en cours, autre phase", "Icône au centre de la case : invocation proposée, acceptée ou refusée, ou joueur dans une autre phase (proche en apparence, mais hors d'atteinte).", fine = true, dep = { "showCenter", true } },
			} },
			{ "Menace", {
				{ "check", "showThreat", "Bordure rouge quand il est attaqué" },
				{ "check", "threatBar", "Barre fine de menace", "Trait de couleur en haut de la barre de vie : jaune quand le joueur prend de la menace sur un monstre, orange quand le monstre va se tourner vers lui, rouge quand le monstre s'en prend à lui.", fine = true },
			} },
			{ "Buffs", {
				{ "check", "missingBuffs", "Mes buffs sur la case", "En bas à gauche de la case, seulement vos buffs à reposer sur ce joueur, gris à bord rouge : absent, perdu, ou bientôt fini. Un buff posé ne se montre pas, la case reste propre. Le même affichage hors combat, en combat et en champ de bataille.", desc = "Gris à bord rouge : à reposer. Un buff posé ne se montre pas." },
				{ "check", "uniqueLive", "Buffs uniques en temps réel", "Bouclier de terre, Gardien de peur, Épines, Serment de lumière : sur le joueur qui le porte, votre buff unique se montre en couleur avec ses charges, dessiné par le jeu, même en combat. Dessous attend son repère gris à bord rouge : dès que le buff tombe (charges épuisées, dissipé, fini), le repère apparaît, sans délai. Il quitte alors la rangée de vos soins.", desc = "En couleur avec ses charges ; gris dès qu'il tombe, même en combat.", dep = { "missingBuffs", true } },
				{ "check", "combatBuffs", "En combat", "En combat (et contre un boss), le jeu cache les buffs : Lyorune garde ce qu'il a lu avant le combat et vos sorts réussis. Un buff revient en gris quand il finit bientôt, ou à la mort du joueur. Un buff dissipé en combat se voit à la fin du combat. Éteint : rien sur les cases en combat.", desc = "Gris à bord rouge : à reposer, d'après ce que Lyorune retient.", dep = { "missingBuffs", true } },
				{ "check", "pvpBuffs", "En champ de bataille", "Même chose en combat pendant un match. Hors combat, les buffs à reposer restent toujours montrés (lus ou retenus). Éteint : rien sur les cases en combat pendant un match.", desc = "Vos buffs à reposer, en combat pendant un match.", dep = { "missingBuffs", true } },
				{ "check", "buffPanel", "Buffs manquants à poser", "Hors combat, chaque buff qui manque à un joueur est proposé : un clic le lui lance. Un groupe entier sans buff : une seule ligne pour la version de groupe. Un buff à poser sur une seule personne (Bouclier de terre, Épines, Gardien de peur) est proposé pour son porteur. Tout disparaît en combat et quand tout est posé. Une touche peut lancer le premier : raccourcis du jeu, AddOns, Lyorune." },
				{ "check", "combatKey", "En combat, la touche relance mon buff unique", "En combat, la touche du prochain buff manquant relance votre buff unique (Bouclier de terre, Gardien de peur...) sur son porteur, choisi dans Mes buffs. Préparée juste avant le combat, par le nom du joueur : elle ne part jamais sur quelqu'un d'autre.", fine = true, dep = { "buffPanel", true } },
				{ "seg", "buffPlace", "Emplacement des buffs manquants", nil, "Avec les cadres : un bandeau fin sous le dernier groupe (le joueur, puis « +N autres » ou le sort), qui passe au buff suivant après chaque sort. Où vous voulez : une petite fenêtre à déplacer." },
				{ "custom", BuffWatchList },
				{ "step", "buffGroupAt", "Sort de groupe dès (joueurs sans le buff)", "Nombre de joueurs d'un même groupe sans le buff, à portée du sort, à partir duquel une seule ligne « Groupe N » lance la version de groupe (Prière de robustesse, Don du fauve...). Leurs cases montrent alors l'icône de cette version. Un joueur trop loin ne compte pas : il garde sa propre ligne.", desc = "Ex. : à 3, trois joueurs d'un même groupe sans Marque du fauve donnent une seule ligne qui lance Don du fauve." },
				{ "custom", BuffGroups },
				{ "custom", BlessingGrid },
				{ "button", "Répartir les buffs...", function() Z:OpenBuffAssign() end, "Chef ou assistant : cochez les groupes que chacun buffe et la bénédiction que chaque paladin pose en premier, puis envoyez avant le combat. Aussi : /lyorune repartir buffs." },
				{ "step", "buffRenew", "Proposer à nouveau sous (secondes)", "Un buff qui finit dans moins de secondes que ce nombre est proposé comme s'il manquait, en gris sur la case : pratique avant un boss. Jamais avant le dernier quart d'un buff court. 0 : seulement quand il manque.", desc = "Au départ : 75 secondes avant la fin. 0 : seulement quand le buff manque." },
			} },
			{ "Mes joueurs (répartition entre soigneurs)", {
				{ "note", "Les joueurs dont vous vous occupez portent un trait doré au bord gauche de leur case. Utile même si vous êtes seul à avoir Lyorune.", 30 },
				{ "check", "assignMark", "Repère sur mes joueurs", "Un trait doré au bord gauche de la case de chaque joueur dont vous vous occupez : vos groupes de raid et vos joueurs choisis. Rien ne s'affiche tant que vous n'avez rien choisi." },
				{ "custom", AssignGroups },
				ListBox("assignPlayers", "Joueurs dont je m'occupe", "Un tank, un joueur à surveiller. Tapez un nom puis Entrée, ou survolez sa case et tapez /lyorune pourmoi.", Z.CleanPinName),
				{ "check", "assignFade", "Estomper un peu les autres", "Les joueurs dont vous ne vous occupez pas sont un peu plus transparents. Votre propre case reste nette.", fine = true },
				{ "custom", AssignStatus },
				{ "button", "Répartir les soigneurs...", function() Z:OpenAssign() end, "Chef ou assistant : cochez ce que chaque soigneur soigne et envoyez-le avant le combat. Ceux qui ont Lyorune le voient sur leurs cases, et le soigneur prévu s'affiche au survol. Aussi : /lyorune repartir." },
			} },
			{ "Au survol d'une case", {
				{ "check", "showTooltip", "Infobulle au survol (hors combat)" },
				{ "check", "clickTooltip", "Mes clics dans l'infobulle", "Au survol d'une case, hors combat : chaque clic et chaque touche avec son sort ou sa macro.", fine = true },
				{ "check", "pingCells", "Signal du jeu sur une case", "Survolez une case et appuyez sur la touche de signal du jeu : le joueur est marqué pour tout le groupe, sans viser son personnage.", fine = true },
			} },
		} },
		{ name = "Sorts et raccourcis", rune = 1, old = { "Clics" }, intro = "Un clic sur une case, un sort lancé.", sections = {
			{ "Mes clics", {
				{ "note", "Un clic ou une touche par ligne, autant que vous voulez, avec Alt, Ctrl, Maj ou leurs combinaisons. Le sort part sur la case survolée.", 30 },
				{ "custom", SpecLine },
				{ "custom", ClickList },
				{ "note", "Au départ, Alt + clic gauche cible le joueur et Alt + clic droit ouvre son menu. « Cibler » et « Menu du joueur » se posent sur toute ligne : en haut de la fenêtre des sorts. Glissez un sort du grimoire sur une ligne pour le poser. Le « + » d'une ligne ajoute une variante : sur un ennemi, en JcJ, sur un tank, hors combat.", 58 },
				{ "button", "Mes macros...", function() Z:OpenMacros() end, "Votre bibliothèque de macros : écrire, vérifier, importer de /macro, puis glisser sur un clic ou dans une barre de sorts." },
			} },
			{ "Comportement", {
				{ "check", "castOnDown", "Lancer le sort dès l'appui (plus rapide)" },
				{ "check", "autoRes", "Le même clic relève un joueur mort", "Si la cible est morte, votre sort de soin est remplacé par votre résurrection." },
				{ "check", "enemyGuard", "Aucun soin sur un ennemi", "Sur une case qui montre un ennemi (Cible, Focalisation, allié sous Contrôle mental), un raccourci sans variante « Sur un ennemi » ne fait rien : votre soin ne part jamais vers lui. Cibler, Menu du joueur et Arrêter l'incantation marchent partout.", desc = "Un raccourci sans variante ennemie n'y fait rien." },
				{ "check", "clicksPerSpec", "Clics propres à chaque spécialisation", "Chaque groupe de talents a ses clics et ses touches ; ils changent tout seuls avec vos talents. Décoché : les mêmes partout.", fine = true },
				{ "check", "newSpellAlert", "Signaler un nouveau sort sans clic", "Quand vous apprenez un sort utilisable sur un allié qui n'a encore ni clic ni touche : un message, et le sort en haut de ce chapitre avec le bouton « Attribuer ».", fine = true },
				{ "check", "clickConflictAlert", "Signaler un clic pris aussi par le jeu", "Si le « clic pour lancer » du jeu utilise la même combinaison qu'un clic de Lyorune : un message, et la ligne en orange dans ce chapitre. Lyorune ne modifie jamais les raccourcis du jeu.", fine = true },
				{ "check", "clickStats", "Compter mes clics", "À côté de chaque ligne de ce chapitre : combien de fois vous l'avez utilisée, par personnage et par spécialisation. Une ligne jamais utilisée est grisée. Chaque clic compte, même si le sort échoue. Changer le sort d'une ligne remet son compte à zéro.", desc = "Combien de fois chaque ligne a servi." },
				{ "button", "Remettre mes comptes à zéro", function()
					Z:ResetClickStats()
					RefreshClicks()
				end, "Remet à zéro les comptes de la spécialisation affichée.", dep = { "clickStats", true } },
				{ "check", "rankChoice", "Choisir le rang des sorts", "Pour garder de la mana : dans la fenêtre de choix d'un sort, un clic droit sur un sort à plusieurs rangs ouvre la liste de ses rangs (niveau, coût en mana). Décoché : tous vos raccourcis lancent le rang le plus haut ; les rangs déjà choisis sont gardés et reviennent si vous recochez.", desc = "Sinon, toujours le rang le plus haut." },
				{ "check", "rankAdapt", "Rang adapté au niveau du joueur soigné", "Un rang choisi trop fort pour un joueur de bas niveau est remplacé, sur sa case, par le meilleur de vos rangs qu'il peut recevoir (jamais plus fort que celui choisi). Calculé hors combat ; en combat, la case garde son rang. Le rang le plus haut est déjà adapté par le jeu.", fine = true, dep = { "rankChoice", true } },
				{ "check", "trinketButtons", "Bijoux avec les sorts", "Deux boutons au bout de chaque ligne : votre bijou du haut ou du bas, utilisé juste avant le sort, sur un joueur vivant. Une ligne qui a déjà un bijou garde ses boutons.", fine = true },
				{ "check", "externalClicks", "Laisser Clique ou le jeu gérer les clics", "À cocher seulement si vous préférez Clique ou le clic-soin du jeu : les clics de Lyorune sont alors coupés.", fine = true },
			} },
			{ "Macros pour vos barres de sorts", {
				{ "check", "actionBarMacros", "Créer une macro par sort de mes clics", "Lyorune crée et tient à jour de vraies macros du jeu (leur nom commence par « Lyo: »), rangées dans /macro, onglet de votre personnage. Il ne touche à aucune autre macro." },
				{ "note", "Cliquez sur une icône, puis déposez-la dans une barre de sorts. La macro vise le joueur sous la souris, sinon votre cible, sinon vous.", 30, dep = { "actionBarMacros", true } },
				{ "custom", BarIcons, dep = { "actionBarMacros", true } },
				{ "button", "Retirer les macros de Lyorune", function()
					if not Z:RemoveBarMacros() then return end -- en combat : refusé, l'option reste cochée
					Z.db.actionBarMacros = false
					RefreshShownPages() -- l'interrupteur et les icônes suivent
				end, "Supprime les macros « Lyo: » et décoche l'option. Vos autres macros ne sont pas touchées." },
			} },
		} },
		{ name = "Alertes", rune = 4, intro = "Annonces dans le chat et sons.", sections = {
			{ "Annonces dans le chat", {
				{ "cycle", "alertChannel", "Canal des annonces" },
				{ "check", "manaAlert", "Annoncer quand ma mana est faible" },
				{ "step", "manaThreshold", "Seuil de mana faible (%)", dep = { "manaAlert", true } },
				AlertText("manaText", function() Z:Announce(Z:ManaText(Z.db.manaThreshold), true) end, { "manaAlert", true }),
				{ "check", "regenAlert", "Annoncer quand ma mana est remontée" },
				{ "step", "regenThreshold", "Seuil de mana remontée (%)", dep = { "regenAlert", true } },
				AlertText("regenText", function() Z:Announce(Z:RegenText(Z.db.regenThreshold), true) end, { "regenAlert", true }),
				{ "check", "resAlert", "Annoncer quand je ressuscite un joueur" },
				AlertText("resText", function() Z:Announce(Z:ResText(UnitName("player")), true) end, { "resAlert", true }),
				{ "note", "Dans les textes, {mana} est remplacé par votre pourcentage de mana et {nom} par le joueur relevé. Les annonces ne partent qu'en groupe. Règle du jeu : hors instance, un addon ne peut pas écrire en /dire tout seul ; l'annonce part alors dans le canal du groupe ou du raid.", 60 },
			} },
			{ "Sons", {
				{ "check", "soundDispel", "Son quand je peux dissiper un affaiblissement" },
				{ "check", "soundMana", "Son quand ma mana est faible" },
				{ "custom", RulerNote },
			} },
		} },
		{ name = "Profils et partage", rune = 20, old = { "Profils" }, intro = "Vos profils, le partage avec vos amis et la synchronisation.", sections = {
			{ "Mes profils", {
				{ "note", "Vos réglages d'apparence, enregistrés sous un nom. Clics, macros, listes et annonces n'en font pas partie : ils ne changent jamais avec le profil.", 30 },
				{ "custom", ProfileBox },
			} },
			{ "Profils automatiques", {
				{ "check", "autoProfile", "Changer de profil tout seul", "Selon la taille du groupe, le champ de bataille et votre spécialisation, sans /reload. En combat, le changement attend la fin du combat." },
				{ "custom", ProfileGrid },
			} },
			{ "Profils prêts à l'emploi", {
				{ "note", "Taille et disposition seulement ; vos clics restent.", 18 },
				{ "custom", PresetButtons },
			} },
			{ "Donner ma configuration", {
				{ "custom", ExportBox },
			} },
			{ "Recevoir une configuration", {
				{ "custom", ImportBox },
			} },
			{ "Entre joueurs", {
				{ "check", "syncEnabled", "Synchronisation entre joueurs", "Messages invisibles entre joueurs qui ont Lyorune. Décochée : rien ne part, rien n'est lu. Pendant un combat de boss ou un match JcJ, le jeu les bloque : rien ne part." },
				{ "check", "resSync", "Montrer qui relève qui", "Quand un soigneur commence une résurrection, son nom remplace « Mort » sur la case, chez tous ceux qui ont Lyorune. Pendant un combat de boss ou un match JcJ, le jeu bloque ces messages.", dep = { "syncEnabled", true } },
				{ "check", "acceptConfigs", "Accepter qu'on me propose une configuration", "Seulement d'un membre du groupe, de la guilde ou d'un ami. Rien n'est appliqué sans votre accord : une fenêtre vous demande.", fine = true, dep = { "syncEnabled", true } },
				{ "check", "assignAccept", "Appliquer la répartition du chef", "Le chef ou un assistant envoie qui soigne quoi et qui buffe quoi : vos repères et vos buffs suivent tout de suite, avec une ligne dans la discussion. Votre propre choix revient quand vous quittez le groupe. Décochée : les répartitions reçues sont ignorées. Pendant un combat de boss ou un match JcJ, le jeu bloque les messages : la répartition part avant.", dep = { "syncEnabled", true } },
				{ "check", "blessingSync", "Entente entre paladins", "Les paladins qui ont Lyorune s'annoncent leurs bénédictions avant le combat : aucun ne pose celle d'un autre sur le même joueur. Sans cette case, une bénédiction déjà posée par un autre paladin est tout de même respectée.", dep = { "syncEnabled", true } },
				{ "check", "cooldownShare", "Partager mes recharges", "Vos gros sorts (résurrection en combat, mana, protections, gros soins de groupe) sont annoncés au groupe quand vous les lancez et quand ils sont prêts : vos alliés qui suivent les recharges du groupe les voient sans que vous ayez rien à faire. Aucun message régulier.", dep = { "syncEnabled", true } },
				{ "check", "versionNotice", "Me prévenir si une version plus récente existe", fine = true, dep = { "syncEnabled", true } },
				{ "custom", SyncWho }, -- après les trois réglages qu'il grise
			} },
			{ "Remise à zéro", {
				{ "custom", ResetBox },
			} },
		} },
		{ name = "Fenêtre et aide", rune = 21, old = { "Aide" }, intro = "Cette fenêtre, la langue, et de l'aide si besoin.", sections = {
			{ "Fenêtres de Lyorune", {
				{ "seg", "windowTheme", "Thème des fenêtres", nil, "Options, visite guidée et petites fenêtres (pas les cases). Moderne : net, bleu givre et or. Classique : comme les fenêtres du jeu. MMORPG : pierre sombre, cadre doré et runes gravées.", desc = "Options, visite guidée et petites fenêtres (pas les cases)." },
				{ "check", "magicEffects", "Effets magiques", "Lumière de soin, or et vert, qui traverse l'en-tête, animation du logo, particules de lumière, rune du chapitre ouvert qui s'allume, éclat sur la case témoin quand un réglage change. Jamais sur vos vraies cases de soin. Coupés par « Animations réduites ».", desc = "Lumière dans l'en-tête, animation du logo, étincelle quand un réglage change." },
				{ "seg", "logoAnimation", "Animation du logo", nil, "Autour du logo de cette fenêtre, aux couleurs des classes de soin. Aurore : des lueurs qui dérivent lentement, un reflet, des étincelles de soin. Sceau : quatre gemmes, une lumière passe de l'une à l'autre. Souffle : une onde de soin lente, d'une couleur à l'autre. Demande « Effets magiques », coupée par « Animations réduites ».", desc = "Aurore, Sceau ou Souffle, aux couleurs des classes de soin." },
				{ "check", "reduceMotion", "Animations réduites", "Seulement des fondus courts : runes fixes, logo immobile, rien ne bouge en boucle. La lueur au survol reste." },
				{ "check", "showRunes", "Inscription runique au bas de cette fenêtre", "Passez la souris sur les runes pour lire leur traduction." },
				{ "check", "minimapButton", "Bouton sur la mini-carte", "Clic gauche : options. Clic droit : mode test. Faites-le glisser pour le déplacer.", fine = true },
				{ "cycle", "language", "Langue de Lyorune", desc = "Le changement s'applique après /reload.", fine = true },
			} },
			{ "Aide", {
				{ "check", "showNews", "Montrer les nouveautés après une mise à jour" },
				{ "buttons", {
					{ "button", "Signaler un bug", function() Z:ShowBug() end, "Trois questions, et un rapport prêt à copier. Fonctionne aussi pour un défaut d'affichage." },
					{ "button", "Journal d'erreurs", function() Z:ShowLog() end, "Le journal note chaque erreur avec son contexte. Copiez-le pour obtenir de l'aide." },
				} },
				{ "check", "errorNotice", "Me prévenir quand Lyorune rencontre une erreur", desc = "Un seul message discret par session, jamais de fenêtre.", fine = true },
				{ "check", "perfMode", "Mode performance", "Pour les grands raids ou un ordinateur modeste : portée vérifiée une fois par seconde au lieu de deux, icônes des soins et des affaiblissements regroupées (un dixième de seconde de retard au plus). Rien ne disparaît. Peut être gardé dans un profil de raid.", fine = true },
				{ "button", "Mesurer les performances", function() Z:ShowMeasure() end, "Fait tourner Lyorune sur un faux groupe de 5, 25 et 40 joueurs, et compare sa mémoire et son temps aux autres addons de soin chargés. Hors combat. Aussi : /lyorune mesure.", fine = true },
			} },
			{ "Lire une case", {
				{ "custom", Legend },
			} },
			{ "Commandes", {
				{ "custom", CommandList },
			} },
		} },
		{ name = "Les amis de Lyorune", rune = 7, intro = "Lyorune en chiffres, le canal des soigneurs, votre carnet et un grand merci.", sections = {
			{ "Lyorune en chiffres", {
				{ "custom", FriendsNumbers },
			} },
			{ "Canal des soigneurs", {
				{ "check", "channelFR", "Canal en français", "Rejoint le canal du jeu « LyoruneFR », pour échanger entre soigneurs en français : façons de jouer, spécialisations, astuces. Vous y écrivez avec son numéro, comme dans tout canal (/5 Bonjour). Décochée : Lyorune quitte le canal. Vaut pour tous vos personnages.", desc = "Le canal « LyoruneFR », pour parler soins et Lyorune." },
				{ "check", "channelEN", "Canal en anglais", "Rejoint le canal du jeu « LyoruneEN », pour échanger entre soigneurs en anglais : façons de jouer, spécialisations, astuces. Vous y écrivez avec son numéro, comme dans tout canal (/6 Hello). Décochée : Lyorune quitte le canal. Vaut pour tous vos personnages.", desc = "Le canal « LyoruneEN », pour parler soins et Lyorune en anglais." },
				{ "custom", ChannelBox },
			} },
			{ "Votre carnet", {
				{ "check", "notebook", "Tenir mon carnet", "Compte vos soins, vos résurrections et vos buffs réussis, pour chaque personnage, d'où qu'ils partent : cases, barres, macros, touches. Les dissipations ne comptent pas. Rien n'est envoyé : le carnet reste sur votre ordinateur.", desc = "Vos soins, résurrections et buffs réussis, par personnage." },
				{ "check", "tallyExit", "Bilan en sortant d'un donjon", "En sortant d'un donjon ou d'un raid, une ligne dans la discussion donne son nom, sa durée et vos soins, résurrections et buffs dedans, puis ceux du jour (depuis votre connexion). Rien quand vous sortez mort, pour revenir après un wipe.", dep = { "notebook", true } },
				{ "custom", NotebookBox },
			} },
			{ "Un mot de BellaDroode", {
				{ "custom", AuthorWord },
			} },
			{ "Merci", {
				{ "custom", ThanksWall },
			} },
		} },
	}
end

-- Chapitre où se règle un réglage, lu dans la liste ci-dessus : la copie d'une partie d'un profil s'en sert
-- (Share.lua). Calculé une seule fois, au premier besoin.
local settingChapter
function Z.TabOfSetting(key)
	if not settingChapter then
		settingChapter = {}
		EachSetting(Chapters(), function(item, _, chapter) settingChapter[item[2]] = chapter.name end)
	end
	return settingChapter[key]
end

----------------------------------------------------------------------------------------------------
-- Fenêtre, barre latérale, pages qui défilent et recherche
----------------------------------------------------------------------------------------------------
-- Un chapitre par son nom, ou par l'ancien nom de son onglet
local function ChapterIndex(name)
	for i, chapter in ipairs(chapters) do
		if chapter.name == name then return i end
		for _, old in ipairs(chapter.old or {}) do
			if old == name then return i end
		end
	end
end

-- Hauteur d'une ligne : l'élément, et sa phrase d'explication dessous
local function PartHeight(part)
	local widget = part.widget
	return widget:GetHeight() + (widget.desc and widget.desc:GetStringHeight() + 3 or 0)
end

-- Range la page de haut en bas ; les réglages fins d'une partie repliée sont cachés, comme une ligne dont la
-- condition (part.when) n'est pas remplie
local function Layout(page)
	local y = page.top
	for _, part in ipairs(page.parts) do
		local shown = (not part.fold or part.fold:IsOpen()) and (not part.when or part.when())
		part.widget:SetShown(shown)
		if shown then
			y = y - (part.before or 0)
			part.widget:ClearAllPoints()
			part.widget:SetPoint("TOPLEFT", page.content, "TOPLEFT", part.fold and FINE or 0, y)
			part.y = -y
			y = y - PartHeight(part) - 8
		end
	end
	page.used = -y -- hauteur occupée (contrôlée par les tests)
	page.scroll:SetContentHeight(-y + 12)
end

-- Réglages dépendants : grisés quand leur réglage parent les rend sans effet. Ils restent réglables (on peut
-- préparer une valeur avant d'allumer le réglage parent).
local function ApplyDeps(page)
	for _, part in ipairs(page.parts) do
		local dep = part.item and part.item.dep
		if dep then
			part.dimmed = not DepOk(dep)
			part.widget:SetAlpha(part.dimmed and DIMMED or 1)
		end
	end
end

-- « Rétablir cette page » : chaque réglage du chapitre reprend sa valeur d'installation. Les listes, les clics,
-- les coins et les profils ne sont pas touchés. Un seul rafraîchissement des cadres, à la fin.
local function ResetChapter(chapter)
	local clicks
	EachSetting({ chapter }, function(item)
		local key = item[2]
		if IsChanged(key) then
			local value = Z.defaults[key]
			Z.db[key] = type(value) == "table" and CopyTable(value) or value
			if CLICK_OPTIONS[key] then clicks = true end
		end
	end)
	Z:Refresh()
	Z:RefreshAlerts()
	if clicks then Z:ApplyClicks() end
	if chapter.page then RefreshPage(chapter.page) end
	AfterChange()
end

-- Bas de page : « Rétablir cette page », à droite, montré seulement si le chapitre a un réglage changé
local function ResetLine(chapter, page)
	local line = CreateFrame("Frame", nil, page.content)
	line:SetSize(ROW, 24)
	line.button = ArmedButton(line, "Rétablir cette page", "Cliquez encore pour confirmer", 240, function() ResetChapter(chapter) end)
	line.button:SetPoint("RIGHT")
	line.button.tip = L["Chaque réglage de ce chapitre reprend sa valeur d'installation. Vos listes, vos textes d'annonce, vos clics et vos profils ne changent pas."]
	page.parts[#page.parts + 1] = { widget = line, before = 14, when = function() return (chapter.changes or 0) > 0 end }
	page.reset = line
end

-- Après chaque changement : la pastille de chaque chapitre, le grisage des réglages dépendants des pages déjà
-- construites, « Rétablir cette page » qui paraît ou disparaît (la page se range alors de nouveau), et la lumière
-- de la rune du chapitre ouvert (effets magiques allumés ou coupés)
AfterChange = function()
	if not chapters then return end
	for _, chapter in ipairs(chapters) do
		chapter.changes = ChapterChanges(chapter)
		if chapter.button then
			chapter.button:SetCount(chapter.changes)
			chapter.button:Light()
		end
		local page = chapter.page
		if page then
			ApplyDeps(page)
			if page.reset and page.reset:IsShown() ~= (chapter.changes > 0) then Layout(page) end
		end
	end
	UpdateFoot()
end

-- Page d'un chapitre, construite à sa première ouverture
local function BuildChapter(index)
	local chapter = chapters[index]
	if chapter.page then return chapter.page end
	local scroll = UI.Scroll(window)
	scroll:SetPoint("TOPLEFT", SIDE + 28, -HEAD - 10)
	scroll:SetPoint("BOTTOMRIGHT", -WITNESS - 8, FOOT) -- la case témoin occupe la droite
	scroll:Hide()
	local content = scroll.content
	content.tabIndex = index
	local page = { scroll = scroll, content = content, parts = {}, top = -64 }
	chapter.page = page

	-- En-tête : la rune du chapitre, son nom, une phrase
	page.rune = UI.Paint(UI.Rune(content, "ARTWORK", chapter.rune, 30), "gold")
	page.rune:SetPoint("TOPLEFT", 2, -4)
	page.title = UI.Title(content, 20)
	page.title:SetPoint("TOPLEFT", 46, -2)
	page.title:SetText(L[chapter.name])
	page.intro = UI.Label(content, 12, nil, "dim")
	page.intro:SetPoint("TOPLEFT", 46, -30)
	page.intro:SetText(L[chapter.intro])

	for s, section in ipairs(chapter.sections) do
		if section[1] then
			local head = Heading(content, section[1])
			page.parts[#page.parts + 1] = { widget = head, before = s > 1 and 14 or 0 }
		end
		local fine = {}
		for _, item in ipairs(section[2]) do
			-- Un réglage qui échoue est noté au journal et ne cache pas les suivants
			Z:Try("option " .. tostring(type(item[2]) == "string" and item[2] or item[1]), function()
				local widget = BuildItem(content, item, item.fine and ROW - FINE or ROW)
				local part = { widget = widget, item = item }
				widget.part = part
				widget.Relayout = function() Layout(page) end -- Fit : la ligne a changé de hauteur
				if item.fine then fine[#fine + 1] = part else page.parts[#page.parts + 1] = part end
			end)
		end
		if #fine > 0 then
			local fold = UI.Fold(content, chapter.name .. "." .. s, #fine, function() Layout(page) end)
			fold:SetWidth(ROW)
			page.parts[#page.parts + 1] = { widget = fold }
			for _, part in ipairs(fine) do
				part.fold = fold
				page.parts[#page.parts + 1] = part
			end
		end
	end
	if content.settings then ResetLine(chapter, page) end -- chapitre qui porte des réglages
	chapter.changes = ChapterChanges(chapter)
	ApplyDeps(page)
	Layout(page)
	return page
end

-- La page entre en fondu en montant de 6 pixels (0,2 s) ; simple fondu en animations réduites
local function Enter(scroll)
	if not scroll.enter then
		scroll.enter = scroll:CreateAnimationGroup()
		scroll.drop = scroll.enter:CreateAnimation("Translation")
		scroll.drop:SetDuration(0)
		scroll.drop:SetOrder(1)
		scroll.rise = scroll.enter:CreateAnimation("Translation")
		scroll.rise:SetDuration(0.2)
		scroll.rise:SetSmoothing("OUT")
		scroll.rise:SetOrder(2)
		scroll.fade = UI.AlphaAnim(scroll.enter, 0, 1, 0.2, "OUT", 2)
	end
	local calm = UI.Calm()
	scroll.drop:SetOffset(0, calm and 0 or -6)
	scroll.rise:SetOffset(0, calm and 0 or 6)
	scroll.fade:SetDuration(calm and 0.15 or 0.2)
	scroll.enter:Stop()
	scroll.enter:Play()
end

local current
-- Ouvre un chapitre, par son numéro ou son nom (Z:ToggleOptions("Clics")). La fenêtre rouvre le dernier chapitre
-- pendant la partie ; il n'est pas sauvé : chaque connexion ou /reload ouvre l'Accueil (retour d'essai).
local function Select(index, quiet)
	if type(index) == "string" then index = ChapterIndex(index) or 1 end
	if not chapters[index] then index = 1 end
	local page = BuildChapter(index)
	local changed = current ~= index
	current = index
	for i, chapter in ipairs(chapters) do
		local other = chapter.page
		if other and i ~= index then other.scroll:Hide() end
		chapter.button:SetActive(i == index)
	end
	page.scroll:Show()
	RefreshPage(page) -- chaque ligne suit les changements faits ailleurs (profil, partage, liste)
	AfterChange()
	if Z.QueueBuffPanel then Z:QueueBuffPanel() end -- chapitre Joueurs : l'exemple des buffs manquants (Buffs.lua)
	if changed and not quiet then Enter(page.scroll) end
	if picker then picker:Hide() end
	return page
end

-- Recherche : les réglages dont le nom contient le texte tapé, puis ceux dont l'explication le contient. Un clic
-- ouvre le chapitre, déplie les réglages fins si besoin, fait défiler jusqu'au réglage et le fait clignoter.
local function BuildSearch()
	local results = CreateFrame("Frame", nil, window)
	results:SetFrameStrata("FULLSCREEN_DIALOG")
	results:SetSize(300, 10)
	results.bg = UI.Paint(UI.Tex(results, "BACKGROUND"), "bg", 0.98)
	results.bg:SetAllPoints()
	results.border = UI.Border(results, 1)
	UI.Paint(results.border, "line")
	results.rows = {}
	results:Hide()

	local flash = UI.Paint(UI.Tex(window, "OVERLAY"), "accent", 0.35)
	flash:Hide()
	window.flash = flash

	local edit = UI.Edit(window, 230)
	edit:SetPoint("TOPRIGHT", -44, -13)
	Placeholder(edit, "Rechercher un réglage...")
	results:SetPoint("TOPRIGHT", edit, "BOTTOMRIGHT", 0, -2)

	local function Go(entry)
		results:Hide()
		edit:SetText("")
		edit:ClearFocus()
		if entry.Show then -- élément hors des chapitres (case témoin) : il se montre lui-même, la page ne change pas
			window.found = entry
			flash.count = (flash.count or 0) + 1
			flash:Hide()
			return entry.Show()
		end
		local page = Select(entry.chapter)
		-- La ligne qui porte l'élément : lui-même, ou la ligne dessinée à part qui le contient
		local holder = entry.widget
		while holder and not holder.part do holder = holder:GetParent() end
		local part = holder and holder.part
		if part and part.fold and not part.fold:IsOpen() then part.fold:SetOpen(true) end -- la page se range de nouveau
		if part and part.y then
			local inside = 0 -- dans une ligne dessinée à part : la place de l'élément dans la ligne
			if holder ~= entry.widget then
				local top, target = holder:GetTop(), entry.widget:GetTop()
				if top and target then inside = top - target end
			end
			page.scroll:ScrollTo(part.y + inside - 30)
		end
		window.found = entry
		flash:ClearAllPoints()
		flash:SetPoint("TOPLEFT", entry.widget, "TOPLEFT", -4, 3)
		flash:SetPoint("BOTTOMRIGHT", entry.widget, "BOTTOMRIGHT", 4, -3)
		flash:Show()
		flash.count = (flash.count or 0) + 1 -- deux recherches de suite : seul le dernier délai éteint
		local mine = flash.count
		C_Timer.After(1.5, function() if flash.count == mine then flash:Hide() end end)
	end

	edit:HookScript("OnTextChanged", function(self)
		local text = Plain(self:GetText()):match("^%s*(.-)%s*$")
		if #text < 2 then return results:Hide() end
		for i = 1, #chapters do BuildChapter(i) end -- la recherche couvre tous les chapitres
		local count = 0
		for pass = 1, 2 do -- d'abord par le nom, puis par l'explication
			for _, entry in ipairs(searchIndex) do
				local byName = entry.text:find(text, 1, true)
				local hit = (pass == 1 and byName) or (pass == 2 and not byName and entry.more:find(text, 1, true))
				if count < 8 and hit then
					count = count + 1
					local row = results.rows[count]
					if not row then
						row = UI.Button(results, "", 292, 22, function(button) Go(button.entry) end)
						row:SetPoint("TOPLEFT", 4, -4 - (count - 1) * 24)
						results.rows[count] = row
					end
					row.entry = entry
					local where = entry.chapter and L[chapters[entry.chapter].name] or entry.where
					row.label:SetText(entry.label .. "  |cff" .. UI.Hex("dim") .. where .. "|r")
					row:Show()
				end
			end
		end
		for i = count + 1, #results.rows do results.rows[i]:Hide() end
		results:SetHeight(count * 24 + 8)
		results:SetShown(count > 0)
	end)
	window.search, window.results, window.Go = edit, results, Go
end

----------------------------------------------------------------------------------------------------
-- Case témoin, dans la colonne de droite : une fausse case agrandie qui suit chaque réglage, un faux groupe de
-- cinq dessous, puis les boutons du mode test. Ce sont les fausses cases du mode test (Preview.lua) : de simples
-- cadres, jamais de bouton protégé, aucune valeur lue sur un vrai joueur. Redessinée après chaque Z:Refresh()
-- (Z:RefreshShapes), seulement quand la fenêtre est ouverte.
----------------------------------------------------------------------------------------------------
local STAGE_W, STAGE_H = 250, 140 -- fond de la case témoin
local TEST_SIZES = { 5, 10, 25, 40 }
local TEST_HINT = "Pose un faux groupe à l'écran, à la vraie taille, pour régler l'apparence en vrai."

-- Ce que montre la case témoin, en une phrase
local function WitnessLegend(hots)
	local db, bits = Z.db, {}
	if db.showDispel then bits[#bits + 1] = L["cadre de couleur : affaiblissement à dissiper"] end
	if db.showAbsorb then
		bits[#bits + 1] = L[db.absorbStyle == "FOLLOW" and "bouclier à la suite de la vie" or "bouclier en bande sous la vie"]
	end
	local names = {}
	for _, point in ipairs(Z.CORNERS) do
		local name = Z.MyCorners()[point]
		if name and name ~= "" then names[#names + 1] = name end
	end
	if #names > 0 then bits[#bits + 1] = L["coins : %s"]:format(table.concat(names, ", ")) end
	if hots == 1 then bits[#bits + 1] = L["1 soin sur la durée"] end
	if hots > 1 then bits[#bits + 1] = L["%d soins sur la durée"]:format(hots) end
	if #bits == 0 then return L["Case nue : tous les indicateurs sont coupés."] end
	local text = table.concat(bits, ", ") -- chaque morceau commence par une lettre sans accent
	return text:sub(1, 1):upper() .. text:sub(2) .. "."
end

local function BuildWitness()
	local col = CreateFrame("Frame", nil, window)
	col:SetPoint("TOPRIGHT", -10, -HEAD)
	col:SetPoint("BOTTOMRIGHT", -10, FOOT)
	col:SetWidth(WITNESS - 10)
	col.bg = UI.Paint(UI.Tex(col, "BACKGROUND"), "side", "sideAlpha")
	col.bg:SetAllPoints()
	col.line = UI.Paint(UI.Tex(col, "ARTWORK"), "line")
	col.line:SetWidth(1)
	col.line:SetPoint("TOPLEFT")
	col.line:SetPoint("BOTTOMLEFT")
	col.title = UI.Heading(col, 15)
	col.title:SetPoint("TOPLEFT", 15, -12)
	col.title:SetText(L["Case témoin"])
	col.intro = UI.Label(col, 11, nil, "dim")
	col.intro:SetPoint("TOPLEFT", 15, -32)
	col.intro:SetText(L["Elle suit chaque réglage, en direct."])

	-- La case, agrandie, sur un fond ; le porteur reçoit l'opacité des cadres
	local stage = CreateFrame("Frame", nil, col)
	stage:SetSize(STAGE_W, STAGE_H)
	stage:SetPoint("TOPLEFT", 15, -52)
	stage.bg = UI.Tex(stage, "BACKGROUND", 0, 0, 0, 0.35)
	stage.bg:SetAllPoints()
	stage.border = UI.Paint(UI.Border(stage, 1), "line")
	stage.holder = CreateFrame("Frame", nil, stage)
	stage.holder:SetAllPoints()
	stage.cell = Z.FakeCell(stage.holder)
	stage.cell:SetPoint("CENTER")
	stage.burst = UI.HealBurst(stage) -- éclat de soin quand un réglage change
	col.stage = stage
	col.legend = UI.Label(col, 11, nil, "dim")
	col.legend:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -6)
	col.legend:SetWidth(STAGE_W)
	col.legend:SetJustifyH("LEFT")
	col.legend:SetSpacing(2)

	-- Faux groupe : cinq petites cases, trois puis deux
	col.groupTitle = UI.Heading(col, 13)
	col.groupTitle:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -56) -- légende : jusqu'à trois lignes
	col.groupTitle:SetText(L["Faux groupe"])
	local group = CreateFrame("Frame", nil, col)
	group:SetPoint("TOPLEFT", col.groupTitle, "BOTTOMLEFT", 0, -6)
	group:SetSize(STAGE_W, 80)
	group.bg = UI.Tex(group, "BACKGROUND", 0, 0, 0, 0.3)
	group.bg:SetAllPoints()
	group.border = UI.Paint(UI.Border(group, 1), "line")
	group.holder = CreateFrame("Frame", nil, group)
	group.holder:SetAllPoints()
	group.slots = {}
	for i = 1, 5 do
		local slot = CreateFrame("Frame", nil, group.holder)
		slot.cell = Z.FakeCell(slot)
		slot.cell:SetPoint("CENTER")
		group.slots[i] = slot
	end
	col.group = group

	-- Mode test : le faux groupe posé à l'écran. Un clic ouvre, un second clic sur le même nombre ferme.
	col.testTitle = UI.Heading(col, 13)
	col.testTitle:SetPoint("TOPLEFT", group, "BOTTOMLEFT", 0, -14)
	col.testTitle:SetText(L["Mode test"])
	local choices = {}
	for i, count in ipairs(TEST_SIZES) do choices[i] = { count, tostring(count) } end
	local test = UI.Segmented(col, "", choices, function() return Z.previewActive and Z:PreviewSize() or nil end,
		function(count) Z:TogglePreview(count) end)
	test:SetWidth(STAGE_W)
	test:SetPoint("TOPLEFT", col.testTitle, "BOTTOMLEFT", 0, -6)
	local each = math.floor((STAGE_W - 2) / #TEST_SIZES) - 2
	for i, b in ipairs(test.segments) do
		b:SetWidth(each)
		b:ClearAllPoints()
		b:SetPoint("LEFT", test.strip, "LEFT", 2 + (i - 1) * (each + 2), 0)
		b.tip = L["Faux groupe de %d joueurs."]:format(b.value)
		b:SetScript("OnClick", function(self)
			PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
			Z:TogglePreview(self.value) -- même nombre : ferme le mode test
			test:Update()
		end)
	end
	test.strip:SetWidth(2 + #TEST_SIZES * (each + 2))
	col.test = test
	col.testText = UI.Label(col, 11, nil, "dim")
	col.testText:SetPoint("TOPLEFT", test, "BOTTOMLEFT", 0, -6)
	col.testText:SetWidth(STAGE_W)
	col.testText:SetJustifyH("LEFT")
	col.testText:SetSpacing(2)
	-- Trouvé par la recherche (retour d'essai 22) : les boutons clignotent ici, sur le chapitre ouvert. Ils ont quitté
	-- Disposition pour cette colonne ; y mener le joueur ne lui montrait rien.
	local glow = UI.Paint(UI.Tex(col, "BORDER"), "accent", 0.35) -- au-dessus du fond de la colonne, sous les boutons
	glow:SetPoint("TOPLEFT", test.strip, "TOPLEFT", -4, 3)
	glow:SetPoint("BOTTOMRIGHT", test.strip, "BOTTOMRIGHT", 4, -3)
	glow:Hide()
	col.glow = glow
	local function Blink() -- trois éclats en 1,5 seconde ; un seul, fixe, avec « Réduire les mouvements »
		glow.count = (glow.count or 0) + 1 -- deux recherches de suite : seule la dernière décide
		local mine, steps = glow.count, Z.db.reduceMotion and 1 or 6
		local function Step(n)
			if glow.count ~= mine then return end
			glow:SetShown(n < steps and n % 2 == 0)
			if n < steps then C_Timer.After(steps == 1 and 1.5 or 0.25, function() Step(n + 1) end) end
		end
		Step(0)
	end
	searchIndex[#searchIndex + 1] = { text = Plain(L["Mode test"]), more = Plain(L[TEST_HINT]), widget = test,
		label = L["Mode test"], where = L["Case témoin"], Show = Blink }

	col.Update = function()
		local db = Z.db
		local width, height = Z.CellSize()
		stage.cell:SetScale(math.min(1.9, (STAGE_W - 24) / width, (STAGE_H - 24) / height))
		local _, _, hots = Z.DrawFakeCell(stage.cell, 2, true, width, height)
		stage.holder:SetAlpha(db.frameAlpha / 100)
		col.legend:SetText(WitnessLegend(hots))
		local mini = math.min(1, 74 / width, 34 / height)
		local w, h = width * mini, height * mini
		for i, slot in ipairs(group.slots) do
			local row, place = math.floor((i - 1) / 3), (i - 1) % 3
			local inRow = row == 0 and 3 or 2
			slot:SetSize(w, h)
			slot:ClearAllPoints()
			slot:SetPoint("TOPLEFT", (STAGE_W - inRow * w - (inRow - 1) * 3) / 2 + place * (w + 3), -8 - row * (h + 3))
			slot.cell:SetScale(mini)
			Z.DrawFakeCell(slot.cell, i, false, width, height)
		end
		group:SetHeight(16 + 2 * h + 3)
		group.holder:SetAlpha(db.frameAlpha / 100)
		test:Update()
		col.testText:SetText(Z.previewActive and L["Faux groupe de %d joueurs à l'écran. Recliquez pour le fermer."]:format(Z:PreviewSize())
			or L[TEST_HINT])
	end
	-- Après un réglage changé (effets magiques, au plus 3 éclairs par seconde) : éclat de soin sur la case, et sa
	-- vie qui remonte quand les barres sont animées (c'est le jeu qui anime la barre)
	local SMOOTH = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
	col.Spark = function()
		if not UI.Magic() or not col:IsVisible() or not UI.Flash() then return end
		stage.burst.Play()
		local hp = stage.cell.hp
		local health = hp:GetValue() -- valeur d'exemple de la fausse case, jamais celle d'un vrai joueur
		if Z.db.smooth and SMOOTH and health and health > 14 then
			hp:SetValue(health - 14)
			hp:SetValue(health, SMOOTH)
		end
	end
	witness, window.witness = col, col
	col:SetScript("OnShow", function() Z:Try("case témoin", col.Update) end)
	col.Update()
end

-- Mène à un réglage par sa clé, dans son chapitre (liste des réglages changés de l'Accueil)
local function GoToSetting(key, index)
	BuildChapter(index)
	for _, entry in ipairs(searchIndex) do
		if entry.key == key then return window.Go(entry) end
	end
end

----------------------------------------------------------------------------------------------------
-- Bas de la fenêtre, de chaque côté de l'inscription runique (retour d'essai de l'auteur) :
--   « Enregistrer mes réglages », toujours là : une petite case de nom s'ouvre au-dessus du bouton ; Entrée garde
--   les réglages du moment comme profil (Z:SaveProfile), Échap annule. On reste sur la page.
--   « Annuler mes changements », montré seulement si un réglage a changé depuis l'ouverture de la fenêtre : en deux
--   clics, tout reprend la valeur qu'il avait à l'ouverture (réglages, clics, listes, coins, placement). La copie
--   est prise à l'ouverture et gardée tant que la fenêtre n'est pas vraiment fermée : une fenêtre secondaire qui
--   l'efface (UI.Away) ou la visite guidée ne la ferment pas. Mes profils et les réglages propres à l'ordinateur
--   (Z.private) n'en font pas partie, sauf la liste des joueurs épinglés (une liste comme les autres, gardée hors
--   des profils partagés seulement) et mes macros (les clics qui les portent reviennent : leur macro aussi). En
--   combat, les clics reviennent à la fin du combat.
----------------------------------------------------------------------------------------------------
local opened -- les réglages copiés à l'ouverture de la fenêtre

local function Copy(value)
	return type(value) == "table" and CopyTable(value) or value
end

-- Réglages de Z.private repris quand même : « Joueurs épinglés » est une liste du chapitre Disposition, privée
-- seulement pour ne pas partir avec un profil partagé ; la bibliothèque de macros suit les clics (une macro
-- renommée ou supprimée puis « Annuler » : le clic revenu retrouve sa macro, sinon il ne ferait plus rien)
local UNDO_PRIVATE = { pinned = true, macros = true }

local function TakeCopy()
	local copy = {}
	for key in pairs(Z.defaults) do
		if not Z.private[key] or UNDO_PRIVATE[key] then copy[key] = Copy(Z.db[key]) end
	end
	return copy
end

-- Un réglage a changé depuis l'ouverture. Le profil en cours seul ne compte pas : enregistrer un profil ne change
-- aucun réglage (il revient quand même avec le reste, sinon le profil d'avant recevrait de mauvais réglages).
local function ChangedSinceOpen()
	if not opened then return false end
	for key, value in pairs(opened) do
		if key ~= "activeProfile" and not UI.Same(value, Z.db[key]) then return true end
	end
	return false
end

local function UndoChanges()
	if not opened then return end
	for key, value in pairs(opened) do Z.db[key] = Copy(value) end
	if Z.MacrosUndone then Z.MacrosUndone() end -- Mes macros, si elle est ouverte, reprend sa macro
	Z:Refresh()
	Z:RefreshAlerts()
	Z:ApplyClicks() -- en combat, attend la fin du combat (boutons protégés)
	if Z.RefreshClicks then Z.RefreshClicks() end
	RefreshShownPages()
	if witness then witness.Spark() end
	if InCombatLockdown() then Z:Print(L["vos clics reviendront à la fin du combat."]) end
end

UpdateFoot = function()
	if window and window.undo then window.undo:SetShown(ChangedSinceOpen()) end
end

-- Case de nom au-dessus de « Enregistrer mes réglages »
local function SaveBox(save)
	local box = CreateFrame("Frame", nil, window)
	box:SetSize(save:GetWidth(), 84) -- le message peut tenir sur deux lignes
	box:SetPoint("BOTTOMLEFT", save, "TOPLEFT", 0, 6)
	box:SetFrameLevel(window:GetFrameLevel() + 30) -- au-dessus de la barre latérale
	box:EnableMouse(true)
	box.bg = UI.Paint(UI.Tex(box, "BACKGROUND"), "bg", 0.98)
	box.bg:SetAllPoints()
	box.border = UI.Paint(UI.Border(box, 1), "line")
	box.title = UI.Label(box, 11)
	box.title:SetPoint("TOPLEFT", 8, -8)
	box.title:SetText(L["Nom du profil"])
	box.status = UI.Label(box, 10, nil, "dim")
	box.status:SetPoint("TOPLEFT", 8, -56)
	box.status:SetWidth(box:GetWidth() - 16)
	box.status:SetJustifyH("LEFT")

	local function Save(text)
		local ok, message = Z:SaveProfile(text)
		Say(box.status, ok, message)
		if not ok then return box.edit:SetFocus() end
		RefreshShownPages() -- Accueil (profil actif), Profils et partage
		box.done = message
		C_Timer.After(2.5, function()
			if box.done == message then box:Hide() end
		end)
	end
	box.edit = UI.Edit(box, box:GetWidth() - 16, Save)
	box.edit:SetPoint("TOPLEFT", 8, -26)
	Placeholder(box.edit, "Par exemple : Raid")
	box.edit:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		box:Hide()
	end)
	box:SetScript("OnShow", function()
		box.done = nil
		box.status:SetText(L["Entrée : enregistrer. Échap : annuler."])
		local active = Z.db.activeProfile
		box.edit:SetText(active ~= "" and Z.db.profiles[active] and active or "") -- le profil en cours, à remplacer
		box.edit:SetFocus()
	end)
	box:Hide()
	return box
end

local function BuildFoot()
	-- À gauche, sous la barre latérale ; en retrait des cadres épais (Classique, MMORPG)
	local save = UI.Button(window, L["Enregistrer mes réglages"], SIDE - 16, 22, function()
		if window.saveBox:IsShown() then window.saveBox:Hide() else window.saveBox:Show() end
	end)
	save:SetPoint("BOTTOMLEFT", 16, 7)
	save.label:SetJustifyH("CENTER")
	save.tip = L["Tout s'enregistre déjà tout seul. Ce bouton garde en plus vos réglages du moment sous un nom, comme profil : vous y reviendrez par Profils et partage. Vos clics et vos listes restent les mêmes dans tous les profils."]
	window.save, window.saveBox = save, SaveBox(save)

	-- À droite, sous la case témoin : montré seulement si un réglage a changé depuis l'ouverture
	local undo = ArmedButton(window, "Annuler mes changements", "Cliquez encore pour confirmer", 214, UndoChanges)
	undo:SetHeight(22)
	undo:SetPoint("BOTTOMRIGHT", -16, 7)
	undo.tip = L["Tout ce que vous avez changé depuis l'ouverture de cette fenêtre reprend sa valeur d'avant : réglages, clics, listes et macros. Vos profils enregistrés ne changent pas."]
	undo:Hide()
	window.undo = undo

	window:HookScript("OnShow", function()
		if not opened then opened = TakeCopy() end
		UpdateFoot()
	end)
	-- Fermée par le joueur : la copie est lâchée. Effacée par une fenêtre secondaire ou par la visite : gardée.
	window:HookScript("OnHide", function()
		window.saveBox:Hide()
		if not (UI.Away() or Z.TutorialRunning and Z:TutorialRunning() or Z.WizardRunning and Z:WizardRunning()) then
			opened = nil
		end
	end)
end

-- Pour les tests : la copie prise à l'ouverture de la fenêtre
function Z:OptionsOpenedCopy()
	return opened
end

-- Une fenêtre qui a fermé les options en gardant la copie (la visite) ne les rend pas : la copie est lâchée, sinon
-- « Annuler mes changements » reprendrait plus tard des changements faits hors de la fenêtre
function Z:ForgetOptionsCopy()
	opened = nil
	UpdateFoot()
end

-- Hauteur de la fenêtre : jamais plus haute que l'écran moins 60 pixels, la page du chapitre défile
function Z.OptionsHeight(screen)
	screen = screen or 0
	return screen > 400 and math.min(HEIGHT, math.floor(screen - 60)) or HEIGHT
end

-- Hauteur de la fenêtre et pas des boutons de la barre latérale, refaits à chaque ouverture et quand l'écran
-- change (UI.Fit) ; screen : hauteur de l'écran dans l'échelle de la fenêtre
local function Stretch(screen)
	local height = Z.OptionsHeight(screen)
	window:SetHeight(height)
	local step = math.min(40, math.floor((height - HEAD - FOOT - 16) / #chapters))
	for i, chapter in ipairs(chapters) do
		chapter.button:SetSize(SIDE - 20, step - 2)
		chapter.button:SetPoint("TOPLEFT", 5, -8 - (i - 1) * step)
	end
end

local function Build()
	window = UI.Window("LyoruneOptions", "Lyorune", WIDTH, HEIGHT)
	tinsert(UISpecialFrames, "LyoruneOptions")
	UI.main = window -- les fenêtres secondaires s'ouvrent à côté d'elle (UI.PlaceBeside)
	chapters = Chapters()
	-- Changement de thème : le numéro de version du titre et les couleurs écrites dans un texte (« |cff... ») ou
	-- données à la main (noms des coins) suivent, sur les pages affichées
	local function Recolor()
		window.title:SetText("Lyorune  |cff" .. UI.Hex("dim") .. Z.version .. "|r")
		if window:IsShown() then RefreshShownPages() end
	end
	Recolor()
	UI.OnSkin(Recolor)

	-- Barre latérale : un bouton par chapitre (rune, nom, pastille des réglages changés)
	local side = CreateFrame("Frame", nil, window)
	side:SetPoint("TOPLEFT", 10, -HEAD)
	side:SetPoint("BOTTOMLEFT", 10, FOOT)
	side:SetWidth(SIDE - 10)
	side.bg = UI.Paint(UI.Tex(side, "BACKGROUND"), "side", "sideAlpha") -- un ton à part de la page
	side.bg:SetAllPoints()
	side.line = UI.Paint(UI.Tex(side, "ARTWORK"), "line")
	side.line:SetWidth(1)
	side.line:SetPoint("TOPRIGHT")
	side.line:SetPoint("BOTTOMRIGHT")
	window.side = side
	for i, chapter in ipairs(chapters) do
		chapter.button = UI.SideButton(side, chapter.rune, L[chapter.name], function() Select(i) end)
	end
	window.Stretch = Stretch
	UI.Fit(window)

	-- Logo dans l'en-tête : il respire lentement (coupé par « Animations réduites »)
	local logo = window:CreateTexture(nil, "ARTWORK")
	logo:SetTexture("Interface\\AddOns\\Lyorune\\Media\\Logo")
	logo:SetSize(26, 26)
	logo:SetPoint("TOPLEFT", 16, -11)
	window.title:SetPoint("TOPLEFT", 48, -16)
	window.logo, window.breath = logo, UI.Breathe(logo, 0.85, 12) -- souffle doux et lent : 12 s par respiration
	window:HookScript("OnShow", function()
		if not UI.Calm() then window.breath:Play() end
		AfterChange() -- réglages changés pendant que la fenêtre était fermée (commande, assistant, profil)
	end)
	window:HookScript("OnHide", function()
		window.breath:Stop()
		if Z.QueueBuffPanel then Z:QueueBuffPanel() end -- l'exemple des buffs manquants s'en va
	end)
	window:HookScript("OnShow", function() if Z.QueueBuffPanel then Z:QueueBuffPanel() end end)

	-- Bas de la fenêtre : un trait sur toute la largeur, puis l'inscription runique au milieu (Runes.lua)
	window.foot = UI.Paint(UI.Tex(window, "ARTWORK"), "line")
	window.foot:SetHeight(1)
	window.foot:SetPoint("BOTTOMLEFT", 10, FOOT)
	window.foot:SetPoint("BOTTOMRIGHT", -10, FOOT)
	BuildFoot() -- Enregistrer mes réglages, Annuler mes changements

	BuildSearch()
	BuildWitness()
	-- Nouveautés, à gauche de la recherche : toujours à portée, quel que soit le chapitre ouvert
	local news = UI.Button(window, L["Nouveautés"], 96, 22, function() Z:ShowNews() end)
	news:SetPoint("RIGHT", window.search, "LEFT", -8, 0)
	news.label:SetJustifyH("CENTER")
	news.tip = L["Relire les nouveautés de chaque version, avec « Me montrer » pour aller au réglage."]
	window.news = news
	window.magic = UI.HeaderMagic(window, logo, news)
	if Z.RefreshRunes then Z:RefreshRunes(window) end
	window.Select, window.GoToSetting = Select, GoToSetting
	window.chapters = chapters
	Select(1, true) -- l'Accueil à la première ouverture de la partie
end

-- Le chapitre ouvert (son nom), ou nil si la fenêtre n'a jamais été ouverte
function Z:OptionChapter()
	return current and chapters[current] and chapters[current].name
end

-- Z:ToggleOptions() ouvre ou ferme. Z:ToggleOptions("Clics") ouvre sur un chapitre (nom, ou ancien nom d'onglet).
function Z:ToggleOptions(chapter)
	if not window then Build() end
	-- pendant le fondu de fermeture, la fenêtre est encore montrée : l'ouvrir arrête le fondu
	if chapter then
		Select(chapter)
		UI.Reopen(window)
	elseif window:IsShown() and not window.outro:IsPlaying() then
		window:Hide()
	else
		UI.Reopen(window)
	end
end

-- Ouvre les options sur un réglage, par sa clé (« Me montrer » des nouveautés) : son chapitre, la ligne mise en
-- lumière. Faux si le réglage n'a pas de ligne dans les options.
function Z:GoToOption(key)
	if not window then Build() end
	local index = ChapterIndex(Z.TabOfSetting(key) or "")
	if not index then return false end
	UI.Reopen(window)
	GoToSetting(key, index)
	return true
end

-- Pour les tests : les icônes des macros de barre, une case de clic
function Z:BarIcons()
	return barIcons
end

-- La ligne d'un raccourci dans le chapitre Sorts et raccourcis (bouton du sort, puis la ligne) ; kind : "click" ou "key"
function Z:ClickCell(key, kind, variant) -- variant : "enemy", "pvp", "ooc" pour une sous-ligne
	for _, row in ipairs(rows) do
		if row.binding and row.binding.key == key and row.binding.kind == (kind or "click") and row:IsShown()
			and (row.variant and row.variant[1]) == variant then return row.spell, row end
	end
end

-- Pour les tests : les chapitres, leurs boutons et leurs pages
function Z:OptionsTabs()
	return chapters
end

function Z:OptionsWindow()
	return window
end

-- Pour les tests : chapitres où chaque réglage a sa ligne (un réglage n'en a qu'une)
function Z:OptionKeys()
	Z:OptionLabels()
	local keys = {}
	for _, entry in ipairs(searchIndex) do
		if entry.key then
			keys[entry.key] = keys[entry.key] or {}
			table.insert(keys[entry.key], chapters[entry.chapter].name)
		end
	end
	return keys
end

-- Pour les tests : libellés de tous les réglages, après construction de tous les chapitres
function Z:OptionLabels()
	if not window then Build() end
	for i = 1, #chapters do BuildChapter(i) end
	local labels = {}
	for _, entry in ipairs(searchIndex) do labels[#labels + 1] = entry.label end
	return labels
end
