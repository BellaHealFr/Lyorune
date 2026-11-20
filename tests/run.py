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
  AURAS["HARMFUL|RAID_PLAYER_DISPELLABLE"] = { AURAS["HARMFUL"][1] }
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

step("options : onze chapitres, recherche, libelles traduits", function()
  SlashCmdList.LYORUNE("")
  local w = Z:OptionsWindow()
  assert(w and w:IsShown() and #w.chapters == 11, "onze chapitres")
  assert(Z:OptionChapter() == "Accueil", "premiere ouverture de la partie : l'Accueil")
  for i = 1, 11 do w.Select(i) end
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
  Z.db.brightness = 60 Z.db.frameAlpha = 80 Z.db.highContrast = true Z.db.showTanks = true Z.db.showPets = true
  Z:Refresh()
  assert(Z.buttons[1].text:GetText() == "80%", Z.buttons[1].text:GetText())
  assert(Z.header:GetAttribute("groupBy") == "ASSIGNEDROLE" and Z.header:GetAttribute("point") == "LEFT")
  assert(Z.header:GetAttribute("groupingOrder") == "HEALER,TANK,DAMAGER,NONE", Z.header:GetAttribute("groupingOrder"))
  assert(LyoruneTanks:IsShown() and LyorunePets:IsShown() and LyoruneTanks:GetAttribute("roleFilter") == "TANK")
  assert(Z:Theme().id == "CONTRAST")
  Z.db.highContrast = false Z.db.showTanks = false Z.db.showPets = false Z.db.text = "NONE" Z.db.color = "CLASS" Z.db.layout = "GROUP" Z.db.horizontal = false
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
  assert(find("Lyo:shift-4") == "/use 13\n/cast [@mouseover] Soins rapides")
  Z:SetClick("shift-4", "/use 14\n/cast [{cible}] Soins rapides")
  assert(find("Lyo:shift-4") == "/use 14\n/cast [@mouseover] Soins rapides", "macro non mise a jour")
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
  MOUSE_FOCI = { cell.label }
  Z:MacroDragStart(row)
  assert(Z:MacroDragStop(), "rien sous la souris")
  MOUSE_FOCI = false
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

step("mana secrete : mana remontee estimee par paliers", function()
  local power, cost, usable, after, now0 = UnitPower, C_Spell.GetSpellPowerCost, C_Spell.IsSpellUsable, C_Timer.After, NOW
  UnitPower = function() return MakeSecret(MANA) end
  local costs = { [139] = 50, [2061] = 190, [527] = 300, [17] = 450 } -- paliers 5, 19, 30 et 45 %
  C_Spell.GetSpellPowerCost = function(id) return costs[id] and { { type = 0, cost = costs[id] } } or {} end
  C_Spell.IsSpellUsable = function(id) local c = costs[id] or 0 return MANA >= c, MANA < c end
  FireEvent("SPELLS_CHANGED") -- avant de garder les minuteurs : celui des nouveaux sorts doit partir
  local timers = {} C_Timer.After = function(d, f) timers[#timers + 1] = { d = d, f = f } end
  Z.db.manaThreshold = 20 Z.db.regenThreshold = 90 Z.db.manaAlert = true Z.db.regenAlert = true Z.db.alertChannel = "SAY"
  Z:RefreshAlerts()
  NOW = 2000 local n = #SENT
  MANA = 600 FireEvent("UNIT_POWER_UPDATE", "player")
  MANA = 150 FireEvent("UNIT_POWER_UPDATE", "player") assert(#SENT == n + 1, "mana faible")
  wipe(timers) -- la mesure de la remontee commence a l'alerte
  NOW = 2010 MANA = 200 FireEvent("UNIT_POWER_UPDATE", "player") -- palier 19 % : un seul, pas encore de vitesse
  assert(#timers == 0 and #SENT == n + 1, "minuteur sans vitesse connue")
  NOW = 2020 MANA = 310 FireEvent("UNIT_POWER_UPDATE", "player") -- palier 30 % : 11 de mana par seconde
  assert(#timers == 1 and math.abs(timers[1].d - 600 / 11) < 0.01, "heure prevue : " .. tostring(timers[1] and timers[1].d))
  NOW = 2025 MANA = 320 FireEvent("UNIT_POWER_UPDATE", "player") assert(#timers == 1, "pas de nouveau palier")
  NOW = 2035 MANA = 460 FireEvent("UNIT_POWER_UPDATE", "player") -- palier 45 % : calcul refait
  assert(#timers == 2, "calcul refait au palier suivant")
  MANA = 900 timers[1].f() assert(#SENT == n + 1, "ancien minuteur pas annule")
  timers[2].f()
  assert(#SENT == n + 2 and SENT[#SENT] == "SAY:Mana remontée (90 %), prêt à repartir !", tostring(SENT[#SENT]))
  timers[2].f() assert(#SENT == n + 2, "annonce repetee")
  -- mana depensee pendant la remontee : le minuteur ne dit rien
  NOW = 2100 MANA = 150 FireEvent("UNIT_POWER_UPDATE", "player") assert(#SENT == n + 3, "nouvelle mana faible")
  NOW = 2110 MANA = 200 FireEvent("UNIT_POWER_UPDATE", "player")
  NOW = 2120 MANA = 310 FireEvent("UNIT_POWER_UPDATE", "player")
  MANA = 60 FireEvent("UNIT_POWER_UPDATE", "player")
  timers[#timers].f() assert(#SENT == n + 3, "annonce apres une depense")
  -- annonce de remontee decochee : aucun minuteur
  Z.db.regenAlert = false Z:RefreshAlerts() local t = #timers
  NOW = 2200 MANA = 200 FireEvent("UNIT_POWER_UPDATE", "player") MANA = 310 NOW = 2210 FireEvent("UNIT_POWER_UPDATE", "player")
  assert(#timers == t, "minuteur alors que l'annonce est decochee")
  Z.db.regenAlert = true Z:RefreshAlerts()
  UnitPower, C_Spell.GetSpellPowerCost, C_Spell.IsSpellUsable, C_Timer.After, NOW = power, cost, usable, after, now0
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

  -- Effets magiques : étincelle avec la rune, cercle et particules de l'en-tête, au plus 3 éclairs par seconde
  assert(Z.db.magicEffects == true and UI.Magic())
  NOW = NOW + 5 c:Run("OnClick")
  assert(c.spark and c.sparkRise:IsPlaying() and c.spark._tex == UI.MAGIC_SPARK, "etincelle de soin")
  assert(c.spark._color[1] == UI.skin.runeGlow[1], "etincelle : couleur du theme")
  local m = w.magic
  assert(m and m.circle:IsShown() and m.spin:IsPlaying() and m.rises[1]:IsPlaying(), "cercle et particules")
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
    assert(not UI.Magic() and not m.circle:IsShown() and not m.spin:IsPlaying() and not m.rises[1]:IsPlaying(), setting)
    c.sparkRise:Stop() c:Run("OnClick")
    assert(not c.sparkRise:IsPlaying(), setting .. " : etincelle")
    Z.db.reduceMotion, Z.db.magicEffects = false, true Z:Refresh()
  end
  assert(m.spin:IsPlaying() and m.circle:IsShown(), "effets revenus")
  w:Hide() m.Stop() w:Show()
  assert(m.spin:IsPlaying(), "effets a la reouverture")

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
  assert(p[1] == "CENTER" and p[4] == 4 and p[5] == 0, "nom decale")
  Z.SetOffset("marker", 0, 2) Z:Refresh()
  assert(b.marker._point[5] == 1, "marqueur decale")
  AURAS["HELPFUL|PLAYER"] = { { name = "Rénovation", icon = 1, auraInstanceID = 41, spellId = 139 } }
  Z.db.showHots, Z.db.hotStyle = true, "ICONS"
  Z.SetOffset("hots", 5, 0) Z:Refresh() FireEvent("UNIT_AURA", "player") RunUpdates()
  assert(b.hots[1]:IsShown() and b.hots[1]._point[4] == 7, "icones de soins decalees")
  AURAS = {}
  Z.db.shape = "BAR" Z:Refresh()
  assert(Z.Offset("name") == 0 and b.name._point[4] == b.iconSize + 3, "une autre forme garde sa place d'origine")
  Z.db.shape = "TILE" Z:Refresh()
  -- bornes, nettoyage, element inconnu refuse
  Z.SetOffset("name", 999, -999)
  local x, y = Z.Offset("name")
  assert(x == 40 and y == -40, "decalage borne")
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
  assert(x == 3 and y == 0, "marqueur glisse : " .. x .. "," .. y)
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
  assert(type(raid.placement) == "table" and raid.placement ~= Z.db.placement, "copie, pas un lien")
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
  assert(LyoruneTanks:GetAttribute("groupBy") == "CLASS" and LyorunePets:GetAttribute("groupBy") == nil, "tanks par classe, familiers par nom")
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
  assert(labels:find("Panneau des buffs manquants", 1, true), "absent de la recherche")
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
  local oldRole, oldAfter = UnitGroupRolesAssigned, C_Timer.After
  -- un buff unique pour le pretre du faux client (Data.lua : Z.uniqueBuffs)
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
  assert(Z.ProfilePart("width") == "Disposition" and Z.ProfilePart("placement") == "Disposition" and Z.ProfilePart("layout") == "Disposition")
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
  INSTANCE_TYPE = "arena" assert(Z.Situation() == "ARENA")
  assert(Z.SituationLabel("ARENA") == "arène" and Z.SituationLabel("25") == "25 joueurs")
  INSTANCE_TYPE = "none"
  Z.db.autoProfile = true
  Z:ProfileRules(1)["5"], Z:ProfileRules(1).ARENA = "Raid", "Arene"
  FireEvent("PLAYER_ENTERING_WORLD")
  assert(Z.db.activeProfile == "Raid")
  INSTANCE_TYPE = "arena" FireEvent("PLAYER_ENTERING_WORLD")
  assert(Z.db.activeProfile == "Arene" and Z.db.shape == "BAR", "arene : son profil")
  -- 2e specialisation sans choix pour l'arene : celui de la 1re avant la taille du groupe
  SPEC_GROUP = 2 Z:ProfileRules(2)["5"] = "Raid" FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  assert(Z.db.activeProfile == "Arene", "2e specialisation : arene de la 1re")
  SPEC_GROUP = 1 FireEvent("ACTIVE_TALENT_GROUP_CHANGED")
  -- champ de bataille sans choix : la regle de la taille du groupe
  INSTANCE_TYPE = "pvp" FireEvent("ZONE_CHANGED_NEW_AREA")
  assert(Z.db.activeProfile == "Raid", "champ de bataille sans choix : taille du groupe")
  INSTANCE_TYPE = "none" FireEvent("PLAYER_ENTERING_WORLD")
  -- chapitre Profils et partage : 12 cases (6 situations, 2 specialisations), fenetre de copie
  Z:ToggleOptions("Profils et partage")
  local page = OptionPart("profileCells")
  assert(page and #page.profileCells == 12, "cases du tableau")
  local arena = page.profileCells[11]
  assert(arena.size == "ARENA" and arena.group == 1 and arena.label:GetText() == "Arene", "case arene")
  assert(page.profileCells[9].label:GetText() == "selon la taille", "champ de bataille sans choix")
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
      self.groups[key] = { filter = filter, candidates = options.candidateFilters or {}, max = options.maxFrameCount }
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
  local function finish()
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
    assert(slots.slots.dispel.filter == "HARMFUL|RAID_PLAYER_DISPELLABLE", "bordure de dissipation")
    assert(slots.slots.boss.candidates.isBossAura == true, "grande icone : auras de boss")
    assert(debuffs.groups.dispellable.filter == "HARMFUL|RAID_PLAYER_DISPELLABLE", "affaiblissement a dissiper en premier")
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
    assert(b.boxes.hots.groups.hots.max == 4, "soins non rallumes")
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
    AURAS["HARMFUL|RAID_PLAYER_DISPELLABLE"] = { { name = "Mal", icon = 4, auraInstanceID = 22, spellId = 98 } }
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
    -- reglage des icones (decompte) : applique par reconstruction
    kept = b.boxes.hots
    Z.db.hotCountdown = not Z.db.hotCountdown Z:Refresh()
    assert(b.boxes.hots ~= kept, "decompte change sans reconstruction")
    Z.db.hotCountdown = not Z.db.hotCountdown Z:Refresh()
    -- nombre d'icones regle par le joueur : conteneurs refaits hors combat
    Z.db.hotCount, Z.db.debuffCount = 6, 4 Z:Refresh()
    assert(b.boxes.hots.groups.hots.max == 6 and b.boxes.bars.groups.bars.max == 6, "nombre de soins non applique")
    assert(b.boxes.debuffs.groups.dispellable.max == 1 and b.boxes.debuffs.groups.others.max == 3, "nombre d'affaiblissements")
    Z.db.hotCount, Z.db.debuffCount = 4, 2 Z:Refresh()
    assert(b.boxes.debuffs.groups.others.max == 1, "nombre d'affaiblissements non remis")
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

step("C7 : barre de ressource selon la classe (rage, energie, forme du druide), comme HealBot et VuhDo", function()
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
    POWER_TYPE, POWER_TOKEN = nil, nil
    -- mode test : le guerrier et le voleur d'exemple ont leur rage et leur énergie
    Z.db.manaBars = "ALL" Z:Refresh()
    Z:TogglePreview(10)
    local cells = Z:PreviewCells(10)
    assert(cells[1].powerType == 1 and cells[1].power._barColor[1] == 1 and cells[1].power._barColor[3] == 0, "guerrier d'exemple en mana")
    assert(cells[6].powerType == 3 and cells[6].power._barColor[3] == 0, "voleur d'exemple en mana")
    assert(cells[2].powerType == 0 and cells[2].power._barColor[3] == Z.manaColors.BLUE[3], "pretre d'exemple sans mana")
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
  local saved = { showPets = Z.db.showPets, horizontal = Z.db.horizontal, width = Z.db.width }
  local function Get(key) return function() return Z.db[key] end end
  local function Set(key) return function(value) Z.db[key] = value end end
  local function Choices(key) local t = {} for _, c in ipairs(Z.choices[key]) do t[#t + 1] = { c[1], Z.L[c[2]] } end return t end
  local function Build()
    local w = {}
    w.switch = UI.Switch(UIParent, "Familiers", Get("showPets"), Set("showPets"))
    w.seg = UI.Segmented(UIParent, "Sens", Choices("horizontal"), Get("horizontal"), Set("horizontal"))
    w.side = UI.SideButton(UIParent, 4, "Disposition", function(self) self.clicked = true end)
    w.fold = UI.Fold(UIParent, "essai", 3)
    w.scroll = UI.Scroll(UIParent)
    return w
  end
  -- Chaque brique, créée dans chaque thème et en contraste élevé, ou créée avant et repeinte au changement
  local early = Build()
  Z.db.showPets, Z.db.horizontal = false, false
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
  local sw = UI.Switch(UIParent, "Familiers", Get("showPets"), Set("showPets"))
  sw:Run("OnClick")
  assert(Z.db.showPets == true and sw.on and sw.slide:IsPlaying(), "interrupteur")
  assert(sw.knob._color[1] == UI.accent[1] and sw.confirm:IsPlaying(), "interrupteur allume")
  Z.db.reduceMotion = true
  sw:Run("OnClick")
  assert(Z.db.showPets == false and not sw.slide:IsPlaying() and sw.knob._color[1] == UI.dim[1], "interrupteur en animations reduites")
  Z.db.reduceMotion = false
  -- Une case à cocher garde son allure d'avant
  local check = UI.Check(UIParent, "essai", Get("showPets"), Set("showPets"))
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
  local swRune = UI.ChangedRune(sw, "showPets", Get("showPets"), Set("showPets"))
  assert(not swRune:IsShown()) sw:Run("OnClick") assert(swRune:IsShown(), "la rune suit l'interrupteur")
  swRune:Run("OnEnter") assert(GameTooltip:GetText() == "Rétablir : Coupé", GameTooltip:GetText())
  swRune:Run("OnClick") assert(Z.db.showPets == Z.defaults.showPets and not sw.on, "interrupteur retabli")
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
  -- Onze chapitres dans la barre latérale, dans l'ordre de la maquette, textes traduits
  local names = { "Accueil", "Disposition", "Apparence", "Vie et portée", "Mes soins", "Affaiblissements", "Joueurs",
    "Sorts et raccourcis", "Alertes", "Profils et partage", "Fenêtre et aide" }
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
  assert(fold and fold.count == 4 and not fold:IsOpen() and not fade.widget:IsShown(), "reglages fins replies")
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
  local saved = { width = Z.db.width, showPets = Z.db.showPets, syncEnabled = Z.db.syncEnabled, profiles = Z.db.profiles,
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
  Z.db.width, Z.db.showPets = Z.defaults.width, Z.defaults.showPets
  w.Select("Accueil")
  local before = home.changed.count
  assert(home.changed.empty:IsShown() == (before == 0), "liste vide annoncee")
  Z.db.width, Z.db.showPets = Z.defaults.width + 4, not Z.defaults.showPets
  w.Select("Accueil")
  assert(home.changed.count == before + 2 and not home.changed.empty:IsShown(), "deux reglages changes")
  local function Row(key)
    for _, row in ipairs(home.changed.rows) do if row:IsShown() and row.key == key then return row end end
  end
  local row = Row("showPets")
  assert(row and row.where:GetText() == "Disposition" and row.rune:IsShown(), "ligne du reglage change")
  assert(row.value:GetText() == (Z.db.showPets and "Activé" or "Coupé"), "valeur du reglage : " .. tostring(row.value:GetText()))
  assert(Row("width").value:GetText() == tostring(Z.defaults.width + 4), "valeur d'un nombre")
  row:Run("OnClick", "LeftButton")
  assert(Z:OptionChapter() == "Disposition" and w.found and w.found.key == "showPets", "clic : aller au reglage")
  local fold = w.found.widget.part.fold
  assert(fold and fold:IsOpen(), "reglage fin deplie")
  fold:Run("OnClick")
  w.Select("Accueil")
  Row("showPets").rune:Run("OnClick")
  assert(Z.db.showPets == Z.defaults.showPets and home.changed.count == before + 1 and not Row("showPets"), "la rune retablit le reglage")
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
    "Glissez une macro sur une ligne du chapitre Sorts et raccourcis, ou cliquez sur le sort d'une ligne pour la choisir.",
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
  local step = math.floor((540 - 58 - 34 - 16) / 11)
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
  assert(body:find("|cff" .. Hex(Z:Theme().absorb) .. "part claire", 1, true) and body:find("prolonge", 1, true), body)
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
  local away = L["Fermez cette fenêtre : les options reviennent, cliquez alors sur le sort d'une ligne, vos macros sont dans la liste."]
  local drag = L["Glissez une macro sur une ligne du chapitre Sorts et raccourcis, ou cliquez sur le sort d'une ligne pour la choisir."]
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

  -- P1 : la plus petite et la plus grande case, poussées de 40 de chaque côté, restent dans la scène
  Z:OpenPlacement()
  local w = Z:PlacementWindow()
  local stage, limit = w.stage, Z.limits.placement
  local room = math.max(-limit[1], limit[2])
  for _, size in ipairs({ { Z.limits.width[1], Z.limits.height[1] }, { Z.limits.width[2], Z.limits.height[2] } }) do
    local scale = w.StageScale(size[1], size[2])
    assert(scale >= 1 and scale <= 3, "P1 : echelle " .. scale)
    assert(scale * (size[1] / 2 + room) <= stage:GetWidth() / 2 and scale * (size[2] / 2 + room) <= stage:GetHeight() / 2,
      "P1 : case " .. size[1] .. "x" .. size[2] .. " poussee hors de la scene")
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

step("aucune variable globale imprevue", function()
  local allowed = { NS = true, FAILED = true, TICK = true, LAST_ERROR = true, BEFORE = true, Lyorune = true, LyoruneDB = true,
    SLASH_LYORUNE1 = true, SLASH_LYORUNE2 = true, Lyorune_OnAddonCompartmentClick = true, ClickCastFrames = true,
    CURSOR_X = true, CURSOR_Y = true,
    PRIVATE = true, PRIVATE_NEXT = true, SUMMON = true, PHASE = true, C_IncomingSummon = true, UnitPhaseReason = true, UnitIsPlayer = true }
  local leaks = {}
  for name in pairs(_G) do
    if not BEFORE[name] and not allowed[name] and not name:match("^Lyorune%u") then leaks[#leaks + 1] = name end
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
print(('  OK    revue : fonctions, champs et reglages coherents') if not revue else ('  ERREUR revue : ' + ', '.join(revue)))
sys.exit(1 if rt.eval('FAILED') or found or revue else 0)
