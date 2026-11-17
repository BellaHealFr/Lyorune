# Lyorune: the player guide

Everything you need to heal with Lyorune. No technical knowledge required.

[Version française](TUTORIEL.md)

Good to know: Lyorune is in English when your game is in English: options, in-game tour (`/lyorune tuto`), news and chat messages. You can also force the language in the Help tab.

## 1. The frames

Every player in your group has a frame. The coloured bar is their health: the shorter it is, the more hurt they are.

| What you see | What it means |
|---|---|
| Light green at the end of the bar | Heals are already on their way |
| Light strip at the bottom of the bar | They have a shield |
| Dark red at the end of the health | A debuff "eats" that part of their health: your heals fill it first, before they count |
| Blue bar under the health | Their mana (everyone, by default; height adjustable in the Indicators tab) |
| Flashing red overlay | Their health is low |
| Red border | They are being attacked |
| White border | They are your target |
| Blue, purple, brown or green outline and light tint | A magic effect, a curse, a disease or a poison that YOU can remove (the name and health stay readable) |
| Faded frame | They are out of range |
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

Hover a frame out of combat: the tooltip shows the player, then the list of your clicks and keys with the spell or macro of each.

## 2. Healing with one click

Click a frame: the spell is cast on that player, without targeting them.

To choose your spells: `/lyorune`, **Clicks** tab. Click a cell of the table (for example "Right click" + "Shift"), then the icon of the spell you want. Lyorune only offers spells your character knows at its level.

Example for a priest: left click for Flash Heal, right click for Renew, Shift + right click for the shield, middle click to dispel.

You can also drag a spell from your spellbook straight onto a cell.

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

- drag it from the list onto a cell of the **Clicks** tab (or onto the "Spell" of a hover key);
- or click the cell: your macros are listed below your spells, in the "My macros" row.

Your macros stay on your computer: they are never sent or received in a shared configuration, and "Reset everything" does not erase them. When a click holds a macro, automatic resurrection is not added to it: use the "If the player is dead: resurrect them" box of the wizard.

Already used macros with a previous version? They are moved into the library by themselves, on the same clicks.

### Ready-made macros for your action bars (optional)

If you ask for it, Lyorune creates a real game macro for each spell of your clicks. Nothing is created until the box is ticked.

1. **Clicks** tab, tick "Create one macro per spell of my clicks": one icon per macro appears.
2. Click an icon, then drop it on an action bar. You also find them in `/macro`, in your character's tab: their name starts with "Lyo:".

The macro heals the player under your mouse (a frame or a character), otherwise your target, otherwise yourself. It updates when you change your clicks. Lyorune never touches your other macros. To do without them, untick "Create one macro per spell of my clicks" or click "Remove Lyorune's macros".

## 3. Hover keys

Prefer the keyboard, or does your mouse have many buttons? In the **Clicks** tab, "Hover keys" section:

1. Click "Key", then press the key you want: a letter, an extra mouse button, the wheel, with or without Shift, Ctrl, Alt.
2. Click "Spell" and choose the spell.

Then hover a frame and press the key: the spell is cast on that player. The key only changes role while you hover a frame.

## 4. Resurrecting a player

With the option "The same click resurrects a dead player" (Clicks tab, ticked by default), simply click a dead player with your usual heal click: Lyorune casts your resurrection instead. No extra key.

## 5. Moving and sizing the frames

- **Move**: drag the "Group" label above the frames. In a raid, each group has its own column and number ("Group 1" to "Group 8"), or the role name when sorting by role: any label moves the whole set.
- **Lock**: "Moving the frames" (Frames tab) offers "Free", "Locked", or "With Alt", "With Ctrl", "With Shift": the frames then only move while you hold the key. While they are free, a small "unlocked" note shows above them. They can never be moved in combat.
- **Each character has its own place**: the position is kept for each character, even after logging out. A new character starts from the default position.
- **Without labels**: untick "Group number above the cells". They only come back while you move the frames.
- **Size**: Frames tab, "Width", "Height", "Spacing".
- **Sorting**: by group or by role. By role, choose the order (tank, healer, damage, or any of the six combinations).
- **Tanks and pets**: each can have its own frame, moved separately.
- **When to show them**: "Show the frames" (Frames tab) offers "Always" or "In combat only". "Always" keeps the frames on screen, in and out of combat, including when you quest alone (with "My own frame when solo" ticked). "In combat only" makes them appear when a fight starts and disappear when it ends. The labels show along with the frames.
- **A frame stays empty?** Type `/lyorune diag`: Lyorune writes the state of each frame in the chat. Copy those lines into your report (`/lyorune bug`).
- **Large raids**: "Shrink cells in large raids" makes the frames smaller above 10, then above 25 players.

## 6. Trying without a group: test mode

Type `/lyorune test`, or click "5 players", "10 players", "25 players" or "40 players" in the Frames tab. A fake group appears, with wounded players, incoming heals and debuffs: tune the look to your taste, everything changes live. Test mode closes by itself if a fight starts.

## 7. Look

**Look** tab:

- **Theme**: Neon, Clean, Glass, Classic or Heroic (flat and modern, lightly embossed, glassy, like the game's raid frames, or textured with a golden border).
- **Transparency**: three one-click presets, "Subtle", "Semi-transparent", "Clearly visible", then the fine settings (frame opacity, out-of-range opacity, brightness).
- **High contrast**: black background, white border, larger text.
- **Health text**: missing health, percentage, or nothing.

## 8. Choosing what is shown

**Indicators** tab: every element of the frame has its checkbox. Nothing is mandatory. You can, for example, only show the debuffs you can dispel, or replace the heal over time icons with thin bars.

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

- **Ready-made profiles**: Dungeon, Raid, Compact, Large and readable. One click changes size and layout; your clicks are kept.
- **Share my configuration**: copy the code shown and send it to a friend, who pastes it into "Receive a configuration".
- **Direct sending**: type the name of a player who has Lyorune. They receive a request and choose whether to accept.
- **Reset everything**: two clicks to go back to the default settings.

## 11. Between players who have Lyorune

Lyorune exchanges two pieces of information, invisibly, with the other players of the group who use it: its version number (to tell you once if a newer version exists) and the configurations you choose to send. Nothing is ever applied without your consent. Both can be turned off in the Profiles tab, "Between players" section.

## 12. Finding a setting

At the top right of the options window, type a word ("mana", "tank", "theme"...): Lyorune takes you to the right setting.

## 13. The minimap button

A small round button in Lyorune's colours sits on the edge of the minimap.

- **Left click**: open or close the options.
- **Right click**: start or close test mode.
- **Drag**: move it around the minimap.

Do not want it? Untick "Minimap button" in the Help tab. The `/lyorune` command always opens the options.

## 14. The runic inscription

At the bottom of the options window, a line of golden runes lights up from time to time, from left to right. Hover it: the runes brighten and their translation appears. It is the sentence Muradin reads on Frostmourne's dais in Warcraft III: "Whomsoever takes up this blade shall wield power eternal."

It is there for the pleasure of the eyes only. To remove it, untick "Runic inscription at the bottom of this window" in the Help tab.

## 15. A problem?

Type `/lyorune bug`. Answer the three questions, click "Select all", copy with Ctrl+C, then paste the report into the [English bug form](https://github.com/BellaHealFr/Lyorune/issues/new?template=bug_en.yml). For a display problem, attach a screenshot. The step by step guide is in [SIGNALER_UN_BUG.md](SIGNALER_UN_BUG.md#reporting-a-bug-english).

Lyorune does not bother you with its errors: at most one discreet message per session, which you can turn off in the Help tab.

## Commands

| Command | Effect |
|---|---|
| `/lyorune` | Open the options |
| `/lyorune test` | Test mode |
| `/lyorune tuto` | In-game tour |
| `/lyorune verrou` | Lock or unlock the position |
| `/lyorune reset` | Move the frames back to the centre |
| `/lyorune bug` | Report a problem |
| `/lyorune nouveautes` | See what is new in this version |
