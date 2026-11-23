-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - BuffMemory.lua : buffs manquants là où le jeu cache les buffs aux addons (champ de bataille, arène,
-- rencontre de boss), même hors combat.
-- Trois sources, de la plus sûre à la moins sûre :
--   1. un buff que le jeu laisse lisible (certains sorts ne sont jamais secrets) se lit directement, partout ;
--   2. le dernier état lu de chaque joueur, mis à jour à chaque lecture et photographié juste avant qu'une
--      restriction ne s'applique (le jeu prévient : état « Activating », les auras se lisent encore) ;
--   3. mes propres sorts réussis (clic sur une case, sur le panneau, macro, cible : tous), retenus pour leur durée.
-- Le tout par identifiant de joueur (en champ de bataille, l'ordre du raid change sans cesse), oublié à la mort
-- (au cimetière, le buff est proposé de nouveau) et gardé après un /reload. Un buff inconnu compte comme absent :
-- mieux vaut le proposer une fois de trop que jamais. Aucune boucle : Auras.lua relit une case à la fin d'un buff.
-- (HealKit retient ses sorts en champ de bataille et en arène seulement ; VuhDo lit seulement les buffs lisibles ;
-- HealBot ne lit rien de secret. Lyorune réunit les trois idées, à sa façon, partout où le jeu cache les buffs.)

local _, Z = ...
local issecret = Z.IsSecret

local DEFAULT_DURATION = 600 -- durée d'un buff jamais lu hors restriction : 10 minutes
local NO_END = 6 * 3600      -- un buff sans fin (aura de paladin) compte pour une soirée entière
local SENT_WINDOW = 15       -- un sort annoncé (UNIT_SPELLCAST_SENT) qui réussit plus tard ne compte plus

local seen = {}   -- seen[joueur][nom du buff] = fin (GetTime) : buffs de tout le monde
local mine = {}   -- mine[joueur][nom du buff] = fin : mes buffs (bénédictions, auras, buffs uniques)
local readable = {} -- readable[numéro] = vrai / faux : le jeu le laisse lisible maintenant (vidé à chaque restriction)

-- Le joueur, par son identifiant (sinon l'unité, quand l'identifiant est secret)
local function Key(unit)
	local ok, guid = pcall(UnitGUID, unit)
	if ok and guid and not issecret(guid) then return guid end
	return unit
end

local function Duration(name)
	local known = Z.db and Z.db.buffDurations and Z.db.buffDurations[name]
	return type(known) == "number" and known > 0 and known or DEFAULT_DURATION
end

-- Le jeu cache-t-il les buffs maintenant ? (combat, boss, match JcJ)
function Z.AurasHidden()
	local secret = C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret()
	if issecret(secret) then return true end
	return secret == true
end

-- Une restriction qui cache les buffs même hors combat est-elle en place (match JcJ, boss, clé) ? Là, une liste
-- d'auras vide ou sans secret ne prouve rien : selon la version, le jeu rend des noms secrets, une erreur ou une
-- liste vide (C15). Réponse secrète : on la prend pour une restriction.
-- Réponse gardée le temps d'une image : en champ de bataille, beaucoup de cases se relisent ensemble.
local RESTRICTING = { "Encounter", "ChallengeMode", "PvPMatch" }
local restrictedAt, restricted
function Z.AurasRestricted()
	local now = GetTime()
	if restrictedAt ~= now then
		restrictedAt, restricted = now, false
		for _, name in ipairs(RESTRICTING) do
			if Z.RestrictionActive(name) then restricted = true break end
		end
	end
	return restricted
end

-- Ce buff de ma liste reste-t-il lisible malgré la restriction ? Tous ses numéros doivent l'être : alors son
-- absence est sûre (il serait dans la liste du jeu, nom lisible).
function Z.BuffReadable(check)
	if not (C_Secrets and C_Secrets.ShouldSpellAuraBeSecret) then return false end
	for _, id in ipairs(check.ids or { check.id }) do
		local known = readable[id]
		if known == nil then
			local ok, secret = pcall(C_Secrets.ShouldSpellAuraBeSecret, id)
			known = ok and not issecret(secret) and secret == false
			readable[id] = known
		end
		if not known then return false end
	end
	return true
end

-- Durée vue sur une aura lisible : retenue pour les lieux où rien ne se lit (LyoruneDB, par nom du buff)
local function Learn(name, duration)
	if issecret(duration) or type(duration) ~= "number" or duration <= 0 then return end
	Z.db.buffDurations = Z.db.buffDurations or {}
	if Z.db.buffDurations[name] ~= duration then Z.db.buffDurations[name] = duration end
end

local function EndOf(aura)
	local expires = aura.expirationTime
	if issecret(expires) or type(expires) ~= "number" then return nil end
	if expires == 0 then return GetTime() + NO_END end
	return expires
end

-- Ce que la lecture d'une case vient de trouver (lisible) : names = noms suivis, list = auras du jeu.
-- own = vrai pour mes auras (filtre HELPFUL|PLAYER). Un nom suivi absent de la liste est effacé. Une liste dont un
-- nom est secret ne dit pas tout : la mémoire reste telle quelle.
function Z.NoteBuffs(unit, list, names, own)
	for i = 1, #list do
		if issecret(list[i].name) then return end
	end
	local key = Key(unit)
	local store = own and mine or seen
	local found = store[key]
	if found then
		for name in pairs(names) do found[name] = nil end
	end
	for i = 1, #list do
		local aura = list[i]
		local name = aura.name
		if not issecret(name) and names[name] then
			local ends = EndOf(aura)
			if ends then
				found = found or {}
				store[key] = found
				found[name] = math.max(found[name] or 0, ends)
				Learn(name, aura.duration)
			end
		end
	end
end

-- Secondes avant de proposer de nouveau ce buff d'après la mémoire (nil : rien de su). Même règle que la
-- lecture : ce qui reste, moins le seuil « buffRefresh », plafonné au quart de sa durée.
function Z.BuffMemoryLeft(unit, name, own, now, margin)
	local found = (own and mine or seen)[Key(unit)]
	local ends = found and found[name]
	if not ends then return nil end
	if margin > 0 then margin = math.min(margin, Duration(name) * 0.25) end
	return ends - now - margin
end

-- Mes buffs uniques retenus sur ce joueur (ceux qui durent encore), comme FindMyUniques : « nom,nom » ou nil
function Z.UniquesInMemory(unit)
	local found = mine[Key(unit)]
	if not found then return nil end
	local now, list = GetTime(), nil
	for _, check in ipairs(Z.uniqueChecks or {}) do
		local ends = found[check.name]
		if ends and ends > now then list = (list and list .. "," or "") .. check.name end
	end
	return list
end

-- Un joueur mort perd ses buffs : la mémoire aussi (appelé par Frames.lua, qui voit la mort même en combat)
function Z.ForgetBuffs(unit)
	local key = Key(unit)
	seen[key], mine[key] = nil, nil
end

----------------------------------------------------------------------------------------------------
-- Mes sorts réussis
----------------------------------------------------------------------------------------------------

-- Nom de buff de ma liste lancé : la ligne qui le suit, et s'il s'agit de la version de groupe ou d'un buff à moi
-- seul (bénédiction, aura, buff unique)
local function Watched(name)
	for _, check in ipairs(Z.buffChecks or {}) do
		if check.groupSpell == name then return check, true end
		if check.names[name] then return check, false, check.blessing or check.aura end
	end
	for _, check in ipairs(Z.uniqueChecks or {}) do
		if check.name == name then return check, false, true end
	end
end

-- Cases des joueurs à qui le buff revient : la cible, ou tout son groupe (vivants et à portée) pour la version de
-- groupe
local function Receivers(target, spell, group)
	if not group then return { target } end
	local units, sub = {}, Z.BuffSubGroup(target)
	for _, b in ipairs(Z.buttons or {}) do
		local unit = b.unit
		if unit and not b.extra and not b.dead and Z.BuffSubGroup(unit) == sub and not units[unit] then
			if unit == target or not Z.BuffAway(unit, spell) then
				units[unit] = true
				units[#units + 1] = unit
			end
		end
	end
	if #units == 0 then units[1] = target end
	return units
end

local function Remember(target, name)
	local _, group, own = Watched(name)
	local ends = GetTime() + Duration(name)
	for _, unit in ipairs(Receivers(target, name, group)) do
		local key = Key(unit)
		seen[key] = seen[key] or {}
		seen[key][name] = ends
		if own then
			mine[key] = mine[key] or {}
			mine[key][name] = ends
		end
		for _, b in ipairs(Z.buttons or {}) do
			if b.unit == unit then Z.QueueAuras(b) end
		end
		if unit == "player" and Z.hiddenSelf then Z.QueueAuras(Z.hiddenSelf) end
	end
	Z:QueueBuffPanel()
end

-- Joueur d'après le nom donné par le jeu (UNIT_SPELLCAST_SENT, parfois avec le royaume) : sa case
local function UnitNamed(target)
	if not target or issecret(target) or target == "" then return nil end
	local short = target:match("^[^-]+") or target
	local function Same(name) return name and not issecret(name) and (name == target or name == short) end
	if Same(UnitName("player")) then return "player" end
	for _, b in ipairs(Z.buttons or {}) do
		if b.unit and not b.extra and Same(UnitName(b.unit)) then return b.unit end
	end
end

local sent -- le dernier buff de ma liste annoncé : { name, unit, guid, at }

local function SpellName(id)
	if not id or issecret(id) then return nil end
	local name = C_Spell.GetSpellName(id)
	return name and not issecret(name) and name or nil
end

local castFrame = CreateFrame("Frame")
castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
castFrame:SetScript("OnEvent", function(_, event, ...)
	Z:Try("mémoire des buffs", function(...)
		if event == "UNIT_SPELLCAST_SENT" then
			local _, target, guid, id = ...
			local name = SpellName(id)
			local check = name and Watched(name)
			if not check then sent = nil return end
			-- sans nom de cible : le dernier clic sur un buff (Buffs.lua), sinon moi (sort sur soi, version de groupe)
			local unit = UnitNamed(target) or (Z.LastBuffTry and Z.LastBuffTry(name)) or "player"
			sent = { name = name, unit = unit, guid = guid, at = GetTime() }
		else
			local _, guid, id = ...
			local s = sent
			if not s or GetTime() - s.at > SENT_WINDOW or SpellName(id) ~= s.name then return end
			if guid and s.guid and not issecret(guid) and not issecret(s.guid) and guid ~= s.guid then return end
			sent = nil
			Remember(s.unit, s.name)
		end
	end, ...)
end)

----------------------------------------------------------------------------------------------------
-- Photo avant une restriction, message, /reload
----------------------------------------------------------------------------------------------------

-- Juste avant la restriction, tout se lit encore : l'état de chaque joueur est retenu (noms suivis : Data.lua,
-- Z.buffNames pour tout le monde, Z.ownNames pour mes bénédictions, auras et buffs uniques)
local function Snapshot()
	local all, own = Z.buffNames or {}, Z.ownNames or {}
	if not next(all) and not next(own) then return end
	local done = {}
	local function Read(unit)
		if done[unit] then return end
		done[unit] = true
		local ok, list = pcall(C_UnitAuras.GetUnitAuras, unit, "HELPFUL", 40)
		if ok and list then Z.NoteBuffs(unit, list, all, false) end
		if next(own) then
			local ok2, list2 = pcall(C_UnitAuras.GetUnitAuras, unit, "HELPFUL|PLAYER", 16)
			if ok2 and list2 then Z.NoteBuffs(unit, list2, own, true) end
		end
	end
	Read("player")
	for _, b in ipairs(Z.buttons or {}) do
		if b.unit and not b.extra and UnitExists(b.unit) then Read(b.unit) end
	end
end

local HIDING = {} -- restrictions qui cachent les buffs même hors combat
local told = {}   -- message déjà donné pour cette restriction

Z:On("ADDON_RESTRICTION_STATE_CHANGED", function(kind, state)
	local types, states = Enum.AddOnRestrictionType, Enum.AddOnRestrictionState
	if not (types and states) then return end
	if not next(HIDING) then
		for _, name in ipairs(RESTRICTING) do
			if types[name] then HIDING[types[name]] = name end
		end
	end
	wipe(readable) -- ce que le jeu laisse lire change avec chaque restriction, combat compris
	if not HIDING[kind] then return end
	if state == states.Activating then
		Snapshot()
		-- une fois par match ou par clé : dire pourquoi le panneau ne sait plus tout
		if HIDING[kind] ~= "Encounter" and not told[kind] and Z.db.buffPanel and #(Z.buffChecks or {}) > 0 then
			told[kind] = true
			Z:Print(Z.L["buffs cachés par le jeu ici : Lyorune retient vos propres buffs, pas ceux des autres joueurs."])
		end
	elseif state == states.Active or state == states.Inactive then
		-- en place : chaque case passe en mode mémoire (photo, mes sorts, inconnu = absent) ; finie : tout se relit
		if state == states.Inactive then told[kind] = nil end
		restrictedAt = nil
		for _, b in ipairs(Z.buttons or {}) do Z.QueueAuras(b) end
		if Z.hiddenSelf then Z.QueueAuras(Z.hiddenSelf) end
	end
end)

-- /reload en plein match : la mémoire passe de l'autre côté (l'horloge du jeu continue pendant un /reload ; un
-- redémarrage la remet à zéro, ce que l'heure réelle permet de voir)
Z:On("PLAYER_LOGOUT", function()
	if not Z.char then return end
	Z.char.buffMemory = (next(seen) or next(mine)) and { at = GetTime(), wall = time(), seen = seen, mine = mine } or nil
end)

Z:On("PLAYER_LOGIN", function()
	local saved = Z.char and Z.char.buffMemory
	if not saved then return end
	Z.char.buffMemory = nil
	if type(saved.at) ~= "number" or type(saved.wall) ~= "number" then return end
	if math.abs((GetTime() - saved.at) - (time() - saved.wall)) > 30 then return end
	local now = GetTime()
	for store, from in pairs({ [seen] = saved.seen, [mine] = saved.mine }) do
		for key, spells in pairs(type(from) == "table" and from or {}) do
			for name, ends in pairs(type(spells) == "table" and spells or {}) do
				if type(ends) == "number" and ends > now then
					store[key] = store[key] or {}
					store[key][name] = ends
				end
			end
		end
	end
end)

----------------------------------------------------------------------------------------------------
-- /lyorune buffs : ce que le jeu laisse lire ici, et ce que Lyorune retient
----------------------------------------------------------------------------------------------------
function Z:BuffsCommand()
	local L = Z.L
	local hidden = Z.AurasHidden()
	Z:Print(hidden and L["buffs : cachés par le jeu ici (mémoire de vos sorts)."] or L["buffs : lisibles ici."])
	local checks = {}
	for _, check in ipairs(Z.buffChecks or {}) do checks[#checks + 1] = check end
	for _, check in ipairs(Z.uniqueChecks or {}) do checks[#checks + 1] = check end
	if #checks == 0 then
		Z:Print(L["aucun buff de votre classe à surveiller."])
		return
	end
	for _, check in ipairs(checks) do
		local readableHere = not hidden or Z.BuffReadable(check)
		local known = Z.db.buffDurations and Z.db.buffDurations[check.spell]
		local duration = known and L["%d min"]:format(math.floor(known / 60 + 0.5)) or L["durée inconnue (10 min)"]
		Z:Print(("%s : %s, %s"):format(check.spell, readableHere and L["lisible"] or L["caché"], duration))
	end
	local players, now = 0, GetTime()
	for _, store in ipairs({ seen, mine }) do
		for _, spells in pairs(store) do
			for _, ends in pairs(spells) do
				if ends > now then players = players + 1 break end
			end
		end
	end
	Z:Print(L["mémoire : %d fiche(s) de joueur en cours."]:format(players))
	for _, line in ipairs(Z.BuffDiagnostic()) do Z:Print(line) end
	for _, line in ipairs(Z.BuffAssignReport and Z.BuffAssignReport() or {}) do Z:Print(line) end -- qui buffe qui
end

-- Détail pour un essai en champ de bataille (C15) : ce que dit le jeu, puis pourquoi un joueur manque au panneau
local function YesNo(value)
	if issecret(value) then return Z.L["secret"] end
	return value and Z.L["oui"] or Z.L["non"]
end

function Z.BuffDiagnostic()
	local L = Z.L
	local secret = C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret()
	local match = "?"
	if C_PvP and C_PvP.GetActiveMatchState then
		local ok, value = pcall(C_PvP.GetActiveMatchState)
		if ok and value ~= nil then match = issecret(value) and L["secret"] or tostring(value) end
	end
	local lines = { L["état : buffs cachés %s, restriction %s, match JcJ %s, partie %s, en combat %s."]:format(YesNo(secret),
		YesNo(Z.AurasRestricted()), YesNo(Z.InPvPMatch and Z.InPvPMatch()), match, YesNo(InCombatLockdown())) }
	local n = { players = 0, missing = 0, dead = 0, fighting = 0, away = 0, refused = 0, secret = 0, restricted = 0, name = 0, hidden = 0 }
	local done = {}
	for _, b in ipairs(Z.buttons or {}) do
		local unit = b.unit
		if unit and not b.extra and not done[unit] and UnitExists(unit) then
			done[unit] = true
			n.players = n.players + 1
			local name = UnitName(unit)
			if not name or issecret(name) then n.name = n.name + 1 end
			if n[b.buffRead or ""] then n[b.buffRead] = n[b.buffRead] + 1 end -- refused, secret, restricted
			if b.status then n.dead = n.dead + 1
			elseif not b:IsVisible() then n.hidden = n.hidden + 1
			elseif Z.BuffFighting and Z.BuffFighting(unit) then n.fighting = n.fighting + 1
			elseif b.missingBuff then
				n.missing = n.missing + 1
				if Z.BuffAway and Z.BuffAway(unit, b.missingBuff.spell) then n.away = n.away + 1 end
			end
		end
	end
	lines[#lines + 1] = L["cases : %d joueur(s), %d au panneau (dont %d hors de portée), %d mort(s), %d en combat, %d case(s) cachée(s)."]
		:format(n.players, n.missing, n.away, n.dead, n.fighting, n.hidden)
	lines[#lines + 1] = L["lecture : %d refusée(s), %d avec des noms secrets, %d lisible(s) mais sous restriction ; %d nom(s) de joueur secret(s)."]
		:format(n.refused, n.secret, n.restricted, n.name)
	return lines
end
