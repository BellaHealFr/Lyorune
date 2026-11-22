-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Assign.lua : répartition entre soigneurs.
--   1. Mes joueurs, sans aucun message : je choisis les groupes de raid et les joueurs (un tank...) dont je
--      m'occupe (réglages assignGroups et assignPlayers, chapitre Joueurs). Leurs cases portent un trait doré
--      (Frames.lua, UpdateAssign) ; au choix, les autres s'estompent un peu. Utile même seul à avoir Lyorune.
--   2. Partage : le chef ou un assistant envoie une répartition à tous les soigneurs (fenêtre « Répartir les
--      soigneurs »). Celui qui reçoit vérifie lui-même que l'expéditeur est chef ou assistant, puis l'applique
--      d'office (réglage assignAccept) ; une ligne dans la discussion le dit. Au survol d'une case : le soigneur
--      prévu. Ma part de la répartition remplace mon choix ; il revient quand je quitte le groupe.
-- Le jeu bloque les messages d'addon pendant un combat de boss ou un match JcJ : la répartition
-- part avant le combat, jamais pendant (envoi refusé avec un message). Une fois reçue, elle reste valable sans
-- aucun message : jusqu'au prochain envoi, son effacement ou la sortie du groupe, même après un /reload
-- (LyoruneCharDB). Un soigneur qui part : ses joueurs restent sans soigneur, rien ne se réattribue tout seul, et
-- celui qui a envoyé la répartition est prévenu. Un nouveau venu qui a Lyorune la reçoit de l'expéditeur.
--
-- Messages (préfixe « Lyorune », Comm.lua), un par soigneur, 255 caractères au plus :
--   A:id:i:n:Soigneur-Royaume=13/Tank-Royaume,Autre-Royaume   part i sur n : groupes 1 et 3, et deux joueurs
--   A:id:0:0:                                                 répartition effacée

local _, Z = ...
local issecret = Z.IsSecret

local MAX_HEALERS = 12  -- soigneurs dans une répartition, au plus
local MAX_PLAYERS = 5   -- joueurs nommés pour un soigneur, au plus
local MAX_LENGTH = 250  -- longueur d'un message (le jeu en accepte 255)
local PART_TIMEOUT = 30 -- une répartition incomplète est oubliée au bout de 30 secondes
local SEND_GAP = 3      -- un envoi au groupe toutes les 3 secondes au plus

local incoming          -- répartition en cours de réception : { from, id, total, parts, count, started }
local pending = {}      -- nouveaux venus à qui envoyer la répartition dès que le jeu le permet
local lastSend = -SEND_GAP
local window

local function Key(name) return Z.CommKey(name) end
local function MyKey() return Key(UnitName("player")) end
local function Short(name) return Z.CommShort(name) end

----------------------------------------------------------------------------------------------------
-- Le groupe
----------------------------------------------------------------------------------------------------
local function GroupUnits()
	local units = {}
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do units[#units + 1] = "raid" .. i end
	else
		units[1] = "player"
		for i = 1, 4 do units[#units + 1] = "party" .. i end
	end
	return units
end

-- Les membres du groupe par clé de nom : { unit, name }. unsure : un nom était secret, la liste peut être incomplète.
local function Members()
	local list, unsure = {}, false
	for _, unit in ipairs(GroupUnits()) do
		if UnitExists(unit) then
			local name = GetUnitName(unit, true)
			if not name or issecret(name) then
				unsure = true
			else
				list[Key(name)] = { unit = unit, name = name }
			end
		end
	end
	list[MyKey()] = list[MyKey()] or { unit = "player", name = UnitName("player") }
	return list, unsure
end
Z.AssignMembers = Members -- aussi pour la répartition des buffs (BuffAssign.lua)

-- Chef du groupe, ou assistant en raid. Réponse secrète : non (on ne devine jamais un droit).
local function MayShare(unit)
	if not unit then return false end
	local leader = UnitIsGroupLeader(unit)
	if issecret(leader) then return false end
	if leader then return true end
	if not IsInRaid() then return false end
	local assist = UnitIsGroupAssistant(unit)
	return not issecret(assist) and assist == true
end
Z.AssignMayShare = MayShare

-- Groupe de raid d'une unité, ou nil (pas en raid, ou réponse secrète)
local function UnitGroup(unit)
	if not IsInRaid() or not GetRaidRosterInfo then return nil end
	local index = tonumber(unit:match("^raid(%d+)$"))
	if not index and UnitInRaid then index = UnitInRaid(unit) end
	if not index or issecret(index) then return nil end
	local group = select(3, GetRaidRosterInfo(index))
	if issecret(group) then return nil end
	return tonumber(group)
end
Z.UnitRaidGroup = UnitGroup

local function InList(players, key)
	for name in pairs(players) do
		if Key(name) == key then return true end
	end
	return false
end

local function IsGroupUnit(unit)
	return unit == "player" or unit:match("^raid%d+$") ~= nil or unit:match("^party%d$") ~= nil
end

----------------------------------------------------------------------------------------------------
-- Ma part
----------------------------------------------------------------------------------------------------
-- La répartition reçue, si elle compte : synchronisation et réglage allumés, et toujours en groupe
local function Shared()
	local shared = Z.char and Z.char.assignShared
	if not shared or not (Z.db.syncEnabled and Z.db.assignAccept) or not IsInGroup() then return nil end
	return shared
end
Z.AssignShared = Shared

-- Ma part : celle de la répartition reçue si elle me nomme, sinon mon choix. Renvoie groupes, joueurs, reçue.
function Z.AssignChoice()
	local shared = Shared()
	local mine = shared and shared.healers[MyKey()]
	if mine then return mine.groups, mine.players, shared end
	return Z.db.assignGroups, Z.db.assignPlayers, nil
end

-- Pour une case : est-ce un de mes joueurs ? Renvoie mine (nil : réponse secrète, la case garde son état) et
-- active (un choix compte ici). Les groupes ne comptent qu'en raid : en groupe de cinq, seuls les joueurs choisis.
function Z.AssignState(unit)
	if not unit or not IsGroupUnit(unit) then return false, false end
	local groups, players = Z.AssignChoice()
	local useGroups = IsInRaid() and next(groups) ~= nil
	if not useGroups and not next(players) then return false, false end
	local name = GetUnitName(unit, true)
	if issecret(name) then return nil, true end
	if name and InList(players, Key(name)) then return true, true end
	if not useGroups then return false, true end
	local group = UnitGroup(unit)
	if group == nil then return nil, true end
	return groups[group] == true, true
end

-- Les soigneurs prévus pour ce joueur dans la répartition reçue (noms courts), ou nil
function Z.AssignHealers(unit)
	local shared = Shared()
	if not shared or not unit then return nil end
	local name = GetUnitName(unit, true)
	if not name or issecret(name) then return nil end
	local key, group = Key(name), UnitGroup(unit)
	local list = {}
	for _, healer in pairs(shared.healers) do
		if InList(healer.players, key) or (group and healer.groups[group]) then list[#list + 1] = Short(healer.name) end
	end
	table.sort(list)
	return #list > 0 and list or nil
end

-- « groupes 1 et 3, Tankou » : une part, en clair
function Z.AssignDescribe(groups, players)
	local L = Z.L
	local parts, numbers, names = {}, {}, {}
	for g = 1, 8 do if groups[g] then numbers[#numbers + 1] = tostring(g) end end
	if #numbers == 1 then
		parts[1] = L["groupe %s"]:format(numbers[1])
	elseif #numbers > 1 then
		parts[1] = L["groupes %s"]:format(table.concat(numbers, ", ", 1, #numbers - 1) .. L[" et "] .. numbers[#numbers])
	end
	for name in pairs(players) do names[#names + 1] = Short(name) end
	table.sort(names)
	for _, name in ipairs(names) do parts[#parts + 1] = name end
	return #parts > 0 and table.concat(parts, ", ") or L["personne"]
end

local function Changed()
	if Z.RefreshAssign then Z.RefreshAssign() end
	if Z.assignStatus and Z.assignStatus:IsVisible() then Z.assignStatus:Update() end
end

----------------------------------------------------------------------------------------------------
-- Messages
----------------------------------------------------------------------------------------------------
-- Une part : « Soigneur-Royaume=13/Tank-Royaume,Autre-Royaume », coupée avant la longueur permise
local function Encode(prefix, healer)
	local numbers = {}
	for g = 1, 8 do if healer.groups[g] then numbers[#numbers + 1] = g end end
	local text = prefix .. Key(healer.name) .. "=" .. table.concat(numbers) .. "/"
	local names = {}
	for name in pairs(healer.players) do names[#names + 1] = Key(name) end
	table.sort(names)
	local first = true
	for i, name in ipairs(names) do
		if i > MAX_PLAYERS or #text + #name + 1 > MAX_LENGTH then break end
		text = text .. (first and "" or ",") .. name
		first = false
	end
	return text
end

local NAME = "^[^%s:,/=%-]+%-[^%s:,/=%-]+$" -- « Nom-Royaume », sans espace ni séparateur

local function Decode(body)
	local name, numbers, list = body:match("^([^=]+)=(%d*)/(.*)$")
	if not name or #name > 60 or not name:match(NAME) or #numbers > 8 then return nil end
	local healer = { name = name, groups = {}, players = {} }
	for digit in numbers:gmatch("%d") do
		local g = tonumber(digit)
		if g >= 1 and g <= 8 then healer.groups[g] = true end
	end
	local count = 0
	for player in list:gmatch("[^,]+") do
		if #player > 60 or not player:match(NAME) then return nil end
		count = count + 1
		if count > MAX_PLAYERS then return nil end
		healer.players[player] = true
	end
	return healer
end

local function SortedKeys(healers)
	local keys = {}
	for key in pairs(healers) do keys[#keys + 1] = key end
	table.sort(keys)
	return keys
end

-- Toutes les parts d'une répartition, à un joueur (chuchotement) ou au groupe
local function SendParts(shared, target)
	local keys = SortedKeys(shared.healers)
	for i, key in ipairs(keys) do
		local prefix = ("A:%s:%d:%d:"):format(shared.id, i, #keys)
		local ok
		if target then ok = Z.CommSend(Encode(prefix, shared.healers[key]), "WHISPER", target) else ok = Z.CommSendGroup(Encode(prefix, shared.healers[key])) end
		if not ok then return false end
	end
	return true
end

-- Une répartition complète, reçue ou envoyée : elle remplace la précédente
local function Apply(shared, quiet)
	Z.char.assignShared = shared
	if not quiet then
		local L = Z.L
		local mine = shared.healers[MyKey()]
		if mine then
			Z:Print(L["répartition de %s : vous soignez %s."]:format(shared.by, Z.AssignDescribe(mine.groups, mine.players)))
		else
			Z:Print(L["répartition de %s reçue : elle ne vous nomme pas, votre choix reste."]:format(shared.by))
		end
	end
	Changed()
end

function Z.AssignReceive(text, sender)
	if not Z.db.assignAccept or not Z.char then return end
	local id, index, total, body = text:match("^(%d+):(%d+):(%d+):(.*)$")
	if not id or #id > 6 then return end
	index, total = tonumber(index), tonumber(total)
	local from = Key(sender)
	if from == MyKey() then return end -- mon propre envoi, revenu du groupe : déjà appliqué
	local member = Members()[from]
	if not member or not MayShare(member.unit) then return end -- seulement le chef ou un assistant du groupe
	if total == 0 then -- effacée par celui qui l'avait envoyée
		local shared = Z.char.assignShared
		if shared and shared.from == from then
			Z.char.assignShared = nil
			Z:Print(Z.L["%s a effacé la répartition des soigneurs."]:format(Short(sender)))
			Changed()
		end
		return
	end
	if total > MAX_HEALERS or index < 1 or index > total then return end
	local healer = Decode(body)
	if not healer then return end
	local now = GetTime()
	if not incoming or incoming.from ~= from or incoming.id ~= id or now - incoming.started > PART_TIMEOUT then
		incoming = { from = from, id = id, total = total, parts = {}, count = 0, started = now }
	end
	if incoming.total ~= total then return end
	if not incoming.parts[index] then incoming.count = incoming.count + 1 end
	incoming.parts[index] = healer
	if incoming.count < total then return end
	local healers = {}
	for _, part in pairs(incoming.parts) do healers[Key(part.name)] = part end
	incoming = nil
	Apply({ from = from, by = Short(sender), id = id, healers = healers })
end

-- Un joueur qui a Lyorune arrive dans le groupe (Comm.lua) : s'il y a une répartition que j'ai envoyée, il la reçoit
function Z.AssignNewMember(sender)
	local shared = Shared()
	if not shared or shared.from ~= MyKey() then return end
	if not SendParts(shared, sender) then pending[sender] = true end -- bloqué : dès que le jeu le permet
end

local function SendPending()
	local shared = Shared()
	if not shared or shared.from ~= MyKey() or Z.CommLockdown() then return end
	for sender in pairs(pending) do
		if not SendParts(shared, sender) then return end
		pending[sender] = nil
	end
end

----------------------------------------------------------------------------------------------------
-- Envoi (chef ou assistant)
----------------------------------------------------------------------------------------------------
-- healers : clé du soigneur -> { name, groups, players }. Les soigneurs sans rien à soigner ne sont pas envoyés.
function Z:AssignSend(healers)
	local L = Z.L
	if not Z.db.syncEnabled then return false, L["La synchronisation entre joueurs est coupée (chapitre Profils et partage)."] end
	if not IsInGroup() then return false, L["Vous n'êtes pas en groupe."] end
	if not MayShare("player") then return false, L["Seuls le chef du groupe et les assistants peuvent envoyer une répartition."] end
	if Z.CommLockdown() then return false, L["Le jeu bloque les messages entre addons pendant un combat de boss ou un match JcJ : envoyez la répartition avant le combat."] end
	if GetTime() - lastSend < SEND_GAP then return false, L["Attendez quelques secondes avant de renvoyer."] end
	local kept = {}
	for key, healer in pairs(healers) do
		if next(healer.groups) or next(healer.players) then kept[key] = healer end
	end
	local count = #SortedKeys(kept)
	if count == 0 then return false, L["Choisissez au moins un groupe ou un joueur pour un soigneur."] end
	if count > MAX_HEALERS then return false, L["%d soigneurs au plus."]:format(MAX_HEALERS) end
	local shared = { from = MyKey(), by = UnitName("player"), id = tostring(math.random(1000, 99999)), healers = kept }
	lastSend = GetTime()
	if not SendParts(shared) then return false, L["Envoi impossible pour le moment (combat ou messages freinés par le jeu). Réessayez dans un instant."] end
	wipe(pending)
	Apply(shared, true)
	return true, L["Répartition envoyée : %d soigneur(s). Ceux qui ont Lyorune la voient tout de suite."]:format(count)
end

function Z:AssignClear()
	local L = Z.L
	local shared = Z.char.assignShared
	if not shared then return true, L["Aucune répartition en cours."] end
	if shared.from == MyKey() and IsInGroup() then
		if Z.CommLockdown() or not Z.CommSendGroup(("A:%s:0:0:"):format(shared.id)) then
			return false, L["Le jeu bloque les messages entre addons pendant un combat de boss ou un match JcJ : envoyez la répartition avant le combat."]
		end
	end
	Z.char.assignShared = nil
	wipe(pending)
	Changed()
	return true, L["Répartition effacée."]
end

----------------------------------------------------------------------------------------------------
-- Le groupe change : un soigneur part, ou je quitte le groupe
----------------------------------------------------------------------------------------------------
local function RosterChanged()
	if not Z.char then return end
	if not IsInGroup() then
		incoming = nil
		wipe(pending)
		if Z.char.assignShared then
			Z.char.assignShared = nil -- mon choix revient
			Changed()
		end
		return
	end
	local shared = Z.char.assignShared
	if not shared then return end
	local members, unsure = Members()
	if unsure then return end -- un nom secret : on ne conclut à aucun départ
	local L, gone = Z.L, false
	for key, healer in pairs(shared.healers) do
		if not members[key] then
			shared.healers[key] = nil
			gone = true
			if shared.from == MyKey() then
				Z:Print(L["%s est parti : %s sans soigneur prévu."]:format(Short(healer.name), Z.AssignDescribe(healer.groups, healer.players)))
			end
		end
	end
	if gone then Changed() end
end

Z:On("GROUP_ROSTER_UPDATE", RosterChanged)
Z:On("PLAYER_ENTERING_WORLD", RosterChanged)
-- Messages de nouveau permis : les nouveaux venus en attente reçoivent la répartition
Z:On("ADDON_RESTRICTION_STATE_CHANGED", function() C_Timer.After(1, SendPending) end)
Z:On("PLAYER_REGEN_ENABLED", SendPending)

----------------------------------------------------------------------------------------------------
-- /lyorune pourmoi [nom] : ajoute ou retire un joueur de mes joueurs (survolé, sinon ma cible)
----------------------------------------------------------------------------------------------------
function Z:AssignCommand(text)
	local L, name = Z.L, nil
	if text and text ~= "" then
		name = Z.CleanPinName(text)
	else
		local hovered = Z.hovered and Z.hovered:IsVisible() and Z.hovered.unit
		name = Z.UnitPinName(hovered) or Z.UnitPinName("target")
	end
	if not name then return Z:Print(L["aucun joueur : survolez sa case ou ciblez-le."]) end
	local added = not Z.db.assignPlayers[name]
	Z.db.assignPlayers[name] = added or nil
	Changed()
	Z:Print((added and L["%s fait partie de vos joueurs."] or L["%s ne fait plus partie de vos joueurs."]):format(name))
end

----------------------------------------------------------------------------------------------------
-- Fenêtre « Répartir les soigneurs » : une ligne par soigneur, une colonne par groupe de raid et par tank
----------------------------------------------------------------------------------------------------
local ROW_H, NAME_W, COL_W, MAX_TANKS = 24, 150, 30, 5

-- Les soigneurs du groupe (rôle choisi dans le jeu), et les tanks. Sans aucun rôle de soigneur : les classes qui soignent.
local HEALING_CLASSES = { PRIEST = true, PALADIN = true, DRUID = true, SHAMAN = true, MONK = true, EVOKER = true }

local function Roster()
	local healers, tanks, groups, byClass = {}, {}, {}, {}
	for key, member in pairs(Members()) do
		local role = UnitGroupRolesAssigned(member.unit)
		if issecret(role) then role = nil end
		local entry = { key = key, name = member.name, unit = member.unit }
		if role == "HEALER" then healers[#healers + 1] = entry end
		if role == "TANK" then tanks[#tanks + 1] = entry end
		local _, class = UnitClass(member.unit)
		if not issecret(class) and HEALING_CLASSES[class] then byClass[#byClass + 1] = entry end
		local group = UnitGroup(member.unit)
		if group then groups[group] = true end
	end
	if #healers == 0 then healers = byClass end
	local function byName(a, b) return a.name < b.name end
	table.sort(healers, byName)
	table.sort(tanks, byName)
	return healers, tanks, groups
end

local function HasLyorune()
	local set = {}
	for _, entry in ipairs(Z:SyncMembers()) do set[Key(entry.name)] = true end
	return set
end

local function Draft()
	-- La répartition en cours sert de départ ; sinon une page blanche
	local draft = {}
	local shared = Z.char.assignShared
	if shared then
		for key, healer in pairs(shared.healers) do
			draft[key] = { name = healer.name, groups = CopyTable(healer.groups), players = CopyTable(healer.players) }
		end
	end
	return draft
end

local function BuildWindow()
	local UI, L = Z.UI, Z.L
	local w = UI.Window("LyoruneAssign", L["Répartir les soigneurs"], 600, 300)
	w.help = UI.Label(w, 11, nil, "dim")
	w.help:SetPoint("TOPLEFT", 18, -44)
	w.help:SetWidth(564)
	w.help:SetJustifyH("LEFT")
	w.help:SetText(L["Cochez ce que chaque soigneur soigne, puis envoyez avant le combat : pendant un combat de boss, le jeu bloque les messages. Les soigneurs qui ont Lyorune (en vert) la voient tout de suite ; elle reste valable tout le combat."])
	w.heads, w.rows = {}, {}
	w.status = UI.Label(w, 11, nil, "dim")
	w.status:SetPoint("BOTTOMLEFT", 18, 48)
	w.status:SetWidth(560)
	w.status:SetJustifyH("LEFT")
	-- l'autre fenêtre de répartition, à un clic
	w.other = UI.Button(w, L["Répartir les buffs..."], 160, 26, function()
		w:Hide()
		Z:OpenBuffAssign()
	end)
	w.other:SetPoint("BOTTOMLEFT", 14, 14)
	w.other.label:SetJustifyH("CENTER")
	w.send = UI.Button(w, L["Envoyer au groupe"], 150, 26, function()
		local _, message = Z:AssignSend(w.draft)
		w.status:SetText(message)
	end)
	w.send:SetPoint("BOTTOMRIGHT", -14, 14)
	w.send.label:SetJustifyH("CENTER")
	w.clear = UI.Button(w, L["Effacer pour tous"], 130, 26, function()
		local _, message = Z:AssignClear()
		w.draft = {}
		w:Fill()
		w.status:SetText(message)
	end)
	w.clear:SetPoint("RIGHT", w.send, "LEFT", -6, 0)
	w.clear.label:SetJustifyH("CENTER")

	local function Head(i)
		local head = w.heads[i]
		if not head then
			head = UI.Label(w, 11, nil, "dim")
			head:SetWidth(COL_W + 20)
			head:SetJustifyH("CENTER")
			head:SetWordWrap(false)
			w.heads[i] = head
		end
		return head
	end

	-- Une case à cocher sans libellé, pour une colonne
	local function Box(row, i)
		local box = row.boxes[i]
		if not box then
			box = UI.Check(row, "", function() return row.Get(i) end, function(value) row.Set(i, value) end)
			box:SetSize(18, 18)
			row.boxes[i] = box
		end
		return box
	end

	function w:Fill()
		local healers, tanks, present = Roster()
		local columns = {}
		if IsInRaid() then
			for g = 1, 8 do if present[g] then columns[#columns + 1] = { group = g, label = L["G%d"]:format(g) } end end
		end
		for i = 1, math.min(#tanks, MAX_TANKS) do columns[#columns + 1] = { player = tanks[i].key, name = tanks[i].name, label = Short(tanks[i].name) } end
		local top = -44 - math.ceil(self.help:GetStringHeight()) - 12
		for _, head in ipairs(self.heads) do head:Hide() end
		for i, column in ipairs(columns) do
			local head = Head(i)
			head:ClearAllPoints()
			head:SetPoint("TOP", self, "TOPLEFT", 18 + NAME_W + (i - 0.5) * (COL_W + 6), top)
			head:SetWidth(column.player and COL_W + 30 or COL_W)
			head:SetText(column.label)
			head:Show()
		end
		local lyorune = HasLyorune()
		for _, row in ipairs(self.rows) do row:Hide() end
		for r, healer in ipairs(healers) do
			local row = self.rows[r]
			if not row then
				row = CreateFrame("Frame", nil, self)
				row:SetSize(NAME_W + MAX_TANKS * 40 + 8 * 36, ROW_H)
				row.name = UI.Label(row, 12)
				row.name:SetPoint("LEFT")
				row.name:SetWidth(NAME_W - 6)
				row.name:SetJustifyH("LEFT")
				row.name:SetWordWrap(false)
				row.boxes = {}
				self.rows[r] = row
			end
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 18, top - 18 - (r - 1) * ROW_H)
			row.name:SetText(Short(healer.name))
			if lyorune[healer.key] then row.name:SetTextColor(0.35, 0.90, 0.55) else row.name:SetTextColor(0.85, 0.85, 0.88) end
			row.Get = function(i)
				local column, part = columns[i], self.draft[healer.key]
				if not part then return false end
				if column.group then return part.groups[column.group] == true end
				for name in pairs(part.players) do if Key(name) == column.player then return true end end
				return false
			end
			row.Set = function(i, value)
				local column = columns[i]
				local part = self.draft[healer.key]
				if not part then
					part = { name = healer.name, groups = {}, players = {} }
					self.draft[healer.key] = part
				end
				if column.group then
					part.groups[column.group] = value or nil
				else
					for name in pairs(part.players) do if Key(name) == column.player then part.players[name] = nil end end
					if value then part.players[column.name] = true end
				end
			end
			for _, box in ipairs(row.boxes) do box:Hide() end
			for i in ipairs(columns) do
				local box = Box(row, i)
				box:ClearAllPoints()
				box:SetPoint("CENTER", row, "LEFT", NAME_W + (i - 0.5) * (COL_W + 6), 0)
				box:Update()
				box:Show()
			end
			row:Show()
		end
		self.empty = self.empty or UI.Label(self, 12, nil, "dim")
		self.empty:ClearAllPoints()
		self.empty:SetPoint("TOPLEFT", 18, top - 18)
		self.empty:SetText(#healers == 0 and L["Aucun soigneur dans le groupe."] or (#columns == 0 and L["Aucun groupe de raid ni tank à répartir."] or ""))
		self:SetHeight(-top + 18 + math.max(1, #healers) * ROW_H + 88)
		local can = MayShare("player")
		self.send:SetEnabled(can)
		self.clear:SetEnabled(can)
		self.status:SetText(can and "" or L["Seuls le chef du groupe et les assistants peuvent envoyer une répartition."])
	end
	return w
end

function Z:OpenAssign()
	if not IsInGroup() then return Z:Print(Z.L["vous n'êtes pas en groupe."]) end
	window = window or BuildWindow()
	window.draft = Draft()
	window:Fill()
	window:Show()
end
