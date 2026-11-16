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
	button = CreateFrame("Button", "LyoruneMinimapButton", Minimap)
	button:SetSize(30, 30)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetTexture(ICON)
	button.icon:SetAllPoints()
	button:SetHighlightTexture(ICON, "ADD")
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
