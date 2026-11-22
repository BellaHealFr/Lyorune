-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Data.lua : ce que chaque classe de WoW Forever sait faire.
-- Tout est donné par identifiant de sort : le nom est traduit tout seul (client français ou anglais).

--
-- AJOUTER UNE CLASSE (par exemple si WoW Forever en introduit une) : tout se passe dans ce fichier.
--   1. Z.dispelSpells.MACLASSE  = { Magic = { id }, Curse = { id }, Disease = { id }, Poison = { id } }
--   2. Z.trackedSpells.MACLASSE = { id, id, ... }      -- ses soins sur la durée et boucliers
--      Z.spellRanks[id] = { id, id, ... }             -- leurs autres rangs, s'ils en ont (voir plus bas)
--   3. Z.clickDefaults.MACLASSE = { ["1"] = { id }, ["shift-1"] = { id }, ... }
--   4. Z.resSpells et Z.classRes : son sort de résurrection, s'il en a un
--   5. Z.raidBuffs.MACLASSE : ses buffs à surveiller (de groupe, sur soi, bénédictions, arme), s'il en a
--   6. Z.uniqueBuffs.MACLASSE : ses buffs à poser sur une seule personne (le tank), s'il en a
--   7. Z.classPower.MACLASSE : sa ressource si ce n'est pas la mana (rage, énergie...) ; une classe absente de
--      cette table compte comme classe à mana (buffs réservés aux joueurs à mana, comme Esprit divin)
--   8. Z.defensives.MACLASSE : ses gros défensifs, montrés sur sa case à tous les soigneurs
--   9. Z.lockouts.MACLASSE : les affaiblissements qui l'empêchent de relancer un de ses sorts, s'il en a
-- MACLASSE est le nom interne de la classe en majuscules (PRIEST, DRUID...), affiché par /lyorune erreurs.
-- Toutes ces tables sont facultatives : une classe absente fonctionne quand même (cadres, clics choisis
-- à la main dans les options, dissipation signalée par le jeu). Aucun autre fichier n'est à modifier.

local _, Z = ...

-- Sorts de dissipation : type d'affaiblissement -> sorts qui l'enlèvent
Z.dispelSpells = {
	PRIEST  = { Magic = { 527 }, Disease = { 552, 528 } },              -- Dissipation de la magie, Abolir / Guérison des maladies
	PALADIN = { Magic = { 4987 }, Disease = { 4987, 1152 }, Poison = { 4987, 1152 } }, -- Epuration, Purification
	DRUID   = { Curse = { 2782 }, Poison = { 2893, 8946 } },            -- Délivrance de la malédiction, Abolir / Guérison du poison
	SHAMAN  = { Disease = { 2870 }, Poison = { 526 } },                 -- Guérison des maladies, Guérison du poison
	MAGE    = { Curse = { 475 } },                                      -- Délivrance de la malédiction mineure
}

-- Filtres du jeu : RAID = les affaiblissements que JE peux dissiper (le jeu le sait pour toute classe, même un sort
-- appris en montant de niveau) ; !RAID = tous les autres. Les deux se complètent : ni trou, ni doublon.
-- (RAID_PLAYER_DISPELLABLE voudrait dire « dissipable par quelqu'un du raid » : pas ce qu'on cherche.)
Z.DISPEL_MINE = "HARMFUL|RAID"
Z.DISPEL_OTHERS = "HARMFUL|!RAID"

-- Mes sorts à suivre sur les cadres (soins sur la durée, boucliers, protections)
Z.trackedSpells = {
	PRIEST  = { 139, 17, 401859, 6346, 552, 10060 },   -- Rénovation, Mot de pouvoir : Bouclier, Prière de guérison, Gardien de peur, Abolir maladie, Infusion de puissance
	DRUID   = { 774, 8936, 408120, 2893, 29166 },      -- Récupération, Rétablissement, Croissance sauvage, Abolir le poison, Innervation
	PALADIN = { 1022, 6940, 1044, 19752 },             -- Bénédictions de protection, de sacrifice, de liberté, Intervention divine
	SHAMAN  = { 22419, 408514 },                       -- Remous, Bouclier de terre
}

-- Autres rangs des sorts suivis : sur WoW Forever, chaque rang a son propre numéro, et les conteneurs d'auras
-- du jeu (Containers.lua) ne montrent que les numéros donnés. Avec tous les rangs, un rang inférieur lancé
-- exprès (macro) ou un rang appris en plein combat s'affiche aussitôt. Un numéro dont le nom, lu dans le jeu,
-- n'est pas celui du sort est ignoré (Z:BuildData) : une erreur ici ne peut rien afficher de faux.
Z.spellRanks = {
	[139]  = { 6074, 6075, 6076, 6077, 6078, 10927, 10928, 10929, 25315 },     -- Rénovation
	[17]   = { 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901 },      -- Mot de pouvoir : Bouclier
	[774]  = { 1058, 1430, 2090, 2091, 3627, 8910, 9839, 9840, 9841, 25299 }, -- Récupération
	[8936] = { 8938, 8939, 8940, 8941, 9750, 9856, 9857, 9858 },              -- Rétablissement
	[1022] = { 5599, 10278 },                                                  -- Bénédiction de protection
	[6940] = { 20729 },                                                        -- Bénédiction de sacrifice
	[29166] = { 456195 },                                                      -- Innervation (variante trouvée dans le jeu)
}

-- Clics proposés au premier lancement. Pour chaque case, le premier sort connu de la liste est retenu.
-- Clé : touche de modification + numéro du bouton (1 gauche, 2 droit, 3 milieu).
Z.clickDefaults = {
	PRIEST = {
		["1"] = { 2061, 2054, 2050 },      -- Soins rapides, sinon Soins, sinon Soins inférieurs
		["shift-1"] = { 2060, 2054 },      -- Soins supérieurs
		["2"] = { 139 },                   -- Rénovation
		["shift-2"] = { 17 },              -- Mot de pouvoir : Bouclier
		["ctrl-1"] = { 401859 },           -- Prière de guérison
		["3"] = { 527 },                   -- Dissipation de la magie
		["shift-3"] = { 552, 528 },        -- Abolir maladie
		["ctrl-2"] = { 2006 },             -- Résurrection
	},
	DRUID = {
		["1"] = { 5185 },                  -- Toucher guérisseur
		["shift-1"] = { 8936 },            -- Rétablissement
		["2"] = { 774 },                   -- Récupération
		["shift-2"] = { 18562 },           -- Prompte guérison
		["ctrl-1"] = { 408120 },           -- Croissance sauvage
		["3"] = { 2782 },                  -- Délivrance de la malédiction
		["shift-3"] = { 2893, 8946 },      -- Abolir le poison
		["ctrl-2"] = { 20484, 1237950 },   -- Renaissance, Ressusciter
	},
	PALADIN = {
		["1"] = { 19750, 635 },            -- Eclair lumineux
		["shift-1"] = { 635 },             -- Lumière sacrée
		["2"] = { 4987, 1152 },            -- Epuration
		["shift-2"] = { 1022 },            -- Bénédiction de protection
		["3"] = { 633 },                   -- Imposition des mains
		["ctrl-2"] = { 7328 },             -- Rédemption
	},
	SHAMAN = {
		["1"] = { 331 },                   -- Vague de soins
		["shift-1"] = { 8004 },            -- Vague de soins inférieurs
		["2"] = { 1064 },                  -- Salve de guérison
		["shift-2"] = { 22419 },           -- Remous
		["ctrl-1"] = { 408514 },           -- Bouclier de terre
		["3"] = { 526 },                   -- Guérison du poison
		["shift-3"] = { 2870 },            -- Guérison des maladies
		["ctrl-2"] = { 2008 },             -- Esprit ancestral
	},
	MAGE = {
		["3"] = { 475 },                   -- Délivrance de la malédiction mineure
	},
}

-- Sorts de résurrection (toutes classes), pour l'annonce « je ressuscite untel »
Z.resSpells = { 2006, 7328, 2008, 20484, 1237950 } -- Résurrection, Rédemption, Esprit ancestral, Renaissance, Ressusciter

-- Résurrection de chaque classe (option « le même clic relève un mort »). combat = utilisable en combat.
Z.classRes = {
	PRIEST = { 2006 }, PALADIN = { 7328 }, SHAMAN = { 2008 },
	DRUID = { 1237950, combat = 20484 },
}

-- Ressource de la classe quand ce n'est pas la mana : numéro et nom du jeu (Enum.PowerType). Sert au mode test,
-- et sur les vraies cases quand le jeu garde la ressource secrète et qu'aucune n'est encore connue.
Z.classPower = { WARRIOR = { 1, "RAGE" }, ROGUE = { 3, "ENERGY" }, HUNTER = { 2, "FOCUS" } }

-- Buffs à surveiller hors combat (panneau des buffs manquants, icône grise sur la case). Une ligne par buff :
--   { simple, groupe }   le sort simple, puis sa version de groupe s'il en a une (Prière de robustesse...)
--   any = { id }         d'autres sorts qui comptent aussi : un joueur qui en porte un n'a besoin de rien
--                        (le premier sort connu de la ligne est lancé)
--   self = true          sur moi seulement (Feu intérieur, boucliers du chaman)
--   mana = true          seulement les joueurs à mana : les classes absentes de Z.classPower
--   blessing = { id }    bénédictions : chaque joueur en veut une de moi (celle d'un autre paladin ne compte
--                        pas) ; tank : Rois, joueur à mana : Sagesse, les autres : Puissance (Z.BlessingFor)
--   weapon = { id }      enchantement de mon arme principale (le jeu le dit à part, pas dans les auras) : le
--                        dernier que j'ai lancé, sinon le premier connu de la liste
--   racial = true       sort de race : absent de « Mes buffs » si mon personnage ne l'a pas
--   pve = false, pvp = false : décoché au départ dans « Mes buffs » (options), en JcE ou en JcJ
-- Le premier numéro de la ligne la désigne dans le réglage « buffWatch ». Numéros vérifiés hors jeu (HealKit,
-- PallyPower et VuhDo portés sur Forever) ; un sort que je ne connais pas est ignoré (Z.Knows).
Z.raidBuffs = {
	PRIEST = {
		{ 1243, 21562 },                -- Mot de pouvoir : Robustesse, Prière de robustesse
		{ 14752, 27681, mana = true },  -- Esprit divin, Prière d'esprit
		{ 976, 27683, pve = false },    -- Protection contre l'ombre, Prière de protection contre l'ombre (JcJ)
		{ 588, self = true },           -- Feu intérieur
		{ 2652, self = true, racial = true },  -- Toucher de faiblesse (sort de race)
		{ 18137, self = true, racial = true }, -- Garde de l'ombre (sort de race)
	},
	PALADIN = {
		{ blessing = { 19740, 19742, 20217, 20911 } }, -- Bénédictions de puissance, de sagesse, des rois, du sanctuaire
		{ 25780, self = true, pve = false, pvp = false }, -- Fureur vertueuse (tanks seulement)
	},
	SHAMAN = {
		{ 408510, any = { 324 }, self = true },        -- Bouclier d'eau, ou Bouclier de foudre
		{ weapon = { 8024, 8017, 8232, 8033 }, self = true }, -- Arme Langue de feu, Croque-roc, Furie-des-vents, Arme de givre
	},
	DRUID  = { { 1126, 21849 } },               -- Marque du fauve, Don du fauve
	MAGE   = { { 1459, 23028, mana = true } },  -- Intelligence des arcanes, Illumination des arcanes
}

-- Buffs à poser sur une seule personne, hors combat : le panneau des buffs manquants les propose pour le
-- tank, ou pour le joueur choisi par /lyorune porteur. Rien n'est proposé tant que le mien est sur quelqu'un,
-- ni pendant son temps de recharge. Un numéro seul, ou { id, pve = false, pvp = false } comme plus haut.
Z.uniqueBuffs = {
	SHAMAN  = { 408514 },                             -- Bouclier de terre
	DRUID   = { 467 },                                -- Épines
	PRIEST  = { { 6346, pve = false, pvp = false } }, -- Gardien de peur
	PALADIN = { 1328548 },                            -- Serment de lumière (talent de WoW Forever)
}

-- Bénédiction proposée à chaque joueur (paladin) : la première que je connais de sa ligne. Ligne choisie dans
-- cet ordre : TANK (rôle du joueur), le nom de sa classe, MANA (classe à mana), puis OTHER.
Z.blessingFor = {
	TANK   = { 20217, 20911, 19740 }, -- Rois, Sanctuaire, Puissance
	HUNTER = { 20217, 19740 },        -- Rois (Puissance ne donne que de la puissance au corps à corps), Puissance
	MANA   = { 19742, 20217 },        -- Sagesse, Rois
	OTHER  = { 19740, 20217 },        -- Puissance, Rois
}

-- Gros défensifs, posés par n'importe quel joueur : leur icône va sur la case de celui qui les porte (réglage
-- « showDefensives »), même en combat (Containers.lua). Une ligne par sort : le premier numéro, puis les autres
-- numéros du même sort sur WoW Forever (rangs, doubles propres au jeu), trouvés par une recherche dans le jeu
-- le 21 novembre 2026. Un numéro dont le nom, lu dans le jeu, n'est pas celui du premier est ignoré (Z:BuildData).
-- Absents de ce client : Cape d'ombre, Suppression de la douleur, Esprit gardien, Écorce de fer, Instincts de
-- survie, Rage du chaman, Bénédiction de salut. RACIAL : les sorts de race, pour toutes les classes.
Z.defensives = {
	WARRIOR = {
		{ 871, 15062, 29061, 1277424 },     -- Mur protecteur
		{ 12975, 12976 },                   -- Dernier rempart
	},
	PALADIN = {
		{ 642, 1020, 13874 },               -- Bouclier divin
		{ 498, 5573, 13007, 27778, 458312, 458371, 1213300 }, -- Protection divine
		{ 1022, 5599, 10278, 442948 },      -- Bénédiction de protection
		{ 6940, 20729 },                    -- Bénédiction de sacrifice
	},
	ROGUE   = { { 5277, 15087 } },          -- Évasion
	DRUID   = { { 22812 } },                -- Écorce
	MAGE    = { { 11958, 27619 } },         -- Bloc de glace
	HUNTER  = { { 19263 } },                -- Dissuasion
	RACIAL  = { { 20594, 7020 } },          -- Forme de pierre (nain)
}
Z.DEFENSIVE_COUNT = 2 -- gros défensifs montrés au plus sur une case

-- Affaiblissements qui m'empêchent de relancer un de mes sorts sur ce joueur, posés par n'importe qui : leur
-- icône, assombrie, suit la rangée de mes soins (réglage « showLockouts »), même en combat (Containers.lua).
-- Une ligne par affaiblissement, comme les gros défensifs : le premier numéro, puis ses doubles éventuels.
Z.lockouts = {
	PRIEST = { { 6788 } },                  -- Âme affaiblie (après Mot de pouvoir : Bouclier)
}
Z.LOCKOUT_COUNT = 1 -- affaiblissements de ce genre montrés au plus sur une case

-- Boisson : un soigneur qui boit le montre sur sa case, à côté de sa mana basse (réglage « drinkHealers »).
-- Les numéros des boissons du jeu (eau de chaque niveau, eau invoquée) ; ceux dont le nom, lu dans le jeu,
-- n'est pas celui du premier sont ignorés (Z:BuildData).
-- Liste complétée par la recherche dans le jeu du 21 novembre 2026 (build 71037) : 18 numéros nommés « Boisson ».
Z.drinkSpells = { 430, 431, 432, 1133, 1135, 1137, 10250, 22734, 24355, 25696, 26261, 26402, 26473, 26475, 29007,
	446714, 468767, 1330734 }

-- Affaiblissements sans intérêt pour un soigneur
Z.ignoredDebuffs = {
	[11196] = true, -- Bandé récemment
	[25771] = true, -- Longanimité
	[15007] = true, -- Mal de résurrection
	[26013] = true, -- Déserteur
}

function Z.SpellName(id)
	return C_Spell.GetSpellName(id)
end

function Z.Knows(id)
	if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(id) then return true end
	if IsPlayerSpell and IsPlayerSpell(id) then return true end
	local name = C_Spell.GetSpellName(id)
	-- un sort appris à un rang supérieur se retrouve par son nom
	return name ~= nil and C_SpellBook ~= nil and C_SpellBook.FindSpellBookSlotForSpell ~= nil
		and C_SpellBook.FindSpellBookSlotForSpell(name) ~= nil
end

-- Icône d'un sort : celle de mon grimoire (lue par le nom du sort, la version que je connais), sinon celle que le
-- jeu donne au numéro. Aucune icône n'est choisie par Lyorune.
function Z.SpellIcon(id)
	local name = Z.SpellName(id)
	local mine = name and Z.Knows(id) and C_Spell.GetSpellTexture(name)
	return mine or C_Spell.GetSpellTexture(id)
end

-- Tous les numéros d'une ligne de Z.raidBuffs ; le premier désigne la ligne (réglage « buffWatch »)
function Z.BuffIds(entry)
	local ids = {}
	for _, list in ipairs({ entry.blessing or {}, entry.weapon or {}, entry, entry.any or {} }) do
		for _, id in ipairs(list) do ids[#ids + 1] = id end
	end
	return ids
end

-- Une ligne de Z.raidBuffs lue dans le grimoire : nil si je ne connais aucun sort à lancer.
-- spell : le sort lancé ; groupSpell : sa version de groupe ; choices : les bénédictions ou les armes connues.
function Z.BuffCheck(entry)
	local ids = Z.BuffIds(entry)
	local check = { id = ids[1], names = {}, self = entry.self, mana = entry.mana, pve = entry.pve, pvp = entry.pvp }
	for _, id in ipairs(ids) do
		local name = Z.SpellName(id)
		if name then check.names[name] = true end
	end
	local choices = entry.blessing or entry.weapon
	if choices then
		check.choices = {}
		for _, id in ipairs(choices) do
			local name = Z.Knows(id) and Z.SpellName(id)
			if name then check.choices[#check.choices + 1] = { id = id, name = name, icon = Z.SpellIcon(id) } end
			if entry.weapon then Z.weaponIds[id] = true end
		end
		if #check.choices == 0 then return end
		check.blessing, check.weapon = entry.blessing ~= nil, entry.weapon ~= nil
		check.spell, check.icon = check.choices[1].name, check.choices[1].icon
		return check
	end
	-- le premier sort connu : la version simple, sinon un des autres sorts qui comptent aussi
	local castable = { entry[1] }
	for _, id in ipairs(entry.any or {}) do castable[#castable + 1] = id end
	for _, id in ipairs(castable) do
		if Z.Knows(id) then
			check.spell, check.icon = Z.SpellName(id), Z.SpellIcon(id)
			break
		end
	end
	if not check.spell then return end
	local group = entry[2] and Z.Knows(entry[2]) and Z.SpellName(entry[2])
	if group and group ~= check.spell then check.groupSpell = group end
	return check
end

-- La liste qui compte ici : « pvp » en champ de bataille et en arène, « pve » partout ailleurs
function Z.BuffContext()
	return Z.PvPKind and Z.PvPKind() and "pvp" or "pve"
end

-- Ce buff est-il dans ma liste (« Mes buffs », options) pour ce lieu ? Mon choix, sinon le départ de Data.lua
function Z.BuffWatched(check, context)
	context = context or Z.BuffContext()
	local chosen = Z.db.buffWatch[check.id]
	if type(chosen) == "table" and chosen[context] ~= nil then return chosen[context] end
	return check[context] ~= false
end

-- Joueur à mana : sa classe n'est pas dans Z.classPower (un familier ne compte pas ; classe secrète : non)
function Z.UsesMana(unit)
	if unit:find("pet", 1, true) then return false end
	local class = select(2, UnitClass(unit))
	if not class or Z.IsSecret(class) then return false end
	return not Z.classPower[class]
end

-- Bénédiction à poser sur ce joueur (Z.blessingFor) : le choix connu, son nom et son icône
function Z.BlessingFor(check, unit)
	local role = UnitGroupRolesAssigned(unit)
	local class = select(2, UnitClass(unit))
	local line = (not Z.IsSecret(role) and role == "TANK" and Z.blessingFor.TANK)
		or (class and not Z.IsSecret(class) and Z.blessingFor[class])
		or (Z.UsesMana(unit) and Z.blessingFor.MANA) or Z.blessingFor.OTHER
	for _, id in ipairs(line) do
		for _, choice in ipairs(check.choices) do
			if choice.id == id then return choice end
		end
	end
	return check.choices[1]
end

-- Enchantement d'arme à poser : le dernier que j'ai lancé (Z.char.weaponEnchant), sinon le premier connu
function Z.WeaponFor(check)
	local last = Z.char and Z.char.weaponEnchant
	for _, choice in ipairs(check.choices) do
		if choice.id == last then return choice end
	end
	return check.choices[1]
end

-- Reconstruit les tables rapides utilisées en combat. Appelé au démarrage et quand les sorts changent.
function Z:BuildData()
	Z.canDispel = {}
	for dispelType, ids in pairs(Z.dispelSpells[Z.class] or {}) do
		for _, id in ipairs(ids) do
			if Z.Knows(id) then Z.canDispel[dispelType] = true end
		end
	end

	Z.resNames = {}
	for _, id in ipairs(Z.resSpells) do
		local name = Z.SpellName(id)
		if name then Z.resNames[name] = true end
	end

	Z.buffChecks, Z.weaponIds = {}, {}
	Z.buffGeneration = (Z.buffGeneration or 0) + 1 -- les cases savent que leurs buffs manquants sont à relire
	for _, entry in ipairs(Z.raidBuffs[Z.class] or {}) do
		local check = Z.BuffCheck(entry)
		if check then Z.buffChecks[#Z.buffChecks + 1] = check end
	end

	Z.uniqueChecks = {}
	for _, entry in ipairs(Z.uniqueBuffs[Z.class] or {}) do
		entry = type(entry) == "table" and entry or { entry }
		local id = entry[1]
		local name = Z.Knows(id) and Z.SpellName(id)
		if name then
			Z.uniqueChecks[#Z.uniqueChecks + 1] = { id = id, name = name, spell = name, icon = Z.SpellIcon(id),
				unique = true, pve = entry.pve, pvp = entry.pvp }
		end
	end

	Z.trackedNames = {}
	for _, id in ipairs(Z.trackedSpells[Z.class] or {}) do
		local name = Z.SpellName(id)
		if name then Z.trackedNames[name] = true end
	end
	-- Tous les rangs connus du jeu, rangés par nom : Z.rankIds["Récupération"] = { [774] = true, [1058] = true... }
	Z.rankIds = {}
	for base, ranks in pairs(Z.spellRanks) do
		local name = Z.SpellName(base)
		if name then
			local set = Z.rankIds[name] or {}
			set[base] = true
			for _, id in ipairs(ranks) do
				if Z.SpellName(id) == name then set[id] = true end
			end
			Z.rankIds[name] = set
		end
	end
	-- Numéros des gros défensifs de toutes les classes, vérifiés par leur nom : Z.defensiveIds[871] = true
	Z.defensiveIds = {}
	for _, spells in pairs(Z.defensives) do
		for _, ids in ipairs(spells) do
			local name = Z.SpellName(ids[1])
			if name then
				for _, id in ipairs(ids) do
					if Z.SpellName(id) == name then Z.defensiveIds[id] = true end
				end
			end
		end
	end
	-- Affaiblissements qui bloquent un de mes sorts (ma classe seulement) et boissons, vérifiés par leur nom
	Z.lockoutIds = {}
	for _, ids in ipairs(Z.lockouts[Z.class] or {}) do
		local name = Z.SpellName(ids[1])
		if name then
			for _, id in ipairs(ids) do
				if Z.SpellName(id) == name then Z.lockoutIds[id] = true end
			end
		end
	end
	Z.drinkIds = {}
	local drink = Z.SpellName(Z.drinkSpells[1])
	if drink then
		for _, id in ipairs(Z.drinkSpells) do
			if Z.SpellName(id) == drink then Z.drinkIds[id] = true end
		end
	end
	-- Les conteneurs d'auras du jeu filtrent par numéro de sort : ils suivent les sorts de la classe
	if Z.RefreshAuraBoxes then Z.RefreshAuraBoxes() end

	-- Premier lancement avec cette classe : on propose des clics
	if Z.db.clicks[Z.class] == nil then
		local binds = {}
		for key, ids in pairs(Z.clickDefaults[Z.class] or {}) do
			for _, id in ipairs(ids) do
				if Z.Knows(id) then
					binds[key] = Z.SpellName(id)
					break
				end
			end
		end
		-- Si le grimoire n'est pas encore chargé, on réessaiera au prochain changement de sorts
		if next(binds) or not Z.clickDefaults[Z.class] then
			Z.db.clicks[Z.class] = binds
			if Z.header then Z:ApplyClicks() end
		end
	end
end
