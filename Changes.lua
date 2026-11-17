-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Changes.lua : ce qui change à chaque version, affiché en jeu après une mise à jour.
-- Ce fichier est la SEULE source du journal des versions : outils/publier.py y ajoute la nouvelle version
-- et régénère CHANGELOG.md à partir de lui. La version la plus récente est en premier.
-- Trois rubriques par version : added (nouveau), improved (amélioré), fixed (corrigé).

local _, Z = ...

Z.changes = {
	{
		version = "1.5.3", date = "2026-11-17",
		added = {
		},
		improved = {
			"La fenêtre d'options est plus haute, pour que les macros des barres de sorts tiennent dans l'onglet Clics.",
			"Une erreur dans un onglet des options ne cache plus les autres réglages, et elle est notée au journal.",
		},
		fixed = {
		},
	},
	{
		version = "1.5.2", date = "2026-11-17",
		added = {
		},
		improved = {
		},
		fixed = {
			"Les cadres s'affichent de nouveau : le jeu refusait de créer les cases, seul comme en groupe.",
		},
	},
	{
		version = "1.5.1", date = "2026-11-17",
		added = {
			"Macros pour vos barres de sorts : Lyorune crée et tient à jour une vraie macro du jeu pour chaque sort de vos clics. Onglet Clics : cliquez sur son icône puis déposez-la dans une barre.",
		},
		improved = {
			"Le rapport de /lyorune erreurs décrit maintenant l'état de chaque cadre.",
		},
		fixed = {
		},
	},
	{
		version = "1.5.0", date = "2026-11-17",
		added = {
			"Macros : dans le choix d'un clic ou d'une touche au survol, le bouton « Macro... » propose trois modèles prêts (bijou puis soin, interrompre puis soigner, annonce puis soin) et une saisie libre.",
		},
		improved = {
			"Un code de configuration reçu d'un autre joueur ne peut contenir que des noms de sorts, jamais une commande.",
		},
		fixed = {
		},
	},
	{
		version = "1.4.2", date = "2026-11-17",
		added = {
			"Réglage « Afficher les cadres » (onglet Cadres) : en permanence, ou seulement pendant les combats.",
			"La commande /lyorune diag décrit l'état de chaque cadre, pour comprendre un cadre resté vide.",
		},
		improved = {
			"L'affichage des cadres est confié au jeu lui-même : il reste fiable en plein combat.",
		},
		fixed = {
			"Après le mode test, les vrais cadres reviennent dès le début du combat.",
			"Plus d'erreur quand on relâche la poignée d'un cadre pendant un combat.",
			"Les soins en route sont de nouveau accrochés au bout de la barre de vie.",
		},
	},
	{
		version = "1.4.1", date = "2026-11-16",
		added = {
		},
		improved = {
			"Lyorune parle anglais partout : visite guidée, nouveautés, messages du chat et noms des thèmes.",
			"Sur un jeu en anglais, les annonces proposées (mana, résurrection) sont en anglais dès l'installation.",
			"La fenêtre /lyorune bug donne le lien direct vers le formulaire de signalement, dans votre langue.",
		},
		fixed = {
		},
	},
	{
		version = "1.4.0", date = "2026-11-16",
		added = {
			"Nouveau nom : Zenith devient Lyorune. Les commandes sont /lyorune et /lyo.",
			"Bouton sur la mini-carte : clic gauche pour les options, clic droit pour le mode test. Il se déplace et se désactive dans l'onglet Aide.",
			"Logo de Lyorune dans la liste des addons.",
			"Inscription runique animée au bas de la fenêtre d'options : passez la souris dessus pour la traduire.",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.3.0", date = "2026-11-16",
		added = {
			"Signaler un bug en trois questions avec /lyorune bug : un rapport prêt à copier.",
			"Trois préréglages de transparence : discret, semi-transparent, bien visible.",
			"Diagnostic de position avec /lyorune position, en vue de la flèche de direction.",
		},
		improved = {
			"Changement de spécialisation ou de talents pris en compte sans /reload.",
			"Un joueur déconnecté reste visible avec la mention « Déco ».",
			"Notification d'erreur réglable, une seule par session.",
		},
		fixed = {
		},
	},
	{
		version = "1.2.0", date = "2026-11-16",
		added = {
			"Mode test : un faux groupe de 5 à 40 joueurs pour régler l'apparence (/lyorune test).",
			"Cadres séparés pour les tanks et les familiers, ordre des rôles au choix.",
			"Barre de mana des soigneurs, alerte visuelle de vie basse, buffs de groupe manquants.",
			"Soins sur la durée en icônes ou en barres fines, affaiblissements importants en grand.",
			"Touches au survol, résurrection automatique sur le clic de soin.",
			"Listes personnelles : sorts à suivre, affaiblissements à ignorer ou à mettre en avant.",
			"Luminosité, opacité, contraste élevé, réduction automatique des cases en grand raid.",
			"Profils prêts à l'emploi, envoi direct de sa configuration à un joueur, tout réinitialiser.",
			"Traduction anglaise des options.",
			"Avertissement quand un membre du groupe a une version plus récente.",
		},
		improved = {
			"Options rangées en huit onglets, avec une recherche.",
		},
		fixed = {
			"Votre propre case n'est plus estompée comme si vous étiez hors de portée.",
		},
	},
	{
		version = "1.1.0", date = "2026-11-16",
		added = {
			"Cinq thèmes, annonces de mana et de résurrection, partage de configuration par code.",
			"Journal d'erreurs (/lyorune erreurs) et contrôle de compatibilité (/lyorune diag).",
		},
		improved = {
		},
		fixed = {
		},
	},
	{
		version = "1.0.0", date = "2026-11-16",
		added = {
			"Première version pour WoW Forever : cadres, clic-soin, soins en route, dissipation, tutoriel.",
		},
		improved = {
		},
		fixed = {
		},
	},
}

-- Rubriques, dans l'ordre d'affichage
Z.changeSections = { { "added", "Nouveau" }, { "improved", "Amélioré" }, { "fixed", "Corrigé" } }

local window

function Z:NewsText()
	local L = Z.L
	local lines = {}
	for _, entry in ipairs(Z.changes) do
		lines[#lines + 1] = "|cff33dd88Lyorune " .. entry.version .. "|r  |cff8a8f99" .. entry.date .. "|r"
		for _, section in ipairs(Z.changeSections) do
			local notes = entry[section[1]]
			if notes and #notes > 0 then
				lines[#lines + 1] = "  |cffffd24d" .. L[section[2]] .. "|r"
				for _, note in ipairs(notes) do lines[#lines + 1] = "    - " .. L[note] end
			end
		end
		lines[#lines + 1] = ""
	end
	return table.concat(lines, "\n")
end

function Z:ShowNews()
	local UI = Z.UI
	if not window then
		window = UI.Window("LyoruneNews", Z.L["Nouveautés de Lyorune"], 560, 400)
		tinsert(UISpecialFrames, "LyoruneNews")
		local scroll = CreateFrame("ScrollFrame", nil, window)
		scroll:SetPoint("TOPLEFT", 16, -46)
		scroll:SetPoint("BOTTOMRIGHT", -16, 16)
		scroll:EnableMouseWheel(true)
		scroll:SetScript("OnMouseWheel", function(self, delta)
			local position = self:GetVerticalScroll() - delta * 40
			self:SetVerticalScroll(math.max(0, math.min(position, self:GetVerticalScrollRange())))
		end)
		local content = CreateFrame("Frame", nil, scroll)
		content:SetSize(520, 10)
		scroll:SetScrollChild(content)
		window.text = UI.Text(content, 12)
		window.text:SetPoint("TOPLEFT")
		window.text:SetWidth(520)
		window.text:SetJustifyH("LEFT")
		window.text:SetSpacing(4)
		window.content = content
	end
	window.text:SetText(Z:NewsText())
	window.content:SetHeight(window.text:GetStringHeight() + 10)
	window:Show()
end
