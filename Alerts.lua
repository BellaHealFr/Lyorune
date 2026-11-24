-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Alerts.lua : les annonces automatiques du soigneur (onglet Alertes).
--   1. Mana faible     : ma mana passe sous un seuil.            Texte : {mana} = mon pourcentage de mana
--   2. Mana remontée   : après une alerte, ma mana est revenue.  Texte : {mana}
--   3. Résurrection    : je commence à relever un joueur.        Texte : {nom} = le joueur relevé
--   4. Quand le jeu cache ma mana (WoW Forever) : la règle à sorts (mana faible) et l'estimation (mana remontée).
-- Chaque annonce a sa case à cocher et son texte. Elles ne partent qu'en groupe.
--
-- Limite imposée par le jeu : hors instance, un addon n'a pas le droit d'écrire en /dire tout seul.
-- Dans ce cas, l'annonce part dans le canal du groupe ou du raid.

local _, Z = ...
local issecret = Z.IsSecret

local MANA = 0        -- type de ressource « mana »
local MIN_DELAY = 30  -- secondes minimum entre deux annonces de mana faible

local low = false     -- vrai entre « mana faible » et « mana remontée »
local waitRegen = false -- mana cachée : vrai entre « mana faible » et « mana remontée » (estimée)
local lastLow, lastRes = -MIN_DELAY, -10
local estimate, estimateAt, lastRate -- mana cachée : mana estimée, heure de la mesure, régénération lue
local castUntil = 0 -- mana cachée : fin des 5 secondes sans régénération après un sort qui coûte de la mana

-- Remplace {mana}, {nom}... dans un texte
local function Fill(text, token, value)
	return (text:gsub(token, function() return tostring(value) end))
end

function Z:ManaText(percent) return Fill(Z.db.manaText, "{mana}", percent) end
function Z:RegenText(percent) return Fill(Z.db.regenText, "{mana}", percent) end
function Z:ResText(name) return Fill(Z.db.resText, "{nom}", name) end

-- Envoie une annonce. « byHand » : déclenchée par un clic du joueur (boutons Tester), donc /dire autorisé partout.
function Z:Announce(text, byHand)
	local channel = "SAY"
	if Z.db.alertChannel == "GROUP" or (not byHand and not IsInInstance()) then
		channel = IsInGroup() and Z.GroupChannel() or "SAY"
	end
	UIErrorsFrame:AddMessage(text, 0.35, 0.65, 1)
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
		return -- le jeu interdit les messages d'addon pendant ce combat : seul l'avertissement à l'écran reste
	end
	local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
	pcall(send, text, channel)
end

----------------------------------------------------------------------------------------------------
-- Mana faible, puis mana remontée
----------------------------------------------------------------------------------------------------
-- Ma mana vient de passer sous le seuil : son et annonce (une annonce toutes les 30 s au plus)
local function WarnLow(percent)
	low, waitRegen = true, true
	estimate, lastRate = nil, nil -- la remontée se mesure à partir de maintenant, depuis le plancher sûr
	if Z.db.soundMana then PlaySound(8959, "Master") end
	if Z.db.manaAlert and GetTime() - lastLow >= MIN_DELAY then
		lastLow = GetTime()
		Z:Announce(Z:ManaText(percent))
	end
end

----------------------------------------------------------------------------------------------------
-- La règle à sorts : savoir si ma mana est sous le seuil quand le jeu la cache (WoW Forever)
----------------------------------------------------------------------------------------------------
-- Le jeu cache ma mana, mais il dit en clair le coût de mes sorts, ma mana maximum, et si un sort
-- manque de mana. Un sort de mon grimoire (tous rangs) qui coûte à peu près le seuil sert de règle :
-- quand il manque de mana, ma mana est sous le seuil. Le seuil est donc approché : il dépend des coûts
-- de mes sorts, et {mana} devient le pourcentage que coûte le sort choisi.
local manaSpells -- { { id = sort, cost = coût en mana }, ... }, relu quand mes sorts changent

local function ReadManaSpells()
	manaSpells = {}
	if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_Spell.GetSpellPowerCost) then return end
	local bank = Enum.SpellBookSpellBank.Player
	for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
		for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
			local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
			local id = item and item.itemType == Enum.SpellBookItemType.Spell and not item.isPassive and item.spellID
			local costs = id and not issecret(id) and C_Spell.GetSpellPowerCost(id)
			for _, c in ipairs(type(costs) == "table" and costs or {}) do
				if not issecret(c.type) and not issecret(c.cost) and c.type == MANA and (c.cost or 0) > 0 then
					manaSpells[#manaSpells + 1] = { id = id, cost = c.cost }
					break
				end
			end
		end
	end
	table.sort(manaSpells, function(a, b) return a.cost < b.cost end) -- du moins cher au plus cher (paliers)
end

-- Ce sort dit-il quelque chose de ma mana ? Vrai, faux (sous son coût), ou rien (réponse secrète,
-- ou sort bloqué pour une autre raison : forme, composant, sort interdit en combat)
local function ManaFor(id)
	local usable, noMana = C_Spell.IsSpellUsable(id)
	if issecret(usable) or issecret(noMana) then return nil end
	if usable then return true end
	if noMana then return false end
	return nil
end

-- Ma mana est-elle sous le seuil ? Rend vrai ou faux, le pourcentage approché et le sort choisi,
-- ou rien si aucun sort ne coûte assez près du seuil (entre 60 % et 125 % du seuil).
function Z:ManaByRuler()
	local max = UnitPowerMax("player", MANA)
	if issecret(max) or not max or max <= 0 or not C_Spell.IsSpellUsable then return nil end
	if not manaSpells then ReadManaSpells() end
	local target = max * Z.db.manaThreshold / 100
	local best, bestGap, bestCost, bestID
	for _, spell in ipairs(manaSpells) do
		local gap = math.abs(spell.cost - target)
		if spell.cost >= target * 0.6 and spell.cost <= target * 1.25 and (not bestGap or gap < bestGap) then
			local enough = ManaFor(spell.id)
			if enough ~= nil then best, bestGap, bestCost, bestID = enough, gap, spell.cost, spell.id end
		end
	end
	if best == nil then return nil end
	return not best, math.floor(bestCost / max * 100 + 0.5), bestID
end

-- Pour l'onglet Alertes : quel sort sert de règle, et à combien de ma mana
function Z:ManaRulerText()
	local L = Z.L
	local mana = UnitPower("player", MANA)
	if not issecret(mana) then return L["Votre mana est lisible : l'annonce part au seuil exact."] end
	local _, percent, id = Z:ManaByRuler()
	if not id then return L["Aucun de vos sorts ne coûte près de ce seuil : essayez un autre seuil."] end
	local name = C_Spell.GetSpellName(id) or "?"
	local rank = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(id)
	if rank and not issecret(rank) and rank ~= "" then name = name .. " (" .. rank .. ")" end
	return L["Le jeu cache votre mana : l'annonce part quand vous n'avez plus assez de mana pour %s, soit vers %d %%. La mana remontée est estimée hors combat avec votre régénération, boisson comprise."]:format(name, percent)
end

----------------------------------------------------------------------------------------------------
-- Mana remontée quand le jeu cache ma mana : l'estimation
----------------------------------------------------------------------------------------------------
-- Aucun sort ne coûte 90 % de ma mana : la règle à sorts ne peut pas dire « remontée » seule. Mais elle
-- encadre ma mana : au moins le coût du sort le plus cher que je peux lancer (plancher), moins que le coût
-- du premier qui en manque (plafond). Hors combat, le jeu dit en clair ma régénération par seconde, boisson
-- comprise (GetPowerRegen). À chaque changement de mana signalé par le jeu, Lyorune ajoute cette
-- régénération multipliée par le temps écoulé, puis garde l'estimation entre le plancher et le plafond.
-- En combat la régénération est secrète : rien n'est ajouté. Un sort qui coûte de la mana ramène
-- l'estimation au plancher, et les 5 secondes qui suivent ne comptent pas. L'annonce ne part donc jamais
-- trop tôt. Aucune boucle, aucun minuteur.

-- Plancher et plafond sûrs de ma mana d'après mes sorts
local function ManaBounds(max)
	if not manaSpells then ReadManaSpells() end
	local floor, ceiling = 0, max
	for _, spell in ipairs(manaSpells) do -- du moins cher au plus cher : on s'arrête au premier qui manque
		local enough = ManaFor(spell.id)
		if enough == false then
			ceiling = spell.cost
			break
		end
		if enough then floor = spell.cost end
	end
	return floor, math.max(ceiling, floor)
end

-- Ma régénération de mana par seconde : lisible hors combat seulement (rien en combat, ou réponse secrète)
local function RegenRate()
	if InCombatLockdown() then return nil end
	local kind = UnitPowerType("player")
	local ok, rate = false, nil
	if (issecret(kind) or kind == MANA) and GetPowerRegen then
		ok, rate = pcall(GetPowerRegen)
	elseif GetPowerRegenForPowerType then -- druide en forme d'ours ou de félin : la mana à part
		ok, rate = pcall(GetPowerRegenForPowerType, MANA)
	end
	if not ok or issecret(rate) or type(rate) ~= "number" or rate < 0 then return nil end
	return rate
end

local function AnnounceRegen(percent)
	waitRegen, estimate, lastRate = false, nil, nil
	if Z.db.regenAlert then Z:Announce(Z:RegenText(percent)) end
end

local function FollowRegen(max, regenAt)
	local now = GetTime()
	local floor, ceiling = ManaBounds(max)
	local rate = RegenRate()
	if estimate and rate and lastRate then
		-- la plus petite des deux mesures : une boisson qui commence ou finit n'avance jamais l'annonce
		local from = math.max(estimateAt, castUntil)
		if now > from then estimate = estimate + math.min(rate, lastRate) * (now - from) end
	end
	estimate = math.min(math.max(estimate or floor, floor), ceiling)
	estimateAt, lastRate = now, rate
	if estimate >= max * regenAt / 100 then
		AnnounceRegen(math.min(100, math.floor(estimate / max * 100 + 0.5)))
	end
end

-- Un sort qui coûte de la mana pendant la remontée : retour au plancher sûr, sans régénération pendant 5 s
local function NoteCast(spellID)
	if not waitRegen then return end
	if not issecret(spellID) and spellID then
		local ok, costs = pcall(C_Spell.GetSpellPowerCost, spellID)
		if ok and type(costs) == "table" and not issecret(costs) then
			local paid = false
			for _, c in ipairs(costs) do
				if issecret(c.type) or issecret(c.cost) or (c.type == MANA and (c.cost or 0) > 0) then paid = true end
			end
			if not paid then return end -- baguette, objet... : ma mana n'a pas bougé
		end
	end
	estimate, castUntil = nil, GetTime() + 5
end

local function CheckMana()
	local db = Z.db
	if not IsInGroup() then return end
	local dead = UnitIsDeadOrGhost("player")
	if issecret(dead) or dead then return end
	local mana, max = UnitPower("player", MANA), UnitPowerMax("player", MANA)
	local regenAt = math.max(db.regenThreshold, db.manaThreshold + 10)
	if issecret(mana) or issecret(max) then
		-- mana cachée : la règle à sorts pour « mana faible », l'estimation pour « mana remontée »
		local isLow, percent = Z:ManaByRuler()
		if isLow and not low then WarnLow(percent) elseif isLow == false then low = false end
		if waitRegen and db.regenAlert and not issecret(max) and max and max > 0 then FollowRegen(max, regenAt) end
		return
	end
	if not max or max <= 0 then return end

	local percent = math.floor(mana / max * 100 + 0.5)
	if percent <= db.manaThreshold then
		if not low then WarnLow(percent) end
	elseif low and percent >= regenAt then
		low, waitRegen = false, false
		if db.regenAlert then Z:Announce(Z:RegenText(percent)) end
	end
end

-- Un sort refusé en combat faute de mana : ma mana est forcément basse, même si la règle n'a rien dit
local function CheckOutOfMana(errorType, message)
	if not InCombatLockdown() or low or not IsInGroup() then return end
	local byType = LE_GAME_ERR_OUT_OF_MANA and not issecret(errorType) and errorType == LE_GAME_ERR_OUT_OF_MANA
	local byText = ERR_OUT_OF_MANA and not issecret(message) and message == ERR_OUT_OF_MANA
	if byType or byText then
		local _, percent = Z:ManaByRuler()
		WarnLow(percent or Z.db.manaThreshold)
	end
end

----------------------------------------------------------------------------------------------------
-- Résurrection : le jeu signale le sort que je lance et sa cible
----------------------------------------------------------------------------------------------------
local function CheckRes(target, spellID)
	if issecret(spellID) or not spellID or not IsInGroup() then return end
	local spell = C_Spell.GetSpellName(spellID)
	if not spell or not Z.resNames[spell] or GetTime() - lastRes < 3 then return end
	if issecret(target) or not target or target == "" then
		target = UnitName("mouseover")
		if issecret(target) or not target then target = Z.L["un allié"] end
	end
	lastRes = GetTime()
	Z:Announce(Z:ResText(target:match("^[^-]+") or target)) -- sans le nom du royaume
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnEvent", function(_, event, ...)
	if event == "UNIT_SPELLCAST_SENT" then
		local _, target, _, spellID = ...
		Z:Try("annonce de résurrection", CheckRes, target, spellID)
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local _, _, spellID = ...
		Z:Try("annonce de mana", NoteCast, spellID)
	elseif event == "UI_ERROR_MESSAGE" then
		Z:Try("annonce de mana", CheckOutOfMana, ...)
	elseif event == "SPELLS_CHANGED" then
		manaSpells = nil -- grimoire relu à la prochaine mesure
	else
		Z:Try("annonce de mana", CheckMana)
	end
end)

-- N'écoute que ce qui est activé : aucun coût si tout est décoché
function Z:RefreshAlerts()
	watcher:UnregisterAllEvents()
	if Z.db.manaAlert or Z.db.regenAlert or Z.db.soundMana then -- le son seul a aussi besoin de la mana
		watcher:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
	end
	if Z.db.manaAlert or Z.db.soundMana or Z.db.regenAlert then -- règle à sorts et paliers : grimoire relu
		watcher:RegisterEvent("SPELLS_CHANGED")
	end
	if Z.db.regenAlert then -- mana cachée : un sort lancé pendant la remontée
		watcher:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	end
	if Z.db.manaAlert or Z.db.soundMana then -- sort refusé faute de mana
		watcher:RegisterEvent("UI_ERROR_MESSAGE")
	end
	if Z.db.resAlert then
		watcher:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
	end
	if Z.RefreshComm then Z:RefreshComm() end -- synchronisation (Comm.lua) : même moment, mêmes réglages
	if Z.RefreshTally then Z:RefreshTally() end -- « Votre carnet » (Tally.lua) : idem
	if Z.RefreshChannels then Z:RefreshChannels() end -- canal des soigneurs (Channels.lua) : idem
end
