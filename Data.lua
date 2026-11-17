-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Data.lua : ce que chaque classe de WoW Forever sait faire.
-- Tout est donné par identifiant de sort : le nom est traduit tout seul (client français ou anglais).

--
-- AJOUTER UNE CLASSE (par exemple si WoW Forever en introduit une) : tout se passe dans ce fichier.
--   1. Z.dispelSpells.MACLASSE  = { Magic = { id }, Curse = { id }, Disease = { id }, Poison = { id } }
--   2. Z.trackedSpells.MACLASSE = { id, id, ... }      -- ses soins sur la durée et boucliers
--   3. Z.clickDefaults.MACLASSE = { ["1"] = { id }, ["shift-1"] = { id }, ... }
--   4. Z.resSpells et Z.classRes : son sort de résurrection, s'il en a un
--   5. Z.raidBuffs.MACLASSE : ses buffs de groupe, s'il en a
-- MACLASSE est le nom interne de la classe en majuscules (PRIEST, DRUID...), affiché par /lyorune erreurs.
-- Les trois tables sont facultatives : une classe absente fonctionne quand même (cadres, clics choisis
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

-- Mes sorts à suivre sur les cadres (soins sur la durée, boucliers, protections)
Z.trackedSpells = {
	PRIEST  = { 139, 17, 401859, 6346, 552 },          -- Rénovation, Mot de pouvoir : Bouclier, Prière de guérison, Gardien de peur, Abolir maladie
	DRUID   = { 774, 8936, 408120, 2893 },             -- Récupération, Rétablissement, Croissance sauvage, Abolir le poison
	PALADIN = { 1022, 6940, 1044, 19752 },             -- Bénédictions de protection, de sacrifice, de liberté, Intervention divine
	SHAMAN  = { 22419, 408514 },                       -- Remous, Bouclier de terre
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

-- Buffs de groupe à surveiller hors combat. Chaque ligne : la version simple puis la version de groupe.
Z.raidBuffs = {
	PRIEST = { { 1243, 21562 } },  -- Mot de pouvoir : Robustesse, Prière de robustesse
	DRUID  = { { 1126, 21849 } },  -- Marque du fauve, Don du fauve
	MAGE   = { { 1459, 23028 } },  -- Intelligence des arcanes, Illumination des arcanes
}

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

	Z.buffChecks = {}
	for _, ids in ipairs(Z.raidBuffs[Z.class] or {}) do
		if Z.Knows(ids[1]) then
			-- spell : le sort lancé par le panneau des buffs ; groupSpell : sa version de groupe, si je la connais
			local check = { names = {}, icon = C_Spell.GetSpellTexture(ids[1]), spell = Z.SpellName(ids[1]) }
			for _, id in ipairs(ids) do
				local name = Z.SpellName(id)
				if name then check.names[name] = true end
			end
			local group = ids[2] and Z.Knows(ids[2]) and Z.SpellName(ids[2])
			if group and group ~= check.spell then check.groupSpell = group end
			Z.buffChecks[#Z.buffChecks + 1] = check
		end
	end

	Z.trackedNames = {}
	for _, id in ipairs(Z.trackedSpells[Z.class] or {}) do
		local name = Z.SpellName(id)
		if name then Z.trackedNames[name] = true end
	end

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
