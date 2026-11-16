-- Zenith (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Zenith - Alerts.lua : les annonces automatiques du soigneur (onglet Alertes).
--   1. Mana faible     : ma mana passe sous un seuil.            Texte : {mana} = mon pourcentage de mana
--   2. Mana remontée   : après une alerte, ma mana est revenue.  Texte : {mana}
--   3. Résurrection    : je commence à relever un joueur.        Texte : {nom} = le joueur relevé
-- Chaque annonce a sa case à cocher et son texte. Elles ne partent qu'en groupe.
--
-- Limite imposée par le jeu : hors instance, un addon n'a pas le droit d'écrire en /dire tout seul.
-- Dans ce cas, l'annonce part dans le canal du groupe ou du raid.

local _, Z = ...
local issecret = Z.IsSecret

local MANA = 0        -- type de ressource « mana »
local MIN_DELAY = 30  -- secondes minimum entre deux annonces de mana faible

local low = false     -- vrai entre « mana faible » et « mana remontée »
local lastLow, lastRes = -MIN_DELAY, -10

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
		channel = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "SAY"
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
local function CheckMana()
	local db = Z.db
	if not IsInGroup() then return end
	local dead = UnitIsDeadOrGhost("player")
	if issecret(dead) or dead then return end
	local mana, max = UnitPower("player", MANA), UnitPowerMax("player", MANA)
	if issecret(mana) or issecret(max) or not max or max <= 0 then return end

	local percent = math.floor(mana / max * 100 + 0.5)
	local regenAt = math.max(db.regenThreshold, db.manaThreshold + 10)
	if percent <= db.manaThreshold then
		if not low then
			low = true
			if db.soundMana then PlaySound(8959, "Master") end
			if db.manaAlert and GetTime() - lastLow >= MIN_DELAY then
				lastLow = GetTime()
				Z:Announce(Z:ManaText(percent))
			end
		end
	elseif low and percent >= regenAt then
		low = false
		if db.regenAlert then Z:Announce(Z:RegenText(percent)) end
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
		if issecret(target) or not target then target = "un allié" end
	end
	lastRes = GetTime()
	Z:Announce(Z:ResText(target:match("^[^-]+") or target)) -- sans le nom du royaume
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnEvent", function(_, event, _, target, _, spellID)
	if event == "UNIT_SPELLCAST_SENT" then
		CheckRes(target, spellID)
	else
		CheckMana()
	end
end)

-- N'écoute que ce qui est activé : aucun coût si tout est décoché
function Z:RefreshAlerts()
	watcher:UnregisterAllEvents()
	if Z.db.manaAlert or Z.db.regenAlert then
		watcher:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
	end
	if Z.db.resAlert then
		watcher:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
	end
end
