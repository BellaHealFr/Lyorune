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
| Blue bar under the health | Their mana (healers, by default) |
| Flashing red overlay | Their health is low |
| Red border | They are being attacked |
| White border | They are your target |
| Blue, purple, brown or green outline | A magic effect, a curse, a disease or a poison that YOU can remove |
| Faded frame | They are out of range |
| "Dead", "Ghost", "Offline" | They are dead, a ghost, or disconnected (their frame stays in place) |
| Small icons at the top left | Your heals over time on them |
| Icons at the bottom right | Their debuffs |
| Large icon on the left | An important debuff (boss, or your own list) |
| Grey icon at the bottom left | They lack your group buff (shown out of combat) |
| Resurrection icon in the centre | Someone is resurrecting them |

## 2. Healing with one click

Click a frame: the spell is cast on that player, without targeting them.

To choose your spells: `/lyorune`, **Clicks** tab. Click a cell of the table (for example "Right click" + "Shift"), then the icon of the spell you want. Lyorune only offers spells your character knows at its level.

Example for a priest: left click for Flash Heal, right click for Renew, Shift + right click for the shield, middle click to dispel.

Your clicks are saved per class: each character keeps its own.

## 3. Hover keys

Prefer the keyboard, or does your mouse have many buttons? In the **Clicks** tab, "Hover keys" section:

1. Click "Key", then press the key you want: a letter, an extra mouse button, the wheel, with or without Shift, Ctrl, Alt.
2. Click "Spell" and choose the spell.

Then hover a frame and press the key: the spell is cast on that player. The key only changes role while you hover a frame.

## 4. Resurrecting a player

With the option "The same click resurrects a dead player" (Clicks tab, ticked by default), simply click a dead player with your usual heal click: Lyorune casts your resurrection instead. No extra key.

## 5. Moving and sizing the frames

- **Move**: drag the small "Lyorune" handle above the frames. Once you are happy, tick "Lock position" (Frames tab): the handle disappears.
- **Size**: Frames tab, "Width", "Height", "Spacing".
- **Sorting**: by group or by role. By role, choose the order (tank, healer, damage, or any of the six combinations).
- **Tanks and pets**: each can have its own frame, moved separately.
- **When to show them**: "Show the frames" (Frames tab) offers "Always" or "In combat only". "Always" keeps the frames on screen, in and out of combat, including when you quest alone (with "My own frame when solo" ticked). "In combat only" makes them appear when a fight starts and disappear when it ends. The handle stays visible as long as the position is not locked.
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
