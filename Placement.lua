-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Placement.lua : l'éditeur de placement.
-- Chaque élément de la case (nom, texte de vie, icônes...) se décale au pixel près sur une case d'exemple
-- agrandie : on le glisse à la souris, ou on le pousse avec les flèches. Le décalage est gardé pour chaque
-- forme de case (Barre, Tuile, Carré, Bandeau), car chaque forme a sa propre disposition d'origine.
-- Un seul réglage : Z.db.placement (Core.lua). Frames.lua et Auras.lua lisent Z.Offset en posant chaque élément.

local _, Z = ...
local UI = Z.UI
local L = Z.L

-- Les éléments que l'on peut placer, dans l'ordre de la liste
Z.placeElements = {
	{ "name", "Nom" },
	{ "text", "Texte de vie" },
	{ "role", "Icône de rôle" },
	{ "marker", "Marqueur de raid" },
	{ "center", "Icône centrale" },
	{ "hots", "Mes soins sur la durée" },
	{ "debuffs", "Affaiblissements" },
	{ "big", "Affaiblissement important" },
	{ "buff", "Buff manquant" },
	{ "private", "Auras privées" },
}
local KNOWN = {}
for _, element in ipairs(Z.placeElements) do KNOWN[element[1]] = true end

function Z.IsPlaceElement(key)
	return KNOWN[key] == true
end

-- Un décalage entier, borné par Z.limits.placement
local function Limit(value)
	local limit = Z.limits.placement
	value = math.floor((tonumber(value) or 0) + 0.5)
	return math.max(limit[1], math.min(limit[2], value))
end

-- Décalage d'un élément pour la forme choisie, en pixels de la case (0, 0 : place d'origine)
function Z.Offset(key)
	local db = Z.db
	local shape = db and type(db.placement) == "table" and db.placement[db.shape]
	local at = type(shape) == "table" and shape[key]
	if type(at) ~= "table" then return 0, 0 end
	return Limit(at[1]), Limit(at[2])
end

-- Enregistre un décalage. (0, 0) efface l'entrée : le réglage reste léger.
function Z.SetOffset(key, x, y, shape)
	if not KNOWN[key] then return end
	local all = Z.db.placement
	shape = shape or Z.db.shape
	x, y = Limit(x), Limit(y)
	all[shape] = all[shape] or {}
	all[shape][key] = (x ~= 0 or y ~= 0) and { x, y } or nil
	if not next(all[shape]) then all[shape] = nil end
end

-- Tous les éléments de la forme choisie reviennent à leur place d'origine
function Z.ResetPlacement()
	Z.db.placement[Z.db.shape] = nil
end

----------------------------------------------------------------------------------------------------
-- La fenêtre : la liste des éléments à gauche, la case d'exemple à droite, les flèches dessous
----------------------------------------------------------------------------------------------------
local WIDTH, HEIGHT = 580, 450
local STAGE_W, STAGE_H = 352, 232
local win, stage, cell, highlight
local selected = "name"
local drag

local SAMPLE_ICONS = {
	debuffs = { "Interface\\Icons\\Spell_Shadow_CurseOfTounges", "Interface\\Icons\\Spell_Nature_Slow" },
	big = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
	buff = "Interface\\Icons\\Spell_Holy_WordFortitude",
	private = "Interface\\Icons\\INV_Misc_QuestionMark",
}

local function SampleIcon(icon, texture)
	icon.texture:SetTexture(texture)
	icon.texture:SetDesaturated(false)
	icon.border:SetColor(0, 0, 0, 1)
	icon.cooldown:Clear()
	icon.count:SetText("")
	icon:SetAlpha(1)
	icon:Show()
end

-- Les morceaux qui forment un élément sur la case d'exemple
local function Regions(key)
	if key == "hots" then
		local list = Z.db.hotStyle == "BARS" and cell.hotBars or cell.hots
		return { list[1], list[2] }
	elseif key == "debuffs" then
		return { cell.debuffs[1], cell.debuffs[2] }
	elseif key == "big" then
		return { cell.bigIcon }
	elseif key == "buff" then
		return { cell.buffIcon }
	elseif key == "private" then
		return { cell.privateHolder }
	end
	return { cell[key] }
end

-- Rectangle d'un élément (gauche, droite, haut, bas), en coordonnées de la case
local function Bounds(key)
	local left, right, top, bottom
	for _, region in ipairs(Regions(key)) do
		local l, r, t, b = region:GetLeft(), region:GetRight(), region:GetTop(), region:GetBottom()
		if l and r and t and b then
			left, right = math.min(left or l, l), math.max(right or r, r)
			top, bottom = math.max(top or t, t), math.min(bottom or b, b)
		end
	end
	return left, right, top, bottom
end

-- Contour d'accent autour de l'élément choisi
local function ShowHighlight()
	local left, right, top, bottom = Bounds(selected)
	local cellLeft, cellTop = cell:GetLeft(), cell:GetTop()
	if not (left and cellLeft and cellTop) then return highlight:Hide() end
	highlight:ClearAllPoints()
	highlight:SetPoint("TOPLEFT", cell, "TOPLEFT", left - cellLeft - 1, top - cellTop + 1)
	highlight:SetSize(right - left + 2, top - bottom + 2)
	highlight.border:SetColor(UI.accent[1], UI.accent[2], UI.accent[3], 1)
	highlight:Show()
end

local function ShapeName(id)
	for _, choice in ipairs(Z.choices.shape) do
		if choice[1] == id then return L[choice[2]] end
	end
	return id
end

-- Dessine la case d'exemple avec TOUS les éléments, même ceux coupés dans les options : on peut les placer
-- d'avance. Les vraies cases, le mode test et cette case passent par les mêmes fonctions de placement.
local function Draw()
	local db = Z.db
	local width, height = Z.CellSize()
	cell:SetSize(width, height)
	cell:SetScale(math.max(1, math.min(3, (STAGE_W - 24) / width, (STAGE_H - 24) / height)))
	cell.powerShown = db.manaBars ~= "OFF"
	cell.power:SetShown(cell.powerShown)
	Z.StyleButton(cell)

	cell.hp:SetMinMaxValues(0, 100)
	cell.hp:SetValue(68)
	cell.hp:SetStatusBarColor(Z.ClassColor(Z.class))
	cell.power:SetMinMaxValues(0, 100)
	cell.power:SetValue(60)
	cell.name:SetText(UnitName("player") or L["Joueur"])
	cell.name:SetTextColor(1, 1, 1)
	cell.text:SetText(db.text == "PERCENT" and "68%" or "-1240")
	cell.text:SetTextColor(1, 1, 1)
	cell.role:SetAtlas("roleicon-tiny-healer")
	cell.role:Show()
	SetRaidTargetIconTexture(cell.marker, 1)
	cell.marker:Show()
	cell.center:SetTexture(READY_CHECK_READY_TEXTURE)
	cell.center:Show()

	local spells = Z.trackedSpells[Z.class] or { 139, 774 }
	for index = 1, 2 do
		if db.hotStyle == "BARS" then
			local bar = Z.HotBar(cell, index)
			bar:SetMinMaxValues(0, 1)
			bar:SetValue(index == 1 and 0.8 or 0.4)
			bar:Show()
		else
			SampleIcon(Z.HotIcon(cell, index), C_Spell.GetSpellTexture(spells[index] or spells[1]))
		end
		SampleIcon(Z.DebuffIcon(cell, index), SAMPLE_ICONS.debuffs[index])
	end
	SampleIcon(Z.BigIcon(cell), SAMPLE_ICONS.big)
	local buff = Z.BuffIcon(cell)
	SampleIcon(buff, SAMPLE_ICONS.buff)
	buff.texture:SetDesaturated(true)
	buff.border:SetColor(1, 0.2, 0.2, 1)

	-- Auras privées : le jeu les dessine lui-même, la case d'exemple montre deux points d'interrogation
	local holder, size = Z.PrivateHolder(cell)
	holder.sample = holder.sample or {}
	for index = 1, Z.PRIVATE_SLOTS do
		local sample = holder.sample[index] or holder:CreateTexture(nil, "ARTWORK")
		holder.sample[index] = sample
		sample:SetTexture(SAMPLE_ICONS.private)
		sample:SetSize(size, size)
		sample:ClearAllPoints()
		sample:SetPoint("LEFT", holder, "LEFT", (index - 1) * (size + 2), 0)
	end
	holder:Show()

	local x, y = Z.Offset(selected)
	win.coords:SetText(L["Décalage : %d, %d"]:format(x, y))
	win.shape:SetText(L["Forme : %s"]:format(ShapeName(db.shape)))
	for _, button in ipairs(win.list) do UI.SetTab(button, button.key == selected) end
	ShowHighlight()
end

-- Un changement fait dans l'éditeur : vraies cases, mode test et case d'exemple (Z:RefreshPlacement)
local function Changed()
	Z:Refresh()
end

local function Select(key)
	selected = key
	Draw()
end

-- Pousse l'élément choisi d'un pixel (Maj : 5 pixels)
local function Nudge(dx, dy)
	local step = IsShiftKeyDown() and 5 or 1
	local x, y = Z.Offset(selected)
	Z.SetOffset(selected, x + dx * step, y + dy * step)
	Changed()
end

-- L'élément sous la souris ; s'ils se recouvrent, le plus petit (une icône posée sur le nom)
local function ElementAt()
	local x, y = GetCursorPosition()
	local scale = cell:GetEffectiveScale()
	x, y = x / scale, y / scale
	local found, area
	for _, element in ipairs(Z.placeElements) do
		local left, right, top, bottom = Bounds(element[1])
		if left and x >= left and x <= right and y >= bottom and y <= top then
			local size = (right - left) * (top - bottom)
			if not area or size < area then found, area = element[1], size end
		end
	end
	return found
end

-- Glisser : la souris ne sert qu'à l'intérieur de la case d'exemple, et seulement pendant le glissement
local function Dragging()
	local x, y = GetCursorPosition()
	local scale = cell:GetEffectiveScale()
	local wantX = drag.offsetX + (x - drag.x) / scale
	local wantY = drag.offsetY + (y - drag.y) / scale
	local oldX, oldY = Z.Offset(drag.key)
	Z.SetOffset(drag.key, wantX, wantY)
	local newX, newY = Z.Offset(drag.key)
	if newX ~= oldX or newY ~= oldY then Draw() end
end

local function StopDrag()
	stage:SetScript("OnUpdate", nil)
	if drag then
		drag = nil
		Z:Refresh()
	end
end

local function StartDrag(_, button)
	if button ~= "LeftButton" then return end
	local key = ElementAt()
	if not key then return end
	Select(key)
	local x, y = GetCursorPosition()
	local offsetX, offsetY = Z.Offset(key)
	drag = { key = key, x = x, y = y, offsetX = offsetX, offsetY = offsetY }
	stage:SetScript("OnUpdate", Dragging)
end

local function Arrow(label, dx, dy)
	local button = UI.Button(win, L[label], 64, 22, function() Nudge(dx, dy) end)
	button.label:SetJustifyH("CENTER")
	button.tip = L["Un pixel par clic, cinq avec Maj."]
	return button
end

local function BuildWindow()
	win = UI.Window("LyorunePlacement", L["Placement des éléments"], WIDTH, HEIGHT)
	win:SetFrameStrata("FULLSCREEN_DIALOG")
	win.beside = true -- à côté des options, sans les recouvrir
	tinsert(UISpecialFrames, "LyorunePlacement")

	-- Liste des éléments
	win.list = {}
	for index, element in ipairs(Z.placeElements) do
		local button = UI.Button(win, L[element[2]], 186, 24, function(self) Select(self.key) end)
		button.key = element[1]
		button:SetPoint("TOPLEFT", 16, -48 - (index - 1) * 27)
		win.list[index] = button
	end

	-- Case d'exemple, agrandie, sur un fond
	stage = CreateFrame("Frame", nil, win)
	stage:SetSize(STAGE_W, STAGE_H)
	stage:SetPoint("TOPLEFT", 214, -48)
	stage.bg = UI.Paint(UI.Tex(stage, "BACKGROUND"), "panel")
	stage.bg:SetAllPoints()
	stage.border = UI.Paint(UI.Border(stage, 1), "line")
	stage:EnableMouse(true)
	stage:SetScript("OnMouseDown", StartDrag)
	stage:SetScript("OnMouseUp", StopDrag)
	stage:SetScript("OnHide", StopDrag)

	cell = CreateFrame("Frame", nil, stage)
	cell:SetPoint("CENTER")
	Z.BuildVisuals(cell)
	highlight = CreateFrame("Frame", nil, cell)
	highlight:SetFrameLevel(cell.over:GetFrameLevel() + 10)
	highlight.border = UI.Border(highlight, 1)
	highlight:Hide()
	win.cell, win.stage = cell, stage

	win.shape = UI.Label(win, 11, nil, "dim")
	win.shape:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -8)
	win.coords = UI.Label(win, 12, nil, "accent")
	win.coords:SetPoint("TOPRIGHT", stage, "BOTTOMRIGHT", 0, -8)

	-- Flèches : un pixel, cinq avec Maj
	win.left = Arrow("Gauche", -1, 0)
	win.left:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -30)
	win.up = Arrow("Haut", 0, 1)
	win.up:SetPoint("LEFT", win.left, "RIGHT", 6, 0)
	win.down = Arrow("Bas", 0, -1)
	win.down:SetPoint("LEFT", win.up, "RIGHT", 6, 0)
	win.right = Arrow("Droite", 1, 0)
	win.right:SetPoint("LEFT", win.down, "RIGHT", 6, 0)

	win.reset = UI.Button(win, L["Remettre à sa place"], 172, 22, function()
		Z.SetOffset(selected, 0, 0)
		Changed()
	end)
	win.reset:SetPoint("TOPLEFT", win.left, "BOTTOMLEFT", 0, -8)
	win.reset.label:SetJustifyH("CENTER")
	win.resetAll = UI.Button(win, L["Tout remettre"], 172, 22, function()
		Z.ResetPlacement()
		Changed()
	end)
	win.resetAll:SetPoint("LEFT", win.reset, "RIGHT", 8, 0)
	win.resetAll.label:SetJustifyH("CENTER")
	win.resetAll.tip = L["Tous les éléments de cette forme de case reviennent à leur place d'origine."]

	local note = UI.Label(win, 11, nil, "dim")
	note:SetPoint("TOPLEFT", 16, -374)
	note:SetPoint("RIGHT", -16, 0)
	note:SetJustifyH("LEFT")
	note:SetSpacing(3)
	note:SetText(L["Glissez un élément sur la case, ou choisissez-le dans la liste et poussez-le avec les flèches (Maj : 5 pixels). Chaque forme de case garde ses propres placements. Tous les éléments sont montrés ici, même ceux coupés dans les options."])

	win:HookScript("OnShow", Draw)
end

function Z:OpenPlacement()
	if not win then BuildWindow() end
	if win:IsShown() then return win:Close() end
	win:Show()
	Draw()
end

-- Appelé après chaque changement d'option : la case d'exemple suit la forme, le thème et les tailles
function Z:RefreshPlacement()
	if win and win:IsShown() and not drag then Draw() end
end

-- Pour les tests
function Z:PlacementWindow()
	return win
end
