# Zenith

**Cadres de soin pour World of Warcraft: Forever.** Simples à régler, légers en combat, agréables à regarder.

[![Tests](https://github.com/BellaDroode/Zenith/actions/workflows/tests.yml/badge.svg)](https://github.com/BellaDroode/Zenith/actions/workflows/tests.yml)
[![Version](https://img.shields.io/github/v/release/BellaDroode/Zenith?label=version&color=33dd88)](https://github.com/BellaDroode/Zenith/releases/latest)
[![Téléchargements](https://img.shields.io/github/downloads/BellaDroode/Zenith/total?label=t%C3%A9l%C3%A9chargements&color=33dd88)](https://github.com/BellaDroode/Zenith/releases)
![Jeu](https://img.shields.io/badge/WoW%20Forever-interface%2016001-1e90ff)
![Licence](https://img.shields.io/badge/licence-tous%20droits%20r%C3%A9serv%C3%A9s-lightgrey)

Par **BellaDroode** · [English version](README.en.md)

## Sommaire

- [Ce que fait Zenith](#ce-que-fait-zenith)
- [Installation](#installation)
- [Prise en main](#prise-en-main)
- [Signaler un problème](#signaler-un-problème)
- [Compatibilité](#compatibilité)
- [Documentation](#documentation)
- [Contribuer](#contribuer)
- [Licence](#licence)

## Ce que fait Zenith

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
| **Rien n'est obligatoire** | Chaque élément a sa case à cocher, et une recherche retrouve n'importe quel réglage. |

Zenith ne modifie aucun cadre du jeu ni des autres addons : il fonctionne à côté d'ElvUI, de Clique ou de vos autres addons d'interface.

## Installation

1. Téléchargez la dernière version sur la page [Releases](https://github.com/BellaDroode/Zenith/releases/latest).
2. Décompressez l'archive dans `World of Warcraft\_forever_\Interface\AddOns\`. Vous devez obtenir un dossier `Zenith`.
3. Lancez le jeu. Un tutoriel d'une minute s'ouvre à la première connexion.

Pour mettre à jour, remplacez le dossier `Zenith` par celui de la nouvelle version. Vos réglages sont conservés.

## Prise en main

| Commande | Effet |
|---|---|
| `/zenith` | Ouvrir les options |
| `/zenith test` | Afficher ou masquer le faux groupe |
| `/zenith tuto` | Relancer le tutoriel |
| `/zenith verrou` | Verrouiller ou libérer la position des cadres |
| `/zenith bug` | Signaler un problème |
| `/zenith nouveautes` | Voir les nouveautés de la version |

Le guide complet pour les joueurs est dans [docs/TUTORIEL.md](docs/TUTORIEL.md).

## Signaler un problème

En jeu, tapez `/zenith bug`. Répondez aux trois questions, copiez le rapport (Ctrl+C) et collez-le dans une [nouvelle demande](https://github.com/BellaDroode/Zenith/issues/new/choose). Pour un défaut d'affichage, joignez une capture d'écran.

## Compatibilité

| | |
|---|---|
| Jeu | World of Warcraft: Forever, interface 16001 |
| Langues | Français, anglais |
| Dépendances | Aucune. LibSharedMedia est utilisé s'il est présent, pour proposer vos textures. |
| Autres addons | Compatible avec ElvUI, Clique et les autres cadres de groupe : Zenith ne touche à aucun cadre qui n'est pas le sien. |

## Documentation

| Document | Pour qui |
|---|---|
| [Guide du joueur](docs/TUTORIEL.md) | Utiliser et régler Zenith |
| [Journal des versions](CHANGELOG.md) | Ce qui change à chaque version |
| [Feuille de route](docs/FEUILLE_DE_ROUTE.md) | Ce qui est prévu |
| [Notice de maintenance](docs/MAINTENANCE.md) | Comprendre et corriger le code |
| [Guide de contribution](CONTRIBUTING.md) | Signaler, proposer, corriger |
| [Sécurité](SECURITY.md) | Ce que Zenith fait de vos données |

## Contribuer

Les rapports de bug et les idées sont les bienvenus : voir [CONTRIBUTING.md](CONTRIBUTING.md).

Le projet est testé hors du jeu à chaque modification :

```
pip install lupa
python tests/run.py .
```

## Licence

Copyright © 2026 BellaDroode. Tous droits réservés.

Vous pouvez utiliser Zenith et le partager gratuitement tel quel. Il est interdit d'en distribuer une version modifiée, de le renommer, de retirer le nom de son auteur ou de le vendre. Le texte complet est dans [LICENSE](LICENSE).

**Le code est visible, il n'est pas libre.** Comme pour tout addon de World of Warcraft, le code de Zenith doit rester lisible par les joueurs qui l'installent ; cela ne donne aucun droit de le reprendre. Si vous voyez une copie de Zenith renommée, modifiée ou publiée sous un autre nom d'auteur, merci de le [signaler](https://github.com/BellaDroode/Zenith/issues/new/choose).

World of Warcraft et Blizzard Entertainment sont des marques de Blizzard Entertainment, Inc. Zenith est un projet indépendant.
