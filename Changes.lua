-- Zenith (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Zenith - Changes.lua : les nouveautés de chaque version, affichées en jeu après une mise à jour.
-- Ce fichier est la SEULE source du journal des versions : outils/publier.py y ajoute la nouvelle version
-- et régénère CHANGELOG.md à partir de lui. La version la plus récente est en premier.

local _, Z = ...

Z.changes = {
	{
		version = "1.3.0", date = "2026-11-16",
		"Signaler un bug en trois questions avec /zenith bug : un rapport prêt à copier.",
		"Trois préréglages de transparence : discret, semi-transparent, bien visible.",
		"Changement de spécialisation ou de talents pris en compte sans /reload.",
		"Un joueur déconnecté reste visible avec la mention « Déco ».",
		"Notification d'erreur réglable, une seule par session.",
		"Diagnostic de position avec /zenith position, en vue de la flèche de direction.",
	},
	{
		version = "1.2.0", date = "2026-11-16",
		"Mode test : un faux groupe de 5 à 40 joueurs pour régler l'apparence (/zenith test).",
		"Cadres séparés pour les tanks et les familiers, ordre des rôles au choix.",
		"Barre de mana des soigneurs, alerte visuelle de vie basse, buffs de groupe manquants.",
		"Soins sur la durée en icônes ou en barres fines, affaiblissements importants en grand.",
		"Touches au survol, résurrection automatique sur le clic de soin.",
		"Listes personnelles : sorts à suivre, affaiblissements à ignorer ou à mettre en avant.",
		"Luminosité, opacité, contraste élevé, réduction automatique des cases en grand raid.",
		"Profils prêts à l'emploi, envoi direct de sa configuration à un joueur, tout réinitialiser.",
		"Options rangées en huit onglets avec une recherche. Traduction anglaise.",
		"Avertissement quand un membre du groupe a une version plus récente.",
	},
	{
		version = "1.1.0", date = "2026-11-16",
		"Cinq thèmes, annonces de mana et de résurrection, partage de configuration par code.",
		"Journal d'erreurs (/zenith erreurs) et contrôle de compatibilité (/zenith diag).",
	},
	{
		version = "1.0.0", date = "2026-11-16",
		"Première version pour WoW Forever : cadres, clic-soin, soins en route, dissipation, tutoriel.",
	},
}

local window

function Z:NewsText()
	local lines = {}
	for _, entry in ipairs(Z.changes) do
		lines[#lines + 1] = "|cff33dd88Zenith " .. entry.version .. "|r  |cff8a8f99" .. entry.date .. "|r"
		for _, line in ipairs(entry) do lines[#lines + 1] = "  - " .. line end
		lines[#lines + 1] = ""
	end
	return table.concat(lines, "\n")
end

function Z:ShowNews()
	local UI = Z.UI
	if not window then
		window = UI.Window("ZenithNews", Z.L["Nouveautés de Zenith"], 560, 400)
		tinsert(UISpecialFrames, "ZenithNews")
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
