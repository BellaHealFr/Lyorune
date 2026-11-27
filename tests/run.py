# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Banc de test de Lyorune : fait tourner le vrai code de l'addon dans un faux client, hors du jeu.
#   pip install lupa
#   python tests/run.py .
# Chaque ligne doit commencer par OK. Code de sortie 1 si une étape échoue.
# Limites : le faux client ne connaît pas les boutons sécurisés du jeu ; un essai en jeu reste nécessaire.
import os, sys
import lupa.lua51 as lua51

here = os.path.dirname(os.path.abspath(__file__))
addon = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, '..')
rt = lua51.LuaRuntime(encoding='utf-8', unpack_returned_tuples=True)
read = lambda p: open(p, encoding='utf-8').read()
import re
rt.globals().TOC_VERSION = re.search(r'## Version: (\S+)', read(os.path.join(addon, 'Lyorune.toc'))).group(1)
rt.execute(read(os.path.join(here, 'mock.lua')))

rt.globals().RUNES_LUA = read(os.path.join(addon, 'Runes.lua')) # rechargé à part (inscription pas encore construite)
rt.globals().BINDINGS_XML = read(os.path.join(addon, 'Bindings.xml')) # raccourcis du jeu (étape 22, lot 4)
rt.execute('BEFORE = {} for k in pairs(_G) do BEFORE[k] = true end')
files = [l.strip().replace('\\', '/') for l in read(os.path.join(addon, 'Lyorune.toc')).splitlines() if l.strip().endswith('.lua')]
rt.execute('NS = {}')
load = rt.eval('function(src, name) local f, err = loadstring(src, name) if not f then error(err) end f("Lyorune", NS) end')
for f in files:
    load(read(os.path.join(addon, f)), '@' + f)
print('fichiers charges :', len(files))

scenario = r'''
local Z = NS
local step = function(label, fn) local ok, err = pcall(fn) print((ok and "OK    " or "ERREUR ") .. label .. (ok and "" or (" : " .. tostring(err)))) if not ok then FAILED = true end end
-- Fenêtre d'options : la ligne dessinée à part qui porte ce champ (tableau des profils...), tous les chapitres construits
local function OptionPart(field)
  Z:OptionLabels()
  for _, chapter in ipairs(Z:OptionsTabs()) do
    for _, part in ipairs(chapter.page and chapter.page.parts or {}) do if part.widget[field] then return part.widget end end
  end
end
-- Chaque page de chapitre est rangée : la hauteur de son contenu suit ce qu'elle montre, elle défile au-delà
local function CheckChapters()
  for _, chapter in ipairs(Z:OptionsWindow().chapters) do
    local page = chapter.page
    if page then
      assert(page.used > 64 and page.scroll.content:GetHeight() >= page.used, "page mal rangee : " .. chapter.name)
    end
  end
end

step("demarrage", function()
  FireEvent("ADDON_LOADED", "Lyorune")
  FireEvent("PLAYER_LOGIN")
  assert(Z.header and #Z.headers == 13, "en-tetes")
end)

step("clics par defaut et resurrection automatique", function()
  local c = Z.db.clicks.PRIEST
  assert(c["1"] == "Soins rapides", "clic gauche = " .. tostring(c["1"]))
  assert(c["shift-1"] == "Soins supérieurs" and c["2"] == "Rénovation")
  assert(c["alt-1"] == "@target" and c["alt-2"] == "@menu", "C18 : cibler et menu au premier lancement")
  assert(Z.header:GetAttribute("z-count") > 0)
  assert(Z.canDispel.Magic and Z.canDispel.Disease and not Z.canDispel.Curse)
end)

step("creation de cases", function()
  for i = 1, 3 do
    local b = CreateFrame("Button", "LyoruneHeaderUnitButton" .. i, Z.header)
    b:Hide()
    Z.header:InitButton(b:GetName())
    b:SetAttribute("unit", i == 1 and "player" or ("party" .. (i - 1)))
    b:Show()
  end
  assert(#Z.buttons == 3)
  Z:ApplyClicks()
  local b = Z.buttons[1]
  assert(b:GetAttribute("type1") == "macro", "resurrection automatique absente")
  assert(b:GetAttribute("macrotext1") == "/cast [@mouseover,help,dead] Résurrection; [@mouseover] Soins rapides", b:GetAttribute("macrotext1"))
  Z.db.autoRes = false Z:ApplyClicks()
  assert(b:GetAttribute("type1") == "spell" and b:GetAttribute("macrotext1") == nil)
  assert(b:GetAttribute("spell1") == "Soins rapides")
  assert(Z.buttons[2]:GetAttribute("shift-spell2") == "Mot de pouvoir : Bouclier")
  assert(ClickCastFrames[b] == nil)
  Z.db.externalClicks = true Z:ApplyClicks()
  assert(ClickCastFrames[b] == true and b:GetAttribute("spell1") == nil, "clics externes")
  Z.db.externalClicks = false Z:ApplyClicks()
end)

step("evenements de vie", function()
  for _, e in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_CONNECTION",
    "UNIT_NAME_UPDATE", "UNIT_FLAGS", "UNIT_THREAT_SITUATION_UPDATE", "INCOMING_RESURRECT_CHANGED", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER" }) do FireEvent(e, "player") end
  assert(Z.buttons[1].text:GetText() == "-200", Z.buttons[1].text:GetText())
  DEAD = true FireEvent("UNIT_HEALTH", "player")
  assert(Z.buttons[1].text:GetText() == "Mort")
  DEAD = false FireEvent("UNIT_HEALTH", "player")
  assert(Z.buttons[1].text:GetText() == "-200")
  assert(Z.buttons[1].powerShown == true, "barre de mana du soigneur")
  Z.db.manaBars = "OFF" Z:Refresh() assert(Z.buttons[1].powerShown == false)
  Z.db.manaBars = "ALL" Z:Refresh()
end)

step("auras", function()
  AURAS["HELPFUL|PLAYER"] = { { name = "Rénovation", icon = 1, auraInstanceID = 11, spellId = 139 }, { name = "Autre", icon = 2, auraInstanceID = 12, spellId = 5 } }
  AURAS["HARMFUL"] = { { name = "Poison", icon = 3, auraInstanceID = 21, spellId = 99, dispelName = "Poison" }, { name = "Mal", icon = 4, auraInstanceID = 22, spellId = 98, dispelName = "Magic" }, { name = "X", icon = 5, auraInstanceID = 23, spellId = 97 } }
  AURAS["HARMFUL|RAID"] = { AURAS["HARMFUL"][2] } -- le jeu : ce que moi (pretre) je peux dissiper
  FireEvent("UNIT_AURA", "player") RunUpdates()
  local b = Z.buttons[1]
  assert(#b.hots == 1 and b.hots[1]:IsShown(), "hots " .. #b.hots)
  assert(b.dispel:IsShown(), "dispel non signale")
  assert(#b.debuffs == 2, "debuffs " .. #b.debuffs)
  Z.db.hotStyle = "BARS" Z:Refresh() RunUpdates()
  assert(b.hotBars[1]:IsShown() and not b.hots[1]:IsShown(), "barres fines")
  Z.db.hotStyle = "ICONS" Z.db.debuffMode = "DISPEL" Z:Refresh() RunUpdates()
  assert(b.debuffs[1]:IsShown() and not b.debuffs[2]:IsShown(), "dissipables seulement")
  Z.db.debuffMode = "ALL" Z.db.showDispel = false Z:Refresh() RunUpdates()
  assert(not b.dispel:IsShown(), "cadre de dissipation coupe")
  Z.db.showDispel = true
  AURAS["HARMFUL|RAID"] = nil
  Z.db.importantNames["X"] = true Z:Refresh() RunUpdates()
  assert(b.bigIcon and b.bigIcon:IsShown(), "affaiblissement important")
  Z.db.importantNames = {} Z.db.ignoredNames["X"] = true Z.db.extraTracked["Autre"] = true Z:Refresh() RunUpdates()
  assert(not b.bigIcon:IsShown() and #b.hots == 2 and b.hots[2]:IsShown(), "listes personnelles")
  Z.db.ignoredNames = {} Z.db.extraTracked = {}
  -- une case en erreur ne prive plus les autres de leurs auras : l'erreur va au journal
  local hotIcon, cells = Z.HotIcon, {}
  for _, x in ipairs(Z.buttons) do if x.unit and x:IsVisible() and not x.extra then cells[#cells + 1] = x end end
  assert(#cells >= 2, "il faut deux cases")
  for _, x in ipairs(cells) do for _, icon in ipairs(x.hots) do icon:Hide() end end
  Z.HotIcon = function(x, i) if x ~= cells[1] then error("case fautive") end return hotIcon(x, i) end
  for _, x in ipairs(cells) do Z.QueueAuras(x) end
  RunUpdates()
  Z.HotIcon = hotIcon
  assert(cells[1].hots[1] and cells[1].hots[1]:IsShown(), "une case en erreur arrete les autres")
  local logged = false
  for _, e in ipairs(Z.db.errors) do
    if tostring(e.message):find("case fautive", 1, true) then
      logged = true
      assert(type(e.instance) == "string" and e.instance ~= "", "contexte d'instance absent du journal")
      assert(type(e.stack) == "string" and e.stack ~= "", "pile d'appels absente du journal")
    end
  end
  assert(logged, "erreur des auras absente du journal")
  -- contexte : donjon et auras cachees par le jeu
  local inInstance, secrets = IsInInstance, C_Secrets
  IsInInstance = function() return true, "party" end
  C_Secrets = { ShouldAurasBeSecret = function() return MakeSecret() end }
  assert(Z:InstanceState() == "donjon, auras secrètes", Z:InstanceState())
  IsInInstance, C_Secrets = inInstance, secrets
  assert(Z:LogText():find("case fautive", 1, true), "journal lisible")
  Z:ClearLog()
  -- donjon : le detail des changements d'auras est secret (1 736 erreurs dans Logs\General.log, 17 novembre 2026).
  -- Les icones doivent quand meme se mettre a jour, sans aucune erreur.
  for _, icon in ipairs(b.hots) do icon:Hide() end
  FireEvent("UNIT_AURA", "player", { addedAuras = MakeSecret(), removedAuraInstanceIDs = MakeSecret() })
  FireEvent("UNIT_AURA", "player", { addedAuras = { MakeSecret() }, removedAuraInstanceIDs = { MakeSecret() } })
  FireEvent("UNIT_AURA", "player", MakeSecret())
  RunUpdates()
  assert(#Z.db.errors == 0, "detail secret des auras : " .. tostring(Z.db.errors[1] and Z.db.errors[1].message))
  assert(b.hots[1]:IsShown(), "icones non mises a jour quand le detail des auras est secret")
  AURAS = {}
  FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(not b.dispel:IsShown() and not b.hots[1]:IsShown() and not b.debuffs[1]:IsShown())
end)

step("buff de groupe manquant", function()
  local b = Z.buttons[1]
  assert(#Z.buffChecks == 1, "buffs surveilles : " .. #Z.buffChecks)
  FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(b.buffIcon and b.buffIcon:IsShown(), "buff manquant non signale")
  AURAS["HELPFUL"] = { { name = "Prière de robustesse", icon = 9, auraInstanceID = 31 } }
  FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(not b.buffIcon:IsShown(), "buff present mais signale manquant")
  AURAS = {} COMBAT = true FireEvent("PLAYER_REGEN_DISABLED") RunUpdates()
  assert(not b.buffIcon:IsShown(), "buff manquant affiche en combat")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
  assert(b.buffIcon:IsShown())
  Z.db.missingBuffs = false Z:Refresh() RunUpdates() assert(not b.buffIcon:IsShown())
  Z.db.missingBuffs = true
end)

step("evenements globaux et portee", function()
  for _, e in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_ROLES_ASSIGNED", "PLAYER_TARGET_CHANGED", "RAID_TARGET_UPDATE",
    "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED", "SPELLS_CHANGED" }) do FireEvent(e) end
  TICK()
  Z.buttons[1]:Run("OnEnter") Z.buttons[1]:Run("OnLeave")
end)

step("combat avec valeurs secretes", function()
  SECRET = true COMBAT = true
  AURAS["HELPFUL|PLAYER"] = { { name = MakeSecret(), icon = 1, auraInstanceID = 11, spellId = MakeSecret() } }
  AURAS["HARMFUL"] = { { name = MakeSecret(), icon = 3, auraInstanceID = 21, spellId = MakeSecret(), dispelName = MakeSecret(), isBossAura = MakeSecret() } }
  AURAS["HARMFUL|RAID"] = { AURAS["HARMFUL"][1] }
  for _, mode in ipairs({ { "CLASS", "DEFICIT", "ICONS" }, { "HEALTH", "PERCENT", "BARS" }, { "HEALTH", "NONE", "ICONS" } }) do
    Z.db.color, Z.db.text, Z.db.hotStyle = mode[1], mode[2], mode[3]
    Z:Refresh()
    for _, e in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_HEAL_PREDICTION", "UNIT_AURA", "UNIT_FLAGS", "UNIT_THREAT_SITUATION_UPDATE",
      "INCOMING_RESURRECT_CHANGED", "UNIT_POWER_UPDATE", "UNIT_CONNECTION" }) do FireEvent(e, "player") end
    for _, e in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "PLAYER_TARGET_CHANGED", "RAID_TARGET_UPDATE", "READY_CHECK" }) do FireEvent(e) end
    RunUpdates() TICK()
  end
  FireEvent("UNIT_POWER_UPDATE", "player") -- annonces : la mana secrete est ignoree sans erreur
  FireEvent("UNIT_SPELLCAST_SENT", "player", MakeSecret(), "cast", MakeSecret())
  SECRET = false COMBAT = false AURAS = {}
  Z.db.color, Z.db.text, Z.db.hotStyle = "CLASS", "DEFICIT", "ICONS"
  FireEvent("PLAYER_REGEN_ENABLED") Z:Refresh() RunUpdates()
end)

step("options : douze chapitres, recherche, libelles traduits", function()
  SlashCmdList.LYORUNE("")
  local w = Z:OptionsWindow()
  assert(w and w:IsShown() and #w.chapters == 12, "douze chapitres")
  assert(Z:OptionChapter() == "Accueil", "premiere ouverture de la partie : l'Accueil")
  for i = 1, 12 do w.Select(i) end
  w.Select("Clics") w.Select("Inconnu")
  local labels = Z:OptionLabels()
  assert(#labels >= 45, "reglages recenses : " .. #labels)
  local seen = {}
  for _, label in ipairs(labels) do assert(not seen[label], "reglage en double : " .. label) seen[label] = true end
  local missing = {}
  for _, label in ipairs(labels) do if not Z.translations.enUS[label] and not label:match("^%d+ ") then missing[#missing + 1] = label end end
  assert(#missing == 0, "sans traduction anglaise : " .. table.concat(missing, " | "))
  w.search:SetText("mana") w.search:Run("OnTextChanged", true)
  for key in pairs(Z.defaults) do assert(Z.db[key] ~= nil, "reglage sans valeur : " .. key) end
end)

step("reglages d'apparence et de rangement", function()
  for _, k in ipairs({ "width", "height", "spacing" }) do Z.db[k] = Z.db[k] + 2 end
  Z.db.color = "HEALTH" Z.db.text = "PERCENT" Z.db.layout = "ROLE" Z.db.roleOrder = "HEALER,TANK,DAMAGER" Z.db.horizontal = true
  Z.db.brightness = 60 Z.db.frameAlpha = 80 Z.db.highContrast = true Z.db.showTanks = true Z.db.pets = "RAID"
  Z:Refresh()
  assert(Z.buttons[1].text:GetText() == "80%", Z.buttons[1].text:GetText())
  assert(Z.header:GetAttribute("groupBy") == "ASSIGNEDROLE" and Z.header:GetAttribute("point") == "LEFT")
  assert(Z.header:GetAttribute("groupingOrder") == "HEALER,TANK,DAMAGER,NONE", Z.header:GetAttribute("groupingOrder"))
  assert(LyoruneTanks:IsShown() and not LyorunePets:IsShown() and LyoruneTanks:GetAttribute("roleFilter") == "TANK", "C26 : familiers hors raid collés au maître, pas de colonne")
  assert(Z:Theme().id == "CONTRAST")
  Z.db.highContrast = false Z.db.showTanks = false Z.db.pets = "PARTY" Z.db.text = "NONE" Z.db.color = "CLASS" Z.db.layout = "GROUP" Z.db.horizontal = false
  Z:Refresh()
  assert(not LyoruneTanks:IsShown())
  Z.db.text = "DEFICIT" Z:Refresh()
end)

step("clics, touches au survol", function()
  Z:SetClick("alt-3", "Dissipation de la magie")
  assert(Z.buttons[3]:GetAttribute("alt-spell3") == "Dissipation de la magie")
  Z:SetClick("1", "@target")
  assert(Z.buttons[1]:GetAttribute("type1") == "target" and Z.buttons[1]:GetAttribute("spell1") == nil)
  Z:SetClick("1", nil)
  assert(Z.buttons[1]:GetAttribute("type1") == nil)
  assert(Z:ClickLabel("shift-1") == "Maj + Clic gauche")
  assert(#Z:KnownSpells() == 4)
  local keys = Z:GetHoverKeys()
  keys[1] = { key = "F", spell = "Rénovation" }
  keys[2] = { key = "BUTTON7", spell = "Soins rapides" }
  keys[3] = { key = 'X") os.exit(', spell = "Piege" }
  Z:ApplyClicks()
  local b = Z.buttons[2]
  assert(b:GetAttribute("*type-zh1") == "spell" and b:GetAttribute("*spell-zh1") == "Rénovation")
  assert(b:GetAttribute("_onenter") == 'self:ClearBindings() self:SetBindingClick(true, "F", self, "zh1") self:SetBindingClick(true, "BUTTON7", self, "zh2")', b:GetAttribute("_onenter"))
  assert(Z.header:GetAttribute("_initialAttribute-_onenter") == b:GetAttribute("_onenter"))
  assert(Z.header:GetAttribute("_initialAttributeNames") == "_onenter,_onleave" and b:GetAttribute("_onleave") == "self:ClearBindings()")
  -- le jeu refuse un attribut « _ » dans le code de creation d'une case : aucun ne doit y figurer, ni dans la liste recopiee
  assert(not Z.header:GetAttribute("initialConfigFunction"):find('SetAttribute%("_'), "attribut _ dans le code de creation")
  for i = 1, Z.header:GetAttribute("z-count") do assert(Z.header:GetAttribute("z-key" .. i):sub(1, 1) ~= "_", "attribut _ recopie") end
  table.remove(keys, 3)
  Z:SetClick("1", "Soins rapides")
end)

step("bibliotheque de macros : visee, verification, partage", function()
  local b = Z.buttons[1]
  local function R(text) return Z:ResolveMacro(text) end
  -- une commande sans cible vise la case ; une cible écrite est respectée
  assert(R("/cast Soins rapides") == "/cast [@mouseover] Soins rapides", R("/cast Soins rapides"))
  assert(R("/cast [help] Soins; [harm] Châtiment") == "/cast [help,@mouseover] Soins; [harm,@mouseover] Châtiment", R("/cast [help] Soins; [harm] Châtiment"))
  assert(R("/cast [@player] Soins") == "/cast [@player] Soins")
  assert(R("/cast [@cible,dead] Résurrection; [@{cible}] Soins") == "/cast [@mouseover,dead] Résurrection; [@mouseover] Soins")
  assert(R("/cast [{cible}] Soins") == "/cast [@mouseover] Soins")
  assert(R("#showtooltip\n/use 13\n/stopcasting") == "#showtooltip\n/use 13\n/stopcasting")
  assert(R("/focus") == "/focus [@mouseover]" and R("/focus {cible}") == "/focus mouseover", R("/focus"))
  assert(R("/cast [mod:shift] Soins") == "/cast [mod:shift,@mouseover] Soins")
  assert(R("/castsequence reset=8 Rénovation, Soins") == "/castsequence [@mouseover] reset=8 Rénovation, Soins")
  Z.db.macroAutoTarget = false
  assert(R("/cast Soins") == "/cast Soins" and R("/cast [@cible] Soins") == "/cast [@mouseover] Soins")
  Z.db.macroAutoTarget = true
  -- vérification en direct
  local function C(body) local t = {} for _, p in ipairs(Z:CheckMacro(body)) do t[#t + 1] = p[1] .. ":" .. p[2] end return table.concat(t, "|") end
  assert(C("/cast Soins rapides") == "", C("/cast Soins rapides"))
  assert(C(""):find("vide"))
  assert(C("/cast [mod:shfit] Soins rapides"):find("shfit", 1, true))
  assert(C("/cast [ded] Soins rapides"):find("« ded »", 1, true))
  assert(C("/cast [nodead,spec:2,mod:alt] Soins rapides; [@player] Soins") == "", C("/cast [nodead,spec:2,mod:alt] Soins rapides; [@player] Soins"))
  assert(C("/cast [help Soins rapides"):find("^err:"))
  -- revue 1.23.5 : un mot de condition effacé pendant la frappe (« [:shift] ») ne doit pas planter
  local okEmpty, emptyWord = pcall(C, "/cast [:shift] Soins rapides")
  assert(okEmpty and emptyWord:find("^warn:"), tostring(emptyWord))
  assert(C("/cast Pluie de feu"):find("^warn:.*spécialisation active"), "sort d'une autre specialisation")
  assert(C("/run print(1)"):find("code", 1, true))
  assert(C("Soins"):find("barre oblique", 1, true))
  assert(C("/cast " .. string.rep("a", 260)):find("trop longue", 1, true))
  -- création, pose sur un clic, modification, renommage
  local m = Z:NewMacro("Bijou et soin", "/use 13\n/cast Soins rapides")
  assert(Z:NewMacro("Bijou et soin", "").name == "Bijou et soin 2", "nom libre")
  Z:RemoveMacro(Z:FindMacro("Bijou et soin 2"))
  Z:SetClick("alt-4", "@macro:Bijou et soin")
  assert(b:GetAttribute("alt-type4") == "macro" and b:GetAttribute("alt-macrotext4") == "/use 13\n/cast [@mouseover] Soins rapides", tostring(b:GetAttribute("alt-macrotext4")))
  m.body = "/cast [@cible] Soins" Z:ApplyClicks()
  assert(b:GetAttribute("alt-macrotext4") == "/cast [@mouseover] Soins", "la macro modifiee doit suivre")
  assert(Z:MacroUses(m)[1] == "Alt + Bouton 4")
  assert(Z:RenameMacro(m, "Soin vite") and Z:GetClicks()["alt-4"] == "@macro:Soin vite", "renommage")
  Z:NewMacro("Autre", "/cast Soins")
  assert(not Z:RenameMacro(m, "autre"), "nom deja pris")
  Z:RemoveMacro(Z:FindMacro("Autre"))
  -- jamais partagée : ni exportée, ni acceptée dans un code reçu
  local code = Z:Export()
  assert(not code:find("%40macro", 1, true) and not code:find("%2F", 1, true), "une macro ne doit pas etre exportee")
  local before = Z:GetClicks()["1"]
  local ok = Z:Import("Lyorune2;c." .. Z.class .. ".1=s%40macro%3ASoin%20vite;c." .. Z.class .. ".2=s%2Fgquit;c." .. Z.class .. ".3=sSoins%0A%2Fgquit;width=n90")
  assert(ok and Z:GetClicks()["1"] == before and Z:GetClicks()["2"] ~= "/gquit" and Z:GetClicks()["3"] ~= "Soins\n/gquit", "macro importee")
  Z.db.width = 86 Z:Refresh()
  -- la réinitialisation garde mes macros
  assert(Z.private.macros, "la reinitialisation ne doit pas effacer mes macros")
  -- assistant
  local text = Z:MacroFromWizard({ spell = "Soins rapides", stop = true, trinket1 = true, res = true, harm = "Châtiment" })
  assert(text == "/stopcasting\n/use 13\n/cast [@cible,help,dead] Résurrection; [@cible,harm,nodead] Châtiment; [@cible] Soins rapides", text)
  assert(Z:MacroIcon("/use 13\n/cast Soins rapides") == 1234)
  -- suppression : les clics qui l'utilisaient sont vidés
  Z:RemoveMacro(m)
  assert(Z:GetClicks()["alt-4"] == nil and b:GetAttribute("alt-type4") == nil)
end)

step("macros pour les barres de sorts", function()
  local function find(name) local i = GetMacroIndexByName(name) return i > 0 and GetMacroBody(i) or nil end
  assert(Z.db.actionBarMacros == false and #MACROS == 0, "aucune macro ne doit etre creee sans qu'on le demande")
  MACROS[#MACROS + 1] = { name = "Ma macro", icon = 134400, body = "/dance" } -- une macro du joueur : jamais touchée
  Z.db.actionBarMacros = true
  Z:SetClick("1", "Soins rapides") Z:SetClick("ctrl-2", "Résurrection")
  assert(find("Lyo:Soins rapide") == "#showtooltip Soins rapides\n/cast [@mouseover,help,nodead][help,nodead] [@player] Soins rapides", tostring(find("Lyo:Soins rapide")))
  assert(find("Lyo:Résurrectio") == "#showtooltip Résurrection\n/cast [@mouseover,help,dead][help,dead] Résurrection", tostring(find("Lyo:Résurrectio")))
  for _, m in ipairs(MACROS) do assert(#m.name <= 16, m.name) end
  local count = #MACROS
  Z:ApplyClicks() assert(#MACROS == count, "macros creees en double")
  -- une macro du joueur posee sur un clic donne aussi une macro de barre, au nom du clic
  Z:SetClick("shift-4", "/use 13\n/cast [{cible}] Soins rapides")
  assert(find("Lyo:shift-4") == "#showtooltip\n/use 13\n/cast [@mouseover,help][] Soins rapides", tostring(find("Lyo:shift-4")))
  Z:SetClick("shift-4", "/use 14\n/cast [{cible}] Soins rapides")
  assert(find("Lyo:shift-4") == "#showtooltip\n/use 14\n/cast [@mouseover,help][] Soins rapides", "macro non mise a jour")
  Z:SetClick("shift-4", nil)
  assert(not find("Lyo:shift-4") and find("Ma macro") == "/dance", "retrait d'un clic")
  -- en combat : rien n'est cree, tout est rattrape a la fin
  COMBAT = true Z:SetClick("alt-5", "Prière") assert(not find("Lyo:Prière"))
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") assert(find("Lyo:Prière"))
  Z:SetClick("alt-5", nil)
  -- icones de l'onglet Clics : un clic prend la macro en main
  Z:ToggleOptions("Clics")
  local shown = 0
  for _, icon in ipairs(Z:BarIcons()) do
    if icon:IsShown() then shown = shown + 1 if icon.macro.name == "Lyo:Soins rapide" then icon:Run("OnClick") end end
  end
  assert(shown == #Z:BarMacros() and shown > 0 and PICKED == "Lyo:Soins rapide", "icones des macros : " .. shown)
  -- option coupee : plus aucune creation ; le bouton de retrait ne retire que les macros de Lyorune
  Z.db.actionBarMacros = false Z:SetClick("alt-5", "Prière") assert(not find("Lyo:Prière"))
  Z:SetClick("alt-5", nil)
  Z:RemoveBarMacros()
  assert(#MACROS == 1 and MACROS[1].name == "Ma macro", "retrait : " .. #MACROS)
  Z.db.actionBarMacros = true Z:ApplyClicks() assert(find("Lyo:Soins rapide"))
  Z:SetClick("ctrl-2", nil)
  Z.db.actionBarMacros = false Z:RemoveBarMacros()
  Z:ToggleOptions()
  -- une macro creee d'office par la 1.5.1 est retiree une fois, sans toucher aux autres
  assert(#MACROS == 1 and MACROS[1].name == "Ma macro")
  -- une macro du joueur dont le nom commence par « Lyo: » : ni modifiée, ni retirée
  MACROS[#MACROS + 1] = { name = "Lyo:Perso", icon = 1, body = "/dance" }
  MACROS[#MACROS + 1] = { name = "Lyo:Soins rapide", icon = 1, body = "/cast Soins rapides" }
  Z.db.actionBarMacros = true Z:ApplyClicks()
  Z.db.actionBarMacros = false Z:RemoveBarMacros()
  assert(find("Lyo:Perso") == "/dance" and find("Lyo:Soins rapide") == "/cast Soins rapides", "macro du joueur touchee")
  -- reprise : une macro « Lyo: » posée par une ancienne version, écrite comme Lyorune l'écrit, reste retirable
  Z.char.barMacrosAdopted = nil
  MACROS[#MACROS + 1] = { name = "Lyo:Ancienne", icon = 1, body = "#showtooltip Soins\n/cast [@mouseover,help,nodead][help,nodead] [@player] Soins" }
  Z:RemoveBarMacros()
  assert(not find("Lyo:Ancienne") and find("Lyo:Perso") == "/dance", "reprise des anciennes macros")
  table.remove(MACROS) table.remove(MACROS)
  assert(#MACROS == 1 and MACROS[1].name == "Ma macro")
end)

step("macros : fenetre, glisser-deposer, reprise des anciennes", function()
  local b = Z.buttons[1]
  -- reprise : une macro écrite sur un clic (1.5.0) et le nom d'une macro de /macro (1.5.4)
  Z:GetClicks()["shift-4"] = "/use 13\n/cast [{cible}] Soins"
  MACROS[#MACROS + 1] = { name = "Bijou soin", icon = 134400, body = "/use 14\n/cast [@mouseover] Soins" }
  Z:GetClicks()["alt-5"] = "@macro:Bijou soin"
  Z:MigrateMacros(true) Z:ApplyClicks()
  assert(Z:GetClicks()["shift-4"] == "@macro:Maj + Bouton 4", tostring(Z:GetClicks()["shift-4"]))
  assert(Z:FindMacro("Maj + Bouton 4").body == "/use 13\n/cast [{cible}] Soins")
  assert(Z:FindMacro("Bijou soin").body == "/use 14\n/cast [@mouseover] Soins")
  assert(b:GetAttribute("alt-macrotext5") == "/use 14\n/cast [@mouseover] Soins")
  assert(b:GetAttribute("shift-macrotext4") == "/use 13\n/cast [@mouseover] Soins")
  -- fenêtre : vérification et aperçu en direct, enregistrement, renommage
  local w = Z:OpenMacros("Bijou soin")
  assert(w:IsShown() and w.macro.name == "Bijou soin" and w.edit:GetText() == "/use 14\n/cast [@mouseover] Soins")
  w.edit:SetText("/cast [mod:shfit] Soins") w.edit:Run("OnTextChanged")
  assert(w.problems:GetText():find("shfit", 1, true), w.problems:GetText())
  assert(w.preview:GetText() == "/cast [mod:shfit,@mouseover] Soins", w.preview:GetText())
  w.edit:SetText("/cast Soins rapides") w.save:Run("OnClick")
  assert(b:GetAttribute("alt-macrotext5") == "/cast [@mouseover] Soins rapides")
  assert(w.uses:GetText():find("Alt + Bouton 5", 1, true), w.uses:GetText())
  w.name:SetText("Soin du bijou") w.name:Run("OnEnterPressed")
  assert(Z:GetClicks()["alt-5"] == "@macro:Soin du bijou", "renommage par la fenetre")
  -- glisser une macro de la liste sur une case de l'onglet Clics
  Z:SetClick("ctrl-4", "Soins")
  Z:ToggleOptions("Clics")
  local cell = Z:ClickCell("ctrl-4")
  local row
  for _, r in ipairs(w.rows) do if r.macro and r.macro.name == "Soin du bijou" then row = r end end
  -- 6c nonies c : hors combat, la macro part en main comme une macro de /macro (sa copie), qu'une ligne reconnaît
  Z:MacroDragStart(row)
  assert(PICKED == "Lyo:Soin du bijo" and CURSOR_INFO and CURSOR_INFO[1] == "macro", "copie en main : " .. tostring(PICKED))
  assert(not Z:MacroDragStop(), "copie en main : rien a deposer soi-meme")
  cell:Run("OnReceiveDrag")
  assert(Z:GetClicks()["ctrl-4"] == "@macro:Soin du bijou" and not Z:FindMacro("Lyo:Soin du bijo"), "copie reconnue : " .. tostring(Z:GetClicks()["ctrl-4"]))
  -- en combat : pas de copie, la macro se pose encore sur une ligne de Lyorune
  Z:SetClick("ctrl-4", "Soins")
  COMBAT = true
  MOUSE_FOCI = { cell.label }
  Z:MacroDragStart(row)
  assert(Z:MacroDragStop(), "rien sous la souris")
  MOUSE_FOCI = false
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  assert(Z:GetClicks()["ctrl-4"] == "@macro:Soin du bijou")
  assert(cell.label:GetText():find("Soin du bijou", 1, true), cell.label:GetText())
  -- glisser un sort du grimoire, puis une macro de /macro, sur une case
  CURSOR_INFO = { "spell", 1, "spell", 139 }
  cell:Run("OnReceiveDrag")
  assert(Z:GetClicks()["ctrl-4"] == "Rénovation" and not CURSOR_INFO)
  MACROS[#MACROS + 1] = { name = "Danse", icon = 1, body = "/dance" }
  CURSOR_INFO = { "macro", 120 + #MACROS }
  cell:Run("OnClick", "LeftButton")
  assert(Z:GetClicks()["ctrl-4"] == "@macro:Danse" and Z:FindMacro("Danse"), tostring(Z:GetClicks()["ctrl-4"]))
  -- la fenêtre de choix d'un clic montre ma bibliothèque
  cell:Run("OnClick", "LeftButton")
  assert(LyorunePicker:IsShown() and LyorunePicker.macroHead:IsShown())
  LyorunePicker:Hide()
  -- importer de /macro : une macro au même nom mais au texte différent reçoit un nouveau nom
  -- revue 1.23.5 : la phrase « aucune macro » ne reste pas quand des macros sont apparues depuis
  local saved = MACROS
  MACROS = {}
  Z:OpenMacroImport():Hide()
  MACROS = saved
  local imp = Z:OpenMacroImport()
  assert(not imp.note:GetText():find("Aucune macro", 1, true), "note de l'import restee sur aucune macro")
  for _, icon in ipairs(imp.icons) do if icon:IsShown() and icon.game.name == "Bijou soin" then icon:Run("OnClick") end end
  assert(Z:FindMacro("Bijou soin") and Z:FindMacro("Bijou soin").body == "/use 14\n/cast [@mouseover] Soins", "import")
  -- assistant
  local wiz = Z:OpenMacroWizard()
  wiz.opts.stop, wiz.opts.spell = true, "Soins rapides" wiz.Update()
  assert(wiz.preview:GetText():find("/stopcasting", 1, true))
  wiz.create:Run("OnClick")
  assert(Z:FindMacro("Soins rapides") and w.macro.name == "Soins rapides", "macro de l'assistant")
  -- nettoyage
  w:Hide() Z:ToggleOptions()
  Z:SetClick("shift-4", nil) Z:SetClick("alt-5", nil) Z:SetClick("ctrl-4", nil)
  Z.db.macros[Z.class] = {}
  for i = #MACROS, 2, -1 do table.remove(MACROS, i) end
end)

step("clics propres a chaque specialisation", function()
  local b = Z.buttons[1]
  local saved = CopyTable(Z.db.clicks.PRIEST)
  assert(Z:SpecGroup() == 1 and Z:ClickSet() == "PRIEST")
  SPEC_GROUP = 2 FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  assert(Z:ClickSet() == "PRIEST2" and Z.db.clicks.PRIEST2["1"] == saved["1"], "copie de la premiere specialisation")
  Z:SetClick("1", "Rénovation")
  assert(b:GetAttribute("spell1") == "Rénovation" and Z.db.clicks.PRIEST["1"] == saved["1"])
  -- une même macro sert dans les deux spécialisations, et s'adapte avec [spec:N]
  local m = Z:NewMacro("Commune", "/cast [spec:1] Soins rapides; [spec:2] Rénovation")
  Z:SetClick("shift-5", "@macro:Commune")
  assert(b:GetAttribute("shift-macrotext5") == "/cast [spec:1,@mouseover] Soins rapides; [spec:2,@mouseover] Rénovation", tostring(b:GetAttribute("shift-macrotext5")))
  SPEC_GROUP = 1 FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  assert(b:GetAttribute("spell1") == saved["1"] and b:GetAttribute("shift-type5") == nil, "retour a la premiere specialisation")
  Z:RenameMacro(m, "Partout")
  assert(Z.db.clicks.PRIEST2["shift-5"] == "@macro:Partout", "renommage dans l'autre specialisation")
  -- le partage emporte la seconde spécialisation
  local code = Z:Export()
  assert(code:find("c.PRIEST2.1=s", 1, true), "seconde specialisation absente du partage")
  Z.db.clicks.PRIEST2 = nil
  assert(Z:Import(code) and Z.db.clicks.PRIEST2["1"] == "Rénovation")
  -- copier l'autre spécialisation
  Z:CopyOtherSpec() assert(Z.db.clicks.PRIEST["1"] == "Rénovation")
  -- interrupteur coupé : les mêmes clics partout
  SPEC_GROUP = 2 Z.db.clicksPerSpec = false
  assert(Z:ClickSet() == "PRIEST")
  Z.db.clicksPerSpec = true SPEC_GROUP = 1
  -- revue 1.23.7 : « Reprendre les clics proposés » en 2e spécialisation remplace ceux de la 2e, pas ceux de la 1re
  SPEC_GROUP = 2 FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  Z.db.clicks.PRIEST["1"] = "Rénovation" Z:SetClick("1", "Rénovation")
  Z:ResetClassClicks()
  assert(Z.db.clicks.PRIEST2["1"] == saved["1"], "clics proposés en 2e spécialisation")
  assert(Z.db.clicks.PRIEST["1"] == "Rénovation", "la 1re spécialisation ne change pas")
  assert(Z.buttons[1]:GetAttribute("spell1") == saved["1"], "clic appliqué tout de suite")
  SPEC_GROUP = 1 FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  Z:ResetClassClicks()
  assert(Z.db.clicks.PRIEST["1"] == saved["1"], "clics proposés en 1re spécialisation")
  -- onglet Clics : la spécialisation affichée
  Z:ToggleOptions("Clics")
  assert(Z:OptionsWindow():IsShown())
  Z:ToggleOptions()
  Z.db.clicks.PRIEST = saved Z.db.clicks.PRIEST2 = nil Z.db.hoverKeys.PRIEST2 = nil
  Z.db.macros[Z.class] = {}
  Z:ApplyClicks()
end)

step("combat : report des changements", function()
  COMBAT = true
  Z:SetClick("1", "Soins")
  assert(Z.buttons[1]:GetAttribute("spell1") == "Soins rapides")
  Z.db.width = 120 Z:Refresh()
  assert(Z.header:GetAttribute("z-width") ~= 120)
  COMBAT = false
  FireEvent("PLAYER_REGEN_ENABLED")
  assert(Z.buttons[1]:GetAttribute("spell1") == "Soins")
  assert(Z.header:GetAttribute("z-width") == 120)
  Z.db.width = 86 Z:Refresh()
end)

step("mode test", function()
  Z:TogglePreview(25)
  assert(Z.previewActive and LyorunePreview:IsShown() and not Z.header:IsShown(), "mode test")
  for _, style in ipairs({ "BARS", "ICONS" }) do Z.db.hotStyle = style Z.db.horizontal = not Z.db.horizontal Z:Refresh() end
  Z:TogglePreview(40) assert(Z.previewActive and Z:PreviewSize() == 40)
  COMBAT = true FireEvent("PLAYER_REGEN_DISABLED")
  assert(not Z.previewActive, "le mode test doit se fermer en combat")
  assert(Z.header:IsShown(), "les vrais cadres doivent revenir des le debut du combat")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  assert(Z.header:IsShown(), "les vrais cadres doivent rester apres le combat")
  Z.db.horizontal = false Z:Refresh()
end)

step("affichage des cadres : toujours, ou en combat seulement", function()
  assert(Z.db.visibility == "ALWAYS" and Z.header:IsShown())
  Z.db.visibility = "COMBAT" Z:Refresh()
  assert(not Z.header:IsShown(), "en combat seulement : masque hors combat")
  COMBAT = true FireEvent("PLAYER_REGEN_DISABLED")
  assert(Z.header:IsShown(), "en combat seulement : affiche en combat")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  assert(not Z.header:IsShown())
  COMBAT = true FireEvent("PLAYER_REGEN_DISABLED")
  Z.db.visibility = "ALWAYS" Z:Refresh() -- change en plein combat : applique a la fin
  assert(Z.header:IsShown())
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  assert(Z.header:IsShown(), "toujours : affiche hors combat")
  COMBAT = true FireEvent("PLAYER_REGEN_DISABLED")
  assert(Z.header:IsShown(), "toujours : affiche en combat")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  assert(#Z.choices.visibility == 2, "deux choix seulement")
  assert(not LyoruneTanks:IsShown(), "un cadre coupe reste masque")
  -- la poignee refusee en combat ne doit rien demander au jeu en fin de glissement
  local stopped = 0
  Z.anchor.StopMovingOrSizing = function() stopped = stopped + 1 end
  Z.anchor.StartMoving = function() end
  local handle = Z.header.handle
  COMBAT = true handle:Run("OnDragStart") handle:Run("OnDragStop")
  assert(stopped == 0, "StopMovingOrSizing appele en combat")
  COMBAT = false handle:Run("OnDragStart") handle:Run("OnDragStop")
  assert(stopped == 1)
  -- releve automatique de l'etat des cadres, et erreur d'habillage ecrite au journal
  Z.db.frameStateLogout = nil FireEvent("PLAYER_LOGOUT")
  local state = table.concat(Z.db.frameStateLogout, "\n")
  assert(state:find("cadre main", 1, true) and state:find("aucune case creee", 1, true) and state:find("showSolo=true", 1, true), state)
  Z.header:SetAttribute("child1", Z.buttons[1])
  state = table.concat(Z:FrameState(), "\n")
  assert(state:find("case 1", 1, true) and state:find("unit=player", 1, true) and state:find("habillee=true", 1, true), state)
  -- /lyorune diag garde le releve du moment (C38 : couches qui couvrent la case)
  Z.db.frameStateDiag = nil Z:DiagnoseFrames()
  assert(Z.db.frameStateDiag and table.concat(Z.db.frameStateDiag, " "):find("case 1", 1, true), "releve de /lyorune diag")
  Z.db.frameStateDiag = nil
  Z.header:SetAttribute("child1", nil)
  assert(Z:LogText():find("État des cadres", 1, true))
  Z.db.errors = {}
  assert(Z:Try("essai", function() error("boum") end) == false and #Z.db.errors == 1 and Z.db.errors[1].message:find("boum"))
  Z.db.errors = {}
  local n = #PRINTED
  Z:DiagnoseFrames()
  assert(#PRINTED == n + 3 and PRINTED[n + 1]:find("cases créées", 1, true), "diagnostic des cadres")
  for i = #PRINTED, n + 1, -1 do PRINTED[i] = nil end
end)

step("tutoriel", function()
  Z.db.tutorialDone = false
  Z:StartTutorial()
  local card = LyoruneTutorial
  for i = 1, #card.runes do card.next:Run("OnClick") end
  assert(Z.db.tutorialDone and not card:IsShown() and not Z.previewActive)
  Z:StartTutorial() card.next:Run("OnClick") card.back:Run("OnClick") card.close:Run("OnClick")
  -- lot 13 : l'etape « Placer les cadres » libere les cadres, puis rend le verrou du joueur
  Z.db.lockMode = "LOCKED" Z:StartTutorial()
  for i = 1, 4 do card.next:Run("OnClick") end
  assert(Z.db.lockMode == "FREE", "cadres libres pendant l'etape")
  card.next:Run("OnClick")
  assert(Z.db.lockMode == "LOCKED", "verrou perdu apres l'etape")
  card.back:Run("OnClick") assert(Z.db.lockMode == "FREE")
  card.close:Run("OnClick")
  assert(Z.db.lockMode == "LOCKED", "verrou perdu a la fermeture")
  Z.db.lockMode = "FREE" Z:Refresh()
  SlashCmdList.LYORUNE("verrou") SlashCmdList.LYORUNE("verrou") SlashCmdList.LYORUNE("reset") SlashCmdList.LYORUNE("tuto") SlashCmdList.LYORUNE("test") SlashCmdList.LYORUNE("test")
  LyoruneTutorial.close:Run("OnClick")
  Lyorune_OnAddonCompartmentClick() Lyorune_OnAddonCompartmentClick()
end)

step("themes", function()
  assert(#Z.themes == 5)
  for _, theme in ipairs(Z.themes) do
    Z.db.theme = theme.id Z.db.texture = "THEME" Z:Refresh()
    assert(Z:Theme() == theme and Z.UI.BarTexture() == theme.texture)
  end
  Z.db.theme = "INCONNU" assert(Z:Theme().id == "PURE")
  Z.db.theme = "PURE"
end)

step("annonces de mana", function()
  Z.db.manaThreshold = 20 Z.db.regenThreshold = 90 Z.db.manaAlert = true Z.db.regenAlert = true Z.db.alertChannel = "SAY"
  Z:RefreshAlerts()
  MANA = 500 FireEvent("UNIT_POWER_UPDATE", "player") assert(#SENT == 0)
  MANA = 180 FireEvent("UNIT_POWER_UPDATE", "player")
  assert(#SENT == 1 and SENT[1] == "SAY:Mana faible : 18 % ! Laissez-moi boire.", SENT[1])
  MANA = 150 FireEvent("UNIT_POWER_UPDATE", "player") assert(#SENT == 1, "annonce repetee")
  MANA = 600 FireEvent("UNIT_POWER_UPDATE", "player") assert(#SENT == 1, "regen trop tot")
  MANA = 950 FireEvent("UNIT_POWER_UPDATE", "player")
  assert(#SENT == 2 and SENT[2] == "SAY:Mana remontée (95 %), prêt à repartir !", SENT[2])
  MANA = 100 FireEvent("UNIT_POWER_UPDATE", "player") assert(#SENT == 2, "delai anti-spam ignore")
  MANA = 950 FireEvent("UNIT_POWER_UPDATE", "player") NOW = 200
  INSTANCE = false MANA = 100 FireEvent("UNIT_POWER_UPDATE", "player")
  assert(SENT[#SENT]:match("^PARTY:Mana faible"), SENT[#SENT])
  -- groupe d'instance (outil de recherche) : canal d'instance, « PARTY » serait refuse en silence par le jeu
  local inGroup = IsInGroup
  LE_PARTY_CATEGORY_HOME, LE_PARTY_CATEGORY_INSTANCE = 1, 2
  IsInGroup = function(category) return category ~= 1 end
  MANA = 950 FireEvent("UNIT_POWER_UPDATE", "player") NOW = 250
  MANA = 100 FireEvent("UNIT_POWER_UPDATE", "player")
  assert(SENT[#SENT]:match("^INSTANCE_CHAT:Mana faible"), "groupe d'instance : " .. SENT[#SENT])
  IsInGroup, LE_PARTY_CATEGORY_HOME, LE_PARTY_CATEGORY_INSTANCE = inGroup, nil, nil
  INSTANCE = true
  Z.db.manaAlert = false Z.db.regenAlert = false Z:RefreshAlerts()
  local n = #SENT MANA = 950 FireEvent("UNIT_POWER_UPDATE", "player") MANA = 50 FireEvent("UNIT_POWER_UPDATE", "player")
  assert(#SENT == n, "annonce alors que tout est desactive")
  -- revue 1.23.4 : le son de mana faible coche seul (annonces decochees) doit sonner
  local playSound, sounds = PlaySound, 0
  PlaySound = function() sounds = sounds + 1 end
  Z.db.soundMana = true Z:RefreshAlerts()
  MANA = 950 FireEvent("UNIT_POWER_UPDATE", "player") MANA = 50 FireEvent("UNIT_POWER_UPDATE", "player")
  assert(sounds == 1 and #SENT == n, "son de mana faible muet sans annonce")
  PlaySound = playSound Z.db.soundMana = false Z:RefreshAlerts()
  MANA = 1000
end)

step("mana secrete : la regle a sorts annonce la mana faible", function()
  local power, cost, usable, now0 = UnitPower, C_Spell.GetSpellPowerCost, C_Spell.IsSpellUsable, NOW
  UnitPower = function() return MakeSecret(MANA) end -- mana cachee, maximum lisible (1000)
  local costs = { [2061] = 190, [139] = 50, [17] = 450 } -- seuil 20 % : seul 2061 (19 %) sert de regle
  C_Spell.GetSpellPowerCost = function(id) return costs[id] and { { type = 0, cost = costs[id] } } or {} end
  C_Spell.IsSpellUsable = function(id) local c = costs[id] or 0 return MANA >= c, MANA < c end
  FireEvent("SPELLS_CHANGED")
  Z.db.manaThreshold = 20 Z.db.manaAlert = true Z.db.alertChannel = "SAY" Z:RefreshAlerts()
  NOW = 1000 local n = #SENT
  MANA = 600 FireEvent("UNIT_POWER_UPDATE", "player") assert(#SENT == n, "annonce trop tot")
  MANA = 150 FireEvent("UNIT_POWER_UPDATE", "player")
  assert(#SENT == n + 1 and SENT[#SENT] == "SAY:Mana faible : 19 % ! Laissez-moi boire.", tostring(SENT[#SENT]))
  MANA = 140 FireEvent("UNIT_POWER_UPDATE", "player") assert(#SENT == n + 1, "annonce repetee")
  -- sort refuse en combat faute de mana, alors que la regle n'a rien dit (aucun sort assez proche du seuil)
  MANA = 900 FireEvent("UNIT_POWER_UPDATE", "player") NOW = 1100
  Z.db.manaThreshold = 80 COMBAT = true
  FireEvent("UNIT_POWER_UPDATE", "player") assert(#SENT == n + 1, "regle sans sort proche du seuil")
  FireEvent("UI_ERROR_MESSAGE", 50, "Hors de vue") assert(#SENT == n + 1, "autre erreur prise pour la mana")
  FireEvent("UI_ERROR_MESSAGE", 50, ERR_OUT_OF_MANA)
  assert(#SENT == n + 2 and SENT[#SENT]:match("^SAY:Mana faible : 80 %%"), "sort refuse faute de mana : " .. tostring(SENT[#SENT]))
  COMBAT = false NOW = now0
  UnitPower, C_Spell.GetSpellPowerCost, C_Spell.IsSpellUsable = power, cost, usable
  FireEvent("SPELLS_CHANGED") Z.db.manaThreshold = 20 MANA = 1000 FireEvent("UNIT_POWER_UPDATE", "player")
end)

step("mana secrete : mana remontee estimee avec la regeneration (bug C8)", function()
  local power, cost, usable, now0 = UnitPower, C_Spell.GetSpellPowerCost, C_Spell.IsSpellUsable, NOW
  UnitPower = function() return MakeSecret(MANA) end
  local costs = { [139] = 50, [2061] = 190, [527] = 300, [17] = 450 } -- paliers 5, 19, 30 et 45 %
  C_Spell.GetSpellPowerCost = function(id) return costs[id] and { { type = 0, cost = costs[id] } } or {} end
  C_Spell.IsSpellUsable = function(id) local c = costs[id] or 0 return MANA >= c, MANA < c end
  -- régénération lue hors combat (boisson comprise), secrète en combat
  local RATE, regen = 20, GetPowerRegen
  GetPowerRegen = function() if COMBAT then return MakeSecret(RATE) end return RATE, 0 end
  FireEvent("SPELLS_CHANGED")
  Z.db.manaThreshold = 20 Z.db.regenThreshold = 90 Z.db.manaAlert = true Z.db.regenAlert = true Z.db.alertChannel = "SAY"
  Z:RefreshAlerts()
  local function At(t, mana) NOW = t MANA = mana FireEvent("UNIT_POWER_UPDATE", "player") end
  local n = #SENT
  At(2000, 600) At(2000, 150) assert(#SENT == n + 1, "mana faible")
  -- je bois : 20 de mana par seconde depuis le plancher sûr (50, le sort le moins cher)
  At(2010, 250) assert(#SENT == n + 1, "annonce trop tot (250)")
  At(2030, 650) assert(#SENT == n + 1, "annonce trop tot (650)")
  At(2040, 850) assert(#SENT == n + 1, "annonce trop tot (850)")
  At(2045, 950)
  assert(#SENT == n + 2 and SENT[#SENT] == "SAY:Mana remontée (95 %), prêt à repartir !", tostring(SENT[#SENT]))
  At(2050, 1000) assert(#SENT == n + 2, "annonce repetee")
  -- plafond : une régénération énorme ne passe pas le coût d'un sort qui manque de mana
  At(2100, 150) assert(#SENT == n + 3, "nouvelle mana faible")
  RATE = 1000
  At(2101, 160) At(2110, 200) assert(#SENT == n + 3, "estimation au-dessus d'un sort qui manque de mana")
  RATE = 20
  -- un sort lancé pendant la remontée : retour au plancher, et 5 secondes sans régénération
  At(2120, 460) -- estimation 450 au moins (plancher)
  FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 2061)
  At(2124, 270) At(2130, 340) -- plancher 190, 20/s seulement après les 5 s, puis plancher 300
  At(2155, 800) assert(#SENT == n + 3, "annonce trop tot apres un sort (800 estimes)")
  At(2165, 1000) assert(#SENT == n + 4, "mana remontee apres un sort")
  -- en combat la régénération est secrète : rien n'est ajouté, aucune annonce trop tôt
  At(2200, 150) assert(#SENT == n + 5, "mana faible avant le combat")
  COMBAT = true
  At(2210, 200) At(2400, 950) assert(#SENT == n + 5, "annonce en combat sans regeneration connue")
  COMBAT = false
  At(2410, 960) At(2450, 1000)
  assert(#SENT == n + 6, "mana remontee apres le combat")
  -- annonce de remontée décochée : rien
  Z.db.regenAlert = false Z:RefreshAlerts()
  At(2500, 150) At(2600, 1000) assert(#SENT == n + 7, "annonce alors qu'elle est decochee")
  Z.db.regenAlert = true Z:RefreshAlerts()
  GetPowerRegen = regen
  UnitPower, C_Spell.GetSpellPowerCost, C_Spell.IsSpellUsable, NOW = power, cost, usable, now0
  FireEvent("SPELLS_CHANGED") MANA = 1000 FireEvent("UNIT_POWER_UPDATE", "player")
end)

step("annonce de resurrection", function()
  Z.db.resAlert = true Z:RefreshAlerts()
  local n = #SENT
  FireEvent("UNIT_SPELLCAST_SENT", "player", "Thrall-Sulfuron", "cast", 2061) assert(#SENT == n)
  FireEvent("UNIT_SPELLCAST_SENT", "player", "Thrall-Sulfuron", "cast", 2006)
  assert(SENT[#SENT] == "SAY:Je ressuscite Thrall.", SENT[#SENT])
  Z.db.resText = "Debout {nom} !" NOW = 300
  Z.db.alertChannel = "GROUP"
  FireEvent("UNIT_SPELLCAST_SENT", "player", "Jaina", "cast", 2006)
  assert(SENT[#SENT] == "PARTY:Debout Jaina !", SENT[#SENT])
  GROUPED = false n = #SENT NOW = 400
  FireEvent("UNIT_SPELLCAST_SENT", "player", "Jaina", "cast", 2006) assert(#SENT == n, "annonce hors groupe")
  GROUPED = true
end)

step("partage, profils prets a l'emploi, reinitialisation", function()
  Z.db.theme = "HEROIC" Z.db.width = 100 Z.db.manaText = "Plus de mana ; = {mana} % !" Z.db.smooth = false Z.db.roleOrder = "DAMAGER,HEALER,TANK"
  Z.db.ignoredNames["Mal de mer"] = true
  Z:SetClick("ctrl-1", "Prière de guérison")
  local code = Z:Export()
  assert(code:match("^Lyorune2;") and not code:find(" "), code)
  Z.db.theme = "NEON" Z.db.width = 60 Z.db.manaText = "x" Z.db.smooth = true Z.db.clicks.PRIEST = {} Z.db.hoverKeys.PRIEST = {} Z.db.ignoredNames = {} Z.db.roleOrder = "TANK,HEALER,DAMAGER"
  local pos = Z.char.pos
  local ok, message = Z:Import("  " .. code .. "\n")
  assert(ok, message)
  assert(Z.db.theme == "HEROIC" and Z.db.width == 100 and Z.db.smooth == false and Z.db.roleOrder == "DAMAGER,HEALER,TANK")
  -- un texte libre (annonce dite dans le chat) ne circule jamais : ni à l'export, ni à l'import
  assert(Z.db.manaText == "x" and not code:find("manaText", 1, true), Z.db.manaText)
  Z.db.texture = "THEME"
  assert(not Z:Import("Lyorune2;manaText=sAchetez%20de%20l%27or;regenText=sx;resText=sx;texture=sInterface%5CFAUX"), "texte libre ou texture inconnue importes")
  assert(Z.db.manaText == "x" and Z.db.texture == "THEME")
  assert(Z:Import("Lyorune2;texture=s" .. Z.UI.TextureList()[1]) and Z.db.texture == Z.UI.TextureList()[1], "texture connue refusee")
  Z.db.texture = "THEME"
  assert(Z.db.clicks.PRIEST["ctrl-1"] == "Prière de guérison" and Z.db.ignoredNames["Mal de mer"])
  assert(Z.db.hoverKeys.PRIEST[2].key == "BUTTON7" and Z.db.hoverKeys.PRIEST[2].spell == "Soins rapides")
  assert(Z.buttons[1]:GetAttribute("ctrl-spell1") == "Prière de guérison" and Z.char.pos == pos)
  assert(not Z:Import("bonjour"))
  assert(not Z:Import("Lyorune2;width=sabc;theme=sFAUX;inconnu=n5;c.PRIEST.zz=sX;roleOrder=sTANK;l.pos=sX"))
  ok = Z:Import("Lyorune1;width=n9999;height=n-5;pos=sHACK;tutorialDone=bfalse;language=senUS")
  assert(ok and Z.db.width == 180 and Z.db.height == 24 and Z.db.pos == nil and Z.char.pos == pos and Z.db.tutorialDone == true and Z.db.language == "AUTO")
  assert(Z:ApplyPreset("COMPACT") and Z.db.width == 64 and Z.db.hotStyle == "ICONS" and Z.db.clicks.PRIEST["ctrl-1"])
  assert(not Z:ApplyPreset("INCONNU"))
  Z.db.errors = { { message = "garde" } }
  Z:ResetAll()
  assert(Z.db.width == 86 and Z.db.theme == "PURE" and Z.char.pos == pos and Z.db.errors[1].message == "garde")
  assert(Z.db.clicks.PRIEST["1"] == "Soins rapides" and next(Z.db.ignoredNames) == nil, "reinitialisation")
  Z.db.autoRes = false Z:ApplyClicks()
end)

step("entre joueurs : version et envoi de configuration", function()
  assert(Z.VersionNumber("1.10.2") > Z.VersionNumber("1.9.9") and Z.VersionNumber("abc") == 0)
  local n = #PRINTED
  FireEvent("CHAT_MSG_ADDON", "Lyorune", "V:0.9.0", "PARTY", "Ami") assert(#PRINTED == n)
  FireEvent("CHAT_MSG_ADDON", "Autre", "V:2.0.0", "PARTY", "Ami") assert(#PRINTED == n)
  -- numéros invraisemblables : ignorés, même annoncés par plusieurs joueurs
  for _, v in ipairs({ "99.0", "99.0.0", "3.0.0", "1.999.0", "1.9.0.1" }) do
    FireEvent("CHAT_MSG_ADDON", "Lyorune", "V:" .. v, "PARTY", "Ami")
    FireEvent("CHAT_MSG_ADDON", "Lyorune", "V:" .. v, "PARTY", "Autre")
  end
  assert(#PRINTED == n, "version invraisemblable signalee")
  -- un seul joueur ne suffit pas, même s'il répète ; un second joueur confirme
  FireEvent("CHAT_MSG_ADDON", "Lyorune", "V:2.0.0", "PARTY", "Ami")
  FireEvent("CHAT_MSG_ADDON", "Lyorune", "V:2.0.0", "PARTY", "Ami") assert(#PRINTED == n, "un seul joueur a suffi")
  FireEvent("CHAT_MSG_ADDON", "Lyorune", "V:2.0.0", "PARTY", "Autre") assert(#PRINTED == n + 1, "version plus recente non signalee")
  assert(PRINTED[#PRINTED]:find("github.com/BellaHealFr/Lyorune", 1, true), "source officielle absente")
  assert(PRINTED[#PRINTED]:find("releases/tag/v2.0.0", 1, true), "avis sans la page des nouveautes de cette version")
  FireEvent("CHAT_MSG_ADDON", "Lyorune", "V:2.0.0", "PARTY", "Troisieme") assert(#PRINTED == n + 1, "signalee deux fois")
  -- messages abîmés : aucune erreur
  for _, bad in ipairs({ "n'importe quoi", "C:1:99:2:x", "C:1:0:0:x", "C:a:1:1:x", "C:1:1:1:" .. ("x"):rep(300), "V:", "C:", ("x"):rep(255) }) do
    FireEvent("CHAT_MSG_ADDON", "Lyorune", bad, "WHISPER", "Ami")
  end
  FireEvent("CHAT_MSG_ADDON", "Lyorune", MakeSecret(), "WHISPER", "Ami")
  FireEvent("CHAT_MSG_ADDON", "Lyorune", "V:2.0.0", "WHISPER", MakeSecret())
  assert(not Z:SendConfig("  "))
  Z.db.width = 132 local first = #ADDON_SENT + 1
  assert(Z:SendConfig("Jaina"))
  assert(#ADDON_SENT - first + 1 >= 2 and ADDON_SENT[first].channel == "WHISPER" and ADDON_SENT[first].target == "Jaina")
  for i = first, #ADDON_SENT do assert(#ADDON_SENT[i].text <= 255, "message trop long") end
  Z.db.width = 86
  local function Receive(sender, from, to) for i = to or #ADDON_SENT, from or first, -1 do FireEvent("CHAT_MSG_ADDON", "Lyorune", ADDON_SENT[i].text, "WHISPER", sender) end end
  -- un inconnu (ni groupe, ni guilde, ni ami) : rien ne s'ouvre
  NOW = 1000 Receive("Inconnu-Ailleurs")
  assert(not rawget(_G, "LyoruneConfigPrompt"), "configuration d'un inconnu proposee")
  -- membre du groupe : la fenêtre s'ouvre, avec le royaume
  GROUP_NAMES.party2 = "Jaina"
  Receive("Jaina-MonRoyaume") -- dans le desordre
  assert(LyoruneConfigPrompt and LyoruneConfigPrompt:IsShown() and Z.db.width == 86, "rien ne doit s'appliquer sans accord")
  assert(LyoruneConfigPrompt.text:GetText():find("Jaina-MonRoyaume", 1, true), "royaume absent")
  -- un autre envoi pendant que la fenêtre est ouverte ne remplace rien
  FRIEND_LIST.Thrall = true
  Z.db.width = 150 local code2 = Z:Export() Z.db.width = 86
  FireEvent("CHAT_MSG_ADDON", "Lyorune", "C:77:1:1:" .. code2:sub(1, 200), "WHISPER", "Thrall-MonRoyaume")
  assert(LyoruneConfigPrompt.text:GetText():find("Jaina", 1, true), "fenetre remplacee")
  -- bouton Importer : sans effet avant le délai
  local opened = NOW
  LyoruneConfigPrompt.readyAt = NOW + 2
  LyoruneConfigPrompt.accept:Run("OnClick") assert(Z.db.width == 86 and LyoruneConfigPrompt:IsShown(), "import immediat")
  NOW = opened + 3
  LyoruneConfigPrompt.accept:Run("OnClick")
  assert(Z.db.width == 132 and not LyoruneConfigPrompt:IsShown())
  -- le même joueur, moins d'une minute après : ignoré ; après une minute : accepté
  Z.db.width = 86 NOW = opened + 30 Receive("Jaina-MonRoyaume")
  assert(not LyoruneConfigPrompt:IsShown(), "deux propositions en moins d'une minute")
  NOW = opened + 70 Receive("Jaina-MonRoyaume")
  assert(LyoruneConfigPrompt:IsShown(), "proposition refusee apres une minute")
  LyoruneConfigPrompt.refuse:Run("OnClick") assert(Z.db.width == 86)
  -- membre de la guilde accepté ; un envoi incomplet est oublié après 30 secondes
  GUILD_LIST.Anduin = true
  NOW = 2000 Receive("Anduin-MonRoyaume", first + 1)
  NOW = 2040 Receive("Anduin-MonRoyaume", first, first)
  assert(not LyoruneConfigPrompt:IsShown(), "envoi incomplet garde trop longtemps")
  GROUP_NAMES.party2, GUILD_LIST.Anduin, FRIEND_LIST.Thrall = nil, nil, nil
  Z.db.acceptConfigs = false Z.db.width = 86
  GROUP_NAMES.party2 = "Jaina" NOW = 3000 Receive("Jaina-MonRoyaume") GROUP_NAMES.party2 = nil
  assert(not LyoruneConfigPrompt:IsShown(), "configuration proposee alors que l'option est coupee")
  Z.db.acceptConfigs = true Z:Refresh()
end)

step("journal d'erreurs, diagnostic, nouveautes", function()
  assert(#Z:MissingAPI() == 0, table.concat(Z:MissingAPI(), ","))
  Z.db.errors = {}
  RaiseError("Interface/AddOns/Lyorune/Frames.lua:42: attempt to index nil")
  RaiseError("Interface/AddOns/Lyorune/Frames.lua:42: attempt to index nil")
  RaiseError("Interface/AddOns/AutreAddon/x.lua:1: rien a voir")
  assert(#Z.db.errors == 1 and Z.db.errors[1].count == 2, "journal : " .. #Z.db.errors)
  assert(LAST_ERROR:find("AutreAddon"), "le gestionnaire d'origine n'est plus appele")
  FireEvent("ADDON_ACTION_BLOCKED", "Lyorune", "Frame:SetAttribute()")
  FireEvent("ADDON_ACTION_BLOCKED", "Autre", "Frame:Show()")
  assert(#Z.db.errors == 2 and Z.db.errors[1].kind == "Action interdite en combat")
  local text = Z:LogText()
  assert(text:find("Frames.lua:42", 1, true) and text:find("PRIEST") and text:find("70938") and text:find("x2", 1, true), text)
  SlashCmdList.LYORUNE("erreurs") SlashCmdList.LYORUNE("diag") SlashCmdList.LYORUNE("nouveautes")
  -- une seule fenêtre à côté des options : les nouveautés, ouvertes en dernier, ont fermé le journal (retour 15)
  assert(LyoruneNews:IsShown() and not LyoruneLog:IsShown())
  local news = Z:NewsText()
  assert(news:find("Nouveau", 1, true) and news:find("Corrigé", 1, true) and news:find("n'est plus estompée", 1, true), "rubriques du journal")
  assert(Z.changes[1].version == Z.version, "Changes.lua n'est pas a jour : " .. Z.changes[1].version .. " / " .. Z.version)
  local saved = C_UnitAuras.GetAuraDuration C_UnitAuras.GetAuraDuration = nil
  assert(Z:MissingAPI()[1] == "C_UnitAuras.GetAuraDuration")
  C_UnitAuras.GetAuraDuration = saved
  Z.db.errors = {}
end)

step("signalement de bug, transparence, specialisation", function()
  Z.db.errors = {} Z.firstError = nil
  local report = Z:BugReport({ "Je soignais", "", "Oui" })
  assert(report:find("Je soignais", 1, true) and report:find("(sans réponse)", 1, true) and report:find("Aucune erreur technique", 1, true), report)
  assert(report:find("PRIEST niveau 60", 1, true) and report:find("[Lyorune " .. Z.version .. "]", 1, true), report)
  local n = #PRINTED
  Z.db.errorNotice = false
  RaiseError("Interface/AddOns/Lyorune/Auras.lua:10: premiere")
  assert(#PRINTED == n, "notification alors qu'elle est coupee")
  RaiseError("Interface/AddOns/Lyorune/Auras.lua:20: seconde")
  report = Z:BugReport()
  assert(report:find("premiere", 1, true) and not report:find("seconde", 1, true), "la premiere erreur doit etre en tete : " .. report)
  assert(Z.db.errors[1].level == 60 and Z.db.errors[1].spec ~= nil)
  -- ni nom de personnage ni royaume dans un rapport publié sur GitHub
  RaiseError("Interface/AddOns/Lyorune/Auras.lua:30: Joueur-party2 de MonRoyaume")
  report = Z:Anonymize(Z:BugReport({ "Je soignais Joueur-party1 sur Mon Royaume" }) .. "\n" .. Z.db.errors[1].message)
  assert(not report:find("Joueur-party", 1, true) and not report:find("Royaume", 1, true) and report:find("(joueur)", 1, true), report)
  assert(not Z:LogText():find("MonRoyaume", 1, true), "journal non anonymise")
  SlashCmdList.LYORUNE("bug") assert(LyoruneBug:IsShown())
  SlashCmdList.LYORUNE("position") assert(#Z.db.positionDiag == 1)
  Z.db.errors = {} Z.firstError = nil Z.db.errorNotice = true
  local w = Z:OptionsWindow() w.Select("Apparence")
  for _, entry in ipairs({ { "Discret", 55 }, { "Bien visible", 100 } }) do
    local found
    for _, label in ipairs(Z:OptionLabels()) do if label == entry[1] then found = true end end
    assert(found, "prereglage absent : " .. entry[1])
  end
  local before = Z.buttons[1]:GetAttribute("spell1")
  FireEvent("ACTIVE_TALENT_GROUP_CHANGED") FireEvent("PLAYER_TALENT_UPDATE")
  assert(Z.buttons[1]:GetAttribute("spell1") == before, "les clics doivent survivre a un changement de specialisation")
end)

step("composition du groupe : departs, arrivees, deconnexion", function()
  local b = Z.buttons[2]
  b:SetAttribute("unit", nil) b:Hide()                       -- un joueur quitte le groupe (ou est exclu)
  FireEvent("GROUP_ROSTER_UPDATE") FireEvent("UNIT_HEALTH", "party1") RunUpdates() TICK()
  b:SetAttribute("unit", "raid7") b:Show()                   -- le groupe devient un raid, un joueur arrive
  FireEvent("GROUP_ROSTER_UPDATE") FireEvent("UNIT_HEALTH", "raid7") RunUpdates()
  assert(b.unit == "raid7" and b.name:GetText() == "Joueur-raid7")
  OFFLINE = true                                             -- deconnexion : la case reste, avec « Déco »
  FireEvent("UNIT_CONNECTION", "raid7")
  assert(b.text:GetText() == "Déco", b.text:GetText())
  OFFLINE = false
  FireEvent("UNIT_CONNECTION", "raid7")                      -- reconnexion
  assert(b.text:GetText() == "-200", b.text:GetText())
  COMBAT = true                                              -- depart en plein combat : aucune erreur, rien de bloque
  b:SetAttribute("unit", nil) b:Hide() FireEvent("GROUP_ROSTER_UPDATE") RunUpdates() TICK()
  b:SetAttribute("unit", "party1") b:Show() FireEvent("GROUP_ROSTER_UPDATE") RunUpdates()
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
  assert(Z.buttons[1]:GetAttribute("spell1") ~= nil and Z.db.width == 86, "reglages conserves")
end)

step("bouton de la mini-carte", function()
  local b = LyoruneMinimapButton
  assert(b and b:IsShown(), "bouton absent alors que le reglage est actif")
  assert(Z.private.minimapAngle and Z.db.minimapAngle == 215)
  local w = Z:OptionsWindow() w:Hide()
  b:Run("OnClick", "LeftButton") assert(w:IsShown(), "le clic gauche ouvre les options")
  b:Run("OnClick", "LeftButton") assert(not w:IsShown())
  b:Run("OnClick", "RightButton") assert(Z.previewActive, "le clic droit lance le mode test")
  b:Run("OnClick", "RightButton") assert(not Z.previewActive)
  b:Run("OnEnter") b:Run("OnLeave")
  CURSOR_X, CURSOR_Y = 400, 500                              -- souris au-dessus de la mini-carte
  b:Run("OnDragStart") b:Run("OnUpdate") b:Run("OnDragStop")
  assert(Z.db.minimapAngle == 90 and b:GetScript("OnUpdate") == nil, "angle = " .. tostring(Z.db.minimapAngle))
  CURSOR_X, CURSOR_Y = nil, nil
  Z.db.minimapButton = false Z:Refresh() assert(not b:IsShown(), "bouton encore visible")
  Z.db.minimapButton = true Z:Refresh() assert(b:IsShown())
  Z:ResetAll() assert(Z.db.minimapAngle == 90, "la place du bouton survit a la reinitialisation")
  Z.db.minimapAngle = 215
end)

step("inscription runique", function()
  local strip = Z:RuneStrip()
  assert(strip and #strip.base == 47 and #strip.glows == 47 and #strip.halos == 47, "runes : " .. tostring(strip and #strip.base))
  assert(strip:GetParent() == Z:OptionsWindow())
  strip:Run("OnShow") strip:Run("OnEnter") strip:Run("OnLeave") strip:Run("OnHide")
  Z.db.showRunes = false Z:Refresh() assert(not strip:IsShown(), "runes encore visibles")
  Z.db.showRunes = true Z:Refresh() assert(strip:IsShown())
  for _, key in ipairs({ "Inscription runique", "« Quiconque s'emparera de cette lame détiendra un pouvoir éternel. »",
    "Runes du socle de Deuillegivre, déchiffrées par Muradin (Warcraft III).", "Clic gauche : ouvrir les options",
    "Clic droit : mode test", "Glisser : déplacer ce bouton" }) do
    assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
  end
end)

step("anglais", function()
  Z.db.language = "enUS" Z:SetLanguage()
  assert(Z.L["Mort"] == "Dead" and Z.L["texte inconnu"] == "texte inconnu")
  DEAD = true FireEvent("UNIT_HEALTH", "player") assert(Z.buttons[1].text:GetText() == "Dead")
  DEAD = false FireEvent("UNIT_HEALTH", "player")
  Z.db.language = "AUTO" Z:SetLanguage() assert(Z.L["Mort"] == "Mort")
end)

step("anglais : visite guidee, nouveautes, messages", function()
  Z.db.language = "enUS" Z:SetLanguage()
  Z.db.tutorialDone = false Z:StartTutorial()
  local card = LyoruneTutorial
  local titles = { "Welcome to Lyorune", "One cell per player", "Heal with one click", "What the colours say",
    "Placing the frames", "Trying without a group", "The options window", "One page per chapter", "The preview cell",
    "Search and Home", "Off you go" }
  for i = 1, #titles do
    assert(card.title:GetText() == titles[i], "titre " .. i .. " : " .. card.title:GetText())
    local body = card.body:GetText()
    assert(i == 3 or not body:find("[\195][\160-\191]"), "etape " .. i .. " encore en francais : " .. body:sub(1, 60))
    assert(card.next.label:GetText() == (i == #titles and "Finish" or "Next"), card.next.label:GetText())
    card.next:Run("OnClick")
  end
  assert(Z.db.tutorialDone)
  local news = Z:NewsText()
  assert(news:find("Minimap button", 1, true) and news:find("New", 1, true), "nouveautes non traduites")
  assert(Z.L["Néon"] == "Neon" and Z.L["un allié"] == "an ally")
  assert(Z:ReportURL():find("bug_en.yml", 1, true), Z:ReportURL())
  SlashCmdList.LYORUNE("diag")
  assert(PRINTED[#PRINTED]:find("error(s) in the log", 1, true), PRINTED[#PRINTED])
  assert(Z.englishTexts.manaText:find("{mana}", 1, true) and Z.englishTexts.resText:find("{nom}", 1, true))
  Z.db.language = "AUTO" Z:SetLanguage()
  assert(Z:ReportURL():find("bug.yml", 1, true) and Z.L["Suivant"] == "Suivant")
end)

step("etape 2 : cadres par groupe, etiquettes, verrou, position par personnage, mana", function()
  -- seul ou en groupe : un seul cadre ; en raid : un cadre par groupe, choisi par le jeu lui-meme
  local raid1, raid3 = LyoruneRaid1, LyoruneRaid3
  assert(Z.header:IsShown() and not raid1:IsShown(), "hors raid : le cadre unique")
  RAID = true Z:Refresh()
  assert(not Z.header:IsShown() and raid1:IsShown() and raid3:IsShown(), "en raid : un cadre par groupe")
  assert(raid3:GetAttribute("groupFilter") == "3" and raid3:GetAttribute("roleFilter") == nil and raid3:GetAttribute("maxColumns") == 1)
  assert(raid3.handle.text:GetText() == Z.L["Groupe %d"]:format(3), raid3.handle.text:GetText())
  -- etiquette : seulement sur un groupe qui a des joueurs
  assert(not raid3.handle:IsShown(), "etiquette sur un groupe vide")
  local b = CreateFrame("Button", "LyoruneRaid3UnitButton1", raid3)
  b:Hide() raid3:InitButton(b:GetName()) raid3:SetAttribute("child1", b) b:SetAttribute("unit", "raid11") b:Show()
  assert(raid3.handle:IsShown(), "etiquette absente sur un groupe occupe")
  -- rangement par role : un cadre par role, dans l'ordre choisi
  Z.db.layout = "ROLE" Z.db.roleOrder = "HEALER,TANK,DAMAGER" Z:Refresh()
  assert(raid1:GetAttribute("roleFilter") == "HEALER" and raid1:GetAttribute("groupFilter") == nil and raid1.handle.text:GetText() == Z.L["Soigneurs"])
  assert(LyoruneRaid4:GetAttribute("roleFilter") == "NONE" and LyoruneRaid4:IsShown() and not LyoruneRaid5:IsShown())
  Z.db.layout = "GROUP" Z.db.roleOrder = "TANK,HEALER,DAMAGER" Z:Refresh()
  assert(LyoruneRaid5:IsShown() and LyoruneRaid5:GetAttribute("groupFilter") == "5")
  -- verrou : libre, verrouille, ou avec une touche
  local moved = 0
  Z.anchor.StartMoving = function(self) self.started = true end
  Z.anchor.StopMovingOrSizing = function() moved = moved + 1 end
  Z.db.lockMode = "LOCKED" Z:Refresh()
  raid3.handle:Run("OnDragStart") raid3.handle:Run("OnDragStop")
  assert(moved == 0, "deplace alors que verrouille")
  Z.db.showGroupLabels = false Z:Refresh()
  assert(not raid3.handle:IsShown(), "etiquette masquee par le reglage")
  Z.db.lockMode = "CTRL" Z:Refresh()
  raid3.handle:Run("OnDragStart") raid3.handle:Run("OnDragStop") assert(moved == 0, "deplace sans la touche")
  CTRL = true FireEvent("MODIFIER_STATE_CHANGED")
  assert(raid3.handle:IsShown(), "l'etiquette revient quand on maintient la touche")
  raid3.handle:Run("OnDragStart") raid3.handle:Run("OnDragStop") assert(moved == 1, "Ctrl + glisser")
  CTRL = false FireEvent("MODIFIER_STATE_CHANGED")
  assert(not raid3.handle:IsShown())
  Z.db.showGroupLabels = true Z.db.lockMode = "FREE" Z:Refresh()
  -- la position est rangee dans la sauvegarde du personnage
  assert(LyoruneCharDB.pos == Z.char.pos and Z.char.pos[1] == "CENTER" and LyoruneDB.pos == nil)
  SlashCmdList.LYORUNE("verrou") assert(Z.db.lockMode == "LOCKED")
  SlashCmdList.LYORUNE("verrou") assert(Z.db.lockMode == "FREE")
  SlashCmdList.LYORUNE("reset") assert(Z.char.pos[2] == -320)
  RAID = false FireEvent("PLAYER_REGEN_ENABLED")
  assert(Z.header:IsShown() and not raid1:IsShown(), "retour au groupe")
  -- mana : pour tous par defaut, hauteur reglable
  assert(Z.defaults.manaBars == "ALL" and Z.limits.powerHeight)
  Z.db.powerHeight = 7 Z:Refresh() assert(Z.buttons[1].power:GetHeight() == 7)
  -- Couleur de la barre de mana : bleue par défaut (posée après la texture, sinon le jeu la laisse blanche), au choix
  local bar = Z.buttons[1].power
  assert(Z.db.manaColor == "BLUE" and bar._barColor[3] == Z.manaColors.BLUE[3] and bar._barColor[1] < 0.5, "mana blanche")
  for _, choice in ipairs(Z.choices.manaColor) do assert(Z.manaColors[choice[1]], "teinte manquante : " .. choice[1]) end
  Z.db.manaColor = "PURPLE" Z:Refresh() assert(bar._barColor[1] == Z.manaColors.PURPLE[1], "mana violette")
  Z.db.manaColor = "BLUE" Z:Refresh()
  -- barre de mana haute, jusqu'a 60 pixels ; la vie garde toujours 10 pixels de la case
  assert(Z.limits.powerHeight[2] == 60, "hauteur de mana limitee a " .. Z.limits.powerHeight[2])
  local height = Z.db.height
  Z.db.powerHeight, Z.db.height = 30, 60 Z:Refresh() assert(Z.buttons[1].power:GetHeight() == 30, "mana de 30 pixels")
  Z.db.powerHeight, Z.db.height = 60, 40 Z:Refresh() assert(Z.buttons[1].power:GetHeight() == 30, "la vie doit garder 10 pixels")
  Z.db.height = height
  Z.db.powerHeight = 4 Z:Refresh()
  -- dissipation : le voile est pose sous le texte, plus dans le cadre de la bordure
  local cell = Z.buttons[1]
  Z.ShowDispel(cell, true, 0.2, 0.6, 1, 1)
  assert(cell.dispel:IsShown() and cell.dispel.fill:IsShown() and cell.dispel.fill:GetParent() == cell.over)
  -- le voile reste leger : la couleur donnee a la texture remplace son opacite (bug des cases toutes vertes)
  assert(cell.dispel.fill:GetAlpha() < 0.5, "voile de dissipation opaque : la vie est cachee")
  Z.ShowDispel(cell, true, 0.2, 0.6, 1, MakeSecret()) assert(cell.dispel.fill:GetAlpha() < 0.5, "opacite secrete")
  assert(Z.DispelCurve(true) ~= Z.DispelCurve(), "le voile des conteneurs doit avoir sa courbe transparente")
  Z.ShowDispel(cell, false) assert(not cell.dispel.fill:IsShown())
  -- mode test : barre d'absorption de soins vide (sinon toute la case est teintee de rouge), bouton Fermer
  Z:TogglePreview(10)
  local fake = Z:PreviewCells(10)[1]
  assert(fake.healAbsorb._value == 0 and fake.healAbsorb._max == 100, "absorption de soins du mode test sans bornes")
  assert(LyorunePreview.close, "bouton Fermer du mode test absent")
  -- le bandeau du mode test se fait glisser et deplace les vrais cadres (meme position enregistree)
  local lockMode = Z.db.lockMode
  Z.db.lockMode = "FREE" Z.char.pos = nil
  LyorunePreview.banner:Run("OnDragStart") LyorunePreview.banner:Run("OnDragStop")
  assert(Z.char.pos and Z.char.pos[1] == "CENTER", "bandeau du mode test non deplacable")
  Z.db.lockMode = lockMode
  LyorunePreview.close:Run("OnClick", "LeftButton")
  assert(not Z.previewActive and not LyorunePreview:IsShown(), "le bouton Fermer doit quitter le mode test")
  -- mini-carte : meme gabarit que les autres boutons
  assert(LyoruneMinimapButton:GetWidth() == 31 and LyoruneMinimapButton.icon:GetWidth() == 18)
end)

step("etape 3 : auras privees, absorption de soins, invocation, phase, infobulle, lueur", function()
  local b = Z.buttons[1]
  local function anchors() local n = 0 for _ in pairs(PRIVATE) do n = n + 1 end return n end
  -- #9 auras privees : deux ancres par case, pour son joueur, refaites quand un reglage change
  assert(b.privateAnchors and #b.privateAnchors == 2, "ancres d'auras privees")
  assert(PRIVATE[b.privateAnchors[1]].unitToken == "player" and PRIVATE[b.privateAnchors[2]].auraIndex == 2)
  local before = anchors()
  Z.db.privateAuraSize = 30 Z.db.privateAuraPoint = "TOP" Z:Refresh()
  assert(anchors() == before, "les anciennes ancres sont retirees")
  assert(PRIVATE[b.privateAnchors[1]].iconInfo.iconWidth == 30)
  b:SetAttribute("unit", "party3")
  assert(PRIVATE[b.privateAnchors[1]].unitToken == "party3", "les ancres suivent le joueur de la case")
  b:SetAttribute("unit", "player")
  Z.db.privateAuras = false Z:Refresh()
  assert(b.privateAnchors == nil and anchors() == 0 and not b.privateHolder:IsShown(), "interrupteur des auras privees")
  Z.db.privateAuras = true Z.db.privateAuraSize = 20 Z.db.privateAuraPoint = "CENTER" Z:Refresh()
  -- #10 absorption de soins : barre au bout de la vie, valeur calculee par le jeu
  local value FireEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player")
  b.healAbsorb.SetValue = function(_, v) value = v end
  FireEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player")
  assert(value == 4 and b.healAbsorb:IsShown(), "absorption de soins")
  Z.db.showHealAbsorb = false Z:Refresh() assert(not b.healAbsorb:IsShown())
  Z.db.showHealAbsorb = true Z:Refresh()
  -- #11 invocation et autre phase : icone centrale
  local atlas, texture
  b.center.SetAtlas = function(_, a) atlas = a end
  b.center.SetTexture = function(_, t) texture = t end
  b.readyCheck = false
  SUMMON = 1 FireEvent("INCOMING_SUMMON_CHANGED", "player")
  assert(atlas == "Raid-Icon-SummonPending" and b.center:IsShown(), "invocation proposee")
  SUMMON = 0 PHASE = 2 FireEvent("UNIT_PHASE", "player")
  assert(texture and texture:find("PhasingIcon"), "autre phase")
  Z.db.showSummonPhase = false Z:Refresh() assert(not b.center:IsShown(), "interrupteur invocation et phase")
  Z.db.showSummonPhase = true PHASE = nil Z:Refresh()
  b.center.SetAtlas, b.center.SetTexture = nil, nil
  -- #12 infobulle des clics, hors combat seulement
  local lines = {}
  GameTooltip.AddDoubleLine = function(_, left, right) lines[#lines + 1] = left .. "=" .. right end
  b:Run("OnEnter") b:Run("OnLeave")
  local text = table.concat(lines, ";")
  assert(text:find("Clic gauche=Soins rapides", 1, true) and text:find("Maj + Clic gauche=Soins supérieurs", 1, true), text)
  lines = {} COMBAT = true b:Run("OnEnter") b:Run("OnLeave") COMBAT = false
  assert(#lines == 0, "pas d'infobulle en combat")
  Z.db.clickTooltip = false b:Run("OnEnter") b:Run("OnLeave") assert(#lines == 0, "interrupteur de l'infobulle des clics")
  Z.db.clickTooltip = true GameTooltip.AddDoubleLine = nil
  -- #13 contour lumineux et son : par nom (ma liste), et contour decide par le jeu en combat
  local sounds = 0
  local playSound = PlaySound
  PlaySound = function() sounds = sounds + 1 end
  Z.db.importantSound = true NOW = (NOW or 0) + 10
  Z.db.importantNames["Brulure"] = true
  AURAS["HARMFUL"] = { { name = "Brulure", icon = 7, auraInstanceID = 41, spellId = 77 } }
  FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(b.glow and b.glow:IsShown() and sounds == 1, "contour et son pour un affaiblissement de ma liste")
  NOW = NOW + 10 FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(sounds == 1, "un seul son tant que l'affaiblissement reste pose")
  Z.db.importantGlow = false Z:Refresh() RunUpdates() assert(not b.glow:IsShown(), "interrupteur du contour")
  Z.db.importantGlow = true
  SECRET = true COMBAT = true
  AURAS["HARMFUL"] = { { name = MakeSecret(), icon = 7, auraInstanceID = 42, spellId = MakeSecret(), isBossAura = MakeSecret() } }
  NOW = NOW + 10 FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(b.glow:IsShown() and sounds == 1, "en combat : contour decide par le jeu, pas de son")
  SECRET = false COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  AURAS = {} FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(not b.glow:IsShown(), "contour retire")
  Z.db.importantNames = {} Z.db.importantSound = false PlaySound = playSound
end)

step("etape 4 : forme des cases, angles, fond par groupe, couleurs de classe", function()
  local b = Z.buttons[1]
  local saved = {} for _, k in ipairs({ "shape", "width", "height", "fontSize", "powerHeight" }) do saved[k] = Z.db[k] end
  -- #14 formes : chacune regle les valeurs existantes, dans leurs limites ; Revenir retablit l'etat d'avant
  assert(Z.defaults.shape == "TILE" and Z.shapes.TILE.width == Z.defaults.width and Z.shapes.TILE.height == Z.defaults.height)
  for _, choice in ipairs(Z.choices.shape) do
    local shape = assert(Z.shapes[choice[1]], "forme sans reglages : " .. choice[1])
    for _, key in ipairs(Z.shapeKeys) do
      local limit = Z.limits[key]
      assert(shape[key] >= limit[1] and shape[key] <= limit[2], "forme " .. choice[1] .. " hors limites : " .. key)
    end
  end
  Z:ApplyShape("BANNER")
  assert(Z.db.shape == "BANNER" and Z.db.width == 170 and Z.db.height == 24 and Z.header:GetAttribute("z-height") == 24)
  assert(b.iconSize >= 10, "icones lisibles sur une case basse")
  Z:ApplyShape("SQUARE") Z:UndoShape()
  assert(Z.db.shape == "BANNER" and Z.db.width == 170, "Revenir retablit la forme d'avant")
  Z:UndoShape() assert(Z.db.shape == "BANNER", "rien a retablir")
  -- vignettes dans l'onglet Apparence, dessinees avec les reglages du moment
  Z:ToggleOptions("Apparence")
  local picker = assert(Z.shapePicker, "vignettes des formes")
  assert(#picker.thumbs == 4 and picker.thumbs[4].chosen and not picker.thumbs[2].chosen)
  picker.thumbs[2]:Run("OnClick")
  assert(Z.db.shape == "TILE" and Z.db.width == 86 and picker.thumbs[2].chosen)
  picker.undo:Run("OnClick") assert(Z.db.shape == "BANNER")
  picker.real:Run("OnClick") assert(Z.previewActive, "Voir en vrai lance le mode test")
  picker.real:Run("OnClick") assert(not Z.previewActive)
  Z:ToggleOptions()
  for k, v in pairs(saved) do Z.db[k] = v end
  -- #15 angles arrondis : fond et bordures arrondis, barres en retrait
  Z.db.corners = "ROUND" Z:Refresh()
  assert(b.bgRound:IsShown() and not b.bg:IsShown() and b.border.rounded and b.threat.rounded and b.selected.rounded)
  assert(b.border.round:IsShown() and not b.border[1]:IsShown())
  Z.db.corners = "SHARP" Z:Refresh()
  assert(b.bg:IsShown() and not b.bgRound:IsShown() and not b.border.rounded and b.border[1]:IsShown())
  -- fond et bordure par groupe : seulement sur un groupe occupe
  Z.db.groupPanel = true Z:Refresh()
  assert(LyoruneRaid3.panel:IsShown(), "fond du groupe")
  assert(not LyoruneRaid6.panel:IsShown(), "pas de fond sur un groupe vide")
  Z:TogglePreview(10) assert(LyorunePreview.panels[1]:IsShown() and LyorunePreview.panels[2]:IsShown()) Z:TogglePreview()
  Z.db.groupPanel = false Z:Refresh() assert(not LyoruneRaid3.panel:IsShown())
  -- #32 couleurs de classe : vives plus saturees que celles du jeu, meme teinte
  local nr, ng, nb Z.db.classIntensity = "NATURAL" nr, ng, nb = Z.ClassColor("DRUID")
  Z.db.classIntensity = "VIVID" local vr, vg, vb = Z.ClassColor("DRUID")
  assert(vr - vb > nr - nb and vr >= vg and vg >= vb, "couleur vive")
  for _, v in ipairs({ vr, vg, vb }) do assert(v >= 0 and v <= 1) end
  assert(select(1, Z.ClassColor(nil)) == 0.6, "classe inconnue")
end)

step("etape 4 bis : themes des fenetres, animations, runes, tutoriel", function()
  local UI = Z.UI
  -- Contraste (WCAG) : texte 4,5:1 sur le fond et sur les boutons, texte secondaire et accent 3:1
  local function lum(c)
    local function ch(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * ch(c[1]) + 0.7152 * ch(c[2]) + 0.0722 * ch(c[3])
  end
  local function ratio(a, b) local x, y = lum(a), lum(b) if x < y then x, y = y, x end return (x + 0.05) / (y + 0.05) end
  for name, skin in pairs(UI.skins) do
    for _, role in ipairs(UI.ROLES) do assert(skin[role] and #skin[role] == 3, name .. " sans " .. role) end
    assert(ratio(skin.text, skin.bg) >= 4.5 and ratio(skin.text, skin.panel) >= 4.5, name .. " : texte peu lisible")
    assert(ratio(skin.dim, skin.bg) >= 3 and ratio(skin.accent, skin.bg) >= 3, name .. " : texte secondaire peu lisible")
    assert(ratio(skin.btext, skin.panel) >= 4.5, name .. " : texte des boutons peu lisible")
    assert(skin.kit and skin.headFont and skin.headSize and skin.runeBase and skin.runeGlow, name .. " incomplet")
    assert(skin.headFont == "STANDARD" or skin.headFont:match("^Fonts\\[%u_]+%.TTF$"), name .. " : chemin de police abime : " .. skin.headFont)
  end
  for key, path in pairs(UI.GAME) do assert(path:match("^Interface\\%a+\\[%w%-]+$"), "texture du jeu abimee : " .. key) end
  assert(Z.db.windowTheme == "MODERN" and Z.db.reduceMotion == false)

  -- Changement de thème en direct, fenêtre ouverte : tout est repeint, rien n'est créé en double
  Z:ToggleOptions("Apparence")
  local w = Z:OptionsWindow()
  local count = #UI.Windows()
  local handle = Z.header.handle
  local titleFont, titleSize = w.title._font, w.title._size
  local sample = UI.Check(w, "essai", function() return true end, function() end)
  local button = w.close
  for _, theme in ipairs({ "CLASSIC", "MMO", "MODERN" }) do
    Z.db.windowTheme = theme Z:Refresh()
    local skin = UI.skins[theme]
    assert(UI.skinName == theme and UI.accent[1] == skin.accent[1], theme)
    assert(w.title._color[1] == skin.accent[1] and w.bg._color[1] == skin.bg[1], theme .. " : fenêtre non repeinte")
    -- Un thème complet : cadre, boutons et cases changent vraiment, pas seulement leurs couleurs
    assert(w.round:IsShown() == (theme == "MODERN") and w.shade:IsShown() == (theme == "MMO"), theme .. " : cadre")
    assert(w._backdrop == (theme ~= "MODERN" and w._backdrop or nil), theme .. " : cadre du jeu")
    assert((w._backdrop and w._backdrop.edgeFile) == (theme == "CLASSIC" and UI.GAME.dialogEdge or theme == "MMO" and UI.GAME.goldEdge or nil), theme .. " : bordure")
    local layers = button.layers or {}
    assert(button.bg:IsShown() == (theme == "MODERN"), theme .. " : bouton plat")
    assert((layers.gameUp and layers.gameUp:IsShown() or false) == (theme == "CLASSIC"), theme .. " : bouton du jeu")
    assert((layers.plate and layers.plate:IsShown() or false) == (theme == "MMO"), theme .. " : plaque doree")
    local side = Z:OptionsTabs()[3].button -- Apparence, le chapitre ouvert
    assert(side.active and side.border:IsShown() and side.round:IsShown() == (theme == "MODERN"), theme .. " : chapitre ouvert")
    assert(side.label._color[1] == (theme == "MODERN" and UI.text or UI.gold)[1], theme .. " : nom du chapitre ouvert")
    assert(not Z:OptionsTabs()[2].button.border:IsShown(), theme .. " : chapitre ferme")
    local field = w.search.layers and w.search.layers[theme]
    assert(theme == "MODERN" or (field and field:IsShown() and field._tex == UI.SKIN[theme].field), theme .. " : champ creuse")
    assert(sample.mark._tex == (theme == "CLASSIC" and UI.GAME.check or theme == "MMO" and UI.RUNES or UI.WHITE), theme .. " : case a cocher")
    assert(w.title._font == titleFont and w.title._size == titleSize, theme .. " : l'en-tete change de taille")
    assert(handle.text._color[1] == UI.frameAccent[1], "les etiquettes des cadres de soin ont suivi le theme")
  end
  assert(w.ornate and not w.ornate:IsShown(), "ornements du theme MMORPG restes visibles")
  -- Tout ce qui est noté est repeint (sauf l'onglet actif, recoloré exprès : fond et libellé)
  local painted, order = UI.Painted()
  local wrong = 0
  for _, obj in ipairs(order) do
    local e, c = painted[obj], obj._color
    if c and math.abs(c[1] - UI[e[1]][1] * (e[3] or 1)) > 0.001 then wrong = wrong + 1 end
  end
  assert(#order > 500 and wrong <= 2, "elements non repeints : " .. wrong)
  assert(getmetatable(painted) == nil, "la liste des elements peints ne doit pas etre faible")
  assert(#UI.Windows() == count, "fenetre en double")
  w:Hide() w:Show()
  Z.db.highContrast = true Z:Refresh()
  assert(UI.bg[1] == UI.CONTRAST.bg[1] and UI.text[1] == UI.CONTRAST.text[1] and w.bg:IsShown(), "contraste eleve")
  Z.db.highContrast = false Z:Refresh()
  assert(UI.Hex("accent") == "73c7ff", UI.Hex("accent"))

  -- Réglage changé : une rune s'allume à côté
  local c = UI.Check(UIParent, "essai", function() return false end, function() end)
  c:Run("OnClick")
  assert(c.confirm and c.confirm:IsPlaying())
  -- Bordure des cases : chaque trait garde au moins un vrai pixel (bord droit qui disparaissait en jeu)
  for i = 1, 4 do assert(c.border[i]._pixels == 1, "trait " .. i .. " de la case arrondi a zero") end

  -- Effets magiques : étincelle avec la rune, animation du logo et particules de l'en-tête, au plus 3 éclairs par seconde
  assert(Z.db.magicEffects == true and UI.Magic())
  NOW = NOW + 5 c:Run("OnClick")
  assert(c.spark and c.sparkRise:IsPlaying() and c.spark._tex == UI.MAGIC_SPARK, "etincelle de soin")
  assert(c.spark._color[1] == UI.skin.runeGlow[1], "etincelle : couleur du theme")
  local m = w.magic
  -- Animation du logo : Aurore au départ, construite à son premier affichage ; une couleur par classe de soin
  local logo = m.logo
  local function Playing(key)
    local st = logo.styles[key]
    return st and st.groups[1]:IsPlaying() and st.groups[#st.groups]:IsPlaying() and st.regions[1]:IsShown()
  end
  local function Quiet(key)
    local st = logo.styles[key]
    if not st then return true end
    for _, g in ipairs(st.groups) do if g:IsPlaying() then return false end end
    return not st.regions[1]:IsShown()
  end
  assert(Z.db.logoAnimation == "AURORA" and Playing("AURORA") and m.rises[1]:IsPlaying(), "aurore et particules")
  assert(not logo.styles.SEAL and not logo.styles.BREATH, "seule l'animation choisie est construite")
  local healers = 0
  for _ in pairs(Z.trackedSpells) do healers = healers + 1 end
  local aurora = logo.styles.AURORA
  -- par classe : une lueur et une etincelle ; plus le reflet
  assert(#aurora.groups == 2 * healers + 1 and #aurora.regions == 2 * healers + 1, "aurore : une lueur et une etincelle par classe de soin")
  assert(aurora.regions[1]._color[1] == 1 and aurora.regions[1]._color[2] == 0.49, "aurore : druide en premier, couleur de classe")
  -- Sceau et Souffle : l'un remplace l'autre, rien ne reste allumé derrière
  for _, key in ipairs({ "SEAL", "BREATH", "AURORA" }) do
    Z.db.logoAnimation = key Z:Refresh()
    assert(Playing(key), key .. " lance")
    for other in pairs(logo.styles) do
      if other ~= key then assert(Quiet(other), other .. " arrete quand " .. key .. " est choisi") end
    end
  end
  -- halo, gemmes (lueur, pierre, serti), anneau, et 9 points de traînée par classe ; aucune rotation (trop rapide en jeu)
  assert(#logo.styles.SEAL.regions == 4 * healers + 1 + 9 * healers, "sceau : halo, gemme et trainee par classe")
  assert(#logo.styles.BREATH.regions == 2 * healers and #logo.styles.BREATH.groups == 2 * healers, "souffle : une lueur et une onde par classe")
  Z.db.logoAnimation = "OFF" Z:Refresh()
  for key in pairs(logo.styles) do assert(Quiet(key), "aucune animation : " .. key) end
  assert(m.rises[1]:IsPlaying(), "particules gardees sans animation du logo")
  Z.db.logoAnimation = "AURORA" Z:Refresh()
  Z.db.windowTheme = "MMO" Z:Refresh()
  assert(m.motes[1]._color[2] == UI.skins.MMO.runeGlow[2], "particules : couleur du theme")
  Z.db.windowTheme = "MODERN" Z:Refresh()
  NOW = NOW + 5
  local allowed = 0
  for _ = 1, 5 do if UI.Flash() then allowed = allowed + 1 end end
  assert(allowed == 3, "plus de 3 eclairs par seconde")
  NOW = NOW + 1
  assert(UI.Flash(), "eclair refuse une seconde plus tard")
  for _, setting in ipairs({ "reduceMotion", "magicEffects" }) do
    Z.db[setting] = setting == "reduceMotion" Z:Refresh()
    assert(not UI.Magic() and Quiet("AURORA") and not m.rises[1]:IsPlaying(), setting)
    c.sparkRise:Stop() c:Run("OnClick")
    assert(not c.sparkRise:IsPlaying(), setting .. " : etincelle")
    Z.db.reduceMotion, Z.db.magicEffects = false, true Z:Refresh()
  end
  assert(Playing("AURORA"), "effets revenus")
  w:Hide() m.Stop() w:Show()
  assert(Playing("AURORA"), "effets a la reouverture")

  -- Runes : même phrase, animations jouées à l'ouverture, arrêtées à la fermeture, aucune en animations réduites
  local spelled = 0
  for _, rune in ipairs(Z:SpellRunes()) do if rune then spelled = spelled + 1 end end
  assert(spelled == 47)
  local strip = Z:RuneStrip()
  strip:Run("OnShow")
  assert(strip.writes[1]:IsPlaying() and strip.waves[1]:IsPlaying() and strip.breath:IsPlaying())
  strip:Run("OnHide")
  assert(not strip.waves[1]:IsPlaying() and not strip.breath:IsPlaying())
  Z.db.reduceMotion = true Z:Refresh()
  strip:Run("OnShow")
  assert(not strip.writes[1]:IsPlaying() and not strip.waves[1]:IsPlaying() and not strip.breath:IsPlaying(), "runes animees")
  assert(not w.breath:IsPlaying(), "logo anime")
  strip:Run("OnEnter") strip:Run("OnLeave")
  assert(not strip.waves[1]:IsPlaying())
  Z.db.reduceMotion = false Z:Refresh()

  -- Fenêtres secondaires : à côté des options au lieu de les recouvrir
  w.GetLeft = function() return 300 end w.GetRight = function() return 1000 end w.GetTop = function() return 900 end
  UIParent.GetWidth = function() return 1920 end UIParent.GetHeight = function() return 1080 end
  if LyoruneBug then LyoruneBug:Hide() end
  Z:ShowBug()
  local p = LyoruneBug._point
  assert(LyoruneBug.beside and p[1] == "TOPLEFT" and p[2] == w and p[3] == "TOPRIGHT", "rapport de bug par-dessus les options")
  UIParent.GetWidth = function() return 1300 end
  LyoruneBug:Hide() Z:ShowBug()
  p = LyoruneBug._point
  assert(p[2] == UIParent, "pas la place : contre le bord le plus degage")
  w.GetLeft, w.GetRight, w.GetTop, UIParent.GetWidth, UIParent.GetHeight = nil, nil, nil, nil, nil
  LyoruneBug:Hide()

  -- Tutoriel : une rune par étape, l'étape en cours respire, la carte glisse
  Z:StartTutorial()
  local card = LyoruneTutorial
  assert(#card.runes == 11 and card.runes[1].breath:IsPlaying())
  card.next:Run("OnClick")
  assert(card.slide:IsPlaying() and card.runes[2].breath:IsPlaying() and not card.runes[1].breath:IsPlaying())
  assert(card.runes[1]._color[1] == UI.gold[1], "etape vue eteinte")
  for _ = 1, 3 do card.next:Run("OnClick") end
  local body = card.body:GetText()
  assert(body:find("|cff33dd88Groupe", 1, true) and not body:find("|cff33dd88/", 1, true), "couleurs du tutoriel")
  card.close:Run("OnClick")
  local labels = table.concat(Z:OptionLabels(), "|")
  assert(labels:find("Thème des fenêtres", 1, true) and labels:find("Animations réduites", 1, true) and labels:find("Effets magiques", 1, true))
end)

step("etape 5 : soins sur la duree, coins, mana en %, menace", function()
  local b = Z.buttons[1]
  -- % de mana : ecrit par le jeu, barre de 8 pixels au moins, meme avec une hauteur reglee a 4
  Z.db.manaBars, Z.db.powerHeight, Z.db.manaPercent = "ALL", 4, true Z:Refresh()
  FireEvent("UNIT_POWER_UPDATE", "player")
  assert(Z.PowerHeight() == 8 and b.power:GetHeight() == 8, "barre agrandie pour le %")
  assert(b.powerText:IsShown() and b.powerText:GetText() == "60%", "pourcentage de mana : " .. tostring(b.powerText:GetText()))
  SECRET = true FireEvent("UNIT_POWER_UPDATE", "player") SECRET = false
  Z.db.manaPercent = false Z:Refresh() FireEvent("UNIT_POWER_UPDATE", "player")
  assert(Z.PowerHeight() == 4 and not b.powerText:IsShown(), "barre simple")
  -- barre fine de menace : couleur selon le niveau, cachee si le niveau est secret ou le reglage coupe
  Z.db.threatBar = true Z:Refresh() FireEvent("UNIT_THREAT_SITUATION_UPDATE", "player")
  assert(b.threatBar:IsShown(), "barre de menace")
  SECRET = true FireEvent("UNIT_THREAT_SITUATION_UPDATE", "player") SECRET = false
  assert(not b.threatBar:IsShown(), "menace secrete : rien d'invente")
  Z.db.threatBar = false Z:Refresh() FireEvent("UNIT_THREAT_SITUATION_UPDATE", "player")
  assert(not b.threatBar:IsShown())
  -- #16 icones de mes soins : cercle, decompte, fondu, charges, combinables
  AURAS["HELPFUL|PLAYER"] = { { name = "Rénovation", icon = 1, auraInstanceID = 41, spellId = 139 } }
  Z.db.hotSwipe, Z.db.hotCountdown, Z.db.hotFade, Z.db.hotCharges = false, true, true, false
  Z:Refresh() FireEvent("UNIT_AURA", "player") RunUpdates()
  local icon = b.hots[1]
  assert(icon:IsShown() and icon.duration, "icone de soin")
  assert(icon.count:GetText() == "", "charges coupees")
  TICK() -- le fondu passe avec le controle de portee, sans boucle a lui
  Z.db.hotSwipe, Z.db.hotCountdown, Z.db.hotFade, Z.db.hotCharges = true, false, false, true
  Z:Refresh() RunUpdates()
  -- #17 coins : un sort par coin et par classe ; il quitte la rangee d'icones
  Z.db.cornerSpells.PRIEST = { TOPLEFT = "Rénovation" }
  Z:Refresh() RunUpdates()
  assert(b.corners and b.corners.TOPLEFT:IsShown(), "carre du coin")
  assert(not b.hots[1]:IsShown(), "le sort du coin quitte la rangee")
  assert(Z.CornerShift(b, "TOPLEFT") > 0 and Z.CornerShift(b, "BOTTOMRIGHT") == 0)
  -- en combat : nom secret, mais numero d'aura retenu hors combat
  SECRET = true
  AURAS["HELPFUL|PLAYER"] = { { name = MakeSecret(), icon = 1, auraInstanceID = 41, spellId = MakeSecret() } }
  FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(b.corners.TOPLEFT:IsShown(), "coin reconnu en combat par le numero d'aura")
  -- en combat : soin lance pendant le combat, reconnu par mon sort lisible et l'aura qui apparait aussitot
  AURAS["HELPFUL|PLAYER"] = { { name = MakeSecret(), icon = 1, auraInstanceID = 42, spellId = MakeSecret() } }
  FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 139)
  FireEvent("UNIT_AURA", "player", { addedAuras = { AURAS["HELPFUL|PLAYER"][1] }, removedAuraInstanceIDs = { 41 } }) RunUpdates()
  assert(b.corners.TOPLEFT:IsShown(), "coin reconnu en combat par le sort lance")
  -- soin inconnu en combat : il reste dans la rangee, jamais dans un coin au hasard
  AURAS["HELPFUL|PLAYER"] = { { name = MakeSecret(), icon = 1, auraInstanceID = 43, spellId = MakeSecret() } }
  FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(not b.corners.TOPLEFT:IsShown() and b.hots[1]:IsShown(), "soin inconnu dans la rangee")
  SECRET = false
  Z.db.cornerSpells.PRIEST = nil AURAS = {} Z:Refresh() RunUpdates()
  assert(not b.corners.TOPLEFT:IsShown())
  -- toutes les classes de soigneur de Forever ont des sorts suivis, donc des coins a choisir ; chacune garde les siens
  for _, class in ipairs({ "PRIEST", "DRUID", "PALADIN", "SHAMAN" }) do
    assert(#(Z.trackedSpells[class] or {}) >= 2, "sorts suivis manquants : " .. class)
  end
  Z.db.cornerSpells.DRUID = { TOPLEFT = "Récupération" } Z:Refresh() RunUpdates()
  assert(Z.CornerShift(b, "TOPLEFT") == 0, "les coins du druide ne touchent pas le pretre")
  Z.db.cornerSpells.DRUID = nil
  -- revue 1.23.7 : la liste d'un coin suit l'onglet Listes, et garde le sort choisi même retiré de la liste
  Z.db.extraTracked["Prière de soins"] = true
  local found
  for _, choice in ipairs(Z.CornerChoices("TOPLEFT")) do if choice[1] == "Prière de soins" then found = true end end
  assert(found, "sort de l'onglet Listes absent du choix des coins")
  Z.db.cornerSpells.PRIEST = { TOPLEFT = "Prière de soins" }
  Z.db.extraTracked["Prière de soins"] = nil
  found = false
  for _, choice in ipairs(Z.CornerChoices("TOPLEFT")) do if choice[1] == "Prière de soins" then found = true end end
  assert(found, "le sort du coin doit rester affiché")
  Z.db.cornerSpells.PRIEST = nil
  -- options : les quatre coins et les nouveaux reglages sont trouvables par la recherche
  Z:ToggleOptions("Indicateurs") Z:ToggleOptions()
  local labels = table.concat(Z:OptionLabels(), "|")
  for _, label in ipairs({ "Pourcentage de mana dans la barre", "Barre fine de menace", "Décompte en secondes", "Icône qui s'efface à la fin", "En haut à gauche", "En bas à droite" }) do
    assert(labels:find(label, 1, true), "option absente : " .. label)
  end
end)

step("etape 6 : echelle, editeur de placement", function()
  local b = Z.buttons[1]
  -- #18 echelle generale : tous les cadres et le mode test, dans ses limites
  assert(Z.defaults.scale == 100 and Z.limits.scale[1] == 50 and Z.limits.scale[2] == 200)
  Z.db.scale = 150 Z:Refresh()
  for _, h in ipairs(Z.headers) do assert(h:GetScale() == 1.5, "echelle des cadres") end
  Z:TogglePreview(5)
  assert(LyorunePreview:GetScale() == 1.5, "echelle du mode test")
  Z:TogglePreview()
  -- placement : decalage ajoute a la place d'origine, garde pour chaque forme
  Z.db.shape = "TILE" Z.db.placement = {}
  Z.SetOffset("name", 4, -3) Z:Refresh()
  local p = b.name._point
  local home = Z.AuraRows().homes.name -- place d'origine (C34 : nom au-dessus de la vie, au milieu de la case)
  assert(p[1] == "CENTER" and p[4] == 4 and p[5] == home.y + select(2, Z.Offset("name")) and select(2, Z.Offset("name")) < 0, "nom decale")
  Z.SetOffset("marker", 0, -2) Z:Refresh() -- à cheval sur le haut de la case : il peut seulement descendre
  assert(b.marker._point[5] == -3, "marqueur decale")
  AURAS["HELPFUL|PLAYER"] = { { name = "Rénovation", icon = 1, auraInstanceID = 41, spellId = 139 } }
  Z.db.showHots, Z.db.hotStyle = true, "ICONS"
  Z.SetOffset("hots", 5, 0) Z:Refresh() FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(b.hots[1]:IsShown() and b.hots[1]._point[4] == 7, "icones de soins decalees")
  AURAS = {}
  Z.db.shape = "BAR" Z:Refresh()
  local after = Z.AuraRows().homes.dispelType
  assert(Z.Offset("name") == 0 and b.name._point[4] == Z.AuraRows().homes.name.x and b.name._point[4] >= b.role._w + 5
    and (not Z.db.dispelIcon or b.name._point[4] == after.x + after.w + 2), "une autre forme garde sa place d'origine")
  Z.db.shape = "TILE" Z:Refresh()
  -- bornes, nettoyage, element inconnu refuse
  Z.SetOffset("name", 999, -999)
  local x, y = Z.Offset("name")
  local _, right, bottom = Z.OffsetRange("name")
  assert(x == right and y == bottom and x > 0 and x < 40 and y < 0 and y > -40, "decalage borne au bord de la case")
  Z.SetOffset("name", 0, 0)
  assert(Z.db.placement.TILE.name == nil, "place d'origine : entree effacee")
  Z.SetOffset("inconnu", 1, 1)
  assert(Z.db.placement.TILE.inconnu == nil)
  -- editeur : liste, fleches (Maj : 5 pixels), coordonnees, glisser, remise a zero
  Z:OpenPlacement()
  local w = Z:PlacementWindow()
  assert(w:IsShown() and #w.list == #Z.placeElements and w.beside, "fenetre de placement")
  for _, button in ipairs(w.list) do if button.key == "hots" then button:Run("OnClick") end end
  w.right:Run("OnClick") w.up:Run("OnClick")
  x, y = Z.Offset("hots")
  assert(x == 6 and y == 1, "fleches : " .. x .. "," .. y)
  local shift = IsShiftKeyDown
  IsShiftKeyDown = function() return true end
  w.left:Run("OnClick")
  IsShiftKeyDown = shift
  assert(Z.Offset("hots") == 1, "Maj : 5 pixels")
  assert(w.coords:GetText():find("1, 1", 1, true), "coordonnees affichees")
  local cell = w.cell
  cell.marker.GetLeft = function() return 100 end cell.marker.GetRight = function() return 110 end
  cell.marker.GetTop = function() return 210 end cell.marker.GetBottom = function() return 200 end
  CURSOR_X, CURSOR_Y = 105, 205
  w.stage:Run("OnMouseDown", "LeftButton")
  assert(w.stage:GetScript("OnUpdate"), "glisser commence sur l'element")
  CURSOR_X, CURSOR_Y = 108, 203
  w.stage:Run("OnUpdate", 0.01)
  w.stage:Run("OnMouseUp", "LeftButton")
  assert(not w.stage:GetScript("OnUpdate"), "aucune boucle apres le glissement")
  x, y = Z.Offset("marker")
  assert(x == 3 and y == -4, "marqueur glisse : " .. x .. "," .. y)
  assert(b.marker._point[4] == 3, "les vraies cases suivent")
  CURSOR_X, CURSOR_Y = nil, nil
  w.resetAll:Run("OnClick")
  assert(Z.db.placement.TILE ~= nil, "tout remettre en un seul clic")
  w.resetAll.armed = true -- le faux client lance les minuteries tout de suite : second clic dans les 4 secondes
  w.resetAll:Run("OnClick")
  assert(Z.db.placement.TILE == nil, "tout remettre")
  w:Hide()
  -- options : trouvables par la recherche
  local labels = table.concat(Z:OptionLabels(), "|")
  assert(labels:find("Échelle générale (%)", 1, true) and labels:find("Placer les éléments de la case...", 1, true))
  Z.db.scale = 100 Z:Refresh()
end)

step("etape 7 : clics et touches sur un seul ecran, nouveau sort sans clic", function()
  local b = Z.buttons[1]
  local saved, savedKeys = CopyTable(Z:GetClicks()), CopyTable(Z:GetHoverKeys())
  local autoRes = Z.db.autoRes Z.db.autoRes = false
  -- #20 combinaisons de modifications : cles valides, libelles, attributs poses sur les cases
  assert(Z.ParseClickKey("alt-ctrl-shift-1") and Z.ParseClickKey("ctrl-shift-2") and Z.ParseClickKey("3"))
  assert(not Z.ParseClickKey("shift-ctrl-1") and not Z.ParseClickKey("ctrl-6") and not Z.ParseClickKey("foo-1") and not Z.ParseClickKey(5))
  assert(Z:ClickLabel("ctrl-shift-1") == "Ctrl + Maj + Clic gauche", Z:ClickLabel("ctrl-shift-1"))
  assert(Z:KeyLabel("ALT-CTRL-SHIFT-F") == "Alt + Ctrl + Maj + F" and Z:KeyLabel("BUTTON6") == "Bouton 6" and Z:KeyLabel("SHIFT-MOUSEWHEELUP") == "Maj + Molette haut")
  assert(Z.ValidKey("CTRL-,") and not Z.ValidKey('F" self:Hide() "') and not Z.ValidKey("A B") and not Z.ValidKey("A|B") and not Z.ValidKey(""))
  Z:SetBinding({ kind = "click", key = "ctrl-shift-2" }, "Rénovation")
  assert(b:GetAttribute("ctrl-shift-spell2") == "Rénovation", "combinaison absente de la case")
  -- touches illimitees, avec modifications
  for i = 1, 20 do Z:SetBinding({ kind = "key", key = "CTRL-SHIFT-F" .. i }, "Soins") end
  assert(#Z:GetHoverKeys() >= 20 and b:GetAttribute("_onenter"):find('"CTRL-SHIFT-F20", self, "zh', 1, true), "touche 20 absente")
  -- une touche deja presente garde sa place, l'ancienne valeur est remplacee
  local n = #Z:GetHoverKeys()
  Z:SetBinding({ kind = "key", key = "CTRL-SHIFT-F3" }, "Rénovation")
  assert(#Z:GetHoverKeys() == n and Z:GetBinding({ kind = "key", key = "CTRL-SHIFT-F3" }) == "Rénovation")
  -- changer de declencheur vers un raccourci pris : les deux actions sont echangees
  Z:SetBinding({ kind = "click", key = "ctrl-shift-2" }, "Soins rapides")
  Z:MoveBinding({ kind = "click", key = "ctrl-shift-2" }, { kind = "key", key = "CTRL-SHIFT-F3" })
  assert(Z:GetClicks()["ctrl-shift-2"] == "Rénovation" and Z:GetBinding({ kind = "key", key = "CTRL-SHIFT-F3" }) == "Soins rapides", "echange")
  -- vers une touche libre : la touche est renommee sur place
  local place
  for i, entry in ipairs(Z:GetHoverKeys()) do if entry.key == "CTRL-SHIFT-F3" then place = i end end
  Z:MoveBinding({ kind = "key", key = "CTRL-SHIFT-F3" }, { kind = "key", key = "ALT-G" })
  assert(Z:GetHoverKeys()[place].key == "ALT-G" and #Z:GetHoverKeys() == n)
  Z:SetBinding({ kind = "key", key = "ALT-G" }, nil) assert(#Z:GetHoverKeys() == n - 1, "retrait")
  -- la liste unique : les clics d'abord, puis les touches ; l'infobulle suit le meme ordre
  local list = Z:Bindings()
  assert(list[1].kind == "click" and list[#list].kind == "key")
  local summary = Z:ClickSummary()
  assert(#summary == #list and summary[#summary][1] == "Ctrl + Maj + F20", summary[#summary][1])
  -- l'ecran : ajouter par la souris (Ctrl + Maj + clic du milieu), puis par une touche
  Z:ToggleOptions("Clics")
  local cell, row = Z:ClickCell("ctrl-shift-2")
  assert(cell and row, "ligne du clic combine absente")
  local page = row:GetParent():GetParent()
  local add = page.add
  assert(add, "bouton Ajouter")
  NOW = NOW + 1 add:Run("OnClick", "LeftButton")
  assert(add.capturing)
  local shift = IsShiftKeyDown
  IsShiftKeyDown = function() return true end CTRL = true
  add:Run("OnMouseDown", "MiddleButton")
  assert(not add.capturing and LyorunePicker:IsShown(), "choix du sort apres la capture")
  LyorunePicker.Choose("Soins")
  assert(Z:GetClicks()["ctrl-shift-3"] == "Soins" and b:GetAttribute("ctrl-shift-spell3") == "Soins")
  NOW = NOW + 1 add:Run("OnClick", "LeftButton")
  add:Run("OnKeyDown", "LSHIFT") assert(add.capturing, "Maj seul ne suffit pas")
  add:Run("OnKeyDown", "Q")
  LyorunePicker.Choose("Rénovation")
  assert(Z:GetBinding({ kind = "key", key = "CTRL-SHIFT-Q" }) == "Rénovation")
  -- le relachement du clic capture ne relance pas l'attente ; Echap annule
  add:Run("OnClick", "LeftButton") assert(not add.capturing, "attente relancee")
  NOW = NOW + 1 add:Run("OnClick", "LeftButton") add:Run("OnKeyDown", "ESCAPE")
  assert(not add.capturing and add.label:GetText():find("Ajouter", 1, true))
  -- changer le declencheur d'une ligne
  -- toutes les lignes sont visibles (la page du chapitre défile) : la liste s'allonge avec les raccourcis
  cell, row = Z:ClickCell("CTRL-SHIFT-Q", "key")
  assert(row and row:IsShown(), "ligne de la touche")
  assert(page:GetHeight() >= #Z:Bindings() * 27, "liste trop courte : " .. page:GetHeight())
  NOW = NOW + 1 row.key:Run("OnClick", "LeftButton") row.key:Run("OnMouseDown", "Button7")
  assert(Z:GetBinding({ kind = "key", key = "CTRL-SHIFT-BUTTON7" }) == "Rénovation" and not Z:GetBinding({ kind = "key", key = "CTRL-SHIFT-Q" }))
  IsShiftKeyDown = shift CTRL = false
  -- partage : combinaisons et touches au-dela de 9 passent
  local code = Z:Export()
  Z.db.clicks.PRIEST = {} Z.db.hoverKeys.PRIEST = {}
  assert(Z:Import(code))
  assert(Z.db.clicks.PRIEST["ctrl-shift-3"] == "Soins" and #Z.db.hoverKeys.PRIEST >= 20, "partage des raccourcis")
  assert(not Z:Import("Lyorune2;h.PRIEST.1=sF%22%20x|Soins") and not Z:Import("Lyorune2;c.PRIEST.shift-ctrl-1=sSoins"), "raccourci invalide importe")
  -- #22 nouveau sort sans clic : rien au premier passage, puis un message et une ligne en haut de l'onglet
  local info, lines = C_SpellBook.GetSpellBookItemInfo, C_SpellBook.GetSpellBookSkillLineInfo
  local function Book(ids)
    C_SpellBook.GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #ids } end
    C_SpellBook.GetSpellBookItemInfo = function(slot) return { itemType = 1, isPassive = false, spellID = ids[slot] } end
  end
  Z.char.knownSpells = nil Z.char.newSpells = nil
  local printed = #PRINTED
  Z:CheckNewSpells()
  assert(Z.char.knownSpells["Soins rapides"] and #PRINTED == printed, "premier passage bavard")
  Book({ 2061, 139, 17, 527, 6346, 2006 })
  Z:QueueNewSpells()
  assert(PRINTED[#PRINTED]:find("Gardien de peur", 1, true) and not PRINTED[#PRINTED]:find("Résurrection", 1, true), PRINTED[#PRINTED])
  assert(#Z:NewSpells() == 1 and Z:NewSpells()[1].name == "Gardien de peur")
  printed = #PRINTED Z:CheckNewSpells() assert(#PRINTED == printed, "signale deux fois")
  Z:ToggleOptions() Z:ToggleOptions("Clics")
  local banner = page.banner
  assert(banner and banner:IsShown() and banner.text:GetText():find("Gardien de peur", 1, true), "bandeau absent")
  -- Attribuer : la capture suivante pose directement le sort, et le bandeau disparait
  NOW = NOW + 1 banner.assign:Run("OnClick", "LeftButton")
  add:Run("OnKeyDown", "H")
  assert(Z:GetBinding({ kind = "key", key = "H" }) == "Gardien de peur" and not banner:IsShown() and #Z:NewSpells() == 0)
  -- un sort ecarte ne revient pas ; l'option coupe tout
  Book({ 2061, 139, 17, 527, 6346, 2006, 596 })
  Z:CheckNewSpells()
  assert(Z:NewSpells()[1] and Z:NewSpells()[1].name == "Prière de soins", "Prière de soins")
  Z:DismissNewSpell("Prière de soins") Z:CheckNewSpells()
  assert(#Z:NewSpells() == 0, "sort ecarte revenu")
  Z.db.newSpellAlert = false assert(#Z:NewSpells() == 0) Z.db.newSpellAlert = true
  C_SpellBook.GetSpellBookItemInfo, C_SpellBook.GetSpellBookSkillLineInfo = info, lines
  local labels = table.concat(Z:OptionLabels(), "|")
  assert(labels:find("Ajouter un clic ou une touche", 1, true) and labels:find("Signaler un nouveau sort sans clic", 1, true))
  Z:ToggleOptions()
  Z.db.clicks.PRIEST, Z.db.hoverKeys.PRIEST = saved, savedKeys
  Z.db.autoRes = autoRes Z:ApplyClicks()
end)

step("etape 2 : reprise des anciens reglages", function()
  local db = { locked = true, lastVersion = "1.6.0", manaBars = "HEALERS", pos = { "TOPLEFT", 10, -10 } }
  local savedDB, savedChar = LyoruneDB, LyoruneCharDB
  LyoruneDB, LyoruneCharDB = db, nil
  FireEvent("ADDON_LOADED", "Lyorune")
  assert(db.locked == nil and db.lockMode == "LOCKED" and db.manaBars == "ALL", "migration des reglages")
  assert(db.pos == nil and LyoruneCharDB.pos[1] == "TOPLEFT", "l'ancienne position revient au premier personnage")
  LyoruneCharDB = nil FireEvent("ADDON_LOADED", "Lyorune")
  assert(LyoruneCharDB.pos[1] == "CENTER" and LyoruneCharDB.pos[2] == -320, "un personnage neuf part de la position par defaut")
  db.manaBars = "HEALERS" db.lastVersion = "1.7.0" FireEvent("ADDON_LOADED", "Lyorune")
  assert(db.manaBars == "HEALERS", "un choix fait apres la 1.7.0 est respecte")
  LyoruneCharDB.optionChapter = "Clics" FireEvent("ADDON_LOADED", "Lyorune")
  assert(LyoruneCharDB.optionChapter == nil, "dernier chapitre des options plus sauve (1.26.0)")
  LyoruneDB, LyoruneCharDB = savedDB, savedChar
  FireEvent("ADDON_LOADED", "Lyorune")
end)

step("etape 8 : profils automatiques, cible et focalisation", function()
  local width, shape, clicks = Z.db.width, Z.db.shape, CopyTable(Z:GetClicks())
  Z.db.profiles, Z.db.autoProfiles, Z.db.activeProfile = {}, {}, ""
  -- #24 mes profils : seulement l'apparence, jamais les clics ni les annonces
  Z.db.width = 100
  assert(Z:SaveProfile("Donjon"))
  Z.db.width = 80
  assert(Z:SaveProfile("  Raid ") and Z.db.activeProfile == "Raid", "nom nettoye, profil en cours")
  local raid = Z.db.profiles.Raid
  assert(raid.width == 80 and raid.clicks == nil and raid.manaText == nil and raid.macros == nil and raid.profiles == nil, "contenu d'un profil")
  assert(raid.placement == nil, "1.49.0 : placements propres au personnage, hors des profils")
  Z.db.cornerSpells = Z.db.cornerSpells or {}
  assert(type(raid.cornerSpells) == "table" and raid.cornerSpells ~= Z.db.cornerSpells, "copie, pas un lien")
  assert(not Z:SaveProfile("") and not Z:SaveProfile(("x"):rep(25)) and not Z:SaveProfile("a\nb"), "noms refuses")
  -- charger : le profil quitte garde ce qui a ete regle pendant qu'il etait actif
  Z.db.width = 82
  assert(Z:LoadProfile("Donjon") and Z.db.width == 100 and Z.db.activeProfile == "Donjon")
  assert(Z.db.profiles.Raid.width == 82, "profil quitte enregistre")
  for key, spell in pairs(clicks) do assert(Z:GetClicks()[key] == spell, "clics inchanges") end
  -- un profil ancien ou abime ne casse rien : choix inconnu ignore, nombre borne
  Z.db.profiles.Raid.shape, Z.db.profiles.Raid.width, Z.db.profiles.Raid.inconnu = "NOPE", 999, true
  Z.db.shape = "BAR"
  Z:LoadProfile("Raid")
  assert(Z.db.shape == "BAR" and Z.db.width == 180 and Z.db.inconnu == nil, "valeurs controlees")
  assert(not Z:LoadProfile("Absent"))
  -- 20 profils au plus
  for i = 1, 18 do assert(Z:SaveProfile("P" .. i)) end
  assert(not Z:SaveProfile("P19") and Z:SaveProfile("P1"), "limite, remplacement permis")
  for i = 1, 18 do Z:DeleteProfile("P" .. i) end
  Z:LoadProfile("Donjon")
  -- profils automatiques : par taille de groupe
  assert(Z.GroupSize() == "5")
  RAID = true
  for _, case in ipairs({ { 8, "10" }, { 10, "10" }, { 11, "25" }, { 25, "25" }, { 26, "40" } }) do
    MEMBERS = case[1] assert(Z.GroupSize() == case[2], "palier " .. case[1])
  end
  Z:ProfileRules(1)["5"], Z:ProfileRules(1)["25"] = "Donjon", "Raid"
  MEMBERS = 20 FireEvent("GROUP_ROSTER_UPDATE")
  assert(Z.db.activeProfile == "Donjon", "interrupteur coupe : rien ne change")
  Z.db.autoProfile = true
  RAID = false FireEvent("GROUP_ROSTER_UPDATE")
  RAID = true FireEvent("GROUP_ROSTER_UPDATE")
  assert(Z.db.activeProfile == "Raid" and Z.db.width == 180, "raid de 20 : profil Raid")
  MEMBERS = 8 FireEvent("GROUP_ROSTER_UPDATE")
  assert(Z.db.activeProfile == "Raid", "aucun choix pour 10 : on garde")
  -- en combat : le changement attend la fin du combat
  COMBAT = true RAID = false MEMBERS = 5 FireEvent("GROUP_ROSTER_UPDATE")
  assert(Z.db.activeProfile == "Raid", "rien en combat")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  assert(Z.db.activeProfile == "Donjon" and Z.db.width == 100, "applique a la fin du combat")
  -- par specialisation : la 2e reprend la 1re si rien n'est choisi
  SPEC_GROUP = 2 FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  assert(Z.db.activeProfile == "Donjon", "2e specialisation sans choix : celui de la 1re")
  Z:ProfileRules(2)["5"] = "Raid"
  FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  assert(Z.db.activeProfile == "Raid", "2e specialisation : son propre profil")
  assert(Z.db.autoProfiles.PRIEST2["5"] == "Raid" and Z.db.autoProfiles.PRIEST["5"] == "Donjon")
  SPEC_GROUP = 1 FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  assert(Z.db.activeProfile == "Donjon")
  -- suppression : plus aucune regle vers un profil disparu
  Z:DeleteProfile("Raid")
  assert(Z.db.autoProfiles.PRIEST["25"] == nil and Z.db.autoProfiles.PRIEST2["5"] == nil, "regles nettoyees")
  -- deconnexion : le profil en cours garde les derniers reglages
  Z.db.width = 96 FireEvent("PLAYER_LOGOUT")
  assert(Z.db.profiles.Donjon.width == 96)
  -- partage : les profils ne partent jamais dans le code ; la reinitialisation les garde
  assert(not Z:Export():find("Donjon", 1, true) and not Z:Export():find("autoProfile", 1, true))
  Z:ResetAll()
  assert(Z.db.profiles.Donjon and Z.db.activeProfile == "" and Z.db.autoProfile == false, "reinitialisation")
  -- chapitre Profils et partage : les cases du tableau font tourner les profils
  Z:ToggleOptions("Profils et partage")
  local page = OptionPart("profileCells")
  assert(page, "chapitre Profils et partage construit")
  do
    local cell = page.profileCells[1]
    cell:Run("OnClick", "LeftButton")
    assert(Z:ProfileRules(1)["5"] == "Donjon", "case du tableau : profil suivant")
    cell:Run("OnClick", "LeftButton")
    assert(Z:ProfileRules(1)["5"] == nil, "puis aucun")
  end
  Z:ToggleOptions()
  Z.db.profiles, Z.db.autoProfiles, Z.db.activeProfile, Z.db.autoProfile = {}, {}, "", false
  Z.db.width, Z.db.shape = width, shape
  RAID, MEMBERS = false, 5
  Z:Refresh()

  -- #25 cible, cible de la cible, focalisation : aucune case tant que rien n'est coche
  local before = #Z.buttons
  assert(LyoruneExtra and not LyoruneExtra1, "cases creees a la demande seulement")
  Z.db.showTarget, Z.db.showFocus = true, true
  Z:Refresh()
  local target, focus = LyoruneExtra1, LyoruneExtra3
  assert(target and focus and not LyoruneExtra2 and #Z.buttons == before + 2, "deux cases creees")
  assert(target.unit == "target" and focus.unit == "focus" and target.extra)
  assert(UNIT_WATCH[target] and UNIT_WATCH[focus], "le jeu montre la case quand l'unite existe")
  assert(target:GetAttribute("spell1") or target:GetAttribute("macrotext1"), "mes clics sur la case cible")
  assert(focus._point[5] == -(Z.db.height + Z.db.spacing), "focalisation sous la cible")
  assert(STATE_DRIVERS[LyoruneExtra] == "show", "cadre affiche")
  target:Show() focus:Show() -- dans le jeu : RegisterUnitWatch, quand l'unite existe
  -- ennemi : couleur de son camp, aucune icone d'aura
  local isPlayer = UnitIsPlayer
  UnitIsPlayer = function(u) return u ~= "target" end
  ENEMIES.target = true
  AURAS["HARMFUL"] = { { name = "Morsure", icon = 3, auraInstanceID = 77, spellId = 5 } }
  Z.db.color = "CLASS"
  FireEvent("PLAYER_TARGET_CHANGED") RunUpdates()
  local c = target.hp._barColor
  assert(c[1] > 0.8 and c[2] < 0.3, "ennemi en rouge")
  assert(not (target.debuffs and target.debuffs[1] and target.debuffs[1]:IsShown()), "aucune icone sur un ennemi")
  ENEMIES.target = nil
  FireEvent("PLAYER_TARGET_CHANGED") RunUpdates()
  assert(target.hp._barColor[2] > 0.5, "personnage amical en vert")
  UnitIsPlayer = isPlayer
  FireEvent("PLAYER_TARGET_CHANGED") RunUpdates()
  assert(target.debuffs and target.debuffs[1]:IsShown(), "un allie garde ses icones")
  AURAS = {}
  -- la case de ma cible n'a pas de bordure blanche ; cible de la cible revue avec la portee
  Z.db.showTargetTarget = true
  COMBAT = true Z:Refresh()
  assert(not LyoruneExtra2, "jamais creee en combat")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  local tot = LyoruneExtra2
  tot:Show()
  assert(tot and tot.unit == "targettarget" and tot._point[5] == -(Z.db.height + Z.db.spacing), "cible de la cible au milieu")
  tot.name:SetText("") TICK()
  assert(tot.name:GetText() ~= "", "revue deux fois par seconde")
  -- decocher : le jeu ne la montre plus, la suivante remonte
  Z.db.showTarget = false Z:Refresh()
  assert(not UNIT_WATCH[target] and not target:IsShown() and tot._point[5] == 0, "case retiree")
  local labels = table.concat(Z:OptionLabels(), "|")
  for _, label in ipairs({ "Case de ma cible", "Case de ma focalisation", "Mes profils", "Profils automatiques", "Changer de profil tout seul" }) do
    assert(labels:find(label, 1, true), "absent de la recherche : " .. label .. " " .. tostring(Z.db.errors[1] and Z.db.errors[1].message))
  end
  Z.db.showTarget, Z.db.showTargetTarget, Z.db.showFocus = false, false, false
  Z:Refresh()
  assert(not focus:IsShown() and not tot:IsShown() and STATE_DRIVERS[LyoruneExtra] == nil, "tout coupe")
end)

step("etape 9 : mode panneau, mode grille, tri", function()
  local raid1, raid2, raid3 = LyoruneRaid1, LyoruneRaid2, LyoruneRaid3
  RAID = true Z:Refresh()
  -- #26 tri : confie au jeu (ordre du groupe par defaut, comme avant)
  assert(raid3:GetAttribute("sortMethod") == "INDEX" and raid3:GetAttribute("groupBy") == nil, "ordre du groupe")
  Z.db.sortOrder = "NAME" Z:Refresh()
  assert(raid3:GetAttribute("sortMethod") == "NAME" and raid3:GetAttribute("groupBy") == nil, "par nom")
  Z.db.sortOrder = "CLASS" Z:Refresh()
  local order = raid3:GetAttribute("groupingOrder")
  assert(raid3:GetAttribute("groupBy") == "CLASS" and raid3:GetAttribute("sortMethod") == "NAME", "par classe puis nom")
  for _, class in ipairs({ "PRIEST", "DRUID", "PALADIN", "SHAMAN", "EVOKER", "MONK" }) do
    assert(("," .. order .. ","):find("," .. class .. ",", 1, true), "classe absente du tri : " .. class)
  end
  assert(LyoruneTanks:GetAttribute("groupBy") == "CLASS" and LyorunePets:GetAttribute("groupBy") == "GROUP", "tanks par classe, familiers dans l'ordre des groupes")
  -- par role : le role d'abord, puis la classe dans chaque cadre de role
  Z.db.layout = "ROLE" Z:Refresh()
  assert(raid1:GetAttribute("roleFilter") == "TANK" and raid1:GetAttribute("groupBy") == "CLASS")
  RAID = false Z:Refresh()
  assert(Z.header:GetAttribute("groupBy") == "ASSIGNEDROLE" and Z.header:GetAttribute("sortMethod") == "NAME", "groupe par role : nom dans chaque role")
  Z.db.layout = "GROUP" Z:Refresh()
  assert(Z.header:GetAttribute("groupBy") == "CLASS", "groupe de 5 par classe")
  Z.db.sortOrder = "INDEX" Z:Refresh()
  assert(Z.header:GetAttribute("groupBy") == "GROUP" and Z.header:GetAttribute("sortMethod") == "INDEX", "retour a l'ordre du groupe")
  -- chaque groupe garde sa place : le groupe 3 ne se colle plus au groupe 2
  RAID = true Z:Refresh()
  assert(raid3._point[2] == raid2, "par defaut les groupes se suivent")
  Z.db.keepGroupPlace = true Z:Refresh()
  local w = Z.CellSize()
  assert(raid3._point[2] ~= raid2 and raid3._point[4] == 2 * (w + Z.db.spacing), "groupe 3 a son rang : " .. tostring(raid3._point[4]))
  Z.db.horizontal = true Z:Refresh()
  assert(raid3._point[4] == 0 and raid3._point[5] < raid2._point[5], "en lignes aussi")
  Z.db.horizontal, Z.db.keepGroupPlace = false, false
  -- grille : un seul cadre pour tout le raid, de la hauteur choisie
  Z.db.layout, Z.db.gridSize = "GRID", 8 Z:Refresh()
  assert(raid1:IsShown() and not raid2:IsShown() and not raid3:IsShown(), "un seul cadre")
  assert(raid1:GetAttribute("groupFilter") == "1,2,3,4,5,6,7,8" and raid1:GetAttribute("roleFilter") == nil)
  assert(raid1:GetAttribute("unitsPerColumn") == 8 and raid1:GetAttribute("maxColumns") == 5, "8 par colonne, 5 colonnes")
  assert(raid1:GetAttribute("groupBy") == "GROUP" and raid1.handle.text:GetText() == Z.L["Raid"])
  Z.db.gridSize = 99 Z:Refresh() -- valeur abimee : une seule colonne, aucune erreur
  assert(raid1:GetAttribute("maxColumns") == 1)
  -- mode test : la grille et le tri se voient aussi
  RAID = false Z.db.gridSize, Z.db.sortOrder, Z.db.groupPanel = 4, "CLASS", true
  Z:TogglePreview(10)
  assert(Z.previewActive and LyorunePreview.box, "fond de la grille")
  local cw, ch = Z.CellSize()
  assert(math.abs(LyorunePreview.box:GetWidth() - (3 * cw + 2 * Z.db.spacing)) < 0.01, "3 colonnes de 4")
  Z:TogglePreview(10)
  assert(not Z.previewActive)
  -- options : les nouveaux reglages sont dans la recherche
  local labels = table.concat(Z:OptionLabels(), "|")
  for _, label in ipairs({ "Ordre dans chaque bloc", "Chaque groupe garde sa place", "Cases par colonne en grille" }) do
    assert(labels:find(label, 1, true), "absent de la recherche : " .. label)
  end
  Z.db.layout, Z.db.gridSize, Z.db.sortOrder, Z.db.groupPanel = "GROUP", 5, "INDEX", false
  Z:Refresh()
end)

step("etape 10 : panneau des buffs manquants, assistant de depart", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = v end
  Z.db.buffPlace = "FREE" -- 1.34.0 : la fenetre (ou vous voulez) ; le bloc colle aux cadres a son etape
  -- #27 : le buff et sa version de groupe, lus dans le grimoire
  local check = Z.buffChecks[1]
  assert(check.spell == "Mot de pouvoir : Robustesse" and check.groupSpell == "Prière de robustesse", "sorts du buff")
  AURAS = {} Z:Refresh() RunUpdates()
  local panel = Z:BuffPanel()
  assert(panel and panel:IsShown(), "panneau absent alors que des buffs manquent")
  local list = Z.BuffRows()
  assert(#list >= 1, "aucune ligne")
  local missing = 0
  for _, b in ipairs(Z.buttons) do if b.missingBuff and not b.extra and b:IsVisible() then missing = missing + 1 end end
  if missing >= 3 then
    assert(list[1].count == missing and list[1].spell == "Prière de robustesse", "un groupe entier : une seule ligne de groupe")
  end
  local row = LyoruneBuffsRow1
  assert(row:GetAttribute("type1") == "spell" and row:GetAttribute("spell1") == list[1].spell and row:GetAttribute("unit") == list[1].unit, "bouton du jeu mal regle")
  row:Run("OnEnter") row:Run("OnLeave")
  -- deux joueurs seulement : une ligne chacun, version simple au clic, version de groupe au clic droit
  for i, b in ipairs(Z.buttons) do if i > 2 then b.missingBuff = nil end end
  Z:UpdateBuffPanel()
  list = Z.BuffRows()
  assert(list[1].spell == "Mot de pouvoir : Robustesse" and list[1].spell2 == "Prière de robustesse" and not list[1].count, "ligne d'un joueur")
  assert(LyoruneBuffsRow1:GetAttribute("spell2") == "Prière de robustesse")
  local third = rawget(_G, "LyoruneBuffsRow3") assert(not third or not third:IsShown(), "ligne en trop")
  -- buff present : plus rien a lancer
  AURAS["HELPFUL"] = { { name = "Mot de pouvoir : Robustesse", icon = 9, auraInstanceID = 31 } }
  Z:Refresh() RunUpdates()
  assert(not panel:IsShown(), "panneau ouvert sans buff manquant")
  AURAS = {} Z:Refresh() RunUpdates()
  assert(panel:IsShown())
  -- combat : cache juste avant le verrouillage, revient apres
  FireEvent("PLAYER_REGEN_DISABLED") COMBAT = true RunUpdates()
  assert(not panel:IsShown(), "panneau visible en combat")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
  assert(panel:IsShown(), "panneau absent apres le combat")
  -- la croix le ferme jusqu'a la fin du prochain combat
  panel.close:Run("OnClick") panel:Hide()
  Z:Refresh() RunUpdates()
  assert(not panel:IsShown(), "panneau revenu apres la croix")
  FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
  assert(panel:IsShown())
  -- interrupteurs : le panneau sans l'icone, puis rien du tout
  Z.db.missingBuffs = false Z:Refresh() RunUpdates()
  assert(panel:IsShown() and not Z.buttons[1].buffIcon:IsShown(), "panneau seul")
  Z.db.buffPanel = false Z:Refresh() RunUpdates()
  assert(not panel:IsShown(), "interrupteur du panneau")
  Z.db.missingBuffs, Z.db.buffPanel = true, true
  -- position par personnage
  panel:Run("OnDragStop")
  assert(type(Z.char.buffPos[2]) == "number", "position du panneau")
  -- #28 : assistant, trois questions puis la visite guidee
  Z.db.wizardDone, Z.db.tutorialDone = false, false
  Z:StartWizard()
  local w = Z:WizardWindow()
  assert(w:IsShown() and w.pages[1]:IsShown() and not w.pages[2]:IsShown(), "premiere question")
  w.pages[1].buttons[2]:Run("OnClick") -- tank
  w.next:Run("OnClick")
  assert(w.pages[2]:IsShown())
  w.pages[2].buttons[3]:Run("OnClick") -- raid de 40
  w.next:Run("OnClick")
  assert(w.pages[3]:IsShown() and Z.db.shape == "SQUARE" and Z.db.width == Z.shapes.SQUARE.width, "forme conseillee pour 40")
  w.pages[3].thumbs[1]:Run("OnClick") -- Barre
  assert(Z.db.shape == "BAR")
  w.next:Run("OnClick")
  assert(not w:IsShown() and Z.db.wizardDone, "fin de l'assistant")
  assert(Z.db.debuffMode == "DISPEL" and Z.db.threatBar and Z.db.manaBars == "HEALERS" and Z.db.autoShrink, "reponses appliquees")
  assert(LyoruneTutorial and LyoruneTutorial:IsShown(), "visite guidee apres l'assistant")
  LyoruneTutorial.close:Run("OnClick")
  -- « Passer » : rien ne change
  Z:StartWizard()
  Z:ApplyWizard("HEALER", "SMALL")
  assert(Z.db.debuffMode == "ALL" and not Z.db.threatBar and not Z.db.autoShrink and Z.db.manaBars == "ALL", "soigneur : reglages d'origine")
  w.close:Run("OnClick")
  assert(not w:IsShown() and Z.db.debuffMode == "ALL")
  -- lot 13 : « Passer » apres la page des formes rend la forme et les tailles d'avant
  Z:ApplyShape("TILE") Z.db.width = 99
  Z:StartWizard()
  w.pages[1].buttons[1]:Run("OnClick") w.next:Run("OnClick")
  w.pages[2].buttons[3]:Run("OnClick") w.next:Run("OnClick")
  assert(Z.db.shape == "SQUARE", "forme posee en direct")
  w.pages[3].thumbs[1]:Run("OnClick")
  assert(Z.db.shape == "BAR")
  w.close:Run("OnClick")
  assert(Z.db.shape == "TILE" and Z.db.width == 99, "passer garde la nouvelle forme : " .. tostring(Z.db.shape) .. " " .. tostring(Z.db.width))
  -- commande et options
  SlashCmdList.LYORUNE("assistant") assert(w:IsShown()) w.close:Run("OnClick")
  local labels = table.concat(Z:OptionLabels(), "|")
  assert(labels:find("Buffs manquants à poser", 1, true) and labels:find("Emplacement des buffs manquants", 1, true), "absent de la recherche")
  for k, v in pairs(saved) do Z.db[k] = v end
  Z:Refresh() RunUpdates()
end)

step("etape 11 : synchronisation entre joueurs", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = v end
  local clicks = CopyTable(Z.db.clicks)
  GROUPED, RAID = true, false
  GROUP_NAMES.party1, GROUP_NAMES.party2 = "Anduin", "Jaina"
  local function Msg(text, sender) FireEvent("CHAT_MSG_ADDON", "Lyorune", text, "PARTY", sender) end
  -- joueurs du groupe qui ont Lyorune : un membre qui annonce sa version entre dans la liste et recoit la mienne
  NOW = 5000 local n = #ADDON_SENT
  Msg("V:1.16.0", "Anduin-MonRoyaume")
  local list = Z:SyncMembers()
  assert(#list == 2 and list[2].name == "Anduin-MonRoyaume" and list[2].version == "1.16.0", "membre absent de la liste")
  assert(#ADDON_SENT == n + 1 and ADDON_SENT[n + 1].text == "V:" .. Z.version and ADDON_SENT[n + 1].channel == "PARTY", "pas de reponse au nouveau venu")
  Msg("V:1.16.0", "Anduin-MonRoyaume") assert(#ADDON_SENT == n + 1, "reponse en double")
  Msg("V:1.16.0", "Inconnu-Ailleurs") assert(#Z:SyncMembers() == 2, "joueur hors du groupe dans la liste")
  GROUP_NAMES.party1 = "Autre" assert(#Z:SyncMembers() == 1, "joueur parti encore dans la liste")
  GROUP_NAMES.party1 = "Anduin" NOW = 5020 Msg("V:1.17.0", "Anduin-MonRoyaume")
  SlashCmdList.LYORUNE("groupe") assert(PRINTED[#PRINTED]:find("Anduin (1.17.0)", 1, true), "commande /lyorune groupe")
  -- qui releve qui : Jaina releve Anduin
  local b for _, x in ipairs(Z.buttons) do if x.unit == "party1" and x:IsVisible() then b = x break end end
  assert(b, "case d'Anduin")
  DEAD = true Z.RefreshResBy() assert(b.text:GetText() == "Mort")
  Msg("R:Anduin-MonRoyaume", "Jaina-MonRoyaume") assert(b.text:GetText() == "Jaina", "nom du soigneur absent")
  Msg("R:-", "Jaina-MonRoyaume") assert(b.text:GetText() == "Mort", "resurrection arretee mais affichee")
  Msg("R:Anduin-MonRoyaume", "Jaina-MonRoyaume") Msg("R:+", "Jaina-MonRoyaume")
  NOW = 5050 Z.RefreshResBy() assert(b.text:GetText() == "Jaina", "attente de l'accord non affichee")
  NOW = 5090 Z.RefreshResBy() assert(b.text:GetText() == "Mort", "resurrection reussie affichee trop longtemps")
  -- releve puis retombe : l'ancien nom ne revient pas
  Msg("R:Anduin-MonRoyaume", "Jaina-MonRoyaume") DEAD = false Z.RefreshResBy() DEAD = true Z.RefreshResBy()
  assert(b.text:GetText() == "Mort", "ancien soigneur encore affiche")
  -- messages refuses : hors du groupe, nom abime
  for _, bad in ipairs({ "R:Anduin", "R:a b-c", "R:" .. ("x"):rep(70) .. "-Y", "R:-x-y", "R:" }) do Msg(bad, "Jaina-MonRoyaume") end
  Msg("R:Anduin-MonRoyaume", "Inconnu-Ailleurs")
  assert(b.text:GetText() == "Mort", "message refuse mais affiche")
  -- ma propre resurrection : le groupe est prevenu, puis l'arret
  n = #ADDON_SENT
  FireEvent("UNIT_SPELLCAST_SENT", "player", "Anduin", "guid1", 2006)
  assert(ADDON_SENT[#ADDON_SENT].text == "R:Anduin-MonRoyaume" and b.text:GetText() == "Joueur", "ma resurrection non annoncee")
  FireEvent("UNIT_SPELLCAST_INTERRUPTED", "player", "autre", 2006) assert(b.text:GetText() == "Joueur")
  FireEvent("UNIT_SPELLCAST_INTERRUPTED", "player", "guid1", 2006)
  assert(ADDON_SENT[#ADDON_SENT].text == "R:-" and b.text:GetText() == "Mort", "arret non annonce")
  FireEvent("UNIT_SPELLCAST_SENT", "player", "Anduin", "guid2", 2061) assert(ADDON_SENT[#ADDON_SENT].text == "R:-", "un soin annonce comme resurrection")
  FireEvent("UNIT_SPELLCAST_SENT", "player", MakeSecret(), MakeSecret(), 2006)
  FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", MakeSecret(), 2006)
  -- debit : un expediteur trop bavard est ignore un moment
  for i = 1, 60 do Msg("V:x", "Jaina-MonRoyaume") end
  Msg("R:Anduin-MonRoyaume", "Jaina-MonRoyaume") assert(b.text:GetText() == "Mort", "expediteur trop bavard ecoute")
  NOW = 5200 Msg("R:Anduin-MonRoyaume", "Jaina-MonRoyaume") assert(b.text:GetText() == "Jaina", "expediteur jamais pardonne")
  Msg("R:-", "Jaina-MonRoyaume")
  -- revue 1.23.6 : 81 résurrections réussies dont le mort ne se relève jamais sous nos yeux (parti du groupe)
  -- ne doivent pas remplir la liste pour toujours
  for i = 1, 81 do NOW = 5200 + i Msg("R:Mort" .. i .. "-MonRoyaume", "Jaina-MonRoyaume") Msg("R:+", "Jaina-MonRoyaume") end
  NOW = 5360 Msg("R:Anduin-MonRoyaume", "Jaina-MonRoyaume") assert(b.text:GetText() == "Jaina", "liste pleine d'entrees perimees")
  Msg("R:-", "Jaina-MonRoyaume")
  -- interrupteurs : la case seule, puis tout
  Z.db.resSync = false Z:RefreshAlerts() n = #ADDON_SENT
  Msg("R:Anduin-MonRoyaume", "Jaina-MonRoyaume") FireEvent("UNIT_SPELLCAST_SENT", "player", "Anduin", "guid3", 2006)
  assert(b.text:GetText() == "Mort" and #ADDON_SENT == n, "qui releve qui coupe")
  Z.db.resSync = true Z.db.syncEnabled = false Z:RefreshAlerts()
  Msg("R:Anduin-MonRoyaume", "Jaina-MonRoyaume") FireEvent("UNIT_SPELLCAST_SENT", "player", "Anduin", "guid4", 2006)
  NOW = 5300 FireEvent("GROUP_ROSTER_UPDATE")
  assert(b.text:GetText() == "Mort" and #ADDON_SENT == n, "synchronisation coupee mais active")
  assert(not Z:SendConfig("Jaina"), "envoi malgre la synchronisation coupee")
  SlashCmdList.LYORUNE("groupe") assert(PRINTED[#PRINTED]:find("coup", 1, true))
  Z.db.syncEnabled = true Z:RefreshAlerts() DEAD = false Z.RefreshResBy()
  -- sauvegarde avant import, puis retour en arriere
  Z.db.importBackup = nil assert(not Z:UndoImport() and not Z:CanUndoImport(), "rien a annuler")
  Z.db.clicks.PRIEST = { ["1"] = "Soins rapides" } Z.db.width = 140 local code = Z:Export()
  Z.db.clicks.PRIEST["alt-5"] = "Rénovation" Z.db.width = 100
  local ok, message = Z:Import(code)
  assert(ok and message:find("/lyorune annuler", 1, true) and Z.db.width == 140 and Z.db.clicks.PRIEST["alt-5"] == nil, "import")
  assert(Z:CanUndoImport())
  SlashCmdList.LYORUNE("annuler")
  assert(Z.db.width == 100 and Z.db.clicks.PRIEST["alt-5"] == "Rénovation" and not Z:CanUndoImport(), "retour en arriere")
  assert(not Z:UndoImport(), "deux retours en arriere")
  Z.db.importBackup = { settings = { width = "abc", inconnu = 5 }, clicks = 7 } -- sauvegarde abimee : sans effet
  assert(Z:UndoImport() and Z.db.width == 100 and Z.db.inconnu == nil and type(Z.db.clicks) == "table")
  -- options
  local labels = table.concat(Z:OptionLabels(), "|")
  for _, label in ipairs({ "Synchronisation entre joueurs", "Montrer qui relève qui", "Annuler l'import" }) do
    assert(labels:find(label, 1, true), "absent de la recherche : " .. label)
  end
  for k, v in pairs(saved) do Z.db[k] = v end
  Z.db.clicks = clicks Z.db.importBackup = nil GROUP_NAMES.party1, GROUP_NAMES.party2 = nil, nil
  Z:RefreshAlerts() Z:Refresh() RunUpdates()
end)

step("etape 12 : mode performance, mesure des performances", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = v end
  Z.db.perfMode = false Z:Refresh() RunUpdates()
  -- #30 : mode performance, la portee une fois par seconde au lieu de deux
  -- (UnitInRange est copie en local par Frames.lua : on compte le fondu, qui suit le meme passage)
  local calls, realFade, realHotFade = 0, Z.FadeHots, Z.db.hotFade
  Z.db.hotFade = true
  Z.FadeHots = function(...) calls = calls + 1 return realFade(...) end
  TICK() TICK() local normal = calls
  calls = 0 Z.db.perfMode = true TICK() TICK()
  Z.FadeHots, Z.db.hotFade = realFade, realHotFade
  assert(normal > 0 and calls * 2 == normal, "portee : " .. normal .. " puis " .. calls)
  -- auras regroupees : rien a la premiere image, tout apres un dixieme de seconde
  local b for _, x in ipairs(Z.buttons) do if x.unit and x:IsVisible() and not x.extra then b = x break end end
  AURAS = {} Z.db.perfMode = false Z.QueueAuras(b) RunUpdates()
  assert(b.missingBuff, "buff manquant attendu")
  AURAS["HELPFUL"] = { { name = "Mot de pouvoir : Robustesse", icon = 9, auraInstanceID = 31 } }
  Z.db.perfMode = true Z.QueueAuras(b) RunUpdates()
  assert(b.missingBuff, "auras non regroupees en mode performance")
  for i = 1, 10 do RunUpdates() end
  assert(not b.missingBuff, "auras jamais mises a jour en mode performance")
  AURAS = {} Z.db.perfMode = false Z.QueueAuras(b) RunUpdates()
  assert(b.missingBuff, "mise a jour immediate hors mode performance")
  -- mesure sans profileur : faux groupe de 5, 25 et 40, memoire de Lyorune et d'ElvUI
  Z.db.perfDiag = nil MEMORY._updated = nil
  -- C6 : fausses cases jamais dessinées (mode test pas ouvert dans la partie) : pas de taille d'icône
  for _, c in ipairs(Z:PreviewCells(40)) do c.iconSize = nil end
  local result = Z:Measure()
  assert(result and MEMORY._updated, "mesure")
  assert(#result.groups == 3 and result.groups[1].count == 5 and result.groups[3].count == 40, "faux groupes")
  for _, g in ipairs(result.groups) do assert(g.perSecond >= 0 and g.full >= 0, "temps negatif") end
  assert(result.addons[1].name == "Lyorune" and result.addons[1].memory == 850, "memoire de Lyorune")
  assert(#result.addons == 2 and result.addons[2].name == "ElvUI", "autres addons charges")
  assert(not result.profiler and result.addons[1].average == nil, "profileur absent mais lu")
  assert(#Z.db.perfDiag == 1 and Z.db.perfDiag[1]:find("40 joueurs", 1, true), "trace")
  -- les cases d'essai sont rendues propres : aucune unite, aucun evenement
  for _, c in ipairs(Z:PreviewCells(40)) do assert(c.unit == nil and not next(c._events), "case d'essai encore active") end
  -- lot 12 : le marqueur de raid et la coche de mon personnage ne restent pas sur les fausses cases
  for _, c in ipairs(Z:PreviewCells(40)) do
    assert(not c.marker:IsShown() and not c.center:IsShown(), "marqueur ou coche de la mesure restes sur le mode test")
  end
  -- profileur du jeu : moyenne, pic, part du temps
  Enum.AddOnProfilerMetric = { SessionAverageTime = 1, RecentAverageTime = 2, PeakTime = 3 }
  local values = { Lyorune = { 0.02, 0.03, 1.5 }, ElvUI = { 0.4, 0.5, 9 } }
  C_AddOnProfiler = { IsEnabled = function() return true end,
    GetAddOnMetric = function(name, id) return values[name] and values[name][id] end,
    GetOverallMetric = function(id) return id == 1 and 0.5 or 1 end }
  result = Z:Measure()
  assert(result.profiler and result.addons[1].average == 0.02 and result.addons[2].peak == 9, "temps reel")
  assert(math.abs(result.share - 4) < 0.001, "part du temps : " .. tostring(result.share))
  -- profileur coupe, valeur secrete, erreur : rien d'invente
  C_AddOnProfiler.IsEnabled = function() return false end
  assert(not Z:Measure().profiler, "profileur coupe mais lu")
  C_AddOnProfiler.IsEnabled = function() return true end
  C_AddOnProfiler.GetAddOnMetric = function() return MakeSecret() end
  assert(Z:Measure().addons[1].average == nil, "valeur secrete lue")
  C_AddOnProfiler.GetAddOnMetric = function() error("x") end
  assert(Z:Measure().addons[1].average == nil)
  C_AddOnProfiler, Enum.AddOnProfilerMetric = nil, nil
  -- le mode test ouvert retrouve ses faux joueurs apres la mesure
  Z:TogglePreview(10)
  Z:Measure()
  local first = Z:PreviewCells(1)[1]
  assert(first.name:GetText():match("^Joueur %d+$"), "mode test abime : " .. tostring(first.name:GetText()))
  Z:TogglePreview()
  -- fenetre, commande, resume dans le chat, trace limitee
  SlashCmdList.LYORUNE("mesure")
  local w = Z:MeasureWindow()
  assert(w and w:IsShown(), "fenetre")
  assert(w.groups[3][1]:GetText() == "40 joueurs", tostring(w.groups[3][1]:GetText()))
  assert(w.addons[1][1]:GetText():find("Lyorune", 1, true) and w.addons[3][1]:GetText() == "", "lignes des addons")
  assert(PRINTED[#PRINTED]:find("mesure faite", 1, true), "resume dans le chat")
  for i = 1, 12 do Z:Measure() end
  assert(#Z.db.perfDiag == 10, "trace limitee")
  COMBAT = true local none, reason = Z:Measure() COMBAT = false
  assert(not none and reason:find("combat", 1, true), "mesure en combat")
  w.close:Run("OnClick")
  -- options
  local labels = table.concat(Z:OptionLabels(), "|")
  for _, label in ipairs({ "Mode performance", "Mesurer les performances" }) do
    assert(labels:find(label, 1, true), "absent de la recherche : " .. label)
  end
  for k, v in pairs(saved) do Z.db[k] = v end
  Z.db.perfDiag = nil
  Z:Refresh() RunUpdates()
end)

step("etape 13 : distance en trois paliers, soin refuse hors de vue", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = v end
  local b for _, x in ipairs(Z.buttons) do if x.unit and x.unit ~= "player" and x:IsVisible() and not x.extra then b = x break end end
  assert(b, "case d'un autre joueur")
  local readyCheck = b.readyCheck b.readyCheck = nil -- l'appel « Pret ? » passe avant
  Z.db.farHint, Z.db.losHint, Z.db.rangeAlpha = true, true, 40 Z:Refresh()
  -- #31 tres loin : le jeu ne voit plus le joueur, case plus estompee et empreintes au centre
  UnitIsVisible = function() return false end
  TICK()
  assert(b.far and b.center:IsShown() and b.center._tex:find("Ability_Tracking", 1, true), "empreintes absentes")
  assert(math.abs(b:GetAlpha() - 0.2) < 0.001, "opacite tres loin : " .. tostring(b:GetAlpha()))
  -- le jeu le revoit : retour a l'estompage simple, plus d'icone
  UnitIsVisible = function() return true end
  TICK()
  assert(not b.far and not b.center:IsShown(), "empreintes restees")
  -- reponse secrete ou joueur deconnecte : on s'en tient a l'estompage simple
  UnitIsVisible = function() return MakeSecret() end TICK()
  assert(not b.far, "reponse secrete prise pour loin")
  UnitIsVisible = function() return false end OFFLINE = true TICK() OFFLINE = false
  assert(not b.far, "deconnecte pris pour loin")
  -- interrupteur
  Z.db.farHint = false TICK()
  assert(not b.far and not b.center:IsShown(), "farHint coupe")
  UnitIsVisible = nil
  -- soin refuse hors de vue : clic sur la case, message du jeu
  SPELL_FAILED_LINE_OF_SIGHT = "Cible hors du champ de vision"
  b:Run("OnClick", "LeftButton")
  FireEvent("UI_ERROR_MESSAGE", 50, "Autre erreur")
  assert(not b.losUntil, "mauvaise erreur prise pour hors de vue")
  FireEvent("UI_ERROR_MESSAGE", 50, SPELL_FAILED_LINE_OF_SIGHT)
  assert(b.losUntil and b.center:IsShown() and b.center._tex:find("Ability_EyeOfTheOwl", 1, true), "oeil absent")
  -- au bout de 3 secondes, l'oeil s'en va
  NOW = NOW + 4 Z.MarkOutOfSight(nil) b.losUntil = NOW - 1 FireEvent("UNIT_PHASE", b.unit)
  assert(not b.center:IsShown(), "oeil reste")
  b.losUntil = nil
  -- refus a la fin d'une incantation partie du clic, et pas d'une autre plus tard
  b:Run("OnClick", "LeftButton")
  FireEvent("UNIT_SPELLCAST_START", "player")
  NOW = NOW + 2.5
  FireEvent("UI_ERROR_MESSAGE", 50, SPELL_FAILED_LINE_OF_SIGHT)
  assert(b.losUntil, "refus en fin d'incantation non relie au clic")
  b.losUntil = nil FireEvent("UNIT_SPELLCAST_STOP", "player")
  NOW = NOW + 5
  FireEvent("UNIT_SPELLCAST_START", "player")
  FireEvent("UI_ERROR_MESSAGE", 50, SPELL_FAILED_LINE_OF_SIGHT)
  assert(not b.losUntil, "sort lance sans clic sur une case")
  -- valeur secrete et interrupteur
  b:Run("OnClick", "LeftButton")
  FireEvent("UI_ERROR_MESSAGE", 50, MakeSecret())
  assert(not b.losUntil, "message secret lu")
  Z.db.losHint = false
  FireEvent("UI_ERROR_MESSAGE", 50, SPELL_FAILED_LINE_OF_SIGHT)
  assert(not b.losUntil, "losHint coupe")
  FireEvent("UNIT_SPELLCAST_STOP", "player")
  SPELL_FAILED_LINE_OF_SIGHT = nil
  -- diagnostic de position : la ligne du nouveau palier
  Z.db.positionDiag = nil SlashCmdList.LYORUNE("position")
  assert(Z.db.positionDiag[1]:find("vu par le jeu", 1, true), "diagnostic sans le palier tres loin")
  -- options
  local labels = table.concat(Z:OptionLabels(), "|")
  for _, label in ipairs({ "Joueur très loin : empreintes", "Soin refusé, hors de vue : un œil" }) do
    assert(labels:find(label, 1, true), "absent de la recherche : " .. label)
  end
  for k, v in pairs(saved) do Z.db[k] = v end
  Z.db.positionDiag = nil
  b.readyCheck = readyCheck
  Z:Refresh() RunUpdates()
end)

step("etape 14 : joueurs epingles, signal, chef de groupe", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = type(v) == "table" and CopyTable(v) or v end
  local h = LyorunePinned
  assert(h and h.def.key == "pinned", "cadre Epingles absent")
  -- liste vide : cadre cache, meme coche
  Z.db.pinned = {} Z.db.showPinned = true Z:Refresh()
  assert(not h:IsShown(), "cadre vide affiche")
  -- nom tape a la main : nettoye, casse du joueur du groupe retrouvee
  GROUP_NAMES.party2 = "Thrall-Autreroyaume"
  assert(Z.CleanPinName("  thrall ") == "Thrall-Autreroyaume", tostring(Z.CleanPinName("thrall")))
  assert(Z.CleanPinName("jaina,proud moore") == "Jainaproudmoore", "virgule ou espace gardes")
  assert(Z.CleanPinName("") == nil and Z.CleanPinName(MakeSecret()) == nil and Z.CleanPinName(("x"):rep(80)) == nil)
  -- /lyorune epingler Nom : la liste passe au jeu (nameList), sans filtre de groupe ni de role
  Z.db.showPinned = false
  SlashCmdList.LYORUNE("epingler Thrall")
  assert(Z.db.pinned["Thrall-Autreroyaume"] and Z.db.showPinned, "epingler ne montre pas le cadre")
  SlashCmdList.LYORUNE("épingler Anduin")
  assert(h:GetAttribute("nameList") == "Anduin,Thrall-Autreroyaume", tostring(h:GetAttribute("nameList")))
  assert(h:GetAttribute("groupFilter") == nil and h:GetAttribute("roleFilter") == nil and h:IsShown(), "cadre Epingles mal regle")
  -- case survolee : epingler puis retirer le meme joueur
  local b for _, x in ipairs(Z.buttons) do if x.unit and x.unit ~= "player" and x:IsVisible() and not x.extra then b = x break end end
  b:Run("OnEnter") GROUP_NAMES[b.unit] = "Varian"
  SlashCmdList.LYORUNE("epingler") assert(Z.db.pinned.Varian, "case survolee non epinglee")
  SlashCmdList.LYORUNE("epingler") assert(not Z.db.pinned.Varian, "second appel ne retire pas")
  b:Run("OnLeave") GROUP_NAMES[b.unit] = nil
  -- personne de vise : message, rien d'ajoute
  local n = #PRINTED
  UnitIsPlayer = function() return false end
  SlashCmdList.LYORUNE("pin")
  UnitIsPlayer = function() return true end
  assert(#PRINTED == n + 1 and PRINTED[n + 1]:find("aucun joueur", 1, true), "message sans joueur")
  -- en combat, la liste change a la fin du combat
  COMBAT = true SlashCmdList.LYORUNE("epingler Garrosh") COMBAT = false
  assert(not h:GetAttribute("nameList"):find("Garrosh"), "liste changee en combat")
  FireEvent("PLAYER_REGEN_ENABLED")
  assert(h:GetAttribute("nameList"):find("Garrosh"), "liste non reprise apres le combat")
  -- interrupteur et diagnostic
  Z.db.showPinned = false Z:Refresh() assert(not h:IsShown(), "showPinned coupe")
  assert(Z:Export():find("pinned") == nil, "noms epingles partages")
  -- chef de groupe et assistant
  Z.db.showLeader = true LEADER = b.unit FireEvent("PARTY_LEADER_CHANGED")
  assert(b.leader:IsShown() and b.leader._tex:find("LeaderIcon", 1, true), "couronne absente")
  LEADER = nil RAID = true ASSISTS[b.unit] = true FireEvent("PARTY_LEADER_CHANGED")
  assert(b.leader:IsShown() and b.leader._tex:find("AssistantIcon", 1, true), "drapeau d'assistant absent")
  RAID = false FireEvent("PARTY_LEADER_CHANGED")
  assert(not b.leader:IsShown(), "assistant hors raid")
  -- reponse secrete en combat : l'icone reste comme elle etait
  LEADER = b.unit FireEvent("PARTY_LEADER_CHANGED")
  SECRET_LEADER = true FireEvent("PARTY_LEADER_CHANGED") SECRET_LEADER = nil
  assert(b.leader:IsShown(), "reponse secrete efface la couronne")
  Z.db.showLeader = false Z:Refresh() assert(not b.leader:IsShown(), "showLeader coupe")
  LEADER, ASSISTS = nil, {}
  -- signal du jeu : la touche de signal marque le joueur de la case (attribut du jeu), interrupteur
  Z.db.pingCells = true Z:Refresh()
  assert(b:GetAttribute("ping-receiver") == true and Z.header:GetAttribute("z-ping") == true, "case sans signal")
  Z.db.pingCells = false Z:Refresh()
  assert(b:GetAttribute("ping-receiver") == nil and Z.header:GetAttribute("z-ping") == nil, "pingCells coupe")
  assert(Z.header:GetAttribute("template"):find("PingableUnitFrameTemplate", 1, true), "modele de signal absent")
  -- placement et options
  assert(Z.IsPlaceElement("leader"), "couronne absente de l'editeur de placement")
  local labels = table.concat(Z:OptionLabels(), "|")
  for _, label in ipairs({ "Cadre des joueurs épinglés", "Chef de groupe et assistants", "Signal du jeu sur une case", "Joueurs épinglés" }) do
    assert(labels:find(label, 1, true), "absent de la recherche : " .. label)
  end
  -- chaque page de chapitre est rangee et defile
  CheckChapters()
  for k, v in pairs(saved) do Z.db[k] = v end
  GROUP_NAMES.party2 = nil
  Z:Refresh() RunUpdates()
end)

step("etape 15 : bijoux, arreter l'incantation, clic pour lancer du jeu", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = type(v) == "table" and CopyTable(v) or v end
  local b = Z.buttons[1]
  Z.db.autoRes = false Z.db.externalClicks = false
  Z.db.clicks[Z:ClickSet()] = { ["shift-1"] = "Soins rapides", ["2"] = "@menu", ["ctrl-1"] = "Rénovation" }
  Z.db.hoverKeys[Z:ClickSet()] = { { key = "F", spell = "Soins rapides" } }
  Z.db.clickTrinkets = {}
  Z:ApplyClicks()
  assert(b:GetAttribute("shift-type1") == "spell", "sans bijou : sort simple")
  -- bijou 1 sur un clic, les deux sur une touche : /use avant le sort, sur un vivant
  local shift, key = { kind = "click", key = "shift-1" }, { kind = "key", key = "F" }
  Z:ToggleTrinket(shift, 1)
  assert(b:GetAttribute("shift-macrotext1") == "/use [@mouseover,nodead] 13\n/cast [@mouseover] Soins rapides", tostring(b:GetAttribute("shift-macrotext1")))
  Z:ToggleTrinket(key, 1) Z:ToggleTrinket(key, 2)
  assert(Z:GetTrinkets()["key:F"] == 3 and b:GetAttribute("*macrotext-zh1") == "/use [@mouseover,nodead] 13\n/use [@mouseover,nodead] 14\n/cast [@mouseover] Soins rapides", tostring(b:GetAttribute("*macrotext-zh1")))
  -- avec la resurrection automatique, le bijou passe avant tout
  Z.db.autoRes = true Z:ApplyClicks()
  assert(b:GetAttribute("shift-macrotext1"):find("^/use %[@mouseover,nodead%] 13\n/cast %[@mouseover,help,dead%]"), tostring(b:GetAttribute("shift-macrotext1")))
  Z.db.autoRes = false
  -- infobulle de la case
  local found for _, line in ipairs(Z:ClickSummary()) do if line[2]:find("bijou", 1, true) then found = true end end
  assert(found, "bijou absent de l'infobulle")
  -- retirer un bijou, deplacer un raccourci : les bijoux suivent leur sort
  Z:ToggleTrinket(key, 2) assert(Z:GetTrinkets()["key:F"] == 1)
  Z:MoveBinding(shift, { kind = "click", key = "ctrl-1" })
  assert(Z:GetTrinkets()["ctrl-1"] == 1 and Z:GetTrinkets()["shift-1"] == nil, "bijou reste sur l'ancien clic")
  assert(b:GetAttribute("ctrl-macrotext1"):find("/use", 1, true) and b:GetAttribute("shift-type1") == "spell", "attributs apres echange")
  Z:MoveBinding(key, { kind = "key", key = "G" })
  assert(Z:GetTrinkets()["key:G"] == 1 and Z:GetTrinkets()["key:F"] == nil, "bijou de la touche renommee")
  -- pas de bijou sur « menu », « cibler », « arreter » ; retirer le raccourci retire le bijou
  assert(not Z.TakesTrinket("@menu") and not Z.TakesTrinket("@target") and not Z.TakesTrinket("@stop") and Z.TakesTrinket("Rénovation"))
  Z:SetBinding({ kind = "click", key = "ctrl-1" }, "@stop")
  assert(Z:GetTrinkets()["ctrl-1"] == nil, "bijou garde sur Arreter")
  assert(b:GetAttribute("ctrl-type1") == "macro" and b:GetAttribute("ctrl-macrotext1") == "/stopcasting", "arreter l'incantation")
  assert(Z:ActionText("@stop") == "Arrêter l'incantation")
  Z:SetBinding({ kind = "click", key = "ctrl-1" }, "Rénovation")
  Z:ToggleTrinket({ kind = "click", key = "ctrl-1" }, 2)
  Z:SetBinding({ kind = "click", key = "ctrl-1" }, nil)
  assert(Z:GetTrinkets()["ctrl-1"] == nil, "raccourci retire, bijou garde")
  -- macro de ma bibliotheque : les lignes /use passent devant
  Z.db.clicks[Z:ClickSet()]["alt-1"] = "/cast [@mouseover] Soins"
  Z:ToggleTrinket({ kind = "click", key = "alt-1" }, 2)
  assert(b:GetAttribute("alt-macrotext1") == "/use [@mouseover,nodead] 14\n/cast [@mouseover] Soins", tostring(b:GetAttribute("alt-macrotext1")))
  -- partage : bijoux exportes avec leur sort, controles a l'import, annulables
  Z:ToggleTrinket({ kind = "click", key = "shift-1" }, 1) -- shift-1 a repris « Rénovation » a l'echange
  local code = Z:Export()
  assert(code:find("t%." .. Z:ClickSet() .. "%.shift%%2D1=n1"), "bijou absent du code")
  assert(not code:find("alt%%2D1=n"), "bijou d'une macro partage")
  Z.db.clickTrinkets = {}
  assert(Z:Import(code))
  assert(Z:GetTrinkets()["shift-1"] == 1, "bijou non importe")
  Z:UndoImport()
  assert(Z:GetTrinkets()["shift-1"] == nil, "annuler l'import garde le bijou")
  local before = Z:GetTrinkets()["key:G"]
  Z:Import("Lyorune1;t.PRIEST.shift%2D1=n9;t.PRIEST.zzz=n1;t.PRIEST.key%3AF%22=n1;c.PRIEST.shift%2D1=sSoins")
  for id, mask in pairs(Z.db.clickTrinkets.PRIEST or {}) do assert(mask >= 1 and mask <= 3 and (Z.ParseClickKey(id) or id:find("^key:")), "bijou abime importe : " .. id) end
  Z:UndoImport()
  -- clic pour lancer du jeu : lu, jamais modifie ; conflit signale une seule fois
  Z.db.clicks[Z:ClickSet()] = { ["shift-1"] = "Soins rapides", ["1"] = "Rénovation" }
  local types = { Spell = 1, Macro = 2, Interaction = 3, PetAction = 4 }
  Enum.ClickBindingType = types
  local profile = { { type = 1, actionID = 2061, button = "LeftButton", modifiers = 1 },
    { type = 3, actionID = 1, button = "LeftButton", modifiers = 0 },  -- « cibler » du jeu : pas un conflit
    { type = 1, actionID = 2061, button = "Button6", modifiers = 0 } }
  C_ClickBindings = { GetProfileInfo = function() return profile end }
  GetStringFromModifiers = function(m) return m == 1 and "SHIFT" or "" end
  assert(Z.GameClickKey("LeftButton", 1) == "shift-1" and Z.GameClickKey("Button5", 0) == "5" and Z.GameClickKey("Button7", 0) == nil)
  local conflicts = Z:GameClickConflicts()
  assert(conflicts["shift-1"] and not conflicts["1"], "conflit mal lu")
  local n = #PRINTED
  Z.db.clickConflictAlert = true Z:ApplyClicks() Z:ApplyClicks()
  assert(#PRINTED == n + 1 and PRINTED[n + 1]:find("Maj + Clic gauche", 1, true), "message de conflit : " .. tostring(PRINTED[n + 1]))
  Z.db.externalClicks = true assert(next(Z:GameClickConflicts()) == nil, "conflit avec clics externes")
  Z.db.externalClicks = false
  C_ClickBindings = { GetProfileInfo = function() error("refuse") end }
  assert(next(Z:GameClickConflicts()) == nil, "erreur du jeu non rattrapee")
  C_ClickBindings, GetStringFromModifiers, Enum.ClickBindingType = nil, nil, nil
  -- options
  local labels = table.concat(Z:OptionLabels(), "|")
  assert(labels:find("Signaler un clic pris aussi par le jeu", 1, true), "option de conflit absente")
  CheckChapters()
  for k, v in pairs(saved) do Z.db[k] = v end
  Z:ApplyClicks()
end)

step("etape 16 : buffs uniques, temps de recharge global", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = type(v) == "table" and CopyTable(v) or v end
  Z.db.buffPlace = "FREE"
  local oldRole, oldAfter = UnitGroupRolesAssigned, C_Timer.After
  -- un buff unique pour le pretre du faux client (Data.lua : Z.uniqueBuffs), dans ma liste au depart
  local dataUnique = Z.uniqueBuffs.PRIEST
  Z.uniqueBuffs.PRIEST = { 6346 } Z:BuildData()
  assert(#Z.uniqueChecks == 1 and Z.uniqueChecks[1].name == "Gardien de peur", "buff unique non lu")
  local units = {}
  for _, b in ipairs(Z.buttons) do if b.unit and not b.extra and b:IsVisible() and not b.unit:find("pet") then units[#units + 1] = b end end
  assert(#units >= 2, "faux groupe trop petit")
  local tank = units[2]
  UnitGroupRolesAssigned = function(u) return u == tank.unit and "TANK" or "HEALER" end
  local function UniqueRow() for _, r in ipairs(Z.BuffRows()) do if r.check.unique then return r end end end
  AURAS = {} Z.db.buffPanel = true Z.char.buffTarget = {} Z:Refresh() RunUpdates()
  local row = UniqueRow()
  assert(row and row.unit == tank.unit and row.spell == "Gardien de peur" and row.why == "tank", "buff unique pas propose au tank")
  local found
  for i = 1, 10 do
    local r = rawget(_G, "LyoruneBuffsRow" .. i)
    if r and r:IsShown() and r:GetAttribute("spell1") == "Gardien de peur" then found = r end
  end
  assert(found and found:GetAttribute("unit") == tank.unit and found:GetAttribute("type1") == "spell", "ligne du panneau")
  found:Run("OnEnter") found:Run("OnLeave")
  -- deja pose par moi sur quelqu'un : plus rien a proposer
  AURAS["HELPFUL|PLAYER"] = { { name = "Gardien de peur", icon = 1, auraInstanceID = 51, spellId = 6346 } }
  Z:Refresh() RunUpdates()
  assert(not UniqueRow(), "buff deja pose encore propose")
  AURAS = {} Z:Refresh() RunUpdates()
  -- le joueur choisi passe avant le tank ; le meme une 2e fois (survol) : retour au tank
  GROUP_NAMES[units[1].unit] = "Thrall"
  SlashCmdList.LYORUNE("porteur thrall")
  assert(Z.char.buffTarget.name == "Thrall", "porteur : " .. tostring(Z.char.buffTarget.name))
  row = UniqueRow()
  assert(row and row.unit == units[1].unit and row.why == "choisi", "joueur choisi ignore")
  units[1]:Run("OnEnter") SlashCmdList.LYORUNE("porteur") units[1]:Run("OnLeave")
  assert(Z.char.buffTarget.name == nil and UniqueRow().unit == tank.unit, "retour au tank")
  -- joueur choisi absent du groupe : le tank
  Z.char.buffTarget.name = "Absent" assert(UniqueRow().unit == tank.unit, "porteur absent")
  Z.char.buffTarget.name = nil
  -- ni tank ni joueur choisi, ou role secret : rien, sans erreur
  UnitGroupRolesAssigned = function() return "HEALER" end assert(not UniqueRow(), "ligne sans tank")
  UnitGroupRolesAssigned = function() return MakeSecret() end assert(not UniqueRow(), "role secret")
  UnitGroupRolesAssigned = oldRole GROUP_NAMES[units[1].unit] = nil
  Z.uniqueBuffs.PRIEST = nil Z:BuildData()
  assert(#Z.uniqueChecks == 0)
  Z.uniqueBuffs.PRIEST = dataUnique Z:BuildData()
  -- temps de recharge global : rien n'est cree tant que le reglage reste sur « Aucun »
  local later = {}
  C_Timer.After = function(_, f) later[#later + 1] = f end
  NOW = 5000
  C_Spell.GetSpellCooldown = function(id) assert(id == 61304, "sort du temps de recharge global") return { startTime = NOW, duration = 1.5 } end
  Z.db.castIndicator = "OFF" Z:Refresh()
  FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
  assert(Z:CastIndicator() == nil, "barre creee sans le reglage")
  -- barre : blanche pour la recharge, cachee a la fin
  Z.db.castIndicator = "BAR" Z:Refresh()
  FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
  local bar = Z:CastIndicator()
  assert(bar and bar:IsShown() and bar._barColor[1] == 0.9, "barre de recharge")
  RunUpdates()
  table.remove(later)() assert(not bar:IsShown(), "barre restee apres la recharge")
  -- incantation : couleur d'accent ; la recharge ne la remplace pas ; a la fin, la recharge reprend
  UnitCastingInfo = function() return "Soins", "", 1, NOW * 1000, NOW * 1000 + 2500 end
  FireEvent("UNIT_SPELLCAST_START", "player")
  assert(bar:IsShown() and bar._barColor[1] == Z.UI.accent[1], "barre d'incantation")
  -- revue 1.23.5 : un 2e sort refusé pendant l'incantation (clics répétés) ne cache pas la barre
  FireEvent("UNIT_SPELLCAST_FAILED", "player")
  assert(bar:IsShown() and bar._barColor[1] == Z.UI.accent[1], "barre cachee par un sort refuse pendant l'incantation")
  FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
  assert(bar._barColor[1] == Z.UI.accent[1], "recharge par-dessus l'incantation")
  FireEvent("UNIT_SPELLCAST_STOP", "player")
  assert(bar:IsShown() and bar._barColor[1] == 0.9, "recharge apres l'incantation")
  for _, f in ipairs(later) do f() end later = {}
  assert(not bar:IsShown())
  -- en combat, temps secrets : l'objet « duree » du jeu est confie a la barre
  UnitCastingInfo = function() return "Soins", "", 1, MakeSecret(), MakeSecret() end
  Enum.StatusBarTimerDirection = { ElapsedTime = 0 }
  local fed
  UnitCastingDuration = function() return "duree" end
  bar.SetTimerDuration = function(_, d) fed = d end
  FireEvent("UNIT_SPELLCAST_START", "player")
  assert(bar:IsShown() and fed == "duree", "duree secrete")
  FireEvent("UNIT_SPELLCAST_FAILED", "player")
  assert(bar:IsShown(), "barre cachee par un sort refuse, nom secret")
  UnitCastingInfo = function() end
  FireEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
  assert(not bar:IsShown() or bar._barColor[1] == 0.9, "incantation interrompue toujours affichee")
  for _, f in ipairs(later) do f() end later = {}
  -- C46 : la place des familiers ne compte que si l'un d'eux est affiche
  local oldHeaders = Z.headers
  local pet = { IsVisible = function() return false end, GetRight = function() return 260 end }
  local cell = { petCell = pet }
  local h = { def = { pos = "pos" }, petRoom = 60,
    IsVisible = function() return true end, GetEffectiveScale = function() return 1 end,
    GetLeft = function() return 100 end, GetRight = function() return 200 end, GetBottom = function() return 50 end,
    GetAttribute = function(_, k) if k == "child1" then return cell end end }
  Z.headers = { h }
  UnitCastingInfo = function() return "Soins", "", 1, NOW * 1000, NOW * 1000 + 2500 end
  FireEvent("UNIT_SPELLCAST_START", "player")
  assert(bar._w == 100, "barre plus large que les cadres sans familier (C46)")
  pet.IsVisible = function() return true end
  FireEvent("UNIT_SPELLCAST_START", "player")
  assert(bar._w == 160, "barre sans la place du familier affiche")
  Z.headers = oldHeaders
  UnitCastingInfo = function() end
  FireEvent("UNIT_SPELLCAST_STOP", "player")
  for _, f in ipairs(later) do f() end later = {}
  -- anneau autour du curseur
  UnitCastingInfo = function() return "Soins", "", 1, NOW * 1000, NOW * 1000 + 2500 end
  Z.db.castIndicator = "RING" Z:Refresh()
  CURSOR_X, CURSOR_Y = 300, 200
  FireEvent("UNIT_SPELLCAST_START", "player")
  local _, ring = Z:CastIndicator()
  assert(ring and ring:IsShown() and not bar:IsShown(), "anneau")
  RunUpdates()
  assert(ring._point and ring._point[4] == 300 and ring._point[5] == 200, "anneau loin du curseur")
  FireEvent("UNIT_SPELLCAST_STOP", "player")
  for _, f in ipairs(later) do f() end later = {}
  assert(not ring:IsShown(), "anneau reste affiche")
  -- interrupteur : plus rien n'ecoute mes sorts
  Z.db.castIndicator = "OFF" Z:Refresh()
  FireEvent("UNIT_SPELLCAST_START", "player")
  assert(not ring:IsShown() and not bar:IsShown(), "indicateur affiche alors que coupe")
  CURSOR_X, CURSOR_Y = nil, nil
  C_Timer.After, C_Spell.GetSpellCooldown = oldAfter, nil
  UnitCastingInfo, UnitCastingDuration, Enum.StatusBarTimerDirection = nil, nil, nil
  -- options
  local labels = table.concat(Z:OptionLabels(), "|")
  assert(labels:find("Recharge globale et incantation", 1, true), "option absente")
  CheckChapters()
  for k, v in pairs(saved) do Z.db[k] = v end
  Z:Refresh()
end)

step("etape 17 : copie d'une partie d'un profil, champ de bataille et arene", function()
  Z.db.profiles, Z.db.autoProfiles, Z.db.activeProfile, Z.db.autoProfile = {}, {}, "", false
  -- chaque reglage d'un profil a sa partie, celle du chapitre ou il se regle
  local parts = {}
  for _, part in ipairs(Z.profileParts) do parts[part] = true end
  for key in pairs(Z.defaults) do
    local part = Z.ProfilePart(key)
    if Z.notInProfile[key] then assert(part == nil, "hors profil mais classe : " .. key)
    else assert(parts[part], "partie inconnue pour " .. key .. " : " .. tostring(part)) end
  end
  assert(Z.ProfilePart("width") == "Disposition" and Z.ProfilePart("placement") == nil and Z.ProfilePart("layout") == "Disposition")
  assert(Z.ProfilePart("shape") == "Apparence" and Z.ProfilePart("theme") == "Apparence" and Z.ProfilePart("rangeAlpha") == "Apparence")
  assert(Z.ProfilePart("showIncoming") == "Vie et portée" and Z.ProfilePart("farHint") == "Vie et portée")
  assert(Z.ProfilePart("showRole") == "Joueurs" and Z.ProfilePart("privateAuraSize") == "Affaiblissements")
  assert(Z.ProfilePart("hotSwipe") == "Mes soins" and Z.ProfilePart("cornerSpells") == "Mes soins" and Z.ProfilePart("missingBuffs") == "Joueurs")
  assert(Z.ProfilePart("perfMode") == "Disposition", "mode performance")
  assert(Z.ProfilePart("clicks") == nil and Z.ProfilePart("castIndicator") == nil and Z.ProfilePart("windowTheme") == nil, "hors profil")
  -- deux profils, puis copie des Cadres seulement
  Z.db.width, Z.db.shape, Z.db.showRole, Z.db.hotSwipe = 120, "BAR", false, false
  assert(Z:SaveProfile("Arene"))
  Z.db.width, Z.db.shape, Z.db.showRole, Z.db.hotSwipe = 90, "TILE", true, true
  assert(Z:SaveProfile("Raid") and Z.db.activeProfile == "Raid")
  local ok, message = Z:CopyProfileParts("Arene", "Raid", {})
  assert(not ok and message:find("au moins une partie"), "aucune partie")
  assert(not Z:CopyProfileParts("Raid", "Raid", { Disposition = true }), "meme profil")
  assert(not Z:CopyProfileParts("Inconnu", "Raid", { Disposition = true }), "profil inconnu")
  -- vers le profil en cours : applique tout de suite
  ok, message = Z:CopyProfileParts("Arene", "Raid", { Disposition = true })
  assert(ok and message:find("Arene", 1, true), "copie : " .. tostring(message))
  assert(Z.db.width == 120 and Z.db.shape == "TILE" and Z.db.showRole == true, "seulement les cadres, en direct")
  -- depuis le profil en cours : ses reglages du moment ; vers un profil enregistre : rien ne bouge a l'ecran
  Z.db.showRole = false
  assert(Z:CopyProfileParts("Raid", "Arene", { Joueurs = true, ["Mes soins"] = true }))
  assert(Z.db.profiles.Arene.showRole == false and Z.db.profiles.Arene.hotSwipe == true and Z.db.profiles.Arene.shape == "BAR")
  assert(Z.db.profiles.Arene.width == 120 and Z.db.width == 120)
  -- un profil ancien sans un reglage : la valeur d'origine
  Z.db.profiles.Arene.hotCountdown = nil
  assert(Z:CopyProfileParts("Arene", "Raid", { ["Mes soins"] = true }) and Z.db.hotCountdown == Z.defaults.hotCountdown)
  -- champ de bataille et arene
  assert(Z.Situation() == "5" and Z.PvPKind() == nil)
  INSTANCE_TYPE = "pvp" assert(Z.Situation() == "BG")
  -- 1.44.0 : pas d'arene sur WoW Forever, une arene compterait comme un champ de bataille
  INSTANCE_TYPE = "arena" assert(Z.Situation() == "BG" and Z.PvPKind() == "BG")
  assert(Z.SituationLabel("BG") == "champ de bataille" and Z.SituationLabel("25") == "25 joueurs")
  INSTANCE_TYPE = "none"
  Z.db.autoProfile = true
  Z:ProfileRules(1)["5"] = "Raid"
  FireEvent("PLAYER_ENTERING_WORLD")
  assert(Z.db.activeProfile == "Raid")
  -- champ de bataille sans choix : la regle de la taille du groupe
  INSTANCE_TYPE = "pvp" FireEvent("ZONE_CHANGED_NEW_AREA")
  assert(Z.db.activeProfile == "Raid", "champ de bataille sans choix : taille du groupe")
  INSTANCE_TYPE = "none" FireEvent("PLAYER_ENTERING_WORLD")
  Z:ProfileRules(1).BG = "Arene"
  INSTANCE_TYPE = "arena" FireEvent("PLAYER_ENTERING_WORLD")
  assert(Z.db.activeProfile == "Arene" and Z.db.shape == "BAR", "champ de bataille : son profil " .. tostring(Z.db.activeProfile) .. " " .. tostring(Z.db.shape))
  -- 2e specialisation sans choix pour le champ de bataille : celui de la 1re avant la taille du groupe
  SPEC_GROUP = 2 Z:ProfileRules(2)["5"] = "Raid" FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  assert(Z.db.activeProfile == "Arene", "2e specialisation : champ de bataille de la 1re")
  SPEC_GROUP = 1 FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  INSTANCE_TYPE = "none" FireEvent("PLAYER_ENTERING_WORLD")
  -- chapitre Profils et partage : 10 cases (5 situations, 2 specialisations), fenetre de copie
  Z:ToggleOptions("Profils et partage")
  local page = OptionPart("profileCells")
  assert(page and #page.profileCells == 10, "cases du tableau")
  local bg = page.profileCells[9]
  assert(bg.size == "BG" and bg.group == 1 and bg.label:GetText() == "Arene", "case champ de bataille")
  assert(page.profileCells[10].label:GetText() == "comme 1", "2e specialisation sans choix")
  OptionPart("copyButton").copyButton:Run("OnClick", "LeftButton")
  local w = Z:ProfileCopyWindow()
  assert(w and w:IsShown(), "fenetre de copie")
  assert(w.from.label and w.parts.Apparence, "fenetre complete")
  Z.db.shape = "SQUARE"
  w.parts.Apparence:Run("OnClick")
  w.copy:Run("OnClick")
  assert(Z.db.profiles.Arene.shape == "SQUARE" and w.result:GetText():find("copi"), "copie depuis la fenetre : " .. tostring(w.result:GetText()))
  w:Close()
  Z:ToggleOptions()
  Z.db.profiles, Z.db.autoProfiles, Z.db.activeProfile, Z.db.autoProfile = {}, {}, "", false
  Z:ResetAll()
end)

step("revue 1.23.1 : le mode test a 40 montre des cases reduites comme un vrai raid", function()
  local width, shrink = Z.db.width, Z.db.autoShrink
  Z.db.width, Z.db.autoShrink = 100, true
  Z:TogglePreview(40)
  assert(Z.previewActive and Z.CellSize() == 70, "40 faux joueurs : 70 % et non " .. tostring(Z.CellSize()))
  Z:TogglePreview(25) assert(Z.CellSize() == 85, "25 faux joueurs : 85 %")
  Z:TogglePreview(5) assert(Z.CellSize() == 100, "5 faux joueurs : taille normale")
  Z:TogglePreview()
  assert(not Z.previewActive and Z.CellSize() == (GetNumGroupMembers() > 10 and 85 or 100), "hors mode test : le vrai groupe")
  Z.db.width, Z.db.autoShrink = width, shrink
  Z:Refresh()
end)

step("revue 1.23.2 : fin du combat et journal vide", function()
  -- une action remise à la fin du combat qui échoue n'empêche pas les autres
  COMBAT = true
  local done = {}
  Z:Safe("a", function() error("panne") end)
  Z:Safe("b", function() done.b = true end)
  Z:Safe("c", function() done.c = true end)
  COMBAT = false
  Z.db.errors = {} Z.firstError = nil
  FireEvent("PLAYER_REGEN_ENABLED")
  assert(done.b and done.c, "une action en erreur a bloque les suivantes")
  assert(#Z.db.errors == 1 and Z.db.errors[1].message:find("panne", 1, true), "l'erreur doit etre notee au journal")
  -- vider le journal efface aussi la premiere erreur de la session
  Z:ClearLog()
  assert(Z.firstError == nil and #Z.db.errors == 0)
  assert(Z:BugReport():find("Aucune erreur technique", 1, true), "erreur effacee encore signalee")
end)

step("revue 1.23.3 : appel Pret relance, oeil hors de vue qui change de joueur", function()
  local b for _, x in ipairs(Z.buttons) do if x.unit and x.unit ~= "player" and x:IsVisible() and not x.extra then b = x break end end
  assert(b, "case d'un autre joueur")
  -- un appel relancé moins de 5 s après la fin du premier garde ses réponses
  local oldAfter, later = C_Timer.After, {}
  C_Timer.After = function(_, f) later[#later + 1] = f end
  FireEvent("READY_CHECK") FireEvent("READY_CHECK_FINISHED")
  FireEvent("READY_CHECK")
  for _, f in ipairs(later) do f() end
  assert(b.readyCheck and b.center:IsShown(), "le minuteur du premier appel a efface le second")
  later = {} FireEvent("READY_CHECK_FINISHED")
  for _, f in ipairs(later) do f() end
  C_Timer.After = oldAfter
  assert(not b.readyCheck, "reponses jamais effacees apres le dernier appel")
  -- l'œil hors de vue ne suit pas la case quand le jeu la donne à un autre joueur
  Z.db.losHint = true
  C_Timer.After = function() end
  Z.MarkOutOfSight(b)
  C_Timer.After = oldAfter
  assert(b.losUntil, "oeil absent")
  local unit = b.unit
  b:SetAttribute("unit", "player") b:SetAttribute("unit", unit)
  assert(not b.losUntil, "oeil reste sur la case donnee a un autre joueur")
  Z.db.losHint = Z.defaults.losHint
  Z:Refresh() RunUpdates()
end)

step("1.24.1 : icones d'auras dessinees par le jeu (conteneurs), en combat, hors combat, groupe de toute taille", function()
  -- faux conteneurs du jeu : ils notent les filtres recus et refusent ce que le vrai jeu refuse
  local oldCreate, oldSecrets, oldPlay = CreateFrame, C_Secrets, PlaySound
  CreateFrame = function(kind, name, parent, template)
    if kind == "AuraContainer" then
      assert(not COMBAT, "conteneur cree en combat (refuse par le jeu)")
    end
    local f = oldCreate(kind, name, parent, template)
    -- niveaux de cadre retenus (le faux client les ignore) : le premier plan doit passer devant les conteneurs
    function f:SetFrameLevel(level) self.level = level end
    function f:GetFrameLevel() return self.level or 1 end
    if kind ~= "AuraContainer" then return f end
    assert(template == "LyoruneAuraBox", "modele du conteneur")
    f.groups, f.slots, f.updates = {}, {}, 0
    function f:AddAuraGroup(key, filter, options)
      assert(self.unit, "groupe ajoute avant SetUnit")
      assert(not self.enabled, "groupe ajoute apres SetEnabled")
      assert(options.templateNames[1]:match("^LyoruneAura%u") and options.maxFrameCount >= 1 and options.layout.elementWidth)
      self.groups[key] = { filter = filter, candidates = options.candidateFilters or {}, max = options.maxFrameCount,
        size = options.layout.elementWidth }
      options.initializeFrame(oldCreate("Button", nil, self)) -- le jeu habille un bouton
    end
    function f:AddAuraSlot(key, filter, options)
      assert(self.unit and not self.enabled, "place fixe ajoutee dans le mauvais ordre")
      local button = oldCreate("Button", nil, self)
      self.slots[key] = { filter = filter, button = button, candidates = options.candidateFilters or {} }
      options.initializeFrame(button)
      return button
    end
    function f:SetEnabled(on)
      assert(not COMBAT, "SetEnabled en combat (refuse par le jeu)")
      self.enabled = on
    end
    function f:SetUnit(unit) self.unit = unit end
    function f:UpdateAllAuras() self.updates = self.updates + 1 end
    -- passage a la ligne et sens des rangees (1.27.0)
    function f:SetFlowLayoutMaximumLineSize(size) self.maxLine = size end
    function f:SetFlowLayoutAnchorPoint(point) self.flowPoint = point end
    return f
  end
  AuraContainerSortMethod = { Default = 0 } AuraContainerSortDirection = { Normal = 0 }
  AnchorUtil = { FlowDirection = { Right = 1, Left = 2, Up = 3, Down = 4 }, FlowLayoutAxis = { Horizontal = 1, Vertical = 2 } }
  Enum.CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 1 }
  local secret = false
  C_Secrets = { ShouldAurasBeSecret = function() return secret end }
  local read = {}
  local oldGet = C_UnitAuras.GetUnitAuras
  C_UnitAuras.GetUnitAuras = function(unit, filter, ...) read[filter] = true return oldGet(unit, filter, ...) end
  local made = {}
  Z.boxWrap = nil
  local function finish()
    Z.boxWrap = nil
    CreateFrame, C_Secrets, PlaySound, C_UnitAuras.GetUnitAuras = oldCreate, oldSecrets, oldPlay, oldGet
    AuraContainerSortMethod, AuraContainerSortDirection, AnchorUtil = nil, nil, nil
    Enum.CustomAuraButtonDispelTypeTextureStyle = nil
    Z.db.cornerSpells = {} Z.db.extraTracked = {} Z.db.ignoredNames = {} Z.db.showHots = true Z.db.soundDispel = false
    COMBAT = false AURAS = {}
    for _, button in ipairs(made) do pcall(button.SetAttribute, button, "unit", nil) end
  end
  local function NewCell(index, unit)
    local b = CreateFrame("Button", "LyoruneHeaderUnitButton" .. index, Z.header)
    Z.header:InitButton(b:GetName())
    made[#made + 1] = b
    if unit then b:SetAttribute("unit", unit) end
    return b
  end
  local ok, err = pcall(function()
    AURAS = {}
    local b = NewCell(30, "player")
    assert(b.boxes, "conteneurs non crees")
    local hots, slots, debuffs = b.boxes.hots, b.boxes.slots, b.boxes.debuffs
    assert(hots.unit == "player" and slots.unit == "player" and hots.enabled and hots.updates > 0, "conteneurs sans joueur")
    -- mes soins suivis, par numero de sort
    local g = hots.groups.hots
    assert(g.filter == "HELPFUL|PLAYER" and g.candidates.includeSpellIDs[139], "Renovation absente du filtre des soins")
    assert(slots.slots.dispel.filter == "HARMFUL|RAID", "bordure de dissipation")
    assert(slots.slots.boss.candidates.isBossAura == true, "grande icone : auras de boss")
    assert(debuffs.groups.dispellable.filter == "HARMFUL|RAID", "affaiblissement a dissiper en premier")
    -- 1.32.1 : les autres = le contraire exact (!RAID), sans exclusion par type (ni trou, ni doublon)
    assert(debuffs.groups.others.filter == "HARMFUL|!RAID", "rangee des autres : " .. tostring(debuffs.groups.others.filter))
    assert(not (debuffs.groups.others.candidates or {}).excludeDispelTypes, "exclusion par type restee")
    -- tous les rangs d'un sort suivi, verifies par leur nom dans le jeu
    local oldName = C_Spell.GetSpellName
    C_Spell.GetSpellName = function(id)
      if id == 6074 then return "Rénovation" elseif id == 6075 then return "Autre sort" end
      return oldName(id)
    end
    Z:BuildData() Z:Refresh()
    C_Spell.GetSpellName = oldName
    assert(b.boxes.hots.groups.hots.candidates.includeSpellIDs[6074], "rang 2 de Renovation absent")
    assert(not b.boxes.hots.groups.hots.candidates.includeSpellIDs[6075], "numero au mauvais nom garde")
    Z:BuildData() Z:Refresh()
    hots, slots, debuffs = b.boxes.hots, b.boxes.slots, b.boxes.debuffs
    -- reglages inchanges : aucune reconstruction
    Z:Refresh()
    assert(b.boxes.hots == hots, "conteneurs refaits sans raison")
    -- un coin prend le sort, qui quitte la rangee (reconstruction hors combat)
    Z.db.cornerSpells = { PRIEST = { TOPLEFT = "Rénovation" } } Z:Refresh()
    assert(b.boxes.hots ~= hots and not hots:IsShown(), "ancien conteneur encore montre")
    hots, slots, debuffs = b.boxes.hots, b.boxes.slots, b.boxes.debuffs
    assert(slots.slots.TOPLEFT.filter == "HELPFUL|PLAYER" and slots.slots.TOPLEFT.candidates.includeSpellIDs[139], "coin")
    assert(not hots.groups.hots.candidates.includeSpellIDs[139], "sort du coin reste dans la rangee")
    assert(not slots.slots.TOPRIGHT, "coin vide actif")
    -- interrupteur : rien a montrer
    Z.db.showHots = false Z:Refresh()
    assert(not b.boxes.hots.groups.hots and not b.boxes.bars.groups.bars, "soins affiches malgre l'interrupteur")
    Z.db.showHots = true Z:Refresh()
    assert(b.boxes.hots.groups.hots.max == Z.HotCount() and Z.HotCount() == 3, "soins non rallumes") -- 4 places : 3 soins, Ame affaiblie
    -- liste par nom ou par numero : le numero tape sert tout de suite
    Z.db.ignoredNames = { ["12345"] = true } Z:Refresh()
    assert(b.boxes.debuffs.groups.others.candidates.excludeSpellIDs[12345], "affaiblissement ignore par son numero")
    -- un nom de ma liste vu hors combat : son numero est retenu et le filtre mis a jour
    Z.db.extraTracked = { ["Mon sort"] = true }
    AURAS["HELPFUL|PLAYER"] = { { name = "Mon sort", icon = 1, auraInstanceID = 99, spellId = 4242 } }
    Z.UpdateAurasNow(b)
    RunUpdates()
    assert(Z.db.auraIds["Mon sort"][4242], "numero non retenu")
    assert(b.boxes.hots.groups.hots.candidates.includeSpellIDs[4242], "filtre non mis a jour avec le numero appris")
    -- son de dissipation hors combat, une seule fois
    local sounds = 0
    PlaySound = function() sounds = sounds + 1 end
    Z.db.soundDispel = true
    AURAS["HARMFUL|RAID"] = { { name = "Mal", icon = 4, auraInstanceID = 22, spellId = 98 } }
    Z.UpdateAurasNow(b) Z.UpdateAurasNow(b)
    assert(sounds == 1, "son de dissipation : " .. sounds)

    -- placement des elements : la grande icone (bouton protege) refait les conteneurs, la rangee de soins
    -- (conteneur libre) se deplace sans reconstruction
    local kept = b.boxes.slots
    Z.SetOffset("big", 6, -3) Z:Refresh()
    assert(b.boxes.slots ~= kept, "grande icone deplacee sans reconstruction")
    kept = b.boxes.hots
    Z.SetOffset("hots", 4, -2) Z:Refresh()
    assert(b.boxes.hots == kept, "conteneur refait pour un simple deplacement")
    Z.SetOffset("big", 0, 0) Z.SetOffset("hots", 0, 0) Z:Refresh()
    -- taille d'une rangee ou de la grande icone (1.27.0) : boutons refaits, en combat seulement a la fin du combat ;
    -- en attendant, le conteneur garde la longueur de ligne de ses boutons d'avant
    kept = b.boxes.hots
    local keptSlots, line, before = b.boxes.slots, b.boxes.hots.maxLine, b.boxes.hots.groups.hots.size
    COMBAT = true
    Z.SetElementSize("hots", 150) Z.SetElementSize("big", 120) Z:Refresh()
    assert(b.boxes.hots == kept and b.boxes.slots == keptSlots, "conteneurs refaits en combat")
    assert(b.boxes.hots.maxLine == line, "ligne du conteneur changee avant ses boutons")
    COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
    assert(b.boxes.hots ~= kept and b.boxes.hots.groups.hots.size > before, "taille des soins non appliquee apres le combat ")
    assert(b.boxes.slots ~= keptSlots, "grande icone : taille non appliquee apres le combat")
    Z.SetElementSize("hots", 100) Z.SetElementSize("big", 100) Z:Refresh()
    assert(Z.db.placement[Z.db.shape] == nil, "taille d'origine : entree effacee")
    -- reglage des icones (decompte) : applique par reconstruction
    kept = b.boxes.hots
    Z.db.hotCountdown = not Z.db.hotCountdown Z:Refresh()
    assert(b.boxes.hots ~= kept, "decompte change sans reconstruction")
    Z.db.hotCountdown = not Z.db.hotCountdown Z:Refresh()
    -- nombre d'icones regle par le joueur : conteneurs refaits hors combat
    Z.db.hotCount, Z.db.debuffCount = 6, 4 Z:Refresh()
    assert(b.boxes.hots.groups.hots.max == 5 and b.boxes.bars.groups.bars.max == 5 and b.boxes.hots.groups.lockouts.max == 1,
      "nombre de soins non applique") -- 6 places : 5 soins, Ame affaiblie (pretre)
    assert(b.boxes.debuffs.groups.dispellable.max == Z.db.dispelCount and b.boxes.debuffs.groups.others.max == 3, "nombre d'affaiblissements")
    Z.db.hotCount, Z.db.debuffCount = 4, 2 Z:Refresh()
    assert(b.boxes.debuffs.groups.others.max == 1, "nombre d'affaiblissements non remis")
    -- 1.27.0 (etape 21) : icones a la mesure de la forme, passees au jeu ; Carre : le jeu passe a la ligne
    assert(Z.boxWrap == true, "passage a la ligne du jeu non detecte")
    local form = {}
    for _, key in ipairs({ "shape", "width", "height", "fontSize", "powerHeight" }) do form[key] = Z.db[key] end
    Z:ApplyShape("SQUARE")
    local rows = Z.AuraRows()
    assert(rows.hots.lines == 2 and b.boxes.hots.maxLine == rows.hots.perLine * (rows.hots.size + 2),
      "Carre : rangee de soins sur deux lignes : " .. tostring(b.boxes.hots.maxLine))
    assert(b.boxes.hots.groups.hots.size == rows.hots.size and b.boxes.debuffs.groups.dispellable.size == rows.debuffs.size
      and b.boxes.debuffs.groups.others.size == rows.debuffs.size, "taille des icones donnee au jeu")
    kept = b.boxes.hots
    Z:ApplyShape("BAR")
    assert(b.boxes.hots ~= kept, "forme changee sans reconstruction (taille des icones)")
    assert(b.boxes.hots.flowPoint == "TOPRIGHT" and b.boxes.hots._point[1] == "TOPRIGHT" and b.boxes.hots._point[2] == b.hp,
      "Barre : soins colles au haut de la barre de vie, a droite")
    assert(b.boxes.debuffs.flowPoint == "BOTTOMRIGHT" and b.boxes.debuffs._point[2] == b.hp, "Barre : affaiblissements")
    assert(b.boxes.hots.groups.hots.size == Z.AuraRows().hots.size, "Barre : taille des soins")
    for key, value in pairs(form) do Z.db[key] = value end
    Z:Refresh()
    assert(b.boxes.hots.flowPoint == "TOPLEFT" and b.boxes.hots._point[2] == b.over, "Tuile : soins en haut a gauche de la case")
    -- le nom et la vie restent lisibles : au-dessus des conteneurs, sous les auras privees
    local level = b.top:GetFrameLevel()
    for _, box in pairs(b.boxes) do assert(box:GetFrameLevel() < level, "conteneur au-dessus du nom") end
    assert(b.name:GetParent() == b.top and b.text:GetParent() == b.top, "textes hors du premier plan")

    -- EN COMBAT : auras secretes, Lyorune ne lit plus rien, le jeu affiche tout
    COMBAT = true FireEvent("PLAYER_REGEN_DISABLED")
    secret = true read = {}
    Z.UpdateAurasNow(b)
    assert(not read["HARMFUL"] and not read["HELPFUL|PLAYER"], "lecture tentee alors que le jeu cache les auras")
    assert(not b.hots[1] or not b.hots[1]:IsShown(), "ancienne icone affichee avec les conteneurs")
    assert(b.boxes.hots:IsShown() and b.boxes.debuffs:IsShown(), "conteneurs caches en combat")
    -- la case change de joueur en combat : les conteneurs suivent (SetUnit permis)
    b:SetAttribute("unit", "party1")
    assert(b.boxes.hots.unit == "party1" and b.boxes.debuffs.unit == "party1", "conteneurs restes sur l'ancien joueur")
    -- reglage change en combat : rien n'est cree, la reconstruction attend la fin du combat
    local kept = b.boxes.hots
    Z.db.ignoredNames = { ["12345"] = true, ["777"] = true } Z:Refresh()
    assert(b.boxes.hots == kept, "conteneur refait en combat")
    -- le groupe grandit en combat : les nouvelles cases attendent la fin du combat, sans erreur
    local late = NewCell(31, "party2")
    assert(not late.boxes, "conteneur cree en combat")
    COMBAT = false secret = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
    assert(late.boxes and late.boxes.hots.unit == "party2" and late.boxes.hots.enabled, "case arrivee en combat jamais construite")
    assert(b.boxes.debuffs.groups.others.candidates.excludeSpellIDs[777], "reglage du combat non applique ensuite")

    -- RAID DE 40 : chaque case a ses conteneurs, sur son joueur
    for i = 1, 40 do NewCell(40 + i, "raid" .. i) end
    for i = 1, 40 do
      local cell = made[#made - 40 + i]
      assert(cell.boxes and cell.boxes.hots.unit == "raid" .. i and cell.boxes.slots.enabled, "raid" .. i .. " sans conteneurs")
    end
    -- case videe : conteneurs caches
    b:SetAttribute("unit", nil)
    assert(not b.boxes.hots:IsShown() and not b.boxes.debuffs:IsShown(), "conteneur sans joueur encore montre")
    b:SetAttribute("unit", "player")
    assert(b.boxes.debuffs:IsShown() and b.boxes.debuffs.unit == "player", "case remplie : conteneurs non rallumes")
    Z.DiagnoseAuras() -- /lyorune auras decrit les conteneurs sans erreur
    for _, e in ipairs(Z.db.errors or {}) do
      assert(e.kind ~= "Conteneur d'auras" and e.kind ~= "filtres des auras" and e.kind ~= "conteneurs d'auras",
        "journal : " .. tostring(e.message))
    end
  end)
  finish()
  assert(ok, err)
end)

step("1.24.1 : mana basse des soigneurs, bouclier a la suite de la vie", function()
  local b = CreateFrame("Button", "LyoruneHeaderUnitButton95", Z.header)
  Z.header:InitButton(b:GetName())
  local oldRole, oldBars = UnitGroupRolesAssigned, Z.db.manaBars
  local ok, err = pcall(function()
    Z.db.manaBars = "OFF" -- l'icone marche sans la barre de mana
    b:SetAttribute("unit", "party1")
    Z:Refresh()
    -- soigneur : la boisson suit la courbe du jeu, les evenements de mana sont ecoutes
    assert(b.lowManaShown and b.lowMana:IsShown() and b.powerListen, "boisson absente sur un soigneur")
    assert(b.lowMana:GetAlpha() == 1, "opacite non donnee par la courbe")
    assert(not b.powerShown, "barre de mana affichee malgre le reglage")
    -- pas soigneur : rien
    UnitGroupRolesAssigned = function() return "DAMAGER" end
    Z:Refresh()
    assert(not b.lowMana:IsShown() and not b.powerListen, "boisson sur un joueur qui ne soigne pas")
    UnitGroupRolesAssigned = oldRole
    -- reglage sur « Non »
    Z.db.lowManaHealers = 0 Z:Refresh()
    assert(not b.lowMana:IsShown(), "boisson affichee malgre « Non »")
    Z.db.lowManaHealers = 20 Z:Refresh()
    -- changement de joueur : l'icone ne reste pas sur la case
    b:SetAttribute("unit", nil)
    assert(not b.lowMana:IsShown() and not b.lowManaShown, "boisson restee sur une case vide")
    b:SetAttribute("unit", "party1") Z:Refresh()
    assert(b.lowMana:IsShown(), "boisson non revenue")
    -- bouclier : bande en bas, ou a la suite de la vie avec le trait du bouclier en trop
    assert(not b.overAbsorb:IsShown(), "trait du bouclier en trop en style bande")
    Z.db.absorbStyle = "FOLLOW" Z:Refresh()
    assert(b.overAbsorb:IsShown(), "trait du bouclier en trop absent")
    Z.cellUpdates.prediction(b)
    Z.db.showAbsorb = false Z:Refresh()
    assert(not b.overAbsorb:IsShown(), "trait affiche sans bouclier")
    Z.db.showAbsorb, Z.db.absorbStyle = true, "BAND" Z:Refresh()
    assert(not b.overAbsorb:IsShown(), "trait reste en style bande")
    -- options, recherche et placement
    local labels = table.concat(Z:OptionLabels(), "|")
    for _, label in ipairs({ "Mana basse des soigneurs", "Place du bouclier" }) do
      assert(labels:find(label, 1, true), "absent de la recherche : " .. label)
    end
    assert(Z.IsPlaceElement("lowMana"), "boisson absente de l'editeur de placement")
  end)
  UnitGroupRolesAssigned, Z.db.manaBars = oldRole, oldBars
  Z.db.lowManaHealers, Z.db.absorbStyle, Z.db.showAbsorb = 20, "BAND", true
  b:SetAttribute("unit", nil)
  Z:Refresh()
  assert(ok, err)
end)

step("C7 : barre de ressource selon la classe (rage, energie, forme du druide)", function()
  local b = CreateFrame("Button", "LyoruneHeaderUnitButton94", Z.header)
  Z.header:InitButton(b:GetName())
  local oldRole, oldBars = UnitGroupRolesAssigned, Z.db.manaBars
  local ok, err = pcall(function()
    Z.db.manaBars = "ALL"
    UnitGroupRolesAssigned = function() return "TANK" end
    -- guerrier : sa rage, en rouge, pas une barre de mana bleue
    POWER_TYPE, POWER_TOKEN = 1, "RAGE"
    b:SetAttribute("unit", "party1") Z:Refresh()
    assert(b.powerShown and b.powerType == 1, "rage absente")
    assert(b.power._barColor[1] == 1 and b.power._barColor[3] == 0, "rage pas en rouge")
    -- druide qui passe en félin : l'événement du jeu suffit, énergie en jaune
    POWER_TYPE, POWER_TOKEN = 3, "ENERGY"
    FireEvent("UNIT_DISPLAYPOWER", "party1")
    assert(b.powerType == 3 and b.power._barColor[2] == 1 and b.power._barColor[3] == 0, "forme de felin pas suivie")
    -- retour en forme humaine : la mana, avec la teinte choisie
    POWER_TYPE, POWER_TOKEN = nil, nil
    FireEvent("UNIT_DISPLAYPOWER", "party1")
    assert(b.powerType == 0 and b.power._barColor[3] == Z.manaColors.BLUE[3], "mana pas revenue")
    -- un nouveau thème ou une autre texture garde la couleur de la ressource
    POWER_TYPE, POWER_TOKEN = 3, "ENERGY"
    FireEvent("UNIT_DISPLAYPOWER", "party1") Z:Refresh()
    assert(b.power._barColor[3] == 0, "couleur de l'energie perdue au rafraichissement")
    -- « Soigneurs » : seulement la mana des soigneurs
    Z.db.manaBars = "HEALERS" Z:Refresh()
    assert(not b.powerShown, "barre d'un tank avec « Soigneurs »")
    -- changement de joueur : la ressource du joueur d'avant ne reste pas
    POWER_TYPE, POWER_TOKEN = nil, nil
    UnitGroupRolesAssigned = function() return "HEALER" end
    b:SetAttribute("unit", nil) b:SetAttribute("unit", "party2") Z:Refresh()
    assert(b.powerShown and b.powerType == 0 and b.power._barColor[3] == Z.manaColors.BLUE[3], "ressource du joueur d'avant")
    -- réponse secrète : la mana, sans erreur
    SECRET = true POWER_TYPE, POWER_TOKEN = 1, "RAGE"
    FireEvent("UNIT_DISPLAYPOWER", "party2")
    SECRET = false
    assert(b.powerType == 0, "type secret mal lu")
    -- réponse secrète sans ressource connue : celle de la classe (un guerrier garde sa rage, pas la mana)
    local oldClass = UnitClass
    UnitClass = function() return "Guerrier", "WARRIOR" end
    b.powerType, b.powerToken = nil, nil
    SECRET = true
    FireEvent("UNIT_DISPLAYPOWER", "party2")
    SECRET = false
    UnitClass = oldClass
    assert(b.powerType == 1 and b.power._barColor[3] == 0, "guerrier en mana quand la ressource est secrete")
    -- sortie de combat : la ressource relue (le guerrier redevient ce que dit le jeu)
    POWER_TYPE, POWER_TOKEN = nil, nil
    FireEvent("PLAYER_REGEN_ENABLED")
    assert(b.powerType == 0, "ressource pas relue a la sortie de combat")
    -- mode test : le guerrier et le voleur d'exemple ont leur rage et leur énergie
    Z.db.manaBars = "ALL" Z:Refresh()
    Z:TogglePreview(10)
    local cells = Z:PreviewCells(10)
    assert(cells[1].powerType == 1 and cells[1].power._barColor[1] == 1 and cells[1].power._barColor[3] == 0, "guerrier d'exemple en mana")
    assert(cells[6].powerType == 3 and cells[6].power._barColor[3] == 0, "voleur d'exemple en mana")
    assert(cells[2].powerType == 0 and cells[2].power._barColor[3] == Z.manaColors.BLUE[3], "pretre d'exemple sans mana")
    Z:TogglePreview()
    -- druides d'exemple (cases 3, 12, 21, 30 du raid) : félin en dégâts, mana en soin, ours en tank, mana en dégâts
    Z:TogglePreview(40)
    cells = Z:PreviewCells(40)
    assert(cells[3].powerType == 3, "druide felin d'exemple sans energie")
    assert(cells[12].powerType == 0, "druide soigneur d'exemple sans mana")
    assert(cells[21].powerType == 1 and cells[21].power._barColor[3] == 0, "druide tank d'exemple sans rage")
    assert(cells[30].powerType == 0, "druide en forme humaine d'exemple sans mana")
    Z:TogglePreview()
  end)
  POWER_TYPE, POWER_TOKEN, SECRET = nil, nil, false
  UnitGroupRolesAssigned, Z.db.manaBars = oldRole, oldBars
  b:SetAttribute("unit", nil)
  Z:Refresh()
  assert(ok, err)
end)

step("securite : codes et messages abimes", function()
  -- des milliers de codes abîmés : jamais d'erreur, jamais de valeur hors des limites, jamais de texte libre
  Z.SetOffset("name", 3, -2) Z.SetOffset("debuffs", -40, 12, "BAR") -- des placements dans le code abîmé aussi
  local saved = Z:Export()
  local seed = 12345
  local function rand(n) seed = (seed * 1103515245 + 12345) % 2147483648 return seed % n + 1 end
  local alphabet = "Lyorune2;=%.snbc0123456789ABCDEFtrue-|\n\0\255 #@/"
  local function noise(len) local t = {} for i = 1, len do local k = rand(#alphabet) t[i] = alphabet:sub(k, k) end return table.concat(t) end
  for i = 1, 3000 do
    local code
    if i % 3 == 0 then code = "Lyorune2;" .. noise(rand(80))
    elseif i % 3 == 1 then local at = rand(#saved) code = saved:sub(1, at) .. noise(rand(10)) .. saved:sub(at + rand(20))
    else code = noise(rand(200)) end
    local ok, err = pcall(Z.Import, Z, code)
    assert(ok, "import : " .. tostring(err) .. " pour " .. code)
  end
  for key, value in pairs(Z.defaults) do
    local current, limit = Z.db[key], Z.limits[key]
    assert(type(current) == type(value), "type change : " .. key)
    if limit and type(current) == "number" then assert(current >= limit[1] and current <= limit[2], "hors limites : " .. key) end
    if Z.choices[key] then
      local found for _, c in ipairs(Z.choices[key]) do if c[1] == current then found = true end end
      assert(found, "choix inconnu : " .. key .. " = " .. tostring(current))
    end
  end
  local limit = Z.limits.placement
  for shape, elements in pairs(Z.db.placement) do
    assert(Z.shapes[shape] and type(elements) == "table", "forme inconnue dans le placement : " .. tostring(shape))
    for key, at in pairs(elements) do
      assert(Z.IsPlaceElement(key), "element inconnu : " .. tostring(key))
      for i = 1, 2 do assert(type(at[i]) == "number" and at[i] >= limit[1] and at[i] <= limit[2], "placement hors limites : " .. key) end
    end
  end
  assert(Z.db.manaText == Z.defaults.manaText or Z.db.manaText == "x", "texte libre modifie : " .. Z.db.manaText)
  for _, spell in pairs(Z:GetClicks()) do assert(type(spell) ~= "string" or not spell:find("%c") or Z.IsMacro(spell) or spell:find("^@macro:"), "commande cachee dans un clic") end
  -- messages entre joueurs abîmés : jamais d'erreur
  for i = 1, 2000 do
    local text = (i % 2 == 0 and "C:" or i % 3 == 0 and "V:" or "") .. noise(rand(255))
    local ok, err = pcall(FireEvent, "CHAT_MSG_ADDON", "Lyorune", text, "WHISPER", "Joueur" .. rand(50))
    assert(ok, "message : " .. tostring(err))
  end
  assert(Z:Import(saved))
  assert(select(1, Z.Offset("name")) == 3 and Z.db.placement.BAR.debuffs[1] == -40, "placements partages")
  Z.db.placement = {} Z:Refresh()
end)

step("refonte 1.26.0, lot 1 : briques de la fenetre a chapitres", function()
  local UI = Z.UI
  local saved = { showFocus = Z.db.showFocus, horizontal = Z.db.horizontal, width = Z.db.width }
  local function Get(key) return function() return Z.db[key] end end
  local function Set(key) return function(value) Z.db[key] = value end end
  local function Choices(key) local t = {} for _, c in ipairs(Z.choices[key]) do t[#t + 1] = { c[1], Z.L[c[2]] } end return t end
  local function Build()
    local w = {}
    w.switch = UI.Switch(UIParent, "Familiers", Get("showFocus"), Set("showFocus"))
    w.seg = UI.Segmented(UIParent, "Sens", Choices("horizontal"), Get("horizontal"), Set("horizontal"))
    w.side = UI.SideButton(UIParent, 4, "Disposition", function(self) self.clicked = true end)
    w.fold = UI.Fold(UIParent, "essai", 3)
    w.scroll = UI.Scroll(UIParent)
    return w
  end
  -- Chaque brique, créée dans chaque thème et en contraste élevé, ou créée avant et repeinte au changement
  local early = Build()
  Z.db.showFocus, Z.db.horizontal = false, false
  for _, look in ipairs({ "MODERN", "CLASSIC", "MMO", "CONTRAST" }) do
    Z.db.windowTheme, Z.db.highContrast = look == "CONTRAST" and "MODERN" or look, look == "CONTRAST"
    Z:Refresh()
    local kit = UI.Kit()
    for _, w in ipairs({ early, Build() }) do
      local sw = w.switch
      sw:Update()
      assert(sw.track:IsShown() == (kit == "MODERN") and sw.knob:IsShown() == (kit == "MODERN" or kit == "FLAT"), look .. " : rail de l'interrupteur")
      assert(sw.box:IsShown() == (kit ~= "MODERN"), look .. " : case de l'interrupteur")
      assert(sw.box._tex == (kit == "CLASSIC" and UI.GAME.checkBox or kit == "MMO" and UI.SKIN.MMO.box or UI.WHITE), look .. " : allure de l'interrupteur")
      assert(sw.mark:IsShown() == ((kit == "CLASSIC" or kit == "MMO") and sw.on), look .. " : marque")
      w.seg:Update()
      for _, b in ipairs(w.seg.segments) do
        local layers = b.layers or {}
        assert(b.pill:IsShown() == (b.selected and kit == "MODERN"), look .. " : pastille du choix")
        assert(b.bg:IsShown() == (b.selected and kit == "FLAT"), look .. " : fond du choix")
        assert((layers.gameUp and layers.gameUp:IsShown() or false) == (b.selected and kit == "CLASSIC"), look .. " : bouton du jeu")
        assert((layers.plate and layers.plate:IsShown() or false) == (b.selected and kit == "MMO"), look .. " : plaque doree")
      end
      assert(w.seg.strip.round:IsShown() == (kit == "MODERN"), look .. " : cadre des choix")
      w.side:SetActive(true)
      assert(w.side.border:IsShown() and w.side.round:IsShown() == (kit == "MODERN") and w.side.bg:IsShown() == (kit ~= "MODERN"), look .. " : chapitre ouvert")
      local strong = (kit == "CLASSIC" or kit == "MMO") and UI.gold or UI.text
      assert(w.side.label._color[1] == strong[1], look .. " : nom du chapitre ouvert")
      w.side:SetActive(false)
      assert(not w.side.border:IsShown() and w.side.label._color[1] == UI.dim[1], look .. " : chapitre ferme")
      assert(w.side.label._font == (kit == "MMO" and UI.skins.MMO.headFont or STANDARD_TEXT_FONT), look .. " : police du chapitre")
    end
  end
  Z.db.windowTheme, Z.db.highContrast = "MODERN", false Z:Refresh()

  -- Interrupteur : écrit le réglage, la pastille glisse (sauf en animations réduites) et prend l'accent
  local sw = UI.Switch(UIParent, "Familiers", Get("showFocus"), Set("showFocus"))
  sw:Run("OnClick")
  assert(Z.db.showFocus == true and sw.on and sw.slide:IsPlaying(), "interrupteur")
  assert(sw.knob._color[1] == UI.accent[1] and sw.confirm:IsPlaying(), "interrupteur allume")
  Z.db.reduceMotion = true
  sw:Run("OnClick")
  assert(Z.db.showFocus == false and not sw.slide:IsPlaying() and sw.knob._color[1] == UI.dim[1], "interrupteur en animations reduites")
  Z.db.reduceMotion = false
  -- Une case à cocher garde son allure d'avant
  local check = UI.Check(UIParent, "essai", Get("showFocus"), Set("showFocus"))
  assert(not check.track and check.box._w == 16, "case a cocher changee")

  -- Choix côte à côte : écrit le réglage, un seul choix sélectionné
  local seg = UI.Segmented(UIParent, "Sens", Choices("horizontal"), Get("horizontal"), Set("horizontal"))
  assert(#seg.segments == 2 and seg.segments[1].selected and seg.segments[1].label:GetText() == "En colonnes")
  seg.segments[2]:Run("OnClick")
  assert(Z.db.horizontal == true and seg.segments[2].selected and not seg.segments[1].selected, "choix cote a cote")
  assert(seg.segments[2].label._color[1] == UI.bg[1] and seg.segments[1].label._color[1] == UI.dim[1], "texte des choix")

  -- Nombre : flèches, molette, saisie directe ramenée aux limites et au pas
  local lo, hi, pas = unpack(Z.limits.width)
  Z.db.width = 86
  local st = UI.Stepper(UIParent, "Largeur", lo, hi, pas, Get("width"), Set("width"))
  assert(st.value:GetText() == "86" and st.value:GetObjectType() == "EditBox")
  st.value.HasFocus = function() return true end -- valeur active (clic dessus) : la molette la change
  st.value:Run("OnMouseWheel", 1) assert(Z.db.width == 86 + pas, "molette vers le haut")
  st.value:Run("OnMouseWheel", -1) st.value:Run("OnMouseWheel", -1) assert(Z.db.width == 86 - pas, "molette vers le bas")
  st.plus:Run("OnClick") assert(Z.db.width == 86, "fleche +")
  st.value:SetText("97") st.value:Run("OnEnterPressed") assert(Z.db.width == 98, "saisie ramenee au pas : " .. Z.db.width)
  st.value:SetText("9999") st.value:Run("OnEnterPressed") assert(Z.db.width == hi, "saisie au-dela du maximum")
  st.value:SetText("abc") st.value:Run("OnEnterPressed") assert(Z.db.width == hi and st.value:GetText() == tostring(hi), "saisie illisible")
  st.value:SetText("-5") st.value:Run("OnEnterPressed") assert(Z.db.width == lo, "saisie sous le minimum")
  st.value:Run("OnMouseWheel", -1) assert(Z.db.width == lo, "molette sous le minimum")
  assert(Z.L["Clic : saisir la valeur au clavier, ou l'ajuster à la molette. Maj + molette : la changer sans clic."] and st.value:GetScript("OnEnter"))

  -- Rune des réglages changés : visible seulement si la valeur diffère de Z.defaults, clic = valeur d'installation
  local rune = UI.ChangedRune(st, "width", Get("width"), Set("width"))
  assert(rune:IsShown() and st.changed == rune, "rune d'un reglage change")
  rune:Run("OnEnter") assert(GameTooltip:GetText() == "Rétablir : " .. Z.defaults.width, GameTooltip:GetText())
  rune:Run("OnClick")
  assert(Z.db.width == Z.defaults.width and not rune:IsShown() and st.value:GetText() == tostring(Z.defaults.width), "retablir")
  st.plus:Run("OnClick") assert(rune:IsShown(), "la rune suit le nombre")
  rune:Run("OnClick")
  local swRune = UI.ChangedRune(sw, "showFocus", Get("showFocus"), Set("showFocus"))
  assert(not swRune:IsShown()) sw:Run("OnClick") assert(swRune:IsShown(), "la rune suit l'interrupteur")
  swRune:Run("OnEnter") assert(GameTooltip:GetText() == "Rétablir : Coupé", GameTooltip:GetText())
  swRune:Run("OnClick") assert(Z.db.showFocus == Z.defaults.showFocus and not sw.on, "interrupteur retabli")
  local segRune = UI.ChangedRune(seg, "horizontal", Get("horizontal"), Set("horizontal"))
  segRune:Run("OnEnter") assert(GameTooltip:GetText() == "Rétablir : En colonnes", GameTooltip:GetText())
  segRune:Run("OnClick") assert(Z.db.horizontal == false and seg.segments[1].selected, "choix retabli")
  assert(UI.Same({ 1, { a = 2 } }, { 1, { a = 2 } }) and not UI.Same({ 1 }, { 1, 2 }) and not UI.Same({}, false))

  -- Réglages fins repliables : l'état est gardé pour le personnage
  Z.char.optionFolds = nil
  local opened
  local fold = UI.Fold(UIParent, "essai", 3, function(open) opened = open end)
  assert(not fold:IsOpen() and fold.label:GetText() == "Réglages fins (3)")
  fold:Run("OnClick")
  assert(fold:IsOpen() and opened == true and Z.char.optionFolds.essai and fold.label:GetText() == "Masquer les réglages fins (3)")
  assert(UI.Fold(UIParent, "essai", 3):IsOpen() and not UI.Fold(UIParent, "autre", 2):IsOpen(), "etat des reglages fins oublie")
  fold:Run("OnClick") assert(not fold:IsOpen() and opened == false and Z.char.optionFolds.essai == nil)

  -- Page qui défile : molette, limites, barre cachée sans défilement, poignée à glisser, aucune boucle au repos
  local scroll = UI.Scroll(UIParent)
  scroll:SetSize(300, 200) scroll.bar:SetHeight(200)
  scroll:Run("OnSizeChanged", 300, 200)
  assert(scroll.content:GetWidth() == 300 - 14, "largeur du contenu")
  scroll:SetContentHeight(600)
  assert(scroll:Range() == 400 and scroll.bar:IsShown())
  scroll:Run("OnMouseWheel", -1) assert(scroll.offset == 40, "molette")
  scroll:Run("OnMouseWheel", 1) scroll:Run("OnMouseWheel", 1) assert(scroll.offset == 0, "au-dessus du haut")
  scroll:ScrollTo(9999) assert(scroll.offset == 400, "au-dela du bas")
  scroll:ScrollTo(0)
  CURSOR_Y = 300 scroll.thumb:Run("OnMouseDown", "LeftButton")
  assert(scroll.thumb:GetScript("OnUpdate"), "poignee tenue")
  CURSOR_Y = 250 scroll.thumb:Run("OnUpdate", 0.01)
  assert(scroll.offset > 100 and scroll.offset < 200, "poignee glissee : " .. scroll.offset)
  scroll.thumb:Run("OnMouseUp", "LeftButton")
  assert(not scroll.thumb:GetScript("OnUpdate") and not scroll:GetScript("OnUpdate"), "boucle restee active")
  CURSOR_Y = nil
  scroll:SetContentHeight(100) assert(scroll.offset == 0 and not scroll.bar:IsShown(), "page courte")
  assert(scroll.thumb.tex._color[1] == UI.gold[1], "barre aux couleurs du theme")

  -- Bouton de chapitre : clic, pastille du nombre de réglages changés
  local side = UI.SideButton(UIParent, 4, "Disposition", function(self) self.clicked = true end)
  assert(not side.badge:IsShown())
  side:SetCount(3) assert(side.badge:IsShown() and side.badge.text:GetText() == "3" and side.tip:find("3 réglages", 1, true) and side.tip:find("choisis par vous", 1, true))
  side:SetCount(1) assert(side.tip:find("1 réglage différent", 1, true), "pastille au singulier")
  side:SetCount(0) assert(not side.badge:IsShown() and not side.tip)
  side:Run("OnClick") assert(side.clicked)

  for _, key in ipairs({ "Réglages fins (%d)", "Masquer les réglages fins (%d)", "Activé", "Coupé", "Rétablir : %s",
    "Rétablir comme à l'installation", "1 réglage différent de l'installation, choisi par vous. Une rune d'or le marque dans le chapitre.",
    "%d réglages différents de l'installation, choisis par vous. Une rune d'or les marque dans le chapitre.", "Clic : saisir la valeur au clavier, ou l'ajuster à la molette. Maj + molette : la changer sans clic." }) do
    assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
  end
  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
end)

step("refonte 1.26.0, lot 2 : fenetre a chapitres, defilement, recherche", function()
  local saved = { windowTheme = Z.db.windowTheme, highContrast = Z.db.highContrast }
  Z:ToggleOptions("Accueil")
  local w = Z:OptionsWindow()
  local chapters = w.chapters
  -- Douze chapitres dans la barre latérale, dans l'ordre de la maquette, textes traduits
  local names = { "Accueil", "Disposition", "Apparence", "Vie et portée", "Mes soins", "Affaiblissements", "Joueurs",
    "Sorts et raccourcis", "Alertes", "Profils et partage", "Fenêtre et aide", "Les amis de Lyorune" }
  local missing, inChapters = {}, {}
  local function Need(text) if text and not Z.translations.enUS[text] then missing[#missing + 1] = text end end
  for i, chapter in ipairs(chapters) do
    assert(chapter.name == names[i], "chapitre " .. i .. " : " .. chapter.name)
    assert(chapter.button and chapter.rune >= 1 and chapter.rune <= 24, "bouton du chapitre " .. chapter.name)
    Need(chapter.name) Need(chapter.intro)
    for _, section in ipairs(chapter.sections) do
      Need(section[1])
      for _, item in ipairs(section[2]) do
        Need(item.desc)
        local kind = item[1]
        if kind == "check" or kind == "seg" or kind == "step" or kind == "cycle" then
          assert(Z.defaults[item[2]] ~= nil, "reglage inconnu : " .. item[2])
          inChapters[item[2]] = chapter.name
          assert(kind ~= "seg" or (#Z.choices[item[2]] >= 2 and #Z.choices[item[2]] <= 4), "trop de choix cote a cote : " .. item[2])
          if item.dep then assert(Z.defaults[item.dep[1]] ~= nil, "reglage parent inconnu : " .. item.dep[1]) end
        end
      end
    end
  end
  Need("Parties à copier : les réglages du chapitre du même nom.")
  Need("Copier seulement une partie d'un profil vers un autre : un ou plusieurs chapitres, de Disposition à Joueurs.")
  assert(#missing == 0, "sans traduction anglaise : " .. table.concat(missing, " | "))

  -- Chaque réglage a une seule ligne, dans un seul chapitre ; aucun réglage simple n'est oublié
  local keys = Z:OptionKeys()
  for key, where in pairs(keys) do assert(#where == 1, "reglage en double : " .. key .. " (" .. table.concat(where, ", ") .. ")") end
  for key, chapter in pairs(inChapters) do assert(keys[key] and keys[key][1] == chapter, "reglage sans ligne : " .. key) end
  local elsewhere = { tutorialDone = true, wizardDone = true, minimapAngle = true, macroAutoTarget = true } -- réglés ailleurs
  for key, value in pairs(Z.defaults) do
    if (type(value) == "boolean" or type(value) == "number" or Z.choices[key]) and not elsewhere[key] then
      assert(keys[key], "reglage absent des options : " .. key)
    end
  end
  for _, e in ipairs(Z.db.errors) do assert(not tostring(e.message):find("^option"), "erreur dans les options : " .. tostring(e.message)) end

  -- Anciens noms d'onglet acceptés (tutoriel, guides) ; un seul chapitre visible, un seul bouton allumé ; le
  -- chapitre ouvert est retenu pendant la partie, pas sauvé
  Z:ToggleOptions("Disposition") Z:ToggleOptions() Z:ToggleOptions()
  assert(Z:OptionChapter() == "Disposition" and not Z.char.optionChapter, "la fenetre rouvre le dernier chapitre de la partie")
  for old, new in pairs({ Cadres = "Disposition", Indicateurs = "Vie et portée", Soins = "Mes soins", Listes = "Affaiblissements",
    Profils = "Profils et partage", Aide = "Fenêtre et aide", Clics = "Sorts et raccourcis", Inconnu = "Accueil" }) do
    Z:ToggleOptions(old)
    assert(Z:OptionChapter() == new, old .. " -> " .. tostring(Z:OptionChapter()))
    local shown, lit = 0, 0
    for _, chapter in ipairs(chapters) do
      if chapter.page and chapter.page.scroll:IsShown() then shown = shown + 1 end
      if chapter.button.active then lit = lit + 1 end
    end
    assert(shown == 1 and lit == 1, old .. " : " .. shown .. " pages, " .. lit .. " boutons")
  end

  -- Chaque chapitre s'ouvre sans erreur dans les 3 thèmes et en contraste élevé, et sa page est rangée
  for _, theme in ipairs({ "CLASSIC", "MMO", "MODERN" }) do
    Z.db.windowTheme = theme Z:Refresh()
    for i = 1, #chapters do assert(w.Select(i) == chapters[i].page, theme .. " : " .. chapters[i].name) end
  end
  Z.db.highContrast = true Z:Refresh()
  for i = 1, #chapters do w.Select(i) end
  Z.db.highContrast = false Z:Refresh()
  CheckChapters()

  -- Réglages fins repliés sous « Réglages fins (n) » ; l'état est gardé pour le personnage
  Z.char.optionFolds = {}
  local page = w.Select("Mes soins")
  local fold, fade
  for _, part in ipairs(page.parts) do
    if part.item and part.item[2] == "hotFade" then fade = part fold = part.fold end
  end
  assert(fold and fold.count == 5 and not fold:IsOpen() and not fade.widget:IsShown(), "reglages fins replies")
  local closed = page.used
  fold:Run("OnClick")
  assert(fold:IsOpen() and fade.widget:IsShown() and page.used > closed and Z.char.optionFolds["Mes soins.1"], "reglages fins deplies")
  fold:Run("OnClick")
  assert(not fade.widget:IsShown() and page.used == closed, "reglages fins replies de nouveau")

  -- Recherche : par le nom, puis par l'explication ; un résultat ouvre le chapitre, déplie, fait défiler
  w.Select("Accueil")
  w.search:SetText("moment de relancer") w.search:Run("OnTextChanged", true)
  local row = w.results.rows[1]
  assert(w.results:IsShown() and row:IsShown() and row.entry.label == "Icône qui s'efface à la fin", "recherche par l'explication")
  row:Run("OnClick", "LeftButton")
  assert(Z:OptionChapter() == "Mes soins" and fold:IsOpen() and fade.widget:IsShown(), "le resultat deplie les reglages fins")
  assert(page.scroll.offset > 0 and w.found == row.entry and w.search:GetText() == "", "le resultat fait defiler la page")
  fold:Run("OnClick")
  w.search:SetText("ajouter un clic") w.search:Run("OnTextChanged", true)
  w.results.rows[1]:Run("OnClick", "LeftButton")
  assert(Z:OptionChapter() == "Sorts et raccourcis", "reglage d'une page dessinee a part")

  -- Fenêtre de 1080 x 708, jamais plus haute que l'écran moins 60 pixels
  assert(w:GetWidth() == 1080 and Z.OptionsHeight(1080) == 708 and Z.OptionsHeight(700) == 640 and Z.OptionsHeight(nil) == 708, "hauteur")

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
  w:Hide()
end)

step("refonte 1.26.0, lot 3a : listes dans leurs chapitres, clics et alertes en une colonne", function()
  local saved = { extraTracked = Z.db.extraTracked, manaText = Z.db.manaText }
  Z.db.extraTracked = {}
  Z.char.optionFolds = {}
  Z:ToggleOptions("Accueil")
  local w = Z:OptionsWindow()
  -- Chaque liste dans son chapitre ; plus aucune page à deux colonnes pour les listes, les clics et les alertes
  local where, boxes = { pinned = "Disposition", extraTracked = "Mes soins", ignoredNames = "Affaiblissements", importantNames = "Affaiblissements" }, {}
  for _, chapter in ipairs(w.chapters) do
    local page = w.Select(chapter.name)
    for _, part in ipairs(page.parts) do
      local widget = part.widget
      if widget.chips then boxes[widget.key] = { box = widget, part = part, chapter = chapter.name } end
      if chapter.name == "Sorts et raccourcis" or chapter.name == "Alertes" or chapter.name == "Affaiblissements" then
        assert(not widget.isBlock, "page a deux colonnes : " .. chapter.name)
      end
    end
  end
  for key, chapter in pairs(where) do assert(boxes[key] and boxes[key].chapter == chapter, "liste " .. key .. " hors de " .. chapter) end
  assert(boxes.pinned.part.fold and not boxes.extraTracked.part.fold, "joueurs epingles dans les reglages fins")

  -- Un nom tapé puis Entrée entre dans la liste, qui s'allonge avec la page ; un clic sur un nom le retire
  local tracked = boxes.extraTracked.box
  local page = w.Select("Mes soins")
  local before, used = tracked:GetHeight(), page.used
  for _, name in ipairs({ "Sort A", "Sort B", "Sort C", "Sort D" }) do
    tracked.edit:SetText(name) tracked.edit:Run("OnEnterPressed")
  end
  assert(Z.db.extraTracked["Sort D"] and tracked.edit:GetText() == "", "ajout a la liste")
  assert(tracked:GetHeight() > before and page.used > used, "la liste et la page s'allongent")
  local found
  for _, choice in ipairs(Z.CornerChoices("TOPLEFT")) do if choice[1] == "Sort C" then found = true end end
  assert(found, "sort suivi absent du choix des coins")
  assert(tracked.chips[1].name == "Sort A") tracked.chips[1]:Run("OnClick", "LeftButton")
  assert(not Z.db.extraTracked["Sort A"] and not tracked.chips[4]:IsShown() and tracked:GetHeight() == before and page.used == used, "retrait d'un nom")

  -- La recherche trouve une liste rangée dans les réglages fins : chapitre ouvert, réglages fins dépliés
  w.search:SetText("joueurs épinglés") w.search:Run("OnTextChanged", true)
  local hit
  for _, row in ipairs(w.results.rows) do if row:IsShown() and row.entry.list == "pinned" then hit = row end end
  assert(hit, "liste des joueurs epingles introuvable")
  hit:Run("OnClick", "LeftButton")
  assert(Z:OptionChapter() == "Disposition" and boxes.pinned.part.fold:IsOpen() and boxes.pinned.box:IsShown(), "recherche d'une liste")
  boxes.pinned.part.fold:Run("OnClick")

  -- Alertes et Clics : chaque réglage a sa ligne dans son chapitre ; le texte d'une annonce s'écrit dans la page
  local keys = Z:OptionKeys()
  for _, key in ipairs({ "alertChannel", "manaAlert", "manaThreshold", "regenAlert", "regenThreshold", "resAlert", "soundDispel", "soundMana" }) do
    assert(keys[key] and keys[key][1] == "Alertes", "Alertes : " .. key)
  end
  for _, key in ipairs({ "castOnDown", "autoRes", "clicksPerSpec", "newSpellAlert", "clickConflictAlert", "externalClicks", "actionBarMacros" }) do
    assert(keys[key] and keys[key][1] == "Sorts et raccourcis", "Sorts et raccourcis : " .. key)
  end
  page = w.Select("Alertes")
  local text
  for _, part in ipairs(page.parts) do if part.widget.test and not text then text = part.widget end end
  assert(text and text.edit:GetText() == Z.db.manaText, "texte de l'annonce de mana")
  text.edit:SetText("Mana basse {mana}") text.edit:Run("OnTextChanged", true)
  assert(Z.db.manaText == "Mana basse {mana}", "texte de l'annonce enregistre")

  -- Plus aucun texte des chapitres ne cite un ancien onglet (l'onglet de /macro est celui du jeu)
  for _, chapter in ipairs(w.chapters) do
    for _, section in ipairs(chapter.sections) do
      for _, item in ipairs(section[2]) do
        for _, value in pairs(item) do
          if type(value) == "string" then
            assert(not value:gsub("onglet de votre personnage", ""):find("onglet"), "ancien onglet cite : " .. value)
          end
        end
      end
    end
  end

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
  w:Hide()
end)

step("refonte 1.26.0, lot 3b : profils et aide en une colonne, Accueil", function()
  local saved = { width = Z.db.width, showFocus = Z.db.showFocus, syncEnabled = Z.db.syncEnabled, profiles = Z.db.profiles,
    activeProfile = Z.db.activeProfile }
  Z.char.optionFolds = {}
  Z:ToggleOptions("Accueil")
  local w = Z:OptionsWindow()
  -- Plus aucune page à deux colonnes : chaque ligne tient dans la colonne
  for _, chapter in ipairs(w.chapters) do
    local page = w.Select(chapter.name)
    assert(page.blocks == nil, "page a deux colonnes : " .. chapter.name)
    for _, part in ipairs(page.parts) do assert(part.widget:GetWidth() <= 520, "ligne trop large dans " .. chapter.name) end
  end
  local keys = Z:OptionKeys()
  for _, key in ipairs({ "autoProfile", "syncEnabled", "resSync", "acceptConfigs", "versionNotice" }) do
    assert(keys[key] and #keys[key] == 1 and keys[key][1] == "Profils et partage", "Profils et partage : " .. key)
  end

  -- Synchronisation coupée : les trois réglages qui en dépendent sont grisés
  local page = w.Select("Profils et partage")
  local sync = page.content.settings
  Z.db.syncEnabled = true
  sync.syncEnabled:Run("OnClick")
  assert(not Z.db.syncEnabled and sync.resSync:GetAlpha() < 1 and sync.versionNotice:GetAlpha() < 1, "synchronisation coupee : reglages grises")
  sync.syncEnabled:Run("OnClick")
  assert(Z.db.syncEnabled and sync.resSync:GetAlpha() == 1, "synchronisation remise")

  -- Un profil enregistré depuis la page devient le profil actif de l'Accueil ; son bouton mène aux profils
  Z.db.profiles, Z.db.activeProfile = {}, ""
  local box = OptionPart("copyButton")
  box.edit:SetText("Essai") box.edit:Run("OnEnterPressed")
  assert(Z.db.profiles.Essai and Z.db.activeProfile == "Essai", "profil enregistre depuis la page")
  page = w.Select("Accueil")
  local home = {}
  for _, part in ipairs(page.parts) do
    if part.widget.go then home.profile = part.widget end
    if part.widget.rows then home.changed = part.widget end
  end
  assert(home.profile and home.profile.name:GetText() == "Essai", "profil actif a l'Accueil")
  home.profile.go:Run("OnClick", "LeftButton")
  assert(Z:OptionChapter() == "Profils et partage", "bouton vers les profils")

  -- Réglages changés : un réglage changé a sa ligne ; un clic mène au réglage (réglages fins dépliés), la rune le rétablit
  Z.db.width, Z.db.showFocus = Z.defaults.width, Z.defaults.showFocus
  w.Select("Accueil")
  local before = home.changed.count
  assert(home.changed.empty:IsShown() == (before == 0), "liste vide annoncee")
  Z.db.width, Z.db.showFocus = Z.defaults.width + 4, not Z.defaults.showFocus
  w.Select("Accueil")
  assert(home.changed.count == before + 2 and not home.changed.empty:IsShown(), "deux reglages changes")
  local function Row(key)
    for _, row in ipairs(home.changed.rows) do if row:IsShown() and row.key == key then return row end end
  end
  local row = Row("showFocus")
  assert(row and row.where:GetText() == "Disposition" and row.rune:IsShown(), "ligne du reglage change")
  assert(row.value:GetText() == (Z.db.showFocus and "Activé" or "Coupé"), "valeur du reglage : " .. tostring(row.value:GetText()))
  assert(Row("width").value:GetText() == tostring(Z.defaults.width + 4), "valeur d'un nombre")
  row:Run("OnClick", "LeftButton")
  assert(Z:OptionChapter() == "Disposition" and w.found and w.found.key == "showFocus", "clic : aller au reglage")
  local fold = w.found.widget.part.fold
  assert(fold and fold:IsOpen(), "reglage fin deplie")
  fold:Run("OnClick")
  w.Select("Accueil")
  Row("showFocus").rune:Run("OnClick")
  assert(Z.db.showFocus == Z.defaults.showFocus and home.changed.count == before + 1 and not Row("showFocus"), "la rune retablit le reglage")
  Row("width").rune:Run("OnClick")
  assert(Z.db.width == Z.defaults.width and home.changed.count == before, "la liste se vide")

  -- Fenêtre et aide : légende et commandes en lignes, retrouvées par la recherche
  page = w.Select("Fenêtre et aide")
  local commands
  for _, part in ipairs(page.parts) do if part.widget.list then commands = part.widget end end
  assert(commands and commands.list:GetText():find("/lyorune diag", 1, true), "liste des commandes")
  w.search:SetText("donner ma config") w.search:Run("OnTextChanged", true)
  assert(w.results.rows[1]:IsShown() and w.results.rows[1].entry.label == "Donner ma configuration", "recherche d'un outil de partage")
  w.results.rows[1]:Run("OnClick", "LeftButton")
  assert(Z:OptionChapter() == "Profils et partage", "recherche : chapitre des profils")

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
  w:Hide()
end)

step("refonte 1.26.0, lot 4a : rune sur chaque ligne, pastilles, retablir une page, reglages dependants", function()
  local keys = { "showHots", "hotCount", "hotStyle", "frameAlpha", "manaBars", "powerHeight", "syncEnabled" }
  local saved = {}
  for _, key in ipairs(keys) do saved[key] = Z.db[key] end
  for _, key in ipairs(keys) do Z.db[key] = Z.defaults[key] end
  Z.char.optionFolds = {}
  Z:ToggleOptions("Mes soins")
  local w = Z:OptionsWindow()
  local chapters = Z:OptionsTabs()
  local function Chapter(name) for _, c in ipairs(chapters) do if c.name == name then return c end end end

  -- Chaque ligne de réglage porte sa rune d'or, cachée tant que le réglage est celui de l'installation (une ligne
  -- repliée se met à jour en s'affichant : on regarde les lignes affichées, chapitre ouvert)
  Z:OptionLabels()
  for _, chapter in ipairs(chapters) do
    w.Select(chapter.name)
    for key, widget in pairs(chapter.page.content.settings or {}) do
      if Z.defaults[key] ~= nil then
        assert(widget.changed, "rune absente : " .. key)
        assert(not widget:IsShown() or widget.changed:IsShown() == not Z.UI.Same(Z.db[key], Z.defaults[key]), "rune mal montree : " .. key)
      end
    end
  end
  assert(Chapter("Accueil").page.reset == nil, "pas de Retablir cette page a l'Accueil")

  -- Un réglage changé depuis sa ligne : rune montrée, pastille du chapitre, « Rétablir cette page » paraît
  local soins, look = Chapter("Mes soins"), Chapter("Apparence")
  local page = w.Select("Mes soins")
  local set = page.content.settings
  local count = soins.button.count
  assert(not page.reset:IsShown() == (count == 0), "Retablir cette page suit les reglages changes")
  set.hotCount.plus:Run("OnClick", "LeftButton")
  assert(Z.db.hotCount == Z.defaults.hotCount + 1 and set.hotCount.changed:IsShown(), "rune d'un nombre change")
  assert(soins.button.count == count + 1 and soins.button.badge:IsShown(), "pastille du chapitre")
  assert(page.reset:IsShown() and page.used > 64, "Retablir cette page montre")

  -- Réglages dépendants : grisés quand le réglage parent est coupé, toujours réglables
  set.showHots:Run("OnClick")
  assert(not Z.db.showHots and set.hotCount:GetAlpha() < 1 and set.hotStyle:GetAlpha() < 1, "dependants grises")
  assert(soins.button.count == count + 2, "pastille : deux reglages")
  set.hotCount.minus:Run("OnClick", "LeftButton")
  assert(Z.db.hotCount == Z.defaults.hotCount and not set.hotCount.changed:IsShown(), "un reglage grise reste reglable")
  set.showHots.changed:Run("OnClick")
  assert(Z.db.showHots and set.hotCount:GetAlpha() == 1 and soins.button.count == count, "la rune retablit et le grisage suit")
  local vie = w.Select("Vie et portée").content.settings
  Z.db.manaBars = "OFF" w.Select("Vie et portée")
  assert(vie.powerHeight:GetAlpha() < 1, "dependance « tout sauf » : barre de mana coupee")
  Z.db.manaBars = "HEALERS" w.Select("Vie et portée")
  assert(vie.powerHeight:GetAlpha() == 1, "dependance « tout sauf » : barre de mana montree")
  Z.db.manaBars = Z.defaults.manaBars
  -- Contraste élevé : il remplace le thème et la texture, qui sont grisés (retour d'essai 10)
  local style = w.Select("Apparence").content.settings
  assert(style.theme:GetAlpha() == 1 and style.texture:GetAlpha() == 1 and style.theme.desc, "theme et texture reglables")
  style.highContrast:Run("OnClick")
  assert(Z.db.highContrast and style.theme:GetAlpha() < 1 and style.texture:GetAlpha() < 1, "contraste eleve : theme et texture grises")
  style.highContrast:Run("OnClick")
  assert(not Z.db.highContrast and style.theme:GetAlpha() == 1, "contraste coupe : theme regle de nouveau")

  -- « Rétablir cette page » : deux clics (le premier arme le bouton), et seulement ce chapitre
  Z.db.frameAlpha = Z.defaults.frameAlpha - 10
  page = w.Select("Mes soins")
  set.showHots:Run("OnClick")
  set.hotCount.plus:Run("OnClick", "LeftButton")
  local others = look.changes
  assert(others >= 1 and soins.changes >= 2, "reglages changes dans deux chapitres")
  page.reset.button:Run("OnClick", "LeftButton")
  assert(not Z.db.showHots, "premier clic : rien n'est retabli")
  page.reset.button.armed = true -- le faux client lance les minuteries tout de suite : second clic dans les 4 secondes
  page.reset.button:Run("OnClick", "LeftButton")
  assert(Z.db.showHots == Z.defaults.showHots and Z.db.hotCount == Z.defaults.hotCount, "page retablie")
  assert(soins.changes == 0 and soins.button.count == 0 and not soins.button.badge:IsShown(), "pastille a zero")
  assert(not page.reset:IsShown() and not set.hotCount.changed:IsShown() and set.hotCount:GetAlpha() == 1, "page rangee apres retablissement")
  assert(Z.db.frameAlpha == Z.defaults.frameAlpha - 10 and look.changes == others, "les autres chapitres ne bougent pas")

  -- Changement fait fenêtre fermée (commande, profil) : la pastille suit à la réouverture
  w:Hide()
  Z.db.frameAlpha = Z.defaults.frameAlpha
  Z:ToggleOptions()
  assert(look.changes == others - 1, "pastille revue a l'ouverture")

  -- Boutons de bijou du chapitre Sorts et raccourcis : cachés sauf réglage fin allumé ou bijou déjà choisi
  -- (retour d'essai 12), jamais un point d'interrogation
  local savedClicks, savedTrinkets = Z.db.clicks[Z:ClickSet()], Z.db.clickTrinkets
  Z.db.clicks[Z:ClickSet()] = { ["shift-1"] = "Soins rapides", ["ctrl-1"] = "Rénovation", ["2"] = "@menu" }
  Z.db.clickTrinkets = {} Z.db.trinketButtons = false
  local clickPage = w.Select("Sorts et raccourcis")
  Z.RefreshClicks()
  local _, plain = Z:ClickCell("ctrl-1")
  local _, menu = Z:ClickCell("2")
  assert(plain and not plain.trinkets[1]:IsShown() and not plain.trinkets[2]:IsShown(), "boutons de bijou caches a l'installation")
  Z:ToggleTrinket({ kind = "click", key = "shift-1" }, 1) Z.RefreshClicks()
  local _, worn = Z:ClickCell("shift-1")
  assert(worn.trinkets[1]:IsShown() and worn.trinkets[2]:IsShown(), "une ligne qui a un bijou garde ses boutons")
  assert(worn.trinkets[1].chosen:IsShown() and not worn.trinkets[2].chosen:IsShown(), "bordure d'or sur le bijou choisi")
  assert(worn.trinkets[2].icon._tex == "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket", "emplacement vide : icone du jeu")
  assert(not plain.trinkets[1]:IsShown(), "les autres lignes restent sans bijou")
  assert(clickPage.content.settings.trinketButtons, "reglage fin dans le chapitre")
  clickPage.content.settings.trinketButtons:Run("OnClick")
  assert(Z.db.trinketButtons and plain.trinkets[1]:IsShown() and not menu.trinkets[1]:IsShown(), "reglage fin : boutons sur chaque sort, pas sur le menu")
  clickPage.content.settings.trinketButtons:Run("OnClick")
  assert(not Z.db.trinketButtons and not plain.trinkets[1]:IsShown(), "reglage coupe : boutons caches")
  Z.db.clicks[Z:ClickSet()], Z.db.clickTrinkets = savedClicks, savedTrinkets
  Z:ApplyClicks()

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
  w:Hide()
end)

step("refonte 1.26.0, lot 4b : case temoin, faux groupe, boutons du mode test", function()
  local keys = { "showHots", "hotCount", "hotStyle", "showDispel", "showAbsorb", "absorbStyle", "color", "width", "height",
    "frameAlpha", "showMarker" }
  local saved = {}
  for _, key in ipairs(keys) do saved[key] = Z.db[key] end
  local savedCorners = Z.db.cornerSpells[Z.class]
  Z.db.cornerSpells[Z.class] = nil
  Z.db.hotStyle = "ICONS"
  Z:ToggleOptions("Apparence")
  local w = Z:OptionsWindow()
  local col = w.witness
  assert(col and col:IsShown(), "colonne de la case temoin")
  local cell = col.stage.cell

  -- De simples cadres, comme les fausses cases du mode test : aucun bouton protégé
  assert(cell:GetObjectType() == "Frame" and #col.group.slots == 5, "case temoin et faux groupe de cinq")
  for _, slot in ipairs(col.group.slots) do assert(slot.cell:GetObjectType() == "Frame", "fausse case du groupe") end

  -- Forme : la taille des vraies cases, agrandie pour tenir dans son fond (leçon C2 : chaque barre a ses bornes)
  Z.db.width, Z.db.height = 150, 50 Z:Refresh()
  local cw, ch = Z.CellSize()
  assert(cell:GetWidth() == cw and cell:GetHeight() == ch, "la case temoin suit la taille")
  assert(math.abs(cell:GetScale() - math.min(1.9, 226 / cw, 116 / ch)) < 0.001, "agrandie dans son fond")
  for _, bar in ipairs({ cell.hp, cell.incoming, cell.absorb, cell.healAbsorb, cell.power }) do
    assert(bar._min == 0 and bar._max == 100 and bar._value ~= nil, "barre sans bornes ou sans valeur")
  end

  -- Couleurs : couleur de la classe, ou couleur de la vie (62 %)
  Z.db.color = "CLASS" Z:Refresh()
  local r = Z.ClassColor(Z.class)
  assert(math.abs(cell.hp._barColor[1] - r) < 0.001, "couleur de classe")
  Z.db.color = "HEALTH" Z:Refresh()
  assert(math.abs(cell.hp._barColor[1] - 0.38) < 0.001, "couleur selon la vie")

  -- Soins sur la durée : jusqu'à trois, et la légende les compte
  Z.db.showHots, Z.db.hotCount = true, 3 Z:Refresh()
  assert(cell.hots[1] and cell.hots[1]:IsShown(), "soin sur la duree montre")
  assert(col.legend:GetText():find("sur la durée", 1, true), "legende des soins : " .. col.legend:GetText())
  Z.db.showHots = false Z:Refresh()
  assert(not cell.hots[1]:IsShown() and not col.legend:GetText():find("sur la durée", 1, true), "soins coupes")

  -- Coins : le carré du sort choisi, et son nom dans la légende
  Z.db.cornerSpells[Z.class] = { TOPLEFT = "Récupération" } Z:Refresh()
  assert(cell.corners and cell.corners.TOPLEFT:IsShown(), "coin montre sur la case temoin")
  assert(col.legend:GetText():find("Récupération", 1, true), "coin dans la legende")
  Z.db.cornerSpells[Z.class] = nil Z:Refresh()
  assert(not cell.corners.TOPLEFT:IsShown(), "coin retire")

  -- Dissipation, bouclier : allumés, ils se voient ; tout coupé, la case est nue
  Z.db.showDispel, Z.db.showAbsorb, Z.db.absorbStyle = true, true, "FOLLOW" Z:Refresh()
  assert(col.legend:GetText():find("dissiper", 1, true) and col.legend:GetText():find("à la suite", 1, true), "dissipation et bouclier")
  assert(cell.absorb:IsShown() and cell.absorb._value > 0, "bouclier sur la case temoin")
  Z.db.showDispel, Z.db.showAbsorb = false, false Z:Refresh()
  assert(col.legend:GetText() == Z.L["Case nue : tous les indicateurs sont coupés."], "case nue : " .. col.legend:GetText())

  -- Opacité des cadres : la case et le faux groupe, pas leur fond
  Z.db.frameAlpha = 50 Z:Refresh()
  assert(col.stage.holder:GetAlpha() == 0.5 and col.group.holder:GetAlpha() == 0.5 and col.stage:GetAlpha() == 1, "opacite")

  -- Un réglage changé depuis sa ligne redessine la case témoin (Option, puis Z:Refresh)
  local set = w.Select("Apparence").content.settings
  set.color.segments[1]:Run("OnClick", "LeftButton")
  local want = Z.db.color == "CLASS" and r or 0.38
  assert(math.abs(cell.hp._barColor[1] - want) < 0.001, "la case temoin suit la ligne de reglage")

  -- Boutons du mode test : un clic ouvre, un second clic sur le même nombre ferme
  local tens = col.test.segments[2]
  assert(tens.value == 10, "bouton 10")
  tens:Run("OnClick", "LeftButton")
  assert(Z.previewActive and Z:PreviewSize() == 10 and tens.selected, "mode test a 10")
  assert(col.testText:GetText():find("10", 1, true), "phrase du mode test ouvert")
  col.test.segments[4]:Run("OnClick", "LeftButton")
  assert(Z.previewActive and Z:PreviewSize() == 40 and col.test.segments[4].selected and not tens.selected, "passage a 40")
  col.test.segments[4]:Run("OnClick", "LeftButton")
  assert(not Z.previewActive and not col.test.segments[4].selected, "second clic : mode test ferme")
  assert(col.testText:GetText() == Z.L["Pose un faux groupe à l'écran, à la vraie taille, pour régler l'apparence en vrai."], "phrase du mode test ferme")

  -- Les boutons ont quitté Disposition ; la recherche les trouve encore
  for _, chapter in ipairs(Z:OptionsTabs()) do
    for _, section in ipairs(chapter.sections) do assert(section[1] ~= "Mode test", "Mode test encore dans " .. chapter.name) end
  end
  w.search:SetText("mode test") w.search:Run("OnTextChanged", true)
  local row = w.results.rows[1]
  assert(row and row:IsShown() and row.entry.widget == col.test, "recherche du mode test")
  row:Run("OnClick", "LeftButton")
  assert(Z:OptionChapter() == "Apparence", "la recherche change de chapitre (retour 22 : les boutons clignotent sur place)")

  -- Fenêtre fermée : rien n'est redessiné ; à la réouverture, la case témoin suit
  w:Hide() col:Hide()
  Z.db.frameAlpha = 80 Z:Refresh()
  assert(col.stage.holder:GetAlpha() == 0.5, "rien n'est redessine fenetre fermee")
  col:Show()
  assert(col.stage.holder:GetAlpha() == 0.8, "redessinee a l'ouverture")

  for key, value in pairs(saved) do Z.db[key] = value end
  Z.db.cornerSpells[Z.class] = savedCorners
  Z:Refresh()
  w:Hide()
end)

step("refonte 1.26.0, lot 5 : lumiere de soin, rune du chapitre, eclat de la case temoin", function()
  local UI = Z.UI
  local saved = { magicEffects = Z.db.magicEffects, reduceMotion = Z.db.reduceMotion, smooth = Z.db.smooth,
    windowTheme = Z.db.windowTheme, highContrast = Z.db.highContrast, showRunes = Z.db.showRunes, color = Z.db.color }
  Z.db.magicEffects, Z.db.reduceMotion, Z.db.smooth, Z.db.showRunes = true, false, true, true
  Z:ToggleOptions("Apparence")
  local w = Z:OptionsWindow()
  w:Show() w:Run("OnShow")
  local m, col = w.magic, w.witness
  local function Open(name) for _, c in ipairs(w.chapters) do if c.name == name then return c end end end

  -- Lumière de soin dans l'en-tête : un faisceau or et vert qui traverse le trait, de bout en bout
  assert(m.track:IsShown() and m.sweep:IsPlaying(), "faisceau de l'en-tete")
  assert(#m.beam.pieces == 3 and m.beam.pieces[1]._tex == "Interface\\Buttons\\WHITE8X8", "trois degrades")
  assert(UI.HEAL_GOLD[1] > UI.HEAL_GOLD[3] and UI.HEAL_GREEN[2] > UI.HEAL_GREEN[1], "or et vert")
  assert(m.beam.haze._color[1] == UI.HEAL_GOLD[1], "halo du faisceau dore")

  -- Trois thèmes et contraste élevé : la lumière reste or et vert, le trait est celui de la fenêtre en Classique
  -- et MMORPG (liseré doré), le sien en Moderne et en contraste élevé
  for _, case in ipairs({ { "MODERN", false, true }, { "CLASSIC", false, false }, { "MMO", false, false }, { "MMO", true, true } }) do
    Z.db.windowTheme, Z.db.highContrast = case[1], case[2] Z:Refresh()
    assert(m.rail:IsShown() == case[3], "trait sous l'en-tete : " .. case[1] .. (case[2] and " contraste" or ""))
    assert(m.track:IsShown() and m.sweep:IsPlaying(), "faisceau : " .. case[1])
    assert(m.beam.haze._color[1] == UI.HEAL_GOLD[1], "lumiere de soin independante du theme")
    assert(Open("Apparence").button.halo._color[2] == UI.HEAL_GOLD[2], "rune : lumiere de soin")
  end
  Z.db.windowTheme, Z.db.highContrast = "MODERN", false Z:Refresh()

  -- Rune du chapitre ouvert : sa lumière s'allume et respire ; les autres restent éteintes
  local open, other = Open("Apparence").button, Open("Disposition").button
  assert(open.active and open.halo:IsShown() and open.pulse:IsPlaying(), "rune du chapitre ouvert allumee")
  assert(not other.halo:IsShown() and not other.pulse:IsPlaying(), "rune d'un autre chapitre eteinte")
  w.Select("Disposition")
  assert(other.halo:IsShown() and other.pulse:IsPlaying() and not open.halo:IsShown() and not open.pulse:IsPlaying(),
    "la lumiere suit le chapitre ouvert")
  w.Select("Apparence")

  -- Éclat de la case témoin à chaque réglage changé, et la vie qui remonte (barres animées)
  NOW = NOW + 5
  local set = w.Select("Apparence").content.settings
  local function Change() -- l'autre couleur des barres : un vrai changement de réglage, depuis sa ligne
    for _, b in ipairs(set.color.segments) do
      if b.value ~= Z.db.color then return b:Run("OnClick", "LeftButton") end
    end
  end
  Change()
  local burst, hp = col.stage.burst, col.stage.cell.hp
  assert(burst.groups[1]:IsPlaying() and burst.groups[2]:IsPlaying(), "eclat de soin sur la case temoin")
  assert(burst.glows[1]._color[1] == UI.HEAL_GOLD[1] and burst.glows[2]._color[2] == UI.HEAL_GREEN[2], "eclat or et vert")
  assert(hp._value == 62 and hp._smoothing == Enum.StatusBarInterpolation.ExponentialEaseOut, "la vie remonte")
  for _, group in ipairs(burst.groups) do group:Stop() end
  -- Barres non animées : l'éclat, mais la vie ne bouge pas
  NOW = NOW + 5
  Z.db.smooth = false
  Change()
  assert(burst.groups[1]:IsPlaying() and hp._smoothing == nil, "vie fixe sans barres animees")
  for _, group in ipairs(burst.groups) do group:Stop() end
  Z.db.smooth = true

  -- « Effets magiques » coupé ou « Animations réduites » : plus rien ne bouge ni ne brille (les fondus courts
  -- des pages restent) ; le trait et l'inscription restent
  for _, setting in ipairs({ "magicEffects", "reduceMotion" }) do
    NOW = NOW + 5
    Z.db[setting] = setting == "reduceMotion"
    Change()
    assert(not UI.Magic(), setting)
    assert(not m.track:IsShown() and not m.sweep:IsPlaying(), setting .. " : faisceau")
    assert(not open.halo:IsShown() and not open.pulse:IsPlaying(), setting .. " : rune du chapitre")
    assert(not burst.groups[1]:IsPlaying() and hp._smoothing == nil, setting .. " : eclat de la case temoin")
    assert(m.rail:IsShown() and w.foot:IsShown(), setting .. " : traits")
    Z.db.magicEffects, Z.db.reduceMotion = true, false
    Change()
    assert(m.sweep:IsPlaying() and open.halo:IsShown() and open.pulse:IsPlaying(), setting .. " : effets revenus")
    for _, group in ipairs(burst.groups) do group:Stop() end -- en jeu, l'éclat s'éteint seul après 0,9 s
  end

  -- Fenêtre fermée : tout s'arrête ; aucun éclat sur une case témoin cachée
  w:Hide() w:Run("OnHide") open:Run("OnHide") col:Hide()
  assert(not m.sweep:IsPlaying() and not open.pulse:IsPlaying(), "effets arretes a la fermeture")
  NOW = NOW + 5
  col.Spark()
  assert(not burst.groups[1]:IsPlaying(), "eclat sur une case temoin cachee")
  col:Show()

  -- Phrase en runes : au bas de la fenêtre, au milieu de la bande sous le trait
  local strip = Z:RuneStrip()
  local p = strip._point
  assert(strip:GetParent() == w and p[1] == "BOTTOM" and p[3] < 34, "inscription au bas de la fenetre")
  assert(w.foot._point[1] == "BOTTOMRIGHT" and w.foot._point[3] == 34, "trait du bas")

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
end)

step("refonte 1.26.0, lot 6b : visite guidee et messages avec les chapitres", function()
  local UI = Z.UI
  local w = Z:OptionsWindow()
  if w:IsShown() then w:Hide() end
  local saved = { language = Z.db.language, lockMode = Z.db.lockMode, tutorialDone = Z.db.tutorialDone }

  -- Toute la visite, en français puis en anglais : plus aucun onglet, les chapitres à leur place
  local function Tour()
    local bodies = {}
    Z:StartTutorial()
    local card = LyoruneTutorial
    for i = 1, #card.runes do
      bodies[i] = card.body:GetText()
      card.next:Run("OnClick")
    end
    assert(not card:IsShown() and not w:IsShown() and not Z.previewActive, "visite mal refermee")
    return bodies
  end
  local fr = Tour()
  for i, body in ipairs(fr) do assert(not body:lower():find("onglet", 1, true), "etape " .. i .. " cite un onglet") end
  -- Lot 6c bis b : la fenêtre d'options en quatre cartes courtes (barre, page, case témoin, recherche)
  local window = table.concat(fr, "|", 7, 10)
  for _, word in ipairs({ "chapitre", "pastille", "Réglages fins", "rune d'or", "Rétablir cette page", "case témoin",
    "mode test", "recherche", "Accueil" }) do
    assert(window:find(word, 1, true), "cartes de la fenetre sans : " .. word)
  end
  assert(fr[3]:find("Bijoux avec les sorts", 1, true) and fr[4]:find("chapitre Mes soins", 1, true), "clics, coins")
  assert(fr[5]:find("partie Position", 1, true) and fr[5]:find("Cadres affichés", 1, true), "placer les cadres")
  assert(fr[6]:find("case témoin", 1, true) and fr[6]:find("second clic", 1, true), "boutons du mode test")
  assert(fr[11]:find("chapitre Sorts et raccourcis", 1, true), "derniere carte")

  Z.db.language = "enUS" Z:SetLanguage()
  local en = Tour()
  for i, body in ipairs(en) do
    -- l'étape 3 montre les sorts du joueur, avec leur nom du jeu
    assert(not body:find("%f[%a]tab%f[%A]") and (i == 3 or not body:find("[\195][\160-\191]")), "etape " .. i .. " : " .. body:sub(1, 60))
  end
  window = table.concat(en, "|", 7, 10)
  for _, word in ipairs({ "chapter", "badge", "Fine settings", "golden rune", "Reset this page", "preview cell",
    "test mode", "search", "Home" }) do
    assert(window:find(word, 1, true), "options window cards without: " .. word)
  end
  assert(en[6]:find("preview cell", 1, true) and en[11]:find("Spells and bindings chapter", 1, true))

  -- Messages du chat et textes hors options : chapitres, traduits, anciennes clés retirées
  for _, key in ipairs({ "... et %d autre(s) : chapitre Sorts et raccourcis.",
    "nouveau sort sans clic : %s. Chapitre Sorts et raccourcis des options, bouton « Attribuer ».",
    "Glissez une macro sur une ligne du chapitre Sorts et raccourcis ou dans une barre de sorts du jeu, ou cliquez sur le sort d'une ligne.",
    "plus de place pour une macro de personnage : supprimez-en une dans /macro, ou coupez l'option dans le chapitre Sorts et raccourcis.",
    "%d macro(s) créée(s) pour vos barres de sorts : chapitre Sorts et raccourcis des options, ou /macro, onglet de votre personnage.",
    "le clic pour lancer du jeu prend aussi : %s. Il peut passer avant Lyorune : changez l'un des deux (chapitre Sorts et raccourcis, ligne en orange).",
    "La synchronisation entre joueurs est coupée (chapitre Profils et partage).",
    "la synchronisation entre joueurs est coupée (chapitre Profils et partage).",
    "Mode performance : activé (chapitre Fenêtre et aide).",
    "Conseil : activez le mode performance (chapitre Fenêtre et aide) pour les grands raids.",
    "Mode performance : désactivé, inutile ici (chapitre Fenêtre et aide)." }) do
    local value = Z.translations.enUS[key]
    assert(value, "sans traduction anglaise : " .. key)
    -- seul l'onglet du personnage de la fenêtre /macro du jeu reste un onglet
    assert(key:find("/macro", 1, true) or not value:find("%f[%a]tab%f[%A]"), "onglet en anglais : " .. value)
  end
  assert(not Z.translations.enUS["... et %d autre(s) : onglet Clics."] and not Z.translations.enUS["Mode performance : activé (onglet Aide)."], "anciennes cles")

  -- Cartes de la fenêtre : la carte se pose à côté de la fenêtre d'options, jamais hors de l'écran
  Z.db.language = saved.language Z:SetLanguage()
  w.GetLeft = function() return 300 end w.GetRight = function() return 1380 end w.GetTop = function() return 900 end
  w.GetBottom = function() return 192 end
  UIParent.GetWidth = function() return 1920 end UIParent.GetHeight = function() return 1080 end
  Z:StartTutorial()
  local card = LyoruneTutorial
  for _ = 1, 6 do card.next:Run("OnClick") end
  assert(card.title:GetText() == "La fenêtre d'options" and UI.main == w, card.title:GetText())
  local p = card._point
  assert(p[1] == "TOPLEFT" and p[2] == w and p[3] == "BOTTOMLEFT" and p[4] == 1380 + 14 - 300, "carte a droite des options")
  w.GetLeft = function() return 110 end w.GetRight = function() return 1190 end UIParent.GetWidth = function() return 1300 end
  w.GetBottom = function() return 100 end
  card.back:Run("OnClick") card.next:Run("OnClick")
  p = card._point
  assert(p[2] == UIParent, "petit ecran : carte contre le bord, pas hors de l'ecran")
  card.close:Run("OnClick")
  w.GetLeft, w.GetRight, w.GetTop, w.GetBottom, UIParent.GetWidth, UIParent.GetHeight = nil, nil, nil, nil, nil, nil
  assert(not w:IsShown(), "options restees ouvertes")

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:SetLanguage() Z:Refresh()
end)

step("refonte 1.26.0, lot 6c bis b : visite qui rend la fenetre, explique les options, ne couvre pas les cases", function()
  local w = Z:OptionsWindow()
  local saved = { language = Z.db.language, lockMode = Z.db.lockMode, tutorialDone = Z.db.tutorialDone }
  Z.db.language = "AUTO" Z:SetLanguage()
  local card

  -- Lancée des options (chapitre Apparence) : la fenêtre se ferme, la carte le dit, elle revient à la fin
  Z:ToggleOptions("Apparence")
  Z:StartTutorial()
  card = LyoruneTutorial
  local light = card.highlight
  assert(not w:IsShown() and card.body:GetText():find("revient à la fin de la visite", 1, true), "premiere carte")
  for _ = 1, 6 do card.next:Run("OnClick") end
  -- Quatre cartes sur la fenêtre, chacune sur sa zone et son chapitre
  local zones = {
    { "La fenêtre d'options", "Accueil", function() return w.side end },
    { "Une page par chapitre", "Disposition", function() return Z:OptionsTabs()[2].page.scroll end },
    { "La case témoin", "Disposition", function() return w.witness end },
    { "Recherche et Accueil", "Accueil", function() return w.search end },
  }
  for i, zone in ipairs(zones) do
    assert(card.title:GetText() == zone[1] and w:IsShown() and Z:OptionChapter() == zone[2], "carte " .. i .. " : " .. card.title:GetText())
    assert(light:IsShown() and light._point[2] == zone[3](), "zone encadree, carte " .. i)
    card.next:Run("OnClick")
  end
  assert(card.title:GetText() == "C'est parti" and not w:IsShown(), "derniere carte : fenetre fermee")
  card.next:Run("OnClick")
  assert(not card:IsShown() and w:IsShown() and Z:OptionChapter() == "Apparence", "fenetre rendue sur son chapitre")

  -- Lancée de l'Accueil, fermée par la croix : la fenêtre revient sur l'Accueil
  Z:ToggleOptions("Accueil")
  Z:StartTutorial() card.next:Run("OnClick") card.next:Run("OnClick")
  card.close:Run("OnClick")
  assert(w:IsShown() and Z:OptionChapter() == "Accueil", "croix : fenetre rendue")

  -- Lancée fenêtre fermée : rien ne s'ouvre à la fin, le dernier chapitre ne change pas (croix sur une carte de la fenêtre)
  Z:ToggleOptions("Mes soins") w:Hide()
  Z:StartTutorial()
  assert(not card.body:GetText():find("revient", 1, true), "phrase de retour sans fenetre ouverte")
  for _ = 1, 7 do card.next:Run("OnClick") end
  assert(w:IsShown() and Z:OptionChapter() == "Disposition")
  card.close:Run("OnClick")
  assert(not w:IsShown() and Z:OptionChapter() == "Mes soins", "dernier chapitre change par la visite")
  Z:StartTutorial()
  for _ = 1, #card.runes do card.next:Run("OnClick") end
  assert(not w:IsShown() and Z:OptionChapter() == "Mes soins")
  -- Ouverte par le joueur pendant les cartes des cases : la fin de la visite la laisse ouverte
  Z:StartTutorial() card.next:Run("OnClick")
  Z:ToggleOptions()
  card.close:Run("OnClick")
  assert(w:IsShown() and Z:OptionChapter() == "Mes soins", "fenetre du joueur fermee par la visite")
  w:Hide()

  -- Une case : la carte se pose à côté du bloc entier des cadres, du côté le plus dégagé, sans le couvrir
  local frames, block = {}, {}
  for _, h in ipairs(Z.headers) do
    if h.def.pos == "pos" and h:IsVisible() then frames[#frames + 1] = h frames[#frames + 1] = h.handle block[#block + 1] = h end
  end
  assert(#block > 0, "aucun cadre visible")
  local button = Z.buttons[1]
  local function Set(f, l, r, t, b)
    f.GetLeft = function() return l end f.GetRight = function() return r end
    f.GetTop = function() return t end f.GetBottom = function() return b end
  end
  local function Blocks(l, r, t, b)
    for _, h in ipairs(block) do Set(h, l, r, t, b) Set(h.handle, l, r, t + 14, t + 2) end
  end
  Set(button, 100, 190, 700, 670)
  UIParent.GetWidth = function() return 1920 end UIParent.GetHeight = function() return 1080 end
  Blocks(100, 300, 700, 500)
  Z:StartTutorial() card.next:Run("OnClick")
  assert(card.title:GetText() == "Une case par joueur" and light._point[2] == button)
  local p = card._point
  assert(p[1] == "TOPLEFT" and p[2] == button and p[3] == "BOTTOMLEFT" and 100 + p[4] == 300 + 14, "a droite du bloc")
  -- Bloc sur toute la largeur : dessous (plus de place que dessus)
  Blocks(0, 1900, 700, 500)
  card.next:Run("OnClick") -- Soigner d'un clic
  p = card._point
  assert(p[1] == "TOPLEFT" and 670 + p[5] == 500 - 14, "sous le bloc : " .. tostring(p[5]))
  -- Plus de place nulle part : contre le bord de l'écran le plus loin de la case
  Blocks(0, 1900, 1000, 100)
  card.next:Run("OnClick") -- Ce que disent les couleurs
  p = card._point
  assert(p[2] == UIParent and p[1] == "TOPRIGHT", "contre le bord")
  -- Placer les cadres : l'étiquette est encadrée, la carte reste hors du bloc
  Blocks(100, 300, 700, 500)
  Z.header.handle.IsVisible = function() return true end -- le faux client ne montre pas l'étiquette
  card.next:Run("OnClick")
  Z.header.handle.IsVisible = nil
  assert(card.title:GetText() == "Placer les cadres" and light._point[2] == Z.header.handle)
  p = card._point
  assert(p[1] == "TOPLEFT" and p[3] == "BOTTOMLEFT", "placer : a droite du bloc")
  card.close:Run("OnClick")
  for _, f in ipairs(frames) do f.GetLeft, f.GetRight, f.GetTop, f.GetBottom = nil, nil, nil, nil end
  button.GetLeft, button.GetRight, button.GetTop, button.GetBottom = nil, nil, nil, nil
  UIParent.GetWidth, UIParent.GetHeight = nil, nil

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:SetLanguage() Z:Refresh()
end)

step("refonte 1.26.0, lot 6c ter : fenetres a la mesure de l'ecran, jamais l'une sur l'autre", function()
  local UI, w = Z.UI, Z:OptionsWindow()
  local saved = { reduceMotion = Z.db.reduceMotion }
  Z.db.reduceMotion = true -- fermetures sans fondu : la fenêtre se cache tout de suite
  w:Hide()
  -- Chaque fenêtre secondaire construite, puis fermée
  Z:ShowBug() Z:ShowNews() Z:ShowLog() Z:ShowMeasure() Z:OpenMacros() Z:OpenPlacement()
  OptionPart("copyButton").copyButton:Run("OnClick", "LeftButton")
  local beside = { LyoruneBug, LyoruneNews, LyoruneLog, LyorunePerf, LyoruneMacros, LyorunePlacement, LyoruneProfileCopy }
  for i, f in ipairs(beside) do
    assert(f and f.beside, "fenetre a cote des options : " .. i)
    f:Hide() f:Run("OnHide")
  end

  -- Quatre écrans (taille de UIParent) et un écran bas : chaque fenêtre tient, jamais sous 75 %
  local function Screen(width, height)
    UIParent.GetWidth = function() return width end UIParent.GetHeight = function() return height end
  end
  for _, screen in ipairs({ { 1024, 768 }, { 1365, 768 }, { 1920, 1080 }, { 2560, 1440 }, { 1365, 600 } }) do
    Screen(screen[1], screen[2])
    for _, f in ipairs(UI.Windows()) do
      UI.Fit(f)
      local s = f:GetScale()
      assert(s >= 0.75 and s <= 1, "echelle " .. s)
      assert(f:GetWidth() * s <= screen[1] - 40 and f:GetHeight() * s <= screen[2] - 60,
        "plus grande que l'ecran " .. screen[1] .. " x " .. screen[2] .. " : " .. tostring(f:GetName()))
    end
  end
  Screen(1024, 768) UI.Fit(w)
  assert(math.abs(w:GetScale() - 984 / 1080) < 0.001 and w:GetHeight() == 708, "options reduites d'un bloc : " .. w:GetScale())
  Screen(1365, 600) UI.Fit(w)
  local step = math.floor((540 - 58 - 34 - 16) / 12)
  assert(w:GetScale() == 1 and w:GetHeight() == 540 and w.chapters[1].button:GetHeight() == step - 2, "options moins hautes")
  -- l'échelle de l'interface change, fenêtre ouverte : elle reprend sa taille
  w:Show() Screen(1365, 768) FireEvent("UI_SCALE_CHANGED")
  assert(w:GetHeight() == 708 and w.chapters[1].button:GetHeight() == 38, "taille reprise")
  Screen(2560, 1440) FireEvent("DISPLAY_SIZE_CHANGED")
  assert(w:GetScale() == 1 and w:GetHeight() == 708, "grand ecran")

  -- Écran de 1365 : aucune fenêtre ne tient à côté, les options s'effacent puis reviennent sur le même chapitre
  Screen(1365, 768)
  w.GetLeft = function() return 142 end w.GetRight = function() return 1222 end w.GetTop = function() return 738 end
  Z:ToggleOptions("Apparence")
  for _, f in ipairs(beside) do
    f:Show()
    local p = f._point
    assert(not w:IsShown(), "options sous " .. f:GetName())
    assert(p[1] == "TOP" and p[2] == UIParent and p[4] == (142 + 1222) / 2 and p[5] == 738, "a la place des options : " .. f:GetName())
    f:Hide() f:Run("OnHide")
    assert(w:IsShown() and Z:OptionChapter() == "Apparence", "options revenues : " .. f:GetName())
  end
  -- deux fenêtres ouvertes : les options reviennent à la fermeture de la dernière
  LyoruneBug:Show() LyoruneLog:Show()
  LyoruneBug:Hide() LyoruneBug:Run("OnHide")
  assert(not w:IsShown(), "options revenues trop tot")
  LyoruneLog:Hide() LyoruneLog:Run("OnHide")
  assert(w:IsShown(), "options pas revenues")
  -- options rouvertes par le joueur : la fenêtre qui les effaçait se ferme
  LyoruneBug:Show()
  Z:ToggleOptions("Apparence")
  assert(w:IsShown() and not LyoruneBug:IsShown(), "deux fenetres l'une sur l'autre")

  -- Écran de 1920, options au milieu : elles glissent pour faire la place, puis retournent à leur place
  Screen(1920, 1080)
  w.GetLeft = function() return 420 end w.GetRight = function() return 1500 end w.GetTop = function() return 900 end
  LyoruneMacros:Show()
  local p = w._point
  assert(w:IsShown() and p[1] == "TOPLEFT" and p[2] == UIParent and p[4] == 106 and p[5] == 900, "options glissees")
  p = LyoruneMacros._point
  assert(p[1] == "TOPLEFT" and p[2] == w and p[3] == "TOPRIGHT", "macros a cote")
  w.GetLeft = function() return 106 end w.GetRight = function() return 1186 end
  LyoruneMacros:Hide() LyoruneMacros:Run("OnHide")
  assert(w._point[1] == "CENTER", "options pas revenues a leur place")
  -- place assez à droite : rien ne bouge
  w.GetLeft = function() return 100 end w.GetRight = function() return 1180 end
  w:SetPoint("CENTER") LyoruneMacros:Show()
  assert(w._point[1] == "CENTER" and LyoruneMacros._point[2] == w, "options deplacees pour rien")
  LyoruneMacros:Hide() LyoruneMacros:Run("OnHide")

  w.GetLeft, w.GetRight, w.GetTop, UIParent.GetWidth, UIParent.GetHeight = nil, nil, nil, nil, nil
  for _, f in ipairs(UI.Windows()) do UI.Fit(f) end
  w:Hide()
  for key, value in pairs(saved) do Z.db[key] = value end
end)

step("refonte 1.26.0, lot 6c quater : annuler mes changements, enregistrer mes reglages", function()
  local w = Z:OptionsWindow()
  local saved = { reduceMotion = Z.db.reduceMotion, activeProfile = Z.db.activeProfile, profiles = CopyTable(Z.db.profiles),
    showRunes = Z.db.showRunes }
  Z.db.reduceMotion = true Z.db.showRunes = true Z:Refresh()
  -- Fermée par le joueur : la copie est lâchée ; rouverte : nouvelle copie, rien à annuler
  w:Hide() w:Run("OnHide")
  assert(Z:OptionsOpenedCopy() == nil, "copie gardee fenetre fermee")
  Z:ToggleOptions("Disposition")
  local copy = Z:OptionsOpenedCopy()
  assert(copy and not w.undo:IsShown(), "Annuler montre sans changement")
  assert(copy.profiles == nil and copy.macros and copy.pinned and copy.language == nil and copy.clicks,
    "copie : reglages prives exclus (sauf les epingles et les macros, constats O12 et M1), clics compris")

  -- Bande du bas : un bouton de chaque côté de l'inscription runique, sans la toucher, dans la bande (34 de haut),
  -- en retrait des cadres épais ; la fenêtre réduite d'un bloc garde ce rapport
  local strip, width = Z:RuneStrip(), w:GetWidth()
  local s, u = w.save._point, w.undo._point
  assert(s[1] == "BOTTOMLEFT" and u[1] == "BOTTOMRIGHT" and s[2] >= 14 and u[2] <= -14, "places des boutons")
  assert(s[2] + w.save:GetWidth() + 20 <= (width - strip:GetWidth()) / 2, "Enregistrer touche l'inscription")
  assert(width + u[2] - w.undo:GetWidth() - 20 >= (width + strip:GetWidth()) / 2, "Annuler touche l'inscription")
  assert(s[3] >= 6 and s[3] + w.save:GetHeight() <= 34 and u[3] + w.undo:GetHeight() <= 34, "boutons hors de la bande")

  -- Enregistrer mes réglages : la case de nom s'ouvre, Entrée enregistre le profil, aucun réglage n'a changé
  w.save:Run("OnClick", "LeftButton")
  local box = w.saveBox
  assert(box:IsShown() and box.status:GetText():find("Échap", 1, true), "case de nom")
  box.edit:SetText(string.rep("x", 30)) box.edit:Run("OnEnterPressed")
  assert(box:IsShown() and box.status:GetText():find("24", 1, true), "nom trop long accepte")
  box.edit:Run("OnEscapePressed")
  assert(not box:IsShown(), "Echap ne ferme pas la case")
  w.save:Run("OnClick", "LeftButton")
  box.edit:SetText("Essai 6c") box.edit:Run("OnEnterPressed")
  assert(Z.db.profiles["Essai 6c"] and Z.db.activeProfile == "Essai 6c" and not box:IsShown(), "profil pas enregistre")
  assert(not w.undo:IsShown(), "Annuler montre apres un simple enregistrement")
  w.save:Run("OnClick", "LeftButton")
  assert(box.edit:GetText() == "Essai 6c", "profil en cours propose")
  w.save:Run("OnClick", "LeftButton")
  assert(not box:IsShown(), "second clic ne ferme pas la case")

  -- Un réglage, un clic, une liste et le placement changés : Annuler paraît, puis tout revient
  local before = { width = Z.db.width, click = Z:GetClicks()["alt-5"] }
  Z.db.width = Z.db.width + 10 Z:Refresh()
  assert(w.undo:IsShown(), "Annuler cache apres un reglage change")
  Z:SetClick("alt-5", "Prière")
  Z.db.ignoredNames["Essai 6c"] = true
  Z.db.placement.TILE = Z.db.placement.TILE or {}
  Z.db.placement.TILE.name = { 3, -2 }
  Z:Refresh()
  -- Effacée par une fenêtre secondaire (écran de 1365) : la copie est gardée, Annuler revient avec les options
  UIParent.GetWidth = function() return 1365 end UIParent.GetHeight = function() return 768 end
  w.GetLeft = function() return 142 end w.GetRight = function() return 1222 end w.GetTop = function() return 738 end
  LyoruneBug:Show()
  assert(not w:IsShown(), "options pas effacees") w:Run("OnHide")
  assert(Z:OptionsOpenedCopy() == copy, "copie perdue sous une fenetre secondaire")
  LyoruneBug:Hide() LyoruneBug:Run("OnHide")
  assert(w:IsShown() and w.undo:IsShown(), "Annuler perdu au retour des options")
  w.GetLeft, w.GetRight, w.GetTop, UIParent.GetWidth, UIParent.GetHeight = nil, nil, nil, nil, nil
  Z.UI.Fit(w)
  -- Visite lancée des options : la copie est gardée, la fenêtre revient avec Annuler
  Z:StartTutorial()
  assert(Z:TutorialRunning(), "visite pas en cours") w:Run("OnHide")
  assert(Z:OptionsOpenedCopy() == copy, "copie perdue pendant la visite")
  LyoruneTutorial.close:Run("OnClick")
  assert(not Z:TutorialRunning() and w:IsShown() and w.undo:IsShown(), "Annuler perdu apres la visite")

  -- En combat : tout revient, les clics à la fin du combat, et le joueur est prévenu
  local printed, Print = nil, Z.Print
  Z.Print = function(_, text) printed = text end
  COMBAT = true
  w.undo:Run("OnClick", "LeftButton")
  assert(Z.db.width ~= before.width, "Annuler au premier clic")
  w.undo.armed = true -- le faux client lance les minuteries tout de suite : second clic dans les 4 secondes
  w.undo:Run("OnClick", "LeftButton")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
  Z.Print = Print
  assert(printed and printed:find("fin du combat", 1, true), "joueur pas prevenu en combat")
  assert(Z.db.width == before.width and Z:GetClicks()["alt-5"] == before.click, "reglage ou clic pas revenu")
  assert(not Z.db.ignoredNames["Essai 6c"] and not (Z.db.placement.TILE and Z.db.placement.TILE.name), "liste ou placement pas revenus")
  assert(Z.db.activeProfile == copy.activeProfile and Z.db.profiles["Essai 6c"], "profil en cours pas revenu, ou profil enregistre perdu")
  assert(not w.undo:IsShown(), "Annuler encore montre")
  assert(Z:OptionsOpenedCopy() == copy, "copie lachee apres Annuler")

  -- Fermée puis rouverte : nouvelle copie
  w:Hide() w:Run("OnHide")
  Z:ToggleOptions()
  assert(Z:OptionsOpenedCopy() and Z:OptionsOpenedCopy() ~= copy, "copie pas reprise a l'ouverture")
  w:Hide() w:Run("OnHide")
  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
end)

step("refonte 1.26.0, lot 6c quinquies : fenetres en gris tres fonce, jamais en noir pur", function()
  local UI = Z.UI
  local function lum(c)
    local function ch(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * ch(c[1]) + 0.7152 * ch(c[2]) + 0.0722 * ch(c[3])
  end
  local function ratio(a, b) local x, y = lum(a), lum(b) if x < y then x, y = y, x end return (x + 0.05) / (y + 0.05) end
  local function black(c) return c[1] == 0 and c[2] == 0 and c[3] == 0 end
  local function white(c) return c[1] == 1 and c[2] == 1 and c[3] == 1 end
  -- Chaque thème des fenêtres, puis le contraste élevé par-dessus chacun : aucun fond noir pur, aucun texte blanc
  -- pur, trois tons distincts (page, colonnes de côté, boutons), texte 4,5:1 au moins (7:1 en contraste élevé)
  -- partout où il se pose, sans être poussé au maximum
  local looks = {}
  for name, skin in pairs(UI.skins) do
    looks[#looks + 1] = { name, skin, 4.5 }
    local high = {}
    for _, role in ipairs(UI.ROLES) do high[role] = UI.CONTRAST[role] or skin[role] end
    looks[#looks + 1] = { name .. " contraste", high, 7 }
  end
  for _, look in ipairs(looks) do
    local name, p, need = look[1], look[2], look[3]
    for _, role in ipairs({ "bg", "side", "panel" }) do
      assert(p[role] and not black(p[role]) and lum(p[role]) < 0.05, name .. " : fond " .. role .. " noir pur ou trop clair")
    end
    assert(lum(p.side) > lum(p.bg) and lum(p.panel) > lum(p.bg), name .. " : plans pas separes")
    assert(not white(p.text) and not white(p.btext), name .. " : texte blanc pur")
    for _, ground in ipairs({ "bg", "side", "panel" }) do
      for _, role in ipairs({ "text", "dim", "accent" }) do
        assert(ratio(p[role], p[ground]) >= need, name .. " : " .. role .. " sur " .. ground .. " peu lisible")
      end
      assert(ratio(p.text, p[ground]) <= 18, name .. " : contraste force au maximum")
    end
    assert(ratio(p.btext, p.panel) >= need, name .. " : texte des boutons peu lisible")
  end
  assert(UI.CONTRAST.bgAlpha == 1, "contraste eleve : fond opaque")

  -- Colonnes de côté peintes au ton « side », thème et contraste élevé suivis en direct
  Z:ToggleOptions("Apparence")
  local w = Z:OptionsWindow()
  local saved = { windowTheme = Z.db.windowTheme, highContrast = Z.db.highContrast }
  for _, case in ipairs({ { "MODERN", false }, { "CLASSIC", false }, { "MMO", false }, { "MODERN", true }, { "MMO", true } }) do
    Z.db.windowTheme, Z.db.highContrast = case[1], case[2] Z:Refresh()
    local skin, look = UI.skins[case[1]], case[1] .. (case[2] and " contraste" or "")
    local want = case[2] and UI.CONTRAST or skin
    for _, f in ipairs({ w.side, w.witness }) do
      assert(f.bg._color[1] == want.side[1] and f.bg._color[4] == want.sideAlpha, look .. " : colonne de cote")
    end
    assert(not black(w.bg._color) and not black(UI.bg) and not white(UI.text), look .. " : fenetre en noir et blanc purs")
  end
  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
  w:Hide() w:Run("OnHide")
end)

step("refonte 1.26.0, lot 6c septies a : corrections de UI.lua (relecture)", function()
  local UI, mt = Z.UI, getmetatable(UIParent)
  local saved = { windowTheme = Z.db.windowTheme, highContrast = Z.db.highContrast, texture = Z.db.texture,
    width = Z.db.width, reduceMotion = Z.db.reduceMotion }

  -- U1 : la rune de confirmation éteinte reste éteinte après un changement de thème (cachée, pas mise à 0)
  local widget = CreateFrame("Frame", nil, UIParent)
  UI.Confirm(widget)
  local rune = widget.confirmRune
  assert(rune:IsShown() and widget.confirm:IsPlaying(), "rune allumee au changement")
  widget.confirm:Run("OnFinished")
  assert(not rune:IsShown(), "rune eteinte a la fin")
  Z.db.windowTheme = "CLASSIC" Z:Refresh()
  Z.db.highContrast = not Z.db.highContrast Z:Refresh()
  assert(not rune:IsShown(), "rune rallumee par le changement de theme")
  UI.Confirm(widget) assert(rune:IsShown(), "rune rallumee au clic suivant")

  -- U2 : LibSharedMedia a aussi sa « Blizzard » : un seul exemplaire, le tour des choix passe par toutes
  local list = mt.List
  mt.List = function() return { "Blizzard", "Lisse", "Raid", "Brillante" } end
  local names, seen = UI.TextureList(), {}
  for _, name in ipairs(names) do assert(not seen[name], "texture en double : " .. name) seen[name] = true end
  assert(#names == 5 and seen.Lisse and seen.Brillante, "textures de LibSharedMedia : " .. #names)
  local choices = { { "THEME", "Celle du thème" } }
  for _, name in ipairs(names) do choices[#choices + 1] = { name, name } end
  Z.db.texture = "THEME"
  local cycle = UI.Cycle(UIParent, "Texture", choices, function() return Z.db.texture end, function(v) Z.db.texture = v end)
  local reached = {}
  for _ = 1, #choices do cycle.button:Run("OnClick", "LeftButton") reached[Z.db.texture] = true end
  for _, choice in ipairs(choices) do assert(reached[choice[1]], "texture jamais atteinte : " .. choice[1]) end
  mt.List = list

  -- U5 : texture inconnue (addon désinstallé) : celle du thème, comme l'affiche la ligne
  local fetch = mt.Fetch
  mt.Fetch = function() return nil end
  Z.db.texture = "Absente"
  assert(UI.BarTexture() == Z:Theme().texture, "texture inconnue : pas celle du theme")
  mt.Fetch = fetch

  -- U6 et B3 a : un champ rend le clavier quand il est caché et écrit dans la couleur du texte de la palette
  local edit = UI.Edit(UIParent, 120)
  assert(edit:GetScript("OnHide"), "champ cache sans rendre le clavier")
  local c = edit._color
  assert(c and c[1] == UI.text[1] and c[2] == UI.text[2] and c[3] == UI.text[3], "champ en blanc pur")
  Z.db.windowTheme = "MMO" Z:Refresh()
  assert(edit._color[1] == UI.text[1], "champ pas repeint au changement de theme")

  -- U7 : la molette fait défiler la page ; elle change le nombre seulement sur une valeur active ou avec Maj
  local scroll = UI.Scroll(UIParent)
  scroll:SetHeight(200) scroll:SetContentHeight(1000)
  local lo, hi, pas = unpack(Z.limits.width)
  Z.db.width = 86
  local st = UI.Stepper(scroll.content, "Largeur", lo, hi, pas, function() return Z.db.width end, function(v) Z.db.width = v end)
  st.value:Run("OnMouseWheel", -1)
  assert(Z.db.width == 86 and scroll.offset == 40, "molette sur un nombre au passage : " .. Z.db.width .. ", " .. scroll.offset)
  local shift = IsShiftKeyDown
  IsShiftKeyDown = function() return true end
  st.value:Run("OnMouseWheel", 1)
  IsShiftKeyDown = shift
  assert(Z.db.width == 86 + pas and scroll.offset == 40, "Maj + molette")
  st.value.HasFocus = function() return true end
  st.value:Run("OnMouseWheel", -1)
  assert(Z.db.width == 86 and scroll.offset == 40, "molette sur la valeur active")

  -- U4 : options effacées en fondu puis rendues pendant ce fondu : elles restent ouvertes
  Z.db.reduceMotion = false
  local w = Z:OptionsWindow()
  UIParent.GetWidth = function() return 1365 end UIParent.GetHeight = function() return 768 end
  w.GetLeft = function() return 142 end w.GetRight = function() return 1222 end w.GetTop = function() return 738 end
  Z:ToggleOptions("Apparence")
  LyoruneBug:Show()
  assert(w.outro:IsPlaying(), "options pas effacees en fondu")
  LyoruneBug:Hide() LyoruneBug:Run("OnHide")
  assert(w:IsShown() and not w.outro:IsPlaying(), "fondu pas arrete : les options se cacheraient")
  -- croix puis réouverture pendant le fondu : la fenêtre reste ; un second appel la ferme
  w:Close()
  assert(w.outro:IsPlaying(), "fondu de la croix")
  Z:ToggleOptions()
  assert(w:IsShown() and not w.outro:IsPlaying(), "options rouvertes pendant le fondu")
  w:Close() Z:ToggleOptions("Accueil")
  assert(w:IsShown() and not w.outro:IsPlaying(), "chapitre ouvert pendant le fondu")
  Z:ToggleOptions()
  assert(not w:IsShown(), "deuxieme appel : options fermees")
  w:Run("OnHide")
  w.GetLeft, w.GetRight, w.GetTop, UIParent.GetWidth, UIParent.GetHeight = nil, nil, nil, nil, nil
  for _, f in ipairs(UI.Windows()) do UI.Fit(f) end

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
end)

step("refonte 1.26.0, lot 6c septies b : corrections d'Options.lua (relecture)", function()
  local UI, w = Z.UI, Z:OptionsWindow()
  local saved = { windowTheme = Z.db.windowTheme, highContrast = Z.db.highContrast, reduceMotion = Z.db.reduceMotion,
    manaText = Z.db.manaText, tutorialDone = Z.db.tutorialDone, wizardDone = Z.db.wizardDone,
    actionBarMacros = Z.db.actionBarMacros, syncEnabled = Z.db.syncEnabled, width = Z.db.width,
    clicks = CopyTable(Z.db.clicks), hoverKeys = CopyTable(Z.db.hoverKeys), pinned = CopyTable(Z.db.pinned),
    autoProfiles = CopyTable(Z.db.autoProfiles or {}), cornerSpells = CopyTable(Z.db.cornerSpells) }
  Z.db.reduceMotion = true Z:Refresh()
  local function Fresh(chapter) -- fenêtre fermée par le joueur puis rouverte : nouvelle copie d'« Annuler »
    w:Hide() w:Run("OnHide")
    Z:ToggleOptions(chapter)
    assert(Z:OptionsOpenedCopy() and not w.undo:IsShown(), "copie prise a l'ouverture : " .. chapter)
  end
  local function Find(page, test)
    for _, part in ipairs(page.parts) do if test(part.widget) then return part.widget end end
  end
  local function Undo()
    w.undo.armed = true -- le faux client lance les minuteries tout de suite : second clic dans les 4 secondes
    w.undo:Run("OnClick", "LeftButton")
  end

  -- O8 : la recherche ne tient compte ni des majuscules ni des accents
  Fresh("Accueil")
  for _, typed in ipairs({ "échelle", "ECHELLE", "echelle", "ÉCHELLE" }) do
    w.search:SetText(typed) w.search:Run("OnTextChanged", true)
    local row = w.results.rows[1]
    assert(row and row:IsShown() and row.entry.label:find("chelle g", 1, true), "recherche : " .. typed)
  end
  w.search:SetText("a ignorer") w.search:Run("OnTextChanged", true)
  local hit
  for _, row in ipairs(w.results.rows) do if row:IsShown() and row.entry.label == "À ignorer" then hit = true end end
  assert(hit, "« a ignorer » ne trouve pas À ignorer")
  assert(Z.SearchText("Œuvre À Ça") == "oeuvre a ca", Z.SearchText("Œuvre À Ça"))
  -- O14 : le nom du chapitre d'un résultat suit le thème
  assert(w.results.rows[1].label:GetText():find(UI.Hex("dim"), 1, true), "chapitre du resultat en gris ecrit en dur")
  -- O15 a : deux recherches de suite, le premier délai n'éteint pas le second clignotement
  local after, timers = C_Timer.After, {}
  C_Timer.After = function(_, f) timers[#timers + 1] = f end
  w.results.rows[1]:Run("OnClick", "LeftButton")
  w.search:SetText("echelle") w.search:Run("OnTextChanged", true)
  w.results.rows[1]:Run("OnClick", "LeftButton")
  assert(#timers == 2 and w.flash:IsShown(), "clignotement : " .. #timers)
  timers[1]() assert(w.flash:IsShown(), "le premier delai eteint le second clignotement")
  timers[2]() assert(not w.flash:IsShown(), "clignotement jamais eteint")

  -- O4 : bouton à confirmer armé, confirmé puis réarmé : le premier délai ne le désarme pas
  timers = {}
  local done = 0
  local armed = Z.ArmedButton(UIParent, "Supprimer", "Cliquez encore pour confirmer", 120, function() done = done + 1 end)
  armed:Run("OnClick", "LeftButton") armed:Run("OnClick", "LeftButton")
  assert(done == 1 and not armed.armed, "second clic")
  armed:Run("OnClick", "LeftButton")
  timers[1]() assert(armed.armed, "desarme par le delai d'avant")
  timers[2]() assert(not armed.armed, "jamais desarme")
  C_Timer.After = after

  -- O1 : attente d'un raccourci puis bouton caché : l'attente est annulée, le clavier rendu
  local page = w.Select("Sorts et raccourcis")
  local list = Find(page, function(x) return x.add and x.banner end)
  local add = list.add
  NOW = NOW + 1 add:Run("OnClick", "LeftButton")
  assert(add.capturing and add:GetScript("OnKeyDown"), "attente lancee")
  add:Hide() add:Run("OnHide") add:Show()
  assert(not add.capturing and not add:GetScript("OnKeyDown") and add.label:GetText() == add.idle, "attente gardee page cachee")

  -- O2 et O6 : la couleur d'un coin revient après un changement de thème ; un coin choisi allume l'éclat
  page = w.Select("Mes soins")
  local corner = Find(page, function(x) return x.label and x.button and x.label:GetText() == "En haut à gauche" end)
  local color = Z.CORNER_COLORS.TOPLEFT
  Z.db.windowTheme = Z.db.windowTheme == "CLASSIC" and "MODERN" or "CLASSIC" Z:Refresh()
  assert(corner.label._color[1] == color[1] and corner.label._color[3] == color[3], "couleur du coin perdue")
  -- O14 : le numéro de version du titre suit le thème
  assert(w.title:GetText():find(UI.Hex("dim") .. Z.version, 1, true), "titre en gris ecrit en dur")
  Z.db.highContrast = not Z.db.highContrast Z:Refresh()
  assert(corner.label._color[1] == color[1], "couleur du coin perdue au contraste eleve")
  assert(w.title:GetText():find(UI.Hex("dim") .. Z.version, 1, true), "titre pas repeint")
  local spark, sparks = w.witness.Spark, 0
  w.witness.Spark = function() sparks = sparks + 1 end
  corner.button:Run("OnClick", "LeftButton")
  w.witness.Spark = spark
  assert(sparks == 1, "coin choisi sans eclat")

  -- O3 : un texte d'annonce changé seul fait paraître « Annuler mes changements »
  Fresh("Alertes")
  page = w.Select("Alertes")
  local text = Find(page, function(x) return x.test and x.edit end)
  text.edit:SetText("Mana basse O3") text.edit:Run("OnTextChanged", true)
  assert(w.undo:IsShown(), "Annuler absent apres un texte d'annonce")
  Undo()
  assert(Z.db.manaText == saved.manaText, "texte d'annonce pas revenu")
  -- ... et un profil automatique aussi
  Fresh("Profils et partage")
  local grid = OptionPart("profileCells")
  Z.db.profiles["Essai O3"] = Z.db.profiles["Essai O3"] or {}
  grid.profileCells[1]:Run("OnClick", "LeftButton")
  assert(w.undo:IsShown(), "Annuler absent apres un profil automatique")
  Undo()
  Z.db.profiles["Essai O3"] = nil

  -- O10 : les clics de la classe se reprennent en deux clics, et « Annuler mes changements » les rend
  Z:SetClick("alt-5", "Prière")
  Fresh("Profils et partage")
  local reset = OptionPart("classClicks").classClicks
  reset:Run("OnClick", "LeftButton")
  assert(Z:GetClicks()["alt-5"] == "Prière" and not w.undo:IsShown(), "clics remplaces au premier clic")
  reset.armed = true reset:Run("OnClick", "LeftButton")
  assert(Z:GetClicks()["alt-5"] ~= "Prière" and w.undo:IsShown(), "clics pas remplaces, ou Annuler absent")
  Undo()
  assert(Z:GetClicks()["alt-5"] == "Prière", "clics pas rendus")

  -- O12 : un joueur épinglé depuis l'ouverture est retiré par « Annuler mes changements »
  Fresh("Disposition")
  Z:TogglePin("Essai-O12")
  assert(Z.db.pinned["Essai-O12"] and w.undo:IsShown(), "Annuler absent apres un epingle")
  Undo()
  assert(not Z.db.pinned["Essai-O12"], "epingle pas retire")

  -- O13 : « Retirer les macros de Lyorune » en combat : refusé, l'option reste cochée
  page = w.Select("Sorts et raccourcis")
  local remove = Find(page, function(x) return x.label and x.label:GetText() == "Retirer les macros de Lyorune" end)
  Z.db.actionBarMacros = true
  local Print = Z.Print
  Z.Print = function() end
  COMBAT = true remove:Run("OnClick", "LeftButton") COMBAT = false
  Z.Print = Print
  assert(Z.db.actionBarMacros == true, "option decochee alors que les macros restent")
  remove:Run("OnClick", "LeftButton")
  assert(Z.db.actionBarMacros == false, "option pas decochee hors combat")

  -- O15 b : sur la liste des réglages changés, la valeur s'arrête avant le nom du chapitre
  Z.db.width = Z.db.width + 10 Z:Refresh()
  page = w.Select("Accueil")
  local changed = Find(page, function(x) return x.rows and x.rows[1] and x.rows[1].where end)
  local row = changed.rows[1]
  assert(282 + row.value:GetWidth() < row:GetWidth() - 6 - row.where:GetWidth(), "valeur sur le nom du chapitre")
  Z.db.width = saved.width Z:Refresh()

  -- O15 c : « Entre joueurs » suit le groupe page ouverte
  page = w.Select("Profils et partage")
  Z.db.syncEnabled = true
  local who = Find(page, function(x) return x.text and x.Update and x:GetScript("OnEnter") and not x.list end)
  assert(who, "ligne Entre joueurs")
  local inGroup, members = IsInGroup, Z.SyncMembers
  IsInGroup = function() return true end
  Z.SyncMembers = function() return { { name = "Un", version = "1" }, { name = "Deux", version = "1" } } end
  FireEvent("GROUP_ROSTER_UPDATE")
  assert(who.text:GetText():find("2", 1, true), "nombre pas revu : " .. who.text:GetText())
  IsInGroup, Z.SyncMembers = inGroup, members
  FireEvent("GROUP_ROSTER_UPDATE")

  -- O9 : l'assistant lancé des options garde la copie d'« Annuler » et rend la fenêtre sur l'Accueil
  Z.db.tutorialDone = true
  Fresh("Accueil")
  local copy = Z:OptionsOpenedCopy()
  page = w.Select("Accueil")
  local discover = Find(page, function(x) return x.buttons and x.buttons[2] and x.buttons[2].label:GetText() == "Assistant de départ" end)
  discover.buttons[2]:Run("OnClick", "LeftButton")
  assert(not w:IsShown() and Z:WizardRunning(), "options pas fermees par l'assistant") w:Run("OnHide")
  assert(Z:OptionsOpenedCopy() == copy, "copie perdue pendant l'assistant")
  LyoruneWizard.close:Run("OnClick")
  assert(w:IsShown() and Z:OptionChapter() == "Accueil" and not Z:WizardRunning(), "fenetre pas rendue sur l'Accueil")
  assert(Z:OptionsOpenedCopy() == copy, "copie perdue apres l'assistant")
  -- premier lancement : la visite suit et c'est elle qui rend la fenêtre
  Z.db.tutorialDone = false
  discover.buttons[2]:Run("OnClick", "LeftButton") w:Run("OnHide")
  LyoruneWizard.close:Run("OnClick")
  assert(Z:TutorialRunning() and not w:IsShown(), "visite pas lancee apres l'assistant")
  assert(Z:OptionsOpenedCopy() == copy, "copie perdue entre l'assistant et la visite")
  LyoruneTutorial.close:Run("OnClick")
  assert(w:IsShown() and Z:OptionChapter() == "Accueil", "fenetre pas rendue apres la visite")
  -- lancé fenêtre fermée (/lyorune assistant) : la fenêtre reste fermée
  Z.db.tutorialDone = true
  w:Hide() w:Run("OnHide")
  Z:StartWizard() LyoruneWizard.close:Run("OnClick")
  assert(not w:IsShown(), "options ouvertes par un assistant lance fenetre fermee")

  w:Hide() w:Run("OnHide")
  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh() Z:ApplyClicks()
end)

step("refonte 1.26.0, lot 6c septies c : corrections de Tutorial.lua et Runes.lua (relecture)", function()
  local w = Z:OptionsWindow()
  local saved = { language = Z.db.language, lockMode = Z.db.lockMode, tutorialDone = Z.db.tutorialDone,
    highContrast = Z.db.highContrast, absorbStyle = Z.db.absorbStyle, windowTheme = Z.db.windowTheme,
    showRunes = Z.db.showRunes, theme = Z.db.theme }
  Z.db.language = "AUTO" Z:SetLanguage()
  w:Hide() w:Run("OnHide")
  local card
  local function Go(n) for _ = 1, n do card.next:Run("OnClick") end end

  -- T1 : visite lancée fenêtre fermée jusqu'au bout : la copie d'« Annuler » prise par les cartes de la fenêtre est lâchée
  Z:StartTutorial() card = LyoruneTutorial
  Go(6)
  assert(card.title:GetText() == "La fenêtre d'options" and w:IsShown() and Z:OptionsOpenedCopy(), "carte de la fenetre")
  Go(4)
  assert(card.title:GetText() == "C'est parti" and not w:IsShown())
  Go(1)
  assert(not card:IsShown() and not w:IsShown() and Z:OptionsOpenedCopy() == nil, "copie gardee apres la visite")

  -- T2 a : /reload pendant la carte « Placer les cadres » : le verrou du joueur revient au chargement
  Z.db.lockMode = "ALT" Z:StartTutorial() Go(4)
  assert(card.title:GetText() == "Placer les cadres" and Z.db.lockMode == "FREE" and Z.db.lockBeforeTutorial == "ALT")
  FireEvent("ADDON_LOADED", "Lyorune")
  assert(Z.db.lockMode == "ALT" and Z.db.lockBeforeTutorial == nil, "verrou perdu au rechargement : " .. tostring(Z.db.lockMode))
  card.close:Run("OnClick")
  assert(Z.db.lockMode == "ALT")
  -- T2 b : « Verrouillé » choisi pendant la carte (elle le conseille) : gardé
  Z:StartTutorial() Go(4)
  Z.db.lockMode = "LOCKED"
  Go(1)
  assert(Z.db.lockMode == "LOCKED" and Z.db.lockBeforeTutorial == nil, "choix du joueur ecrase : " .. Z.db.lockMode)
  card.close:Run("OnClick")
  -- rechargement sans visite coupée : rien ne change
  FireEvent("ADDON_LOADED", "Lyorune")
  assert(Z.db.lockMode == "LOCKED")

  -- T3 : couleurs des soins en route et du bouclier lues dans le thème des cases, place du bouclier suivie
  local function Hex(c) return ("%02x%02x%02x"):format(c[1] * 255 + 0.5, c[2] * 255 + 0.5, c[3] * 255 + 0.5) end
  Z.db.highContrast = true Z.db.absorbStyle = "BAND" Z:Refresh()
  Z:StartTutorial() Go(1)
  local body = card.body:GetText()
  assert(card.title:GetText() == "Une case par joueur")
  assert(body:find("|cff" .. Hex(Z:Theme().absorb) .. "bande claire", 1, true) and body:find("|cff" .. Hex(Z:Theme().incoming), 1, true), body)
  assert(not body:find("8cd9ff", 1, true) and not body:find("vert clair", 1, true), "couleurs de l'Epure en dur")
  Z.db.highContrast = false Z.db.theme = "HEROIC" Z.db.absorbStyle = "FOLLOW" Z:Refresh()
  card.back:Run("OnClick") Go(1)
  body = card.body:GetText()
  assert(body:find("|cff" .. Hex(Z:Theme().absorb) .. "part rayée", 1, true) and body:find("prolonge", 1, true), body)
  card.close:Run("OnClick")
  Z.db.absorbStyle = saved.absorbStyle Z.db.theme = saved.theme Z.db.highContrast = saved.highContrast Z:Refresh()

  -- T4 : aucune vraie case visible : les cartes des cases ouvrent le faux groupe et l'encadrent, puis le ferment
  local button = Z.buttons[1]
  button.IsVisible = function() return false end
  Z:StartTutorial() Go(1)
  local light = card.highlight
  assert(Z.previewActive and Z:PreviewSize() == 5, "faux groupe pas ouvert")
  assert(light:IsShown() and light._point[2] == Z:PreviewCells(1)[1], "faux groupe pas encadre")
  Go(2)
  assert(card.title:GetText() == "Ce que disent les couleurs" and Z.previewActive)
  Go(1)
  assert(card.title:GetText() == "Placer les cadres" and not Z.previewActive, "faux groupe laisse ouvert")
  Go(1)
  assert(Z.previewActive and light._point[2] == Z:PreviewCells(1)[1], "carte du mode test")
  card.close:Run("OnClick")
  assert(not Z.previewActive, "mode test laisse ouvert par la visite")
  button.IsVisible = nil
  -- T7 a : mode test ouvert par le joueur avant la visite : il reste ouvert
  Z:TogglePreview(5)
  Z:StartTutorial() Go(5)
  assert(card.title:GetText() == "Essayer sans groupe" and Z.previewActive)
  Go(1)
  assert(Z.previewActive, "mode test du joueur ferme par la visite")
  card.close:Run("OnClick")
  assert(Z.previewActive) Z:TogglePreview()

  -- T5 : Échap termine la visite comme la croix (fenêtre d'options rendue, copie gardée, verrou rendu)
  local found
  for _, name in ipairs(UISpecialFrames) do found = found or name == "LyoruneTutorial" end
  assert(found, "carte absente de UISpecialFrames")
  Z:ToggleOptions("Mes soins")
  local copy = Z:OptionsOpenedCopy()
  Z:StartTutorial() Go(7)
  assert(card.title:GetText() == "Une page par chapitre" and w:IsShown())
  w:Hide() w:Run("OnHide") card:Hide() card:Run("OnHide") -- Échap ferme les deux
  assert(not Z:TutorialRunning(), "visite pas terminee par Echap")
  assert(w:IsShown() and Z:OptionChapter() == "Mes soins" and Z:OptionsOpenedCopy() == copy, "fenetre pas rendue apres Echap")
  w:Hide() w:Run("OnHide")
  Z.db.lockMode = "SHIFT" Z:StartTutorial() Go(4)
  card:Hide() card:Run("OnHide")
  assert(not Z:TutorialRunning() and Z.db.lockMode == "SHIFT", "verrou pas rendu apres Echap")
  card.close:Run("OnClick") -- déjà finie : sans effet

  -- T6 : fenêtre fermée par sa croix sur une de ses cartes : le cadre lumineux part avec elle
  Z:StartTutorial() Go(6)
  assert(light:IsShown() and w:IsShown())
  w:Hide() w:Run("OnHide")
  assert(not light:IsShown() and card:IsShown(), "cadre lumineux seul a l'ecran")
  card.close:Run("OnClick")

  -- T7 b : thème des fenêtres changé pendant la visite : les mots d'accent suivent aussitôt
  Z:StartTutorial()
  Z.db.windowTheme = Z.db.windowTheme == "MMO" and "MODERN" or "MMO" Z.UI.ApplySkin()
  assert(card.body:GetText():find("|cff" .. Z.UI.Hex("accent") .. "/lyorune", 1, true), "accent pas suivi : " .. card.body:GetText())
  card.close:Run("OnClick")
  Z.db.windowTheme = saved.windowTheme Z.UI.ApplySkin()

  -- R1 : inscription coupée à la première ouverture, puis rallumée : construite sans attendre un /reload
  local fresh = setmetatable({}, { __index = Z })
  local f = assert(loadstring(RUNES_LUA, "@Runes.lua"))
  f("Lyorune", fresh)
  Z.db.showRunes = false
  fresh:RefreshRunes(w)
  assert(fresh:RuneStrip() == nil)
  Z.db.showRunes = true
  fresh:RefreshRunes()
  local strip = fresh:RuneStrip()
  assert(strip and strip:IsShown(), "inscription pas construite une fois rallumee")
  strip:Hide()

  -- R2 : fenêtre fermée la souris sur les runes : éclat du survol et infobulle partent avec elle
  strip = Z:RuneStrip()
  strip:Run("OnEnter")
  assert(strip.lit)
  local owned = GameTooltip.IsOwned
  GameTooltip.IsOwned = function(_, owner) return owner == strip end
  GameTooltip:Show()
  strip:Run("OnHide")
  GameTooltip.IsOwned = owned
  assert(not strip.lit and strip.base[1]._color[4] == 0.5, "runes restees allumees")
  assert(not GameTooltip:IsShown(), "infobulle restee ouverte")

  w:Hide() w:Run("OnHide")
  for key, value in pairs(saved) do Z.db[key] = value end
  Z:SetLanguage() Z.UI.ApplySkin() Z:Refresh()
end)

step("refonte 1.26.0, lot 6c septies d : corrections de Macros.lua (relecture)", function()
  local UI, o, L = Z.UI, Z:OptionsWindow(), Z.L
  local saved = { reduceMotion = Z.db.reduceMotion, windowTheme = Z.db.windowTheme, macroAutoTarget = Z.db.macroAutoTarget,
    macros = CopyTable(Z.db.macros), clicks = CopyTable(Z.db.clicks), hoverKeys = CopyTable(Z.db.hoverKeys) }
  local after, print = C_Timer.After, Z.Print
  Z.db.reduceMotion = true Z:Refresh()
  local b = Z.buttons[1]
  local function Fresh() -- options fermées par le joueur puis rouvertes : nouvelle copie d'« Annuler »
    o:Hide() o:Run("OnHide")
    Z:ToggleOptions("Sorts et raccourcis")
    assert(Z:OptionsOpenedCopy() and not o.undo:IsShown(), "copie prise a l'ouverture")
  end
  local function Undo()
    o.undo.armed = true -- le faux client lance les minuteries tout de suite : second clic dans les 4 secondes
    o.undo:Run("OnClick", "LeftButton")
  end
  Z.db.macros[Z.class] = {}
  Z:NewMacro("Bijou soin", "/use 13\n/cast Soins")
  Z:SetClick("alt-5", "@macro:Bijou soin")

  -- M1 : renommer puis « Annuler » : le clic et sa macro reviennent ensemble, la fenêtre reprend la macro
  Fresh()
  local w = Z:OpenMacros("Bijou soin")
  w.name:SetText("Soin du bijou") w.name:Run("OnEnterPressed")
  assert(Z:GetClicks()["alt-5"] == "@macro:Soin du bijou" and o.undo:IsShown(), "renommage")
  Undo()
  assert(Z:GetClicks()["alt-5"] == "@macro:Bijou soin" and Z:FindMacro("Bijou soin") and not Z:FindMacro("Soin du bijou"),
    "M1 : macro pas revenue avec son clic")
  assert(w.macro == Z:FindMacro("Bijou soin") and w.name:GetText() == "Bijou soin", "M1 : fenetre restee sur l'ancienne table")
  assert(b:GetAttribute("alt-macrotext5") == "/use 13\n/cast [@mouseover] Soins", tostring(b:GetAttribute("alt-macrotext5")))
  -- M2 : supprimer demande un second clic ; puis « Annuler » rend la macro et son clic
  C_Timer.After = function() end
  w.remove:Run("OnClick", "LeftButton")
  assert(Z:FindMacro("Bijou soin") and w.remove.armed, "M2 : supprimee en un clic")
  w.remove:Run("OnClick", "LeftButton")
  assert(not Z:FindMacro("Bijou soin") and Z:GetClicks()["alt-5"] == nil, "M2 : second clic sans effet")
  Undo()
  assert(Z:FindMacro("Bijou soin") and Z:GetClicks()["alt-5"] == "@macro:Bijou soin" and b:GetAttribute("alt-macrotext5"),
    "M1 : suppression pas annulee")
  assert(w.macro == Z:FindMacro("Bijou soin"), "M1 : fenetre apres la suppression annulee")
  -- M2 : armé sur une macro, puis une autre choisie : le second clic ne la supprime pas
  Z:NewMacro("Autre", "/cast Soins")
  w.remove:Run("OnClick", "LeftButton")
  assert(w.remove.armed)
  w.SaveCurrent() w.Select(Z:FindMacro("Autre"))
  assert(not w.remove.armed and w.remove.label:GetText() == L["Supprimer"], "M2 : reste arme sur une autre macro")
  C_Timer.After = after
  -- M1 : le texte seul change : « Annuler » paraît et le rend
  w.Select(Z:FindMacro("Bijou soin"))
  Fresh()
  w.edit:SetText("/cast Rénovation") w.save:Run("OnClick")
  assert(o.undo:IsShown(), "M1 : texte change seul, Annuler absent")
  Undo()
  assert(Z:FindMacro("Bijou soin").body == "/use 13\n/cast Soins" and w.edit:GetText() == "/use 13\n/cast Soins", "M1 : texte")

  -- M3 : chaque zone de la colonne de droite a sa hauteur et finit avant le haut de la suivante
  local function Top(f) return f._point[#f._point] end
  assert(w.problems:GetHeight() == 6 * 13 and w.preview:GetHeight() == 5 * 13 and w.uses:GetHeight() == 2 * 13
    and w.help:GetHeight() == 2 * 13, "hauteurs des zones")
  local box = w.scroll:GetParent()
  local column = { { -72, box:GetHeight() }, { Top(w.help), w.help:GetHeight() }, { -230 }, { Top(w.problems), w.problems:GetHeight() },
    { -330 }, { Top(w.preview), w.preview:GetHeight() }, { -417 }, { Top(w.uses), w.uses:GetHeight() }, { Top(w.auto), 24 },
    { -(w:GetHeight() - 14 - 24) } }
  for i = 1, #column - 1 do
    local top, height = column[i][1], column[i][2] or 14
    assert(top - height >= column[i + 1][1], "M3 : zone " .. i .. " sur la suivante")
  end
  -- six fautes et plus : trois montrées, le reste compté au bout du titre
  w.edit:SetText("a\nb\nc\nd\ne\nf") w.edit:Run("OnTextChanged")
  local _, breaks = w.problems:GetText():gsub("\n", "")
  assert(breaks == 2 and w.others:GetText() == L["et %d autres"]:format(4), w.others:GetText())
  w.edit:SetText("/cast Soins") w.edit:Run("OnTextChanged")
  assert(w.others:GetText() == "", "compte reste")
  -- aperçu coupé : texte entier dans l'infobulle
  w.preview.IsTruncated = function() return true end
  w.preview.hover:Run("OnEnter")
  assert(GameTooltip:GetText() == w.preview:GetText(), "M3 : infobulle de l'apercu")
  w.preview.hover:Run("OnLeave") w.preview.IsTruncated = nil
  -- zone d'écriture qui défile et suit le curseur
  local shift = 0
  w.scroll.GetVerticalScroll = function() return shift end
  w.scroll.SetVerticalScroll = function(_, v) shift = v end
  w.edit:Run("OnCursorChanged", 0, -150, 2, 14)
  assert(shift == 150 + 14 - w.scroll:GetHeight(), "curseur sous la zone : " .. shift)
  w.edit:Run("OnCursorChanged", 0, -10, 2, 14)
  assert(shift == 10, "curseur au-dessus : " .. shift)
  w.scroll.GetVerticalScroll, w.scroll.SetVerticalScroll = nil, nil
  w.edit:SetText(Z:FindMacro("Bijou soin").body) w.save:Run("OnClick")

  -- M4 : écran de 1365, options effacées : la consigne ne demande pas de glisser sur une ligne invisible
  local function Screen(width, height)
    UIParent.GetWidth = function() return width end UIParent.GetHeight = function() return height end
  end
  w:Hide() w:Run("OnHide")
  Screen(1365, 768)
  o.GetLeft = function() return 142 end o.GetRight = function() return 1222 end o.GetTop = function() return 738 end
  Z:ToggleOptions("Sorts et raccourcis")
  Z:OpenMacros()
  local away = L["Glissez une macro dans une barre de sorts du jeu. Pour un clic, fermez cette fenêtre : les options reviennent, cliquez alors sur le sort d'une ligne."]
  local drag = L["Glissez une macro sur une ligne du chapitre Sorts et raccourcis ou dans une barre de sorts du jeu, ou cliquez sur le sort d'une ligne."]
  assert(UI.Away() and w.hint:GetText() == away, "M4 : consigne du glisser, options effacees")
  w:Hide() w:Run("OnHide")
  assert(o:IsShown() and not UI.Away())
  Screen(2560, 1440)
  Z:OpenMacros()
  assert(not UI.Away() and w.hint:GetText() == drag, "M4 : consigne du glisser, grand ecran")
  Screen(1365, 768) FireEvent("UI_SCALE_CHANGED") -- l'écran change, fenêtre ouverte
  assert(UI.Away() and w.hint:GetText() == away, "M4 : consigne apres le changement d'ecran")
  w:Hide() w:Run("OnHide")
  o.GetLeft, o.GetRight, o.GetTop, UIParent.GetWidth, UIParent.GetHeight = nil, nil, nil, nil, nil
  for _, f in ipairs(UI.Windows()) do UI.Fit(f) end

  -- M5 : la macro ouverte a sa bordure, dans les 3 thèmes et après un changement de thème
  Z:OpenMacros("Autre")
  for _, theme in ipairs({ "CLASSIC", "MMO", "MODERN" }) do
    Z.db.windowTheme = theme Z:Refresh()
    for _, row in ipairs(w.rows) do
      local chosen = row.macro ~= nil and row.macro == w.macro
      assert(row.mark:IsShown() == chosen, "M5 : marque " .. theme .. " " .. tostring(row.macro and row.macro.name))
      if chosen then assert(row.mark[1]._color[1] == UI.accent[1], "M5 : couleur " .. theme) end
    end
  end
  -- M10 : gris et texte du thème
  w.Refresh()
  assert(w.uses:GetText():find(UI.Hex("dim"), 1, true) and not w.uses:GetText():find("8a8f99", 1, true), w.uses:GetText())
  assert(w.preview._color[1] == UI.text[1] and w.uses._color[1] == UI.text[1], "M10 : texte en dur")

  -- M6 : le champ du nom montre toujours le vrai nom
  local m = w.macro
  w.name:SetText("") w.name:Run("OnEnterPressed")
  assert(w.name:GetText() == "Autre" and m.name == "Autre", "M6 : nom vide")
  w.name:SetText(string.rep("é", 20)) w.name:Run("OnEnterPressed")
  assert(#m.name <= 32 and w.name:GetText() == m.name, "M6 : nom coupe")
  local printed
  Z.Print = function(_, text) printed = text end
  w.name:SetText("Bijou soin") w.SaveCurrent()
  Z.Print = print
  assert(printed == L["Une autre macro porte déjà ce nom."] and w.name:GetText() == m.name, "M6 : nom pris sans message")

  -- M7 : Échap ferme seulement la fenêtre du dessus
  local function Listed(name)
    for _, n in ipairs(UISpecialFrames) do if n == name then return true end end
  end
  local wiz = Z:OpenMacroWizard()
  assert(Listed("LyoruneMacroWizard") and not Listed("LyoruneMacros") and not Listed("LyoruneOptions"), "M7 : assistant")
  wiz.spell:Run("OnClick", "LeftButton") -- choix d'un sort par-dessus l'assistant
  assert(LyorunePicker:IsShown() and Listed("LyorunePicker") and not Listed("LyoruneMacroWizard"), "M7 : choix d'un sort")
  LyorunePicker:Hide()
  assert(Listed("LyoruneMacroWizard") and not Listed("LyoruneMacros"), "M7 : assistant rendu")
  wiz:Hide()
  assert(Listed("LyoruneMacros") and Listed("LyoruneOptions") and Listed("LyorunePicker"), "M7 : noms rendus")
  -- M11 c : classe sans résurrection, la suite remonte d'une ligne
  local res = Z.classRes[Z.class]
  Z.classRes[Z.class] = nil
  Z:OpenMacroWizard()
  assert(wiz:GetHeight() == 336 and wiz.tail._point[3] == wiz.tailY + 24 and not wiz.res:IsShown(), "M11 c : trou")
  wiz:Hide()
  Z.classRes[Z.class] = res
  Z:OpenMacroWizard()
  assert(wiz:GetHeight() == 360 and wiz.tail._point[3] == wiz.tailY and wiz.res:IsShown())
  wiz.opts.spell = nil wiz.Update()
  assert(wiz.spell.label:GetText():find(UI.Hex("dim"), 1, true), "M10 : Choisir... en gris du theme")
  wiz:Hide()

  -- M8 : macro tenue au curseur, fenêtre fermée : rien n'est déposé
  local dropped
  Z:MacroDragStart(w.rows[1])
  w:Hide() w:Run("OnHide")
  MOUSE_FOCI = { { dropValue = function() dropped = true end } }
  assert(not Z:MacroDragStop() and not dropped, "M8 : macro deposee apres la fermeture")
  MOUSE_FOCI = false
  -- M9 : la zone d'écriture rend le clavier à la fermeture
  assert(w.edit:GetScript("OnHide") == w.edit.ClearFocus, "M9")

  -- M11 a : l'aide suit la case
  Z:OpenMacros()
  Z.db.macroAutoTarget = false w.Refresh()
  assert(w.help:GetText() == L["{cible} est le joueur de la case."], "M11 a")
  Z.db.macroAutoTarget = true w.Refresh()
  assert(w.help:GetText():find(L["Une commande sans cible vise la case"], 1, true), "M11 a : case cochee")
  -- M11 b : plus de macros que de lignes, la molette est annoncée
  for i = 1, 14 do Z:NewMacro("Macro " .. i, "/cast Soins") end
  w.Refresh()
  assert(w.more:IsShown() and w.more:GetText() == L["Molette : %d de plus"]:format(#Z:GetMacros() - 13), w.more:GetText())
  -- M11 f : aucune macro, une phrase et aucune ligne
  Z.db.macros[Z.class] = {}
  w.macro = nil w.Refresh()
  assert(w.empty:IsShown() and not w.more:IsShown(), "M11 f")
  for _, row in ipairs(w.rows) do assert(not row:IsShown(), "M11 f : ligne vide montree") end
  -- M11 d : icônes de l'import espacées de 3
  MACROS[#MACROS + 1] = { name = "Deux", icon = 1, body = "/dance" }
  local imp = Z:OpenMacroImport()
  assert(imp.icons[2]._point[2] - imp.icons[1]._point[2] == 35, "M11 d")
  imp:Hide()
  table.remove(MACROS)
  -- M11 e : options ouvertes, Mes macros n'est plus posée par Z:OpenMacros (UI.Appear le fait) ; fermées, au milieu
  w:Hide() w:Run("OnHide")
  w._point = nil
  Z:OpenMacros()
  assert(w._point == nil, "M11 e : place posee pour rien")
  w:Hide() w:Run("OnHide")
  o:Hide() o:Run("OnHide")
  Z:OpenMacros()
  assert(w._point[1] == "CENTER", "M11 e : options fermees")
  w:Hide() w:Run("OnHide")

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh() Z:ApplyClicks()
end)

step("refonte 1.26.0, lot 6c septies e : corrections de Placement, Bug, Changes, Log et Perf (relecture)", function()
  local UI, L = Z.UI, Z.L
  local painted = UI.Painted()
  local saved = { reduceMotion = Z.db.reduceMotion, errors = Z.db.errors, perfMode = Z.db.perfMode,
    placement = CopyTable(Z.db.placement) }
  local after = C_Timer.After
  Z.db.reduceMotion = true Z:Refresh()

  -- P1 (revu en 1.40.2, C14) : la plus petite et la plus grande case tiennent dans la scène et la remplissent
  Z:OpenPlacement()
  local w = Z:PlacementWindow()
  local stage, margin = w.stage, w.STAGE_MARGIN
  for _, size in ipairs({ { Z.limits.width[1], Z.limits.height[1] }, { Z.limits.width[2], Z.limits.height[2] } }) do
    local scale = w.StageScale(size[1], size[2])
    local fitW, fitH = scale * size[1] <= stage:GetWidth() - 2 * margin + 0.001, scale * size[2] <= stage:GetHeight() - 2 * margin + 0.001
    assert(fitW and fitH, "P1 : case " .. size[1] .. "x" .. size[2] .. " hors de la scene")
    assert(math.abs(scale * size[1] - (stage:GetWidth() - 2 * margin)) < 0.001
      or math.abs(scale * size[2] - (stage:GetHeight() - 2 * margin)) < 0.001, "P1 : case " .. size[1] .. "x" .. size[2] .. " trop petite")
  end
  -- P3 : une seule mise en place à l'ouverture
  w:Hide() w:Run("OnHide")
  local draws, set = 0, w.coords.SetText
  w.coords.SetText = function(self, text) draws = draws + 1 return set(self, text) end
  Z:OpenPlacement()
  assert(draws == 1, "P3 : dessinee " .. draws .. " fois")
  w.coords.SetText = nil
  -- B2 : rappelée, elle reste ouverte
  Z:OpenPlacement()
  assert(w:IsShown(), "B2 : placement ferme au second appel")
  -- P2 : armé puis fenêtre fermée : désarmé
  C_Timer.After = function() end
  w.resetAll:Run("OnClick")
  assert(w.resetAll.armed and w.resetAll.label:GetText():find(L["Confirmer"], 1, true), "P2 : pas arme")
  w:Hide() w:Run("OnHide")
  assert(not w.resetAll.armed and w.resetAll.label:GetText() == L["Tout remettre"], "P2 : reste arme a la fermeture")
  C_Timer.After = after

  -- B1 : un nom remplacé seulement comme mot entier, nom accentué compris
  local name, exists = UnitName, UnitExists
  UnitName = function(u) if u == "player" then return "Lyo" elseif u == "party1" then return "Élyne" end end
  UnitExists = function(u) return u == "player" or u == "party1" end
  local text = Z:Anonymize("[Lyorune 1.25.1] Interface/AddOns/Lyorune/Frames.lua:12 Lyo soigne Élyne, pas Élynea ni xÉlyne. (Lyo)")
  UnitName, UnitExists = name, exists
  assert(text == "[Lyorune 1.25.1] Interface/AddOns/Lyorune/Frames.lua:12 (joueur) soigne (joueur), pas Élynea ni xÉlyne. ((joueur))",
    "B1 : " .. text)
  assert(Z:Anonymize("Mon Royaume, MonRoyaume, MonRoyaumes") == "(royaume), (royaume), MonRoyaumes", "B1 : royaume")

  -- B2 : « Signaler un bug » rappelé garde les réponses ; fermé puis rouvert, il repart à vide
  Z:ShowBug()
  local bug = LyoruneBug
  bug.answers[1]:SetText("en raid")
  Z:ShowBug()
  assert(bug:IsShown() and bug.answers[1]:GetText() == "en raid", "B2 : reponse effacee")
  bug:Hide() bug:Run("OnHide")
  Z:ShowBug()
  assert(bug.answers[1]:GetText() == "", "B2 : nouvelle ouverture")
  -- B3 : zones à copier et phrase dans les couleurs du thème
  assert(painted[bug.report][1] == "text" and painted[bug.hint][1] == "accent", "B3 : rapport")
  bug:Hide() bug:Run("OnHide")

  -- L1 : chaque titre de fenêtre a sa traduction
  local english = {}
  for key, value in pairs(Z.translations.enUS) do english[key], english[value] = true, true end
  Z:ShowLog()
  for _, f in ipairs(UI.Windows()) do -- la fenêtre d'options porte le nom de l'addon et sa version
    assert(f == UI.main or english[f.title:GetText()], "L1 : titre sans traduction : " .. f.title:GetText())
  end
  -- L2 : la phrase s'arrête au bord droit, sur deux lignes au plus
  local log = LyoruneLog
  local p = log.hint._point
  assert(p[1] == "RIGHT" and p[2] == log and p[3] == "BOTTOMRIGHT" and p[4] < 0 and p[5] == 26, "L2 : phrase sans bord droit")
  -- B3 et L4 : texte du thème, lu depuis le haut à chaque nouveau texte
  assert(painted[log.edit][1] == "text" and painted[log.hint][1] == "dim", "B3 : journal")
  local scrolled
  log.scroll.SetVerticalScroll = function(_, v) scrolled = v end
  Z.db.errors = { { message = "essai", count = 1, kind = "Erreur Lua", first = "12:00", last = "12:00" } }
  Z:ShowLog()
  assert(log:IsShown() and scrolled == 0, "L4 : journal rappele")
  -- L3 : vider demande un second clic
  scrolled = nil
  C_Timer.After = function() end
  log.clear:Run("OnClick")
  assert(#Z.db.errors == 1 and log.clear.armed, "L3 : journal vide en un clic")
  log.clear:Run("OnClick")
  assert(#Z.db.errors == 0 and scrolled == 0, "L3 : second clic")
  log.clear:Run("OnClick")
  log:Hide() log:Run("OnHide")
  assert(not log.clear.armed, "L3 : reste arme a la fermeture")
  C_Timer.After = after
  log.scroll.SetVerticalScroll = nil

  -- N1 : date dans le gris du thème, texte peint ; rappelée, lue depuis le haut
  Z:ShowNews()
  local news = LyoruneNews
  local newsText = news.text:GetText()
  assert(newsText:find("|cff" .. UI.Hex("dim"), 1, true) and not newsText:find("8a8f99", 1, true), "N1 : date en dur")
  assert(painted[news.text][1] == "text", "N1 : texte")
  scrolled = nil
  news.scroll.SetVerticalScroll = function(_, v) scrolled = v end
  Z:ShowNews()
  assert(news:IsShown() and scrolled == 0, "L4 : nouveautes")
  news.scroll.SetVerticalScroll = nil
  news:Hide() news:Run("OnHide")

  -- F3 a : virgule en français, point en anglais
  assert(Z.Decimal(0.25, 2) == "0,25" and Z.Decimal(1536 / 1024, 1) == "1,5" and Z.Decimal(12, 0) == "12", "F3 a")
  Z.db.language = "enUS" Z:SetLanguage()
  assert(Z.Decimal(0.25, 2) == "0.25" and L["%s Mo"]:format("1.5") == "1.5 MB", "F3 a : anglais")
  Z.db.language = "AUTO" Z:SetLanguage()
  -- F1, F2 : la phrase du mode sous la note, à gauche du bouton ; gris du thème, vert et or dans le texte
  Z.db.perfMode = true
  local printed, print = nil, Z.Print
  Z.Print = function(_, msg) printed = msg end
  Z:ShowMeasure()
  Z.Print = print
  local perf = LyorunePerf
  assert(perf:GetHeight() == 450, "F1 : hauteur")
  local m = perf.mode._point
  assert(m[2] == perf.profiler and m[3] == "BOTTOMLEFT" and m[5] == -8, "F1 : phrase du mode posee par le bas")
  assert(16 + perf.mode:GetWidth() < perf:GetWidth() - 16 - 150, "F1 : phrase sous le bouton")
  assert(painted[perf.profiler][1] == "dim" and painted[perf.mode][1] == "dim", "F2 : gris en dur")
  assert(perf.mode:GetText():find("^|cff73ff8c"), "F2 : vert dans le texte")
  assert(not perf.groups[1][2]:GetText():find("%d%.%d") and perf.groups[1][2]:GetText():find("%d,%d"), "F3 a : " .. perf.groups[1][2]:GetText())
  assert(printed and not printed:find("%d%.%d") and printed:find(" ms par seconde", 1, true), "F3 a : chat " .. tostring(printed))
  Z.Print = function() end
  Z:ShowMeasure()
  Z.Print = print
  assert(perf:IsShown(), "B2 : mesure rappelee")
  perf:Hide() perf:Run("OnHide")

  Z.db.errors = saved.errors
  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
end)

step("refonte 1.26.0, retours d'essai 14 et 15 : infobulle des runes, une fenetre a cote des options", function()
  local UI, L, o = Z.UI, Z.L, Z:OptionsWindow()
  local saved = { theme = Z.db.theme, texture = Z.db.texture, text = Z.db.text, reduceMotion = Z.db.reduceMotion }
  Z.db.reduceMotion = true
  -- 14 : la rune dit la valeur d'installation en mots, jamais un nom interne (« PURE », « THEME »)
  Z.db.theme, Z.db.texture, Z.db.text = "HEROIC", "Raid", "PERCENT"
  Z:Refresh()
  o:Hide() o:Run("OnHide")
  Z:ToggleOptions("Accueil")
  Z:OptionLabels()
  local seen = {}
  local function Check(rune, key)
    rune:Run("OnEnter")
    local tip = GameTooltip:GetText()
    assert(not tip:find(": %u[%u_]+$"), "14 : nom interne dans l'infobulle de " .. key .. " : " .. tip)
    seen[key] = tip
  end
  for _, chapter in ipairs(o.chapters) do
    local page = chapter.page
    for key, widget in pairs(page and page.content.settings or {}) do
      if widget.changed then
        widget.changed:Update() -- page pas encore ouverte : la rune suit le réglage à l'ouverture
        if widget.changed:IsShown() then Check(widget.changed, key) end
      end
    end
    for _, part in ipairs(page and page.parts or {}) do
      if part.widget.rows then
        part.widget:Update()
        for _, row in ipairs(part.widget.rows) do if row:IsShown() then Check(row.rune, "Accueil " .. row.key) end end
      end
    end
  end
  assert(seen["Accueil theme"] == L["Rétablir : %s"]:format(L["Épuré"]), tostring(seen["Accueil theme"]))
  assert(seen["Accueil texture"] == L["Rétablir : %s"]:format(L["Celle du thème"]), tostring(seen["Accueil texture"]))
  assert(seen.theme == seen["Accueil theme"], "14 : rune du chapitre Apparence : " .. tostring(seen.theme))

  -- 15 : la nouvelle fenêtre ferme l'ancienne ; options effacées sur un petit écran, elles restent effacées
  -- jusqu'à la fermeture de la dernière, puis reviennent
  Z:ShowBug()
  Z:ShowLog()
  assert(LyoruneLog:IsShown() and not LyoruneBug:IsShown(), "15 : bug et journal l'un sur l'autre")
  Z:ShowBug()
  assert(LyoruneBug:IsShown() and not LyoruneLog:IsShown(), "15 : dans l'autre sens")
  LyoruneBug:Hide() LyoruneBug:Run("OnHide")
  UIParent.GetWidth = function() return 1365 end UIParent.GetHeight = function() return 768 end
  o.GetLeft = function() return 142 end o.GetRight = function() return 1222 end o.GetTop = function() return 738 end
  Z:ShowBug()
  assert(UI.Away() and not o:IsShown(), "options effacees")
  Z:ShowLog()
  LyoruneBug:Run("OnHide") -- le faux client ne lance pas OnHide tout seul
  assert(not LyoruneBug:IsShown() and UI.Away() and not o:IsShown(), "15 : options revenues sous le journal")
  LyoruneLog:Hide() LyoruneLog:Run("OnHide")
  assert(not UI.Away() and o:IsShown(), "15 : options pas rendues")
  o.GetLeft, o.GetRight, o.GetTop, UIParent.GetWidth, UIParent.GetHeight = nil, nil, nil, nil, nil
  for _, f in ipairs(UI.Windows()) do UI.Fit(f) end

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
end)

step("refonte 1.26.0, lot 6c octies : retours 16, 18, 20 et 21 (visite et Mes macros)", function()
  local UI, L, o = Z.UI, Z.L, Z:OptionsWindow()
  local saved = { reduceMotion = Z.db.reduceMotion }
  Z.db.reduceMotion = true
  local function Highest(f, best)
    best = math.max(best, f:GetFrameLevel())
    for _, child in ipairs({ f:GetChildren() }) do best = Highest(child, best) end
    return best
  end

  -- 21 : l'import posé sur Mes macros passe au-dessus de tous les enfants de Mes macros, même haut placés
  local win = Z:OpenMacros()
  local deep = CreateFrame("Frame", nil, win.scroll)
  deep:SetFrameLevel(win:GetFrameLevel() + 40)
  local importer = Z:OpenMacroImport()
  assert(importer:GetFrameLevel() > Highest(win, 0), "21 : import sous un enfant de Mes macros")
  assert(importer.close:GetFrameLevel() > Highest(win, 0), "21 : croix de l'import sous Mes macros")
  local level = importer:GetFrameLevel()
  Z:OpenMacroImport() -- rappelée ouverte : elle reste au-dessus, sans monter pour rien
  assert(importer:GetFrameLevel() == level, "21 : niveau qui monte a chaque appel")
  importer:Hide()
  -- de même l'assistant de macro (capture de l'auteur), et le choix d'un sort ouvert depuis l'assistant ; fond opaque
  local wizard = Z:OpenMacroWizard()
  assert(wizard:GetFrameLevel() > Highest(win, 0), "21 : assistant sous Mes macros")
  assert(wizard.bg._color[4] == 1 and wizard.shade._color[4] == 1, "21 : fond de l'assistant transparent")
  wizard.spell:Run("OnClick")
  assert(LyorunePicker:IsShown() and LyorunePicker:GetFrameLevel() > Highest(wizard, 0), "21 : choix d'un sort sous l'assistant")
  LyorunePicker:Hide()
  wizard:Hide()

  -- 18 : un sort écrit avec d'autres accents que le grimoire est signalé, avec sa bonne écriture et un clic
  local problems = Z:CheckMacro("/cast [@cible] renovation")
  assert(problems.fixes and problems.fixes[1][2] == "Rénovation", "18 : pas de correction proposee")
  assert(problems[1][2] == L["Ligne %d : « %s » s'écrit « %s » dans votre grimoire."]:format(1, "renovation", "Rénovation"), problems[1][2])
  assert(Z:FixMacroSpelling("/cast [@cible,help] renovation; renovationx") == "/cast [@cible,help] Rénovation; renovationx",
    "18 : correction hors du mot entier")
  assert(not Z:CheckMacro("/cast Tempete").fixes, "18 : correction inventee")
  local macro = Z:NewMacro("Accents", "/cast [@cible] renovation")
  win.Select(macro)
  assert(win.fix:IsShown(), "18 : bouton Corriger absent")
  win.fix:Run("OnClick")
  assert(macro.body == "/cast [@cible] Rénovation" and win.edit:GetText() == macro.body, "18 : macro pas corrigee : " .. macro.body)
  assert(not win.fix:IsShown(), "18 : bouton Corriger reste")

  -- 20 : « Enregistrer » dit deux secondes que c'est fait, puis reprend son nom ; une autre macro le remet
  local after, later = C_Timer.After
  C_Timer.After = function(_, f) later = f end
  win.save:Run("OnClick")
  assert(win.save.label:GetText() == L["Enregistrée"], "20 : aucun signe")
  later()
  assert(win.save.label:GetText() == L["Enregistrer"], "20 : nom pas rendu")
  win.save:Run("OnClick")
  win.Select(Z:GetMacros()[1])
  assert(win.save.label:GetText() == L["Enregistrer"], "20 : « Enregistrée » garde pour une autre macro")
  later()
  C_Timer.After = after
  Z:RemoveMacro(macro)
  win.Select(Z:GetMacros()[1])

  -- 16 : la visite ferme d'abord les fenêtres posées à côté des options
  o:Hide() o:Run("OnHide")
  Z:ToggleOptions("Accueil")
  Z:OpenMacros()
  assert(win:IsShown(), "Mes macros ouverte")
  Z:StartTutorial()
  assert(not win:IsShown(), "16 : Mes macros reste ouverte sous la visite")
  local card = LyoruneTutorial
  while Z:TutorialRunning() and not o:IsShown() do card.next:Run("OnClick") end
  local chapter = Z:OptionChapter()
  -- une fenêtre à côté des options ouverte sur une carte de la fenêtre : la visite s'arrête, les options restent
  Z:OpenMacros()
  assert(not Z:TutorialRunning() and not card:IsShown() and not card.highlight:IsShown(), "16 : visite pas arretee")
  assert(o:IsShown() and win:IsShown() and Z:OptionChapter() == chapter, "16 : options pas gardees")
  win:Hide() win:Run("OnHide")
  -- petit écran : Mes macros efface les options, la visite s'arrête aussi ; les options reviennent à la fermeture
  UIParent.GetWidth = function() return 1365 end UIParent.GetHeight = function() return 768 end
  o.GetLeft = function() return 142 end o.GetRight = function() return 1222 end o.GetTop = function() return 738 end
  Z:StartTutorial()
  while Z:TutorialRunning() and not o:IsShown() do card.next:Run("OnClick") end
  Z:OpenMacros()
  assert(not Z:TutorialRunning() and not card:IsShown(), "16 : visite pas arretee (petit ecran)")
  assert(UI.Away() and not o:IsShown(), "16 : options pas effacees")
  win:Hide() win:Run("OnHide")
  assert(not UI.Away() and o:IsShown(), "16 : options pas rendues")
  o.GetLeft, o.GetRight, o.GetTop, UIParent.GetWidth, UIParent.GetHeight = nil, nil, nil, nil, nil
  for _, f in ipairs(UI.Windows()) do UI.Fit(f) end

  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh()
end)

step("refonte 1.26.0, lot 6c nonies a : retour 22 (recherche du mode test)", function()
  local L, o = Z.L, Z:OptionsWindow()
  local saved = { reduceMotion = Z.db.reduceMotion }
  o:Hide() o:Run("OnHide")
  Z:ToggleOptions("Mes soins")
  local chapter = Z:OptionChapter()
  local after, timers = C_Timer.After, {}
  C_Timer.After = function(_, f) timers[#timers + 1] = f end
  local function Find()
    o.search:SetText("mode test") o.search:Run("OnTextChanged", true)
    for _, row in ipairs(o.results.rows) do
      if row:IsShown() and row.entry.label == L["Mode test"] then return row end
    end
  end
  -- le résultat dit où sont les boutons, et les fait clignoter sans changer de chapitre
  Z.db.reduceMotion = false
  local row = Find()
  assert(row and row.label:GetText():find(L["Case témoin"], 1, true), "22 : resultat sans « Case témoin »")
  row:Run("OnClick", "LeftButton")
  local glow = o.witness.glow
  assert(Z:OptionChapter() == chapter, "22 : la recherche change de chapitre")
  assert(glow:IsShown() and not o.flash:IsShown(), "22 : boutons du mode test pas montres")
  local seen = { glow:IsShown() }
  local i = 1
  while timers[i] do timers[i]() seen[#seen + 1] = glow:IsShown() i = i + 1 end
  assert(#seen == 7 and not glow:IsShown(), "22 : clignotement : " .. #seen)
  assert(seen[2] == false and seen[3] == true, "22 : pas de clignotement")
  -- Réduire les mouvements : un seul éclat fixe ; une seconde recherche reprend la main sur la première
  Z.db.reduceMotion = true
  timers = {}
  Find():Run("OnClick", "LeftButton")
  Find():Run("OnClick", "LeftButton")
  assert(#timers == 2 and glow:IsShown(), "22 : eclat fixe : " .. #timers)
  timers[1]() assert(glow:IsShown(), "22 : le premier delai eteint le second eclat")
  timers[2]() assert(not glow:IsShown(), "22 : eclat jamais eteint")
  C_Timer.After = after
  for key, value in pairs(saved) do Z.db[key] = value end
end)

step("refonte 1.26.0, lot 6c nonies b : retour 23 (aucun element hors de la case)", function()
  local keys = { "shape", "width", "height", "corners", "manaBars", "hotStyle", "hotCount", "debuffCount",
    "privateAuraPoint", "privateAuraSize", "fontSize", "autoShrink" }
  local saved = { placement = CopyTable(Z.db.placement), cornerSpells = Z.db.cornerSpells[Z.class] }
  for _, key in ipairs(keys) do saved[key] = Z.db[key] end
  local b = Z.buttons[1]
  -- Place d'un élément recalculée à partir des ancres notées par le faux client, sans passer par Placement.lua.
  -- Rectangle { gauche, droite, bas, haut }, (0, 0) en bas à gauche de la case.
  local W, H
  local function Spot(r, point)
    local x = point:find("LEFT") and r[1] or point:find("RIGHT") and r[2] or (r[1] + r[2]) / 2
    local y = point:find("BOTTOM") and r[3] or point:find("TOP") and r[4] or (r[3] + r[4]) / 2
    return x, y
  end
  local Rect
  local function Anchor(region, p)
    local relative, relPoint, x, y
    if type(p[2]) == "table" then
      relative = p[2]
      if type(p[3]) == "string" then relPoint, x, y = p[3], p[4], p[5] else relPoint, x, y = p[1], p[3], p[4] end
    else
      relative, relPoint, x, y = region._parent, p[1], p[2], p[3]
    end
    local px, py = Spot(Rect(relative), relPoint)
    return px + (x or 0), py + (y or 0)
  end
  function Rect(region)
    if region == b then return { 0, W, 0, H } end
    if region._all then return Rect(region._all) end
    local points = region._points
    assert(points, "element sans ancre")
    if points.TOPLEFT and points.BOTTOMRIGHT then
      local left, top = Anchor(region, points.TOPLEFT)
      local right, bottom = Anchor(region, points.BOTTOMRIGHT)
      return { left, right, bottom, top }
    end
    local p = region._point
    local x, y = Anchor(region, p)
    local w, h = region._w, region._kind == "FontString" and region._size or region._h
    local left = p[1]:find("LEFT") and x or p[1]:find("RIGHT") and x - w or x - w / 2
    local bottom = p[1]:find("BOTTOM") and y or p[1]:find("TOP") and y - h or y - h / 2
    return { left, left + w, bottom, bottom + h }
  end
  -- Les morceaux de chaque élément, posés comme sur les vraies cases
  local function Parts(key)
    if key == "hots" then
      local row = {}
      for i = 1, Z.db.hotCount do row[i] = Z.db.hotStyle == "BARS" and Z.HotBar(b, i) or Z.HotIcon(b, i) end
      return row
    elseif key == "debuffs" then
      local row = {}
      for i = 1, Z.db.debuffCount do row[i] = Z.DebuffIcon(b, i) end
      return row
    elseif key == "big" then return { Z.BigIcon(b) }
    elseif key == "buff" then return { Z.BuffIcon(b) }
    elseif key == "defensives" then
      local row = {}
      for i = 1, Z.DEFENSIVE_COUNT do row[i] = Z.DefensiveIcon(b, i) end
      return row
    elseif key == "controls" then return { Z.ControlIcon(b) }
    elseif key == "dispelType" then return { Z.DispelTypeIcon(b) }
    elseif key == "private" then return { (Z.PrivateHolder(b)) } end
    return { b[key] }
  end
  local function Rects(power)
    b.powerShown = power
    Z.StyleButton(b)
    W, H = Z.CellSize()
    local all = {}
    for _, element in ipairs(Z.placeElements) do
      all[element[1]] = {}
      for i, part in ipairs(Parts(element[1])) do all[element[1]][i] = Rect(part) end
    end
    return all
  end
  local function Push(x, y)
    Z.db.placement = {}
    for _, element in ipairs(Z.placeElements) do Z.SetOffset(element[1], x, y) end
    Z:Refresh()
  end
  -- Chaque élément poussé au plus loin, dans les 8 directions : jamais plus loin que la case (ou que sa place
  -- d'origine, quand il y dépasse déjà, comme le marqueur à cheval sur le haut)
  local PUSHES = { { 40, 0 }, { -40, 0 }, { 0, 40 }, { 0, -40 }, { 40, 40 }, { -40, 40 }, { 40, -40 }, { -40, -40 } }
  local checked, moved = 0, {}
  local function Check(label)
    for _, power in ipairs({ false, true }) do
      Push(0, 0)
      local home = Rects(power)
      for _, push in ipairs(PUSHES) do
        Push(push[1], push[2])
        local now = Rects(power)
        for key, parts in pairs(now) do
          for i, r in ipairs(parts) do
            local o = home[key][i]
            local where = label .. ", " .. key .. " " .. i .. (power and ", mana" or "") .. ", pousse " .. push[1] .. "," .. push[2]
            assert(r[1] >= math.min(0, o[1]) - 0.01 and r[2] <= math.max(W, o[2]) + 0.01
              and r[3] >= math.min(0, o[3]) - 0.01 and r[4] <= math.max(H, o[4]) + 0.01,
              "23 : hors de la case : " .. where .. string.format(" (%.1f %.1f %.1f %.1f dans %dx%d)", r[1], r[2], r[3], r[4], W, H))
            if math.abs(r[1] - o[1]) >= 1 or math.abs(r[3] - o[3]) >= 1 then moved[key] = true end
            checked = checked + 1
          end
        end
      end
    end
  end
  Z.db.manaBars, Z.db.autoShrink = "ALL", false
  for _, shape in ipairs({ "BAR", "TILE", "SQUARE", "BANNER" }) do
    Z.db.shape = shape
    local default = Z.shapes[shape]
    local sizes = { { default.width, default.height }, { Z.limits.width[1], Z.limits.height[1] },
      { Z.limits.width[2], Z.limits.height[2] }, { Z.limits.width[1], Z.limits.height[2] } }
    for _, size in ipairs(sizes) do
      Z.db.width, Z.db.height = size[1], size[2]
      Z.db.corners, Z.db.hotStyle, Z.db.hotCount, Z.db.debuffCount = "SQUARE", "ICONS", 2, 2
      Z.db.privateAuraPoint, Z.db.privateAuraSize, Z.db.fontSize = "CENTER", 20, default.fontSize
      Z.db.cornerSpells[Z.class] = nil
      Check(shape .. " " .. size[1] .. "x" .. size[2])
      -- Autres réglages : angles arrondis, coins pris, barres fines, rangées longues, auras privées en haut
      Z.db.corners, Z.db.hotStyle, Z.db.hotCount, Z.db.debuffCount = "ROUND", "BARS", 6, 5
      Z.db.privateAuraPoint, Z.db.privateAuraSize, Z.db.fontSize = "TOP", 40, Z.limits.fontSize[2]
      Z.db.cornerSpells[Z.class] = { TOPLEFT = "Rénovation", TOPRIGHT = "Rénovation", BOTTOMRIGHT = "Rénovation", BOTTOMLEFT = "Rénovation" }
      Check(shape .. " " .. size[1] .. "x" .. size[2] .. " variante")
    end
  end
  for _, element in ipairs(Z.placeElements) do assert(moved[element[1]], "23 : " .. element[1] .. " ne bouge plus du tout") end
  assert(checked > 5000, "23 : trop peu de verifications : " .. checked)

  -- Le nom rétrécit près du bord au lieu d'en sortir, et garde trois tailles de police de large
  Z.db.shape, Z.db.width, Z.db.height, Z.db.fontSize = "TILE", 86, 42, 11
  Z.db.corners, Z.db.hotStyle, Z.db.hotCount, Z.db.debuffCount = "SQUARE", "ICONS", 2, 2
  Z.db.cornerSpells[Z.class] = nil
  Push(0, 0)
  Z.StyleButton(b)
  -- C34 : le nom est raccourci des deux côtés par l'icône du type à dissiper, au début de sa ligne
  local nameW = Z.AuraRows().homes.name.w
  assert(nameW == 86 - 2 * (3 + Z.AuraRows().homes.dispelType.w + 2), "23 : nom raccourci par le type a dissiper : " .. nameW)
  assert(b.name._w == nameW and b.text._w == 78, "23 : largeur d'origine du nom : " .. tostring(b.name._w))
  Z.db.placement = {} Z.SetOffset("name", -40, 0) Z:Refresh()
  local x = Z.Offset("name")
  assert(x < 0 and x > -40 and b.name._w < nameW and b.name._w >= 33, "23 : nom pousse a gauche : " .. x .. ", largeur " .. b.name._w)
  -- Ancien décalage trop grand dans la sauvegarde : ramené au bord à la lecture, jamais réécrit
  Z.db.placement = { TILE = { name = { -40, 0 } } } Z:Refresh()
  assert(Z.Offset("name") == x and Z.db.placement.TILE.name[1] == -40, "23 : sauvegarde reecrite")
  -- Le chef de groupe suit l'icône de rôle poussée au bord gauche : il est repoussé dans la case
  Z.db.placement = { TILE = { role = { -40, 0 } } } Z:Refresh()
  W, H = Z.CellSize()
  local leader = Rect(b.leader)
  assert(leader[1] >= 0, "23 : chef de groupe hors de la case : " .. leader[1])
  -- Une autre forme (code de partage) : seulement les limites du réglage
  Z.SetOffset("debuffs", -40, 12, "BAR")
  assert(Z.db.placement.BAR.debuffs[1] == -40, "23 : autre forme bornee a la case choisie")

  -- Éditeur : rangées entières, et « au bord » quand une flèche ne pousse plus
  Z.db.placement = {} Z.db.hotCount = 4 Z:Refresh()
  Z:OpenPlacement()
  local w = Z:PlacementWindow()
  for _, button in ipairs(w.list) do if button.key == "hots" then button:Run("OnClick") end end
  local shown = 0
  for _, icon in ipairs(w.cell.hots) do if icon:IsShown() then shown = shown + 1 end end
  assert(shown == 4, "23 : editeur, rangee de soins : " .. shown) -- 3 soins et Ame affaiblie (pretre)
  for _ = 1, 30 do w.up:Run("OnClick") end
  local _, top = Z.Offset("hots")
  assert(top == select(4, Z.OffsetRange("hots")), "23 : fleche au dela du bord")
  assert(w.coords:GetText() == Z.L["Au bord de la case : %d, %d"]:format(0, top), "23 : bord pas signale : " .. w.coords:GetText())
  w:Hide() w:Run("OnHide")

  Z.db.placement = saved.placement
  Z.db.cornerSpells[Z.class] = saved.cornerSpells
  for _, key in ipairs(keys) do Z.db[key] = saved[key] end
  Z:Refresh()
end)

step("refonte 1.26.0, lot 6c nonies c : retour 19 (macros de Mes macros dans les barres du jeu)", function()
  local L = Z.L
  local function find(name) local i = GetMacroIndexByName(name) return i > 0 and GetMacroBody(i) or nil end
  local function printed(text) for i = #PRINTED, 1, -1 do if PRINTED[i]:find(text, 1, true) then return true end end end
  -- le jeu limite une macro (et le texte d'un bouton) à 255 caractères depuis le patch 11.0.2
  assert(Z.MACRO_MAX == 255, "limite des macros")
  local long = "/cast " .. string.rep("a", 260)
  assert(Z:CheckMacro(long)[1][1] == "err", "macro de plus de 255 caracteres acceptee")
  -- texte pour une barre : le joueur survolé, sinon la cible
  local cases = {
    { "/cast [@cible] Soins rapides", "#showtooltip\n/cast [@mouseover,help][] Soins rapides" },
    { "/cast [@cible,harm,nodead] Châtiment; [@cible] Soins", "#showtooltip\n/cast [@mouseover,harm,nodead][harm,nodead] Châtiment; [@mouseover,help][] Soins" },
    { "/cast [@mouseover,help][@player] Soins", "#showtooltip\n/cast [@mouseover,help][help][@player] Soins" },
    { "#showtooltip Soins\n/cast [@player] Soins", "#showtooltip Soins\n/cast [@player] Soins" },
    { "/use 13\n/focus [@mouseover]", "#showtooltip\n/use 13\n/focus [@mouseover]" },
    { "/use [@cible] 13", "#showtooltip\n/use [@mouseover,exists][] 13" },
  }
  for _, case in ipairs(cases) do
    assert(Z:BarText(case[1]) == case[2], "texte de barre : " .. Z:BarText(case[1]))
  end
  -- une macro qui tient sur un clic mais pas dans une barre : signalée en jaune
  local near = "/cast [@cible] " .. string.rep("b", 232)
  local warned
  for _, problem in ipairs(Z:CheckMacro(near)) do
    assert(problem[1] ~= "err", "erreur sur une macro de 251 caracteres : " .. problem[2])
    if problem[2]:find("barre de sorts", 1, true) then warned = problem[1] end
  end
  assert(#Z:ResolveMacro(near) <= 255 and #Z:BarText(near) > 255 and warned == "warn", "avertissement de la barre")

  local before = #MACROS
  local m = Z:NewMacro("Prière vite", "/cast [@cible] Prière")
  -- glisser : copie « Lyo: » créée, mise en main, montrée dans la fenêtre
  local ok = Z:PickupGameCopy(m)
  assert(ok and PICKED == "Lyo:Prière vite" and find("Lyo:Prière vite") == "#showtooltip\n/cast [@mouseover,help][] Prière", tostring(find("Lyo:Prière vite")))
  assert(#MACROS == before + 1 and Z:GameCopy(m) == "Lyo:Prière vite")
  ClearCursor()
  local w = Z:OpenMacros("Prière vite")
  assert(w.uses:GetText():find(L["copie dans /macro : %s"]:format("Lyo:Prière vite"), 1, true), w.uses:GetText())
  assert(w.hint:GetText():find("barre de sorts", 1, true), "consigne sans la barre")
  -- glissée une seconde fois : la même copie, pas une nouvelle
  assert(Z:PickupGameCopy(m) and #MACROS == before + 1, "copie en double")
  ClearCursor()
  -- le texte change : la copie suit
  m.body = "/cast [@cible] Soins rapides" Z:ApplyClicks()
  assert(find("Lyo:Prière vite") == "#showtooltip\n/cast [@mouseover,help][] Soins rapides", "copie pas mise a jour")
  -- en combat : rien n'est touché, tout est rattrapé à la fin
  COMBAT = true
  local held, why = Z:PickupGameCopy(m)
  assert(not held and why == L["impossible de modifier les macros en combat."], "copie en combat")
  m.body = "/cast [@cible] Rénovation" Z:ApplyClicks()
  assert(find("Lyo:Prière vite"):find("Soins rapides", 1, true), "copie modifiee en combat")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  assert(find("Lyo:Prière vite"):find("Rénovation", 1, true), "copie pas rattrapee apres le combat")
  -- renommée : la copie suit, au même emplacement de /macro (EditMacro, pas une nouvelle)
  assert(Z:RenameMacro(m, "Prière"))
  assert(Z:GameCopy(m) == "Lyo:Prière" and not find("Lyo:Prière vite") and #MACROS == before + 1, "renommage de la copie")
  -- la copie déposée sur une ligne de Lyorune ou sur la liste redevient la macro, sans doublon
  assert(Z:ImportGameMacro(GetMacroIndexByName("Lyo:Prière")) == m and not Z:FindMacro("Lyo:Prière"), "copie importee en double")
  -- « Retirer les macros de Lyorune » (option des clics) laisse les copies glissées
  Z.db.actionBarMacros = true Z:ApplyClicks()
  Z.db.actionBarMacros = false Z:RemoveBarMacros()
  assert(find("Lyo:Prière"), "copie retiree avec l'option des clics")
  -- deux macros au début de nom pareil : deux copies distinctes de 16 octets au plus
  local a, b = Z:NewMacro("Soins rapides A", "/cast Soins"), Z:NewMacro("Soins rapides B", "/cast Soins")
  assert(Z:PickupGameCopy(a) and Z:PickupGameCopy(b))
  assert(Z:GameCopy(a) ~= Z:GameCopy(b) and #Z:GameCopy(a) <= 16 and #Z:GameCopy(b) <= 16, Z:GameCopy(a) .. " / " .. Z:GameCopy(b))
  ClearCursor()
  -- trop longue pour une barre : refusée avec sa raison, elle se pose encore sur nos lignes
  local big = Z:NewMacro("Longue", near)
  held, why = Z:PickupGameCopy(big)
  assert(not held and why and why:find("Longue", 1, true) and not Z:GameCopy(big), "copie trop longue")
  -- plus de place dans l'onglet du personnage : refus clair
  local saved = #MACROS
  for i = #MACROS + 1, MAX_CHARACTER_MACROS do MACROS[i] = { name = "Perso " .. i, icon = 1, body = "/dance" } end
  local c = Z:NewMacro("Pleine", "/cast Soins")
  held, why = Z:PickupGameCopy(c)
  assert(not held and why == L["plus de place pour une macro de personnage : supprimez-en une dans /macro."], "places pleines")
  for i = #MACROS, saved + 1, -1 do MACROS[i] = nil end
  -- supprimée de Mes macros : sa copie part ; retirée à la main de /macro : jamais recréée
  Z:RemoveMacro(a)
  assert(not find(Z.char.barCopies["Soins rapides A"] or "Lyo:Soins rapide") and Z.char.barCopies["Soins rapides A"] == nil, "copie restee apres la suppression")
  local copyB = Z:GameCopy(b)
  table.remove(MACROS, GetMacroIndexByName(copyB) - 120)
  Z:ApplyClicks()
  assert(not find(copyB) and Z.char.barCopies["Soins rapides B"] == nil, "copie retiree a la main recreee")
  -- une macro du joueur n'est jamais touchée
  MACROS[#MACROS + 1] = { name = "Lyo:Perso", icon = 1, body = "/dance" }
  Z:RemoveMacro(m)
  assert(not find("Lyo:Prière"), "copie restee")
  assert(not Z:GameCopy(m), "copie de la macro supprimee")
  assert(MACROS[#MACROS].body == "/dance", "macro du joueur touchee")
  table.remove(MACROS)
  -- clic avec bijou : 255 caractères au plus, une longue macro part sans la ligne du bijou
  local button, trigger = Z.buttons[1], { kind = "click", key = "shift-3" }
  Z:SetClick("shift-3", "@macro:Longue")
  if not Z:HasTrinket(trigger, 1) then Z:ToggleTrinket(trigger, 1) end
  local sent = button:GetAttribute("shift-macrotext3")
  assert(sent == Z:ResolveMacro(near) and #sent <= 255, "bijou en trop : " .. #tostring(sent))
  Z:SetClick("shift-3", "@macro:Pleine")
  assert(button:GetAttribute("shift-macrotext3"):find("^/use %[@mouseover,nodead%] 13"), "bijou perdu sur une macro courte")
  Z:ToggleTrinket(trigger, 1) Z:SetClick("shift-3", nil)
  for _, x in ipairs({ b, big, c }) do Z:RemoveMacro(x) end
  assert(#MACROS == before, "macros restantes : " .. #MACROS)
  w:Hide()
end)

step("etape 21, lot 2 : icones a la mesure de chaque forme (Barre, Tuile, Carre, Bandeau), raid de 40", function()
  local keys = { "shape", "width", "height", "corners", "manaBars", "hotStyle", "hotCount", "debuffCount", "fontSize",
    "powerHeight", "autoShrink", "showHots", "showDebuffs", "debuffMode" }
  local saved = { placement = CopyTable(Z.db.placement), cornerSpells = Z.db.cornerSpells[Z.class], members = MEMBERS }
  for _, key in ipairs(keys) do saved[key] = Z.db[key] end
  local b = Z.buttons[1]
  Z.db.placement = {} Z.db.cornerSpells[Z.class] = nil
  Z.db.corners, Z.db.hotStyle, Z.db.manaBars, Z.db.autoShrink = "SQUARE", "ICONS", "ALL", true
  Z.db.showHots, Z.db.showDebuffs, Z.db.debuffMode = true, true, "ALL"
  -- Rectangles { gauche, droite, bas, haut } des icônes d'une rangée, (0, 0) en bas à gauche de la case
  local function Icons(row, n, W, H, hp)
    local frame = row.relative == "HP" and hp or { 0, W, 0, H }
    local ax = row.point:find("LEFT") and frame[1] or frame[2]
    local ay = row.point:find("TOP") and frame[4] or frame[3]
    local list = {}
    for i = 1, n do
      local column, line = (i - 1) % row.perLine, math.floor((i - 1) / row.perLine)
      local x = ax + row.x + row.dirX * column * (row.size + 2)
      local y = ay + row.y + row.dirY * line * (row.size + 2)
      local left = row.dirX > 0 and x or x - row.size
      local bottom = row.dirY > 0 and y or y - row.size
      list[i] = { left, left + row.size, bottom, bottom + row.size }
    end
    return list
  end
  local function Overlap(a, c)
    return math.min(a[2], c[2]) - math.max(a[1], c[1]) > 0.01 and math.min(a[4], c[4]) - math.max(a[3], c[3]) > 0.01
  end
  local checked = 0
  for _, members in ipairs({ 5, 40 }) do
    MEMBERS = members
    for _, shape in ipairs({ "BAR", "TILE", "SQUARE", "BANNER" }) do
      Z:ApplyShape(shape)
      local rules = Z.shapes[shape].auras
      for hots = 1, 6 do
        for debuffs = 2, 5 do
          Z.db.hotCount, Z.db.debuffCount = hots, debuffs
          Z.ForgetPlacementRanges()
          b.powerShown = true
          Z.StyleButton(b)
          local W, H = Z.CellSize()
          local where = shape .. ", " .. hots .. " soins, " .. debuffs .. " affaiblissements, groupe de " .. members
          local rows = Z.AuraRows()
          local inset = Z.UI.Inset(Z:Theme().borderSize, false)
          local hp = { inset, W - inset, inset + Z.PowerHeight() + 1, H - inset }
          local icon = Z.IconSize()
          local h, d = Icons(rows.hots, Z.HotSlots(), W, H, hp), Icons(rows.debuffs, debuffs, W, H, hp)
          assert(rows.hots.lines <= 2 and rows.debuffs.lines <= 2, "plus de deux lignes : " .. where)
          assert(rows.hots.size <= math.floor(H * rules.size + 0.5) and rows.hots.size >= 5, "taille des soins : " .. where)
          for _, list in ipairs({ h, d }) do
            for _, r in ipairs(list) do
              assert(r[1] >= 0 and r[2] <= W and r[3] >= 0 and r[4] <= H,
                "icone hors de la case : " .. where .. string.format(" (%d %d %d %d dans %dx%d)", r[1], r[2], r[3], r[4], W, H))
              checked = checked + 1
            end
          end
          for _, r in ipairs(h) do
            for _, o in ipairs(d) do assert(not Overlap(r, o), "soins sur les affaiblissements : " .. where) end
          end
          if not rules.inline then
            -- Tuile et Carré : les soins s'arrêtent avant l'icône de rôle, les affaiblissements avant le buff manquant
            local roleW, buffW = rows.homes.role.w, rows.buffW
            local role = { W - 2 - roleW, W - 2, H - 2 - roleW, H - 2 }
            local buff = { 2, 2 + buffW, 2, 2 + buffW }
            for _, r in ipairs(h) do assert(not Overlap(r, role), "soins sous l'icone de role : " .. where) end
            for _, r in ipairs(d) do assert(not Overlap(r, buff), "affaiblissements sous le buff manquant : " .. where) end
          else
            local lineW = math.floor(W * rules.hotLine)
            assert(rows.hots.width <= lineW or rows.hots.size == 5, "rangee trop large : " .. where)
            if rules.inline == "EDGES" then
              -- Barre : la ligne du texte, au milieu de la barre de vie, reste libre (sauf icônes déjà à leur plus
              -- petite taille, 5 pixels, dans une case de raid de 40 très basse : le texte reste devant elles)
              local middle, cap = (hp[3] + hp[4]) / 2, math.ceil(Z.db.fontSize * 0.72)
              for _, r in ipairs(h) do assert(rows.hots.size == 5 or r[3] >= middle + cap / 2 - 0.51, "soins sur la ligne du texte : " .. where) end
              for _, r in ipairs(d) do assert(rows.debuffs.size == 5 or r[4] <= middle - cap / 2 + 0.51, "affaiblissements sur le texte : " .. where) end
            else
              -- Bandeau : le chiffre de vie se range à gauche du bloc, le nom s'arrête avant lui
              local textRight = hp[2] + rows.textX
              for _, list in ipairs({ h, d }) do
                for _, r in ipairs(list) do assert(textRight <= r[1] - 4, "chiffre de vie sur le bloc : " .. where) end
              end
              assert(b.text._point[1] == "RIGHT" and b.text._point[2] == b.hp and b.text._point[4] == rows.textX, "chiffre de vie pas pose : " .. where)
              local name = rows.homes.name
              assert(name.w == Z.db.fontSize or inset + name.x + name.w <= textRight - rows.textW, "nom sur le chiffre de vie : " .. where)
            end
          end
          -- Les icônes posées sur la case sont celles calculées (ancien affichage, mode test, éditeur)
          for i = 1, hots do
            local p = Z.HotIcon(b, i)._point
            assert(p[1] == rows.hots.point and p[2] == (rows.hots.relative == "HP" and b.hp or b.over) and Z.HotIcon(b, i)._w == rows.hots.size,
              "soin " .. i .. " mal pose : " .. where)
          end
          local last = Z.DebuffIcon(b, debuffs)._point
          local column, line = (debuffs - 1) % rows.debuffs.perLine, math.floor((debuffs - 1) / rows.debuffs.perLine)
          assert(last[4] == rows.debuffs.x + rows.debuffs.dirX * column * (rows.debuffs.size + 2)
            and last[5] == rows.debuffs.y + rows.debuffs.dirY * line * (rows.debuffs.size + 2), "dernier affaiblissement : " .. where)
          -- Les bornes de l'éditeur décrivent la même rangée
          local left, right = Z.OffsetRange("hots")
          assert(left <= 0 and right >= 0, "editeur : rangee de soins hors de ses bornes : " .. where)
        end
      end
    end
  end
  assert(checked == 1376, "nombre de verifications : " .. checked) -- avec la place d'Ame affaiblie apres un seul soin (pretre, etape 23)
  MEMBERS = 5

  -- Tailles d'origine des formes (C34 : trois bandes en Tuile et Carré, rien ne se couvre ; barre de mana)
  local function At(shape, hots, debuffs)
    Z:ApplyShape(shape) Z.db.hotCount, Z.db.debuffCount = hots, debuffs
    return Z.AuraRows()
  end
  local r = At("TILE", 4, 2)
  assert(r.mode == "LINE" and r.hots.size == 9 and r.debuffs.size == 9 and r.hots.lines == 1 and r.hots.point == "TOPLEFT"
    and r.debuffs.point == "BOTTOMRIGHT", "Tuile : 9 pixels, vie sous le nom")
  r = At("SQUARE", 4, 2)
  assert(r.hots.size == 6 and r.hots.perLine == 2 and r.hots.lines == 2 and r.debuffs.size == 10, "Carre : soins sur deux lignes")
  r = At("SQUARE", 2, 5)
  assert(r.debuffs.lines == 2 and r.debuffs.size < 10, "Carre : 5 affaiblissements, deux lignes et plus petits")
  r = At("BAR", 4, 2)
  assert(r.hots.size == 7 and r.hots.point == "TOPRIGHT" and r.hots.relative == "HP" and r.textX == -4, "Barre : 7 pixels")
  r = At("BANNER", 4, 2)
  assert(r.hots.size == 9 and r.debuffs.size == 9 and r.textX < -4, "Bandeau : 9 pixels, chiffre de vie a gauche")
  -- Bandeau : seules les rangées montrées comptent pour le bloc
  local blockX = r.textX
  Z.db.showHots = false
  assert(At("BANNER", 4, 2).textX > blockX, "Bandeau : soins coupes, le chiffre de vie se rapproche du bord")
  Z.db.showHots, Z.db.showDebuffs = false, false
  assert(At("BANNER", 4, 2).textX == -4, "Bandeau : rien a montrer, chiffre de vie au bout")
  Z.db.showHots, Z.db.showDebuffs = true, true
  -- Une rangée trop longue rapetisse au lieu de sortir de la case
  r = At("TILE", 6, 2)
  assert(r.hots.lines == 1 and r.hots.size < 11, "Tuile : 6 soins rapetisses")
  -- Le jeu ne sait pas passer à la ligne : le Carré rapetisse sur une ligne
  AuraContainerSortMethod = { Default = 0 }
  AnchorUtil = { FlowDirection = { Right = 1, Left = 2, Up = 3, Down = 4 } }
  Enum.CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 1 }
  Z.boxWrap = false
  local ok, err = pcall(function()
    local small = At("SQUARE", 4, 2)
    assert(small.hots.lines == 1 and small.hots.size < 10, "Carre sans passage a la ligne : " .. small.hots.lines .. " lignes")
    Z.boxWrap = true
    assert(At("SQUARE", 4, 2).hots.lines == 2, "Carre : passage a la ligne du jeu")
  end)
  AuraContainerSortMethod, AnchorUtil, Enum.CustomAuraButtonDispelTypeTextureStyle, Z.boxWrap = nil, nil, nil, nil
  assert(ok, err)
  -- Une forme ajoutée sans « auras » prend les règles de la Tuile
  Z.shapes.TEST = { width = 80, height = 40, fontSize = 10, powerHeight = 3 }
  Z.db.shape = "TEST"
  ok, err = pcall(Z.AuraRows)
  Z.shapes.TEST = nil
  assert(ok and err.hots.point == "TOPLEFT", "forme sans regles d'icones : " .. tostring(err))

  -- Remise à zéro unique des décalages des icônes (et du chiffre de vie en Bandeau), à l'arrivée de la 1.27.0
  local savedDB, savedChar, version = LyoruneDB, LyoruneCharDB, Z.version
  local db = { lastVersion = "1.26.0", placement = { BAR = { hots = { 3, 1 }, name = { 2, 0 } },
    BANNER = { text = { 4, 0 }, debuffs = { 1, 1 } }, TILE = { hots = { 5, 5 } }, SQUARE = { debuffs = { 1, 1 } } } }
  LyoruneDB = db
  Z.version = "1.26.0" FireEvent("ADDON_LOADED", "Lyorune")
  assert(db.placement.BAR.hots, "remise a zero avant la 1.27.0")
  Z.version = "1.27.0" FireEvent("ADDON_LOADED", "Lyorune")
  assert(db.placement.BAR.hots == nil and db.placement.BAR.name[1] == 2, "Barre : decalages des icones remis a zero, nom garde")
  assert(db.placement.BANNER == nil and db.placement.SQUARE == nil, "Bandeau et Carre remis a zero")
  assert(db.placement.TILE.hots[1] == 5, "Tuile : place d'origine inchangee, decalage garde")
  db.lastVersion = "1.27.0" db.placement.BAR.hots = { 3, 1 } FireEvent("ADDON_LOADED", "Lyorune")
  assert(db.placement.BAR.hots[1] == 3, "remise a zero refaite")
  Z.version = version
  LyoruneDB, LyoruneCharDB = savedDB, savedChar
  FireEvent("ADDON_LOADED", "Lyorune")

  Z.db.placement = saved.placement
  Z.db.cornerSpells[Z.class] = saved.cornerSpells
  MEMBERS = saved.members
  for _, key in ipairs(keys) do Z.db[key] = saved[key] end
  Z:Refresh()
end)

step("etape 21, lot 3 : taille de chaque element dans l'editeur de placement (50 a 200 %, par forme, partage, combat)", function()
  local keys = { "shape", "width", "height", "corners", "manaBars", "hotStyle", "hotCount", "debuffCount", "fontSize",
    "powerHeight", "autoShrink", "showHots", "showDebuffs", "debuffMode" }
  local saved = { placement = CopyTable(Z.db.placement), cornerSpells = Z.db.cornerSpells[Z.class], members = MEMBERS }
  for _, key in ipairs(keys) do saved[key] = Z.db[key] end
  local b, L = Z.buttons[1], Z.L
  Z.db.placement = {} Z.db.cornerSpells[Z.class] = nil
  Z.db.corners, Z.db.hotStyle, Z.db.manaBars, Z.db.autoShrink = "SQUARE", "ICONS", "ALL", true
  Z.db.showHots, Z.db.showDebuffs, Z.db.debuffMode = true, true, "ALL"
  Z:ApplyShape("TILE")
  local icon = Z.IconSize()

  -- Réglage : taille gardée avec le décalage, bornée, effacée à 100 %
  assert(Z.GetElementSize("role") == 100 and Z.ElementScale("role") == 1, "taille d'origine")
  local roleBase = b.role._w -- taille d'origine (C34 : jamais plus haute que la bande du haut)
  assert(roleBase <= icon - 2, "icone de role plus grande qu'avant : " .. roleBase)
  Z.SetElementSize("role", 150) Z:Refresh()
  assert(Z.db.placement.TILE.role[1] == 0 and Z.db.placement.TILE.role[3] == 150, "taille enregistree")
  assert(b.role._w == math.floor(roleBase * 1.5 + 0.5), "icone de role agrandie : " .. b.role._w)
  Z.SetOffset("role", -3, -1)
  assert(Z.db.placement.TILE.role[3] == 150 and Z.db.placement.TILE.role[1] == -3, "le decalage garde la taille")
  Z.SetOffset("role", 0, 0)
  assert(Z.db.placement.TILE.role and Z.db.placement.TILE.role[3] == 150, "place d'origine : la taille reste")
  Z.SetElementSize("role", 100)
  assert(Z.db.placement.TILE == nil, "place et taille d'origine : entree effacee")
  Z.SetElementSize("marker", 500) assert(Z.GetElementSize("marker") == 300, "300 % au plus")
  Z.SetElementSize("marker", 10) assert(Z.GetElementSize("marker") == 50, "50 % au moins")
  Z:Refresh()
  assert(b.marker._w == math.floor(icon * 0.5 + 0.5), "marqueur rapetisse")
  Z.SetElementSize("marker", 100)
  -- Le nom, le texte de vie et les auras privées gardent leur propre réglage ; les barres fines leur épaisseur
  for _, key in ipairs({ "name", "text", "private" }) do
    Z.SetElementSize(key, 150)
    assert(not Z.CanSize(key) and Z.GetElementSize(key) == 100 and Z.ElementScale(key) == 1, "taille de " .. key)
  end
  assert(Z.db.placement.TILE == nil, "taille d'un texte enregistree")
  Z.db.hotStyle = "BARS" assert(not Z.CanSize("hots"), "barres fines") Z.db.hotStyle = "ICONS"
  -- Chaque forme garde ses tailles
  local bigBase = Z.BigIconSize() -- C34 : jamais plus haute que le milieu de la case
  assert(bigBase <= math.floor(icon * 1.6 + 0.5), "grande icone plus grande qu'avant")
  Z.SetElementSize("big", 150)
  Z:ApplyShape("BAR")
  assert(Z.GetElementSize("big") == 100 and Z.GetElementSize("big", "TILE") == 150, "taille propre a chaque forme")
  Z:ApplyShape("TILE") Z:Refresh()
  assert(Z.BigIcon(b)._w == Z.BigIconSize() and Z.BigIconSize() == math.floor(bigBase * 1.5 + 0.5), "grande icone")
  Z.SetElementSize("big", 100)
  -- Jamais plus grand que la case
  Z:ApplyShape("BANNER")
  Z.SetElementSize("center", 200) Z:Refresh()
  local W, H = Z.CellSize()
  assert(b.center._w <= math.min(W, H), "icone centrale plus grande que la case")
  local left, right, low, high = Z.OffsetRange("center")
  assert(left <= right and low <= high, "bornes a l'envers")
  Z.SetElementSize("center", 100)
  -- Sur une ligne, le nom part après l'icône de rôle, à sa taille
  Z:ApplyShape("BAR")
  Z.SetElementSize("role", 150) Z:Refresh()
  local homes = Z.AuraRows().homes
  local nameX = homes.name.x
  assert(homes.dispelType.x >= b.role._w + 5 and (not Z.db.dispelIcon or nameX == homes.dispelType.x + homes.dispelType.w + 2)
    and b.name._point[4] == nameX, "nom apres l'icone de role")
  Z.SetElementSize("role", 100) Z:Refresh()
  assert(Z.AuraRows().homes.name.x < nameX and Z.AuraRows().homes.dispelType.x >= b.role._w + 5, "nom a sa place d'origine")

  -- Rangées de soins et d'affaiblissements à toutes les tailles : dans la case, deux lignes au plus
  local checked = 0
  for _, members in ipairs({ 5, 40 }) do
    MEMBERS = members
    for _, shape in ipairs({ "BAR", "TILE", "SQUARE", "BANNER" }) do
      Z:ApplyShape(shape)
      Z.db.hotCount, Z.db.debuffCount = 4, 3
      local base = Z.AuraRows()
      for _, size in ipairs({ 50, 80, 100, 150, 200 }) do
        Z.SetElementSize("hots", size) Z.SetElementSize("debuffs", size)
        Z.ForgetPlacementRanges()
        local r = Z.AuraRows()
        W, H = Z.CellSize()
        local where = shape .. " a " .. size .. " %, groupe de " .. members
        for _, key in ipairs({ "hots", "debuffs" }) do
          local row = r[key]
          assert(row.lines <= 2 and row.size >= 5 and row.width <= W and row.height <= H, "rangee hors de la case : " .. where)
          if size < 100 then assert(row.size <= base[key].size, "rangee pas plus petite : " .. where) end
          if size > 100 then assert(row.size >= base[key].size, "rangee pas plus grande : " .. where) end
          local lo, hi = Z.OffsetRange(key)
          assert(lo <= hi, "bornes a l'envers : " .. where)
          checked = checked + 1
        end
      end
      Z.SetElementSize("hots", 100) Z.SetElementSize("debuffs", 100)
    end
  end
  assert(checked == 80, "nombre de verifications : " .. checked)
  MEMBERS = 5
  Z:ApplyShape("TILE")
  local normal = Z.AuraRows().hots.size
  Z.SetElementSize("hots", 150)
  assert(Z.AuraRows().hots.size > normal, "Tuile : soins agrandis")
  Z.SetElementSize("hots", 100)

  -- L'éditeur : « - », « + », molette, messages, éléments sans taille, remise à l'origine
  Z:Refresh()
  Z:OpenPlacement()
  local w = Z:PlacementWindow()
  local function Pick(key) for _, button in ipairs(w.list) do if button.key == key then button:Run("OnClick") end end end
  Pick("role")
  assert(w.size:GetText():find("100", 1, true) and w.bigger:GetAlpha() == 1, "taille affichee")
  w.bigger:Run("OnClick")
  assert(Z.GetElementSize("role") == 110 and w.size:GetText():find("110", 1, true), "plus grand")
  w.stage:Run("OnMouseWheel", -1) w.stage:Run("OnMouseWheel", -1)
  assert(Z.GetElementSize("role") == 90, "molette : " .. Z.GetElementSize("role"))
  Pick("name")
  assert(w.bigger:GetAlpha() < 1 and w.size:GetText():find(L["Taille du texte"], 1, true), "nom : renvoi a la taille du texte")
  w.bigger:Run("OnClick")
  assert(Z.GetElementSize("name") == 100, "nom agrandi")
  Pick("private")
  assert(w.size:GetText():find(L["Taille des auras privées"], 1, true), "auras privees : renvoi a leur reglage")
  Pick("role")
  w.reset:Run("OnClick")
  assert(Z.db.placement.TILE == nil, "remettre a sa place : la taille aussi")
  -- Case pleine : le « + » s'arrête et le dit
  Z:ApplyShape("BANNER")
  Pick("center")
  for _ = 1, 12 do w.bigger:Run("OnClick") end
  local most = Z.GetElementSize("center")
  assert(most <= 300 and w.size:GetText():find(L["Au plus grand pour cette case : %d %%"]:format(most), 1, true), "case pleine : " .. w.size:GetText())
  local _, cellH = Z.CellSize()
  assert(Z.ElementSize("center", Z.IconSize() + 8) <= cellH, "icone centrale hors de la case")
  for _ = 1, 20 do w.smaller:Run("OnClick") end
  assert(Z.GetElementSize("center") == 50 and w.size:GetText():find("50", 1, true), "au plus petit")
  w.resetAll.armed = true w.resetAll:Run("OnClick")
  assert(Z.db.placement.BANNER == nil, "tout remettre : tailles comprises")
  w:Hide()

  -- Partage : la taille voyage avec le décalage ; un ancien code (sans taille) reste lisible
  Z:ApplyShape("TILE")
  Z.SetOffset("buff", 2, 1) Z.SetElementSize("buff", 140) Z.SetElementSize("debuffs", 70, "BAR")
  local code = Z:Export()
  assert(code:find("p.TILE.buff=s2%2C1%2C140", 1, true) and code:find("p.BAR.debuffs=s0%2C0%2C70", 1, true), "taille absente du code")
  Z.db.placement = {}
  assert(Z:Import(code), "import")
  assert(Z.GetElementSize("buff") == 140 and Z.db.placement.TILE.buff[1] == 2 and Z.GetElementSize("debuffs", "BAR") == 70, "taille importee")
  Z.db.placement = {}
  assert(Z:Import("Lyorune2;pv=n2;p.TILE.role=s3%2C1;p.TILE.name=s0%2C0%2C150;p.TILE.marker=s0%2C0%2C999"), "ancien code")
  assert(Z.db.placement.TILE.role[1] == 3 and Z.GetElementSize("role") == 100, "ancien code : decalage seul")
  assert(Z.db.placement.TILE.name[3] == nil and Z.GetElementSize("marker") == 300, "taille d'un texte, ou hors limites")

  Z.db.placement = saved.placement
  Z.db.cornerSpells[Z.class] = saved.cornerSpells
  MEMBERS = saved.members
  for _, key in ipairs(keys) do Z.db[key] = saved[key] end
  Z:Refresh()
end)

step("etape 21, lot 4 : decompte des soins a la taille de l'icone (aucun chiffre ne mord sur l'icone voisine)", function()
  local keys = { "shape", "hotCountdown", "hotStyle", "hotCount", "showHots", "placement" }
  local saved = {}
  for _, key in ipairs(keys) do saved[key] = Z.db[key] end
  -- Police : 62 % de l'icone, de 6 a 12 points, une seule par hauteur
  assert(Z.CountdownFont(9) == "LyoruneCountdown6" and LyoruneCountdown6._size == 6, "icone de 9 pixels : 6 points")
  assert(Z.CountdownFont(11) == "LyoruneCountdown7" and Z.CountdownFont(4) == "LyoruneCountdown6", "Tuile, et plancher")
  assert(Z.CountdownFont(40) == "LyoruneCountdown12" and Z.CountdownFont(nil) == "LyoruneCountdown7", "plafond, et taille inconnue")
  local font = LyoruneCountdown6
  assert(Z.CountdownFont(9.4) == "LyoruneCountdown6" and LyoruneCountdown6 == font, "police creee une seule fois")
  -- Chaque forme : le chiffre est plus petit que son icone, et suit la taille choisie dans l'editeur
  local b, corners = Z.buttons[1], Z.db.cornerSpells[Z.class]
  Z.db.cornerSpells[Z.class] = nil
  AURAS["HELPFUL|PLAYER"] = { { name = "Rénovation", icon = 1, auraInstanceID = 41, spellId = 139 } }
  Z.db.placement, Z.db.hotStyle, Z.db.hotCount, Z.db.showHots, Z.db.hotCountdown = {}, "ICONS", 4, true, true
  for _, shape in ipairs({ "BAR", "TILE", "SQUARE", "BANNER" }) do
    Z:ApplyShape(shape) Z:Refresh() FireEvent("UNIT_AURA", "player") RunUpdates()
    local icon, size = b.hots[1], Z.AuraRows().hots.size
    assert(icon:IsShown(), shape .. " : icone de soin")
    local wanted = Z.CountdownFont(size)
    assert(icon.cooldown._countdownFont == wanted, shape .. " : police " .. tostring(icon.cooldown._countdownFont) .. " au lieu de " .. wanted)
    assert(_G[wanted]._size <= math.max(6, size * 0.7), shape .. " : chiffre trop grand pour une icone de " .. size)
  end
  Z.SetElementSize("hots", 200) Z:Refresh() FireEvent("UNIT_AURA", "player") RunUpdates()
  local big = Z.AuraRows().hots.size
  assert(b.hots[1].cooldown._countdownFont == Z.CountdownFont(big), "icones agrandies : chiffre agrandi")
  AURAS["HELPFUL|PLAYER"] = nil
  Z.db.cornerSpells[Z.class] = corners
  for _, key in ipairs(keys) do Z.db[key] = saved[key] end
  Z:Refresh()
end)

step("C10 : un reglage change en combat ne donne aucun sens des clics au jeu (action refusee sur une case securisee)", function()
  -- espion sur chaque case : le faux client n'a pas RegisterForClicks
  local calls = {}
  for _, b in ipairs(Z.buttons) do
    b.RegisterForClicks = function(_, mode) calls[#calls + 1] = mode end
    b.clickMode = nil
  end
  -- actions remises à la fin du combat : seule « sens des clics » compte ici (la disposition l'est toujours)
  local Safe, waits = Z.Safe, 0
  Z.Safe = function(self, key, fn)
    if key == "sens des clics" and InCombatLockdown() then waits = waits + 1 end
    return Safe(self, key, fn)
  end
  local n, fontSize = #Z.buttons, Z.db.fontSize
  local function all(mode)
    if #calls ~= n then return false end
    for _, m in ipairs(calls) do if m ~= mode then return false end end
    -- C11 : la touche au survol part au même sens que la case
    for _, b in ipairs(Z.buttons) do
      if b:GetAttribute("useOnKeyDown") ~= (mode == "AnyDown") then return false end
    end
    return true
  end
  -- case sans sens connu (creee en combat) : la fin du combat le lui donne
  Z.db.castOnDown = true
  FireEvent("PLAYER_REGEN_ENABLED")
  assert(all("AnyDown"), "fin du combat : " .. #calls .. " appels")
  -- hors combat, un reglage ordinaire : aucun appel
  calls = {}
  Z.db.fontSize = fontSize + 1 Z:Refresh()
  assert(#calls == 0, "reglage ordinaire hors combat : " .. #calls .. " appels")
  -- en combat, un reglage ordinaire : aucun appel, aucun message
  COMBAT = true FireEvent("PLAYER_REGEN_DISABLED")
  Z.db.fontSize = fontSize Z:Refresh()
  assert(#calls == 0 and waits == 0, "reglage ordinaire en combat : " .. #calls .. " appels, " .. waits .. " messages")
  -- une case creee en combat (sens encore inconnu) ne fait pas parler un reglage ordinaire
  Z.buttons[1].clickMode = nil
  Z.db.fontSize = fontSize + 1 Z:Refresh()
  assert(#calls == 0 and waits == 0, "case creee en combat : " .. waits .. " messages")
  -- en combat, « Lancer le sort des l'appui » change : rien tout de suite, remis a la fin du combat
  Z.db.castOnDown = false Z:Refresh()
  assert(#calls == 0 and waits == 1, "sens change en combat : " .. #calls .. " appels, " .. waits .. " remises")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  assert(all("AnyUp"), "sens applique a la fin du combat : " .. #calls .. " appels")
  -- hors combat : applique tout de suite, sans message
  calls = {}
  Z.db.castOnDown = true Z:Refresh()
  assert(all("AnyDown") and waits == 1, "sens change hors combat : " .. #calls .. " appels")
  Z.Safe = Safe
  Z.db.fontSize = fontSize
  for _, b in ipairs(Z.buttons) do b.RegisterForClicks = nil end
  Z:Refresh()
end)

step("etape 22, lot 3 : gros defensifs des joueurs et controles sur la case (conteneurs du jeu, ancien affichage, placement)", function()
  local oldName, oldCreate = C_Spell.GetSpellName, CreateFrame
  local extra = { [871] = "Mur protecteur", [15062] = "Mur protecteur", [29061] = "Autre sort", [22812] = "Écorce" }
  C_Spell.GetSpellName = function(id) return extra[id] or oldName(id) end
  local form = { placement = CopyTable(Z.db.placement) }
  for _, key in ipairs({ "shape", "width", "height", "fontSize", "powerHeight", "showDefensives", "showControls", "showHots" }) do
    form[key] = Z.db[key]
  end
  local made = {}
  local function finish()
    C_Spell.GetSpellName, CreateFrame = oldName, oldCreate
    AuraContainerSortMethod, AnchorUtil, Enum.CustomAuraButtonDispelTypeTextureStyle = nil, nil, nil
    Z.boxWrap = nil
    for _, c in ipairs(made) do pcall(c.SetAttribute, c, "unit", nil) end
    for key, value in pairs(form) do Z.db[key] = value end
    AURAS = {}
    Z:BuildData() Z:Refresh() RunUpdates()
  end
  local ok, err = xpcall(function()
    Z:BuildData()
    -- numéros vérifiés par leur nom dans le jeu : un numéro inconnu ou d'un autre sort n'est jamais filtré
    assert(Z.defensiveIds[871] and Z.defensiveIds[15062] and Z.defensiveIds[22812], "numeros des defensifs")
    assert(not Z.defensiveIds[29061] and not Z.defensiveIds[1277424], "numero au mauvais nom garde")
    for _, spells in pairs(Z.defensives) do
      for _, ids in ipairs(spells) do assert(type(ids[1]) == "number", "ligne de Z.defensives sans numero") end
    end
    Z.db.placement = {}
    Z:ApplyShape("TILE")

    -- 1. Ancien affichage (client sans conteneurs) : un défensif posé par n'importe qui, un contrôle
    local b = Z.buttons[1]
    AURAS = {}
    AURAS["HELPFUL"] = { { name = "Autre", icon = 9, auraInstanceID = 62, spellId = 5 },
      { name = "Mur protecteur", icon = 8, auraInstanceID = 61, spellId = 871 } }
    AURAS["HARMFUL|CROWD_CONTROL"] = { { name = "Métamorphose", icon = 10, auraInstanceID = 63, spellId = 118 } }
    Z:Refresh() Z.UpdateAurasNow(b)
    assert(b.defensives[1] and b.defensives[1]:IsShown() and not (b.defensives[2] and b.defensives[2]:IsShown()),
      "defensif absent, ou autre buff pris pour un defensif")
    assert(b.controlIcon and b.controlIcon:IsShown(), "controle absent")
    local row = Z.AuraRows()
    assert(b.defensives[1]._point[1] == "RIGHT" and b.controlIcon._point[1] == "CENTER", "places d'origine (Tuile)")
    Z.db.showDefensives, Z.db.showControls = false, false
    Z:Refresh() Z.UpdateAurasNow(b)
    assert(not b.defensives[1]:IsShown() and not b.controlIcon:IsShown(), "interrupteurs (ancien affichage)")
    Z.db.showDefensives, Z.db.showControls = true, true
    -- un de mes sorts suivis qui est aussi un défensif : montré une seule fois, avec les défensifs
    table.insert(Z.defensives.RACIAL, { 139 })
    Z:BuildData()
    AURAS["HELPFUL|PLAYER"] = { { name = "Rénovation", icon = 1, auraInstanceID = 11, spellId = 139 } }
    AURAS["HELPFUL"] = AURAS["HELPFUL|PLAYER"]
    Z:Refresh() Z.UpdateAurasNow(b)
    assert(not (b.hots[1] and b.hots[1]:IsShown()) and b.defensives[1]:IsShown(), "defensif montre deux fois")
    Z.db.showDefensives = false
    Z:Refresh() Z.UpdateAurasNow(b)
    assert(b.hots[1]:IsShown(), "defensifs coupes : le sort revient dans la rangee de mes soins")
    Z.db.showDefensives = true

    -- 2. Conteneurs du jeu : filtres, liseré de couleur, places, interrupteurs
    CreateFrame = function(kind, name, parent, template)
      local f = oldCreate(kind, name, parent, template)
      if kind ~= "AuraContainer" then return f end
      assert(not COMBAT, "conteneur cree en combat")
      f.groups = {}
      function f:AddAuraGroup(key, filter, options)
        local button = oldCreate("Button", nil, self)
        button.Edge = { SetColorTexture = function(edge, r, g, bl) edge.color = { r, g, bl } end }
        self.groups[key] = { filter = filter, candidates = options.candidateFilters or {}, max = options.maxFrameCount,
          size = options.layout.elementWidth, button = button }
        options.initializeFrame(button)
      end
      function f:AddAuraSlot(_, _, options)
        local button = oldCreate("Button", nil, self)
        options.initializeFrame(button)
        return button
      end
      function f:SetEnabled(on) self.enabled = on end
      function f:SetUnit(unit) self.unit = unit end
      function f:UpdateAllAuras() end
      function f:SetFlowLayoutMaximumLineSize(size) self.maxLine = size end
      function f:SetFlowLayoutAnchorPoint(point) self.flowPoint = point end
      return f
    end
    AuraContainerSortMethod = { Default = 0 }
    AnchorUtil = { FlowDirection = { Right = 1, Left = 2, Up = 3, Down = 4 }, FlowLayoutAxis = { Horizontal = 1, Vertical = 2 } }
    Enum.CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 1 }
    local c = CreateFrame("Button", "LyoruneHeaderUnitButton32", Z.header)
    Z.header:InitButton(c:GetName())
    made[#made + 1] = c
    c:SetAttribute("unit", "player")
    assert(c.boxes and c.boxes.defensives and c.boxes.controls, "conteneurs des defensifs et des controles absents")
    local g = c.boxes.defensives.groups.defensives
    assert(g.filter == "HELPFUL" and g.candidates.includeSpellIDs[871] and g.max == Z.DEFENSIVE_COUNT, "defensifs : filtre")
    assert(g.size == Z.AuraRows().defensives.size, "defensifs : taille")
    assert(g.button.Edge.color and g.button.Edge.color[3] == Z.DEFENSIVE_EDGE[3], "defensifs : lisere bleu")
    assert(not c.boxes.hots.groups.hots.candidates.includeSpellIDs[139], "mon sort defensif reste dans la rangee des soins")
    local cc = c.boxes.controls.groups.controls
    assert(cc.filter == "HARMFUL|CROWD_CONTROL" and cc.max == 1, "controles : filtre")
    assert(cc.button.Edge.color[1] == Z.CONTROL_EDGE[1], "controles : lisere rouge")
    local box = c.boxes.defensives
    assert(box._point[1] == "RIGHT" and box._point[2] == c.over and box.flowPoint == "TOPRIGHT", "Tuile : defensifs au bord droit")
    assert(c.boxes.controls._point[1] == "CENTER" and c.boxes.controls._point[2] == c.over, "Tuile : controle au centre")
    -- Barre et Bandeau : sur la barre de vie, avant le chiffre de vie
    for _, shape in ipairs({ "BAR", "BANNER" }) do
      Z:ApplyShape(shape)
      local rows = Z.AuraRows()
      box = c.boxes.defensives
      assert(box._point[2] == c.hp and c.boxes.controls._point[2] == c.hp, shape .. " : sur la barre de vie")
      assert(rows.defensives.x < rows.textX, shape .. " : defensifs sur le chiffre de vie")
      if shape == "BANNER" then
        assert(rows.defensives.x <= rows.textX - rows.textW, "Bandeau : defensifs sur le chiffre de vie")
      end
      assert(rows.defensives.size >= 5 and rows.controls.size >= 5, shape .. " : icones trop petites")
    end
    Z:ApplyShape("TILE")
    -- déplacés dans l'éditeur : le conteneur suit sans être refait (il n'est pas protégé)
    local kept = c.boxes.defensives
    Z.SetOffset("defensives", -6, 3) Z:Refresh()
    assert(c.boxes.defensives == kept and kept._point[4] == -2 - 6 and kept._point[5] == 3, "defensifs deplaces")
    -- plus grands : boutons refaits (le jeu fixe leur taille à la création)
    Z.SetElementSize("controls", 150) Z:Refresh()
    assert(c.boxes.controls.groups.controls.size == Z.AuraRows().controls.size and c.boxes.defensives ~= kept,
      "taille du controle non appliquee")
    Z.db.showDefensives, Z.db.showControls = false, false Z:Refresh()
    assert(not c.boxes.defensives.groups.defensives and not c.boxes.controls.groups.controls, "interrupteurs (conteneurs)")
    assert(c.boxes.hots.groups.hots.candidates.includeSpellIDs[139], "defensifs coupes : sort rendu a la rangee")
    table.remove(Z.defensives.RACIAL)
    Z.db.showDefensives, Z.db.showControls = true, true

    -- 3. Éditeur de placement et mode test
    assert(Z.IsPlaceElement("defensives") and Z.IsPlaceElement("controls") and Z.CanSize("defensives") and Z.CanSize("controls"))
    Z:OpenPlacement()
    local w = Z:PlacementWindow()
    for _, button in ipairs(w.list) do if button.key == "controls" then button:Run("OnClick") end end
    assert(w.cell.controlIcon:IsShown() and w.cell.defensives[Z.DEFENSIVE_COUNT]:IsShown(), "case d'exemple sans les nouveaux elements")
    w:Hide()
    local cell = Z.FakeCell(UIParent)
    Z.DrawFakeCell(cell, 1, true)
    assert(cell.defensives[1] and cell.defensives[1]:IsShown(), "case temoin : defensif d'exemple absent")
    assert(not (cell.controlIcon and cell.controlIcon:IsShown()), "case temoin : controle sur le nom")
    Z.DrawFakeCell(cell, 3, false)
    assert(cell.controlIcon and cell.controlIcon:IsShown(), "mode test : controle d'exemple absent")
  end, debug.traceback)
  finish()
  assert(ok, err)
end)

step("etape 22, lot 4 : raccourcis du jeu (Bindings.xml, cadres masques, prochain buff manquant)", function()
  local L = Z.L
  -- 1. Le fichier : chaque raccourci a son nom (traduit), aucune touche posée au départ, chaque action est connue
  local names = {}
  for attrs in BINDINGS_XML:gmatch("<Binding%s([^>]*)>") do
    assert(not attrs:find("default", 1, true), "touche posee au depart : " .. attrs)
    assert(attrs:find('category="ADDONS"', 1, true), "raccourci hors de la rubrique AddOns : " .. attrs)
    local name = attrs:match('name="([^"]+)"')
    names[#names + 1] = name
    assert(Z.bindingNames[name], "raccourci sans nom : " .. name)
    assert(_G["BINDING_NAME_" .. name] == L[Z.bindingNames[name]], "nom absent du jeu : " .. name)
  end
  assert(#names == 4 and BINDING_HEADER_LYORUNE == "Lyorune", "4 raccourcis attendus")
  local count = 0 for _ in pairs(Z.bindingNames) do count = count + 1 end
  assert(count == #names, "nom sans raccourci dans Bindings.xml")
  for action in BINDINGS_XML:gmatch('Lyorune_Binding%("(%u+)"%)') do
    assert(action == "OPTIONS" or action == "FRAMES" or action == "TEST", "action inconnue : " .. action)
  end
  local clickName = BINDINGS_XML:match('name="CLICK ([^:"]+):LeftButton"')
  assert(clickName == "LyoruneNextBuff" and _G[clickName], "bouton du prochain buff absent")

  -- 2. Ouvrir les options, mode test : les mêmes fonctions que /lyorune et /lyorune test
  local window = Z:OptionsWindow()
  local wasShown = window and window:IsShown()
  Lyorune_Binding("OPTIONS")
  Lyorune_Binding("OPTIONS")
  Lyorune_Binding("TEST")
  assert(Z.previewActive, "mode test non ouvert par le raccourci")
  Lyorune_Binding("TEST")
  assert(not Z.previewActive, "mode test non ferme par le raccourci")

  -- 3. Afficher ou masquer les cadres : hors combat seulement, même en combat une fois masqués, rien de sauvé
  Z:Refresh() RunUpdates()
  local main = Z.header
  assert(main:IsShown(), "cadre principal cache au depart")
  Lyorune_Binding("FRAMES")
  assert(Z.framesHidden and not main:IsShown(), "cadres non masques")
  for _, h in ipairs(Z.headers) do assert(not h:IsShown(), "un cadre reste visible : " .. h.def.key) end
  COMBAT = true FireEvent("PLAYER_REGEN_DISABLED") ApplyStateDrivers()
  assert(not main:IsShown(), "cadres masques revenus en combat")
  local printed = #PRINTED
  Z:ToggleFramesShown()
  assert(Z.framesHidden and #PRINTED == printed + 1 and PRINTED[#PRINTED]:find(L["les cadres s'affichent ou se masquent hors combat seulement."], 1, true), "combat : pas de message")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") ApplyStateDrivers() RunUpdates()
  assert(Z.db.framesHidden == nil and Z.char.framesHidden == nil, "etat sauve")
  SlashCmdList.LYORUNE("cadres")
  assert(not Z.framesHidden and main:IsShown(), "/lyorune cadres ne ramene pas les cadres")

  -- 4. Prochain buff manquant : la première ligne du panneau, vidée quand plus rien ne manque et en combat
  local saved = { buffPanel = Z.db.buffPanel, castOnDown = Z.db.castOnDown, buffPlace = Z.db.buffPlace }
  local nextBuff = LyoruneNextBuff
  Z.db.buffPanel, Z.db.buffPlace = true, "FREE"
  AURAS = {} Z:Refresh() RunUpdates() Z:UpdateBuffPanel()
  local list = Z.BuffRows()
  assert(#list >= 1, "aucun buff manquant pour l'essai")
  assert(nextBuff:GetAttribute("type") == "spell" and nextBuff:GetAttribute("spell") == list[1].spell
    and nextBuff:GetAttribute("unit") == list[1].unit, "prochain buff mal regle")
  assert(nextBuff:GetAttribute("spell") == LyoruneBuffsRow1:GetAttribute("spell1"), "pas la premiere ligne du panneau")
  assert(nextBuff:GetAttribute("useOnKeyDown") == (Z.db.castOnDown and true or false), "sens de la touche")
  Z.db.castOnDown = not Z.db.castOnDown Z:UpdateBuffPanel()
  assert(nextBuff:GetAttribute("useOnKeyDown") == (Z.db.castOnDown and true or false), "sens de la touche non suivi")
  -- fermé par la croix : la touche marche encore
  Z:BuffPanel().close:Run("OnClick")
  Z:UpdateBuffPanel()
  assert(not Z:BuffPanel():IsShown() and nextBuff:GetAttribute("spell") == list[1].spell, "panneau ferme : touche videe")
  printed = #PRINTED nextBuff:Run("PostClick")
  assert(#PRINTED == printed, "message alors qu'un buff part")
  -- entrée en combat : vidé avant le verrouillage, un mot si on appuie quand même
  FireEvent("PLAYER_REGEN_DISABLED") COMBAT = true
  assert(nextBuff:GetAttribute("type") == nil and nextBuff:GetAttribute("spell") == nil, "ancien buff garde en combat")
  nextBuff:Run("PostClick")
  assert(PRINTED[#PRINTED]:find(L["le prochain buff manquant se pose hors combat seulement."], 1, true), "combat : pas de message")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates() Z:UpdateBuffPanel()
  assert(nextBuff:GetAttribute("spell") == list[1].spell, "pas repris apres le combat")
  -- plus rien ne manque, ou panneau éteint : vidé, et un mot à l'appui
  Z.db.buffPanel = false Z:UpdateBuffPanel()
  assert(nextBuff:GetAttribute("spell") == nil and nextBuff:GetAttribute("unit") == nil, "panneau eteint : touche pas videe")
  nextBuff:Run("PostClick")
  assert(PRINTED[#PRINTED]:find(L["aucun buff manquant à poser."], 1, true), "pas de message sans buff")
  for key, value in pairs(saved) do Z.db[key] = value end
  Z:Refresh() RunUpdates()
  if window and not wasShown then window:Hide() end

  -- 5. Les options en parlent : commande dans la liste, phrase des raccourcis, langue anglaise complète
  for _, text in ipairs({ "afficher ou masquer les cadres", "cadres affichés.", "aucun buff manquant à poser.",
    "Touches au choix dans les raccourcis du jeu (Échap, Options, Raccourcis, AddOns, Lyorune) : ouvrir les options, afficher ou masquer les cadres, poser le prochain buff manquant, mode test. Aucune touche au départ." }) do
    assert(Z.translations.enUS[text], "sans traduction : " .. text)
  end
  for _, text in pairs(Z.bindingNames) do assert(Z.translations.enUS[text], "nom sans traduction : " .. text) end
end)

step("etape 23, lot 1 : jusqu'a 3 affaiblissements a dissiper par case (conteneurs, ancien affichage, rangee, exemple)", function()
  Z.db.shownDebuffs = { [6788] = false, [25771] = false } Z.shownCache = nil -- (Toujours montres : essayes a part, 1.51.0)
  local oldCreate = CreateFrame
  local form = {}
  for _, key in ipairs({ "shape", "width", "height", "fontSize", "powerHeight", "dispelCount", "debuffCount", "debuffMode",
    "showDebuffs" }) do form[key] = Z.db[key] end
  local made = {}
  local function finish()
    CreateFrame = oldCreate
    AuraContainerSortMethod, AnchorUtil, Enum.CustomAuraButtonDispelTypeTextureStyle = nil, nil, nil
    Z.boxWrap = nil
    for _, c in ipairs(made) do pcall(c.SetAttribute, c, "unit", nil) end
    for key, value in pairs(form) do Z.db[key] = value end
    AURAS = {}
    Z:BuildData() Z:Refresh() RunUpdates()
  end
  local ok, err = xpcall(function()
    -- 1. Le réglage : une seule fois, borné, deux au départ
    assert(Z.defaults.dispelCount == 2 and Z.limits.dispelCount[1] == 1 and Z.limits.dispelCount[2] == 3, "reglage dispelCount")
    Z.db.dispelCount = 9 assert(Z.DispelCount() == 3, "borne haute") Z.db.dispelCount = 0 assert(Z.DispelCount() == 1, "borne basse")
    Z.db.dispelCount, Z.db.debuffCount, Z.db.debuffMode = 3, 2, "ALL"
    assert(Z.DebuffSlots() == 4, "places de la rangee (Tous)")
    Z.db.debuffMode = "DISPEL" assert(Z.DebuffSlots() == 3, "places de la rangee (Dissipables par moi)")
    Z.db.debuffMode = "ALL"
    assert(Z.translations.enUS["Affaiblissements à dissiper"] and Z.translations.enUS["Montrés avant les autres, le plus important d'abord."],
      "reglage sans traduction")

    -- 2. Ancien affichage : trois à dissiper (le jeu les donne dans l'ordre), puis un autre ; jamais deux fois le même
    local b = Z.buttons[1]
    AURAS = {}
    local d1 = { name = "A", icon = 1, auraInstanceID = 71, spellId = 1001, dispelName = "Magic" }
    local d2 = { name = "B", icon = 2, auraInstanceID = 72, spellId = 1002, dispelName = "Magic" }
    local d3 = { name = "C", icon = 3, auraInstanceID = 73, spellId = 1003, dispelName = "Disease" }
    local d4 = { name = "D", icon = 4, auraInstanceID = 74, spellId = 1004, dispelName = "Magic" }
    local other = { name = "E", icon = 5, auraInstanceID = 75, spellId = 1005 }
    AURAS["HARMFUL|RAID"] = { d1, d2, d3, d4 }
    AURAS["HARMFUL"] = { d1, other, d2, d3, d4 }
    Z:Refresh() Z.UpdateAurasNow(b)
    local function shown()
      local n = 0
      for i = 1, #b.debuffs do if b.debuffs[i]:IsShown() then n = i end end
      return n
    end
    assert(shown() == 4, "3 a dissiper et 1 autre attendus : " .. shown())
    assert(b.debuffs[1].texture._tex == 1 and b.debuffs[3].texture._tex == 3 and b.debuffs[4].texture._tex == 5,
      "ordre : ceux a dissiper d'abord, puis l'autre")
    Z.db.dispelCount = 1 Z:Refresh() Z.UpdateAurasNow(b)
    assert(shown() == 2 and b.debuffs[2].texture._tex == 5, "un seul a dissiper : le comportement d'avant")
    Z.db.dispelCount, Z.db.debuffMode = 2, "DISPEL" Z:Refresh() Z.UpdateAurasNow(b)
    assert(shown() == 2 and b.debuffs[2].texture._tex == 2, "Dissipables par moi : deux, sans les autres")
    Z.db.debuffMode = "ALL"
    -- 1.32.1 : le filtre du jeu rend une liste vide = rien a dissiper pour moi. Un affaiblissement Magie que
    -- personne ne retire n'est ni colore ni sonne (fausse alerte d'avant), mais il reste dans la rangee des autres
    -- (le trou d'avant : il n'apparaissait nulle part)
    AURAS["HARMFUL|RAID"] = nil
    local canDispel = Z.canDispel
    Z.canDispel = { Magic = true }
    Z:Refresh() Z.UpdateAurasNow(b)
    assert(not b.dispel:IsShown(), "liste vide du jeu : aucune couleur de dissipation")
    assert(shown() == 1 and b.debuffs[1].texture._tex == 1, "Magie non dissipable montree avec les autres : " .. shown())
    -- le jeu refuse le filtre : mes propres sorts reconnaissent le type (pretre : magie et maladie)
    local getAuras = C_UnitAuras.GetUnitAuras
    C_UnitAuras.GetUnitAuras = function(unit, filter, ...)
      if filter == Z.DISPEL_MINE then error("filtre refuse") end
      return getAuras(unit, filter, ...)
    end
    Z:Refresh() Z.UpdateAurasNow(b)
    C_UnitAuras.GetUnitAuras = getAuras
    assert(b.debuffs[1].texture._tex == 1 and b.debuffs[2].texture._tex == 2, "repli sur mes sorts")
    Z.canDispel = canDispel
    AURAS = {}

    -- 3. Conteneurs du jeu : groupe des dissipables à la taille réglée, rangée assez longue
    CreateFrame = function(kind, name, parent, template)
      local f = oldCreate(kind, name, parent, template)
      if kind ~= "AuraContainer" then return f end
      f.groups = {}
      function f:AddAuraGroup(key, filter, options)
        local button = oldCreate("Button", nil, self)
        button.Edge = { SetColorTexture = function() end }
        self.groups[key] = { filter = filter, max = options.maxFrameCount, sort = options.sortMethod, size = options.layout.elementWidth }
        options.initializeFrame(button)
      end
      function f:AddAuraSlot(_, _, options)
        local button = oldCreate("Button", nil, self)
        options.initializeFrame(button)
        return button
      end
      function f:SetEnabled(on) self.enabled = on end
      function f:SetUnit(unit) self.unit = unit end
      function f:UpdateAllAuras() end
      function f:SetFlowLayoutMaximumLineSize(size) self.maxLine = size end
      function f:SetFlowLayoutAnchorPoint(point) self.flowPoint = point end
      return f
    end
    AuraContainerSortMethod = { Default = 0 }
    AnchorUtil = { FlowDirection = { Right = 1, Left = 2, Up = 3, Down = 4 }, FlowLayoutAxis = { Horizontal = 1, Vertical = 2 } }
    Enum.CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 1 }
    local c = CreateFrame("Button", "LyoruneHeaderUnitButton33", Z.header)
    Z.header:InitButton(c:GetName())
    made[#made + 1] = c
    c:SetAttribute("unit", "player")
    Z.db.dispelCount, Z.db.debuffCount = 3, 3 Z:Refresh()
    local groups = c.boxes.debuffs.groups
    assert(groups.dispellable.max == 3 and groups.dispellable.sort == AuraContainerSortMethod.Default, "dissipables : 3, tri du jeu")
    assert(groups.others.max == 2, "autres : debuffCount - 1")
    -- chaque forme : la rangée tient dans la case (passage à la ligne ou icônes plus petites)
    for _, shape in ipairs({ "BAR", "TILE", "SQUARE", "BANNER" }) do
      Z:ApplyShape(shape)
      local rows, W, H = Z.AuraRows(), Z.CellSize()
      local row = rows.debuffs
      assert(row.perLine * row.lines >= 5, shape .. " : rangee trop courte")
      assert(row.width <= W and row.height <= H, shape .. " : rangee hors de la case")
    end
    Z:ApplyShape("TILE")

    -- 4. Éditeur de placement et mode test
    Z:OpenPlacement()
    local w = Z:PlacementWindow()
    assert(w.cell.debuffs[5] and w.cell.debuffs[5]:IsShown(), "case d'exemple : toutes les places")
    w:Hide()
    local cell = Z.FakeCell(UIParent)
    Z.db.showDispel = true
    Z.DrawFakeCell(cell, 1, true)
    assert(cell.debuffs[2] and cell.debuffs[2]:IsShown(), "case temoin : deux a dissiper")
  end, debug.traceback)
  finish()
  Z.db.shownDebuffs = {} Z.shownCache = nil
  assert(ok, err)
end)

step("etape 23, lot 4 : liseré de ma mana basse au bord de l'écran (courbe du jeu, classes sans mana, interrupteur)", function()
  local kept, class, power = Z.db.manaEdge, Z.class, UnitPowerPercent
  local ok, err = pcall(function()
    assert(Z.defaults.manaEdge == 20 and Z.choices.manaEdge[1][1] == 0, "reglage manaEdge")
    Z.db.manaEdge = 30 Z:Refresh()
    local edge = Z:ManaEdge()
    assert(edge and edge:IsShown() and edge:GetFrameStrata() == "BACKGROUND", "lisere absent")
    assert(not edge:IsMouseEnabled(), "lisere cliquable")
    -- l'opacité vient de la courbe passée au jeu, jamais d'une comparaison de la mana (secrète)
    local seen
    UnitPowerPercent = function(unit, kind, predicted, curve)
      seen = { unit = unit, kind = kind, curve = curve }
      return CreateColor(1, 1, 1, MakeSecret and MakeSecret() or 0.4)
    end
    Z:RefreshManaEdge()
    assert(seen and seen.unit == "player" and seen.kind == 0 and seen.curve, "courbe non passee au jeu")
    UnitPowerPercent = power
    -- une classe sans mana (guerrier) n'a jamais de liseré
    Z.class = "WARRIOR" Z:RefreshManaEdge()
    assert(not edge:IsShown(), "lisere pour une classe sans mana")
    Z.class = class
    Z.db.manaEdge = 0 Z:Refresh()
    assert(not edge:IsShown(), "interrupteur du lisere")
    for _, text in ipairs({ "Liseré de ma mana basse", "Un liseré bleu doux au bord de l'écran." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
  end)
  Z.db.manaEdge, Z.class, UnitPowerPercent = kept, class, power
  Z:Refresh()
  assert(ok, err)
end)

step("etape 23, lot 5 : regle des 5 secondes, un trait qui se vide sur ma case apres un sort paye en mana", function()
  local kept, isUnit, cost, class = Z.db.fiveSecondRule, UnitIsUnit, C_Spell.GetSpellPowerCost, Z.class
  local ok, err = pcall(function()
    assert(Z.defaults.fiveSecondRule == false, "reglage fiveSecondRule : eteint au depart")
    local b = Z.buttons[1]
    b:SetAttribute("unit", "player") b.unit = "player"
    UnitIsUnit = function(a, c) return a == "player" and c == "player" end
    local costs = { [2061] = { { type = 0, cost = 120 } }, [5019] = {} }
    C_Spell.GetSpellPowerCost = function(id) return costs[id] end
    Z.db.fiveSecondRule = true Z:Refresh()
    -- un tir de baguette (sans mana) : aucun trait
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 5019)
    assert(not (b.fiveLine and b.fiveLine:IsShown()), "trait apres un sort sans mana")
    -- 1.29.1 : la pêche (coût que le jeu ne donne pas : nil) et un coût illisible ne lancent pas le trait
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 7620)
    assert(not (b.fiveLine and b.fiveLine:IsShown()), "trait apres la peche")
    C_Spell.GetSpellPowerCost = function() error("sort inconnu") end
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 7620)
    assert(not (b.fiveLine and b.fiveLine:IsShown()), "trait apres un cout illisible")
    C_Spell.GetSpellPowerCost = function(id) return costs[id] end
    -- un soin payé en mana : le trait part et se vide par une animation du jeu
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 2061)
    assert(b.fiveLine and b.fiveLine:IsShown() and b.fiveLine.drain:IsPlaying(), "trait absent apres un soin")
    -- numéro secret : compté comme payé (le trait ne manque jamais)
    b.fiveLine:Hide() b.fiveLine.drain:Stop()
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", MakeSecret())
    assert(b.fiveLine:IsShown(), "numero secret : trait absent")
    -- la fin de l'animation cache le trait
    b.fiveLine.drain:Run("OnFinished")
    assert(not b.fiveLine:IsShown(), "trait reste apres 5 secondes")
    -- interrupteur, et classe sans mana
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 2061)
    Z.db.fiveSecondRule = false Z:Refresh()
    assert(not b.fiveLine:IsShown(), "interrupteur : trait reste")
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 2061)
    assert(not b.fiveLine:IsShown(), "interrupteur : trait relance")
    Z.db.fiveSecondRule, Z.class = true, "ROGUE" Z:Refresh()
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 2061)
    assert(not b.fiveLine:IsShown(), "classe sans mana : trait")
    Z.class = class
    for _, text in ipairs({ "Règle des 5 secondes sur ma case", "Un trait qui se vide jusqu'au retour de la régénération." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
    -- 1.29.1 : éteinte au départ ; la 1.29.0 l'avait allumée pour tous, elle repart éteinte une seule fois
    local savedDB, savedChar, version = LyoruneDB, LyoruneCharDB, Z.version
    local fine, why = pcall(function()
      local db = { lastVersion = "1.29.0", fiveSecondRule = true }
      LyoruneDB = db
      Z.version = "1.29.0" FireEvent("ADDON_LOADED", "Lyorune")
      assert(db.fiveSecondRule == true, "remise avant la 1.29.1")
      Z.version = "1.29.1" FireEvent("ADDON_LOADED", "Lyorune")
      assert(db.fiveSecondRule == false, "1.29.0 : regle des 5 secondes pas eteinte")
      db.lastVersion, db.fiveSecondRule = "1.29.1", true FireEvent("ADDON_LOADED", "Lyorune")
      assert(db.fiveSecondRule == true, "choix du joueur ecrase apres la 1.29.1")
      db = { lastVersion = "1.28.0" } LyoruneDB = db FireEvent("ADDON_LOADED", "Lyorune")
      assert(db.fiveSecondRule == false, "ancien joueur : regle allumee")
    end)
    Z.version = version
    LyoruneDB, LyoruneCharDB = savedDB, savedChar
    FireEvent("ADDON_LOADED", "Lyorune")
    assert(fine, why)
  end)
  Z.db.fiveSecondRule, UnitIsUnit, C_Spell.GetSpellPowerCost, Z.class = kept, isUnit, cost, class
  Z:Refresh()
  assert(ok, err)
end)

step("etape 23, lot 2 : sorts externes, Ame affaiblie au bout de mes soins (donnees, ancien affichage, conteneurs, exemple)", function()
  local oldCreate, class, role = CreateFrame, Z.class, UnitGroupRolesAssigned
  local form = {}
  for _, key in ipairs({ "showLockouts", "showHots", "hotCount", "hotStyle", "showDebuffs", "debuffMode", "debuffCount",
    "drinkHealers" }) do form[key] = Z.db[key] end
  local made = {}
  local function finish()
    CreateFrame, Z.class, UnitGroupRolesAssigned = oldCreate, class, role
    AuraContainerSortMethod, AnchorUtil, Enum.CustomAuraButtonDispelTypeTextureStyle = nil, nil, nil
    Z.boxWrap = nil
    for _, c in ipairs(made) do pcall(c.SetAttribute, c, "unit", nil) end
    for key, value in pairs(form) do Z.db[key] = value end
    AURAS = {}
    Z:BuildData() Z:Refresh() RunUpdates()
  end
  local ok, err = xpcall(function()
    -- 1. Données : sorts externes suivis, Âme affaiblie vérifiée par son nom, boissons au bon nom seulement
    assert(Z.defaults.showLockouts == true and Z.defaults.drinkHealers == true, "reglages showLockouts, drinkHealers")
    Z:BuildData()
    assert(Z.trackedNames["Infusion de puissance"], "Infusion de puissance non suivie")
    assert(Z.lockoutIds[6788] and Z.drinkIds[430] and Z.drinkIds[431] and Z.drinkIds[1133], "numeros verifies par leur nom")
    assert(not Z.drinkIds[26473] and not Z.drinkIds[432], "numero au mauvais nom garde")
    local found
    for _, id in ipairs(Z.trackedSpells.DRUID) do if id == 29166 then found = true end end
    assert(found, "Innervation absente des sorts du druide")
    Z.db.showHots, Z.db.showLockouts, Z.db.hotCount = true, true, 3
    assert(Z.HotSlots() == 3 and Z.HotCount() == 2, "Ame affaiblie a la derniere place")
    Z.db.hotCount = 1 assert(Z.HotSlots() == 2 and Z.HotCount() == 1, "un seul soin : Ame affaiblie apres lui")
    Z.db.hotCount = 3
    Z.db.showLockouts = false assert(Z.HotSlots() == 3 and Z.HotCount() == 3, "interrupteur : place gardee")
    Z.db.showLockouts = true
    Z.class = "DRUID" Z:BuildData()
    assert(next(Z.lockoutIds) == nil and Z.HotSlots() == 3, "classe sans blocage : place gardee")
    Z.class = class Z:BuildData()
    for _, text in ipairs({ "Sort que je ne peux pas relancer", "Âme affaiblie (prêtre), Longanimité (paladin), assombries après vos soins." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end

    -- 2. Ancien affichage : Rénovation, puis Âme affaiblie assombrie ; elle quitte la rangée des affaiblissements
    local b = Z.buttons[1]
    AURAS = {}
    local renew = { name = "Rénovation", icon = 11, auraInstanceID = 81, spellId = 139 }
    local weak = { name = "Âme affaiblie", icon = 77, auraInstanceID = 82, spellId = 6788 }
    local other = { name = "Autre", icon = 55, auraInstanceID = 83, spellId = 1005 }
    AURAS["HELPFUL|PLAYER"] = { renew }
    AURAS["HARMFUL"] = { weak, other }
    Z.db.hotStyle, Z.db.showDebuffs, Z.db.debuffMode, Z.db.debuffCount = "ICONS", true, "ALL", 3
    Z:Refresh() Z.UpdateAurasNow(b)
    assert(b.hots[1]:IsShown() and b.hots[1].texture._tex == 11, "mon soin d'abord")
    assert(b.hots[2] and b.hots[2]:IsShown() and b.hots[2].texture._tex == 77, "Ame affaiblie au bout de mes soins")
    assert(b.hots[2].texture._color[1] == Z.LOCKOUT_SHADE, "Ame affaiblie non assombrie")
    for i = 1, #b.debuffs do
      assert(not (b.debuffs[i]:IsShown() and b.debuffs[i].texture._tex == 77), "Ame affaiblie montree deux fois")
    end
    -- une icône réutilisée pour un soin reprend sa couleur
    AURAS["HARMFUL"] = { other }
    AURAS["HELPFUL|PLAYER"] = { renew, { name = "Mot de pouvoir : Bouclier", icon = 12, auraInstanceID = 84, spellId = 17 } }
    Z.UpdateAurasNow(b)
    assert(b.hots[2].texture._tex == 12 and b.hots[2].texture._color[1] == 1, "icone reutilisee restee sombre")
    -- interrupteur : Âme affaiblie revient parmi les affaiblissements
    AURAS["HELPFUL|PLAYER"] = { renew }
    AURAS["HARMFUL"] = { weak, other }
    Z.db.showLockouts = false Z:Refresh() Z.UpdateAurasNow(b)
    assert(not b.hots[2]:IsShown(), "interrupteur : Ame affaiblie reste apres mes soins")
    local back
    for i = 1, #b.debuffs do if b.debuffs[i]:IsShown() and b.debuffs[i].texture._tex == 77 then back = true end end
    assert(back, "interrupteur : Ame affaiblie absente des affaiblissements")
    Z.db.showLockouts = true
    -- style « Barres » : une barre grise après les miennes
    Z.db.hotStyle = "BARS" Z:Refresh() Z.UpdateAurasNow(b)
    assert(b.hotBars[2] and b.hotBars[2]:IsShown(), "barre d'Ame affaiblie absente")
    Z.db.hotStyle = "ICONS"
    AURAS = {}

    -- 3. Conteneurs du jeu : groupe « HARMFUL » au bout de la rangée de mes soins, exclu des affaiblissements
    CreateFrame = function(kind, name, parent, template)
      local f = oldCreate(kind, name, parent, template)
      if kind ~= "AuraContainer" then return f end
      f.groups = {}
      function f:AddAuraGroup(key, filter, options)
        local button = oldCreate("Button", nil, self)
        button.Edge = { SetColorTexture = function() end }
        button.Icon = oldCreate("Frame", nil, button):CreateTexture()
        self.groups[key] = { filter = filter, max = options.maxFrameCount, candidates = options.candidateFilters,
          index = options.layout.layoutIndex, size = options.layout.elementWidth, button = button }
        options.initializeFrame(button)
      end
      function f:AddAuraSlot(_, _, options)
        local button = oldCreate("Button", nil, self)
        options.initializeFrame(button)
        return button
      end
      function f:SetEnabled(on) self.enabled = on end
      function f:SetUnit(unit) self.unit = unit end
      function f:UpdateAllAuras() end
      function f:SetFlowLayoutMaximumLineSize(size) self.maxLine = size end
      function f:SetFlowLayoutAnchorPoint(point) self.flowPoint = point end
      return f
    end
    AuraContainerSortMethod = { Default = 0 }
    AnchorUtil = { FlowDirection = { Right = 1, Left = 2, Up = 3, Down = 4 }, FlowLayoutAxis = { Horizontal = 1, Vertical = 2 } }
    Enum.CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 1 }
    local c = CreateFrame("Button", "LyoruneHeaderUnitButton34", Z.header)
    Z.header:InitButton(c:GetName())
    made[#made + 1] = c
    c:SetAttribute("unit", "player")
    Z:Refresh()
    local lock = c.boxes.hots.groups.lockouts
    assert(lock and lock.filter == "HARMFUL" and lock.max == Z.LOCKOUT_COUNT and lock.index == 2, "groupe Ame affaiblie")
    assert(lock.candidates.includeSpellIDs[6788], "Ame affaiblie absente du filtre")
    assert(lock.button.Icon._color[1] == Z.LOCKOUT_SHADE, "icone du jeu non assombrie")
    assert(c.boxes.bars.groups.lockbars, "barre d'Ame affaiblie absente (conteneur)")
    assert(c.boxes.debuffs.groups.others.candidates.excludeSpellIDs[6788], "Ame affaiblie encore parmi les affaiblissements")
    assert(not c.boxes.hots.groups.hots.candidates.includeSpellIDs[6788], "Ame affaiblie parmi mes soins")
    Z.db.showLockouts = false Z:Refresh()
    assert(not c.boxes.hots.groups.lockouts, "interrupteur : groupe garde")
    Z.db.showLockouts = true Z:Refresh()
    -- la rangée tient dans la case avec la place de plus, dans chaque forme
    Z.db.hotCount = 6
    for _, shape in ipairs({ "BAR", "TILE", "SQUARE", "BANNER" }) do
      Z:ApplyShape(shape)
      local rows, W, H = Z.AuraRows(), Z.CellSize()
      local row = rows.hots
      assert(row.perLine * row.lines >= Z.HotSlots() and Z.HotSlots() == 6, shape .. " : rangee trop courte")
      assert(row.width <= W and row.height <= H, shape .. " : rangee hors de la case")
    end
    Z:ApplyShape("TILE")
    Z.db.hotCount = 3

    -- 4. Éditeur de placement et case témoin : la place assombrie au bout de mes soins
    Z:OpenPlacement()
    local w = Z:PlacementWindow()
    assert(w.cell.hots[3] and w.cell.hots[3]:IsShown() and w.cell.hots[3].texture._color[1] == Z.LOCKOUT_SHADE
      and w.cell.hots[2].texture._color[1] == 1 and not (w.cell.hots[4] and w.cell.hots[4]:IsShown()),
      "case d'exemple : place d'Ame affaiblie")
    w:Hide()
    local cell = Z.FakeCell(UIParent)
    local _, _, shown = Z.DrawFakeCell(cell, 1, true)
    assert(cell.hots[shown + 1] and cell.hots[shown + 1]:IsShown(), "case temoin : Ame affaiblie absente")

    -- 5. Lot 3, soigneur qui boit : conteneur à côté de la mana basse, montré sur les soigneurs seulement
    local drink = c.boxes.drink.groups.drink
    assert(drink and drink.filter == "HELPFUL" and drink.max == 1 and drink.candidates.includeSpellIDs[430], "groupe boisson")
    assert(not drink.candidates.includeSpellIDs[26473], "boisson au mauvais nom dans le filtre")
    assert(c.boxes.drink:IsShown(), "boisson cachee sur un soigneur")
    -- C34 : sous l'icône de mana basse (Tuile, Carré), à sa droite (Barre, Bandeau)
    local x, y, size, point = Z.DrinkPlace()
    local low = Z.AuraRows().homes.lowMana
    assert(drink.size == size and size == low.w and ((point == "TOPRIGHT" and x == low.x and y == low.y - size - 2)
      or (point == "LEFT" and x == low.x + size + 2 and y == low.y)), "boisson pas a cote de la mana basse")
    UnitGroupRolesAssigned = function() return "DAMAGER" end
    Z:Refresh() RunUpdates()
    assert(not c.boxes.drink:IsShown(), "boisson montree sur un joueur qui n'est pas soigneur")
    UnitGroupRolesAssigned = role
    Z.db.drinkHealers = false Z:Refresh()
    assert(not c.boxes.drink.groups.drink, "interrupteur : groupe boisson garde")
    Z.db.drinkHealers = true
  end, debug.traceback)
  finish()
  assert(ok, err)
end)

step("etape 23, lot 3 : soigneur qui boit, ancien affichage et mode test", function()
  local role, kept = UnitGroupRolesAssigned, Z.db.drinkHealers
  local ok, err = xpcall(function()
    for _, text in ipairs({ "Soigneur qui boit", "L'icône de sa boisson, à côté de sa mana basse." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
    local b = Z.buttons[1]
    AURAS = {}
    AURAS["HELPFUL"] = { { name = "Boisson", icon = 99, auraInstanceID = 91, spellId = 430 } }
    Z.db.drinkHealers = true Z:Refresh() Z.UpdateAurasNow(b)
    assert(b.drinkIcon and b.drinkIcon:IsShown() and b.drinkIcon.texture._tex == 99, "boisson absente sur un soigneur")
    -- une autre aura que la boisson : rien
    AURAS["HELPFUL"] = { { name = "Nourriture", icon = 98, auraInstanceID = 92, spellId = 26473 } }
    Z.UpdateAurasNow(b)
    assert(not b.drinkIcon:IsShown(), "boisson montree pour une autre aura")
    AURAS["HELPFUL"] = { { name = "Boisson", icon = 99, auraInstanceID = 91, spellId = 430 } }
    UnitGroupRolesAssigned = function() return "TANK" end
    Z:Refresh() Z.UpdateAurasNow(b)
    assert(not b.drinkIcon:IsShown(), "boisson montree sur un tank")
    UnitGroupRolesAssigned = role
    Z.db.drinkHealers = false Z:Refresh() Z.UpdateAurasNow(b)
    assert(not b.drinkIcon:IsShown(), "interrupteur : boisson reste")
    -- mode test : la boisson sur le soigneur à court de mana
    Z.db.drinkHealers = true
    local cell = Z.FakeCell(UIParent)
    Z.DrawFakeCell(cell, 2, false)
    assert(cell.drinkIcon and cell.drinkIcon:IsShown(), "mode test : boisson absente")
    Z.DrawFakeCell(cell, 3, false)
    assert(not cell.drinkIcon:IsShown(), "mode test : boisson sur un joueur qui n'est pas soigneur")
  end, debug.traceback)
  UnitGroupRolesAssigned, Z.db.drinkHealers = role, kept
  AURAS = {}
  Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("etape 23, lot 6 : visite guidee, phrases de mana selon les reglages et la classe, Ame affaiblie", function()
  local form, class = {}, Z.class
  for _, key in ipairs({ "fiveSecondRule", "manaEdge", "drinkHealers", "tutorialDone" }) do form[key] = Z.db[key] end
  local function CellText()
    Z:StartTutorial()
    local card = LyoruneTutorial
    card.next:Run("OnClick")
    local body = card.body:GetText()
    card.next:Run("OnClick") card.next:Run("OnClick")
    local colors = card.body:GetText()
    card.close:Run("OnClick")
    return body, colors
  end
  local ok, err = xpcall(function()
    local five, edge, drink = "trait fin sur votre case", "bord de l'écran bleuit", "boisson près de la mana"
    Z.class = "PRIEST" Z.db.fiveSecondRule, Z.db.manaEdge, Z.db.drinkHealers = true, 20, true
    local body, colors = CellText()
    assert(body:find(five, 1, true) and body:find(edge, 1, true) and body:find(drink, 1, true), "phrases de mana absentes")
    assert(colors:find("Âme affaiblie", 1, true), "Ame affaiblie absente de la carte des couleurs")
    -- chaque phrase suit son interrupteur
    Z.db.fiveSecondRule, Z.db.manaEdge, Z.db.drinkHealers = false, 0, false
    body = CellText()
    assert(not body:find(five, 1, true) and not body:find(edge, 1, true) and not body:find(drink, 1, true), "phrase d'un reglage eteint")
    -- classe sans mana : rien sur ma mana, la boisson des soigneurs reste
    Z.class = "WARRIOR" Z.db.fiveSecondRule, Z.db.manaEdge, Z.db.drinkHealers = true, 20, true
    body = CellText()
    assert(not body:find(five, 1, true) and not body:find(edge, 1, true) and body:find(drink, 1, true), "classe sans mana")
    for _, text in ipairs({ "Après un sort payé en mana, un trait fin sur votre case se vide en 5 secondes : ensuite, votre mana repart.",
      "Le bord de l'écran bleuit quand votre mana baisse.", "Une boisson près de la mana d'un soigneur : il boit." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
  end, debug.traceback)
  for key, value in pairs(form) do Z.db[key] = value end
  Z.class = class
  Z:Refresh()
  assert(ok, err)
end)

step("etape 24, lot 1 : joueurs en bonne sante estompes (courbe du jeu, survol, mort, interrupteur, mode test)", function()
  local kept = { healthyFade = Z.db.healthyFade, healthyFadeAt = Z.db.healthyFadeAt, text = Z.db.text }
  local create = C_CurveUtil.CreateColorCurve
  HEALTH_PCT = 0.95 -- vie du joueur pour les courbes (faux client)
  -- Courbe en escalier qui calcule vraiment l'opacité, comme le jeu
  C_CurveUtil.CreateColorCurve = function()
    local c = { points = {} }
    function c:SetType() end
    function c:AddPoint(x, color) self.points[#self.points + 1] = { x, color } end
    function c:Evaluate(x)
      local found = self.points[1][2]
      for _, p in ipairs(self.points) do if x >= p[1] then found = p[2] end end
      return found
    end
    return c
  end
  local ok, err = pcall(function()
    assert(Z.defaults.healthyFade == false and Z.defaults.healthyFadeAt == 90, "reglage healthyFade : eteint au depart, 90 %")
    assert(Z.limits.healthyFadeAt, "limites du seuil")
    local b = Z.buttons[1]
    b:SetAttribute("unit", "player") b.unit = "player"
    Z.db.text = "DEFICIT"
    Z.db.healthyFade = false Z:Refresh() Z.cellUpdates.health(b)
    assert(b.hp:GetAlpha() == 1 and b.name:GetAlpha() == 1, "eteint : case estompee")
    Z.db.healthyFade, Z.db.healthyFadeAt = true, 90 Z:Refresh() Z.cellUpdates.health(b)
    assert(b.hp:GetAlpha() == Z.HEALTHY_ALPHA and b.power:GetAlpha() == Z.HEALTHY_ALPHA and b.name:GetAlpha() == Z.HEALTHY_ALPHA, "95 % : pas estompe")
    assert(b.text:GetAlpha() == Z.HEALTHY_ALPHA, "95 % : chiffre de vie pas estompe")
    assert(b.over:GetAlpha() == 1 and b.top:GetAlpha() == 1, "icones et alertes estompees")
    HEALTH_PCT = 1 Z.cellUpdates.health(b)
    assert(b.text:GetAlpha() == 0 and b.hp:GetAlpha() == Z.HEALTHY_ALPHA, "100 % : chiffre visible ou case nette")
    HEALTH_PCT = 0.5 Z.cellUpdates.health(b)
    assert(b.hp:GetAlpha() == 1 and b.text:GetAlpha() == 1, "50 % : case estompee")
    -- survol : toujours nette, puis estompée de nouveau
    HEALTH_PCT = 0.95
    b:Run("OnEnter")
    assert(b.hp:GetAlpha() == 1 and b.text:GetAlpha() == 1, "survol : case estompee")
    b:Run("OnLeave")
    assert(b.hp:GetAlpha() == Z.HEALTHY_ALPHA, "apres le survol : case nette")
    -- pourcentage : estompé aussi
    Z.db.text = "PERCENT" Z:Refresh() Z.cellUpdates.health(b)
    assert(b.text:GetAlpha() == Z.HEALTHY_ALPHA, "pourcentage pas estompe")
    -- seuil changé
    Z.db.healthyFadeAt = 100 Z.db.text = "DEFICIT" Z:Refresh() Z.cellUpdates.health(b)
    assert(b.hp:GetAlpha() == 1, "seuil 100 % : 95 % estompe")
    HEALTH_PCT = 1 Z.cellUpdates.health(b)
    assert(b.hp:GetAlpha() == Z.HEALTHY_ALPHA, "seuil 100 % : pleine vie") -- chiffre : courbe « invisible à 100 % » d'avant
    -- joueur mort : jamais estompé
    rawset(_G, "DEAD", true) Z.cellUpdates.health(b)
    assert(b.hp:GetAlpha() == 1, "joueur mort estompe")
    rawset(_G, "DEAD", false) Z.cellUpdates.health(b)
    -- interrupteur coupé : tout redevient net
    Z.db.healthyFade = false Z:Refresh() Z.cellUpdates.health(b)
    assert(b.hp:GetAlpha() == 1 and b.name:GetAlpha() == 1 and b.power:GetAlpha() == 1, "coupe : case reste estompee")
    -- case témoin et mode test : un joueur à pleine vie s'estompe, un blessé non
    Z.db.healthyFade, Z.db.healthyFadeAt = true, 90
    local cell = Z.FakeCell(UIParent)
    Z.DrawFakeCell(cell, 1, true)
    assert(cell.hp:GetAlpha() == Z.HEALTHY_ALPHA and cell.text:GetAlpha() == Z.HEALTHY_ALPHA, "case temoin pas estompee")
    Z.DrawFakeCell(cell, 2, false)
    assert(cell.hp:GetAlpha() == 1, "faux joueur blesse estompe")
    Z.db.healthyFade = false Z.DrawFakeCell(cell, 1, true)
    assert(cell.hp:GetAlpha() == 1, "mode test : interrupteur")
    for _, text in ipairs({ "Estomper les joueurs en bonne santé", "Seuil de bonne santé (%)", "Ceux qui ont besoin de soins ressortent." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
  end)
  C_CurveUtil.CreateColorCurve, HEALTH_PCT = create, false
  rawset(_G, "DEAD", false)
  for key, value in pairs(kept) do Z.db[key] = value end
  Z:Refresh()
  assert(ok, err)
end)

step("etape 24, lot 2 : statistiques de mes clics (souris, touches au survol, sort change, echange, remise a zero)", function()
  local set = Z:ClickSet()
  local keptClicks, keptKeys, keptStats = Z.db.clicks[set], Z.db.hoverKeys[set], Z.char.clickStats
  local kept = { clickStats = Z.db.clickStats, externalClicks = Z.db.externalClicks }
  local shift = IsShiftKeyDown
  local ok, err = pcall(function()
    assert(Z.defaults.clickStats == false and Z.notInProfile.clickStats, "reglage clickStats : eteint au depart, hors profil")
    Z.db.clicks[set] = { ["shift-1"] = "Rénovation", ["1"] = "Soins rapides" }
    Z.db.hoverKeys[set] = { { key = "F", spell = "Prière de soins" } }
    Z.char.clickStats = nil
    Z:ApplyClicks()
    local b = Z.buttons[1]
    local renov, plain, key = { kind = "click", key = "shift-1" }, { kind = "click", key = "1" }, { kind = "key", key = "F" }
    -- éteint : rien n'est compté
    Z.db.clickStats = false
    b:Run("OnClick", "LeftButton", false)
    assert(Z.char.clickStats == nil, "eteint : clic compte")
    Z.db.clickStats = true
    -- clic seul, puis avec Maj, puis touche au survol (bouton virtuel « zh1 »)
    b:Run("OnClick", "LeftButton", false)
    IsShiftKeyDown = function() return true end
    b:Run("OnClick", "LeftButton", false) b:Run("OnClick", "LeftButton", false)
    IsShiftKeyDown = shift
    b:Run("OnClick", "zh1", true)
    assert(Z:ClickCount(plain, "Soins rapides") == 1, "clic seul")
    assert(Z:ClickCount(renov, "Rénovation") == 2, "Maj + clic gauche")
    assert(Z:ClickCount(key, "Prière de soins") == 1, "touche au survol")
    assert(type(Z:ClickStatsSince()) == "number", "date du debut des comptes")
    -- un clic libre (clic droit sans sort) ou un bouton inconnu ne compte pas
    b:Run("OnClick", "RightButton", false) b:Run("OnClick", "Button9", false) b:Run("OnClick", "zh7", true)
    assert(not Z.char.clickStats[set].lines["2"], "clic libre compte")
    -- Clique ou le jeu gèrent les clics : rien n'est compté
    Z.db.externalClicks = true
    b:Run("OnClick", "LeftButton", false)
    Z.db.externalClicks = false
    assert(Z:ClickCount(plain, "Soins rapides") == 1, "clics externes comptes")
    -- échange de deux raccourcis : chaque sort garde son compte
    Z:MoveBinding(renov, plain)
    assert(Z:ClickCount(plain, "Rénovation") == 2 and Z:ClickCount(renov, "Soins rapides") == 1, "echange : comptes perdus")
    -- touche renommée : son compte la suit
    Z:MoveBinding(key, { kind = "key", key = "G" })
    assert(Z:ClickCount({ kind = "key", key = "G" }, "Prière de soins") == 1, "touche renommee : compte perdu")
    -- un autre sort sur la ligne : le compte repart de zéro
    Z:SetBinding(plain, "Soins")
    assert(Z:ClickCount(plain, "Soins") == 0, "nouveau sort : ancien compte")
    b:Run("OnClick", "LeftButton", false)
    assert(Z:ClickCount(plain, "Soins") == 1, "nouveau sort : pas compte")
    -- liste des options : nombre à côté de chaque ligne, ligne jamais utilisée grisée
    Z:ToggleOptions("Sorts et raccourcis")
    local w = Z:OptionsWindow()
    local page = w.Select("Sorts et raccourcis")
    Z.RefreshClicks()
    local _, used = Z:ClickCell("1")
    local _, other = Z:ClickCell("shift-1")
    assert(used.count:IsShown() and used.count.n == 1 and used.spell:GetAlpha() == 1, "ligne utilisee")
    assert(other.count.n == 1, "compte apres echange")
    Z:SetBinding(renov, "Rénovation") Z.RefreshClicks()
    local _, never = Z:ClickCell("shift-1")
    assert(never.count.n == 0 and never.spell:GetAlpha() == 0.5 and never.key:GetAlpha() == 0.5, "ligne jamais utilisee pas grisee")
    never.count:Run("OnEnter") never.count:Run("OnLeave")
    assert(page.content.settings.clickStats, "reglage dans le chapitre Sorts et raccourcis")
    -- remise à zéro : la spécialisation affichée seulement
    Z.char.clickStats.OTHER = { since = 1, lines = { ["1"] = { v = "x", n = 3 } } }
    Z:ResetClickStats() Z.RefreshClicks()
    assert(Z:ClickCount(plain, "Soins") == 0 and Z.char.clickStats.OTHER.lines["1"].n == 3, "remise a zero")
    -- réglage coupé : plus de nombre, plus de ligne grisée
    page.content.settings.clickStats:Run("OnClick")
    assert(not Z.db.clickStats and not used.count:IsShown() and used.spell:GetAlpha() == 1, "coupe : nombre visible")
    w:Hide()
    for _, text in ipairs({ "Compter mes clics", "Remettre mes comptes à zéro", "Utilisé %d fois", "Depuis le %s" }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
  end)
  IsShiftKeyDown = shift
  Z.db.clicks[set], Z.db.hoverKeys[set], Z.char.clickStats = keptClicks, keptKeys, keptStats
  for k, value in pairs(kept) do Z.db[k] = value end
  Z:ApplyClicks() Z:Refresh()
  assert(ok, err)
end)

step("etape 25, lot 1 : mes joueurs (repere, groupes en raid, joueurs choisis, estompage, nom secret, commande, mode test)", function()
  local kept = { assignMark = Z.db.assignMark, assignFade = Z.db.assignFade, assignGroups = Z.db.assignGroups, assignPlayers = Z.db.assignPlayers }
  local keptRaid, keptGrouped, keptMembers, getName = RAID, GROUPED, MEMBERS, GetUnitName
  local roster = {}
  rawset(_G, "GetRaidRosterInfo", function(i) return "x", 0, roster[i] or 1 end)
  local b = Z.buttons[1]
  local ok, err = pcall(function()
    assert(Z.defaults.assignMark == true and Z.defaults.assignFade == false and Z.defaults.assignAccept == true, "reglages de depart")
    assert(Z.notInProfile.assignGroups and Z.notInProfile.assignFade and Z.private.assignGroups and Z.private.assignPlayers, "choix hors profil ou partage")
    Z.db.assignGroups, Z.db.assignPlayers = {}, {}
    GROUPED, RAID = true, false
    b:SetAttribute("unit", "party1") b.unit = "party1"
    Z.cellUpdates.all(b)
    local mine, active = Z.AssignState("party1")
    assert(mine == false and active == false and not b.assign:IsShown() and (b.assignDim or 1) == 1, "rien choisi : repere ou estompage")
    -- un joueur choisi, en groupe de cinq
    Z.db.assignPlayers["Joueur-party1"] = true
    Z.RefreshAssign()
    assert(b.assign:IsShown(), "joueur choisi sans repere")
    assert(Z.AssignState("party2") == false, "autre joueur pris pour le mien")
    assert(select(2, Z.AssignState("target")) == false, "case de ma cible comptee")
    -- les groupes ne comptent qu'en raid
    Z.db.assignPlayers, Z.db.assignGroups = {}, { [2] = true }
    assert(select(2, Z.AssignState("party1")) == false, "groupes comptes hors raid")
    RAID, MEMBERS = true, 10
    roster[3], roster[7] = 1, 2
    assert(Z.AssignState("raid7") == true and Z.AssignState("raid3") == false, "groupe de raid")
    -- les autres un peu estompés, la portée garde ses paliers
    Z.db.assignFade = true
    b:SetAttribute("unit", "raid3") b.unit = "raid3"
    Z.cellUpdates.all(b)
    assert(not b.assign:IsShown() and b.assignDim == Z.ASSIGN_DIM and math.abs(b:GetAlpha() - Z.ASSIGN_DIM) < 0.01, "autre joueur pas estompe")
    b:SetAttribute("unit", "raid7") b.unit = "raid7"
    Z.cellUpdates.all(b)
    assert(b.assign:IsShown() and (b.assignDim or 1) == 1 and b:GetAlpha() == 1, "mon joueur estompe")
    -- nom secret : la case garde son état
    GetUnitName = function() return MakeSecret() end
    assert(Z.AssignState("raid7") == nil, "nom secret : etat devine")
    Z.RefreshAssign()
    assert(b.assign:IsShown(), "nom secret : repere perdu")
    GetUnitName = getName
    -- repère coupé
    Z.db.assignMark = false Z.RefreshAssign()
    assert(not b.assign:IsShown(), "repere coupe")
    Z.db.assignMark = true
    -- /lyorune pourmoi : le joueur survolé, puis un nom tapé
    b:Run("OnEnter")
    SlashCmdList.LYORUNE("pourmoi")
    b:Run("OnLeave")
    assert(Z.db.assignPlayers["Joueur-raid7"], "pourmoi : joueur survole")
    SlashCmdList.LYORUNE("pourmoi joueur-raid7")
    assert(not Z.db.assignPlayers["Joueur-raid7"], "pourmoi : retrait")
    -- case témoin et mode test
    local cell = Z.FakeCell(UIParent)
    Z.DrawFakeCell(cell, 1, true)
    assert(cell.assign:IsShown(), "case temoin sans repere")
    Z.db.assignGroups = { [1] = true }
    Z.DrawFakeCell(cell, 7, false)
    assert(not cell.assign:IsShown() and math.abs(cell:GetAlpha() - Z.ASSIGN_DIM) < 0.01, "mode test : autre groupe")
    Z.DrawFakeCell(cell, 3, false)
    assert(cell.assign:IsShown() and cell:GetAlpha() == 1, "mode test : mon groupe")
    Z.db.assignGroups = {}
    Z.DrawFakeCell(cell, 1, true)
    assert(not cell.assign:IsShown(), "case temoin : repere sans choix")
    -- options : chapitre Joueurs
    Z:ToggleOptions("Joueurs")
    local w = Z:OptionsWindow()
    local page = w.Select("Joueurs")
    assert(page.content.settings.assignMark and page.content.settings.assignFade, "reglages hors du chapitre Joueurs")
    assert(Z.assignStatus and Z.assignStatus.text:GetText():find("votre choix", 1, true), "etat de la repartition")
    w:Hide()
    for _, text in ipairs({ "Repère sur mes joueurs", "Groupes de raid dont je m'occupe", "Joueurs dont je m'occupe", "Estomper un peu les autres", "%s fait partie de vos joueurs." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
  end)
  GetUnitName = getName
  RAID, GROUPED, MEMBERS = keptRaid, keptGrouped, keptMembers
  rawset(_G, "GetRaidRosterInfo", nil)
  for key, value in pairs(kept) do Z.db[key] = value end
  b.assignDim = nil
  Z:Refresh()
  assert(ok, err)
end)

step("etape 25, lot 2 : repartition du chef (droits, reception, envoi, blocage, code du jeu, depart, effacement, nouveau venu, fenetre)", function()
  local kept = { assignAccept = Z.db.assignAccept, assignGroups = Z.db.assignGroups, assignPlayers = Z.db.assignPlayers, syncEnabled = Z.db.syncEnabled }
  local keptRaid, keptGrouped, keptMembers, keptLeader, keptAssists, keptNames = RAID, GROUPED, MEMBERS, LEADER, ASSISTS, GROUP_NAMES
  local lockdown, send, now = C_ChatInfo.InChatMessagingLockdown, C_ChatInfo.SendAddonMessage, NOW
  local roster = { 1, 1, 2, 4, 3 }
  rawset(_G, "GetRaidRosterInfo", function(i) return "x", 0, roster[i] or 1 end)
  local function Msg(text, sender) FireEvent("CHAT_MSG_ADDON", "Lyorune", text, "RAID", sender) end
  local ok, err = pcall(function()
    Z.db.assignGroups, Z.db.assignPlayers, Z.db.syncEnabled, Z.db.assignAccept = { [3] = true }, {}, true, true
    Z.char.assignShared = nil
    GROUPED, RAID, MEMBERS, ASSISTS = true, true, 5, {}
    GROUP_NAMES = { raid1 = "Joueur-player", raid2 = "Chef", raid3 = "Soin", raid4 = "Tankou", raid5 = "Autre" }
    LEADER = "raid2"
    -- reçue du chef, en deux parts : appliquée d'office quand tout est là
    Msg("A:42:1:2:Joueur-player=12/Tankou-MonRoyaume", "Chef")
    assert(Z.char.assignShared == nil, "appliquee avant la derniere part")
    Msg("A:42:2:2:Soin-MonRoyaume=3/", "Chef")
    local shared = Z.char.assignShared
    assert(shared and shared.by == "Chef" and shared.healers["Joueur-player"].groups[1], "repartition recue")
    assert(PRINTED[#PRINTED]:find("Chef", 1, true) and PRINTED[#PRINTED]:find("groupes 1 et 2, Tankou", 1, true), "ligne dans la discussion : " .. PRINTED[#PRINTED])
    -- ma part remplace mon choix (groupe 3)
    assert(Z.AssignState("raid3") == true and Z.AssignState("raid4") == true and Z.AssignState("raid5") == false, "ma part")
    local healers = Z.AssignHealers("raid5")
    assert(healers and healers[1] == "Soin" and #healers == 1, "soigneur prevu au survol")
    -- sans droit : ignoré ; chef secret : refusé ; assistant en raid : accepté
    Msg("A:43:1:1:Joueur-player=5/", "Autre")
    assert(Z.char.assignShared.id == "42", "repartition d'un joueur sans droit")
    SECRET_LEADER = true Msg("A:45:1:1:Joueur-player=5/", "Chef") SECRET_LEADER = false
    assert(Z.char.assignShared.id == "42", "chef secret pris pour le chef")
    ASSISTS = { raid5 = true }
    Msg("A:44:1:1:Joueur-player=3/", "Autre")
    assert(Z.char.assignShared.id == "44" and Z.AssignState("raid5") == true, "assistant refuse")
    ASSISTS = {}
    -- messages abîmés : rien ne change
    for _, bad in ipairs({ "A:1:1:1:pasdenom=1/", "A:1:3:2:Joueur-player=1/", "A:1:1:99:Joueur-player=1/", "A:1:1:1:Joueur-player=1/a b-c", "A:x:1:1:Joueur-player=1/", "A:1:1:1:Joueur-player=123456789/" }) do
      Msg(bad, "Chef")
      assert(Z.char.assignShared.id == "44", "message abime accepte : " .. bad)
    end
    -- effacée : seulement par celui qui l'a envoyée
    Msg("A:44:0:0:", "Chef")
    assert(Z.char.assignShared, "effacee par un autre que l'expediteur")
    ASSISTS = { raid5 = true } Msg("A:44:0:0:", "Autre") ASSISTS = {}
    assert(Z.char.assignShared == nil and Z.AssignState("raid5") == true and Z.AssignState("raid3") == false, "effacement : mon choix ne revient pas")
    -- réglage coupé : ignorée
    Z.db.assignAccept = false
    Msg("A:46:1:1:Joueur-player=1/", "Chef")
    assert(Z.char.assignShared == nil, "repartition recue reglage coupe")
    Z.db.assignAccept = true
    -- envoi : je suis le chef
    LEADER = "player"
    local part = { name = "Soin", groups = { [1] = true, [2] = true }, players = { Tankou = true } }
    local first = #ADDON_SENT + 1
    local sent, message = Z:AssignSend({ ["Soin-MonRoyaume"] = part, ["Vide-MonRoyaume"] = { name = "Vide", groups = {}, players = {} } })
    assert(sent, message)
    assert(#ADDON_SENT == first and ADDON_SENT[first].channel == "RAID", "soigneur sans rien envoye")
    assert(ADDON_SENT[first].text == "A:" .. Z.char.assignShared.id .. ":1:1:Soin-MonRoyaume=12/Tankou-MonRoyaume", ADDON_SENT[first].text)
    Msg(ADDON_SENT[first].text, "Joueur-player") -- mon envoi revient du groupe : rien de plus
    assert(Z.char.assignShared.from == "Joueur-player", "mon envoi relu")
    -- trop tôt, bloqué par le jeu, freiné : refusé avec un message
    sent = Z:AssignSend({ ["Soin-MonRoyaume"] = part })
    assert(not sent, "renvoi trop rapproche")
    NOW = NOW + 5
    C_ChatInfo.InChatMessagingLockdown = function() return true end
    sent, message = Z:AssignSend({ ["Soin-MonRoyaume"] = part })
    assert(not sent and message:find("combat de boss", 1, true), "blocage du jeu : " .. tostring(message))
    C_ChatInfo.InChatMessagingLockdown = lockdown
    C_ChatInfo.SendAddonMessage = function() return 3 end
    sent = Z:AssignSend({ ["Soin-MonRoyaume"] = part })
    assert(not sent, "envoi freine pris pour reussi")
    C_ChatInfo.SendAddonMessage = send
    NOW = NOW + 5
    -- beaucoup de joueurs nommés : 5 au plus, message court
    local many = { name = "Soin", groups = { [1] = true }, players = {} }
    for i = 1, 9 do many.players["Joueurtreslongnumero" .. i .. "-RoyaumeAuNomInterminable"] = true end
    first = #ADDON_SENT + 1
    assert(Z:AssignSend({ ["Soin-MonRoyaume"] = many }))
    assert(#ADDON_SENT[first].text <= 255 and select(2, ADDON_SENT[first].text:gsub(",", "")) <= 4, "message trop long")
    -- sans droit : refusé
    LEADER = "raid2" NOW = NOW + 5
    sent, message = Z:AssignSend({ ["Soin-MonRoyaume"] = part })
    assert(not sent and message:find("chef", 1, true), "envoi sans droit")
    LEADER = "player"
    -- un nouveau venu qui a Lyorune la reçoit ; bloqué : dès que le jeu le permet
    first = #ADDON_SENT + 1
    Z.AssignNewMember("Nouveau")
    assert(ADDON_SENT[first] and ADDON_SENT[first].channel == "WHISPER" and ADDON_SENT[first].target == "Nouveau", "nouveau venu oublie")
    C_ChatInfo.InChatMessagingLockdown = function() return true end
    first = #ADDON_SENT + 1
    Z.AssignNewMember("Tardif")
    assert(#ADDON_SENT == first - 1, "envoi pendant le blocage")
    C_ChatInfo.InChatMessagingLockdown = lockdown
    FireEvent("PLAYER_REGEN_ENABLED")
    assert(ADDON_SENT[first] and ADDON_SENT[first].target == "Tardif", "nouveau venu en attente oublie")
    -- un soigneur part : ses joueurs restent sans soigneur, je suis prévenu
    GROUP_NAMES.raid3 = "Remplacant"
    FireEvent("GROUP_ROSTER_UPDATE")
    assert(Z.char.assignShared.healers["Soin-MonRoyaume"] == nil and PRINTED[#PRINTED]:find("Soin est parti", 1, true), "depart : " .. PRINTED[#PRINTED])
    -- fenêtre du chef : une ligne par soigneur, une colonne par groupe de raid ; une case cochée part au groupe
    Z:OpenAssign()
    local w = _G.LyoruneAssign
    assert(w and w:IsShown() and #w.rows >= 5 and w.rows[1].boxes[1], "fenetre de repartition")
    w.rows[2].boxes[1]:Run("OnClick")
    NOW = NOW + 5
    first = #ADDON_SENT + 1
    w.send:Run("OnClick")
    assert(ADDON_SENT[first] and ADDON_SENT[first].text:match("^A:%d+:1:%d:"), "envoi depuis la fenetre : " .. tostring(w.status:GetText()))
    w.clear:Run("OnClick")
    assert(Z.char.assignShared == nil and ADDON_SENT[#ADDON_SENT].text:match(":0:0:$"), "effacer pour tous")
    w:Hide()
    -- oubliée quand je quitte le groupe
    LEADER = "raid2"
    Msg("A:47:1:1:Joueur-player=1/", "Chef")
    assert(Z.char.assignShared and Z.char.assignShared.id == "47", "repartition du chef")
    GROUPED, RAID = false, false
    FireEvent("GROUP_ROSTER_UPDATE")
    assert(Z.char.assignShared == nil, "sortie du groupe : repartition gardee")
    for _, text in ipairs({ "Répartir les soigneurs", "Envoyer au groupe", "Appliquer la répartition du chef", "Soigneur prévu : %s", "répartition de %s : vous soignez %s.", "%s est parti : %s sans soigneur prévu." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
  end)
  C_ChatInfo.InChatMessagingLockdown, C_ChatInfo.SendAddonMessage, NOW = lockdown, send, now
  RAID, GROUPED, MEMBERS, LEADER, ASSISTS, GROUP_NAMES = keptRaid, keptGrouped, keptMembers, keptLeader, keptAssists, keptNames
  rawset(_G, "SECRET_LEADER", nil)
  rawset(_G, "GetRaidRosterInfo", nil)
  Z.char.assignShared = nil
  for key, value in pairs(kept) do Z.db[key] = value end
  Z:Refresh()
  assert(ok, err)
end)

step("33 ter (C32) : vie basse en lisere rouge fixe, en combat seulement (sans battement, vie inconnue, portee, releve, mode test)", function()
  local kept = { lowHealth = Z.db.lowHealth, lowHealthAt = Z.db.lowHealthAt }
  local create = C_CurveUtil.CreateColorCurve
  C_CurveUtil.CreateColorCurve = function()
    local c = { points = {} }
    function c:SetType() end
    function c:AddPoint(x, color) self.points[#self.points + 1] = { x, color } end
    function c:Evaluate(x)
      local found = self.points[1][2]
      for _, p in ipairs(self.points) do if x >= p[1] then found = p[2] end end
      return found
    end
    return c
  end
  local ok, err = pcall(function()
    Z.db.lowHealth, Z.db.lowHealthAt = true, 25 Z:Refresh()
    local b = Z.buttons[1]
    assert(b.low.fill.isBorder and not b.low.pulse, "le voile bat encore ou n'est pas un lisere")
    assert(Z.PulseLow == nil and Z.LOW_BEATS == nil, "restes du battement")
    -- hors combat : jamais de lisere, meme a 10 %
    HEALTH_PCT = 0.1
    FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
    FireEvent("UNIT_HEALTH", b.unit) RunUpdates()
    assert(b.low.fill:GetAlpha() == 0, "lisere hors combat")
    -- entree en combat : le lisere vient sans attendre un changement de vie
    COMBAT = true FireEvent("PLAYER_REGEN_DISABLED") RunUpdates()
    assert(b.low.fill:GetAlpha() == 1, "pas de lisere en combat a 10 %")
    -- la vie remonte sans evenement (jeu en retard) : le passage de la portee l'efface (jamais bloque)
    HEALTH_PCT = 1
    b:Show() TICK() TICK()
    assert(b.low.fill:GetAlpha() == 0, "lisere reste a 100 %")
    HEALTH_PCT = 0.1 Z.cellUpdates.health(b)
    assert(b.low.fill:GetAlpha() == 1, "lisere absent a 10 %")
    -- vie maximale lisible a 0 (joueur en chargement) : rien
    HEALTH_MAX = 0
    FireEvent("UNIT_MAXHEALTH", b.unit) RunUpdates()
    assert(b.low.fill:GetAlpha() == 0, "lisere pour une vie inconnue")
    -- vie maximale secrete : aucune comparaison, aucune erreur
    HEALTH_MAX = nil
    SECRET = true
    FireEvent("UNIT_MAXHEALTH", b.unit) RunUpdates()
    SECRET = false
    -- sortie de combat : efface tout de suite
    Z.cellUpdates.health(b)
    assert(b.low.fill:GetAlpha() == 1, "lisere perdu")
    COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
    assert(b.low.fill:GetAlpha() == 0, "lisere reste apres le combat")
    -- releve des cadres : vie max, lisere, combat
    Z.header:SetAttribute("child1", b)
    local state = table.concat(Z:FrameState(), "\n")
    Z.header:SetAttribute("child1", nil)
    assert(state:find("vie basse : vie max=1000", 1, true) and state:find("combat=false", 1, true), state)
    -- mode test : montre le lisere meme hors combat, pour le voir
    Z.db.lowHealthAt = 100 Z:Refresh()
    Z:TogglePreview(10)
    local low = 0
    for index, cell in ipairs(Z:PreviewCells(10)) do
      if index <= 10 and cell.low.fill:GetAlpha() == 1 then low = low + 1 end
    end
    Z:TogglePreview()
    assert(low > 0, "mode test : aucun lisere")
  end)
  C_CurveUtil.CreateColorCurve, HEALTH_PCT = create, false
  HEALTH_MAX = nil
  SECRET = false COMBAT = false
  FireEvent("PLAYER_REGEN_ENABLED")
  for key, value in pairs(kept) do Z.db[key] = value end
  Z:Refresh()
  assert(ok, err)
end)

step("33 ter (C35) : aucun chiffre de vie sur un familier (vraie case et mode test)", function()
  local kept = Z.db.text
  local old = { health = UnitHealth, dead = UnitIsDeadOrGhost }
  local ok, err = pcall(function()
    local b = Z.buttons[1]
    for _, mode in ipairs({ "PERCENT", "DEFICIT" }) do
      Z.db.text = mode Z:Refresh()
      b.isPet = true Z.cellUpdates.health(b)
      assert(b.text:GetText() == "", mode .. " : chiffre de vie sur un familier")
      b.isPet = nil Z.cellUpdates.health(b)
      assert(b.text:GetText() ~= "", mode .. " : chiffre de vie perdu sur un joueur")
    end
    -- familier mort en combat, état secret : vie à 0 lue, jamais de liseré rouge (retour de l'auteur, 1.48.0)
    UnitHealth = function() return 0 end
    UnitIsDeadOrGhost = function() return MakeSecret() end
    COMBAT = true FireEvent("PLAYER_REGEN_DISABLED")
    b.isPet = true Z:Refresh() Z.cellUpdates.health(b)
    assert(b.low.fill:GetAlpha() == 0 and not b.low:IsShown(), "liseré rouge sur un familier")
    b.isPet = nil Z:Refresh() Z.cellUpdates.health(b)
    local a = b.low.fill:GetAlpha()
    assert(issecretvalue(a) or a > 0, "plus de liseré sur un joueur à 0")
  end)
  UnitHealth, UnitIsDeadOrGhost = old.health, old.dead
  if COMBAT then COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") end
  Z.buttons[1].isPet = nil
  Z.db.text = kept Z:Refresh()
  assert(ok, err)
end)

step("etape 26 a : buffs complets (quatre classes, JcE et JcJ, toutes les absences, seuil, benedictions, arme, recharge, options)", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = type(v) == "table" and CopyTable(v) or v end
  local old = { name = C_Spell.GetSpellName, known = C_SpellBook.IsSpellKnown, isUnit = UnitIsUnit, class = UnitClass,
    role = UnitGroupRolesAssigned, after = C_Timer.After, cd = C_Spell.GetSpellCooldown, zclass = Z.class,
    instance = INSTANCE, itype = INSTANCE_TYPE, now = NOW, lastChoice = Z.char.lastChoice, passive = C_Spell.IsSpellPassive }
  local ok, err = pcall(function()
    local extra = { [14752] = "Esprit divin", [27681] = "Prière d'esprit", [976] = "Protection contre l'ombre",
      [27683] = "Prière de protection contre l'ombre", [588] = "Feu intérieur",
      [19740] = "Bénédiction de puissance", [19742] = "Bénédiction de sagesse", [20217] = "Bénédiction des rois",
      [25780] = "Fureur vertueuse", [408510] = "Bouclier d'eau", [324] = "Bouclier de foudre",
      [8024] = "Arme Langue de feu", [8017] = "Arme Croque-roc" }
    C_Spell.GetSpellName = function(id) return extra[id] or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return extra[id] ~= nil or old.known(id) end
    local me = Z.buttons[1]
    local other
    for _, b in ipairs(Z.buttons) do
      if b ~= me and b.unit and not b.extra and b:IsVisible() and not b.unit:find("pet") then other = other or b end
    end
    assert(other, "faux groupe trop petit")
    UnitIsUnit = function(a, b) return a == b or (b == "player" and a == me.unit) end
    local classes = {}
    UnitClass = function(u) local c = classes[u] if c then return c, c end return old.class(u) end
    local later = {}
    C_Timer.After = function(s, f) if s >= 1 then later[#later + 1] = { s = s, f = f } else f() end end
    local function Ids(b)
      local t = {} for _, m in ipairs(b.missingBuffs or {}) do t[#t + 1] = m.check.id end
      return table.concat(t, ",")
    end
    local function Spell(b, id) for _, m in ipairs(b.missingBuffs or {}) do if m.check.id == id then return m.spell end end end
    local function Update() Z:Refresh() RunUpdates() end
    INSTANCE, INSTANCE_TYPE = true, "party"
    Z.db.buffWatch, Z.db.buffRenew, Z.db.buffGroupAt = {}, 0, 3
    Z.db.missingBuffs, Z.db.buffPanel = true, true

    -- Pretre : Robustesse, Esprit divin (joueurs a mana), Feu interieur (sur moi) ; Protection contre l'ombre
    -- aussi, tous actifs au depart ; sorts de race inconnus ignores
    Z.class = "PRIEST" Z:BuildData() AURAS = {} Update()
    assert(#Z.buffChecks == 4, "buffs du pretre : " .. #Z.buffChecks)
    assert(Ids(me) == "1243,14752,976,588", "pretre, sur moi : " .. Ids(me))
    assert(Ids(other) == "1243,14752,976", "pretre, un autre joueur : " .. Ids(other))
    assert(me.missingBuff == me.missingBuffs[1] and me.buffIcon:IsShown(), "icone de la case : le premier")
    classes[other.unit] = "WARRIOR" Update()
    assert(Ids(other) == "1243,976", "Esprit divin propose a un guerrier : " .. Ids(other))
    classes[other.unit] = nil
    -- toutes les absences d'un joueur : une ligne chacune dans le panneau
    Z.db.buffGroupAt = 5 Update()
    local mine = 0
    for _, row in ipairs(Z.BuffRows()) do if row.unit == me.unit and not row.count then mine = mine + 1 end end
    assert(mine >= 2, "une ligne par buff manquant : " .. mine)
    local feu
    for _, row in ipairs(Z.BuffRows()) do if row.spell == "Feu intérieur" then feu = row end end
    assert(feu and feu.unit == me.unit and not feu.spell2, "Feu interieur sur moi seulement")
    -- version de groupe des N joueurs (reglage)
    local n = 0
    for _, b in ipairs(Z.buttons) do
      if b.unit and not b.extra and b:IsVisible() and Spell(b, 1243) and not b.unit:find("pet") then n = n + 1 end
    end
    local function GroupRow() for _, row in ipairs(Z.BuffRows()) do if row.count and row.check.id == 1243 then return row end end end
    Z.db.buffGroupAt = 2 Update()
    assert(n < 2 or GroupRow(), "version de groupe des 2 joueurs")
    Z.db.buffGroupAt = math.min(5, n + 1) Update()
    assert(n >= 5 or not GroupRow(), "version de groupe sous le seuil")
    -- 32 d : seuls comptent les joueurs a portee du sort de groupe ; leurs cases montrent l'icone de cette version
    Z.db.buffGroupAt = 2 Update()
    local row = GroupRow()
    if n >= 2 then
      local check = row.check
      assert(check.groupIcon and row.icon == check.groupIcon, "ligne de groupe : icone de la version de groupe")
      for _, e in ipairs(row.players) do
        assert(Z.GroupCover(e.unit, check) == check.groupIcon, "case couverte sans l'icone de groupe")
      end
      local far
      for _, e in ipairs(row.players) do if not UnitIsUnit(e.unit, "player") then far = far or e.unit end end
      local oldDistance = UnitDistanceSquared
      local okFar, errFar = pcall(function()
        UnitDistanceSquared = function(u) if u == far then return 50 * 50, true end return 25, true end
        Z.db.buffGroupAt = row.count
        assert(not GroupRow(), "joueur hors de portee compte pour la version de groupe")
        local own
        for _, r in ipairs(Z.BuffRows()) do if r.unit == far and r.check == check and not r.count then own = r end end
        assert(own, "joueur loin sans sa propre ligne")
        assert(not Z.GroupCover(far, check), "joueur loin couvert par la version de groupe")
        -- distance secrete (en instance) : rien n'est ecarte a tort
        UnitDistanceSquared = function() return MakeSecret(2500), MakeSecret(true) end
        assert(GroupRow(), "distance secrete : joueur ecarte a tort")
        -- version de groupe seule cochee : personne n'a de ligne a lui, le joueur loin reste dans la ligne de groupe
        UnitDistanceSquared = function(u) if u == far then return 50 * 50, true end return 25, true end
        Z.db.buffWatch = { [1243] = { pve = false } } Update()
        local g = GroupRow()
        assert(g and g.count == row.count, "groupe seul : joueur loin perdu")
        assert(not UnitIsUnit(g.unit, far), "groupe seul : la ligne vise le joueur loin")
        Z.db.buffWatch = {} Update()
      end)
      UnitDistanceSquared = oldDistance
      Z.db.buffWatch = {}
      assert(okFar, errFar)
    end
    Z.db.buffGroupAt = 3
    -- JcJ : la colonne JcJ compte en champ de bataille et en arene
    INSTANCE_TYPE = "pvp" Update()
    assert(Ids(me) == "1243,14752,976,588", "liste JcJ : " .. Ids(me))
    INSTANCE_TYPE = "arena" Update() assert(Ids(other) == "1243,14752,976", "arene : " .. Ids(other))
    INSTANCE_TYPE = "party"
    Z.db.buffWatch[976] = { pvp = false } Update()
    assert(Ids(other) == "1243,14752,976", "decoche en JcJ seulement : " .. Ids(other))
    Z.db.buffWatch = { [1243] = { pve = false }, [21562] = { pve = false } } Update()
    assert(Ids(other) == "14752,976", "buff decoche en JcE : " .. Ids(other))
    INSTANCE_TYPE = "pvp" Update() assert(Ids(other):find("1243", 1, true), "decoche en JcE seulement")
    INSTANCE_TYPE = "party" Z.db.buffWatch = {}
    -- buff present, puis presque fini (reglage « buffRenew ») : relu tout seul au passage du seuil
    NOW = 1000
    AURAS["HELPFUL"] = { { name = "Mot de pouvoir : Robustesse", icon = 9, auraInstanceID = 31, expirationTime = NOW + 120 } }
    Update() assert(not Ids(other):find("1243", 1, true), "buff present compte absent")
    Z.db.buffRenew = 300 Update() assert(Ids(other):find("1243", 1, true), "buff presque fini non propose")
    later = {}
    Z.db.buffRenew = 60 Update()
    assert(not Ids(other):find("1243", 1, true), "buff encore long propose")
    local rdv = {}
    for _, l in ipairs(later) do if l.s > 55 and l.s < 65 then rdv[#rdv + 1] = l end end
    assert(#rdv > 0, "aucun rendez-vous au passage du seuil")
    NOW = NOW + 61 for _, l in ipairs(rdv) do l.f() end RunUpdates()
    assert(Ids(other):find("1243", 1, true), "case non relue au passage du seuil")
    AURAS["HELPFUL"] = { { name = "Mot de pouvoir : Robustesse", icon = 9, auraInstanceID = 31, expirationTime = 0 } }
    Update() assert(not Ids(other):find("1243", 1, true), "buff sans fin compte presque fini")
    Z.db.buffRenew = 0
    -- nom secret (1.35.0) : Robustesse lue juste avant reste connue (BuffMemory.lua), le reste inconnu est propose
    AURAS["HELPFUL"] = { { name = MakeSecret(), icon = 9, auraInstanceID = 31 } }
    Update() assert(Ids(other) == "14752,976", "nom secret : " .. Ids(other))
    AURAS = {}

    -- Buffs uniques : Gardien de peur eteint au depart, attend la fin de sa recharge
    UnitGroupRolesAssigned = function(u) return u == other.unit and "TANK" or "HEALER" end
    local function Fear() for _, row in ipairs(Z.BuffRows()) do if row.spell == "Gardien de peur" then return row end end end
    Update()
    assert(#Z.uniqueChecks == 1 and Fear() and Fear().unit == other.unit, "Gardien de peur actif au depart, pas propose au tank")
    Z.db.buffWatch[6346] = { pve = false } Update()
    assert(not Fear(), "Gardien de peur decoche encore propose")
    Z.db.buffWatch = {} Update()
    later = {}
    C_Spell.GetSpellCooldown = function() return { startTime = NOW - 5, duration = 30, isOnGCD = false } end
    assert(not Fear(), "Gardien de peur propose pendant sa recharge")
    assert(#later >= 1 and later[#later].s > 24 and later[#later].s < 26, "panneau non relu a la fin de la recharge")
    C_Spell.GetSpellCooldown = function() return { startTime = NOW, duration = 1.5, isOnGCD = true } end
    assert(Fear(), "temps de recharge global pris pour une recharge")
    C_Spell.GetSpellCooldown = function() return { startTime = MakeSecret(), duration = MakeSecret(), isOnGCD = MakeSecret() } end
    assert(Fear(), "recharge secrete")
    C_Spell.GetSpellCooldown = old.cd
    -- 1.33.4 : sur qui poser chaque buff a une personne (tank au depart, moi, un joueur choisi)
    local third
    for _, b in ipairs(Z.buttons) do
      if b ~= me and b ~= other and b.unit and not b.extra and b:IsVisible() and not b.unit:find("pet") then third = third or b end
    end
    assert(third, "faux groupe trop petit pour le porteur")
    Z.char.buffTarget = {}
    assert(Z.BuffBearer(6346) == "TANK" and Fear().unit == other.unit and Fear().why == "tank", "depart : le tank")
    Z.SetBuffBearer(6346, "ME") assert(Fear().unit == me.unit and Fear().why == "vous", "sur moi")
    GROUP_NAMES[third.unit] = "Thrall"
    Z.SetBuffBearer(6346, "NAME", "Thrall") assert(Fear().unit == third.unit and Fear().why == "choisi", "joueur choisi")
    Z.SetBuffBearer(6346, "NAME", "Absent") assert(Fear().unit == other.unit, "joueur choisi absent : le tank")
    UnitGroupRolesAssigned = function() return "HEALER" end
    assert(Fear().unit == me.unit, "ni tank ni joueur choisi : moi")
    UnitGroupRolesAssigned = function(u) return u == other.unit and "TANK" or "HEALER" end
    -- la commande vaut pour tous les buffs uniques et efface les choix par buff
    Z.SetBuffBearer(6346, "ME")
    SlashCmdList.LYORUNE("porteur thrall")
    assert(Z.char.buffTarget.byId == nil and Z.BuffBearer(6346) == "NAME" and Fear().unit == third.unit, "commande porteur")
    SlashCmdList.LYORUNE("porteur thrall")
    assert(Z.BuffBearer(6346) == "TANK", "commande : retour au tank")
    Z.db.buffWatch = {}

    -- Paladin : une benediction de moi par joueur (Sagesse a mana, Puissance, Rois au tank et au chasseur) ;
    -- Fureur vertueuse active au depart
    Z.class = "PALADIN" Z:BuildData() UnitGroupRolesAssigned = function() return "HEALER" end Update()
    assert(Ids(me) == "19740,25780" and Spell(me, 19740) == "Bénédiction de sagesse", "paladin, joueur a mana : " .. tostring(Spell(me, 19740)))
    classes[other.unit] = "WARRIOR" Update()
    assert(Spell(other, 19740) == "Bénédiction de puissance", "guerrier : " .. tostring(Spell(other, 19740)))
    classes[other.unit] = "HUNTER" Update()
    assert(Spell(other, 19740) == "Bénédiction des rois", "chasseur : " .. tostring(Spell(other, 19740)))
    UnitGroupRolesAssigned = function(u) return u == other.unit and "TANK" or "HEALER" end
    classes[other.unit] = "WARRIOR" Update()
    assert(Spell(other, 19740) == "Bénédiction des rois", "tank : " .. tostring(Spell(other, 19740)))
    UnitGroupRolesAssigned = function() return MakeSecret() end Update()
    assert(Spell(other, 19740) == "Bénédiction de puissance", "role secret")
    classes[other.unit] = nil UnitGroupRolesAssigned = function() return "HEALER" end
    -- la benediction d'un autre paladin ne compte pas, la mienne oui (n'importe laquelle)
    AURAS["HELPFUL"] = { { name = "Bénédiction de sagesse", icon = 9, auraInstanceID = 41 } }
    Update() assert(Ids(other) == "19740", "benediction d'un autre paladin prise pour la mienne")
    AURAS["HELPFUL|PLAYER"] = { { name = "Bénédiction des rois", icon = 9, auraInstanceID = 42 } }
    Update() assert(Ids(other) == "", "ma benediction non reconnue : " .. Ids(other))
    AURAS = {}
    Z.db.buffWatch[25780] = { pve = false } Update()
    assert(Ids(me) == "19740" and Ids(other) == "19740", "Fureur vertueuse decochee : " .. Ids(me))
    -- auras du paladin : une des miennes suffit, la derniere lancee est proposee
    extra[465], extra[19746] = "Aura de dévotion", "Aura de concentration"
    Z:BuildData() Update()
    assert(Ids(me) == "19740,465" and Ids(other) == "19740", "aura sur moi seulement : " .. Ids(me))
    assert(Spell(me, 465) == "Aura de dévotion", "premiere aura connue")
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 19746) Update()
    assert(Spell(me, 465) == "Aura de concentration", "derniere aura lancee non proposee")
    AURAS["HELPFUL"] = { { name = "Aura de dévotion", icon = 9, auraInstanceID = 61 } }
    Update() assert(Ids(me) == "19740,465", "aura d'un autre paladin prise pour la mienne")
    AURAS["HELPFUL|PLAYER"] = { { name = "Aura de concentration", icon = 9, auraInstanceID = 62 } }
    Update() assert(not Ids(me):find("465", 1, true), "mon aura non reconnue : " .. Ids(me))
    AURAS = {} extra[465], extra[19746] = nil, nil
    Z.db.buffWatch = {}

    -- Chaman : Bouclier d'eau ou de foudre sur moi, enchantement d'arme (le dernier lance)
    Z.class = "SHAMAN" Z:BuildData()
    local has, left = false, 0
    rawset(_G, "GetWeaponEnchantInfo", function() return has, left end)
    Update()
    assert(Ids(me) == "408510,8024" and Ids(other) == "", "chaman : " .. Ids(me) .. " / " .. Ids(other))
    assert(Spell(me, 408510) == "Bouclier d'eau" and Spell(me, 8024) == "Arme Langue de feu", "sorts du chaman")
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 8017)
    assert(Z.char.lastChoice and Z.char.lastChoice[8024] == 8017, "enchantement lance non retenu")
    Update() assert(Spell(me, 8024) == "Arme Croque-roc", "dernier enchantement non propose")
    AURAS["HELPFUL"] = { { name = "Bouclier de foudre", icon = 9, auraInstanceID = 51 } }
    has, left = true, 1800000
    later = {}
    FireEvent("WEAPON_ENCHANT_CHANGED") RunUpdates()
    assert(Ids(me) == "", "bouclier de foudre ou arme enchantee non reconnus : " .. Ids(me))
    local weaponRdv
    for _, l in ipairs(later) do if l.s > 1799 and l.s < 1802 then weaponRdv = l end end
    assert(weaponRdv, "fin de l'enchantement non attendue")
    rawset(_G, "GetWeaponEnchantInfo", function() return MakeSecret(), MakeSecret() end)
    Update() assert(Ids(me) == "", "enchantement secret")
    rawset(_G, "GetWeaponEnchantInfo", nil)
    AURAS = {}

    -- Druide : Augure de clarte sur soi, jamais propose s'il est passif sur ce client
    extra[1126], extra[16864] = "Marque du fauve", "Augure de clarté"
    Z.class = "DRUID" Z:BuildData() Update()
    assert(Ids(me) == "1126,16864" and Ids(other) == "1126", "druide : " .. Ids(me))
    C_Spell.IsSpellPassive = function(id) return id == 16864 end
    Z:BuildData() Update()
    assert(Ids(me) == "1126", "sort passif propose : " .. Ids(me))
    C_Spell.IsSpellPassive = old.passive extra[1126], extra[16864] = nil, nil

    -- Options : « Mes buffs », deux cases par buff, un choix egal au depart est efface
    Z.class = "PRIEST" Z:BuildData()
    Z:ToggleOptions("Joueurs")
    local box = Z.buffWatchBox
    assert(box, "liste Mes buffs absente")
    box:Update()
    local row976
    for _, row in ipairs(box.lines) do if row:IsShown() and row.entry.id == 976 then row976 = row end end
    assert(row976 and row976.checks[1].on and row976.checks[2].on, "Protection contre l'ombre : active au depart")
    -- la version de groupe a sa propre ligne, juste en dessous : decochee, le panneau ne propose que la version simple
    local rowPrayer
    for _, row in ipairs(box.lines) do if row:IsShown() and row.entry.id == 21562 then rowPrayer = row end end
    assert(rowPrayer and rowPrayer.entry.group and rowPrayer.checks[1].on, "ligne de la Priere de robustesse")
    assert(not row976.name:GetText():find("Prière", 1, true), "Priere encore sur la ligne du buff simple")
    AURAS = {} Z.db.buffGroupAt = 2 Update()
    local function HasPrayer()
      for _, r in ipairs(Z.BuffRows()) do if r.spell == "Prière de robustesse" or r.spell2 == "Prière de robustesse" then return true end end
    end
    assert(HasPrayer(), "Priere de robustesse non proposee au depart")
    rowPrayer.checks[1]:Run("OnClick")
    assert(Z.db.buffWatch[21562] and Z.db.buffWatch[21562].pve == false, "case de la Priere non enregistree")
    Update() assert(not HasPrayer(), "Priere decochee encore proposee")
    local simple = false
    for _, r in ipairs(Z.BuffRows()) do if r.spell == "Mot de pouvoir : Robustesse" then simple = true end end
    assert(simple, "version simple absente quand la Priere est decochee")
    rowPrayer.checks[1]:Run("OnClick") Z.db.buffGroupAt = 3 Update()
    row976.checks[1]:Run("OnClick")
    assert(Z.db.buffWatch[976] and Z.db.buffWatch[976].pve == false, "case JcE non enregistree")
    row976.checks[1]:Run("OnClick")
    assert(Z.db.buffWatch[976] == nil, "retour au depart non efface")
    -- buff a une personne : sa 2e ligne « Sur : Tank / Moi / Un joueur »
    local fearRow
    for _, row in ipairs(box.lines) do if row:IsShown() and row.entry.id == 6346 then fearRow = row end end
    assert(fearRow and fearRow.modes and fearRow.modes[1]:IsShown() and not fearRow.edit:IsShown(), "choix du porteur absent")
    assert(not row976.modes or not row976.modes[1]:IsShown(), "choix du porteur sur un buff de groupe")
    fearRow.modes[2]:Run("OnClick") assert(Z.BuffBearer(6346) == "ME", "bouton Moi")
    fearRow.modes[3]:Run("OnClick") assert(Z.BuffBearer(6346) == "NAME" and fearRow.edit:IsShown() and fearRow.pick:IsShown(), "bouton Un joueur")
    fearRow.edit:SetText("thrall") fearRow.edit:Run("OnEnterPressed")
    local mode, who = Z.BuffBearer(6346)
    assert(mode == "NAME" and who == "Thrall", "nom tape : " .. tostring(who))
    fearRow.edit:SetText("") fearRow.edit:Run("OnEnterPressed") assert(Z.BuffBearer(6346) == "TANK", "nom efface : retour au tank")
    fearRow.modes[1]:Run("OnClick") assert(Z.BuffBearer(6346) == "TANK", "bouton Tank")
    for _, text in ipairs({ "Sur :", "Moi", "Un joueur", "Nom, puis Entrée", "Ma cible", "vous", "ciblez d'abord le joueur qui doit recevoir ce buff." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
    Z.char.buffTarget = {} GROUP_NAMES[third.unit] = nil
    local shown = 0 for _, row in ipairs(box.lines) do if row:IsShown() then shown = shown + 1 end end
    assert(shown == 8, "lignes du pretre : " .. shown) -- 4 buffs, 3 Prieres et Gardien de peur, sans les sorts de race que je n'ai pas
    for _, row in ipairs(box.lines) do assert(not row:IsShown() or row.entry.id ~= 15473, "Forme d'ombre proposee a un soigneur") end
    for _, row in ipairs(box.lines) do assert(not row:IsShown() or (row.entry.id ~= 2652 and row.entry.id ~= 18137), "sort de race d'une autre race") end
    extra[2652] = "Toucher de faiblesse" box:Update()
    shown = 0 for _, row in ipairs(box.lines) do if row:IsShown() then shown = shown + 1 end end
    assert(shown == 9, "sort de race que j'ai : absent de Mes buffs")
    extra[2652] = nil
    local labels = table.concat(Z:OptionLabels(), "|")
    for _, text in ipairs({ "Mes buffs", "Proposer à nouveau sous (secondes)", "Sort de groupe dès (joueurs sans le buff)" }) do
      assert(labels:find(text, 1, true), "absent de la recherche : " .. text)
    end
    for _, text in ipairs({ "Mes buffs", "JcE", "JcJ", "une personne", "sur vous", " ou ", "Bénédictions (une de vous par joueur)",
      "Enchantement de l'arme", "Votre classe n'a aucun buff à surveiller." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
    Z:ToggleOptions()
  end)
  C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, UnitIsUnit, UnitClass = old.name, old.known, old.isUnit, old.class
  UnitGroupRolesAssigned, C_Timer.After, C_Spell.GetSpellCooldown = old.role, old.after, old.cd
  INSTANCE, INSTANCE_TYPE, NOW, Z.char.lastChoice, C_Spell.IsSpellPassive = old.instance, old.itype, old.now, old.lastChoice, old.passive
  rawset(_G, "GetWeaponEnchantInfo", nil)
  for k, v in pairs(saved) do Z.db[k] = v end
  Z.class = old.zclass Z:BuildData() AURAS = {} Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("1.33.7 : version simple et de groupe cochees a part, Mes buffs aligne, buffs 2 minutes avant leur fin, buffs a une personne par classe et par situation", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = type(v) == "table" and CopyTable(v) or v end
  local old = { name = C_Spell.GetSpellName, known = C_SpellBook.IsSpellKnown, isUnit = UnitIsUnit, role = UnitGroupRolesAssigned,
    dead = DEAD, usable = C_Spell.IsSpellUsable, zclass = Z.class, instance = INSTANCE, itype = INSTANCE_TYPE, raid = RAID, now = NOW,
    target = CopyTable(Z.char.buffTarget or {}) }
  local hidden = {}
  local ok, err = pcall(function()
    local extra = { [1126] = "Marque du fauve", [21849] = "Don du fauve", [467] = "Épines", [408514] = "Bouclier de terre",
      [408510] = "Bouclier d'eau", [1328548] = "Serment de lumière" }
    C_Spell.GetSpellName = function(id) return extra[id] or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return extra[id] ~= nil or old.known(id) end
    local me = Z.buttons[1]
    local others = {}
    for _, b in ipairs(Z.buttons) do
      if b ~= me and b.unit and not b.extra and b:IsVisible() and not b.unit:find("pet") then others[#others + 1] = b end
    end
    assert(#others >= 2, "faux groupe trop petit")
    local other, third = others[1], others[2]
    UnitIsUnit = function(a, b) return a == b or (b == "player" and a == me.unit) end
    UnitGroupRolesAssigned = function() return "HEALER" end
    local function Update() Z:Refresh() RunUpdates() end
    local function Ids(b)
      local t = {} for _, m in ipairs(b.missingBuffs or {}) do t[#t + 1] = m.check.id end
      return table.concat(t, ",")
    end
    INSTANCE, INSTANCE_TYPE, RAID = true, "party", false
    Z.db.buffWatch, Z.db.buffRenew, Z.db.buffGroupAt = {}, 0, 3
    Z.db.missingBuffs, Z.db.buffPanel = true, true
    AURAS = {}

    -- 1. Version simple et version de groupe cochees a part (pretre, Robustesse et Priere de robustesse)
    Z.class = "PRIEST" Z:BuildData()
    local function Rows(id)
      local simple, group = {}, {}
      for _, row in ipairs(Z.BuffRows()) do
        if row.check.id == id then
          if row.count then group[#group + 1] = row else simple[#simple + 1] = row end
        end
      end
      return simple, group
    end
    -- les deux cochees : selon le seuil
    Z.db.buffGroupAt = 5 Update()
    local simple, group = Rows(1243)
    assert(#simple > 0 and #group == 0 and simple[1].spell2 == "Prière de robustesse", "les deux cochees, sous le seuil")
    Z.db.buffGroupAt = 2 Update()
    simple, group = Rows(1243)
    assert(#group > 0 and group[1].spell == "Prière de robustesse", "les deux cochees, au seuil")
    -- seulement la version de groupe : des lignes « Groupe N » seulement, des le premier joueur, jamais de familier
    Z.db.buffGroupAt = 5
    Z.db.buffWatch[1243] = { pve = false } Update()
    simple, group = Rows(1243)
    assert(#simple == 0, "groupe seulement : ligne d'un joueur")
    assert(#group > 0 and group[1].spell == "Prière de robustesse", "groupe seulement : aucune ligne Groupe N")
    assert(Ids(other):find("1243", 1, true), "groupe seulement : buff plus surveille sur la case")
    for _, b in ipairs(Z.buttons) do
      if b.unit and b.unit:find("pet") then assert(not Ids(b):find("1243", 1, true), "groupe seulement : familier propose") end
    end
    -- un seul joueur du groupe sans le buff suffit (seuil ignore)
    AURAS["HELPFUL"] = { { name = "Mot de pouvoir : Robustesse", icon = 9, auraInstanceID = 31 } }
    Update()
    for _, b in ipairs(others) do b.missingBuffs = nil b.missingBuff = nil end
    other.missingBuffs = { { check = Z.buffChecks[1], spell = "Mot de pouvoir : Robustesse", icon = 9 } }
    other.missingBuff = other.missingBuffs[1]
    simple, group = Rows(1243)
    assert(#group == 1 and group[1].count == 1 and #simple == 0, "groupe seulement : un joueur sans le buff ne suffit pas")
    AURAS = {}
    -- seulement la version simple : une ligne par joueur, jamais de Priere (ni ligne, ni clic droit)
    Z.db.buffWatch = { [21562] = { pve = false } } Z.db.buffGroupAt = 2 Update()
    simple, group = Rows(1243)
    assert(#group == 0 and #simple > 0, "simple seulement : ligne Groupe N")
    for _, row in ipairs(simple) do assert(not row.spell2, "simple seulement : Priere au clic droit") end
    -- sans composant (le jeu dit la Priere inutilisable) : un par un, meme si seule la Priere est cochee
    C_Spell.IsSpellUsable = function(name) return name ~= "Prière de robustesse" end
    Z.db.buffWatch = {} Update()
    simple, group = Rows(1243)
    assert(#group == 0 and #simple > 0 and not simple[1].spell2, "sans composant : Priere proposee")
    Z.db.buffWatch = { [1243] = { pve = false } } Update()
    simple, group = Rows(1243)
    assert(#group == 0 and #simple > 0, "sans composant, Priere seule cochee : rien a lancer")
    C_Spell.IsSpellUsable = function() return MakeSecret() end Update()
    simple, group = Rows(1243)
    assert(#group > 0, "reponse secrete : Priere ecartee")
    C_Spell.IsSpellUsable = old.usable
    -- aucune : buff non surveille
    Z.db.buffWatch = { [1243] = { pve = false }, [21562] = { pve = false } } Update()
    simple, group = Rows(1243)
    assert(#simple == 0 and #group == 0 and not Ids(other):find("1243", 1, true), "aucune cochee : buff encore propose")
    -- chaque lieu garde son choix : groupe seulement en JcJ, les deux en JcE
    -- (un seul joueur sans le buff : la version simple quand les deux sont cochees)
    local function OnlyOther()
      AURAS["HELPFUL"] = { { name = "Mot de pouvoir : Robustesse", icon = 9, auraInstanceID = 31 } }
      Update()
      other.missingBuffs = { { check = Z.buffChecks[1], spell = "Mot de pouvoir : Robustesse", icon = 9 } }
      other.missingBuff = other.missingBuffs[1]
      AURAS = {}
    end
    Z.db.buffWatch = { [1243] = { pvp = false } }
    INSTANCE_TYPE = "pvp" OnlyOther()
    simple, group = Rows(1243)
    assert(#simple == 0 and #group == 1, "JcJ : groupe seulement")
    INSTANCE_TYPE = "party" OnlyOther()
    simple, group = Rows(1243)
    assert(#simple == 1 and #group == 0 and simple[1].spell2 == "Prière de robustesse", "JcE : les deux versions perdues")
    Z.db.buffWatch, Z.db.buffGroupAt = {}, 3

    -- 2. « Mes buffs » aligne : icones dans une meme colonne, version de groupe reconnue a sa mention
    Z:ToggleOptions("Joueurs")
    local box = Z.buffWatchBox
    box:Update()
    local x, groupRows, fearRow = nil, 0, nil
    for _, row in ipairs(box.lines) do
      if row:IsShown() then
        local point = row.icon._points and row.icon._points.TOPLEFT
        assert(point, "icone sans place")
        x = x or point[2]
        assert(point[2] == x, "icone decalee : " .. tostring(point[2]) .. " au lieu de " .. tostring(x))
        if row.entry.group then
          groupRows = groupRows + 1
          assert(row.entry.name:find("(" .. Z.L["groupe"] .. ")", 1, true), "version de groupe sans sa mention")
        end
        if row.entry.unique then fearRow = row end
      end
    end
    assert(groupRows >= 1, "lignes de groupe du pretre : " .. groupRows) -- seule la Priere de robustesse a un nom ici
    -- la ligne « Sur : » commence au bord des noms (apres l'icone de 18 et son ecart de 8)
    assert(fearRow and fearRow.on._points.TOPLEFT[2] == x + 18 + 8, "ligne Sur : decalee")
    Z:ToggleOptions()
    assert(Z.translations.enUS["La version simple et la version de groupe se cochent séparément."], "sans traduction : aide de Mes buffs")
    assert(Z.translations.enUS["Au départ : 75 secondes avant la fin. 0 : seulement quand le buff manque."], "sans traduction : seuil")

    -- 3. Buffs proposes 2 minutes avant leur fin : nouveau depart, migration unique des joueurs restes sur 0
    assert(Z.defaults.buffRenew == 75, "depart du seuil : " .. tostring(Z.defaults.buffRenew))
    Z.db.buffRenew = 120 NOW = 1000
    AURAS["HELPFUL"] = { { name = "Mot de pouvoir : Robustesse", icon = 9, auraInstanceID = 31, expirationTime = NOW + 100 } }
    Update() assert(Ids(other):find("1243", 1, true), "buff a 100 s de sa fin non propose")
    AURAS["HELPFUL"][1].expirationTime = NOW + 300
    Update() assert(not Ids(other):find("1243", 1, true), "buff a 5 minutes de sa fin propose")
    -- jamais avant le dernier quart d'un buff court : 5 minutes, propose sous 75 s seulement (fait mieux qu'un seuil fixe)
    AURAS["HELPFUL"][1].expirationTime, AURAS["HELPFUL"][1].duration = NOW + 100, 300
    Update() assert(not Ids(other):find("1243", 1, true), "buff de 5 minutes propose a 100 s de sa fin")
    AURAS["HELPFUL"][1].expirationTime = NOW + 70
    Update() assert(Ids(other):find("1243", 1, true), "buff de 5 minutes non propose a 70 s de sa fin")
    AURAS["HELPFUL"][1].expirationTime, AURAS["HELPFUL"][1].duration = NOW + 100, MakeSecret()
    Update() assert(Ids(other):find("1243", 1, true), "duree secrete : seuil entier perdu")
    AURAS["HELPFUL"][1].duration = nil
    AURAS["HELPFUL"][1].expirationTime = 0
    Update() assert(not Ids(other):find("1243", 1, true), "buff sans fin propose")
    AURAS = {} Z.db.buffRenew = 0
    local savedDB, savedChar, version = LyoruneDB, LyoruneCharDB, Z.version
    local fine, why = pcall(function()
      -- 1.46.3 (C20) : seuil en secondes ; ancien depart (2 min ou 0 avant la 1.33.7) : 75 s ; autre choix converti
      local db = { lastVersion = "1.33.6", buffRefresh = 0 }
      LyoruneDB = db
      Z.version = "1.46.3" FireEvent("ADDON_LOADED", "Lyorune")
      assert(db.buffRefresh == nil and db.buffRenew == 75, "reste sur 0 avant la 1.33.7 : " .. tostring(db.buffRenew))
      db = { lastVersion = "1.46.2", buffRefresh = 2 } LyoruneDB = db FireEvent("ADDON_LOADED", "Lyorune")
      assert(db.buffRefresh == nil and db.buffRenew == 75, "ancien depart : " .. tostring(db.buffRenew))
      db = { lastVersion = "1.46.2", buffRefresh = 5 } LyoruneDB = db FireEvent("ADDON_LOADED", "Lyorune")
      assert(db.buffRenew == 300, "autre choix non converti : " .. tostring(db.buffRenew))
      db = { lastVersion = "1.46.2", buffRefresh = 0 } LyoruneDB = db FireEvent("ADDON_LOADED", "Lyorune")
      assert(db.buffRenew == 0, "0 choisi ecrase : " .. tostring(db.buffRenew))
      db.buffRenew = 45 FireEvent("ADDON_LOADED", "Lyorune")
      assert(db.buffRenew == 45, "migration refaite")
      db = {} LyoruneDB = db FireEvent("ADDON_LOADED", "Lyorune")
      assert(db.buffRenew == 75, "nouveau joueur : " .. tostring(db.buffRenew))
    end)
    Z.version = version
    LyoruneDB, LyoruneCharDB = savedDB, savedChar
    FireEvent("ADDON_LOADED", "Lyorune")
    assert(fine, why)
    Z.db.buffWatch, Z.db.buffRenew, Z.db.buffGroupAt, Z.db.missingBuffs, Z.db.buffPanel = {}, 0, 3, true, true

    -- 4. Buffs a une personne (bug signale : druide seul, Marque du fauve active, Epines jamais proposee) : chaque
    -- classe, chaque situation
    local function Unique(spell)
      for _, row in ipairs(Z.BuffRows()) do if row.spell == spell then return row end end
    end
    local function Solo(on)
      for _, b in ipairs(Z.buttons) do
        if b ~= me and b.unit and not b.extra then
          if on then
            hidden[b] = hidden[b] or b.IsVisible
            b.IsVisible = function() return false end
          elseif hidden[b] then
            b.IsVisible = hidden[b] hidden[b] = nil
          end
        end
      end
    end
    for _, case in ipairs({ { "DRUID", "Épines", "Marque du fauve" }, { "SHAMAN", "Bouclier de terre", "Bouclier d'eau" },
      { "PRIEST", "Gardien de peur", "Mot de pouvoir : Robustesse" }, { "PALADIN", "Serment de lumière" } }) do
      local class, spell, mine = case[1], case[2], case[3]
      Z.class = class Z:BuildData() Z.char.buffTarget = {}
      assert(#Z.uniqueChecks == 1 and Z.uniqueChecks[1].name == spell, class .. " : buff a une personne absent")
      UnitGroupRolesAssigned = function() return "HEALER" end
      -- seul, mes autres buffs poses (Marque du fauve active) : sur moi
      Solo(true)
      if mine then AURAS["HELPFUL"] = { { name = mine, icon = 9, auraInstanceID = 71 } } end
      Update()
      local row = Unique(spell)
      assert(row and row.unit == me.unit and row.why == Z.L["vous"], class .. " seul : " .. spell .. " non propose")
      Solo(false) AURAS = {}
      -- groupe sans tank : sur moi ; donjon, raid, champ de bataille, monde : pareil
      for _, place in ipairs({ { "party", false }, { "raid", true }, { "pvp", false }, { "none", false } }) do
        INSTANCE_TYPE, RAID = place[1], place[2] Update()
        row = Unique(spell)
        assert(row and row.unit == me.unit, class .. " sans tank (" .. place[1] .. ") : non propose sur moi")
      end
      INSTANCE_TYPE, RAID = "party", false
      -- un tank : sur lui ; mort : sur moi
      UnitGroupRolesAssigned = function(u) return u == other.unit and "TANK" or "HEALER" end
      Update() row = Unique(spell)
      assert(row and row.unit == other.unit and row.why == Z.L["tank"], class .. " : tank oublie")
      DEAD = { [other.unit] = true }
      FireEvent("UNIT_FLAGS", other.unit) RunUpdates() row = Unique(spell)
      assert(row and row.unit == me.unit, class .. " : propose a un tank mort")
      DEAD = false FireEvent("UNIT_FLAGS", other.unit) RunUpdates()
      -- joueur choisi ; absent : le tank
      GROUP_NAMES[third.unit] = "Thrall"
      Z.SetBuffBearer(Z.uniqueChecks[1].id, "NAME", "Thrall") Update()
      assert(Unique(spell).unit == third.unit, class .. " : joueur choisi")
      Z.SetBuffBearer(Z.uniqueChecks[1].id, "NAME", "Absent") Update()
      assert(Unique(spell).unit == other.unit, class .. " : joueur choisi absent, pas le tank")
      GROUP_NAMES[third.unit] = nil Z.char.buffTarget = {}
      -- mon buff sur un joueur : rien ; il disparait : relu tout seul (aura, zone ou connexion)
      AURAS["HELPFUL|PLAYER"] = { { name = spell, icon = 9, auraInstanceID = 72 } }
      Update() assert(not Unique(spell), class .. " : propose alors qu'il est pose")
      AURAS = {}
      FireEvent("UNIT_AURA", other.unit, { isFullUpdate = true }) RunUpdates()
      assert(Unique(spell), class .. " : buff fini, panneau non relu")
      AURAS["HELPFUL|PLAYER"] = { { name = spell, icon = 9, auraInstanceID = 72 } } Update() AURAS = {}
      FireEvent("PLAYER_ENTERING_WORLD") RunUpdates()
      assert(Unique(spell), class .. " : changement de zone, panneau non relu")
      -- moi mort et sans tank : rien a lancer ; relevé : proposé de nouveau
      UnitGroupRolesAssigned = function() return "HEALER" end
      DEAD = { [me.unit] = true }
      FireEvent("UNIT_FLAGS", me.unit) RunUpdates() assert(not Unique(spell), class .. " : propose sur moi mort")
      DEAD = false FireEvent("UNIT_FLAGS", me.unit) RunUpdates()
      assert(Unique(spell), class .. " : apres la mort, panneau non relu")
    end
    -- 5. Seul avec « Mon cadre quand je suis seul » decoche : aucune case, ma fiche prend le relais ;
    -- en groupe, rien de plus
    Z.class = "DRUID" Z:BuildData() Z.char.buffTarget = {}
    local grouped = GROUPED
    GROUPED = false
    for _, b in ipairs(Z.buttons) do
      hidden[b] = hidden[b] or b.IsVisible
      b.IsVisible = function() return false end
    end
    assert(Z.SelfHidden(), "seul sans case : non reconnu")
    AURAS["HELPFUL"] = { { name = "Marque du fauve", icon = 9, auraInstanceID = 81 } }
    FireEvent("UNIT_AURA", "player", { isFullUpdate = true }) RunUpdates()
    local row = Unique("Épines")
    assert(row and row.unit == "player", "seul sans case : Epines non proposee")
    local marque = false
    for _, r in ipairs(Z.BuffRows()) do if r.spell == "Marque du fauve" then marque = true end end
    assert(not marque, "seul sans case : Marque du fauve presente proposee")
    AURAS["HELPFUL|PLAYER"] = { { name = "Épines", icon = 9, auraInstanceID = 82 } }
    FireEvent("UNIT_AURA", "player", { isFullUpdate = true }) RunUpdates()
    assert(not Unique("Épines"), "seul sans case : Epines posee encore proposee")
    AURAS = {}
    FireEvent("UNIT_AURA", "player", { isFullUpdate = true }) RunUpdates()
    for _, r in ipairs(Z.BuffRows()) do if r.spell == "Marque du fauve" then marque = true end end
    assert(marque and Unique("Épines"), "seul sans case : buffs finis non relus")
    DEAD = true FireEvent("PLAYER_DEAD") RunUpdates()
    assert(not Unique("Épines"), "seul sans case : propose sur moi mort")
    DEAD = false FireEvent("PLAYER_ALIVE") RunUpdates()
    assert(Unique("Épines"), "seul sans case : relevé, non propose")
    -- ma case revient (option recochee, ou groupe) : la fiche se vide, aucune ligne en double
    GROUPED = true FireEvent("UNIT_AURA", "player", { isFullUpdate = true }) RunUpdates()
    assert(not Z.hiddenSelf.missingKey and not Z.hiddenSelf.myUniques, "en groupe : fiche encore pleine")
    for _, r in ipairs(Z.BuffRows()) do assert(r.unit ~= "player", "en groupe : ligne de ma fiche") end
    GROUPED = grouped
  end)
  for b, f in pairs(hidden) do b.IsVisible = f end
  C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, UnitIsUnit, UnitGroupRolesAssigned = old.name, old.known, old.isUnit, old.role
  DEAD, INSTANCE, INSTANCE_TYPE, RAID, NOW = old.dead, old.instance, old.itype, old.raid, old.now
  Z.char.buffTarget, C_Spell.IsSpellUsable = old.target, old.usable
  for k, v in pairs(saved) do Z.db[k] = v end
  Z.class = old.zclass Z:BuildData() AURAS = {} Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("1.34.0 / 1.37.1 / 1.40.1 : buffs manquants colles sous les cadres, en bandeau fin de la largeur d'une case", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = type(v) == "table" and CopyTable(v) or v end
  local oldRange, realRows, realName, realNow = UnitInRange, Z.BuffRows, C_Spell.GetSpellName, NOW
  local patched = {}
  local ok, err = pcall(function()
    assert(Z.defaults.buffPlace == "FRAMES", "depart : avec les cadres")
    Z.db.buffPanel, Z.db.buffPlace = true, "FRAMES"
    AURAS = {} Z:Refresh() RunUpdates() Z:UpdateBuffPanel()
    local block, panel = Z:BuffBlock(), Z:BuffPanel()
    local list = Z.BuffRows()
    assert(#list >= 1, "aucun buff manquant pour l'essai")
    assert(block and block:IsShown(), "bloc absent alors que des buffs manquent")
    assert(not (panel and panel:IsShown()), "fenetre ouverte en plus du bloc")
    -- une seule case (1.34.1) = ce que lance la touche ; « + N » dans son coin
    local tile = LyoruneBuffsTile1
    assert(tile:GetAttribute("type1") == "spell" and tile:GetAttribute("spell1") == list[1].spell
      and tile:GetAttribute("unit") == list[1].unit, "premiere case mal reglee")
    assert(LyoruneNextBuff:GetAttribute("spell") == tile:GetAttribute("spell1"), "la touche ne lance pas la premiere case")
    -- C27 : le temps du clic que le jeu garde (useOnKeyDown) suit « Lancer le sort des l'appui »
    assert(tile:GetAttribute("useOnKeyDown") == (Z.db.castOnDown and true or false), "bandeau : useOnKeyDown absent (C27)")
    local function Shown()
      local n = 0
      for i = 1, 8 do local t = rawget(_G, "LyoruneBuffsTile" .. i) if t and t:IsShown() then n = n + 1 end end
      return n
    end
    assert(Shown() == 1, "une seule case attendue : " .. Shown())
    assert(block:GetHeight() == tile:GetHeight(), "bloc plus haut que sa case : rien ne doit apparaitre dessous")

    tile:Run("OnEnter") tile:Run("OnLeave")
    -- 1.37.1 : bandeau fin, meme disposition pour les quatre formes (choix de l'auteur)
    local L = Z.L
    for _, id in ipairs({ "BAR", "TILE", "SQUARE", "BANNER" }) do
      assert(Z.shapes[id].buffs == nil, id .. " : allure des buffs par forme devenue inutile")
      Z:ApplyShape(id) RunUpdates() Z:UpdateBuffPanel()
      local w = Z.CellSize()
      local size = Z.db.fontSize + (Z:Theme().fontBonus or 0)
      local h = tile:GetHeight()
      assert(tile:GetWidth() == w, id .. " : largeur exacte d'une case (C13) : " .. tile:GetWidth() .. " au lieu de " .. w)
      assert(h >= 2 * size + 4 and h <= 2 * size + 10, id .. " : hauteur tiree du texte : " .. h)
      assert(block:GetWidth() == tile:GetWidth() and block:GetHeight() == h, id .. " : bloc a la taille du bandeau")
      assert(tile.icon:GetWidth() == tile.icon:GetHeight() and tile.icon:GetHeight() >= h - 6, id .. " : icone de toute la hauteur")
      if id == "SQUARE" then -- 1.40.1 (C13) : trop etroit pour le texte, icone seule centree et « +N » dans son coin
        assert(tile.icon._points.CENTER and not tile.line:IsShown() and not tile.label:IsShown(), id .. " : icone seule attendue")
        assert(#list == 1 or tile.sub:GetText() == "+" .. (#list - 1), id .. " : +N dans le coin de l'icone : " .. tile.sub:GetText())
      else
        assert(tile.line:IsShown() and tile.line._points and tile.line._points.TOPLEFT, id .. " : trait entre l'icone et le texte")
        assert(tile.label:IsShown() and tile.sub:IsShown(), id .. " : deux lignes")
        assert(not tile.label:GetText():find("|c", 1, true), id .. " : ligne 1, le joueur seul")
      end
      local second = rawget(_G, "LyoruneBuffsTile2")
      assert(not (second and second:IsShown()), id .. " : une case suivante montree")
    end
    Z:UndoShape() Z:ApplyShape("BAR") RunUpdates() -- la suite lit le texte : une forme assez large
    -- 1.40.1 (C13) : la largeur suit la case quand le joueur la change, et reste juste si les echelles different
    local width = Z.db.width
    Z.db.width = width + 23 Z:Refresh() RunUpdates() Z:UpdateBuffPanel()
    assert(tile:GetWidth() == Z.CellSize(), "largeur changee non suivie : " .. tile:GetWidth())
    local cell
    for _, b in ipairs(Z.buttons) do if b.unit and not b.extra and b:IsVisible() and b:GetWidth() then cell = b break end end
    assert(cell, "aucune case visible pour mesurer")
    local realEff = cell.GetEffectiveScale
    cell.GetEffectiveScale = function() return 1.5 end
    Z:UpdateBuffPanel()
    cell.GetEffectiveScale = realEff
    assert(tile:GetWidth() == math.floor(cell:GetWidth() * 1.5 + 0.5), "echelle des cases non suivie : " .. tile:GetWidth())
    Z.db.width = width Z:Refresh() RunUpdates() Z:UpdateBuffPanel()
    assert(tile:GetWidth() == Z.CellSize(), "largeur d'origine non retrouvee")
    -- ligne 1 : « Vous » sur ma case, « Groupe N » pour un groupe ; ligne 2 : « +N autres » ou le nom court du sort
    local fakeCheck = list[1].check
    local realIsUnit = UnitIsUnit
    UnitIsUnit = function(a, b) return a == b end
    Z.BuffRows = function() return { { check = fakeCheck, spell = "Mot de pouvoir : Robustesse", unit = "player", name = "Moi", class = "PRIEST" } } end
    Z:UpdateBuffPanel()
    UnitIsUnit = realIsUnit
    assert(tile.label:GetText() == L["Vous"], "ma case : Vous attendu : " .. tostring(tile.label:GetText()))
    assert(tile.sub:GetText() == "Robustesse", "un seul buff : nom court du sort : " .. tostring(tile.sub:GetText()))
    Z.BuffRows = function() return { { check = fakeCheck, spell = "Mot de pouvoir : Robustesse", unit = "raid9", count = 4, group = 3, class = "PRIEST" },
      { check = fakeCheck, spell = "x", unit = "player", name = "Moi" } } end
    Z:UpdateBuffPanel()
    assert(tile.label:GetText() == L["Groupe %d"]:format(3), "groupe : Groupe 3 attendu")
    assert(tile.sub:GetText() == L["+1 autre"], "deux buffs : +1 autre attendu : " .. tostring(tile.sub:GetText()))
    Z.BuffRows = function() return { { check = fakeCheck, spell = "a", unit = "player", name = "Moi" }, { check = fakeCheck, spell = "b", unit = "player" },
      { check = fakeCheck, spell = "c", unit = "player" } } end
    Z:UpdateBuffPanel()
    assert(tile.sub:GetText() == L["+%d autres"]:format(2), "trois buffs : +2 autres attendu")
    Z.BuffRows = realRows
    Z:UpdateBuffPanel()
    -- theme, texture et angles des cases
    Z.db.corners = "ROUND" Z:UpdateBuffPanel()
    assert(tile.bgRound:IsShown() and not tile.bg:IsShown(), "angles arrondis non suivis")
    Z.db.corners = "SHARP" Z:UpdateBuffPanel()
    assert(tile.bg:IsShown() and not tile.bgRound:IsShown(), "angles droits non suivis")
    assert(tile.fill._tex == Z.UI.BarTexture(), "texture des barres non suivie")
    Z.db.scale = 120 Z:UpdateBuffPanel()
    assert(block:GetScale() == 1.2, "echelle des cadres non suivie")
    Z.db.scale = saved.scale
    -- place : sous la case la plus basse, au-dessus si la place manque, au point de depart sans case visible
    Z:UpdateBuffPanel()
    assert(block.where == "ANCHOR" and block._points.TOPLEFT[2] == Z.anchor, "sans mesure : sous le point de depart")
    local low, left = 400, 1000
    for i, b in ipairs(Z.buttons) do
      local header = b:GetParent()
      if b.unit and not b.extra and b:IsVisible() and header and header.def and header.def.pos == "pos" then
        local bottom = 500 - i * 40
        low, left = math.min(low, bottom), math.min(left, 100 + i)
        patched[b] = true
        b.GetLeft, b.GetBottom, b.GetTop = function() return 100 + i end, function() return bottom end, function() return bottom + 36 end
      end
    end
    assert(next(patched), "aucune case des cadres du groupe")
    Z:UpdateBuffPanel()
    local point = block._points.TOPLEFT
    assert(block.where == "BELOW" and point and point[2] == UIParent and point[4] == left, "bloc pas sous la premiere colonne")
    assert(point[5] == low - Z.db.spacing, "bloc pas colle sous la case la plus basse : " .. tostring(point[5]))
    for b in pairs(patched) do b.GetBottom = function() return 5 end end
    Z:UpdateBuffPanel()
    assert(block.where == "ABOVE" and block._points.BOTTOMLEFT, "pas de place en bas : au-dessus des cadres")
    -- par ses cases : accroche au point de depart des cadres, il les suit pendant un deplacement
    for b in pairs(patched) do b.GetBottom = function() return 300 end end
    Z.anchor.GetLeft, Z.anchor.GetTop = function() return 90 end, function() return 480 end
    Z:UpdateBuffPanel()
    point = block._points.TOPLEFT
    assert(point[2] == Z.anchor and point[3] == "TOPLEFT" and point[4] == left - 90 and point[5] == 300 - Z.db.spacing - 480,
      "pas accroche au point de depart des cadres")
    Z.anchor.GetLeft, Z.anchor.GetTop = nil, nil
    for b in pairs(patched) do b.GetLeft, b.GetBottom, b.GetTop = nil, nil, nil end
    patched = {}
    -- les cadres changent de taille : le bloc se replace, sans boucle
    for _, h in ipairs(Z.headers) do if h.def.pos == "pos" then h:Run("OnSizeChanged") h:Run("OnShow") end end
    RunUpdates()
    -- un joueur hors de portee passe en fin de liste
    local first = list[1]
    if #list > 1 and not first.count and first.unit ~= "player" then
      UnitInRange = function(unit) if unit == first.unit then return false, true end return true, true end
      local again = Z.BuffRows()
      assert(again[#again].unit == first.unit and again[1].unit ~= first.unit, "hors de portee pas en fin de liste")
      UnitInRange = oldRange
    end
    -- portee du sort (UnitInRange secret sur Forever, meme hors combat) : en fin de liste
    if #list > 1 and not first.count and first.unit ~= "player" then
      C_Spell.IsSpellInRange = function(spell, unit) return unit ~= first.unit end
      local again = Z.BuffRows()
      assert(again[#again].unit == first.unit, "hors de portee du sort pas en fin de liste")
      C_Spell.IsSpellInRange = nil
      UnitIsVisible = function(unit) return unit ~= first.unit end
      again = Z.BuffRows()
      assert(again[#again].unit == first.unit, "hors de vue pas en fin de liste")
      UnitIsVisible = nil
      -- un joueur deja en combat : ses buffs sont caches, il n'est pas propose
      UnitAffectingCombat = function(unit) return unit == first.unit end
      for _, r in ipairs(Z.BuffRows()) do assert(r.unit ~= first.unit or r.count, "joueur en combat propose") end
      UnitAffectingCombat = nil
    end
    -- combat : cache avant le verrouillage ; revient apres
    FireEvent("PLAYER_REGEN_DISABLED")
    assert(not block:IsShown(), "bloc visible en combat")
    COMBAT = true Z:UpdateBuffPanel() assert(not block:IsShown()) COMBAT = false
    FireEvent("PLAYER_REGEN_ENABLED") RunUpdates() Z:UpdateBuffPanel()
    assert(block:IsShown(), "bloc pas revenu apres le combat")
    -- ou vous voulez : la fenetre, plus le bloc
    Z.db.buffPlace = "FREE" Z:UpdateBuffPanel()
    assert(not block:IsShown() and Z:BuffPanel():IsShown(), "ou vous voulez : la fenetre")
    Z.db.buffPlace = "FRAMES" Z:UpdateBuffPanel()
    assert(block:IsShown() and not Z:BuffPanel():IsShown(), "retour avec les cadres")
    -- buff que je viens de lancer : plus propose quelques secondes, le temps que l'aura arrive
    local oldName, now = C_Spell.GetSpellName, NOW
    local e = Z.BuffRows()[1]
    local function Proposed()
      for _, r in ipairs(Z.BuffRows()) do if r.unit == e.unit and r.spell == e.spell then return true end end
    end
    C_Spell.GetSpellName = function(id) if id == 999999 then return e.spell end return oldName(id) end
    tile:Run("PreClick", "LeftButton")
    assert(Proposed(), "clic seul (sort pas encore parti) : deja ecarte")
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 1)
    assert(Proposed(), "un autre sort reussi : ecarte a tort")
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 999999)
    assert(not Proposed(), "sort reussi : encore propose avant que l'aura arrive")
    NOW = now + 5
    assert(Proposed(), "aura jamais venue : pas propose de nouveau")
    -- la touche aussi ; un clic trop ancien n'ecarte rien
    Z:UpdateBuffPanel()
    LyoruneNextBuff:Run("PreClick", "LeftButton")
    NOW = NOW + 10
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 999999)
    assert(Proposed(), "clic trop ancien : ecarte a tort")
    C_Spell.GetSpellName, NOW = oldName, now
    -- exemple : rien a poser, options ouvertes sur le chapitre Joueurs
    local oldRows = Z.BuffRows
    Z.BuffRows = function() return {} end
    Z:UpdateBuffPanel()
    assert(not block:IsShown(), "rien a poser : bloc visible")
    Z:ToggleOptions("Joueurs") Z:UpdateBuffPanel()
    assert(block:IsShown() and tile.sample and tile:GetAttribute("type1") == nil and tile:GetAttribute("unit") == nil,
      "exemple absent, ou il lance un sort")
    assert(LyoruneNextBuff:GetAttribute("spell") == nil, "la touche lancerait l'exemple")
    tile:Run("OnEnter") tile:Run("OnLeave")
    tile:Run("PreClick", "LeftButton")
    Z:ToggleOptions("Clics") Z:UpdateBuffPanel()
    assert(not block:IsShown(), "exemple hors du chapitre Joueurs")
    Z:ToggleOptions("Joueurs") Z:OptionsWindow():Hide() Z:UpdateBuffPanel()
    assert(not block:IsShown(), "exemple encore la, options fermees")
    Z.BuffRows = oldRows
    for _, key in ipairs({ "Exemple", "Hors combat, vos buffs manquants s'afficheront ici, un à la fois : un clic le pose, puis le suivant prend sa place." }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
    -- tout pose, ou interrupteur coupe : rien
    Z.db.buffPanel = false Z:UpdateBuffPanel()
    assert(not block:IsShown() and LyoruneNextBuff:GetAttribute("spell") == nil, "interrupteur coupe : bloc visible")
    -- options : un seul reglage, dans la recherche, traduit
    local labels = table.concat(Z:OptionLabels(), "|")
    assert(labels:find("Emplacement des buffs manquants", 1, true), "reglage absent des options")
    for _, key in ipairs({ "Avec les cadres", "Où vous voulez", "+1 autre", "+%d autres", "Vous", "Emplacement des buffs manquants" }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
  end)
  for b in pairs(patched) do b.GetLeft, b.GetBottom, b.GetTop = nil, nil, nil end
  UnitInRange, C_Spell.IsSpellInRange, UnitAffectingCombat, UnitIsVisible = oldRange, nil, nil, nil
  Z.anchor.GetLeft, Z.anchor.GetTop = nil, nil
  COMBAT = false
  Z.BuffRows, C_Spell.GetSpellName, NOW = realRows, realName, realNow
  for k, v in pairs(saved) do Z.db[k] = v end
  AURAS = {} Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("1.34.1 : tous mes soins et buffs dans Sorts et raccourcis, /lyorune sorts, revue des quatre classes", function()
  local realName, realHelpful, realPassive, class = C_Spell.GetSpellName, C_Spell.IsSpellHelpful, C_Spell.IsSpellPassive, Z.class
  local info, lines = C_SpellBook.GetSpellBookItemInfo, C_SpellBook.GetSpellBookSkillLineInfo
  -- sorts de l'essai : numero -> { nom, utilisable sur un allie d'apres le jeu }
  local fake = {
    [2061] = { "Soins rapides", true }, [588] = { "Feu intérieur" }, [15237] = { "Nova sacrée" },
    [585] = { "Châtiment" }, [13908] = { "Prière du désespoir" }, [1243] = { "Mot de pouvoir : Robustesse", true },
    [19750] = { "Eclair lumineux", true }, [25780] = { "Fureur vertueuse" }, [465] = { "Aura de dévotion" }, [20271] = { "Jugement" },
    [331] = { "Vague de soins", true }, [324] = { "Bouclier de foudre" }, [8017] = { "Arme Croque-roc" },
    [5394] = { "Totem guérisseur" }, [403] = { "Éclair" },
    [5185] = { "Toucher guérisseur", true }, [740] = { "Tranquillité" }, [16864] = { "Augure de clarté" }, [5176] = { "Colère" },
  }
  local ok, err = pcall(function()
    C_Spell.GetSpellName = function(id) return fake[id] and fake[id][1] or realName(id) end
    C_Spell.IsSpellHelpful = function(id) return fake[id] ~= nil and fake[id][2] == true end
    C_Spell.IsSpellPassive = nil
    -- grimoire : { numero, passif, autre specialisation }
    local function Book(items)
      C_SpellBook.GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #items } end
      C_SpellBook.GetSpellBookItemInfo = function(slot)
        local item = items[slot]
        return { itemType = 1, spellID = item[1], isPassive = item[2] == true, isOffSpec = item[3] == true }
      end
    end
    local function Names()
      local set = {}
      for _, spell in ipairs(Z:KnownSpells()) do set[spell.name] = true end
      return set
    end
    local cases = {
      PRIEST  = { book = { { 2061 }, { 588 }, { 15237 }, { 585 }, { 13908, false, true } },
                  yes = { "Soins rapides", "Feu intérieur", "Nova sacrée" }, no = { "Châtiment", "Prière du désespoir" },
                  why = { "Prière du désespoir (autre spécialisation)", "Mot de pouvoir : Robustesse (pas appris)" }, out = "Châtiment" },
      PALADIN = { book = { { 19750 }, { 25780 }, { 465 }, { 20271 } },
                  yes = { "Eclair lumineux", "Fureur vertueuse", "Aura de dévotion" }, no = { "Jugement" }, out = "Jugement" },
      SHAMAN  = { book = { { 331 }, { 324 }, { 8017 }, { 5394 }, { 403 } },
                  yes = { "Vague de soins", "Bouclier de foudre", "Arme Croque-roc", "Totem guérisseur" }, no = { "Éclair" }, out = "Éclair" },
      DRUID   = { book = { { 5185 }, { 740 }, { 16864, true }, { 5176 } },
                  yes = { "Toucher guérisseur", "Tranquillité" }, no = { "Augure de clarté", "Colère" },
                  why = { "Augure de clarté (passif)" }, out = "Colère" },
    }
    for name, case in pairs(cases) do
      Z.class = name
      Book(case.book)
      local set = Names()
      for _, spell in ipairs(case.yes) do assert(set[spell], name .. " : absent de la liste : " .. spell) end
      for _, spell in ipairs(case.no) do assert(not set[spell], name .. " : propose a tort : " .. spell) end
      local proposed, missing, filtered = Z:SpellReport()
      assert(#proposed == #case.yes, name .. " : " .. table.concat(proposed, ", "))
      local text = table.concat(missing, "|")
      for _, line in ipairs(case.why or {}) do assert(text:find(line, 1, true), name .. " : raison absente : " .. line .. " dans " .. text) end
      assert(table.concat(filtered, "|") == case.out, name .. " : ecartes : " .. table.concat(filtered, ", "))
    end
    -- la commande ecrit les trois lignes, en francais et en anglais
    Z.class = "PRIEST" Book(cases.PRIEST.book)
    local printed = #PRINTED
    Z.Command("sorts")
    assert(#PRINTED == printed + 3, "commande /lyorune sorts muette")
    assert(PRINTED[printed + 1]:find("3 sorts proposés", 1, true) and PRINTED[printed + 3]:find("Châtiment", 1, true), PRINTED[printed + 1])
    for _, key in ipairs({ "quels sorts Lyorune propose, et pourquoi un sort manque", "%d sorts proposés dans « Sorts et raccourcis » : %s.",
      "Sorts de votre classe absents : %s.", "Écartés (offensifs ou sans effet sur un allié) : %s.", "pas appris", "autre spécialisation", "passif" }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
    -- grimoire illisible : les sorts connus de ma classe, comme avant
    C_SpellBook.GetSpellBookSkillLineInfo = function() error("pas de grimoire") end
    assert(#Z:KnownSpells() > 0, "grimoire illisible : liste vide")
  end)
  C_Spell.GetSpellName, C_Spell.IsSpellHelpful, C_Spell.IsSpellPassive, Z.class = realName, realHelpful, realPassive, class
  C_SpellBook.GetSpellBookItemInfo, C_SpellBook.GetSpellBookSkillLineInfo = info, lines
  assert(ok, err)
end)

step("1.35.0 : buffs caches par le jeu (champ de bataille, arene) : photo, memoire de mes sorts, mort, buff lisible, version de groupe, /reload, /lyorune buffs", function()
  local old = { name = C_Spell.GetSpellName, known = C_SpellBook.IsSpellKnown, isUnit = UnitIsUnit, after = C_Timer.After,
    secrets = C_Secrets, guid = UnitGUID, instance = INSTANCE, kind = INSTANCE_TYPE, types = Enum.AddOnRestrictionType, states = Enum.AddOnRestrictionState, class = Z.class }
  local ok, err = pcall(function()
    local extra = { [14752] = "Esprit divin", [27681] = "Prière d'esprit", [976] = "Protection contre l'ombre", [588] = "Feu intérieur" }
    C_Spell.GetSpellName = function(id) return extra[id] or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return extra[id] ~= nil or old.known(id) end
    C_Timer.After = function(s, f) if s < 1 then f() end end
    local me = Z.buttons[1]
    local other
    for _, b in ipairs(Z.buttons) do
      if b ~= me and b.unit and not b.extra and b:IsVisible() and not b.unit:find("pet") then other = other or b end
    end
    UnitIsUnit = function(a, b) return a == b or (b == "player" and a == me.unit) end
    UnitGUID = function(u) return "G-" .. (u == me.unit and "player" or u) end
    local hidden, never = false, {}
    C_Secrets = { ShouldAurasBeSecret = function() return hidden end, ShouldSpellAuraBeSecret = function(id) return not never[id] end }
    Enum.AddOnRestrictionType = { Combat = 0, Encounter = 1, ChallengeMode = 2, PvPMatch = 3 }
    Enum.AddOnRestrictionState = { Inactive = 0, Activating = 1, Active = 2 }
    local function Ids(b)
      local t = {} for _, m in ipairs(b.missingBuffs or {}) do t[#t + 1] = m.check.id end
      return table.concat(t, ",")
    end
    local function Update() Z:Refresh() RunUpdates() end
    INSTANCE, INSTANCE_TYPE, NOW = true, "pvp", 5000
    Z.db.buffWatch, Z.db.buffRenew, Z.db.buffGroupAt, Z.db.buffDurations = {}, 0, 3, nil
    Z.db.missingBuffs, Z.db.buffPanel = true, true
    Z.class = "PRIEST" Z:BuildData()
    assert(Z.buffNames["Mot de pouvoir : Robustesse"] and Z.buffNames["Prière d'esprit"], "noms suivis")
    -- avant le match : tout se lit, l'etat de chacun est retenu, la duree apprise
    AURAS = { HELPFUL = { { name = "Mot de pouvoir : Robustesse", icon = 9, auraInstanceID = 31, expirationTime = NOW + 3000, duration = 3600 } } }
    Update()
    assert(Ids(other) == "14752,976", "avant le match : " .. Ids(other))
    assert(Z.db.buffDurations["Mot de pouvoir : Robustesse"] == 3600, "duree non apprise")
    -- le match commence : un message, une seule fois ; une rencontre de boss n'en donne pas
    local printed = #PRINTED
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED", 3, 1)
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED", 3, 2)
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED", 3, 1)
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED", 1, 1)
    assert(#PRINTED == printed + 1 and PRINTED[#PRINTED]:find("cachés par le jeu", 1, true), "message du match")
    -- pendant le match : noms secrets ; Robustesse connue par la photo, le reste inconnu donc propose (plus de panneau vide)
    hidden = true
    AURAS = { HELPFUL = { { name = MakeSecret(), icon = 9, auraInstanceID = 31 } } }
    Update()
    assert(Ids(other) == "14752,976", "pendant le match : " .. Ids(other))
    assert(Z.AurasHidden(), "restriction non vue")
    assert(#Z.BuffRows() > 0, "panneau vide en champ de bataille")
    -- Esprit divin pose pendant le match : retenu (cible donnee par le jeu, sort reussi), duree inconnue = 10 minutes
    FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(other.unit), "cast-1", 14752)
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 14752)
    RunUpdates()
    assert(Ids(other) == "976", "buff pose pendant le match : " .. Ids(other))
    -- un autre lancement ne compte pas
    FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(other.unit), "cast-2", 976)
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-3", 976)
    RunUpdates()
    assert(Ids(other) == "976", "sort d'un autre lancement compte : " .. Ids(other))
    -- fin des 10 minutes : propose de nouveau
    NOW = NOW + 601 Update()
    assert(Ids(other) == "14752,976", "buff retenu sans fin : " .. Ids(other))
    -- mort : tout est oublie, au cimetiere tout est propose
    Z.ForgetBuffs(other.unit) Update()
    assert(Ids(other) == "1243,14752,976", "mort : " .. Ids(other))
    -- buff que le jeu laisse lisible : son absence est sure, sa presence aussi
    never[976], never[27683] = true, true -- les deux versions doivent etre lisibles
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED", 0, 2)
    AURAS = { HELPFUL = { { name = MakeSecret(), icon = 9, auraInstanceID = 31 },
      { name = "Protection contre l'ombre", icon = 9, auraInstanceID = 32, expirationTime = NOW + 500, duration = 600 } } }
    Update()
    assert(Ids(other) == "1243,14752", "buff lisible pendant le match : " .. Ids(other))
    -- version de groupe : tout le groupe de la cible, vivants et a portee
    FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(other.unit), "cast-4", 27681)
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-4", 27681)
    RunUpdates()
    assert(Ids(other) == "1243" and not Ids(me):find("14752", 1, true), "version de groupe : " .. Ids(other) .. " / " .. Ids(me))
    -- /reload pendant le match : la memoire est gardee avec le personnage
    FireEvent("PLAYER_LOGOUT")
    local saved = Z.char.buffMemory
    assert(saved and saved.at == NOW and saved.seen["G-" .. other.unit]["Prière d'esprit"], "memoire non gardee au /reload")
    Z.char.buffMemory = nil
    -- /lyorune buffs : une ligne par buff, lisible ou cache
    printed = #PRINTED
    Z.Command("buffs")
    local text = table.concat(PRINTED, "|", printed + 1)
    assert(text:find("cachés par le jeu ici", 1, true) and text:find("Protection contre l'ombre : lisible", 1, true)
      and text:find("Mot de pouvoir : Robustesse : caché, 60 min", 1, true), "commande /lyorune buffs : " .. text)
    -- fin du match : tout se relit
    hidden = false
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED", 3, 0)
    AURAS = {} Update()
    assert(Ids(other) == "1243,14752,976", "apres le match : " .. Ids(other))
    for _, key in ipairs({ "Buffs cachés par le jeu ici : Lyorune retient vos propres buffs, pas ceux des autres joueurs.",
      "buffs cachés par le jeu ici : Lyorune retient vos propres buffs, pas ceux des autres joueurs.",
      "buffs : cachés par le jeu ici (mémoire de vos sorts).", "buffs : lisibles ici.", "aucun buff de votre classe à surveiller.",
      "%d min", "durée inconnue (10 min)", "lisible", "caché", "mémoire : %d fiche(s) de joueur en cours." }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
  end)
  C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, UnitIsUnit, C_Timer.After = old.name, old.known, old.isUnit, old.after
  C_Secrets, UnitGUID, Enum.AddOnRestrictionType, Enum.AddOnRestrictionState, Z.class = old.secrets, old.guid, old.types, old.states, old.class
  INSTANCE, INSTANCE_TYPE, AURAS = old.instance, old.kind, {}
  Z.db.buffDurations = nil
  Z:BuildData() Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("C31 : buff pose jamais montre, de retour en gris quand il faut le reposer (hors combat, combat, mort, groupe change, champ de bataille), touche du buff unique", function()
  local old = { create = CreateFrame, name = C_Spell.GetSpellName, known = C_SpellBook.IsSpellKnown, isUnit = UnitIsUnit,
    secrets = C_Secrets, class = Z.class, after = C_Timer.After, now = NOW }
  local made = {}
  local ok, err = pcall(function()
    local extra = { [1244] = "Mot de pouvoir : Robustesse", [10938] = "Mot de pouvoir : Robustesse", [21562] = "Prière de robustesse",
      [21564] = "Prière de robustesse", [588] = "Feu intérieur", [10952] = "Feu intérieur", [6346] = "Gardien de peur",
      [10937] = "Autre sort" } -- un numero dont le nom n'est pas celui du buff est ecarte
    C_Spell.GetSpellName = function(id) return extra[id] or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return extra[id] ~= nil or old.known(id) end
    C_Timer.After = function(s, f) if s < 1 then f() end end
    local hidden = false
    C_Secrets = { ShouldAurasBeSecret = function() return hidden end }
    -- faux conteneurs : places fixes notees avec leur filtre
    CreateFrame = function(kind, name, parent, template)
      if kind == "AuraContainer" then assert(not COMBAT, "conteneur cree en combat") end
      local f = old.create(kind, name, parent, template)
      if kind ~= "AuraContainer" then return f end
      f.groups, f.slots = {}, {}
      function f:AddAuraGroup(key, filter, options) options.initializeFrame(old.create("Button", nil, self)) end
      function f:AddAuraSlot(key, filter, options)
        assert(self.unit and not self.enabled, "place ajoutee dans le mauvais ordre")
        local button = old.create("Button", nil, self)
        button.Icon = old.create("Frame", nil, button):CreateTexture()
        self.slots[key] = { filter = filter, ids = (options.candidateFilters or {}).includeSpellIDs, button = button }
        options.initializeFrame(button)
        return button
      end
      function f:SetEnabled(on) assert(not COMBAT, "SetEnabled en combat") self.enabled = on end
      function f:SetUnit(unit) self.unit = unit end
      function f:UpdateAllAuras() self.updates = (self.updates or 0) + 1 end
      return f
    end
    AuraContainerSortMethod = { Default = 0 }
    AnchorUtil = { FlowDirection = { Right = 1, Left = 2, Up = 3, Down = 4 }, FlowLayoutAxis = { Horizontal = 1, Vertical = 2 } }
    Enum.CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 1 }
    Z.db.buffWatch, Z.db.missingBuffs, Z.db.combatBuffs, Z.db.buffPanel, Z.db.combatKey, Z.db.uniqueLive = {}, true, true, true, true, false -- (memoire ; en temps reel : etape 33 ter)
    Z.char.buffTarget = { byId = { [6346] = { mode = "ME" } } }
    Z.class = "PRIEST" Z:BuildData()
    -- tous les rangs, simple et groupe, sans le numero d'un autre sort
    local fort = Z.buffChecks[1]
    assert(fort.auraIds[1243] and fort.auraIds[1244] and fort.auraIds[10938] and fort.auraIds[21562] and fort.auraIds[21564],
      "rangs de Robustesse absents")
    assert(not fort.auraIds[10937], "numero d'un autre sort garde")
    local c = CreateFrame("Button", "LyoruneHeaderUnitButton35", Z.header)
    Z.header:InitButton(c:GetName())
    made[#made + 1] = c
    UnitIsUnit = function(a, b) return a == b or (a == "player" and b == Z.buttons[1].unit) or (b == "player" and a == Z.buttons[1].unit) end
    c:SetAttribute("unit", "player")
    Z:Refresh() RunUpdates()
    -- plus de conteneur des buffs : le jeu ne dessine jamais un buff pose (C31)
    assert(c.boxes and c.boxes.hots and not c.boxes.buffs, "conteneur des buffs encore cree")
    local robust = "Mot de pouvoir : Robustesse"
    local function Gray()
      local list = {}
      for _, icon in ipairs(c.buffList or {}) do
        if icon:IsShown() then list[#list + 1] = icon.texture._tex end
      end
      return list
    end
    local function Count() return #Gray() end
    local function Again() Z.QueueAuras(c) RunUpdates() end
    -- hors combat, rien de pose : tout en gris, le buff unique aussi chez son porteur (moi)
    assert(c.missingBuffs and c.missingBuffs[1].check == fort, "Robustesse non manquante")
    local ward
    for _, entry in ipairs(c.buffWatch) do if entry.check.id == 6346 then ward = entry end end
    assert(ward, "buff unique non suivi chez son porteur")
    local all = Count()
    assert(all == #c.buffWatch and all >= 3, "buffs absents en gris : " .. all .. "/" .. #c.buffWatch)
    -- Robustesse posee : elle disparait de la case
    local start = NOW
    AURAS["HELPFUL"] = { { name = robust, icon = 99, auraInstanceID = 31, spellId = 10938, expirationTime = NOW + 1800, duration = 1800 } }
    Again()
    assert(Count() == all - 1 and not c.missingBuffs[2], "buff pose encore montre hors combat")
    -- combat : le jeu cache tout, la case garde ce qu'elle savait (rien en couleur, Robustesse toujours cachee)
    FireEvent("PLAYER_REGEN_DISABLED") COMBAT = true hidden = true
    AURAS["HELPFUL"] = nil
    Again()
    assert(Count() == all - 1, "combat : buffs lus avant le combat perdus, ou buff pose montre")
    -- toujours en combat, 75 s avant sa fin : de retour en gris (memoire)
    NOW = start + 1800 - Z.db.buffRenew + 1
    Again()
    assert(Count() == all, "combat : Robustesse pas revenue en gris sous le seuil")
    -- je la relance en combat (sort reussi, memoire) : cachee de nouveau
    Z.NoteBuffs("player", { { name = robust, expirationTime = NOW + 1800, duration = 1800 } }, Z.buffNames, false)
    Again()
    assert(Count() == all - 1, "combat : sort reussi sans effet sur la case")
    -- mort en combat : tout revient en gris, meme ce qui etait pose avant
    NOW = NOW + 1
    Z.ForgetBuffs("player")
    Again()
    assert(Count() == all, "combat : mort sans effet sur la case")
    -- touche du prochain buff : mon buff unique sur son porteur, par son nom
    local key = _G.LyoruneNextBuff
    assert(key:GetAttribute("type") == "macro" and key:GetAttribute("macrotext"):find("^/cast %[@.+%] Gardien de peur$"),
      "touche du buff unique : " .. tostring(key:GetAttribute("macrotext")))
    -- le groupe change en combat : rien sur la case jusqu'a la fin du combat (le joueur n'est plus sur)
    FireEvent("GROUP_ROSTER_UPDATE") RunUpdates()
    assert(#Gray() == 0, "buffs gardes apres un changement de groupe en combat")
    COMBAT = false hidden = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
    assert(Count() == all and not c.buffWatch.stale, "fin du combat : buffs non revus")
    assert(key:GetAttribute("type") ~= "macro", "touche du buff unique gardee hors combat")
    -- le groupe change en combat mais le joueur reste le meme (identifiant lisible) : sa case garde ses buffs
    local oldGuid = UnitGUID
    UnitGUID = function(unit) return "Joueur-" .. tostring(unit) end
    Again()
    FireEvent("PLAYER_REGEN_DISABLED") COMBAT = true RunUpdates()
    FireEvent("GROUP_ROSTER_UPDATE") RunUpdates()
    assert(not c.buffWatch.stale and Count() == all, "meme joueur apres un changement de groupe : buffs effaces")
    COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
    -- mort avant le combat, releve en combat : tout revient en gris (la liste d'avant sa mort est gardee)
    AURAS["HELPFUL"] = { { name = robust, icon = 99, auraInstanceID = 32, spellId = 10938, expirationTime = NOW + 1800, duration = 1800 } }
    Again()
    assert(Count() == all - 1, "Robustesse posee montree")
    Z.ForgetBuffs("player") c.status = "dead" AURAS["HELPFUL"] = nil
    Again()
    assert(Count() == 0 and c.buffWatch, "joueur mort : buffs montres, ou liste perdue")
    FireEvent("PLAYER_REGEN_DISABLED") COMBAT = true c.status = nil
    Again()
    assert(Count() == all, "releve en combat : buffs pas revenus en gris")
    COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
    UnitGUID = oldGuid
    -- interrupteurs : « En combat » ailleurs, « En champ de bataille » en match ; hors combat, toujours montre
    local realKind = Z.PvPKind
    local function InCombat() FireEvent("PLAYER_REGEN_DISABLED") COMBAT = true Again() return #Gray() > 0 end
    local function OutCombat() COMBAT = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates() return #Gray() > 0 end
    Z.db.combatBuffs = false
    assert(not InCombat(), "En combat eteint : buffs montres en combat")
    Z.PvPKind = function() return "BG" end
    assert(InCombat(), "En champ de bataille allume : rien en combat en champ de bataille")
    Z.db.combatBuffs, Z.db.pvpBuffs = true, false
    assert(not InCombat(), "champ de bataille eteint : buffs montres en combat en match")
    assert(OutCombat(), "champ de bataille eteint : rien hors combat")
    Z.PvPKind = realKind
    assert(InCombat(), "En combat allume : rien en combat")
    assert(OutCombat(), "hors combat : rangee perdue")
    Z.db.pvpBuffs = true
    assert(Z.defaults.combatBuffs == true and Z.defaults.pvpBuffs == true, "deux interrupteurs allumes au depart")
    Z.db.combatBuffs, Z.db.combatKey = true, false
    FireEvent("PLAYER_REGEN_DISABLED")
    assert(key:GetAttribute("type") == nil, "interrupteur de la touche")
    FireEvent("PLAYER_REGEN_ENABLED")
    AURAS["HELPFUL"] = nil
    for _, text in ipairs({ "En combat", "En champ de bataille", "En combat, la touche relance mon buff unique",
      "Gris à bord rouge : à reposer. Un buff posé ne se montre pas.", "Mes buffs sur la case" }) do
      assert(Z.translations.enUS[text], "sans traduction anglaise : " .. text)
    end
  end)
  CreateFrame, C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, UnitIsUnit = old.create, old.name, old.known, old.isUnit
  C_Secrets, Z.class, C_Timer.After, NOW, AURAS["HELPFUL"] = old.secrets, old.class, old.after, old.now, nil
  AuraContainerSortMethod, AnchorUtil, Enum.CustomAuraButtonDispelTypeTextureStyle, Z.boxWrap = nil, nil, nil, nil
  Z.db.combatBuffs, Z.db.pvpBuffs, Z.db.combatKey, Z.char.buffTarget, COMBAT = true, true, true, {}, false
  for _, button in ipairs(made) do pcall(button.SetAttribute, button, "unit", nil) end
  Z:BuildData() Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("33 ter (C33) : buff unique en temps reel sur son porteur (place du jeu avec charges, repere gris dessous, en combat, hors de la rangee des soins, interrupteur)", function()
  local old = { create = CreateFrame, name = C_Spell.GetSpellName, known = C_SpellBook.IsSpellKnown, isUnit = UnitIsUnit,
    secrets = C_Secrets, class = Z.class, after = C_Timer.After, now = NOW, live = Z.db.uniqueLive }
  local made = {}
  local ok, err = pcall(function()
    local extra = { [1244] = "Mot de pouvoir : Robustesse", [6346] = "Gardien de peur" }
    C_Spell.GetSpellName = function(id) return extra[id] or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return extra[id] ~= nil or old.known(id) end
    C_Timer.After = function(s, f) if s < 1 then f() end end
    local hidden = false
    C_Secrets = { ShouldAurasBeSecret = function() return hidden end }
    CreateFrame = function(kind, name, parent, template)
      local f = old.create(kind, name, parent, template)
      if kind ~= "AuraContainer" then return f end
      f.groups, f.slots = {}, {}
      function f:AddAuraGroup(key, filter, options)
        self.groups[key] = (options.candidateFilters or {}).includeSpellIDs or {}
        options.initializeFrame(old.create("Button", nil, self))
      end
      function f:AddAuraSlot(key, filter, options)
        local button = old.create("Button", nil, self)
        self.slots[key] = { filter = filter, ids = (options.candidateFilters or {}).includeSpellIDs, button = button }
        options.initializeFrame(button)
        return button
      end
      function f:SetEnabled(on) assert(not COMBAT, "SetEnabled en combat") self.enabled = on end
      function f:SetUnit(unit) self.unit = unit end
      function f:UpdateAllAuras() end
      return f
    end
    AuraContainerSortMethod = { Default = 0 }
    AnchorUtil = { FlowDirection = { Right = 1, Left = 2, Up = 3, Down = 4 }, FlowLayoutAxis = { Horizontal = 1, Vertical = 2 } }
    Enum.CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 1 }
    Z.db.buffWatch, Z.db.missingBuffs, Z.db.combatBuffs, Z.db.buffPanel, Z.db.uniqueLive = {}, true, true, true, true
    assert(Z.defaults.uniqueLive == true, "uniqueLive allume au depart (decision de l'auteur)")
    Z.char.buffTarget = { byId = { [6346] = { mode = "ME" } } }
    Z.class = "PRIEST" Z:BuildData()
    local c = CreateFrame("Button", "LyoruneHeaderUnitButton36", Z.header)
    Z.header:InitButton(c:GetName())
    made[#made + 1] = c
    UnitIsUnit = function(a, b) return a == b or (a == "player" and b == Z.buttons[1].unit) or (b == "player" and a == Z.buttons[1].unit) end
    c:SetAttribute("unit", "player")
    NOW = (NOW or 0) + 1 -- le porteur est retenu le temps d'un instant (Auras.lua, Bearer)
    Z:Refresh() RunUpdates()
    assert(Z.UniqueLive(), "temps reel inactif")
    -- une place fixe du jeu pour Gardien de peur, mes auras seulement ; plus dans la rangee des soins
    local slot = c.boxes.slots.slots.unique1
    assert(slot and slot.filter == "HELPFUL|PLAYER" and slot.ids[6346], "pas de place du jeu pour le buff unique")
    assert(not c.boxes.hots.groups.hots[6346], "buff unique encore dans la rangee des soins")
    -- son repere gris en premiere place, sous la place du jeu ; plus suivi par la memoire
    local function Shown(index) local icon = c.buffList and c.buffList[index] return icon and icon:IsShown() and icon end
    local ward = Z.uniqueChecks[1]
    assert(ward.id == 6346 and Shown(1) and Shown(1).texture._tex == ward.icon, "repere gris du buff unique absent")
    for _, entry in ipairs(c.buffWatch or {}) do assert(entry.check.id ~= 6346, "buff unique aussi suivi par la memoire") end
    assert(Shown(2) and Shown(2).texture._tex ~= nil, "les autres buffs a reposer ne suivent pas le buff unique")
    -- en combat, buffs caches : le repere reste (le jeu le couvre tant que le buff est la)
    FireEvent("PLAYER_REGEN_DISABLED") COMBAT = true hidden = true
    Z.QueueAuras(c) RunUpdates()
    assert(Shown(1) and Shown(1).texture._tex == ward.icon, "combat : repere gris du buff unique perdu")
    -- en combat, ce qui a ete lu avant reste (un buff unique d'un autre pretre ne fait pas apparaitre le gris)
    c.otherUniques = "Gardien de peur" Z.QueueAuras(c) RunUpdates()
    assert(c.otherUniques == "Gardien de peur" and not (Shown(1) and Shown(1).texture._tex == ward.icon and #c.buffList > 1 and Shown(2) and Shown(2).texture._tex == ward.icon),
      "combat : lecture d'avant effacee")
    c.otherUniques = nil
    COMBAT = false hidden = false FireEvent("PLAYER_REGEN_ENABLED") RunUpdates()
    -- case sans la place du jeu (refaite a la fin du combat, conteneurs refuses) : pas de gris que rien ne couvre,
    -- le buff unique revient a la memoire
    local place = c.slots.unique1
    c.slots.unique1 = nil
    NOW = NOW + 1 Z.QueueAuras(c) RunUpdates()
    local watched = false
    for _, entry in ipairs(c.buffWatch or {}) do if entry.check.id == 6346 then watched = true end end
    assert(watched and not Z.HasUniquePlace(c, 1), "case sans place du jeu : buff unique ni suivi ni ecarte")
    c.slots.unique1 = place
    NOW = NOW + 1 Z.QueueAuras(c) RunUpdates()
    -- un autre joueur que le porteur : aucun repere en premiere place
    local realBearer = Z.UniqueBearer
    Z.UniqueBearer = function() return "party4" end
    NOW = NOW + 1 Z.QueueAuras(c) RunUpdates()
    Z.UniqueBearer = realBearer
    local count = 0
    for index = 1, #(c.buffList or {}) do if Shown(index) then count = count + 1 end end
    assert(count == 1 and Shown(1), "repere gris chez un joueur qui n'est pas le porteur, ou place gardee pour rien")
    -- interrupteur coupe : plus de place du jeu, le sort revient dans la rangee des soins
    Z.db.uniqueLive = false Z:Refresh() RunUpdates()
    assert(not c.boxes.slots.slots.unique1 and c.boxes.hots.groups.hots[6346], "interrupteur sans effet")
    for _, text in ipairs({ "Buffs uniques en temps réel", "En couleur avec ses charges ; gris dès qu'il tombe, même en combat." }) do
      assert(Z.translations.enUS[text], "sans traduction anglaise : " .. text)
    end
  end)
  CreateFrame, C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, UnitIsUnit = old.create, old.name, old.known, old.isUnit
  C_Secrets, Z.class, C_Timer.After, NOW, Z.db.uniqueLive = old.secrets, old.class, old.after, old.now, old.live
  AuraContainerSortMethod, AnchorUtil, Enum.CustomAuraButtonDispelTypeTextureStyle, Z.boxWrap = nil, nil, nil, nil
  Z.char.buffTarget, COMBAT = {}, false
  for _, button in ipairs(made) do pcall(button.SetAttribute, button, "unit", nil) end
  Z:BuildData() Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("1.37.0 : qui buffe qui : groupes a buffer, benediction par joueur, autre paladin, entente, repartition des buffs, fenetre, options", function()
  local saved = {} for k, v in pairs(Z.db) do saved[k] = type(v) == "table" and CopyTable(v) or v end
  local old = { name = C_Spell.GetSpellName, known = C_SpellBook.IsSpellKnown, isUnit = UnitIsUnit, class = UnitClass,
    role = UnitGroupRolesAssigned, after = C_Timer.After, zclass = Z.class, now = NOW, auras = AURAS,
    raid = RAID, grouped = GROUPED, leader = LEADER, assists = ASSISTS, names = GROUP_NAMES, members = MEMBERS }
  local ok, err = pcall(function()
    local extra = { [19740] = "Bénédiction de puissance", [19742] = "Bénédiction de sagesse", [20217] = "Bénédiction des rois",
      [25780] = "Fureur vertueuse", [25782] = "Bénédiction de puissance supérieure" }
    C_Spell.GetSpellName = function(id) return extra[id] or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return extra[id] ~= nil or old.known(id) end
    C_Timer.After = function(s, f) if s < 1 then f() end end
    local me = Z.buttons[1]
    local other
    for _, b in ipairs(Z.buttons) do
      if b ~= me and b.unit and not b.extra and b:IsVisible() and not b.unit:find("pet") then other = other or b end
    end
    assert(other, "faux groupe trop petit")
    UnitIsUnit = function(a, b) return a == b or (b == "player" and a == me.unit) end
    local classes, roles = { [me.unit] = "PALADIN", player = "PALADIN" }, {}
    UnitClass = function(u) local c = classes[u] if c then return c, c end return old.class(u) end
    UnitGroupRolesAssigned = function(u) return roles[u] or "DAMAGER" end
    local function Spell(b, id) for _, m in ipairs(b.missingBuffs or {}) do if m.check.id == id then return m.spell end end return nil end
    local function Update() Z:Refresh() RunUpdates() end
    local function Msg(text, sender) FireEvent("CHAT_MSG_ADDON", "Lyorune", text, "PARTY", sender) end
    GROUPED, RAID = true, false
    Z.db.buffWatch, Z.db.buffRenew, Z.db.missingBuffs, Z.db.buffPanel = {}, 0, true, true
    Z.db.blessingPick, Z.db.buffGroups, Z.db.blessingSync, Z.db.syncEnabled, Z.db.assignAccept = {}, {}, true, true, true
    Z.char.buffShared = nil
    AURAS = {}
    Z.class = "PALADIN" Z:BuildData()

    -- 2. grille : au depart, les regles d'avant (Puissance au guerrier, Rois au tank, Sagesse au soigneur)
    classes[other.unit] = "WARRIOR" Update()
    assert(Spell(other, 19740) == "Bénédiction de puissance", "guerrier : " .. tostring(Spell(other, 19740)))
    roles[other.unit] = "TANK" Update()
    assert(Spell(other, 19740) == "Bénédiction des rois", "tank : " .. tostring(Spell(other, 19740)))
    roles[other.unit] = nil
    roles[me.unit] = "HEALER" roles.player = "HEALER" Update()
    assert(Spell(me, 19740) == "Bénédiction de sagesse", "soigneur : " .. tostring(Spell(me, 19740)))
    -- choix dans la grille, puis « aucune »
    Z.db.blessingPick.WARRIOR = 20217 Z.BlessingsChanged() RunUpdates()
    assert(Spell(other, 19740) == "Bénédiction des rois", "choix du guerrier : " .. tostring(Spell(other, 19740)))
    Z.db.blessingPick.WARRIOR = 0 Z.BlessingsChanged() RunUpdates()
    assert(Spell(other, 19740) == nil, "aucune benediction choisie : encore proposee")
    -- Sagesse choisie a la main pour un guerrier : gardee (seulement ecartee du depart)
    Z.db.blessingPick.WARRIOR = 19742 Z.BlessingsChanged() RunUpdates()
    assert(Spell(other, 19740) == "Bénédiction de sagesse", "Sagesse choisie ecartee")
    Z.db.blessingPick = {} Z.BlessingsChanged() RunUpdates()

    -- 3. un autre paladin a deja pose Puissance : la suivante (Rois), jamais Sagesse a un guerrier
    AURAS["HELPFUL"] = { { name = "Bénédiction de puissance", icon = 1, auraInstanceID = 41, spellId = 19740 } }
    AURAS["HELPFUL|PLAYER"] = {}
    Update()
    assert(Spell(other, 19740) == "Bénédiction des rois", "benediction d'un autre paladin reprise : " .. tostring(Spell(other, 19740)))
    -- (1.51.0) sa version superieure compte pour la simple : jamais Puissance par-dessus
    AURAS["HELPFUL"] = { { name = "Bénédiction de puissance supérieure", icon = 1, auraInstanceID = 41, spellId = 25782 } }
    Update()
    assert(Spell(other, 19740) == "Bénédiction des rois", "benediction superieure d'un autre paladin ignoree : " .. tostring(Spell(other, 19740)))
    AURAS["HELPFUL"] = { { name = "Bénédiction de puissance", icon = 1, auraInstanceID = 41, spellId = 19740 } }
    AURAS["HELPFUL"][2] = { name = "Bénédiction des rois", icon = 2, auraInstanceID = 42, spellId = 20217 }
    Update()
    assert(Spell(other, 19740) == nil, "guerrier : toutes prises, encore une proposee : " .. tostring(Spell(other, 19740)))
    -- la mienne compte toujours comme posee
    AURAS["HELPFUL|PLAYER"] = { AURAS["HELPFUL"][1] }
    Update()
    assert(Spell(other, 19740) == nil, "ma benediction prise pour celle d'un autre")
    AURAS = {}

    -- 4. entente : mon annonce part au groupe ; celle d'un autre paladin prioritaire ecarte la benediction
    NOW = NOW + 10
    local first = #ADDON_SENT + 1
    Z.db.blessingPick.TANK = 20217 Z.BlessingsChanged() RunUpdates()
    local sent = ADDON_SENT[#ADDON_SENT]
    assert(#ADDON_SENT >= first and sent.text:match("^P:") and sent.text:find("TANK=20217p", 1, true) and sent.text:find("WARRIOR=19740d", 1, true),
      "annonce : " .. tostring(sent and sent.text))
    assert(#sent.text <= 255, "annonce trop longue")
    roles[other.unit] = "TANK" Update()
    assert(Spell(other, 19740) == "Bénédiction des rois", "tank avant l'annonce")
    -- un autre paladin annonce Rois aux tanks au depart : mon choix (p) passe avant
    Msg("P:TANK=20217d,WARRIOR=19740d", "Joueur-party2") RunUpdates()
    assert(Spell(other, 19740) == "Bénédiction des rois", "annonce de depart passee devant mon choix")
    -- choisi aussi : a egalite, le premier nom (party2 avant player) la garde
    Msg("P:TANK=20217p", "Joueur-party2") RunUpdates()
    assert(Spell(other, 19740) == "Bénédiction de puissance", "egalite : " .. tostring(Spell(other, 19740)))
    -- un joueur hors du groupe, un message abime : rien
    Msg("P:-", "Inconnu") Msg("P:TANK=abc", "Joueur-party2") RunUpdates()
    assert(Spell(other, 19740) == "Bénédiction de puissance", "message abime ou etranger")
    -- interrupteur : les annonces ne comptent plus
    Z.db.blessingSync = false Z.BlessingsChanged() RunUpdates()
    assert(Spell(other, 19740) == "Bénédiction des rois", "entente coupee encore suivie")
    Z.db.blessingSync = true Z.BlessingsChanged() RunUpdates()
    Msg("P:-", "Joueur-party2") RunUpdates()
    assert(Spell(other, 19740) == "Bénédiction des rois", "annonce retiree encore suivie")
    -- bloque par le jeu : rien ne part, l'annonce suit des que possible
    local lockdown = C_ChatInfo.InChatMessagingLockdown
    C_ChatInfo.InChatMessagingLockdown = function() return true end
    NOW = NOW + 10 first = #ADDON_SENT + 1
    Z.db.blessingPick.TANK = nil Z.BlessingsChanged()
    assert(#ADDON_SENT == first - 1, "annonce pendant le blocage")
    C_ChatInfo.InChatMessagingLockdown = lockdown
    FireEvent("PLAYER_REGEN_ENABLED")
    assert(ADDON_SENT[first] and ADDON_SENT[first].text:find("TANK=20217d", 1, true), "annonce en attente oubliee")
    -- un paladin revenu (/reload) redemande les annonces
    NOW = NOW + 10 first = #ADDON_SENT + 1
    Msg("P:?", "Joueur-party2")
    assert(ADDON_SENT[first] and ADDON_SENT[first].text:match("^P:TANK"), "demande d'annonce sans reponse")
    roles[other.unit] = nil

    -- 1. mes groupes a buffer (raid seulement), et « Comme mes soins »
    local roster = { 1, 1, 2, 4, 3 }
    rawset(_G, "GetRaidRosterInfo", function(i) return "x", 0, roster[i] or 1 end)
    RAID, MEMBERS = true, 5
    GROUP_NAMES = { raid1 = "Joueur-player", raid2 = "Chef", raid3 = "Soin", raid4 = "Tankou", raid5 = "Autre" }
    assert(Z.BuffGroupOK("raid3"), "depart : tous les groupes")
    Z.db.buffGroups[2] = false
    assert(not Z.BuffGroupOK("raid3") and Z.BuffGroupOK("raid4") and not Z.BuffGroupOK("raidpet3"), "groupe 2 ecarte")
    Z.db.assignGroups = { [4] = true }
    assert(Z.BuffGroupsLikeHealing() and Z.db.buffGroups[4] == nil and Z.db.buffGroups[1] == false, "comme mes soins")
    assert(Z.BuffGroupOK("raid4") and not Z.BuffGroupOK("raid2"), "groupes recopies")
    Z.db.assignGroups = {}
    assert(not Z.BuffGroupsLikeHealing(), "sans groupe de soin : rien a recopier")

    -- 5. repartition des buffs du chef : mes groupes et ma benediction imposee
    LEADER, ASSISTS = "raid2", {}
    Msg("B:7:1:2:Joueur-player=12/20217", "Chef")
    assert(Z.char.buffShared == nil, "appliquee avant la derniere part")
    Msg("B:7:2:2:Soin-MonRoyaume=3/0", "Chef")
    local shared = Z.char.buffShared
    assert(shared and shared.buffers["Joueur-player"].blessing == 20217, "repartition des buffs recue")
    assert(PRINTED[#PRINTED]:find("groupes 1 et 2", 1, true) and PRINTED[#PRINTED]:find("rois", 1, true), "ligne : " .. PRINTED[#PRINTED])
    local groups, chief = Z.BuffGroupsChoice()
    assert(chief and groups[1] and groups[2] and not groups[4] and Z.BuffGroupOK("raid3") and not Z.BuffGroupOK("raid4"), "groupes du chef")
    assert(Z.BlessingAnnounceText():find("WARRIOR=20217f", 1, true), "benediction imposee non annoncee")
    -- sans droit, abime : ignore ; effacee par son expediteur seulement
    Msg("B:8:1:1:Joueur-player=5/0", "Autre")
    for _, bad in ipairs({ "B:9:1:1:pasdenom=1/0", "B:9:1:1:Joueur-player=1/x", "B:9:1:99:Joueur-player=1/0" }) do Msg(bad, "Chef") end
    assert(Z.char.buffShared.id == "7", "repartition sans droit ou abimee acceptee")
    Msg("B:7:0:0:", "Autre")
    assert(Z.char.buffShared, "effacee par un autre")
    Msg("B:7:0:0:", "Chef")
    assert(Z.char.buffShared == nil and not Z.BuffGroupOK("raid2"), "effacement : mon choix ne revient pas")
    -- reglage coupe : ignoree
    Z.db.assignAccept = false Msg("B:10:1:1:Joueur-player=1/0", "Chef") Z.db.assignAccept = true
    assert(Z.char.buffShared == nil, "repartition recue reglage coupe")

    -- fenetre du chef : une ligne par joueur qui buffe, cases de groupe, benediction du paladin
    classes.raid2, classes.raid3, classes.raid1 = "PRIEST", "PALADIN", "PALADIN"
    LEADER = "player"
    Z:OpenBuffAssign()
    local w = _G.LyoruneBuffAssign
    assert(w and w:IsShown() and #w.rows >= 2, "fenetre de repartition des buffs")
    local pala
    for _, row in ipairs(w.rows) do if row:IsShown() and row.buffer.key == "Soin-MonRoyaume" then pala = row end end
    assert(pala and pala.bless:IsShown() and pala.boxes[1], "ligne du paladin")
    pala.boxes[1]:Run("OnClick")
    pala.bless:Run("OnClick")
    assert(w.draft["Soin-MonRoyaume"].blessing ~= 0, "benediction non choisie")
    NOW = NOW + 10 first = #ADDON_SENT + 1
    w.send:Run("OnClick")
    assert(ADDON_SENT[first] and ADDON_SENT[first].text:match("^B:%d+:1:1:Soin%-MonRoyaume=%d+/%d+$"), "envoi : " .. tostring(w.status:GetText()))
    -- un nouveau venu la recoit en chuchotement
    first = #ADDON_SENT + 1
    Z.BuffAssignNewMember("Nouveau")
    local whisper = false
    for i = first, #ADDON_SENT do if ADDON_SENT[i].channel == "WHISPER" and ADDON_SENT[i].text:match("^B:") then whisper = true end end
    assert(whisper, "nouveau venu oublie")
    -- un joueur part : je suis prevenu
    GROUP_NAMES.raid3 = "Remplacant" FireEvent("GROUP_ROSTER_UPDATE")
    assert(Z.char.buffShared.buffers["Soin-MonRoyaume"] == nil and PRINTED[#PRINTED]:find("Soin est parti", 1, true), "depart : " .. PRINTED[#PRINTED])
    w.clear:Run("OnClick")
    assert(Z.char.buffShared == nil and ADDON_SENT[#ADDON_SENT].text:match("^B:%d+:0:0:$"), "effacer pour tous")
    w.other:Run("OnClick")
    assert(not w:IsShown() and _G.LyoruneAssign and _G.LyoruneAssign:IsShown(), "passage a la fenetre des soigneurs")
    _G.LyoruneAssign.other:Run("OnClick")
    assert(w:IsShown(), "retour a la fenetre des buffs")
    w:Hide()
    -- /lyorune buffs dit qui buffe qui
    local n = #PRINTED
    SlashCmdList.LYORUNE("buffs")
    local said = table.concat(PRINTED, "\n", n + 1)
    assert(said:find("groupes buffés", 1, true) and said:find("bénédictions", 1, true), "rapport : " .. said)
    -- sortie du groupe : annonces et repartition oubliees
    Msg("P:TANK=20217f", "Chef")
    GROUPED, RAID = false, false FireEvent("GROUP_ROSTER_UPDATE")
    assert(not next(Z.BlessingClaims()) and Z.char.buffShared == nil, "sortie du groupe : annonces gardees")
    GROUPED = true
    GROUP_NAMES = old.names
    rawset(_G, "GetRaidRosterInfo", nil)

    -- Options : groupes a buffer et grille (paladin seulement)
    Z:ToggleOptions("Joueurs")
    local grid, gbox = Z.blessingGridBox, Z.buffGroupsBox
    assert(grid and gbox, "options absentes")
    grid:Update()
    assert(grid.rows[1]:IsShown() and grid.rows[1].slot == "TANK" and #grid.rows == #Z.blessingSlots, "grille")
    grid.rows[1].pick:Run("OnClick")
    assert(Z.db.blessingPick.TANK == Z.buffChecks[1].choices[1].id, "clic sur la grille : " .. tostring(Z.db.blessingPick.TANK))
    Z.db.buffGroups = {}
    gbox.buttons[5]:Run("OnClick")
    assert(Z.db.buffGroups[5] == false, "bouton de groupe")
    gbox.buttons[5]:Run("OnClick")
    assert(Z.db.buffGroups[5] == nil, "bouton de groupe rallume")
    Z.class = "PRIEST" Z:BuildData() grid:Update()
    assert(grid.empty:IsShown() and not grid.rows[1]:IsShown(), "grille montree a un pretre")
    Z:ToggleOptions()
    for _, text in ipairs({ "Groupes de raid que je buffe", "Bénédiction par joueur", "Entente entre paladins", "Répartir les buffs",
      "Répartir les buffs...", "Comme mes soins", "répartition des buffs de %s : vous buffez %s.", "Tanks", "Démoniste" }) do
      assert(Z.translations.enUS[text], "sans traduction anglaise : " .. text)
    end
  end)
  C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, UnitIsUnit, UnitClass = old.name, old.known, old.isUnit, old.class
  UnitGroupRolesAssigned, C_Timer.After, Z.class, NOW, AURAS = old.role, old.after, old.zclass, old.now, old.auras
  RAID, GROUPED, LEADER, ASSISTS, GROUP_NAMES, MEMBERS = old.raid, old.grouped, old.leader, old.assists, old.names, old.members
  rawset(_G, "GetRaidRosterInfo", nil)
  for k, v in pairs(saved) do Z.db[k] = v end
  Z.char.buffShared = nil
  if _G.LyoruneBuffAssign then _G.LyoruneBuffAssign:Hide() end
  if _G.LyoruneAssign then _G.LyoruneAssign:Hide() end
  FireEvent("GROUP_ROSTER_UPDATE")
  Z:BuildData() Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("1.38.0 : rang choisi sur chaque raccourci : rang fixe par numero, rang inconnu par le nom, liste des rangs, rang glisse garde, macros des barres, partage", function()
  local old = { name = C_Spell.GetSpellName, known = C_SpellBook.IsSpellKnown, sub = C_Spell.GetSpellSubtext, level = C_Spell.GetSpellLevelLearned,
    cost = C_Spell.GetSpellPowerCost, info = C_SpellBook.GetSpellBookItemInfo, lines = C_SpellBook.GetSpellBookSkillLineInfo,
    click = Z:GetClicks()["1"], res = Z.db.autoRes, class = Z.class }
  Z.db.rankChoice = true
  local ok, err = pcall(function()
    -- Soins rapides : rangs 1 (2061), 2 (9472) et 3 (9473) ; Soins inferieurs (2050) : inconnu de ce personnage
    local ranks = { [2061] = 1, [9472] = 2, [9473] = 3 }
    C_Spell.GetSpellName = function(id) return ranks[id] and "Soins rapides" or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return ranks[id] ~= nil or old.known(id) end
    C_Spell.GetSpellSubtext = function(id) return ranks[id] and ("Rang " .. ranks[id]) or "" end
    C_Spell.GetSpellLevelLearned = function(id) return ({ [2061] = 20, [9472] = 26, [9473] = 32 })[id] or 0 end
    C_Spell.GetSpellPowerCost = function(id) return { { cost = ({ [2061] = 125, [9472] = 155, [9473] = 185 })[id] or 0 } } end
    local function Book(items)
      C_SpellBook.GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #items } end
      C_SpellBook.GetSpellBookItemInfo = function(slot)
        local id = items[slot]
        return { itemType = 1, spellID = id, isPassive = false, subName = C_Spell.GetSpellSubtext(id) }
      end
    end
    Z.class = "PRIEST"
    Book({ 9473, 2061, 139, 9472 })
    -- liste des rangs : le plus haut en premier, puis chaque rang du plus bas au plus haut, niveau et mana
    local spell
    for _, s in ipairs(Z:KnownSpells()) do if s.name == "Soins rapides" then spell = s end end
    assert(spell and spell.top == 3 and #spell.ranks == 3 and spell.id == 9473, "rangs du grimoire")
    local list, hidden = Z.RankChoices(spell)
    assert(#list == 4 and list[1].value == "Soins rapides" and list[2].value == "#2061" and list[4].value == "#9473" and not hidden, "liste des rangs")
    assert(list[2].text:find("Rang 1", 1, true) and list[2].text:find("niveau 20", 1, true) and list[2].text:find("125 mana", 1, true), list[2].text)
    -- grimoire sans l'option des rangs : seul le rang 3, la liste le dit
    Book({ 9473, 139 })
    for _, s in ipairs(Z:KnownSpells()) do if s.name == "Soins rapides" then spell = s end end
    assert(select(2, Z.RankChoices(spell)) == true, "rangs caches non signales")
    -- sort sans rang : aucun chiffre
    for _, s in ipairs(Z:KnownSpells()) do if s.name == "Rénovation" then assert(not s.top, "Renovation sans rang") end end
    Book({ 9473, 2061, 139, 9472 })
    -- rang fixe : lance par son numero, ligne avec le rang
    local b = Z.buttons[1]
    Z.db.autoRes = false
    Z:SetClick("1", "#2061")
    assert(b:GetAttribute("type1") == "spell" and b:GetAttribute("spell1") == 2061, "rang fixe : " .. tostring(b:GetAttribute("spell1")))
    assert(Z:ActionText("#2061") == "Soins rapides, rang 1", Z:ActionText("#2061"))
    assert(Z:SpellIsBound("Soins rapides"), "rang fixe non reconnu comme attribue")
    -- dans une macro (resurrection automatique) : le texte du rang du jeu
    Z.db.autoRes = true Z:ApplyClicks()
    assert(b:GetAttribute("macrotext1"):find("[@mouseover] Soins rapides(Rang 1)", 1, true), b:GetAttribute("macrotext1"))
    -- rang inconnu de ce personnage : lance par le nom, ligne en orange
    Z.db.autoRes = false
    Z:SetClick("1", "#2050")
    assert(b:GetAttribute("spell1") == "Soins inférieurs", tostring(b:GetAttribute("spell1")))
    assert(Z:ActionText("#2050"):find("rang inconnu de ce personnage", 1, true), Z:ActionText("#2050"))
    -- numero que le jeu ne connait pas du tout : rien, sans erreur
    Z:SetClick("1", "#999999")
    assert(b:GetAttribute("type1") == nil, "numero inconnu du jeu")
    -- glisse depuis le grimoire : un rang bas reste ce rang, le rang le plus haut devient « le plus haut »
    CURSOR_INFO = { "spell", 1, "spell", 2061 }
    assert(Z:TakeCursor() == "#2061", "rang bas glisse perdu")
    CURSOR_INFO = { "spell", 1, "spell", 9473 }
    assert(Z:TakeCursor() == "Soins rapides", "rang le plus haut glisse")
    CURSOR_INFO = nil
    -- macros des barres : un nom a part, le rang dans le texte
    Z:GetClicks()["1"] = "#2061"
    Z:GetClicks()["2"] = Z:GetClicks()["2"] or "Soins rapides"
    local fixed
    for _, macro in ipairs(Z:BarMacros()) do
      if macro.body:find("Soins rapides(Rang 1)", 1, true) then fixed = macro end
    end
    assert(fixed and fixed.name == "Lyo:1 Soins rapi", "macro de barre : " .. tostring(fixed and fixed.name))
    -- code de partage : le rang fixe passe tel quel
    local code = Z:Export()
    Z:GetClicks()["1"] = "Rénovation"
    assert(Z:Import(code) and Z:GetClicks()["1"] == "#2061", "partage du rang : " .. tostring(Z:GetClicks()["1"]))
    for _, key in ipairs({ "rang inconnu de ce personnage", "Le plus haut (suit vos nouveaux rangs)", "Rang %d", "niveau %d", "%d mana",
      "Clic : le rang le plus haut. Clic droit : choisir un rang." }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
  end)
  C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, C_Spell.GetSpellSubtext = old.name, old.known, old.sub
  C_Spell.GetSpellLevelLearned, C_Spell.GetSpellPowerCost = old.level, old.cost
  C_SpellBook.GetSpellBookItemInfo, C_SpellBook.GetSpellBookSkillLineInfo = old.info, old.lines
  CURSOR_INFO, Z.db.autoRes, Z.class = nil, old.res, old.class
  Z.db.rankChoice = false
  Z:SetClick("1", old.click)
  assert(ok, err)
end)

step("1.38.1 : choix du rang eteint au depart (toujours le plus haut), rang adapte au niveau du joueur soigne", function()
  local old = { name = C_Spell.GetSpellName, known = C_SpellBook.IsSpellKnown, sub = C_Spell.GetSpellSubtext, level = C_Spell.GetSpellLevelLearned,
    info = C_SpellBook.GetSpellBookItemInfo, lines = C_SpellBook.GetSpellBookSkillLineInfo, unitLevel = UnitLevel,
    click = Z:GetClicks()["1"], res = Z.db.autoRes, class = Z.class, choice = Z.db.rankChoice, adapt = Z.db.rankAdapt }
  local ok, err = pcall(function()
    assert(Z.defaults.rankChoice == false and Z.defaults.rankAdapt == true, "reglages de depart")
    assert(Z.notInProfile.rankChoice and Z.notInProfile.rankAdapt, "reglages hors profil")
    local ranks = { [2061] = 1, [9472] = 2, [9473] = 3 }
    C_Spell.GetSpellName = function(id) return ranks[id] and "Soins rapides" or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return ranks[id] ~= nil or old.known(id) end
    C_Spell.GetSpellSubtext = function(id) return ranks[id] and ("Rang " .. ranks[id]) or "" end
    C_Spell.GetSpellLevelLearned = function(id) return ({ [2061] = 20, [9472] = 26, [9473] = 32 })[id] or 0 end
    local items = { 9473, 2061, 139, 9472 }
    C_SpellBook.GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #items } end
    C_SpellBook.GetSpellBookItemInfo = function(slot) return { itemType = 1, spellID = items[slot], subName = C_Spell.GetSpellSubtext(items[slot]) } end
    Z.class, Z.db.autoRes = "PRIEST", false
    local b = Z.buttons[1]
    -- eteint : le rang choisi est garde, mais le plus haut part, par le nom ; un rang glisse devient le plus haut
    Z.db.rankChoice = false
    Z:SetClick("1", "#2061")
    assert(Z:GetClicks()["1"] == "#2061" and b:GetAttribute("spell1") == "Soins rapides", tostring(b:GetAttribute("spell1")))
    assert(Z:ActionText("#2061") == "Soins rapides", Z:ActionText("#2061"))
    CURSOR_INFO = { "spell", 1, "spell", 2061 }
    assert(Z:TakeCursor() == "Soins rapides", "rang glisse alors que le choix est eteint")
    -- rallume : le rang revient
    Z.db.rankChoice = true Z:ApplyClicks()
    assert(b:GetAttribute("spell1") == 2061, "rang choisi perdu")
    -- adapte au joueur soigne : rang 3 (appris au niveau 32) sur un joueur de niveau 18 : rang 2 (26 - 10 <= 18)
    local levels = {}
    UnitLevel = function(unit) return levels[unit] or 60 end
    levels[b.unit] = 18
    Z:SetClick("1", "#9473")
    assert(b:GetAttribute("spell1") == 9472, "rang non adapte : " .. tostring(b:GetAttribute("spell1")))
    assert(Z.buttons[2]:GetAttribute("spell1") == 9473, "un joueur de niveau 60 garde le rang choisi")
    -- dans une macro aussi
    Z.db.autoRes = true Z:ApplyClicks()
    assert(b:GetAttribute("macrotext1"):find("Soins rapides(Rang 2)", 1, true), b:GetAttribute("macrotext1"))
    Z.db.autoRes = false Z:ApplyClicks()
    -- trop bas pour tous les rangs : le rang choisi ; niveau qui change : la case suit
    levels[b.unit] = 5 Z:FitAllRanks()
    assert(b:GetAttribute("spell1") == 9473, "aucun rang assez bas")
    levels[b.unit] = 12 Z:FitAllRanks()
    assert(b:GetAttribute("spell1") == 2061, "niveau 12 : rang 1")
    -- en combat : rien ne change, revu a la fin du combat
    levels[b.unit] = 60
    COMBAT = true Z:FitAllRanks()
    assert(b:GetAttribute("spell1") == 2061, "change en combat")
    COMBAT = false
    Z:FitAllRanks()
    assert(b:GetAttribute("spell1") == 9473, "fin du combat : rang choisi")
    -- reglage eteint : le rang choisi partout
    Z.db.rankAdapt = false levels[b.unit] = 18 Z:ApplyClicks()
    assert(b:GetAttribute("spell1") == 9473, "rankAdapt eteint")
    for _, key in ipairs({ "Choisir le rang des sorts", "Rang adapté au niveau du joueur soigné", "Sinon, toujours le rang le plus haut." }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
  end)
  C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, C_Spell.GetSpellSubtext, C_Spell.GetSpellLevelLearned = old.name, old.known, old.sub, old.level
  C_SpellBook.GetSpellBookItemInfo, C_SpellBook.GetSpellBookSkillLineInfo, UnitLevel = old.info, old.lines, old.unitLevel
  CURSOR_INFO, COMBAT, Z.db.autoRes, Z.class, Z.db.rankChoice, Z.db.rankAdapt = nil, false, old.res, old.class, old.choice, old.adapt
  Z:SetClick("1", old.click)
  assert(ok, err)
end)

step("1.39.0 : variantes d'un raccourci (sur un ennemi, en JcJ, hors combat) et aucun soin sur un ennemi", function()
  local old = { clicks = CopyTable(Z:GetClicks()), keys = CopyTable(Z:GetHoverKeys()), res = Z.db.autoRes, class = Z.class,
    guard = Z.db.enemyGuard, harmful = C_Spell.IsSpellHarmful, helpful = C_Spell.IsSpellHelpful, info = C_SpellBook.GetSpellBookItemInfo,
    lines = C_SpellBook.GetSpellBookSkillLineInfo, name = C_Spell.GetSpellName }
  local ok, err = pcall(function()
    assert(Z.defaults.enemyGuard == true and type(Z.defaults.clickVariants) == "table", "reglages de depart")
    assert(Z.notInProfile.enemyGuard and Z.notInProfile.clickVariants, "reglages hors profil")
    Z.class, Z.db.autoRes, Z.db.enemyGuard = "PRIEST", false, true
    local b = Z.buttons[1]
    local one, shift = { kind = "click", key = "1" }, { kind = "click", key = "shift-1" }
    Z:SetClick("1", "Soins")
    Z:SetClick("2", "@target")
    Z:SetClick("shift-1", "Rénovation")
    -- garde : sur un ennemi, un soin passe sur un bouton sans action ; Cibler reste Cibler
    assert(b:GetAttribute("harmbutton1") == "zxnone" and b:GetAttribute("*type-zxnone") == nil, "garde : " .. tostring(b:GetAttribute("harmbutton1")))
    assert(b:GetAttribute("harmbutton2") == nil, "Cibler garde sur un ennemi")
    assert(b:GetAttribute("shift-harmbutton1") == "zxnone", "garde avec Maj")
    -- touche au survol gardee aussi
    Z:SetBinding({ kind = "key", key = "F" }, "Rénovation")
    local index
    for i, entry in ipairs(Z:GetHoverKeys()) do if entry.key == "F" then index = i end end
    assert(b:GetAttribute("*harmbutton-zh" .. index) == "zxnone", "garde de la touche")
    -- garde eteinte : plus rien
    Z.db.enemyGuard = false Z:ApplyClicks()
    assert(b:GetAttribute("harmbutton1") == nil, "garde eteinte")
    Z.db.enemyGuard = true Z:ApplyClicks()
    -- variante ennemie : le bouton du jeu passe sur « zx1 » / « zxshift1 », qui lance le sort offensif
    Z:SetVariant(one, "enemy", "Châtiment")
    assert(b:GetAttribute("harmbutton1") == "zx1" and b:GetAttribute("*type-zx1") == "spell" and b:GetAttribute("*spell-zx1") == "Châtiment", "variante ennemie")
    assert(b:GetAttribute("type1") == "spell" and b:GetAttribute("spell1") == "Soins", "le clic sur un allie change")
    Z:SetVariant(shift, "enemy", "@target")
    assert(b:GetAttribute("shift-harmbutton1") == "zxshift1" and b:GetAttribute("*type-zxshift1") == "target", "Maj sur un ennemi : cibler")
    Z:SetVariant({ kind = "key", key = "F" }, "enemy", "Mot de l'ombre : Douleur")
    assert(b:GetAttribute("*harmbutton-zh" .. index) == "zxh" .. index and b:GetAttribute("*spell-zxh" .. index) == "Mot de l'ombre : Douleur", "touche sur un ennemi")
    -- infobulle de la case : la variante en retrait
    local found
    for _, line in ipairs(Z:ClickSummary()) do if line[2] == "Châtiment" then found = line[1] end end
    assert(found and found:find("Sur un ennemi", 1, true), "infobulle sans variante")
    -- hors combat : un sort seulement ; le jeu choisit par la macro
    Z:SetVariant(one, "ooc", "@macro:Test")
    assert(Z:VariantsOf(one).ooc == nil, "macro acceptee hors combat")
    Z:SetVariant(one, "ooc", "Mot de pouvoir : Robustesse")
    assert(b:GetAttribute("type1") == "macro" and b:GetAttribute("macrotext1") == "/cast [nocombat,@mouseover] Mot de pouvoir : Robustesse; [@mouseover] Soins",
      tostring(b:GetAttribute("macrotext1")))
    Z.db.autoRes = true Z:ApplyClicks()
    local text = b:GetAttribute("macrotext1")
    assert(text:find("dead", 1, true) and text:find("[nocombat,@mouseover] Mot de pouvoir : Robustesse; [@mouseover] Soins", 1, true), text)
    Z.db.autoRes = false Z:ApplyClicks()
    -- devant une macro : le sort hors combat, puis la macro s'arrete hors combat
    Z:SetClick("3", "/cast [@mouseover] Prière de soins")
    Z:SetVariant({ kind = "click", key = "3" }, "ooc", "Rénovation")
    assert(b:GetAttribute("macrotext3"):find("^/cast %[nocombat,@mouseover%] Rénovation\n/stopmacro %[nocombat%]\n/cast %[@mouseover%] Prière de soins"), b:GetAttribute("macrotext3"))
    -- en JcJ : la variante est posee a l'entree, hors combat, et retiree a la sortie
    Z:SetVariant(one, "ooc", nil)
    Z:SetVariant(one, "pvp", "Soins rapides")
    assert(b:GetAttribute("spell1") == "Soins", "variante JcJ hors du JcJ")
    INSTANCE_TYPE = "pvp" FireEvent("ZONE_CHANGED_NEW_AREA")
    assert(b:GetAttribute("spell1") == "Soins rapides", "variante JcJ absente en champ de bataille")
    assert(b:GetAttribute("harmbutton1") == "zx1", "variante ennemie perdue en JcJ")
    -- sortie en combat : attendue jusqu'a la fin du combat, sans message
    local printed = #PRINTED
    COMBAT = true INSTANCE_TYPE = "none" FireEvent("ZONE_CHANGED_NEW_AREA")
    assert(b:GetAttribute("spell1") == "Soins rapides" and #PRINTED == printed, "change en combat")
    COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
    assert(b:GetAttribute("spell1") == "Soins", "variante JcJ restee apres la sortie")
    INSTANCE_TYPE = "arena" FireEvent("PLAYER_ENTERING_WORLD")
    assert(b:GetAttribute("spell1") == "Soins rapides", "arene")
    INSTANCE_TYPE = "none" FireEvent("PLAYER_ENTERING_WORLD")
    -- deplacer un raccourci : ses variantes suivent ; le retirer : elles partent
    Z:MoveBinding(one, { kind = "click", key = "4" })
    assert(Z:VariantsOf({ kind = "click", key = "4" }).enemy == "Châtiment" and not next(Z:VariantsOf(one)), "variantes non deplacees")
    assert(b:GetAttribute("harmbutton4") == "zx4", "variante deplacee non posee")
    -- partage : les variantes passent avec les clics, jamais une macro
    local code = Z:Export()
    assert(code:find("v.PRIEST.4.enemy=s", 1, true), "variante absente du code")
    Z:SetVariant({ kind = "click", key = "4" }, "enemy", nil)
    assert(Z:Import(code) and Z:VariantsOf({ kind = "click", key = "4" }).enemy == "Châtiment", "variante non importee")
    assert(Z:VariantsOf({ kind = "click", key = "4" }).pvp == "Soins rapides", "variante JcJ non importee")
    Z:SetBinding({ kind = "click", key = "4" }, nil)
    assert(not next(Z:VariantsOf({ kind = "click", key = "4" })), "variantes restees apres le retrait")
    -- sorts pour un ennemi : ceux que le jeu dit offensifs
    local items = { 585, 139 }
    C_Spell.GetSpellName = function(id) return id == 585 and "Châtiment" or old.name(id) end
    C_Spell.IsSpellHarmful = function(id) return id == 585 end
    C_Spell.IsSpellHelpful = function(id) return id ~= 585 end
    C_SpellBook.GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #items } end
    C_SpellBook.GetSpellBookItemInfo = function(slot) return { itemType = 1, spellID = items[slot] } end
    local enemy = Z:KnownSpells("enemy")
    assert(#enemy == 1 and enemy[1].name == "Châtiment", "sorts pour un ennemi")
    for _, spell in ipairs(Z:KnownSpells()) do assert(spell.name ~= "Châtiment", "sort offensif propose sur un allie") end
    assert(Z:SpellIsBound("Mot de l'ombre : Douleur"), "sort d'une variante non reconnu")
    -- l'ecran : la sous-ligne sous son raccourci, le « + » ouvre le choix (sans menu du jeu : la premiere variante libre)
    Z:SetClick("1", "Soins")
    Z:ToggleOptions("Clics")
    local _, row = Z:ClickCell("1")
    assert(row and row.add:IsShown(), "bouton +")
    row.add:Run("OnClick", "LeftButton")
    assert(LyorunePicker:IsShown(), "choix de la variante")
    LyorunePicker.Choose("Châtiment")
    assert(Z:VariantsOf(one).enemy == "Châtiment", "variante choisie a l'ecran")
    local _, sub = Z:ClickCell("1", "click", "enemy")
    assert(sub and sub:IsShown() and not sub.add:IsShown() and sub.spell.label:GetText() == "Châtiment", "sous-ligne")
    sub.clear:Run("OnClick", "LeftButton")
    assert(not Z:VariantsOf(one).enemy and Z:GetClicks()["1"] == "Soins", "retrait de la variante seule")
    Z:ToggleOptions()
    local labels = table.concat(Z:OptionLabels(), "|")
    assert(labels:find("Aucun soin sur un ennemi", 1, true), "interrupteur absent")
    for _, key in ipairs({ "Sur un ennemi", "En JcJ", "Hors combat", "Ajouter une variante", "Retirer cette variante",
      "hors combat : un sort seulement, pas de macro." }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
  end)
  C_Spell.IsSpellHarmful, C_Spell.GetSpellName, C_Spell.IsSpellHelpful = old.harmful, old.name, old.helpful
  C_SpellBook.GetSpellBookItemInfo, C_SpellBook.GetSpellBookSkillLineInfo = old.info, old.lines
  INSTANCE_TYPE, COMBAT = "none", false
  if LyorunePicker then LyorunePicker:Hide() end
  Z.db.clickVariants = {}
  Z.db.clicks[Z:ClickSet()], Z.db.hoverKeys[Z:ClickSet()] = old.clicks, old.keys
  Z.db.autoRes, Z.class, Z.db.enemyGuard = old.res, old.class, old.guard
  Z:ApplyClicks()
  assert(ok, err)
end)

step("1.39.1 : variante sur un tank (cadres tries par role surs en combat, autres cases posees hors combat)", function()
  local old = { clicks = CopyTable(Z:GetClicks()), keys = CopyTable(Z:GetHoverKeys()), res = Z.db.autoRes, class = Z.class,
    role = UnitGroupRolesAssigned, guard = Z.db.enemyGuard }
  local b, other = Z.buttons[1], Z.buttons[2]
  local parent, otherParent = b._parent, other._parent
  local ok, err = pcall(function()
    Z.class, Z.db.autoRes, Z.db.enemyGuard = "PRIEST", false, true
    local one = { kind = "click", key = "1" }
    local tankUnit = b.unit or "player"
    b.unit = tankUnit
    other.unit = other.unit or "party1"
    UnitGroupRolesAssigned = function(u) return u == tankUnit and "TANK" or "DAMAGER" end
    Z:SetClick("1", "Soins")
    assert(b:GetAttribute("spell1") == "Soins", "sans variante, rien ne change")
    Z:SetVariant(one, "tank", "Soins supérieurs")
    assert(Z:VariantsOf(one).tank == "Soins supérieurs", "variante tank refusee")
    -- groupe melange : la case du tank recoit la variante hors combat, les autres la base
    assert(b:GetAttribute("spell1") == "Soins supérieurs", "case du tank : " .. tostring(b:GetAttribute("spell1")))
    assert(other:GetAttribute("spell1") == "Soins", "case d'un autre : " .. tostring(other:GetAttribute("spell1")))
    -- l'en-tete « Tanks » recopie la variante sur ses nouvelles cases, les autres la base
    local function HeaderValue(h, key)
      for i = 1, h:GetAttribute("z-count") or 0 do
        if h:GetAttribute("z-key" .. i) == key then return h:GetAttribute("z-value" .. i) end
      end
    end
    assert(HeaderValue(LyoruneTanks, "spell1") == "Soins supérieurs", "en-tete Tanks")
    for _, h in ipairs(Z.headers) do
      if h ~= LyoruneTanks and h:GetAttribute("roleFilter") ~= "TANK" and h:GetAttribute("z-count") then
        assert(HeaderValue(h, "spell1") ~= "Soins supérieurs", "en-tete melange avec la variante : " .. tostring(h:GetName()))
      end
    end
    -- une case du cadre Tanks : la variante, quel que soit le role lu
    other._parent = LyoruneTanks
    Z:FitAllRanks()
    assert(other:GetAttribute("spell1") == "Soins supérieurs", "case du cadre Tanks")
    other._parent = otherParent
    Z:FitAllRanks()
    assert(other:GetAttribute("spell1") == "Soins", "case revenue dans un groupe melange")
    -- role change en combat : attendu jusqu'a la fin du combat
    COMBAT = true
    UnitGroupRolesAssigned = function(u) return u == other.unit and "TANK" or "DAMAGER" end
    FireEvent("PLAYER_ROLES_ASSIGNED")
    assert(b:GetAttribute("spell1") == "Soins supérieurs" and other:GetAttribute("spell1") == "Soins", "change en combat")
    COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
    assert(b:GetAttribute("spell1") == "Soins" and other:GetAttribute("spell1") == "Soins supérieurs", "pas repose apres le combat")
    -- role secret : la base
    UnitGroupRolesAssigned = function() return MakeSecret() end
    FireEvent("PLAYER_ROLES_ASSIGNED")
    assert(other:GetAttribute("spell1") == "Soins", "role secret")
    -- hors combat : la base garde son sort hors combat, le tank prend sa variante meme hors combat
    UnitGroupRolesAssigned = function(u) return u == tankUnit and "TANK" or "DAMAGER" end
    Z:SetVariant(one, "ooc", "Rénovation")
    assert(b:GetAttribute("type1") == "spell" and b:GetAttribute("spell1") == "Soins supérieurs", "tank hors combat")
    assert(other:GetAttribute("macrotext1"):find("[nocombat,@mouseover] Rénovation", 1, true), "base sans son sort hors combat")
    -- garde ennemie et variante ennemie : pareilles sur les deux versions
    assert(b:GetAttribute("harmbutton1") == "zxnone" and other:GetAttribute("harmbutton1") == "zxnone", "garde perdue")
    -- en JcJ, la variante JcJ passe avant le tank
    Z:SetVariant(one, "pvp", "Soins rapides")
    INSTANCE_TYPE = "pvp" FireEvent("ZONE_CHANGED_NEW_AREA")
    assert((b:GetAttribute("macrotext1") or ""):find("[@mouseover] Soins rapides", 1, true), "JcJ avant tank : " .. tostring(b:GetAttribute("macrotext1")))
    INSTANCE_TYPE = "none" FireEvent("ZONE_CHANGED_NEW_AREA")
    assert(b:GetAttribute("spell1") == "Soins supérieurs", "tank apres JcJ")
    -- partage et ecran
    assert(Z:Export():find("v.PRIEST.1.tank=s", 1, true), "variante tank absente du code")
    Z:ToggleOptions("Clics")
    local _, sub = Z:ClickCell("1", "click", "tank")
    assert(sub and sub:IsShown() and sub.spell.label:GetText() == "Soins supérieurs", "sous-ligne tank")
    Z:ToggleOptions()
    -- variante retiree : plus de version tank, toutes les cases reviennent a la base
    Z:SetVariant(one, "tank", nil)
    assert(b:GetAttribute("type1") == "macro" and HeaderValue(LyoruneTanks, "spell1") == nil, "version tank restee")
    assert(Z.translations.enUS["Sur un tank"], "sans traduction anglaise")
  end)
  b._parent, other._parent = parent, otherParent
  INSTANCE_TYPE, COMBAT = "none", false
  UnitGroupRolesAssigned = old.role
  Z.db.clickVariants = {}
  Z.db.clicks[Z:ClickSet()], Z.db.hoverKeys[Z:ClickSet()] = old.clicks, old.keys
  Z.db.autoRes, Z.class, Z.db.enemyGuard = old.res, old.class, old.guard
  Z:ApplyClicks()
  assert(ok, err)
end)

step("1.40.0 : chiffre du bouclier (meme en combat, cache sans bouclier), boucliers du pretre et du paladin suivis", function()
  local b = Z.buttons[1]
  local old = { text = Z.db.absorbText, shape = Z.db.shape, absorb = Z.db.showAbsorb, class = Z.class }
  local ok, err = pcall(function()
    assert(Z.defaults.absorbText == false, "chiffre du bouclier eteint au depart")
    Z:Refresh()
    assert(not b.absorbSwitch:IsShown(), "chiffre affiche alors qu'il est eteint")
    Z.db.absorbText = true Z:Refresh()
    assert(b.absorbSwitch:IsShown(), "chiffre absent une fois allume")
    -- total du jeu ecrit tel quel, la barre de 0 a 1 le montre
    ABSORB_TOTAL = 1200
    Z.cellUpdates.prediction(b)
    assert(b.absorbText:GetText() == "+1200", "chiffre : " .. tostring(b.absorbText:GetText()))
    assert(b.absorbSwitch:GetValue() == 1200, "barre du chiffre non remplie")
    -- plus de bouclier : la barre se vide (le jeu coupe alors le texte)
    ABSORB_TOTAL = 0
    Z.cellUpdates.prediction(b)
    assert(b.absorbSwitch:GetValue() == 0, "barre du chiffre restee pleine")
    -- en combat : total secret, ecrit sans erreur ni comparaison
    ABSORB_TOTAL = MakeSecret()
    Z.cellUpdates.prediction(b)
    ABSORB_TOTAL = nil
    -- Barre : le texte de vie recule pour laisser la place au chiffre
    Z.db.shape = "BAR" Z:Refresh()
    assert(b.absorbSwitch:IsShown(), "chiffre absent en Barre")
    -- sans bande de bouclier, pas de chiffre
    Z.db.showAbsorb = false Z:Refresh()
    assert(not b.absorbSwitch:IsShown(), "chiffre sans bouclier")
    Z.db.showAbsorb, Z.db.shape = true, old.shape Z:Refresh()
    -- options et recherche
    local labels = table.concat(Z:OptionLabels(), "|")
    assert(labels:find("Chiffre du bouclier", 1, true), "chiffre absent de la recherche")
    -- ancien affichage : ce qui reste de mon bouclier sur son icone, quand l'aura se lit
    Z.class = "PRIEST" Z:BuildData()
    assert(Z.absorbIds[17] and Z.absorbIds[431622], "boucliers du pretre non reconnus")
    AURAS["HELPFUL|PLAYER"] = { { name = "Mot de pouvoir : Bouclier", icon = 1, auraInstanceID = 51, spellId = 17, points = { 950 } } }
    Z:Refresh() FireEvent("UNIT_AURA", "player") RunUpdates()
    local icon = b.hots[1]
    assert(icon and icon:IsShown() and icon.count:GetText() == "950", "reste du bouclier : " .. tostring(icon and icon.count:GetText()))
    -- montant cache : l'icone garde son decompte, rien d'invente
    AURAS["HELPFUL|PLAYER"][1].points = MakeSecret()
    FireEvent("UNIT_AURA", "player") RunUpdates()
    assert(icon.count:GetText() ~= "950", "ancien reste garde")
    AURAS["HELPFUL|PLAYER"][1].spellId = MakeSecret()
    FireEvent("UNIT_AURA", "player") RunUpdates()
    AURAS = {}
    -- sorts suivis : Egide divine, Veille de la Lumiere (et le buff qu'elle laisse), Serment de lumiere
    local function has(list, id) for _, v in ipairs(list) do if v == id then return true end end end
    assert(has(Z.trackedSpells.PRIEST, 431622), "Egide divine non suivie")
    assert(has(Z.trackedSpells.PALADIN, 1310911) and has(Z.trackedSpells.PALADIN, 1328548), "sorts du paladin non suivis")
    assert(has(Z.spellRanks[1310911], 1310909), "buff de Veille de la Lumiere absent des rangs")
  end)
  ABSORB_TOTAL, AURAS = nil, {}
  Z.db.absorbText, Z.db.shape, Z.db.showAbsorb, Z.class = old.text, old.shape, old.absorb, old.class
  Z:BuildData() Z:Refresh()
  assert(ok, err)
end)

step("1.41.0 (C14) : case du placement des elements agrandie a toute la scene, contour d'un pixel", function()
  local old = { shape = Z.db.shape, width = Z.db.width, height = Z.db.height, placement = CopyTable(Z.db.placement) }
  local ok, err = pcall(function()
    Z.db.placement = {}
    Z:OpenPlacement()
    local w = Z:PlacementWindow()
    local cell, stage, margin = w.cell, w.stage, w.STAGE_MARGIN
    for _, shape in ipairs({ "BAR", "TILE", "SQUARE", "BANNER" }) do
      Z.db.shape = shape Z:Refresh() Z:RefreshPlacement()
      local W, H = Z.CellSize()
      local outer = Z.PlacementOuter()
      -- le tour couvre la case, et le marqueur de raid à cheval sur le haut
      assert(outer[1] <= 0 and outer[2] >= W and outer[3] <= 0 and outer[4] > H, shape .. " : marqueur hors du tour")
      local scale, ow, oh = cell:GetScale(), outer[2] - outer[1], outer[4] - outer[3]
      assert(scale * ow <= stage:GetWidth() - 2 * margin + 0.001 and scale * oh <= stage:GetHeight() - 2 * margin + 0.001,
        shape .. " : depasse de la scene")
      assert(math.abs(scale * ow - (stage:GetWidth() - 2 * margin)) < 0.001
        or math.abs(scale * oh - (stage:GetHeight() - 2 * margin)) < 0.001, shape .. " : ne remplit pas la scene")
      -- le tour est au centre de la scène
      local p = cell._points.CENTER
      assert(p[2] == stage and math.abs(p[4] - (W - outer[1] - outer[2]) / 2) < 0.001
        and math.abs(p[5] - (H - outer[3] - outer[4]) / 2) < 0.001, shape .. " : tour pas centre")
      if shape == "TILE" then assert(scale > 3, "Tuile agrandie seulement " .. scale .. " fois") end
    end
    -- contour : un pixel d'écran, quel que soit l'agrandissement
    Z.db.shape = "TILE" Z:Refresh() Z:RefreshPlacement()
    local border = w.highlight.border
    assert(math.abs(border.size * cell:GetScale() - 1) < 0.001, "contour plus epais qu'un pixel")
    -- largeur changée : la case suit
    local before = cell:GetScale()
    Z.db.width = Z.limits.width[2] Z:Refresh() Z:RefreshPlacement()
    assert(cell:GetScale() < before, "largeur changee non suivie")
  end)
  Z.db.shape, Z.db.width, Z.db.height, Z.db.placement = old.shape, old.width, old.height, old.placement
  Z:Refresh()
  local w = Z:PlacementWindow() if w then w:Hide() w:Run("OnHide") end
  assert(ok, err)
end)

step("1.41.0 : afficher ou masquer chaque element dans l'editeur de placement, meme reglage que les options", function()
  local keys = { "showName", "text", "showRole", "showMarker", "showLeader", "showCenter", "lowManaHealers", "showHots",
    "showDebuffs", "bossDebuffs", "showControls", "showDefensives", "missingBuffs", "privateAuras", "manaBars",
    "showAbsorb", "showIncoming", "lowHealth", "showThreat", "showDispel", "showSummonPhase", "readyCheck" }
  local old = { placement = CopyTable(Z.db.placement), shape = Z.db.shape }
  for _, key in ipairs(keys) do old[key] = Z.db[key] end
  local ok, err = pcall(function()
    -- deux nouveaux reglages, allumes au depart, une ligne chacun dans les options
    assert(Z.defaults.showName == true and Z.defaults.showCenter == true, "showName ou showCenter absents")
    Z.db.placement = {} Z.db.shape = "TILE" Z:Refresh()
    Z:OpenPlacement()
    local w = Z:PlacementWindow()
    assert(#w.checks == #Z.placeElements and #w.list == #Z.placeElements, "une case a cocher par element")
    assert(#w.also == 6, "aussi sur la case : six reglages")
    assert(w:GetHeight() <= 600, "fenetre trop haute")
    local function Index(key) for i, e in ipairs(Z.placeElements) do if e[1] == key then return i end end end
    local function Click(check) check:Run("OnClick", "LeftButton") end

    -- masquer : le reglage des options s'eteint, la place et la taille restent, l'element passe en transparence
    Z.SetOffset("role", -3, -2) Z.SetElementSize("role", 130)
    local role = w.checks[Index("role")]
    assert(role.on, "icone de role cochee au depart")
    Click(role)
    assert(Z.db.showRole == false and not role.on, "decocher n'eteint pas showRole")
    assert(w.cell.role:GetAlpha() == 0.25 and w.cell.role:IsShown(), "element masque pas en transparence")
    assert(w.list[Index("role")].label:GetAlpha() < 1, "element masque pas grise dans la liste")
    local x, y = Z.Offset("role")
    assert(x == -3 and y == -2 and Z.GetElementSize("role") == 130, "place ou taille perdues en masquant ")
    Click(role)
    assert(Z.db.showRole == true and w.cell.role:GetAlpha() == 1, "recocher ne rend pas l'element")
    x, y = Z.Offset("role")
    assert(x == -3 and y == -2 and Z.GetElementSize("role") == 130, "place ou taille perdues au retour")

    -- reglages a choix : valeur sans rien, puis le choix d'avant
    Z.db.text = "PERCENT" Z:Refresh()
    Click(w.checks[Index("text")]) assert(Z.db.text == "NONE", "texte de vie pas a Aucun")
    Click(w.checks[Index("text")]) assert(Z.db.text == "PERCENT", "choix d'avant du texte perdu")
    Z.db.lowManaHealers = 30 Z:Refresh()
    Click(w.checks[Index("lowMana")]) assert(Z.db.lowManaHealers == 0, "mana basse pas a Non")
    Click(w.checks[Index("lowMana")]) assert(Z.db.lowManaHealers == 30, "choix d'avant de la mana basse perdu")
    -- masque depuis les options : recoche, la valeur de depart revient
    Z.db.text = "NONE" Z:Refresh()
    assert(not w.checks[Index("text")].on, "case non suivie apres un changement dans les options")
    Click(w.checks[Index("text")]) assert(Z.db.text == "PERCENT" or Z.db.text == Z.defaults.text, "texte de vie non rendu")

    -- options -> editeur : la case suit, dans les deux sens
    Z.db.showMarker = false Z:Refresh()
    assert(not w.checks[Index("marker")].on and w.cell.marker:GetAlpha() == 0.25, "editeur ne suit pas les options")
    Z.db.showMarker = true Z:Refresh()
    assert(w.checks[Index("marker")].on and w.cell.marker:GetAlpha() == 1, "editeur ne suit pas les options (retour)")

    -- nom : masque sur les vraies cases, toujours visible (transparent) sur la case d'exemple
    local b = Z.buttons[1]
    Click(w.checks[Index("name")])
    assert(Z.db.showName == false and not b.name:IsShown(), "nom encore affiche sur la vraie case")
    assert(w.cell.name:IsShown() and w.cell.name:GetAlpha() == 0.25, "nom absent de la case d'exemple")
    local fake = Z.FakeCell(UIParent) Z.DrawFakeCell(fake, 1, true)
    assert(not fake.name:IsShown(), "nom encore affiche en mode test")
    Click(w.checks[Index("name")]) assert(b.name:IsShown(), "nom pas revenu")

    -- icone centrale : plus rien au centre, l'appel compris
    local wasReady = b.readyCheck
    b.readyCheck = true FireEvent("UNIT_PHASE", "player")
    assert(b.center:IsShown(), "appel absent avec l'icone centrale allumee")
    Z.db.showCenter = false Z:Refresh() FireEvent("UNIT_PHASE", "player")
    assert(not b.center:IsShown(), "icone centrale encore affichee")
    Z.db.showCenter = true Z:Refresh() b.readyCheck = wasReady FireEvent("UNIT_PHASE", "player")

    -- aussi sur la case : barre de mana a Personne, puis le choix d'avant
    Z.db.manaBars = "HEALERS" Z:Refresh()
    Click(w.also[1]) assert(Z.db.manaBars == "OFF", "barre de mana pas a Personne")
    Click(w.also[1]) assert(Z.db.manaBars == "HEALERS", "choix d'avant de la barre de mana perdu")
    Click(w.also[5]) assert(Z.db.showThreat == false, "bordure de menace")
    Click(w.also[5]) assert(Z.db.showThreat == true, "bordure de menace (retour)")

    -- tout afficher : chaque element revient, d'un seul changement
    Z.db.showRole, Z.db.showHots, Z.db.privateAuras, Z.db.text, Z.db.showName = false, false, false, "NONE", false
    Z:Refresh()
    local refreshes, refresh = 0, Z.Refresh
    Z.Refresh = function(...) refreshes = refreshes + 1 return refresh(...) end
    w.showAll:Run("OnClick", "LeftButton")
    Z.Refresh = refresh
    assert(refreshes == 1, "tout afficher : " .. refreshes .. " mises a jour au lieu d'une")
    for _, e in ipairs(Z.placeElements) do assert(Z.ElementShown(e[1]), "tout afficher : " .. e[1] .. " encore masque") end
    for _, check in ipairs(w.checks) do assert(check.on, "tout afficher : case non cochee") end
  end)
  for key, value in pairs(old) do Z.db[key] = value end
  Z:Refresh()
  local w = Z:PlacementWindow() if w then w:Hide() w:Run("OnHide") end
  assert(ok, err)
end)

step("1.41.1 : la place d'un element masque profite aux autres, plafond a 300 %, Remplir la place", function()
  local keys = { "shape", "showRole", "showLeader", "missingBuffs", "showHots", "showDebuffs", "hotStyle", "manaBars", "width", "height" }
  local old = { placement = CopyTable(Z.db.placement) }
  for _, key in ipairs(keys) do old[key] = Z.db[key] end
  local ok, err = pcall(function()
    assert(Z.limits.placement.size[2] == 300, "plafond pas a 300 %")
    Z.db.placement = {} Z.db.hotStyle = "ICONS"
    Z.db.showRole, Z.db.missingBuffs, Z.db.showHots, Z.db.showDebuffs = true, true, true, true
    Z:ApplyShape("TILE")

    -- Tuile : la rangee de mes soins s'arrete a l'icone de role ; masquee, elle va jusqu'au bord
    Z.SetElementSize("hots", 300)
    local rows = Z.AuraRows()
    assert(rows.hots.blocker == "ROLE", "obstacle de mes soins : " .. tostring(rows.hots.blocker))
    local before = rows.hots.size
    Z.db.showRole = false Z:Refresh()
    -- C34 : la ligne s'arrête aussi au chef de groupe, à gauche du rôle
    assert(Z.AuraRows().hots.blocker == "ROLE", "chef de groupe oublie par la rangee de mes soins")
    Z.db.showLeader = false Z:Refresh()
    rows = Z.AuraRows()
    assert(rows.hots.size > before and rows.hots.blocker == nil, "role masque : mes soins n'ont pas grandi " .. before .. " -> " .. rows.hots.size)
    assert(Z.buttons[1].rows.hots.size == rows.hots.size, "vraie case qui ne suit pas")
    Z.db.showRole, Z.db.showLeader = true, true Z:Refresh()
    assert(Z.AuraRows().hots.size == before, "role revenu : la place n'est pas rendue")
    -- affaiblissements et buff manquant
    Z.SetElementSize("debuffs", 300)
    rows = Z.AuraRows()
    if rows.debuffs.blocker == "BUFF" then
      before = rows.debuffs.size
      Z.db.missingBuffs = false Z:Refresh()
      assert(Z.AuraRows().debuffs.size > before, "buff masque : les affaiblissements n'ont pas grandi")
      Z.db.missingBuffs = true Z:Refresh()
    end

    -- Bandeau : les deux rangees se partagent la hauteur ; seule, une rangee la prend toute (au-dela de 110 %)
    Z.db.placement = {} Z:ApplyShape("BANNER")
    Z.SetElementSize("hots", 300)
    rows = Z.AuraRows()
    assert(rows.hots.blocker == "DEBUFFS", "obstacle en Bandeau : " .. tostring(rows.hots.blocker))
    before = rows.hots.size
    local shared = Z.FillSize("hots")
    Z.db.showDebuffs = false Z:Refresh()
    rows = Z.AuraRows()
    assert(rows.hots.size > before and rows.hots.blocker == nil, "rangee seule : pas toute la hauteur")
    assert(Z.FillSize("hots") > math.max(110, shared), "rangee seule bloquee a " .. Z.FillSize("hots") .. " %")
    -- le nom prend la place de l'icone de role masquee (et du badge du chef, pose sur son coin)
    local nameX, nameW = rows.homes.name.x, rows.homes.name.w
    Z.db.showRole = false Z:Refresh()
    assert(Z.AuraRows().homes.name.x == nameX, "nom sous le badge du chef")
    Z.db.showLeader = false Z:Refresh()
    rows = Z.AuraRows()
    assert(rows.homes.name.x < nameX and rows.homes.name.w > nameW, "nom qui ne prend pas la place de l'icone de role")
    Z.db.showRole, Z.db.showLeader, Z.db.showDebuffs = true, true, true Z:Refresh()

    -- 300 % toujours borne par la case
    Z.SetElementSize("center", 300)
    local W, H = Z.CellSize()
    assert(Z.ElementSize("center", Z.IconSize() + 8) <= math.min(W, H), "300 % hors de la case")

    -- Remplir la place : plus petite taille qui atteint le plus grand, et le message de l'obstacle
    Z.db.placement = {} Z:ApplyShape("TILE")
    local L = Z.L
    Z:OpenPlacement()
    local w = Z:PlacementWindow()
    local function Pick(key) for _, button in ipairs(w.list) do if button.key == key then button:Run("OnClick") end end end
    Pick("name")
    assert(w.fill:GetAlpha() < 1, "remplir la place permis pour le nom")
    Pick("hots")
    assert(w.fill:GetAlpha() == 1, "remplir la place grise pour mes soins")
    local fill = Z.FillSize("hots")
    w.fill:Run("OnClick", "LeftButton")
    assert(Z.GetElementSize("hots") == fill, "remplir la place : " .. Z.GetElementSize("hots") .. " au lieu de " .. fill)
    local most = Z.AuraRows().hots.size
    Z.SetElementSize("hots", fill - 10) assert(Z.AuraRows().hots.size < most, "pas la plus petite taille utile")
    Z.SetElementSize("hots", fill)
    assert(w.size:GetText() == Z.PlacementFullText("hots", fill), "message de remplir la place")
    assert(w.size:GetText():find(L["Au plus grand : %d %%. L'icône de rôle bloque : décochez-la pour lui laisser sa place."]:format(fill), 1, true),
      "obstacle non nomme : " .. w.size:GetText())
    Pick("marker")
    w.fill:Run("OnClick", "LeftButton")
    assert(w.size:GetText():find(L["Au plus grand pour cette case : %d %%"]:format(Z.GetElementSize("marker")), 1, true), "marqueur : la case bloque")
  end)
  for key, value in pairs(old) do Z.db[key] = value end
  Z:Refresh()
  local w = Z:PlacementWindow() if w then w:Hide() w:Run("OnHide") end
  assert(ok, err)
end)

step("1.42.0 : mes recharges sous les cadres, trait de canalisation sur la case soignee", function()
  local set = Z:ClickSet()
  local old = { clicks = Z.db.clicks[set], keys = Z.db.hoverKeys[set], variants = (Z.db.clickVariants or {})[set],
    panel = Z.db.cooldownPanel, show = Z.db.cooldownShow, ignored = Z.db.cooldownIgnored, mark = Z.db.channelMark,
    name = C_Spell.GetSpellName, info = C_Spell.GetSpellInfo, known = C_SpellBook.IsSpellKnown, class = Z.class,
    block = Z.BuffBlock }
  local extra = { [402261] = "Pénitence", [13908] = "Prière du désespoir", [14751] = "Focalisation intérieure" }
  local BASE = { [402261] = 12000, [401859] = 10000, [6346] = 30000, [10060] = 180000, [13908] = 600000, [17] = 4000 }
  local COOL, SECRET_CD = {}, false
  local ok, err = pcall(function()
    assert(Z.defaults.cooldownPanel == false and Z.defaults.cooldownShow == "ALL" and Z.defaults.channelMark == true, "departs")
    assert(Z.notInProfile.cooldownPanel and Z.notInProfile.cooldownIgnored, "hors profil comme la recharge globale")
    Z.class = "PRIEST"
    C_Spell.GetSpellName = function(id) return extra[id] or old.name(id) end
    C_Spell.GetSpellInfo = function(spell)
      for id, n in pairs(extra) do if spell == id or spell == n then return { name = n, spellID = id } end end
      return old.info(spell)
    end
    C_SpellBook.IsSpellKnown = function(id) if id == 14751 then return false end return extra[id] ~= nil or old.known(id) end
    rawset(_G, "GetSpellBaseCooldown", function(id) return BASE[id] or 0 end)
    C_Spell.GetSpellCooldown = function(id)
      if SECRET_CD then return { isActive = MakeSecret(), isOnGCD = MakeSecret(), startTime = MakeSecret(), duration = MakeSecret() } end
      if COOL[id] then return { isActive = true, isOnGCD = false, startTime = NOW - 2, duration = 12 } end
      return { isActive = false, isOnGCD = false, startTime = 0, duration = 0 }
    end
    Z.db.clicks[set] = { ["1"] = "Soins rapides", ["ctrl-1"] = "Prière de guérison", ["shift-2"] = "Mot de pouvoir : Bouclier" }
    Z.db.hoverKeys[set] = {}
    Z:GetVariants()["shift-2"] = { tank = "Pénitence" }
    Z.db.cooldownIgnored = {}

    -- la liste : raccourcis a recharge (pas Soins rapides), puis les gros sorts connus de Data.lua
    local list = Z.CooldownList()
    local names = {}
    for _, e in ipairs(list) do names[#names + 1] = e.name end
    assert(table.concat(names, ",") == "Prière de guérison,Mot de pouvoir : Bouclier,Pénitence,Gardien de peur,Infusion de puissance,Prière du désespoir",
      "liste : " .. table.concat(names, ","))
    assert(list[1].keys[1] == Z:ClickLabel("ctrl-1"), "raccourci de Priere de guerison")
    assert(list[3].keys[1]:find(Z.L["Sur un tank"], 1, true), "variante tank de Penitence")
    Z.db.cooldownIgnored = { ["Gardien de peur"] = true }
    for _, e in ipairs(Z.CooldownList()) do assert(e.name ~= "Gardien de peur", "sort ecarte encore montre") end

    -- eteint au depart : rien ; allume : une icone par sort
    Z:Refresh()
    local row = Z:CooldownRow()
    assert(not row or not row:IsShown(), "rangee visible reglage eteint")
    Z.db.cooldownPanel = true Z:Refresh()
    local row, icons, spells = Z:CooldownRow()
    assert(row:IsShown() and #spells == 5, "rangee : " .. tostring(#spells))
    for i = 1, 5 do assert(icons[i]:IsShown() and icons[i].cooling == false and icons[i].icon:GetAlpha() == 1, "icone " .. i) end

    -- un sort qui recharge : grise ; recharge cachee par le jeu : l'icone reste nette
    COOL[402261] = true
    FireEvent("SPELL_UPDATE_COOLDOWN")
    assert(icons[3].cooling == true and icons[3].icon:GetAlpha() < 1, "Penitence pas grisee")
    SECRET_CD = true
    FireEvent("SPELL_UPDATE_COOLDOWN")
    assert(icons[3].cooling == nil and icons[3].icon:GetAlpha() == 1 and icons[3]:IsShown(), "secret : icone cachee ou grisee")
    SECRET_CD = false
    FireEvent("SPELL_UPDATE_COOLDOWN")

    -- en recharge seulement : la seule icone qui recharge ; plus rien : rangee cachee
    Z.db.cooldownShow = "COOLING" Z:Refresh()
    assert(row:IsShown() and icons[3]:IsShown() and not icons[1]:IsShown(), "seulement les recharges")
    COOL[402261] = nil
    icons[3].cd:Run("OnCooldownDone")
    assert(not row:IsShown(), "rangee restee sans recharge")
    Z.db.cooldownShow = "ALL" Z:Refresh()

    -- infobulle Mes clics : le sort en recharge porte ses secondes
    COOL[401859] = true
    local found
    for _, line in ipairs(Z:ClickSummary()) do if line[2] == "Prière de guérison" then found = line end end
    assert(found and found.cooldown and math.abs(found.cooldown - 10) < 0.01, "secondes dans Mes clics")
    COOL[401859] = nil

    -- en combat : liste gardee, refaite a la fin du combat
    COMBAT = true
    Z.db.cooldownIgnored = {}
    FireEvent("SPELLS_CHANGED")
    assert(#select(3, Z:CooldownRow()) == 5, "liste refaite en combat")
    COMBAT = false
    FireEvent("PLAYER_REGEN_ENABLED")
    assert(#select(3, Z:CooldownRow()) == 6, "liste pas refaite apres le combat")

    -- sous le bandeau des buffs manquants quand il est du meme cote
    local fake = CreateFrame("Frame", nil, UIParent)
    fake.where = row.where
    Z.BuffBlock = function() return fake end
    Z.PlaceCooldowns()
    assert(row._point[2] == fake, "rangee pas collee au bandeau")
    fake:Hide()
    Z.PlaceCooldowns()
    assert(row._point[2] ~= fake, "rangee collee a un bandeau cache")
    Z.BuffBlock = old.block

    -- trait de canalisation : sur la case cliquee, pas pour un soin sans cible, pas sur un ennemi, pas eteint
    local b
    for _, button in ipairs(Z.buttons) do if button.unit and not b then b = button end end
    local CHANNEL, ENEMY = 402261, false
    rawset(_G, "UnitChannelInfo", function() return "x", "", 1, NOW * 1000, (NOW + 2) * 1000, false, false, CHANNEL end)
    rawset(_G, "UnitCanAttack", function() return ENEMY end)
    b:Run("OnClick", "LeftButton")
    FireEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    assert(Z.ChannelCell() == b and b.channel:IsShown(), "pas de trait sur la case cliquee")
    FireEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    assert(Z.ChannelCell() == nil and not b.channel:IsShown(), "trait reste apres la canalisation")
    CHANNEL = 596 -- Priere de soins : sans cible
    b:Run("OnClick", "LeftButton")
    FireEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    assert(Z.ChannelCell() == nil, "trait pour un soin sans cible")
    CHANNEL, ENEMY = 402261, true
    b:Run("OnClick", "LeftButton")
    FireEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    assert(Z.ChannelCell() == nil, "trait sur un ennemi")
    ENEMY = false
    b:Run("OnClick", "LeftButton")
    NOW = NOW + 1 -- canalisation sans clic juste avant (barre d'action)
    FireEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    assert(Z.ChannelCell() == nil, "trait sans clic sur la case")
    Z.db.channelMark = false
    b:Run("OnClick", "LeftButton")
    FireEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    assert(Z.ChannelCell() == nil, "trait reglage eteint")
    FireEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
  end)
  Z.db.clicks[set], Z.db.hoverKeys[set] = old.clicks, old.keys
  Z:GetVariants()["shift-2"] = old.variants and old.variants["shift-2"] or nil
  Z.db.cooldownPanel, Z.db.cooldownShow, Z.db.cooldownIgnored, Z.db.channelMark = old.panel, old.show, old.ignored, old.mark
  C_Spell.GetSpellName, C_Spell.GetSpellInfo, C_SpellBook.IsSpellKnown, Z.class, Z.BuffBlock = old.name, old.info, old.known, old.class, old.block
  C_Spell.GetSpellCooldown = nil
  rawset(_G, "GetSpellBaseCooldown", nil) rawset(_G, "UnitChannelInfo", nil) rawset(_G, "UnitCanAttack", nil)
  COMBAT = false
  Z:ApplyClicks()
  Z:Refresh()
  assert(ok, err)
end)

step("1.42.1 : recharges du groupe, partage de mes recharges, messages bloques", function()
  local old = { name = C_Spell.GetSpellName, known = C_SpellBook.IsSpellKnown, class = Z.class, after = C_Timer.After,
    lockdown = C_ChatInfo.InChatMessagingLockdown, grouped = GROUPED, raid = RAID, now = NOW,
    group = Z.db.groupCooldowns, share = Z.db.cooldownShare, sync = Z.db.syncEnabled, ignored = Z.db.cooldownIgnored,
    durations = Z.db.cooldownDurations, panel = Z.db.cooldownPanel }
  local extra = { [29166] = "Innervation", [20484] = "Renaissance", [740] = "Tranquillité", [10060] = "Infusion de puissance",
    [6346] = "Gardien de peur", [633] = "Imposition des mains" }
  local BASE = { [29166] = 360000, [20484] = 1800000, [740] = 600000 }
  local COOL = {}
  local LOCKED = false
  local ok, err = pcall(function()
    assert(Z.defaults.groupCooldowns == false and Z.defaults.cooldownShare == false, "departs")
    assert(Z.notInProfile.groupCooldowns and Z.notInProfile.cooldownShare, "hors profil")
    for class, list in pairs(Z.groupCooldowns) do
      for _, id in ipairs(list) do
        local found = false
        for _, big in ipairs(Z.cooldownSpells[class] or {}) do if big == id then found = true end end
        assert(found, "sort du groupe absent de Z.cooldownSpells : " .. id)
      end
    end
    C_Spell.GetSpellName = function(id) return extra[id] or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return id == 29166 or id == 20484 or old.known(id) end
    rawset(_G, "GetSpellBaseCooldown", function(id) return BASE[id] or 0 end)
    C_Spell.GetSpellCooldown = function(id)
      local c = COOL[id]
      if c == "secret" then return { isActive = MakeSecret(), isOnGCD = MakeSecret(), startTime = MakeSecret(), duration = MakeSecret() } end
      if c then return { isActive = true, isOnGCD = false, startTime = NOW - 10, duration = c } end
      return { isActive = false, isOnGCD = false, startTime = 0, duration = 0 }
    end
    C_ChatInfo.InChatMessagingLockdown = function() return LOCKED end
    local queued = {}
    C_Timer.After = function(s, f) if s <= 1 then f() else queued[#queued + 1] = f end end
    local function Msg(text, sender) FireEvent("CHAT_MSG_ADDON", "Lyorune", text, "PARTY", sender) end
    local function Last() local m = ADDON_SENT[#ADDON_SENT] return m and m.text end
    Z.class = "DRUID"
    Z.db.syncEnabled, Z.db.cooldownShare, Z.db.groupCooldowns, Z.db.cooldownIgnored, Z.db.cooldownDurations = true, true, false, {}, nil
    Z.db.cooldownPanel = false
    GROUPED, RAID = true, false
    NOW = NOW + 100

    -- 1. partage : mon etat complet part (sorts connus seulement, Tranquillite inconnue)
    local first = #ADDON_SENT + 1
    Z:Refresh()
    NOW = NOW + 20
    Z.GroupCooldownSendFull()
    assert(Last() == "K:+20484=0/1800,29166=0/360", "etat complet : " .. tostring(Last()))
    -- au plus une fois toutes les 10 secondes : reporte, puis part
    local n = #ADDON_SENT
    Z.GroupCooldownSendFull() Z.GroupCooldownSendFull()
    assert(#ADDON_SENT == n and #queued == 1, "etat complet repete sans attendre")
    queued[1]() queued = {}
    assert(#ADDON_SENT == n + 1, "etat reporte jamais parti")

    -- 2. un sort lance : « lance » avec sa duree, puis « pret » quand la recharge finit (pas juste apres le sort)
    COOL[29166] = 300
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 29166)
    assert(Last() == "K:29166=360/360", "sort lance : " .. tostring(Last()))
    FireEvent("SPELL_UPDATE_COOLDOWN")
    assert(Z.db.cooldownDurations[29166] == 300, "duree reelle pas apprise")
    COOL[29166] = nil
    n = #ADDON_SENT
    FireEvent("SPELL_UPDATE_COOLDOWN")
    assert(#ADDON_SENT == n, "pret annonce juste apres le sort")
    NOW = NOW + 5
    FireEvent("SPELL_UPDATE_COOLDOWN")
    assert(Last() == "K:29166=0/300", "pret : " .. tostring(Last()))
    -- en combat, recharge cachee : le reste se deduit de mon sort
    COOL[20484] = "secret"
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 20484)
    NOW = NOW + 30
    assert(Z.GroupCooldownEntry(20484) == "20484=1770/1800", "reste deduit : " .. tostring(Z.GroupCooldownEntry(20484)))
    COOL[20484] = nil

    -- 3. messages bloques : rien ne part, l'etat complet part a la fin
    LOCKED = true
    n = #ADDON_SENT
    COOL[29166] = 300
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 29166)
    assert(#ADDON_SENT == n, "message envoye pendant le blocage")
    LOCKED = false
    NOW = NOW + 20
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED")
    assert(Last() and Last():match("^K:%+20484=%d+/1800,29166=%d+/300$"), "etat apres le blocage : " .. tostring(Last()))
    COOL[29166] = nil

    -- 4. le panneau : eteint, rien n'est garde ; allume, il redemande les recharges
    Msg("K:+29166=0/360", "Joueur-party2")
    local panel, lines, players = Z:GroupCooldownPanel()
    assert(not next(players), "garde sans le panneau")
    n = #ADDON_SENT
    Z.db.groupCooldowns = true Z:Refresh()
    assert(ADDON_SENT[n + 1] and ADDON_SENT[n + 1].text == "K:?", "pas de demande en allumant")
    -- une demande d'un autre : mon etat part
    NOW = NOW + 20 n = #ADDON_SENT
    Msg("K:?", "Joueur-party2")
    assert(#ADDON_SENT == n + 1 and Last():match("^K:%+"), "demande sans reponse")

    -- 5. reception : une ligne par sort, pret net, en recharge pale avec ses secondes
    Msg("K:+29166=0/360,20484=600/1800", "Joueur-party2")
    Msg("K:29166=120/360", "Joueur-party3")
    panel, lines, players = Z:GroupCooldownPanel()
    assert(panel and panel:IsShown(), "panneau cache")
    local shown = 0
    for _, line in ipairs(lines) do if line:IsShown() then shown = shown + 1 end end
    assert(shown == 2, "lignes : " .. shown)
    -- ordre des classes puis de Data.lua : Renaissance puis Innervation (druide), joueurs par nom
    local inner = lines[2]
    assert(inner.entries[1].who == "Joueur" and inner.entries[2].who == "Joueur", "noms")
    local readyCount, coolingCount = 0, 0
    for _, line in ipairs(lines) do
      for _, e in ipairs(line.entries) do
        if e:IsShown() then
          if e.clock:IsShown() then coolingCount = coolingCount + 1 else readyCount = readyCount + 1 end
        end
      end
    end
    assert(readyCount == 1 and coolingCount == 2, "pret " .. readyCount .. ", en recharge " .. coolingCount)
    -- etat complet : remplace ; mise a jour : complete
    Msg("K:+29166=0/360", "Joueur-party2")
    assert(players[Z.CommKey("Joueur-party2")].spells[20484] == nil, "etat complet sans remplacer")
    Msg("K:20484=0/1800", "Joueur-party2")
    assert(players[Z.CommKey("Joueur-party2")].spells[20484], "mise a jour perdue")
    -- messages abimes, sort hors liste, etranger, moi-meme : rien
    Msg("K:+99999=0/10", "Joueur-party2") Msg("K:+29166=900/360", "Joueur-party2") Msg("K:+abc", "Joueur-party2")
    Msg("K:+29166=0/360", "Inconnu") Msg("K:+29166=0/360", UnitName("player"))
    assert(players[Z.CommKey("Joueur-party2")].spells[20484], "message abime pris")
    assert(not players[Z.CommKey("Inconnu")] and not players[Z.CommKey(UnitName("player"))], "etranger ou moi pris")
    -- sort ecarte par son nom : sa ligne part
    Z.db.cooldownIgnored = { ["Renaissance"] = true }
    Z.DrawGroupCooldowns()
    shown = 0
    for _, line in ipairs(lines) do if line:IsShown() then shown = shown + 1 end end
    assert(shown == 1, "sort ecarte encore montre")
    Z.db.cooldownIgnored = {}
    -- blocage : le titre le dit
    LOCKED = true
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED")
    local title = select(4, Z:GroupCooldownPanel()):GetText()
    assert(title and title:find(Z.L["(avant le boss)"], 1, true), "titre pendant le blocage : " .. tostring(title))
    LOCKED = false
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED")
    -- « K:- » : le joueur part du panneau ; groupe quitte : tout s'efface
    Msg("K:-", "Joueur-party3")
    assert(not players[Z.CommKey("Joueur-party3")], "K:- ignore")
    GROUPED = false
    FireEvent("GROUP_ROSTER_UPDATE")
    assert(not next(players) and not panel:IsShown(), "groupe quitte : panneau reste")
    -- groupe rejoint : mon etat part
    GROUPED = true NOW = NOW + 20 n = #ADDON_SENT
    FireEvent("GROUP_ROSTER_UPDATE")
    local joined = false
    for i = n + 1, #ADDON_SENT do if ADDON_SENT[i].text:match("^K:%+") then joined = true end end
    assert(joined, "groupe rejoint sans annonce")

    -- 6. partage coupe : « K:- » part une fois, plus rien ensuite
    n = #ADDON_SENT
    Z.db.cooldownShare = false Z:Refresh()
    assert(Last() == "K:-", "arret du partage pas annonce")
    n = #ADDON_SENT
    COOL[29166] = 300
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 29166)
    assert(#ADDON_SENT == n, "partage coupe : message parti")
  end)
  C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, Z.class, C_Timer.After = old.name, old.known, old.class, old.after
  C_ChatInfo.InChatMessagingLockdown, GROUPED, RAID, NOW = old.lockdown, old.grouped, old.raid, old.now
  Z.db.groupCooldowns, Z.db.cooldownShare, Z.db.syncEnabled, Z.db.cooldownIgnored = old.group, old.share, old.sync, old.ignored
  Z.db.cooldownDurations, Z.db.cooldownPanel = old.durations, old.panel
  C_Spell.GetSpellCooldown = nil
  rawset(_G, "GetSpellBaseCooldown", nil)
  FireEvent("GROUP_ROSTER_UPDATE")
  Z:Refresh()
  assert(ok, err)
end)

step("1.43.0 : secondes des affaiblissements, Longanimite au bout des soins du paladin, icone et lisere du type", function()
  local old = { create = CreateFrame, name = C_Spell.GetSpellName, class = Z.class, placement = CopyTable(Z.db.placement) }
  local form = {}
  for _, key in ipairs({ "shape", "debuffCountdown", "lockoutCountdown", "dispelIcon", "showDispel", "showDebuffs",
    "debuffMode", "showHots", "showLockouts", "bossDebuffs" }) do form[key] = Z.db[key] end
  local made = {}
  local ok, err = xpcall(function()
    assert(Z.defaults.debuffCountdown == true and Z.defaults.lockoutCountdown == true and Z.defaults.dispelIcon == true,
      "reglages allumes au depart")
    -- 1. Longanimite : au bout des soins du paladin, jamais dans la rangee des affaiblissements
    C_Spell.GetSpellName = function(id) if id == 25771 then return "Longanimité" end return old.name(id) end
    Z.class = "PALADIN" Z:BuildData()
    assert(Z.lockoutIds[25771] and Z.ShowsLockouts(), "Longanimite non suivie pour le paladin")
    assert(not Z.ignoredDebuffs[25771], "Longanimite encore ignoree (1.51.0 : montree a toutes les classes)")
    Z.class = "PRIEST" Z:BuildData()
    assert(not Z.lockoutIds[25771] and Z.lockoutIds[6788], "pretre : Ame affaiblie seulement")

    -- 2. Ancien affichage : secondes sur les affaiblissements, icone du type, lisere colore
    Z.db.placement = {}
    Z:ApplyShape("TILE")
    local b = Z.buttons[1]
    AURAS = {}
    AURAS["HARMFUL"] = { { name = "Mot de l'ombre : Douleur", icon = 1, auraInstanceID = 71, spellId = 589, dispelName = "Magic" } }
    AURAS[Z.DISPEL_MINE] = AURAS["HARMFUL"]
    Z.db.showDebuffs, Z.db.showDispel, Z.db.dispelIcon, Z.db.debuffCountdown = true, true, true, true
    Z:Refresh() Z.UpdateAurasNow(b)
    assert(b.dispelTypeIcon and b.dispelTypeIcon:IsShown(), "icone du type absente")
    local atlas
    b.dispelTypeIcon.texture.SetAtlas = function(_, a) atlas = a end
    local hidden
    b.debuffs[1].cooldown.SetHideCountdownNumbers = function(_, h) hidden = h end
    Z.UpdateAurasNow(b)
    assert(atlas == "RaidFrame-Icon-DebuffMagic", "image du type : " .. tostring(atlas))
    assert(hidden == false, "secondes cachees sur l'affaiblissement")
    assert(b.debuffs[1].border.color[3] == 1, "lisere pas a la couleur du type")
    -- type secret (combat) : rien d'invente
    AURAS["HARMFUL"][1].dispelName = MakeSecret()
    Z.UpdateAurasNow(b)
    assert(not b.dispelTypeIcon:IsShown(), "type secret : icone montree")
    AURAS["HARMFUL"][1].dispelName = "Magic"
    Z.db.debuffCountdown, Z.db.dispelIcon = false, false
    Z:Refresh() Z.UpdateAurasNow(b)
    assert(hidden == true and not b.dispelTypeIcon:IsShown(), "interrupteurs (ancien affichage)")
    Z.db.debuffCountdown, Z.db.dispelIcon = true, true
    AURAS = {}

    -- 3. Conteneurs du jeu : place fixe du type (style Icon), lisere (PreserveAsset), secondes
    local slots, edges, numbers = {}, {}, {}
    CreateFrame = function(kind, name, parent, template)
      local f = old.create(kind, name, parent, template)
      if kind ~= "AuraContainer" then return f end
      function f:AddAuraGroup(key, filter, options)
        local button = old.create("Button", nil, self)
        button.Edge = old.create("Frame", nil, button):CreateTexture()
        button.Cooldown = { SetHideCountdownNumbers = function(_, h) numbers[key] = not h end }
        function button:AddDispelTypeTexture(tex, o) if tex == self.Edge then edges[key] = o.style end end
        options.initializeFrame(button)
      end
      function f:AddAuraSlot(key, filter, options)
        local button = old.create("Button", nil, self)
        button.Type = old.create("Frame", nil, button):CreateTexture()
        button.Face = { Cooldown = { SetHideCountdownNumbers = function(_, h) numbers[key] = not h end } }
        function button:AddDispelTypeTexture(tex, o) if tex == self.Type then slots[key] = { filter = filter, style = o.style } end end
        options.initializeFrame(button)
        return button
      end
      function f:SetEnabled(on) self.enabled = on end
      function f:SetUnit(unit) self.unit = unit end
      function f:UpdateAllAuras() end
      return f
    end
    AuraContainerSortMethod = { Default = 0 }
    AnchorUtil = { FlowDirection = { Right = 1, Left = 2, Up = 3, Down = 4 }, FlowLayoutAxis = { Horizontal = 1, Vertical = 2 } }
    Enum.CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 1, Icon = 3 }
    Z.db.debuffMode, Z.db.bossDebuffs, Z.db.showHots, Z.db.showLockouts = "ALL", true, true, true
    local c = CreateFrame("Button", "LyoruneHeaderUnitButton43", Z.header)
    Z.header:InitButton(c:GetName())
    made[#made + 1] = c
    c:SetAttribute("unit", "player")
    Z:Refresh()
    assert(slots.dispelType and slots.dispelType.filter == Z.DISPEL_MINE and slots.dispelType.style == 3,
      "place du type absente ou mauvais style")
    assert(edges.dispellable == 1 and edges.others == 1, "lisere du type absent")
    assert(numbers.dispellable and numbers.others and numbers.lockouts and numbers.boss, "secondes absentes")
    assert(not numbers.hots, "secondes de mes soins suivies a tort (hotCountdown eteint)")
    -- interrupteurs : reconstruits sans le type, sans secondes, sans lisere
    slots, edges, numbers = {}, {}, {}
    Z.db.dispelIcon, Z.db.debuffCountdown, Z.db.lockoutCountdown, Z.db.showDispel = false, false, false, false
    Z:Refresh()
    assert(not slots.dispelType and not edges.dispellable, "type ou lisere malgre les interrupteurs")
    assert(not numbers.dispellable and not numbers.lockouts and not numbers.boss, "secondes malgre l'interrupteur")

    -- 4. Placement et options
    assert(Z.IsPlaceElement("dispelType") and Z.IsSizedElement("dispelType"), "element du placement")
    Z.db.dispelIcon = true
    Z:OpenPlacement()
    local w = Z:PlacementWindow()
    assert(w.cell.dispelTypeIcon and w.cell.dispelTypeIcon:IsShown(), "case d'exemple sans icone du type")
    w:Hide() w:Run("OnHide")
    local labels = table.concat(Z:OptionLabels(), "|")
    for _, text in ipairs({ "Secondes restantes", "Icône du type à dissiper", "Ses secondes restantes" }) do
      assert(labels:find(text, 1, true), "option absente : " .. text)
    end
  end, debug.traceback)
  CreateFrame, C_Spell.GetSpellName, Z.class = old.create, old.name, old.class
  AuraContainerSortMethod, AnchorUtil, Enum.CustomAuraButtonDispelTypeTextureStyle = nil, nil, nil
  Z.boxWrap = nil
  for _, c in ipairs(made) do pcall(c.SetAttribute, c, "unit", nil) end
  for key, value in pairs(form) do Z.db[key] = value end
  Z.db.placement = old.placement
  AURAS = {}
  Z:BuildData() Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("1.43.1 : mode Utiles des affaiblissements, liste a mettre en avant en tete, liens de sorts et etat", function()
  Z.db.shownDebuffs = { [6788] = false, [25771] = false } Z.shownCache = nil -- (Toujours montres : essayes a part, 1.51.0)
  local old = { create = CreateFrame, auraIds = Z.db.auraIds, important = Z.db.importantNames, ignored = Z.db.ignoredNames }
  local form = {}
  for _, key in ipairs({ "debuffMode", "dispelCount", "debuffCount", "showDebuffs", "showDispel", "bossDebuffs",
    "importantGlow", "showControls" }) do form[key] = Z.db[key] end
  local made = {}
  local ok, err = xpcall(function()
    -- 1. Trois choix, places de la rangee
    local values = {}
    for _, c in ipairs(Z.choices.debuffMode) do values[#values + 1] = c[1] end
    assert(table.concat(values, ",") == "ALL,USEFUL,DISPEL", "choix du mode : " .. table.concat(values, ","))
    Z.db.importantNames, Z.db.ignoredNames, Z.db.auraIds = {}, {}, {}
    Z.db.dispelCount, Z.db.debuffCount = 2, 3
    Z.db.debuffMode = "ALL" assert(Z.DebuffSlots() == 4, "places (Tous)")
    Z.db.debuffMode = "USEFUL" assert(Z.DebuffSlots() == 4, "places (Utiles)")
    Z.db.debuffMode = "DISPEL" assert(Z.DebuffSlots() == 2, "places (Ceux que je dissipe)")
    Z.db.importantNames = { X = true } assert(Z.DebuffSlots() == 3, "une place de plus pour ma liste")
    Z.db.importantNames = { X = true, Y = true, ["5"] = true } assert(Z.DebuffSlots() == 4, "deux places au plus pour ma liste")
    Z.db.importantNames = {}

    -- 2. Lien de sort : nom garde, numero retenu, etat reconnu
    local link = "|cff71d5ff|Hspell:424242:0|h[Peste noire]|h|r"
    local name, id = Z.SpellFromLink(link)
    assert(name == "Peste noire" and id == 424242, "lien mal lu")
    assert(Z.SpellFromLink("Peste noire") == nil, "un nom n'est pas un lien")
    assert(not Z.KnownAuraIds("Peste noire"), "reconnu avant le lien")
    assert(Z.AddToList("importantNames", link) == "Peste noire" and Z.db.importantNames["Peste noire"], "lien non ajoute")
    assert(Z.KnownAuraIds("Peste noire") and Z.db.auraIds["Peste noire"][424242], "numero du lien non retenu")
    assert(Z.KnownAuraIds("777"), "un numero tape est reconnu")
    Z.AddToList("ignoredNames", "Peste noire") -- par erreur dans les deux listes : ma liste gagne

    -- 3. Ancien affichage : ma liste en tete, Utiles sans Deserteur, Ceux que je dissipe
    local b = Z.buttons[1]
    AURAS = {}
    local listed = { name = "Peste noire", icon = 1, auraInstanceID = 81, spellId = 424242, duration = 30 }
    local long = { name = "Malédiction lente", icon = 2, auraInstanceID = 82, spellId = 99002, duration = 900 }
    local short = { name = "Brûlure", icon = 3, auraInstanceID = 83, spellId = 9001, duration = 12 }
    local secret = { name = MakeSecret(), icon = 4, auraInstanceID = 84, spellId = MakeSecret(), duration = MakeSecret() }
    AURAS["HARMFUL"] = { long, short, listed, secret }
    Z.db.showDebuffs, Z.db.dispelCount, Z.db.debuffCount = true, 1, 5
    local function icons()
      local list = {}
      for i = 1, #b.debuffs do if b.debuffs[i]:IsShown() then list[#list + 1] = b.debuffs[i].texture._tex end end
      return table.concat(list, ",")
    end
    Z.db.debuffMode = "ALL" Z:Refresh() Z.UpdateAurasNow(b)
    assert(icons() == "1,2,3,4", "Tous : " .. icons())
    Z.db.debuffMode = "USEFUL" Z:Refresh() Z.UpdateAurasNow(b)
    assert(icons() == "1,3,4", "Utiles : ma liste, le court, le secret ; pas Deserteur : " .. icons())
    Z.db.debuffMode = "DISPEL" Z:Refresh() Z.UpdateAurasNow(b)
    assert(icons() == "1", "Ceux que je dissipe : ma liste reste montree : " .. icons())
    -- par son numero tape
    Z.db.importantNames = { ["9001"] = true } Z:Refresh() Z.UpdateAurasNow(b)
    assert(icons() == "3", "numero tape non reconnu : " .. icons())
    Z.db.importantNames = { ["Peste noire"] = true }
    AURAS = {}

    -- 4. Conteneurs du jeu : groupe de ma liste en tete, Utiles trie par le jeu et par la duree
    local groups, policy = {}, nil
    CreateFrame = function(kind, fname, parent, template)
      local f = old.create(kind, fname, parent, template)
      if kind ~= "AuraContainer" then return f end
      function f:AddAuraGroup(key, filter, options)
        groups[key] = { filter = filter, candidates = options.candidateFilters, max = options.maxFrameCount,
          index = options.layout.layoutIndex, box = self }
      end
      function f:AddAuraSlot(key, filter, options) return old.create("Button", nil, self) end
      function f:SetAuraProcessingPolicy(p, o) policy = { box = self, p = p, o = o } end
      function f:SetEnabled(on) end
      function f:SetUnit(unit) end
      function f:UpdateAllAuras() end
      return f
    end
    AuraContainerSortMethod = { Default = 0 }
    AnchorUtil = { FlowDirection = { Right = 1, Left = 2, Up = 3, Down = 4 }, FlowLayoutAxis = { Horizontal = 1, Vertical = 2 } }
    AuraUtil = { AuraUpdateChangedType = { Debuff = 7 } }
    CustomAuraContainerAuraProcessingPolicy = { ProcessAura = 2 }
    Enum.CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 1, Icon = 3 }
    Z.db.debuffMode, Z.db.dispelCount, Z.db.debuffCount, Z.db.showControls = "USEFUL", 1, 3, true
    local c = CreateFrame("Button", "LyoruneHeaderUnitButton431", Z.header)
    Z.header:InitButton(c:GetName())
    made[#made + 1] = c
    c:SetAttribute("unit", "player")
    Z:Refresh()
    local row, others = groups.listedRow, groups.others
    assert(row and row.index == 1 and row.max == 1 and row.candidates.includeSpellIDs[424242], "groupe de ma liste absent")
    -- un nom sans numero ne prend pas de place ; un sort bloque de ma liste reste au bout de mes soins
    Z.db.importantNames["Nom jamais vu"] = true
    assert(Z.DebuffPlaces() == 1, "place pour un nom sans numero")
    Z.db.importantNames["Nom jamais vu"] = nil
    -- un sort bloque (Ame affaiblie) mis dans ma liste ne reserve pas de place vide dans la rangee
    local savedLock, savedHots, savedShow = Z.lockoutIds, Z.db.showHots, Z.db.showLockouts
    Z.lockoutIds, Z.db.showHots, Z.db.showLockouts = { [515151] = true }, true, true
    Z.db.importantNames["515151"] = true
    assert(Z.KnownAuraIds("515151") and Z.KnownAuraIds("515151", true) == false, "sort bloque vu comme reconnu")
    assert(Z.DebuffPlaces() == 1, "place vide pour un sort bloque de ma liste")
    Z.db.importantNames["515151"] = nil
    Z.lockoutIds, Z.db.showHots, Z.db.showLockouts = savedLock, savedHots, savedShow
    assert(groups.dispellable.index == 2 and groups.dispellable.candidates.excludeSpellIDs[424242], "doublon avec ceux a dissiper")
    assert(others and others.index == 3 and others.max == 2 and others.candidates.excludeSpellIDs[424242], "groupe des autres")
    assert(others.candidates.maxDuration == 300 and others.candidates.processedAuraType == 7, "Utiles : tri du jeu et duree")
    assert(policy and policy.box == others.box and policy.p == 2 and policy.o.displayOnlyDispellableDebuffs == false,
      "politique du jeu non posee sur la rangee")
    local ctrl = groups.controls.candidates.excludeSpellIDs
    assert(not (ctrl and ctrl[424242]), "ma liste ignoree a tort (A ignorer gagne)")
    -- Tous : ni tri du jeu ni duree ; Ceux que je dissipe : pas d'autres
    groups, policy = {}, nil
    Z.db.debuffMode = "ALL" Z:Refresh()
    assert(groups.others and not groups.others.candidates.maxDuration and not groups.others.candidates.processedAuraType
      and not policy, "Tous trie a tort")
    groups = {}
    Z.db.debuffMode = "DISPEL" Z:Refresh()
    assert(not groups.others and groups.listedRow, "Ceux que je dissipe : autres montres, ou ma liste absente")
    -- client sans politique : la duree seule trie
    groups, policy = {}, nil
    CustomAuraContainerAuraProcessingPolicy = nil
    Z.db.debuffMode = "USEFUL" Z:Refresh()
    assert(groups.others.candidates.maxDuration == 300 and not groups.others.candidates.processedAuraType and not policy,
      "repli sans politique")

    -- 5. Options
    local labels = table.concat(Z:OptionLabels(), "|")
    assert(labels:find("Affaiblissements affichés", 1, true) and labels:find("À mettre en avant", 1, true), "options absentes")
    for _, text in ipairs({ "Utiles", "Ceux que je dissipe", "Reconnu par son numéro : le jeu le trouve aussi en combat." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
  end, debug.traceback)
  CreateFrame = old.create
  AuraContainerSortMethod, AnchorUtil, AuraUtil, CustomAuraContainerAuraProcessingPolicy = nil, nil, nil, nil
  Enum.CustomAuraButtonDispelTypeTextureStyle = nil
  Z.boxWrap = nil
  for _, c in ipairs(made) do pcall(c.SetAttribute, c, "unit", nil) end
  for key, value in pairs(form) do Z.db[key] = value end
  Z.db.auraIds, Z.db.importantNames, Z.db.ignoredNames = old.auraIds, old.important, old.ignored
  AURAS = {}
  Z:BuildData() Z:Refresh() RunUpdates()
  Z.db.shownDebuffs = {} Z.shownCache = nil
  assert(ok, err)
end)

step("1.44.0 : JcJ (ligne Match JcJ, pas d'arene) et partage des recharges eteint au depart", function()
  -- partager mes recharges : eteint au depart ; remis au defaut une fois pour ceux des 1.42.1 a 1.43.1
  assert(Z.defaults.cooldownShare == false, "partage eteint au depart")
  local savedDB, savedChar, version = LyoruneDB, LyoruneCharDB, Z.version
  local fine, why = pcall(function()
    local db = { lastVersion = "1.43.1", cooldownShare = true, autoProfiles = { PRIEST = { ["5"] = "Raid", ARENA = "Arene" } } }
    LyoruneDB = db
    Z.version = "1.44.0" FireEvent("ADDON_LOADED", "Lyorune")
    assert(db.cooldownShare == false, "1.43.1 : partage pas remis au defaut")
    assert(db.autoProfiles.PRIEST.ARENA == nil and db.autoProfiles.PRIEST["5"] == "Raid", "regle Arene effacee, les autres gardees")
    db.lastVersion, db.cooldownShare = "1.44.0", true FireEvent("ADDON_LOADED", "Lyorune")
    assert(db.cooldownShare == true, "choix du joueur ecrase apres la 1.44.0")
    db = { lastVersion = "1.41.0", cooldownShare = true } LyoruneDB = db FireEvent("ADDON_LOADED", "Lyorune")
    assert(db.cooldownShare == true, "avant la 1.42.1 : le reglage n'existait pas, rien a remettre")
  end)
  Z.version = version
  LyoruneDB, LyoruneCharDB = savedDB, savedChar
  FireEvent("ADDON_LOADED", "Lyorune")
  assert(fine, why)
  -- plus de profil Arene
  for _, size in ipairs(Z.profileSizes) do assert(size ~= "ARENA", "profil Arene encore propose") end
  -- match JcJ : restriction du jeu, une ligne dans l'infobulle d'une case
  local saved, oldTypes, add = C_RestrictedActions, Enum.AddOnRestrictionType, GameTooltip.AddLine
  local ok, err = pcall(function()
    local active = false
    Enum.AddOnRestrictionType = oldTypes or { Combat = 0, Encounter = 1, ChallengeMode = 2, PvPMatch = 3 }
    C_RestrictedActions = { IsAddOnRestrictionActive = function(kind) return kind == Enum.AddOnRestrictionType.PvPMatch and active end }
    assert(Z.InPvPMatch() == false, "hors match")
    local b = Z.buttons[1]
    local lines = {}
    GameTooltip.AddLine = function(_, text) lines[#lines + 1] = text end
    b:Run("OnEnter") b:Run("OnLeave")
    assert(not table.concat(lines, ";"):find("Match JcJ", 1, true), "ligne hors match")
    active = true lines = {}
    assert(Z.InPvPMatch() == true, "match")
    b:Run("OnEnter") b:Run("OnLeave")
    assert(table.concat(lines, ";"):find("Match JcJ", 1, true), "ligne Match JcJ absente")
    C_RestrictedActions = nil assert(Z.InPvPMatch() == false, "fonction absente")
  end)
  GameTooltip.AddLine, C_RestrictedActions, Enum.AddOnRestrictionType = add, saved, oldTypes
  assert(ok, err)
end)

step("1.44.1 : C15, buffs manquants en champ de bataille (lecture refusee, nom secret, joueur en combat, /lyorune buffs detaille)", function()
  local old = { isUnit = UnitIsUnit, after = C_Timer.After, secrets = C_Secrets, name = UnitName,
    fight = UnitAffectingCombat, instance = INSTANCE, kind = INSTANCE_TYPE, class = Z.class,
    restricted = C_RestrictedActions, types = Enum.AddOnRestrictionType }
  local ok, err = pcall(function()
    C_Timer.After = function(s, f) if s < 1 then f() end end
    local me = Z.buttons[1]
    local other
    for _, b in ipairs(Z.buttons) do
      if b ~= me and b.unit and not b.extra and b:IsVisible() and not b.unit:find("pet") then other = other or b end
    end
    UnitIsUnit = function(a, b) return a == b or (b == "player" and a == me.unit) end
    local hidden = true
    C_Secrets = { ShouldAurasBeSecret = function() return hidden end, ShouldSpellAuraBeSecret = function() return true end }
    -- le jeu refuse la lecture des auras (mesure publiee pour Forever en match JcJ) : le faux client leve une erreur
    AURAS = setmetatable({}, { __index = function() error("auras secretes") end })
    local function Update() Z:Refresh() RunUpdates() end
    INSTANCE, INSTANCE_TYPE, NOW = true, "pvp", 9000
    Z.db.buffWatch, Z.db.buffRenew, Z.db.buffGroupAt = {}, 0, 99
    Z.db.missingBuffs, Z.db.buffPanel = true, true
    Z.class = "PRIEST" Z:BuildData()
    Update()
    assert(other.buffRead == "refused" and other.missingBuff, "lecture refusee en match : rien ne manque plus")
    assert(#Z.BuffRows() > 0, "panneau vide en match (lecture refusee)")
    -- liste vide mais lisible pendant une restriction (vu par d'autres addons pendant un boss) : elle ne prouve
    -- rien, la memoire de mes sorts tient ; sans restriction, la meme liste vide efface la memoire
    local function Has(b, id) for _, m in ipairs(b.missingBuffs or {}) do if m.check.id == id then return true end end end
    local restricted = true
    Enum.AddOnRestrictionType = Enum.AddOnRestrictionType or { Combat = 0, Encounter = 1, ChallengeMode = 2, PvPMatch = 3 }
    C_RestrictedActions = { IsAddOnRestrictionActive = function(kind) return restricted and kind == Enum.AddOnRestrictionType.PvPMatch end }
    AURAS = {}
    FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(other.unit), "cast-c15", 1243)
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-c15", 1243)
    Update()
    assert(other.buffRead == "restricted" and not Has(other, 1243), "liste vide sous restriction : memoire effacee")
    assert(Z.AurasRestricted(), "restriction non vue")
    restricted = false NOW = NOW + 1 Update() -- (la reponse du jeu est gardee le temps d'une image)
    assert(Has(other, 1243), "liste vide hors restriction : buff non propose")
    C_RestrictedActions = nil
    AURAS = setmetatable({}, { __index = function() error("auras secretes") end })
    -- buff que le jeu laisse lisible, mais lecture refusee : son absence n'est pas sure, la memoire decide
    C_Secrets.ShouldSpellAuraBeSecret = function() return false end
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED", 0, 2)
    FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(other.unit), "cast-c15b", 1243)
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-c15b", 1243)
    Update()
    assert(not Has(other, 1243), "buff lisible, lecture refusee : memoire ignoree")
    C_Secrets.ShouldSpellAuraBeSecret = function() return true end
    FireEvent("ADDON_RESTRICTION_STATE_CHANGED", 0, 2)
    Z.ForgetBuffs(other.unit) -- (comme une mort : la suite repart d'un joueur inconnu)
    Update()
    -- nom secret : le joueur reste au panneau, sous son groupe
    UnitName = function(u) if u == other.unit then return MakeSecret() end return old.name(u) end
    local found
    for _, row in ipairs(Z.BuffRows()) do if row.unit == other.unit then found = row end end
    assert(found and found.name == "Prêtre (Groupe 1)", "nom secret : joueur absent du panneau " .. tostring(found and found.name))
    UnitName = old.name
    -- en combat pendant le match : gardé (la memoire decide) ; hors match, ecarte comme avant
    UnitAffectingCombat = function(u) return u == other.unit end
    found = nil
    for _, row in ipairs(Z.BuffRows()) do if row.unit == other.unit then found = row end end
    assert(found, "joueur en combat ecarte en match")
    -- /lyorune buffs : etat du jeu et raisons, lisibles
    local printed = #PRINTED
    Z.Command("buffs")
    local text = table.concat(PRINTED, "|", printed + 1)
    assert(text:find("état : buffs cachés oui", 1, true) and text:find("refusée", 1, true), "commande detaillee : " .. text)
    -- hors match : une lecture refusee ne propose rien (comme avant)
    hidden = false
    INSTANCE, INSTANCE_TYPE = false, "none"
    Update()
    assert(not other.missingBuff, "lecture refusee hors match : buff propose a tort")
    AURAS = {}
    Update()
    found = nil
    for _, row in ipairs(Z.BuffRows()) do if row.unit == other.unit then found = row end end
    assert(not found, "joueur en combat hors match : plus ecarte")
    for _, key in ipairs({ "oui", "non", "secret", "état : buffs cachés %s, restriction %s, match JcJ %s, partie %s, en combat %s.",
      "cases : %d joueur(s), %d au panneau (dont %d hors de portée), %d mort(s), %d en combat, %d case(s) cachée(s).",
      "lecture : %d refusée(s), %d avec des noms secrets, %d lisible(s) mais sous restriction ; %d nom(s) de joueur secret(s)." }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
  end)
  UnitIsUnit, C_Timer.After, C_Secrets, UnitName = old.isUnit, old.after, old.secrets, old.name
  UnitAffectingCombat, INSTANCE, INSTANCE_TYPE, Z.class = old.fight, old.instance, old.kind, old.class
  C_RestrictedActions, Enum.AddOnRestrictionType = old.restricted, old.types
  AURAS = {}
  Z:BuildData() Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("1.45.0 : Les amis de Lyorune (chiffres, carnet, mot de l'auteur, mur de remerciements)", function()
  local old = { helpful = C_Spell.IsSpellHelpful, class = Z.class, notebook = Z.db.notebook, about = Z.about }
  local ok, err = pcall(function()
    Z.class = "PRIEST" Z:BuildData()
    Z.db.notebook = true Z:RefreshAlerts()
    Z.ResetTally()
    -- un sort offensif (le jeu le dit pas utilisable sur un allie) ne compte pas
    C_Spell.IsSpellHelpful = function(id) return id ~= 139 end -- (Renovation tenue pour offensive)
    for _, id in ipairs({ 2061, 2061, 596, 2006, 1243, 21562, 527, 139 }) do
      FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-" .. id, id)
    end
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-secret", MakeSecret(2061)) -- numero secret : ignore
    local t = Z.Tally()
    assert(t.heals == 3 and t.res == 1 and t.buffs == 2, ("carnet : %d soins, %d res, %d buffs"):format(t.heals, t.res, t.buffs))
    assert(Z.char.tally == t and t.since:match("^%d+%-%d+%-%d+"), "carnet par personnage, avec sa date")
    -- carnet eteint : plus rien n'est compte, les chiffres restent
    Z.db.notebook = false Z:RefreshAlerts()
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-off", 2061)
    assert(Z.Tally().heals == 3, "carnet eteint : soin compte")
    Z.db.notebook = true Z:RefreshAlerts()
    -- la page : douzieme chapitre, chiffres du projet, carnet, mur de remerciements
    Z.about = { date = "2026-11-23", github = 1200, curseforge = 345, discord = 40, names = {} }
    SlashCmdList.LYORUNE("")
    local w = Z:OptionsWindow()
    local page = w.Select("Les amis de Lyorune")
    local numbers, notebook, wall = OptionPart("updates"), OptionPart("tallyRows"), OptionPart("thanks")
    assert(numbers and notebook and wall, "page des amis incomplete")
    numbers:Update()
    assert(numbers.updates.value:GetText() == tostring(#Z.changes), "mises a jour : " .. numbers.updates.value:GetText())
    assert(numbers.downloads.value:GetText() == "1 545" and numbers.discord.value:GetText() == "40", "chiffres : " .. numbers.downloads.value:GetText())
    assert(numbers.when:GetText():find("23/11/2026", 1, true), "date des chiffres")
    assert(numbers.link:GetText() == "discord.gg/uRaEPTGePu", "lien du Discord")
    numbers.link:SetText("efface") numbers.link:Run("OnTextChanged")
    assert(numbers.link:GetText() == "discord.gg/uRaEPTGePu", "lien du Discord modifiable")
    notebook:Update()
    assert(notebook.tallyRows.heals:GetText() == "3" and notebook.tallyRows.buffs:GetText() == "2", "carnet affiche")
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-live", 2061)
    assert(notebook.tallyRows.heals:GetText() == "4", "carnet ouvert : le chiffre ne suit pas")
    notebook.reset:Run("OnClick", "LeftButton")
    assert(Z.Tally().heals == 4, "carnet efface au premier clic")
    notebook.reset.armed = true notebook.reset:Run("OnClick", "LeftButton")
    assert(Z.Tally().heals == 0 and notebook.tallyRows.heals:GetText() == "0", "carnet remis a zero")
    wall:Update()
    assert(wall.thanks:GetText() == "Votre nom ici ?", "mur vide")
    Z.about.names = { "Joueur 1", { name = "Joueur 2", class = "DRUID", mode = "Soins, JcJ" } } -- (noms factices du test)
    wall:Update()
    local text = wall.thanks:GetText()
    assert(text:find("Joueur 1", 1, true) and text:find("Joueur 2", 1, true), "mur des noms")
    assert(text:find("|cff%x%x%x%x%x%xJoueur 2|r") and text:find("Druide, Soins, JcJ", 1, true), "classe et mode : " .. text)
    -- interrupteur du carnet : la page ouverte le dit aussitot
    Z.db.notebook = false Z:RefreshAlerts()
    assert(notebook.since:GetText():find("Carnet éteint", 1, true), "carnet eteint : page pas a jour")
    Z.db.notebook = true Z:RefreshAlerts()
    assert(notebook.since:GetText():find("En tout depuis le", 1, true), "carnet rallume : page pas a jour")
    for _, key in ipairs({ "mises à jour", "téléchargements", "sur le Discord", "Soins lancés", "Buffs posés",
      "Discord de Lyorune (Ctrl+C) :", "Chiffres du %s (GitHub et CurseForge), mis à jour à chaque version de Lyorune.",
      "En tout depuis le %s, aujourd'hui depuis votre connexion, pour ce personnage. Tous vos sorts réussis comptent : cases, barres, macros et touches.",
      "Carnet éteint : plus rien n'est compté, vos chiffres sont gardés.", "Votre nom ici ?" }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
    w:Hide()
  end)
  C_Spell.IsSpellHelpful, Z.class, Z.db.notebook, Z.about = old.helpful, old.class, old.notebook, old.about
  Z:BuildData() Z:RefreshAlerts()
  assert(ok, err)
end)

step("1.46.0 : mes totems sous les cadres, icone de classe", function()
  local old = { class = Z.class, totem = Z.db.totemPanel, icon = Z.db.showClassIcon, cd = Z.db.cooldownPanel, shape = Z.db.shape }
  local TOTEMS, SECRET = {}, false
  local ok, err = pcall(function()
    -- eteints au depart, chacun son interrupteur ; emplacements donnes par Data.lua
    assert(Z.defaults.totemPanel == false and Z.defaults.showClassIcon == false, "eteints au depart")
    assert(Z.notInProfile.totemPanel and not Z.notInProfile.showClassIcon, "totems hors profil comme mes recharges")
    assert(#Z.totemSlots.SHAMAN == 4 and Z.totemSlots.PRIEST == nil, "emplacements")
    rawset(_G, "GetTotemInfo", function(slot)
      if SECRET then return MakeSecret(), MakeSecret(), MakeSecret(), MakeSecret(), MakeSecret() end
      if TOTEMS[slot] then return true, TOTEMS[slot], NOW - 5, 60, 136000 + slot end
      return false, "", 0, 0, nil
    end)
    -- l'objet duree du jeu : present seulement quand un totem est pose, jamais secret
    rawset(_G, "GetTotemDuration", function(slot) return TOTEMS[slot] and { slot = slot } or nil end)
    Z.class, Z.db.cooldownPanel = "SHAMAN", false
    Z.db.totemPanel = false Z:Refresh()
    local row = Z:TotemRow()
    assert(not row or not row:IsShown(), "rangee visible reglage eteint")
    Z.db.totemPanel = true Z:Refresh()
    local row, icons = Z:TotemRow()
    assert(row and not row:IsShown(), "rien de pose : rangee cachee")
    TOTEMS[2] = "Totem de peau de pierre" FireEvent("PLAYER_TOTEM_UPDATE", 2)
    assert(row:IsShown(), "totem pose : rangee visible")
    assert(icons[2].have == true and icons[2]:GetAlpha() == 1 and icons[2].element == "Terre", "emplacement de terre")
    assert(icons[1].have == false and icons[1]:GetAlpha() < 1 and icons[1]:IsShown(), "emplacement vide pale, garde sa place")
    -- en combat, GetTotemInfo est secret : GetTotemDuration decide, sans rien comparer de secret
    SECRET = true FireEvent("PLAYER_TOTEM_UPDATE", 1)
    assert(row:IsShown() and icons[2].have == true and icons[1].have == false and icons[1]:GetAlpha() < 1, "totems secrets")
    TOTEMS = {} FireEvent("PLAYER_TOTEM_UPDATE", 2)
    assert(not row:IsShown(), "en combat sans totem : rangee cachee")
    -- jeu sans GetTotemDuration : GetTotemInfo, un oui secret compte comme pose
    rawset(_G, "GetTotemDuration", nil)
    FireEvent("PLAYER_TOTEM_UPDATE", 1)
    assert(row:IsShown() and icons[1].have == true, "sans objet duree : secret = pose")
    SECRET = false FireEvent("PLAYER_TOTEM_UPDATE", 1)
    assert(not row:IsShown(), "totems partis : rangee cachee")
    -- une classe sans totems : rien, et plus rien n'est ecoute
    TOTEMS[1] = "Totem incendiaire" Z.class = "PRIEST" Z:Refresh()
    FireEvent("PLAYER_TOTEM_UPDATE", 1)
    assert(not row:IsShown(), "pretre : pas de rangee")

    -- icone de classe : l'image du jeu, rien pour une classe secrete ou inconnue
    rawset(_G, "CLASS_ICON_TCOORDS", { PRIEST = { 0.5, 0.75, 0.25, 0.5 }, SHAMAN = { 0.25, 0.5, 0.25, 0.5 } })
    local tex = UIParent:CreateTexture()
    assert(Z.SetClassIcon(tex, "PRIEST") and tex:IsShown(), "pretre")
    assert(not Z.SetClassIcon(tex, MakeSecret()) and not tex:IsShown(), "classe secrete")
    assert(not Z.SetClassIcon(tex, "INCONNUE") and not tex:IsShown(), "classe inconnue")
    Z.class = old.class
    local b = Z.buttons[1]
    Z.db.showClassIcon = false Z:Refresh()
    assert(not b.class:IsShown(), "icone visible reglage eteint")
    Z.db.showClassIcon = true Z:Refresh()
    assert(b.class:IsShown(), "icone de classe sur la case")
    -- element de l'editeur de placement, lie au reglage ; en Barre, le nom part apres elle
    assert(Z.IsPlaceElement("class") and Z.ElementShown("class"), "element de placement")
    Z.ShowElement("class", false)
    assert(Z.db.showClassIcon == false, "case de l'editeur")
    Z.db.shape = "BAR"
    local off = Z.AuraRows()
    Z.db.showClassIcon = true
    local on = Z.AuraRows()
    assert(on.homes.name.x > off.homes.name.x and on.homes.class.x == off.homes.class.x, "nom apres l'icone de classe")
    local typeOn = select(2, Z.DispelTypeHome())
    Z.db.showClassIcon = false
    assert(typeOn > select(2, Z.DispelTypeHome()), "type a dissiper apres l'icone de classe")
    -- Tuile : le type a dissiper passe aussi apres l'icone de classe (meme bord gauche)
    Z.db.shape, Z.db.showClassIcon = old.shape, true
    if not Z:Shape().inline then
      local x = select(2, Z.DispelTypeHome())
      assert(x >= 3 + Z.AuraRows().homes.class.w + 2, "tuile : type a dissiper sur l'icone de classe")
    end
    Z.db.showClassIcon = false
    for _, key in ipairs({ "Icône de classe", "Mes totems (chaman)", "Mes totems", "Emplacement : %s", "Aucun totem posé",
      "Feu", "Terre", "Eau", "Air" }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
  end)
  Z.class, Z.db.totemPanel, Z.db.showClassIcon, Z.db.cooldownPanel, Z.db.shape = old.class, old.totem, old.icon, old.cd, old.shape
  rawset(_G, "GetTotemInfo", nil) rawset(_G, "GetTotemDuration", nil) rawset(_G, "CLASS_ICON_TCOORDS", nil)
  Z:Refresh()
  assert(ok, err)
end)

step("C17 : raid de 40 qui change, cadres replaces une fois, cases toujours placees", function()
  -- Cadres de groupe du jeu simules comme le vrai code (SecureGroupHeaders.lua) : replacement complet a chaque
  -- reglage change tant que le cadre est visible, sauf pendant _ignore ; replacement aussi quand il apparait.
  local old = { raid = RAID, members = MEMBERS, layout = Z.db.layout, shrink = Z.db.autoShrink, after = C_Timer.After,
    refresh = Z.Refresh }
  local updates, whole, fake = 0, {}, {}
  local function Update(h)
    updates = updates + 1
    for i = 1, 1 - (h:GetAttribute("startingIndex") or 1) do -- cases creees d'avance (1.50.1), comme le jeu
      if not h:GetAttribute("child" .. i) then
        h:SetAttribute("child" .. i, CreateFrame("Button", nil, h))
        fake[#fake + 1] = { h, i }
      end
    end
    if h.def.raid and RAID and not h:GetAttribute("groupFilter") and not h:GetAttribute("roleFilter")
      and not h:GetAttribute("nameList") then whole[h.def.raid] = true end -- tout le raid dans un seul cadre
    local i = 1
    while h:GetAttribute("child" .. i) do h:GetAttribute("child" .. i):SetPoint("TOP", h, "TOP") i = i + 1 end
  end
  local raidHeaders = {}
  for _, h in ipairs(Z.headers) do
    if h.def.raid then
      raidHeaders[#raidHeaders + 1] = h
      h:SetScript("OnAttributeChanged", function(self, name)
        if name == "_ignore" or self:GetAttribute("_ignore") then return end
        if self:IsVisible() then Update(self) end
      end)
      h:HookScript("OnShow", Update)
      for i = 1, 5 do -- cinq cases par groupe, comme le jeu les cree
        if not h:GetAttribute("child" .. i) then
          local b = CreateFrame("Button", h:GetName() .. "UnitButton" .. i, h)
          h:SetAttribute("child" .. i, b)
          h:InitButton(b:GetName())
          b:SetAttribute("unit", "raid" .. ((h.def.raid - 1) * 5 + i))
        end
      end
    end
  end
  RAID, MEMBERS = true, 40
  local ok, err = pcall(function()
    local function Placed(label)
      for _, h in ipairs(raidHeaders) do
        if h:IsVisible() then
          for i = 1, 5 do assert(h:GetAttribute("child" .. i)._points, label .. " : case sans place, groupe " .. h.def.raid) end
        end
      end
    end
    -- chaque disposition : un seul replacement par cadre visible, jamais tout le raid dans un cadre de groupe
    for _, layout in ipairs({ "GROUP", "ROLE", "GRID", "GROUP" }) do
      Z.db.layout = layout
      Z:Refresh()
      updates, whole = 0, {}
      Z:Refresh()
      local shown = 0
      for _, h in ipairs(raidHeaders) do if h:IsVisible() then shown = shown + 1 end end
      assert(updates <= shown, layout .. " : " .. updates .. " replacements pour " .. shown .. " cadres")
      assert(not next(whole), layout .. " : un cadre a montre tout le raid")
      Placed(layout)
    end
    -- un cadre qui apparait se replace en s'affichant, sans replacement en plus
    raidHeaders[2]:Hide()
    updates = 0
    Z:Refresh()
    assert(raidHeaders[2]:IsVisible() and updates <= #raidHeaders, "cadre reapparu : " .. updates)
    -- un reglage qui echoue ne laisse ni le cadre en attente ni des cases sans place
    local pinned = Z.PinnedList
    Z.PinnedList = function() error("essai") end
    Z:Refresh()
    Z.PinnedList = pinned
    for _, h in ipairs(Z.headers) do assert(not h:GetAttribute("_ignore"), "cadre reste en attente : " .. h.def.key) end
    Placed("reglage en erreur")
    -- rafale de 20 changements : une mise a jour visible a l'image suivante, le travail lourd une seule fois a la fin
    local timers = {}
    C_Timer.After = function(delay, fn) timers[#timers + 1] = { delay, fn } end
    local quick, calm, refreshes = 0, 0, 0
    Z:OnRoster(function() quick = quick + 1 end)
    Z:OnRosterSettled(function() calm = calm + 1 end)
    Z.db.autoShrink = true
    Z.Refresh = function(...) refreshes = refreshes + 1 return old.refresh(...) end
    local start = os.clock()
    for n = 1, 20 do
      MEMBERS = 40 - n -- le raid fond : la taille des cases change deux fois (paliers 25 et 10)
      FireEvent("GROUP_ROSTER_UPDATE")
    end
    for _, delay in ipairs({ 0, 1 }) do -- l'image suivante, puis le calme
      for _, t in ipairs(timers) do if (t[1] == 0) == (delay == 0) then t[2]() end end
    end
    local spent = os.clock() - start
    assert(quick == 1, "mises a jour visibles : " .. quick)
    assert(calm == 1, "travail lourd : " .. calm)
    assert(refreshes == 1, "cases reduites " .. refreshes .. " fois")
    Placed("apres la rafale")
    -- groupe qui ne cesse de bouger (un changement toutes les 0,3 s pendant 3 s) : le travail lourd part quand meme
    local start, nowWas = NOW, NOW
    timers, calm = {}, 0
    C_Timer.After = function(delay, fn) timers[#timers + 1] = { NOW + delay, fn } end
    for k = 1, 10 do
      NOW = start + 0.3 * k
      for _, t in ipairs(timers) do if t[2] and t[1] <= NOW then local fn = t[2] t[2] = nil fn() end end
      FireEvent("GROUP_ROSTER_UPDATE")
    end
    assert(calm >= 1, "travail lourd jamais lance pendant une rafale sans fin")
    NOW = nowWas
    print("      (rafale de 20 changements : " .. ("%.3f"):format(spent) .. " s hors jeu)")
  end)
  C_Timer.After, Z.Refresh = old.after, old.refresh
  RAID, MEMBERS, Z.db.layout, Z.db.autoShrink = old.raid, old.members, old.layout, old.shrink
  for _, h in ipairs(raidHeaders) do h:SetScript("OnAttributeChanged", nil) end
  for _, f in ipairs(fake) do f[1]:GetAttribute("child" .. f[2]):Hide() f[1]:SetAttribute("child" .. f[2], nil) end
  Z:Refresh()
  assert(ok, err)
end)

step("C23 : journal qui s'ouvre malgre une valeur secrete", function()
  -- transparence d'une case reglee par la vie (secrete) : ecrite « secret » dans l'etat des cadres
  local b = Z.buttons[1]
  local oldAlpha, oldState = b.GetAlpha, Z.FrameState
  Z.header:SetAttribute("child1", b)
  b.GetAlpha = function() return MakeSecret(0.5) end
  local ok, err = pcall(function()
    local state = table.concat(Z:FrameState(), "\n")
    assert(state:find("alpha=secret", 1, true), "valeur secrete non remplacee")
    -- filet : une ligne secrete venue d'ailleurs ne bloque pas le journal
    Z.FrameState = function() return { "ligne lisible", MakeSecret("x") } end
    local text = Z:LogText()
    assert(text:find("ligne lisible", 1, true) and text:find("valeur secrète", 1, true), "journal bloque")
  end)
  b.GetAlpha, Z.FrameState = oldAlpha, oldState
  Z.header:SetAttribute("child1", nil)
  assert(ok, err)
end)

step("C24 et C25 : chef jamais sur l'icone de role, icone des DPS", function()
  local b = Z.buttons[1]
  local old = { shape = Z.db.shape, offset = Z.Offset, roles = UnitGroupRolesAssigned, dps = Z.db.showDpsRole }
  local ok, err = pcall(function()
    Z.db.shape = "TILE"
    Z.Offset = function(key) if key == "leader" then return 18, 2 end return 0, 0 end
    b.role:SetSize(12, 12) b.leader:SetSize(12, 12)
    b.role:Show()
    Z.PlaceLeader(b)
    local p = b.leader._point
    assert(p[1] == "TOPRIGHT" and p[2] == b.role and p[4] == -1 and p[5] == 2, "chef pose sur l'icone de role : " .. tostring(p[4]))
    b.role:Hide()
    Z.PlaceLeader(b)
    assert(b.leader._point[4] == 17, "sans icone de role, le chef reste ou le joueur l'a mis")
    -- icone des DPS : seulement avec son interrupteur (eteint au depart)
    assert(Z.defaults.showDpsRole == false, "allumee au depart")
    rawset(_G, "UnitGroupRolesAssigned", function() return "DAMAGER" end)
    b.role.SetAtlas = function(self, atlas) self._atlas = atlas end
    Z.db.showDpsRole = false
    Z:Refresh()
    assert(not b.role:IsShown(), "icone DPS affichee sans l'interrupteur")
    Z.db.showDpsRole = true
    Z:Refresh()
    assert(b.role:IsShown() and b.role._atlas == "roleicon-tiny-dps", "icone DPS absente")
    -- mode test : le faux DPS (troisieme case d'un groupe) montre aussi l'epee, seulement avec l'interrupteur
    local fake = Z.FakeCell(UIParent)
    Z.DrawFakeCell(fake, 3, false)
    assert(fake.role:IsShown(), "mode test : icone DPS absente")
    Z.db.showDpsRole = false
    Z.DrawFakeCell(fake, 3, false)
    assert(not fake.role:IsShown(), "mode test : icone DPS sans l'interrupteur")
    assert(Z.translations.enUS["Icône des DPS aussi"], "sans traduction anglaise")
  end)
  Z.db.shape, Z.Offset, Z.db.showDpsRole = old.shape, old.offset, old.dps
  rawset(_G, "UnitGroupRolesAssigned", old.roles)
  b.role.SetAtlas = nil
  Z:Refresh()
  assert(ok, err)
end)

step("C18 : Alt + clic gauche cible, Alt + clic droit ouvre le menu", function()
  local saved = CopyTable(Z.db.clicks.PRIEST)
  Z.db.clicks.PRIEST["alt-1"], Z.db.clicks.PRIEST["alt-2"] = "@target", "@menu"
  Z:ApplyClicks()
  local b = Z.buttons[1]
  assert(b:GetAttribute("alt-type1") == "target" and b:GetAttribute("alt-type2") == "togglemenu", "attributs du ciblage")
  -- carte « Soigner d'un clic » : elle dit comment cibler, ou où poser Cibler
  Z.db.tutorialDone = false Z:StartTutorial()
  local card = LyoruneTutorial
  card.next:Run("OnClick") card.next:Run("OnClick")
  assert(card.body:GetText():find("Alt + Clic gauche|r sur sa case", 1, true), card.body:GetText())
  card.close:Run("OnClick")
  Z.db.clicks.PRIEST["alt-1"] = nil
  Z.db.tutorialDone = false Z:StartTutorial()
  card.next:Run("OnClick") card.next:Run("OnClick")
  assert(card.body:GetText():find("Clic gauche|r sur sa case", 1, true), "sans Cibler : combinaison libre du clic gauche")
  -- Clique ou le jeu gerent les clics : rien sur le ciblage
  card.close:Run("OnClick")
  Z.db.externalClicks = true Z.db.tutorialDone = false Z:StartTutorial()
  card.next:Run("OnClick") card.next:Run("OnClick")
  assert(not card.body:GetText():find("Pour cibler", 1, true), "ciblage annonce avec les clics externes")
  Z.db.externalClicks = false
  card.close:Run("OnClick")
  Z.db.tutorialDone = true
  -- mise a jour : ajoutes une fois, a la connexion, seulement sur une combinaison libre chez Lyorune et dans le
  -- clic pour lancer du jeu, joueur prevenu
  local savedDB, version = LyoruneDB, Z.version
  local ok, err = pcall(function()
    local db = { lastVersion = "1.46.1", clicks = { PRIEST = { ["1"] = "Soins rapides", ["alt-1"] = "Rénovation" }, PRIEST2 = {}, MAGE = "abime" } }
    LyoruneDB = db Z.version = "1.46.2" Z.clickActionsPending = nil
    FireEvent("ADDON_LOADED", "Lyorune")
    assert(Z.clickActionsPending and db.clicks.PRIEST["alt-2"] == nil, "rien a poser avant la connexion")
    -- le clic pour lancer du jeu a un sort sur Alt + clic droit
    Enum.ClickBindingType = { Spell = 1, Macro = 2, Interaction = 3, PetAction = 4 }
    GetStringFromModifiers = function(m) return m == 4 and "ALT" or "" end
    C_ClickBindings = { GetProfileInfo = function() return { { type = 1, actionID = 139, button = "RightButton", modifiers = 4 } } end }
    local n = #PRINTED
    local added = Z:AddPendingClickActions()
    assert(added and #PRINTED == n + 1 and PRINTED[n + 1]:find("Alt + clic gauche", 1, true), "joueur non prevenu")
    assert(db.clicks.PRIEST["alt-1"] == "Rénovation", "clic du joueur ecrase")
    assert(db.clicks.PRIEST2["alt-1"] == "@target", "actions non ajoutees")
    assert(db.clicks.PRIEST2["alt-2"] == nil and db.clicks.PRIEST["alt-2"] == nil, "clic pour lancer du jeu ecrase")
    assert(not Z.clickActionsPending and not Z:AddPendingClickActions(), "ajoute une seconde fois")
    db.lastVersion = "1.46.2" FireEvent("ADDON_LOADED", "Lyorune")
    assert(not Z.clickActionsPending, "migration rejouee")
    assert(Z.translations.enUS["Pour cibler un joueur : %s sur sa case."], "sans traduction anglaise")
  end)
  C_ClickBindings, GetStringFromModifiers, Enum.ClickBindingType = nil, nil, nil
  Z.clickActionsPending = nil
  LyoruneDB, Z.version = savedDB, version FireEvent("ADDON_LOADED", "Lyorune")
  Z.db.clicks.PRIEST = saved Z:ApplyClicks()
  assert(ok, err)
end)

step("C20 a C22 : seuil en secondes, fin cachee en donjon, une seule rangee de buffs sur la case", function()
  local old = { isUnit = UnitIsUnit, after = C_Timer.After, instance = INSTANCE, kind = INSTANCE_TYPE, class = Z.class,
    durations = Z.db.buffDurations, renew = Z.db.buffRenew, name = C_Spell.GetSpellName, known = C_SpellBook.IsSpellKnown }
  local ok, err = pcall(function()
    C_Timer.After = function(s, f) if s < 1 then f() end end
    -- le pretre connait aussi Esprit divin, Protection contre l'ombre et Feu interieur : quatre buffs a lui
    local extra = { [14752] = "Esprit divin", [976] = "Protection contre l'ombre", [588] = "Feu intérieur" }
    C_Spell.GetSpellName = function(id) return extra[id] or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return extra[id] ~= nil or old.known(id) end
    local me = Z.buttons[1]
    local other
    for _, b in ipairs(Z.buttons) do
      if b ~= me and b.unit and not b.extra and b:IsVisible() and not b.unit:find("pet") then other = other or b end
    end
    UnitIsUnit = function(a, b) return a == b or (b == "player" and a == me.unit) end
    local function Has(b, id) for _, m in ipairs(b.missingBuffs or {}) do if m.check.id == id then return true end end end
    local function Update() Z:Refresh() RunUpdates() end
    INSTANCE, INSTANCE_TYPE, NOW = true, "party", 20000
    Z.db.buffWatch, Z.db.buffGroupAt, Z.db.missingBuffs, Z.db.buffPanel = {}, 99, true, true
    Z.class = "PRIEST" Z:BuildData()
    local fort = "Mot de pouvoir : Robustesse"
    -- C20 : 75 s au depart ; un buff de 30 minutes revient a 70 s de sa fin, pas a 80 s
    Z.db.buffRenew = Z.defaults.buffRenew
    assert(Z.db.buffRenew == 75 and Z.limits.buffRenew[1] == 0 and Z.limits.buffRenew[3] == 15, "seuil en secondes")
    AURAS = { HELPFUL = { { name = fort, icon = 9, auraInstanceID = 41, expirationTime = NOW + 80, duration = 1800 } } }
    Update() assert(not Has(other, 1243), "buff a 80 s propose avec un seuil de 75 s")
    AURAS.HELPFUL[1].expirationTime = NOW + 70
    Update() assert(Has(other, 1243), "buff a 70 s non propose (C20)")
    -- fin cachee par le jeu (donjon) : sans rien de su, le buff reste la (jamais propose a tort)
    Z.db.buffDurations = nil
    AURAS.HELPFUL[1].expirationTime, AURAS.HELPFUL[1].duration = MakeSecret(), MakeSecret()
    Update() assert(not Has(other, 1243) and other.buffEndHidden, "fin cachee sans memoire : buff propose a tort")
    -- je le lui ai lance : sa duree deja lue ailleurs (30 min) dit quand il finit
    FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(other.unit), "cast-c20", 1243)
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-c20", 1243)
    Update() assert(not Has(other, 1243), "duree jamais lue : une duree devinee le propose")
    Z.db.buffDurations = { [fort] = 1800 }
    FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(other.unit), "cast-c20b", 1243)
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-c20b", 1243)
    Update() assert(not Has(other, 1243), "buff tout neuf propose")
    -- la lecture suivante (fin toujours cachee) ne doit pas effacer ce souvenir
    NOW = NOW + 1800 - 60 Update()
    assert(Has(other, 1243), "fin cachee : buff presque fini non propose malgre mon sort (C20)")
    -- toujours la apres la fin retenue : quelqu'un l'a relance, il n'est plus propose
    NOW = NOW + 120 Update()
    assert(not Has(other, 1243), "buff relance par un autre (fin cachee) propose sans fin")
    local lines = table.concat(Z.BuffDiagnostic(), " | ")
    assert(lines:find("fin cachée : ", 1, true), "/lyorune buffs ne dit rien de la fin cachee")
    -- C29 : buff unique cache par le jeu (noms secrets en donjon) : le souvenir de mon sort, puis la case se relit
    -- toute seule a sa fin (aucun evenement du jeu), et le buff est propose de nouveau
    local fear = Z.uniqueChecks[1]
    if fear then
      Z.db.buffWatch = { [fear.id] = { pve = true, pvp = true } }
      local bearer = Z.UniqueBearer(fear)
      local cell
      for _, b in ipairs(Z.buttons) do if b.unit == bearer and not b.extra then cell = b end end
      assert(cell, "case du porteur introuvable")
      local timers = {}
      C_Timer.After = function(sec, f) if sec < 1 then f() else timers[#timers + 1] = { s = sec, f = f } end end
      AURAS = { HELPFUL = { { name = MakeSecret(), icon = 9, auraInstanceID = 71 } },
        ["HELPFUL|PLAYER"] = { { name = MakeSecret(), icon = 9, auraInstanceID = 72 } } }
      FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(bearer), "cast-c29", fear.id)
      FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-c29", fear.id)
      Update()
      assert(cell.myUniques and cell.myUniques:find(fear.name, 1, true), "souvenir du buff unique absent")
      local due
      local list = {}
      for _, t in ipairs(timers) do list[#list + 1] = math.floor(t.s) if t.s > 590 and t.s < 610 then due = t end end
      assert(due, "aucune relecture prevue a la fin du souvenir (C29) : " .. table.concat(list, ","))
      -- (le porteur peut avoir deux cases, chacune son rendez-vous : tous sont tenus)
      NOW = NOW + due.s
      for _, t in ipairs(timers) do if t.s > 590 and t.s < 610 then t.f() end end
      RunUpdates()
      assert(not cell.myUniques, "buff unique toujours cru pose apres la fin du souvenir")
      C_Timer.After = function(sec, f) if sec < 1 then f() end end
      AURAS = {} Z.db.buffWatch = {}
    end
    -- C29 : chaque buff unique dit pourquoi il est propose ou non
    local uniques = Z.UniqueDiagnostic()
    assert(#uniques == #Z.uniqueChecks, "diagnostic des buffs uniques incomplet")
    for _, line in ipairs(uniques) do assert(line:find("porteur", 1, true), line) end
    -- C21 : toutes les absences sur la case, pas seulement la premiere ; jamais au-dela de son bord
    AURAS = {} Update()
    local shown = 0
    for _, icon in ipairs(me.buffList or {}) do if icon:IsShown() then shown = shown + 1 end end
    -- (plus mon buff unique quand je suis son porteur, C31)
    local expected = 0
    for _, entry in ipairs(me.buffWatch or {}) do if entry.at <= NOW then expected = expected + 1 end end
    assert(expected >= #me.missingBuffs and #me.missingBuffs >= 3, "absences non suivies sur la case")
    assert(shown == expected, "une seule icone de buff : " .. shown .. "/" .. expected)
    local x, _, size = Z.BuffMarkPlace(me)
    local width = me:GetWidth()
    me:SetWidth(x + (size + 2) * 1.5) Z.QueueAuras(me) RunUpdates()
    shown = 0
    for _, icon in ipairs(me.buffList or {}) do if icon:IsShown() then shown = shown + 1 end end
    assert(shown == 1, "rangee qui deborde de la case : " .. shown)
    me:SetWidth(width) Update()
    -- C28 : un familier n'est jamais propose (case, bandeau, touche)
    for _, unit in ipairs({ "pet", "partypet1", "raidpet3" }) do
      for _, check in ipairs(Z.buffChecks) do
        assert(not Z.BuffConcerns(check, unit, false), "buff propose a un familier : " .. unit .. " " .. check.spell)
      end
    end
    assert(Z.BuffConcerns(Z.buffChecks[1], other.unit, false), "joueur ecarte avec les familiers")
    -- interrupteur : rien sur la case
    Z.db.missingBuffs = false Update()
    for _, icon in ipairs(me.buffList or {}) do assert(not icon:IsShown(), "rangee montree interrupteur eteint") end
    Z.db.missingBuffs = true
    -- textes : option et traductions
    for _, text in ipairs({ "Proposer à nouveau sous (secondes)", "Mes buffs sur la case",
      "Gris à bord rouge : à reposer. Un buff posé ne se montre pas.", "Au plus grand : %d %%. Mes buffs bloquent : décochez-les pour leur laisser la place.",
      "fin cachée : %d joueur(s) dont un buff a une heure de fin secrète (la mémoire de vos sorts décide)." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
  end)
  UnitIsUnit, C_Timer.After, INSTANCE, INSTANCE_TYPE = old.isUnit, old.after, old.instance, old.kind
  C_Spell.GetSpellName, C_SpellBook.IsSpellKnown = old.name, old.known
  Z.db.buffDurations, Z.db.buffRenew = old.durations, old.renew
  AURAS = {}
  Z.class = old.class Z:BuildData() Z:Refresh() RunUpdates()
  assert(ok, err)
end)

step("C30 : buffs (refus du jeu, buff d'un autre, buffs uniques, arme, mort, moi d'abord, mana)", function()
  local old = { isUnit = UnitIsUnit, after = C_Timer.After, class = Z.class, renew = Z.db.buffRenew, name = C_Spell.GetSpellName,
    known = C_SpellBook.IsSpellKnown, unitClass = UnitClass, byName = C_UnitAuras.GetAuraDataBySpellName,
    panel = Z.db.buffPanel, place = Z.db.buffPlace, groupAt = Z.db.buffGroupAt }
  local globals = { "SPELL_FAILED_AURA_BOUNCED", "ERR_OUT_OF_RANGE", "ITEM_ENCHANT_TIME_LEFT_MIN", "ITEM_ENCHANT_TIME_LEFT_HOURS",
    "GetWeaponEnchantInfo", "GetInventoryItemID" }
  local ok, err = pcall(function()
    local timers = {}
    C_Timer.After = function(s, f) if s < 1 then f() else timers[#timers + 1] = { s = s, f = f } end end
    local extra = { [8024] = "Arme Langue de feu", [8017] = "Arme Croque-roc", [408510] = "Bouclier d'eau" }
    C_Spell.GetSpellName = function(id) return extra[id] or old.name(id) end
    C_SpellBook.IsSpellKnown = function(id) return extra[id] ~= nil or old.known(id) end
    local me = Z.buttons[1]
    local other
    for _, b in ipairs(Z.buttons) do
      if b ~= me and b.unit and not b.extra and b:IsVisible() and not b.unit:find("pet") then other = other or b end
    end
    UnitIsUnit = function(a, b) return a == b or (b == "player" and a == me.unit) or (a == "player" and b == me.unit) end
    local function Has(b, id) for _, m in ipairs(b.missingBuffs or {}) do if m.check.id == id then return true end end end
    local function Update() Z:Refresh() RunUpdates() end
    local function Row(unit, spell)
      for _, r in ipairs(Z.BuffRows()) do if r.unit == unit and r.spell == spell and not r.count then return r end end
    end
    NOW = 30000
    Z.db.buffWatch, Z.db.buffGroupAt, Z.db.missingBuffs, Z.db.buffPanel, Z.db.buffPlace = {}, 99, true, true, "FREE"
    Z.db.buffRenew = 75
    Z.class = "PRIEST" Z:BuildData()
    local fort = "Mot de pouvoir : Robustesse"

    -- 6 : le buff d'un autre joueur compte jusqu'a sa fin, le mien est repris sous le seuil
    AURAS = { HELPFUL = { { name = fort, icon = 9, auraInstanceID = 81, expirationTime = NOW + 60, duration = 1800,
      sourceUnit = "raid9" } } }
    Update() assert(not Has(other, 1243), "buff d'un autre joueur repris avant sa fin (C30)")
    local rdv
    for _, t in ipairs(timers) do if t.s > 59 and t.s < 62 then rdv = t end end
    assert(rdv, "fin du buff d'un autre joueur non attendue")
    AURAS.HELPFUL[1].sourceUnit = "player"
    Update() assert(Has(other, 1243), "mon buff sous le seuil non propose")
    AURAS.HELPFUL[1].sourceUnit = MakeSecret()
    Update() assert(Has(other, 1243), "lanceur secret : traite comme avant (repris sous le seuil)")

    -- 11 : un buff qui me manque passe en tete du panneau et de la touche
    AURAS = {} Update() Z:UpdateBuffPanel()
    local list = Z.BuffRows()
    assert(#list > 1 and list[1].unit == me.unit, "mon buff pas en tete : " .. tostring(list[1] and list[1].unit))
    assert(LyoruneNextBuff:GetAttribute("unit") == me.unit, "touche : mon buff pas en premier")

    -- 1, 4, 9 : refus du jeu apres mon clic : ce joueur est mis de cote pour ce buff
    rawset(_G, "SPELL_FAILED_AURA_BOUNCED", "Un sort plus puissant est déjà actif")
    rawset(_G, "ERR_OUT_OF_RANGE", "Hors de portée")
    -- (les lignes changent d'ordre a chaque mise a jour : la bonne est cherchee avant chaque clic)
    local function Click()
      Z:UpdateBuffPanel()
      for i = 1, 10 do
        local r = _G["LyoruneBuffsRow" .. i]
        if r and r:IsShown() and r.unitToken == other.unit and r.spellName == fort then r:Run("PreClick", "LeftButton") return end
      end
      error("ligne de la Robustesse de l'autre joueur absente")
    end
    -- un message sans clic ne met personne de cote
    FireEvent("UI_ERROR_MESSAGE", 50, SPELL_FAILED_AURA_BOUNCED)
    assert(Row(other.unit, fort), "refus sans clic : joueur mis de cote")
    -- un autre sort parti apres le clic : le refus ne lui est pas attribue
    Click()
    FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(other.unit), "c30-a", 2061)
    FireEvent("UI_ERROR_MESSAGE", 50, SPELL_FAILED_AURA_BOUNCED)
    assert(Row(other.unit, fort), "refus attribue au mauvais sort")
    -- mon sort parti, refuse par le serveur : de cote 10 minutes, les autres restent proposes
    Click()
    FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(other.unit), "c30-b", 1243)
    NOW = NOW + 2
    FireEvent("UI_ERROR_MESSAGE", 50, SPELL_FAILED_AURA_BOUNCED)
    assert(not Row(other.unit, fort), "refuse par le jeu : toujours propose (C30)")
    assert(Row(me.unit, fort), "les autres joueurs ne sont plus proposes")
    local report = Z.AsideReport()
    assert(#report == 1 and report[1]:find("SPELL_FAILED_AURA_BOUNCED", 1, true), "/lyorune buffs : mise de cote absente")
    NOW = NOW + 599 assert(not Row(other.unit, fort), "mis de cote moins de 10 minutes")
    NOW = NOW + 2 assert(Row(other.unit, fort), "toujours de cote apres 10 minutes")
    -- trop loin : 20 secondes ; sa mort efface la mise de cote
    Click()
    FireEvent("UI_ERROR_MESSAGE", 50, ERR_OUT_OF_RANGE)
    assert(not Row(other.unit, fort), "hors de portee : toujours en tete")
    Z.ForgetBuffs(other.unit)
    assert(Row(other.unit, fort), "mort : mise de cote gardee")
    Click()
    FireEvent("UI_ERROR_MESSAGE", 50, ERR_OUT_OF_RANGE)
    NOW = NOW + 21 assert(Row(other.unit, fort), "hors de portee : de cote plus de 20 s")
    -- hors de vue : le jeu lance le sort sur moi a la place du joueur vise ; il est mis de cote 20 s
    Click()
    FireEvent("UNIT_SPELLCAST_SENT", "player", "Quelqu'un", "c30-c", 1243)
    assert(not Row(other.unit, fort), "sort parti sur moi : le joueur vise reste en tete (C30)")
    NOW = NOW + 21 assert(Row(other.unit, fort), "sort parti sur moi : de cote plus de 20 s")
    Click()
    FireEvent("UNIT_SPELLCAST_SENT", "player", UnitName(other.unit) .. "-Royaume", "c30-d", 1243)
    assert(Row(other.unit, fort), "nom avec royaume pris pour un autre joueur")
    -- 4 : rang que le joueur peut recevoir, lance par son numero ; niveau inconnu ou assez haut : le sort par son nom
    local oldFit, oldInfo, oldLevel = Z.FitRank, C_Spell.GetSpellInfo, UnitLevel
    local level = 10
    Z.FitRank = function(id, lvl) return (id == 10938 and lvl < 40) and 1245 or id end
    C_Spell.GetSpellInfo = function() return { spellID = 10938 } end
    UnitLevel = function() return level end
    assert(Z.BuffCastFor(fort, other.unit) == 1245, "joueur de bas niveau : rang trop haut lance")
    level = 60 assert(Z.BuffCastFor(fort, other.unit) == fort, "joueur de haut niveau : rang choisi a tort")
    level = MakeSecret() assert(Z.BuffCastFor(fort, other.unit) == fort, "niveau secret : rang devine")
    level = 10 Z.db.rankAdapt = false
    assert(Z.BuffCastFor(fort, other.unit) == fort, "interrupteur du rang adapte eteint : rang baisse quand meme")
    Z.db.rankAdapt = true
    Z.FitRank, C_Spell.GetSpellInfo, UnitLevel = oldFit, oldInfo, oldLevel

    -- 8 : mort ou fantome, rien a poser
    DEAD = { player = true } Z:UpdateBuffPanel()
    assert(LyoruneNextBuff:GetAttribute("spell") == nil, "mort : la touche lance encore un buff")
    DEAD = nil Z:UpdateBuffPanel()
    assert(LyoruneNextBuff:GetAttribute("spell") ~= nil, "revenu : plus rien propose")

    -- 7 : buff unique presque fini, renouvele sur le joueur qui le porte ; celui d'un autre jamais remplace
    local fear = Z.uniqueChecks[1]
    if fear then
      local bearer = Z.UniqueBearer(fear)
      local function Fear() for _, r in ipairs(Z.BuffRows()) do if r.spell == fear.spell then return r end end end
      AURAS = { ["HELPFUL|PLAYER"] = { { name = fear.name, icon = 9, auraInstanceID = 91, expirationTime = NOW + 100, duration = 600 } } }
      Update() assert(not Fear(), "buff unique a 100 s propose")
      AURAS["HELPFUL|PLAYER"][1].expirationTime = NOW + 30
      Update()
      local r = Fear()
      assert(r and r.why == Z.L["à renouveler"], "buff unique presque fini non renouvele (C30)")
      AURAS = {}
      C_UnitAuras.GetAuraDataBySpellName = function(unit, name) if name == fear.name and unit == bearer then return { name = name } end end
      Update() assert(not Fear(), "buff unique d'un autre joueur remplace (C30)")
      local said
      for _, line in ipairs(Z.UniqueDiagnostic()) do if line:find(Z.L["un autre joueur le lui a déjà posé"], 1, true) then said = true end end
      assert(said, "/lyorune buffs ne dit pas que le buff vient d'un autre")
      C_UnitAuras.GetAuraDataBySpellName = old.byName
      Update() assert(Fear(), "buff unique plus propose")
    end

    -- 3 : arme du chaman : sans arme, rien ; enchantement que le jeu ne voit pas, lu dans l'infobulle
    AURAS = { HELPFUL = { { name = "Bouclier d'eau", icon = 9, auraInstanceID = 95 } } }
    Z.class = "SHAMAN" Z:BuildData()
    rawset(_G, "GetWeaponEnchantInfo", function() return false, 0 end)
    local item
    rawset(_G, "GetInventoryItemID", function() return item end)
    Update() assert(not Has(me, 8024), "sans arme : enchantement propose")
    item = 1234
    FireEvent("WEAPON_ENCHANT_CHANGED") RunUpdates()
    assert(Has(me, 8024), "arme sans enchantement : rien de propose")
    rawset(_G, "ITEM_ENCHANT_TIME_LEFT_MIN", "%s (%d min)")
    rawset(_G, "ITEM_ENCHANT_TIME_LEFT_HOURS", "%s (%d |4heure:heures;)")
    local tip = "Croque-roc 1 (60 min)"
    C_TooltipInfo = { GetInventoryItem = function() return { lines = { { leftText = "Masse" }, { leftText = tip } } } end }
    FireEvent("WEAPON_ENCHANT_CHANGED") RunUpdates()
    assert(not Has(me, 8024), "enchantement de l'infobulle non lu (C30)")
    tip = "Croque-roc 1 (2 heures)"
    FireEvent("WEAPON_ENCHANT_CHANGED") RunUpdates()
    assert(not Has(me, 8024), "infobulle en heures non lue")
    tip = "Croque-roc 1 (1 min)"
    FireEvent("WEAPON_ENCHANT_CHANGED") RunUpdates()
    assert(Has(me, 8024), "enchantement presque fini (infobulle) non propose")
    C_TooltipInfo = nil

    -- 10 : chasseur : la reponse du jeu tranche (mana ou non), un guerrier n'en a jamais
    UnitClass = function() return "Chasseur", "HUNTER" end
    assert(not Z.UsesMana("party1"), "chasseur sans mana compte comme joueur a mana")
    POWER_TYPE = 0 assert(Z.UsesMana("party1"), "chasseur a mana (Forever) ecarte")
    POWER_TYPE = MakeSecret() assert(not Z.UsesMana("party1"), "reponse secrete : la classe ne decide pas")
    POWER_TYPE = nil
    UnitClass = function() return "Druide", "DRUID" end
    POWER_TYPE = 1 assert(Z.UsesMana("party1"), "druide en forme d'ours prive de mana")
    POWER_TYPE = nil

    for _, text in ipairs({ "à renouveler", "un autre joueur le lui a déjà posé", "mis de côté : %s, %s (%s), encore %d s." }) do
      assert(Z.translations.enUS[text], "sans traduction : " .. text)
    end
  end)
  for _, name in ipairs(globals) do rawset(_G, name, nil) end
  C_TooltipInfo, POWER_TYPE, DEAD = nil, nil, nil
  UnitIsUnit, C_Timer.After, UnitClass = old.isUnit, old.after, old.unitClass
  C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, C_UnitAuras.GetAuraDataBySpellName = old.name, old.known, old.byName
  Z.db.buffRenew, Z.db.buffPanel, Z.db.buffPlace, Z.db.buffGroupAt = old.renew, old.panel, old.place, old.groupAt
  Z.db.buffWatch = {}
  AURAS = {}
  Z.class = old.class Z:BuildData() Z:Refresh() RunUpdates() Z:UpdateBuffPanel()
  assert(ok, err)
end)

step("C26 : familiers en colonne a part, en face de leur maitre, plus petits ; colonne apres les groupes en raid", function()
  local saved = { pets = Z.db.pets, horizontal = Z.db.horizontal, layout = Z.db.layout, raid = RAID }
  Z.db.pets, Z.db.horizontal, Z.db.layout, RAID = "RAID", false, "GROUP", false
  -- Le modèle du cadre « Groupe » porte la case du familier (Pets.xml), créée avec celle du maître
  assert(Z.header:GetAttribute("template"):find("LyoruneOwnerTemplate", 1, true), "modele du maitre")
  assert(not LyoruneRaid1:GetAttribute("template"):find("LyoruneOwnerTemplate", 1, true), "pas en raid")
  local owner = CreateFrame("Button", "LyoruneHeaderUnitButton990", Z.header)
  local pet = CreateFrame("Button", "LyoruneHeaderUnitButton990Pet", owner)
  owner.zPet = pet
  owner:Hide()
  Z.header:InitButton(owner:GetName())
  assert(owner.petCell == pet and pet.isPet and pet.owner == owner and pet.hp, "case du familier habillee")
  assert(UNIT_WATCH[pet], "le jeu montre le familier seulement s'il existe")
  Z:Refresh()
  local width, height = Z.CellSize()
  local pw, ph = Z.PetSize()
  assert(Z.db.petSize == 60 and pw == math.floor(width * 0.6 + 0.5) and ph == math.floor(height * 0.6 + 0.5), "60 % au depart")
  assert(pet:GetWidth() == pw and pet:GetHeight() == ph, "plus petite")
  local p = pet._points.LEFT
  assert(p[2] == owner and p[3] == "RIGHT" and p[4] == Z.PetGap() and Z.PetGap() > Z.db.spacing, "en face de son maitre, apres un vrai espace")
  assert(Z.header:GetAttribute("z-petwidth") == pw and Z.header:GetAttribute("z-petheight") == ph, "taille donnee au code securise")
  assert(Z.header:GetAttribute("columnSpacing") == Z.db.spacing + Z.PetGap() + pw, "place gardee entre colonnes")
  Z.db.petSize = 80 Z:Refresh()
  assert(pet:GetWidth() == math.floor(width * 0.8 + 0.5), "taille reglable")
  Z.db.petSize = 60
  Z.db.horizontal = true Z:Refresh()
  assert(Z.header:GetAttribute("xOffset") == Z.db.spacing + Z.PetGap() + pw, "en lignes : place a droite de chacun")
  assert(LyoruneRaid1:GetAttribute("xOffset") == Z.db.spacing, "les groupes du raid gardent leur pas")
  Z.db.horizontal = false
  -- Portée : la case du familier garde la sienne (opacité générale comprise), pas celle de son maître
  pet:Hide() pet:SetAttribute("unit", "partypet1")
  assert(not pet._events.UNIT_HEALTH, "cache : n'ecoute rien")
  pet:Show()
  assert(pet._events.UNIT_HEALTH, "montre : ecoute sa vie")
  assert(pet:GetAttribute("ping-receiver") == nil, "pas de signal sur la petite case")
  assert(pet:GetAlpha() <= Z.db.frameAlpha / 100 + 1e-6, "opacite generale")
  -- Hors raid : pas de colonne ; en raid : colonne étroite collée à droite du dernier groupe, sans place à elle
  assert(not LyorunePets:IsShown(), "pas de colonne hors raid")
  RAID = true Z:Refresh()
  assert(LyorunePets:IsShown() and LyorunePets:GetAttribute("z-width") == pw and LyorunePets:GetAttribute("z-height") == ph, "colonne en raid, cases plus petites")
  assert(LyorunePets:GetAttribute("yOffset") == -Z.db.spacing - (height - ph), "chaque familier a la hauteur d'une ligne de joueurs")
  local q = LyorunePets._points.TOPLEFT
  assert(q[2] == LyoruneRaid8 and q[3] == "TOPRIGHT" and q[4] == Z.PetGap(), "apres le dernier groupe, un vrai espace")
  assert(LyoruneRaid8:GetAttribute("minWidth") == 0.1, "un groupe vide ne prend aucune place")
  assert(Z.header.petRoom == pw + Z.PetGap(), "fond de groupe et barre comptent les familiers")
  assert(LyorunePets.def.pos == "pos", "son etiquette deplace tout le cadre principal")
  Z.db.layout = "GRID" Z:Refresh()
  q = LyorunePets._points.TOPLEFT
  assert(q[2] == LyoruneRaid1 and q[3] == "TOPRIGHT", "en grille : a droite de la grille")
  Z.db.layout, Z.db.horizontal = "GROUP", true Z:Refresh()
  q = LyorunePets._points.TOPLEFT
  assert(q[3] == "BOTTOMLEFT" and q[4] > 4 * width, "en lignes : a droite de la premiere ligne")
  assert(LyorunePets:GetAttribute("columnSpacing") == Z.db.spacing + height - ph, "en lignes : chaque rangee a la hauteur d'une ligne")
  assert(LyorunePets:GetAttribute("groupBy") == "GROUP" and LyorunePets:GetAttribute("groupingOrder") == "1,2,3,4,5,6,7,8", "rangee dans l'ordre des groupes")
  -- Case de la colonne du raid : nom du maître, couleur de sa classe pâlie, portée par le sort du clic gauche
  local raidPet = CreateFrame("Button", "LyorunePetsUnitButton990", LyorunePets)
  LyorunePets:InitButton(raidPet:GetName())
  raidPet:SetAttribute("unit", "raidpet3") raidPet:Show()
  assert(raidPet.isPet and not raidPet.owner and raidPet.name:GetText() == "Joueur-raid3", "nom du maitre en raid")
  assert(pet.name:GetText() == "Joueur-partypet1", "en groupe, en face du maitre : son propre nom")
  Z.db.color = "CLASS" Z.cellUpdates.all(raidPet)
  local r, g = Z.ClassColor("PRIEST")
  local c = raidPet.hp._barColor
  assert(math.abs(c[1] - (r + (1 - r) * 0.35)) < 1e-6 and math.abs(c[2] - (g + (1 - g) * 0.35)) < 1e-6, "couleur du maitre, palie")
  local inRange, owner = C_Spell.IsSpellInRange, UnitInRange
  local asked
  C_Spell.IsSpellInRange = function(spell, unit) asked = spell return false end
  NOW = (NOW or 0) + 10
  Z.cellUpdates.range(raidPet)
  assert(asked == Z:GetClicks()["1"] and raidPet:GetAlpha() < 1, "portee du sort du clic gauche")
  C_Spell.IsSpellInRange = function() return nil end
  Z.cellUpdates.range(raidPet)
  assert(raidPet:GetAlpha() == 1, "sans reponse du sort : portee du maitre (a portee ici)")
  C_Spell.IsSpellInRange, UnitInRange = inRange, owner
  -- Mode test : un faux familier en face du faux chasseur (groupe), puis dans la colonne après les groupes (raid)
  RAID = false Z.db.horizontal = false Z:Refresh()
  Z:TogglePreview(5)
  local fake = Z:PreviewPets()[4]
  assert(fake and fake:IsShown() and fake:GetWidth() == pw and fake:GetHeight() == ph, "faux familier, plus petit")
  assert(fake._points.LEFT and fake._points.LEFT[4] == Z.PetGap() and fake.name:GetText() == "Familier", "en face de son maitre")
  Z:TogglePreview(5)
  Z:TogglePreview(10)
  fake = Z:PreviewPets()[4]
  assert(fake:IsShown() and fake.name:GetText() == "Joueur 4" and fake._points.TOPLEFT, "en raid : colonne, nom du maitre")
  assert(Z:PreviewPets()[9]:IsShown(), "le demoniste aussi")
  Z.db.pets = "PARTY" Z:RefreshPreview()
  assert(not fake:IsShown(), "familiers du raid coupes : rien en raid")
  Z.db.pets = "RAID"
  Z:TogglePreview(10)
  RAID, Z.db.horizontal = true, true Z:Refresh()
  -- Coupé : la colonne disparaît, la petite case n'est plus confiée au jeu
  Z.db.pets = "OFF" Z:Refresh()
  assert(not LyorunePets:IsShown() and not UNIT_WATCH[pet] and not pet:IsShown(), "familiers coupes")
  assert(Z.header:GetAttribute("columnSpacing") == Z.db.spacing and Z.header:GetAttribute("xOffset") == Z.db.spacing, "plus de place gardee")
  -- Une case créée en combat est confiée au jeu à la fin du combat
  Z.db.pets, RAID, Z.db.horizontal = "RAID", false, false
  COMBAT = true
  local owner2 = CreateFrame("Button", "LyoruneHeaderUnitButton991", Z.header)
  local pet2 = CreateFrame("Button", "LyoruneHeaderUnitButton991Pet", owner2)
  owner2.zPet = pet2
  Z.header:InitButton(owner2:GetName())
  assert(pet2.isPet and not UNIT_WATCH[pet2], "rien en combat")
  COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
  assert(UNIT_WATCH[pet2], "confiee au jeu a la fin du combat")
  Z.db.pets, Z.db.horizontal, Z.db.layout, RAID = saved.pets, saved.horizontal, saved.layout, saved.raid
  Z:Refresh()
end)

step("1.47.0 : Me montrer, nouveautes pas encore vues, bilan du donjon et de la soiree", function()
  local old = { notebook = Z.db.notebook, exit = Z.db.tallyExit, instance = INSTANCE, kind = INSTANCE_TYPE, class = Z.class, seen = Z.db.newsSeen }
  local ok, err = pcall(function()
    -- chaque reglage de Z.changeShows : une version connue, une ligne qui existe, un reglage qui a sa ligne
    local versions, keys = {}, Z:OptionKeys()
    for _, entry in ipairs(Z.changes) do versions[entry.version] = entry end
    for version, shows in pairs(Z.changeShows) do
      local entry = versions[version]
      assert(entry, "Me montrer : version inconnue " .. version)
      for section, list in pairs(shows) do
        assert(entry[section], "Me montrer : rubrique inconnue " .. version .. " " .. section)
        for i, key in pairs(list) do
          assert(entry[section][i], ("Me montrer : %s %s, pas de ligne %d"):format(version, section, i))
          assert(key == false or keys[key], "Me montrer : reglage sans ligne dans les options : " .. tostring(key))
        end
      end
    end
    local text = Z:NewsText()
    assert(text:find("|Hlyorune:show:pets|h", 1, true) and text:find("[Me montrer]", 1, true), "lien Me montrer absent")
    assert(not text:find("lyorune:show:false", 1, true), "lien vers rien")
    -- un clic sur le lien ouvre les options sur le reglage
    Z:ShowNews()
    local news = _G.LyoruneNews
    local content
    for _, child in ipairs({ news:GetChildren() }) do
      for _, inner in ipairs({ child:GetChildren() }) do if inner._links then content = inner end end
    end
    assert(content and content:GetScript("OnHyperlinkClick"), "liens des nouveautes non actifs")
    local w = Z:OptionsWindow()
    if w and w:IsShown() then w:Hide() end
    content:Run("OnHyperlinkClick", "lyorune:show:showDpsRole", "[Me montrer]", "LeftButton")
    w = Z:OptionsWindow()
    assert(w:IsShown() and Z:OptionChapter() == Z.TabOfSetting("showDpsRole"), "Me montrer : mauvais chapitre " .. tostring(Z:OptionChapter()))
    assert(w.found and w.found.key == "showDpsRole", "Me montrer : reglage pas mis en lumiere")
    assert(Z:GoToOption("cleInconnue") == false, "reglage inconnu")
    -- bilan de la soiree : compte avec le carnet, garde au /reload, efface a la connexion
    Z.class = "PRIEST" Z:BuildData()
    Z.db.notebook, Z.db.tallyExit = true, true Z:RefreshAlerts()
    FireEvent("PLAYER_ENTERING_WORLD", true, false)
    assert(Z.char.tonight == nil and Z.TonightLine() == nil, "connexion : soiree pas remise a zero")
    local total = Z.Tally().heals
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-soir", 2061)
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-soir2", 2006)
    assert(Z.Tonight().heals == 1 and Z.Tonight().res == 1 and Z.Tally().heals == total + 1, "soiree : chiffres")
    FireEvent("PLAYER_ENTERING_WORLD", false, true)
    assert(Z.Tonight().heals == 1, "soiree perdue au /reload")
    -- entrer dans un donjon, y soigner, mourir (rien en sortant mort), revenir, sortir vivant : une ligne
    INSTANCE, INSTANCE_TYPE, INSTANCE_NAME = true, "party", "Donjon 1"
    FireEvent("PLAYER_ENTERING_WORLD", false, false)
    assert(Z.char.outing and Z.char.outing.name == "Donjon 1" and Z.char.outing.heals == 1, "entree du donjon pas notee")
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-donjon", 2061)
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-donjon2", 2061)
    local n = #PRINTED
    DEAD = true
    INSTANCE, INSTANCE_TYPE = false, "none" FireEvent("PLAYER_ENTERING_WORLD", false, false)
    assert(#PRINTED == n and Z.char.outing, "sorti mort : bilan donne a tort")
    DEAD = false
    INSTANCE, INSTANCE_TYPE = true, "party" FireEvent("PLAYER_ENTERING_WORLD", false, false)
    FireEvent("PLAYER_ENTERING_WORLD", false, true) -- /reload dans le donjon
    assert(Z.char.outing.heals == 1, "retour au meme donjon : ses chiffres repartis de zero")
    INSTANCE, INSTANCE_TYPE = false, "none" FireEvent("PLAYER_ENTERING_WORLD", false, false)
    local said = PRINTED[n + 1] or ""
    assert(#PRINTED == n + 1 and said:find("Donjon 1 (1 min) : 2 soins, 0 résurrections, 0 buffs.", 1, true)
      and said:find("Bilan du jour : 3 soins, 1 résurrections, 0 buffs.", 1, true), "bilan en sortie : " .. said)
    assert(Z.char.outing == nil, "donjon pas oublie a la sortie")
    INSTANCE_NAME = nil
    -- interrupteur eteint, ou sortie d'un champ de bataille : rien
    Z.db.tallyExit = false
    INSTANCE, INSTANCE_TYPE = true, "raid" FireEvent("PLAYER_ENTERING_WORLD", false, false)
    INSTANCE, INSTANCE_TYPE = false, "none" FireEvent("PLAYER_ENTERING_WORLD", false, false)
    Z.db.tallyExit = true
    INSTANCE, INSTANCE_TYPE = true, "pvp" FireEvent("PLAYER_ENTERING_WORLD", false, false)
    INSTANCE, INSTANCE_TYPE = false, "none" FireEvent("PLAYER_ENTERING_WORLD", false, false)
    assert(#PRINTED == n + 1, "bilan donne a tort")
    -- la page des amis : colonne Aujourd'hui
    local notebook = OptionPart("tonightRows")
    notebook:Update()
    assert(notebook.tonightRows.heals:GetText() == "3" and notebook.tonightRows.res:GetText() == "1", "colonne Aujourd'hui")
    -- nouveautes pas encore vues : une rune d'or sur les versions sorties depuis la derniere lecture
    Z.db.newsSeen = "1.46.4"
    text = Z:NewsText()
    local first, second = text:match("Lyorune 1%.46%.5[^%c]*"), text:match("Lyorune 1%.46%.4[^%c]*")
    assert(Z.version == "1.46.5" or Z.VersionNumber(Z.version) > Z.VersionNumber("1.46.4"), "version")
    assert(first:find("|cffffd24dNouveau pour vous|r", 1, true) and not second:find("|cffffd24dNouveau pour vous|r", 1, true), "rune des nouveautes : " .. first)
    Z:ShowNews() news:Hide() news:Run("OnHide")
    -- (la rune elle-meme : une note de version peut citer ces mots)
    assert(Z.db.newsSeen == Z.version and not Z:NewsText():find("|cffffd24dNouveau pour vous|r", 1, true), "nouveautes lues : rune restee")
    for _, key in ipairs({ "En tout", "Aujourd'hui", "Me montrer", "Nouveau pour vous", "%s soins, %s résurrections, %s buffs",
      "Bilan du jour : %s.", "%s (%d min) : %s.",
      "Mène au réglage de cette nouveauté dans les options." }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
  end)
  Z.db.notebook, Z.db.tallyExit, INSTANCE, INSTANCE_TYPE, Z.class = old.notebook, old.exit, old.instance, old.kind, old.class
  Z.db.newsSeen, DEAD, INSTANCE_NAME = old.seen, false, nil
  Z:BuildData() Z:RefreshAlerts()
  assert(ok, err)
end)

step("nouveautes : toujours relisibles (en-tete des options, mini-carte, rappel a la fermeture)", function()
  local old = { seen = Z.db.newsSeen, button = Z.db.minimapButton, shift = IsShiftKeyDown }
  local ok, err = pcall(function()
    local w = Z:OptionsWindow() w:Show()
    local news = LyoruneNews
    if news then news:Hide() end
    assert(w.news and w.news:IsShown(), "bouton Nouveautes absent de l'en-tete")
    w.news:Run("OnClick", "LeftButton")
    assert(LyoruneNews and LyoruneNews:IsShown(), "le bouton n'ouvre pas les nouveautes")
    LyoruneNews:Hide() w:Hide()
    -- Maj + clic gauche sur la mini-carte : les nouveautes, pas les options
    Z.db.minimapButton = true Z:RefreshMinimap()
    IsShiftKeyDown = function() return true end
    LyoruneMinimapButton:Run("OnClick", "LeftButton")
    assert(LyoruneNews:IsShown() and not w:IsShown(), "Maj + clic sur la mini-carte")
    Z.db.newsSeen = Z.version
    LyoruneMinimapButton:Run("OnClick", "LeftButton")
    assert(not LyoruneNews:IsShown(), "Maj + clic ne referme pas les nouveautes")
    Z:ShowNews()
    IsShiftKeyDown = old.shift
    -- premiere fermeture apres une mise a jour : une ligne dit ou les relire, une seule fois
    Z.db.newsSeen = "1.0.0"
    local count = #PRINTED
    LyoruneNews:Hide() LyoruneNews:Run("OnHide")
    assert(#PRINTED == count + 1 and PRINTED[#PRINTED]:find("/lyorune nouveautes", 1, true), "rappel absent")
    Z:ShowNews() LyoruneNews:Hide() LyoruneNews:Run("OnHide")
    assert(#PRINTED == count + 1, "rappel repete")
    for _, key in ipairs({ "Nouveautés", "Maj + clic gauche : nouveautés",
      "Relire les nouveautés de chaque version, avec « Me montrer » pour aller au réglage.",
      "Pour relire les nouveautés : bouton Nouveautés en haut des options, Maj + clic sur le bouton de la mini-carte, ou /lyorune nouveautes." }) do
      assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
    end
  end)
  IsShiftKeyDown = old.shift
  Z.db.newsSeen, Z.db.minimapButton = old.seen, old.button
  Z:RefreshMinimap()
  if LyoruneNews then LyoruneNews:Hide() end
  assert(ok, err)
end)

step("C34 lot 1 : places d'origine sans chevauchement (trois bandes en Tuile et Carre, bord gauche en Barre et Bandeau)", function()
  local keys = { "shape", "width", "height", "fontSize", "powerHeight", "corners", "manaBars", "hotStyle", "hotCount",
    "debuffCount", "text", "showClassIcon", "lowManaHealers", "autoShrink", "showLeader", "showRole", "missingBuffs" }
  local old = { placement = CopyTable(Z.db.placement), cornerSpells = Z.db.cornerSpells[Z.class] }
  for _, key in ipairs(keys) do old[key] = Z.db[key] end
  local db, b = Z.db, Z.buttons[1]
  local ok, err = pcall(function()
    -- Rectangle de chaque morceau, recalculé à partir des ancres notées par le faux client (sans Placement.lua)
    local W, H
    local Rect
    local function Spot(r, point)
      local x = point:find("LEFT") and r[1] or point:find("RIGHT") and r[2] or (r[1] + r[2]) / 2
      local y = point:find("BOTTOM") and r[3] or point:find("TOP") and r[4] or (r[3] + r[4]) / 2
      return x, y
    end
    local function Anchor(region, p)
      local relative, relPoint, x, y
      if type(p[2]) == "table" then
        relative = p[2]
        if type(p[3]) == "string" then relPoint, x, y = p[3], p[4], p[5] else relPoint, x, y = p[1], p[3], p[4] end
      else relative, relPoint, x, y = region._parent, p[1], p[2], p[3] end
      local px, py = Spot(Rect(relative), relPoint)
      return px + (x or 0), py + (y or 0)
    end
    function Rect(region)
      if region == b then return { 0, W, 0, H } end
      if region._all then return Rect(region._all) end
      local points = region._points
      if points.TOPLEFT and points.BOTTOMRIGHT then
        local left, top = Anchor(region, points.TOPLEFT)
        local right, bottom = Anchor(region, points.BOTTOMRIGHT)
        return { left, right, bottom, top }
      end
      local p = region._point
      local x, y = Anchor(region, p)
      local w, h = region._w, region._kind == "FontString" and region._size or region._h
      local left = p[1]:find("LEFT") and x or p[1]:find("RIGHT") and x - w or x - w / 2
      local bottom = p[1]:find("BOTTOM") and y or p[1]:find("TOP") and y - h or y - h / 2
      return { left, left + w, bottom, bottom + h, point = p[1] }
    end
    -- Toujours là (1) et alertes (2) ; une alerte peut couvrir les « petits » (nom, vie, rôle, classe, chef, type)
    local FAMILY = { name = 1, text = 1, role = 1, class = 1, leader = 1, hots = 1, debuffs = 1, dispelType = 1, buff = 1,
      lowMana = 2, big = 2, controls = 2, center = 2, defensives = 2 }
    local SOFT = { name = true, text = true, role = true, class = true, leader = true, dispelType = true }
    local function Parts(key)
      local list = {}
      if key == "hots" then for i = 1, Z.HotSlots() do list[i] = Z.HotIcon(b, i) end
      elseif key == "debuffs" then for i = 1, Z.DebuffSlots() do list[i] = Z.DebuffIcon(b, i) end
      elseif key == "defensives" then for i = 1, Z.DEFENSIVE_COUNT do list[i] = Z.DefensiveIcon(b, i) end
      elseif key == "big" then list[1] = Z.BigIcon(b)
      elseif key == "buff" then list[1] = Z.BuffIcon(b)
      elseif key == "controls" then list[1] = Z.ControlIcon(b)
      elseif key == "dispelType" then list[1] = Z.DispelTypeIcon(b)
      elseif key == "lowMana" then list = { b.lowMana, Z.DrinkIcon(b) }
      else list[1] = b[key] end
      return list
    end
    -- Lettres réelles : Z.LETTERS tailles de police de haut ; chiffre de vie : Z.DIGITS de large
    local function Letters(key, r)
      if key ~= "name" and key ~= "text" then return r end
      local font = db.fontSize - (key == "text" and 1 or 0)
      local h, cy = math.ceil(font * Z.LETTERS), (r[3] + r[4]) / 2
      local out = { r[1], r[2], cy - h / 2, cy + h / 2 }
      if key == "text" then
        local w = math.min(r[2] - r[1], math.ceil(db.fontSize * Z.DIGITS))
        if r.point:find("RIGHT") then out[1] = r[2] - w elseif r.point:find("LEFT") then out[2] = r[1] + w
        else local cx = (r[1] + r[2]) / 2 out[1], out[2] = cx - w / 2, cx + w / 2 end
      end
      return out
    end
    local function Over(a, c) return a[1] < c[2] - 0.01 and c[1] < a[2] - 0.01 and a[3] < c[4] - 0.01 and c[3] < a[4] - 0.01 end
    local checked = 0
    local function Check(label)
      for _, power in ipairs({ false, true }) do
        b.powerShown = power
        Z.StyleButton(b)
        W, H = Z.CellSize()
        local all = {}
        for key in pairs(FAMILY) do
          all[key] = {}
          for i, part in ipairs(Parts(key)) do all[key][i] = Letters(key, Rect(part)) end
        end
        local inline = Z:Shape().inline
        for a, fa in pairs(FAMILY) do
          for c, fc in pairs(FAMILY) do
            local badge = inline and a == "leader" and c == "role" -- le badge du chef, posé sur le coin du rôle
            local forbidden = (fa == 1 and fc == 1) or (fa ~= fc and ((fa == 1 and not SOFT[a]) or (fc == 1 and not SOFT[c])))
            if a < c and forbidden and not badge and Z.ElementShown(a) and Z.ElementShown(c) then
              for i, ra in ipairs(all[a]) do
                for j, rc in ipairs(all[c]) do
                  assert(not Over(ra, rc), string.format("%s%s : %s %d sur %s %d", label, power and ", mana" or "", a, i, c, j))
                  checked = checked + 1
                end
              end
            end
          end
        end
      end
    end
    db.placement, db.autoShrink, db.manaBars, db.lowManaHealers = {}, false, "ALL", 20
    db.showLeader, db.showRole, db.missingBuffs = true, true, true
    db.cornerSpells[Z.class] = nil
    local function Reset(shape, width, height)
      Z:ApplyShape(shape)
      db.width, db.height = width or db.width, height or db.height
      db.corners, db.hotStyle, db.hotCount, db.debuffCount, db.text, db.showClassIcon = "SQUARE", "ICONS", 4, 2, "DEFICIT", false
      db.cornerSpells[Z.class] = nil
    end
    for _, shape in ipairs({ "BAR", "TILE", "SQUARE", "BANNER" }) do
      local s = Z.shapes[shape]
      local sizes = { { s.width, s.height }, { Z.limits.width[2], Z.limits.height[2] }, { s.width, Z.limits.height[2] },
        { Z.limits.width[2], s.height } }
      if not s.inline then sizes[#sizes + 1] = { s.width, 40 } end
      for _, size in ipairs(sizes) do
        Reset(shape, size[1], size[2]) Z:Refresh()
        Check(shape .. " " .. size[1] .. "x" .. size[2])
      end
      -- Autres réglages, à la taille d'origine de la forme
      local variants = {
        { "classe", function() db.showClassIcon = true end },
        { "angles arrondis", function() db.corners = "ROUND" end },
        { "sans chiffre de vie", function() db.text = "NONE" end },
        { "6 soins, 5 affaiblissements", function() db.hotCount, db.debuffCount = 6, 5 end },
        { "police 14", function() db.fontSize = 14 end },
      }
      -- Carré : quatre carrés de coin ne laissent plus la place (icônes déjà à leur plus petite taille)
      if shape ~= "SQUARE" then
        variants[#variants + 1] = { "coins pris", function()
          db.cornerSpells[Z.class] = { TOPLEFT = "Rénovation", TOPRIGHT = "Rénovation", BOTTOMRIGHT = "Rénovation", BOTTOMLEFT = "Rénovation" }
        end }
      end
      for _, variant in ipairs(variants) do
        Reset(shape, s.width, s.height) variant[2]() Z:Refresh()
        Check(shape .. " " .. variant[1])
      end
    end
    assert(checked > 10000, "trop peu de verifications : " .. checked)

    -- Tuile : la vie sous le nom ; sans chiffre de vie, les bandes s'agrandissent et les icônes aussi
    Reset("TILE") Z:Refresh()
    local rows = Z.AuraRows()
    assert(rows.mode == "LINE" and rows.homes.name.y > 0 and rows.homes.text.y < 0, "Tuile : vie sous le nom")
    local size = rows.hots.size
    db.text = "NONE" Z:Refresh()
    assert(Z.AuraRows().hots.size > size, "sans chiffre de vie, les icones ne grandissent pas")
    -- Barre : le rôle remonte au-dessus du buff, la mana basse se pose sur lui, la boisson à côté vers l'intérieur
    Reset("BAR") Z:Refresh()
    rows = Z.AuraRows()
    assert(rows.homes.role.y > 0 and rows.homes.lowMana.y == rows.homes.role.y and rows.homes.lowMana.x == rows.homes.role.x, "Barre : role et mana basse")
    local x, _, drinkSize = Z.DrinkPlace(b)
    assert(x == rows.homes.lowMana.x + drinkSize + 2, "Barre : boisson a cote de la mana basse")
    -- Un élément agrandi dans l'éditeur garde sa taille au-delà de sa bande
    Reset("TILE") Z:Refresh()
    local role = Z.AuraRows().homes.role.w
    Z.SetElementSize("role", 200) Z:Refresh()
    assert(b.role._w == math.floor(role * 2 + 0.5), "role agrandi : " .. b.role._w)
  end)
  db.placement, db.cornerSpells[Z.class] = old.placement, old.cornerSpells
  for _, key in ipairs(keys) do db[key] = old[key] end
  b.powerShown = nil
  Z:Refresh()
  assert(ok, err)
end)

step("C34 lot 2 : anciens placements gardes au pixel pres, placements par personnage", function()
  local keys = { "shape", "width", "height", "fontSize", "powerHeight", "autoShrink", "showClassIcon", "dispelIcon",
    "showLeader", "showRole", "missingBuffs", "manaBars", "hotStyle", "bossDebuffs" }
  local db = Z.db
  local old = { placement = db.placement, placements = db.placements }
  for _, key in ipairs(keys) do old[key] = db[key] end
  local ok, err = pcall(function()
    local function Box(spec, dx, dy)
      local point, x, y, w, h = spec[1], spec[2] + dx, spec[3] + dy, spec[4], spec[5]
      local left = point:find("LEFT") and x or point:find("RIGHT") and x - w or x - w / 2
      local bottom = point:find("BOTTOM") and y or point:find("TOP") and y - h or y - h / 2
      return { left, left + w, bottom, bottom + h }
    end
    local function Spot(r, point)
      return point:find("LEFT") and r[1] or point:find("RIGHT") and r[2] or (r[1] + r[2]) / 2,
        point:find("BOTTOM") and r[3] or point:find("TOP") and r[4] or (r[3] + r[4]) / 2
    end
    local ROWS = { hots = true, debuffs = true, defensives = true, controls = true }
    local function Measure(spec, key, rows)
      if ROWS[key] then return rows[key].size end
      if key == "leader" then return rows.leaderW end
      if key == "buff" then return rows.buffW end
      return spec[4]
    end
    local saved = { role = { -3, -2, 150 }, name = { 0, 2 }, text = { -1, 1 }, hots = { 1, 0, 120 }, debuffs = { 0, 0, 80 },
      buff = { 2, 1 }, leader = { -1, 0 }, lowMana = { 0, 1, 130 }, big = { 4, 0 }, dispelType = { 0, -1 },
      class = { 1, 0, 110 }, center = { 0, 0, 90 }, defensives = { -2, 0 }, controls = { 0, 0, 120 }, marker = { 0, -2 } }
    local checked, report = 0, {}
    for _, shape in ipairs({ "TILE", "SQUARE", "BAR", "BANNER" }) do
      for _, variant in ipairs({ "moved", "plain" }) do
        db.shape = shape
        for _, key in ipairs(Z.shapeKeys) do db[key] = Z.shapes[shape][key] end
        db.autoShrink, db.showClassIcon, db.dispelIcon, db.showLeader = false, true, true, true
        db.showRole, db.missingBuffs, db.manaBars, db.hotStyle, db.bossDebuffs = true, true, "ALL", "ICONS", true
        db.placement = { [shape] = variant == "moved" and CopyTable(saved) or { hots = { 0, 0, 130 }, debuffs = { 0, 0, 120 } } }
        Z.ForgetPlacementRanges()
        local power = true
        -- où chaque élément était, avec les règles de la 1.48.1
        local before = Z.OldPlacementOrigins(power)
        local roleAt = db.placement[shape].role or { 0, 0 }
        before = Z.OldPlacementOrigins(power, Box(before.role, roleAt[1], roleAt[2]))
        local want = {}
        for key, at in pairs(db.placement[shape]) do
          if key ~= "marker" then
            want[key] = { rect = Box(before[key], at[1], at[2]), size = before.rowSize[key] or before[key][4] }
          end
        end
        -- une autre forme enregistrée, réglée à ses tailles d'origine : migrée aussi
        local other = shape == "TILE" and "BAR" or "TILE"
        db.placement[other] = { big = { 2, 0 } }
        Z.MigratePlacement()
        assert(db.shape == shape and db.width == Z.shapes[shape].width and db.autoShrink == false, "reglages rendus")
        assert(db.placement[other] and db.placement[other].big, "autre forme gardee")
        Z.ForgetPlacementRanges()
        local rows = Z.AuraRows()
        local now = Z.PlacementOrigins(power)
        local rx, ry = Z.Offset("role")
        now = Z.PlacementOrigins(power, Box(now.role, rx, ry))
        for key, w in pairs(want) do
          local dx, dy = Z.Offset(key)
          local rect = Box(now[key], dx, dy)
          local size = Measure(now[key], key, rows)
          local x1, y1 = Spot(rect, now[key][1])
          local x2, y2 = Spot(w.rect, now[key][1])
          -- nom et vie : leur largeur suit la case ; une rangée que les nouvelles règles bornent (elle ne couvre
          -- plus le chef ni le buff) peut être plus petite, jamais plus grande, toujours partie du même coin
          local text = key == "name" or key == "text"
          local wrong = not text and size ~= w.size and not (ROWS[key] and size < w.size)
          if wrong or math.abs(x1 - x2) > 0.5 or math.abs(y1 - y2) > 0.5 then
            report[#report + 1] = shape .. " " .. variant .. " " .. key .. " taille " .. size .. "/" .. w.size .. " place " .. x1 .. "," .. y1 .. " / " .. x2 .. "," .. y2
          end
          checked = checked + 1
        end
        local marker = (db.placement[shape] or {}).marker
        assert(variant == "plain" or marker[2] == -2, "marqueur inchange")
      end
    end
    assert(#report == 0, table.concat(report, " | "))
    assert(checked > 60, "elements verifies : " .. checked)
    -- Code de partage d'avant la 1.49.0 : ses placements passent aussi ; un code d'aujourd'hui porte « pv=n2 »
    db.shape = "TILE"
    for _, key in ipairs(Z.shapeKeys) do db[key] = Z.shapes.TILE[key] end
    db.placement = {}
    local backup = db.importBackup
    assert(Z:Import("Lyorune2;p.TILE.lowMana=s0%2C0"), "ancien code")
    local lx = db.placement.TILE.lowMana[1]
    assert(lx < -20, "mana basse gardee en bas a gauche : " .. lx)
    assert(Z:Export():find(";pv=n2;", 1, true), "code marque")
    db.placement = {}
    assert(Z:Import("Lyorune2;pv=n2;p.TILE.lowMana=s0%2C0") and db.placement.TILE.lowMana[1] == 0, "code d'aujourd'hui tel quel")
    db.importBackup = backup

    -- Passage une seule fois, à la connexion ; les profils perdent leur ancienne copie des placements
    local savedDB, savedChar, version = LyoruneDB, LyoruneCharDB, Z.version
    local ok2, err2 = pcall(function()
      local up = { lastVersion = "1.48.1", placement = { TILE = { role = { 2, 0 } } }, profiles = { Raid = { width = 90, placement = { TILE = { big = { 1, 1 } } } }, Solo = { placement = { TILE = { role = { 2, 0 } } } } } }
      LyoruneDB = up Z.version = "1.49.0" Z.placementPending = nil
      FireEvent("ADDON_LOADED", "Lyorune")
      local me = Z.CharKey()
      assert(Z.placementPending and up.placements[me] and up.placement == up.placements[me], "passage prevu, placements du personnage")
      assert(up.placements[me].TILE.role[1] == 2, "copie des placements du compte")
      assert(up.profiles.Raid.placement == nil and up.profiles.Raid.width == 90 and up.profiles.Solo.placement == nil, "profils sans placements")
      assert(up.placements["Profil : Raid"].TILE.big and not up.placements["Profil : Solo"], "placements d'un profil gardes s'ils different")
      assert(#Z.placementProfiles == 1, "placements du profil passes a la connexion")
      Z.placementPending, Z.placementProfiles = nil, nil
      up.lastVersion = "1.49.0" FireEvent("ADDON_LOADED", "Lyorune")
      assert(not Z.placementPending, "passage rejoue")
      -- un autre personnage : ses placements, copiables
      up.placements["Autre-Mon Royaume"] = { BAR = { name = { 1, 1 } } }
      up.placements["Vide-Mon Royaume"] = {}
      local list = Z.PlacementCharacters()
      assert(#list == 2 and list[1] == "Autre-Mon Royaume" and list[2] == "Profil : Raid", "liste des autres personnages")
      local mine = Z.db.placement
      assert(Z.CopyPlacements("Autre-Mon Royaume") and Z.db.placement == mine and mine.BAR.name[1] == 1 and mine.TILE == nil, "copie")
      assert(mine.BAR ~= up.placements["Autre-Mon Royaume"].BAR, "copie, pas un lien")
      assert(not Z.CopyPlacements(me) and not Z.CopyPlacements("Personne"), "copie refusee")
      -- annuler un import : les placements ne reviennent qu'au personnage qui a importé
      Z.db.importBackup = { settings = {}, placement = { TILE = { role = { 9, 9 } } }, placementOwner = "Autre-Mon Royaume" }
      assert(Z:UndoImport() and Z.db.placement == mine and mine.BAR.name[1] == 1, "annulation d'un autre personnage")
      Z.db.importBackup = { settings = {}, placement = { TILE = { role = { 9, 9 } } }, placementOwner = me }
      assert(Z:UndoImport() and Z.db.placement.TILE.role[1] == 9, "annulation du personnage")
      Z.db.placement = mine
      -- une annulation remplace la table : la déconnexion garde quand même les placements du personnage
      Z.db.placement = { SQUARE = { big = { 3, 3 } } }
      FireEvent("PLAYER_LOGOUT")
      assert(up.placements[me].SQUARE.big[1] == 3, "placements gardes a la deconnexion")
      -- un nouveau personnage reçoit une copie des derniers placements
      up.placements[me] = nil
      FireEvent("ADDON_LOADED", "Lyorune")
      assert(up.placements[me].SQUARE.big[1] == 3, "nouveau personnage")
    end)
    LyoruneDB, LyoruneCharDB, Z.version, Z.placementPending = savedDB, savedChar, version, nil
    FireEvent("ADDON_LOADED", "Lyorune")
    assert(ok2, err2)
  end)
  db = Z.db
  db.placement, db.placements = old.placement, old.placements
  if type(db.placements) == "table" then db.placements[Z.CharKey()] = db.placement end
  for _, key in ipairs(keys) do db[key] = old[key] end
  Z.ForgetPlacementRanges()
  Z:Refresh()
  assert(ok, err)
  -- L'éditeur : le bouton de copie, sans autre personnage, le dit
  Z:OpenPlacement()
  local win = Z:PlacementWindow()
  assert(win.copy, "bouton de copie")
  win.copy:Run("OnClick")
  assert(win.size:GetText():find("Aucun autre", 1, true), "message sans autre personnage : " .. tostring(win.size:GetText()))
  win:Hide()
end)

step("1.50.0 : canal des soigneurs (eteint au depart, rejoint, nom de secours, quitte, /leave)", function()
  local db, char = Z.db, Z.char
  assert(db.channelFR == false and db.channelEN == false, "canaux eteints au depart")
  FireEvent("PLAYER_ENTERING_WORLD") -- le premier regard attend que le jeu ait remis ses canaux
  assert(#CHANNEL_CALLS == 0, "canal rejoint sans action du joueur")
  assert(Z.notInProfile.channelFR and Z.notInProfile.channelEN and Z.notInProfile.channelLocks, "canal dans les profils")
  -- case cochee : LyoruneFR rejoint, dans la fenetre principale, avec la ligne qui dit comment y ecrire
  db.channelFR = true Z:RefreshAlerts()
  assert(GetChannelName("LyoruneFR") > 0 and char.channels.FR == "LyoruneFR", "LyoruneFR pas rejoint")
  assert(PRINTED[#PRINTED]:find("LyoruneFR rejoint", 1, true), "ligne d'aide : " .. PRINTED[#PRINTED])
  assert(DEFAULT_CHAT_FRAME.added[#DEFAULT_CHAT_FRAME.added] == "LyoruneFR", "pas dans la fenetre de discussion")
  Z:RefreshAlerts()
  assert(#CHANNEL_CALLS == 1, "rejoint deux fois")
  -- canal anglais verrouille par un inconnu : nom de secours, nom refuse retenu un jour
  LOCKED_CHANNELS.LyoruneEN = true
  db.channelEN = true Z:RefreshAlerts()
  assert(char.channels.EN == "LyoruneEN2" and GetChannelName("LyoruneEN2") > 0, "nom de secours : " .. tostring(char.channels.EN))
  assert(db.channelLocks["Alliance-Mon Royaume"].LyoruneEN, "nom refuse oublie")
  -- la Horde a son propre LyoruneEN : le refus de l'Alliance ne la concerne pas
  FACTION = "Horde"
  db.channelEN, char.channels.EN = false, nil
  CHANNELS.lyoruneen2 = nil
  LOCKED_CHANNELS = {}
  db.channelEN = true Z:RefreshAlerts()
  assert(char.channels.EN == "LyoruneEN", "Horde : nom refuse par l'Alliance saute")
  db.channelEN = false Z:RefreshAlerts()
  FACTION = "Alliance"
  LOCKED_CHANNELS.LyoruneEN = true
  db.channelEN = true Z:RefreshAlerts()
  assert(char.channels.EN == "LyoruneEN2", "Alliance : nom de secours perdu")
  local knocks = #CHANNEL_CALLS
  Z:RefreshAlerts()
  assert(#CHANNEL_CALLS == knocks, "nom refuse redemande")
  -- la page dit ou ecrire
  SlashCmdList.LYORUNE("")
  local w = Z:OptionsWindow()
  w.Select("Les amis de Lyorune")
  local box = OptionPart("rules")
  assert(box and box.where, "partie du canal absente")
  box:Update()
  local text = box.where:GetText()
  assert(text:find("/4 LyoruneFR", 1, true) and text:find("LyoruneEN2", 1, true), "page : " .. text)
  -- un autre addon renumerote les canaux : la page ouverte suit
  CHANNELS.lyorunefr = 12
  FireEvent("CHANNEL_UI_UPDATE")
  assert(box.where:GetText():find("/12 LyoruneFR", 1, true), "renumerotation : " .. box.where:GetText())
  CHANNELS.lyorunefr = 4
  -- case decochee : Lyorune quitte le sien, jamais un canal rejoint a la main
  db.channelEN = false Z:RefreshAlerts()
  assert(GetChannelName("LyoruneEN2") == 0 and not char.channels.EN, "LyoruneEN2 pas quitte")
  CHANNELS.lyoruneen = 9
  Z:RefreshAlerts()
  assert(GetChannelName("LyoruneEN") == 9, "canal rejoint a la main quitte")
  CHANNELS.lyoruneen = nil
  -- /leave du joueur : la case se decoche, Lyorune ne le fait pas revenir
  PlayerLeavesChannel("LyoruneFR")
  assert(db.channelFR == false and not char.channels.FR, "case pas decochee apres /leave")
  Z:RefreshAlerts()
  assert(GetChannelName("LyoruneFR") == 0, "le joueur revient de force")
  -- case decochee sur un autre personnage : le jeu remet le canal a la connexion, Lyorune le quitte
  char.channels.FR = "LyoruneFR"
  GameRejoinsChannel("LyoruneFR")
  assert(GetChannelName("LyoruneFR") == 0 and not char.channels.FR, "canal remis par le jeu garde")
  -- remis par le jeu, case cochee : garde, sans ligne d'aide ni ajout a la fenetre
  local added, printed = #DEFAULT_CHAT_FRAME.added, #PRINTED
  db.channelFR = true
  GameRejoinsChannel("LyoruneFR")
  assert(char.channels.FR == "LyoruneFR" and #DEFAULT_CHAT_FRAME.added == added and #PRINTED == printed, "canal remis par le jeu : fenetre ou ligne")
  db.channelFR = false Z:RefreshAlerts()
  -- dix canaux : le jeu ne repond pas, la demande est oubliee et le joueur prevenu
  CHANNELS_FULL = true
  db.channelEN = true Z:RefreshAlerts()
  assert(PRINTED[#PRINTED]:find("dix canaux", 1, true) and not char.channels.EN, "dix canaux : " .. PRINTED[#PRINTED])
  CHANNELS_FULL = nil
  Z:RefreshAlerts()
  assert(char.channels.EN == "LyoruneEN2", "nouvel essai apres dix canaux")
  db.channelEN = false Z:RefreshAlerts()
  box:Update()
  assert(box.where:GetText() == "Aucun canal rejoint pour l'instant.", "page : " .. box.where:GetText())
  -- trois noms verrouilles : un message, aucun essai de plus
  for _, name in ipairs({ "LyoruneFR", "LyoruneFR2", "LyoruneFR3" }) do LOCKED_CHANNELS[name] = true end
  db.channelFR = true Z:RefreshAlerts()
  assert(PRINTED[#PRINTED]:find("trois noms", 1, true) and not char.channels.FR, "tous verrouilles")
  knocks = #CHANNEL_CALLS
  Z:RefreshAlerts()
  assert(#CHANNEL_CALLS == knocks, "noms verrouilles redemandes")
  -- un jour plus tard : nouvel essai
  local locks = db.channelLocks["Alliance-Mon Royaume"]
  for name in pairs(locks) do locks[name] = locks[name] - 86400 end
  LOCKED_CHANNELS = {}
  Z:RefreshAlerts()
  assert(char.channels.FR == "LyoruneFR", "pas de nouvel essai apres un jour")
  for _, key in ipairs({ "Ouverts à tous, quelle que soit la langue de votre jeu : le français, l'anglais ou les deux, à votre choix. Le jeu sépare l'Alliance et la Horde : chaque faction a son canal.",
    "Pour y écrire : %s.", "Aucun canal rejoint pour l'instant.", "%s rejoint : écrivez /%d suivi de votre message.",
    "%s est verrouillé par un autre joueur : Lyorune passe à %s.",
    "%s : le jeu n'a pas ouvert le canal. Vous avez peut-être déjà dix canaux : quittez-en un, puis recochez la case.", "Vous avez quitté %s : la case « %s » est décochée.",
    "%s : les trois noms du canal sont verrouillés par d'autres joueurs. Lyorune réessaiera demain." }) do
    assert(Z.translations.enUS[key], "sans traduction anglaise : " .. key)
  end
  w:Hide()
  db.channelFR, db.channelLocks, CHANNELS, CHANNEL_CALLS = false, {}, {}, {}
  char.channels = {}
end)

step("1.50.1 : cases creees d'avance hors combat (joueur arrive en combat : action bloquee par le jeu)", function()
  -- Le jeu cree des cases d'avance quand la liste commence avant le premier joueur (startingIndex negatif), avec le
  -- calcul de SecureGroupHeaders.lua (ici sans aucun joueur) : min(unitsPerColumn * colonnes, places), colonnes
  -- limitees par maxColumns. En combat, cette creation est refusee : tout doit etre pret avant.
  local old = { layout = Z.db.layout, tanks = Z.db.showTanks }
  local active, refuse, made, fake = true, false, 0, {}
  local function Update(h)
    if not active then return end
    local places = 1 - (h:GetAttribute("startingIndex") or 1)
    if places < 1 then return end
    if refuse then error("refus du jeu") end
    local perColumn = h:GetAttribute("unitsPerColumn") or places
    local columns = math.min(math.ceil(places / perColumn), h:GetAttribute("maxColumns") or 1)
    for i = 1, math.min(perColumn * columns, places) do
      if not h:GetAttribute("child" .. i) then
        assert(not InCombatLockdown(), "case creee en combat")
        h:SetAttribute("child" .. i, CreateFrame("Button", nil, h))
        fake[#fake + 1] = { h, i }
        made = made + 1
      end
      h:GetAttribute("child" .. i):SetAttribute("unit", "party1") -- le jeu y range les joueurs du groupe
    end
  end
  local headers = {}
  for _, h in ipairs(Z.headers) do
    if not h.def.extra then
      headers[#headers + 1] = h
      h:SetScript("OnAttributeChanged", function(self, name)
        if name == "_ignore" or name:find("^child") or self:GetAttribute("_ignore") then return end
        if self:IsVisible() then Update(self) end
      end)
      h:HookScript("OnShow", Update)
    end
  end
  local function Count(h)
    local n = 0
    while h:GetAttribute("child" .. (n + 1)) do n = n + 1 end
    return n
  end
  local ok, err = pcall(function()
    Z.db.layout, Z.db.showTanks = "GROUP", true
    -- le jeu refuse (ou interface masquee) : le cadre revient au premier joueur, et le reglage suivant recommence
    refuse = true
    Z:Refresh()
    refuse = false
    for _, h in ipairs(headers) do
      assert((h:GetAttribute("startingIndex") or 1) == 1, h.def.key .. " : liste pas revenue apres un refus")
    end
    Z:Refresh()
    for _, h in ipairs(headers) do
      local want = (h.def.key == "main" or h.def.raid) and 5 or h.def.key == "tanks" and 40 or 0
      assert(Count(h) >= want, h.def.key .. " : " .. Count(h) .. " cases pour " .. want)
      assert((h:GetAttribute("startingIndex") or 1) == 1, h.def.key .. " : liste pas revenue au premier joueur")
    end
    assert(not Z.headers[2]:IsShown(), "cadre de raid montre hors raid pour preparer ses cases")
    -- cadre cache : ses cases ne gardent aucun joueur (elles ecouteraient ses evenements pour rien)
    for _, h in ipairs(headers) do
      if not h:IsShown() then
        local i = 1
        while h:GetAttribute("child" .. i) do
          assert(h:GetAttribute("child" .. i):GetAttribute("unit") ~= "party1", h.def.key .. " : case cachee avec un joueur")
          i = i + 1
        end
      end
    end
    made = 0
    Z:Refresh()
    assert(made == 0, "cases recreees : " .. made)
    Z.db.layout = "GRID"
    Z:Refresh()
    assert(Count(Z.headers[2]) >= 40, "grille : " .. Count(Z.headers[2]) .. " cases")
    Z.db.layout = "ROLE"
    Z:Refresh()
    for i = 2, 5 do assert(Count(Z.headers[i]) >= 40, "par role : cadre " .. i .. " avec " .. Count(Z.headers[i]) .. " cases") end
  end)
  active = false
  for _, h in ipairs(headers) do h:SetScript("OnAttributeChanged", nil) end
  for _, f in ipairs(fake) do f[1]:GetAttribute("child" .. f[2]):Hide() f[1]:SetAttribute("child" .. f[2], nil) end
  Z.db.layout, Z.db.showTanks = old.layout, old.tanks
  Z:Refresh()
  assert(ok, err)
end)

step("1.50.2 : buffs manquants recoches une fois, choix suivant garde, diagnostic sur la case visible", function()
  local savedDB, savedChar, version = LyoruneDB, LyoruneCharDB, Z.version
  local fine, why = pcall(function()
    local db = { lastVersion = "1.50.1", buffPanel = false, missingBuffs = false }
    LyoruneDB = db
    Z.version = "1.50.2" FireEvent("ADDON_LOADED", "Lyorune")
    assert(db.buffPanel == true and db.missingBuffs == true, "1.50.1 : buffs manquants pas recoches")
    db.lastVersion, db.buffPanel = "1.50.2", false FireEvent("ADDON_LOADED", "Lyorune")
    assert(db.buffPanel == false, "choix du joueur ecrase apres la 1.50.2")
  end)
  Z.version = version
  LyoruneDB, LyoruneCharDB = savedDB, savedChar
  FireEvent("ADDON_LOADED", "Lyorune")
  assert(fine, why)
  -- une case cachee qui porte le meme joueur ne prend pas la place de la case visible dans /lyorune buffs
  local visible
  for _, b in ipairs(Z.buttons) do if b.unit and not b.extra and b:IsVisible() then visible = b break end end
  assert(visible, "aucune case visible pour l'essai")
  local before = Z.BuffDiagnostic()[2]
  local ghost = { unit = visible.unit, IsVisible = function() return false end }
  table.insert(Z.buttons, 1, ghost)
  local ok, lines = pcall(Z.BuffDiagnostic)
  table.remove(Z.buttons, 1)
  assert(ok, lines)
  assert(lines[2] == before, "case cachee comptee a la place de la visible : " .. lines[2])
end)

step("1.51.0 : affaiblissements Toujours montres (Ame affaiblie et Longanimite pour toutes les classes, liste, recherche)", function()
  local old = { create = CreateFrame, class = Z.class, name = C_Spell.GetSpellName, anchor = AnchorUtil, sort = AuraContainerSortMethod,
    util = AuraUtil, policy = CustomAuraContainerAuraProcessingPolicy }
  local saved = { shown = Z.db.shownDebuffs, seen = Z.db.debuffsSeen, important = Z.db.importantNames, ignored = Z.db.ignoredNames }
  local form = {}
  for _, key in ipairs({ "debuffMode", "dispelCount", "debuffCount", "showDebuffs", "showHots", "showLockouts", "showDispel" }) do
    form[key] = Z.db[key]
  end
  local made = {}
  local ok, err = xpcall(function()
    C_Spell.GetSpellName = function(id)
      if id == 25771 then return "Longanimité" end
      if id == 31337 then return "Mal de mer" end
      return old.name(id)
    end
    Z.db.shownDebuffs, Z.db.debuffsSeen, Z.db.importantNames, Z.db.ignoredNames = {}, {}, {}, {}
    Z.db.showDebuffs, Z.db.showDispel = true, false
    -- 1. Donnees : Longanimite n'est plus ignoree ; le depart vaut pour toutes les classes, par numero
    assert(not Z.ignoredDebuffs[25771], "Longanimite encore ignoree")
    Z.class = "DRUID" Z:BuildData() Z:Refresh()
    assert(Z.ShownIds()[6788] and Z.ShownIds()[25771], "depart absent pour un druide")
    -- 2. Places : une en tete hors de Tous ; Utiles jamais plus long que Tous
    Z.db.dispelCount, Z.db.debuffCount = 2, 3
    Z.db.debuffMode = "ALL" assert(Z.DebuffSlots() == 4, "places (Tous)")
    Z.db.debuffMode = "USEFUL" assert(Z.DebuffSlots() == 4, "places (Utiles)")
    Z.db.debuffMode = "DISPEL" assert(Z.DebuffSlots() == 3, "places (Ceux que je dissipe)")

    -- 3. Ancien affichage, druide : Ame affaiblie montree dans les trois modes
    local b = Z.buttons[1]
    AURAS = {}
    local soul = { name = "Âme affaiblie", icon = 66, auraInstanceID = 91, spellId = 6788, duration = 15 }
    local burn = { name = "Brûlure", icon = 3, auraInstanceID = 92, spellId = 9001, duration = 12 }
    AURAS["HARMFUL"] = { burn, soul }
    local function icons()
      local list = {}
      for i = 1, #b.debuffs do if b.debuffs[i]:IsShown() then list[#list + 1] = b.debuffs[i].texture._tex end end
      return table.concat(list, ",")
    end
    Z.db.debuffMode = "ALL" Z:Refresh() Z.UpdateAurasNow(b)
    assert(icons() == "66,3", "Tous : " .. icons())
    Z.db.debuffMode = "USEFUL" Z:Refresh() Z.UpdateAurasNow(b)
    assert(icons() == "66,3", "Utiles : " .. icons())
    Z.db.debuffMode = "DISPEL" Z:Refresh() Z.UpdateAurasNow(b)
    assert(icons() == "66", "Ceux que je dissipe : " .. icons())
    -- decochee : plus montree ; recochee : redevient le depart (rien de garde)
    Z.SetShown(6788, false) Z.UpdateAurasNow(b)
    assert(Z.db.shownDebuffs[6788] == false and not Z.ShownOn(6788) and icons() == "", "decochee : " .. icons())
    Z.db.debuffMode = "ALL" Z:Refresh() Z.UpdateAurasNow(b)
    assert(icons() == "3", "decochee : encore montree en Tous : " .. icons())
    Z.db.debuffMode = "DISPEL"
    Z.SetShown(6788, true) Z.UpdateAurasNow(b)
    assert(Z.db.shownDebuffs[6788] == nil and Z.ShownOn(6788) and icons() == "66", "recochee : " .. icons())
    -- gagne sur A ignorer
    Z.db.ignoredNames = { ["6788"] = true } Z.db.debuffMode = "ALL" Z:Refresh() Z.UpdateAurasNow(b)
    assert(icons() == "66,3", "A ignorer gagne : " .. icons())
    Z.db.ignoredNames = {}
    -- pretre : au bout de ses soins (Z.lockouts), jamais deux fois
    Z.db.showHots, Z.db.showLockouts = true, true
    Z.class = "PRIEST" Z:BuildData() Z:Refresh()
    assert(not Z.ShownIds()[6788] and Z.ShownIds()[25771], "pretre : Ame affaiblie deux fois")
    Z.class = "DRUID" Z:BuildData() Z:Refresh()
    AURAS = {}

    -- 4. Vus sur le groupe, liste, recherche dans la langue du jeu ou par numero, resume sous le bouton
    assert(Z.db.debuffsSeen[9001] and Z.db.debuffsSeen[6788], "ancien affichage : vus non retenus")
    Z.db.debuffsSeen = {}
    Z.NoteSeenDebuffs({ { name = "Mal de mer", spellId = 31337 }, { name = MakeSecret(), spellId = MakeSecret() } })
    assert(Z.db.debuffsSeen[31337] and next(Z.db.debuffsSeen, next(Z.db.debuffsSeen)) == nil, "vus : secret retenu")
    local list = Z.ShownCatalog("")
    assert(#list == 3 and list[1].on and list[2].on and list[3].id == 31337 and not list[3].on, "liste : cochees d'abord")
    assert(#Z.ShownCatalog("MER") == 1 and #Z.ShownCatalog("6788") == 1 and #Z.ShownCatalog("rien") == 0, "recherche")
    assert(#Z.ShownCatalog("ame") == 1 and #Z.ShownCatalog("âme") == 1 and #Z.ShownCatalog("longanimite") == 1, "recherche sans accents")
    assert(Z.ShownIdFromText("Mal de mer") == 31337 and Z.ShownIdFromText("6788") == 6788
      and Z.ShownIdFromText("|cff71d5ff|Hspell:31337:0|h[Mal de mer]|h|r") == 31337, "ajout par nom, numero ou lien")
    assert(Z.ShownIdFromText("mal de mer") == 31337, "ajout par nom en minuscules")
    assert(Z.ShownIdFromText("Nom inconnu") == nil and Z.ShownIdFromText("999999") == nil, "ajout d'un inconnu")
    assert(Z.ShownSummary() == "Longanimité, Âme affaiblie" or Z.ShownSummary() == "Âme affaiblie, Longanimité", "resume : " .. Z.ShownSummary())
    Z.SetShown(31337, true)
    assert(Z.db.shownDebuffs[31337] == true and Z.ShownIds()[31337], "coche non gardee par numero")
    Z.SetShown(31337, false)
    assert(Z.db.shownDebuffs[31337] == false and #Z.ShownCatalog("") == 3, "decoche : sort de la liste")

    -- 5. Conteneurs du jeu : groupe de tete en Utiles, ecarte des autres ; parmi les autres en Tous
    local groups = {}
    CreateFrame = function(kind, fname, parent, template)
      local f = old.create(kind, fname, parent, template)
      if kind ~= "AuraContainer" then return f end
      function f:AddAuraGroup(key, filter, options)
        groups[key] = { candidates = options.candidateFilters, max = options.maxFrameCount }
      end
      function f:AddAuraSlot() return old.create("Button", nil, self) end
      function f:SetAuraProcessingPolicy() end
      function f:SetEnabled() end
      function f:SetUnit() end
      function f:UpdateAllAuras() end
      return f
    end
    AuraContainerSortMethod = { Default = 0 }
    AnchorUtil = { FlowDirection = { Right = 1, Left = 2, Up = 3, Down = 4 }, FlowLayoutAxis = { Horizontal = 1, Vertical = 2 } }
    AuraUtil = { AuraUpdateChangedType = { Debuff = 7 } }
    CustomAuraContainerAuraProcessingPolicy = { ProcessAura = 2 }
    Enum.CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 1, Icon = 3 }
    Z.db.debuffMode = "USEFUL"
    local c = CreateFrame("Button", "LyoruneHeaderUnitButton451", Z.header)
    Z.header:InitButton(c:GetName())
    made[#made + 1] = c
    c:SetAttribute("unit", "player")
    Z:Refresh()
    local row, others = groups.listedRow, groups.others
    assert(row and row.max == 1 and row.candidates.includeSpellIDs[6788] and row.candidates.includeSpellIDs[25771], "groupe de tete")
    assert(others and others.max == 1 and others.candidates.excludeSpellIDs[6788], "doublon dans les autres")
    groups = {}
    Z.db.debuffMode = "ALL" Z:Refresh()
    assert(groups.listedRow and groups.listedRow.candidates.includeSpellIDs[6788] and groups.others.candidates.excludeSpellIDs[6788],
      "Tous : pas en tete")
    -- decochee : ignoree partout (pas meme parmi les autres)
    Z.db.shownDebuffs[6788] = false groups = {} Z:Refresh()
    assert(not groups.listedRow.candidates.includeSpellIDs[6788] and groups.others.candidates.excludeSpellIDs[6788], "decochee montree")
    Z.db.shownDebuffs[6788] = nil
  end, debug.traceback)
  CreateFrame = old.create
  AnchorUtil, AuraContainerSortMethod, AuraUtil, CustomAuraContainerAuraProcessingPolicy = old.anchor, old.sort, old.util, old.policy
  for _, c in ipairs(made) do c:Hide() c:SetAttribute("unit", nil) end
  C_Spell.GetSpellName = old.name
  for key, value in pairs(form) do Z.db[key] = value end
  Z.db.shownDebuffs, Z.db.debuffsSeen, Z.db.importantNames, Z.db.ignoredNames = saved.shown, saved.seen, saved.important, saved.ignored
  Z.class = old.class
  AURAS = {}
  Z:BuildData() Z:Refresh() RunUpdates()
  assert(ok, err)
end)
step("C43 et C44 : role du druide d'apres ses talents (forme ignoree, synchronisation), releve avec visibilite secrete", function()
  local old = { now = NOW, class = UnitClass, roles = UnitGroupRolesAssigned, ct = rawget(_G, "C_ClassTalents"), tr = rawget(_G, "C_Traits"), grouped = GROUPED, opt = Z.db.talentRole }
  local b = Z.buttons[1]
  local ok, err = pcall(function()
    assert(Z.defaults.talentRole == true, "eteint au depart")
    local spent = { [11328] = 0, [11347] = 5, [11340] = 31 }
    rawset(_G, "UnitClass", function() return "Druide", "DRUID" end)
    rawset(_G, "C_ClassTalents", { GetActiveConfigID = function() return 7 end })
    rawset(_G, "C_Traits", {
      GetConfigInfo = function(id) assert(id == 7) return { treeIDs = { 42 } } end,
      GetGroupDisplayInfoByTreeID = function(tree) assert(tree == 42) return { { groupID = 11328 }, { groupID = 11347 }, { groupID = 11340 } } end,
      GetGroupCurrencyInfo = function(_, ids) return { { currencyInfos = { { spent = spent[ids[1]] } } } } end,
    })
    local game = "DAMAGER" -- le jeu : « DPS » depuis le passage en felin
    rawset(_G, "UnitGroupRolesAssigned", function() return game end)
    GROUPED = true
    local n = #ADDON_SENT
    FireEvent("TRAIT_CONFIG_UPDATED", 7)
    assert(Z.UnitRole("player") == "HEALER", "druide Restauration : " .. tostring(Z.UnitRole("player")))
    assert(#ADDON_SENT == n + 1 and ADDON_SENT[#ADDON_SENT].text == "T:H", "role non annonce au groupe")
    FireEvent("PLAYER_TALENT_UPDATE") assert(#ADDON_SENT == n + 1, "annonce repetee sans changement")
    -- icone de la case : soigneur malgre le role du jeu
    b.role.SetAtlas = function(self, atlas) self._atlas = atlas end
    Z:Refresh()
    if b.unit == "player" then assert(b.role:IsShown() and b.role._atlas == "roleicon-tiny-healer", "icone : " .. tostring(b.role._atlas)) end
    -- interrupteur coupe : le role du jeu
    Z.db.talentRole = false
    assert(Z.UnitRole("player") == "DAMAGER", "interrupteur sans effet")
    Z.db.talentRole = true
    -- Farouche : le role du jeu, qui suit la forme (ours : tank)
    spent[11347], spent[11340] = 40, 0 game = "TANK"
    FireEvent("TRAIT_CONFIG_UPDATED", 7)
    assert(Z.UnitRole("player") == "TANK" and ADDON_SENT[#ADDON_SENT].text == "T:-", "Farouche : role du jeu")
    -- Equilibre : DPS meme en ours
    spent[11347], spent[11328] = 0, 30
    FireEvent("TRAIT_CONFIG_UPDATED", 7)
    assert(Z.UnitRole("player") == "DAMAGER" and ADDON_SENT[#ADDON_SENT].text == "T:D", "Equilibre")
    -- un autre druide du groupe qui a Lyorune ; un inconnu ou un message mal forme ne change rien
    GROUP_NAMES.party1 = "Ami"
    game = "DAMAGER"
    FireEvent("CHAT_MSG_ADDON", "Lyorune", "T:H", "PARTY", "Ami")
    assert(Z.UnitRole("party1") == "HEALER", "role annonce ignore")
    FireEvent("CHAT_MSG_ADDON", "Lyorune", "T:H", "PARTY", "Etranger")
    GROUP_NAMES.party2 = "Etranger" assert(Z.UnitRole("party2") == "DAMAGER", "role d'un joueur hors du groupe") GROUP_NAMES.party2 = nil
    FireEvent("CHAT_MSG_ADDON", "Lyorune", "T:X", "PARTY", "Ami") assert(Z.UnitRole("party1") == "HEALER", "message mal forme lu")
    FireEvent("CHAT_MSG_ADDON", "Lyorune", "T:-", "PARTY", "Ami") assert(Z.UnitRole("party1") == "DAMAGER", "retour au role du jeu")
    -- joueur parti : son role est oublie (il peut revenir avec d'autres talents, ou sans Lyorune)
    FireEvent("CHAT_MSG_ADDON", "Lyorune", "T:H", "PARTY", "Ami") assert(Z.UnitRole("party1") == "HEALER")
    GROUP_NAMES.party1 = nil FireEvent("GROUP_ROSTER_UPDATE") GROUP_NAMES.party1 = "Ami"
    assert(Z.UnitRole("party1") == "DAMAGER", "role d'un joueur parti garde")
    -- en combat : lecture remise a la sortie du combat ; points illisibles : le role connu reste
    COMBAT = true spent[11328], spent[11340] = 0, 30
    FireEvent("TRAIT_CONFIG_UPDATED", 7) assert(Z.UnitRole("player") == "DAMAGER", "talents lus en combat")
    COMBAT = false FireEvent("PLAYER_REGEN_ENABLED")
    assert(Z.UnitRole("player") == "HEALER" and ADDON_SENT[#ADDON_SENT].text == "T:H", "lecture apres le combat")
    spent[11340] = MakeSecret() n = #ADDON_SENT
    FireEvent("TRAIT_CONFIG_UPDATED", 7)
    assert(Z.UnitRole("player") == "HEALER" and #ADDON_SENT == n, "points illisibles : role perdu")
    Z:RoleCommand()
    spent[11340], spent[11328] = 0, 30 FireEvent("TRAIT_CONFIG_UPDATED", 7)
    assert(Z.UnitRole("player") == "DAMAGER")
    -- nouveau venu : il recoit mon role avec ma version
    n = #ADDON_SENT NOW = NOW + 10 -- (une annonce groupee par 3 secondes au plus)
    GROUP_NAMES.party3 = "Neuf"
    FireEvent("CHAT_MSG_ADDON", "Lyorune", "V:" .. Z.version, "PARTY", "Neuf")
    local sent = false
    for i = n + 1, #ADDON_SENT do if ADDON_SENT[i].text == "T:D" then sent = true end end
    assert(sent, "nouveau venu sans mon role")
    -- rafale de nouveaux venus (arrivee dans un raid) : une seule annonce
    n = #ADDON_SENT Z.AnnounceTalentRole(true) Z.AnnounceTalentRole(true)
    assert(#ADDON_SENT == n, "annonces en rafale")
    GROUP_NAMES.party1, GROUP_NAMES.party3 = nil, nil
    -- role du jeu secret : rien
    rawset(_G, "UnitGroupRolesAssigned", function() return MakeSecret() end)
    assert(Z.UnitRole("party4") == nil, "role secret")
    Z:RoleCommand()
    -- autre classe : jamais de role tire des talents, rien d'annonce
    rawset(_G, "UnitClass", old.class)
    n = #ADDON_SENT
    FireEvent("TRAIT_CONFIG_UPDATED", 7)
    rawset(_G, "UnitGroupRolesAssigned", function() return "TANK" end)
    assert(Z.UnitRole("player") == "TANK" and #ADDON_SENT == n, "pretre : role du jeu")
    Z:RoleCommand()
    assert(Z.translations.enUS["Rôle du druide d'après ses talents"] and Z.translations.enUS["aucun"], "sans traduction anglaise")
    -- C44 : une couche dont la visibilite est secrete est decrite, sans erreur
    local layer = CreateFrame("Frame"):CreateTexture()
    b.GetSize, b.IsVisible = function() return 100, 40 end, function() return true end -- (le faux client n'a ni taille ni affichage)
    layer.GetSize = function() return 100, 40 end
    layer.IsVisible = function() return MakeSecret() end
    layer.IsObjectType = function(_, kind) return kind == "Texture" end
    b.GetRegions = function() return layer end
    Z.header:SetAttribute("child1", b)
    Z.db.frameStateDiag = nil Z:DiagnoseFrames()
    assert(table.concat(Z.db.frameStateDiag, " "):find("couche", 1, true), "couche a visibilite secrete absente du releve")
  end)
  rawset(_G, "UnitClass", old.class) rawset(_G, "UnitGroupRolesAssigned", old.roles)
  rawset(_G, "C_ClassTalents", old.ct) rawset(_G, "C_Traits", old.tr)
  GROUPED, Z.db.talentRole, NOW = old.grouped, old.opt, old.now
  b.role.SetAtlas, b.GetRegions, b.GetSize, b.IsVisible = nil, nil, nil, nil
  Z.header:SetAttribute("child1", nil) Z.db.frameStateDiag = nil
  FireEvent("TRAIT_CONFIG_UPDATED", 7)
  Z:Refresh()
  assert(ok, err)
end)

step("C48 : Remous suivi sous son numero de Forever, tous ses rangs, ancien numero garde s'il existe", function()
  local function has(list, id) for _, v in ipairs(list or {}) do if v == id then return true end end end
  assert(Z.trackedSpells.SHAMAN[1] == 408521, "Remous non suivi sous 408521")
  local ranks = Z.spellRanks[408521]
  assert(has(ranks, 1239242) and has(ranks, 1239243) and has(ranks, 22419), "rangs de Remous incomplets")
  assert(Z.clickDefaults.SHAMAN["shift-2"][1] == 408521, "clic de Remous sur l'ancien numero")
  -- noms lus dans le jeu : un numero au nom different est ignore, l'ancien numero absent ne casse rien
  local old = { class = Z.class, name = C_Spell.GetSpellName }
  local ok, err = pcall(function()
    local names = { [408521] = "Remous", [1239242] = "Remous", [1239243] = "Remous" }
    C_Spell.GetSpellName = function(id) return names[id] or old.name(id) end
    Z.class = "SHAMAN" Z:BuildData()
    local set = Z.rankIds["Remous"]
    assert(Z.trackedNames["Remous"], "Remous absent des sorts suivis")
    assert(set and set[408521] and set[1239242] and set[1239243] and not set[22419], "rangs de Remous mal lus")
    names[22419] = "Remous" Z:BuildData()
    assert(Z.rankIds["Remous"][22419], "ancien numero de Remous non garde quand il existe")
  end)
  C_Spell.GetSpellName, Z.class = old.name, old.class
  Z:BuildData()
step("36 lot 1 : /lyorune soins decrit les soins sans rien changer, et une incantation une seule fois", function()
  local Z = NS
  local old = { after = C_Timer.After, secrets = C_Secrets }
  local later = {}
  C_Timer.After = function(_, f) later[#later + 1] = f end
  rawset(_G, "C_Secrets", { ShouldAurasBeSecret = function() return MakeSecret() end })
  local ok, err = pcall(function()
    local before = #(Z.db.errors or {})
    Z.Command("soins")
    local log = Z.db.errors[1]
    assert(#Z.db.errors > before and log.kind == "Diagnostic soins", "diagnostic absent du journal")
    assert(not log.message:find("interrompu", 1, true), "diagnostic interrompu : " .. log.message)
    assert(log.message:find("auras secrètes : secret", 1, true), "valeur secrete mal decrite")
    assert(log.message:find("soins en route sur player", 1, true), "soins en route absents")
    -- une incantation : decrite une fois, puis l'ecoute s'arrete
    FireEvent("UNIT_SPELLCAST_START", "player")
    assert(#later == 2, "description de l'incantation non prevue")
    later[2]()
    assert(Z.db.errors[1].message:find("pendant l'incantation", 1, true), "incantation non decrite")
    local n = #Z.db.errors
    FireEvent("UNIT_SPELLCAST_START", "player")
    assert(#later == 2, "ecoute non arretee apres la premiere incantation")
    -- deux commandes de suite : l'attente de la premiere n'arrete pas l'ecoute de la seconde
    Z.Command("soins") later[1]()
    FireEvent("UNIT_SPELLCAST_START", "player")
    assert(#later == 4, "seconde ecoute arretee par la premiere attente")
    later[3]()
  end)
  C_Timer.After = old.after
  rawset(_G, "C_Secrets", old.secrets)
  assert(ok, err)
end)

step("36 a : soins en route, bouclier et absorption animes, ordre des couches, contraste sur barre verte, rayures", function()
  local b = CreateFrame("Button", "LyoruneHeaderUnitButton360", Z.header)
  Z.header:InitButton(b:GetName())
  local old = { color = Z.db.color, smooth = Z.db.smooth, style = Z.db.absorbStyle, class = UnitClass, cc = C_ClassColor.GetClassColor }
  local ok, err = pcall(function()
    b:SetAttribute("unit", "party1")
    Z.db.smooth = true Z:Refresh()
    Z.cellUpdates.prediction(b)
    local SMOOTH = Enum.StatusBarInterpolation.ExponentialEaseOut
    assert(b.incoming._smoothing == SMOOTH and b.absorb._smoothing == SMOOTH and b.healAbsorb._smoothing == SMOOTH,
      "soins en route, bouclier ou absorption non animes")
    Z.db.smooth = false Z:Refresh()
    Z.cellUpdates.prediction(b)
    assert(b.incoming._smoothing == nil and b.absorb._smoothing == nil, "anime malgre le reglage coupe")
    -- ordre de dessin : vie, soins en route, bouclier, rayures, absorption de soins
    local function sub(bar) return bar:GetStatusBarTexture()._sublevel end
    assert(sub(b.hp) < sub(b.incoming) and sub(b.incoming) < sub(b.absorb) and sub(b.absorb) < b.stripes._sublevel
      and b.stripes._sublevel < sub(b.healAbsorb), "ordre des couches de la barre de vie")
    -- couleur de classe : soins en route en teinte de contraste sur une classe verte seulement
    local theme = Z:Theme()
    Z.db.color = "CLASS" Z:Refresh()
    assert(b.incoming._barColor[1] == theme.incoming[1] and b.incoming._barColor[4] == theme.incoming[4], "pretre : couleur normale")
    rawset(_G, "UnitClass", function() return "Chasseur", "HUNTER" end)
    C_ClassColor.GetClassColor = function() return { r = 0.67, g = 0.83, b = 0.45 } end
    Z:Refresh()
    assert(b.incoming._barColor[1] == theme.incomingOnGreen[1], "chasseur : pas de teinte de contraste")
    for _, t in ipairs(Z.themes) do assert(t.incomingOnGreen, t.id .. " sans teinte de contraste") end
    -- vie restante : couleur donnee par une courbe du jeu
    Z.db.color = "HEALTH" Z:Refresh()
    assert(b.incoming._barColor[4] ~= nil, "vie restante : couleur des soins en route non posee")
    -- bouclier : rayures a la suite de la vie seulement
    Z.db.absorbStyle = "FOLLOW" Z:Refresh()
    assert(b.stripes:IsShown(), "rayures absentes a la suite de la vie")
    Z.db.absorbStyle = "BAND" Z:Refresh()
    assert(not b.stripes:IsShown(), "rayures sur la bande")
  end)
  Z.db.color, Z.db.smooth, Z.db.absorbStyle = old.color, old.smooth, old.style
  rawset(_G, "UnitClass", old.class) C_ClassColor.GetClassColor = old.cc
  b:SetAttribute("unit", nil)
  Z:Refresh()
  assert(ok, err)
end)

step("36 b, lot 4 : mon soin et celui des autres, alerte de gaspillage, voile de mon incantation", function()
  local b = CreateFrame("Button", "LyoruneHeaderUnitButton361", Z.header)
  Z.header:InitButton(b:GetName())
  local old = { split = Z.db.incomingSplit, warn = Z.db.overhealWarn, fill = Z.db.castFill, style = Z.db.absorbStyle,
    dur = UnitCastingDuration, dir = Enum.StatusBarTimerDirection, info = UnitCastingInfo }
  local ok, err = pcall(function()
    b:SetAttribute("unit", "party1")
    -- separes : le mien (5), puis ceux des autres (5), le bouclier a la suite des autres
    Z.db.incomingSplit, Z.db.absorbStyle = "SPLIT", "FOLLOW" Z:Refresh()
    Z.cellUpdates.prediction(b)
    assert(b.incoming._value == 5 and b.incomingOthers:IsShown() and b.incomingOthers._value == 5, "separes : valeurs")
    assert(b.incomingOthers._barColor[4] < b.incoming._barColor[4], "ceux des autres pas plus pales")
    -- les miens seulement : pas de segment des autres
    Z.db.incomingSplit = "MINE" Z:Refresh()
    Z.cellUpdates.prediction(b)
    assert(b.incoming._value == 5 and not b.incomingOthers:IsShown(), "les miens")
    -- tous ensemble : un seul segment, le total
    Z.db.incomingSplit = "ALL" Z:Refresh()
    Z.cellUpdates.prediction(b)
    assert(b.incoming._value == 10 and not b.incomingOthers:IsShown(), "tous ensemble")
    -- alerte de gaspillage : teintes posees sur mon soin, coupees avec le reglage
    Z.db.overhealWarn = true Z:Refresh()
    assert(b.overheal:IsShown() and b.overheal._sublevel > b.incoming:GetStatusBarTexture()._sublevel, "teinte de gaspillage")
    Z.cellUpdates.prediction(b) -- booleen du jeu branche sur l'opacite, sans erreur
    Z.db.overhealWarn = false Z:Refresh()
    assert(not b.overheal:IsShown() and not b.overhealMore:IsShown(), "alerte malgre le reglage coupe")
    -- voile : lance a mon incantation avec la duree du jeu, efface a la fin
    Enum.StatusBarTimerDirection = { ElapsedTime = 0, RemainingTime = 1 }
    rawset(_G, "UnitCastingDuration", function() return "duree" end)
    b.castFill.SetTimerDuration = function(self, d) self._timer = d end
    Z.db.castFill = true Z:Refresh()
    assert(not b.castFill:IsShown(), "voile en tous ensemble")
    Z.db.incomingSplit = "SPLIT" Z:Refresh()
    FireEvent("UNIT_SPELLCAST_START", "player")
    assert(b.castFill._timer == "duree" and b.castFill:GetAlpha() == 1, "voile non lance")
    -- un clic de plus, refuse pendant l'incantation : FAILED, mais l'incantation continue, le voile reste
    rawset(_G, "UnitCastingInfo", function() return "Soin" end)
    FireEvent("UNIT_SPELLCAST_FAILED", "player")
    rawset(_G, "UnitCastingInfo", old.info)
    assert(b.castFill:GetAlpha() == 1, "voile efface par un sort refuse pendant l'incantation")
    FireEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    assert(b.castFill:GetAlpha() == 0, "voile reste apres l'interruption")
    Z.db.castFill = false Z:Refresh()
    b.castFill._timer = nil
    FireEvent("UNIT_SPELLCAST_START", "player")
    assert(b.castFill._timer == nil and not b.castFill:IsShown(), "voile malgre le reglage coupe")
    FireEvent("UNIT_SPELLCAST_STOP", "player")
    -- options : les trois reglages, dans la recherche
    local labels = table.concat(Z:OptionLabels(), "|")
    for _, label in ipairs({ "Soins en route de qui", "Alerte de gaspillage", "Mon soin se remplit pendant l'incantation" }) do
      assert(labels:find(label, 1, true), "absent de la recherche : " .. label)
    end
  end)
  Z.db.incomingSplit, Z.db.overhealWarn, Z.db.castFill, Z.db.absorbStyle = old.split, old.warn, old.fill, old.style
  rawset(_G, "UnitCastingDuration", old.dur) Enum.StatusBarTimerDirection = old.dir
  b.castFill.SetTimerDuration = nil
  b:SetAttribute("unit", nil)
  Z:Refresh()
  assert(ok, err)
end)

step("36 b, lot 5 : chiffre des soins en route, eclat a l'arrivee de mon soin", function()
  local b = CreateFrame("Button", "LyoruneHeaderUnitButton362", Z.header)
  Z.header:InitButton(b:GetName())
  local old = { split = Z.db.incomingSplit, text = Z.db.incomingText, landing = Z.db.healLanding, shape = Z.db.shape,
    absorb = Z.db.absorbText, incoming = Z.db.showIncoming, after = C_Timer.After }
  local ok, err = pcall(function()
    assert(Z.defaults.incomingText == false and Z.defaults.healLanding == true, "valeurs de depart")
    b:SetAttribute("unit", "party1")
    -- chiffre : eteint au depart, puis le total (separes, tous ensemble) ou le mien (les miens)
    Z.db.incomingSplit = "SPLIT" Z:Refresh()
    assert(not b.incomingSwitch:IsShown(), "chiffre affiche alors qu'il est eteint")
    Z.db.incomingText = true Z:Refresh()
    Z.cellUpdates.prediction(b)
    assert(b.incomingSwitch:IsShown() and b.incomingText:GetText() == "+10" and b.incomingSwitch:GetValue() == 10, "chiffre : tous")
    Z.db.incomingSplit = "MINE" Z:Refresh()
    Z.cellUpdates.prediction(b)
    assert(b.incomingText:GetText() == "+5", "chiffre : les miens")
    -- Barre : a gauche du chiffre du bouclier, le texte de vie recule des deux
    Z.db.shape, Z.db.absorbText = "BAR", true Z:Refresh()
    assert(b.incomingSwitch._point[4] < b.absorbSwitch._point[4], "chiffre des soins pas a gauche du bouclier")
    Z.db.showIncoming = false Z:Refresh()
    assert(not b.incomingSwitch:IsShown() and not b.landing:IsShown(), "chiffre ou eclat sans soins en route")
    Z.db.showIncoming = true Z:Refresh()
    -- eclat : mon soin garde par la barre de l'eclat, figee pendant l'eclat
    local later = {}
    C_Timer.After = function(_, f) later[#later + 1] = f end
    Z.cellUpdates.prediction(b)
    assert(b.landing:IsShown() and b.landing._value == 5, "eclat : mon soin")
    -- un sort lance pendant l'incantation (bijou) : pas d'eclat ; l'incantation elle-meme : eclat
    FireEvent("UNIT_SPELLCAST_START", "player", "incantation-1")
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "bijou-2")
    assert(not b.landingFlash:IsPlaying(), "eclat sur un autre sort que mon incantation")
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "incantation-1")
    assert(b.landingFlash:IsPlaying(), "eclat non joue")
    FireEvent("UNIT_SPELLCAST_STOP", "player")
    b.landing._value = 7
    Z.cellUpdates.prediction(b)
    assert(b.landing._value == 7, "barre de l'eclat non figee")
    for _, f in ipairs(later) do f() end
    assert(b.landing._value == 5, "barre de l'eclat non relue a la fin de l'eclat")
    -- en combat : la relecture ne passe qu'une valeur (le jeu refuse une valeur secrete en 2e argument)
    later = {}
    FireEvent("UNIT_SPELLCAST_START", "player", "incantation-3")
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "incantation-3")
    FireEvent("UNIT_SPELLCAST_STOP", "player")
    SECRET = true
    local done, why = pcall(function() for _, f in ipairs(later) do f() end end)
    SECRET = false
    assert(done, "relecture de l'eclat en combat : " .. tostring(why))
    -- tous ensemble : pas d'eclat (le bout du segment porte aussi les soins des autres)
    Z.db.incomingSplit = "ALL" Z:Refresh()
    assert(not b.landing:IsShown(), "eclat en tous ensemble")
    Z.db.incomingSplit = "MINE" Z:Refresh()
    -- coupe : ni eclat ni barre
    Z.db.healLanding = false Z:Refresh()
    b.landingFlash:Stop()
    FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    assert(not b.landing:IsShown() and not b.landingFlash:IsPlaying(), "eclat malgre le reglage coupe")
    local labels = table.concat(Z:OptionLabels(), "|")
    for _, label in ipairs({ "Chiffre des soins en route", "Éclat quand mon soin arrive" }) do
      assert(labels:find(label, 1, true), "absent de la recherche : " .. label)
    end
  end)
  C_Timer.After = old.after
  Z.db.incomingSplit, Z.db.incomingText, Z.db.healLanding, Z.db.shape, Z.db.absorbText = old.split, old.text, old.landing, old.shape, old.absorb
  Z.db.showIncoming = old.incoming
  b:SetAttribute("unit", nil)
  Z:Refresh()
  assert(ok, err)
end)

step("36 a, fouille : nouveau joueur dans une case, barres posees d'un coup ; rayures du bouclier posees", function()
  local b = CreateFrame("Button", "LyoruneHeaderUnitButton362", Z.header)
  Z.header:InitButton(b:GetName())
  local ok, err = pcall(function()
    local keys = { "hp", "incoming", "incomingOthers", "absorb", "healAbsorb" }
    -- comme le jeu : case cachee, joueur change, puis case montree
    b:Hide()
    for _, key in ipairs(keys) do b[key]._snapped = nil end
    b:SetAttribute("unit", "party2")
    b:Show()
    for _, key in ipairs(keys) do assert(b[key]._snapped, key .. " glisse depuis le joueur precedent") end
    -- reaffichee pour le meme joueur : elle glisse normalement
    b.hp._snapped = nil b:Hide() b:Show()
    assert(not b.hp._snapped, "saut a chaque affichage")
    -- case deja visible : saut immediat
    b.hp._snapped = nil b:SetAttribute("unit", "party3")
    assert(b.hp._snapped, "case visible : pas de saut")
  end)
  b:SetAttribute("unit", nil)
  assert(ok, err)
end)

step("aucune variable globale imprevue", function()

  local allowed = { NS = true, FAILED = true, TICK = true, LAST_ERROR = true, BEFORE = true, Lyorune = true, LyoruneDB = true,
    SLASH_LYORUNE1 = true, SLASH_LYORUNE2 = true, Lyorune_OnAddonCompartmentClick = true, ClickCastFrames = true,
    Lyorune_Binding = true, BINDING_HEADER_LYORUNE = true, -- raccourcis du jeu (Bindings.xml)
    CURSOR_X = true, CURSOR_Y = true,
    PRIVATE = true, PRIVATE_NEXT = true, SUMMON = true, PHASE = true, C_IncomingSummon = true, UnitPhaseReason = true, UnitIsPlayer = true }
  local leaks = {}
  for name in pairs(_G) do
    if not BEFORE[name] and not allowed[name] and not name:match("^Lyorune%u") and not (Z.bindingNames[(name:gsub("^BINDING_NAME_", ""))] and name:find("^BINDING_NAME_")) then leaks[#leaks + 1] = name end
  end
  table.sort(leaks)
  assert(#leaks == 0, "variables globales en trop : " .. table.concat(leaks, ", "))
end)

local miss = {}
for k in pairs(MISSING) do miss[#miss + 1] = k end
table.sort(miss)
print("globales absentes du faux client : " .. table.concat(miss, ", "))
'''
rt.execute(scenario)
# Site de présentation : chaque code de la galerie de profils (site/src/profils.json) est importé comme en jeu,
# et chacun de ses réglages doit arriver tel quel (un code refusé ou incomplet ne doit jamais être publié).
import importlib.util, json
_spec = importlib.util.spec_from_file_location('site_lyorune', os.path.join(addon, 'outils', 'site.py'))
_site = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(_site)
def _lua(v):
    return ('true' if v else 'false') if isinstance(v, bool) else (repr(v) if isinstance(v, (int, float)) else '"%s"' % v)
_profils = json.loads(read(os.path.join(addon, 'site', 'src', 'profils.json')))['profils']
rt.execute('SITE_PROFILS = {' + ','.join(
    '{ id = "%s", code = "%s", attendu = { %s } }' % (p['id'], _site.code_partage(p['reglages']),
    ', '.join('%s = %s' % (k, _lua(v)) for k, v in p['reglages'].items())) for p in _profils) + '}')
rt.execute(r'''
local Z = NS
local ok, err = pcall(function()
  for _, p in ipairs(SITE_PROFILS) do
    local reussi, message = Z:Import(p.code)
    assert(reussi, p.id .. " : " .. tostring(message))
    local n = 0
    for cle, valeur in pairs(p.attendu) do
      n = n + 1
      assert(Z.db[cle] == valeur, p.id .. " : " .. cle .. " = " .. tostring(Z.db[cle]))
    end
    assert(tonumber(message:match("%d+")) == n, p.id .. " : " .. message)
    -- les quatre premiers recopient un profil prêt à l'emploi du jeu (Z.presets) : ils doivent rester identiques
    local jeu = ({ donjon = "DUNGEON", raid = "RAID", compact = "COMPACT", lisible = "LARGE" })[p.id]
    if jeu then
      for _, preset in ipairs(Z.presets) do
        if preset[1] == jeu then
          for cle, valeur in pairs(preset[3]) do assert(p.attendu[cle] == valeur, p.id .. " : " .. cle .. " differe du jeu") end
          for cle, valeur in pairs(p.attendu) do assert(preset[3][cle] == valeur, p.id .. " : " .. cle .. " absent du jeu") end
        end
      end
    end
    Z:UndoImport()
  end
end)
print((ok and "OK    " or "ERREUR ") .. "site : codes de la galerie de profils importes comme en jeu" .. (ok and "" or (" : " .. tostring(err))))
if not ok then FAILED = true end
''')
for line in rt.eval('PRINTED').values():
    if line.startswith(('OK', 'ERREUR', 'globales')):
        print(' ', line)

# Fonctions du jeu qu'un addon de soin n'a aucune raison d'appeler : exécuter du texte, toucher à l'or, au courrier,
# aux échanges, à la guilde ou aux objets. Leur présence dans le code est une erreur, même dans un commentaire.
FORBIDDEN = ['loadstring', 'RunScript', 'setfenv', 'getfenv', 'SendMail', 'SetSendMailMoney', 'PickupPlayerMoney',
             'SetTradeMoney', 'AcceptTrade', 'InitiateTrade', 'GuildDisband', 'GuildLeave', 'GuildUninvite', 'GuildPromote',
             'DeleteCursorItem', 'PlaceAuctionBid', 'BuyMerchantItem', 'BNSendWhisper', 'SendSystemMessage']
found = []
for f in files + ['Locales/' + name for name in os.listdir(os.path.join(addon, 'Locales'))]:
    text = read(os.path.join(addon, f))
    for word in FORBIDDEN:
        if re.search(r'\b' + word + r'\b', text):
            found.append('%s dans %s' % (word, f))
    # le chat public : seulement depuis Alerts.lua (annonces choisies par le joueur)
    if f != 'Alerts.lua' and re.search(r'\bSendChatMessage\b', text):
        found.append('SendChatMessage dans %s' % f)
print(('  OK    securite : aucune fonction interdite') if not found else ('  ERREUR securite : ' + ', '.join(found)))

# Revue du code (étape 19) : ce qu'un œil rate facilement, vérifié sur tout l'addon à chaque essai.
#   - une fonction de Z appelée alors qu'elle n'existe nulle part (erreur au premier appel, parfois en combat)
#   - un champ de Z lu alors que rien ne l'écrit (il vaut toujours nil : code mort ou oubli)
#   - une clé de Z.limits, Z.choices, Z.notInProfile ou Z.private absente de Z.defaults (réglage décrit une seule fois)
def sans_commentaires(s):
    s = re.sub(r'--\[(=*)\[.*?\]\1\]', '', s, flags=re.S)
    return re.sub(r'--[^\n]*', '', s)
code = '\n'.join(sans_commentaires(read(os.path.join(addon, f))) for f in files)
ecrits = set(re.findall(r'function\s+Z[.:](\w+)', code)) | set(re.findall(r'\bZ\.(\w+)\s*=', code))
revue = ['Z:%s() appelée mais absente' % n for n in sorted(set(re.findall(r'\bZ[.:](\w+)\s*\(', code)) - ecrits)]
revue += ['Z.%s lu mais jamais écrit' % n for n in sorted(set(re.findall(r'\bZ\.(\w+)', code)) - ecrits - {'db', 'char'})]
def cles(nom):
    core = sans_commentaires(read(os.path.join(addon, 'Core.lua')))
    debut = core.index(nom + ' = {') + len(nom) + 4
    profondeur, plat = 0, ''
    for c in core[debut:core.index('\n}', debut)]:
        if c == '{': profondeur += 1
        elif c == '}': profondeur -= 1
        elif profondeur == 0: plat += c
    return set(re.findall(r'\b(\w+)\s*=', plat))
defauts = cles('Z.defaults')
for nom in ('Z.limits', 'Z.choices', 'Z.notInProfile', 'Z.private'):
    revue += ['%s.%s absent de Z.defaults' % (nom, k) for k in sorted(cles(nom) - defauts)]
# Revue 1.23.5 : un échappement inconnu de Lua 5.1 (« Interface\GroupFrame ») perd sa barre sans erreur, l'image
# n'est pas trouvée. Les chemins s'écrivent avec deux barres « \\ ».
for f in files:
    for n, ligne in enumerate(sans_commentaires(read(os.path.join(addon, f))).split('\n'), 1):
        if re.search(r'(?<!\\)(?:\\\\)*\\[^\\nrt"\'0-9abfv|x\[\]]', ligne):
            revue.append('barre inverse seule dans %s, ligne %d' % (f, n))
# Lot 6c septies e (constat L1) : UI.Window ne traduit pas son titre, il lui arrive déjà traduit (L[...])
for f in files:
    for n, ligne in enumerate(sans_commentaires(read(os.path.join(addon, f))).split('\n'), 1):
        if re.search(r'UI\.Window\(\s*"[^"]*"\s*,\s*"(?!"|Lyorune")', ligne): # sauf titre vide ou nom de l'addon
            revue.append('titre de fenetre sans traduction dans %s, ligne %d' % (f, n))
# 1.26.0 : mot d'ouverture de la page de publication (docs/annonces), français et anglais ensemble, sans tiret long
annonces = os.path.join(addon, 'docs', 'annonces')
for f in (sorted(os.listdir(annonces)) if os.path.isdir(annonces) else []):
    if not f.endswith('.en.md') and not os.path.exists(os.path.join(annonces, f[:-3] + '.en.md')):
        revue.append('annonce %s sans version anglaise' % f)
    if re.search('[‒-―]', read(os.path.join(annonces, f))):
        revue.append('tiret long dans docs/annonces/%s' % f)
print(('  OK    revue : fonctions, champs et reglages coherents') if not revue else ('  ERREUR revue : ' + ', '.join(revue)))
sys.exit(1 if rt.eval('FAILED') or found or revue else 0)
