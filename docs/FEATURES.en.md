# All Lyorune features

Everything Lyorune does for you, in detail. The summary is in the [README](../README.md); to learn how to set
everything up step by step, see the [player guide](GUIDE.en.md).

[Français](FONCTIONNALITES.md)

## Contents

- [Heal with one click](#heal-with-one-click)
- [Hover keys](#hover-keys)
- [Everything at a glance](#everything-at-a-glance)
- [Dispel without searching](#dispel-without-searching)
- [Resurrect with the same click](#resurrect-with-the-same-click)
- [Your style](#your-style)
- [Test mode](#test-mode)
- [Announcements](#announcements)
- [Profiles and sharing](#profiles-and-sharing)
- [Always at hand](#always-at-hand)
- [Easy to set up](#easy-to-set-up)
- [Friends of Lyorune](#friends-of-lyorune)
- [Nothing is mandatory](#nothing-is-mandatory)

## Heal with one click

<img src="images/runes/s.png" alt="" width="40">

- Every mouse button, alone or with Shift, Ctrl, Alt, casts the spell of your choice on a player's frame.
- No targeting needed: Alt + left click still targets the player, Alt + right click opens their menu.
- All your heals and buffs can be chosen, even those without a target (Inner Fire, auras, totems), and
  `/lyorune spells` tells you why a spell is missing.
- Each binding casts the highest rank or, if you turn it on, the rank you choose (right-click the spell: level and
  mana cost of each rank), adapted to the healed player's level.

### Variants

- A line's "+" gives it variants:
  - another spell on an enemy (Target or Focus frame);
  - in battlegrounds;
  - on a tank (a big rank on them, a cheaper one elsewhere);
  - or out of combat;
- and no heal goes to an enemy by mistake.

### Extras

- A trinket can go with the spell.
- Another click stops casting.
- A counter shows which clicks you really use.
- Lyorune warns you if the game's click casting uses the same combination.
- The game's ping key on a frame marks the player for the whole group.
- Your macros are written once in My macros, then go on a click or are dragged onto a game action bar.

## Hover keys

<img src="images/runes/t.png" alt="" width="40">

- A keyboard key, an extra mouse button or the wheel casts a spell on the hovered frame.

## Everything at a glance

<img src="images/runes/u.png" alt="" width="40">

### Health and protection

- Health.
- Incoming heals that glide smoothly: your heal first, other healers' heals next, paler.
- Your heal fills up while you cast, and a short flash shows where it just landed.
- Overheal warning (amber, then copper): the part that will be wasted shows on the end of the health, even at full health.
- Your heals over time on the bar: what they will still restore, the next tick brighter, even in combat; your pending Prayer of Mending.
- Shields (as a band or after the health, with what is left to absorb if you wish, even in combat).
- Heal absorbs.
- Low health (steady red edge, in combat).
- Healthy players faded so the injured stand out.

### Mana

- Mana.
- Other healers' low mana and their drink while they drink.
- When your mana runs low, a soft blue edge borders the screen.
- After a spell paid with mana, a line on your cell counts the 5 seconds before your mana comes back.

### Auras and player states

- Heals over time and debuffs (drawn by the game: visible in the middle of combat, every rank of your spells; your
  external spells such as Power Infusion and Innervate; Weakened Soul and Forbearance in grey after your heals, with
  their seconds).
- Boss private auras.
- Players' big defensives (Shield Wall, Divine Shield, Barkskin...).
- Stunned, feared or polymorphed players.
- Summons.
- Threat.
- Range in three levels.
- Group leader (never on top of the role icon).
- Class and DPS icons if you wish.
- Druid role from talents, not from their form (Restoration: healer, Balance: DPS), shared with other players who use Lyorune; `/lyorune role` tells what Lyorune knows.

### Casting and cooldowns

- Global cooldown and casting (bar or ring at the cursor).
- Your cooldown spells in a row under the frames (the game's sweep and seconds, even in combat).
- Your shaman totems with their time.
- And, below, the big spells of your allies who have Lyorune (Rebirth, Innervate, Lay on Hands...).
- And a line emptying on the cell of the player who gets your channelled heal (Penance).

### Missing buffs

- Out of combat, a panel casts all your missing buffs (priest, paladin, shaman, druid: blessings, Inner Fire, shaman
  shields and weapon, the tank's Earth Shield, shown in real time with its charges and in grey as soon as it drops,
  even in combat), with your list of buffs for PvE and another for PvP.
- And on each cell only your buffs to cast again, in grey, the same row everywhere, out of combat, in combat, in
  dungeons and in battlegrounds (a buff that is up is not shown; it comes back when missing or ending soon, 75 seconds
  before it ends by default).
- Out of combat, the next one shows under your frames in a thin strip, and one click casts it.
- Separate switches for combat and for battlegrounds.
- In combat, a key recasts your single-target buff on its holder.

### Who buffs whom

- Your buff groups in a raid.
- The blessing for each kind of player.
- And paladins never cast another paladin's blessing again (agreement between those who have Lyorune).
- Another paladin's greater blessing is recognized: the single one is not offered on top of it.
- The leader can also assign buffs.

## Dispel without searching

<img src="images/runes/d.png" alt="" width="40">

- The frame lights up when you can remove a magic effect, a curse, a disease or a poison.
- The type's picture (magic drop, curse skull...) is added, and each icon's edge takes the colour of its type.
- Up to 3 debuffs to dispel per cell, the most important first, with their seconds left, even in combat.
- The other debuffs as you like:
  - all;
  - only the useful ones (those the game shows on its raid frames, without Deserter or Exhaustion);
  - or none.
- "Always shown": debuffs that matter to a healer, even if they cannot be dispelled, shown in all three modes, in
  combat too, without sound or glow. At first, for every class: Weakened Soul and Forbearance.
  - A drop-down list to check, which also offers the debuffs already seen on your group.
  - A field to filter the list by name or number; Enter, or Shift-click on a spell, adds one never seen.
  - Names are those of your game, in English or in French: your choices stay the same if you change language.
- Those from your "Highlight" list always first (Shift-click a spell to add it), and Lyorune tells you whether it
  recognizes them in combat.

## Resurrect with the same click

<img src="images/runes/r.png" alt="" width="40">

- On a dead player, your heal click casts your resurrection spell. Nobody stays on the floor.
- Between healers: a gold line marks the players you look after, and the leader sends the assignments to everyone who
  has Lyorune, before the fight.

## Your style

<img src="images/runes/g.png" alt="" width="40">

- Five themes, high contrast, transparency, size.
- Four cell shapes with icons laid out to fit each one.
- Default icon places that never overlap.
- Every cell element placed, resized, shown or hidden as you like (its room then goes to the others).
- Placements for each character, copied from one to another.
- Sorting by group or by role.
- Separate frame for tanks.
- Pets facing their owner.
- Pinned players kept apart.
- Target and focus cells.

## Test mode

<img src="images/runes/m.png" alt="" width="40">

- A fake group of 5 to 40 players to tune everything in peace.

## Announcements

<img src="images/runes/a.png" alt="" width="40">

- Low mana, mana restored, resurrection, with your own wording.
- On WoW Forever, where mana is hidden from addons, the low mana and mana restored announcements still go out on
  their own (threshold estimated from your spell costs, recovery measured while you drink).

## Profiles and sharing

<img src="images/runes/p.png" alt="" width="40">

- One profile per group size, battleground and specialization, applied automatically.
- Copy just one part of a profile to another.
- Send your configuration to a friend, with a code or directly in game.

## Always at hand

<img src="images/runes/b.png" alt="" width="40">

- A button on the edge of the minimap opens the options or the test mode. You can move it, or remove it with a
  checkbox.
- In the game key bindings, keys of your choice open the options, hide the frames, cast the next missing buff or
  start test mode.

## Easy to set up

<img src="images/runes/f.png" alt="" width="40">

- An options window in twelve chapters, with a preview cell that shows every setting live while you change it.
- A golden rune marks what you changed (one click resets it).
- The less common settings stay folded away.
- A search finds any setting, even in the explanations.
- A gold and green healing light brings it to life, and a checkbox turns it off.

## Friends of Lyorune

<img src="images/runes/w.png" alt="" width="40">

A chapter of its own:

- Lyorune in numbers (updates, downloads, Discord).
- The healers' channel in French and in English, where healers talk about how they play and their specialisations
  (join it if you wish).
- Your healer's notebook (successful heals, resurrections and buffs, per character, in total and today, with a summary
  when leaving a dungeon, kept on your computer).
- A word from the author and a thank you wall.

## Nothing is mandatory

<img src="images/runes/n.png" alt="" width="40">

- Every element has its checkbox: keep only what you use.

---

Lyorune never changes the game's frames or other addons' frames: it runs alongside ElvUI, Clique and your other
interface addons.
