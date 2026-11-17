-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Options.lua : la fenêtre /lyorune.
-- Huit onglets, un sujet par onglet, chaque réglage à un seul endroit :
--   Cadres       où et comment les cases sont rangées
--   Apparence    à quoi elles ressemblent
--   Indicateurs  ce qui s'affiche dessus
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
	local label = UI.Text(f, 13)
	label:SetPoint("BOTTOMLEFT", 0, 4)
	label:SetText(L[text])
	label:SetTextColor(UI.accent[1], UI.accent[2], UI.accent[3])
	local line = UI.Tex(f, "ARTWORK", UI.line[1], UI.line[2], UI.line[3])
	line:SetPoint("BOTTOMLEFT")
	line:SetPoint("BOTTOMRIGHT")
	line:SetHeight(1)
	return f
end

local function Note(parent, text, x, y, width)
	local note = UI.Text(parent, 11)
	note:SetPoint("TOPLEFT", x, y)
	note:SetWidth(width or (WIDTH - 48))
	note:SetJustifyH("LEFT")
	note:SetSpacing(3)
	note:SetTextColor(UI.dim[1], UI.dim[2], UI.dim[3])
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

-- Préréglage de transparence : opacité des cadres et opacité hors de portée
local function OpacityButton(label, frameAlpha, rangeAlpha)
	return { "button", label, function()
		Z.db.frameAlpha, Z.db.rangeAlpha = frameAlpha, rangeAlpha
		Z:Refresh()
		for _, tab in ipairs(tabs) do -- les valeurs affichées suivent
			if tab.page and tab.page:IsShown() then tab.page:Hide() tab.page:Show() end
		end
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
				{ "check", "autoShrink", "Réduire les cases en grand raid", "Au-delà de 10 joueurs les cases rétrécissent de 15 %, au-delà de 25 de 30 %." },
				{ "head", "Rangement" },
				{ "cycle", "layout", "Rangement des joueurs" },
				{ "cycle", "roleOrder", "Ordre des rôles", nil, "Utilisé quand le rangement est « Par rôle »." },
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
				{ "check", "hideBlizzard", "Masquer les cadres de groupe du jeu", "Expérimental. Pour les faire revenir, décochez puis tapez /reload." },
				{ "head", "Mode test" },
				{ "note", "Affiche un faux groupe pour régler l'apparence. Recliquez pour le fermer.", 30 },
				PreviewButton(5), PreviewButton(10), PreviewButton(25), PreviewButton(40),
			},
		},
		Apparence = {
			{
				{ "head", "Style" },
				{ "cycle", "theme", "Thème", ThemeChoices() },
				{ "cycle", "texture", "Texture des barres", TextureChoices() },
				{ "check", "highContrast", "Contraste élevé", "Fond noir, bordure blanche, texte plus gros : pour une lecture facile." },
				{ "check", "smooth", "Barres animées" },
				{ "head", "Texte" },
				{ "cycle", "text", "Texte de vie" },
				{ "step", "fontSize", "Taille du texte" },
			},
			{
				{ "head", "Couleurs et transparence" },
				{ "cycle", "color", "Couleur des barres" },
				{ "step", "brightness", "Luminosité des barres (%)" },
				{ "step", "frameAlpha", "Opacité des cadres (%)" },
				{ "step", "rangeAlpha", "Opacité hors de portée (%)" },
				{ "head", "Préréglages de transparence" },
				{ "note", "Un rendu en un clic, à ajuster ensuite avec les trois réglages ci-dessus.", 30 },
				OpacityButton("Discret", 55, 25),
				OpacityButton("Semi-transparent", 80, 35),
				OpacityButton("Bien visible", 100, 45),
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
				{ "head", "Joueur" },
				{ "check", "showRole", "Icône de rôle (tank, soigneur)" },
				{ "check", "showMarker", "Marqueur de raid" },
				{ "check", "showThreat", "Bordure rouge quand il est attaqué" },
				{ "check", "showSummonPhase", "Invocation en cours, autre phase", "Icône au centre de la case : invocation proposée, acceptée ou refusée, ou joueur dans une autre phase (proche en apparence, mais hors d'atteinte)." },
				{ "check", "showTooltip", "Infobulle au survol (hors combat)" },
				{ "check", "clickTooltip", "Mes clics dans l'infobulle", "Au survol d'une case, hors combat : chaque clic et chaque touche avec son sort ou sa macro." },
			},
			{
				{ "head", "Mes soins" },
				{ "check", "showHots", "Mes soins sur la durée" },
				{ "cycle", "hotStyle", "Affichage des soins sur la durée" },
				{ "check", "missingBuffs", "Buff de groupe manquant (hors combat)", "Icône grise en bas à gauche quand un joueur n'a pas votre buff de groupe." },
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
local cells, hoverRows, barIcons = {}, {}, {}

local function SpellText(value)
	return Z:ActionText(value)
end

local RefreshClicks -- définie plus bas
local specLabel, specCopy

local function CellText(key)
	local value = Z:GetClicks()[key]
	if value and value ~= "" then return SpellText(value) end
	if key:match("^1$") or key:match("%-1$") then return "|cff8a8f99" .. L["Cibler"] .. "|r" end
	if key:match("2$") then return "|cff8a8f99" .. L["Menu du joueur"] .. "|r" end
	return "|cff555a63-|r"
end

function RefreshClicks()
	for key, cell in pairs(cells) do cell.label:SetText(CellText(key)) end
	local keys = Z:GetHoverKeys()
	for i, row in ipairs(hoverRows) do
		local entry = keys[i]
		row.key.label:SetText(entry and entry.key or "|cff555a63" .. L["Touche"] .. "|r")
		row.spell.label:SetText(entry and entry.spell ~= "" and SpellText(entry.spell) or "|cff555a63" .. L["Sort"] .. "|r")
		row.clear:SetShown(entry ~= nil)
		row:SetShown(i <= #keys + 1) -- une seule ligne vide à la fois
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
Z.RefreshClicks = function() if RefreshClicks then RefreshClicks() end end

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
		picker.hint:SetTextColor(UI.dim[1], UI.dim[2], UI.dim[3])
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
		picker.macroHead:SetTextColor(UI.accent[1], UI.accent[2], UI.accent[3])
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

-- Attend la prochaine touche (clavier, bouton de souris supplémentaire ou molette) et la renvoie
local MODIFIER_KEYS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, LMETA = true, RMETA = true }

local function CaptureKey(button, onKey)
	local function Finish(key)
		button:EnableKeyboard(false)
		button:EnableMouseWheel(false)
		button:SetScript("OnKeyDown", nil)
		button:SetScript("OnMouseWheel", nil)
		button:SetScript("OnMouseDown", nil)
		if key then
			local prefix = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "")
			onKey(prefix .. key)
		end
		RefreshClicks()
	end
	button.label:SetText("|cff33dd88" .. L["Appuyez..."] .. "|r")
	button:EnableKeyboard(true)
	button:EnableMouseWheel(true)
	button:SetScript("OnKeyDown", function(_, key)
		if MODIFIER_KEYS[key] then return end
		Finish(key ~= "ESCAPE" and key or nil)
	end)
	button:SetScript("OnMouseWheel", function(_, delta) Finish(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end)
	button:SetScript("OnMouseDown", function(_, mouse)
		local number = mouse:match("^Button(%d+)$") -- boutons supplémentaires des souris MMO
		if mouse == "MiddleButton" then Finish("BUTTON3") elseif number then Finish("BUTTON" .. number) end
	end)
end

local function BuildClicks(page)
	Note(page, "Clics de souris : cliquez sur une cellule pour choisir le sort ou la macro lancé sur la case d'un joueur. Vous pouvez aussi y glisser un sort du grimoire.", 0, 0, 420)

	-- Spécialisation dont on voit les clics, et copie depuis l'autre
	specLabel = UI.Text(page, 11)
	specLabel:SetPoint("TOPRIGHT", 0, 0)
	specLabel:SetTextColor(UI.accent[1], UI.accent[2], UI.accent[3])
	specCopy = UI.Button(page, L["Copier l'autre spécialisation"], 200, 18, function()
		Z:CopyOtherSpec()
		RefreshClicks()
	end)
	specCopy:SetPoint("TOPRIGHT", 0, -15)
	specCopy.label:SetJustifyH("CENTER")
	specCopy.tip = L["Remplace les clics et les touches de cette spécialisation par ceux de l'autre."]

	local left, top, cellWidth, cellHeight = 96, -44, 132, 24
	for column, modifier in ipairs(Z.clickModifiers) do
		local head = UI.Text(page, 12)
		head:SetPoint("TOP", page, "TOPLEFT", left + (column - 1) * (cellWidth + 4) + cellWidth / 2, top + 18)
		head:SetText(L[modifier[2]])
		head:SetTextColor(UI.accent[1], UI.accent[2], UI.accent[3])
	end
	for row, button in ipairs(Z.clickButtons) do
		local y = top - (row - 1) * (cellHeight + 4)
		local label = UI.Text(page, 12)
		label:SetPoint("LEFT", page, "TOPLEFT", 0, y - cellHeight / 2)
		label:SetText(L[button[2]])
		for column, modifier in ipairs(Z.clickModifiers) do
			local key = modifier[1] .. button[1]
			local cell = UI.Button(page, "", cellWidth, cellHeight, function()
				local held = Z:TakeCursor() -- un sort ou une macro tenu sous la souris est posé directement
				if held then
					Z:SetClick(key, held)
					return RefreshClicks()
				end
				OpenPicker(Z:ClickLabel(key), function(value) Z:SetClick(key, value) end, Z:GetClicks()[key])
			end)
			Droppable(cell, function(value) Z:SetClick(key, value) end)
			cell:SetPoint("TOPLEFT", left + (column - 1) * (cellWidth + 4), y)
			cell.label:SetJustifyH("CENTER")
			cells[key] = cell
		end
	end

	-- Touches au survol
	local head = Heading(page, "Touches au survol")
	head:SetPoint("TOPLEFT", 0, -196)
	Register(page.tabIndex, L["Touches au survol"], head)
	Note(page, "Une touche du clavier, un bouton de souris supplémentaire ou la molette lance un sort sur la case survolée. Cliquez sur « Touche », puis appuyez.", 0, -224, COLUMN)
	for i = 1, Z.MAX_HOVER_KEYS do
		local row = CreateFrame("Frame", nil, page)
		row:SetSize(COLUMN, 22)
		row:SetPoint("TOPLEFT", 0, -262 - (i - 1) * 25)
		row.key = UI.Button(row, "", 110, 22, function(self)
			CaptureKey(self, function(key)
				local keys = Z:GetHoverKeys()
				keys[i] = keys[i] or { spell = "" }
				keys[i].key = key
				Z:ApplyClicks()
			end)
		end)
		row.key:SetPoint("LEFT")
		row.key.label:SetJustifyH("CENTER")
		row.spell = UI.Button(row, "", 150, 22, function()
			OpenPicker(L["Touche au survol"] .. " " .. i, function(value)
				local keys = Z:GetHoverKeys()
				if keys[i] then
					keys[i].spell = value or ""
					Z:ApplyClicks()
				end
			end, (Z:GetHoverKeys()[i] or {}).spell)
		end)
		row.spell:SetPoint("LEFT", row.key, "RIGHT", 4, 0)
		row.spell.label:SetJustifyH("CENTER")
		Droppable(row.spell, function(value)
			local keys = Z:GetHoverKeys()
			if keys[i] then
				keys[i].spell = value
				Z:ApplyClicks()
			end
		end)
		row.clear = UI.Button(row, "x", 22, 22, function()
			table.remove(Z:GetHoverKeys(), i)
			Z:ApplyClicks()
			RefreshClicks()
		end)
		row.clear:SetPoint("LEFT", row.spell, "RIGHT", 4, 0)
		row.clear.label:SetJustifyH("CENTER")
		hoverRows[i] = row
	end

	-- Mes macros et spécialisations
	local library = BuildItem(page, { "button", "Mes macros...", function() Z:OpenMacros() end,
		"Votre bibliothèque de macros : écrire, vérifier, importer de /macro, puis glisser sur un clic." })
	library:SetPoint("TOPLEFT", 0, -470)
	local perSpec = BuildItem(page, { "check", "clicksPerSpec", "Clics propres à chaque spécialisation",
		"Chaque groupe de talents a ses clics et ses touches ; ils changent tout seuls avec vos talents. Décoché : les mêmes partout." })
	perSpec:SetPoint("TOPLEFT", 0, -500)

	-- Comportement
	local x = COLUMN + 32
	local options = {
		{ "head", "Comportement" },
		{ "check", "castOnDown", "Lancer le sort dès l'appui (plus rapide)" },
		{ "check", "autoRes", "Le même clic relève un joueur mort", "Si la cible est morte, votre sort de soin est remplacé par votre résurrection." },
		{ "check", "externalClicks", "Laisser Clique ou le jeu gérer les clics", "À cocher seulement si vous préférez Clique ou le clic-soin du jeu : les clics de Lyorune sont alors coupés." },
		{ "head", "Macros pour vos barres de sorts" },
		{ "check", "actionBarMacros", "Créer une macro par sort de mes clics", "Lyorune crée et tient à jour de vraies macros du jeu (leur nom commence par « Lyo: »), rangées dans /macro, onglet de votre personnage. Il ne touche à aucune autre macro." },
		{ "note", "Cliquez sur une icône, puis déposez-la dans une barre de sorts. La macro vise le joueur sous la souris, sinon votre cible, sinon vous.", 44 },
	}
	local y = -196
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

	page:SetScript("OnShow", RefreshClicks)
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

	-- Colonne de gauche : points de départ et remise à zéro
	local presets = Heading(page, "Profils prêts à l'emploi")
	presets:SetPoint("TOPLEFT")
	Register(page.tabIndex, L["Profils prêts à l'emploi"], presets)
	Note(page, "Un point de départ en un clic. Seules la taille et la disposition changent ; vos clics sont conservés.", 0, -30, COLUMN)
	for i, preset in ipairs(Z.presets) do
		local button = UI.Button(page, L[preset[2]], 150, 24, function() Z:ApplyPreset(preset[1]) end)
		button:SetPoint("TOPLEFT", ((i - 1) % 2) * 156, -70 - math.floor((i - 1) / 2) * 29)
		button.label:SetJustifyH("CENTER")
	end

	local clicksHead = Heading(page, "Remise à zéro")
	clicksHead:SetPoint("TOPLEFT", 0, -140)
	local clicks = UI.Button(page, L["Reprendre les clics proposés pour ma classe"], COLUMN, 24, function()
		Z.db.clicks[Z.class] = nil
		Z:BuildData()
		Z:ApplyClicks()
		result:SetText("|cff33dd88" .. L["Clics de la classe rétablis."] .. "|r")
	end)
	clicks:SetPoint("TOPLEFT", 0, -172)
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
		result:SetText("|cff33dd88" .. L["Tous les réglages sont revenus à l'origine."] .. "|r")
	end)
	reset:SetPoint("TOPLEFT", 0, -202)
	reset.label:SetJustifyH("CENTER")
	reset.tip = L["Remet tous les réglages d'origine. La position des cadres est conservée."]
	Register(page.tabIndex, L["Tout réinitialiser"], reset)

	local sync = Heading(page, "Entre joueurs")
	sync:SetPoint("TOPLEFT", 0, -244)
	local accept = BuildItem(page, { "check", "acceptConfigs", "Accepter qu'on me propose une configuration", "Rien n'est appliqué sans votre accord : une fenêtre vous demande." })
	accept:SetPoint("TOPLEFT", 0, -276)
	local notice = BuildItem(page, { "check", "versionNotice", "Me prévenir si une version plus récente existe" })
	notice:SetPoint("TOPLEFT", 0, -303)

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

	result = Note(page, "", right, -236, COLUMN)
	page:SetScript("OnShow", FillExport)
	FillExport()
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
	local list = UI.Text(page, 12)
	list:SetPoint("TOPLEFT", commands, "BOTTOMLEFT", 0, -8)
	list:SetJustifyH("LEFT")
	list:SetSpacing(4)
	list:SetText("|cff33dd88/lyorune|r  " .. L["ouvrir cette fenêtre"] .. "\n|cff33dd88/lyorune test|r  " .. L["mode test (faux groupe)"]
		.. "\n|cff33dd88/lyorune tuto|r  " .. L["relancer le tutoriel"] .. "\n|cff33dd88/lyorune verrou|r  " .. L["verrouiller ou libérer la position"]
		.. "\n|cff33dd88/lyorune bug|r  " .. L["signaler un bug"] .. "\n|cff33dd88/lyorune diag|r  " .. L["compatibilité avec le jeu"])

	local items = {
		{ "head", "Découvrir" },
		{ "button", "Lancer le tutoriel", function() window:Hide() Z:StartTutorial() end },
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
	tab.page:SetPoint("BOTTOMRIGHT", -24, 20)
	tab.page.tabIndex = index
	tab.page:Hide()
	if tab.columns then
		BuildColumns(tab.page, tab.columns)
	else
		Z:Try("onglet " .. tab.name, tab.build, tab.page)
	end
end

local function Select(index)
	if type(index) == "string" then -- par nom : Z:ToggleOptions("Clics")
		for i, tab in ipairs(tabs) do
			if tab.name == index then index = i end
		end
		if type(index) == "string" then index = 1 end
	end
	BuildPage(index)
	for i, tab in ipairs(tabs) do
		if tab.page then tab.page:SetShown(i == index) end
		tab.button.bg:SetVertexColor(unpack(i == index and UI.line or UI.panel))
	end
	if picker then picker:Hide() end
end

-- Recherche : liste les réglages dont le nom contient le texte tapé ; un clic y mène
local function BuildSearch()
	local results = CreateFrame("Frame", nil, window)
	results:SetFrameStrata("FULLSCREEN_DIALOG")
	results:SetSize(260, 10)
	results.bg = UI.Tex(results, "BACKGROUND", UI.bg[1], UI.bg[2], UI.bg[3], 0.98)
	results.bg:SetAllPoints()
	results.border = UI.Border(results, 1)
	results.border:SetColor(UI.line[1], UI.line[2], UI.line[3])
	results.rows = {}
	results:Hide()

	local flash = UI.Tex(window, "OVERLAY", UI.accent[1], UI.accent[2], UI.accent[3], 0.35)
	flash:Hide()

	local edit = UI.Edit(window, 170)
	edit:SetPoint("TOPRIGHT", -42, -11)
	edit.placeholder = UI.Text(edit, 11)
	edit.placeholder:SetPoint("LEFT", 6, 0)
	edit.placeholder:SetTextColor(UI.dim[1], UI.dim[2], UI.dim[3])
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

	local simple = SimpleTabs()
	tabs = {
		{ name = "Cadres", columns = simple.Cadres },
		{ name = "Apparence", columns = simple.Apparence },
		{ name = "Indicateurs", columns = simple.Indicateurs },
		{ name = "Listes", build = BuildLists },
		{ name = "Clics", build = BuildClicks },
		{ name = "Alertes", build = BuildAlerts },
		{ name = "Profils", build = BuildProfiles },
		{ name = "Aide", build = BuildHelp },
	}
	local tabWidth = math.floor((WIDTH - 48 - (#tabs - 1) * 4) / #tabs)
	for i, tab in ipairs(tabs) do
		tab.button = UI.Button(window, L[tab.name], tabWidth, 26, function() Select(i) end)
		tab.button:SetPoint("TOPLEFT", 24 + (i - 1) * (tabWidth + 4), -50)
		tab.button.label:SetJustifyH("CENTER")
	end
	BuildSearch()
	if Z.RefreshRunes then Z:RefreshRunes(window) end
	window.Select = Select
	Select(1)
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

function Z:ClickCell(key)
	return cells[key]
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
