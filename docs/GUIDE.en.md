# Lyorune: the player guide

Everything you need to heal with Lyorune. No technical knowledge required.

[Version française](TUTORIEL.md)

Good to know: Lyorune is in English when your game is in English: options, in-game tour (`/lyorune tuto`), news and chat messages. You can also force the language with "Lyorune language" (Window and help chapter, fine settings of the Lyorune windows part).

On the very first launch, a **setup assistant** asks three questions before the tour: your role (healer, tank or damage), the group size you play in most (solo or 5, raid of 10 to 25, raid of 40) and the cell shape, picked from thumbnails. Lyorune sets itself up from your answers; everything can be changed later in the options. "Skip" or the close button keeps your current settings, cell shape included. To see it again: `/lyorune assistant`, or "Setup assistant" on the Home page of the options.

## 1. The options window

Type `/lyorune` (or click Lyorune's button on the edge of the minimap). The window has three columns.

**On the left, the sidebar**: eleven chapters, each with its own rune. One click opens a chapter. At each login, the window opens on Home; during the session, it reopens the chapter you used last. A small golden badge counts, in each chapter, the settings you chose yourself that differ from the default: Lyorune never changes anything by itself.

| Chapter | What you set there |
|---|---|
| Home | Your profile, your changed settings, the tutorial, the assistant and what's new |
| Layout | Cell size, sorting, position, shown frames (tanks, target, pinned players...) |
| Look | Cell shape, theme, colours, transparency, text |
| Health and range | Incoming heals, shield, low health, mana bar, players far away or out of sight |
| My heals | Your heals over time, the cell corners, your tracked spells, the global cooldown |
| Debuffs | Dispelling, icons, important debuffs, boss private auras |
| Players | Role, marker, leader, threat, missing buffs, tooltip |
| Spells and bindings | Your spells on clicks and keys, your macros |
| Alerts | Chat announcements and sounds |
| Profiles and sharing | Profiles, sharing a configuration, exchanges between players, reset |
| Window and help | This window's theme, effects, language, help, reading a cell, commands |

**In the middle, the open chapter**: its settings are grouped in parts ("Cell size", "Sorting"...) and the page scrolls with the mouse wheel.

**On the right, the preview cell**: an enlarged fake cell that follows every setting live, with a short sentence saying what it shows (shield, corners, heals over time...). Below it, a fake group of five, then the test mode buttons (see part 7).

**Setting things**:

- **Switch**: one click turns it on or off (in the Classic theme, it looks like one of the game's checkboxes).
- **Side by side choices**: click the one you want. A longer list of choices moves to the next one on each click (right-click: the previous one).
- **Number**: "-" and "+" buttons, mouse wheel over the value, or click the value, type the number and press Enter.
- **Fine settings (n)**: at the bottom of each part, the less common settings are folded away. One click unfolds them; Lyorune remembers what you unfolded.
- **Greyed-out setting**: it depends on another setting that is off (for example the mana bar height while the mana bar is off). You can still change it, and it counts as soon as the other one is back on.

**What you changed**:

- **Golden rune**: it lights up next to every setting that no longer has its default value. Hover it to see that value, click it to go back to it.
- **"Reset this page"**: at the bottom of a chapter where a setting has changed. Two clicks, and every setting of the chapter goes back to its default value. Your lists, clicks and profiles do not move.

**Finding a setting**: at the top right, type a word in "Search a setting..." ("mana", "tank", "theme"...). Lyorune looks in the setting names, then in their explanations. Clicking a result opens the right chapter, unfolds the fine settings if needed and makes the setting flash.

**The Home page** shows:

- **Active profile**: the current profile and how it was chosen, with the "Change profile" button;
- **Your changed settings**: all your settings that are no longer as installed. Click a name to go there; click its golden rune to reset it;
- **Discover**: "Start the tutorial", "Setup assistant" and "What's new in Lyorune".

At the bottom of the Window and help chapter, "Reading a cell" recalls what the main colours of a cell mean, and "Commands" lists the `/lyorune` commands.

## 2. The frames

Every player in your group has a frame. The coloured bar is their health: the shorter it is, the more hurt they are.

| What you see | What it means |
|---|---|
| Light green at the end of the bar | Heals are already on their way |
| Light strip at the bottom of the bar | They have a shield (your choice, Health and range chapter, "Shield position": following the health, like the game's frames, with a bright line at the end when the shield exceeds the missing health) |
| A drink at the bottom left | This healer is low on mana (threshold of your choice in the Health and range chapter, "Healers' low mana"): works in combat, even when the game hides mana |
| Dark red at the end of the health | A debuff "eats" that part of their health: your heals fill it first, before they count |
| Blue bar under the health | Their mana (everyone, by default; height from 2 to 60 pixels and colour adjustable in the Health and range chapter, fine settings of the Mana part; the health always keeps at least 10 pixels of the cell: blue, sky blue, purple, teal or white). With "Mana percentage in the bar", the % is written in it, even in combat |
| Flashing red overlay | Their health is low |
| Red border | They are being attacked |
| Coloured line at the top of the health (if you turn it on) | Their threat: yellow, they build threat on a monster; orange, the monster is about to turn on them; red, the monster is attacking them |
| Small coloured square in a corner | A spell you placed in that corner (My heals chapter): it drains over time |
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

The main colours are recalled in game: Window and help chapter, "Reading a cell".

Hover a frame out of combat: the tooltip shows the player, then the list of your clicks and keys with the spell or macro of each.

**Pointing a player out to the group**: hover their cell and press the game's ping key (set in the game's key bindings). The player is marked for the whole group, as if you aimed at their character, without hunting for them in the fight. Can be turned off in the Players chapter ("Game ping on a cell", in the fine settings of the When hovering a cell part).

## 3. Healing with one click

Click a frame: the spell is cast on that player, without targeting them.

To choose your spells: `/lyorune`, **Spells and bindings** chapter. All your shortcuts are on a single list, one per line: the click or key on the left, the spell in the middle, "x" on the right to remove it.

**Adding a shortcut:**

1. Click "+ Add a click or a key".
2. On that same button, do the combination you want: a click (left, right, middle, buttons 4 and 5), with or without Alt, Ctrl, Shift, even several at once (Ctrl + Shift + right click). A keyboard key, an extra mouse button or the wheel work too.
3. Pick the spell in the window that opens. Lyorune only offers spells your character knows at its level.

There is no limit: add as many lines as you like. All lines stay visible; when the list is long, scroll the page with the mouse wheel.

- **Changing the spell**: click the spell of the line, or drag a spell from your spellbook onto it.
- **Changing the shortcut**: click the click or key of the line, then do the new combination. If it was already taken, the two spells are swapped: nothing is lost.
- **Using a trinket with the spell**: first turn on "Trinkets with spells" (fine settings of Behaviour). Each line then has two small squares at its end, your top (1) and bottom (2) trinkets; the tooltip says which one. Click one to light it up (golden border, your trinket's icon): the trinket is used right before the spell, only if the player is alive. Click again to turn it off. If the trinket is not ready, the spell is still cast.
- **Stop casting**: in the spell choice window, this button turns a click into a "stop" that interrupts the spell being cast (a long heal that is no longer needed, for example).
- A left or right click without a spell keeps its usual role: target the player, open their menu.

The settings of the click itself are in the **Behaviour** part, below the list: "Cast on key press (faster)", "The same click resurrects a dead player", then in its fine settings the clicks per specialization, the two warnings explained below and "Let Clique or the game handle clicks".

### A click the game also uses

The game has its own click casting (in the spellbook). If it uses the same combination as a Lyorune click, it may go first. Lyorune tells you once in the chat, and the line turns orange in the **Spells and bindings** chapter: change the combination on one side or the other. Lyorune never changes the game's bindings. To stop being warned, turn off "Warn about a click the game also uses" (fine settings of Behaviour).

Example for a priest: left click for Flash Heal, right click for Renew, Shift + right click for the shield, middle click to dispel, Ctrl + Shift + left click for Prayer of Healing.

### A new spell without a click

You just learned a spell usable on an ally, and none of your clicks or keys casts it? Lyorune tells you once in the chat, and the spell shows up at the top of the **Spells and bindings** chapter:

- "Assign": then do, on the "Add" button, the click or key you want, and the spell is put on it straight away;
- "x": Lyorune stops suggesting it.

Your resurrection and your group buffs are never reported. To see nothing at all, turn off "Report a new spell without a click" (fine settings of Behaviour).

Your clicks are saved per class: each character keeps its own.

### One specialization, its own clicks

Your character has two specializations (two talent groups)? Each one has its own clicks and its own keys. When you switch talents, Lyorune moves to the right clicks by itself, macros included.

- Just above the list of the **Spells and bindings** chapter, Lyorune shows which specialization's clicks you are looking at.
- The first time, your second specialization takes over the clicks of the first. Then change whatever you like.
- "Copy the other specialization", on the same line, takes over all the clicks and keys of the other one.
- Want the same clicks everywhere? Turn off "Separate clicks for each specialization" (fine settings of Behaviour).

### My macros: several actions in one click

A macro does several things in one click: use a trinket then heal, resurrect a dead player or heal a living one, attack an enemy or heal an ally...

Lyorune keeps your macros in a library. You write a macro once, then put it on as many clicks and keys as you like, in both specializations. If you edit it, all its clicks follow. It takes no room in the game's `/macro` window.

**Open the library**: **Spells and bindings** chapter, "My macros..." button below the list (or the same button in the spell picker).

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

- drag it from the list onto the spell of a line in the **Spells and bindings** chapter;
- or click that spell: your macros are listed below your spells, in the "My macros" row.

Your macros stay on your computer: they are never sent or received in a shared configuration, and "Reset everything" does not erase them. When a click holds a macro, automatic resurrection is not added to it: use the "If the player is dead: resurrect them" box of the wizard.

Already used macros with a previous version? They are moved into the library by themselves, on the same clicks.

### Ready-made macros for your action bars (optional)

If you ask for it, Lyorune creates a real game macro for each spell of your clicks. Nothing is created until the setting is turned on.

1. **Spells and bindings** chapter, "Macros for your action bars" part: turn on "Create one macro per spell of my clicks". One icon per macro appears.
2. Click an icon, then drop it on an action bar. You also find them in `/macro`, in your character's tab: their name starts with "Lyo:".

The macro heals the player under your mouse (a frame or a character), otherwise your target, otherwise yourself. It updates when you change your clicks. Lyorune never touches your other macros. To do without them, turn off "Create one macro per spell of my clicks" or click "Remove Lyorune's macros".

## 4. Hover keys

Prefer the keyboard, or does your mouse have many buttons? Keys are set on the same list as clicks, **Spells and bindings** chapter:

1. Click "+ Add a click or a key".
2. Press the key you want: a letter, a number, a mouse button from the 6th on, the wheel, with or without Shift, Ctrl, Alt (and their combinations). Escape cancels.
3. Pick the spell.

Then hover a frame and press the key: the spell is cast on that player. The key only changes role while you hover a frame. The number of keys is not limited.

## 5. Resurrecting a player

With "The same click resurrects a dead player" (Spells and bindings chapter, Behaviour part, on by default), simply click a dead player with your usual heal click: Lyorune casts your resurrection instead. No extra key.

## 6. Moving and sizing the frames

Everything is set in the **Layout** chapter.

- **Move**: drag the "Group" label above the frames. In a raid, each group has its own column and number ("Group 1" to "Group 8"), or the role name when sorting by role: any label moves the whole set.
- **Lock**: "Moving the frames" (Position part) offers "Free", "Locked", or "With Alt", "With Ctrl", "With Shift": the frames then only move while you hold the key. While they are free, a small "unlocked" note shows above them. They can never be moved in combat. "Move frames back to the centre" brings them back to the middle of the screen.
- **Each character has its own place**: the position is kept for each character, even after logging out. A new character starts from the default position.
- **Without labels**: turn off "Group number above the cells". They only come back while you move the frames.
- **Size**: Cell size part, "Width" and "Height"; "Spacing" is in the fine settings.
- **Overall scale**: "Overall scale (%)", from 50 to 200%. Everything grows or shrinks together (cells, icons, texts, labels) without changing your size settings. Test mode follows the same scale. In combat, the change waits for the end of the fight.
- **Place the cell elements**: "Place the cell elements..." button (Cell size part). An enlarged sample cell shows every element: name, health text, role icon, raid marker, group leader, centre icon, your heals over time, debuffs, important debuff, missing buff and private auras. Drag an element with the mouse, or pick it in the list and nudge it with "Left", "Up", "Down", "Right": one pixel per click, five with Shift. The offset is shown under the cell and your real cells follow at once. "Put it back" undoes it for the chosen element, "Reset all" for all of them. Each cell shape (Bar, Tile, Square, Strip) keeps its own placements.
- **Sorting**: by group, by role or as a grid (Sorting part). By role, choose the order (tank, healer, damage, or any of the six combinations) with "Role order", in the fine settings. As a grid, the whole raid is one block with no gap between groups: "Cells per column in grid" (fine settings) sets its height (8 cells per column give 5 columns for 40 players). A setting that does not apply to the chosen sorting is greyed out.
- **Order in each block**: group order, by name, or by class then name (all priests together, then all druids...). The game keeps this order up to date by itself, even in combat, when someone joins or changes group. When arranged by role, "by class" sorts by name within each role.
- **Each group keeps its place** (fine settings): when arranged by group, group 3 always stays in the 3rd column, even if group 2 is empty. Handy to find a player at a glance. Turned off, groups close up.
- **Tanks and pets**: each can have its own frame, moved separately (Shown frames part; pets are in the fine settings).
- **Pinned players**: a small "Pinned" frame for the players you want to keep apart (a second tank, a player to watch). To pin someone: hover their cell and type `/lyorune pin` (handy in a macro on a key), or target them and click "Pin my target", or type their name in the "Pinned players" list (these last two are in the fine settings of the Shown frames part). The same action unpins them. The frame only shows when a player from the list is in your group; move it by its label. In combat, a change to the list waits for the end of the fight.
- **Target, target's target, focus**: Shown frames part, "My target's cell", then in the fine settings "My target's target cell" and "My focus cell". They appear in a small "Target" frame, moved by its label like the others. Each cell has your clicks and the same look as the group's. It only appears when the target or focus exists, even in combat. An enemy is red, a friendly non-player character green, and neither shows heal or debuff icons. Your target's target (for example the player the boss is hitting) is checked twice a second, since the game gives no notice when it changes.
- **When to show them**: "Show the frames" offers "Always" or "In combat only". "Always" keeps the frames on screen, in and out of combat, including when you quest alone (with "My own frame when solo" on). "In combat only" makes them appear when a fight starts and disappear when it ends. The labels show along with the frames.
- **A frame stays empty?** Type `/lyorune diag`: Lyorune writes the state of each frame in the chat. Copy those lines into your report (`/lyorune bug`).
- **Large raids**: "Shrink cells in large raids" (fine settings of Cell size) makes the frames smaller above 10, then above 25 players.

## 7. Trying without a group: test mode

Type `/lyorune test`, or click "5", "10", "25" or "40" under "Test mode", in the right column of the options window (below the preview cell). A fake group appears, with wounded players, incoming heals, debuffs and the corners you chose: tune the look to your taste, everything changes live. Drag the "Test mode" banner to move the fake group: your real frames will take the same place (same lock as the "Group" labels). To leave it, click the same number a second time, or "Close" at the end of the "Test mode" banner above the cells (or type `/lyorune test` again). Test mode also closes by itself if a fight starts.

## 8. Look

**Look** chapter:

- **Cell shape**: four thumbnails show each shape in your colours. **Bar** (name on the left, health on the right), **Tile** (the original shape), **Square** (small, for large raids) and **Strip** (one long, thin line). One click is enough: size, text and mana bar follow. You then fine-tune each value in the Layout chapter. "Undo" cancels the last choice, "See it live" shows a fake group of 10 players.
- **Cell corners**: square or rounded, whatever the shape.
- **Background and border per group** (fine settings): each group sits on its own background, in the theme's colours.
- **Theme**: Neon, Clean, Glass, Classic or Heroic (flat and modern, lightly embossed, glassy, like the game's raid frames, or textured with a golden border).
- **High contrast**: black background, white border, larger text. It also applies to Lyorune's windows. It replaces the theme and the bar texture: both lines stay greyed out while it is on.
- **Class colours**: "Vivid" (default) for bold, bright colours, or "Natural" for the game's own. Greyed out when the bars do not use class colours.
- **Transparency**: "Frame opacity (%)" and "Out-of-range opacity (%)". In the fine settings, "Bar brightness (%)" and three one-click presets: "Subtle", "Semi-transparent", "Clearly visible".
- **Health text**: missing health, percentage, or nothing; with the text size.

### Lyorune's windows

**Window and help** chapter, "Lyorune windows" part: it dresses the options window, the guided tour and the small windows, never the cells.

- **Window theme**: three complete looks, each with its own frame, buttons, switches and section titles. The change is immediate, no `/reload`, and the header (logo, name, version) stays put.
  - **Modern** (default): dark, clean background with rounded corners, flat buttons, switches with a sliding knob, frost blue and the logo's gold.
  - **Classic**: like the game's own windows, with the game's dialog frame, red buttons and checkboxes, and sunken input fields.
  - **MMORPG**: a grimoire, with a stone background veiled behind the text, a golden border, a rune carved in each corner, bronze plates with a golden bevel as buttons (they sink when clicked), sunken input fields, gold-rimmed switches marked with a rune and section titles in an ancient script.
- **Magic effects** (on by default): a healing light, gold and green, sweeps across the header; a rune circle slowly turns behind the logo and lights up when the window opens; small motes of light rise in the header; the rune of the open chapter lights up in the sidebar; and each time you change a setting, a healing burst passes over the preview cell while its health rises. The circle and the motes take the theme colour (frost in Modern, gold in Classic, ember in MMORPG). None of this ever touches the healing cells.
- **Reduced motion**: windows open with a simple fade, runes and logo stay still, nothing moves in a loop, and the magic effects are turned off. Handy if motion bothers you.

The macros, bug report, error log and news windows open next to the options window instead of covering it.

## 9. Choosing what is shown

Every element of the cell has its switch, filed according to what it shows. Nothing is mandatory. You can, for example, only show the debuffs you can dispel.

- **Health and range**: incoming heals, shield, low health overlay (its threshold in the fine settings), heal absorb, mana bar, healers' low mana, and the two range hints below.
- **My heals**: your heals over time, the cell corners, your tracked spells, the global cooldown.
- **Debuffs**: dispelling, icons, important debuffs, boss private auras.
- **Players**: role icon, raid marker, group leader, summon and phase, threat, missing buffs, tooltip.

### Range (Health and range chapter)

**Player far away: footprints** and **Heal refused, out of sight: an eye**: two switches, Range part. The game does not give player positions in dungeons or raids (no arrow possible); these two hints work everywhere, even in combat.

### Your heals over time (My heals chapter)

Lyorune adapts to your class (priest, druid, paladin or shaman): it tracks your heals over time and shields, plus the spells in your list.

- **Heals shown**: from 1 to 6 per cell (4 at first). In the Debuffs chapter, **Debuffs shown** (fine settings of the Icons part) does the same for debuffs: from 2 to 5 (2 at first), the one you can dispel always first. A change made in combat applies when the fight ends.
- **Icons or thin bars**: pick the display. On icons, four fine settings combine as you like:
  - **Draining circle**: a shade turns as time passes;
  - **Countdown in seconds**: the remaining seconds, drawn by the game;
  - **Icon fades at the end**: near the end of the heal the icon darkens. Time to recast;
  - **Number of charges**: a small number when the heal has several.
- **Cell corners**: place one of your spells in each corner. It becomes a small coloured square (green, blue, yellow, pink) that drains over time, and leaves the icon row. At a glance you see who lacks your Renew or Rejuvenation. Each class keeps its own corners: your druid and your priest never mix. The chosen corners also show on the preview cell and in test mode.
- **My spells to track** (Tracked spells part): add one of your spells, it shows with your heals over time and is offered for the corners.
- **Global cooldown and casting** (Global cooldown part, off at first): a thin bar under the frames, or a ring around the cursor, your choice. White during the global cooldown, accent colour during your cast. You see at a glance when the next heal can go, even in combat.

Everything works in combat. The game hides aura names there, but Lyorune recognises your heals by their number, or by the spell you just cast. A heal it cannot recognise stays in the icon row, never in the wrong corner.

### Buffs (Players chapter)

- **Missing buffs panel** (priest, druid, mage): out of combat, a small window lists the players who lack your group buff (Fortitude, Mark of the Wild, Arcane Intellect). Click a name to cast the buff on them, without targeting them; right-click casts the group version. When three players of the same group lack the buff, a single "Group N" line casts the group version directly. A player out of range is faded. The panel hides in combat and comes back afterwards; the cross closes it until the end of the next fight. Drag it by its title: its position is kept for each character. It has its own switch, separate from the small grey icon on the cell ("Missing group buff").
- **Buffs meant for a single person** (shaman: Earth Shield; druid: Thorns): as long as yours is on nobody, the missing buffs panel offers a line for the tank, out of combat. Prefer another player? Hover their cell and type `/lyorune bearer` (or `/lyorune bearer Name`): they come before the tank, for this character. The same command on the same player brings you back to the tank. If your buff is already on someone, Lyorune asks nothing.

### Lists

Each list sits in its own chapter: "My spells to track" in My heals (Tracked spells part), "Ignore" (debuffs never to show) in Debuffs, Icons part, and "Highlight" (debuffs to show as a large icon) in Debuffs, Important part. Type the exact name, then Enter. Click a name to remove it.

### In dungeons and raids

- **Boss private auras** (Debuffs chapter): some boss debuffs are hidden from addons. The game still agrees to draw them itself on the frame: choose their size and position (centre, top, bottom, left or right) in the fine settings. Two at most per player.
- **Heal absorb** (Health and range chapter, fine settings of the Health part): the dark red band at the end of the health shows what a debuff "eats". Your heals fill it first. The amount comes from the game and stays accurate in combat.
- **Glow and sound** (Debuffs chapter, Important part): a debuff from your "Highlight" list, or a boss debuff, surrounds the frame with a golden outline. The sound, to turn on in the fine settings, plays for those in your list.
  Good to know: in combat the game often hides boss debuff names. Lyorune then cannot tell which one is applied: the outline still works (the game itself decides whether it is a boss debuff), the sound does not.

## 10. Announcements and sounds

**Alerts** chapter: Lyorune can announce that your mana is low, that it is back, and that you are resurrecting a player. Each announcement is turned on separately and its wording is yours. Write `{mana}` for your mana percentage and `{nom}` for the resurrected player. The thresholds are set with "Low mana threshold (%)" and "Mana back threshold (%)".

Good to know: outside dungeons and raids, the game does not let an addon write in /say on its own. The announcement then goes to the party channel.

## 11. Profiles and sharing

**Profiles and sharing** chapter (the active profile also shows on the Home page, with the "Change profile" button):

- **My profiles**: set the look the way you like it, type a name (for example "Dungeon") and click "Save as". A profile keeps size, shape, colours, indicators, your heals over time and element placement. It never touches your clicks, macros, lists or announcements. Pick a profile in the list, then "Load" or "Delete" (two clicks). "Copy..." opens a small window to copy only part of a profile to another one: choose "From" and "To", tick Layout, Look, Health and range, My heals, Debuffs or Players (the settings of the chapter with the same name), then "Copy". The rest of the target profile does not move. What you change while a profile is current belongs to it: Lyorune saves it by itself before switching profile and at logout. Up to 20 profiles.
- **Automatic profiles**: turn on "Switch profile automatically", then fill in the small table. One row per situation (solo or 5, raid of 10, 25, 40, battleground, arena) and one column per specialization: click a cell to move to the next profile, right-click to go back. "-" means "keep the current settings". In the 2nd specialization column, "as 1" uses the 1st one's choice. In a battleground or arena, "by size" applies the profile set for the group size. The switch happens without /reload, as soon as the group changes size, you enter (or leave) a battleground or arena, or you change specialization; in combat, it waits for the end of the fight. A chat message tells you which profile was applied.
- **Ready-made profiles**: Dungeon, Raid, Compact, Large and readable. One click changes size and layout; your clicks are kept.
- **Share my configuration**: copy the code shown and send it to a friend, who pastes it into "Receive a configuration". The code holds the look (element placements included), clicks and lists, but never your macros nor the sentences of your announcements (mana, resurrection): nobody can make you say anything in chat.
- **Direct sending**: type the name of a player who has Lyorune. They receive a request and choose whether to accept. A request only comes from a member of your group, your guild or your friends list, at most once a minute. The window shows the sender's name and realm, and the "Import" button only becomes active after two seconds.
- **Reset**, at the bottom of the chapter:
  - **Undo import**: you don't like a pasted code or a received configuration? This button (or `/lyorune undo`) restores your settings from before the last import: look, clicks, keys and lists. Lyorune keeps this backup even after a /reload, until the next import.
  - **Reset everything**: two clicks to go back to the default settings. Your saved profiles and the frames' position are kept. For a single chapter, use "Reset this page" at the bottom of that chapter instead.

## 12. Between players who have Lyorune

Lyorune talks invisibly with the other players of the group who use it. Everything is set in the Profiles and sharing chapter, "Between players" part:

- **Sync between players**: the main switch. Turned off, nothing is sent and nothing is read; the settings below are greyed out.
- **Who resurrects whom** ("Show who resurrects whom"): when a healer starts a resurrection, their name shows in green instead of "Dead" on the player's cell, for everyone who has Lyorune. You see at a glance who is already taken care of: two healers no longer resurrect the same player while another one waits. The name stays during the cast, then for a minute while the player decides to accept. During a boss fight, the game blocks these messages: only the game's resurrection icon remains.
- **Who has Lyorune**: below these settings, Lyorune counts the group players who use it. Hover over it for the list, with each player's version, or type `/lyorune group`.
- **Configurations** ("Let players offer me their configuration", in the fine settings): you only get the ones you accept (see "Direct sending" above).
- **New version** ("Tell me when a newer version exists", in the fine settings): Lyorune tells you once if a newer version exists, with the address of its official page, where every new feature is described. After updating, the news window also details them in game.

Nothing is ever applied without your consent. A player who sends too many messages is ignored for a while.

A new version is only reported when two different players announce it. Download Lyorune only from its official page: [github.com/BellaHealFr/Lyorune](https://github.com/BellaHealFr/Lyorune/releases/latest). Another site, or a player sending you a file, is not a safe source.

## 13. The minimap button

A small round button in Lyorune's colours sits on the edge of the minimap.

- **Left click**: open or close the options.
- **Right click**: start or close test mode.
- **Drag**: move it around the minimap.

Do not want it? Turn off "Minimap button" (Window and help chapter, fine settings of the Lyorune windows part). The `/lyorune` command always opens the options.

## 14. The runic inscription

At the bottom of the options window, under a thin line, a line of runes writes itself as the window opens, one rune after another, then a glow runs along it from time to time, from left to right. Hover it: a wave of light spreads from the centre, then the translation appears. Its colours follow the window theme: frost blue, soft gold, or embers with a few sparks. It is the sentence Muradin reads on Frostmourne's dais in Warcraft III: "Whomsoever takes up this blade shall wield power eternal."

It is there for the pleasure of the eyes only. To remove it, turn off "Runic inscription at the bottom of this window" (Window and help chapter).

## 15. A problem?

Type `/lyorune bug` (or "Report a bug", Window and help chapter, Help part). Answer the three questions, click "Select all", copy with Ctrl+C, then paste the report into the [English bug form](https://github.com/BellaHealFr/Lyorune/issues/new?template=bug_en.yml). Your character's name, your realm and your group members' names are replaced with "(joueur)" and "(royaume)": the report is public. For a display problem, attach a screenshot. The step by step guide is in [SIGNALER_UN_BUG.md](SIGNALER_UN_BUG.md#reporting-a-bug-english).

Lyorune does not bother you with its errors: at most one discreet message per session, which you can turn off with "Tell me when Lyorune hits an error" (Window and help chapter, fine settings of the Help part).

### The game slows down in a big raid?

Lyorune only works when a player changes (health, heals, debuffs). Only the range is checked twice per second. On a modest computer or in a 40 player raid, turn on **Performance mode** (Window and help chapter, fine settings of the Help part): the range is then checked once per second, and heal and debuff icons are grouped (a tenth of a second late at most). Nothing disappears from your frames. This setting can be kept in a raid profile.

To be sure, click **Measure performance** (same place) or type `/lyorune measure`, out of combat. Lyorune runs its frames on a fake group of 5, 25 and 40 players and shows:
- the time it would take each second in a busy fight, for each group size;
- its memory, next to that of the other healing or interface addons loaded;
- their real time, if the game's profiler is on.

Attach this result to your report if the game slows down with Lyorune.

## Commands

This list is also in game: Window and help chapter, "Commands".

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
