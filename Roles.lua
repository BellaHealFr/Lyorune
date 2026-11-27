-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Roles.lua : le rôle montré pour chaque joueur (C43).
-- Sur WoW Forever, le jeu change le rôle du druide selon sa forme (ours : tank, félin : DPS) et la forme
-- normale ne le remet pas : un druide Restauration resté « DPS » après un passage en félin. Lyorune prend donc,
-- pour les classes de Z.talentRoles (Data.lua), le rôle de l'arbre de talents le plus rempli :
--   - le mien est lu dans mes talents, relu quand ils changent (jamais en combat : le jeu l'interdit) ;
--   - celui des autres arrive par un message invisible (Comm.lua), seulement s'ils ont Lyorune.
-- Arbre sans rôle fixe (Combat farouche), autre classe ou rien de connu : le rôle donné par le jeu.
-- Message (préfixe « Lyorune ») : T:H soigneur, T:D DPS, T:T tank, T:- aucun rôle tiré des talents.

local _, Z = ...
local issecret = Z.IsSecret


local LETTER = { HEALER = "H", DAMAGER = "D", TANK = "T" }
local FROM_LETTER = { H = "HEALER", D = "DAMAGER", T = "TANK" }
local MAX_ENTRIES = 80        -- jamais plus de rôles reçus en mémoire
local GATHER = 3              -- annonces demandées en rafale (arrivée dans un raid) : une seule, 3 secondes après
local RETRY = 10              -- annonce freinée hors combat : un nouvel essai 10 secondes après

local myRole, myGroup, mySpent -- mon rôle tiré des talents, le groupe de talents qui le donne, ses points
local myKey                   -- la clé de mon nom (Comm.lua), gardée une fois connue
local ready = false           -- mes talents ont été lus au moins une fois : rien n'est annoncé avant
local others, otherCount = {}, 0 -- clé du nom -> rôle annoncé (false : aucun rôle tiré des talents)
local sentRole = false        -- dernier rôle annoncé au groupe (false : rien encore)
local pending = false         -- annonce ratée (combat de boss, envoi freiné) : refaite plus tard
local gatherAt, retryAt = -60, -60 -- heure de la dernière annonce groupée, du dernier nouvel essai
local readAfterCombat = false

-- Le groupe de talents le plus rempli (C_Traits : les trois arbres de Forever sont des groupes d'un même arbre).
-- Rend lisible (vrai ou faux), puis le groupe et ses points. Sans aucun point : lisible, sans groupe.
-- Une réponse absente, mal formée ou secrète rend « illisible » : le rôle déjà connu est gardé.
local function BestGroup()
	local CT, TR = C_ClassTalents, C_Traits
	if not (CT and CT.GetActiveConfigID and TR and TR.GetConfigInfo and TR.GetGroupDisplayInfoByTreeID and TR.GetGroupCurrencyInfo) then return false end
	local ok, config = pcall(CT.GetActiveConfigID)
	if not ok or type(config) ~= "number" then return false end
	local okInfo, info = pcall(TR.GetConfigInfo, config)
	local tree = okInfo and type(info) == "table" and type(info.treeIDs) == "table" and info.treeIDs[1]
	if type(tree) ~= "number" then return false end
	local okGroups, groups = pcall(TR.GetGroupDisplayInfoByTreeID, tree)
	if not okGroups or type(groups) ~= "table" or not groups[1] then return false end
	local best, bestSpent = nil, 0
	for _, group in ipairs(groups) do
		local id = type(group) == "table" and group.groupID
		if type(id) ~= "number" then return false end
		local okSpent, currency = pcall(TR.GetGroupCurrencyInfo, config, { id })
		local entry = okSpent and type(currency) == "table" and currency[1]
		local list = type(entry) == "table" and entry.currencyInfos
		local spent = type(list) == "table" and type(list[1]) == "table" and list[1].spent
		if type(spent) ~= "number" or issecret(spent) then return false end
		if spent > bestSpent then best, bestSpent = id, spent end
	end
	return true, best, bestSpent
end

local function MyClassRoles()
	local _, class = UnitClass("player")
	return not issecret(class) and Z.talentRoles[class or ""] or nil
end

local function Refresh()
	if Z.RefreshRoles then Z.RefreshRoles() end -- Frames.lua : l'icône et ce qui dépend du rôle
end

-- Annonce de mon rôle au groupe, seulement s'il a changé depuis la dernière (force : nouveau venu dans le groupe).
-- Plusieurs annonces forcées en quelques secondes (arrivée dans un raid) n'en font qu'une.
local Announce
local function Send()
	if not ready or not Z.db.syncEnabled or not IsInGroup() or not MyClassRoles() or not Z.CommSendGroup then return end
	local role = myRole or "-"
	if Z.CommSendGroup("T:" .. (LETTER[role] or "-")) then
		sentRole, pending = role, false
		return
	end
	-- Freiné ou bloqué : un nouvel essai plus tard ; en combat, à la sortie du combat
	pending = true
	if GetTime() - retryAt >= RETRY and not InCombatLockdown() then
		retryAt = GetTime()
		C_Timer.After(RETRY, function() if pending then Announce(true) end end)
	end
end
Announce = function(force)
	if not force then
		if (myRole or "-") ~= sentRole then Send() end
		return
	end
	if GetTime() - gatherAt < GATHER then return end -- déjà prévue : elle partira avec l'état du moment
	gatherAt = GetTime()
	C_Timer.After(GATHER, Send)
end
Z.AnnounceTalentRole = Announce

-- Relit mes talents. Les événements de talents arrivent par paquets : une seule lecture, une seconde après.
-- En combat, le jeu interdit de changer de talents et peut cacher les points : lecture à la sortie du combat.
local timer
local function Read()
	timer = nil
	if InCombatLockdown() then readAfterCombat = true return end
	local roles = MyClassRoles()
	local readable, group, spent = false, nil, nil
	if roles then readable, group, spent = BestGroup() end
	if roles and not readable then return end -- illisible pour l'instant : le rôle connu reste, le prochain événement relira
	myGroup, mySpent = group, spent
	local role = roles and group and roles[group] or nil
	local first = not ready
	ready = true
	if role ~= myRole then
		myRole = role
		Refresh()
	end
	-- Première lecture : le groupe apprend mon rôle ; ensuite, seulement s'il change
	Announce(first)
end
local function ReadSoon()
	if timer then return end
	timer = true
	C_Timer.After(1, Read)
end
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED", "ACTIVE_COMBAT_CONFIG_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED" }) do
	Z:On(event, ReadSoon)
end
-- Sortie de combat : la lecture remise à plus tard, puis l'annonce ratée (combat de boss, match JcJ)
Z:On("PLAYER_REGEN_ENABLED", function()
	if readAfterCombat then readAfterCombat = false ReadSoon() end
	if pending then Announce(true) end
end)

-- Groupe stable : les rôles des joueurs partis sont oubliés (un druide qui revient en ayant changé de talents
-- ou sans Lyorune ne garde pas l'ancien), et une annonce ratée est refaite
Z:OnRosterSettled(function()
	if otherCount > 0 and Z.CommGroupKeys then
		local present = Z.CommGroupKeys()
		for key in pairs(others) do
			if not present[key] then others[key], otherCount = nil, otherCount - 1 end
		end
	end
	if pending then Announce(true) end
end)

-- Message reçu d'un membre du groupe (Comm.lua a déjà vérifié le préfixe, le débit et l'appartenance au groupe)
function Z.TalentRoleReceive(letter, sender)
	if not Z.CommKey or (letter ~= "-" and not FROM_LETTER[letter]) then return end
	local key = Z.CommKey(sender)
	local role = FROM_LETTER[letter] or false
	if others[key] == role then return end
	if others[key] == nil then
		if otherCount >= MAX_ENTRIES then wipe(others) otherCount = 0 end
		otherCount = otherCount + 1
	end
	others[key] = role
	Refresh()
end

-- Le rôle montré pour ce joueur : « TANK », « HEALER », « DAMAGER », « NONE », ou nil si le jeu le garde secret
function Z.UnitRole(unit)
	local game = UnitGroupRolesAssigned(unit)
	if issecret(game) then game = nil end
	if not Z.db.talentRole or (not myRole and otherCount == 0) or not Z.CommKey then return game end
	local name = GetUnitName(unit, true)
	if not name or issecret(name) then return game end
	local key = Z.CommKey(name)
	myKey = myKey or Z.CommKey(UnitName("player"))
	if key == myKey then return myRole or game end
	return others[key] or game
end

-- /lyorune role : ce que Lyorune sait de mon rôle, pour un essai en jeu
function Z:RoleCommand()
	local L = Z.L
	local game = UnitGroupRolesAssigned("player")
	game = issecret(game) and "?" or tostring(game)
	if not MyClassRoles() then
		return Z:Print((L["rôle du jeu : %s. Votre classe garde toujours le rôle donné par le jeu."]):format(game))
	end
	local readable, group, spent = BestGroup()
	if not readable then group, spent = L["illisible"], "?" end
	Z:Print((L["rôle du jeu : %s ; groupe de talents le plus rempli : %s (%s points) ; rôle tiré des talents : %s ; rôle montré : %s."]):format(
		game, tostring(group or "?"), tostring(spent or 0), tostring(myRole or L["aucun"]), tostring(Z.UnitRole("player") or "?")))
end
