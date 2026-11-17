# Changelog

All notable changes to Lyorune, version by version. [Version française](CHANGELOG.md)

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); numbering follows [semantic versioning](https://semver.org/).

<!-- Fichier généré par outils/publier.py à partir de Changes.lua. Ne pas le modifier à la main. -->

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
- Magic effects (switch in Appearance): rune circle behind the logo, motes of light in the header, a spark when a setting changes, theme colour ([#39](https://github.com/BellaHealFr/Lyorune/issues/39)).

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

- Boss private auras: the game draws them itself on the frame, adjustable size and position ([#9](https://github.com/BellaHealFr/Lyorune/issues/9)).
- Heal absorb: dark red band at the end of the health, computed by the game, accurate in combat ([#10](https://github.com/BellaHealFr/Lyorune/issues/10)).
- Icons for a pending summon and for a player in another phase ([#11](https://github.com/BellaHealFr/Lyorune/issues/11)).
- Tooltip when hovering a frame: the list of your clicks and keys, out of combat ([#12](https://github.com/BellaHealFr/Lyorune/issues/12)).
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

- A macro command without a target aims at the frame; [@mouseover] works as it is.
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
- Brightness, opacity, high contrast, automatic frame shrinking in large raids.
- Ready-made profiles, direct sending of your configuration to a player, reset everything.
- English translation of the options.
- Warning when a group member has a newer version.

### Improved

- Options sorted into eight tabs, with a search box.

### Fixed

- Your own frame is no longer faded as if you were out of range.

## 1.1.0 - 2026-11-16

### Added

- Five themes, mana and resurrection announcements, configuration sharing by code.
- Error log (/lyorune erreurs) and compatibility check (/lyorune diag).

## 1.0.0 - 2026-11-16

### Added

- First version for WoW Forever: frames, click-healing, incoming heals, dispels, tutorial.

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
