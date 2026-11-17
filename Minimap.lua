-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Minimap.lua : le bouton au bord de la mini-carte. Facultatif (réglage « minimapButton »).
-- Clic gauche : options. Clic droit : mode test. Glisser : le déplacer autour de la mini-carte.
-- Un simple bouton natif, sans bibliothèque, créé seulement quand le réglage est actif.

local _, Z = ...
local ICON = "Interface\\AddOns\\Lyorune\\Media\\Minimap"
local button

local function Place()
	local angle = math.rad(Z.db.minimapAngle)
	local radius = Minimap:GetWidth() / 2 + 6
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

-- Appelée à chaque image, mais seulement pendant que le joueur fait glisser le bouton
local function Follow()
	local x, y = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	local centerX, centerY = Minimap:GetCenter()
	Z.db.minimapAngle = math.floor(math.deg(math.atan2(y / scale - centerY, x / scale - centerX)) + 0.5) % 360
	Place()
end

local function Create()
	local L = Z.L
	-- Même gabarit que les autres boutons de la mini-carte : fond sombre, icône ronde de 18 pixels et anneau
	-- doré du jeu. Le médaillon du logo est recadré pour que son propre anneau ne double pas celui du jeu.
	button = CreateFrame("Button", "LyoruneMinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button.background = button:CreateTexture(nil, "BACKGROUND")
	button.background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	button.background:SetSize(24, 24)
	button.background:SetPoint("CENTER")
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetTexture(ICON)
	button.icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)
	button.icon:SetSize(18, 18)
	button.icon:SetPoint("CENTER")
	button.border = button:CreateTexture(nil, "OVERLAY")
	button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	button.border:SetSize(50, 50)
	button.border:SetPoint("TOPLEFT")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", Follow) end)
	button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	button:SetScript("OnClick", function(_, mouseButton)
		if not Z.header then return end -- Lyorune n'a pas pu démarrer
		if mouseButton == "RightButton" then Z:TogglePreview() else Z:ToggleOptions() end
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Lyorune", 0.93, 0.75, 0.35)
		GameTooltip:AddLine(L["Clic gauche : ouvrir les options"], 1, 1, 1)
		GameTooltip:AddLine(L["Clic droit : mode test"], 1, 1, 1)
		GameTooltip:AddLine(L["Glisser : déplacer ce bouton"], 0.6, 0.64, 0.7)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Affiche ou retire le bouton selon le réglage. Sans mini-carte (client inattendu), ne fait rien.
function Z:RefreshMinimap()
	if not Minimap then return end
	if Z.db.minimapButton and not button then Create() end
	if not button then return end
	button:SetShown(Z.db.minimapButton)
	if Z.db.minimapButton then Place() end
end

Z:On("PLAYER_LOGIN", function() Z:RefreshMinimap() end)
