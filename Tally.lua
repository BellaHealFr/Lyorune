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
-- Bilan de la soirée : les mêmes chiffres depuis la connexion du personnage (LyoruneCharDB.tonight), gardés après
-- un /reload, repartis de zéro à chaque connexion. En sortant d'un donjon ou d'un raid, une ligne dans la
-- discussion donne le donjon quitté (nom, durée, ses chiffres) puis la soirée (réglage tallyExit, avec le carnet).

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

-- 12345 -> "12 345" (chiffres du carnet et de la page des amis)
function Z.Grouped(n)
	local text = tostring(math.floor(tonumber(n) or 0))
	repeat
		local done
		text, done = text:gsub("^(%d+)(%d%d%d)", "%1 %2")
	until done == 0
	return text
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

-- Bilan de la soirée (créé au premier besoin)
function Z.Tonight()
	local tonight = Z.char.tonight
	if type(tonight) ~= "table" then
		tonight = { heals = 0, res = 0, buffs = 0 }
		Z.char.tonight = tonight
	end
	return tonight
end

-- Le carnet repart de zéro (bouton de la page), la soirée aussi
function Z.ResetTally()
	Z.char.tally, Z.char.tonight = nil, nil
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
	local tally, tonight = Z.Tally(), Z.Tonight()
	tally[kind] = (tally[kind] or 0) + 1
	tonight[kind] = (tonight[kind] or 0) + 1
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

-- Mes chiffres de la soirée en une phrase : « 152 soins, 2 résurrections, 18 buffs »
local function Numbers(heals, res, buffs)
	return Z.L["%s soins, %s résurrections, %s buffs"]:format(Z.Grouped(heals), Z.Grouped(res), Z.Grouped(buffs))
end

-- La ligne du bilan de la soirée, ou nil si rien n'a été compté depuis la connexion
function Z.TonightLine()
	local tonight = Z.Tonight()
	if tonight.heals + tonight.res + tonight.buffs == 0 then return end
	return Z.L["Bilan de la soirée : %s."]:format(Numbers(tonight.heals, tonight.res, tonight.buffs))
end

-- La ligne de sortie : le donjon quitté (nom, durée, ses chiffres), puis la soirée. outing : LyoruneCharDB.outing.
function Z.OutingLine(outing)
	local tonight = Z.Tonight()
	local line = Z.TonightLine()
	if not line or not outing then return line end
	local minutes = math.max(1, math.floor((time() - (outing.start or time())) / 60))
	return Z.L["%s (%d min) : %s."]:format(outing.name or "?", minutes, Numbers(tonight.heals - (outing.heals or 0),
		tonight.res - (outing.res or 0), tonight.buffs - (outing.buffs or 0))) .. " " .. line
end

-- Chaque écran de chargement. Une connexion efface la soirée. Entrer dans un donjon ou un raid note son nom, l'heure
-- et les chiffres du moment (LyoruneCharDB.outing, gardé au /reload) ; en sortir vivant donne le bilan. Sorti mort
-- (retour au cimetière après un wipe) : rien, le donjon continue au retour.
local lastKind -- type de lieu au dernier chargement ("party", "raid", ...)
local function Dungeon(kind) return kind == "party" or kind == "raid" end

Z:On("PLAYER_ENTERING_WORLD", function(isInitialLogin)
	if isInitialLogin then Z.char.tonight, Z.char.outing = nil, nil end
	local _, kind = IsInInstance()
	local was = lastKind
	lastKind = kind
	if Dungeon(kind) then
		local name = GetInstanceInfo()
		if issecret(name) or not name then name = nil end
		local outing = Z.char.outing
		if not outing or outing.name ~= name then -- un autre donjon : on repart de ses chiffres
			local tonight = Z.Tonight()
			Z.char.outing = { name = name, start = time(), heals = tonight.heals, res = tonight.res, buffs = tonight.buffs }
		end
		return
	end
	if not Dungeon(was) then return end
	local dead = UnitIsDeadOrGhost("player")
	if issecret(dead) or dead then return end
	local outing = Z.char.outing
	Z.char.outing = nil
	if Z.db.notebook and Z.db.tallyExit then
		local line = Z.OutingLine(outing)
		if line then Z:Print(line) end
	end
end)
