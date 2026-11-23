-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Cooldowns.lua : « Mes recharges » (réglage « cooldownPanel », éteint au départ).
-- Une rangée d'icônes collée sous les cadres du groupe, sous le bandeau des buffs manquants quand il est là :
-- les sorts de mes raccourcis (clics, touches au survol, variantes) dont la recharge dépasse la recharge globale,
-- puis mes gros sorts de Data.lua (Z.cooldownSpells), s'ils sont connus. Rien d'écrit par classe ailleurs.
-- Le jeu dessine lui-même le balayage et les secondes (objet durée, en combat aussi) ; l'icône est grisée tant que
-- le sort recharge (isActive et isOnGCD, jamais secrets d'après le code du jeu ; secrets quand même : l'icône
-- reste nette, le balayage du jeu dit tout). Aucune boucle : SPELL_UPDATE_COOLDOWN, et la fin du balayage de
-- chaque icône. Ce ne sont pas des boutons du jeu : la rangée change et se replace en plein combat sans rien
-- bloquer. La liste se refait hors combat (raccourcis, grimoire, réglages) ; en combat, la dernière reste.

local _, Z = ...
local UI = Z.UI
local issecret = Z.IsSecret

local GCD_MS = 1500 -- recharge de base jusqu'à cette durée : seule la recharge globale compte, pas d'icône
local GAP = 2       -- écart entre deux icônes

local row, events
local icons = {}
local spells = {}       -- { { id, name, icon, keys = { "Maj + Clic gauche" } } }, dans l'ordre de la rangée
local rebuildLater = false
local hooked = false   -- les cadres du groupe sont suivis (Rebuild)

local function On()
	return Z.db and Z.db.cooldownPanel and Z.class ~= nil
end

----------------------------------------------------------------------------------------------------
-- La liste : mes raccourcis d'abord (dans l'ordre de l'onglet), puis mes gros sorts
----------------------------------------------------------------------------------------------------
-- Recharge de base d'un sort, en millisecondes, ou nil si le jeu ne la donne pas
local function BaseCooldown(id)
	if not GetSpellBaseCooldown then return end
	local ok, ms = pcall(GetSpellBaseCooldown, id)
	if ok and type(ms) == "number" and not issecret(ms) then return ms end
end

-- Ce qu'un raccourci lance, si c'est un sort : son nom ou son numéro (rang fixe) ; nil pour une macro, une action
local function SpellOfValue(value)
	if not Z.TakesTrinket(value) or Z.IsMacro(value) or Z.MacroRef(value) then return end
	return Z.SpellOf(value)
end

function Z.CooldownList()
	local list, seen = {}, {}
	local ignored = Z.db.cooldownIgnored or {}
	-- big : un gros sort de Data.lua, gardé si le jeu ne donne pas sa recharge ; un raccourci, seulement si elle
	-- dépasse la recharge globale
	local function Add(spell, key, big)
		local info = spell and C_Spell.GetSpellInfo(spell)
		local id, name = info and info.spellID, info and info.name
		if issecret(id) or issecret(name) or not id or not name or ignored[name] then return end
		local entry = seen[name]
		if not entry then
			if not Z.Knows(id) or Z.IsPassive(id) then return end
			local ms = BaseCooldown(id)
			if ms and ms <= GCD_MS then return end
			if not ms and not big then return end
			entry = { id = id, name = name, icon = Z.SpellIcon(id) or info.iconID, keys = {} }
			seen[name] = entry
			list[#list + 1] = entry
		end
		if key then entry.keys[#entry.keys + 1] = key end
	end
	for _, binding in ipairs(Z:Bindings()) do
		local label = Z:TriggerLabel(binding)
		Add(SpellOfValue(binding.value), label)
		for _, kind in ipairs(Z.variantKinds) do
			local value = binding.variants and binding.variants[kind[1]]
			if value then Add(SpellOfValue(value), label .. " (" .. Z.L[kind[2]] .. ")") end
		end
	end
	for _, id in ipairs(Z.cooldownSpells[Z.class] or {}) do Add(id, nil, true) end
	return list
end

----------------------------------------------------------------------------------------------------
-- État d'un sort
----------------------------------------------------------------------------------------------------
-- Le sort recharge-t-il (hors recharge globale) ? true, false, ou nil si le jeu le cache
function Z.SpellCooling(id)
	local info = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(id)
	if not info then return false end
	local active, gcd = info.isActive, info.isOnGCD
	if issecret(active) or issecret(gcd) then return nil end
	if active ~= nil then return active and not gcd end
	-- jeu sans isActive : début et durée, lisibles hors combat
	local start, length = info.startTime, info.duration
	if issecret(start) or issecret(length) then return nil end
	return (start or 0) > 0 and (length or 0) > GCD_MS / 1000
end

-- Secondes restantes d'une recharge, lisibles hors combat (infobulle « Mes clics »), sinon nil
function Z.SpellCooldownLeft(id)
	if Z.SpellCooling(id) ~= true then return end
	local info = C_Spell.GetSpellCooldown(id)
	if issecret(info.startTime) or issecret(info.duration) then return end
	local left = (info.startTime or 0) + (info.duration or 0) - GetTime()
	return left > 0 and left or nil
end

----------------------------------------------------------------------------------------------------
-- Les icônes
----------------------------------------------------------------------------------------------------
local Layout -- plus bas : une icône qui passe de « en recharge » à « prête » peut changer la rangée

local function IconEnter(self)
	local L = Z.L
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	if not pcall(GameTooltip.SetSpellByID, GameTooltip, self.spellId) then GameTooltip:SetText(self.spellName or "", 1, 1, 1) end
	if self.keys and #self.keys > 0 then
		GameTooltip:AddLine(L["Raccourci : %s"]:format(table.concat(self.keys, ", ")), UI.accent[1], UI.accent[2], UI.accent[3], true)
	end
	if self.cooling == true then
		GameTooltip:AddLine(L["En recharge"], 1, 0.4, 0.35)
	elseif self.cooling == false then
		GameTooltip:AddLine(L["Prêt"], 0.4, 1, 0.5)
	end
	if not InCombatLockdown() then
		GameTooltip:AddLine(L["Ne plus le montrer : chapitre Mes soins, « Recharges à ne pas montrer »."], 0.6, 0.6, 0.65, true)
	end
	GameTooltip:Show()
end

local function IconLeave()
	GameTooltip:Hide()
end

-- Dessine l'état d'une icône : balayage et secondes du jeu, grisée pendant la recharge
local function Draw(f)
	local id = f.spellId
	local duration = C_Spell.GetSpellCooldownDuration and C_Spell.GetSpellCooldownDuration(id, true)
	if duration and f.cd.SetCooldownFromDurationObject then
		f.cd:SetCooldownFromDurationObject(duration)
	else -- jeu sans objet durée : début et durée lisibles, sinon rien
		local info = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(id)
		local start, length = info and info.startTime, info and info.duration
		if info and not issecret(start) and not issecret(length) and Z.SpellCooling(id) then
			f.cd:SetCooldown(start, length)
		else
			f.cd:Clear()
		end
	end
	f.cooling = Z.SpellCooling(id)
	f.icon:SetDesaturated(f.cooling == true)
	f.icon:SetAlpha(f.cooling == true and 0.75 or 1)
end

local function Icon(index)
	if icons[index] then return icons[index] end
	local f = CreateFrame("Frame", nil, row)
	f.bg = UI.Tex(f, "BACKGROUND", 0, 0, 0, 0.6)
	f.bg:SetAllPoints()
	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
	f.cd:SetDrawEdge(false)
	f.cd:SetDrawBling(false)
	f.cd:SetHideCountdownNumbers(false) -- les secondes, écrites par le jeu (lisibles en combat)
	f.cd:SetSwipeColor(0, 0, 0, 0.6)
	-- la recharge finie : l'icône redevient nette (le jeu n'envoie pas toujours SPELL_UPDATE_COOLDOWN à ce moment)
	f.cd:SetScript("OnCooldownDone", function()
		Z:Try("mes recharges", function()
			if f.spellId then Draw(f) end
			if Z.db.cooldownShow == "COOLING" then Layout() end
		end)
	end)
	f.border = UI.Border(f, 1)
	f:EnableMouse(true)
	f:SetScript("OnEnter", IconEnter)
	f:SetScript("OnLeave", IconLeave)
	icons[index] = f
	return f
end

-- Côté d'une icône : la hauteur du bandeau des buffs manquants (deux lignes de texte), au moins 18
local function IconSize()
	local theme = Z:Theme()
	local size = Z.db.fontSize + (theme.fontBonus or 0)
	return math.max(18, 2 * size + 4 + 2 * UI.Inset(theme.borderSize, Z.db.corners == "ROUND"))
end

----------------------------------------------------------------------------------------------------
-- La rangée
----------------------------------------------------------------------------------------------------
local PlaceRow -- plus bas

-- Sous les cadres, ou collée au bandeau des buffs manquants quand il est du même côté
function Z.PlaceCooldowns()
	if row and row:IsShown() then PlaceRow() end
	if Z.PlaceGroupCooldowns then Z.PlaceGroupCooldowns() end -- les recharges du groupe suivent (GroupCooldowns.lua)
end

function PlaceRow()
	Z.PlaceUnderCells(row)
	local block = Z.BuffBlock and Z:BuffBlock()
	if block and block:IsShown() and block.where == row.where then
		local gap = Z.db.spacing
		row:ClearAllPoints()
		if row.where == "ABOVE" then
			row:SetPoint("BOTTOMLEFT", block, "TOPLEFT", 0, gap)
		else
			row:SetPoint("TOPLEFT", block, "BOTTOMLEFT", 0, -gap)
		end
	end
end

-- Range les icônes à montrer (toutes, ou seulement celles qui rechargent) et passe à la ligne au bord des cadres
function Layout()
	if not row then return end
	local shown = {}
	local onlyCooling = Z.db.cooldownShow == "COOLING"
	for i, f in ipairs(icons) do
		if i <= #spells and f.spellId and not (onlyCooling and f.cooling == false) then
			shown[#shown + 1] = f
		else
			f:Hide()
		end
	end
	if not On() or #shown == 0 then
		row:Hide()
		Z.PlaceCooldowns() -- les recharges du groupe prennent sa place
		return
	end
	row:SetScale(Z.db.scale / 100)
	local size = IconSize()
	local perRow = math.max(1, math.floor((Z.CellsWidth(row) + GAP) / (size + GAP)))
	local theme = Z:Theme()
	for i, f in ipairs(shown) do
		local col, line = (i - 1) % perRow, math.floor((i - 1) / perRow)
		f:SetSize(size, size)
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", col * (size + GAP), -line * (size + GAP))
		f.icon:ClearAllPoints()
		f.icon:SetPoint("TOPLEFT", 1, -1)
		f.icon:SetPoint("BOTTOMRIGHT", -1, 1)
		f.cd:ClearAllPoints()
		f.cd:SetAllPoints(f.icon)
		f.border:SetColor(theme.border[1], theme.border[2], theme.border[3], 1)
		f:Show()
	end
	local columns, lines = math.min(#shown, perRow), math.ceil(#shown / perRow)
	row:SetSize(columns * (size + GAP) - GAP, lines * (size + GAP) - GAP)
	row:Show()
	Z.PlaceCooldowns()
end
Z.LayoutCooldowns = Layout -- pour les tests

-- Toutes les icônes redessinées (un sort lancé, une recharge finie) ; la rangée suit si elle ne montre que les
-- recharges
local function DrawAll()
	if not row then return end
	local before = {}
	for i = 1, #spells do
		local f = icons[i]
		before[i] = f.cooling
		Draw(f)
	end
	if Z.db.cooldownShow == "COOLING" then
		for i = 1, #spells do
			if (icons[i].cooling == false) ~= (before[i] == false) then return Layout() end
		end
	end
end

-- La liste refaite (hors combat) et les icônes posées
local function Rebuild()
	if InCombatLockdown() then
		rebuildLater = true
		return
	end
	rebuildLater = false
	if not row then
		row = CreateFrame("Frame", "LyoruneCooldowns", UIParent)
		row:SetFrameStrata("MEDIUM")
		row:SetClampedToScreen(true)
		row:Hide()
	end
	-- les cadres du groupe changent de taille, apparaissent ou disparaissent : la rangée se replace, même en
	-- combat (ce n'est pas un bouton du jeu). Une fois, dès que les cadres existent.
	if not hooked and Z.headers and #Z.headers > 0 then
		hooked = true
		local function Moved() Z:Try("mes recharges", Layout) end
		for _, h in ipairs(Z.headers) do
			if h.def and h.def.pos == "pos" then
				h:HookScript("OnSizeChanged", Moved)
				h:HookScript("OnShow", Moved)
				h:HookScript("OnHide", Moved)
			end
		end
	end
	spells = On() and Z.CooldownList() or {}
	for i, entry in ipairs(spells) do
		local f = Icon(i)
		f.spellId, f.spellName, f.keys = entry.id, entry.name, entry.keys
		f.icon:SetTexture(entry.icon)
		Draw(f)
	end
	for i = #spells + 1, #icons do icons[i].spellId = nil end
	Layout()
end

local handlers = {
	SPELL_UPDATE_COOLDOWN = DrawAll,
	SPELL_UPDATE_CHARGES = DrawAll,
	SPELLS_CHANGED = Rebuild,
	PLAYER_ENTERING_WORLD = Rebuild,
	PLAYER_REGEN_ENABLED = function() if rebuildLater then Rebuild() end end,
}

-- Réglage, raccourcis ou liste changés : on n'écoute les recharges que si la rangée est voulue
function Z:RefreshCooldowns()
	if not On() then
		if events then events:UnregisterAllEvents() end
		if row then row:Hide() end
		Z.PlaceCooldowns()
		spells = {}
		return
	end
	if not events then
		events = CreateFrame("Frame")
		events:SetScript("OnEvent", function(_, event)
			Z:Try("mes recharges", handlers[event])
		end)
	end
	for event in pairs(handlers) do events:RegisterEvent(event) end
	Rebuild()
end

function Z:CooldownRow()
	return row, icons, spells
end

Z:On("PLAYER_LOGIN", function() Z:RefreshCooldowns() end)
