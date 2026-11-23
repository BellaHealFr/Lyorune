-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Containers.lua : les icônes d'auras des vraies cases, dessinées par le jeu.
-- En combat, le jeu refuse à tout addon la lecture des auras (« auras secrètes »). Il prête en revanche des
-- conteneurs : Lyorune leur dit quoi montrer (filtres, numéros de sorts) et où, le jeu y dessine les auras,
-- leur durée et la couleur de dissipation. Rien n'est lu, rien ne tourne en boucle.
-- Sept conteneurs par case :
--   hots       : mes soins sur la durée en icônes (place et taille selon la forme, Z.AuraRows dans Themes.lua),
--                puis, assombri, l'affaiblissement qui bloque un de mes sorts (Âme affaiblie, Z.lockouts)
--   bars       : les mêmes en barres fines (style « Barres »)
--   debuffs    : affaiblissements (selon la forme aussi), celui que je peux dissiper en premier
--   defensives : gros défensifs posés par n'importe qui (Z.defensives, Data.lua)
--   controls   : contrôle subi (étourdi, apeuré, métamorphosé), filtre « CROWD_CONTROL » du jeu
--   drink      : la boisson d'un soigneur qui boit (Z.drinkSpells), à côté de sa mana basse
--   slots      : places fixes : un carré par coin, la bordure de dissipation, l'icône du type à dissiper, la
--                grande icône et son contour
--   buffs      : mes buffs, une place fixe chacun, montrés seulement quand le jeu cache les buffs (repères gris
--                dessous : gris = manquant, couleur = posé ; étape 26 b bis, plus bas)
-- Si le jeu n'a pas ces conteneurs, Auras.lua garde l'ancien affichage (lecture des auras).

local _, Z = ...
local issecret = Z.IsSecret

local SPACING = 2

-- Les conteneurs existent-ils dans ce client ? (lu à chaque fois : un changement de version du jeu suffit)
function Z.HasAuraBoxes()
	return AuraContainerSortMethod ~= nil and AnchorUtil ~= nil and AnchorUtil.FlowDirection ~= nil
		and Enum.CustomAuraButtonDispelTypeTextureStyle ~= nil
end

-- Une rangée peut-elle passer à la ligne (Carré) ? Le jeu le fait avec SetFlowLayoutMaximumLineSize, en pixels.
-- Sans elle, la rangée rapetisse pour tenir sur une ligne (Z.AuraRows). L'ancien affichage pose chaque icône
-- lui-même : il passe toujours à la ligne. Z.boxWrap est lu sur un premier conteneur (Probe, plus bas).
function Z.CanWrapAuras()
	if not Z.HasAuraBoxes() then return true end
	return Z.boxWrap ~= false
end

-- Appel protégé d'une méthode du jeu : une erreur est notée une fois au journal, jamais avalée sans trace
local logged = {}
local function Call(object, method, ...)
	local f = type(object) == "table" and object[method]
	if not f then return end
	local ok, result = pcall(f, object, ...)
	if ok then return result end
	if not logged[method] then
		logged[method] = true
		Z:Log("Conteneur d'auras", method .. " : " .. tostring(result), "")
		Z:Print("Conteneur d'auras, " .. method .. " : " .. tostring(result))
	end
end

-- Pour /lyorune auras : l'état de chaque conteneur de la case, tel que le jeu le voit
local function Show(value)
	if issecret(value) then return "secret" end
	return tostring(value)
end

function Z.DescribeAuraBoxes(b, Add)
	for _, name in ipairs({ "hots", "bars", "debuffs", "defensives", "controls", "drink", "slots", "buffs" }) do
		local box = b.boxes[name]
		local ok, text = pcall(function()
			local point, relative, _, x, y = box:GetPoint()
			return ("%s : montré %s, visible %s, actif %s, joueur %s, taille %dx%d, échelle %.2f, opacité %.2f, ancre %s %s %d %d"):format(
				name, Show(box:IsShown()), Show(box:IsVisible()), Show(Call(box, "IsEnabled")), Show(Call(box, "GetUnit")),
				box:GetWidth(), box:GetHeight(), box:GetScale(), box:GetEffectiveAlpha(), tostring(point),
				tostring(relative and relative.GetName and relative:GetName() or relative), x or 0, y or 0)
		end)
		Add(ok and text or (name .. " : " .. tostring(text)))
	end
	-- Les boutons dessinés par le jeu peuvent répondre par des valeurs secrètes : tout passe par Show et pcall
	local function Frame(button)
		if not button then return "aucun" end
		local ok, text = pcall(function()
			return "montré " .. Show(button:IsShown()) .. ", visible " .. Show(button:IsVisible())
				.. ", taille " .. Show(button:GetWidth()) .. " x " .. Show(button:GetHeight())
				.. ", opacité " .. Show(button:GetEffectiveAlpha())
		end)
		return ok and text or ("illisible : " .. tostring(text))
	end
	for key, list in pairs(b.boxButtons) do
		-- « dispellable » et « others » sont dans « debuffs », « lockouts » dans « hots », « lockbars » dans « bars »
		local box = b.boxes[key] or (key == "lockouts" and b.boxes.hots) or (key == "lockbars" and b.boxes.bars)
			or b.boxes.debuffs
		Add(("  groupe %s : boutons habillés %d, comptés par le jeu %s, premier %s"):format(key, #list,
			Show(Call(box, "GetAuraGroupFrameCount", key)), Frame(Call(box, "GetAuraGroupFrame", key, 1))))
	end
	for key, button in pairs(b.slots) do Add("  place " .. key .. " : " .. Frame(button)) end
	for i, entry in ipairs(b.markList or {}) do
		Add(("  repère %s : %s, %s"):format(entry.key, Frame(b.markButtons and b.markButtons[i]),
			b.marksShown and "montré" or (b.marksStale and "en attente (joueur changé en combat)" or "caché")))
	end
	for method in pairs(logged) do Add("  erreur notée : " .. method) end
end

----------------------------------------------------------------------------------------------------
-- Numéros de sorts. Le jeu filtre par numéro, Lyorune connaît des noms (réglages, listes).
-- Un nom donne : le nombre tapé par le joueur, le sort de mon grimoire, tous ses rangs (Z.spellRanks), et les numéros vus sur les auras
-- quand elles étaient lisibles (hors combat), gardés dans LyoruneDB.auraIds pour les sessions suivantes.
----------------------------------------------------------------------------------------------------
local function Seen()
	Z.db.auraIds = Z.db.auraIds or {}
	return Z.db.auraIds
end

local function AddIds(set, name)
	if type(name) ~= "string" or name == "" then return end
	local number = tonumber(name)
	if number then set[number] = true return end
	local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(name)
	if type(info) == "table" and info.spellID then set[info.spellID] = true end
	for id in pairs(Z.rankIds and Z.rankIds[name] or {}) do set[id] = true end -- tous les rangs (Data.lua)
	local seen = Seen()[name]
	if type(seen) == "table" then
		for id in pairs(seen) do set[id] = true end
	end
end

local function Empty(set) return next(set) == nil end

-- Les numéros voulus par chaque élément, selon les réglages et la classe jouée
local function Wanted()
	local db = Z.db
	local corners, inCorner = {}, {}
	for point, name in pairs(Z.MyCorners()) do
		if name ~= "" then
			local set = {}
			AddIds(set, name)
			if not Empty(set) then
				corners[point] = set
				for id in pairs(set) do inCorner[id] = true end
			end
		end
	end
	local hots = {}
	for _, id in ipairs(Z.trackedSpells[Z.class] or {}) do
		hots[id] = true
		AddIds(hots, Z.SpellName(id))
	end
	for name in pairs(db.extraTracked) do AddIds(hots, name) end
	for id in pairs(inCorner) do hots[id] = nil end -- un sort placé dans un coin n'est plus dans la rangée
	-- Gros défensifs : montrés à part pour tout lanceur, ils quittent la rangée de mes soins (jamais deux fois)
	local defensives = {}
	if db.showDefensives then
		for id in pairs(Z.defensiveIds or {}) do
			defensives[id] = true
			hots[id] = nil
		end
	end
	local ignored = {}
	for id in pairs(Z.ignoredDebuffs) do ignored[id] = true end
	for name in pairs(db.ignoredNames) do AddIds(ignored, name) end
	-- Affaiblissement qui bloque un de mes sorts : au bout de mes soins, il quitte la rangée des affaiblissements
	local lockouts = {}
	if Z.ShowsLockouts() then
		for id in pairs(Z.lockoutIds) do
			lockouts[id] = true
			ignored[id] = true
		end
	end
	-- Ma liste « À mettre en avant » gagne sur « À ignorer » (pas sur le sort bloqué, montré au bout de mes soins)
	local important, listed, rowIgnored = {}, {}, {}
	for name in pairs(db.importantNames) do AddIds(important, name) end
	for id in pairs(important) do
		if not lockouts[id] then
			ignored[id] = nil
			listed[id] = true
		end
	end
	-- Rangée des affaiblissements : ma liste a son propre groupe en tête, les autres groupes l'écartent (aucun doublon)
	for id in pairs(ignored) do rowIgnored[id] = true end
	for id in pairs(listed) do rowIgnored[id] = true end
	return hots, corners, ignored, important, defensives, lockouts, listed, rowIgnored
end

-- Un nom qui intéresse Lyorune (soins suivis, coins, listes) : son numéro vaut la peine d'être retenu
local function Interesting(name)
	local db = Z.db
	if Z.trackedNames[name] or db.extraTracked[name] or db.ignoredNames[name] or db.importantNames[name] then
		return true
	end
	for _, wanted in pairs(Z.MyCorners()) do
		if wanted == name then return true end
	end
end

-- Un nom de liste est-il reconnu par son numéro ? (sinon le jeu ne peut pas le trouver en combat, nom secret)
-- Rend nil sans numéro. Avec outsideLockouts : faux si tous ses numéros sont des sorts bloqués (Âme affaiblie),
-- montrés au bout de mes soins et jamais dans la rangée des affaiblissements.
function Z.KnownAuraIds(name, outsideLockouts)
	local set = {}
	AddIds(set, name)
	if Empty(set) then return nil end
	if outsideLockouts and Z.ShowsLockouts() then
		for id in pairs(Z.lockoutIds) do set[id] = nil end
		if Empty(set) then return false end
	end
	return true
end

-- Numéro pris dans un lien de sort glissé dans une liste : retenu pour ce nom, comme un numéro vu hors combat
-- Rend vrai si le numéro est nouveau pour ce nom
function Z.RememberAuraId(name, id)
	if type(name) ~= "string" or name == "" or type(id) ~= "number" then return end
	local seen = Seen()
	if type(seen[name]) ~= "table" then seen[name] = {} end
	if seen[name][id] then return end
	seen[name][id] = true
	return true
end

-- Appelé par Auras.lua quand une aura est lisible (hors combat) : un numéro nouveau met les filtres à jour
local refilterQueued -- nil, « boxes » (filtres) ou « all » (la rangée change de taille)
function Z.LearnAuraId(name, id)
	if not name or not id or issecret(name) or issecret(id) or not Z.HasAuraBoxes() then return end
	if not Interesting(name) then return end
	local listed = Z.db.importantNames[name] and Z.DebuffPlaces()
	if not Z.RememberAuraId(name, id) then return end
	if Z.db.importantNames[name] and Z.RefreshOptionPages then Z.RefreshOptionPages() end -- le nom n'est plus gris
	if not refilterQueued then
		C_Timer.After(0, function()
			local all = refilterQueued == "all"
			refilterQueued = nil
			if all then Z:Refresh() else Z:Try("filtres des auras", Z.RefreshAuraBoxes) end
		end)
	end
	-- Un nom de « À mettre en avant » reconnu peut ouvrir une place dans la rangée : tout est remesuré
	if listed and Z.DebuffPlaces() ~= listed then refilterQueued = "all" else refilterQueued = refilterQueued or "boxes" end
end

----------------------------------------------------------------------------------------------------
-- Habillage des boutons créés par le jeu. Ce sont des objets protégés : leurs textures viennent toutes de
-- Containers.xml. Lyorune ne les touche que pendant leur création (le jeu l'y autorise), ou plus tard quand
-- le jeu répond qu'ils sont accessibles (CanBeAccessedInContext). Tout passe par Call : jamais d'erreur.
----------------------------------------------------------------------------------------------------
-- Élément déclaré dans Containers.xml (nil s'il manque)
local function Part(object, key)
	return type(object) == "table" and object[key] or nil
end

local function Open(button)
	return button ~= nil and Call(button, "CanBeAccessedInContext") == true
end

local function Silent(button)
	Call(button, "EnableMouse", false) -- les clics vont à la case (clic-soin), jamais aux icônes
	Call(button, "SetMouseClickEnabled", false)
	Call(button, "SetMouseMotionEnabled", false)
end

-- Secondes restantes d'un groupe d'icônes qui n'est pas celui de mes soins (1.43.0) : affaiblissements et contrôle
-- subi (« debuffCountdown »), sort que je ne peux pas relancer (« lockoutCountdown ») ; jamais les gros défensifs
local function Numbers(key)
	local db = Z.db
	if key == "lockouts" then return db.lockoutCountdown and true or false end
	if key == "listedRow" or key == "dispellable" or key == "others" or key == "controls" then return db.debuffCountdown and true or false end
	return false
end

-- Réglages d'une icône : cercle, décompte (police à la taille de l'icône), charges, voile de fin (seulement pour
-- mes soins). numbers : secondes restantes d'une autre icône (Numbers)
local function StyleIcon(button, mine, size, numbers)
	local db = Z.db
	local cooldown = button.Cooldown
	if mine then numbers = db.hotCountdown end
	Call(cooldown, "SetDrawSwipe", not mine or db.hotSwipe)
	Call(cooldown, "SetHideCountdownNumbers", not numbers)
	if numbers then Call(cooldown, "SetCountdownFont", Z.CountdownFont(size)) end
	Call(button.Texts, "SetAlpha", (not mine or db.hotCharges) and 1 or 0)
	Call(button.Veil, "SetAlpha", (mine and db.hotFade) and 1 or 0)
end

-- Icône d'aura ; mine = un de mes soins ; size = taille de sa rangée ; edge = couleur du liseré (noir sinon) ;
-- dark = assombrie (un sort que je ne peux pas relancer) ; numbers = secondes restantes (StyleIcon) ; typed =
-- liseré à la couleur du type de l'affaiblissement, posée par le jeu (même en combat), noir sans type
local function DressIcon(button, mine, size, edge, dark, numbers, typed)
	Silent(button)
	if typed then
		Call(button.Edge, "SetColorTexture", 1, 1, 1, 1)
		Call(button.Edge, "SetVertexColor", 0, 0, 0, 1)
		Call(button, "AddDispelTypeTexture", button.Edge, {
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
			showWhenHarmful = true, showWhenHelpful = false, showWithoutDispelType = true, -- sans type : noir
			customDispelColorCurve = Z.EdgeCurve(),
		})
	end
	if dark then
		Call(button.Icon, "SetDesaturated", true)
		Call(button.Icon, "SetVertexColor", Z.LOCKOUT_SHADE, Z.LOCKOUT_SHADE, Z.LOCKOUT_SHADE)
	end
	if edge then Call(button.Edge, "SetColorTexture", edge[1], edge[2], edge[3], 1) end
	Call(button.Texts, "SetFrameLevel", (Call(button.Cooldown, "GetFrameLevel") or 1) + 1)
	Call(button, "SetIcon", button.Icon)
	Call(button, "SetDurationCooldown", button.Cooldown)
	Call(button, "SetApplicationCount", Part(button.Texts, "Count"), {})
	-- Fin du soin : le jeu montre ce voile pendant les derniers instants (réglage « hotFade »)
	if mine then Call(button, "AddPandemicRegion", button.Veil) end
	StyleIcon(button, mine, size, numbers)
end

-- Barre fine : couleur selon son rang (grise pour un sort que je ne peux pas relancer), largeur selon la case
local function DressBar(button, index, color)
	Silent(button)
	color = color or Z.BAR_COLORS[index] or Z.BAR_COLORS[1]
	Call(button.Bar, "SetStatusBarColor", color[1], color[2], color[3])
	Call(button.Bar, "SetWidth", math.floor(Z.CellSize() * 0.45))
	Call(button, "SetDurationBar", button.Bar, { direction = Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime })
end

-- Places fixes : position et taille, refaites à chaque changement d'options quand le jeu l'autorise
local function PlaceCorner(b, button, point)
	local size, sign = Z.CornerSize(b), Z.CORNER_SIGN[point]
	Call(button, "SetSize", size, size)
	Call(button, "ClearAllPoints")
	Call(button, "SetPoint", point, b.boxes.slots, point, sign[1] * 2, sign[2] * 2)
end

local function PlaceBig(b, button)
	local db = Z.db
	local dx, dy = Z.Offset("big")
	local big = Z.BigIconSize()
	Call(button, "SetAllPoints", b.boxes.slots)
	Call(button.Face, "SetSize", big, big)
	Call(button.Face, "ClearAllPoints")
	Call(button.Face, "SetPoint", "LEFT", button, "LEFT", 3 + dx, dy)
	Call(button.Face, "SetShown", db.bossDebuffs)
	Call(button.Glow, "SetShown", db.importantGlow)
	-- secondes restantes, comme les autres affaiblissements (1.43.0)
	local cooldown = Part(button.Face, "Cooldown")
	Call(cooldown, "SetHideCountdownNumbers", not db.debuffCountdown)
	if db.debuffCountdown then Call(cooldown, "SetCountdownFont", Z.CountdownFont(big)) end
end

-- Icône du type à dissiper (1.43.0) : place et taille de Z.DispelTypePlace (Auras.lua), comme sur les fausses cases
local function PlaceType(b, button)
	local relative, x, y, size = Z.DispelTypePlace()
	Call(button, "SetSize", size, size)
	Call(button, "ClearAllPoints")
	Call(button, "SetPoint", "LEFT", relative == "HP" and b.hp or b.boxes.slots, "LEFT", x, y)
end

-- Repère d'un buff : la place numéro « index » de la rangée qui part du coin bas gauche (Z.BuffMarkPlace)
local function PlaceMark(b, button, index)
	local x, y, size = Z.BuffMarkPlace(b)
	Call(button, "SetSize", size, size)
	Call(button, "ClearAllPoints")
	Call(button, "SetPoint", "BOTTOMLEFT", b.boxes.buffs, "BOTTOMLEFT", x + (index - 1) * (size + 2), y)
end

-- Le buff posé, en couleur, sans durée ni voile : il dit seulement « il est là » et cache le repère gris dessous
local function DressMark(b, index)
	return function(button)
		Silent(button)
		Call(button, "SetIcon", button.Icon)
		Call(button.Texts, "SetAlpha", 0)
		PlaceMark(b, button, index)
	end
end

local function DressCorner(b, point)
	return function(button)
		Silent(button)
		local color = Z.CORNER_COLORS[point]
		Call(button.Fill, "SetVertexColor", color[1], color[2], color[3], 1)
		Call(button, "SetDurationCooldown", button.Cooldown)
		PlaceCorner(b, button, point)
	end
end

local function DressDispel(b)
	return function(button)
		Silent(button)
		Call(button, "SetAllPoints", b.boxes.slots)
		local function Options(veil)
			return {
				style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
				showWhenHarmful = true, showWhenHelpful = false,
				customDispelColorCurve = Z.DispelCurve(veil),
			}
		end
		local edge = Options(false)
		for _, key in ipairs({ "Top", "Bottom", "Left", "Right" }) do
			Call(button, "AddDispelTypeTexture", button[key], edge)
		end
		-- voile léger : la vie reste visible dessous (une opacité pleine cachait toute la barre)
		Call(button, "AddDispelTypeTexture", button.Fill, Options(true))
	end
end

-- Le jeu y pose l'image du type du premier affaiblissement que je peux dissiper (style « Icon »)
local function DressType(b)
	return function(button)
		Silent(button)
		Call(button, "AddDispelTypeTexture", button.Type, {
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.Icon, showWhenHarmful = true, showWhenHelpful = false,
		})
		PlaceType(b, button)
	end
end

local function DressBig(b)
	return function(button)
		Silent(button)
		Call(button, "SetIcon", Part(button.Face, "Icon"))
		Call(button, "SetDurationCooldown", Part(button.Face, "Cooldown"))
		Call(Part(button.Glow, "Pulse"), "Play")
		PlaceBig(b, button)
	end
end

----------------------------------------------------------------------------------------------------
-- Construction des conteneurs d'une case.
-- Règles du jeu, vérifiées sur Forever :
--   * ordre : créer, ancrer, SetUnit, AddAuraGroup / AddAuraSlot, SetEnabled(true) en dernier ;
--   * jamais de création ni de SetEnabled en combat : la construction attend la fin du combat ;
--   * un filtre ne se modifie pas : un réglage changé reconstruit les conteneurs (l'ancien est caché).
----------------------------------------------------------------------------------------------------
local function NilIfEmpty(set) if set and next(set) then return set end end

----------------------------------------------------------------------------------------------------
-- Repères des buffs (étape 26 b bis, choix de l'auteur le 22 novembre 2026). Quand le jeu cache les buffs (combat,
-- champ de bataille, arène), Lyorune ne peut plus lire qu'un buff manque. Chaque buff de ma liste qui
-- concerne ce joueur (décidé hors combat, mêmes règles que le panneau : Z.BuffConcerns) reçoit un repère gris à bord
-- rouge (Z.BuffMark, Auras.lua) et une place du conteneur « buffs », juste au-dessus : le jeu y dessine le buff en
-- couleur quand il est là. Gris = manquant, couleur = posé. Un seul conteneur par case (pas un par buff), tous les
-- rangs du buff (Z.spellRanks, Data.lua), bénédictions, auras et buffs uniques : seulement les miens.
----------------------------------------------------------------------------------------------------
local fighting = false -- entre PLAYER_REGEN_DISABLED et PLAYER_REGEN_ENABLED (le verrou arrive juste après)

-- Deux interrupteurs (1.37.1, retour d'un joueur) : en champ de bataille et en arène, seul « pvpBuffs » décide ;
-- ailleurs (combat, boss hors combat), seul « combatBuffs ».
function Z.BuffMarksOn()
	local db = Z.db
	if not (db and db.missingBuffs) then return false end
	if Z.PvPKind and Z.PvPKind() then
		if not db.pvpBuffs then return false end
	elseif not db.combatBuffs then
		return false
	end
	return fighting or InCombatLockdown() or Z.AurasHidden()
end

function Z.BuffMarksShown(b)
	return b.boxes ~= nil and b.marksShown == true
end

-- Porteur de chaque buff unique (Z.UniqueBearer, Buffs.lua), cherché une fois par image pour toutes les cases
local bearers, bearersAt = {}, nil
local function Bearer(check)
	local now = GetTime()
	if bearersAt ~= now then bearers, bearersAt = {}, now end
	if bearers[check.id] == nil then bearers[check.id] = Z.UniqueBearer and Z.UniqueBearer(check) or false end
	return bearers[check.id] or nil
end

-- Les buffs suivis sur cette case : { key, filter, ids, icon }. Rien en combat (rien n'y est sûr : la case attend).
local function Marks(b)
	local db, list = Z.db, {}
	local unit = b.unit
	-- préparés dès qu'un des deux interrupteurs est allumé : Z.BuffMarksOn choisit selon le lieu, sans reconstruire
	if not (db.missingBuffs and (db.combatBuffs or db.pvpBuffs)) or b.extra or not unit or InCombatLockdown() then return list end
	local me = UnitIsUnit(unit, "player")
	if issecret(me) then return list end
	for _, check in ipairs(Z.buffChecks or {}) do
		if check.auraIds and Z.BuffConcerns(check, unit, me) then
			local own = check.blessing or check.aura
			local choice = check.blessing and Z.BlessingFor(check, unit) or (check.aura and Z.LastChoice(check))
			if choice or not check.blessing then -- (aucune bénédiction prévue pour lui : grille, autres paladins)
				list[#list + 1] = { box = "buffs", key = "buff" .. check.id, filter = own and "HELPFUL|PLAYER" or "HELPFUL", ids = check.auraIds,
					icon = choice and choice.icon or check.icon }
			end
		end
	end
	if not unit:find("pet", 1, true) then
		for _, check in ipairs(Z.uniqueChecks or {}) do
			local bearer = Z.BuffWatched(check) and Bearer(check)
			local same = bearer and UnitIsUnit(unit, bearer)
			if same and not issecret(same) then
				list[#list + 1] = { box = "buffs", key = "buff" .. check.id, filter = "HELPFUL|PLAYER", ids = check.auraIds, icon = check.icon }
			end
		end
	end
	return list
end

-- « Utiles » : le jeu trie comme pour ses cadres de raid si ce client sait le faire (politique de traitement des
-- auras) ; sinon seule la durée trie
local USEFUL_SECONDS = 300
function Z.UsefulPolicy()
	local changed = AuraUtil and AuraUtil.AuraUpdateChangedType
	return (changed and changed.Debuff and CustomAuraContainerAuraProcessingPolicy
		and CustomAuraContainerAuraProcessingPolicy.ProcessAura) and true or false
end

-- Ce que les conteneurs d'une case doivent montrer, selon les réglages et la classe jouée.
-- Chaque entrée : conteneur, clé, filtre du jeu, filtres de candidats, nombre (groupes) ou place fixe.
local function Plan(b)
	local db = Z.db
	local hots, corners, ignored, important, defensives, lockouts, listedIds, rowIgnored = Wanted()
	-- Ce que le jeu ne laisse régler qu'à la création d'un bouton (il le protège ensuite) : place et taille de la
	-- grande icône, taille des coins, largeur des barres, taille et coin de départ des rangées (Z.AuraRows),
	-- réglages des icônes. Un changement reconstruit les conteneurs (en combat : à la fin du combat).
	local rows = b.rows or Z.AuraRows()
	local bigX, bigY = Z.Offset("big")
	local drinkSize = select(3, Z.DrinkPlace())
	local look = table.concat({ tostring(db.debuffCountdown), tostring(db.lockoutCountdown), bigX, bigY, Z.BigIconSize(), Z.CornerSize(b), math.floor(Z.CellSize() * 0.45), drinkSize,
		rows.hots.size, rows.hots.point, rows.debuffs.size, rows.debuffs.point, rows.defensives.size, rows.controls.size,
		tostring(db.hotSwipe), tostring(db.hotCountdown), tostring(db.hotFade), tostring(db.hotCharges),
		tostring(db.bossDebuffs), tostring(db.importantGlow) }, ",")
	local plan = { look = look, groups = {}, slots = {}, rows = rows }
	local function Group(box, key, filter, candidates, max, index, template, dress, size)
		size = size or rows[box] and rows[box].size or 12 -- barres fines : leur taille est donnée à part (Build)
		table.insert(plan.groups, { box = box, key = key, filter = filter, candidates = candidates, max = max,
			index = index, template = template, dress = dress, size = size })
	end
	local function Slot(key, filter, candidates, template, dress)
		table.insert(plan.slots, { key = key, filter = filter, candidates = candidates, template = template, dress = dress })
	end

	if db.showHots and not Empty(hots) then
		Group("hots", "hots", "HELPFUL|PLAYER", { includeSpellIDs = hots }, Z.HotCount(), 1, "LyoruneAuraIcon", "mine")
		Group("bars", "bars", "HELPFUL|PLAYER", { includeSpellIDs = hots }, Z.HotCount(), 1, "LyoruneAuraBar", "bar")
	end
	-- Âme affaiblie (posée par n'importe qui) : après mes soins, dans la même rangée, assombrie
	if not Empty(lockouts) then
		Group("hots", "lockouts", "HARMFUL", { includeSpellIDs = lockouts }, Z.LOCKOUT_COUNT, 2, "LyoruneAuraIcon", "lockout")
		Group("bars", "lockbars", "HARMFUL", { includeSpellIDs = lockouts }, Z.LOCKOUT_COUNT, 2, "LyoruneAuraBar", "lockbar")
	end
	-- Boisson : montrée seulement sur les soigneurs (Visibility), à côté de leur mana basse
	if db.drinkHealers and Z.drinkIds and not Empty(Z.drinkIds) then
		Group("drink", "drink", "HELPFUL", { includeSpellIDs = Z.drinkIds }, 1, 1, "LyoruneAuraIcon", "other", drinkSize)
	end
	for _, point in ipairs(Z.CORNERS) do
		if corners[point] then
			Slot(point, "HELPFUL|PLAYER", { includeSpellIDs = corners[point] }, "LyoruneAuraSquare", "corner")
		end
	end

	-- Un de ma liste « À mettre en avant » d'abord, quel que soit le mode ; puis ceux que je peux dissiper
	-- moi-même (filtre RAID du jeu, réglage « dispelCount »), puis les autres (!RAID : le contraire exact, ni trou
	-- ni doublon ; réglage « debuffCount »). Le jeu sait ce que je peux dissiper, même un sort appris en montant de
	-- niveau. « Utiles » : le jeu choisit comme pour ses cadres de raid (type d'aura traité « affaiblissement »),
	-- et rien de plus de 5 minutes (Déserteur, Épuisement, fêtes).
	local excluded = NilIfEmpty(ignored)
	if db.showDebuffs then
		local listed, dispel, others = Z.DebuffPlaces()
		local rowExcluded = NilIfEmpty(rowIgnored)
		if listed > 0 and not Empty(listedIds) then
			Group("debuffs", "listedRow", "HARMFUL", { includeSpellIDs = listedIds }, listed, 1, "LyoruneAuraIcon", "debuff")
		end
		Group("debuffs", "dispellable", Z.DISPEL_MINE, { excludeSpellIDs = rowExcluded }, dispel, 2,
			"LyoruneAuraIcon", "debuff")
		if others > 0 then
			local candidates = { excludeSpellIDs = rowExcluded }
			if db.debuffMode == "USEFUL" then
				candidates.maxDuration = USEFUL_SECONDS
				plan.useful = Z.UsefulPolicy() -- le conteneur reçoit alors la politique du jeu (Build)
				if plan.useful then candidates.processedAuraType = AuraUtil.AuraUpdateChangedType.Debuff end
			end
			Group("debuffs", "others", Z.DISPEL_OTHERS, candidates, others, 3, "LyoruneAuraIcon", "debuff")
		end
	end
	-- Gros défensifs de tout lanceur, et contrôle subi : le jeu les reconnaît lui-même, même en combat
	if db.showDefensives and not Empty(defensives) then
		Group("defensives", "defensives", "HELPFUL", { includeSpellIDs = defensives }, Z.DEFENSIVE_COUNT, 1,
			"LyoruneAuraIcon", "defensive")
	end
	if db.showControls then
		Group("controls", "controls", "HARMFUL|CROWD_CONTROL", { excludeSpellIDs = excluded }, 1, 1, "LyoruneAuraIcon",
			"control")
	end
	if db.showDispel then Slot("dispel", Z.DISPEL_MINE, nil, "LyoruneAuraCover", "dispel") end
	if db.dispelIcon then Slot("dispelType", Z.DISPEL_MINE, nil, "LyoruneAuraType", "dispelType") end
	if db.bossDebuffs or db.importantGlow then
		Slot("boss", "HARMFUL", { isBossAura = true }, "LyoruneAuraBig", "big")
		if not Empty(important) then
			Slot("listed", "HARMFUL", { includeSpellIDs = important }, "LyoruneAuraBig", "big")
		end
	end
	-- place de l'icône du type : seulement si elle est montrée (un changement refait les conteneurs)
	if db.dispelIcon then plan.look = plan.look .. "," .. table.concat({ Z.DispelTypePlace() }, ",") end
	plan.marks = Marks(b)
	if #plan.marks > 0 then
		local x, y, size = Z.BuffMarkPlace(b)
		plan.look = plan.look .. "," .. x .. "," .. y .. "," .. size
	end
	return plan
end

-- Empreinte d'un plan : deux plans égaux donnent le même texte (rien à reconstruire)
local function Sorted(set)
	local list = {}
	for key, value in pairs(set or {}) do list[#list + 1] = tostring(key) .. "=" .. tostring(value) end
	table.sort(list)
	return table.concat(list, ",")
end

local function Signature(plan)
	local parts = { plan.look }
	for _, list in ipairs({ plan.groups, plan.slots, plan.marks }) do
		for _, entry in ipairs(list) do
			local candidates = { ids = entry.ids and "{" .. Sorted(entry.ids) .. "}" or nil }
			for key, value in pairs(entry.candidates or {}) do
				candidates[key] = type(value) == "table" and "{" .. Sorted(value) .. "}" or tostring(value)
			end
			parts[#parts + 1] = (entry.box or "slot") .. ":" .. entry.key .. ":" .. entry.filter .. ":" .. tostring(entry.max)
				.. ":" .. Sorted(candidates)
		end
	end
	return table.concat(parts, "|")
end

local function Dresser(b, entry)
	local how = entry.dress
	if how == "mine" then return function(button) DressIcon(button, true, entry.size) end end
	if how == "other" then return function(button) DressIcon(button, false, entry.size) end end
	if how == "debuff" then
		local numbers, typed = Numbers(entry.key), Z.db.showDispel and true or false
		return function(button) DressIcon(button, false, entry.size, nil, false, numbers, typed) end
	end
	if how == "defensive" then return function(button) DressIcon(button, false, entry.size, Z.DEFENSIVE_EDGE) end end
	if how == "control" then
		return function(button) DressIcon(button, false, entry.size, Z.CONTROL_EDGE, false, Numbers("controls")) end
	end
	if how == "lockout" then return function(button) DressIcon(button, false, entry.size, nil, true, Numbers("lockouts")) end end
	if how == "bar" then return DressBar end
	if how == "lockbar" then return function(button, index) DressBar(button, index, Z.LOCKOUT_BAR) end end
	if how == "corner" then return DressCorner(b, entry.key) end
	if how == "dispel" then return DressDispel(b) end
	if how == "dispelType" then return DressType(b) end
	return DressBig(b)
end

local function NewBox(b, level)
	local ok, box = pcall(CreateFrame, "AuraContainer", nil, b.over, "LyoruneAuraBox")
	if not ok or not box then return end
	Call(box, "SetMouseClickEnabled", false)
	Call(box, "SetMouseMotionEnabled", false)
	Call(box, "SetFrameLevel", b.over:GetFrameLevel() + level)
	return box
end

local function Flow(box, point, horizontal, vertical, axis)
	Call(box, "SetFlowLayoutAnchorPoint", point)
	Call(box, "SetFlowLayoutAxis", axis or AnchorUtil.FlowLayoutAxis.Horizontal)
	Call(box, "SetFlowLayoutGrowthDirection", horizontal, vertical)
end

-- Une rangée de Z.AuraRows : coin de départ, sens, et longueur d'une ligne (au-delà, le jeu passe à la ligne).
-- La longueur compte l'écart après la dernière icône : juste assez pour row.perLine icônes, que le jeu compte
-- cet écart ou non.
-- row.flow : coin de départ des icônes quand la rangée s'accroche par un bord ou par son centre (défensifs,
-- contrôle) ; une rangée accrochée au centre a juste sa largeur, pour rester centrée.
local function PlaceRow(b, box, row, dx, dy)
	local DIR = AnchorUtil.FlowDirection
	Call(box, "ClearAllPoints")
	Call(box, "SetPoint", row.point, row.relative == "HP" and b.hp or b.over, row.point, row.x + dx, row.y + dy)
	Call(box, "SetSize", row.point == "CENTER" and row.width or row.perLine * (row.size + SPACING), row.height)
	Flow(box, row.flow or row.point, row.dirX < 0 and DIR.Left or DIR.Right, row.dirY < 0 and DIR.Down or DIR.Up)
	if Z.boxWrap then Call(box, "SetFlowLayoutMaximumLineSize", row.perLine * (row.size + SPACING)) end
end

local waiting = {} -- cases à construire à la fin du combat (Rebuild)

-- Places des conteneurs dans la case (les conteneurs ne sont pas protégés : refait librement). Une case qui
-- attend la fin du combat pour être refaite (une taille changée) garde les rangées de ses boutons d'avant.
local function Place(b)
	local db = Z.db
	local boxes = b.boxes
	local rows = (waiting[b] and b.boxRows) or b.rows or Z.AuraRows()

	local dx, dy = Z.Offset("hots")
	PlaceRow(b, boxes.hots, rows.hots, dx, dy)

	Call(boxes.bars, "ClearAllPoints")
	Call(boxes.bars, "SetPoint", "TOPLEFT", b.over, "TOPLEFT", 3 + Z.CornerShift(b, "TOPLEFT") + dx, dy - 3)
	Call(boxes.bars, "SetSize", math.floor(Z.CellSize() * 0.45), Z.HotSlots() * 4)

	local x, y, size = Z.DrinkPlace()
	Call(boxes.drink, "ClearAllPoints")
	Call(boxes.drink, "SetPoint", "BOTTOMLEFT", b.hp, "BOTTOMLEFT", x, y)
	Call(boxes.drink, "SetSize", size, size)

	dx, dy = Z.Offset("debuffs")
	PlaceRow(b, boxes.debuffs, rows.debuffs, dx, dy)
	PlaceRow(b, boxes.defensives, rows.defensives, Z.Offset("defensives"))
	PlaceRow(b, boxes.controls, rows.controls, Z.Offset("controls"))

	Call(boxes.slots, "SetAllPoints", b.over)
	Call(boxes.buffs, "SetAllPoints", b.over)
	for index, button in ipairs(b.markButtons or {}) do
		if Open(button) then PlaceMark(b, button, index) end
	end

	-- Boutons déjà créés par le jeu : seulement s'il nous laisse y toucher (sinon, à la prochaine occasion)
	for key, button in pairs(b.slots) do
		if Open(button) then
			if Z.CORNER_SIGN[key] then PlaceCorner(b, button, key)
			elseif key == "boss" or key == "listed" then PlaceBig(b, button)
			elseif key == "dispelType" then PlaceType(b, button) end
		end
	end
	for _, button in ipairs(b.boxButtons.hots or {}) do
		if Open(button) then StyleIcon(button, true, rows.hots.size) end
	end
	for key, row in pairs({ listedRow = rows.debuffs, dispellable = rows.debuffs, others = rows.debuffs, defensives = rows.defensives,
		controls = rows.controls, lockouts = rows.hots }) do
		for _, button in ipairs(b.boxButtons[key] or {}) do
			if Open(button) then StyleIcon(button, false, row.size, Numbers(key)) end
		end
	end
	for _, button in ipairs(b.boxButtons.bars or {}) do
		if Open(button) then Call(button.Bar, "SetWidth", math.floor(Z.CellSize() * 0.45)) end
	end
end

-- Montrés ou cachés : pas de joueur, ennemi visé, style d'icônes (icônes ou barres), boisson des soigneurs
local function Visibility(b)
	if not b.boxes then return end
	local shown = b.unit ~= nil and b.boxesShown ~= false
	local bars = Z.db.hotStyle == "BARS"
	Call(b.boxes.slots, "SetShown", shown)
	Call(b.boxes.debuffs, "SetShown", shown)
	Call(b.boxes.defensives, "SetShown", shown)
	Call(b.boxes.controls, "SetShown", shown)
	Call(b.boxes.hots, "SetShown", shown and not bars)
	Call(b.boxes.bars, "SetShown", shown and bars)
	Call(b.boxes.drink, "SetShown", shown and b.drinkShown == true)
	-- repères des buffs : seulement quand le jeu cache les buffs, et jamais pour un joueur changé en combat
	local list = b.markList or {}
	local marks = shown and #list > 0 and not b.marksStale and Z.BuffMarksOn()
	b.marksShown = marks and true or false
	Call(b.boxes.buffs, "SetShown", b.marksShown)
	for index, entry in ipairs(list) do
		local icon = Z.BuffMark(b, index, entry.icon)
		icon:SetShown(b.marksShown)
	end
	for index = #list + 1, #(b.markIcons or {}) do b.markIcons[index]:Hide() end
end

local function EachBox(b, method, ...)
	for _, box in pairs(b.boxes) do Call(box, method, ...) end
end

-- Anciens conteneurs : cachés et oubliés (le jeu ne sait pas retirer un groupe)
local function Drop(b)
	if not b.boxes then return end
	EachBox(b, "Hide")
	for _, icon in ipairs(b.markIcons or {}) do icon:Hide() end
	b.boxes, b.boxButtons, b.slots, b.boxesSig = nil, nil, nil, nil
	b.markButtons, b.markList, b.marksShown = nil, nil, nil
end

local function Build(b, plan)
	b.boxes, b.boxButtons, b.slots, b.markButtons = {}, {}, {}, {}
	b.markList, b.marksStale, b.markUnit = plan.marks, nil, b.unit
	local boxes = b.boxes
	boxes.hots = NewBox(b, 1)
	boxes.bars = NewBox(b, 1)
	boxes.debuffs = NewBox(b, 1)
	boxes.defensives = NewBox(b, 2)
	boxes.controls = NewBox(b, 3) -- au-dessus des autres icônes : un joueur qui ne peut plus agir se voit d'abord
	boxes.drink = NewBox(b, 1)
	boxes.slots = NewBox(b, 4) -- au-dessus des icônes, sous les auras privées
	boxes.buffs = NewBox(b, 2) -- au-dessus des repères gris (b.over + 1)
	if plan.useful then -- « Utiles » : le jeu marque chaque aura comme pour ses cadres de raid
		Call(boxes.debuffs, "SetAuraProcessingPolicy", CustomAuraContainerAuraProcessingPolicy.ProcessAura,
			{ displayOnlyDispellableDebuffs = false })
	end
	for _, key in ipairs({ "hots", "bars", "debuffs", "defensives", "controls", "drink", "slots", "buffs" }) do
		if not boxes[key] then error("création refusée") end
	end

	-- 1. ancrer (les rangées de soins et d'affaiblissements prennent leur sens dans Place)
	local DIR = AnchorUtil.FlowDirection
	Flow(boxes.bars, "TOPLEFT", DIR.Right, DIR.Down, AnchorUtil.FlowLayoutAxis.Vertical)
	Flow(boxes.drink, "BOTTOMLEFT", DIR.Right, DIR.Up)
	Place(b)

	-- 2. le joueur suivi, avant les groupes
	for _, box in pairs(boxes) do
		local ok, err = pcall(box.SetUnit, box, b.unit)
		if not ok then error("SetUnit : " .. tostring(err)) end
	end

	-- 3. groupes et places fixes, filtres donnés à la création
	for _, entry in ipairs(plan.groups) do
		local list, made, dress = {}, 0, Dresser(b, entry)
		b.boxButtons[entry.key] = list
		local width, height = entry.size, entry.size
		if entry.template == "LyoruneAuraBar" then width, height = math.floor(Z.CellSize() * 0.45), 3 end
		local box = boxes[entry.box]
		local ok, err = pcall(box.AddAuraGroup, box, entry.key, entry.filter, {
			maxFrameCount = entry.max,
			sortMethod = AuraContainerSortMethod.Default,
			templateNames = { entry.template },
			candidateFilters = entry.candidates,
			layout = { elementWidth = width, elementHeight = height, elementSpacing = SPACING, lineSpacing = SPACING,
				groupSpacing = SPACING, layoutIndex = entry.index },
			initializeFrame = function(button)
				made = made + 1
				Call(button, "SetSize", width, height)
				dress(button, made)
				list[#list + 1] = button
			end,
		})
		if not ok then error("AddAuraGroup " .. entry.key .. " : " .. tostring(err)) end
	end
	for _, entry in ipairs(plan.slots) do
		local dress = Dresser(b, entry)
		local box = boxes.slots
		local ok, button = pcall(box.AddAuraSlot, box, entry.key, entry.filter, {
			templateNames = { entry.template },
			candidateFilters = entry.candidates,
			initializeFrame = function(button) dress(button) end,
		})
		if not ok then error("AddAuraSlot " .. entry.key .. " : " .. tostring(button)) end
		b.slots[entry.key] = button
	end
	for index, entry in ipairs(plan.marks) do
		local box = boxes.buffs
		local ok, button = pcall(box.AddAuraSlot, box, entry.key, entry.filter, {
			templateNames = { "LyoruneAuraIcon" },
			candidateFilters = { includeSpellIDs = entry.ids },
			initializeFrame = DressMark(b, index),
		})
		if not ok then error("AddAuraSlot " .. entry.key .. " : " .. tostring(button)) end
		b.markButtons[index] = button
	end

	-- 4. en dernier : le jeu se met à suivre les auras
	EachBox(b, "SetEnabled", true)
	Visibility(b)
	EachBox(b, "UpdateAllAuras")
end

----------------------------------------------------------------------------------------------------
-- Points d'entrée (Frames.lua, Auras.lua)
----------------------------------------------------------------------------------------------------


-- Un premier conteneur, hors combat, dit si le jeu sait passer à la ligne (Z.CanWrapAuras). Sans réponse, la
-- taille des rangées compte sur le passage à la ligne : la case est refaite dès que la réponse change la taille.
local function Probe(b)
	if Z.boxWrap ~= nil or InCombatLockdown() then return end
	local ok, box = pcall(CreateFrame, "AuraContainer", nil, b.over, "LyoruneAuraBox")
	if not ok or not box then return end
	Z.boxWrap = type(box.SetFlowLayoutMaximumLineSize) == "function"
	Call(box, "Hide")
	b.rows = Z.AuraRows()
end

-- Construit ou reconstruit les conteneurs si le plan a changé ; en combat, attend la fin du combat
local function Rebuild(b)
	if b.boxesFailed or not Z.HasAuraBoxes() or not b.unit or not b.over then return end
	Probe(b)
	local plan = Plan(b)
	local signature = Signature(plan)
	if b.boxes and b.boxesSig == signature then
		-- mêmes places : seules les icônes des repères peuvent changer (bénédiction choisie, dernière aura)
		if not InCombatLockdown() then
			b.markList, b.marksStale = plan.marks, nil
			Visibility(b)
		end
		return
	end
	if InCombatLockdown() then waiting[b] = true return end
	waiting[b] = nil
	Drop(b)
	local ok, err = pcall(Build, b, plan)
	if not ok then
		-- l'ancien affichage reste en place pour cette case
		Drop(b)
		b.boxesFailed = true
		Z:Log("Conteneur d'auras", tostring(err), "")
		Z:Print("Conteneur d'auras : " .. tostring(err))
		return
	end
	b.boxesSig, b.boxRows = signature, plan.rows
	Z.HideAuras(b)
	Z.ShowDispel(b, false)
end

-- Le jeu se met à cacher les buffs, ou cesse : les repères des buffs apparaissent ou s'effacent sur chaque case.
-- Montrés : le jeu redessine le conteneur, et l'ancien repère lu hors combat s'efface. Effacés : la case se relit.
local function MarksChanged()
	for _, b in ipairs(Z.buttons or {}) do
		if b.boxes then
			local before = b.marksShown
			Visibility(b)
			if b.marksShown and not before then
				Call(b.boxes.buffs, "UpdateAllAuras")
				if b.buffIcon then b.buffIcon:Hide() end
			elseif before and not b.marksShown and Z.QueueAuras then
				Z.QueueAuras(b)
			end
		end
	end
end

Z:On("PLAYER_REGEN_DISABLED", function()
	fighting = true
	MarksChanged()
end)

Z:On("PLAYER_REGEN_ENABLED", function()
	fighting = false
	for b in pairs(waiting) do
		waiting[b] = nil
		Z:Try("conteneurs d'auras", Rebuild, b)
	end
	MarksChanged()
end)

-- Restriction du jeu (match JcJ, boss) qui commence ou finit
Z:On("ADDON_RESTRICTION_STATE_CHANGED", function() MarksChanged() end)

-- Le groupe change en plein combat : un même nom d'unité peut désigner un autre joueur. Ses repères (mana, porteur)
-- ne sont plus sûrs : cachés jusqu'à la fin du combat, puis revus.
Z:On("GROUP_ROSTER_UPDATE", function() -- tout de suite : le combat se lit au moment du changement (rien hors combat)
	if not InCombatLockdown() then return end
	for _, b in ipairs(Z.buttons or {}) do
		if b.markList and #b.markList > 0 then
			b.marksStale = true
			waiting[b] = true
			if b.boxes then Visibility(b) end
		end
	end
end)

-- Hors combat, après une relecture du panneau des buffs (Buffs.lua) : un porteur, un réglage de « Mes buffs » ou un
-- joueur a pu changer. Chaque case revoit ses repères (rien n'est refait si rien n'a changé).
function Z.RecheckBuffMarks()
	if InCombatLockdown() then return end
	for _, b in ipairs(Z.buttons or {}) do
		if b.boxes then Rebuild(b) end
	end
end

-- Le joueur de la case change : les conteneurs le suivent (SetUnit est permis en combat)
function Z.BindAuraBoxes(b)
	if not b.boxes then return Rebuild(b) end
	if b.unit then
		for _, box in pairs(b.boxes) do
			if not pcall(box.SetUnit, box, b.unit) then
				-- refusé : ne jamais montrer les auras de l'ancien joueur
				b.boxesShown, b.boxesSig = false, nil
				waiting[b] = true
			end
		end
		-- les repères des buffs dépendent du joueur (mana, porteur) : revus hors combat, en attente en combat
		if b.unit ~= b.markUnit then
			b.markUnit = b.unit
			if InCombatLockdown() then
				b.marksStale = true
				waiting[b] = true
			elseif b.boxesSig then
				Rebuild(b)
			end
		end
	end
	Visibility(b)
	if b.unit then EachBox(b, "UpdateAllAuras") end
end

-- Réglages changés (Frames.lua, Style) : reconstruction si les filtres ont changé, sinon les places
function Z.StyleAuraBoxes(b)
	Rebuild(b)
	if not b.boxes then return end
	local ok, err = pcall(Place, b)
	if not ok then Z:Log("Conteneur d'auras", tostring(err), "") end
	Visibility(b)
end

-- Toutes les cases : nouveau numéro de sort appris, sorts de la classe changés
function Z.RefreshAuraBoxes()
	for _, b in ipairs(Z.buttons or {}) do Z.StyleAuraBoxes(b) end
end

-- Le rôle du joueur a changé (Frames.lua) : la boisson ne se montre que sur un soigneur
function Z.ShowDrinkBox(b)
	Visibility(b)
end

-- Case cible ou focalisation sur un ennemi : rien à lui montrer.
-- Ces cases gardent le même nom d'unité (« target ») quand le joueur visé change : on redemande les auras.
function Z.ShowAuraBoxes(b, shown)
	if not b.boxes then return end
	if b.extra and shown then EachBox(b, "UpdateAllAuras") end
	if b.boxesShown == shown then return end
	b.boxesShown = shown
	Visibility(b)
end
