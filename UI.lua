-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - UI.lua : le style visuel et les petits éléments d'interface (boutons, cases, fenêtres).
-- Tout est dessiné avec les éléments natifs du jeu : rien de plus léger.

local _, Z = ...
local UI = {}
Z.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"
UI.WHITE = WHITE

-- Palette
UI.accent = { 0.20, 0.87, 0.53 }
UI.bg     = { 0.05, 0.06, 0.08 }
UI.panel  = { 0.10, 0.11, 0.14 }
UI.line   = { 0.22, 0.24, 0.30 }
UI.text   = { 0.92, 0.94, 0.97 }
UI.dim    = { 0.60, 0.64, 0.70 }

-- LibSharedMedia est facultatif : s'il est installé (ElvUI, SharedMedia...), ses textures sont proposées.
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local builtinTextures = {
	{ "Lyorune", WHITE },
	{ "Blizzard", "Interface\\TargetingFrame\\UI-StatusBar" },
	{ "Raid", "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
}

function UI.TextureList()
	local list = {}
	for _, entry in ipairs(builtinTextures) do list[#list + 1] = entry[1] end
	if LSM then
		for _, name in ipairs(LSM:List("statusbar")) do list[#list + 1] = name end
	end
	return list
end

function UI.BarTexture()
	local wanted = Z.db.texture
	if wanted == "THEME" then return Z:Theme().texture end
	for _, entry in ipairs(builtinTextures) do
		if entry[1] == wanted then return entry[2] end
	end
	return (LSM and LSM:Fetch("statusbar", wanted, true)) or WHITE
end

function UI.Font()
	return STANDARD_TEXT_FONT
end

----------------------------------------------------------------------------------------------------
-- Briques de base
----------------------------------------------------------------------------------------------------
function UI.Tex(parent, layer, r, g, b, a)
	local t = parent:CreateTexture(nil, layer or "BACKGROUND")
	t:SetTexture(WHITE)
	t:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
	return t
end

function UI.Text(parent, size, flags)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(UI.Font(), size or 12, flags or "")
	fs:SetShadowColor(0, 0, 0, 1)
	fs:SetShadowOffset(1, -1)
	fs:SetTextColor(UI.text[1], UI.text[2], UI.text[3])
	return fs
end

-- Bordure de « size » pixels autour de parent, décalée de « outset » vers l'extérieur
local function BorderSetColor(self, r, g, b, a)
	for i = 1, 4 do self[i]:SetVertexColor(r, g, b, a or 1) end
end

local function BorderSetThickness(self, size)
	self[1]:SetHeight(size)
	self[2]:SetHeight(size)
	self[3]:SetPoint("TOPLEFT", 0, -size) self[3]:SetPoint("BOTTOMLEFT", 0, size) self[3]:SetWidth(size)
	self[4]:SetPoint("TOPRIGHT", 0, -size) self[4]:SetPoint("BOTTOMRIGHT", 0, size) self[4]:SetWidth(size)
end

function UI.Border(parent, size, outset)
	local f = CreateFrame("Frame", nil, parent)
	outset = outset or 0
	f:SetPoint("TOPLEFT", parent, "TOPLEFT", -outset, outset)
	f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", outset, -outset)
	for i = 1, 4 do f[i] = UI.Tex(f, "OVERLAY", 0, 0, 0, 1) end
	f[1]:SetPoint("TOPLEFT") f[1]:SetPoint("TOPRIGHT")
	f[2]:SetPoint("BOTTOMLEFT") f[2]:SetPoint("BOTTOMRIGHT")
	f.SetColor = BorderSetColor
	f.SetThickness = BorderSetThickness
	f:SetThickness(size)
	return f
end

local function Click()
	PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
end

----------------------------------------------------------------------------------------------------
-- Éléments des fenêtres
----------------------------------------------------------------------------------------------------
function UI.Button(parent, text, width, height, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(width, height)
	b.bg = UI.Tex(b, "BACKGROUND", UI.panel[1], UI.panel[2], UI.panel[3])
	b.bg:SetAllPoints()
	b.border = UI.Border(b, 1)
	b.border:SetColor(UI.line[1], UI.line[2], UI.line[3])
	b.label = UI.Text(b, 12)
	b.label:SetPoint("LEFT", 6, 0)
	b.label:SetPoint("RIGHT", -6, 0)
	b.label:SetWordWrap(false)
	b.label:SetText(text or "")
	b:SetScript("OnEnter", function(self)
		self.border:SetColor(UI.accent[1], UI.accent[2], UI.accent[3])
		if self.tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(self.tip, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end
	end)
	b:SetScript("OnLeave", function(self)
		self.border:SetColor(UI.line[1], UI.line[2], UI.line[3])
		GameTooltip:Hide()
	end)
	b:SetScript("OnClick", function(self, button)
		Click()
		if onClick then onClick(self, button) end
	end)
	return b
end

-- Case à cocher : get() donne l'état, set(valeur) l'enregistre
function UI.Check(parent, label, get, set)
	local c = CreateFrame("Button", nil, parent)
	c:SetSize(250, 20)
	c.box = UI.Tex(c, "BACKGROUND", UI.panel[1], UI.panel[2], UI.panel[3])
	c.box:SetSize(16, 16)
	c.box:SetPoint("LEFT")
	c.border = UI.Border(c, 1)
	c.border:ClearAllPoints()
	c.border:SetAllPoints(c.box)
	c.border:SetColor(UI.line[1], UI.line[2], UI.line[3])
	c.mark = UI.Tex(c, "ARTWORK", UI.accent[1], UI.accent[2], UI.accent[3])
	c.mark:SetPoint("TOPLEFT", c.box, 3, -3)
	c.mark:SetPoint("BOTTOMRIGHT", c.box, -3, 3)
	c.label = UI.Text(c, 12)
	c.label:SetPoint("LEFT", c.box, "RIGHT", 8, 0)
	c.label:SetText(label)
	c.Update = function(self) self.mark:SetShown(get() and true or false) end
	c:SetScript("OnClick", function(self)
		Click()
		set(not get())
		self:Update()
	end)
	c:SetScript("OnShow", c.Update)
	c:Update()
	return c
end

-- Valeur numérique avec boutons - et +
function UI.Stepper(parent, label, min, max, step, get, set)
	local s = CreateFrame("Frame", nil, parent)
	s:SetSize(250, 22)
	s.label = UI.Text(s, 12)
	s.label:SetPoint("LEFT")
	s.label:SetText(label)
	s.value = UI.Text(s, 12)
	s.value:SetPoint("RIGHT", -30, 0)
	s.value:SetWidth(40)
	s.value:SetTextColor(UI.accent[1], UI.accent[2], UI.accent[3])
	s.Update = function(self) self.value:SetText(get()) end
	local function change(delta)
		set(math.max(min, math.min(max, get() + delta)))
		s:Update()
	end
	s.plus = UI.Button(s, "+", 22, 22, function() change(step) end)
	s.plus:SetPoint("RIGHT")
	s.plus.label:SetJustifyH("CENTER")
	s.minus = UI.Button(s, "-", 22, 22, function() change(-step) end)
	s.minus:SetPoint("RIGHT", -74, 0)
	s.minus.label:SetJustifyH("CENTER")
	s:SetScript("OnShow", s.Update)
	s:Update()
	return s
end

-- Choix parmi une liste : chaque clic passe au choix suivant (clic droit : précédent).
-- choices = { { valeur, "libellé" }, ... }
function UI.Cycle(parent, label, choices, get, set)
	local c = CreateFrame("Frame", nil, parent)
	c:SetSize(250, 22)
	c.label = UI.Text(c, 12)
	c.label:SetPoint("LEFT")
	c.label:SetText(label)
	local function index()
		local current = get()
		for i, choice in ipairs(choices) do
			if choice[1] == current then return i end
		end
		return 1
	end
	c.button = UI.Button(c, "", 130, 22, function(_, mouseButton)
		local i = index() + (mouseButton == "RightButton" and -1 or 1)
		if i > #choices then i = 1 elseif i < 1 then i = #choices end
		set(choices[i][1])
		c:Update()
	end)
	c.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	c.button:SetPoint("RIGHT")
	c.button.label:SetJustifyH("CENTER")
	c.button.label:SetTextColor(UI.accent[1], UI.accent[2], UI.accent[3])
	c.Update = function(self) self.button.label:SetText(choices[index()][2]) end
	c:SetScript("OnShow", c.Update)
	c:Update()
	return c
end

-- Champ de saisie. onEnter(texte) est appelé à la touche Entrée.
function UI.Edit(parent, width, onEnter)
	local e = CreateFrame("EditBox", nil, parent)
	e:SetSize(width, 22)
	e:SetAutoFocus(false)
	e:SetFont(UI.Font(), 12, "")
	e:SetTextInsets(6, 6, 0, 0)
	e.bg = UI.Tex(e, "BACKGROUND", UI.panel[1], UI.panel[2], UI.panel[3])
	e.bg:SetAllPoints()
	e.border = UI.Border(e, 1)
	e.border:SetColor(UI.line[1], UI.line[2], UI.line[3])
	e:SetScript("OnEscapePressed", e.ClearFocus)
	e:SetScript("OnEditFocusGained", function(self)
		self.border:SetColor(UI.accent[1], UI.accent[2], UI.accent[3])
		self:HighlightText()
	end)
	e:SetScript("OnEditFocusLost", function(self)
		self.border:SetColor(UI.line[1], UI.line[2], UI.line[3])
		self:HighlightText(0, 0)
	end)
	e:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		if onEnter then onEnter((self:GetText():match("^%s*(.-)%s*$"))) end
	end)
	return e
end

-- Fenêtre déplaçable avec titre et bouton de fermeture
function UI.Window(name, title, width, height)
	local w = CreateFrame("Frame", name, UIParent)
	w:SetSize(width, height)
	w:SetPoint("CENTER")
	w:SetFrameStrata("DIALOG")
	w:SetClampedToScreen(true)
	w:EnableMouse(true)
	w:SetMovable(true)
	w:RegisterForDrag("LeftButton")
	w:SetScript("OnDragStart", w.StartMoving)
	w:SetScript("OnDragStop", w.StopMovingOrSizing)
	w.bg = UI.Tex(w, "BACKGROUND", UI.bg[1], UI.bg[2], UI.bg[3], 0.96)
	w.bg:SetAllPoints()
	w.border = UI.Border(w, 1)
	w.border:SetColor(0, 0, 0, 1)
	w.accent = UI.Tex(w, "ARTWORK", UI.accent[1], UI.accent[2], UI.accent[3])
	w.accent:SetPoint("TOPLEFT", 1, -1)
	w.accent:SetPoint("TOPRIGHT", -1, -1)
	w.accent:SetHeight(2)
	w.title = UI.Text(w, 15)
	w.title:SetPoint("TOPLEFT", 14, -14)
	w.title:SetText(title)
	w.close = UI.Button(w, "x", 22, 22, function() w:Hide() end)
	w.close:SetPoint("TOPRIGHT", -10, -10)
	w.close.label:SetJustifyH("CENTER")
	w:Hide()
	return w
end
