-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Channels.lua : le canal des soigneurs, en français et en anglais (page « Les amis de Lyorune »).
-- Un lieu pour que les soigneurs échangent entre eux : façons de jouer, spécialisations, astuces, difficultés.
-- Deux cases indépendantes, éteintes au départ (channelFR, channelEN), ouvertes à tous quelle que soit la langue
-- du jeu. Cochée : Lyorune rejoint le canal du jeu « LyoruneFR » ou « LyoruneEN », comme la commande /join, sur la
-- fenêtre principale de discussion. Le joueur y écrit avec son numéro (/5 Bonjour), comme dans tout canal.
-- Lyorune n'y envoie jamais rien : l'affichage, /ignore et le signalement restent ceux du jeu.
--   * Lyorune ne quitte que le canal qu'il a rejoint lui-même sur ce personnage (Z.char.channels) : un canal
--     rejoint à la main n'est jamais touché. Les cases valent pour tout le compte, le canal suit chaque personnage
--     à sa connexion.
--   * À la connexion, le jeu remet lui-même ses canaux personnalisés, après l'entrée dans le monde : Lyorune attend
--     5 secondes avant de regarder, pour ne pas rejoindre en double ni changer les numéros des autres canaux.
--   * Un nom refusé à l'entrée (mot de passe posé par un inconnu, bannissement) : Lyorune passe au suivant
--     (LyoruneFR2, LyoruneFR3) et retient le nom refusé un jour, pour ne pas faire surgir chaque fois la demande de
--     mot de passe du jeu. Une demande restée sans réponse (dix canaux déjà rejoints...) est oubliée en 10 s.
--   * Le joueur quitte le canal lui-même (/leave) : la case se décoche, Lyorune ne le fait pas revenir.
-- Rien ne tourne en boucle : tout part d'un réglage changé, de la connexion ou d'un avis du canal.

local _, Z = ...
local L = Z.L
local issecret = Z.IsSecret

local KEYS = { FR = "channelFR", EN = "channelEN" }
local LABEL = { FR = "Canal en français", EN = "Canal en anglais" }
local NAMES = 3          -- LyoruneFR, LyoruneFR2, LyoruneFR3
local LOCK_FOR = 86400   -- un nom refusé est passé un jour
local SETTLE = 5         -- secondes laissées au jeu pour remettre ses canaux après l'entrée dans le monde
local ANSWER = 10        -- secondes d'attente d'une réponse du jeu à une demande

-- Noms de chaque langue, dans l'ordre, et la recherche inverse : « lyoruneen2 » -> { "EN", "LyoruneEN2" }
local NAMES_OF, BY_LOWER = {}, {}
for lang, base in pairs({ FR = "LyoruneFR", EN = "LyoruneEN" }) do
	NAMES_OF[lang] = {}
	for i = 1, NAMES do
		local name = base .. (i > 1 and i or "")
		NAMES_OF[lang][i] = name
		BY_LOWER[name:lower()] = { lang, name }
	end
end

local ready = false      -- le jeu a remis ses canaux : Lyorune peut regarder
local knocking = {}      -- nom demandé au jeu -> langue, en attente de sa réponse
local leaving = {}       -- nom que Lyorune quitte lui-même (pas un /leave du joueur), en minuscules

-- Langue et nom exact d'un de nos canaux (« 5. LyoruneFR2 » accepté), ou nil
local function LangOf(name)
	if type(name) ~= "string" or issecret(name) then return end
	local hit = BY_LOWER[name:gsub("^%d+%.%s*", ""):lower()]
	if hit then return hit[1], hit[2] end
end

-- Numéro du canal dans la discussion, ou nil si je n'y suis pas
local function Number(name)
	local id = GetChannelName(name)
	if type(id) == "number" and not issecret(id) and id > 0 then return id end
end

-- Le canal de cette langue où je suis déjà, quel que soit le nom de secours
local function Current(lang)
	for _, name in ipairs(NAMES_OF[lang]) do
		if Number(name) then return name end
	end
end

local function Locks()
	if type(Z.db.channelLocks) ~= "table" then Z.db.channelLocks = {} end
	return Z.db.channelLocks
end

-- Premier nom de cette langue qui ne m'a pas été refusé depuis un jour
local function Free(lang)
	local locks, now = Locks(), time()
	for _, name in ipairs(NAMES_OF[lang]) do
		local at = locks[name]
		if not at or now - at >= LOCK_FOR then
			locks[name] = nil
			return name
		end
	end
end

local function Changed() if Z.ChannelsChanged then Z.ChannelsChanged() end end -- page ouverte : l'état suit

local function Leave(name)
	if not (Number(name) and LeaveChannelByName) then return end
	leaving[name:lower()] = true
	pcall(LeaveChannelByName, name)
end

local function Join(lang)
	local name = Free(lang)
	if not name then
		Z:Print(L["%s : les trois noms du canal sont verrouillés par d'autres joueurs. Lyorune réessaiera demain."]:format(L[LABEL[lang]]))
		return
	end
	if knocking[name] then return end
	knocking[name] = lang
	local frame = DEFAULT_CHAT_FRAME
	pcall(JoinPermanentChannel, name, nil, frame and frame.GetID and frame:GetID() or 1, false)
	-- pas de réponse du jeu (dix canaux déjà rejoints, refus sans avis) : la demande est oubliée
	C_Timer.After(ANSWER, function()
		if not knocking[name] then return end
		knocking[name] = nil
		if Z.db[KEYS[lang]] and not Number(name) then
			Z:Print(L["%s : le jeu n'a pas ouvert le canal. Vous avez peut-être déjà dix canaux : quittez-en un, puis recochez la case."]:format(L[LABEL[lang]]))
		end
	end)
end

-- Cases cochées ou décochées : appelé à la connexion et après chaque réglage changé (Alerts.lua)
function Z:RefreshChannels()
	if not (ready and GetChannelName and JoinPermanentChannel) then return end
	local mine = Z.char.channels
	for lang, key in pairs(KEYS) do
		local current = Current(lang)
		if Z.db[key] then
			if current then mine[lang] = current else Join(lang) end
		elseif mine[lang] then
			Leave(mine[lang])
			mine[lang] = nil
		end
	end
	Changed()
end

-- Le jeu a remis ses canaux personnalisés un peu après l'entrée dans le monde : premier regard à ce moment
Z:On("PLAYER_ENTERING_WORLD", function()
	if ready then return end
	C_Timer.After(SETTLE, function()
		ready = true
		Z:RefreshChannels()
	end)
end)

-- Nom refusé à l'entrée : retenu un jour, puis le nom suivant
local function Refused(name, lang)
	knocking[name] = nil
	Locks()[name] = time()
	if Z.db[KEYS[lang]] then
		local nextName = Free(lang)
		if nextName then
			Z:Print(L["%s est verrouillé par un autre joueur : Lyorune passe à %s."]:format(name, nextName))
		end
		Join(lang)
	end
end

local function OnNotice(kind, _, _, _, _, _, _, _, baseName)
	if not Z.char or type(kind) ~= "string" or issecret(kind) then return end
	local lang, name = LangOf(baseName)
	if not lang then return end
	local mine = Z.char.channels
	if kind == "YOU_JOINED" or kind == "YOU_CHANGED" then
		local asked = knocking[name] ~= nil
		knocking[name] = nil
		if not (asked or Z.db[KEYS[lang]]) then
			-- remis par le jeu à la connexion alors que la case a été décochée (sur un autre personnage) : quitté
			if mine[lang] == name then
				Leave(name)
				mine[lang] = nil
			end
			return -- sinon rejoint à la main, case décochée : pas le nôtre
		end
		mine[lang] = name
		local number = Number(name)
		if asked then
			-- seulement à la demande : un canal retiré d'un onglet par le joueur n'y revient pas à chaque connexion
			local frame = DEFAULT_CHAT_FRAME
			if frame and frame.AddChannel then pcall(frame.AddChannel, frame, name) end
			if number then Z:Print(L["%s rejoint : écrivez /%d suivi de votre message."]:format(name, number)) end
		end
		Changed()
	elseif (kind == "WRONG_PASSWORD" or kind == "BANNED") and knocking[name] then
		Refused(name, lang)
	elseif kind == "YOU_LEFT" then
		if leaving[name:lower()] then
			leaving[name:lower()] = nil
		elseif mine[lang] == name then
			-- le joueur est parti de lui-même : la case suit, Lyorune ne le fait pas revenir
			mine[lang] = nil
			Z.db[KEYS[lang]] = false
			Z:Print(L["Vous avez quitté %s : la case « %s » est décochée."]:format(name, L[LABEL[lang]]))
			if Z.RefreshOptionPages then Z.RefreshOptionPages() end -- la case affichée se décoche aussi
		end
		Changed()
	end
end

Z:On("CHAT_MSG_CHANNEL_NOTICE", OnNotice)
-- Le jeu demande un mot de passe (sa propre fenêtre est déjà ouverte) : ce nom nous est fermé
Z:On("CHANNEL_PASSWORD_REQUEST", function(name)
	local lang, ours = LangOf(name)
	if lang and Z.char and knocking[ours] then Refused(ours, lang) end
end)

-- État pour la page : { FR = { name = "LyoruneFR", number = 5 } }, rien pour un canal où je ne suis pas
function Z.ChannelNumbers()
	local out = {}
	for lang in pairs(KEYS) do
		local name = Current(lang)
		if name then out[lang] = { name = name, number = Number(name) } end
	end
	return out
end
