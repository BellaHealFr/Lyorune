-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Bug.lua : signaler un bug à l'auteur, et diagnostic de position pour la future flèche de direction.
--
-- Un addon ne peut rien envoyer sur internet. /lyorune bug pose donc trois questions et prépare un rapport
-- compact que le joueur copie (Ctrl+C) et colle à l'adresse indiquée. Aucune fenêtre ne s'ouvre toute seule.

local _, Z = ...

-- Adresse du formulaire de signalement : en français, ou en anglais si Lyorune est en anglais
function Z:ReportURL()
	local english = Z.L["Mort"] ~= "Mort"
	return "https://github.com/BellaHealFr/Lyorune/issues/new?template=" .. (english and "bug_en.yml" or "bug.yml")
end

local QUESTIONS = {
	"Que faisais-tu quand c'est arrivé ?",
	"Que s'est-il passé ?",
	"Est-ce que ça se reproduit à chaque fois ?",
}

-- Les premières lignes d'une pile d'appels suffisent pour localiser une erreur
local function ShortStack(stack)
	local lines = {}
	for line in tostring(stack or ""):gmatch("[^\n]+") do
		lines[#lines + 1] = line
		if #lines == 5 then break end
	end
	return table.concat(lines, "\n")
end

-- Le rapport finit sur GitHub, en public : le nom de mon personnage, de mon royaume et des membres de mon groupe
-- y sont remplacés par « (joueur) » et « (royaume) », même s'ils apparaissent dans un message d'erreur ou une réponse.
local function Escape(text) return (text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end

function Z:Anonymize(text)
	local names, realms = {}, {}
	local function add(list, value)
		if type(value) == "string" and not Z.IsSecret(value) and #value >= 2 then list[#list + 1] = value end
	end
	local units = { "player" }
	for i = 1, 4 do units[#units + 1] = "party" .. i end
	if IsInRaid() then for i = 1, 40 do units[#units + 1] = "raid" .. i end end
	for _, unit in ipairs(units) do
		if UnitExists(unit) then
			pcall(function()
				local name, realm = UnitName(unit)
				add(names, name) add(realms, realm)
			end)
		end
	end
	pcall(function() add(realms, GetRealmName()) add(realms, GetNormalizedRealmName()) end)
	-- les plus longs d'abord : « Jainara » avant « Jaina »
	table.sort(names, function(a, b) return #a > #b end)
	table.sort(realms, function(a, b) return #a > #b end)
	for _, realm in ipairs(realms) do text = text:gsub(Escape(realm), "(royaume)") end
	for _, name in ipairs(names) do text = text:gsub(Escape(name), "(joueur)") end
	return text
end

-- Rapport compact : les réponses du joueur, le contexte, et la première erreur de la session
function Z:BugReport(answers)
	local version, build, _, interface = GetBuildInfo()
	local lines = {
		("[Lyorune %s] jeu %s.%s (%s), %s"):format(Z.version, tostring(version), tostring(build), tostring(interface), tostring(GetLocale())),
		("%s niveau %s, spé %s, %s, %s"):format(tostring(Z.class), tostring(UnitLevel("player")), Z:SpecName(),
			IsInRaid() and ("raid de " .. GetNumGroupMembers()) or IsInGroup() and "groupe" or "seul",
			InCombatLockdown() and "en combat" or "hors combat"),
	}
	for i, question in ipairs(QUESTIONS) do
		local answer = answers and answers[i] or ""
		lines[#lines + 1] = question .. " " .. (answer ~= "" and answer or "(sans réponse)")
	end
	local errors = Z.db.errors or {}
	local first = Z.firstError or errors[1]
	if first then
		lines[#lines + 1] = ("Erreurs enregistrées : %d. Première de la session (x%d, %s) :"):format(#errors, first.count or 1, tostring(first.kind))
		lines[#lines + 1] = tostring(first.message)
		local stack = ShortStack(first.stack)
		if stack ~= "" then lines[#lines + 1] = stack end
	else
		lines[#lines + 1] = "Aucune erreur technique enregistrée."
	end
	return Z:Anonymize(table.concat(lines, "\n"))
end

local window

function Z:ShowBug()
	local UI, L = Z.UI, Z.L
	if not window then
		window = UI.Window("LyoruneBug", L["Signaler un bug"], 600, 520)
		window.beside = true -- à côté des options, jamais dessous ni par-dessus
		window:SetFrameStrata("FULLSCREEN_DIALOG")
		tinsert(UISpecialFrames, "LyoruneBug")
		window.answers = {}

		local function Update()
			local answers = {}
			for i, edit in ipairs(window.answers) do answers[i] = edit:GetText() end
			window.report:SetText(Z:BugReport(answers))
		end
		window.Update = Update

		for i, question in ipairs(QUESTIONS) do
			local label = UI.Text(window, 12)
			label:SetPoint("TOPLEFT", 16, -46 - (i - 1) * 50)
			label:SetText(L[question])
			local edit = UI.Edit(window, 568)
			edit:SetPoint("TOPLEFT", 16, -64 - (i - 1) * 50)
			edit:SetMaxLetters(200)
			edit:HookScript("OnTextChanged", function(_, byUser) if byUser then Update() end end)
			window.answers[i] = edit
		end

		local title = UI.Text(window, 12)
		title:SetPoint("TOPLEFT", 16, -200)
		title:SetText(L["Rapport prêt à envoyer (Ctrl+C pour copier) :"])
		UI.Paint(title, "accent")

		local scroll = CreateFrame("ScrollFrame", nil, window)
		scroll:SetPoint("TOPLEFT", 16, -220)
		scroll:SetPoint("BOTTOMRIGHT", -16, 110)
		scroll.bg = UI.Paint(UI.Tex(scroll, "BACKGROUND"), "panel")
		scroll.bg:SetAllPoints()
		UI.Field(scroll, scroll.bg) -- zone de texte habillée selon le thème
		scroll:EnableMouseWheel(true)
		scroll:SetScript("OnMouseWheel", function(self, delta)
			local position = self:GetVerticalScroll() - delta * 40
			self:SetVerticalScroll(math.max(0, math.min(position, self:GetVerticalScrollRange())))
		end)
		local report = CreateFrame("EditBox", nil, scroll)
		report:SetMultiLine(true)
		report:SetAutoFocus(false)
		report:SetFont(UI.Font(), 11, "")
		report:SetWidth(560)
		report:SetTextInsets(6, 6, 6, 6)
		report:SetScript("OnEscapePressed", report.ClearFocus)
		scroll:SetScrollChild(report)
		window.report = report

		local select = UI.Button(window, L["Tout sélectionner"], 150, 24, function()
			report:SetFocus()
			report:HighlightText()
		end)
		select:SetPoint("BOTTOMLEFT", 16, 78)
		select.label:SetJustifyH("CENTER")

		window.hint = UI.Text(window, 11)
		window.hint:SetPoint("LEFT", select, "RIGHT", 12, 0)
		window.hint:SetWidth(400)
		window.hint:SetJustifyH("LEFT")
		window.hint:SetTextColor(1, 0.82, 0.3)

		local where = UI.Text(window, 12)
		where:SetPoint("BOTTOMLEFT", 16, 50)
		where:SetText(L["Colle ton rapport ici :"])
		local link = UI.Edit(window, 568)
		link:SetPoint("BOTTOMLEFT", 16, 20)
		link:SetText(Z:ReportURL())
		link:HookScript("OnTextChanged", function(self, byUser) if byUser then self:SetText(Z:ReportURL()) end end)
	end
	for _, edit in ipairs(window.answers) do edit:SetText("") end
	local hasError = (Z.firstError or (Z.db.errors or {})[1]) ~= nil
	window.hint:SetText(hasError and "" or L["Aucune erreur technique enregistrée : pense à joindre une capture d'écran du défaut."])
	window.Update()
	window:Show()
end

----------------------------------------------------------------------------------------------------
-- /lyorune position : ce que le jeu accepte de dire sur la position des joueurs, ici et maintenant.
-- Sert à décider si une flèche de direction est possible (extérieur, donjon, combat). Le résultat est
-- affiché dans le chat et gardé dans LyoruneDB.positionDiag pour pouvoir être relu hors du jeu.
----------------------------------------------------------------------------------------------------
local function Describe(label, fn)
	local ok, a, b, c = pcall(fn)
	if not ok then return label .. " : erreur (" .. tostring(a) .. ")" end
	local parts = {}
	for _, value in ipairs({ a, b, c }) do
		parts[#parts + 1] = Z.IsSecret(value) and "secret" or tostring(value)
	end
	return label .. " : " .. (#parts > 0 and table.concat(parts, ", ") or "rien")
end

function Z:DiagnosePosition()
	local other = IsInRaid() and "raid1" or "party1"
	local inInstance, kind = IsInInstance()
	local lines = {
		("%s | instance : %s (%s) | %s | %s"):format(date("%Y-%m-%d %H:%M:%S"), tostring(inInstance), tostring(kind),
			InCombatLockdown() and "en combat" or "hors combat", tostring(GetRealZoneText and GetRealZoneText())),
		Describe("orientation du joueur", function() return GetPlayerFacing() end),
		Describe("position du joueur", function() return UnitPosition("player") end),
		Describe("position de " .. other, function() return UnitPosition(other) end),
		Describe("carte du joueur", function() return C_Map.GetBestMapForUnit("player") end),
		Describe("position sur la carte de " .. other, function()
			local position = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), other)
			if not position then return nil end
			return position:GetXY()
		end),
		Describe("à portée de " .. other, function() return UnitInRange(other) end),
	}
	local db = Z.db
	db.positionDiag = db.positionDiag or {}
	table.insert(db.positionDiag, 1, table.concat(lines, " || "))
	while #db.positionDiag > 12 do table.remove(db.positionDiag) end
	for _, line in ipairs(lines) do Z:Print(line) end
end
