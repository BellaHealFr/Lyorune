-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Comm.lua : messages invisibles entre joueurs qui utilisent Lyorune.
--   1. Version : chacun annonce sa version au groupe. Si un membre en a une plus récente, Lyorune le signale.
--   2. Configuration : envoyer sa configuration à un joueur précis, qui choisit de l'accepter ou non.
-- Les deux fonctions se coupent dans les options (onglet Profils). Rien n'est appliqué sans accord.

local _, Z = ...
local issecret = Z.IsSecret

local PREFIX = "Lyorune"
local CHUNK = 200             -- taille d'un morceau de configuration (un message d'addon est limité à 255 caractères)
local incoming = {}           -- configurations en cours de réception, par expéditeur
local newerSeen, lastAnnounce = false, -60
local prompt

local function Send(text, channel, target)
	if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return false end
	return pcall(C_ChatInfo.SendAddonMessage, PREFIX, text, channel, target)
end

-- "1.10.2" -> 11002, pour comparer deux versions
local function VersionNumber(text)
	local major, minor, patch = tostring(text):match("^(%d+)%.(%d+)%.?(%d*)")
	if not major then return 0 end
	return tonumber(major) * 10000 + tonumber(minor) * 100 + (tonumber(patch) or 0)
end
Z.VersionNumber = VersionNumber

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
		if db.versionNotice and not newerSeen and VersionNumber(version) > VersionNumber(Z.version) then
			newerSeen = true
			Z:Print((Z.L["une version plus récente de Lyorune existe (%s, vous avez %s)."]):format(version, Z.version))
		end
		return
	end

	local id, index, total, chunk = text:match("^C:(%d+):(%d+):(%d+):(.*)$")
	if id and db.acceptConfigs then
		index, total = tonumber(index), tonumber(total)
		if total < 1 or total > 40 or index < 1 or index > total then return end
		local transfer = incoming[sender]
		if not transfer or transfer.id ~= id then
			transfer = { id = id, parts = {}, count = 0 }
			incoming[sender] = transfer
		end
		if not transfer.parts[index] then
			transfer.parts[index] = chunk
			transfer.count = transfer.count + 1
		end
		if transfer.count == total then
			incoming[sender] = nil
			Ask(sender, table.concat(transfer.parts))
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
