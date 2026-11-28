-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Hots.lua : mes soins sur la durée (Z.hotSpells, Data.lua), pour les dessiner sur la barre de vie de
-- leur cible. Le jeu ne les compte pas dans ses soins en route : Lyorune retient lui-même
-- chaque lancement réussi, à qui il va, combien il rend et jusqu'à quand.
--   Qui le reçoit : le joueur nommé par le jeu, sinon la case cliquée, sinon moi (Z.CastReceiver, BuffMemory.lua).
--   Combien : appris par rang (chaque rang a son numéro sur WoW Forever), gardé par personnage, réappris à chaque
--   lancement hors combat (équipement changé : rien à effacer). Trois sources, de la plus sûre à la moins sûre :
--   la bulle d'aide du buff posé (soins en plus compris), les nombres de l'aura, la description du sort.
--   Jusqu'à quand : la vraie durée de l'aura quand elle se lit, sinon celle apprise, sinon celle de Data.lua.
--   Fin avant l'heure : hors combat, une aura partie du joueur (dissipée, consommée) est vue à son UNIT_AURA ; en
--   combat, Prompte guérison suit sa règle de Data.lua. Les 3 dernières secondes, le segment s'éclaircit.
--   Prière de guérison (« en attente ») : un seul porteur à la fois ; quand elle saute, son aura lisible arrivée sur
--   un autre joueur (sous ses numéros d'aura, Data.lua) la déplace. Sinon, en combat, elle est oubliée dès que son
--   porteur a pu la perdre.
--   Croissance sauvage : sur ma cible, et sur chaque autre joueur dont l'aura arrivée se lit (de moi, sûrement).
-- Aucune boucle : trois événements sur moi seulement, une lecture de l'aura juste après le lancement, un
-- minuteur par coup de soin et un pour les 3 dernières secondes, qui redessinent la barre de ce seul joueur
-- (Z.RedrawHots, Frames.lua).
-- Un soin oublié vaut mieux qu'un soin inventé : sans cible sûre ni montant connu, rien n'est retenu.

local _, Z = ...
local issecret = Z.IsSecret

local SENT_WINDOW = 10 -- un sort annoncé (UNIT_SPELLCAST_SENT) qui réussit plus tard ne compte plus (incantation)
local READ_DELAY = 0.3 -- l'aura est posée un peu après la réussite du sort
local TICK_LAG = 0.05  -- le segment descend juste après le coup, quand la vie l'a reçu
local ENDING = 3       -- les dernières secondes d'un soin, segment éclairci : à relancer
local GONE_AFTER = 0.5 -- une aura absente moins d'une demi-seconde après le lancement peut encore arriver
local SAME_CAST = 1    -- une aura arrivée moins d'une seconde avant ou après mon lancement : la même pose
local CHANNEL_LINK = 1.5 -- une canalisation change de numéro d'incantation sur WoW Forever : rattachée par le temps

local spells, builtFor -- spells[numéro de n'importe quel rang] = { entry = ligne de Z.hotSpells, name = nom }
                       -- (aura = true : un numéro de l'aura posée, pas du sort lancé)
local castOf = {}      -- castOf[numéro du premier rang] = numéro de mon dernier lancement annoncé de ce sort
local arriving         -- ma classe a un sort « pending » ou « group » : ses auras arrivées sont lues (Arrivals)
local active = {}      -- active[joueur][numéro du premier rang] = soin en cours (voir Remember)
local sent = {}        -- mes soins sur la durée annoncés, du plus ancien au plus récent : { id, spell, target, guid, at }
local channel          -- ma dernière canalisation retenue (Pénitence) : coupée, ses coups restants tombent
local prayer           -- ma Prière de guérison retenue : un seul porteur à la fois (le jeu n'en garde qu'une)
local listening = false -- réglage hotPrediction allumé (Z:RefreshHotPrediction)
local last             -- mon dernier soin sur la durée réussi : { name, target, unit } (/lyorune soins)
local heard = { sent = 0, done = 0 } -- mes sorts entendus depuis le chargement, et le dernier annoncé (/lyorune soins)

-- Numéros de mes soins sur la durée, tous rangs, vérifiés par leur nom (refaits quand mes sorts changent)
local function Spells()
	if spells and builtFor == Z.buffGeneration then return spells end
	builtFor, spells, arriving = Z.buffGeneration, {}, false
	for _, entry in ipairs(Z.hotSpells[Z.class] or {}) do
		local name = Z.SpellName(entry.id)
		if name then
			arriving = arriving or entry.kind == "pending" or entry.kind == "group"
			spells[entry.id] = { entry = entry, name = name }
			for id in pairs(Z.rankIds and Z.rankIds[name] or {}) do spells[id] = spells[id] or { entry = entry, name = name } end
			local function Add(list, aura)
				for _, id in ipairs(list or {}) do
					if Z.SpellName(id) == name then spells[id] = spells[id] or { entry = entry, name = name, aura = aura } end
				end
			end
			Add(entry.also) Add(entry.auras, true)
		end
	end
	return spells
end

local function SpellOf(id)
	if not id or issecret(id) then return nil end
	return Spells()[id]
end

-- Mes auras sur ce joueur, quand la liste se lit (sinon nil)
local function MyAuras(unit)
	local ok, list = pcall(C_UnitAuras.GetUnitAuras, unit, "HELPFUL|PLAYER", 40)
	if ok and type(list) == "table" and not issecret(list) then return list end
end

-- Cette aura vient-elle de ce sort ? (son numéro, ou un numéro d'aura du même sort : Prière de guérison)
local function SameSpell(id, entry)
	local spell = SpellOf(id)
	return spell ~= nil and spell.entry == entry
end

----------------------------------------------------------------------------------------------------
-- Montant appris
----------------------------------------------------------------------------------------------------

-- « 1 234 », « 1,234 », « 1.234 » : un seul nombre (espaces insécables du client français compris)
local function Joined(text)
	text = text:gsub("\194\160", " "):gsub("\226\128\175", " ")
	local done
	repeat text, done = text:gsub("(%d)[ ,%.](%d%d%d)%f[%D]", "%1%2") until done == 0
	return text
end

-- Soin total et durée lus dans un texte du jeu (bulle d'aide, description) : « 98 points de vie supplémentaires
-- en 21 sec », « 45 points de vie toutes les 3 sec pendant 15 sec », « Heals 45 damage every 3 seconds ».
-- Chaque nombre suivi de « s » (sec, secondes, seconds) est une durée, et le nombre juste avant lui un soin :
-- celui de l'intervalle est un soin par coup. every, duration : connus de Data.lua ou de l'aura (nil possible).
-- ticks : nombre de coups connu (une canalisation frappe aussi dès son début : Pénitence, 3 coups en 2 sec).
-- Rend total, durée (ou nil, nil).
function Z.HotFromText(text, every, duration, ticks)
	if type(text) ~= "string" or issecret(text) or text == "" then return nil end
	local found, amount, longest = {}, nil, nil
	for number, after in Joined(text):gmatch("(%d+)(%s*%a?)") do
		local n = tonumber(number)
		if after:find("^%s*s$") then
			if amount then found[#found + 1] = { amount = amount, seconds = n } amount = nil end
			if n ~= every and n > (longest or 0) then longest = n end
		else
			amount = n
		end
	end
	local length = duration or longest
	local tick, total, totalFor
	for _, pair in ipairs(found) do
		if every and pair.seconds == every then tick = tick or pair.amount
		elseif not total or pair.seconds == length then total, totalFor = pair.amount, pair.seconds end
	end
	if total and total > 0 then return total, length or totalFor end
	-- (ticks : nombre de coups connu, une canalisation frappe aussi dès son début)
	if tick and tick > 0 and length then return tick * (ticks or math.floor(length / every + 0.5)), length end
	return nil
end

-- Soin d'un sort qui attend (Prière de guérison) : « rend 800 points de vie la prochaine fois qu'elle subit des
-- dégâts, saute jusqu'à 5 fois, dure 30 sec ». Le plus grand nombre qui n'est pas une durée (le soin dépasse
-- toujours les sauts et les mètres), et la plus longue durée. Rend soin, durée (ou nil, nil).
function Z.PendingFromText(text)
	if type(text) ~= "string" or issecret(text) or text == "" then return nil end
	local amount, longest
	for number, after in Joined(text):gmatch("(%d+)(%s*%a?)") do
		local n = tonumber(number)
		if after:find("^%s*s$") then
			if n > (longest or 0) then longest = n end
		elseif n > (amount or 0) then
			amount = n
		end
	end
	if amount and amount > 0 then return amount, longest end
	return nil
end

-- Soin et durée lus dans un texte du jeu, selon la forme du sort
local function FromText(entry, text, duration)
	if entry.kind == "pending" then return Z.PendingFromText(text) end
	return Z.HotFromText(text, entry.every, duration, entry.kind == "channel" and entry.ticks or nil)
end

local function Learned(id)
	local store = Z.char and Z.char.hotAmounts
	local known = store and store[id]
	return type(known) == "table" and type(known.total) == "number" and known or nil
end

-- Retenu pour ce rang (source : "bulle", "aura" ou "texte"). La description ne sert qu'en l'absence de tout
-- montant appris (FromDescription) ; la bulle et l'aura se réapprennent à chaque lancement hors combat.
local function Learn(id, total, duration, source, ticks)
	if not (Z.char and total and total > 0) then return end
	Z.char.hotAmounts = Z.char.hotAmounts or {}
	local known = Learned(id)
	Z.char.hotAmounts[id] = { total = math.floor(total + 0.5), duration = duration or (known and known.duration), from = source,
		ticks = ticks } -- (une canalisation : les coups comptés, pour réapprendre si Data.lua change)
end

-- Nombre de soins d'un sort qui dure duration secondes
local function Ticks(entry, duration)
	if entry.ticks then return entry.ticks end
	if entry.every and duration then return math.max(1, math.floor(duration / entry.every + 0.5)) end
end

-- Premier coup : une canalisation frappe dès son début, un soin régulier après un intervalle
local function First(hot)
	return hot.entry.kind == "channel" and 0 or hot.entry.every
end

-- Moment du coup n° k (1 : le premier)
local function TickTime(hot, k)
	return hot.start + First(hot) + (k - 1) * hot.entry.every
end

-- Coups déjà tombés à cet instant (0 à ticks)
local function Done(hot, now)
	return math.max(0, math.min(hot.ticks, math.floor((now - hot.start - First(hot)) / hot.entry.every) + 1))
end

-- La description du sort, en secours (chargée à la demande par le jeu : vide la première fois, parfois)
local function FromDescription(id, entry)
	-- (une canalisation n'a pas d'aura à relire : son montant se réapprend si ses coups ont changé dans Data.lua)
	local known = Learned(id)
	if known and not (entry.kind == "channel" and known.from == "texte" and known.ticks ~= entry.ticks) then return end
	local ok, text = pcall(C_Spell.GetSpellDescription, id)
	if not ok or type(text) ~= "string" or issecret(text) or text == "" then
		if C_Spell.RequestLoadSpellData then pcall(C_Spell.RequestLoadSpellData, id) end
		return
	end
	local total, seconds = FromText(entry, text, entry.duration)
	Learn(id, total, seconds or entry.duration, "texte", entry.kind == "channel" and entry.ticks or nil)
end

local Restart -- (plus bas : redessin et minuteur des coups)

-- Numéro de l'aura posée, quand il se lit : en combat, il dit encore si elle est là (Still)
local function Instance(aura)
	local id = aura.auraInstanceID
	if id ~= nil and not issecret(id) then return id end
end

-- Mon aura vue sur le joueur : sa vraie durée, son vrai début, son numéro
local function Apply(hot, aura)
	hot.seen = true -- (Z.CheckHots : son départ pourra l'oublier)
	hot.instance = Instance(aura) or hot.instance
	local duration, expires = aura.duration, aura.expirationTime
	if not issecret(duration) and type(duration) == "number" and duration > 0 then
		hot.duration = duration
		if not issecret(expires) and type(expires) == "number" and expires > 0 then hot.start = expires - duration end
	end
	hot.ticks = Ticks(hot.entry, hot.duration)
end

-- Mon aura posée, lue hors combat : sa vraie durée, sa fin, la bulle d'aide puis ses nombres
-- Un soin relancé avant sa fin n'apprend rien : le jeu peut y reporter ce qui restait (durée plus longue, plus de
-- coups), ce n'est pas la valeur d'une pose neuve.
local function ReadAura(hot)
	if hot.refreshed or InCombatLockdown() or Z.AurasHidden() then return end
	local unit = hot.unit
	local list = MyAuras(unit)
	if not list then return end
	for _, aura in ipairs(list) do
		if not issecret(aura) and SameSpell(aura.spellId, hot.entry) then
			Apply(hot, aura)
			local total, source
			if C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID and not issecret(aura.auraInstanceID) then
				local okTip, tip = pcall(C_TooltipInfo.GetUnitBuffByAuraInstanceID, unit, aura.auraInstanceID, "HELPFUL|PLAYER")
				for _, line in ipairs(okTip and type(tip) == "table" and type(tip.lines) == "table" and tip.lines or {}) do
					total = FromText(hot.entry, line.leftText, hot.duration)
					if total then source = "bulle" break end
				end
			end
			-- nombres de l'aura : un soin par coup (soin régulier seulement : un sort mixte mêle les deux soins)
			local points = aura.points
			if not total and hot.entry.kind == "hot" and type(points) == "table" and not issecret(points) then
				local tick = points[1]
				local ticks = Ticks(hot.entry, hot.duration)
				if not issecret(tick) and type(tick) == "number" and tick > 0 and ticks then total, source = tick * ticks, "aura" end
			end
			if total then
				Learn(hot.id, total, hot.duration, source)
				local known = Learned(hot.id)
				hot.total = known and known.total
			elseif hot.duration then
				local known = Learned(hot.id)
				if known then known.duration = hot.duration end
			end
			Restart(hot) -- vraie durée, vrai début, vrai montant : la barre et les coups suivent
			return
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Mes lancements
----------------------------------------------------------------------------------------------------

-- La barre de vie de ce joueur se redessine (cases affichées seulement, Z.RedrawHots dans Frames.lua)
local function Changed(key)
	if Z.RedrawHots then Z.RedrawHots(key) end
end

local function Current(hot)
	local mine = active[hot.key]
	return mine and mine[hot.base] == hot
end

-- Un minuteur par coup, du coup k au dernier : après chacun, la barre descend d'un coup. Un soin relancé, relu ou
-- oublié arrête la suite (numéro de chaîne). Jamais plus de minuteurs que de coups : pas de boucle.
local function Schedule(hot, k, chain)
	if k > hot.ticks then return end
	C_Timer.After(math.max(0, TickTime(hot, k) - GetTime()) + TICK_LAG, function()
		if hot.chain ~= chain or not Current(hot) then return end
		Schedule(hot, k + 1, chain) -- (d'abord : une erreur de dessin n'arrête pas les coups suivants)
		Z:Try("soins sur la durée", Changed, hot.key)
	end)
end

-- Les 3 dernières secondes (une canalisation ne se relance pas : jamais)
local function Ending(hot, now)
	return hot.entry.kind ~= "channel" and hot.duration and now >= hot.start + hot.duration - ENDING or false
end

-- La barre de ce soin redessinée plus tard, s'il n'a été ni relancé ni oublié entre-temps
local function RedrawLater(hot, chain, delay)
	C_Timer.After(delay, function()
		if hot.chain == chain and Current(hot) then Z:Try("soins sur la durée", Changed, hot.key) end
	end)
end

function Restart(hot)
	hot.chain = (hot.chain or 0) + 1
	local chain, now = hot.chain, GetTime()
	if hot.ticks and hot.entry.every and hot.total then
		Schedule(hot, Done(hot, now) + 1, chain)
		if hot.duration and not Ending(hot, now) and hot.entry.kind ~= "channel" then
			RedrawLater(hot, chain, hot.start + hot.duration - ENDING - now)
		end
	end
	-- un soin en attente qui n'a pas sauté s'efface à sa fin (aucun coup ne redessine la barre)
	if hot.entry.kind == "pending" and hot.duration then
		RedrawLater(hot, chain, math.max(0, hot.start + hot.duration - now) + TICK_LAG)
	end
	Changed(hot.key)
end

-- Un de mes soins sur ce joueur est parti avant l'heure : oublié, sa barre redessinée
local function Drop(key, base)
	local mine = active[key]
	if not (mine and mine[base]) then return end
	mine[base] = nil
	if not next(mine) then active[key] = nil end
	Changed(key)
end

-- Un de mes soins sur la durée vient de réussir sur ce joueur : { id, base, entry, unit, guid, start, duration,
-- ticks, total } (total nil : montant encore inconnu, durée nil : inconnue). Un nouveau lancement du même sort
-- remplace l'ancien (rafraîchi par le jeu). aura : mon aura déjà vue sur lui (Landed), avec sa vraie durée.
local Purge -- (plus bas : oubli des soins finis, sur tous les joueurs)
local function Remember(unit, id, spell, aura)
	local entry = spell.entry
	Purge(GetTime()) -- (un joueur sans case, parti du groupe : ses soins finis ne restent pas)
	FromDescription(id, entry)
	local known = Learned(id)
	local duration = known and known.duration or entry.duration
	local key = Z.PlayerKey(unit)
	local hot = { id = id, base = entry.id, entry = entry, name = spell.name, unit = unit, key = key, start = GetTime(),
		duration = duration, ticks = Ticks(entry, duration), total = known and known.total,
		fought = InCombatLockdown() or nil } -- posé en combat : son aura n'a pas été lue (Consume)
	active[key] = active[key] or {}
	local before = active[key][entry.id]
	-- mon lancement qui réussit juste après son aura arrivée (Landed) : la même pose, déjà retenue
	if not aura and before and before.id == id and before.seen and hot.start - before.start < SAME_CAST then return end
	-- Prière de guérison arrivée puis déjà sautée avant la réussite de mon sort : elle est chez son nouveau porteur
	if not aura and entry.kind == "pending" and prayer and Current(prayer) and prayer.id == id and prayer.seen
		and hot.start - prayer.start < SAME_CAST then return end
	hot.refreshed = before and before.duration and hot.start < before.start + before.duration or nil
	hot.seen = hot.refreshed and before.seen or nil
	hot.instance = hot.refreshed and before.instance or nil -- (rafraîchie, son aura garde son numéro : Still en combat)
	if aura then Apply(hot, aura) end
	active[key][entry.id] = hot
	if entry.kind == "channel" then channel = hot end
	if entry.kind == "pending" then
		-- elle a sauté (ou je l'ai relancée ailleurs) : l'ancien porteur ne l'a plus
		if prayer and prayer.key ~= key and Current(prayer) then Drop(prayer.key, prayer.base) end
		prayer = hot
	end
	Restart(hot) -- (une relance remplace l'ancien : son minuteur s'arrête, le segment glisse à sa nouvelle taille)
	-- l'aura ne se lit que hors combat (ReadAura) : pas de minuteur en combat
	if not InCombatLockdown() then C_Timer.After(READ_DELAY, function() Z:Try("soins sur la durée", ReadAura, hot) end) end
end

-- Mes soins sur la durée en cours sur ce joueur (liste, ou nil). Un soin dont la durée est passée est oublié ;
-- un soin dont la durée reste inconnue (ni Data.lua, ni appris, ni lu sur l'aura) aussi : sans fin connue, il
-- resterait sur la barre pour toujours.
local function Over(hot, now)
	if not hot.duration then return now > hot.start + READ_DELAY + 1 end
	return now >= hot.start + hot.duration
end

-- Les soins finis de ce joueur (sa clé) oubliés : ceux qui restent (ou nil)
local function AliveKey(key, now)
	local mine = active[key]
	if not mine then return nil end
	for base, hot in pairs(mine) do
		if Over(hot, now) then mine[base] = nil end
	end
	if not next(mine) then active[key] = nil return nil end
	return mine
end
local function Alive(unit, now)
	return AliveKey(Z.PlayerKey(unit), now)
end

function Purge(now)
	for key in pairs(active) do AliveKey(key, now) end
end

function Z.MyHots(unit)
	local mine = Alive(unit, GetTime())
	if not mine then return nil end
	local list = {}
	for _, hot in pairs(mine) do list[#list + 1] = hot end
	return list
end

-- Un joueur mort perd mes soins (appelé par Z.ForgetBuffs, BuffMemory.lua)
function Z.ForgetHots(unit)
	local key = Z.PlayerKey(unit)
	if not active[key] then return end
	active[key] = nil
	Changed(key)
end

-- Ce que mes soins sur la durée vont encore rendre à ce joueur, et ce qu'en rendent les prochains coups (un par
-- soin). Montants appris, jamais secrets ; un soin au montant encore inconnu ne compte pas. Rend reste, prochains,
-- vrai si l'un d'eux est dans ses 3 dernières secondes (à relancer), et le soin qui attend que le joueur soit
-- touché (Prière de guérison, dessiné à part).
function Z.HotAmounts(unit)
	if not next(active) then return 0, 0, false, 0 end
	local now = GetTime()
	local mine = Alive(unit, now)
	if not mine then return 0, 0, false, 0 end
	local left, soon, ending, waiting = 0, 0, false, 0
	for _, hot in pairs(mine) do
		if hot.entry.kind == "pending" then
			waiting = waiting + (hot.total or 0)
		elseif hot.total and hot.ticks and hot.ticks > 0 and hot.entry.every then
			local remaining = hot.ticks - Done(hot, now)
			if remaining > 0 then
				local each = hot.total / hot.ticks
				left, soon = left + each * remaining, soon + each
				ending = ending or Ending(hot, now)
			end
		end
	end
	return left, soon, ending, waiting
end

-- Hors combat, à chaque UNIT_AURA de la case (Frames.lua) : un de mes soins dont l'aura n'est plus sur le joueur
-- (dissipé, consommé par Prompte guérison, même lancée par un autre druide) est oublié. Seulement quand le jeu dit
-- qu'une aura est partie, quand le joueur est en vue et que toutes ses auras se lisent : une aura illisible ne
-- prouve aucune absence (combat, auras cachées, restriction d'une rencontre ou d'un match : liste vide possible).
-- L'aura est reconnue par son numéro ou par son nom ; seul un soin dont l'aura a déjà été vue sur le joueur peut
-- être oublié (un talent dont l'aura porte un autre numéro et un autre nom ne fait donc rien oublier).
local function AurasUnsure()
	return InCombatLockdown() or Z.AurasHidden() or Z.AurasRestricted()
end

-- Mon aura arrivée sur ce joueur, lisible (de moi, sûrement) : Prière de guérison qui a sauté ici, Croissance
-- sauvage qui l'a touché. La même pose que mon lancement est seulement relue ; sinon, un soin neuf est retenu.
local function Landed(unit, id, spell, aura)
	-- une aura au numéro distinct du sort : le rang lancé (son montant appris), sinon le premier rang (jamais la
	-- description de l'aura, qui n'est pas celle du sort)
	if spell.aura then id = castOf[spell.entry.id] or spell.entry.id end
	local mine = active[Z.PlayerKey(unit)]
	local hot = mine and mine[spell.entry.id]
	if hot and hot.instance and hot.instance == Instance(aura) then return end -- (le joueur dans deux cases)
	if hot and hot.id == id and not hot.seen and GetTime() - hot.start < SAME_CAST then
		Apply(hot, aura)
		return Restart(hot)
	end
	Remember(unit, id, spell, aura)
end

local function Arrivals(unit, info)
	Spells()
	if not arriving then return end
	local added = type(info) == "table" and not issecret(info) and info.addedAuras
	if type(added) ~= "table" or issecret(added) then return end
	for _, aura in ipairs(added) do
		if type(aura) == "table" and not issecret(aura) then
			local spell = SpellOf(aura.spellId)
			local kind = spell and spell.entry.kind
			if (kind == "pending" and Z.db.hotPending or kind == "group") and Z.AuraFromMe(unit, aura) == true then
				Landed(unit, aura.spellId, spell, aura)
			end
		end
	end
end

-- Le jeu a-t-il pu retirer une aura de ce joueur ? (rien de lisible : oui)
local function MaybeRemoved(info)
	if type(info) ~= "table" or issecret(info) then return true end
	local full, removed = info.isFullUpdate, info.removedAuraInstanceIDs
	if issecret(full) or issecret(removed) or full then return true end
	return type(removed) == "table" and #removed > 0
end

-- Mon aura est-elle encore là ? Son numéro le dit même en combat ; numéro inconnu : rien de sûr
local function Still(unit, hot)
	local get = C_UnitAuras.GetAuraDataByAuraInstanceID
	if not (hot.instance and get) then return false end
	local ok, aura = pcall(get, unit, hot.instance)
	if not ok then return false end
	if issecret(aura) then return true end -- (une valeur secrète n'est jamais nil : l'aura est là)
	return type(aura) == "table"
end

function Z.CheckHots(unit, info)
	if not listening then return end
	Arrivals(unit, info)
	if not next(active) then return end
	local key = Z.PlayerKey(unit)
	local mine = active[key]
	if not mine then return end
	if AurasUnsure() then
		-- Prière de guérison saute quand son porteur est touché : s'il a pu la perdre, elle est oubliée
		local p = prayer
		if p and p.key == key and Current(p) and GetTime() - p.start > GONE_AFTER and MaybeRemoved(info)
			and not Still(unit, p) then Drop(key, p.base) end
		return
	end
	if not MaybeRemoved(info) then return end
	local visible = UnitIsVisible and UnitIsVisible(unit)
	if issecret(visible) or not visible then return end
	local list = MyAuras(unit)
	if not list then return end
	local present = {}
	for _, aura in ipairs(list) do
		if type(aura) ~= "table" or issecret(aura) or issecret(aura.spellId) or issecret(aura.name) then return end
		if aura.spellId then present[aura.spellId] = true end
		if aura.name then present[aura.name] = true end
	end
	local now = GetTime()
	for base, hot in pairs(mine) do
		if present[hot.id] or present[hot.name] then
			hot.seen = true
		elseif hot.seen and hot.entry.kind ~= "channel" and now - hot.start > GONE_AFTER then
			Drop(key, base)
		end
	end
end

-- Un sort qui consomme un de mes soins (Prompte guérison) a réussi sur ce joueur. Hors combat, Z.CheckHots voit
-- quelle aura est partie ; en combat (ou auras cachées), la règle de Data.lua choisit parmi mes soins retenus.
local function Consume(unit, entry)
	local mine = Alive(unit, GetTime())
	if not mine then return end
	-- hors combat, les auras se lisent : un soin visé encore là est vu (Z.CheckHots l'oubliera à son départ), un soin
	-- posé en combat et jamais vu dont l'aura est déjà partie est oublié ; la règle ne sert que si rien ne se lit
	local list = not AurasUnsure() and MyAuras(unit)
	if list then
		local present, readable = {}, true
		for _, aura in ipairs(list) do
			if type(aura) ~= "table" or issecret(aura) or issecret(aura.spellId) or issecret(aura.name) then readable = false break end
			local spell = SpellOf(aura.spellId)
			if spell then present[spell.entry.id] = true end
			if aura.name then present[aura.name] = true end
		end
		if readable then
			for _, base in ipairs(entry.takes or {}) do
				local hot = mine[base]
				if hot and (present[base] or present[hot.name]) then hot.seen = true
				elseif hot and hot.fought and not hot.seen then Drop(Z.PlayerKey(unit), base)
				end
			end
			return
		end
	end
	if not AurasUnsure() then
		local unseen = false
		for _, base in ipairs(entry.takes or {}) do
			local hot = mine[base]
			if hot and hot.seen then return end
			unseen = unseen or hot and hot.fought or false
		end
		if not unseen then return end
	end
	local pick, pickEnd
	for _, base in ipairs(entry.takes or {}) do
		local hot = mine[base]
		local ends = hot and hot.duration and hot.start + hot.duration
		if ends and (not pick or (entry.pick == "shortest" and ends < pickEnd)) then pick, pickEnd = base, ends end
	end
	if pick then Drop(Z.PlayerKey(unit), pick) end
end

-- Cible annoncée sans case ni clic : ma cible, quand le jeu dit qu'elle ne peut pas être aidée (un ennemi, un PNJ
-- qu'on ne soigne pas) ; le jeu lance alors mon soin sur moi. Lisible même en combat. Le nom annoncé doit être le
-- sien (Z.NameMatch : nom de famille ou royaume compris). Vu à l'annonce et à la réussite. Rend "player" ou nil.
local function OnUnhelpable(target)
	if not UnitCanAssist or issecret(target) or type(target) ~= "string" or target == "" then return nil end
	local helpable = UnitCanAssist("player", "target")
	if issecret(helpable) or helpable then return nil end
	-- son nom complet ; un seul nom connu : seulement l'annonce « Nom-Royaume » (jamais un prénom partagé)
	local found = Z.NameMatch(target, "target")
	if found == 2 or found == 1 and target:find("-", 1, true) and not target:find(" ", 1, true) then return "player" end
end

-- Sinon (cible illisible, sans clic) : le joueur sur qui mon aura de ce sort vient d'arriver, quand les auras se
-- lisent. Une seule lecture, juste après le lancement, des cases affichées et de moi ; un seul joueur trouvé, sinon
-- rien. Rend le joueur trouvé (ou nil).
local function Find(id, spell, at)
	if Z.AurasHidden() or Z.AurasRestricted() then return nil end
	local found, aura, count, checked = nil, nil, 0, {}
	local function Look(unit)
		local key = Z.PlayerKey(unit)
		if checked[key] then return end
		checked[key] = true
		local list = MyAuras(unit)
		if not list then return end
		for _, a in ipairs(list) do
			if type(a) == "table" and not issecret(a) and SameSpell(a.spellId, spell.entry) then
				local d, e = a.duration, a.expirationTime
				if not issecret(d) and not issecret(e) and type(d) == "number" and type(e) == "number" and d > 0
					and math.abs(e - d - at) < SAME_CAST then
					count, found, aura = count + 1, unit, a
				end
			end
		end
	end
	Look("player")
	for _, b in ipairs(Z.buttons or {}) do
		if b.unit and not b.extra then Look(b.unit) end
	end
	if count ~= 1 then return nil end
	Alive(found, GetTime()) -- (un soin fini n'est plus la même pose)
	Landed(found, id, spell, aura) -- (une aura déjà retenue n'est que relue)
	return found
end

local castFrame = CreateFrame("Frame")
castFrame:SetScript("OnEvent", function(_, event, ...)
	Z:Try("soins sur la durée", function(...)
		if event == "UNIT_SPELLCAST_CHANNEL_STOP" then
			-- canalisation finie ou coupée (j'ai bougé) : rien de plus ne tombera
			local hot = channel
			channel = nil
			local now = GetTime()
			if hot and hot.duration and now < hot.start + hot.duration then
				hot.duration = now - hot.start
				Changed(hot.key)
			end
		elseif event == "UNIT_SPELLCAST_SENT" then
			local _, target, guid, id = ...
			heard.sent, heard.id, heard.target = heard.sent + 1, id, target
			-- un autre sort annoncé (file d'attente du jeu pendant une incantation) n'efface pas le soin en cours
			local spell = SpellOf(id)
			if spell then
				castOf[spell.entry.id] = id
				if #sent >= 4 then table.remove(sent, 1) end
				sent[#sent + 1] = { id = id, spell = spell, target = target, guid = guid, at = GetTime(),
					unhelpable = not spell.entry.harms and OnUnhelpable(target) or nil } -- (ma cible doit le rester jusqu'à la réussite)
			end
		else
			local _, guid, id = ...
			heard.done = heard.done + 1
			local spell = SpellOf(id)
			if not spell then return end
			-- le plus récent du même sort, encore récent, au même numéro d'incantation quand les deux se lisent ;
			-- une canalisation (Pénitence) en change : annoncée il y a moins de 1,5 s, c'est elle
			local now, s, at = GetTime()
			local byTime = spell.entry.kind == "channel"
			for i = #sent, 1, -1 do
				if now - sent[i].at > SENT_WINDOW then table.remove(sent, i) end
			end
			-- (après la purge : l'index trouvé ne bouge plus)
			for i = #sent, 1, -1 do
				local c = sent[i]
				if c.spell.entry == spell.entry and (byTime and now - c.at < CHANNEL_LINK
					or not (guid and c.guid and not issecret(guid) and not issecret(c.guid) and guid ~= c.guid)) then
					s, at = c, i
					break
				end
			end
			if not s then return end
			table.remove(sent, at)
			castOf[spell.entry.id] = s.id -- (une annonce ratée entre-temps ne garde pas son rang)
			-- canalisation réussie : ses annonces plus anciennes ont échoué (un second « réussi » ne les reprend pas)
			if byTime then
				for i = #sent, 1, -1 do
					if sent[i].spell.entry == spell.entry and sent[i].at <= s.at then table.remove(sent, i) end
				end
			end
			-- la cible est retrouvée maintenant : la case cliquée est sûrement notée (Frames.lua)
			local unit = Z.CastReceiver(s.target, s.spell.name, s.at) or s.unhelpable and OnUnhelpable(s.target)
			if spell.entry.kind == "consume" then
				if unit then Consume(unit, spell.entry) end
				return
			end
			if spell.entry.kind == "pending" and not Z.db.hotPending then return end -- (réglage éteint : rien de suivi)
			local cast = { name = s.spell.name, target = s.target, unit = unit }
			last = cast
			-- sans joueur sûr : celui où mon aura arrive (Find), un peu plus tard
			if not unit then
				C_Timer.After(READ_DELAY, function()
					Z:Try("soins sur la durée", function()
						if listening then cast.unit = Find(s.id, s.spell, now) or false end
					end)
				end)
				return
			end
			Remember(unit, s.id, s.spell)
		end
	end, ...)
end)

-- Réglage hotPrediction (appelé par Z:Refresh) : éteint, Lyorune n'écoute plus rien et oublie mes soins
function Z:RefreshHotPrediction()
	-- Prière de guérison éteinte : celle en cours est oubliée
	if not Z.db.hotPending and prayer then
		if Current(prayer) then Drop(prayer.key, prayer.base) end
		prayer = nil
	end
	if (Z.db.hotPrediction or false) == listening then return end
	listening = Z.db.hotPrediction or false
	if listening then
		castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
		castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		castFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
	else
		castFrame:UnregisterAllEvents()
		active, sent, castOf, channel, prayer, last = {}, {}, {}, nil, nil, nil
	end
end

-- À la connexion et à chaque /reload, sans attendre un changement de réglage (Z:Refresh n'y passe pas toujours)
Z:On("PLAYER_LOGIN", function() Z:RefreshHotPrediction() end)

-- /lyorune soins : ce que Lyorune a appris et retient
function Z.HotReport()
	local lines, byEntry = {}, {}
	for id, spell in pairs(Spells()) do
		local known = Learned(id)
		if known then
			local ranks = byEntry[spell.entry] or {}
			byEntry[spell.entry] = ranks
			ranks[#ranks + 1] = ("%d : %d en %s s (%s)"):format(id, known.total, tostring(known.duration or "?"), known.from)
		end
	end
	for _, entry in ipairs(Z.hotSpells[Z.class] or {}) do
		local name = entry.kind ~= "consume" and Z.SpellName(entry.id)
		if name then
			local ranks = byEntry[entry] or {}
			table.sort(ranks)
			lines[#lines + 1] = ("soin sur la durée %s : %s"):format(name, #ranks > 0 and table.concat(ranks, ", ") or "montant pas encore appris")
		end
	end
	local count = 0
	for key in pairs(active) do
		for _ in pairs(active[key]) do count = count + 1 end
	end
	lines[#lines + 1] = ("soins sur la durée retenus en cours : %d"):format(count)
	local function Named(target)
		return issecret(target) and "secrète" or (target == nil or target == "") and "aucune" or tostring(target)
	end
	lines[#lines + 1] = ("mes sorts entendus : écoute %s, %d annoncés, %d réussis, dernier annoncé %s (soin sur la durée : %s), cible %s")
		:format(listening and "oui" or "non", heard.sent, heard.done, issecret(heard.id) and "secret" or heard.id and tostring(heard.id) or "aucun",
			SpellOf(heard.id) and "oui" or "non", Named(heard.target))
	local function Shown(value) return issecret(value) and "secret" or ("%s « %s »"):format(type(value), tostring(value)) end
	local first, second = UnitName("player")
	local full = GetUnitName and GetUnitName("player", true)
	local short, realm = UnitFullName and UnitFullName("player")
	lines[#lines + 1] = ("mon nom pour le jeu : UnitName %s / %s, GetUnitName %s, UnitFullName %s / %s")
		:format(Shown(first), Shown(second), Shown(full), Shown(short), Shown(realm))
	if last then
		local target = Named(last.target)
		local unit = last.unit
		unit = unit == false and "personne (aura introuvable)" or unit == nil and "en recherche" or unit
		lines[#lines + 1] = ("dernier soin sur la durée : %s, cible annoncée %s, retenu sur %s"):format(last.name, target, unit)
	end
	return lines
end
