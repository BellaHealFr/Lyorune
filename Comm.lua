-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Comm.lua : messages invisibles entre joueurs qui utilisent Lyorune (synchronisation, #29).
--   1. Version : chacun annonce sa version au groupe. On sait ainsi qui a Lyorune (/lyorune groupe), et si un
--      membre a une version plus récente, Lyorune le signale.
--   2. Configuration : envoyer sa configuration à un joueur précis, qui choisit de l'accepter ou non.
--   3. Qui relève qui : quand je commence une résurrection, le groupe le sait. Le nom du soigneur s'affiche sur
--      la case du mort, chez tous ceux qui ont Lyorune : deux soigneurs ne relèvent plus le même joueur.
-- Un interrupteur général coupe tout ; chaque fonction a aussi sa case (onglet Profils). Rien n'est appliqué
-- sans accord. Pendant un combat de boss, le jeu bloque ces messages : la synchronisation attend la fin.
--
-- Messages (préfixe « Lyorune ») :
--   V:1.17.0          ma version               C:id:n:total:morceau   un morceau de configuration
--   R:Nom-Royaume     je relève ce joueur      R:-  j'arrête          R:+  sort réussi, il doit accepter

local _, Z = ...
local issecret = Z.IsSecret

local PREFIX = "Lyorune"
local CHUNK = 200             -- taille d'un morceau de configuration (un message d'addon est limité à 255 caractères)
local TIMEOUT = 30            -- un envoi incomplet est oublié au bout de 30 secondes
local PER_SENDER = 60         -- une proposition par joueur et par minute, au plus
local ACCEPT_DELAY = 2        -- le bouton Importer s'active après 2 secondes : pas d'accord donné par mégarde
local REPLY_DELAY = 10        -- je réponds à un nouveau venu au plus une fois toutes les 10 secondes
local FLOOD, FLOOD_WINDOW, FLOOD_PAUSE = 50, 10, 30 -- plus de 50 messages en 10 s : expéditeur ignoré 30 s
local RES_CAST, RES_DONE = 15, 60 -- affichage d'une résurrection : pendant le sort, puis pendant l'attente de l'accord
local MAX_ENTRIES = 80        -- aucune liste en mémoire ne dépasse cette taille

local incoming = {}           -- configurations en cours de réception, par expéditeur
local lastOffer = {}          -- heure de la dernière proposition de chaque joueur
local newerVotes = {}         -- version plus récente annoncée -> joueurs qui l'ont annoncée
local members = {}            -- joueurs du groupe qui ont Lyorune : clé du nom -> { name, version }
local traffic, trafficSize = {}, 0 -- débit de chaque expéditeur
local rezzers, rezzerCount = {}, 0 -- clé du nom du mort -> { by = soigneur (nom court), from = clé du soigneur, ends, done }
local myRes                   -- ma résurrection en cours : { guid, key }
local newerSeen, lastAnnounce, lastReply = false, -60, -REPLY_DELAY
local prompt

local function Enabled() return Z.db.syncEnabled end

local function Send(text, channel, target)
	if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return false end
	return pcall(C_ChatInfo.SendAddonMessage, PREFIX, text, channel, target)
end

-- Groupe trouvé par l'outil de recherche (donjon, raid) : le canal d'instance ; sinon le groupe ou le raid.
-- Sert aussi aux annonces (Alerts.lua) : « PARTY » est refusé en silence dans un groupe d'instance.
local function GroupChannel()
	if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and not IsInGroup(LE_PARTY_CATEGORY_HOME) then
		return "INSTANCE_CHAT"
	end
	return IsInRaid() and "RAID" or "PARTY"
end
Z.GroupChannel = GroupChannel

local function SendGroup(text)
	if not IsInGroup() then return false end
	return Send(text, GroupChannel())
end

-- Nom complet « Nom-Royaume » (le jeu omet mon royaume), puis clé de comparaison sans espace ni apostrophe
local function Full(name)
	if name:find("-", 1, true) then return name end
	local realm = GetNormalizedRealmName and GetNormalizedRealmName()
	return realm and (name .. "-" .. realm) or name
end
local function Key(name) return (Full(name):gsub("[%s']", "")) end
local function Short(name) return name:match("^[^-]+") or name end

local function GroupUnits()
	local units = {}
	if IsInRaid() then
		for i = 1, 40 do units[#units + 1] = "raid" .. i end
	elseif IsInGroup() then
		for i = 1, 4 do units[#units + 1] = "party" .. i end
	end
	return units
end

-- Le nom de chaque membre du groupe (sauf moi), par clé
local function GroupKeys()
	local keys = {}
	for _, unit in ipairs(GroupUnits()) do
		local name = UnitExists(unit) and GetUnitName(unit, true)
		if name and not issecret(name) then keys[Key(name)] = name end
	end
	return keys
end

local function InGroup(sender)
	return GroupKeys()[Key(sender)] ~= nil
end

-- Débit : un expéditeur qui envoie trop de messages est ignoré un moment. La table ne grossit pas sans fin.
local function Flooding(sender, now)
	local t = traffic[sender]
	if not t then
		if trafficSize >= MAX_ENTRIES * 2 then wipe(traffic) trafficSize = 0 end
		t = { start = now, count = 0, muted = 0 }
		traffic[sender], trafficSize = t, trafficSize + 1
	end
	if now < t.muted then return true end
	if now - t.start > FLOOD_WINDOW then t.start, t.count = now, 0 end
	t.count = t.count + 1
	if t.count > FLOOD then
		t.muted = now + FLOOD_PAUSE
		return true
	end
	return false
end

local VersionNumber = Z.VersionNumber -- Core.lua

-- Une version annoncée par un autre joueur : format exact, et au plus une version majeure d'écart avec la mienne.
-- « V:99.0 » envoyé par un plaisantin ne fait donc rien croire.
local function Plausible(version)
	local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)$")
	if not major or #minor > 2 or #patch > 2 then return false end
	local mine = tonumber(Z.version:match("^(%d+)")) or 0
	return tonumber(major) <= mine + 1
end

local function AnnounceVersion()
	if not Enabled() or not IsInGroup() or GetTime() - lastAnnounce < 60 then return end
	lastAnnounce, lastReply = GetTime(), GetTime()
	SendGroup("V:" .. Z.version)
end

----------------------------------------------------------------------------------------------------
-- Joueurs du groupe qui ont Lyorune
----------------------------------------------------------------------------------------------------
-- Liste triée { name, version }, moi en premier. Seuls les joueurs encore dans le groupe y figurent.
function Z:SyncMembers()
	local list = { { name = UnitName("player"), version = Z.version } }
	local present = GroupKeys()
	local others = {}
	for key, entry in pairs(members) do
		if present[key] then others[#others + 1] = entry else members[key] = nil end
	end
	table.sort(others, function(a, b) return a.name < b.name end)
	for _, entry in ipairs(others) do list[#list + 1] = entry end
	return list
end

function Z:PrintSyncMembers()
	local L = Z.L
	if not Enabled() then return Z:Print(L["la synchronisation entre joueurs est coupée (chapitre Profils et partage)."]) end
	if not IsInGroup() then return Z:Print(L["vous n'êtes pas en groupe."]) end
	local parts = {}
	for _, entry in ipairs(Z:SyncMembers()) do parts[#parts + 1] = Short(entry.name) .. " (" .. entry.version .. ")" end
	Z:Print((L["avec Lyorune dans le groupe : %s."]):format(table.concat(parts, ", ")))
end

----------------------------------------------------------------------------------------------------
-- Qui relève qui
----------------------------------------------------------------------------------------------------
local function RefreshCells()
	if Z.RefreshResBy then Z.RefreshResBy() end
end

local function ExpireLater(delay)
	C_Timer.After(delay + 0.1, RefreshCells)
end

-- Le nom (court) du soigneur qui relève ce joueur, ou nil
function Z.ResBy(unit)
	if not (Z.db.syncEnabled and Z.db.resSync) or rezzerCount == 0 then return nil end
	local name = GetUnitName(unit, true)
	if not name or issecret(name) then return nil end
	local entry = rezzers[Key(name)]
	if entry and GetTime() < entry.ends then return entry.by end
end

-- Le joueur est debout : son entrée ne sert plus (s'il retombe, l'ancien nom ne doit pas revenir)
function Z.ClearResFor(unit)
	if rezzerCount == 0 then return end
	local name = GetUnitName(unit, true)
	if not name or issecret(name) then return end
	local key = Key(name)
	if rezzers[key] then rezzers[key], rezzerCount = nil, rezzerCount - 1 end
end

-- Les résurrections en cours d'un soigneur : arrêtées (« - ») ou réussies (« + »). Une résurrection réussie
-- reste affichée pendant que le joueur relevé décide d'accepter.
local function EndRes(from, success)
	local now = GetTime()
	for key, entry in pairs(rezzers) do
		if entry.from == from and not entry.done then
			if success then
				entry.done, entry.ends = true, now + RES_DONE
			else
				rezzers[key], rezzerCount = nil, rezzerCount - 1
			end
		end
	end
	if success then ExpireLater(RES_DONE) end
	RefreshCells()
end

local function StartRes(target, from, by)
	EndRes(from, false) -- un soigneur relève un seul joueur à la fois
	local key = Key(target)
	if not rezzers[key] and rezzerCount >= MAX_ENTRIES then
		-- liste pleine : les entrées périmées partent d'abord (un mort qui a quitté le groupe ne se relève
		-- jamais sous nos yeux, son entrée resterait sinon pour toujours)
		local now = GetTime()
		for old, entry in pairs(rezzers) do
			if now >= entry.ends then rezzers[old], rezzerCount = nil, rezzerCount - 1 end
		end
	end
	if not rezzers[key] then
		if rezzerCount >= MAX_ENTRIES then return end
		rezzerCount = rezzerCount + 1
	end
	rezzers[key] = { by = by, from = from, ends = GetTime() + RES_CAST }
	ExpireLater(RES_CAST)
	RefreshCells()
end

local resWatch = CreateFrame("Frame")
local function OnResEvent(event, a, b, c)
	if event == "UNIT_SPELLCAST_SENT" then -- a : cible, b : identifiant du sort lancé, c : sort
		if issecret(c) or not c or issecret(a) or not a or a == "" or issecret(b) or not b then return end
		local spell = C_Spell.GetSpellName(c)
		if not spell or not (Z.resNames and Z.resNames[spell]) then return end
		local me = UnitName("player")
		myRes = { guid = b }
		StartRes(a, Key(me), Short(me))
		SendGroup("R:" .. Full(a))
	elseif myRes and not issecret(a) and a == myRes.guid then -- a : identifiant du sort qui s'arrête ou réussit
		local success = event == "UNIT_SPELLCAST_SUCCEEDED"
		myRes = nil
		EndRes(Key(UnitName("player")), success)
		SendGroup(success and "R:+" or "R:-")
	end
end
resWatch:SetScript("OnEvent", function(_, event, _, a, b, c) Z:Try("qui relève qui", OnResEvent, event, a, b, c) end)

-- N'écoute mes sorts que si l'option est active
function Z:RefreshComm()
	resWatch:UnregisterAllEvents()
	if Z.db.syncEnabled and Z.db.resSync then
		for _, event in ipairs({ "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED" }) do
			pcall(resWatch.RegisterUnitEvent, resWatch, event, "player")
		end
	end
	RefreshCells()
end

----------------------------------------------------------------------------------------------------
-- Envoi de ma configuration à un joueur
----------------------------------------------------------------------------------------------------
function Z:SendConfig(target)
	local L = Z.L
	if not Enabled() then return false, L["La synchronisation entre joueurs est coupée (chapitre Profils et partage)."] end
	target = (target or ""):match("^%s*(.-)%s*$")
	if target == "" then return false, L["Indiquez le nom du joueur."] end
	local code = Z:Export()
	local total = math.ceil(#code / CHUNK)
	local id = math.random(1000, 9999)
	for i = 1, total do
		local ok = Send(("C:%d:%d:%d:%s"):format(id, i, total, code:sub((i - 1) * CHUNK + 1, i * CHUNK)), "WHISPER", target)
		if not ok then return false, L["Envoi impossible pour le moment (combat ou joueur introuvable)."] end
	end
	return true, (L["Configuration envoyée à %s. Il doit avoir Lyorune et l'accepter."]):format(target)
end

-- Un joueur que je connais : membre de mon groupe, de ma guilde, ou dans ma liste d'amis
local function Known(sender)
	if InGroup(sender) then return true end
	local short = Ambiguate and Ambiguate(sender, "none") or sender
	local ok, found = pcall(function()
		if C_GuildInfo and C_GuildInfo.MemberExistsByName and IsInGuild() and C_GuildInfo.MemberExistsByName(short) then return true end
		return C_FriendList and C_FriendList.GetFriendInfo and C_FriendList.GetFriendInfo(short) ~= nil
	end)
	return ok and found == true
end

-- Fenêtre « untel vous propose sa configuration »
local function Ask(sender, code)
	local UI, L = Z.UI, Z.L
	if not prompt then
		prompt = UI.Window("LyoruneConfigPrompt", L["Configuration reçue"], 380, 150)
		prompt:SetFrameStrata("FULLSCREEN_DIALOG")
		prompt.text = UI.Text(prompt, 12)
		prompt.text:SetPoint("TOPLEFT", 16, -46)
		prompt.text:SetWidth(348)
		prompt.text:SetJustifyH("LEFT")
		prompt.accept = UI.Button(prompt, L["Importer"], 110, 26, function()
			if GetTime() < prompt.readyAt then return end
			local _, message = Z:Import(prompt.code)
			Z:Print(message)
			prompt:Hide()
		end)
		prompt.accept:SetPoint("BOTTOMRIGHT", -14, 14)
		prompt.accept.label:SetJustifyH("CENTER")
		prompt.refuse = UI.Button(prompt, L["Refuser"], 110, 26, function() prompt:Hide() end)
		prompt.refuse:SetPoint("RIGHT", prompt.accept, "LEFT", -6, 0)
		prompt.refuse.label:SetJustifyH("CENTER")
	end
	prompt.code = code
	prompt.readyAt = GetTime() + ACCEPT_DELAY
	prompt.accept:SetEnabled(false)
	C_Timer.After(ACCEPT_DELAY, function() if prompt.code == code then prompt.accept:SetEnabled(true) end end)
	prompt.text:SetText((L["%s vous propose sa configuration Lyorune (apparence, clics, alertes). Votre configuration actuelle sera remplacée."]):format(sender))
	prompt:Show()
end

----------------------------------------------------------------------------------------------------
-- Réception
----------------------------------------------------------------------------------------------------
local function OnVersion(version, sender)
	local db = Z.db
	if not Plausible(version) then return end
	-- Un membre du groupe qui a Lyorune : noté. Un nouveau venu reçoit ma version en retour (une fois par
	-- 10 secondes au plus), pour qu'il me voie aussi dans sa liste.
	if InGroup(sender) then
		local key = Key(sender)
		local known = members[key]
		members[key] = { name = Full(sender), version = version } -- seulement des membres du groupe : 40 au plus
		if not known and GetTime() - lastReply >= REPLY_DELAY then
			lastReply = GetTime()
			SendGroup("V:" .. Z.version)
		end
	end

	if not db.versionNotice or newerSeen or VersionNumber(version) <= VersionNumber(Z.version) then return end
	-- Deux joueurs différents doivent annoncer la même version : un seul ne suffit pas à y croire
	local votes = newerVotes[version]
	if not votes then
		if #newerVotes >= 10 then return end -- pas de table qui grossit sans fin
		votes = { count = 0 }
		newerVotes[version], newerVotes[#newerVotes + 1] = votes, version
	end
	if not votes[sender] then
		votes[sender] = true
		votes.count = votes.count + 1
	end
	if votes.count >= 2 then
		newerSeen = true
		-- Le contenu d'une version future est inconnu de ce client, et un texte libre venu d'un autre joueur ne
		-- s'affiche jamais : l'avis donne donc la page officielle de cette version, où chaque nouveauté est décrite.
		Z:Print((Z.L["Lyorune %s est sortie (vous avez %s). Ce qu'elle apporte : github.com/BellaHealFr/Lyorune/releases/tag/v%s (seule source officielle). Après la mise à jour, la fenêtre des nouveautés détaille chaque changement en jeu."]):format(version, Z.version, version))
	end
end

local function OnRes(arg, sender)
	if not Z.db.resSync or not InGroup(sender) then return end
	local from = Key(sender)
	if arg == "-" or arg == "+" then return EndRes(from, arg == "+") end
	-- « Nom-Royaume », sans espace ni deux-points, d'une longueur raisonnable
	if #arg > 60 or not arg:match("^[^%s:%-]+%-[^%s:%-]+$") then return end
	StartRes(arg, from, Short(sender))
end

local function OnConfig(id, index, total, chunk, sender, now)
	index, total = tonumber(index), tonumber(total)
	if total < 1 or total > 40 or index < 1 or index > total or #chunk > CHUNK then return end
	for name, old in pairs(incoming) do -- envois restés incomplets : oubliés
		if now - old.started > TIMEOUT then incoming[name] = nil end
	end
	-- Fenêtre déjà ouverte : rien ne la remplace. Inconnu, ou proposition trop rapprochée : ignoré.
	if (prompt and prompt:IsShown()) or (lastOffer[sender] and now - lastOffer[sender] < PER_SENDER) or not Known(sender) then return end
	local transfer = incoming[sender]
	if not transfer or transfer.id ~= id then
		transfer = { id = id, parts = {}, count = 0, started = now }
		incoming[sender] = transfer
	end
	if not transfer.parts[index] then
		transfer.parts[index] = chunk
		transfer.count = transfer.count + 1
	end
	if transfer.count == total then
		incoming[sender] = nil
		lastOffer[sender] = now
		-- Nom et royaume, toujours : un homonyme d'un autre royaume ne peut pas se faire passer pour un ami
		Ask(Full(sender), table.concat(transfer.parts))
	end
end

local function OnMessage(prefix, text, _, sender)
	if prefix ~= PREFIX or issecret(text) or issecret(sender) or type(text) ~= "string" or type(sender) ~= "string" then return end
	if not Enabled() or sender == "" then return end
	local now = GetTime()
	if Flooding(sender, now) then return end

	local version = text:match("^V:([%d%.]+)$")
	if version then return OnVersion(version, sender) end

	local res = text:match("^R:(.+)$")
	if res then return OnRes(res, sender) end

	local id, index, total, chunk = text:match("^C:(%d+):(%d+):(%d+):(.*)$")
	if id and Z.db.acceptConfigs then OnConfig(id, index, total, chunk, sender, now) end
end

function Z:StartComm()
	Z:RefreshComm()
	if not (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix and C_ChatInfo.SendAddonMessage) then return end
	C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
	Z:On("CHAT_MSG_ADDON", OnMessage)
	Z:On("GROUP_ROSTER_UPDATE", AnnounceVersion)
	AnnounceVersion()
end
