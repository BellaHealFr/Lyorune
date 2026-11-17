# Lyorune: the player guide

Everything you need to heal with Lyorune. No technical knowledge required.

[Version française](TUTORIEL.md)

Good to know: Lyorune is in English when your game is in English: options, in-game tour (`/lyorune tuto`), news and chat messages. You can also force the language in the Help tab.

On the very first launch, a **setup assistant** asks three questions before the tour: your role (healer, tank or damage), the group size you play in most (solo or 5, raid of 10 to 25, raid of 40) and the cell shape, picked from thumbnails. Lyorune sets itself up from your answers; everything can be changed later in the options. "Skip" keeps the default settings. To see it again: `/lyorune assistant`, or "Setup assistant" in the Help tab.

## 1. The frames

Every player in your group has a frame. The coloured bar is their health: the shorter it is, the more hurt they are.

| What you see | What it means |
|---|---|
| Light green at the end of the bar | Heals are already on their way |
| Light strip at the bottom of the bar | They have a shield |
| Dark red at the end of the health | A debuff "eats" that part of their health: your heals fill it first, before they count |
| Blue bar under the health | Their mana (everyone, by default; height and colour adjustable in the Indicators tab: blue, sky blue, purple, teal or white). With "Mana percentage in the bar", the % is written in it, even in combat |
| Flashing red overlay | Their health is low |
| Red border | They are being attacked |
| Coloured line at the top of the health (if you turn it on) | Their threat: yellow, they climb a monster's list; orange, they are about to pull it; red, they have it |
| Small coloured square in a corner | A spell you placed in that corner (Heals tab): it drains over time |
| White border | They are your target |
| Blue, purple, brown or green outline and light tint | A magic effect, a curse, a disease or a poison that YOU can remove (the name and health stay readable) |
| Faded frame | They are out of your healing range |
| Frame faded further, footprints in the middle | They are far away (about 100 yards or more): you really need to move. Works in dungeons and raids too |
| An eye in the middle, for 3 seconds | The game just refused your heal: they are out of sight (behind a pillar, a wall). Step aside |
| "Dead", "Ghost", "Offline" | They are dead, a ghost, or disconnected (their frame stays in place) |
| Small icons at the top left | Your heals over time on them |
| Icons at the bottom right | Their debuffs |
| Large icon on the left | An important debuff (boss, or your own list) |
| Pulsing golden outline | An important debuff is applied (with a sound for those in your list, if you turn it on) |
| Icons drawn by the game (in the centre, by default) | Boss debuffs the game hides from addons: it shows them itself on the frame |
| Grey icon at the bottom left | They lack your group buff (shown out of combat) |
| Resurrection icon in the centre | Someone is resurrecting them |
| Summon icon in the centre | A summon is offered to them, or they accepted or declined it |
| Phase icon in the centre | They are in another phase: they seem close, but your spells cannot reach them |
| Crown next to the role icon | They lead the group (a small flag: a raid assistant) |

Hover a frame out of combat: the tooltip shows the player, then the list of your clicks and keys with the spell or macro of each.

**Pointing a player out to the group**: hover their cell and press the game's ping key (set in the game's key bindings). The player is marked for the whole group, as if you aimed at their character, without hunting for them in the fight. Can be turned off in the Indicators tab ("Game ping on a cell").

## 2. Healing with one click

Click a frame: the spell is cast on that player, without targeting them.

To choose your spells: `/lyorune`, **Clicks** tab. All your shortcuts are on a single list, one per line: the click or key on the left, the spell in the middle, "x" on the right to remove it.

**Adding a shortcut:**

1. Click "+ Add a click or a key".
2. On that same button, do the combination you want: a click (left, right, middle, buttons 4 and 5), with or without Alt, Ctrl, Shift, even several at once (Ctrl + Shift + right click). A keyboard key, an extra mouse button or the wheel work too.
3. Pick the spell in the window that opens. Lyorune only offers spells your character knows at its level.

There is no limit: add as many lines as you like. When the list is long, scroll it with the mouse wheel.

- **Changing the spell**: click the spell of the line, or drag a spell from your spellbook onto it.
- **Changing the shortcut**: click the click or key of the line, then do the new combination. If it was already taken, the two spells are swapped: nothing is lost.
- **Using a trinket with the spell**: each line has two small icons, your top (1) and bottom (2) trinkets. Click one to light it up: the trinket is used right before the spell, only if the player is alive. Click again to turn it off. If the trinket is not ready, the spell is still cast.
- **Stop casting**: in the spell choice window, this button turns a click into a "stop" that interrupts the spell being cast (a long heal that is no longer needed, for example).
- A left or right click without a spell keeps its usual role: target the player, open their menu.

### A click the game also uses

The game has its own click casting (in the spellbook). If it uses the same combination as a Lyorune click, it may go first. Lyorune tells you once in the chat, and the line turns orange in the **Clicks** tab: change the combination on one side or the other. Lyorune never changes the game's bindings. To stop being warned, untick "Warn about a click the game also uses".

Example for a priest: left click for Flash Heal, right click for Renew, Shift + right click for the shield, middle click to dispel, Ctrl + Shift + left click for Prayer of Healing.

### A new spell without a click

You just learned a spell usable on an ally, and none of your clicks or keys casts it? Lyorune tells you once in the chat, and the spell shows up at the top of the **Clicks** tab:

- "Assign": then do, on the "Add" button, the click or key you want, and the spell is put on it straight away;
- "x": Lyorune stops suggesting it.

Your resurrection and your group buffs are never reported. To see nothing at all, untick "Report a new spell without a click".

Your clicks are saved per class: each character keeps its own.

### One specialization, its own clicks

Your character has two specializations (two talent groups)? Each one has its own clicks and its own keys. When you switch talents, Lyorune moves to the right clicks by itself, macros included.

- At the top right of the **Clicks** tab, Lyorune shows which specialization's clicks you are looking at.
- The first time, your second specialization takes over the clicks of the first. Then change whatever you like.
- "Copy the other specialization" takes over all the clicks and keys of the other one.
- Want the same clicks everywhere? Untick "Separate clicks for each specialization".

### My macros: several actions in one click

A macro does several things in one click: use a trinket then heal, resurrect a dead player or heal a living one, attack an enemy or heal an ally...

Lyorune keeps your macros in a library. You write a macro once, then put it on as many clicks and keys as you like, in both specializations. If you edit it, all its clicks follow. It takes no room in the game's `/macro` window.

**Open the library**: **Clicks** tab, "My macros..." button (or the same button in the spell picker).

**Three ways to create a macro:**

1. **The wizard** ("Wizard..." button): pick your healing spell, then tick what you want: stop the current cast, use a trinket, resurrect the player if dead, cast an attack spell if it is an enemy. Lyorune writes the macro for you.
2. **Write it yourself** ("New" button), like a game macro, one command per line.
3. **Take a game macro** ("Import from /macro..." button), or drag it from the `/macro` window onto the list.

**Aiming at the player of the frame.** Nothing to write: a command without a target goes to the player of the frame.

```
/use 13
/cast Rejuvenation
```

A macro found on the Internet with `[@mouseover]` works as it is. To place the player of the frame yourself, write `{cible}`: `/cast [@cible,dead] Resurrection; [@cible] Flash Heal`. A written target (`[@player]`) is always respected. If you prefer your macros to go out exactly as written, untick "A command without a target aims at the frame" in the library.

**One macro for both specializations.** The game condition `[spec:1]` or `[spec:2]` picks the spell according to your talents:

```
/cast [spec:1] Flash Heal; [spec:2] Rejuvenation
```

**Checked while you type.** Below the macro, Lyorune points out:

- a typo in a condition (`[mod:shfit]`, `[ded]`);
- a forgotten bracket, a line that is too long;
- a spell your active specialization does not know (maybe it belongs to the other one);
- a command that runs code (`/run`, `/script`).

Just below, "Sent to the game" shows the exact text that goes out on the click, and "Used on" the clicks that use the macro.

**Putting the macro on a click:**

- drag it from the list onto the spell of a line in the **Clicks** tab;
- or click that spell: your macros are listed below your spells, in the "My macros" row.

Your macros stay on your computer: they are never sent or received in a shared configuration, and "Reset everything" does not erase them. When a click holds a macro, automatic resurrection is not added to it: use the "If the player is dead: resurrect them" box of the wizard.

Already used macros with a previous version? They are moved into the library by themselves, on the same clicks.

### Ready-made macros for your action bars (optional)

If you ask for it, Lyorune creates a real game macro for each spell of your clicks. Nothing is created until the box is ticked.

1. **Clicks** tab, tick "Create one macro per spell of my clicks": one icon per macro appears.
2. Click an icon, then drop it on an action bar. You also find them in `/macro`, in your character's tab: their name starts with "Lyo:".

The macro heals the player under your mouse (a frame or a character), otherwise your target, otherwise yourself. It updates when you change your clicks. Lyorune never touches your other macros. To do without them, untick "Create one macro per spell of my clicks" or click "Remove Lyorune's macros".

## 3. Hover keys

Prefer the keyboard, or does your mouse have many buttons? Keys are set on the same list as clicks, **Clicks** tab:

1. Click "+ Add a click or a key".
2. Press the key you want: a letter, a number, a mouse button from the 6th on, the wheel, with or without Shift, Ctrl, Alt (and their combinations). Escape cancels.
3. Pick the spell.

Then hover a frame and press the key: the spell is cast on that player. The key only changes role while you hover a frame. The number of keys is not limited.

## 4. Resurrecting a player

With the option "The same click resurrects a dead player" (Clicks tab, ticked by default), simply click a dead player with your usual heal click: Lyorune casts your resurrection instead. No extra key.

## 5. Moving and sizing the frames

- **Move**: drag the "Group" label above the frames. In a raid, each group has its own column and number ("Group 1" to "Group 8"), or the role name when sorting by role: any label moves the whole set.
- **Lock**: "Moving the frames" (Frames tab) offers "Free", "Locked", or "With Alt", "With Ctrl", "With Shift": the frames then only move while you hold the key. While they are free, a small "unlocked" note shows above them. They can never be moved in combat.
- **Each character has its own place**: the position is kept for each character, even after logging out. A new character starts from the default position.
- **Without labels**: untick "Group number above the cells". They only come back while you move the frames.
- **Size**: Frames tab, "Width", "Height", "Spacing".
- **Overall scale**: Frames tab, "Overall scale (%)", from 50 to 200%. Everything grows or shrinks together (cells, icons, texts, labels) without changing your size settings. Test mode follows the same scale. In combat, the change waits for the end of the fight.
- **Place the cell elements**: Frames tab, "Place the cell elements..." button. An enlarged sample cell shows every element: name, health text, role icon, raid marker, group leader, centre icon, your heals over time, debuffs, important debuff, missing buff and private auras. Drag an element with the mouse, or pick it in the list and nudge it with "Left", "Up", "Down", "Right": one pixel per click, five with Shift. The offset is shown under the cell and your real cells follow at once. "Put it back" undoes it for the chosen element, "Reset all" for all of them. Each cell shape (Bar, Tile, Square, Strip) keeps its own placements.
- **Sorting**: by group, by role or as a grid. By role, choose the order (tank, healer, damage, or any of the six combinations). As a grid, the whole raid is one block with no gap between groups: "Cells per column in grid" sets its height (8 cells per column give 5 columns for 40 players).
- **Order in each block**: group order, by name, or by class then name (all priests together, then all druids...). The game keeps this order up to date by itself, even in combat, when someone joins or changes group. When arranged by role, "by class" sorts by name within each role.
- **Each group keeps its place**: when arranged by group, group 3 always stays in the 3rd column, even if group 2 is empty. Handy to find a player at a glance. Unchecked, groups close up.
- **Tanks and pets**: each can have its own frame, moved separately.
- **Pinned players**: a small "Pinned" frame for the players you want to keep apart (a second tank, a player to watch). To pin someone: hover their cell and type `/lyorune pin` (handy in a macro on a key), or target them and click "Pin my target" (Lists tab), or type their name in the "Pinned players" list. The same action unpins them. The frame only shows when a player from the list is in your group; move it by its label. In combat, a change to the list waits for the end of the fight.
- **Target, target's target, focus**: Frames tab, three checkboxes ("My target's cell", "My target's target cell", "My focus cell"). They appear in a small "Target" frame, moved by its label like the others. Each cell has your clicks and the same look as the group's. It only appears when the target or focus exists, even in combat. An enemy is red, a friendly non-player character green, and neither shows heal or debuff icons. Your target's target (for example the player the boss is hitting) is checked twice a second, since the game gives no notice when it changes.
- **When to show them**: "Show the frames" (Frames tab) offers "Always" or "In combat only". "Always" keeps the frames on screen, in and out of combat, including when you quest alone (with "My own frame when solo" ticked). "In combat only" makes them appear when a fight starts and disappear when it ends. The labels show along with the frames.
- **A frame stays empty?** Type `/lyorune diag`: Lyorune writes the state of each frame in the chat. Copy those lines into your report (`/lyorune bug`).
- **Large raids**: "Shrink cells in large raids" makes the frames smaller above 10, then above 25 players.

## 6. Trying without a group: test mode

Type `/lyorune test`, or click "5 players", "10 players", "25 players" or "40 players" in the Frames tab. A fake group appears, with wounded players, incoming heals and debuffs: tune the look to your taste, everything changes live. Test mode closes by itself if a fight starts.

## 7. Look

**Look** tab:

- **Cell shape**: four thumbnails show each shape in your colours. **Bar** (name on the left, health on the right), **Tile** (the original shape), **Square** (small, for large raids) and **Strip** (one long, thin line). One click is enough: size, text and mana bar follow. You then fine-tune each value in the Frames tab. "Undo" cancels the last choice, "See it live" shows a fake group of 10 players.
- **Cell corners**: square or rounded, whatever the shape.
- **Background and border per group**: each group sits on its own background, in the theme's colours.
- **Class colors**: "Vivid" (default) for bold, bright colours, or "Natural" for the game's own.
- **Theme**: Neon, Clean, Glass, Classic or Heroic (flat and modern, lightly embossed, glassy, like the game's raid frames, or textured with a golden border).
- **Transparency**: three one-click presets, "Subtle", "Semi-transparent", "Clearly visible", then the fine settings (frame opacity, out-of-range opacity, brightness).
- **Player far away: footprints** and **Heal refused, out of sight: an eye**: two switches, just under the out-of-range opacity. The game does not give player positions in dungeons or raids (no arrow possible); these two hints work everywhere, even in combat.
- **High contrast**: black background, white border, larger text. It also applies to Lyorune's windows.
- **Health text**: missing health, percentage, or nothing.

**Lyorune windows** section (on the right of the same tab): it dresses the options window, the guided tour and the small windows, never the cells.

- **Window theme**: three complete looks, each with its own frame, buttons, checkboxes and section titles. The change is immediate, no `/reload`, and the header (logo, name, version) stays put.
  - **Modern** (default): dark, clean background with rounded corners, flat buttons, frost blue and the logo's gold.
  - **Classic**: like the game's own windows, with the game's dialog frame, red buttons and checkboxes, raised tabs and sunken input fields.
  - **MMORPG**: a grimoire, with a stone background veiled behind the text, a golden border, a rune carved in each corner, bronze plates with a golden bevel as buttons (they sink when clicked), chased tabs, sunken input fields, gold-rimmed checkboxes marked with a rune and section titles in an ancient script.
- **Reduced motion**: windows open with a simple fade, runes and logo stay still, nothing moves in a loop. Handy if motion bothers you.
- **Magic effects** (on by default): a rune circle slowly turns behind the logo and lights up when the window opens, small motes of light rise in the header, and a spark rises when you change a setting. They take the theme colour (frost in Modern, gold in Classic, ember in MMORPG) and never touch the healing cells. "Reduced motion" turns them off too.

The macros, bug report, error log and news windows open next to the options window instead of covering it.

## 8. Choosing what is shown

**Indicators** tab: every element of the frame has its checkbox. Nothing is mandatory. You can, for example, only show the debuffs you can dispel.

### Your heals over time (Heals tab)

Lyorune adapts to your class (priest, druid, paladin or shaman): it tracks your heals over time and shields, plus the spells in your list.

- **Icons or thin bars**: pick the display. On icons, four settings combine as you like:
  - **Draining circle**: a shade turns as time passes;
  - **Countdown in seconds**: the remaining seconds, drawn by the game;
  - **Icon fades at the end**: during the last 6 seconds the icon fades. Time to recast;
  - **Number of charges**: a small number when the heal has several.
- **Cell corners**: place one of your spells in each corner. It becomes a small coloured square (green, blue, yellow, pink) that drains over time, and leaves the icon row. At a glance you see who lacks your Renew or Rejuvenation. Each class keeps its own corners: your druid and your priest never mix.
- **Missing buffs panel** (priest, druid, mage): out of combat, a small window lists the players who lack your group buff (Fortitude, Mark of the Wild, Arcane Intellect). Click a name to cast the buff on them, without targeting them; right-click casts the group version. When three players of the same group lack the buff, a single "Group N" line casts the group version directly. A player out of range is faded. The panel hides in combat and comes back afterwards; the cross closes it until the end of the next fight. Drag it by its title: its position is kept for each character. It has its own switch, separate from the small grey icon on the cell.
- **Buffs meant for a single person** (shaman: Earth Shield; druid: Thorns): as long as yours is on nobody, the missing buffs panel offers a line for the tank, out of combat. Prefer another player? Hover their cell and type `/lyorune bearer` (or `/lyorune bearer Name`): they come before the tank, for this character. The same command on the same player brings you back to the tank. If your buff is already on someone, Lyorune asks nothing.
- **Global cooldown and casting** ("Global cooldown and casting" setting, off at first): a thin bar under the frames, or a ring around the cursor, your choice. White during the global cooldown, accent color during your cast. You see at a glance when the next heal can go, even in combat.

Everything works in combat. The game hides aura names there, but Lyorune recognises your heals by their number, or by the spell you just cast. A heal it cannot recognise stays in the icon row, never in the wrong corner.

**Lists** tab: add one of your spells to track, a debuff that should never be shown, or a debuff to show as a large icon. Type the exact name, then Enter. Click a name to remove it.

### In dungeons and raids

- **Boss private auras**: some boss debuffs are hidden from addons. The game still agrees to draw them itself on the frame: choose their size and position (centre, top, bottom, left or right). Two at most per player.
- **Heal absorb**: the dark red band at the end of the health shows what a debuff "eats". Your heals fill it first. The amount comes from the game and stays accurate in combat.
- **Glow and sound**: a debuff from your "Highlight" list, or a boss debuff, surrounds the frame with a golden outline. The sound, once turned on, plays for those in your list.
  Good to know: in combat the game often hides boss debuff names. Lyorune then cannot tell which one is applied: the outline still works (the game itself decides whether it is a boss debuff), the sound does not.

## 9. Announcements and sounds

**Alerts** tab: Lyorune can announce that your mana is low, that it is back, and that you are resurrecting a player. Each announcement is enabled separately and its wording is yours. Write `{mana}` for your mana percentage and `{nom}` for the resurrected player.

Good to know: outside dungeons and raids, the game does not let an addon write in /say on its own. The announcement then goes to the party channel.

## 10. Profiles and sharing

**Profiles** tab:

- **My profiles**: set the look the way you like it, type a name (for example "Dungeon") and click "Save as". A profile keeps size, shape, colours, indicators, your heals over time and element placement. It never touches your clicks, macros, lists or announcements. Pick a profile in the list, then "Load" or "Delete" (two clicks). "Copy..." opens a small window to copy only part of a profile to another one: choose "From" and "To", tick Frames, Appearance, Indicators or Heals (the settings of the tab with the same name), then "Copy". The rest of the target profile does not move. What you change while a profile is current belongs to it: Lyorune saves it by itself before switching profile and at logout. Up to 20 profiles.
- **Automatic profiles**: tick "Switch profile automatically", then fill in the small table. One row per situation (solo or 5, raid of 10, 25, 40, battleground, arena) and one column per specialization: click a cell to move to the next profile, right-click to go back. "-" means "keep the current settings". In the 2nd specialization column, "as 1" uses the 1st one's choice. In a battleground or arena, "by size" applies the profile set for the group size. The switch happens without /reload, as soon as the group changes size, you enter (or leave) a battleground or arena, or you change specialization; in combat, it waits for the end of the fight. A chat message tells you which profile was applied.
- **Ready-made profiles**: Dungeon, Raid, Compact, Large and readable. One click changes size and layout; your clicks are kept.
- **Share my configuration**: copy the code shown and send it to a friend, who pastes it into "Receive a configuration". The code holds the look (element placements included), clicks and lists, but never your macros nor the sentences of your announcements (mana, resurrection): nobody can make you say anything in chat.
- **Direct sending**: type the name of a player who has Lyorune. They receive a request and choose whether to accept. A request only comes from a member of your group, your guild or your friends list, at most once a minute. The window shows the sender's name and realm, and the "Import" button only becomes active after two seconds.
- **Undo import**: you don't like a pasted code or a received configuration? This button (or `/lyorune undo`) restores your settings from before the last import: look, clicks, keys and lists. Lyorune keeps this backup even after a /reload, until the next import.
- **Reset everything**: two clicks to go back to the default settings. Your saved profiles are kept.

## 11. Between players who have Lyorune

Lyorune talks invisibly with the other players of the group who use it. Everything is set in the Profiles tab, "Between players" section:

- **Sync between players**: the main switch. Unticked, nothing is sent and nothing is read; the boxes below are greyed out.
- **Who resurrects whom** ("Show who resurrects whom"): when a healer starts a resurrection, their name shows in green instead of "Dead" on the player's cell, for everyone who has Lyorune. You see at a glance who is already taken care of: two healers no longer resurrect the same player while another one waits. The name stays during the cast, then for a minute while the player decides to accept. During a boss fight, the game blocks these messages: only the game's resurrection icon remains.
- **Who has Lyorune**: below the boxes, Lyorune counts the group players who use it. Hover over it for the list, with each player's version, or type `/lyorune group`.
- **Configurations**: you only get the ones you accept (see chapter 10).
- **New version**: Lyorune tells you once if a newer version exists, with the address of its official page, where every new feature is described. After updating, the news window also details them in game.

Nothing is ever applied without your consent. A player who sends too many messages is ignored for a while.

A new version is only reported when two different players announce it. Download Lyorune only from its official page: [github.com/BellaHealFr/Lyorune](https://github.com/BellaHealFr/Lyorune/releases/latest). Another site, or a player sending you a file, is not a safe source.

## 12. Finding a setting

At the top right of the options window, type a word ("mana", "tank", "theme"...): Lyorune takes you to the right setting.

## 13. The minimap button

A small round button in Lyorune's colours sits on the edge of the minimap.

- **Left click**: open or close the options.
- **Right click**: start or close test mode.
- **Drag**: move it around the minimap.

Do not want it? Untick "Minimap button" in the Help tab. The `/lyorune` command always opens the options.

## 14. The runic inscription

At the bottom of the options window, a line of runes writes itself as the window opens, one rune after another, then a glow runs along it from time to time, from left to right. Hover it: a wave of light spreads from the centre, then the translation appears. Its colours follow the window theme: frost blue, soft gold, or embers with a few sparks. It is the sentence Muradin reads on Frostmourne's dais in Warcraft III: "Whomsoever takes up this blade shall wield power eternal."

It is there for the pleasure of the eyes only. To remove it, untick "Runic inscription at the bottom of this window" in the Help tab.

## 15. A problem?

Type `/lyorune bug`. Answer the three questions, click "Select all", copy with Ctrl+C, then paste the report into the [English bug form](https://github.com/BellaHealFr/Lyorune/issues/new?template=bug_en.yml). Your character's name, your realm and your group members' names are replaced with "(joueur)" and "(royaume)": the report is public. For a display problem, attach a screenshot. The step by step guide is in [SIGNALER_UN_BUG.md](SIGNALER_UN_BUG.md#reporting-a-bug-english).

Lyorune does not bother you with its errors: at most one discreet message per session, which you can turn off in the Help tab.

### The game slows down in a big raid?

Lyorune only works when a player changes (health, heals, debuffs). Only the range is checked twice per second. On a modest computer or in a 40 player raid, tick **Performance mode** in the Help tab: the range is then checked once per second, and heal and debuff icons are grouped (a tenth of a second late at most). Nothing disappears from your frames. This setting can be kept in a raid profile.

To be sure, click **Measure performance** (Help tab) or type `/lyorune measure`, out of combat. Lyorune runs its frames on a fake group of 5, 25 and 40 players and shows:
- the time it would take each second in a busy fight, for each group size;
- its memory, next to that of the other healing or interface addons loaded;
- their real time, if the game's profiler is on.

Attach this result to your report if the game slows down with Lyorune.

## Commands

| Command | Effect |
|---|---|
| `/lyorune` | Open the options |
| `/lyorune test` | Test mode |
| `/lyorune tuto` | In-game tour |
| `/lyorune assistant` | Setup assistant (three questions) |
| `/lyorune verrou` | Lock or unlock the position |
| `/lyorune reset` | Move the frames back to the centre |
| `/lyorune pin` | Pin or unpin the hovered player (or your target, or the name typed after) |
| `/lyorune bearer` | The hovered player (or your target, or the name typed after) gets your single-target buffs instead of the tank; a 2nd time: back to the tank |
| `/lyorune group` | Group players who have Lyorune |
| `/lyorune undo` | Go back to the configuration from before the last import |
| `/lyorune measure` | Measure performance (out of combat) |
| `/lyorune bug` | Report a problem |
| `/lyorune nouveautes` | See what is new in this version |
