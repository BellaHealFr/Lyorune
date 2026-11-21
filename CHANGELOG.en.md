# Changelog

All notable changes to Lyorune, version by version. [Version française](CHANGELOG.md)

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); numbering follows [semantic versioning](https://semver.org/).

<!-- Fichier généré par outils/publier.py à partir de Changes.lua. Ne pas le modifier à la main. -->

## [1.27.1] - 2026-11-21

### Fixed

- Changing a setting in combat no longer causes an action blocked by the game: the click mode (on press or on release) waits for the end of combat.
- Hover keys cast their spell even when "Cast on key press" and the game's own "cast on key down" setting do not match.

## [1.27.0] - 2026-11-21

### Added

- Size of each icon in "Place the cell elements..." (Layout chapter): "-" and "+" under the arrows, or the mouse wheel on the icon, from 50 to 200% of its original size, kept for each cell shape along with its position and carried by configuration sharing. A size changed in combat applies as soon as combat ends.

### Improved

- Icons fitted to each cell shape: on Tile and Square, your heals over time at the top left and debuffs at the bottom right, at a size taken from the cell (on Square, a row that is too long wraps to a second line); on Bar, along the top and bottom edges of the health bar, on the right, without covering the name; on Strip, in a block at the end of the cell, with the health number to their left. A row that is too wide shrinks instead of leaving the cell. The offsets of these icons (and of the health number on Strip) start from zero once on Bar, Strip and Square.
- Guided tour and player guide: where the icons sit for each cell shape, and where to set their size.

### Fixed

- Heal countdown in seconds: the numbers are drawn at the icon's size and no longer spill onto the next icon (they overlapped on Strip).

## [1.26.0] - 2026-11-20

### Added

- New options window, fully redesigned and modernised: eleven chapters sorted by task in a sidebar (Home, Layout, Look, Health and range, My heals, Debuffs, Players, Spells and bindings, Alerts, Profiles and sharing, Window and help), a scrolling page split into parts, and the less common settings folded under Fine settings to keep the essentials in sight.
- Preview cell on the right of the window: an enlarged fake cell shows every setting live, without closing the window, with a fake group of five below it and the test mode buttons (5, 10, 25, 40).
- Golden rune next to every setting you have changed: hovering it tells the default value in words, a click goes back to it. In the sidebar, a badge counts your own choices in each chapter.
- Reset this page at the bottom of each chapter, in two clicks: only the open page goes back to the default values, your lists, clicks and profiles stay as they are.
- At the bottom of the window, Undo my changes puts everything back as it was when the window was opened, in two clicks: settings, clicks, lists, announcement texts, pinned players and macros (a renamed or deleted macro gets its click back). Save my settings keeps them under a profile name.
- Home page: your active profile, the list of your changed settings, the tutorial, the starting assistant and what's new. The window opens on Home at each login, then on the last chapter used.
- Magic effects in the window: a gold and green healing light crosses the header, a runic circle shines behind the logo, the rune of the open chapter lights up and the preview cell glows at every changed setting. Never on your real healing frames; Reduced motion turns them off.
- Your Lyorune macros go on your action bars: drag a macro from My macros onto a game bar, out of combat. Lyorune makes a Lyo:Name copy in /macro (your character's tab) that heals the player under your mouse, otherwise your target; it follows every change of text or name and goes away with the macro. The Create one macro per spell of my clicks option aims the same way.

### Improved

- Search in setting names and in their explanations, with or without accents; clicking a result opens the right chapter and makes the setting flash. Searching for Test mode makes the test mode buttons under the preview cell flash, without changing chapter.
- Easier controls: switches, side by side choices, numbers set with the keyboard or the mouse wheel (after clicking the value, or with Shift); the wheel scrolls the page without changing a setting on the way. A setting is greyed out while the one it depends on is off, and can still be changed.
- Windows easier on the eyes: very dark grey instead of black, off-white text, sidebar in its own shade; High contrast stays very readable without pure black or white, and greys out Theme and Bar texture, which it replaces (your healing frames do not change).
- Windows adapt to your screen: a window that is too big is scaled down to fit, only one window opens next to the options at a time and never covers them (the options slide aside, or fade out and come back on the same chapter, at the same place on the page).
- The clicks chapter is now called Spells and bindings; all its lines are visible, and its trinket buttons are easier to read (the game's slot icon, then a golden border and your trinket's icon) and only show when Trinkets with spells is on.
- Player guide and guided tour rewritten for the new window, in French and English: four short cards present it area by area. The cards sit next to your frames, never on top of them; started from the options, the tour gives the window back on Home; Escape stops it like the close button; hidden frames are replaced by the test mode's fake group during its cards; opening another window stops it cleanly.
- My macros, safer and easier to read: the open macro is marked in every theme, the writing area scrolls, each area keeps its place (full text in the tooltip), Save shows Saved, and the wizard, the import and the spell picker open whole on top; Escape only closes the window on top.
- My macros: a spell written with other accents than in your spellbook is flagged with its right spelling, and Fix spelling puts it in.
- Actions that cannot be undone now ask for a second click: deleting a macro, Reset all in the placement, Clear the log, Take the clicks suggested for my class.
- The test mode's fake cells show the chosen corners; the performance measure has MB and KB in English and texts that no longer overlap.

### Fixed

- Blue mana bar under a warrior, a rogue, a hunter or a druid in bear or cat form: every player now shows their own resource in the game's colours (rage, energy, focus), the bar changes with the druid's form and is read again after combat; the colour you choose applies to mana. Test mode and preview cell included.
- Mana recovered announcement when the game hides your mana: with a low threshold, it came late or never. Lyorune now estimates your mana with the regeneration the game gives out of combat, drinking included, and announces as soon as the estimate reaches your threshold, never too early.
- Macros longer than 255 characters were accepted although the game does not run them: the limit is now 255, a counter shows it, a macro that is too long is flagged in red, and trinkets are no longer added to a click that would go over.
- Element placement: an element pushed far (name, health, icons, markers) could leave the cell, on screen as in the sample. Each offset now stops at the edge, according to the shape and size of your cells: At the edge of the cell shows, the name and health text shrink near the edge, the leader crown stays in the cell, and an offset brought back to the edge finds its place again if you make the cells bigger.
- /lyorune mesure: Lua error (iconSize) and no measure when the test mode had not been opened yet in the session.
- Guided tour: the frame lock chosen before the tour could be lost after a /reload; the shield and incoming heals colours named by the tour are now those of your theme.
- Bug report: a short player name damaged the report text (it is now only replaced as a whole word), and calling the window again erased your answers. Error log: title translated into English. Runic inscription turned off then on again: it comes back without /reload.
- Bar texture: the click stopped on a duplicate texture when other textures were installed, it now goes through all of them. My macros: a refused name (empty, too long or already taken) stayed in the field.

## [1.25.1] - 2026-11-20

### Improved

- Test mode: a Close button at the end of the banner, no command needed.
- Test mode: drag the banner with the mouse to move the real frames along with it (unless the frames are locked).

### Fixed

- Frames fully colored (blue, purple or green) when a player had a debuff to dispel: health stays visible under a light veil.
- Test mode: class colors tinted red.

## [1.25.0] - 2026-11-19

### Added

- Healers' low mana: a drink icon on the frame of a healer running out of mana, even in combat (Indicators tab).
- Shield as a band or after the health, with a bright line when it is larger than the missing health (Look tab).

### Improved

- Number of icons of your choice: 1 to 6 heals, 2 to 5 debuffs.
- Every rank of your heals is recognised in combat, even a lower rank cast by macro.

### Fixed

- Heal and debuff icons shown again, in and out of combat, whatever the group size.
- Name and health stay readable in front of aura icons; the big debuff icon follows its placement again.

## [1.24.0] - 2026-11-18

### Added

- Mana restored announcement even when the game hides your mana (WoW Forever): while you drink, Lyorune notes when each of your spells becomes usable again, works out how fast your mana comes back and announces when it reaches your chosen threshold.

### Improved

- Interface texts reviewed in French and English: clearer sentences and the same words from one screen to the next.

## [1.23.13] - 2026-11-18

### Added

- Low mana announcement and sound even when the game hides your mana (WoW Forever): Lyorune picks the spell in your spellbook that costs about your threshold, and the announcement goes out when that spell lacks mana, in combat too. Approximate threshold; the Alerts tab shows the chosen spell.

### Improved

- A spell refused in combat for lack of mana also triggers the low mana announcement.
- "Hide the game's group frames" option removed: Lyorune never touches the game's frames.

## [1.23.12] - 2026-11-18

### Improved

- Mana bar height adjustable from 2 to 60 pixels (10 at most before); the health bar always keeps at least 10 pixels of the cell.

## [1.23.11] - 2026-11-18

### Improved

- "Compact" ready-made profile: your heals over time stay as icons (thin bars only show if you pick them).

## [1.23.10] - 2026-11-18

### Improved

- More precise error log: the call stack is taken when the error happens, and each entry tells where you were (outdoors, dungeon, raid...) and whether the game was hiding auras.
- The /lyorune bug report also tells the location (outdoors, dungeon, raid...).

## [1.23.9] - 2026-11-18

### Improved

- More complete error log: every cell event and every regular update is watched by Lyorune itself, without relying on any other addon.

### Fixed

- In dungeons, your heals over time, debuffs and dispel highlight show on the cells again: the game makes aura change details secret there, which caused hundreds of errors.
- Mana and resurrection announcements in a group-finder group are sent to the instance channel (they were refused).

## [1.23.8] - 2026-11-17

### Fixed

- Performance measurement: your character's raid marker and ready check icon no longer stay on the test mode cells ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).
- Setup assistant: "Skip" or the close button restores the previous cell shape ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).
- Guided tour: locked frames are locked again after the "Placing the frames" step ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.7] - 2026-11-17

### Fixed

- Cell corners: the list follows the Lists tab without /reload, and a corner's spell stays shown even when removed from the list ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).
- "Restore suggested clicks" in the 2nd specialization replaces its clicks without erasing those of the 1st ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.6] - 2026-11-17

### Fixed

- Who resurrects whom: the list no longer fills up for the whole session when resurrected players leave the group ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.5] - 2026-11-17

### Fixed

- Cast bar or ring: a spell refused during a cast (repeated clicks) no longer hides them ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).
- The leader crown now shows in test mode and in the "Place the cell elements" window.
- My macros: erasing the word before ":" in a condition ([:shift]) no longer causes an error.
- Import from /macro: the window no longer says "no macro" when macros were created since.

## [1.23.4] - 2026-11-17

### Fixed

- "Sound when my mana is low" now also works when the mana announcements are unticked ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.3] - 2026-11-17

### Fixed

- A ready check started again less than 5 seconds after the previous one keeps its answers on the cells.
- The out of sight eye no longer stays on a cell when the game gives it to another player.

## [1.23.2] - 2026-11-17

### Fixed

- End of combat: if one postponed change fails, the others (clicks, layout, profile) still apply ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).
- "Clear the log": /lyorune bug no longer reports an error that was already cleared ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.1] - 2026-11-17

### Fixed

- Test mode with 25 or 40 players: with "Shrink cells in large raids", cells now shrink like in a real raid ([#46](https://github.com/BellaHealFr/Lyorune/issues/46)).

## [1.23.0] - 2026-11-17

### Added

- Copy part of a profile (Profiles tab, "Copy..." button): Frames, Look, Indicators or Heals, as you choose, from one profile to another; the rest of the target profile stays as it is ([#44](https://github.com/BellaHealFr/Lyorune/issues/44)).
- Automatic profiles in battlegrounds and arenas, for each specialization; with nothing chosen, the profile set for the group size applies ([#44](https://github.com/BellaHealFr/Lyorune/issues/44)).

## [1.22.0] - 2026-11-17

### Added

- Buffs meant for a single person: as long as your Earth Shield (shaman) or Thorns (druid) is on nobody, the missing buffs panel offers a line for the tank, or for the player chosen with /lyorune bearer ([#43](https://github.com/BellaHealFr/Lyorune/issues/43)).
- Global cooldown and casting (Heals tab): a thin bar under the frames, or a ring around the cursor, shows the global cooldown and your current cast, even in combat ([#43](https://github.com/BellaHealFr/Lyorune/issues/43)).

## [1.21.0] - 2026-11-17

### Added

- Trinket with the spell: on each line of the Clicks tab, two small icons use your top or bottom trinket right before the spell, on a living player ([#42](https://github.com/BellaHealFr/Lyorune/issues/42)).
- Stop casting: a click or a key can interrupt the spell being cast ([#42](https://github.com/BellaHealFr/Lyorune/issues/42)).
- Click the game also uses: if the game's click casting uses the same combination as a Lyorune click, a message says so and the line turns orange; Lyorune never touches the game's bindings ([#42](https://github.com/BellaHealFr/Lyorune/issues/42)).

## [1.20.0] - 2026-11-17

### Added

- Pinned players: a small "Pinned" frame to keep a second tank or a player to watch apart; pin from the hovered cell (/lyorune pin), your target or the list in the Lists tab ([#41](https://github.com/BellaHealFr/Lyorune/issues/41)).
- Game ping on a cell: hover it and press the ping key, the player is marked for the whole group ([#41](https://github.com/BellaHealFr/Lyorune/issues/41)).
- Group leader crown and raid assistant flag on the cells, movable in the placement editor ([#41](https://github.com/BellaHealFr/Lyorune/issues/41)).

### Improved

- The new version notice gives the address of that version's page, where every new feature is described.

## [1.19.0] - 2026-11-17

### Added

- Distance in three levels, even in dungeons and raids: in healing range, close (faded cell), far away (cell faded further, footprints in the middle) ([#31](https://github.com/BellaHealFr/Lyorune/issues/31)).
- Heal refused because the player is out of sight: an eye shows for 3 seconds in the middle of their cell ([#31](https://github.com/BellaHealFr/Lyorune/issues/31)).

### Improved

- /lyorune position also checks the "far away" level, in dungeons and in combat.

## [1.18.0] - 2026-11-17

### Added

- Performance mode for big raids or a modest computer: range checked once per second, heal and debuff icons grouped, nothing disappears ([#30](https://github.com/BellaHealFr/Lyorune/issues/30)).
- Performance measurement (Help tab or /lyorune measure): Lyorune runs on a fake group of 5, 25 and 40 players and compares itself with the other healing addons loaded ([#30](https://github.com/BellaHealFr/Lyorune/issues/30)).

## [1.17.0] - 2026-11-17

### Added

- Who resurrects whom: when a healer starts a resurrection, their name replaces "Dead" on the cell, in green, for everyone who has Lyorune; two healers no longer resurrect the same player ([#29](https://github.com/BellaHealFr/Lyorune/issues/29)).
- Group players who have Lyorune, with their version: in the Profiles tab (on hover) and with /lyorune group ([#29](https://github.com/BellaHealFr/Lyorune/issues/29)).
- Undo import: the configuration from before the last import comes back in one click (Profiles tab) or with /lyorune undo ([#29](https://github.com/BellaHealFr/Lyorune/issues/29)).

### Improved

- A main switch "Sync between players" turns off every invisible message; a player who sends too many is ignored for a while ([#29](https://github.com/BellaHealFr/Lyorune/issues/29)).

## [1.16.0] - 2026-11-17

### Added

- Missing buffs panel (Heals tab): out of combat, a small window lists the players without your group buff; one click casts it on them, without targeting them, and a whole group without it gets a single line for the group version ([#27](https://github.com/BellaHealFr/Lyorune/issues/27)).
- Setup assistant: on first launch, three questions (role, group size, cell shape from thumbnails) set Lyorune up before the guided tour; see it again with /lyorune assistant or from the Help tab ([#28](https://github.com/BellaHealFr/Lyorune/issues/28)).

## [1.15.0] - 2026-11-17

### Added

- Grid layout (Frames tab): the whole raid in one block, with no gap between groups, and a chosen number of cells per column ([#26](https://github.com/BellaHealFr/Lyorune/issues/26)).
- Order in each block: group order, by name, or by class then name; the game keeps it up to date by itself, even in combat ([#26](https://github.com/BellaHealFr/Lyorune/issues/26)).
- Each group keeps its place: when sorting by group, a group stays in its column even if the one before is empty ([#26](https://github.com/BellaHealFr/Lyorune/issues/26)).

### Improved

- Test mode shows the chosen grid and order ([#26](https://github.com/BellaHealFr/Lyorune/issues/26)).

## [1.14.0] - 2026-11-17

### Added

- My profiles (Profiles tab): your appearance settings saved under a name, loaded in one click; the current profile keeps what you change in it by itself. Clicks, macros, lists and announcements are not part of it ([#24](https://github.com/BellaHealFr/Lyorune/issues/24)).
- Automatic profiles: one profile for 5, 10, 25 and 40 players and for each specialization, applied by itself without /reload, at the end of combat if needed ([#24](https://github.com/BellaHealFr/Lyorune/issues/24)).
- Cells for your target, your target's target and your focus, each with its own switch (Frames tab), in a small movable "Target" frame, with your clicks; an enemy is red ([#25](https://github.com/BellaHealFr/Lyorune/issues/25)).

## [1.13.0] - 2026-11-17

### Added

- Clicks tab: a single list for mouse and keyboard, one shortcut per line, no limit, with every combination of Alt, Ctrl and Shift ([#20](https://github.com/BellaHealFr/Lyorune/issues/20)).
- "Add a click or a key" button: do the combination you want, then pick the spell. Changing a line's shortcut swaps the two spells if it was already taken ([#20](https://github.com/BellaHealFr/Lyorune/issues/20)).
- New spell without a click: a message, and the spell at the top of the Clicks tab with "Assign" (option "Report a new spell without a click") ([#22](https://github.com/BellaHealFr/Lyorune/issues/22)).

## [1.12.0] - 2026-11-17

### Added

- Overall scale for all frames, from 50 to 200%, followed by test mode ([#18](https://github.com/BellaHealFr/Lyorune/issues/18)).
- Placement editor (Frames tab): on an enlarged sample cell, drag or nudge to the exact pixel the name, health text, role, marker and centre icons, your heals, debuffs, missing buff and private auras; each cell shape keeps its placements, shared with the configuration code ([#18](https://github.com/BellaHealFr/Lyorune/issues/18)).

## [1.11.0] - 2026-11-17

### Added

- Heals tab: your heals over time with draining circle, countdown in seconds, icon that fades at the end and charges, combine as you like ([#16](https://github.com/BellaHealFr/Lyorune/issues/16)).
- Cell corners: one of your spells per corner, as a small coloured square that drains over time, set for each class and recognised even in combat ([#17](https://github.com/BellaHealFr/Lyorune/issues/17)).
- Thin threat bar at the top of the health: yellow, orange then red ([#17](https://github.com/BellaHealFr/Lyorune/issues/17)).
- Mana percentage written in the mana bar, readable in combat ([#40](https://github.com/BellaHealFr/Lyorune/issues/40)).

### Fixed

- The health text no longer overlaps the mana bar in the Tile and Square shapes ([#40](https://github.com/BellaHealFr/Lyorune/issues/40)).

## [1.10.0] - 2026-11-17

### Added

- Mana bar colour of your choice (Indicators tab): blue by default, sky blue, purple, teal or white.
- Three themes for Lyorune's windows: Modern (default), Classic and MMORPG, switched live; high contrast applies to them too ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).
- Animated runic inscription: the runes write themselves on opening, a haloed glow runs along them, a wave of light on hover before the translation, colours by theme ([#33](https://github.com/BellaHealFr/Lyorune/issues/33)).
- "Reduced motion" setting: short fades only, still runes and logo ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).
- Magic effects (switch in the Look tab): rune circle behind the logo, motes of light in the header, a spark when a setting changes, theme colour ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).

### Improved

- Smoother windows: fade-in opening, sliding tab bar, glowing hover, confirmation rune, runic dividers, logo in the header ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).
- Guided tour: steps slide in, one rune per step, the element shown is framed with runes ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).
- Interface colours matched to the logo's frost blue and gold ([#19](https://github.com/BellaHealFr/Lyorune/issues/19)).

### Fixed

- The mana bar stayed white instead of blue.
- The right edge of some checkboxes vanished depending on the UI scale: every border line now keeps at least one pixel.
- The macros, bug report, error log and news windows open next to the options instead of covering them.

## [1.9.0] - 2026-11-17

### Added

- Choice of cell shape: Bar, Tile, Square or Strip, with live thumbnails, an "Undo" button and a "See it live" button ([#14](https://github.com/BellaHealFr/Lyorune/issues/14)).
- Square or rounded cell corners, for every shape and every theme ([#15](https://github.com/BellaHealFr/Lyorune/issues/15)).
- Background and border per group, in the theme's colours ([#14](https://github.com/BellaHealFr/Lyorune/issues/14)).

### Improved

- Brighter class colours by default, or natural ones if you prefer ([#32](https://github.com/BellaHealFr/Lyorune/issues/32)).

## [1.8.1] - 2026-11-17

### Improved

- Security checks before each release: damaged codes and messages, forbidden functions, archive contents ([#38](https://github.com/BellaHealFr/Lyorune/issues/38)).

### Fixed

- Received configurations: only from a group member, guild member or friend, at most one a minute, with the sender's realm; an open window is no longer replaced and the Import button waits two seconds. Announcement sentences and unknown textures are no longer shared ([#34](https://github.com/BellaHealFr/Lyorune/issues/34)).
- New version notice: two different players and a plausible number are needed; the message names the official page ([#35](https://github.com/BellaHealFr/Lyorune/issues/35)).
- Bug report and error log: character and realm names are replaced ([#36](https://github.com/BellaHealFr/Lyorune/issues/36)).
- Action bar macros: Lyorune only touches the macros it created, never a player macro named "Lyo:" ([#37](https://github.com/BellaHealFr/Lyorune/issues/37)).

## [1.8.0] - 2026-11-17

### Added

- Boss private auras: the game draws them itself on the cell, adjustable size and position ([#9](https://github.com/BellaHealFr/Lyorune/issues/9)).
- Heal absorb: dark red band at the end of the health, computed by the game, accurate in combat ([#10](https://github.com/BellaHealFr/Lyorune/issues/10)).
- Icons for a pending summon and for a player in another phase ([#11](https://github.com/BellaHealFr/Lyorune/issues/11)).
- Tooltip when hovering a cell: the list of your clicks and keys, out of combat ([#12](https://github.com/BellaHealFr/Lyorune/issues/12)).
- Glowing outline for an important debuff, even in combat for boss debuffs, and a sound for those in your list ([#13](https://github.com/BellaHealFr/Lyorune/issues/13)).

## [1.7.0] - 2026-11-17

### Added

- In a raid, one frame per group with its number above ("Group 1" to "Group 8"), or the role name when sorting by role; a setting hides them ([#6](https://github.com/BellaHealFr/Lyorune/issues/6)).
- Choose how the frames move: free, locked, or while holding Alt, Ctrl or Shift, by any group label ([#7](https://github.com/BellaHealFr/Lyorune/issues/7)).
- Frame position kept for each character; a new character starts from the default position ([#5](https://github.com/BellaHealFr/Lyorune/issues/5)).

### Improved

- Mana bar shown for everyone by default, adjustable height ([#8](https://github.com/BellaHealFr/Lyorune/issues/8)).
- Minimap button now the same size as other addons' buttons.

### Fixed

- The dispel colour no longer hides the name or health: coloured outline and light tint ([#4](https://github.com/BellaHealFr/Lyorune/issues/4)).

## [1.6.0] - 2026-11-17

### Added

- "My macros" library: write a macro once, put it on as many clicks and keys as you like ([#23](https://github.com/BellaHealFr/Lyorune/issues/23)).
- Checkbox macro wizard, import from /macro, drag and drop onto the cells.
- The macro is checked while you type, with a preview of the exact text sent to the game.
- Clicks and keys for each specialization, switching by themselves with your talents ([#21](https://github.com/BellaHealFr/Lyorune/issues/21)).

### Improved

- A macro command without a target aims at the cell; [@mouseover] works as it is.
- Your previous macros are moved into the library by themselves.

## [1.5.4] - 2026-11-17

### Added

- Your own game macros on a click: the spell picker shows the macros you wrote in /macro.

### Improved

- Action bar macros are no longer created automatically: tick the box in the Clicks tab if you want them. Those created by 1.5.1 are removed.

## [1.5.3] - 2026-11-17

### Improved

- The options window is taller, so that the action bar macros fit in the Clicks tab.
- An error in one options tab no longer hides the other settings, and it is written to the log.

## [1.5.2] - 2026-11-17

### Fixed

- The frames show up again: the game refused to create the cells, solo as well as in a group.

## [1.5.1] - 2026-11-17

### Added

- Macros for your action bars: Lyorune creates and keeps up to date a real game macro for each spell of your clicks. Clicks tab: click its icon, then drop it on an action bar.

### Improved

- The /lyorune erreurs report now describes the state of each frame.

## [1.5.0] - 2026-11-17

### Added

- Macros: when choosing a click or a hover key, the "Macro..." button offers three ready-made templates (trinket then heal, stop cast then heal, announce then heal) and free typing.

### Improved

- A configuration code received from another player can only hold spell names, never a command.

## [1.4.2] - 2026-11-17

### Added

- "Show the frames" setting (Frames tab): all the time, or only during fights.
- The /lyorune diag command describes the state of each frame, to understand a frame that stays empty.

### Improved

- Showing the frames is now handled by the game itself: it stays reliable in the middle of a fight.

### Fixed

- After test mode, the real frames come back as soon as the fight starts.
- No more error when releasing a frame handle during a fight.
- Incoming heals are attached to the end of the health bar again.

## [1.4.1] - 2026-11-16

### Improved

- Lyorune now speaks English everywhere: guided tour, news, chat messages and theme names.
- On an English game client, the suggested announcements (mana, resurrection) are in English from the first install.
- The /lyorune bug window gives a direct link to the report form, in your language.

## [1.4.0] - 2026-11-16

### Added

- New name: Lyorune. The commands are /lyorune and /lyo.
- Minimap button: left click for the options, right click for test mode. It can be moved, and turned off in the Help tab.
- Lyorune logo in the addon list.
- Animated runic inscription at the bottom of the options window: hover it to translate it.

## 1.3.0 - 2026-11-16

### Added

- Report a bug in three questions with /lyorune bug: a report ready to copy.
- Three transparency presets: subtle, semi-transparent, clearly visible.
- Position diagnostic with /lyorune position, in preparation for the direction arrow.

### Improved

- Specialization or talent changes are picked up without /reload.
- A disconnected player stays visible, marked "Offline".
- Adjustable error notification, only one per session.

## 1.2.0 - 2026-11-16

### Added

- Test mode: a fake group of 5 to 40 players to tune the look (/lyorune test).
- Separate frames for tanks and pets, role order of your choice.
- Healer mana bar, low health visual alert, missing group buffs.
- Heals over time as icons or thin bars, important debuffs shown large.
- Hover keys, automatic resurrection on the heal click.
- Personal lists: spells to track, debuffs to ignore or to highlight.
- Brightness, opacity, high contrast, automatic cell shrinking in large raids.
- Ready-made profiles, direct sending of your configuration to a player, reset everything.
- English translation of the options.
- Warning when a group member has a newer version.

### Improved

- Options sorted into eight tabs, with a search box.

### Fixed

- Your own cell is no longer faded as if you were out of range.

## 1.1.0 - 2026-11-16

### Added

- Five themes, mana and resurrection announcements, configuration sharing by code.
- Error log (/lyorune erreurs) and compatibility check (/lyorune diag).

## 1.0.0 - 2026-11-16

### Added

- First version for WoW Forever: frames, click-healing, incoming heals, dispels, tutorial.

[1.27.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.27.0...v1.27.1
[1.27.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.26.0...v1.27.0
[1.26.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.25.1...v1.26.0
[1.25.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.25.0...v1.25.1
[1.25.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.24.0...v1.25.0
[1.24.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.13...v1.24.0
[1.23.13]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.12...v1.23.13
[1.23.12]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.11...v1.23.12
[1.23.11]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.10...v1.23.11
[1.23.10]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.9...v1.23.10
[1.23.9]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.8...v1.23.9
[1.23.8]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.7...v1.23.8
[1.23.7]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.6...v1.23.7
[1.23.6]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.5...v1.23.6
[1.23.5]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.4...v1.23.5
[1.23.4]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.3...v1.23.4
[1.23.3]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.2...v1.23.3
[1.23.2]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.1...v1.23.2
[1.23.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.23.0...v1.23.1
[1.23.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.22.0...v1.23.0
[1.22.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.21.0...v1.22.0
[1.21.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.20.0...v1.21.0
[1.20.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.19.0...v1.20.0
[1.19.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.18.0...v1.19.0
[1.18.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.17.0...v1.18.0
[1.17.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.16.0...v1.17.0
[1.16.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.15.0...v1.16.0
[1.15.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.14.0...v1.15.0
[1.14.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.13.0...v1.14.0
[1.13.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.12.0...v1.13.0
[1.12.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.11.0...v1.12.0
[1.11.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.10.0...v1.11.0
[1.10.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.9.0...v1.10.0
[1.9.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.8.1...v1.9.0
[1.8.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.8.0...v1.8.1
[1.8.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.5.4...v1.6.0
[1.5.4]: https://github.com/BellaHealFr/Lyorune/compare/v1.5.3...v1.5.4
[1.5.3]: https://github.com/BellaHealFr/Lyorune/compare/v1.5.2...v1.5.3
[1.5.2]: https://github.com/BellaHealFr/Lyorune/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/BellaHealFr/Lyorune/compare/v1.4.2...v1.5.0
[1.4.2]: https://github.com/BellaHealFr/Lyorune/compare/v1.4.1...v1.4.2
[1.4.1]: https://github.com/BellaHealFr/Lyorune/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/BellaHealFr/Lyorune/releases/tag/v1.4.0
