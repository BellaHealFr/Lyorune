-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Tutorial.lua : visite guidée, lancée au premier démarrage puis à la demande (/lyorune tuto).
-- Chaque étape a un titre, un texte, et peut encadrer un élément de l'écran.

local _, Z = ...
local UI = Z.UI

local card, highlight, current
local fake     -- vrai quand la visite a ouvert elle-même le mode test : elle le ferme en partant (ouvert avant, il reste)
local watching -- vrai une fois le crochet posé sur la fenêtre d'options (cadre lumineux caché avec elle)
-- D'où la visite a été lancée : fenêtre d'options ouverte ou non, et son chapitre. La visite la ferme le temps des
-- cases, puis rend la fenêtre telle qu'elle était, sur le même chapitre (retour d'essai de l'auteur).
local back = {}
local starting -- vrai pendant que la visite ferme la fenêtre d'options, juste avant sa première carte
local GAP = 14 -- écart entre la carte et ce qu'elle présente (le cadre de runes déborde de 12 pixels)

-- La première case montrée : une vraie, ou celle du faux groupe quand le mode test est ouvert (il cache les vraies)
local function Cell()
	if Z.previewActive then return Z:PreviewCells(1)[1] end
	return Z.buttons[1]
end

-- Le bloc entier des cadres de soin : le groupe, ou chaque groupe de raid, avec son étiquette ; en mode test, les
-- cases du faux groupe
local function Block()
	if Z.previewActive then
		local list, size = {}, Z:PreviewSize()
		for i, cell in ipairs(Z:PreviewCells(size)) do
			if i <= size and cell:IsVisible() then list[#list + 1] = cell end
		end
		return list
	end
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

-- Couleur d'un élément des cases en « |cff... » (soins en route, bouclier), lue dans le thème des cases en cours :
-- elle change d'un thème à l'autre (bouclier doré en Héroïque, jaune en contraste élevé)
local function Hex(color)
	return ("%02x%02x%02x"):format(color[1] * 255 + 0.5, color[2] * 255 + 0.5, color[3] * 255 + 0.5)
end

-- Ouvre le faux groupe du mode test (wanted : nombre de joueurs) s'il n'est pas déjà ouvert, ou le ferme (nil) si
-- c'est la visite qui l'a ouvert. Jamais en combat (le mode test y est refusé).
local function FakeGroup(wanted)
	if wanted then
		if not Z.previewActive and not InCombatLockdown() then
			Z:TogglePreview(wanted)
			fake = true
		end
	elseif fake then
		fake = nil
		if Z.previewActive then Z:TogglePreview() end
	end
end

-- Comment cibler un joueur (C18) : son premier raccourci « Cibler » (Alt + clic gauche au départ), sinon une
-- combinaison du clic gauche laissée libre (elle cible aussi : *type1, Frames.lua), sinon où poser « Cibler ».
-- Rien quand Clique ou le jeu gèrent les clics.
local function TargetLine(target)
	if Z.db.externalClicks then return "" end
	local label = target and Z:TriggerLabel(target)
	if not label then
		local clicks = Z:GetClicks()
		for _, modifier in ipairs(Z.clickModifiers) do
			local key = modifier[1] .. "1"
			if (clicks[key] or "") == "" then label = Z:ClickLabel(key) break end
		end
	end
	if not label then
		return "\n" .. Z.L["Pour cibler un joueur : chapitre Sorts et raccourcis, bouton « Cibler » en haut de la fenêtre des sorts."]
	end
	return "\n" .. Z.L["Pour cibler un joueur : %s sur sa case."]:format("|cff33dd88" .. label .. "|r")
end

-- Résumé des clics du joueur, écrit à partir de ses vrais réglages, puis comment cibler
local function ClickSummary()
	local lines, target = {}, nil
	for _, binding in ipairs(Z:Bindings()) do
		local value = binding.value
		local shown = Z.MacroRef(value) and Z.L["macro"] .. " " .. Z.MacroRef(value)
			or Z.RankId(value) and Z.RankLabel(value) or value
		if value == "@target" then target = target or binding end
		if value ~= "" and (value:sub(1, 1) ~= "@" or Z.MacroRef(value)) and #lines < 5 then
			lines[#lines + 1] = "|cff33dd88" .. Z:TriggerLabel(binding) .. "|r : " .. shown
		end
	end
	if #lines == 0 then
		return Z.L["Aucun sort n'est encore attribué : vous les choisirez dans le chapitre Sorts et raccourcis des options."] .. TargetLine(target)
	end
	return table.concat(lines, "\n") .. TargetLine(target)
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
		-- Écrit d'après les réglages : couleurs du thème des cases, place du bouclier, éléments coupés
		text = function()
			local L, db, theme = Z.L, Z.db, Z:Theme()
			local text = L["La barre colorée est la vie du joueur : plus elle est courte, plus il est blessé."]
			if db.showIncoming then
				text = text .. "\n\n" .. L["La |cff%steinte claire|r au bout de la vie montre les soins déjà en route."]:format(Hex(theme.incoming))
			end
			if db.showAbsorb then
				local shield = db.absorbStyle == "FOLLOW" and "La |cff%spart claire|r qui prolonge la vie est un bouclier."
					or "La |cff%sbande claire|r en bas de la case est un bouclier."
				text = text .. (db.showIncoming and " " or "\n\n") .. L[shield]:format(Hex(theme.absorb))
				if db.absorbText then text = text .. " " .. L["Son petit chiffre dit ce qui reste à absorber, même en combat."] end
			end
			if db.channelMark then
				text = text .. "\n\n" .. L["Un trait qui se vide en haut d'une case : le soin que vous canalisez sur ce joueur (Pénitence)."]
			end
			-- Mana (étape 23) : seulement ce qui est allumé, et rien sur ma mana pour une classe sans mana
			local mana = {}
			local mine = Z.class ~= nil and not (Z.classPower and Z.classPower[Z.class])
			if mine and db.fiveSecondRule then
				mana[#mana + 1] = L["Après un sort payé en mana, un trait fin sur votre case se vide en 5 secondes : ensuite, votre mana repart."]
			end
			if mine and (tonumber(db.manaEdge) or 0) > 0 then
				mana[#mana + 1] = L["Le bord de l'écran bleuit quand votre mana baisse."]
			end
			if db.drinkHealers then
				mana[#mana + 1] = L["Une boisson près de la mana d'un soigneur : il boit."]
			end
			if #mana > 0 then text = text .. "\n\n" .. table.concat(mana, " ") end
			text = text .. "\n\n" .. (db.showClassIcon and L["La petite image près du nom : la classe du joueur."]
				or L["La classe de chacun en image ? « Icône de classe », chapitre Joueurs."])
			return text
		end,
		target = Cell,
		around = Block,
		cells = true,
	},
	{
		title = "Soigner d'un clic",
		text = function()
			return Z.L["Cliquez sur une case pour lancer un sort sur ce joueur, sans le cibler."] .. "\n\n" .. ClickSummary()
				.. "\n\n" .. Z.L["Un bijou avec un sort ? Chapitre Sorts et raccourcis, réglages fins : « Bijoux avec les sorts »."]
				.. "\n" .. Z.L["Combien de fois chaque clic a servi ? « Compter mes clics », même chapitre."]
				.. "\n" .. Z.L["Tous vos soins et buffs y sont, même sans cible (Feu intérieur, totems). Un sort manque ? /lyorune sorts dit pourquoi."]
				.. "\n" .. Z.L["Un rang plus bas pour garder de la mana ? « Choisir le rang des sorts », même chapitre."]
				.. "\n" .. Z.L["Un autre sort sur un ennemi, en JcJ, sur un tank ou hors combat ? Le « + » au bout d'une ligne."]
				.. "\n" .. Z.L["Vos sorts à recharge sous les cadres, même en combat, ceux de vos alliés et vos totems ? « Mes recharges », « Recharges du groupe » et « Mes totems », chapitre Mes soins."]
		end,
		target = Cell,
		around = Block,
		cells = true,
	},
	{
		title = "Ce que disent les couleurs",
		text = "|cff3399ffBleu|r, |cffa633ffviolet|r, |cffbf801abrun|r ou |cff1ad933vert|r autour d'une case : "
			.. "une magie, une malédiction, une maladie ou un poison que VOUS pouvez dissiper (l'image du type à gauche, le liseré de chaque icône à sa couleur).\n\n"
			.. "|cffff2626Bordure rouge|r : le joueur est attaqué. Case estompée : il est hors de portée (des empreintes : très loin ; un œil : hors de vue). Vie et nom pâles : il est en bonne santé (à allumer, chapitre Vie et portée). |cffffcc4dTrait doré|r à gauche : un de vos joueurs (chapitre Joueurs, partie Mes joueurs).\n\n"
			.. "Vos soins sur la durée et ses affaiblissements se rangent selon la forme des cases ; "
			.. "« Placer les éléments de la case... » (chapitre Disposition) les déplace, règle leur taille, et les affiche ou les masque d'une case à cocher (un élément masqué laisse sa place aux autres). "
			.. "Les petits carrés de couleur dans les coins : les sorts que vous y avez placés (chapitre Mes soins). "
			.. "Une icône grise au bout de vos soins : un sort que vous ne pouvez pas encore relancer sur lui (Âme affaiblie, Longanimité), avec ses secondes. "
			.. "Ces icônes sont dessinées par le jeu : elles restent visibles en plein combat.\n\n"
			.. "|cffffd140Contour doré|r : un affaiblissement important (boss, ou votre liste, toujours en tête de la rangée). "
			.. "Liseré |cff73ccffbleu|r : un gros défensif posé sur lui ; liseré |cffff4d33rouge|r au centre : il est étourdi, apeuré ou métamorphosé. "
			.. "Survolez une case hors combat : l'infobulle rappelle vos clics.",
		target = Cell,
		around = Block,
		cells = true,
	},
	{
		title = "Placer les cadres",
		text = "Faites glisser l'étiquette |cff33dd88Groupe|r au-dessus des cases pour déplacer les cadres où vous voulez. "
			.. "En raid, chaque groupe a son numéro, et n'importe lequel déplace l'ensemble.\n\n"
			.. "Une fois satisfait, choisissez « Verrouillé » dans « Déplacement des cadres » (chapitre Disposition, partie Position), "
			.. "ou « Avec Alt » pour ne les déplacer qu'en maintenant la touche.\n\n"
			.. "Dans la partie Cadres affichés, « Afficher les cadres » permet de les voir en permanence, ou seulement en combat. "
			.. "Les familiers peuvent se coller à leur maître ; en raid, leur colonne suit les groupes.",
		target = function() return Z.header.handle end,
		around = Block,
		-- Les cadres sont libres le temps de l'étape, puis le choix du joueur revient (verrou compris). L'ancien choix
		-- est gardé dans la sauvegarde : un /reload ou une déconnexion pendant la carte le rend au chargement
		-- (Core.lua). Un verrou choisi par le joueur pendant la carte (elle le lui conseille) n'est pas écrasé.
		before = function()
			if Z.db.lockMode ~= "FREE" then
				Z.db.lockBeforeTutorial = Z.db.lockMode
				Z.db.lockMode = "FREE"
				Z:Refresh()
			end
		end,
		after = function()
			local before = Z.db.lockBeforeTutorial
			Z.db.lockBeforeTutorial = nil
			if before and Z.db.lockMode == "FREE" then
				Z.db.lockMode = before
				Z:Refresh()
			end
		end,
	},
	{
		title = "Essayer sans groupe",
		text = "Le |cff33dd88mode test|r affiche un faux groupe pour régler l'apparence tranquillement : "
			.. "joueurs blessés, soins en route, dissipation, vie basse.\n\n"
			.. "Ouvrez-le avec |cff33dd88/lyorune test|r, ou avec « 5 », « 10 », « 25 » ou « 40 » sous la case témoin des options. Glissez son bandeau pour le déplacer ; un second clic sur le même nombre, ou le bouton |cff33dd88Fermer|r au bout du bandeau, le quitte ; il se ferme aussi tout seul en combat.",
		target = Cell,
		around = Block,
		preview = 10, -- ouvert pour la carte s'il ne l'est pas, puis refermé ; ouvert par le joueur avant, il reste
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
			.. "L'|cff33dd88Accueil|r, en haut de la barre, liste vos réglages changés et relance ce tutoriel. "
			.. "Tout en bas, |cff33dd88Les amis de Lyorune|r : Lyorune en chiffres et votre carnet de soigneur.",
		window = "Accueil",
		target = function() return Z:OptionsWindow().search end,
	},
	{
		title = "C'est parti",
		text = "Vous savez l'essentiel. Bon soin !\n\nAstuce : avant un combat important, vérifiez le chapitre Sorts et raccourcis. "
			.. "Les changements de clics et de taille demandés en combat s'appliquent dès qu'il se termine.\n\n"
			.. "Le bouton Lyorune au bord de la mini-carte ouvre les options (clic gauche) ou le mode test (clic droit). "
			.. "Une touche peut aussi le faire, ou masquer les cadres et poser le prochain buff manquant : raccourcis du jeu, rubrique AddOns. Hors combat, le prochain buff qui manque s'affiche sous vos cadres, dans un bandeau fin : un clic le pose, puis le suivant prend sa place. Trois joueurs d'un groupe sans le buff : un seul sort de groupe, son icône sur leurs cases. Vos buffs à surveiller, en JcE et en JcJ : chapitre Joueurs. Sur chaque case, une rangée de vos buffs, partout : en couleur, posés, rien à faire ; gris, à relancer (en combat et en champ de bataille : deux interrupteurs). Vos groupes à buffer et la bénédiction de chaque joueur s'y règlent aussi ; le chef peut les répartir.\n\n"
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

-- Le texte d'une carte, avec l'accent du thème de fenêtre
local function Body(step)
	return Accent(type(step.text) == "function" and step.text() or Z.L[step.text])
end

-- Faux groupe voulu par une carte : celui de la carte du mode test ; pour les cartes des cases, 5 joueurs quand
-- aucune vraie case n'est visible (cadres cachés hors combat, ou seul sans son propre cadre)
local function Wanted(step)
	if step.preview then return step.preview end
	if step.cells and (fake or not Z.previewActive and not (Z.buttons[1] and Z.buttons[1]:IsVisible())) then return 5 end
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
	if not current then return end -- déjà finie (Échap, puis la croix dans le même instant)
	local step = steps[current]
	if step.after then step.after() end
	current = nil
	FakeGroup(nil)
	card:Hide()
	highlight:Hide()
	Z.db.tutorialDone = true
	local window = Z:OptionsWindow()
	if not window then return end
	if back.touched then window.Select(back.chapter or 1, true) end -- chapitres ouverts par la visite
	if back.open then
		-- effacée par une fenêtre secondaire encore ouverte : elle revient à sa fermeture
		if not UI.Away() then window:Show() end
	elseif step.window then
		window:Hide() -- fermée sur une carte de la fenêtre ; une fenêtre ouverte par le joueur reste ouverte
	end
	-- La fenêtre ne revient pas : la copie d'« Annuler mes changements », gardée pendant la visite, est lâchée
	if not (window:IsShown() or UI.Away()) then Z:ForgetOptionsCopy() end
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
	FakeGroup(Wanted(step))
	if step.before then step.before() end
	-- Les cartes de la fenêtre d'options l'ouvrent sur leur chapitre ; les autres la ferment
	if step.window then
		back.touched = true
		Z:ToggleOptions(step.window)
		-- Fenêtre fermée par sa croix sur une de ses cartes : le cadre lumineux part avec elle
		if not watching then
			watching = true
			Z:OptionsWindow():HookScript("OnHide", function()
				local shown = steps[current]
				if shown and shown.window then highlight:Hide() end
			end)
		end
	elseif previous and previous.window then
		Z:OptionsWindow():Hide()
	end

	local L = Z.L
	local wasShown = card:IsShown()
	card.title:SetText(L[step.title])
	card.body:SetText(Body(step))
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
	-- Échap termine la visite comme la croix. Fini juste après : sur les cartes de la fenêtre, Échap ferme aussi la
	-- fenêtre d'options, et la visite la rend une fois tout fermé.
	tinsert(UISpecialFrames, "LyoruneTutorial")
	card:HookScript("OnHide", function()
		if current then
			C_Timer.After(0, function()
				if current and not card:IsShown() then Finish() end
			end)
		end
	end)

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
	-- Thème de fenêtre changé pendant la visite : runes et mots à la couleur d'accent suivent tout de suite
	UI.OnSkin(function()
		if current then
			Progress(current)
			card.body:SetText(Body(steps[current]))
		end
	end)
end

-- Lancée des options (bouton de l'Accueil, ou /lyorune tuto fenêtre ouverte), la visite ferme la fenêtre le temps
-- des cases et la rend à la fin sur le même chapitre ; la première carte le dit.
-- from : où rendre la fenêtre, donné par l'assistant lancé des options ({ open = true, chapter = "Accueil" }),
-- qui l'a déjà fermée.
function Z:StartTutorial(from)
	if not Z.header then return end
	if not card then Build() end
	-- Mes macros, Placement, Signaler un bug... ouverts : fermés d'abord (les options effacées reviennent), sinon
	-- une carte de la fenêtre, posée à côté des options, tomberait sur l'une d'elles
	UI.CloseBeside()
	local window = Z:OptionsWindow()
	if not current then -- relancée en cours de route : on garde d'où elle était partie
		-- effacée par une fenêtre secondaire (UI.Away), la fenêtre compte comme ouverte : elle revient à la fin
		back = from or { open = window and (window:IsShown() or UI.Away()), chapter = Z:OptionChapter() }
	end
	if window and window:IsShown() then
		starting = true
		window:Hide()
		starting = nil
	end
	Show(1)
end

-- Une fenêtre à côté des options s'ouvre pendant la visite (UI.Appear) : la visite s'arrête. Sur une carte de la
-- fenêtre, le joueur se sert des options : elles restent ouvertes, sur la page où il est allé.
function Z:StopTutorial()
	if not current then return end
	if steps[current].window then
		back.open = true
		back.touched = nil
	end
	Finish()
end

-- Vrai pendant la visite : la fenêtre d'options fermée par la visite n'est pas fermée par le joueur (elle garde
-- de quoi « Annuler mes changements »)
function Z:TutorialRunning()
	return current ~= nil or starting == true
end
