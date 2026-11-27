# Réglages de la page GitHub

Réglages à faire à la main sur https://github.com/BellaHealFr/Lyorune (roue dentée à côté de « About », puis onglet
« Settings »). Ce fichier ne change rien tout seul.

## Description « About »

Une phrase, 160 caractères au plus. GitHub n'accepte qu'une description : choisissez la langue de la page d'accueil
(le README s'ouvre en anglais).

| Langue | Texte | Longueur |
|---|---|---|
| Anglais (en ligne depuis le 27 novembre 2026) | Healing frames for WoW Forever: click-casting at the rank you choose, missing buffs, dispels, healer mana. Every feature optional, in English and French. | 153 |
| Français | Cadres de soin pour WoW Forever : clic-soin au rang choisi, buffs manquants, dissipation, mana des soigneurs. Tout se coche, en français et en anglais. | 151 |

Le détail des fonctions, dont les nouveautés de chaque version (en 1.51.0 : affaiblissements « Toujours montrés »,
Âme affaiblie et Longanimité, et leur liste à cocher ; en 1.51.1 : rôle du druide d'après ses talents), va dans le README et dans
[FEATURES.en.md](FEATURES.en.md) / [FONCTIONNALITES.md](FONCTIONNALITES.md), plus dans la description.

En ligne de commande : `gh repo edit BellaHealFr/Lyorune --description "..."`.

## Topics

GitHub accepte 20 topics au plus. Liste retenue, qui décrit les fonctions de l'addon et le jeu :

| Topic | État |
|---|---|
| `world-of-warcraft` | déjà posé |
| `world-of-warcraft-addon` | déjà posé |
| `wow` | déjà posé |
| `wow-addon` | déjà posé |
| `wow-forever` | déjà posé |
| `addon` | déjà posé |
| `warcraft` | déjà posé |
| `lua` | déjà posé |
| `healer` | déjà posé |
| `healing` | déjà posé |
| `raid-frames` | déjà posé |
| `unit-frames` | déjà posé, catégorie du Hub WowUp |
| `click-casting` | déjà posé |
| `buffs-debuffs` | déjà posé, catégorie du Hub WowUp |
| `wow-forever-addon` | posé |
| `combat` | posé, catégorie du Hub WowUp |
| `priest` | posé, classe (Hub WowUp) |
| `paladin` | posé, classe (Hub WowUp) |
| `shaman` | posé, classe (Hub WowUp) |
| `druid` | posé, classe (Hub WowUp) |
| `healing-frames` | retiré (utilisé par aucun autre dépôt, il ne rapportait aucune visite) |

Total : 20.

En ligne de commande :

```
gh repo edit BellaHealFr/Lyorune --remove-topic healing-frames
gh repo edit BellaHealFr/Lyorune --add-topic wow-forever-addon --add-topic combat --add-topic priest --add-topic paladin --add-topic shaman --add-topic druid
```

## Autres réglages

- **Image de prévisualisation sociale** : déjà définie (`docs/images/apercu-github.png`, logo sur fond étoilé). C'est
  aussi l'icône que montre le Hub WowUp. Rien à faire.
- **Releases avec notes** : déjà faites à chaque version par la publication automatique (archive et notes de
  `RELEASE.md`). Rien à faire.
- **Discussions** : désactivées. Les échanges se font aujourd'hui sur Discord : à activer seulement si vous voulez
  aussi un espace de discussion sur GitHub (Settings, General, Features, « Discussions »).
- **Site web** : le champ « Website » de « About » pointe déjà vers `https://bellahealfr.github.io/Lyorune/`. Rien à
  faire.
