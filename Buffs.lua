-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Buffs.lua : buffs manquants, hors combat seulement : collés sous les cadres, à la forme des cases
-- (départ), ou dans une petite fenêtre posée où l'on veut (réglage « buffPlace »).
-- Une ligne par buff qui manque à un joueur (tous ses buffs manquants, pas seulement le premier) : un clic le
-- lui lance, sans le cibler. Seuls comptent les buffs de ma liste pour ce lieu (« Mes buffs », JcE ou JcJ).
-- Un buff unique (Bouclier de terre...) a sa ligne pour le tank, ou pour le joueur choisi, s'il n'est sur personne.
-- Quand je connais la version de groupe du buff et que N joueurs d'un même groupe en manquent (réglage
-- « buffGroupAt »), une seule ligne « Groupe N » lance la version de groupe : moins de clics, moins de mana.
-- Le panneau se cache à l'entrée en combat (avant que le jeu ne verrouille ses boutons) et revient après.
-- Un joueur hors de portée passe en fin de liste. Il lit ce que les cases ont déjà trouvé (b.missingBuff, Auras.lua) : aucune lecture d'aura en plus.

local _, Z = ...
local UI = Z.UI
local issecret = Z.IsSecret

local MAX_ROWS = 10    -- au-delà, une ligne « et N autres »
local ROW_H = 22
local WIDTH = 230

local panel, more
local rows = {}
local queued = false
local closed = false   -- fermé par la croix : revient à la fin du prochain combat
local cooldownAt       -- fin de recharge d'un buff unique déjà attendue (UniqueRows)

-- Buff que je viens de lancer : ce joueur n'est plus proposé pour ce buff pendant quelques secondes, le temps que
-- le jeu pose l'aura et que sa case la relise (sinon la touche, pressée de nouveau, le relancerait sur lui). Le
-- clic note le joueur et le sort ; seul le sort réussi (UNIT_SPELLCAST_SUCCEEDED) l'écarte : un sort raté, hors
-- de portée ou interrompu n'écarte personne. Idée vue chez PallyPower, faite à notre façon.
local RECENT = 4
local recent = {} -- recent["unité|sort"] = fin de la mise de côté
local tried       -- le dernier clic : { unit, spell, at }

local function Recent(unit, spell)
	local untilAt = unit and spell and recent[unit .. "|" .. spell]
	return untilAt ~= nil and untilAt > GetTime()
end

-- Après un clic sur un bouton de buff (case du bloc, ligne de la fenêtre, touche) : le joueur et le sort visés
local function NoteTry(button, mouse)
	if button.sample then return end
	local unit = button:GetAttribute("unit")
	local spell = button:GetAttribute("spell")
		or (mouse == "RightButton" and button:GetAttribute("spell2") or button:GetAttribute("spell1"))
	tried = unit and spell and { unit = unit, spell = spell, at = GetTime() } or nil
end

local castWatch = CreateFrame("Frame")
castWatch:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
castWatch:SetScript("OnEvent", function(_, _, _, _, spellID)
	if not tried or GetTime() - tried.at > 3 or not spellID or issecret(spellID) then return end
	local name = C_Spell.GetSpellName(spellID)
	if not name or issecret(name) or name ~= tried.spell then return end
	recent[tried.unit .. "|" .. tried.spell] = GetTime() + RECENT
	tried = nil
	Z:QueueBuffPanel()
	C_Timer.After(RECENT + 0.1, function() Z:QueueBuffPanel() end) -- l'aura n'est pas venue : de nouveau proposé
end)

-- Raccourci « Poser le prochain buff manquant » (Bindings.xml : CLICK LyoruneNextBuff:LeftButton). Un bouton
-- sécurisé caché, créé au chargement (hors combat), qui lance la première ligne du panneau. Il est vidé dès que
-- le panneau n'a plus rien à proposer et à l'entrée en combat : une touche ne lance jamais un ancien buff.
-- Il suit le panneau même fermé par la croix (le joueur n'a pas besoin de le voir pour appuyer).
local nextBuff = CreateFrame("Button", "LyoruneNextBuff", UIParent, "SecureActionButtonTemplate")
nextBuff:Hide()

local function SetNextBuff(entry)
	if InCombatLockdown() then return end
	-- une touche part selon « useOnKeyDown », posé au même sens que les clics (comme les cases, C11)
	local castOnDown = Z.db and Z.db.castOnDown
	nextBuff:RegisterForClicks(castOnDown and "AnyDown" or "AnyUp")
	nextBuff:SetAttribute("useOnKeyDown", castOnDown and true or false)
	nextBuff:SetAttribute("unit", entry and entry.unit)
	nextBuff:SetAttribute("type", entry and "spell")
	nextBuff:SetAttribute("spell", entry and entry.spell)
	nextBuff:SetAttribute("macrotext", nil)
	nextBuff.entry, nextBuff.combat = entry, nil
end

-- En combat (choix de l'auteur, 22 novembre 2026), la même touche relance mon premier buff unique suivi sur son
-- porteur (Z.UniqueBearer). Préparée juste avant le verrouillage des boutons, par le nom du porteur (macro
-- « /cast [@Nom] Sort ») : si le raid se réorganise en plein combat, le sort ne part jamais sur un autre joueur.
-- Réglage « combatKey » ; sans buff unique ni porteur, la touche est vidée comme avant.
local function CombatKey()
	if InCombatLockdown() then return end
	SetNextBuff(nil)
	if not (Z.db.combatKey and Z.db.buffPanel) then return end
	for _, check in ipairs(Z.uniqueChecks or {}) do
		if Z.BuffWatched(check) then
			local _, name = Z.UniqueBearer(check)
			if name then
				nextBuff:SetAttribute("type", "macro")
				nextBuff:SetAttribute("macrotext", "/cast [@" .. name .. "] " .. check.spell)
				nextBuff.combat = { name = name, spell = check.spell }
				return
			end
		end
	end
end
Z.CombatBuffKey = CombatKey -- pour les tests et /lyorune buffs

-- Après l'appui : un mot quand rien n'est parti (combat, ou aucun buff à poser), pour que la touche ne semble
-- pas cassée
nextBuff:SetScript("PostClick", function(self, mouse)
	NoteTry(self, mouse)
	if InCombatLockdown() then
		if not self.combat then Z:Print(Z.L["le prochain buff manquant se pose hors combat seulement."]) end
	elseif not self.entry then
		Z:Print(Z.L["aucun buff manquant à poser."])
	end
end)

-- Joueur hors de vue ou hors de portée de ce sort, lisible hors combat. Sur Forever, UnitInRange reste secret même hors combat :
-- la portée du sort lui-même d'abord (C_Spell.IsSpellInRange, souvent 30 m), puis UnitInRange s'il répond.
-- Une valeur secrète ou inconnue compte comme « à portée » (rien n'est écarté à tort).
local function Away(unit, spell)
	if not unit then return false end
	local me = UnitIsUnit(unit, "player")
	if not issecret(me) and me then return false end
	-- hors de vue (une centaine de mètres) : le jeu ne peut pas le cibler, le sort partirait sur moi
	local visible = UnitIsVisible and UnitIsVisible(unit)
	if visible == false then return true end
	if spell and C_Spell.IsSpellInRange then
		local ok, inRange = pcall(C_Spell.IsSpellInRange, spell, unit)
		if ok and not issecret(inRange) and inRange == false then return true end
	end
	local inRange, checked = UnitInRange(unit)
	return not issecret(inRange) and not issecret(checked) and checked and not inRange or false
end

-- Un autre joueur déjà en combat : le jeu cache alors ses buffs aux addons, ils sembleraient tous manquer (au
-- début d'un combat, le tank y entre un instant avant moi). Il est laissé de côté jusqu'à la relecture.
local function Fighting(unit)
	local me = UnitIsUnit(unit, "player")
	if not issecret(me) and me then return false end
	local fighting = UnitAffectingCombat and UnitAffectingCombat(unit)
	return not issecret(fighting) and fighting or false
end

-- Groupe de raid d'une unité (1 en groupe de 5 ; 0 pour un familier, toujours sur sa propre ligne)
local function SubGroup(unit)
	local index = unit:match("^raid(%d+)$")
	if index and GetRaidRosterInfo then
		local group = select(3, GetRaidRosterInfo(tonumber(index)))
		return tonumber(group) or 1
	end
	if unit:find("pet", 1, true) then return 0 end
	return 1
end

-- Pour la mémoire des buffs (BuffMemory.lua) : groupe, portée, et le joueur du dernier clic sur ce buff
Z.BuffSubGroup = SubGroup
Z.BuffAway = Away
function Z.LastBuffTry(spell)
	if tried and tried.spell == spell and GetTime() - tried.at <= 3 then return tried.unit end
end

-- Buffs qui manquent aux joueurs, lus sur les cases visibles (chaque joueur une seule fois) : une entrée par
-- joueur et par buff
local function Missing()
	local list, seen = {}, {}
	for _, b in ipairs(Z.buttons) do
		local unit = b.unit
		if unit and b.missingBuff and not b.extra and not seen[unit] and b:IsVisible() and not Fighting(unit) then
			local name = UnitName(unit)
			if name and not issecret(name) then
				seen[unit] = true
				local group, class = SubGroup(unit), select(2, UnitClass(unit))
				for _, missing in ipairs(b.missingBuffs or { b.missingBuff }) do
					list[#list + 1] = { unit = unit, check = missing.check, spell = missing.spell, icon = missing.icon,
						name = name, group = group, class = class }
				end
			end
		end
	end
	-- moi, case cachée (seul) : ma fiche (Auras.lua, Z.hiddenSelf)
	local me = Z.hiddenSelf
	local myName = me and me.missingBuffs and UnitName("player")
	if myName and not issecret(myName) then
		for _, missing in ipairs(me.missingBuffs) do
			list[#list + 1] = { unit = "player", check = missing.check, spell = missing.spell, icon = missing.icon,
				name = myName, group = 1, class = select(2, UnitClass("player")) }
		end
	end
	table.sort(list, function(a, b)
		if a.group ~= b.group then return a.group < b.group end
		return a.name < b.name
	end)
	return list
end

-- Sort en recharge (hors temps de recharge global) : secondes restantes, sinon nil. Lisible hors combat.
local function CooldownLeft(name)
	local info = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(name)
	if not info or issecret(info.startTime) or issecret(info.duration) or issecret(info.isOnGCD) then return end
	if info.isOnGCD or not info.startTime or info.startTime == 0 or (info.duration or 0) <= 1.5 then return end
	local left = info.startTime + info.duration - GetTime()
	return left > 0 and left or nil
end

-- Une ligne de buff unique pour son porteur, si elle est à proposer
local function UniqueRow(result, check, placed, target, why)
	local wanted = not placed[check.name] and Z.BuffWatched(check)
	local wait = wanted and CooldownLeft(check.spell)
	if wait then
		-- un seul rendez-vous à la fois : le panneau se relit souvent hors combat
		local at = GetTime() + wait
		if not (cooldownAt and cooldownAt > GetTime() and cooldownAt <= at) then
			cooldownAt = at
			C_Timer.After(wait + 0.2, function() Z:QueueBuffPanel() end)
		end
	elseif wanted then
		result[#result + 1] = { check = check, spell = check.spell, icon = check.icon, unit = target.unit,
			name = target.name, class = select(2, UnitClass(target.unit)), why = why }
	end
end

-- Sur qui poser un buff unique : « TANK » (départ), « ME » (moi) ou « NAME » (un joueur choisi, name). Choix par
-- buff dans « Mes buffs » (Z.char.buffTarget.byId), sinon le joueur de /lyorune porteur (buffTarget.name), sinon
-- le tank. Gardé pour ce personnage.
function Z.BuffBearer(id)
	local target = Z.char.buffTarget
	local chosen = target.byId and target.byId[id]
	if chosen then return chosen.mode, chosen.name end
	if target.name then return "NAME", target.name end
	return "TANK"
end

function Z.SetBuffBearer(id, mode, name)
	local target = Z.char.buffTarget
	target.byId = target.byId or {}
	target.byId[id] = { mode = mode, name = mode == "NAME" and name or nil }
	Z:QueueBuffPanel()
end

-- Le porteur de ce buff unique, sur les cases du groupe, hors combat : son unité et son nom, ou nil. Même choix
-- que le panneau (joueur choisi, moi, sinon le tank, sinon moi), mais qu'il soit en combat ou que mon buff soit
-- déjà posé : sert aux repères dessinés par le jeu (Containers.lua) et au raccourci en combat (CombatKey).
function Z.UniqueBearer(check)
	local mode, chosen = Z.BuffBearer(check.id)
	local found, tank, me
	for _, b in ipairs(Z.buttons or {}) do
		local unit = b.unit
		if unit and not b.extra and not unit:find("pet", 1, true) and not b.status then
			local name = Z.UnitPinName(unit)
			if name then
				local isMe = UnitIsUnit(unit, "player")
				if issecret(isMe) then isMe = false end
				local role = UnitGroupRolesAssigned(unit)
				if mode == "NAME" and name == chosen then found = found or unit end
				if isMe then me = me or unit end
				if not issecret(role) and role == "TANK" then tank = tank or unit end
			end
		end
	end
	if mode == "ME" then found = me end
	local unit = found or tank or me or (Z.SelfHidden() and "player") or nil
	if unit then return unit, Z.UnitPinName(unit) end
end

-- Buffs uniques (Bouclier de terre...) : une ligne par buff pour son porteur (Z.BuffBearer) : le joueur choisi,
-- moi, ou le tank ; joueur choisi absent (ou mort, ou déconnecté) : le tank ; pas de tank : moi. Seulement tant que le mien n'est posé sur
-- personne, s'il est dans ma liste et s'il n'est pas en recharge (le panneau se relit à la fin de la recharge).
-- Lu sur les cases visibles (b.myUniques, Auras.lua).
local function UniqueRows(result)
	if #Z.uniqueChecks == 0 then return end
	local placed, members, tank, me = {}, {}, nil, nil
	for _, b in ipairs(Z.buttons) do
		local unit = b.unit
		if unit and not b.extra and b:IsVisible() and not unit:find("pet", 1, true) then
			for name in (b.myUniques or ""):gmatch("[^,]+") do placed[name] = true end
			local name = Z.UnitPinName(unit)
			-- mort, fantôme ou déconnecté : ne peut pas recevoir le buff ; en combat : ses buffs sont cachés
			if name and not b.status and not Fighting(unit) then
				local player = { unit = unit, name = name }
				members[name] = members[name] or player
				local role = UnitGroupRolesAssigned(unit)
				if not issecret(role) and role == "TANK" then tank = tank or player end
				local isMe = UnitIsUnit(unit, "player")
				if not issecret(isMe) and isMe then me = me or player end
			end
		end
	end
	-- moi, case cachée (seul) : ma fiche (Auras.lua, Z.hiddenSelf)
	local hidden = Z.hiddenSelf
	if hidden and (hidden.missingKey or hidden.myUniques or hidden.status == nil) and Z.SelfHidden() then
		for name in (hidden.myUniques or ""):gmatch("[^,]+") do placed[name] = true end
		local name = Z.UnitPinName("player")
		if name and not hidden.status and not me then
			me = { unit = "player", name = name }
			members[name] = members[name] or me
		end
	end
	for _, check in ipairs(Z.uniqueChecks) do
		local mode, name = Z.BuffBearer(check.id)
		local target, why
		if mode == "NAME" and members[name] then target, why = members[name], Z.L["choisi"]
		elseif mode == "ME" and me then target, why = me, Z.L["vous"] end
		if not target and tank then target, why = tank, Z.L["tank"] end
		if not target and me then target, why = me, Z.L["vous"] end
		if target then UniqueRow(result, check, placed, target, why) end
	end
end

-- Lignes du panneau : un buff après l'autre (ordre de Data.lua), un joueur ou un groupe entier par ligne
function Z.BuffRows()
	local missing, result = Missing(), {}
	for _, check in ipairs(Z.buffChecks) do
		local byGroup, order = {}, {}
		for _, entry in ipairs(missing) do
			if entry.check == check then
				if not byGroup[entry.group] then
					byGroup[entry.group] = {}
					order[#order + 1] = entry.group
				end
				table.insert(byGroup[entry.group], entry)
			end
		end
		-- « Mes buffs » : version de groupe décochée = la version simple seulement ; version simple décochée = la
		-- version de groupe seulement, dès un joueur du groupe sans le buff (un familier seul, groupe 0 : rien).
		-- Sans le composant de la version de groupe : la version simple, comme si elle était seule cochée.
		local groupSpell = Z.GroupSpell(check)
		local simple = Z.BuffWatched(check) or not groupSpell
		local groupAt = simple and Z.db.buffGroupAt or 1
		for _, group in ipairs(order) do
			local players = byGroup[group]
			if groupSpell and group > 0 and #players >= groupAt then
				result[#result + 1] = { check = check, spell = groupSpell, icon = check.icon, unit = players[1].unit,
					group = group, count = #players, players = players }
			elseif simple then
				for _, entry in ipairs(players) do
					result[#result + 1] = { check = check, spell = entry.spell, spell2 = groupSpell, icon = entry.icon,
						unit = entry.unit, name = entry.name, class = entry.class }
				end
			end
		end
	end
	UniqueRows(result)
	-- hors de portée : en fin de liste (lisible hors combat), l'ordre reste le même dans chaque partie
	local near, far = {}, {}
	for _, entry in ipairs(result) do
		if Recent(entry.unit, entry.spell) then -- je viens de le lui lancer : l'aura arrive
		elseif Away(entry.unit, entry.spell) then far[#far + 1] = entry else near[#near + 1] = entry end
	end
	for _, entry in ipairs(far) do near[#near + 1] = entry end
	return near
end

-- Portée : une ligne hors de portée est estompée, comme sa case (le jeu ne dit rien en combat, le panneau
-- n'existe pas en combat)
local tiles = {} -- cases du bloc collé aux cadres

local function UpdateRange()
	for _, list in ipairs({ rows, tiles }) do for _, row in ipairs(list) do
		if row:IsShown() and row.unitToken then
			row:SetAlpha(Away(row.unitToken, row.spellName) and 0.4 or 1)
		end
	end end
end

local function RowEnter(self)
	self.hover:Show()
	local L = Z.L
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if self.sample then
		GameTooltip:SetText(L["Exemple"], 1, 1, 1)
		GameTooltip:AddLine(L["Hors combat, vos buffs manquants s'afficheront ici, à la forme de vos cases : un clic les pose."], 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
		return
	end
	GameTooltip:SetText(self.tip or self.label:GetText() or "", 1, 1, 1)
	GameTooltip:AddLine(L["Clic : %s"]:format(self.spellName or ""), UI.accent[1], UI.accent[2], UI.accent[3])
	if self.why then
		GameTooltip:AddLine(Z.L["Un autre joueur : /lyorune porteur en survolant sa case."], 0.8, 0.8, 0.8, true)
	end
	if self.spell2Name then
		GameTooltip:AddLine(L["Clic droit : %s (tout son groupe)"]:format(self.spell2Name), 0.8, 0.8, 0.8)
	end
	if Z.AurasHidden() then -- champ de bataille, arène, clé mythique : le jeu cache les buffs (BuffMemory.lua)
		GameTooltip:AddLine(L["Buffs cachés par le jeu ici : Lyorune retient vos propres buffs, pas ceux des autres joueurs."], 1, 0.82, 0.3, true)
	end
	GameTooltip:Show()
end

local function RowLeave(self)
	self.hover:Hide()
	GameTooltip:Hide()
end

-- Une ligne : bouton sécurisé du jeu (il lance le sort sur l'unité), créé hors combat
local function Row(index)
	if rows[index] then return rows[index] end
	local row = CreateFrame("Button", "LyoruneBuffsRow" .. index, panel, "SecureActionButtonTemplate")
	row:SetSize(WIDTH - 28, ROW_H)
	row:SetPoint("TOPLEFT", 14, -42 - (index - 1) * (ROW_H + 2))
	row.bg = UI.Paint(UI.Tex(row, "BACKGROUND"), "panel")
	row.bg:SetAllPoints()
	row.hover = UI.Paint(UI.Tex(row, "BORDER"), "accent", 0.18)
	row.hover:SetAllPoints()
	row.hover:Hide()
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ROW_H - 4, ROW_H - 4)
	row.icon:SetPoint("LEFT", 2, 0)
	row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	row.label = UI.Text(row, 12)
	row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	row.label:SetPoint("RIGHT", -4, 0)
	row.label:SetJustifyH("LEFT")
	row.label:SetWordWrap(false)
	row:SetScript("OnEnter", RowEnter)
	row:SetScript("OnLeave", RowLeave)
	row:SetScript("PostClick", NoteTry)
	rows[index] = row
	return row
end

local function SavePosition(self)
	self:StopMovingOrSizing()
	local point, _, relative, x, y = self:GetPoint()
	Z.char.buffPos = { point, math.floor(x + 0.5), math.floor(y + 0.5), relative }
end

local function Build()
	panel = UI.Window("LyoruneBuffs", Z.L["Buffs manquants"], WIDTH, 80)
	panel:SetFrameStrata("MEDIUM")
	panel:SetScript("OnDragStop", SavePosition)
	panel.close:SetScript("OnClick", function()
		closed = true
		panel:Close()
	end)
	more = UI.Label(panel, 11, nil, "dim")
	more:SetJustifyH("LEFT")
	local elapsed = 0
	panel:SetScript("OnUpdate", function(_, delta) -- portée seulement, et seulement panneau ouvert
		elapsed = elapsed + delta
		if elapsed >= 0.5 then
			elapsed = 0
			UpdateRange()
		end
	end)
	local pos = Z.char.buffPos
	panel:ClearAllPoints()
	panel:SetPoint(pos[1], UIParent, pos[4] or pos[1], pos[2], pos[3])
end

-- Texte d'une entrée : « Groupe N (nombre) », « Nom (tank) » ou le nom ; et sa couleur
local function EntryText(entry)
	local L = Z.L
	if entry.count then
		return L["Groupe %d"]:format(entry.group) .. "  |cffb3b3b3(" .. entry.count .. ")|r", unpack(UI.accent)
	elseif entry.why then
		return entry.name .. "  |cffb3b3b3(" .. entry.why .. ")|r", Z.ClassColor(entry.class)
	end
	return entry.name, Z.ClassColor(entry.class)
end

-- Réglages communs d'un bouton du jeu qui lance le buff d'une entrée (ligne de la fenêtre ou case du bloc)
local function Arm(button, entry)
	button:RegisterForClicks(Z.db.castOnDown and "AnyDown" or "AnyUp")
	button.sample = entry.sample
	button:SetAttribute("unit", not entry.sample and entry.unit or nil) -- l'exemple ne lance rien
	button:SetAttribute("type1", not entry.sample and "spell" or nil)
	button:SetAttribute("spell1", not entry.sample and entry.spell or nil)
	button:SetAttribute("type2", not entry.sample and entry.spell2 and "spell" or nil)
	button:SetAttribute("spell2", not entry.sample and entry.spell2 or nil)
	button.unitToken, button.spellName, button.spell2Name, button.why = entry.unit, entry.spell, entry.spell2, entry.why
end

----------------------------------------------------------------------------------------------------
-- Bloc collé aux cadres (« Emplacement : avec les cadres », le départ). Sous la case la plus basse des cadres
-- du groupe, aligné sur la première colonne, à l'échelle et à l'écart des cases ; au-dessus quand la place
-- manque en bas de l'écran. Il prend la forme des cases (Z.shapes[...].buffs, Themes.lua), leur taille, leur
-- thème, leur texture et leurs angles. Une seule case (demande de l'auteur, 22 novembre 2026, idée vue chez
-- HealKit) : le prochain buff, celui que lance aussi la touche « prochain buff » ; après chaque sort, la case
-- passe au suivant. Dans son coin, « + N » dit combien il en reste après lui. Replacé seulement quand les cadres changent (groupe, taille,
-- déplacement, réglages) : aucune boucle, sauf la portée deux fois par seconde quand il est visible.
----------------------------------------------------------------------------------------------------
local LABEL_GAP = 14 -- place de l'étiquette « Groupe » au-dessus des cases (LABEL_SPACE, Frames.lua)
local PANEL_OUTSET = 3 -- débord du fond de groupe autour des cases (Frames.lua)
local block, blockMore

-- Nom court d'un sort : « Mot de pouvoir : Robustesse » devient « Robustesse »
local function ShortSpell(name)
	return name and (name:match(".* : (.+)$") or name) or ""
end

local function Tile(index)
	if tiles[index] then return tiles[index] end
	local tile = CreateFrame("Button", "LyoruneBuffsTile" .. index, block, "SecureActionButtonTemplate")
	tile.bg = UI.Tex(tile, "BACKGROUND")
	tile.bg:SetAllPoints()
	tile.bgRound = UI.RoundTex(tile, "BACKGROUND")
	tile.bgRound:SetAllPoints()
	tile.fill = tile:CreateTexture(nil, "BORDER")
	tile.hover = UI.Tex(tile, "ARTWORK", 1, 1, 1, 0.12)
	tile.hover:Hide()
	tile.icon = tile:CreateTexture(nil, "OVERLAY")
	tile.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	tile.label = UI.Text(tile, 11)
	tile.label:SetWordWrap(false)
	tile.sub = UI.Text(tile, 11)
	tile.sub:SetWordWrap(false)
	tile.border = UI.Border(tile, 1)
	tile:SetScript("OnEnter", RowEnter)
	tile:SetScript("OnLeave", RowLeave)
	tile:SetScript("PostClick", NoteTry)
	tiles[index] = tile
	return tile
end

-- Icône d'une case du bloc : la moitié de la place qu'elle aurait (demande de l'auteur, 22 novembre 2026 : « bien
-- trop grosse »), jamais sous ICON_MIN pour rester lisible sur les cases basses (Barre, Bandeau)
local ICON_MIN = 14

-- Habille une case du bloc comme une case des cadres, puis range son icône et ses textes selon « style » :
-- "LINE", "TWO" ou "ICON" (Z.shapes)
local function StyleTile(tile, w, h, style, entry)
	local db, theme = Z.db, Z:Theme()
	local rounded = db.corners == "ROUND"
	local inset = UI.Inset(theme.borderSize, rounded)
	tile:SetSize(w, h)
	tile.bg:SetVertexColor(unpack(theme.bg))
	tile.bgRound:SetVertexColor(unpack(theme.bg))
	tile.bg:SetShown(not rounded)
	tile.bgRound:SetShown(rounded)
	tile.border:SetThickness(theme.borderSize)
	tile.border:SetColor(theme.border[1], theme.border[2], theme.border[3], 1)
	tile.border:SetRounded(rounded)
	for _, region in ipairs({ tile.fill, tile.hover }) do
		region:ClearAllPoints()
		region:SetPoint("TOPLEFT", inset, -inset)
		region:SetPoint("BOTTOMRIGHT", -inset, inset)
	end
	local text, r, g, b = EntryText(entry)
	tile.fill:SetTexture(UI.BarTexture())
	tile.fill:SetVertexColor(r, g, b, 0.35) -- la couleur de la classe en fond léger : le texte reste lisible
	tile.icon:SetTexture(entry.icon or entry.check.icon)
	tile.tip = text
	local size = db.fontSize + (theme.fontBonus or 0)
	tile.label:SetFont(theme.font, size, theme.flags)
	tile.sub:SetFont(theme.font, size - 1, theme.flags)
	tile.icon:ClearAllPoints()
	tile.label:ClearAllPoints()
	tile.sub:ClearAllPoints()
	tile.label:Show()
	tile.sub:Hide()
	if style == "ICON" then -- icône, le nom dessous
		local icon = math.max(ICON_MIN, math.floor(math.min(w, h) * 0.55 / 2))
		tile.icon:SetSize(icon, icon)
		tile.icon:SetPoint("TOP", 0, -inset - 3)
		tile.label:SetPoint("BOTTOMLEFT", inset + 1, inset + 2)
		tile.label:SetPoint("BOTTOMRIGHT", -inset - 1, inset + 2)
		tile.label:SetJustifyH("CENTER")
		tile.label:SetText(entry.count and Z.L["Groupe %d"]:format(entry.group) or entry.name)
		tile.label:SetTextColor(r, g, b)
	else
		local icon = math.max(ICON_MIN, math.floor((h - 2 * inset - 4) / 2))
		tile.icon:SetSize(icon, icon)
		tile.icon:SetPoint("LEFT", inset + 2, 0)
		tile.label:SetJustifyH("LEFT")
		tile.sub:SetJustifyH("LEFT")
		if style == "TWO" then -- le sort, puis le joueur
			tile.label:SetPoint("BOTTOMLEFT", tile.icon, "RIGHT", 4, 1)
			tile.label:SetPoint("RIGHT", -inset - 3, 0)
			tile.label:SetText(ShortSpell(entry.spell))
			tile.label:SetTextColor(unpack(UI.accent))
			tile.sub:SetPoint("TOPLEFT", tile.icon, "RIGHT", 4, -1)
			tile.sub:SetPoint("RIGHT", -inset - 3, 0)
			tile.sub:SetText(text)
			tile.sub:SetTextColor(r, g, b)
			tile.sub:Show()
		else -- une ligne : le joueur, puis le sort en gris
			tile.label:SetPoint("LEFT", tile.icon, "RIGHT", 4, 0)
			tile.label:SetPoint("RIGHT", -inset - 3, 0)
			tile.label:SetText(text .. "  |cff9a9a9a" .. ShortSpell(entry.spell) .. "|r")
			tile.label:SetTextColor(r, g, b)
		end
	end
end

-- Bord des cases des cadres du groupe (pas les tanks, familiers, épinglés ni la cible), en pixels de l'écran
local function MainCells()
	local left, bottom, top, scale
	for _, b in ipairs(Z.buttons) do
		local header = b:GetParent()
		if b.unit and not b.extra and b:IsVisible() and header and header.def and header.def.pos == "pos" then
			local l, bt, t = b:GetLeft(), b:GetBottom(), b:GetTop()
			if l and bt and t then
				local s = b:GetEffectiveScale()
				l, bt, t = l * s, bt * s, t * s
				left = left and math.min(left, l) or l
				bottom = bottom and math.min(bottom, bt) or bt
				top = top and math.max(top, t) or t
				scale = s
			end
		end
	end
	return left, bottom, top, scale
end

-- Place le bloc : sous les cadres, au-dessus si la place manque, sous leur point de départ s'ils sont cachés.
-- block.where : « BELOW », « ABOVE » ou « ANCHOR ».
local function PlaceBlock()
	local db = Z.db
	local gap = db.spacing + (db.groupPanel and 2 * PANEL_OUTSET or 0) -- le bloc ne touche pas un fond de groupe
	local left, bottom, top, scale = MainCells()
	block:ClearAllPoints()
	if not left then -- aucune case visible (seul, ma case cachée) : là où les cadres commencent
		block:SetPoint("TOPLEFT", Z.anchor or UIParent, "BOTTOMLEFT", 0, -LABEL_GAP)
		block.where = "ANCHOR"
		return
	end
	local eff = block:GetEffectiveScale()
	local below = bottom - gap * scale
	local point, y = "TOPLEFT", below
	block.where = "BELOW"
	if below - block:GetHeight() * eff < 0 then
		point, y = "BOTTOMLEFT", top + (gap + LABEL_GAP) * scale
		block.where = "ABOVE"
	end
	-- accroché au point de départ des cadres (comme leurs groupes) : il les suit pendant qu'on les déplace.
	-- Point de départ pas encore mesuré : posé sur l'écran, il sera replacé au prochain changement.
	local anchor = Z.anchor
	local ax, ay = anchor and anchor:GetLeft(), anchor and anchor:GetTop()
	if ax and ay then
		local aEff = anchor:GetEffectiveScale()
		block:SetPoint(point, anchor, "TOPLEFT", (left - ax * aEff) / eff, (y - ay * aEff) / eff)
	else
		block:SetPoint(point, UIParent, "BOTTOMLEFT", left / eff, y / eff)
	end
end

local function BuildBlock()
	block = CreateFrame("Frame", "LyoruneBuffsBlock", UIParent)
	block:SetFrameStrata("MEDIUM")
	block:SetClampedToScreen(true)
	blockMore = UI.Text(Tile(1), 10) -- « + N » dans le coin de l'unique case
	blockMore:SetTextColor(0.7, 0.7, 0.7)
	local elapsed = 0
	block:SetScript("OnUpdate", function(_, delta) -- portée seulement, et seulement bloc visible
		elapsed = elapsed + delta
		if elapsed >= 0.5 then
			elapsed = 0
			UpdateRange()
		end
	end)
	-- les cadres du groupe changent de taille, apparaissent ou disparaissent : le bloc se replace, une fois
	local function Moved() Z:QueueBuffPanel() end
	for _, h in ipairs(Z.headers or {}) do
		if h.def and h.def.pos == "pos" then
			h:HookScript("OnSizeChanged", Moved)
			h:HookScript("OnShow", Moved)
			h:HookScript("OnHide", Moved)
		end
	end
	block:Hide()
end

local function ShowBlock(list)
	if not block then BuildBlock() end
	local db = Z.db
	local w, h = Z.CellSize()
	local entry, tile = list[1], Tile(1)
	Arm(tile, entry)
	tile:ClearAllPoints()
	StyleTile(tile, w, h, Z:Shape().buffs or "LINE", entry)
	tile:SetPoint("TOPLEFT", 0, 0)
	tile:Show()
	blockMore:ClearAllPoints()
	if #list > 1 then
		local theme = Z:Theme()
		local inset = UI.Inset(theme.borderSize, db.corners == "ROUND")
		blockMore:SetFont(theme.font, math.max(8, db.fontSize - 1), theme.flags)
		blockMore:SetText(Z.L["+ %d"]:format(#list - 1))
		blockMore:SetPoint("TOPRIGHT", -inset - 3, -inset - 2)
		blockMore:Show()
		if (Z:Shape().buffs or "LINE") ~= "ICON" then -- le texte de la case s'arrête avant le compteur
			tile.label:SetPoint("RIGHT", -inset - 6 - blockMore:GetStringWidth(), 0)
		end
	else
		blockMore:Hide()
	end
	local y = h
	block:SetScale(db.scale / 100)
	block:SetSize(w, y)
	PlaceBlock()
	UpdateRange()
	if not block:IsShown() then block:Show() end
end

-- Fenêtre « où vous voulez » : une ligne par entrée (10 au plus), « et N autres »
local function ShowWindow(list)
	if closed then list = {} end
	if #list == 0 then
		if panel then panel:Hide() end
		return
	end
	if not panel then Build() end
	local L = Z.L
	local shown = math.min(#list, MAX_ROWS)
	for i = 1, shown do
		local entry, row = list[i], Row(i)
		Arm(row, entry)
		row.icon:SetTexture(entry.icon or entry.check.icon)
		local text, r, g, b = EntryText(entry)
		row.label:SetText(text)
		row.label:SetTextColor(r, g, b)
		row:Show()
	end
	for i = shown + 1, #rows do
		rows[i]:Hide()
		rows[i].unitToken = nil
	end
	local height = 42 + shown * (ROW_H + 2) + 12
	more:ClearAllPoints()
	more:SetPoint("TOPLEFT", 16, -42 - shown * (ROW_H + 2) - 2)
	if #list > shown then
		more:SetText(L["et %d autres"]:format(#list - shown))
		more:Show()
		height = height + 16
	else
		more:Hide()
	end
	panel:SetHeight(height)
	UpdateRange()
	if not panel:IsShown() then panel:Show() end
end

-- Exemple (idée vue chez HealKit) : options ouvertes sur le chapitre Joueurs, où se règlent les buffs, et rien à
-- poser : une case d'exemple montre où et à quoi ressembleront les buffs manquants. Elle ne lance rien.
local function SampleList()
	local window = Z.OptionsWindow and Z:OptionsWindow()
	if not (window and window:IsShown() and Z:OptionChapter() == "Joueurs") then return {} end
	local check = Z.buffChecks[1] or Z.uniqueChecks[1]
	local name = UnitName("player")
	if not check or not name or issecret(name) then return {} end
	return { { check = check, spell = check.spell, icon = check.icon, unit = "player", name = name,
		class = select(2, UnitClass("player")), sample = true } }
end

function Z:UpdateBuffPanel()
	queued = false
	if InCombatLockdown() then return end -- les boutons du jeu ne bougent plus en combat
	Z.UpdateHiddenSelf() -- ma case cachée (seul) : ma fiche à jour avant la lecture (relit le panneau si elle change)
	if Z.RecheckBuffMarks then Z.RecheckBuffMarks() end -- repères des buffs (Containers.lua) : porteur, réglages
	local list = (Z.db.buffPanel and (#Z.buffChecks > 0 or #Z.uniqueChecks > 0)) and Z.BuffRows() or {}
	SetNextBuff(list[1])
	if #list == 0 and Z.db.buffPanel then list = SampleList() end
	if Z.db.buffPlace == "FREE" then
		if block then block:Hide() end
		ShowWindow(list)
	else
		if panel then panel:Hide() end
		if #list == 0 then
			if block then block:Hide() end
		else
			ShowBlock(list)
		end
	end
end

-- Plusieurs cases qui changent dans la même seconde : une seule mise à jour du panneau
function Z:QueueBuffPanel()
	if queued then return end
	queued = true
	C_Timer.After(0.3, function() Z:Try("panneau des buffs", Z.UpdateBuffPanel, Z) end)
end

function Z:BuffPanel()
	return panel
end

function Z:BuffBlock()
	return block
end

-- Entrée en combat : le jeu verrouille les boutons juste après cet événement, on cache le panneau avant
Z:On("PLAYER_REGEN_DISABLED", function()
	CombatKey()
	if InCombatLockdown() then return end
	if panel then panel:Hide() end
	if block then block:Hide() end
end)
Z:On("PLAYER_REGEN_ENABLED", function()
	closed = false
	Z:QueueBuffPanel()
end)
Z:On("GROUP_ROSTER_UPDATE", function() Z:QueueBuffPanel() end)

-- /lyorune porteur [nom] : le joueur qui reçoit mes buffs uniques à la place du tank (le joueur survolé, ou ma
-- cible). Le même joueur une 2e fois, ou sans joueur : retour au tank. Gardé pour ce personnage.
function Z:BuffTargetCommand(text)
	local L, target = Z.L, Z.char.buffTarget
	local name
	if text and text ~= "" then
		name = Z.CleanPinName(text)
	else
		local hovered = Z.hovered and Z.hovered:IsVisible() and Z.hovered.unit
		name = Z.UnitPinName(hovered) or Z.UnitPinName("target")
	end
	target.byId = nil -- la commande vaut pour tous mes buffs uniques : les choix par buff s'effacent
	if not name or name == target.name then
		target.name = nil
		Z:Print(L["buffs uniques : de retour sur le tank."])
	else
		target.name = name
		Z:Print(L["buffs uniques : %s les recevra."]:format(name))
	end
	Z:QueueBuffPanel()
end
