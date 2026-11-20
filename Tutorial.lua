-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Tutorial.lua : visite guidée, lancée au premier démarrage puis à la demande (/lyorune tuto).
-- Chaque étape a un titre, un texte, et peut encadrer un élément de l'écran.

local _, Z = ...
local UI = Z.UI

local card, highlight, current
local lockBefore -- déplacement des cadres choisi par le joueur, rendu à la fin de l'étape « Placer les cadres »
-- D'où la visite a été lancée : fenêtre d'options ouverte ou non, et son chapitre. La visite la ferme le temps des
-- cases, puis rend la fenêtre telle qu'elle était, sur le même chapitre (retour d'essai de l'auteur).
local back = {}
local starting -- vrai pendant que la visite ferme la fenêtre d'options, juste avant sa première carte
local GAP = 14 -- écart entre la carte et ce qu'elle présente (le cadre de runes déborde de 12 pixels)

-- Le bloc entier des cadres de soin : le groupe, ou chaque groupe de raid, avec son étiquette
local function Block()
	local list = { Z.buttons[1] }
	for _, h in ipairs(Z.headers) do
		if h.def and h.def.pos == "pos" and h:IsVisible() then
			list[#list + 1] = h
			if h.handle and h.handle:IsShown() then list[#list + 1] = h.handle end
		end
	end
	return list
end

-- La page du chapitre ouvert dans la fenêtre d'options
local function OpenPage()
	local window = Z:OptionsWindow()
	for _, chapter in ipairs(window and window.chapters or {}) do
		if chapter.page and chapter.page.scroll:IsShown() then return chapter.page.scroll end
	end
end

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
		return Z.L["Aucun sort n'est encore attribué : vous les choisirez dans le chapitre Sorts et raccourcis des options."]
	end
	return table.concat(lines, "\n")
end

local steps = {
	{
		title = "Bienvenue dans Lyorune",
		text = function()
			local L = Z.L
			local text = L["Lyorune affiche votre groupe sous forme de cases et vous laisse soigner d'un simple clic.\n\n"
				.. "Cette visite dure une minute. Vous pourrez la relancer avec |cff33dd88/lyorune tuto|r."]
			if back.open then text = text .. "\n\n" .. L["La fenêtre d'options revient à la fin de la visite."] end
			return text
		end,
	},
	{
		title = "Une case par joueur",
		text = "La barre colorée est la vie du joueur : plus elle est courte, plus il est blessé.\n\n"
			.. "Le |cff73ff99vert clair|r au bout de la barre montre les soins déjà en route. "
			.. "La |cff8cd9ffbande claire|r en bas est un bouclier.",
		target = function() return Z.buttons[1] end,
		around = Block,
	},
	{
		title = "Soigner d'un clic",
		text = function()
			return Z.L["Cliquez sur une case pour lancer un sort sur ce joueur, sans le cibler."] .. "\n\n" .. ClickSummary()
				.. "\n\n" .. Z.L["Un bijou avec un sort ? Chapitre Sorts et raccourcis, réglages fins : « Bijoux avec les sorts »."]
		end,
		target = function() return Z.buttons[1] end,
		around = Block,
	},
	{
		title = "Ce que disent les couleurs",
		text = "|cff3399ffBleu|r, |cffa633ffviolet|r, |cffbf801abrun|r ou |cff1ad933vert|r autour d'une case : "
			.. "une magie, une malédiction, une maladie ou un poison que VOUS pouvez dissiper.\n\n"
			.. "|cffff2626Bordure rouge|r : le joueur est attaqué. Case estompée : il est hors de portée (des empreintes : très loin ; un œil : hors de vue).\n\n"
			.. "En haut à gauche : vos soins sur la durée. En bas à droite : ses affaiblissements. "
			.. "Les petits carrés de couleur dans les coins : les sorts que vous y avez placés (chapitre Mes soins). "
			.. "Ces icônes sont dessinées par le jeu : elles restent visibles en plein combat.\n\n"
			.. "|cffffd140Contour doré|r : un affaiblissement important (boss, ou votre liste). "
			.. "Survolez une case hors combat : l'infobulle rappelle vos clics.",
		target = function() return Z.buttons[1] end,
		around = Block,
	},
	{
		title = "Placer les cadres",
		text = "Faites glisser l'étiquette |cff33dd88Groupe|r au-dessus des cases pour déplacer les cadres où vous voulez. "
			.. "En raid, chaque groupe a son numéro, et n'importe lequel déplace l'ensemble.\n\n"
			.. "Une fois satisfait, choisissez « Verrouillé » dans « Déplacement des cadres » (chapitre Disposition, partie Position), "
			.. "ou « Avec Alt » pour ne les déplacer qu'en maintenant la touche.\n\n"
			.. "Dans la partie Cadres affichés, « Afficher les cadres » permet de les voir en permanence, ou seulement en combat.",
		target = function() return Z.header.handle end,
		around = Block,
		-- Les cadres sont libres le temps de l'étape, puis le choix du joueur revient (verrou compris)
		before = function()
			lockBefore = Z.db.lockMode
			if Z.db.lockMode ~= "FREE" then
				Z.db.lockMode = "FREE"
				Z:Refresh()
			end
		end,
		after = function()
			if lockBefore and lockBefore ~= Z.db.lockMode then
				Z.db.lockMode = lockBefore
				Z:Refresh()
			end
			lockBefore = nil
		end,
	},
	{
		title = "Essayer sans groupe",
		text = "Le |cff33dd88mode test|r affiche un faux groupe pour régler l'apparence tranquillement : "
			.. "joueurs blessés, soins en route, dissipation, vie basse.\n\n"
			.. "Ouvrez-le avec |cff33dd88/lyorune test|r, ou avec « 5 », « 10 », « 25 » ou « 40 » sous la case témoin des options. Glissez son bandeau pour le déplacer ; un second clic sur le même nombre, ou le bouton |cff33dd88Fermer|r au bout du bandeau, le quitte ; il se ferme aussi tout seul en combat.",
		target = function() return LyorunePreview end,
		before = function() if not Z.previewActive then Z:TogglePreview(10) end end,
		after = function() if Z.previewActive then Z:TogglePreview() end end,
	},
	-- La fenêtre d'options, zone par zone : chaque carte ouvre la fenêtre sur son chapitre (window) et encadre sa
	-- zone ; la carte se pose à côté de la fenêtre entière, jamais sur la zone présentée
	{
		title = "La fenêtre d'options",
		text = "Tout se règle ici et s'enregistre tout seul. Rien n'est obligatoire : chaque élément a son interrupteur.\n\n"
			.. "À gauche, un |cff33dd88chapitre|r par sujet ; sa pastille d'or compte vos réglages changés. "
			.. "Dessous, « Enregistrer mes réglages » les garde sous un nom.",
		window = "Accueil",
		target = function() return Z:OptionsWindow().side end,
	},
	{
		title = "Une page par chapitre",
		text = "La page défile et se range par parties. « Réglages fins » déplie les réglages plus rares.\n\n"
			.. "Pour revenir en arrière : la |cffffd140rune d'or|r d'un réglage changé, « Rétablir cette page » tout en bas, "
			.. "ou « Annuler mes changements » au bas de la fenêtre.",
		window = "Disposition",
		target = OpenPage,
	},
	{
		title = "La case témoin",
		text = "La |cff33dd88case témoin|r suit chaque réglage en direct, avec un faux groupe dessous.\n\n"
			.. "Les boutons « 5 », « 10 », « 25 » et « 40 » ouvrent le mode test.",
		window = "Disposition",
		target = function() return Z:OptionsWindow().witness end,
	},
	{
		title = "Recherche et Accueil",
		text = "Un réglage introuvable ? Tapez un mot dans la |cff33dd88recherche|r : un clic sur un résultat vous y mène.\n\n"
			.. "L'|cff33dd88Accueil|r, en haut de la barre, liste vos réglages changés et relance ce tutoriel.",
		window = "Accueil",
		target = function() return Z:OptionsWindow().search end,
	},
	{
		title = "C'est parti",
		text = "Vous savez l'essentiel. Bon soin !\n\nAstuce : avant un combat important, vérifiez le chapitre Sorts et raccourcis. "
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

-- Fin de la visite (Terminer ou la croix) : la fenêtre d'options revient comme elle était, même chapitre, sans que
-- la visite change le dernier chapitre utilisé
local function Finish()
	local step = steps[current]
	if step and step.after then step.after() end
	current = nil
	card:Hide()
	highlight:Hide()
	Z.db.tutorialDone = true
	local window = Z:OptionsWindow()
	if not window then return end
	if back.touched then window.Select(back.chapter or 1, true) end -- chapitres ouverts par la visite
	if back.open then
		window:Show()
	elseif step and step.window then
		window:Hide() -- fermée sur une carte de la fenêtre ; une fenêtre ouverte par le joueur reste ouverte
	end
end

-- Bords d'un ou plusieurs cadres (gauche, droite, haut, bas), en points de l'écran, et le premier cadre mesuré ;
-- nil si le jeu ne connaît encore la place d'aucun
local function Box(frames)
	local base = UIParent:GetEffectiveScale()
	local left, right, top, bottom, ref
	for _, f in ipairs(frames) do
		local l, r, t, b = f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom()
		if l and r and t and b then
			local k = f:GetEffectiveScale() / base
			left, right = math.min(left or l * k, l * k), math.max(right or r * k, r * k)
			top, bottom = math.max(top or t * k, t * k), math.min(bottom or b * k, b * k)
			ref = ref or { frame = f, left = l * k, bottom = b * k }
		end
	end
	return left, right, top, bottom, ref
end

-- Pose la carte à côté du bloc (around) sans jamais le couvrir : du côté où il reste le plus de place (droite,
-- gauche, dessous, dessus) ; elle suit le bloc s'il est déplacé. Si rien ne tient : contre le bord de l'écran le
-- plus loin de ce qui est encadré.
local function Place(target, around)
	local l, r, t, b, ref = Box(around)
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	if not (l and width and height) then return card:SetPoint("TOPLEFT", target, "TOPRIGHT", GAP, 0) end
	local w, h = card:GetWidth(), card:GetHeight()
	local best
	for _, side in ipairs({
		{ width - r - w, "TOPLEFT", r + GAP, t },
		{ l - w, "TOPRIGHT", l - GAP, t },
		{ b - h, "TOPLEFT", l, b - GAP },
		{ height - t - h, "BOTTOMLEFT", l, t + GAP },
	}) do
		if side[1] >= GAP and (not best or side[1] > best[1]) then best = side end
	end
	if best then
		return card:SetPoint(best[2], ref.frame, "BOTTOMLEFT", best[3] - ref.left, best[4] - ref.bottom)
	end
	local x = target:GetCenter()
	if x and x * target:GetEffectiveScale() / UIParent:GetEffectiveScale() < width / 2 then
		card:SetPoint("TOPRIGHT", UIParent, "BOTTOMRIGHT", 0, t)
	else
		card:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, t)
	end
end

local function Show(index)
	local previous = steps[current]
	if previous and previous.after then previous.after() end
	current = index
	local step = steps[index]
	if step.before then step.before() end
	-- Les cartes de la fenêtre d'options l'ouvrent sur leur chapitre ; les autres la ferment
	if step.window then
		back.touched = true
		Z:ToggleOptions(step.window)
	elseif previous and previous.window then
		Z:OptionsWindow():Hide()
	end

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
		-- À côté du bloc des cadres pour une case, de la fenêtre entière pour une zone des options
		local around = step.around and step.around() or step.window and { Z:OptionsWindow() } or { target }
		Place(target, around)
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
	card = UI.Window("LyoruneTutorial", "", 400, 220)
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
	card.body:SetWidth(368)
	card.body:SetJustifyH("LEFT")
	card.body:SetSpacing(3)

	-- Une rune par étape : allumée une fois vue, celle de l'étape en cours respire. Onze runes, le compte « 11 / 11 »
	-- et les deux boutons de 88 tiennent sur la largeur de la carte.
	card.runes = {}
	for i = 1, #steps do
		local rune = UI.Rune(card, "ARTWORK", PROGRESS[(i - 1) % #PROGRESS + 1], 11)
		rune:SetPoint("BOTTOMLEFT", 16 + (i - 1) * 13, 22)
		rune.breath = UI.Breathe(rune, 0.35, 1.6)
		card.runes[i] = rune
	end
	card.progress = UI.Label(card, 11, nil, "dim")
	card.progress:SetPoint("LEFT", card.runes[#steps], "RIGHT", 8, 0)

	card.next = UI.Button(card, Z.L["Suivant"], 88, 26, function()
		if current == #steps then Finish() else Show(current + 1) end
	end)
	card.next:SetPoint("BOTTOMRIGHT", -14, 14)
	card.next.label:SetJustifyH("CENTER")
	UI.Paint(card.next.bg, "accent", 1, 0.45)

	card.back = UI.Button(card, Z.L["Précédent"], 88, 26, function() Show(current - 1) end)
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
	card.highlight = highlight
	UI.OnSkin(function() if current then Progress(current) end end)
end

-- Lancée des options (bouton de l'Accueil, ou /lyorune tuto fenêtre ouverte), la visite ferme la fenêtre le temps
-- des cases et la rend à la fin sur le même chapitre ; la première carte le dit.
function Z:StartTutorial()
	if not Z.header then return end
	if not card then Build() end
	local window = Z:OptionsWindow()
	if not current then -- relancée en cours de route : on garde d'où elle était partie
		back = { open = window and window:IsShown(), chapter = Z:OptionChapter() }
	end
	if window and window:IsShown() then
		starting = true
		window:Hide()
		starting = nil
	end
	Show(1)
end

-- Vrai pendant la visite : la fenêtre d'options fermée par la visite n'est pas fermée par le joueur (elle garde
-- de quoi « Annuler mes changements »)
function Z:TutorialRunning()
	return current ~= nil or starting == true
end
