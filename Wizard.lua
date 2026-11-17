-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Wizard.lua : assistant du premier lancement. Trois questions (rôle, taille de groupe habituelle,
-- forme des cases), puis la visite guidée. Relancé à la demande (/lyorune assistant, onglet Aide).
-- Chaque réponse ne touche que quelques réglages, tous retouchables ensuite dans les options.

local _, Z = ...
local UI = Z.UI

local WIDTH = 360
local window, page, answers
local pages = {}

-- Ce que chaque réponse change. Un soigneur garde les réglages d'origine, pensés pour lui.
Z.wizardRoles = {
	HEALER  = { debuffMode = "ALL", manaBars = "ALL", threatBar = false },
	TANK    = { debuffMode = "DISPEL", manaBars = "HEALERS", threatBar = true },  -- qui prend l'attention du monstre
	DAMAGER = { debuffMode = "DISPEL", manaBars = "HEALERS", threatBar = false }, -- seulement ce que je peux dissiper
}
Z.wizardSizes = {
	SMALL  = { autoShrink = false, showSolo = true, layout = "GROUP", shape = "TILE" },
	MEDIUM = { autoShrink = false, showSolo = true, layout = "GROUP", shape = "TILE" },
	LARGE  = { autoShrink = true, showSolo = true, layout = "GROUP", shape = "SQUARE" }, -- 40 joueurs : cases plus petites
}

-- Rôle proposé d'emblée : celui de ma spécialisation si le jeu le donne, sinon soigneur pour une classe de soin
local function GuessRole()
	local info = C_SpecializationInfo
	local getSpec = info and info.GetSpecialization or GetSpecialization
	local getRole = info and info.GetSpecializationRole or GetSpecializationRole
	if getSpec and getRole then
		local ok, role = pcall(function()
			local spec = getSpec()
			return spec and getRole(spec)
		end)
		if ok and role and Z.wizardRoles[role] then return role end
	end
	return Z.classRes[Z.class] and "HEALER" or "DAMAGER" -- les classes qui relèvent les morts sont celles qui soignent
end

-- Applique les réponses (la forme est déjà posée par sa vignette, en direct)
function Z:ApplyWizard(role, size)
	for key, value in pairs(Z.wizardRoles[role] or {}) do Z.db[key] = value end
	for key, value in pairs(Z.wizardSizes[size] or {}) do
		if key ~= "shape" then Z.db[key] = value end
	end
	Z:Refresh()
end

----------------------------------------------------------------------------------------------------
-- Fenêtre
----------------------------------------------------------------------------------------------------
-- Bouton de réponse : fond et texte à la couleur d'accent quand il est choisi
local function Paint(button, chosen)
	UI.Paint(button.bg, chosen and "accent" or "panel", 1, chosen and 0.45 or nil)
	UI.Paint(button.border, chosen and "accent" or "line")
	UI.Paint(button.label, chosen and "accent" or "btext")
end

local function Choices(parent, key, list)
	local buttons = {}
	local function Update()
		for _, b in ipairs(buttons) do Paint(b, answers[key] == b.value) end
	end
	for i, choice in ipairs(list) do
		local b = UI.Button(parent, Z.L[choice[2]], WIDTH - 36, 30, function(self)
			answers[key] = self.value
			if key == "size" then -- taille de groupe : la forme conseillée devient le choix par défaut
				answers.shape = Z.wizardSizes[self.value].shape
			end
			Update()
		end)
		b.value = choice[1]
		b.tip = choice[3] and Z.L[choice[3]]
		b:SetPoint("TOPLEFT", 18, -86 - (i - 1) * 36)
		buttons[i] = b
	end
	parent.Update, parent.buttons = Update, buttons
end

local function Question(parent, text)
	local label = UI.Label(parent, 13)
	label:SetPoint("TOPLEFT", 18, -50)
	label:SetWidth(WIDTH - 36)
	label:SetJustifyH("LEFT")
	label:SetText(Z.L[text])
end

local function ShapePage(parent)
	local thumbs = {}
	local function Update()
		for _, thumb in ipairs(thumbs) do thumb:Draw() end
	end
	for index, choice in ipairs(Z.choices.shape) do
		local thumb = Z.ShapeThumb(parent, choice[1], choice[2], function(self)
			answers.shape = self.id
			Update()
		end)
		thumb:SetPoint("TOPLEFT", 25 + ((index - 1) % 2) * 160, -86 - math.floor((index - 1) / 2) * 68)
		thumbs[index] = thumb
	end
	local real = UI.Button(parent, Z.L["Voir en vrai"], WIDTH - 36, 26, function()
		Z:TogglePreview(not Z.previewActive and 10 or nil)
	end)
	real:SetPoint("TOPLEFT", 18, -226)
	real.label:SetJustifyH("CENTER")
	real.tip = Z.L["Affiche un faux groupe de 10 joueurs avec la forme choisie. Recliquez pour le fermer."]
	parent.Update, parent.thumbs = Update, thumbs
end

local function Finish(apply)
	if apply then Z:ApplyWizard(answers.role, answers.size) end
	if Z.previewActive then Z:TogglePreview() end
	Z.db.wizardDone = true
	window:Hide()
	if not Z.db.tutorialDone then C_Timer.After(0.5, function() Z:StartTutorial() end) end
end

local function Show(index)
	page = index
	if pages[index].isShapes and answers.shape ~= Z.db.shape then Z:ApplyShape(answers.shape) end
	for i, p in ipairs(pages) do p:SetShown(i == index) end
	pages[index]:Update()
	window.progress:SetText(index .. " / " .. #pages)
	window.back:SetShown(index > 1)
	window.next.label:SetText(index == #pages and Z.L["Terminer"] or Z.L["Suivant"])
end

local function Build()
	window = UI.Window("LyoruneWizard", Z.L["Bienvenue dans Lyorune"], WIDTH, 310)
	window:SetFrameStrata("FULLSCREEN_DIALOG")
	window.close:SetScript("OnClick", function() Finish(false) end)

	local questions = {
		{ "role", "Quel rôle jouez-vous le plus souvent ?", {
			{ "HEALER", "Soigneur", "Tous les affaiblissements et la mana de chacun." },
			{ "TANK", "Tank", "Les affaiblissements que vous pouvez dissiper, la mana des soigneurs et une barre de menace sur chaque case." },
			{ "DAMAGER", "Dégâts", "Les affaiblissements que vous pouvez dissiper et la mana des soigneurs." },
		} },
		{ "size", "Dans quel groupe jouez-vous le plus souvent ?", {
			{ "SMALL", "Seul, ou en groupe de 5" },
			{ "MEDIUM", "En raid de 10 à 25" },
			{ "LARGE", "En raid de 40", "Les cases rétrécissent quand le raid grandit." },
		} },
	}
	for i, q in ipairs(questions) do
		local p = CreateFrame("Frame", nil, window)
		p:SetAllPoints()
		Question(p, q[2])
		Choices(p, q[1], q[3])
		pages[i] = p
	end
	local shapes = CreateFrame("Frame", nil, window)
	shapes:SetAllPoints()
	shapes.isShapes = true
	Question(shapes, "Quelle forme de case préférez-vous ?")
	ShapePage(shapes)
	pages[#pages + 1] = shapes
	window.pages = pages

	window.progress = UI.Label(window, 11, nil, "dim")
	window.progress:SetPoint("BOTTOMLEFT", 18, 22)
	window.next = UI.Button(window, Z.L["Suivant"], 96, 26, function()
		if page == #pages then Finish(true) else Show(page + 1) end
	end)
	window.next:SetPoint("BOTTOMRIGHT", -14, 14)
	window.next.label:SetJustifyH("CENTER")
	UI.Paint(window.next.bg, "accent", 1, 0.45)
	window.back = UI.Button(window, Z.L["Précédent"], 96, 26, function() Show(page - 1) end)
	window.back:SetPoint("RIGHT", window.next, "LEFT", -6, 0)
	window.back.label:SetJustifyH("CENTER")
	local skip = UI.Button(window, Z.L["Passer"], 70, 26, function() Finish(false) end)
	skip:SetPoint("LEFT", window.progress, "RIGHT", 10, 0)
	skip.label:SetJustifyH("CENTER")
	skip.tip = Z.L["Garde les réglages actuels. L'assistant se relance avec /lyorune assistant."]
	UI.OnSkin(function() if window:IsShown() then pages[page]:Update() end end)
end

function Z:StartWizard()
	if not Z.header then return end
	if not window then Build() end
	answers = { role = GuessRole(), size = "SMALL", shape = Z.db.shape }
	Show(1)
	window:Show()
end

function Z:WizardWindow()
	return window
end
