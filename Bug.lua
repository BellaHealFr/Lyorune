-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Bug.lua : signaler un bug à l'auteur, et diagnostics de position (/lyorune position) et de soins (/lyorune soins).
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
	"Que faisiez-vous quand c'est arrivé ?",
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
-- Un octet de mot : lettre, chiffre, ou morceau d'une lettre accentuée (octet de 128 et plus)
local function WordByte(text, at)
	local byte = text:byte(at)
	return byte ~= nil and (byte >= 128 or text:sub(at, at):match("%w") ~= nil)
end

-- Remplace « word » seulement comme mot entier : un personnage « Lyo » ne touche ni « Lyorune » ni un chemin
local function ReplaceWord(text, word, by)
	local parts, from = {}, 1
	while true do
		local first, last = text:find(word, from, true)
		if not first then break end
		if not WordByte(text, first - 1) and not WordByte(text, last + 1) then
			parts[#parts + 1] = text:sub(from, first - 1) .. by
		else
			parts[#parts + 1] = text:sub(from, last)
		end
		from = last + 1
	end
	parts[#parts + 1] = text:sub(from)
	return table.concat(parts)
end

Z.ReplaceWord = ReplaceWord -- aussi pour corriger l'écriture d'un sort dans une macro (Macros.lua)

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
	for _, realm in ipairs(realms) do text = ReplaceWord(text, realm, "(royaume)") end
	for _, name in ipairs(names) do text = ReplaceWord(text, name, "(joueur)") end
	return text
end

-- Rapport compact : les réponses du joueur, le contexte, et la première erreur de la session
function Z:BugReport(answers)
	local version, build, _, interface = GetBuildInfo()
	local lines = {
		("[Lyorune %s] jeu %s.%s (%s), %s"):format(Z.version, tostring(version), tostring(build), tostring(interface), tostring(GetLocale())),
		("%s niveau %s, spé %s, %s, %s, %s"):format(tostring(Z.class), tostring(UnitLevel("player")), Z:SpecName(),
			IsInRaid() and ("raid de " .. GetNumGroupMembers()) or IsInGroup() and "groupe" or "seul",
			InCombatLockdown() and "en combat" or "hors combat", Z:InstanceState()),
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
			local label = UI.Label(window, 12)
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
		UI.Paint(report, "text") -- sans couleur, le jeu écrit en blanc pur
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

		window.hint = UI.Label(window, 11, nil, "accent")
		window.hint:SetPoint("LEFT", select, "RIGHT", 12, 0)
		window.hint:SetWidth(400)
		window.hint:SetJustifyH("LEFT")

		local where = UI.Label(window, 12)
		where:SetPoint("BOTTOMLEFT", 16, 50)
		where:SetText(L["Collez votre rapport ici :"])
		local link = UI.Edit(window, 568)
		link:SetPoint("BOTTOMLEFT", 16, 20)
		link:SetText(Z:ReportURL())
		link:HookScript("OnTextChanged", function(self, byUser) if byUser then self:SetText(Z:ReportURL()) end end)
	end
	-- Nouvelle ouverture : réponses vides. Rappelée alors qu'elle est ouverte : elle passe devant, réponses gardées.
	if not window:IsShown() then
		for _, edit in ipairs(window.answers) do edit:SetText("") end
	end
	local hasError = (Z.firstError or (Z.db.errors or {})[1]) ~= nil
	window.hint:SetText(hasError and "" or L["Aucune erreur technique enregistrée : pensez à joindre une capture d'écran du défaut."])
	window.Update()
	UI.Reopen(window)
	window:Raise()
end

----------------------------------------------------------------------------------------------------
-- /lyorune position : ce que le jeu accepte de dire sur la position des joueurs, ici et maintenant.
-- Sert à vérifier les paliers de distance des cases (extérieur, donjon, combat). Le résultat est
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
		-- palier « très loin » des cases (1.19.0) : il faut une réponse lisible, même en combat
		Describe("vu par le jeu : " .. other, function() return UnitIsVisible(other) end),
	}
	local db = Z.db
	db.positionDiag = db.positionDiag or {}
	table.insert(db.positionDiag, 1, table.concat(lines, " || "))
	while #db.positionDiag > 12 do table.remove(db.positionDiag) end
	for _, line in ipairs(lines) do Z:Print(line) end
end

----------------------------------------------------------------------------------------------------
-- /lyorune soins : ce que le client donne pour dessiner les soins sur la barre de vie (soins en route,
-- soins sur la durée, incantation, vie max réduite). Ne change rien : il décrit, et le résultat va aussi
-- au journal (lu hors du jeu par outils/erreurs.py). Après la commande, la prochaine incantation du joueur
-- est décrite une fois toute seule (pendant qu'elle est en route), puis l'écoute s'arrête.
----------------------------------------------------------------------------------------------------
local function Value(value)
	if Z.IsSecret(value) then return "secret" end
	if type(value) == "number" then return ("%.4g"):format(value) end
	if type(value) == "table" then
		local parts = {}
		for i, v in ipairs(value) do parts[i] = Value(v) end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(value)
end

local function Values(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[i] = Value((select(i, ...))) end
	return #parts > 0 and table.concat(parts, ", ") or "rien"
end

-- Une ligne par vérification ; une erreur du jeu est écrite au lieu de tout arrêter.
-- Le nombre de réponses est compté (select) : un nil au milieu ne cache pas les suivantes.
local function Answer(Add, label, ok, ...)
	if ok then Add(label .. " : " .. Values(...)) else Add(label .. " : erreur (" .. tostring((...)) .. ")") end
end
local function Check(Add, label, fn)
	Answer(Add, label, pcall(fn))
end

local function DescribeIncoming(Add, unit)
	if not (CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction) then
		Add("calculateur de soins en route absent de ce client") return
	end
	for _, overflow in ipairs({ false, 1.0, 1.25 }) do
		local calc = CreateUnitHealPredictionCalculator()
		local label = "soins en route sur " .. unit
		if overflow then
			if not calc.SetIncomingHealOverflowPercent then Add("SetIncomingHealOverflowPercent absente") return end
			calc:SetIncomingHealOverflowPercent(overflow)
			label = label .. (" (dépassement %d %%)"):format(overflow * 100)
		end
		Check(Add, label, function()
			UnitGetDetailedHealPrediction(unit, "player", calc)
			return calc:GetIncomingHeals()
		end)
	end
	Check(Add, "UnitGetIncomingHeals " .. unit .. " (tous, les miens)", function()
		return UnitGetIncomingHeals(unit), UnitGetIncomingHeals(unit, "player")
	end)
end

local function DescribeAuras(Add)
	local list = C_UnitAuras and C_UnitAuras.GetUnitAuras and C_UnitAuras.GetUnitAuras("player", "HELPFUL|PLAYER")
	if Z.IsSecret(list) then Add("mes auras sur moi : liste secrète") return end
	if type(list) ~= "table" then Add("mes auras sur moi : " .. type(list)) return end
	Add(("mes auras sur moi : %d"):format(#list))
	for i = 1, math.min(#list, 6) do
		local aura = list[i]
		if Z.IsSecret(aura) then Add("  aura secrète") else
			Add(("  %s, sort %s, durée %s, fin %s, nombres %s"):format(Value(aura.name), Value(aura.spellId),
				Value(aura.duration), Value(aura.expirationTime), Value(aura.points)))
		end
	end
end

local function DescribeCast(Add)
	Check(Add, "incantation (nom, début, fin, sort)", function()
		local name, _, _, startMS, endMS, _, _, _, spellID = UnitCastingInfo("player")
		return name, startMS, endMS, spellID
	end)
	Check(Add, "UnitCastingDuration", function()
		local duration = UnitCastingDuration and UnitCastingDuration("player")
		if duration == nil then return UnitCastingDuration and "rien" or "absente" end
		return type(duration), duration.GetRemainingDuration and duration:GetRemainingDuration()
	end)
end

local function DescribeHeals(Add, moment)
	Add(("%s | %s | %s"):format(date("%Y-%m-%d %H:%M:%S"), moment, InCombatLockdown() and "en combat" or "hors combat"))
	Check(Add, "auras secrètes", function() return C_Secrets.ShouldAurasBeSecret() end)
	DescribeIncoming(Add, "player")
	if UnitExists("target") then DescribeIncoming(Add, "target") end
	local ok, err = pcall(DescribeAuras, Add) -- une aura inattendue n'empêche pas de décrire l'incantation
	if not ok then Add("mes auras : erreur (" .. tostring(err) .. ")") end
	DescribeCast(Add)
	Add("C_DurationUtil.CreateDuration : " .. (C_DurationUtil and C_DurationUtil.CreateDuration and "oui" or "absente"))
	Check(Add, "durée fabriquée de 10 s (SetTimeFromStart, reste)", function()
		local duration = C_DurationUtil.CreateDuration()
		if not duration.SetTimeFromStart then return "SetTimeFromStart absente" end
		duration:SetTimeFromStart(GetTime(), 10)
		return "oui", duration.GetRemainingDuration and duration:GetRemainingDuration()
	end)
	local bar = Z.buttons and Z.buttons[1] and Z.buttons[1].incoming
	Add("SetTimerDuration sur une barre : " .. (bar and (bar.SetTimerDuration and "oui" or "absente") or "aucune case"))
	Check(Add, "vie max réduite (GetUnitTotalModifiedMaxHealthPercent, joueur)", function()
		if not GetUnitTotalModifiedMaxHealthPercent then return "absente" end
		return GetUnitTotalModifiedMaxHealthPercent("player")
	end)
	for _, line in ipairs(Z.HotReport()) do Add(line) end -- montants appris de mes soins sur la durée (Hots.lua)
	-- part perdue sur ma case (Frames.lua)
	for _, cell in ipairs(Z.buttons or {}) do
		local same = cell.unit and UnitIsUnit(cell.unit, "player")
		if cell.unit and not Z.IsSecret(same) and same and cell:IsVisible() and Z.LostReport then
			for _, line in ipairs(Z.LostReport(cell)) do Add("part perdue, " .. line) end
			break
		end
	end
end

local function RunHeals(moment)
	local lines = {}
	-- une ligne devenue secrète (valeur du jeu mêlée au texte) est remplacée : rien ne doit planter
	local ok, err = pcall(DescribeHeals, function(text) lines[#lines + 1] = Z.IsSecret(text) and "(ligne secrète)" or tostring(text) end, moment)
	if not ok then lines[#lines + 1] = "diagnostic interrompu : " .. tostring(err) end
	for _, text in ipairs(lines) do Z:Print(text) end
	Z:Log("Diagnostic soins", table.concat(lines, " | "), "")
end

-- Écoute d'une seule incantation : créée à la demande, arrêtée dès la première (ou au bout d'une minute)
local castWatch, watchCount = nil, 0
function Z:DiagnoseHeals()
	RunHeals("maintenant")
	watchCount = watchCount + 1
	local count = watchCount
	castWatch = castWatch or CreateFrame("Frame")
	castWatch:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
	castWatch:SetScript("OnEvent", function(self)
		self:UnregisterAllEvents()
		C_Timer.After(0.3, function() RunHeals("pendant l'incantation") end) -- le soin doit être parti en route
	end)
	C_Timer.After(60, function() if count == watchCount then castWatch:UnregisterAllEvents() end end)
	Z:Print(Z.L["Lancez un soin dans la minute : il sera décrit pendant son incantation."])
end
