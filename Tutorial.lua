-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Tutorial.lua : visite guidée, lancée au premier démarrage puis à la demande (/lyorune tuto).
-- Chaque étape a un titre, un texte, et peut encadrer un élément de l'écran.

local _, Z = ...
local UI = Z.UI

local card, highlight, current

-- Résumé des clics du joueur, écrit à partir de ses vrais réglages
local function ClickSummary()
	local lines = {}
	for _, button in ipairs(Z.clickButtons) do
		for _, modifier in ipairs(Z.clickModifiers) do
			local key = modifier[1] .. button[1]
			local value = Z:GetClicks()[key]
			local shown = Z.MacroRef(value) and Z.L["macro"] .. " " .. Z.MacroRef(value) or value
			if value and (value:sub(1, 1) ~= "@" or Z.MacroRef(value)) and #lines < 5 then
				lines[#lines + 1] = "|cff33dd88" .. Z:ClickLabel(key) .. "|r : " .. shown
			end
		end
	end
	if #lines == 0 then
		return Z.L["Aucun sort n'est encore attribué : vous les choisirez dans l'onglet Clics des options."]
	end
	return table.concat(lines, "\n")
end

local steps = {
	{
		title = "Bienvenue dans Lyorune",
		text = "Lyorune affiche votre groupe sous forme de cases et vous laisse soigner d'un simple clic.\n\n"
			.. "Cette visite dure une minute. Vous pourrez la relancer avec |cff33dd88/lyorune tuto|r.",
	},
	{
		title = "Une case par joueur",
		text = "La barre colorée est la vie du joueur : plus elle est courte, plus il est blessé.\n\n"
			.. "Le |cff73ff99vert clair|r au bout de la barre montre les soins déjà en route. "
			.. "La |cff8cd9ffbande bleue|r en bas est un bouclier.",
		target = function() return Z.buttons[1] end,
	},
	{
		title = "Soigner d'un clic",
		text = function()
			return Z.L["Cliquez sur une case pour lancer un sort sur ce joueur, sans le cibler."] .. "\n\n" .. ClickSummary()
		end,
		target = function() return Z.buttons[1] end,
	},
	{
		title = "Ce que disent les couleurs",
		text = "|cff3399ffBleu|r, |cffa633ffviolet|r, |cffbf801abrun|r ou |cff1ad933vert|r autour d'une case : "
			.. "une magie, une malédiction, une maladie ou un poison que VOUS pouvez dissiper.\n\n"
			.. "|cffff2626Bordure rouge|r : le joueur est attaqué. Case estompée : il est hors de portée.\n\n"
			.. "En haut à gauche : vos soins sur la durée. En bas à droite : ses affaiblissements.",
		target = function() return Z.buttons[1] end,
	},
	{
		title = "Placer les cadres",
		text = "Faites glisser l'étiquette |cff33dd88Groupe|r au-dessus des cases pour déplacer les cadres où vous voulez. "
			.. "En raid, chaque groupe a son numéro, et n'importe lequel déplace l'ensemble.\n\n"
			.. "Une fois satisfait, choisissez « Verrouillé » dans « Déplacement des cadres » (onglet Cadres), "
			.. "ou « Avec Alt » pour ne les déplacer qu'en maintenant la touche.\n\n"
			.. "Dans l'onglet Cadres, « Afficher les cadres » permet de les voir en permanence, ou seulement en combat.",
		target = function() return Z.header.handle end,
		before = function()
			if Z.db.lockMode ~= "FREE" then
				Z.db.lockMode = "FREE"
				Z:Refresh()
			end
		end,
	},
	{
		title = "Essayer sans groupe",
		text = "Le |cff33dd88mode test|r affiche un faux groupe pour régler l'apparence tranquillement : "
			.. "joueurs blessés, soins en route, dissipation, vie basse.\n\n"
			.. "Ouvrez-le avec |cff33dd88/lyorune test|r ou depuis l'onglet Cadres. Il se ferme tout seul en combat.",
		target = function() return LyorunePreview end,
		before = function() if not Z.previewActive then Z:TogglePreview(10) end end,
		after = function() if Z.previewActive then Z:TogglePreview() end end,
	},
	{
		title = "Régler Lyorune",
		text = "Tout se règle ici, et rien n'est obligatoire : chaque élément a sa case à cocher.\n\n"
			.. "|cff33dd88Cadres|r : taille, rangement, tanks, familiers, mode test.\n"
			.. "|cff33dd88Apparence|r : thème, couleurs, luminosité, texte.\n"
			.. "|cff33dd88Indicateurs|r : ce qui s'affiche sur une case.\n"
			.. "|cff33dd88Listes|r : vos sorts à suivre, les affaiblissements à ignorer.\n"
			.. "|cff33dd88Clics|r : souris, touches au survol, mes macros, spécialisations.\n"
			.. "|cff33dd88Alertes|r : annonces et sons.\n"
			.. "|cff33dd88Profils|r : profils prêts à l'emploi, partage.\n\n"
			.. "Un réglage introuvable ? Tapez un mot dans la recherche, en haut à droite.",
		target = function() return Z:OptionsWindow() end,
		before = function() Z:ToggleOptions("Clics") end,
		after = function()
			local window = Z:OptionsWindow()
			if window then window:Hide() end
		end,
	},
	{
		title = "C'est parti",
		text = "Vous savez l'essentiel. Bon soin !\n\nAstuce : avant un combat important, vérifiez l'onglet Clics. "
			.. "Les changements de clics et de taille demandés en combat s'appliquent dès qu'il se termine.\n\n"
			.. "Le bouton Lyorune au bord de la mini-carte ouvre les options (clic gauche) ou le mode test (clic droit).\n\n"
			.. "Un souci ou un défaut d'affichage ? Tapez |cff33dd88/lyorune bug|r : trois questions, "
			.. "et un rapport prêt à copier pour l'auteur.",
	},
}

local function Finish()
	local step = steps[current]
	if step and step.after then step.after() end
	current = nil
	card:Hide()
	highlight:Hide()
	Z.db.tutorialDone = true
end

local function Show(index)
	local previous = steps[current]
	if previous and previous.after then previous.after() end
	current = index
	local step = steps[index]
	if step.before then step.before() end

	local L = Z.L
	card.title:SetText(L[step.title])
	card.body:SetText(type(step.text) == "function" and step.text() or L[step.text])
	card.progress:SetText(index .. " / " .. #steps)
	card.back:SetShown(index > 1)
	card.next.label:SetText(index == #steps and L["Terminer"] or L["Suivant"])
	card:SetHeight(card.body:GetStringHeight() + 112)

	-- Encadre l'élément dont parle l'étape et place la carte à côté
	local target = step.target and step.target()
	card:ClearAllPoints()
	if target and target:IsVisible() then
		highlight:ClearAllPoints()
		highlight:SetPoint("TOPLEFT", target, "TOPLEFT", -5, 5)
		highlight:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 5, -5)
		highlight:Show()
		highlight.pulse:Play()
		if target:GetWidth() > 400 then
			card:SetPoint("TOPLEFT", target, "TOPRIGHT", 14, 0)
		else
			card:SetPoint("TOPLEFT", target, "BOTTOMRIGHT", 14, -14)
		end
	else
		highlight:Hide()
		card:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
	end
	card:Show()
end

local function Build()
	card = UI.Window("LyoruneTutorial", "", 380, 220)
	card:SetFrameStrata("FULLSCREEN_DIALOG")
	card.close:SetScript("OnClick", Finish)
	card.title:SetTextColor(UI.accent[1], UI.accent[2], UI.accent[3])

	card.body = UI.Text(card, 12)
	card.body:SetPoint("TOPLEFT", 16, -46)
	card.body:SetWidth(348)
	card.body:SetJustifyH("LEFT")
	card.body:SetSpacing(3)

	card.progress = UI.Text(card, 11)
	card.progress:SetPoint("BOTTOMLEFT", 16, 20)
	card.progress:SetTextColor(UI.dim[1], UI.dim[2], UI.dim[3])

	card.next = UI.Button(card, Z.L["Suivant"], 96, 26, function()
		if current == #steps then Finish() else Show(current + 1) end
	end)
	card.next:SetPoint("BOTTOMRIGHT", -14, 14)
	card.next.label:SetJustifyH("CENTER")
	card.next.bg:SetVertexColor(UI.accent[1] * 0.45, UI.accent[2] * 0.45, UI.accent[3] * 0.45)

	card.back = UI.Button(card, Z.L["Précédent"], 96, 26, function() Show(current - 1) end)
	card.back:SetPoint("RIGHT", card.next, "LEFT", -6, 0)
	card.back.label:SetJustifyH("CENTER")

	-- Cadre lumineux qui pulse autour de l'élément présenté
	highlight = CreateFrame("Frame", nil, UIParent)
	highlight:SetFrameStrata("FULLSCREEN")
	highlight.border = UI.Border(highlight, 2)
	highlight.border:SetColor(UI.accent[1], UI.accent[2], UI.accent[3], 1)
	highlight.pulse = highlight:CreateAnimationGroup()
	highlight.pulse:SetLooping("BOUNCE")
	local fade = highlight.pulse:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0.25)
	fade:SetDuration(0.7)
	fade:SetSmoothing("IN_OUT")
	highlight:Hide()
end

function Z:StartTutorial()
	if not Z.header then return end
	if not card then Build() end
	Show(1)
end
