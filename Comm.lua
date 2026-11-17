-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Comm.lua : messages invisibles entre joueurs qui utilisent Lyorune.
--   1. Version : chacun annonce sa version au groupe. Si un membre en a une plus récente, Lyorune le signale.
--   2. Configuration : envoyer sa configuration à un joueur précis, qui choisit de l'accepter ou non.
-- Les deux fonctions se coupent dans les options (onglet Profils). Rien n'est appliqué sans accord.

local _, Z = ...
local issecret = Z.IsSecret

local PREFIX = "Lyorune"
local CHUNK = 200             -- taille d'un morceau de configuration (un message d'addon est limité à 255 caractères)
local TIMEOUT = 30            -- un envoi incomplet est oublié au bout de 30 secondes
local PER_SENDER = 60         -- une proposition par joueur et par minute, au plus
local ACCEPT_DELAY = 2        -- le bouton Importer s'active après 2 secondes : pas d'accord donné par mégarde
local incoming = {}           -- configurations en cours de réception, par expéditeur
local lastOffer = {}          -- heure de la dernière proposition de chaque joueur
local newerVotes = {}         -- version plus récente annoncée -> joueurs qui l'ont annoncée
local newerSeen, lastAnnounce = false, -60
local prompt

local function Send(text, channel, target)
	if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return false end
	return pcall(C_ChatInfo.SendAddonMessage, PREFIX, text, channel, target)
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
	if not IsInGroup() or GetTime() - lastAnnounce < 60 then return end
	lastAnnounce = GetTime()
	Send("V:" .. Z.version, IsInRaid() and "RAID" or "PARTY")
end

----------------------------------------------------------------------------------------------------
-- Envoi de ma configuration à un joueur
----------------------------------------------------------------------------------------------------
function Z:SendConfig(target)
	local L = Z.L
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
	local short = Ambiguate and Ambiguate(sender, "none") or sender
	local units = {}
	if IsInRaid() then
		for i = 1, 40 do units[#units + 1] = "raid" .. i end
	elseif IsInGroup() then
		for i = 1, 4 do units[#units + 1] = "party" .. i end
	end
	for _, unit in ipairs(units) do
		local name = UnitExists(unit) and GetUnitName(unit, true)
		if name and not issecret(name) and (name == sender or name == short) then return true end
	end
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
local function OnMessage(prefix, text, _, sender)
	if prefix ~= PREFIX or issecret(text) or issecret(sender) or type(text) ~= "string" then return end
	local db = Z.db

	local version = text:match("^V:([%d%.]+)$")
	if version then
		if not db.versionNotice or newerSeen or not Plausible(version) or VersionNumber(version) <= VersionNumber(Z.version) then return end
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
			Z:Print((Z.L["une version plus récente de Lyorune existe (%s, vous avez %s). Téléchargez-la uniquement sur github.com/BellaHealFr/Lyorune."]):format(version, Z.version))
		end
		return
	end

	local id, index, total, chunk = text:match("^C:(%d+):(%d+):(%d+):(.*)$")
	if id and db.acceptConfigs then
		index, total = tonumber(index), tonumber(total)
		if total < 1 or total > 40 or index < 1 or index > total or #chunk > CHUNK then return end
		local now = GetTime()
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
			local realm = GetNormalizedRealmName and GetNormalizedRealmName()
			Ask((sender:find("-", 1, true) or not realm) and sender or (sender .. "-" .. realm), table.concat(transfer.parts))
		end
	end
end

function Z:StartComm()
	if not (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix and C_ChatInfo.SendAddonMessage) then return end
	C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
	Z:On("CHAT_MSG_ADDON", OnMessage)
	Z:On("GROUP_ROSTER_UPDATE", AnnounceVersion)
	AnnounceVersion()
end
