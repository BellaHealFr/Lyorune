-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Log.lua : journal d'erreurs et contrôle de compatibilité avec la version du jeu.
--
-- Le journal est enregistré dans LyoruneDB.errors, donc dans le fichier
--   WTF\Account\<COMPTE>\SavedVariables\Lyorune.lua
-- En jeu : /lyorune erreurs (fenêtre à copier-coller), /lyorune diag (contrôle de compatibilité).
-- Chaque entrée dit QUOI (message), OÙ (pile d'appels : fichier et ligne) et DANS QUEL CONTEXTE
-- (version de Lyorune et du jeu, classe, combat, groupe), pour corriger sans avoir à reproduire le bug.

local ADDON, Z = ...

Z.testedInterface = 16001 -- version du jeu avec laquelle cette version de Lyorune a été testée
local MAX_ENTRIES = 30

-- Fonctions du jeu indispensables. Si une mise à jour du jeu en retire une, /lyorune diag la nomme.
Z.requiredAPI = {
	"UnitHealthPercent", "UnitHealthMissing", "UnitInRange", "UnitGetDetailedHealPrediction",
	"CreateUnitHealPredictionCalculator", "AbbreviateNumbers", "UnitGroupRolesAssigned",
	"UnitHasIncomingResurrection", "UnitThreatSituation", "CreateColor",
	"C_CurveUtil.CreateColorCurve", "Enum.LuaCurveType.Step",
	"C_UnitAuras.GetUnitAuras", "C_UnitAuras.GetAuraDuration",
	"C_UnitAuras.GetAuraApplicationDisplayCount", "C_UnitAuras.GetAuraDispelTypeColor",
	"C_ClassColor.GetClassColor", "C_Spell.GetSpellName", "C_Spell.GetSpellTexture",
	"C_Timer.After", "C_Timer.NewTicker",
}

function Z:MissingAPI()
	local missing = {}
	for _, path in ipairs(Z.requiredAPI) do
		local value = _G
		for part in path:gmatch("[^.]+") do
			value = type(value) == "table" and value[part] or nil
		end
		if value == nil then missing[#missing + 1] = path end
	end
	return missing
end

local function GameVersion()
	local version, build, _, interface = GetBuildInfo()
	return ("%s.%s (interface %s)"):format(tostring(version), tostring(build), tostring(interface)), interface
end

----------------------------------------------------------------------------------------------------
-- Enregistrement
----------------------------------------------------------------------------------------------------
local warned, logging

function Z:Log(kind, message, stack)
	local db = Z.db
	if not db or logging then return end
	logging = true
	db.errors = db.errors or {}
	local now = date("%Y-%m-%d %H:%M:%S")
	for _, entry in ipairs(db.errors) do
		if entry.message == message then -- même erreur : on compte au lieu de remplir le journal
			entry.count = entry.count + 1
			entry.last = now
			Z.firstError = Z.firstError or entry
			logging = false
			return
		end
	end
	table.insert(db.errors, 1, {
		kind = kind,
		message = message,
		stack = stack,
		first = now,
		last = now,
		count = 1,
		lyorune = Z.version,
		game = GameVersion(),
		class = Z.class,
		level = UnitLevel("player"),
		spec = Z:SpecName(),
		combat = InCombatLockdown() and true or false,
		group = IsInRaid() and ("raid de " .. GetNumGroupMembers()) or IsInGroup() and "groupe" or "seul",
		zone = GetRealZoneText and GetRealZoneText() or "?",
	})
	while #db.errors > MAX_ENTRIES do table.remove(db.errors) end
	Z.firstError = Z.firstError or db.errors[1] -- la première de la session : les suivantes en découlent souvent
	if not warned and db.errorNotice then
		warned = true
		Z:Print(Z.L["Lyorune a rencontré un problème. Tapez |cff33dd88/lyorune bug|r pour le signaler."])
	end
	logging = false
end

-- Spécialisation du joueur, si le jeu sait la donner
function Z:SpecName()
	local ok, name = pcall(function()
		local index = C_SpecializationInfo.GetSpecialization()
		local _, specName = C_SpecializationInfo.GetSpecializationInfo(index)
		return specName or ("n° " .. tostring(index))
	end)
	return ok and name and tostring(name) or "?"
end

-- Rapport complet, lisible par un humain
function Z:LogText()
	local lines = {
		"=== Journal Lyorune ===",
		"Lyorune " .. Z.version .. " (testé pour l'interface " .. Z.testedInterface .. ")",
		"Jeu : " .. GameVersion(),
		"Classe : " .. tostring(Z.class) .. ", niveau " .. tostring(UnitLevel("player")) .. ", langue " .. tostring(GetLocale()),
	}
	local missing = Z:MissingAPI()
	lines[#lines + 1] = "Fonctions du jeu manquantes : " .. (#missing > 0 and table.concat(missing, ", ") or "aucune")
	local errors = Z.db.errors or {}
	lines[#lines + 1] = "Erreurs enregistrées : " .. #errors
	for i, e in ipairs(errors) do
		lines[#lines + 1] = ""
		lines[#lines + 1] = ("--- %d. %s (x%d) ---"):format(i, e.kind, e.count)
		lines[#lines + 1] = "Message : " .. tostring(e.message)
		lines[#lines + 1] = ("Première fois : %s, dernière fois : %s"):format(e.first, e.last)
		lines[#lines + 1] = ("Contexte : Lyorune %s, jeu %s, %s niveau %s spé %s, %s, %s, %s"):format(tostring(e.lyorune), tostring(e.game),
			tostring(e.class), tostring(e.level), tostring(e.spec), e.combat and "en combat" or "hors combat", tostring(e.group), tostring(e.zone))
		if e.stack and e.stack ~= "" then lines[#lines + 1] = "Pile d'appels :\n" .. e.stack end
	end
	return table.concat(lines, "\n")
end

----------------------------------------------------------------------------------------------------
-- Capture : toute erreur Lua qui cite Lyorune, et toute action que le jeu bloque à Lyorune
----------------------------------------------------------------------------------------------------
local function HookErrors()
	local previous = geterrorhandler()
	seterrorhandler(function(message, ...)
		if type(message) == "string" and not Z.IsSecret(message) and message:find(ADDON, 1, true) then
			pcall(Z.Log, Z, "Erreur Lua", message, debugstack(3, 15, 0))
		end
		return previous(message, ...)
	end)
end

local function Blocked(kind)
	return function(addon, action)
		if addon == ADDON then
			Z:Log(kind, tostring(action), debugstack(2, 15, 0))
		end
	end
end
Z:On("ADDON_ACTION_BLOCKED", Blocked("Action interdite en combat"))
Z:On("ADDON_ACTION_FORBIDDEN", Blocked("Action réservée au jeu"))

----------------------------------------------------------------------------------------------------
-- Contrôle au démarrage. Renvoie false si Lyorune ne peut pas fonctionner avec ce client.
----------------------------------------------------------------------------------------------------
function Z:CheckGame()
	HookErrors()
	local _, interface = GameVersion()
	local missing = Z:MissingAPI()
	if #missing > 0 then
		Z:Log("Incompatibilité", "Fonctions du jeu manquantes : " .. table.concat(missing, ", "))
		Z:Print(Z.L["cette version du jeu n'est pas compatible (fonctions manquantes : %s). Lyorune reste désactivé. Détails : /lyorune erreurs"]:format(table.concat(missing, ", ")))
		return false
	end
	if interface ~= Z.testedInterface and Z.db.lastInterface ~= interface then
		Z:Print(Z.L["le jeu est passé à l'interface %s (Lyorune a été testé pour %s). Tout semble compatible ; en cas de souci, tapez /lyorune erreurs."]:format(tostring(interface), Z.testedInterface))
	end
	Z.db.lastInterface = interface
	return true
end

function Z:Diagnose()
	local missing = Z:MissingAPI()
	Z:Print(Z.L["jeu %s, Lyorune %s testé pour l'interface %s."]:format((GameVersion()), Z.version, Z.testedInterface))
	if #missing == 0 then
		Z:Print(Z.L["compatibilité : toutes les fonctions nécessaires sont présentes."])
	else
		Z:Print(Z.L["compatibilité : fonctions manquantes : %s"]:format(table.concat(missing, ", ")))
	end
	Z:Print(Z.L["%d erreur(s) dans le journal (/lyorune erreurs)."]:format(#(Z.db.errors or {})))
end

----------------------------------------------------------------------------------------------------
-- Fenêtre du journal : texte à sélectionner et copier
----------------------------------------------------------------------------------------------------
local window

function Z:ShowLog()
	local UI = Z.UI
	if not window then
		window = UI.Window("LyoruneLog", "Journal d'erreurs", 660, 440)
		tinsert(UISpecialFrames, "LyoruneLog")

		local scroll = CreateFrame("ScrollFrame", nil, window)
		scroll:SetPoint("TOPLEFT", 14, -44)
		scroll:SetPoint("BOTTOMRIGHT", -14, 50)
		scroll.bg = UI.Tex(scroll, "BACKGROUND", UI.panel[1], UI.panel[2], UI.panel[3])
		scroll.bg:SetAllPoints()
		scroll:EnableMouseWheel(true)
		scroll:SetScript("OnMouseWheel", function(self, delta)
			local position = self:GetVerticalScroll() - delta * 60
			self:SetVerticalScroll(math.max(0, math.min(position, self:GetVerticalScrollRange())))
		end)

		local edit = CreateFrame("EditBox", nil, scroll)
		edit:SetMultiLine(true)
		edit:SetAutoFocus(false)
		edit:SetFont(UI.Font(), 11, "")
		edit:SetWidth(620)
		edit:SetTextInsets(6, 6, 6, 6)
		edit:SetScript("OnEscapePressed", edit.ClearFocus)
		scroll:SetScrollChild(edit)
		window.edit = edit

		local select = UI.Button(window, Z.L["Tout sélectionner"], 140, 24, function()
			edit:SetFocus()
			edit:HighlightText()
		end)
		select:SetPoint("BOTTOMLEFT", 14, 14)
		select.label:SetJustifyH("CENTER")
		local clear = UI.Button(window, Z.L["Vider le journal"], 130, 24, function()
			Z.db.errors = {}
			edit:SetText(Z:LogText())
		end)
		clear:SetPoint("LEFT", select, "RIGHT", 6, 0)
		clear.label:SetJustifyH("CENTER")
		local hint = UI.Text(window, 11)
		hint:SetPoint("LEFT", clear, "RIGHT", 12, 0)
		hint:SetTextColor(UI.dim[1], UI.dim[2], UI.dim[3])
		hint:SetText(Z.L["Ctrl+C pour copier, puis collez le texte à la personne qui vous aide."])
	end
	window.edit:SetText(Z:LogText())
	window:Show()
end
