-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Totems.lua : « Mes totems » (réglage « totemPanel », éteint au départ).
-- Une rangée d'une icône par emplacement de totem de ma classe (Data.lua, Z.totemSlots : Feu, Terre, Eau, Air
-- pour le chaman), collée sous « Mes recharges » (ou sous le bandeau des buffs manquants, ou sous les cadres).
-- Un totem posé : son image, le temps qui tourne et ses secondes, dessinés par le jeu (objet durée, en combat
-- aussi). Un emplacement vide : une case pâle, qui garde sa place. Rien de posé : la rangée disparaît.
-- En combat, GetTotemInfo cache si un totem est posé (valeur secrète) ; GetTotemDuration, lui, rend un objet durée
-- quand un totem est posé et rien sinon, jamais secret : c'est lui qui décide. Aucune boucle :
-- PLAYER_TOTEM_UPDATE seulement.
-- Ce ne sont pas des boutons du jeu : la rangée change et se replace en plein combat sans rien bloquer.

local _, Z = ...
local UI = Z.UI
local issecret = Z.IsSecret

local GAP = 2           -- écart entre deux icônes
local EMPTY_ALPHA = 0.3 -- emplacement vide

local row, events
local icons = {}
local hooked = false

local function Slots()
	return Z.class and Z.totemSlots[Z.class]
end

local function On()
	return Z.db and Z.db.totemPanel and Slots() ~= nil and GetTotemInfo ~= nil
end

----------------------------------------------------------------------------------------------------
-- Une icône
----------------------------------------------------------------------------------------------------
local function IconEnter(self)
	local L = Z.L
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	local shown = self.have and GameTooltip.SetTotem and pcall(GameTooltip.SetTotem, GameTooltip, self.slot)
	if not shown then GameTooltip:SetText(L["Mes totems"], 1, 1, 1) end
	GameTooltip:AddLine(L["Emplacement : %s"]:format(L[self.element]), UI.accent[1], UI.accent[2], UI.accent[3])
	if not self.have then GameTooltip:AddLine(L["Aucun totem posé"], 0.6, 0.6, 0.65) end
	GameTooltip:Show()
end

local function IconLeave()
	GameTooltip:Hide()
end

-- Un totem est-il posé ? Par GetTotemDuration (jamais secret) ; sans elle, GetTotemInfo, et un « oui » secret
-- compte comme posé (la case reste nette, le jeu dessine ce qu'il sait)
local function Present(slot, have)
	if GetTotemDuration then
		local timer = GetTotemDuration(slot)
		return timer ~= nil, timer
	end
	return issecret(have) or have == true
end

-- Dessine un emplacement. f.have : true ou false
local function Draw(f)
	local have, _, start, duration, icon = GetTotemInfo(f.slot)
	local timer
	f.have, timer = Present(f.slot, have)
	f.icon:SetTexture(icon) -- le jeu accepte une image secrète
	if timer and f.cd.SetCooldownFromDurationObject then
		f.cd:SetCooldownFromDurationObject(timer)
	elseif f.have and not issecret(start) and not issecret(duration) and (duration or 0) > 0 then
		f.cd:SetCooldown(start, duration)
	else
		f.cd:Clear()
	end
	f:SetAlpha(f.have and 1 or EMPTY_ALPHA)
end

local function Icon(index)
	if not icons[index] then icons[index] = Z.UnderRowIcon(row, IconEnter, IconLeave) end
	return icons[index]
end

----------------------------------------------------------------------------------------------------
-- La rangée
----------------------------------------------------------------------------------------------------
-- Sous « Mes recharges », sinon sous le bandeau des buffs manquants, sinon sous les cadres
function Z.PlaceTotems()
	if not (row and row:IsShown()) then return end
	Z.PlaceInStack(row, (Z:CooldownRow()), Z:BuffBlock())
end

-- Tous les emplacements redessinés ; la rangée se montre s'il y a un totem posé
local function Update()
	if not row then return end
	local slots = Slots()
	local any = false
	if On() then
		for index = 1, #slots do
			local f = icons[index]
			Draw(f)
			if f.have then any = true end
		end
	end
	if not any then
		if row:IsShown() then
			row:Hide()
			Z.PlaceCooldowns() -- les recharges du groupe prennent sa place
		end
		return
	end
	if not row:IsShown() then
		row:Show()
		Z.PlaceCooldowns()
	end
end

-- Taille et place des icônes (réglages, thème, échelle)
local function Layout()
	local slots = Slots()
	if not (row and slots) then return end
	row:SetScale(Z.db.scale / 100)
	local size = Z.UnderRowIconSize()
	local theme = Z:Theme()
	for index, element in ipairs(slots) do
		local f = Icon(index)
		f.slot, f.element = index, element
		f:SetSize(size, size)
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", (index - 1) * (size + GAP), 0)
		f.border:SetColor(theme.border[1], theme.border[2], theme.border[3], 1)
		f:Show()
	end
	row:SetSize(#slots * (size + GAP) - GAP, size)
	Z.PlaceTotems()
end

-- Réglage, classe ou thème changés : on n'écoute les totems que si la rangée est voulue
function Z:RefreshTotems()
	if not On() then
		if events then events:UnregisterAllEvents() end
		if row and row:IsShown() then
			row:Hide()
			Z.PlaceCooldowns()
		end
		return
	end
	if not row then
		row = CreateFrame("Frame", "LyoruneTotems", UIParent)
		row:SetFrameStrata("MEDIUM")
		row:SetClampedToScreen(true)
		row:Hide()
	end
	-- les cadres du groupe changent de taille, apparaissent ou disparaissent : la rangée se replace, même en
	-- combat. Une fois, dès que les cadres existent.
	if not hooked and Z.headers and #Z.headers > 0 then
		hooked = true
		Z.FollowCells(function() Z:Try("mes totems", Z.PlaceTotems) end)
	end
	if not events then
		events = CreateFrame("Frame")
		events:SetScript("OnEvent", function() Z:Try("mes totems", Update) end)
	end
	events:RegisterEvent("PLAYER_TOTEM_UPDATE")
	events:RegisterEvent("PLAYER_ENTERING_WORLD")
	Layout()
	Update()
end

function Z:TotemRow()
	return row, icons
end

Z:On("PLAYER_LOGIN", function() Z:RefreshTotems() end)
