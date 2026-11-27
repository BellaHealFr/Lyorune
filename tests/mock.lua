-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Faux client minimal pour faire tourner Lyorune hors du jeu (détection des erreurs Lua).
MISSING = {}
RAID = false
local frames = {}
local Obj = {}
Obj.__index = function(t, k)
	local v = Obj[k]
	if v then return v end
	if k == "Stretch" then return nil end -- champ posé par l'addon sur la seule fenêtre d'options (UI.Fit), pas une méthode
	if type(k) == "string" and k:match("^%u") then return function() end end -- méthode inconnue : sans effet
end

-- Fenêtres posées sur une autre (UI.OnTop) : comme dans le jeu, les cacher lance OnHide, qui rend à
-- UISpecialFrames les noms retirés (ailleurs, les tests lancent OnHide à la main)
local HIDE_RUNS_ONHIDE = { LyorunePicker = true, LyoruneMacroImport = true, LyoruneMacroWizard = true }

local function new(kind, name, parent)
	local o = setmetatable({ _kind = kind, _name = name, _parent = parent, _scripts = {}, _attr = {}, _events = {}, _shown = true, _w = 100, _h = 20,
		_hideRuns = name and HIDE_RUNS_ONHIDE[name], _level = parent and (parent._level or 1) + 1 or 1 }, Obj)
	frames[#frames + 1] = o
	if name then _G[name] = o end
	return o
end

function Obj:SetScript(n, f) self._scripts[n] = f end
function Obj:SetHyperlinksEnabled(on) self._links = on end
function Obj:GetScript(n) return self._scripts[n] end
function Obj:HookScript(n, f)
	local old = self._scripts[n]
	self._scripts[n] = old and function(...) old(...) f(...) end or f
end
function Obj:Run(n, ...) if self._scripts[n] then return self._scripts[n](self, ...) end end
function Obj:SetAttribute(k, v) self._attr[k] = v; self:Run("OnAttributeChanged", k, v) end
function Obj:GetAttribute(k) return self._attr[k] end
function Obj:Show() local was = self._shown; self._shown = true; if not was then self:Run("OnShow") end end
function Obj:Hide()
	local was = self._shown
	self._shown = false
	if was and self._hideRuns then self:Run("OnHide") end
end
function Obj:SetShown(s) if s then self:Show() else self:Hide() end end
function Obj:IsShown() return self._shown end
function Obj:IsVisible() return self._shown end
function Obj:RegisterEvent(e)
	if e == "FAKE_EVENT" then error("unknown event") end
	self._events[e] = true
end
function Obj:RegisterUnitEvent(e, u) self._events[e] = u end
function Obj:UnregisterAllEvents() self._events = {} end
function Obj:CreateTexture(_, layer, _, sub) local t = new("Texture", nil, self) t._layer, t._sublevel = layer, sub return t end
function Obj:CreateFontString() return new("FontString", nil, self) end
function Obj:CreateAnimationGroup() return new("AnimationGroup", nil, self) end
function Obj:CreateAnimation() return new("Animation", nil, self) end
function Obj:CreateControlPoint() return new("ControlPoint", nil, self) end
function Obj:CreateMaskTexture() return new("MaskTexture", nil, self) end
function Obj:GetStatusBarTexture() self._sbt = self._sbt or new("Texture", nil, self); return self._sbt end
function Obj:SetSize(w, h) self._w, self._h = w, h end
function Obj:SetWidth(w) self._w = w end
function Obj:SetHeight(h) self._h = h end
function Obj:GetWidth() return self._w end
function Obj:GetHeight() return self._h end
function Obj:GetStringHeight() return 60 end
function Obj:GetStringWidth() return 120 end
-- Niveaux comme dans le jeu : un enfant naît un cran au-dessus de son parent et le suit quand il change
function Obj:GetFrameLevel() return self._level or 1 end
function Obj:SetFrameLevel(level)
	local delta = level - (self._level or 1)
	self._level = level
	for _, child in ipairs(self._children or {}) do child:SetFrameLevel((child._level or 1) + delta) end
end
function Obj:GetChildren() return unpack(self._children or {}) end
function Obj:GetName() return self._name end
function Obj:GetParent() return self._parent end
function Obj:SetText(t) self._text = t end
function Obj:SetFormattedText(f, ...) self._text = string.format(f, ...) end
function Obj:GetText() return self._text or "" end
function Obj:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function Obj:GetIncomingHeals() if SECRET then return MakeSecret(10), MakeSecret(5), MakeSecret(5), MakeSecret(false) end return 10, 5, 5, false end
function Obj:GetDamageAbsorbs() return 3, false end
function Obj:GetTotalDamageAbsorbs() if ABSORB_TOTAL == nil then return 4 end return ABSORB_TOTAL end
function Obj:GetRGB() return 1, 1, 1 end
function Obj:GetRGBA() return 1, 1, 1, 1 end
function Obj:SetAlphaFromBoolean(b, x, y) assert(type(x) == "number" and type(y) == "number") end
function Obj:List() return { "Flat", "Glossy" } end
function Obj:Fetch() return "tex" end
function Obj:StartMoving() end
function Obj:StopMovingOrSizing() end
function Obj:ClearFocus() end
-- Couleurs, police et animations : notées pour que les tests puissent les vérifier
function Obj:GetObjectType() return self._kind end
function Obj:SetVertexColor(r, g, b, a) self._color = { r, g, b, a } if a ~= nil then self._alpha = a end end -- comme le jeu : l'opacité de la couleur remplace celle de la texture
function Obj:SetTextColor(r, g, b, a) self._color = { r, g, b, a } end
function Obj:SetFont(file, size) self._font, self._size = file, size return true end
function Obj:SetCountdownFont(name) self._countdownFont = name end
function Obj:SetTexture(t) self._tex = t end
function Obj:SetAlpha(a) self._alpha = a end
function Obj:SetMinMaxValues(lo, hi) self._min, self._max = lo, hi end
function Obj:SetValue(v, smoothing)
	-- comme le jeu : la 2e valeur (l'animation) ne peut jamais être secrète
	if issecretvalue and issecretvalue(smoothing) then error("SetValue : valeur secrete en 2e argument", 2) end
	self._value, self._smoothing = v, smoothing
end
function Obj:SetDrawLayer(layer, sub) self._layer, self._sublevel = layer, sub end
function Obj:SetToTargetValue() self._snapped = true end
function Obj:GetValue() return self._value end
function Obj:GetAlpha() return self._alpha or 1 end
function Obj:SetFrameStrata(strata) self._strata = strata end
function Obj:GetFrameStrata() return self._strata or "MEDIUM" end
function Obj:EnableMouse(on) self._mouse = on and true or false end
function Obj:IsMouseEnabled() return self._mouse or false end
function Obj:SetStatusBarColor(r, g, b, a) self._barColor = { r, g, b, a } end
function Obj:SetBackdrop(b) self._backdrop = b end
function Obj:SetPoint(...)
	self._point = { ... }
	-- Toutes les ancres, pour les tests qui recalculent la place d'un élément (aucune géométrie ici)
	self._points = self._points or {}
	self._points[(...)] = { ... }
	self._all = nil
end
function Obj:ClearAllPoints() self._points, self._all = nil, nil end
function Obj:SetAllPoints(relative) self._points, self._all = nil, relative or self._parent end
function Obj:Play() self._playing = true end
function Obj:Stop() self._playing = false end
function Obj:IsPlaying() return self._playing or false end

function FireEvent(e, ...)
	if e == "PLAYER_REGEN_DISABLED" or e == "PLAYER_REGEN_ENABLED" then ApplyStateDrivers() end
	for _, f in ipairs(frames) do
		if f._events[e] then f:Run("OnEvent", e, ...) end
	end
end
function RunUpdates()
	for _, f in ipairs(frames) do
		if f._kind == "Frame" and f._shown and f._scripts.OnUpdate then f:Run("OnUpdate", 0.01) end
	end
end

UIParent = new("Frame", "UIParent")
Minimap = new("Frame", "Minimap")
function Obj:GetCenter() return 400, 300 end
function Obj:GetEffectiveScale() return 1 end
function Obj:SetScale(s) self._scale = s end
function Obj:GetScale() return self._scale or 1 end
function GetCursorPosition() return CURSOR_X or 500, CURSOR_Y or 300 end
GameTooltip = new("GameTooltip", "GameTooltip")
function CreateFont(name) return new("Font", name) end
function CreateFrame(kind, name, parent)
	local o = new(kind, name, parent)
	if parent and parent ~= UIParent then -- UIParent : trop d'enfants pour les compter, et personne ne les lit
		parent._children = parent._children or {}
		parent._children[#parent._children + 1] = o
	end
	return o
end
function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a, GetRGB = function() return r, g, b end, GetRGBA = function() return r, g, b, a end } end
function CopyTable(t) local c = {} for k, v in pairs(t) do c[k] = type(v) == "table" and CopyTable(v) or v end return c end
PixelUtil = {
	SetWidth = function(t, w, pixels) t._w, t._pixels = w, pixels end,
	SetHeight = function(t, h, pixels) t._h, t._pixels = h, pixels end,
}
tinsert = table.insert
UISpecialFrames = {}
BackdropTemplateMixin = {}
SlashCmdList = {}
STANDARD_TEXT_FONT = "font"
READY_CHECK_READY_TEXTURE, READY_CHECK_NOT_READY_TEXTURE, READY_CHECK_WAITING_TEXTURE = "r", "n", "w"
Enum = {
	StatusBarInterpolation = { Immediate = 0, ExponentialEaseOut = 1 },
	LuaCurveType = { Step = 1, Linear = 0 },
	UnitIncomingHealClampMode = { MissingHealth = 1, MaximumHealth = 0 },
	UnitDamageAbsorbClampMode = { MissingHealth = 1, MaximumHealth = 0 },
	UnitAuraSortRule = { Default = 0 },
	SpellBookSpellBank = { Player = 0 },
	SpellBookItemType = { Spell = 1 },
}
CurveConstants = { ScaleTo100 = new("Curve") }
SOUNDKIT = { IG_MAINMENU_OPTION_CHECKBOX_ON = 856 }

COMBAT = false
local names = { [2061] = "Soins rapides", [2060] = "Soins supérieurs", [139] = "Rénovation", [17] = "Mot de pouvoir : Bouclier",
	[527] = "Dissipation de la magie", [552] = "Abolir maladie", [2006] = "Résurrection", [401859] = "Prière de guérison", [6346] = "Gardien de peur", [596] = "Prière de soins",
	[528] = "Guérison des maladies", [1243] = "Mot de pouvoir : Robustesse", [21562] = "Prière de robustesse", [2054] = "Soins", [2050] = "Soins inférieurs",
	-- étape 23 : sort externe, Âme affaiblie, boissons (26473 a un autre nom : il doit être écarté)
	[10060] = "Infusion de puissance", [6788] = "Âme affaiblie", [430] = "Boisson", [431] = "Boisson", [1133] = "Boisson", [26473] = "Nourriture" }
C_AddOns = { GetAddOnMetadata = function() return TOC_VERSION or "0.0.0" end }
C_Timer = { After = function(_, f) f() end, NewTicker = function(_, f) TICK = f end }
C_Spell = {
	GetSpellName = function(id) return names[id] end,
	GetSpellTexture = function(id) return 1234 end,
	IsSpellHelpful = function() return true end,
	GetSpellInfo = function(name) for id, n in pairs(names) do if n == name or id == name then return { name = n, spellID = id } end end end,
}
C_SpellBook = {
	IsSpellKnown = function(id) return names[id] ~= nil and id ~= 2050 end,
	FindSpellBookSlotForSpell = function() return nil end,
	GetNumSpellBookSkillLines = function() return 1 end,
	GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = 4 } end,
	GetSpellBookItemInfo = function(slot) return { itemType = 1, isPassive = false, spellID = ({ 2061, 139, 17, 527 })[slot] } end,
}
C_CurveUtil = { CreateColorCurve = function() return new("Curve") end, CreateCurve = function() return new("Curve") end }
C_ClassColor = { GetClassColor = function(class) if class == "DRUID" then return { r = 1, g = 0.49, b = 0.04 } end return { r = 1, g = 1, b = 1 } end }
AURAS = {}
C_UnitAuras = {
	GetUnitAuras = function(unit, filter, count)
		if filter:find("FAKE") then error("bad filter") end
		return AURAS[filter] or {}
	end,
	GetAuraDuration = function() return new("Duration") end,
	GetAuraApplicationDisplayCount = function() return "" end,
	GetAuraDispelTypeColor = function() return CreateColor(0.2, 0.6, 1, 1) end,
	IsAuraFilteredOutByInstanceID = function() return false end,
}
function UnitPowerPercent(u, p, predicted, curve) if curve == CurveConstants.ScaleTo100 then return 60 end return CreateColor(1, 1, 1, 1) end
function CreateUnitHealPredictionCalculator() return new("Calc") end
function UnitGetDetailedHealPrediction() end
function UnitClass(u) return "Prêtre", "PRIEST" end
local GAME_CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER" }
function GetNumClasses() return #GAME_CLASSES end
function GetClassInfo(i) return GAME_CLASSES[i], GAME_CLASSES[i], i end
function UnitName(u) return "Joueur-" .. u end
function UnitExists(u) return true end
function UnitHealth() return 800 end
function UnitHealthMax() return 1000 end
function UnitHealthMissing() return 200 end
function UnitHealthPercent(u, p, curve) if curve == CurveConstants.ScaleTo100 then return 80 end return CreateColor(1, 1, 1, 1) end
function AbbreviateNumbers(n) return tostring(n) end
rawset(_G, "OFFLINE", false)
function UnitIsConnected() return not OFFLINE end
function UnitIsDeadOrGhost(u) if type(DEAD) == "table" then return DEAD[u] or false end return DEAD or false end -- DEAD : tous, ou { [unité] = true }
function UnitIsGhost() return false end
function UnitInRange() return true, true end
function UnitThreatSituation() return 3 end
function UnitGroupRolesAssigned() return "HEALER" end
function GetRaidTargetIndex() return 4 end
function SetRaidTargetIconTexture() end
function GetReadyCheckStatus() return "ready" end
function UnitHasIncomingResurrection() return false end
function UnitIsUnit() return false end
function InCombatLockdown() return COMBAT end
-- Régénération de mana par seconde (hors combat, puis pendant les 5 s après un sort)
function GetPowerRegen() return 10, 0 end
-- Macros du personnage : MACROS[1] porte le numéro 121 dans le jeu
MACROS, PICKED = {}, false
MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = 120, 18
function GetNumMacros() return 0, #MACROS end
function GetMacroInfo(index) local m = MACROS[index - 120] if m then return m.name, m.icon, m.body end end
function GetMacroBody(index) local m = MACROS[index - 120] return m and m.body end
function GetMacroIndexByName(name) for i, m in ipairs(MACROS) do if m.name == name then return 120 + i end end return 0 end
function CreateMacro(name, icon, body, perCharacter)
	assert(not COMBAT and perCharacter and #name <= 16 and #body <= 255, "macro refusee : " .. name)
	MACROS[#MACROS + 1] = { name = name, icon = icon, body = body }
	return 120 + #MACROS
end
function EditMacro(index, name, icon, body) local m = MACROS[index - 120] m.name, m.body = name, body end
function DeleteMacro(index) assert(not COMBAT) table.remove(MACROS, index - 120) end
function PickupMacro(index) PICKED = MACROS[index - 120].name CURSOR_INFO = { "macro", index } end
-- Règles de visibilité : le faux client les réévalue à chaque changement de combat (voir FireEvent dans run.py)
STATE_DRIVERS = {}
-- Règle « [cond,cond] action; [cond] action; action » : conditions combat et group:raid
function SecureCmdOptionParse(rule)
	for clause in (rule .. ";"):gmatch("%s*([^;]+);") do
		local conds, action = clause:match("^%[(.-)%]%s*(%a+)$")
		if not conds then return clause:match("^%s*(%a+)") end
		local ok = true
		for cond in conds:gmatch("[^,]+") do
			if cond == "combat" then ok = ok and COMBAT == true
			elseif cond == "group:raid" then ok = ok and RAID == true
			else error("condition inconnue du faux client : " .. cond) end
		end
		if ok then return action end
	end
end
function RegisterStateDriver(frame, state, rule) assert(state == "visibility") STATE_DRIVERS[frame] = rule end
function UnregisterStateDriver(frame) STATE_DRIVERS[frame] = nil end
function ApplyStateDrivers()
	for frame, rule in pairs(STATE_DRIVERS) do frame:SetShown(SecureCmdOptionParse(rule) == "show") end
end
function IsPlayerSpell() return false end
function GameTooltip_SetDefaultAnchor() end
function PlaySound() end
function LibStub(name, silent) return new("Lib") end
function issecretvalue() return false end
PRINTED = {}
function print(...) PRINTED[#PRINTED + 1] = table.concat({ ... }, " ") end

setmetatable(_G, { __index = function(_, k) MISSING[k] = true return nil end })

-- Ajouts : annonces, journal, partage
MANA, SENT, NOW, INSTANCE, GROUPED = 1000, {}, 100, true, true
rawset(_G, "DEAD", false)
rawset(_G, "ClickCastFrames", {})
function UnitPower() return MANA end
function UnitPowerMax() return 1000 end
function UnitLevel() return 60 end
function GetLocale() return "frFR" end
function GetTime() return NOW end
function IsInGroup() return GROUPED end
function IsInRaid() return RAID or false end
INSTANCE_TYPE = "none"
function IsInInstance() return INSTANCE, INSTANCE_TYPE end
function GetInstanceInfo() return INSTANCE_NAME or "Donjon d'essai", INSTANCE_TYPE end
function GetNumGroupMembers() return 5 end
function GetRealZoneText() return "Hurlevent" end
function GetBuildInfo() return "1.60.1", "70938", "Nov 1 2026", INTERFACE or 16001 end
function SendChatMessage(text, channel) SENT[#SENT + 1] = channel .. ":" .. text end
function date() return "2026-11-16 21:00:00" end
function time() return 1795392000 end
function debugstack() return "Interface/AddOns/Lyorune/Frames.lua:42: in function <UpdateHealth>" end
local handler = function(msg) LAST_ERROR = msg end
function geterrorhandler() return handler end
function seterrorhandler(f) handler = f end
function RaiseError(msg) return handler(msg) end
UIErrorsFrame = CreateFrame("Frame", "UIErrorsFrame")
C_AddOns.IsAddOnLoaded = function(name) return name == "ElvUI" end
-- Mesure des performances : chronomètre, mémoire par addon (le profileur, C_AddOnProfiler, est ajouté par le test)
function debugprofilestop() return os.clock() * 1000 end
MEMORY = { Lyorune = 850, ElvUI = 12000 }
function UpdateAddOnMemoryUsage() MEMORY._updated = true end
function GetAddOnMemoryUsage(name) return MEMORY[name] or 0 end
C_ChatInfo = { InChatMessagingLockdown = function() return false end }
ERR_OUT_OF_MANA = "Pas assez de mana"

----------------------------------------------------------------------------------------------------
-- Ajouts 1.2 : valeurs secrètes simulées, messages d'addon, touches
----------------------------------------------------------------------------------------------------
-- Une valeur secrète peut être affichée, mais tout calcul, comparaison ou lecture de champ échoue,
-- comme dans le jeu. (Limite : un simple « if valeur then » ne peut pas être détecté ici.)
local Secret = {}
Secret.__tostring = function() return "<secret>" end
Secret.__index = function() error("lecture d'un champ d'une valeur secrète", 2) end
Secret.__eq = function() error("comparaison d'une valeur secrète", 2) end
function MakeSecret(value) return setmetatable({}, Secret) end
function issecretvalue(value) return getmetatable(value) == Secret end
-- Comme le jeu : parcourir une liste secrète est une erreur (vu dans Logs\General.log, 17 novembre 2026)
do
	local realIpairs, realPairs = ipairs, pairs
	ipairs = function(t, ...)
		if getmetatable(t) == Secret then error("bad argument #1 to 'ipairs' (table expected, got secret)", 2) end
		return realIpairs(t, ...)
	end
	pairs = function(t, ...)
		if getmetatable(t) == Secret then error("bad argument #1 to 'pairs' (table expected, got secret)", 2) end
		return realPairs(t, ...)
	end
end

SECRET = false
local function S(value)
	if SECRET then return MakeSecret(value) end
	return value
end

function UnitHealth() return S(800) end
function UnitHealthMax() return S(HEALTH_MAX or 1000) end -- HEALTH_MAX : vie inconnue (0) pour un test
function UnitHealthMissing() return S(200) end
function UnitHealthPercent(u, p, curve)
	-- HEALTH_PCT (0 à 1) : un test qui veut une vraie courbe l'évalue lui-même (curve.Evaluate posé par le test)
	if HEALTH_PCT and type(curve) == "table" and rawget(curve, "Evaluate") then return curve:Evaluate(HEALTH_PCT) end
	if curve == CurveConstants.ScaleTo100 then return S(80) end
	local c = { r = S(1), g = S(1), b = S(1), a = S(1) }
	c.GetRGB = function() return c.r, c.g, c.b end
	c.GetRGBA = function() return c.r, c.g, c.b, c.a end
	return c
end
function AbbreviateNumbers(n) return issecretvalue(n) and n or tostring(n) end
function UnitIsDeadOrGhost(u) if type(DEAD) == "table" then return S(DEAD[u] or false) end return S(DEAD or false) end
function UnitInRange() return S(true), S(true) end
function UnitThreatSituation() return S(3) end
function UnitGroupRolesAssigned() return S("HEALER") end
function GetRaidTargetIndex() return S(4) end
function UnitIsUnit() return S(false) end
function UnitHasIncomingResurrection() return S(false) end
function UnitPower() return S(MANA) end
function UnitPowerMax() return S(1000) end
-- Ressource du joueur (bug C7) : la mana, sauf si un test choisit POWER_TYPE et POWER_TOKEN
-- Sans choix du test : la ressource de la classe (guerrier rage, voleur énergie, chasseur focalisation), sinon la mana
local CLASS_POWER = { WARRIOR = { 1, "RAGE" }, ROGUE = { 3, "ENERGY" }, HUNTER = { 2, "FOCUS" } }
function UnitPowerType(u)
	if POWER_TYPE == nil and u and UnitClass then
		local p = CLASS_POWER[select(2, UnitClass(u)) or ""]
		if p then return S(p[1]), S(p[2]) end
	end
	return S(POWER_TYPE or 0), S(POWER_TOKEN or "MANA")
end
-- Couleurs des barres de ressource du jeu, par nom et par numéro
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 }, RAGE = { r = 1, g = 0, b = 0 }, ENERGY = { r = 1, g = 1, b = 0 },
	FOCUS = { r = 1, g = 0.5, b = 0.25 } }
PowerBarColor[0], PowerBarColor[1], PowerBarColor[2], PowerBarColor[3] = PowerBarColor.MANA, PowerBarColor.RAGE,
	PowerBarColor.FOCUS, PowerBarColor.ENERGY
function UnitPowerPercent(u, p, predicted, curve)
	if curve == CurveConstants.ScaleTo100 then return S(60) end
	return { r = S(1), g = S(1), b = S(1), a = S(1) } -- courbe de couleurs : la couleur, secrète
end
C_UnitAuras.GetAuraDispelTypeColor = function()
	local c = { S(0.2), S(0.6), S(1), S(1) }
	return { GetRGBA = function() return c[1], c[2], c[3], c[4] end }
end

-- Les fonctions d'affichage acceptent les secrets ; celles qui décident de la visibilité ou du placement, non
local Obj = getmetatable(UIParent)
local strict = { "SetShown", "SetSize", "SetWidth", "SetHeight", "SetPoint" }
for _, method in ipairs(strict) do
	local original = rawget(Obj, method) or function() end
	Obj[method] = function(self, ...)
		for i = 1, select("#", ...) do
			if issecretvalue((select(i, ...))) then error(method .. " a reçu une valeur secrète", 2) end
		end
		return original(self, ...)
	end
end
function Obj:SetFormattedText(format, ...)
	local args = { ... }
	for i = 1, #args do
		if issecretvalue(args[i]) then
			args[i] = 0
			format = format:gsub("%%s", "%%d", 1)
		end
	end
	self._text = string.format(format, unpack(args))
end
function Obj:GetVerticalScroll() return 0 end
function Obj:GetVerticalScrollRange() return 100 end

-- Messages d'addon : ce que Lyorune envoie est gardé dans ADDON_SENT
ADDON_SENT = {}
C_ChatInfo.RegisterAddonMessagePrefix = function() return true end
C_ChatInfo.SendAddonMessage = function(prefix, text, channel, target)
	ADDON_SENT[#ADDON_SENT + 1] = { prefix = prefix, text = text, channel = channel, target = target }
	return true
end

function IsAltKeyDown() return false end
function IsControlKeyDown() return CTRL or false end
function IsShiftKeyDown() return false end
rawset(_G, "CTRL", false)
rawset(_G, "HEALTH_PCT", false)
rawset(_G, "LyorunePreview", false)


-- Ajouts 1.6 : spécialisation, objet tenu par la souris, cadres sous la souris
rawset(_G, "SPEC_GROUP", 1)
rawset(_G, "CURSOR_INFO", false)
rawset(_G, "MOUSE_FOCI", false)
C_SpecializationInfo = { GetActiveSpecGroup = function() return SPEC_GROUP end }
function GetCursorInfo() if CURSOR_INFO then return unpack(CURSOR_INFO) end end
function ClearCursor() CURSOR_INFO = false end
function GetMouseFoci() return MOUSE_FOCI or {} end

----------------------------------------------------------------------------------------------------
-- Ajouts 1.8 : auras privées, absorption de soins, invocation, phase
----------------------------------------------------------------------------------------------------
Enum.UnitHealAbsorbClampMode = { CurrentHealth = 1, MaximumHealth = 0 }
PRIVATE, PRIVATE_NEXT = {}, 0
C_UnitAuras.AddPrivateAuraAnchor = function(args)
	assert(args.unitToken and args.auraIndex and args.parent and args.iconInfo.iconAnchor.relativeTo, "ancre incomplete")
	PRIVATE_NEXT = PRIVATE_NEXT + 1
	PRIVATE[PRIVATE_NEXT] = args
	return PRIVATE_NEXT
end
C_UnitAuras.RemovePrivateAuraAnchor = function(id) assert(PRIVATE[id], "ancre inconnue") PRIVATE[id] = nil end
C_IncomingSummon = { IncomingSummonStatus = function() return SUMMON or 0 end }
function UnitPhaseReason() return PHASE end
function UnitIsPlayer() return true end
function Obj:GetHealAbsorbs() return 4, false end

----------------------------------------------------------------------------------------------------
-- Ajouts 1.8.1 : groupe, guilde et amis (qui peut me proposer sa configuration), royaume
----------------------------------------------------------------------------------------------------
GROUP_NAMES, GUILD_LIST, FRIEND_LIST = {}, {}, {}
function GetNormalizedRealmName() return "MonRoyaume" end
function GetRealmName() return "Mon Royaume" end
function Ambiguate(name) return (name:gsub("%-MonRoyaume$", "")) end
function GetUnitName(u) return GROUP_NAMES[u] or UnitName(u) end
function IsInGuild() return true end
C_GuildInfo = { MemberExistsByName = function(name) return GUILD_LIST[name] or false end }
C_FriendList = { GetFriendInfo = function(name) return FRIEND_LIST[name] and { name = name } or nil end }

----------------------------------------------------------------------------------------------------
-- Ajouts 1.14.0 : cases cible et focalisation, profils
----------------------------------------------------------------------------------------------------
UNIT_WATCH = {}
function RegisterUnitWatch(frame) UNIT_WATCH[frame] = true end
function UnregisterUnitWatch(frame) UNIT_WATCH[frame] = nil end
ENEMIES = {}
function UnitCanAttack(_, unit) return ENEMIES[unit] or false end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
MEMBERS = 5
function GetNumGroupMembers() return MEMBERS end

----------------------------------------------------------------------------------------------------
-- Ajouts 1.20.0 : chef de groupe et assistants, joueurs épinglés, signal du jeu
----------------------------------------------------------------------------------------------------
LEADER, ASSISTS = nil, {}
function UnitIsGroupLeader(u) if SECRET_LEADER then return MakeSecret() end return u == LEADER end
function UnitIsGroupAssistant(u) return ASSISTS[u] or false end
PingableType_UnitFrameMixin = {}

----------------------------------------------------------------------------------------------------
-- Ajouts 1.50.0 : canaux de discussion personnalisés (canal des soigneurs)
-- CHANNELS[nom en minuscules] = numéro ; LOCKED_CHANNELS[nom] = true : le jeu demande un mot de passe
----------------------------------------------------------------------------------------------------
CHANNELS, LOCKED_CHANNELS, CHANNEL_CALLS = {}, {}, {}
FACTION = "Alliance"
function UnitFactionGroup() return FACTION, FACTION end
local function ChannelNotice(kind, name) FireEvent("CHAT_MSG_CHANNEL_NOTICE", kind, "", "", "", "", "", 0, 0, name) end
function GetChannelName(name)
	local id = CHANNELS[tostring(name):lower()]
	if id then return id, name end
	return 0
end
function JoinPermanentChannel(name, password, frameID)
	CHANNEL_CALLS[#CHANNEL_CALLS + 1] = "join " .. name
	if CHANNELS_FULL then return end -- dix canaux : le jeu ne répond rien
	if LOCKED_CHANNELS[name] then
		FireEvent("CHANNEL_PASSWORD_REQUEST", name)
		ChannelNotice("WRONG_PASSWORD", name)
		return
	end
	local n = 4
	for _, id in pairs(CHANNELS) do if id >= n then n = id + 1 end end
	CHANNELS[name:lower()] = n
	ChannelNotice("YOU_JOINED", name)
end
function LeaveChannelByName(name)
	CHANNEL_CALLS[#CHANNEL_CALLS + 1] = "leave " .. name
	CHANNELS[name:lower()] = nil
	ChannelNotice("YOU_LEFT", name)
end
function GameRejoinsChannel(name) -- le jeu remet un canal permanent à la connexion
	local n = 4
	for _, id in pairs(CHANNELS) do if id >= n then n = id + 1 end end
	CHANNELS[name:lower()] = n
	ChannelNotice("YOU_JOINED", name)
end
function PlayerLeavesChannel(name) -- un /leave tapé par le joueur
	CHANNELS[name:lower()] = nil
	ChannelNotice("YOU_LEFT", name)
end
DEFAULT_CHAT_FRAME = CreateFrame("Frame", "ChatFrame1")
function DEFAULT_CHAT_FRAME:GetID() return 1 end
function DEFAULT_CHAT_FRAME:AddChannel(name) self.added = self.added or {} self.added[#self.added + 1] = name end
