-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - Preview.lua : le mode test. Affiche un faux groupe (5, 10, 25 ou 40 joueurs) pour régler
-- l'apparence sans être en groupe. Les fausses cases utilisent exactement le même habillage que les vraies.
-- Le mode test se ferme tout seul à l'entrée en combat.

local _, Z = ...
local UI = Z.UI

local container
local cells = {}
local petCells = {} -- faux familiers, par numéro de faux joueur (C26)
local size = 10

-- (un chasseur dans les cinq premiers : le faux groupe montre aussi un familier)
local CLASSES = { "WARRIOR", "PRIEST", "DRUID", "HUNTER", "PALADIN", "ROGUE", "SHAMAN", "MAGE", "WARLOCK" }
local PET_CLASSES = { HUNTER = true, WARLOCK = true }
local HEALTH = { 100, 62, 100, 18, 85, 100, 0, 45, 100, 73 } -- vie des faux joueurs, en %
local CLASS_POWER = Z.classPower -- ressource de chaque classe quand ce n'est pas la mana (Data.lua)
local DISPEL_COLORS = { { 0.20, 0.60, 1.00 }, { 0.65, 0.20, 1.00 }, { 0.10, 0.85, 0.20 } }
local DISPEL_KINDS = { "Magic", "Curse", "Poison" } -- les mêmes types, pour l'icône du type à dissiper

-- Remplit une fausse case avec un état d'exemple. sample : la case témoin des options, à mon nom, où chaque
-- indicateur allumé dans les options se voit. Renvoie le nombre de soins sur la durée montrés.
local function Fill(cell, index, sample)
	local db, L = Z.db, Z.L
	local class = (sample and Z.class) or CLASSES[(index - 1) % #CLASSES + 1]
	local r, g, b = Z.ClassColor(class)
	local health = cell.fakeHealth or HEALTH[(index - 1) % #HEALTH + 1] -- (faux familier : en pleine forme)
	local dead = health == 0

	cell.hp:SetMinMaxValues(0, 100)
	cell.hp:SetValue(health)
	cell.name:SetText(sample and UnitName("player") or (L["Joueur"] .. " " .. index))
	if dead then
		cell.hp:SetStatusBarColor(0.25, 0.25, 0.28)
		cell.name:SetTextColor(0.65, 0.65, 0.68)
		cell.text:SetText(L["Mort"])
		cell.text:SetTextColor(0.95, 0.35, 0.35)
	else
		local br, bg, bb = r, g, b -- couleur de la barre : classe, ou vie restante
		if db.color == "CLASS" then
			cell.name:SetTextColor(1, 1, 1)
		else
			br, bg, bb = 1 - health / 100, health / 100 * 0.8, 0.2
			cell.name:SetTextColor(r, g, b)
		end
		cell.hp:SetStatusBarColor(br, bg, bb)
		if db.showIncoming then -- teinte de contraste sur une barre verte ; ceux des autres plus pâles
			Z.SetIncomingColor(cell, Z.IncomingColor(br, bg, bb))
		end
		cell.text:SetTextColor(1, 1, 1)
		if db.text == "DEFICIT" then
			cell.text:SetText(health < 100 and ("-" .. (100 - health) * 40) or "")
		elseif db.text == "PERCENT" then
			cell.text:SetText(health .. "%")
		else
			cell.text:SetText("")
		end
	end
	-- Joueur en bonne santé estompé (réglage healthyFade), comme sur les vraies cases
	local faded = db.healthyFade and not dead and health >= db.healthyFadeAt
	local alpha = faded and Z.HEALTHY_ALPHA or 1
	Z.SetHealthyAlpha(cell, alpha)
	cell.text:SetAlpha(alpha)

	-- Soins en route et bouclier sur quelques joueurs blessés
	cell.incoming:SetMinMaxValues(0, 100)
	-- soins en route : le mien, puis celui d'un autre soigneur sur une case sur quatre (réglage incomingSplit)
	local healed = not dead and health < 90 and index % 2 == 0
	local others = healed and index % 4 == 0 and db.incomingSplit ~= "MINE" and 6 or 0
	cell.incoming:SetValue(healed and (db.incomingSplit == "ALL" and 9 + others or 9) or 0)
	if cell.incomingOthers then
		cell.incomingOthers:SetMinMaxValues(0, 100)
		cell.incomingOthers:SetValue(db.incomingSplit == "SPLIT" and others or 0)
	end
	-- Chiffre des soins en route (incomingText) : ce que montrent les segments
	if cell.incomingSwitch then
		local amount = healed and (db.incomingSplit == "MINE" and 9 or 9 + others) or 0
		cell.incomingSwitch:SetValue(amount > 0 and 1 or 0)
		cell.incomingText:SetText(amount > 0 and ("+" .. AbbreviateNumbers(amount * 40)) or "")
	end
	cell.absorb:SetMinMaxValues(0, 100)
	local shield = (not dead and (sample or index % 5 == 2)) and (sample and 18 or 30) or 0
	cell.absorb:SetValue(shield)
	-- Chiffre du bouclier (absorbText) : même procédé que les vraies cases, la barre de 0 à 1 le montre ou le cache
	if cell.absorbSwitch then
		cell.absorbSwitch:SetValue(shield > 0 and 1 or 0)
		cell.absorbText:SetText(shield > 0 and ("+" .. AbbreviateNumbers(shield * 40)) or "")
	end
	-- Absorption de soins : bornes données, sinon le jeu dessine la barre pleine et teinte toute la case en rouge
	cell.healAbsorb:SetMinMaxValues(0, 100)
	cell.healAbsorb:SetValue(0)
	-- Mes soins sur la durée, part perdue, gaspillage et voile : vides (rien ne reste de la mesure des performances)
	for _, bar in ipairs({ cell.hot, cell.hotNext, cell.pending }) do
		bar:SetMinMaxValues(0, 100) bar:SetValue(0)
	end
	for _, bar in ipairs(cell.lostBars or {}) do bar:SetValue(0) end
	for _, bar in ipairs(cell.lostHots or {}) do bar:SetValue(0) end
	for _, more in ipairs(cell.lostMores or {}) do more:SetAlpha(0) end
	for _, t in ipairs({ cell.overheal, cell.overhealMore, cell.castFill }) do t:SetAlpha(0) end

	-- Rôles : un tank et un soigneur par groupe de cinq
	local slot = (index - 1) % 5
	local role = slot == 0 and "TANK" or slot == 1 and "HEALER" or nil -- nil : un DPS
	local icon = role == "TANK" and "roleicon-tiny-tank" or role == "HEALER" and "roleicon-tiny-healer"
		or db.showDpsRole and "roleicon-tiny-dps" -- (C25, comme les vraies cases)
	cell.role:SetShown(db.showRole and icon and true or false)
	if icon then cell.role:SetAtlas(icon) end
	Z.PlaceLeader(cell) -- l'icône de rôle vient d'apparaître ou de disparaître (C24)
	if db.showClassIcon then Z.SetClassIcon(cell.class, class) else cell.class:Hide() end
	-- Chef de groupe sur la première case, un assistant par groupe de cinq en raid
	local leader = db.showLeader and ((sample or index == 1) and "LeaderIcon" or size > 5 and slot == 0 and "AssistantIcon")
	if leader then cell.leader:SetTexture("Interface\\GroupFrame\\UI-Group-" .. leader) end
	cell.leader:SetShown(leader and true or false)
	-- Barre de ressource comme sur les vraies cases : mana, rage, énergie ou focalisation selon la classe.
	-- Le druide montre sa forme : ours (rage) quand il tank, félin (énergie) un druide sur deux en dégâts
	local power = CLASS_POWER[class]
	if class == "DRUID" and not sample then
		if role == "TANK" then
			power = CLASS_POWER.WARRIOR
		elseif not role and index % 2 == 1 then
			power = CLASS_POWER.ROGUE
		end
	end
	cell.powerType, cell.powerToken = power and power[1] or 0, power and power[2] or "MANA"
	local mana = db.manaBars == "ALL" or (db.manaBars == "HEALERS" and role == "HEALER" and not power)
	if mana ~= cell.powerShown then
		cell.powerShown = mana
		cell.power:SetShown(mana)
		Z.StyleButton(cell)
	end
	cell.power:SetStatusBarColor(Z.PowerColor(cell.powerType, cell.powerToken))
	cell.power:SetMinMaxValues(0, 100)
	cell.power:SetValue(65)
	-- Un soigneur sur deux est à court de mana ; un bouclier dépasse la vie manquante
	cell.lowMana:SetAlpha(1)
	cell.lowMana:SetShown((tonumber(db.lowManaHealers) or 0) > 0 and role == "HEALER" and index % 10 == 2 and not dead)
	cell.overAbsorb:SetAlpha((index % 5 == 2 and health >= 75) and 1 or 0)

	-- Marqueur de raid : seulement sur la case témoin (le faux groupe en serait couvert)
	if sample and db.showMarker then SetRaidTargetIconTexture(cell.marker, 1) end
	cell.marker:SetShown(sample and db.showMarker and true or false)
	cell.threat:SetShown(db.showThreat and (sample or slot == 0) and not dead)
	local low = db.lowHealth and not dead and not cell.isPet and health <= db.lowHealthAt
	cell.low.fill:SetAlpha(low and 1 or 0) -- liseré fixe ; montré ici même hors combat, pour le voir (C32)
	cell.selected:SetAlpha((index == 2 and not sample) and 1 or 0)
	-- Répartition entre soigneurs : mes groupes (en raid) portent le repère, un joueur choisi est montré par le
	-- premier tank ; la case témoin le porte dès qu'un choix existe. Les autres s'estompent (réglage assignFade).
	local groups, players = Z.AssignChoice()
	local useGroups = size > 5 and next(groups) ~= nil
	local active = useGroups or next(players) ~= nil
	local mine = sample or (useGroups and groups[math.floor((index - 1) / 5) + 1]) or (next(players) ~= nil and index == 1)
	cell.assign:SetShown((db.assignMark and active and mine) and true or false)
	local dim = (db.assignFade and active and not mine) and Z.ASSIGN_DIM or 1
	cell:SetAlpha(((index % 10 == 9 and not sample) and db.rangeAlpha / 100 or 1) * dim)

	-- Dissipation possible sur un joueur sur six
	local kind = math.floor(index / 6) % #DISPEL_COLORS + 1
	local toDispel = not dead and (sample or index % 6 == 3)
	local dispel = db.showDispel and toDispel and DISPEL_COLORS[kind]
	if dispel then
		Z.ShowDispel(cell, true, dispel[1], dispel[2], dispel[3], 1)
	else
		Z.ShowDispel(cell, false)
	end

	-- Soins sur la durée d'exemple, avec les icônes de mes vrais sorts
	Z.HideAuras(cell)
	if db.dispelIcon and toDispel then Z.ShowDispelType(cell, DISPEL_KINDS[kind]) end
	local mine = not dead and (sample or index % 3 ~= 0) -- joueurs qui portent mes soins
	local shown = 0
	if db.showHots and mine then
		for _, id in ipairs(Z.trackedSpells[Z.class] or { 139, 774 }) do
			if shown == math.min(sample and 3 or 2, Z.HotCount()) then break end
			shown = shown + 1
			if db.hotStyle == "BARS" then
				local bar, color = Z.HotBar(cell, shown), Z.BAR_COLORS[shown] or Z.BAR_COLORS[1]
				bar:SetStatusBarColor(color[1], color[2], color[3])
				bar:SetMinMaxValues(0, 1)
				bar:SetValue(shown == 1 and 0.8 or 0.4)
				bar:Show()
			else
				local icon = Z.HotIcon(cell, shown)
				icon.texture:SetTexture(C_Spell.GetSpellTexture(id))
				icon.cooldown:Clear()
				icon.count:SetText("")
				icon:Show()
			end
		end
	end
	-- Âme affaiblie (prêtre) : assombrie au bout de mes soins, sur la case témoin et un joueur sur quatre
	if Z.ShowsLockouts() and not dead and (sample or index % 4 == 1) then
		local texture = C_Spell.GetSpellTexture(next(Z.lockoutIds))
		if db.hotStyle == "BARS" then
			local bar = Z.HotBar(cell, shown + 1)
			bar:SetStatusBarColor(Z.LOCKOUT_BAR[1], Z.LOCKOUT_BAR[2], Z.LOCKOUT_BAR[3])
			bar:SetMinMaxValues(0, 1)
			bar:SetValue(0.6)
			bar:Show()
		elseif texture then
			local icon = Z.HotIcon(cell, shown + 1)
			icon.texture:SetTexture(texture)
			Z.DarkenIcon(icon)
			icon.cooldown:Clear()
			icon.count:SetText("")
			icon:Show()
		end
	end
	-- Boisson sur le soigneur à court de mana (comme en vrai : sur les soigneurs seulement)
	if db.drinkHealers and role == "HEALER" and index % 10 == 2 and not dead then
		local icon = Z.DrinkIcon(cell)
		icon.texture:SetTexture("Interface\\Icons\\INV_Drink_18")
		icon.texture:SetDesaturated(false)
		icon.texture:SetVertexColor(1, 1, 1)
		icon.cooldown:Clear()
		icon.count:SetText("")
		icon:Show()
	end
	-- Coins : un carré par sort choisi, sur les mêmes joueurs (montrés même soins sur la durée coupés, comme en vrai)
	if mine then
		for point, name in pairs(Z.MyCorners()) do
			if name ~= "" then
				local square = Z.CornerSquare(cell, point)
				square.cooldown:Clear()
				square:Show()
			end
		end
	end
	-- Affaiblissements : sur la case témoin, autant à dissiper que le réglage le permet (deux au plus)
	if db.showDebuffs and (dispel or index % 7 == 5) and not dead then
		local textures = { "Interface\\Icons\\Spell_Shadow_CurseOfTounges", "Interface\\Icons\\Spell_Nature_Slow" }
		for i = 1, (sample and dispel) and math.min(2, Z.DispelCount()) or 1 do
			local icon = Z.DebuffIcon(cell, i)
			icon.texture:SetTexture(textures[i])
			-- liseré à la couleur du type quand ils sont à dissiper, noir sinon
			local edge = dispel or { 0, 0, 0 }
			icon.border:SetColor(edge[1], edge[2], edge[3], 1)
			icon.cooldown:Clear()
			icon.count:SetText("")
			icon:Show()
		end
	end
	-- Gros défensif (Mur protecteur) sur la case témoin et un joueur sur huit ; contrôle subi (métamorphose) sur
	-- un joueur sur onze du faux groupe (au centre, il cacherait le nom de la case témoin)
	local function Sample(icon, texture)
		icon.texture:SetTexture(texture)
		icon.texture:SetDesaturated(false)
		icon.cooldown:Clear()
		icon.count:SetText("")
		icon:Show()
	end
	if db.showDefensives and not dead and (sample or index % 8 == 4) then
		Sample(Z.DefensiveIcon(cell, 1), "Interface\\Icons\\Ability_Warrior_ShieldWall")
	end
	if db.showControls and not dead and not sample and index % 11 == 3 then
		Sample(Z.ControlIcon(cell), "Interface\\Icons\\Spell_Nature_Polymorph")
	end
	return shown
end

-- Une fausse case hors du mode test (case témoin des options) : même habillage, simple cadre, jamais de bouton
-- protégé, aucune valeur lue sur un vrai joueur
function Z.FakeCell(parent)
	local cell = CreateFrame("Frame", nil, parent)
	Z.BuildVisuals(cell)
	return cell
end

-- Dessine une fausse case à la taille des vraies, avec l'état du faux joueur index. Renvoie sa largeur, sa hauteur
-- et le nombre de soins sur la durée montrés.
function Z.DrawFakeCell(cell, index, sample, width, height)
	if not width then width, height = Z.CellSize() end
	cell:SetSize(width, height)
	Z.StyleButton(cell)
	return width, height, Fill(cell, index, sample)
end

-- Ordre des faux joueurs, comme le jeu le ferait : trié dans chaque groupe de cinq, ou dans toute la grille.
-- Renvoie la liste des numéros de faux joueurs, place par place.
local function Order()
	local db, L = Z.db, Z.L
	local classRank, rank = {}, 0
	for class in Z.ClassOrder():gmatch("[^,]+") do rank = rank + 1; classRank[class] = rank end
	local function name(i) return L["Joueur"] .. " " .. i end
	local function before(a, b)
		if db.sortOrder == "CLASS" then
			local ca = classRank[CLASSES[(a - 1) % #CLASSES + 1]] or 99
			local cb = classRank[CLASSES[(b - 1) % #CLASSES + 1]] or 99
			if ca ~= cb then return ca < cb end
		end
		if db.sortOrder == "INDEX" then return a < b end
		return name(a) < name(b)
	end
	local order, block = {}, db.layout == "GRID" and size or 5
	for first = 1, size, block do
		local chunk = {}
		for i = first, math.min(first + block - 1, size) do chunk[#chunk + 1] = i end
		table.sort(chunk, before)
		for _, i in ipairs(chunk) do order[#order + 1] = i end
	end
	return order
end

-- Range les fausses cases comme le ferait le jeu : par paquets de cinq, chaque paquet sur son fond (réglage),
-- ou en une seule grille de la hauteur choisie
local function Layout()
	local db = Z.db
	local width, height = Z.CellSize()
	local grid = db.layout == "GRID"
	local perColumn = grid and db.gridSize or 5
	local apart = (db.groupPanel and not grid) and 6 or 0 -- même écart que les vrais cadres entre deux fonds de groupe
	local order = Order()
	-- Familiers (C26), comme les vrais : en groupe, chacun en face de son maître (une colonne de place gardée) ; en
	-- raid, une colonne après les groupes, dans l'ordre des groupes
	local party = size <= 5
	local petWidth, petHeight = Z.PetSize()
	local gapToPets = Z.PetGap()
	local petsShown = db.pets == "RAID" or (party and db.pets == "PARTY")
	local petRoom = (party and db.pets ~= "OFF") and gapToPets + petWidth or 0
	local owners = {}
	for place, cell in ipairs(cells) do
		local shown = place <= size
		cell:SetShown(shown)
		if shown then
			local group, slot = math.floor((place - 1) / perColumn), (place - 1) % perColumn
			local x, y
			if db.horizontal then
				x, y = slot * (width + db.spacing + petRoom), -group * (height + db.spacing + apart)
			else
				x, y = group * (width + db.spacing + apart + petRoom), -slot * (height + db.spacing)
			end
			cell:ClearAllPoints()
			cell:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)
			cell.petRoom = petRoom -- le fond de groupe compte la colonne des familiers (Z.StylePanel)
			Z.DrawFakeCell(cell, order[place], false, width, height)
			if petsShown and PET_CLASSES[CLASSES[(order[place] - 1) % #CLASSES + 1]] then owners[#owners + 1] = { cell, order[place] } end
		end
	end
	for _, pet in pairs(petCells) do pet:Hide() end
	local groups = math.ceil(size / perColumn)
	for k, owner in ipairs(owners) do
		local cell, index = owner[1], owner[2]
		local pet = petCells[index]
		if not pet then
			pet = CreateFrame("Frame", nil, container)
			pet.isPet, pet.fakeHealth = true, 100
			Z.BuildVisuals(pet)
			petCells[index] = pet
		end
		Z.DrawFakeCell(pet, index, false, petWidth, petHeight)
		if db.color == "CLASS" then pet.hp:SetStatusBarColor(Z.PetColor(CLASSES[(index - 1) % #CLASSES + 1])) end
		pet.role:Hide() pet.class:Hide() pet.leader:Hide()
		pet.text:SetText("") -- pas de chiffre de vie sur un familier, comme sur les vraies cases (C35)
		pet:ClearAllPoints()
		if party then
			pet.name:SetText(Z.L["Familier"])
			pet:SetPoint("LEFT", cell, "RIGHT", gapToPets, 0)
		else
			pet.name:SetText(Z.L["Joueur"] .. " " .. index) -- en raid : le nom du maître
			local column, line = math.floor((k - 1) / perColumn), (k - 1) % perColumn -- comme le vrai cadre
			local x, y
			if db.horizontal then
				x = perColumn * (width + db.spacing) - db.spacing + gapToPets + line * (petWidth + db.spacing)
				y = -column * (height + db.spacing) - math.floor((height - petHeight) / 2)
			else
				x = groups * (width + db.spacing + apart) - db.spacing - apart + gapToPets + column * (petWidth + db.spacing)
				y = -line * (height + db.spacing) - math.floor((height - petHeight) / 2)
			end
			pet:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)
		end
		pet:Show()
	end
	for group = 1, 8 do
		local first = cells[(group - 1) * 5 + 1]
		local wanted = db.groupPanel and first and first:IsShown()
		local last = cells[math.min(group * 5, size)]
		if grid then -- un seul fond pour toute la grille, posé sur un cadre invisible de sa taille
			wanted = wanted and group == 1
			local columns, rows = math.ceil(size / perColumn), math.min(size, perColumn)
			if db.horizontal then columns, rows = rows, columns end
			container.box = container.box or CreateFrame("Frame", nil, container)
			container.box:ClearAllPoints()
			container.box:SetPoint("TOPLEFT", container, "TOPLEFT")
			container.box:SetSize(columns * width + (columns - 1) * db.spacing, rows * height + (rows - 1) * db.spacing)
			container.box.petRoom = petRoom
			first, last = container.box, container.box
		end
		local panel = container.panels[group]
		if wanted and not panel then
			panel = Z.BuildPanel(container)
			container.panels[group] = panel
		end
		if panel then
			if wanted then Z.StylePanel(panel, first, last) end
			panel:SetShown(wanted and true or false)
		end
	end
	container:SetAlpha(db.frameAlpha / 100)
	container:SetScale(db.scale / 100) -- même échelle générale que les vrais cadres
end

function Z:RefreshPreview()
	if Z.previewActive then Layout() end
end

local function Stop()
	if not Z.previewActive then return end
	Z.previewActive = false
	container:Hide()
	Z:Refresh() -- réaffiche les vrais cadres (à la fin du combat si besoin)
end

function Z:PreviewSize()
	return size
end

-- Le cadre du mode test et ses fausses cases, créés une seule fois, au premier besoin
local function EnsureCells(count)
	if not container then
		container = CreateFrame("Frame", "LyorunePreview", UIParent)
		container:SetSize(10, 10)
		container:SetPoint("TOPLEFT", Z.anchor, "BOTTOMLEFT", 0, -3)
		container.panels = {}
		-- Bandeau « Mode test » : il se fait glisser comme les étiquettes « Groupe » et déplace les vrais cadres
		container.banner = CreateFrame("Frame", nil, container)
		container.banner:SetPoint("BOTTOMLEFT", Z.anchor, "TOPLEFT", 0, 3)
		container.banner:SetHeight(14)
		container.label = UI.Text(container.banner, 11)
		container.label:SetPoint("LEFT")
		container.label:SetTextColor(UI.frameAccent[1], UI.frameAccent[2], UI.frameAccent[3])
		Z.MakeDragHandle(container.banner, "pos", function() return Z.L["Mode test : faux groupe."] end)
		-- Bouton pour quitter le mode test à la souris, au bout du bandeau
		container.close = UI.Button(container, Z.L["Fermer"], 60, 18, Stop)
		container.close:SetPoint("LEFT", container.label, "RIGHT", 8, 0)
		container.close.label:SetJustifyH("CENTER")
		container.close.tip = Z.L["Quitte le mode test et réaffiche vos vrais cadres. Clic droit sur le bouton de la mini-carte ou /lyorune test font de même."]
		Z:On("PLAYER_REGEN_DISABLED", Stop)
		container:Hide()
	end
	for index = #cells + 1, count do
		local cell = CreateFrame("Frame", nil, container)
		Z.BuildVisuals(cell)
		cells[index] = cell
	end
	return cells
end

-- La mesure des performances (Perf.lua) prête ces mêmes cases : aucun cadre de plus en mémoire
function Z:PreviewCells(count)
	return EnsureCells(count)
end

-- Faux familiers, par numéro de faux joueur (pour les tests)
function Z:PreviewPets()
	return petCells
end

-- Z:TogglePreview() ouvre ou ferme. Z:TogglePreview(25) ouvre avec 25 faux joueurs.
function Z:TogglePreview(wanted)
	if Z.previewActive and (not wanted or wanted == size) then return Stop() end
	if InCombatLockdown() then
		return Z:Print(Z.L["le mode test n'est pas disponible en combat."])
	end
	size = wanted or size
	EnsureCells(size)
	container.label:SetText(Z.L["Mode test : faux groupe."])
	container.banner:SetWidth(container.label:GetStringWidth() + 2)
	container.banner:EnableMouse(Z.db.lockMode ~= "LOCKED")
	Z.previewActive = true
	container:Show()
	Z:Refresh() -- masque les vrais cadres et dessine les faux
end
