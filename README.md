<p align="center"><img src="docs/images/logo.png" alt="Logo de Lyorune" width="160"></p>

# Lyorune

**Cadres de soin pour World of Warcraft: Forever.** Simples à régler, légers en combat, agréables à regarder.

[![Tests](https://github.com/BellaHealFr/Lyorune/actions/workflows/tests.yml/badge.svg)](https://github.com/BellaHealFr/Lyorune/actions/workflows/tests.yml)
[![Version](https://img.shields.io/github/v/release/BellaHealFr/Lyorune?label=version&color=33dd88)](https://github.com/BellaHealFr/Lyorune/releases/latest)
[![Téléchargements](https://img.shields.io/github/downloads/BellaHealFr/Lyorune/total?label=t%C3%A9l%C3%A9chargements&color=33dd88)](https://github.com/BellaHealFr/Lyorune/releases)
![Jeu](https://img.shields.io/badge/WoW%20Forever-interface%2016001-1e90ff)
![Licence](https://img.shields.io/badge/licence-tous%20droits%20r%C3%A9serv%C3%A9s-lightgrey)

Par **BellaDroode** · [English version](README.en.md)

## Sommaire

- [Ce que fait Lyorune](#ce-que-fait-lyorune)
- [Installation](#installation)
- [Prise en main](#prise-en-main)
- [Signaler un problème](#signaler-un-problème)
- [Compatibilité](#compatibilité)
- [Documentation](#documentation)
- [Contribuer](#contribuer)
- [L'auteur](#lauteur)
- [Licence](#licence)

## Ce que fait Lyorune

| | |
|---|---|
| **Soigner d'un clic** | Chaque bouton de souris, seul ou avec Maj, Ctrl, Alt, lance le sort de votre choix sur la case d'un joueur. |
| **Touches au survol** | Une touche du clavier, un bouton de souris supplémentaire ou la molette lance un sort sur la case survolée. |
| **Tout voir d'un coup d'œil** | Vie, soins en route, boucliers, mana des soigneurs, soins sur la durée, affaiblissements, vie basse, menace, portée. |
| **Dissiper sans chercher** | La case se colore quand vous pouvez retirer une magie, une malédiction, une maladie ou un poison. |
| **Relever sans changer de touche** | Sur un joueur mort, votre clic de soin lance votre résurrection. |
| **À votre goût** | Cinq thèmes, contraste élevé, transparence, taille, rangement par groupe ou par rôle, cadres séparés pour les tanks et les familiers. |
| **Mode test** | Un faux groupe de 5 à 40 joueurs pour tout régler tranquillement. |
| **Annonces** | Mana faible, mana remontée, résurrection, avec vos propres textes. |
| **Partage** | Envoyez votre configuration à un ami, par un code ou directement en jeu. |
| **Toujours sous la main** | Un bouton au bord de la mini-carte ouvre les options ou le mode test. Il se déplace, et se retire d'une case à cocher. |
| **Rien n'est obligatoire** | Chaque élément a sa case à cocher, et une recherche retrouve n'importe quel réglage. |

Lyorune ne modifie aucun cadre du jeu ni des autres addons : il fonctionne à côté d'ElvUI, de Clique ou de vos autres addons d'interface.

## Installation

1. Téléchargez la dernière version sur la page [Releases](https://github.com/BellaHealFr/Lyorune/releases/latest).
2. Décompressez l'archive dans `World of Warcraft\_forever_\Interface\AddOns\`. Vous devez obtenir un dossier `Lyorune`.
3. Lancez le jeu. Un tutoriel d'une minute s'ouvre à la première connexion.

Pour mettre à jour, remplacez le dossier `Lyorune` par celui de la nouvelle version. Vos réglages sont conservés.

## Prise en main

| Commande | Effet |
|---|---|
| `/lyorune` | Ouvrir les options |
| `/lyorune test` | Afficher ou masquer le faux groupe |
| `/lyorune tuto` | Relancer le tutoriel |
| `/lyorune verrou` | Verrouiller ou libérer la position des cadres |
| `/lyorune bug` | Signaler un problème |
| `/lyorune nouveautes` | Voir les nouveautés de la version |

Le guide complet pour les joueurs est dans [docs/TUTORIEL.md](docs/TUTORIEL.md).

## Signaler un problème

En jeu, tapez `/lyorune bug`. Répondez aux trois questions, copiez le rapport (Ctrl+C) et collez-le dans une [nouvelle demande](https://github.com/BellaHealFr/Lyorune/issues/new?template=bug.yml). Pour un défaut d'affichage, joignez une capture d'écran.

Première fois sur GitHub ? Le pas à pas est dans [docs/SIGNALER_UN_BUG.md](docs/SIGNALER_UN_BUG.md) : trois minutes, sans connaissance technique.

## Compatibilité

| | |
|---|---|
| Jeu | World of Warcraft: Forever, interface 16001 |
| Langues | Français, anglais |
| Dépendances | Aucune. LibSharedMedia est utilisé s'il est présent, pour proposer vos textures. |
| Autres addons | Compatible avec ElvUI, Clique et les autres cadres de groupe : Lyorune ne touche à aucun cadre qui n'est pas le sien. |

## Documentation

| Document | Pour qui |
|---|---|
| [Guide du joueur](docs/TUTORIEL.md) | Utiliser et régler Lyorune |
| [Journal des versions](CHANGELOG.md) | Ce qui change à chaque version |
| [Feuille de route](docs/FEUILLE_DE_ROUTE.md) | Ce qui est prévu |
| [Notice de maintenance](docs/MAINTENANCE.md) | Comprendre et corriger le code |
| [Publication](docs/PUBLICATION.md) | Numérotation, sortie d'une version, suivi des demandes |
| [Guide de contribution](CONTRIBUTING.md) | Signaler, proposer, corriger |
| [Sécurité](SECURITY.md) | Ce que Lyorune fait de vos données |

## Contribuer

Les rapports de bug et les idées sont les bienvenus : voir [CONTRIBUTING.md](CONTRIBUTING.md).

Le projet est testé hors du jeu à chaque modification :

```
pip install lupa
python tests/run.py .
```

## L'auteur

**BellaDroode** est un amoureux de World of Warcraft : un monde magique où la solitude n'a pas sa place.

Lyorune est né de cette idée. Derrière chaque barre de vie se trouve un compagnon de route, et soigner, c'est veiller sur lui. Cet addon est fait pour que ce geste reste simple, rapide et beau.

## Licence

Copyright © 2026 BellaDroode. Tous droits réservés.

Vous pouvez utiliser Lyorune et le partager gratuitement tel quel. Il est interdit d'en distribuer une version modifiée, de le renommer, de retirer le nom de son auteur ou de le vendre. Le texte complet est dans [LICENSE](LICENSE).

**Le code est visible, il n'est pas libre.** Comme pour tout addon de World of Warcraft, le code de Lyorune doit rester lisible par les joueurs qui l'installent ; cela ne donne aucun droit de le reprendre. Si vous voyez une copie de Lyorune renommée, modifiée ou publiée sous un autre nom d'auteur, merci de le [signaler](https://github.com/BellaHealFr/Lyorune/issues/new/choose).

World of Warcraft et Blizzard Entertainment sont des marques de Blizzard Entertainment, Inc. Lyorune est un projet indépendant. L'inscription runique de la fenêtre d'options cite une phrase de Warcraft III, en hommage.
