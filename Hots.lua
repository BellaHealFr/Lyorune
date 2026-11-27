-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Hots.lua : mes soins sur la durée (Z.hotSpells, Data.lua), pour les dessiner sur la barre de vie de
-- leur cible. Le jeu ne les compte pas dans ses soins en route : Lyorune retient lui-même
-- chaque lancement réussi, à qui il va, combien il rend et jusqu'à quand.
--   Qui le reçoit : le joueur nommé par le jeu, sinon la case cliquée, sinon moi (Z.CastReceiver, BuffMemory.lua).
--   Combien : appris par rang (chaque rang a son numéro sur WoW Forever), gardé par personnage, réappris à chaque
--   lancement hors combat (équipement changé : rien à effacer). Trois sources, de la plus sûre à la moins sûre :
--   la bulle d'aide du buff posé (soins en plus compris), les nombres de l'aura, la description du sort.
--   Jusqu'à quand : la vraie durée de l'aura quand elle se lit, sinon celle apprise, sinon celle de Data.lua.
-- Aucune boucle : trois événements sur moi seulement, une lecture de l'aura juste après le lancement, et un
-- minuteur par coup de soin, qui redessine la barre de ce seul joueur (Z.RedrawHots, Frames.lua).
-- Un soin oublié vaut mieux qu'un soin inventé : sans cible sûre ni montant connu, rien n'est retenu.

local _, Z = ...
local issecret = Z.IsSecret

local SENT_WINDOW = 10 -- un sort annoncé (UNIT_SPELLCAST_SENT) qui réussit plus tard ne compte plus (incantation)
local READ_DELAY = 0.3 -- l'aura est posée un peu après la réussite du sort
local TICK_LAG = 0.05  -- le segment descend juste après le coup, quand la vie l'a reçu

local spells, builtFor -- spells[numéro de n'importe quel rang] = { entry = ligne de Z.hotSpells, name = nom }
local active = {}      -- active[joueur][numéro du premier rang] = soin en cours (voir Remember)
local sent             -- le dernier de mes soins sur la durée annoncé : { id, spell, target, guid, at }
local channel          -- ma dernière canalisation retenue (Pénitence) : coupée, ses coups restants tombent

-- Numéros de mes soins sur la durée, tous rangs, vérifiés par leur nom (refaits quand mes sorts changent)
local function Spells()
	if spells and builtFor == Z.buffGeneration then return spells end
	builtFor, spells = Z.buffGeneration, {}
	for _, entry in ipairs(Z.hotSpells[Z.class] or {}) do
		local name = Z.SpellName(entry.id)
		if name then
			spells[entry.id] = { entry = entry, name = name }
			for id in pairs(Z.rankIds and Z.rankIds[name] or {}) do spells[id] = spells[id] or { entry = entry, name = name } end
			for _, id in ipairs(entry.also or {}) do
				if Z.SpellName(id) == name then spells[id] = spells[id] or { entry = entry, name = name } end
			end
		end
	end
	return spells
end

local function SpellOf(id)
	if not id or issecret(id) then return nil end
	return Spells()[id]
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
-- Rend total, durée (ou nil, nil).
function Z.HotFromText(text, every, duration)
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
	if tick and tick > 0 and length then return tick * math.floor(length / every + 0.5), length end
	return nil
end

local function Learned(id)
	local store = Z.char and Z.char.hotAmounts
	local known = store and store[id]
	return type(known) == "table" and type(known.total) == "number" and known or nil
end

-- Retenu pour ce rang (source : "bulle", "aura" ou "texte"). La description ne sert qu'en l'absence de tout
-- montant appris (FromDescription) ; la bulle et l'aura se réapprennent à chaque lancement hors combat.
local function Learn(id, total, duration, source)
	if not (Z.char and total and total > 0) then return end
	Z.char.hotAmounts = Z.char.hotAmounts or {}
	local known = Learned(id)
	Z.char.hotAmounts[id] = { total = math.floor(total + 0.5), duration = duration or (known and known.duration), from = source }
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
	if Learned(id) then return end
	local ok, text = pcall(C_Spell.GetSpellDescription, id)
	if not ok or type(text) ~= "string" or issecret(text) or text == "" then
		if C_Spell.RequestLoadSpellData then pcall(C_Spell.RequestLoadSpellData, id) end
		return
	end
	local total, seconds = Z.HotFromText(text, entry.every, entry.duration)
	Learn(id, total, seconds or entry.duration, "texte")
end

local Restart -- (plus bas : redessin et minuteur des coups)

-- Mon aura posée, lue hors combat : sa vraie durée, sa fin, la bulle d'aide puis ses nombres
-- Un soin relancé avant sa fin n'apprend rien : le jeu peut y reporter ce qui restait (durée plus longue, plus de
-- coups), ce n'est pas la valeur d'une pose neuve.
local function ReadAura(hot)
	if hot.refreshed or InCombatLockdown() or Z.AurasHidden() then return end
	local unit = hot.unit
	local ok, list = pcall(C_UnitAuras.GetUnitAuras, unit, "HELPFUL|PLAYER", 40)
	if not ok or type(list) ~= "table" or issecret(list) then return end
	for _, aura in ipairs(list) do
		if not issecret(aura) and not issecret(aura.spellId) and aura.spellId == hot.id then
			local duration, expires = aura.duration, aura.expirationTime
			if not issecret(duration) and type(duration) == "number" and duration > 0 then
				hot.duration = duration
				if not issecret(expires) and type(expires) == "number" and expires > 0 then hot.start = expires - duration end
			end
			local total, source
			if C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID and not issecret(aura.auraInstanceID) then
				local okTip, tip = pcall(C_TooltipInfo.GetUnitBuffByAuraInstanceID, unit, aura.auraInstanceID, "HELPFUL|PLAYER")
				for _, line in ipairs(okTip and type(tip) == "table" and type(tip.lines) == "table" and tip.lines or {}) do
					total = Z.HotFromText(line.leftText, hot.entry.every, hot.duration)
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
			hot.ticks = Ticks(hot.entry, hot.duration)
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

function Restart(hot)
	hot.chain = (hot.chain or 0) + 1
	if hot.ticks and hot.entry.every and hot.total then Schedule(hot, Done(hot, GetTime()) + 1, hot.chain) end
	Changed(hot.key)
end

-- Un de mes soins sur la durée vient de réussir sur ce joueur : { id, base, entry, unit, guid, start, duration,
-- ticks, total } (total nil : montant encore inconnu, durée nil : inconnue). Un nouveau lancement du même sort
-- remplace l'ancien (rafraîchi par le jeu).
local function Remember(unit, id, spell)
	local entry = spell.entry
	FromDescription(id, entry)
	local known = Learned(id)
	local duration = known and known.duration or entry.duration
	local key = Z.PlayerKey(unit)
	local hot = { id = id, base = entry.id, entry = entry, unit = unit, key = key, start = GetTime(), duration = duration,
		ticks = Ticks(entry, duration), total = known and known.total }
	active[key] = active[key] or {}
	local before = active[key][entry.id]
	hot.refreshed = before and before.duration and hot.start < before.start + before.duration or nil
	active[key][entry.id] = hot
	if entry.kind == "channel" then channel = hot end
	Restart(hot) -- (une relance remplace l'ancien : son minuteur s'arrête, le segment glisse à sa nouvelle taille)
	-- l'aura ne se lit que hors combat (ReadAura) : pas de minuteur en combat
	if not InCombatLockdown() then C_Timer.After(READ_DELAY, function() Z:Try("soins sur la durée", ReadAura, hot) end) end
end

-- Mes soins sur la durée en cours sur ce joueur (liste, ou nil). Un soin dont la durée est passée est oublié ;
-- un soin dont la durée reste inconnue (ni Data.lua, ni appris, ni lu sur l'aura) aussi : sans fin connue, il
-- resterait sur la barre pour toujours.
local function Alive(unit, now)
	local key = Z.PlayerKey(unit)
	local mine = active[key]
	if not mine then return nil end
	for base, hot in pairs(mine) do
		if not hot.duration then
			if now > hot.start + READ_DELAY + 1 then mine[base] = nil end
		elseif now >= hot.start + hot.duration then mine[base] = nil
		end
	end
	if not next(mine) then active[key] = nil return nil end
	return mine
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
-- soin). Montants appris, jamais secrets ; un soin au montant encore inconnu ne compte pas. Rend reste, prochains.
function Z.HotAmounts(unit)
	local now = GetTime()
	local mine = Alive(unit, now)
	if not mine then return 0, 0 end
	local left, soon = 0, 0
	for _, hot in pairs(mine) do
		if hot.total and hot.ticks and hot.ticks > 0 and hot.entry.every then
			local remaining = hot.ticks - Done(hot, now)
			if remaining > 0 then
				local each = hot.total / hot.ticks
				left, soon = left + each * remaining, soon + each
			end
		end
	end
	return left, soon
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
			local spell = SpellOf(id)
			sent = spell and { id = id, spell = spell, target = target, guid = guid, at = GetTime() } or nil
		else
			local _, guid, id = ...
			local s, spell = sent, SpellOf(id)
			if not (s and spell) or spell.entry ~= s.spell.entry or GetTime() - s.at > SENT_WINDOW then return end
			if guid and s.guid and not issecret(guid) and not issecret(s.guid) and guid ~= s.guid then return end
			sent = nil
			-- la cible est retrouvée maintenant : la case cliquée est sûrement notée (Frames.lua)
			local unit = Z.CastReceiver(s.target, s.spell.name, s.at)
			if unit then Remember(unit, s.id, s.spell) end
		end
	end, ...)
end)

-- Réglage hotPrediction (appelé par Z:Refresh) : éteint, Lyorune n'écoute plus rien et oublie mes soins
local listening = false
function Z:RefreshHotPrediction()
	if (Z.db.hotPrediction or false) == listening then return end
	listening = Z.db.hotPrediction or false
	if listening then
		castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
		castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		castFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
	else
		castFrame:UnregisterAllEvents()
		active, sent, channel = {}, nil, nil
	end
end

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
		local name = Z.SpellName(entry.id)
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
	return lines
end
