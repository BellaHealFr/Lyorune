-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Tutorial.lua : visite guidée, lancée au premier démarrage puis à la demande (/lyorune tuto).
-- Chaque étape a un titre, un texte, et peut encadrer un élément de l'écran.

local _, Z = ...
local UI = Z.UI

local card, highlight, current

-- Résumé des clics du joueur, écrit à partir de ses vrais réglages
local function ClickSummary()
	local lines = {}
	for _, binding in ipairs(Z:Bindings()) do
		local value = binding.value
		local shown = Z.MacroRef(value) and Z.L["macro"] .. " " .. Z.MacroRef(value) or value
		if value ~= "" and (value:sub(1, 1) ~= "@" or Z.MacroRef(value)) and #lines < 5 then
			lines[#lines + 1] = "|cff33dd88" .. Z:TriggerLabel(binding) .. "|r : " .. shown
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
				.. "\n\n" .. Z.L["Onglet Clics : les icônes de bijou d'une ligne utilisent votre bijou avec le sort."]
		end,
		target = function() return Z.buttons[1] end,
	},
	{
		title = "Ce que disent les couleurs",
		text = "|cff3399ffBleu|r, |cffa633ffviolet|r, |cffbf801abrun|r ou |cff1ad933vert|r autour d'une case : "
			.. "une magie, une malédiction, une maladie ou un poison que VOUS pouvez dissiper.\n\n"
			.. "|cffff2626Bordure rouge|r : le joueur est attaqué. Case estompée : il est hors de portée (des empreintes : très loin ; un œil : hors de vue).\n\n"
			.. "En haut à gauche : vos soins sur la durée. En bas à droite : ses affaiblissements. "
			.. "Les petits carrés de couleur dans les coins : les sorts que vous y avez placés (onglet Soins).\n\n"
			.. "|cffffd140Contour doré|r : un affaiblissement important (boss, ou votre liste). "
			.. "Survolez une case hors combat : l'infobulle rappelle vos clics.",
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
			.. "|cff33dd88Cadres|r : taille, échelle, placement des éléments, rangement (groupe, rôle, grille) et tri, tanks, familiers, joueurs épinglés, cible et focalisation, mode test.\n"
			.. "|cff33dd88Apparence|r : forme des cases, angles, thème, couleurs, texte, fenêtres.\n"
			.. "|cff33dd88Indicateurs|r : ce qui s'affiche sur une case.\n"
			.. "|cff33dd88Soins|r : vos soins sur la durée (décompte, fondu), les coins, le panneau des buffs manquants.\n"
			.. "|cff33dd88Listes|r : vos sorts à suivre, les affaiblissements à ignorer, vos joueurs épinglés.\n"
			.. "|cff33dd88Clics|r : clics et touches sur une seule liste, combinaisons, mes macros, spécialisations.\n"
			.. "|cff33dd88Alertes|r : annonces et sons.\n"
			.. "|cff33dd88Profils|r : mes profils, changés tout seuls selon le groupe, partage, qui relève qui.\n"
			.. "|cff33dd88Aide|r : tutoriel, assistant, mode performance et mesure, signaler un problème.\n\n"
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

-- Runes de la progression et des angles du cadre (index dans Media/Runes.tga)
local PROGRESS = { 4, 9, 17, 22, 15, 10, 20, 16 }

-- Les mots en vert des textes prennent l'accent du thème de fenêtre, sauf l'étiquette « Groupe »
-- des cadres de soin, qui garde sa couleur à l'écran
local function Accent(text)
	local color = "|cff" .. UI.Hex("accent")
	return (text:gsub("|cff33dd88(%a*)", function(word)
		if word == "Groupe" or word == "Group" then return nil end
		return color .. word
	end))
end

-- Étapes vues : runes allumées ; étape en cours : rune qui respire ; à venir : runes éteintes
local function Progress(index)
	local gold, dim = UI.gold, UI.line
	for i, rune in ipairs(card.runes) do
		rune.breath:Stop()
		if i <= index then
			rune:SetVertexColor(gold[1], gold[2], gold[3], 1)
		else
			rune:SetVertexColor(dim[1], dim[2], dim[3], 0.9)
		end
		if i == index and not UI.Calm() then rune.breath:Play() end
	end
end

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
	local wasShown = card:IsShown()
	card.title:SetText(L[step.title])
	card.body:SetText(Accent(type(step.text) == "function" and step.text() or L[step.text]))
	card.progress:SetText(index .. " / " .. #steps)
	Progress(index)
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
		highlight.pulse:Stop()
		if not UI.Calm() then highlight.pulse:Play() end
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
	-- D'une étape à l'autre, la carte glisse de 12 pixels en fondu (0,25 s) ; simple fondu en animations réduites
	if wasShown then
		local calm = UI.Calm()
		card.from:SetOffset(calm and 0 or 12, 0)
		card.to:SetOffset(calm and 0 or -12, 0)
		card.fade:SetDuration(calm and 0.15 or 0.25)
		card.slide:Stop()
		card.slide:Play()
	end
end

local function Build()
	card = UI.Window("LyoruneTutorial", "", 380, 220)
	card:SetFrameStrata("FULLSCREEN_DIALOG")
	card.close:SetScript("OnClick", Finish)

	card.slide = card:CreateAnimationGroup()
	card.from = card.slide:CreateAnimation("Translation")
	card.from:SetDuration(0)
	card.from:SetOrder(1)
	card.to = card.slide:CreateAnimation("Translation")
	card.to:SetDuration(0.25)
	card.to:SetSmoothing("OUT")
	card.to:SetOrder(2)
	card.fade = UI.AlphaAnim(card.slide, 0, 1, 0.25, "OUT", 2)

	card.body = UI.Label(card, 12)
	card.body:SetPoint("TOPLEFT", 16, -46)
	card.body:SetWidth(348)
	card.body:SetJustifyH("LEFT")
	card.body:SetSpacing(3)

	-- Une rune par étape : allumée une fois vue, celle de l'étape en cours respire
	card.runes = {}
	for i = 1, #steps do
		local rune = UI.Rune(card, "ARTWORK", PROGRESS[(i - 1) % #PROGRESS + 1], 11)
		rune:SetPoint("BOTTOMLEFT", 16 + (i - 1) * 14, 22)
		rune.breath = UI.Breathe(rune, 0.35, 1.6)
		card.runes[i] = rune
	end
	card.progress = UI.Label(card, 11, nil, "dim")
	card.progress:SetPoint("LEFT", card.runes[#steps], "RIGHT", 8, 0)

	card.next = UI.Button(card, Z.L["Suivant"], 96, 26, function()
		if current == #steps then Finish() else Show(current + 1) end
	end)
	card.next:SetPoint("BOTTOMRIGHT", -14, 14)
	card.next.label:SetJustifyH("CENTER")
	UI.Paint(card.next.bg, "accent", 1, 0.45)

	card.back = UI.Button(card, Z.L["Précédent"], 96, 26, function() Show(current - 1) end)
	card.back:SetPoint("RIGHT", card.next, "LEFT", -6, 0)
	card.back.label:SetJustifyH("CENTER")

	-- Cadre de runes qui pulse doucement autour de l'élément présenté (cycle de 1,4 s)
	highlight = CreateFrame("Frame", nil, UIParent)
	highlight:SetFrameStrata("FULLSCREEN")
	highlight.border = UI.Border(highlight, 2)
	UI.Paint(highlight.border, "accent", 1)
	highlight.runes = {}
	for i, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
		local rune = UI.Paint(UI.Rune(highlight, "OVERLAY", PROGRESS[i], 14), "gold")
		rune:SetPoint("CENTER", highlight, corner)
		highlight.runes[i] = rune
	end
	highlight.pulse = UI.Breathe(highlight, 0.3, 1.4)
	highlight:Hide()
	UI.OnSkin(function() if current then Progress(current) end end)
end

function Z:StartTutorial()
	if not Z.header then return end
	if not card then Build() end
	Show(1)
end
