-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - GroupCooldowns.lua : recharges du groupe (réglages « groupCooldowns », éteint au départ, et
-- « cooldownShare », éteint au départ : allumé, vos alliés qui suivent voient vos sorts sans rien faire).
-- Le jeu cache les sorts lancés par les autres joueurs et ferme le journal de combat : seuls les joueurs qui ont
-- Lyorune se suivent. Chacun annonce ses gros sorts de Data.lua (Z.groupCooldowns) : « lancé », puis « prêt »
-- quand le jeu dit que la recharge est finie (isActive, jamais secret), et son état complet en rejoignant un
-- groupe, après un /reload et à la fin d'un blocage des messages. Durée réelle de la recharge lue chez lui hors
-- combat (talents compris) et retenue ; le décompte se fait chez celui qui regarde : aucun envoi régulier, aucune
-- boucle (le jeu écrit les secondes et prévient à la fin). Aucune valeur secrète ne part jamais.
-- Pendant un combat de boss ou un match JcJ, le jeu bloque les messages : le panneau garde le dernier état connu,
-- marqué « avant le boss », et tout se remet à jour à la fin.
--
-- Messages (préfixe « Lyorune », reçus par Comm.lua) :
--   K:+20484=0/600,29166=134/360   mon état complet (numéro du sort = secondes restantes / durée de la recharge)
--   K:29166=360/360                un sort qui change (lancé, ou prêt avec 0)
--   K:?   envoyez-moi vos recharges (après mon /reload)          K:-   je ne partage plus rien

local _, Z = ...
local UI = Z.UI
local issecret = Z.IsSecret

local REPLY_GAP = 10    -- mon état complet part au plus une fois toutes les 10 secondes
local READY_GUARD = 2   -- juste après un sort, le jeu peut ne pas encore avoir lancé la recharge
local MAX_SPELLS = 12   -- sorts lus dans un message, au plus
local MAX_LENGTH = 7200 -- une recharge annoncée plus longue que 2 heures est ignorée
local GAP = 2

----------------------------------------------------------------------------------------------------
-- Les sorts suivis : la liste de Data.lua, toutes classes (seuls ces numéros sont acceptés d'un autre joueur)
----------------------------------------------------------------------------------------------------
local order -- { numéro, ... } : classes dans l'ordre alphabétique, sorts dans l'ordre de Data.lua
local allowed -- [numéro] = place dans l'ordre

local function Allowed()
	if not allowed then
		order, allowed = {}, {}
		local classes = {}
		for class in pairs(Z.groupCooldowns or {}) do classes[#classes + 1] = class end
		table.sort(classes)
		for _, class in ipairs(classes) do
			for _, id in ipairs(Z.groupCooldowns[class]) do
				if not allowed[id] then
					order[#order + 1] = id
					allowed[id] = #order
				end
			end
		end
	end
	return allowed
end

----------------------------------------------------------------------------------------------------
-- 1. Partager mes recharges
----------------------------------------------------------------------------------------------------
local castAt = {}  -- [numéro] = heure de mon dernier sort réussi
local cooling = {} -- [numéro] = true : annoncé « lancé », on attend la fin de la recharge
local dirty = false -- un message n'a pas pu partir (blocage) : mon état complet partira dès que possible
local shared = false -- j'ai déjà annoncé quelque chose dans ce groupe
local lastFull, fullQueued = -REPLY_GAP, false

local function Sharing()
	return Z.db.syncEnabled and Z.db.cooldownShare and Z.class ~= nil and IsInGroup()
end

-- Mes sorts de la liste que je connais : { { id, name } }
local function MySpells()
	local list = {}
	for _, id in ipairs((Z.groupCooldowns or {})[Z.class] or {}) do
		local name = C_Spell.GetSpellName(id)
		if name and not issecret(name) and Z.Knows(id) then list[#list + 1] = { id = id, name = name } end
	end
	return list
end

-- Durée réelle de la recharge, lue quand le jeu la donne (hors combat, sort en recharge) et retenue
local function Learn(id)
	if Z.SpellCooling(id) ~= true then return end
	local info = C_Spell.GetSpellCooldown(id)
	local length = info and info.duration
	if issecret(length) or type(length) ~= "number" or length <= 1.5 or length > MAX_LENGTH then return end
	length = math.floor(length + 0.5)
	Z.db.cooldownDurations = Z.db.cooldownDurations or {}
	if Z.db.cooldownDurations[id] ~= length then Z.db.cooldownDurations[id] = length end
end

-- Durée de la recharge en secondes : apprise, sinon celle de base donnée par le jeu, sinon nil
local function Total(id)
	local known = Z.db.cooldownDurations and Z.db.cooldownDurations[id]
	if known then return known end
	if not GetSpellBaseCooldown then return end
	local ok, ms = pcall(GetSpellBaseCooldown, id)
	if ok and type(ms) == "number" and not issecret(ms) and ms > 1500 then return math.floor(ms / 1000 + 0.5) end
end

-- « numéro=reste/durée », ou nil si je ne sais rien de sûr (recharge cachée sans sort vu)
local function Entry(id, left)
	local total = Total(id)
	if not total then return end
	if not left then
		local state = Z.SpellCooling(id)
		if state == false then
			left = 0
		else
			left = Z.SpellCooldownLeft(id)
			if not left and castAt[id] then left = math.max(1, total - (GetTime() - castAt[id])) end
			if not left then return end
			left = math.max(1, left) -- en recharge : jamais « 0 », qui voudrait dire prêt
		end
	end
	left = math.min(total, math.floor(left + 0.5))
	return ("%d=%d/%d"):format(id, left, total)
end
Z.GroupCooldownEntry = Entry -- pour les tests

local function Send(text)
	if Z.CommLockdown() or not Z.CommSendGroup("K:" .. text) then
		dirty = true
		return false
	end
	shared = true
	return true
end

-- Mon état complet, au plus une fois toutes les 10 secondes (sinon reporté ; now : l'envoi reporté lui-même)
local function SendFull(now)
	if not Sharing() then return end
	local wait = REPLY_GAP - (GetTime() - lastFull)
	if wait > 0 and now ~= true then
		if not fullQueued then
			fullQueued = true
			C_Timer.After(wait + 0.1, function()
				fullQueued = false
				Z:Try("recharges du groupe", SendFull, true)
			end)
		end
		return
	end
	if Z.CommLockdown() then dirty = true return end
	local parts = {}
	for _, spell in ipairs(MySpells()) do
		local entry = Entry(spell.id)
		if entry then
			parts[#parts + 1] = entry
			cooling[spell.id] = not entry:find("=0/", 1, true) or nil
		end
	end
	if #parts == 0 then return end
	lastFull = GetTime()
	if Send("+" .. table.concat(parts, ",")) then dirty = false end
end
Z.GroupCooldownSendFull = SendFull

-- Un de mes sorts réussi : « lancé » (le jeu cache la recharge en combat ; je connais sa durée)
local function OnCast(spellId)
	if issecret(spellId) or not spellId then return end
	local name = C_Spell.GetSpellName(spellId)
	if not name or issecret(name) then return end
	for _, spell in ipairs(MySpells()) do
		if spell.name == name then
			castAt[spell.id], cooling[spell.id] = GetTime(), true
			local total = Total(spell.id)
			local entry = total and Entry(spell.id, total)
			if entry then Send(entry) end
			return
		end
	end
end

-- Les recharges changent : un sort annoncé « lancé » qui est prêt part en « prêt » ; durées apprises
local function OnCooldowns()
	for id in pairs(cooling) do
		Learn(id)
		if Z.SpellCooling(id) == false and GetTime() - (castAt[id] or 0) >= READY_GUARD then
			cooling[id], castAt[id] = nil, nil
			local entry = Entry(id, 0)
			if entry then Send(entry) end
		end
	end
end

----------------------------------------------------------------------------------------------------
-- 2. Les recharges des autres
----------------------------------------------------------------------------------------------------
local players = {} -- [clé du nom] = { name = nom court, class, spells = { [numéro] = { ends, total } } }
local panel, title
local lines = {}   -- lignes du panneau, une par sort
local hooked = false
local Draw         -- plus bas

local function Showing()
	return Z.db and Z.db.groupCooldowns and Z.db.syncEnabled and IsInGroup()
end

local function MyKey() return Z.CommKey(UnitName("player")) end

-- Classe d'un membre du groupe, par sa clé (couleur du nom)
local function ClassOf(key)
	local entry = Z.AssignMembers()[key]
	if not entry then return end
	local _, class = UnitClass(entry.unit)
	if not issecret(class) then return class end
end

-- Un message « K: » d'un membre du groupe (Comm.lua)
function Z.GroupCooldownReceive(body, sender)
	if not Z.db.syncEnabled then return end
	local key = Z.CommKey(sender)
	if key == MyKey() then return end
	local members = Z.AssignMembers()
	if not members[key] then return end
	if body == "?" then
		if Sharing() then SendFull() end
		return
	end
	if body == "-" then
		if players[key] then players[key] = nil Draw() end
		return
	end
	if not Showing() then return end -- rien n'est gardé sans le panneau (il redemande en s'allumant)
	local replace = body:sub(1, 1) == "+"
	if replace then body = body:sub(2) end
	local ok = Allowed()
	local now, read, count = GetTime(), {}, 0
	for id, left, total in body:gmatch("(%d+)=(%d+)/(%d+)") do
		count = count + 1
		if count > MAX_SPELLS or #id > 9 or #total > 5 then return end
		id, left, total = tonumber(id), tonumber(left), tonumber(total)
		if not ok[id] or total < 1 or total > MAX_LENGTH or left > total then return end
		read[id] = { ends = now + left, total = total }
	end
	if count == 0 then return end
	local player = players[key]
	if not player or replace then
		player = { name = Z.CommShort(sender), spells = {} }
		players[key] = player
	end
	player.class = ClassOf(key)
	for id, state in pairs(read) do player.spells[id] = state end
	Draw()
end

-- Le groupe change : les joueurs partis sont oubliés ; je rejoins un groupe : mon état part
local function RosterChanged()
	if not IsInGroup() then
		wipe(players)
		shared = false
		Draw()
		return
	end
	local members, unsure = Z.AssignMembers()
	if not unsure then
		for key in pairs(players) do
			if not members[key] then players[key] = nil end
		end
	end
	if not shared and Sharing() then SendFull() end
	Draw()
end

-- Un joueur qui a Lyorune arrive dans le groupe (Comm.lua) : il reçoit mon état
function Z.CooldownNewMember()
	if Sharing() then SendFull() end
end

----------------------------------------------------------------------------------------------------
-- 3. Le panneau « Groupe »
----------------------------------------------------------------------------------------------------
local function Size()
	return math.max(16, Z.db.fontSize + 6)
end

local function Clock(seconds)
	seconds = math.max(0, math.floor(seconds + 0.5))
	if seconds >= 60 then return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60) end
	return Z.L["%d s"]:format(seconds)
end

local function EntryEnter(self)
	local L = Z.L
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:SetText(self.who or "", 1, 1, 1)
	GameTooltip:AddLine(self.spellName or "", UI.accent[1], UI.accent[2], UI.accent[3])
	local left = (self.ends or 0) - GetTime()
	if left > 0 then
		GameTooltip:AddLine(L["Prêt dans %s"]:format(Clock(left)), 1, 0.4, 0.35)
	else
		GameTooltip:AddLine(L["Prêt"], 0.4, 1, 0.5)
	end
	if Z.CommLockdown() then
		GameTooltip:AddLine(L["Le jeu bloque les messages pendant ce combat : dernier état connu, mis à jour à la fin."], 0.6, 0.6, 0.65, true)
	end
	GameTooltip:Show()
end

local function Leave() GameTooltip:Hide() end

-- Une case « nom + secondes » d'un joueur sur la ligne d'un sort
local function NewEntry(line)
	local e = CreateFrame("Frame", nil, line)
	e.text = UI.Text(e, Z.db.fontSize)
	e.text:SetPoint("LEFT")
	e.clock = CreateFrame("Frame", nil, e)
	e.cd = CreateFrame("Cooldown", nil, e.clock, "CooldownFrameTemplate")
	e.cd:SetAllPoints()
	e.cd:SetDrawSwipe(false)
	e.cd:SetDrawEdge(false)
	e.cd:SetDrawBling(false)
	e.cd:SetHideCountdownNumbers(false) -- les secondes, écrites par le jeu : aucune boucle
	e.cd:SetScript("OnCooldownDone", function() Z:Try("recharges du groupe", Draw) end)
	e:EnableMouse(true)
	e:SetScript("OnEnter", EntryEnter)
	e:SetScript("OnLeave", Leave)
	return e
end

local function Line(index)
	if lines[index] then return lines[index] end
	local line = CreateFrame("Frame", nil, panel)
	line.bg = UI.Tex(line, "BACKGROUND", 0, 0, 0, 0.6)
	line.bg:SetAllPoints()
	line.icon = line:CreateTexture(nil, "ARTWORK")
	line.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	line.icon:SetPoint("TOPLEFT", 1, -1)
	line.entries = {}
	lines[index] = line
	return line
end

-- Au-dessous de « Mes recharges », sinon du bandeau des buffs manquants, sinon des cadres (même côté)
function Z.PlaceGroupCooldowns()
	if not (panel and panel:IsShown()) then return end
	Z.PlaceUnderCells(panel)
	local row = Z.CooldownRow and Z:CooldownRow()
	local block = Z.BuffBlock and Z:BuffBlock()
	local above
	if row and row:IsShown() and row.where == panel.where then
		above = row
	elseif block and block:IsShown() and block.where == panel.where then
		above = block
	end
	if not above then return end
	local gap = Z.db.spacing
	panel:ClearAllPoints()
	if panel.where == "ABOVE" then
		panel:SetPoint("BOTTOMLEFT", above, "TOPLEFT", 0, gap)
	else
		panel:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -gap)
	end
end

-- Le panneau entier : une ligne par sort (« Renaissance : Lyra, Tom 4:10 »), les joueurs par ordre alphabétique
function Draw()
	if not panel then
		if not Showing() or not next(players) then return end
		panel = CreateFrame("Frame", "LyoruneGroupCooldowns", UIParent)
		panel:SetFrameStrata("MEDIUM")
		panel:SetClampedToScreen(true)
		title = UI.Text(panel, Z.db.fontSize)
		title:SetPoint("TOPLEFT")
	end
	if not hooked and Z.headers and #Z.headers > 0 then
		hooked = true
		local function Moved() Z:Try("recharges du groupe", Z.PlaceGroupCooldowns) end
		for _, h in ipairs(Z.headers) do
			if h.def and h.def.pos == "pos" then
				h:HookScript("OnSizeChanged", Moved)
				h:HookScript("OnShow", Moved)
				h:HookScript("OnHide", Moved)
			end
		end
	end
	local L, now = Z.L, GetTime()
	local ignored = Z.db.cooldownIgnored or {}
	local byId = {}
	if Showing() then
		for key, player in pairs(players) do
			for id, state in pairs(player.spells) do
				byId[id] = byId[id] or {}
				table.insert(byId[id], { key = key, player = player, state = state })
			end
		end
	end
	Allowed()
	local used, size, width = 0, Size(), 0
	local font = Z.db.fontSize
	local top = font + 4
	for _, id in ipairs(order) do
		local list = byId[id]
		local name = list and C_Spell.GetSpellName(id)
		if list and name and not issecret(name) and not ignored[name] then
			used = used + 1
			table.sort(list, function(a, b) return a.player.name < b.player.name end)
			local line = Line(used)
			line.icon:SetSize(size - 2, size - 2)
			line.icon:SetTexture(Z.SpellIcon(id))
			local x, anyReady = size + 6, false
			for i, item in ipairs(list) do
				local e = line.entries[i] or NewEntry(line)
				line.entries[i] = e
				local left = item.state.ends - now
				local ready = left <= 0
				anyReady = anyReady or ready
				e.who, e.spellName, e.ends = item.player.name, name, item.state.ends
				e.text:SetFont(UI.Font(), font, "")
				e.text:SetText(item.player.name)
				local r, g, b = Z.ClassColor(item.player.class)
				e.text:SetTextColor(r, g, b, ready and 1 or 0.55)
				local w = math.ceil(e.text:GetStringWidth())
				if ready then
					e.cd:Clear()
					e.clock:Hide()
				else
					e.clock:ClearAllPoints()
					e.clock:SetPoint("LEFT", e.text, "RIGHT", 2, 0)
					e.clock:SetSize(size * 1.6, size)
					e.cd:SetCooldown(item.state.ends - item.state.total, item.state.total)
					e.clock:Show()
					w = w + 2 + math.ceil(size * 1.6)
				end
				e:SetSize(w, size)
				e:ClearAllPoints()
				e:SetPoint("LEFT", line, "LEFT", x, 0)
				e:Show()
				x = x + w + 8
			end
			for i = #list + 1, #line.entries do line.entries[i]:Hide() end
			line.icon:SetDesaturated(not anyReady)
			line:SetSize(x - 4, size)
			line:ClearAllPoints()
			line:SetPoint("TOPLEFT", 0, -top - (used - 1) * (size + GAP))
			line:Show()
			width = math.max(width, x - 4)
		end
	end
	for i = used + 1, #lines do lines[i]:Hide() end
	if used == 0 then
		panel:Hide()
		return
	end
	-- messages bloqués par le jeu : le titre le dit
	local stale = Z.CommLockdown()
	local text = L["Recharges du groupe"]
	if stale then text = text .. " " .. (Z.PvPKind and Z.PvPKind() and L["(avant le match)"] or L["(avant le boss)"]) end
	title:SetFont(UI.Font(), font, "")
	title:SetText(text)
	title:SetTextColor(UI.accent[1], UI.accent[2], UI.accent[3], stale and 0.6 or 1)
	width = math.max(width, math.ceil(title:GetStringWidth()))
	panel:SetScale(Z.db.scale / 100)
	panel:SetSize(width, top + used * (size + GAP) - GAP)
	panel:Show()
	Z.PlaceGroupCooldowns()
end
Z.DrawGroupCooldowns = Draw

function Z:GroupCooldownPanel()
	return panel, lines, players, title
end

----------------------------------------------------------------------------------------------------
-- Événements : seulement ce que les réglages demandent
----------------------------------------------------------------------------------------------------
local events = CreateFrame("Frame")
local handlers = {
	UNIT_SPELLCAST_SUCCEEDED = function(_, _, spellId) OnCast(spellId) end,
	SPELL_UPDATE_COOLDOWN = OnCooldowns,
	PLAYER_REGEN_ENABLED = function() if dirty then SendFull() end end,
}
events:SetScript("OnEvent", function(_, event, ...)
	Z:Try("recharges du groupe", handlers[event], ...)
end)

local wasSharing, wasShowing = false, false

-- Réglages changés (Options.lua, chargement) : écoute, panneau, annonces
function Z:RefreshGroupCooldowns()
	events:UnregisterAllEvents()
	local share = Z.db.syncEnabled and Z.db.cooldownShare and Z.class ~= nil
	if share then
		pcall(events.RegisterUnitEvent, events, "UNIT_SPELLCAST_SUCCEEDED", "player")
		events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		events:RegisterEvent("PLAYER_REGEN_ENABLED")
		if not wasSharing and IsInGroup() then SendFull() end
	elseif wasSharing and shared and IsInGroup() and not Z.CommLockdown() then
		Z.CommSendGroup("K:-")
		shared = false
	end
	wasSharing = share
	local showing = Showing() and true or false
	if not showing then wipe(players) end
	if showing and not wasShowing then Z.AskGroupCooldowns() end -- le panneau s'allume
	wasShowing = showing
	Draw()
end

-- Les autres m'envoient leurs recharges (panneau allumé, /reload)
function Z.AskGroupCooldowns()
	if Showing() and not Z.CommLockdown() then Z.CommSendGroup("K:?") end
end

Z:On("PLAYER_LOGIN", function() Z:RefreshGroupCooldowns() end)
Z:On("GROUP_ROSTER_UPDATE", RosterChanged)
Z:On("PLAYER_ENTERING_WORLD", function()
	RosterChanged()
	Z.AskGroupCooldowns() -- après un /reload, ce que je savais est perdu
end)
-- fin d'un blocage des messages : mon état part s'il n'a pas pu partir, le titre perd « avant le boss »
Z:On("ADDON_RESTRICTION_STATE_CHANGED", function()
	C_Timer.After(1, function()
		Z:Try("recharges du groupe", function()
			if dirty and not Z.CommLockdown() then SendFull() end
			Draw()
		end)
	end)
end)
