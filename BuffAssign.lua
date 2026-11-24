-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - BuffAssign.lua : qui buffe qui.
--   1. Mes groupes à buffer (réglage buffGroups, Mes buffs) : en raid, les buffs manquants ne sont proposés que
--      pour ces groupes. Tous au départ ; un bouton recopie mes groupes de soin (Assign.lua). Moi : toujours.
--   2. Bénédiction par type de joueur (réglage blessingPick, grille de Mes buffs, paladin) : une ligne par rôle
--      (tank, soigneur) puis par classe (Z.blessingSlots, Data.lua). Au départ : Z.blessingFor.
--   3. Plusieurs paladins, sans aucun message : hors combat, une bénédiction déjà posée par un autre paladin n'est
--      jamais reprise ; la suivante de la ligne du joueur est proposée. Marche aussi avec un paladin sans Lyorune.
--   4. Entente entre paladins qui ont Lyorune (réglage blessingSync) : chacun annonce sa bénédiction par type de
--      joueur, avant le combat. Deux paladins qui veulent la même : la priorité la plus haute la garde (imposée
--      par le chef, puis choisie, puis le départ), à égalité le premier nom dans l'ordre alphabétique ; l'autre
--      passe à la suivante. Une annonce reste valable sans aucun message jusqu'à la suivante ou au départ du joueur.
--   5. Répartition des buffs : le chef ou un assistant envoie à chacun ses groupes et, pour un paladin, la
--      bénédiction qu'il pose en premier (fenêtre « Répartir les buffs »), avec les règles de la répartition entre
--      soigneurs (réglage assignAccept, appliquée d'office, jamais pendant un blocage des messages).
-- Le jeu bloque les messages d'addon pendant un combat de boss ou un match JcJ : rien ne part
-- alors, tout attend la fin du blocage (ADDON_RESTRICTION_STATE_CHANGED, fin du combat).
--
-- Messages (préfixe « Lyorune », Comm.lua), 255 caractères au plus :
--   P:TANK=20217d,HEALER=19742p,WARRIOR=0p   mes bénédictions (d départ, p choisie, f imposée ; 0 : aucune)
--   P:-                                      je n'annonce plus rien      P:?   annoncez-vous (après mon /reload)
--   B:id:i:n:Nom-Royaume=13/19742            part i sur n : groupes 1 et 3, bénédiction imposée (0 : aucune)
--   B:id:0:0:                                répartition des buffs effacée

local _, Z = ...
local issecret = Z.IsSecret

local ANNOUNCE_GAP = 5  -- une annonce de mes bénédictions toutes les 5 secondes au plus
local MAX_BUFFERS = 16  -- joueurs dans une répartition des buffs, au plus
local PART_TIMEOUT = 30 -- une répartition incomplète est oubliée au bout de 30 secondes
local SEND_GAP = 3      -- un envoi de répartition au groupe toutes les 3 secondes au plus
local RANK = { d = 1, p = 2, f = 3 } -- priorité d'une annonce : départ, choisie, imposée par le chef

local claims = {}       -- annonces des autres paladins : clé du nom -> { name, slots = { [ligne] = { id, rank } } }
local announced         -- texte de ma dernière annonce envoyée
local announceAt, announceQueued = -ANNOUNCE_GAP, false
local incoming          -- répartition en cours de réception : { from, id, total, parts, count, started }
local pending = {}      -- nouveaux venus à qui envoyer la répartition dès que le jeu le permet
local lastSend = -SEND_GAP
local window

local function Key(name) return Z.CommKey(name) end
local function MyKey() return Key(UnitName("player")) end
local function Short(name) return Z.CommShort(name) end

-- Les buffs suivis changent pour tout le monde : chaque case relit les siens, le bloc et les repères suivent
local function Recheck()
	Z.buffGeneration = (Z.buffGeneration or 0) + 1
	for _, b in ipairs(Z.buttons or {}) do
		if b.unit and Z.QueueAuras then Z.QueueAuras(b) end
	end
	if Z.hiddenSelf and Z.QueueAuras then Z.QueueAuras(Z.hiddenSelf) end
	if Z.QueueBuffPanel then Z:QueueBuffPanel() end
end
Z.RecheckAllBuffs = Recheck

----------------------------------------------------------------------------------------------------
-- Ma part de la répartition des buffs
----------------------------------------------------------------------------------------------------
-- La répartition reçue, si elle compte : synchronisation et réglage allumés, et toujours en groupe
local function Shared()
	local shared = Z.char and Z.char.buffShared
	if not shared or not (Z.db.syncEnabled and Z.db.assignAccept) or not IsInGroup() then return nil end
	return shared
end
Z.BuffShared = Shared

local function MyPart()
	local shared = Shared()
	return shared and shared.buffers[MyKey()], shared
end

----------------------------------------------------------------------------------------------------
-- 1. Mes groupes à buffer
----------------------------------------------------------------------------------------------------
-- Groupes que je buffe : ceux de la répartition reçue si elle m'en donne, sinon mon choix. Renvoie un ensemble
-- (groupes[3] = true) et vrai quand il vient du chef.
function Z.BuffGroupsChoice()
	local part = MyPart()
	if part and next(part.groups) then return part.groups, true end
	local groups = {}
	for g = 1, 8 do groups[g] = Z.db.buffGroups[g] ~= false or nil end
	return groups, false
end

-- Ce joueur est-il dans un groupe que je buffe ? Hors raid, moi, ou groupe inconnu (réponse secrète) : oui.
function Z.BuffGroupOK(unit)
	if not unit or not IsInRaid() then return true end
	local part = MyPart()
	local chief = part and next(part.groups) and part.groups
	if not chief and not next(Z.db.buffGroups) then return true end -- tous les groupes : rien à lire
	local owner = unit:match("^raidpet(%d+)$") -- un familier suit le groupe de son maître
	local group = Z.UnitRaidGroup(owner and ("raid" .. owner) or unit)
	if group == nil then return true end
	if chief then return chief[group] == true end
	return Z.db.buffGroups[group] ~= false
end

-- Bouton « Comme mes soins » : mes groupes de soin (1.32.0) deviennent mes groupes à buffer
function Z.BuffGroupsLikeHealing()
	local groups = Z.AssignChoice and Z.AssignChoice() or Z.db.assignGroups
	if not next(groups) then return false end
	for g = 1, 8 do
		if groups[g] then Z.db.buffGroups[g] = nil else Z.db.buffGroups[g] = false end
	end
	Recheck()
	return true
end

----------------------------------------------------------------------------------------------------
-- 2. Bénédiction par type de joueur
----------------------------------------------------------------------------------------------------
-- Ligne de la grille d'un joueur : son rôle (tank, soigneur), sinon sa classe ; nil si rien n'est lisible
function Z.BlessingSlot(unit)
	local role = UnitGroupRolesAssigned(unit)
	if not issecret(role) and role == "TANK" then return role end
	-- (un soigneur a toujours de la mana : un rôle de soigneur sur une classe sans mana est une erreur du groupe)
	if not issecret(role) and role == "HEALER" and Z.UsesMana(unit) then return role end
	local class = select(2, UnitClass(unit))
	if class and not issecret(class) and Z.blessingSlotNames[class] then return class end
end

-- Départ d'une ligne de la grille : Z.blessingFor[ligne], sinon selon la mana de la classe
local function DefaultLine(slot, mana)
	if slot and Z.blessingFor[slot] then return Z.blessingFor[slot] end
	if slot == "HEALER" then return Z.blessingFor.MANA end
	if slot and slot ~= "TANK" then mana = not Z.classPower[slot] end
	return mana and Z.blessingFor.MANA or Z.blessingFor.OTHER
end

-- Le numéro choisi pour une ligne (grille), « nil » au départ, 0 pour aucune
function Z.BlessingPick(slot)
	local pick = slot and Z.db.blessingPick[slot]
	return type(pick) == "number" and pick or nil
end

-- Toutes les bénédictions que je connais pour cette ligne, dans l'ordre : imposée par le chef, choisie, départ,
-- puis les autres (sauf Sagesse à un joueur sans mana). Renvoie la liste et la priorité de la première (RANK).
-- Liste vide : « aucune » choisie.
local function Line(check, slot, mana)
	local part = MyPart()
	local forced = part and part.blessing ~= 0 and part.blessing or nil
	local pick = Z.BlessingPick(slot)
	if pick == 0 and not forced then return {}, nil end
	local order, rank = {}, forced and "f" or (pick and "p") or "d"
	if forced then order[1] = forced end
	if pick and pick ~= 0 then order[#order + 1] = pick end
	for _, id in ipairs(DefaultLine(slot, mana)) do order[#order + 1] = id end
	for _, choice in ipairs(check.choices) do order[#order + 1] = choice.id end
	local line, seen = {}, {}
	for _, id in ipairs(order) do
		-- (une bénédiction imposée ou choisie est gardée telle quelle ; Sagesse n'est écartée que du départ et de la suite)
		if not seen[id] and (mana or not Z.manaBlessings[id] or id == forced or id == pick) then
			seen[id] = true
			for _, choice in ipairs(check.choices) do
				if choice.id == id then line[#line + 1] = choice end
			end
		end
	end
	return line, rank
end

-- Mon annonce pour une ligne : la première bénédiction de ma ligne et sa priorité (nil : rien)
local function MyClaim(check, slot)
	local mana = slot == "HEALER" or (slot ~= "TANK" and not Z.classPower[slot])
	local line, rank = Line(check, slot, mana)
	return line[1] and line[1].id or 0, rank or "p"
end

-- Un autre paladin du groupe a-t-il annoncé cette bénédiction pour cette ligne, avec une priorité plus haute que
-- la mienne ? (À égalité : le premier nom dans l'ordre alphabétique la garde.)
local function Claimed(slot, id, mine, myRank)
	if not slot or not Z.db.blessingSync or not Z.db.syncEnabled or not next(claims) then return false end
	local me = MyKey()
	local ours = (mine == id) and RANK[myRank] or 0
	for key, claim in pairs(claims) do
		local theirs = claim.slots[slot]
		if theirs and theirs.id == id then
			local rank = RANK[theirs.rank] or 1
			if rank > ours or (rank == ours and key < me) then return true end
		end
	end
	return false
end

-- Bénédiction à poser sur ce joueur : { id, name, icon }, ou nil (aucune choisie, ou toutes déjà prises).
-- taken : noms des bénédictions qu'un autre paladin lui a déjà posées (lues hors combat, Auras.lua).
function Z.BlessingFor(check, unit, taken)
	local slot = Z.BlessingSlot(unit)
	local mana = Z.UsesMana(unit)
	local line, rank = Line(check, slot, mana)
	local first = line[1] and line[1].id
	for _, choice in ipairs(line) do
		if not (taken and taken[choice.name]) and not Claimed(slot, choice.id, first, rank) then return choice end
	end
end

----------------------------------------------------------------------------------------------------
-- 4. Entente entre paladins : annonces
----------------------------------------------------------------------------------------------------
local function BlessingCheck()
	for _, check in ipairs(Z.buffChecks or {}) do
		if check.blessing then return check end
	end
end

-- Mon annonce : « TANK=20217d,HEALER=19742p,... », ou nil (pas paladin, entente coupée, hors groupe)
local function AnnounceText()
	local check = BlessingCheck()
	if not check or not Z.db.blessingSync or not Z.db.syncEnabled or not IsInGroup() then return nil end
	local parts = {}
	for _, slot in ipairs(Z.blessingSlots) do
		local id, rank = MyClaim(check, slot)
		parts[#parts + 1] = slot .. "=" .. id .. rank
	end
	return table.concat(parts, ",")
end
Z.BlessingAnnounceText = AnnounceText -- pour les tests

local function Announce(force)
	announceQueued = false
	local text = AnnounceText()
	if not text then
		if announced and IsInGroup() and Z.CommSendGroup("P:-") then announced = nil end
		return
	end
	if text == announced and not force then return end
	local wait = ANNOUNCE_GAP - (GetTime() - announceAt)
	if wait > 0 or Z.CommLockdown() then
		-- trop tôt, ou messages bloqués : réessayé plus tard (fin du blocage : ADDON_RESTRICTION_STATE_CHANGED)
		if not announceQueued and wait > 0 then
			announceQueued = true
			C_Timer.After(wait + 0.1, function() Announce(force) end)
		end
		return
	end
	if Z.CommSendGroup("P:" .. text) then
		announced, announceAt = text, GetTime()
	end
end

-- Mes choix ont changé (grille, répartition reçue, groupe) : mon annonce suit
function Z.BlessingsChanged()
	Recheck()
	Announce()
end

local function Decode(body)
	local slots, count = {}, 0
	for slot, id, rank in body:gmatch("(%u+)=(%d+)([dpf])") do
		count = count + 1
		if count > 20 or not Z.blessingSlotNames[slot] or #id > 9 then return nil end
		slots[slot] = { id = tonumber(id), rank = rank }
	end
	return count > 0 and slots or nil
end

function Z.BlessingReceive(body, sender)
	if not Z.db.blessingSync or not Z.db.syncEnabled then return end
	local from = Key(sender)
	if from == MyKey() then return end
	local members = Z.AssignMembers()
	if not members[from] then return end
	if body == "?" then return Announce(true) end -- un paladin revenu (/reload) : il a besoin des annonces
	if body == "-" then
		if claims[from] then
			claims[from] = nil
			Recheck()
		end
		return
	end
	if #body > 250 then return end
	local slots = Decode(body)
	if not slots then return end
	claims[from] = { name = sender, slots = slots }
	Recheck()
end

-- Annonces lues : { nom court -> { ligne -> numéro } }, pour /lyorune buffs
function Z.BlessingClaims()
	return claims
end

----------------------------------------------------------------------------------------------------
-- 5. Répartition des buffs (chef ou assistant)
----------------------------------------------------------------------------------------------------
local NAME = "^[^%s:,/=%-]+%-[^%s:,/=%-]+$" -- « Nom-Royaume », sans espace ni séparateur

local function Encode(prefix, buffer)
	local numbers = {}
	for g = 1, 8 do if buffer.groups[g] then numbers[#numbers + 1] = g end end
	return prefix .. Key(buffer.name) .. "=" .. table.concat(numbers) .. "/" .. (buffer.blessing or 0)
end

local function DecodePart(body)
	local name, numbers, blessing = body:match("^([^=]+)=(%d*)/(%d+)$")
	if not name or #name > 60 or not name:match(NAME) or #numbers > 8 or #blessing > 9 then return nil end
	local buffer = { name = name, groups = {}, blessing = tonumber(blessing) }
	for digit in numbers:gmatch("%d") do
		local g = tonumber(digit)
		if g >= 1 and g <= 8 then buffer.groups[g] = true end
	end
	return buffer
end

local function SortedKeys(list)
	local keys = {}
	for key in pairs(list) do keys[#keys + 1] = key end
	table.sort(keys)
	return keys
end

local function SendParts(shared, target)
	local keys = SortedKeys(shared.buffers)
	for i, key in ipairs(keys) do
		local text = Encode(("B:%s:%d:%d:"):format(shared.id, i, #keys), shared.buffers[key])
		local ok
		if target then ok = Z.CommSend(text, "WHISPER", target) else ok = Z.CommSendGroup(text) end
		if not ok then return false end
	end
	return true
end

-- Ma part, en clair : « groupes 1 et 3, Bénédiction des rois »
local function Describe(buffer)
	local L = Z.L
	local text = next(buffer.groups) and Z.AssignDescribe(buffer.groups, {}) or L["tous les groupes"]
	if buffer.blessing and buffer.blessing ~= 0 then text = text .. ", " .. (Z.SpellName(buffer.blessing) or "#" .. buffer.blessing) end
	return text
end
Z.BuffAssignDescribe = Describe

local function Apply(shared, quiet)
	Z.char.buffShared = shared
	if not quiet then
		local L = Z.L
		local mine = shared.buffers[MyKey()]
		if mine then
			Z:Print(L["répartition des buffs de %s : vous buffez %s."]:format(shared.by, Describe(mine)))
		else
			Z:Print(L["répartition des buffs de %s reçue : elle ne vous nomme pas, votre choix reste."]:format(shared.by))
		end
	end
	Z.BlessingsChanged()
	if Z.RefreshBuffAssign then Z.RefreshBuffAssign() end
end

function Z.BuffAssignReceive(text, sender)
	if not Z.db.assignAccept or not Z.char then return end
	local id, index, total, body = text:match("^(%d+):(%d+):(%d+):(.*)$")
	if not id or #id > 6 then return end
	index, total = tonumber(index), tonumber(total)
	local from = Key(sender)
	if from == MyKey() then return end
	local member = Z.AssignMembers()[from]
	if not member or not Z.AssignMayShare(member.unit) then return end -- seulement le chef ou un assistant du groupe
	if total == 0 then
		local shared = Z.char.buffShared
		if shared and shared.from == from then
			Z.char.buffShared = nil
			Z:Print(Z.L["%s a effacé la répartition des buffs."]:format(Short(sender)))
			Z.BlessingsChanged()
		end
		return
	end
	if total > MAX_BUFFERS or index < 1 or index > total then return end
	local buffer = DecodePart(body)
	if not buffer then return end
	local now = GetTime()
	if not incoming or incoming.from ~= from or incoming.id ~= id or now - incoming.started > PART_TIMEOUT then
		incoming = { from = from, id = id, total = total, parts = {}, count = 0, started = now }
	end
	if incoming.total ~= total then return end
	if not incoming.parts[index] then incoming.count = incoming.count + 1 end
	incoming.parts[index] = buffer
	if incoming.count < total then return end
	local buffers = {}
	for _, part in pairs(incoming.parts) do buffers[Key(part.name)] = part end
	incoming = nil
	Apply({ from = from, by = Short(sender), id = id, buffers = buffers })
end

-- Un joueur qui a Lyorune arrive (Comm.lua) : mes annonces, et la répartition des buffs si c'est moi qui l'ai envoyée
function Z.BuffAssignNewMember(sender)
	Announce(true)
	local shared = Shared()
	if not shared or shared.from ~= MyKey() then return end
	if not SendParts(shared, sender) then pending[sender] = true end
end

local function SendPending()
	if announceQueued == false and AnnounceText() ~= announced then Announce() end
	local shared = Shared()
	if not shared or shared.from ~= MyKey() or Z.CommLockdown() then return end
	for sender in pairs(pending) do
		if not SendParts(shared, sender) then return end
		pending[sender] = nil
	end
end

-- buffers : clé -> { name, groups, blessing }. Ceux sans groupe ni bénédiction ne sont pas envoyés.
function Z:BuffAssignSend(buffers)
	local L = Z.L
	if not Z.db.syncEnabled then return false, L["La synchronisation entre joueurs est coupée (chapitre Profils et partage)."] end
	if not IsInGroup() then return false, L["Vous n'êtes pas en groupe."] end
	if not Z.AssignMayShare("player") then return false, L["Seuls le chef du groupe et les assistants peuvent envoyer une répartition."] end
	if Z.CommLockdown() then return false, L["Le jeu bloque les messages entre addons pendant un combat de boss ou un match JcJ : envoyez la répartition avant le combat."] end
	if GetTime() - lastSend < SEND_GAP then return false, L["Attendez quelques secondes avant de renvoyer."] end
	local kept = {}
	for key, buffer in pairs(buffers) do
		if next(buffer.groups) or (buffer.blessing or 0) ~= 0 then kept[key] = buffer end
	end
	local count = #SortedKeys(kept)
	if count == 0 then return false, L["Choisissez au moins un groupe ou une bénédiction."] end
	if count > MAX_BUFFERS then return false, L["%d joueurs au plus."]:format(MAX_BUFFERS) end
	local shared = { from = MyKey(), by = UnitName("player"), id = tostring(math.random(1000, 99999)), buffers = kept }
	lastSend = GetTime()
	if not SendParts(shared) then return false, L["Envoi impossible pour le moment (combat ou messages freinés par le jeu). Réessayez dans un instant."] end
	wipe(pending)
	Apply(shared, true)
	return true, L["Répartition des buffs envoyée : %d joueur(s). Ceux qui ont Lyorune la suivent tout de suite."]:format(count)
end

function Z:BuffAssignClear()
	local L = Z.L
	local shared = Z.char.buffShared
	if not shared then return true, L["Aucune répartition en cours."] end
	if shared.from == MyKey() and IsInGroup() then
		if Z.CommLockdown() or not Z.CommSendGroup(("B:%s:0:0:"):format(shared.id)) then
			return false, L["Le jeu bloque les messages entre addons pendant un combat de boss ou un match JcJ : envoyez la répartition avant le combat."]
		end
	end
	Z.char.buffShared = nil
	wipe(pending)
	Z.BlessingsChanged()
	return true, L["Répartition effacée."]
end

----------------------------------------------------------------------------------------------------
-- Le groupe change : un joueur part, ou je quitte le groupe
----------------------------------------------------------------------------------------------------
local function RosterChanged()
	if not Z.char then return end
	if not IsInGroup() then
		incoming, announced = nil, nil
		wipe(pending)
		local had = next(claims) ~= nil or Z.char.buffShared ~= nil
		wipe(claims)
		Z.char.buffShared = nil -- mon choix revient
		if had then Recheck() end
		return
	end
	local members, unsure = Z.AssignMembers()
	if unsure then return end -- un nom secret : on ne conclut à aucun départ
	local changed = false
	for key in pairs(claims) do
		if not members[key] then claims[key], changed = nil, true end
	end
	local shared = Z.char.buffShared
	if shared then
		for key, buffer in pairs(shared.buffers) do
			if not members[key] then
				shared.buffers[key], changed = nil, true
				if shared.from == MyKey() then
					Z:Print(Z.L["%s est parti : %s sans buffs prévus."]:format(Short(buffer.name), Describe(buffer)))
				end
			end
		end
	end
	if changed then Recheck() end
	Announce() -- (rien ne part si l'annonce n'a pas changé)
end

Z:OnRosterSettled(RosterChanged) -- une fois la rafale du groupe finie (Core.lua)
Z:On("PLAYER_ENTERING_WORLD", function()
	RosterChanged()
	-- après un /reload, les annonces des autres sont perdues : je les redemande (une fois, si le jeu le permet)
	if IsInGroup() and Z.db.blessingSync and Z.db.syncEnabled and BlessingCheck() and not Z.CommLockdown() then
		Z.CommSendGroup("P:?")
	end
end)
Z:On("ADDON_RESTRICTION_STATE_CHANGED", function() C_Timer.After(1, SendPending) end)
Z:On("PLAYER_REGEN_ENABLED", SendPending)

----------------------------------------------------------------------------------------------------
-- /lyorune buffs : qui buffe qui
----------------------------------------------------------------------------------------------------
function Z.BuffAssignReport()
	local L, lines = Z.L, {}
	if IsInRaid() then
		local groups, chief = Z.BuffGroupsChoice()
		local list = {}
		for g = 1, 8 do if groups[g] then list[#list + 1] = g end end
		lines[#lines + 1] = (chief and L["groupes buffés (répartition du chef) : %s."] or L["groupes buffés : %s."])
			:format(#list == 8 and L["tous"] or (#list == 0 and L["aucun"] or table.concat(list, ", ")))
	end
	local check = BlessingCheck()
	if check then
		local names = {}
		for _, claim in pairs(claims) do
			local parts = {}
			for _, slot in ipairs(Z.blessingSlots) do
				local theirs = claim.slots[slot]
				if theirs and theirs.id ~= 0 then
					parts[#parts + 1] = L[Z.blessingSlotNames[slot]] .. " " .. (Z.SpellName(theirs.id) or "#" .. theirs.id)
				end
			end
			names[#names + 1] = Short(claim.name) .. " (" .. (#parts > 0 and table.concat(parts, ", ") or L["aucune"]) .. ")"
		end
		table.sort(names)
		lines[#lines + 1] = #names > 0 and L["bénédictions annoncées : %s."]:format(table.concat(names, " ; "))
			or L["aucun autre paladin n'a annoncé ses bénédictions."]
	end
	return lines
end

----------------------------------------------------------------------------------------------------
-- Fenêtre « Répartir les buffs » : une ligne par joueur qui pose des buffs de groupe, une colonne par groupe
-- de raid ; pour un paladin, la bénédiction qu'il pose en premier (clic : la suivante)
----------------------------------------------------------------------------------------------------
local ROW_H, NAME_W, COL_W, BLESS_W = 24, 140, 30, 150

-- Classes dont un buff se pose aux autres (Data.lua : une ligne sans « self ») : prêtre, druide, mage, paladin
local function Buffers()
	local classes = {}
	for class, entries in pairs(Z.raidBuffs) do
		for _, entry in ipairs(entries) do
			if not entry.self then classes[class] = true end
		end
	end
	local list, groups = {}, {}
	for key, member in pairs(Z.AssignMembers()) do
		local _, class = UnitClass(member.unit)
		if class and not issecret(class) and classes[class] then
			list[#list + 1] = { key = key, name = member.name, paladin = class == "PALADIN" }
		end
		local group = Z.UnitRaidGroup(member.unit)
		if group then groups[group] = true end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list, groups
end

-- Bénédictions qu'un paladin peut recevoir à poser en premier : 0 (libre), puis celles de Data.lua
local function BlessingChoices()
	local list = { 0 }
	for _, entry in ipairs(Z.raidBuffs.PALADIN or {}) do
		for _, id in ipairs(entry.blessing or {}) do
			if Z.SpellName(id) then list[#list + 1] = id end
		end
	end
	return list
end

local function Draft()
	local draft = {}
	local shared = Z.char.buffShared
	if shared then
		for key, buffer in pairs(shared.buffers) do
			draft[key] = { name = buffer.name, groups = CopyTable(buffer.groups), blessing = buffer.blessing }
		end
	end
	return draft
end

local function BuildWindow()
	local UI, L = Z.UI, Z.L
	local w = UI.Window("LyoruneBuffAssign", L["Répartir les buffs"], 600, 300)
	w.help = UI.Label(w, 11, nil, "dim")
	w.help:SetPoint("TOPLEFT", 18, -44)
	w.help:SetWidth(564)
	w.help:SetJustifyH("LEFT")
	w.help:SetText(L["Cochez les groupes que chacun buffe et, pour un paladin, la bénédiction qu'il pose en premier (clic : la suivante). Envoyez avant le combat. Ceux qui ont Lyorune (en vert) la suivent tout de suite ; les paladins ne reprennent jamais la bénédiction d'un autre."])
	w.heads, w.rows = {}, {}
	w.status = UI.Label(w, 11, nil, "dim")
	w.status:SetPoint("BOTTOMLEFT", 18, 48)
	w.status:SetWidth(560)
	w.status:SetJustifyH("LEFT")
	-- l'autre fenêtre de répartition, à un clic
	w.other = UI.Button(w, L["Répartir les soigneurs..."], 160, 26, function()
		w:Hide()
		Z:OpenAssign()
	end)
	w.other:SetPoint("BOTTOMLEFT", 14, 14)
	w.other.label:SetJustifyH("CENTER")
	w.send = UI.Button(w, L["Envoyer au groupe"], 150, 26, function()
		local _, message = Z:BuffAssignSend(w.draft)
		w.status:SetText(message)
	end)
	w.send:SetPoint("BOTTOMRIGHT", -14, 14)
	w.send.label:SetJustifyH("CENTER")
	w.clear = UI.Button(w, L["Effacer pour tous"], 130, 26, function()
		local _, message = Z:BuffAssignClear()
		w.draft = {}
		w:Fill()
		w.status:SetText(message)
	end)
	w.clear:SetPoint("RIGHT", w.send, "LEFT", -6, 0)
	w.clear.label:SetJustifyH("CENTER")

	local function Part(row)
		local part = w.draft[row.buffer.key]
		if not part then
			part = { name = row.buffer.name, groups = {}, blessing = 0 }
			w.draft[row.buffer.key] = part
		end
		return part
	end

	function w:Fill()
		local buffers, present = Buffers()
		local columns = {}
		if IsInRaid() then
			for g = 1, 8 do if present[g] then columns[#columns + 1] = g end end
		end
		local top = -44 - math.ceil(self.help:GetStringHeight()) - 12
		for _, head in ipairs(self.heads) do head:Hide() end
		for i, g in ipairs(columns) do
			local head = self.heads[i]
			if not head then
				head = UI.Label(self, 11, nil, "dim")
				head:SetWidth(COL_W)
				head:SetJustifyH("CENTER")
				self.heads[i] = head
			end
			head:ClearAllPoints()
			head:SetPoint("TOP", self, "TOPLEFT", 18 + NAME_W + (i - 0.5) * (COL_W + 6), top)
			head:SetText(L["G%d"]:format(g))
			head:Show()
		end
		local lyorune = {}
		for _, entry in ipairs(Z:SyncMembers()) do lyorune[Key(entry.name)] = true end
		local choices = BlessingChoices()
		for _, row in ipairs(self.rows) do row:Hide() end
		for r, buffer in ipairs(buffers) do
			local row = self.rows[r]
			if not row then
				row = CreateFrame("Frame", nil, self)
				row:SetSize(564, ROW_H)
				row.name = UI.Label(row, 12)
				row.name:SetPoint("LEFT")
				row.name:SetWidth(NAME_W - 6)
				row.name:SetJustifyH("LEFT")
				row.name:SetWordWrap(false)
				row.boxes = {}
				row.bless = UI.Button(row, "", BLESS_W, 20, function()
					local part = Part(row)
					local at = 1
					for i, id in ipairs(choices) do if id == (part.blessing or 0) then at = i end end
					part.blessing = choices[at % #choices + 1]
					self:Fill()
				end)
				row.bless.label:SetJustifyH("CENTER")
				self.rows[r] = row
			end
			row.buffer = buffer
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 18, top - 18 - (r - 1) * ROW_H)
			row.name:SetText(Short(buffer.name))
			if lyorune[buffer.key] then row.name:SetTextColor(0.35, 0.90, 0.55) else row.name:SetTextColor(0.85, 0.85, 0.88) end
			row.columns = columns
			row.Get = function(g)
				local part = self.draft[buffer.key]
				return part ~= nil and part.groups[g] == true
			end
			row.Set = function(g, value) Part(row).groups[g] = value or nil end
			for _, box in ipairs(row.boxes) do box:Hide() end
			for i in ipairs(columns) do
				local box = row.boxes[i]
				if not box then
					box = UI.Check(row, "", function() return row.Get(row.columns[i]) end, function(value) row.Set(row.columns[i], value) end)
					box:SetSize(18, 18)
					row.boxes[i] = box
				end
				box:ClearAllPoints()
				box:SetPoint("CENTER", row, "LEFT", NAME_W + (i - 0.5) * (COL_W + 6), 0)
				box:Update()
				box:Show()
			end
			local part = self.draft[buffer.key]
			local blessing = part and part.blessing or 0
			row.bless:SetShown(buffer.paladin)
			row.bless:ClearAllPoints()
			row.bless:SetPoint("LEFT", row, "LEFT", NAME_W + #columns * (COL_W + 6) + 8, 0)
			row.bless.label:SetText(blessing == 0 and L["Bénédiction libre"] or (Z.SpellName(blessing) or "#" .. blessing))
			row:Show()
		end
		self.empty = self.empty or UI.Label(self, 12, nil, "dim")
		self.empty:ClearAllPoints()
		self.empty:SetPoint("TOPLEFT", 18, top - 18)
		self.empty:SetText(#buffers == 0 and L["Personne dans le groupe ne pose de buff de groupe (prêtre, druide, mage, paladin)."] or "")
		self:SetWidth(math.max(600, 36 + NAME_W + #columns * (COL_W + 6) + BLESS_W + 16))
		self:SetHeight(-top + 18 + math.max(1, #buffers) * ROW_H + 88)
		local can = Z.AssignMayShare("player")
		self.send:SetEnabled(can)
		self.clear:SetEnabled(can)
		self.status:SetText(can and "" or L["Seuls le chef du groupe et les assistants peuvent envoyer une répartition."])
	end
	return w
end

function Z:OpenBuffAssign()
	if not IsInGroup() then return Z:Print(Z.L["vous n'êtes pas en groupe."]) end
	window = window or BuildWindow()
	window.draft = Draft()
	window:Fill()
	window:Show()
end

function Z.RefreshBuffAssign()
	if window and window:IsShown() then
		window.draft = Draft()
		window:Fill()
	end
end
