-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Tally.lua : « Votre carnet », sur la page « Les amis de Lyorune » (réglage notebook).
-- Compte, par personnage, mes sorts réussis d'où qu'ils partent (case, barre, macro, touche au survol), rangés
-- par leur nom (tous les rangs comptent) :
--   res    : une résurrection (Z.resNames)
--   buffs  : un buff de ma classe (Z.buffNames, Z.ownNames : bénédictions, auras, buffs uniques)
--   heals  : sinon, un sort de mon grimoire que le jeu dit utilisable sur un allié, ou un soin sans cible
--            (Z.groupHeals)
-- Les dissipations ne comptent pas comme des soins. Un seul événement, sur moi seulement, écouté seulement
-- quand le carnet est allumé. Un numéro de sort secret (en combat, selon le jeu) n'est pas compté.
-- Rangé dans LyoruneCharDB.tally = { since = "AAAA-MM-JJ", heals = n, res = n, buffs = n }.

local _, Z = ...
local issecret = Z.IsSecret

local groupHealNames, dispelNames, builtFor -- noms des soins sans cible et des dissipations de ma classe

-- Les deux listes de noms, refaites quand les sorts du personnage changent (Z:BuildData)
local function Names()
	if groupHealNames and builtFor == Z.buffGeneration then return end
	builtFor = Z.buffGeneration
	groupHealNames, dispelNames = {}, {}
	for _, id in ipairs(Z.groupHeals[Z.class] or {}) do
		local name = Z.SpellName(id)
		if name then groupHealNames[name] = true end
	end
	for _, ids in pairs(Z.dispelSpells[Z.class] or {}) do
		for _, id in ipairs(ids) do
			local name = Z.SpellName(id)
			if name then dispelNames[name] = true end
		end
	end
end

-- Mon carnet (créé au premier besoin)
function Z.Tally()
	local tally = Z.char.tally
	if type(tally) ~= "table" then
		tally = { since = date("%Y-%m-%d"), heals = 0, res = 0, buffs = 0 }
		Z.char.tally = tally
	end
	return tally
end

-- Le carnet repart de zéro (bouton de la page)
function Z.ResetTally()
	Z.char.tally = nil
	return Z.Tally()
end

-- Rubrique du carnet d'un sort réussi : "res", "buffs", "heals" ou nil (pas compté)
function Z.TallyKind(spellID)
	if not spellID or issecret(spellID) then return end
	local name = C_Spell.GetSpellName(spellID)
	if not name or issecret(name) then return end
	if Z.resNames and Z.resNames[name] then return "res" end
	if (Z.buffNames and Z.buffNames[name]) or (Z.ownNames and Z.ownNames[name]) then return "buffs" end
	Names()
	if dispelNames[name] then return end
	if groupHealNames[name] then return "heals" end
	-- sort d'aide de mon grimoire : ni objet (boisson, potion), ni sort déclenché par un autre
	if C_Spell.IsSpellHelpful and Z.Knows(spellID) then
		local ok, helpful = pcall(C_Spell.IsSpellHelpful, spellID)
		if ok and not issecret(helpful) and helpful == true then return "heals" end
	end
end

local function Count(spellID)
	local kind = Z.TallyKind(spellID)
	if not kind then return end
	local tally = Z.Tally()
	tally[kind] = (tally[kind] or 0) + 1
	if Z.TallyChanged then Z.TallyChanged() end -- page ouverte : les chiffres suivent
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnEvent", function(_, _, _, _, spellID) Z:Try("carnet", Count, spellID) end)

-- N'écoute que si le carnet est allumé (appelé avec les alertes, après chaque réglage changé)
function Z:RefreshTally()
	watcher:UnregisterAllEvents()
	if Z.db.notebook then watcher:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") end
	if Z.TallyChanged then Z.TallyChanged() end -- page ouverte : « Carnet éteint » ou les chiffres, aussitôt
end
