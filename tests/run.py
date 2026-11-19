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

step("options : neuf onglets, recherche, libelles traduits", function()
  SlashCmdList.LYORUNE("")
  local w = Z:OptionsWindow()
  assert(w and w:IsShown())
  for i = 1, 9 do w.Select(i) end
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
  for i = 1, 8 do card.next:Run("OnClick") end
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
  assert(LyoruneLog:IsShown() and LyoruneNews:IsShown())
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
    "Placing the frames", "Trying without a group", "Setting up Lyorune", "Off you go" }
  for i = 1, 8 do
    assert(card.title:GetText() == titles[i], "titre " .. i .. " : " .. card.title:GetText())
    local body = card.body:GetText()
    assert(i == 3 or not body:find("[\195][\160-\191]"), "etape " .. i .. " encore en francais : " .. body:sub(1, 60))
    assert(card.next.label:GetText() == (i == 8 and "Finish" or "Next"), card.next.label:GetText())
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
  Z.ShowDispel(cell, false) assert(not cell.dispel.fill:IsShown())
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
    local tab = Z:OptionsTabs()[2].button
    local tabLayer = tab.layers and tab.layers[theme .. "TabActive"]
    assert(theme == "MODERN" or (tabLayer and tabLayer:IsShown() and tabLayer._tex == UI.SKIN[theme].tabActive), theme .. " : onglet actif")
    assert(w.indicator:IsShown() == (theme == "MODERN"), theme .. " : barre d'onglet")
    local field = w.search.layers and w.search.layers[theme]
    assert(theme == "MODERN" or (field and field:IsShown() and field._tex == UI.SKIN[theme].field), theme .. " : champ creuse")
    assert(sample.mark._tex == (theme == "CLASSIC" and UI.GAME.check or theme == "MMO" and UI.RUNES or UI.WHITE), theme .. " : case a cocher")
    assert(w.title._font == titleFont and w.title._size == titleSize, theme .. " : l'en-tete change de taille")
    assert(w.indicator._color[2] == skin.accent[2], theme .. " : onglet actif")
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
  assert(UI.bg[1] == 0 and UI.text[1] == 1 and w.bg:IsShown(), "contraste eleve")
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
  assert(#card.runes == 8 and card.runes[1].breath:IsPlaying())
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
  local list = page.add and Z:ClickCell("ctrl-shift-2") and select(2, Z:ClickCell("ctrl-shift-2")):GetParent()
  assert(not Z:ClickCell("CTRL-SHIFT-Q", "key"), "liste sans defilement")
  list:Run("OnMouseWheel", -100) -- la molette descend au bas de la liste
  cell, row = Z:ClickCell("CTRL-SHIFT-Q", "key")
  assert(row, "ligne de la touche")
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
  -- onglet Profils : les cases du tableau font tourner les profils
  Z:ToggleOptions()
  local page
  for _, tab in ipairs(Z:OptionsTabs()) do if tab.page and tab.page.profileCells then page = tab.page end end
  assert(page, "onglet Profils construit")
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
  -- chaque onglet tient dans la fenetre (528 pixels de haut)
  for _, tab in ipairs(Z:OptionsWindow().tabs) do
    if tab.page and tab.page.used then assert(tab.page.used <= 528, "onglet trop haut : " .. tostring(tab.name) .. " " .. tab.page.used) end
  end
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
  for _, tab in ipairs(Z:OptionsWindow().tabs) do
    if tab.page and tab.page.used then assert(tab.page.used <= 528, "onglet trop haut : " .. tostring(tab.name) .. " " .. tab.page.used) end
  end
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
  for _, tab in ipairs(Z:OptionsWindow().tabs) do
    if tab.page and tab.page.used then assert(tab.page.used <= 528, "onglet trop haut : " .. tostring(tab.name) .. " " .. tab.page.used) end
  end
  for k, v in pairs(saved) do Z.db[k] = v end
  Z:Refresh()
end)

step("etape 17 : copie d'une partie d'un profil, champ de bataille et arene", function()
  Z.db.profiles, Z.db.autoProfiles, Z.db.activeProfile, Z.db.autoProfile = {}, {}, "", false
  -- chaque reglage d'un profil a sa partie, celle de l'onglet ou il se regle
  local parts = {}
  for _, part in ipairs(Z.profileParts) do parts[part] = true end
  for key in pairs(Z.defaults) do
    local part = Z.ProfilePart(key)
    if Z.notInProfile[key] then assert(part == nil, "hors profil mais classe : " .. key)
    else assert(parts[part], "partie inconnue pour " .. key .. " : " .. tostring(part)) end
  end
  assert(Z.ProfilePart("width") == "Cadres" and Z.ProfilePart("placement") == "Cadres" and Z.ProfilePart("layout") == "Cadres")
  assert(Z.ProfilePart("shape") == "Apparence" and Z.ProfilePart("theme") == "Apparence" and Z.ProfilePart("rangeAlpha") == "Apparence")
  assert(Z.ProfilePart("showRole") == "Indicateurs" and Z.ProfilePart("privateAuraSize") == "Indicateurs")
  assert(Z.ProfilePart("hotSwipe") == "Soins" and Z.ProfilePart("cornerSpells") == "Soins" and Z.ProfilePart("missingBuffs") == "Soins")
  assert(Z.ProfilePart("clicks") == nil and Z.ProfilePart("castIndicator") == nil and Z.ProfilePart("windowTheme") == nil, "hors profil")
  -- deux profils, puis copie des Cadres seulement
  Z.db.width, Z.db.shape, Z.db.showRole, Z.db.hotSwipe = 120, "BAR", false, false
  assert(Z:SaveProfile("Arene"))
  Z.db.width, Z.db.shape, Z.db.showRole, Z.db.hotSwipe = 90, "TILE", true, true
  assert(Z:SaveProfile("Raid") and Z.db.activeProfile == "Raid")
  local ok, message = Z:CopyProfileParts("Arene", "Raid", {})
  assert(not ok and message:find("au moins une partie"), "aucune partie")
  assert(not Z:CopyProfileParts("Raid", "Raid", { Cadres = true }), "meme profil")
  assert(not Z:CopyProfileParts("Inconnu", "Raid", { Cadres = true }), "profil inconnu")
  -- vers le profil en cours : applique tout de suite
  ok, message = Z:CopyProfileParts("Arene", "Raid", { Cadres = true })
  assert(ok and message:find("Arene", 1, true), "copie : " .. tostring(message))
  assert(Z.db.width == 120 and Z.db.shape == "TILE" and Z.db.showRole == true, "seulement les cadres, en direct")
  -- depuis le profil en cours : ses reglages du moment ; vers un profil enregistre : rien ne bouge a l'ecran
  Z.db.showRole = false
  assert(Z:CopyProfileParts("Raid", "Arene", { Indicateurs = true, Soins = true }))
  assert(Z.db.profiles.Arene.showRole == false and Z.db.profiles.Arene.hotSwipe == true and Z.db.profiles.Arene.shape == "BAR")
  assert(Z.db.profiles.Arene.width == 120 and Z.db.width == 120)
  -- un profil ancien sans un reglage : la valeur d'origine
  Z.db.profiles.Arene.hotCountdown = nil
  assert(Z:CopyProfileParts("Arene", "Raid", { Soins = true }) and Z.db.hotCountdown == Z.defaults.hotCountdown)
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
  -- onglet Profils : 12 cases (6 situations, 2 specialisations), fenetre de copie
  Z:ToggleOptions()
  local page
  for _, tab in ipairs(Z:OptionsTabs()) do if tab.page and tab.page.profileCells then page = tab.page end end
  assert(page and #page.profileCells == 12, "cases du tableau")
  local arena = page.profileCells[11]
  assert(arena.size == "ARENA" and arena.group == 1 and arena.label:GetText() == "Arene", "case arene")
  assert(page.profileCells[9].label:GetText() == "selon la taille", "champ de bataille sans choix")
  page.copyButton:Run("OnClick", "LeftButton")
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

step("1.24.1 : icones d'auras dessinees par le jeu (conteneurs), meme quand les auras sont secretes", function()
  -- faux conteneurs du jeu : ils notent les filtres recus
  local oldCreate, oldSecrets, oldPlay = CreateFrame, C_Secrets, PlaySound
  local boxes = {}
  CreateFrame = function(kind, name, parent, template)
    local f = oldCreate(kind, name, parent, template)
    if kind ~= "AuraContainer" then return f end
    assert(template == "LyoruneAuraBox", "modele du conteneur")
    f.groups, f.slots, f.updates = {}, {}, 0
    function f:AddAuraGroup(key, filter, options)
      assert(options.templateNames[1]:match("^LyoruneAura%u") and options.maxFrameCount >= 1 and options.layout.elementWidth)
      self.groups[key] = { filter = filter }
      options.initializeFrame(oldCreate("Button", nil, self)) -- le jeu habille un bouton
    end
    function f:SetAuraGroupFilterString(key, filter) self.groups[key].filter = filter end
    function f:SetAuraGroupCandidateFilters(key, c) self.groups[key].candidates = c end
    function f:SetAuraGroupMaxFrameCount(key, n) self.groups[key].max = n end
    function f:AddAuraSlot(key, filter, options)
      local button = oldCreate("Button", nil, self)
      self.slots[key] = { filter = filter, button = button }
      options.initializeFrame(button)
      return button
    end
    function f:SetAuraSlotFilterString(key, filter) self.slots[key].filter = filter end
    function f:SetAuraSlotCandidateFilters(key, c) self.slots[key].candidates = c end
    function f:SetUnit(unit) self.unit = unit end
    function f:UpdateAllAuras() self.updates = self.updates + 1 end
    boxes[#boxes + 1] = f
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
  local function finish()
    CreateFrame, C_Secrets, PlaySound, C_UnitAuras.GetUnitAuras = oldCreate, oldSecrets, oldPlay, oldGet
    AuraContainerSortMethod, AuraContainerSortDirection, AnchorUtil = nil, nil, nil
    Enum.CustomAuraButtonDispelTypeTextureStyle = nil
    Z.db.cornerSpells = {} Z.db.extraTracked = {} Z.db.ignoredNames = {} Z.db.showHots = true Z.db.soundDispel = false
    AURAS = {}
  end
  local ok, err = pcall(function()
    AURAS = {}
    local b = CreateFrame("Button", "LyoruneHeaderUnitButton30", Z.header)
    Z.header:InitButton(b:GetName())
    b:SetAttribute("unit", "player")
    assert(b.boxes, "conteneurs non crees")
    local hots, slots, debuffs = b.boxes.hots, b.boxes.slots, b.boxes.debuffs
    assert(hots.unit == "player" and slots.unit == "player" and hots.updates > 0, "conteneurs sans joueur")
    -- mes soins suivis, par numero de sort
    local g = hots.groups.hots
    assert(g.filter == "HELPFUL|PLAYER" and g.candidates.includeSpellIDs[139], "Renovation absente du filtre des soins")
    assert(slots.slots.dispel.filter == "HARMFUL|RAID_PLAYER_DISPELLABLE", "bordure de dissipation")
    assert(slots.slots.boss.candidates.isBossAura == true, "grande icone : auras de boss")
    assert(debuffs.groups.dispellable.filter == "HARMFUL|RAID_PLAYER_DISPELLABLE", "affaiblissement a dissiper en premier")
    -- un coin prend le sort, qui quitte la rangee
    Z.db.cornerSpells = { PRIEST = { TOPLEFT = "Rénovation" } } Z:Refresh()
    assert(slots.slots.TOPLEFT.filter == "HELPFUL|PLAYER" and slots.slots.TOPLEFT.candidates.includeSpellIDs[139], "coin")
    assert(not hots.groups.hots.candidates.includeSpellIDs[139], "sort du coin reste dans la rangee")
    assert(slots.slots.TOPRIGHT.filter == "", "coin vide actif")
    -- interrupteur : rien a montrer
    Z.db.showHots = false Z:Refresh()
    assert(hots.groups.hots.max == 0 and b.boxes.bars.groups.bars.max == 0, "soins affiches malgre l'interrupteur")
    Z.db.showHots = true Z:Refresh()
    assert(hots.groups.hots.max == 4, "soins non rallumes")
    -- liste par nom ou par numero : le numero tape sert tout de suite
    Z.db.ignoredNames = { ["12345"] = true } Z:Refresh()
    assert(debuffs.groups.others.candidates.excludeSpellIDs[12345], "affaiblissement ignore par son numero")
    -- un nom de ma liste vu hors combat : son numero est retenu et le filtre mis a jour
    Z.db.extraTracked = { ["Mon sort"] = true }
    AURAS["HELPFUL|PLAYER"] = { { name = "Mon sort", icon = 1, auraInstanceID = 99, spellId = 4242 } }
    Z.UpdateAurasNow(b)
    assert(Z.db.auraIds["Mon sort"][4242], "numero non retenu")
    assert(hots.groups.hots.candidates.includeSpellIDs[4242], "filtre non mis a jour avec le numero appris")
    -- son de dissipation hors combat, une seule fois
    local sounds = 0
    PlaySound = function() sounds = sounds + 1 end
    Z.db.soundDispel = true
    AURAS["HARMFUL|RAID_PLAYER_DISPELLABLE"] = { { name = "Mal", icon = 4, auraInstanceID = 22, spellId = 98 } }
    Z.UpdateAurasNow(b) Z.UpdateAurasNow(b)
    assert(sounds == 1, "son de dissipation : " .. sounds)
    -- auras secretes : Lyorune ne lit plus rien, le jeu affiche tout
    secret = true read = {}
    Z.UpdateAurasNow(b)
    assert(not read["HARMFUL"] and not read["HELPFUL|PLAYER"], "lecture tentee alors que le jeu cache les auras")
    assert(not b.hots[1] or not b.hots[1]:IsShown(), "ancienne icone affichee avec les conteneurs")
    -- la case change de joueur : les conteneurs suivent
    b:SetAttribute("unit", "party1")
    assert(hots.unit == "party1" and debuffs.unit == "party1", "conteneurs restes sur l'ancien joueur")
    Z.DiagnoseAuras() -- /lyorune auras décrit les conteneurs sans erreur
    b:SetAttribute("unit", nil)
    assert(hots.unit == "none", "conteneur sans joueur")
    for _, e in ipairs(Z.db.errors or {}) do
      assert(e.kind ~= "Conteneur d'auras" and e.kind ~= "filtres des auras", "journal : " .. tostring(e.message))
    end
  end)
  finish()
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
print(('  OK    revue : fonctions, champs et reglages coherents') if not revue else ('  ERREUR revue : ' + ', '.join(revue)))
sys.exit(1 if rt.eval('FAILED') or found or revue else 0)
