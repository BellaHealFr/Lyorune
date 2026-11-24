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
--  10. Z.groupHeals.MACLASSE : ses soins sans cible (de zone, sur soi, totems), pour « Sorts et raccourcis »
--  11. Z.cooldownSpells.MACLASSE : ses gros sorts à recharge, montrés dans « Mes recharges » même sans raccourci
--  12. Z.groupCooldowns.MACLASSE : ceux que ses alliés voient dans « Recharges du groupe » (s'il a Lyorune)
--  13. Z.totemSlots.MACLASSE : les noms de ses emplacements de totems, si elle en pose (« Mes totems »)
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
	PRIEST  = { 139, 17, 431622, 401859, 6346, 552, 10060 }, -- Rénovation, Mot de pouvoir : Bouclier, Égide divine, Prière de guérison, Gardien de peur, Abolir maladie, Infusion de puissance
	DRUID   = { 774, 8936, 408120, 2893, 29166 },      -- Récupération, Rétablissement, Croissance sauvage, Abolir le poison, Innervation
	PALADIN = { 1022, 6940, 1044, 19752, 1310911, 1328548 }, -- Bénédictions de protection, de sacrifice, de liberté, Intervention divine, Veille de la Lumière, Serment de lumière (sorts de WoW Forever)
	SHAMAN  = { 22419, 408514 },                       -- Remous, Bouclier de terre
}

-- Boucliers d'absorption parmi mes sorts suivis : avec le chiffre du bouclier (absorbText), l'ancien affichage
-- des icônes (Auras.lua) écrit sur l'icône ce qui reste à absorber, quand le jeu laisse lire l'aura. Tous rangs.
Z.absorbSpells = { 17, 431622 }                       -- Mot de pouvoir : Bouclier, Égide divine

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
	[1310911] = { 1310909, 1311593, 1311597 },                                 -- Veille de la Lumière : le buff laissé, rangs 1 à 3
	-- Buffs de Z.raidBuffs et Z.uniqueBuffs : le jeu les dessine en combat sur les cases (Containers.lua, repères
	-- des buffs), seulement aux numéros donnés. Vérifiés hors jeu (HealKit, PallyPower, VuhDo, WhatsTraining).
	[1243]  = { 1244, 1245, 2791, 10937, 10938 },                              -- Mot de pouvoir : Robustesse
	[21562] = { 21564 },                                                       -- Prière de robustesse
	[14752] = { 14818, 14819, 27841 },                                         -- Esprit divin
	[976]   = { 10957, 10958 },                                                -- Protection contre l'Ombre
	[588]   = { 7128, 602, 1006, 10951, 10952 },                               -- Feu intérieur
	[2652]  = { 19261, 19262, 19264, 19265, 19266 },                           -- Toucher de faiblesse
	[18137] = { 19308, 19309, 19310, 19311, 19312 },                           -- Garde de l'ombre
	[19740] = { 19834, 19835, 19836, 19837, 19838, 25291 },                    -- Bénédiction de puissance
	[19742] = { 19850, 19852, 19853, 19854, 25290 },                           -- Bénédiction de sagesse
	[20911] = { 20912, 20913, 20914 },                                         -- Bénédiction du sanctuaire
	[465]   = { 10290, 643, 10291, 1032, 10292, 10293 },                       -- Aura de dévotion
	[7294]  = { 10298, 10299, 10300, 10301 },                                  -- Aura de vindicte
	[19876] = { 19895, 19896 },                                                -- Aura de résistance à l'Ombre
	[19888] = { 19897, 19898 },                                                -- Aura de résistance au Givre
	[19891] = { 19899, 19900 },                                                -- Aura de résistance au Feu
	[324]   = { 325, 905, 945, 8134, 10431, 10432 },                           -- Bouclier de foudre
	[1126]  = { 5232, 6756, 5234, 8907, 9884, 9885 },                          -- Marque du fauve
	[21849] = { 21850 },                                                       -- Don du fauve
	[467]   = { 782, 1075, 8914, 9756, 9910 },                                 -- Épines
	[1459]  = { 1460, 1461, 10156, 10157 },                                    -- Intelligence des arcanes
}

-- Actions proposées à toutes les classes, en plus des sorts (C18) : les clics de départ prennent le clic gauche et
-- le clic droit : Cibler et Menu du joueur ont donc leur ligne, sur Alt (pris par aucun clic de départ). Posées
-- seulement sur une combinaison libre (Z.AddClickActions, Clicks.lua), au premier lancement et à la mise à jour.
Z.clickActions = { ["alt-1"] = "@target", ["alt-2"] = "@menu" }

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

-- Soins sans cible (de zone, sur soi, totems) : le jeu ne les dit pas « utilisables sur un allié », mais
-- « Sorts et raccourcis » les propose quand même (Z:KnownSpells), comme tous les sorts de ma classe listés
-- dans ce fichier. Numéros vérifiés hors jeu (HealKit, HealBot et VuhDo portés sur Forever) ; un sort que je
-- ne connais pas n'est pas proposé.
Z.groupHeals = {
	PRIEST = { 15237, 596, 13908 },     -- Nova sacrée, Prière de soins, Prière du désespoir
	DRUID  = { 740 },                   -- Tranquillité
	SHAMAN = { 5394, 16190 },           -- Totem guérisseur, Totem de vague de mana
}

-- Gros sorts à recharge (« Mes recharges », Cooldowns.lua) : montrés dès qu'ils sont connus, même sans raccourci.
-- Les sorts de mes raccourcis dont la recharge dépasse la recharge globale s'y ajoutent tout seuls : cette liste
-- ne sert qu'aux sorts qu'on lance d'une barre (Innervation, Rapidité de la nature...). Numéros vérifiés hors jeu
-- (HealKit, HealBot, VuhDo et ArcAuras portés sur Forever) ; un sort inconnu ou sans recharge n'apparaît pas.
Z.cooldownSpells = {
	PRIEST  = { 402261, 401859, 6346, 10060, 14751, 13908 }, -- Pénitence, Prière de guérison, Gardien de peur, Infusion de puissance, Focalisation intérieure, Prière du désespoir
	DRUID   = { 18562, 408120, 29166, 17116, 20484, 740 },   -- Prompte guérison, Croissance sauvage, Innervation, Rapidité de la nature, Renaissance, Tranquillité
	PALADIN = { 20473, 633, 1022, 6940, 1044, 20216, 642, 19752 }, -- Choc sacré, Imposition des mains, Bénédictions de protection, de sacrifice, de liberté, Faveur divine, Bouclier divin, Intervention divine
	SHAMAN  = { 408521, 16188, 16190 },                      -- Remous, Rapidité de la nature, Totem de vague de mana
}

-- Recharges du groupe : les sorts qui comptent pour les autres (résurrection en combat, mana, protection posée
-- sur un allié, gros soin de groupe). Chacun annonce les siens à ses alliés qui ont Lyorune ; un numéro absent
-- de cette liste n'est jamais accepté d'un autre joueur. Tous sont aussi dans Z.cooldownSpells.
Z.groupCooldowns = {
	PRIEST  = { 10060, 6346 },               -- Infusion de puissance, Gardien de peur
	DRUID   = { 20484, 29166, 740 },         -- Renaissance, Innervation, Tranquillité
	PALADIN = { 633, 1022, 6940, 19752 },    -- Imposition des mains, Bénédictions de protection et de sacrifice, Intervention divine
	SHAMAN  = { 16190 },                     -- Totem de vague de mana
}

-- Emplacements de totems (« Mes totems », Totems.lua) : un nom par emplacement du jeu (GetTotemInfo 1, 2...), dans
-- l'ordre de la rangée. Vérifié hors jeu (ArcAuras porté sur Forever) : 1 Feu, 2 Terre, 3 Eau, 4 Air.
Z.totemSlots = {
	SHAMAN = { "Feu", "Terre", "Eau", "Air" },
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
--   blessing = { id }    bénédictions : chaque joueur en veut une de moi ; laquelle : grille « Bénédiction par
--                        joueur » (Z.blessingSlots), sans reprendre celle qu'un autre paladin a posée ou annoncée
--                        (Z.BlessingFor, BuffAssign.lua)
--   weapon = { id }      enchantement de mon arme principale (le jeu le dit à part, pas dans les auras) : le
--                        dernier que j'ai lancé, sinon le premier connu de la liste
--   aura = { id }        auras du paladin : une des miennes suffit ; la dernière lancée, sinon la première connue
--   Un sort passif sur ce client (Augure de clarté, d'après HealKit) n'est jamais proposé (Z.IsPassive).
--   racial = true       sort de race : absent de « Mes buffs » si mon personnage ne l'a pas
--   La version de groupe a sa propre ligne dans « Mes buffs » (réglage buffWatch[son numéro]) : décochée, le
--   panneau ne propose que la version simple, joueur par joueur (aucun composant dépensé) ; seule cochée, des
--   lignes « Groupe N » seulement (sans composant : la version simple, sinon rien ne pourrait être lancé).
--   pve = false, pvp = false : décoché au départ dans « Mes buffs » (options), en JcE ou en JcJ. Aucun buff ne
--                        l'est aujourd'hui : tous sont actifs au départ (demande de l'auteur, 22 novembre 2026)
-- Le premier numéro de la ligne la désigne dans le réglage « buffWatch ». Numéros vérifiés hors jeu (HealKit,
-- PallyPower et VuhDo portés sur Forever) ; un sort que je ne connais pas est ignoré (Z.Knows).
Z.raidBuffs = {
	PRIEST = {
		{ 1243, 21562 },                -- Mot de pouvoir : Robustesse, Prière de robustesse
		{ 14752, 27681, mana = true },  -- Esprit divin, Prière d'Esprit
		{ 976, 27683 },                 -- Protection contre l'Ombre, Prière de protection contre l'Ombre
		{ 588, self = true },           -- Feu intérieur
		{ 2652, self = true, racial = true },  -- Toucher de faiblesse (sort de race)
		{ 18137, self = true, racial = true }, -- Garde de l'ombre (sort de race)
	},
	PALADIN = {
		{ blessing = { 19740, 19742, 20217, 20911 } }, -- Bénédictions de puissance, de sagesse, des rois, du sanctuaire
		{ 25780, self = true },         -- Fureur vertueuse
		{ aura = { 465, 19746, 7294, 20218, 19876, 19888, 19891 }, self = true }, -- Auras : dévotion, concentration,
		                                -- châtiment, sainteté, résistance à l'ombre, au givre, au feu (listées par HealBot)
	},
	SHAMAN = {
		{ 408510, any = { 324 }, self = true },        -- Bouclier d'eau, ou Bouclier de foudre
		{ weapon = { 8024, 8017, 8232, 8033 }, self = true }, -- Arme Langue de feu, Croque-roc, Furie-des-vents, Arme de givre
	},
	DRUID  = {
		{ 1126, 21849 },                -- Marque du fauve, Don du fauve
		{ 16864, self = true },         -- Augure de clarté (ignoré s'il est passif sur ce client)
	},
	MAGE   = { { 1459, 23028, mana = true } },  -- Intelligence des arcanes, Illumination des arcanes
}

-- Buffs à poser sur une seule personne, hors combat : le panneau des buffs manquants les propose pour le
-- tank, ou pour le joueur choisi par /lyorune porteur. Rien n'est proposé tant que le mien est sur quelqu'un,
-- ni pendant son temps de recharge. Un numéro seul, ou { id, pve = false, pvp = false } comme plus haut.
Z.uniqueBuffs = {
	SHAMAN  = { 408514 },                             -- Bouclier de terre
	DRUID   = { 467 },                                -- Épines
	PRIEST  = { 6346 },                               -- Gardien de peur
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

-- Grille « Bénédiction par joueur » (Mes buffs, paladin) : une ligne par type de joueur, dans cet ordre. Rôle du
-- joueur d'abord (TANK, HEALER), sinon sa classe. Une classe ajoutée au jeu : une entrée de plus ici, et son nom
-- dans Z.blessingSlotNames. Départ d'une ligne : Z.blessingFor[ligne], sinon MANA (soigneur, classe à mana) ou OTHER.
Z.blessingSlots = { "TANK", "HEALER", "WARRIOR", "ROGUE", "HUNTER", "PALADIN", "SHAMAN", "DRUID", "PRIEST", "MAGE", "WARLOCK" }
Z.blessingSlotNames = { TANK = "Tanks", HEALER = "Soigneurs", WARRIOR = "Guerrier", ROGUE = "Voleur", HUNTER = "Chasseur",
	PALADIN = "Paladin", SHAMAN = "Chaman", DRUID = "Druide", PRIEST = "Prêtre", MAGE = "Mage", WARLOCK = "Démoniste" }
-- Bénédictions utiles seulement aux joueurs à mana (Sagesse) : jamais proposées à un guerrier ou un voleur, même
-- quand un autre paladin a déjà posé toutes les autres
Z.manaBlessings = { [19742] = true }

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
	PALADIN = { { 25771 } },                -- Longanimité (après Bouclier divin, Protection divine, Bénédiction de protection)
}
Z.LOCKOUT_COUNT = 1 -- affaiblissements de ce genre montrés au plus sur une case

-- Boisson : un soigneur qui boit le montre sur sa case, à côté de sa mana basse (réglage « drinkHealers »).
-- Les numéros des boissons du jeu (eau de chaque niveau, eau invoquée) ; ceux dont le nom, lu dans le jeu,
-- n'est pas celui du premier sont ignorés (Z:BuildData).
-- Liste complétée par la recherche dans le jeu du 21 novembre 2026 (build 71037) : 18 numéros nommés « Boisson ».
Z.drinkSpells = { 430, 431, 432, 1133, 1135, 1137, 10250, 22734, 24355, 25696, 26261, 26402, 26473, 26475, 29007,
	446714, 468767, 1330734 }

-- Affaiblissements sans intérêt pour un soigneur, jamais dans la rangée des affaiblissements (Longanimité reste
-- montrée au paladin, au bout de ses soins : Z.lockouts)
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

-- Sort passif (il ne se lance pas) : jamais proposé comme buff. Réponse absente ou secrète : non.
function Z.IsPassive(id)
	local passive = C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(id)
	return passive == true
end

-- Tous les numéros d'une ligne de Z.raidBuffs ; le premier désigne la ligne (réglage « buffWatch »)
function Z.BuffIds(entry)
	local ids = {}
	for _, list in ipairs({ entry.blessing or {}, entry.weapon or {}, entry.aura or {}, entry, entry.any or {} }) do
		for _, id in ipairs(list) do ids[#ids + 1] = id end
	end
	return ids
end

-- Une ligne de Z.raidBuffs lue dans le grimoire : nil si je ne connais aucun sort à lancer.
-- spell : le sort lancé ; groupSpell : sa version de groupe ; choices : les bénédictions ou les armes connues.
function Z.BuffCheck(entry)
	local ids = Z.BuffIds(entry)
	local check = { id = ids[1], ids = ids, names = {}, self = entry.self, mana = entry.mana, pve = entry.pve,
		pvp = entry.pvp }
	for _, id in ipairs(ids) do
		local name = Z.SpellName(id)
		if name then check.names[name] = true end
	end
	local choices = entry.blessing or entry.weapon or entry.aura
	if choices then
		check.choices = {}
		for _, id in ipairs(choices) do
			local name = Z.Knows(id) and Z.SpellName(id)
			if name then check.choices[#check.choices + 1] = { id = id, name = name, icon = Z.SpellIcon(id) } end
			if entry.weapon then Z.weaponIds[id] = true end
			if not entry.blessing then Z.choiceIds[id] = check.id end -- le dernier lancé sera proposé (Z.LastChoice)
		end
		if #check.choices == 0 then return end
		check.blessing, check.weapon, check.aura = entry.blessing ~= nil, entry.weapon ~= nil, entry.aura ~= nil
		check.spell, check.icon = check.choices[1].name, check.choices[1].icon
		return check
	end
	-- le premier sort connu : la version simple, sinon un des autres sorts qui comptent aussi
	local castable = { entry[1] }
	for _, id in ipairs(entry.any or {}) do castable[#castable + 1] = id end
	for _, id in ipairs(castable) do
		if Z.Knows(id) and not Z.IsPassive(id) then
			check.spell, check.icon = Z.SpellName(id), Z.SpellIcon(id)
			break
		end
	end
	if not check.spell then return end
	local group = entry[2] and Z.Knows(entry[2]) and Z.SpellName(entry[2])
	if group and group ~= check.spell then check.groupSpell, check.groupId = group, entry[2] end
	return check
end

-- La liste qui compte ici : « pvp » en champ de bataille et en arène, « pve » partout ailleurs
function Z.BuffContext()
	return Z.PvPKind and Z.PvPKind() and "pvp" or "pve"
end

-- Je connais la version de groupe de ce buff (Prière de robustesse...) et elle est cochée ici
function Z.GroupWanted(check)
	return check.groupSpell ~= nil and Z.BuffWatched({ id = check.groupId })
end

-- La version de groupe à proposer : voulue, et lançable maintenant. Sans son composant (Chandelle sacrée...), le
-- jeu la dit inutilisable : les buffs se posent un par un (réponse secrète ou fonction absente : on la propose).
function Z.GroupSpell(check)
	if not Z.GroupWanted(check) then return end
	local usable = C_Spell.IsSpellUsable and C_Spell.IsSpellUsable(check.groupSpell)
	if not Z.IsSecret(usable) and usable == false then return end
	return check.groupSpell
end

-- Ce buff est-il dans ma liste (« Mes buffs », options) pour ce lieu ? Mon choix, sinon le départ de Data.lua
function Z.BuffWatched(check, context)
	context = context or Z.BuffContext()
	local chosen = Z.db.buffWatch[check.id]
	if type(chosen) == "table" and chosen[context] ~= nil then return chosen[context] end
	return check[context] ~= false
end

-- Ce buff est-il suivi d'une façon ou d'une autre : sa version simple ou sa version de groupe cochée. Les deux se
-- cochent séparément : simple seule = une ligne par joueur ; groupe seule = des lignes « Groupe N » seulement.
function Z.BuffFollowed(check)
	return Z.BuffWatched(check) or Z.GroupWanted(check)
end

-- Joueur à mana : sa classe n'est pas dans Z.classPower (un familier ne compte pas ; classe secrète : non)
function Z.UsesMana(unit)
	if unit:find("pet", 1, true) then return false end
	local class = select(2, UnitClass(unit))
	if not class or Z.IsSecret(class) then return false end
	return not Z.classPower[class]
end

-- Bénédiction à poser sur ce joueur : Z.BlessingFor, dans BuffAssign.lua (grille, entente entre paladins)

-- Enchantement d'arme ou aura à poser : le dernier que j'ai lancé (Z.char.lastChoice), sinon le premier connu
function Z.LastChoice(check)
	local last = Z.char and Z.char.lastChoice and Z.char.lastChoice[check.id]
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

	Z.buffChecks = {}
	Z.weaponIds = {} -- enchantements d'arme : ma case se relit quand l'arme change (Auras.lua)
	Z.choiceIds = {} -- arme ou aura lancée -> sa ligne de buff (Z.char.lastChoice)
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
	-- Noms suivis, pour la mémoire des buffs (BuffMemory.lua) : ceux de tout le monde, et les miens seulement
	-- (bénédictions, auras, buffs uniques : celui d'un autre joueur ne compte pas)
	Z.buffNames = {}
	Z.ownNames = {}
	for _, check in ipairs(Z.buffChecks) do
		for name in pairs(check.names) do
			Z.buffNames[name] = true
			if check.blessing or check.aura then Z.ownNames[name] = true end
		end
	end
	for _, check in ipairs(Z.uniqueChecks) do
		Z.ownNames[check.name] = true
	end

	-- Mes soins sans cible (Tranquillité...) : jamais de trait de canalisation sur la case cliquée (Frames.lua)
	Z.untargetedNames = {}
	for _, id in ipairs(Z.groupHeals[Z.class] or {}) do
		local name = Z.SpellName(id)
		if name then Z.untargetedNames[name] = true end
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
	Z.absorbIds = {}
	for _, id in ipairs(Z.absorbSpells) do
		Z.absorbIds[id] = true
		for rank in pairs(Z.rankIds[Z.SpellName(id) or ""] or {}) do Z.absorbIds[rank] = true end
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
	-- Numéros que le jeu dessine pour chaque buff de ma liste, quand il cache les buffs (repères des buffs,
	-- Containers.lua) : tous ses numéros connus du jeu et tous leurs rangs. L'arme n'est pas une aura : aucun.
	for _, check in ipairs(Z.buffChecks) do
		check.auraIds = nil
		if not check.weapon then
			local set = {}
			for _, id in ipairs(check.ids) do
				if Z.SpellName(id) then set[id] = true end
			end
			for name in pairs(check.names) do
				for id in pairs(Z.rankIds[name] or {}) do set[id] = true end
			end
			check.auraIds = next(set) and set or nil
		end
	end
	for _, check in ipairs(Z.uniqueChecks) do
		local set = { [check.id] = true }
		for id in pairs(Z.rankIds[check.name] or {}) do set[id] = true end
		check.auraIds = set
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
			Z.AddClickActions(binds)
			Z.db.clicks[Z.class] = binds
			if Z.header then Z:ApplyClicks() end
		end
	end
end
