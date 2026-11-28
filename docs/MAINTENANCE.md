# Lyorune : notice de maintenance

Pour la personne qui corrige ou fait évoluer Lyorune. Aucune connaissance préalable du code n'est supposée.

## Les fichiers

| Fichier | Rôle |
|---|---|
| `Core.lua` | Réglages par défaut, événements (`Z:On`), actions remises à la fin du combat (`Z:Safe`), commandes `/lyorune` |
| `Log.lua` | Journal d'erreurs, contrôle de compatibilité avec la version du jeu |
| `Data.lua` | Tout ce qui dépend de la classe : dissipations, sorts suivis, clics proposés, résurrections |
| `UI.lua` | Boutons, cases à cocher, fenêtres (éléments natifs, aucune bibliothèque obligatoire) |
| `Themes.lua` | Les 5 thèmes, un bloc de réglages par thème |
| `Frames.lua` | Les cases des joueurs : vie, soins entrants, bouclier, portée, rôle, bordures |
| `Auras.lua` | Soins sur la durée, affaiblissements, signalement des dissipations |
| `Hots.lua` | Mémoire de mes soins sur la durée lancés (cible, montant appris par rang, durée), pour la barre de vie |
| `Clicks.lua` | Clic-soin : traduction des clics en attributs de bouton sécurisé |
| `Alerts.lua` | Annonces : mana faible, mana remontée, résurrection |
| `Share.lua` | Export et import de la configuration (code texte) |
| `Options.lua` | Fenêtre `/lyorune` |
| `Tutorial.lua` | Visite guidée |
| `Minimap.lua` | Bouton de la mini-carte (réglage `minimapButton`, place gardée dans `minimapAngle`) |
| `Runes.lua` | Inscription runique animée au bas de la fenêtre d'options (réglage `showRunes`) |
| `Media/` | Images : `Logo.tga` (icône de l'addon), `Minimap.tga` (bouton), `Runes.tga` (grille de 24 runes, produite par `outils/runes.py`) |

## Corriger un bug signalé par un joueur

1. Le joueur tape `/lyorune erreurs`, clique sur « Tout sélectionner », copie (Ctrl+C) et envoie le texte.
   Le même journal se trouve dans `WTF\Account\<COMPTE>\SavedVariables\Lyorune.lua`, table `errors`.
2. Chaque entrée donne le message, la pile d'appels prise au moment de l'erreur (fichier et ligne), les versions
   de Lyorune et du jeu, la classe, l'état de combat, la taille du groupe, la zone et le lieu (extérieur, donjon,
   raid...), avec « auras secrètes » quand le jeu cache les auras aux addons.
   Sur son propre ordinateur, `python outils/erreurs.py` (`--pile` pour la pile complète) rassemble en une fois :
   le journal du jeu `Logs\General.log`, où le jeu écrit TOUTES les erreurs Lua même quand un autre addon a pris
   le gestionnaire d'erreurs, et le journal de Lyorune. Lire `General.log`
   avant de relancer le jeu : il est réécrit au lancement.
3. Les entrées « Action interdite en combat » désignent un appel protégé fait pendant un combat :
   il doit passer par `Z:Safe(clé, fonction)`, qui le remet à la fin du combat.
4. Après correction, lancer les tests (voir plus bas).

## Quand le jeu change de version

1. En jeu, `/lyorune diag` nomme les fonctions du jeu qui ont disparu (liste `Z.requiredAPI` dans `Log.lua`).
2. Si tout est présent : mettre le nouveau numéro dans `## Interface:` de `Lyorune.toc`
   (plusieurs numéros séparés par des virgules sont acceptés) et dans `Z.testedInterface` de `Log.lua`.
3. Si une fonction manque : c'est le seul endroit à adapter. Les appels sont regroupés en tête de
   `Frames.lua` et `Auras.lua`. Toute nouvelle fonction du jeu utilisée doit être ajoutée à `Z.requiredAPI`.
4. Les événements inconnus du client sont ignorés automatiquement (`Z:On` et la liste `unitEvents`).

## Valeurs secrètes

En combat, le client rend secrètes certaines valeurs (vie, auras, parfois les noms de sorts).
Une valeur secrète peut être donnée à une fonction d'affichage (`SetValue`, `SetText`, `SetVertexColor`...),
mais ni comparée ni utilisée dans un calcul. Avant tout `if` ou calcul sur une valeur venue du jeu,
tester `Z.IsSecret(valeur)`. Pour colorer selon une valeur secrète, utiliser une courbe
(`C_CurveUtil.CreateColorCurve`), comme `healthCurve` dans `Frames.lua`.
- Le jeu refuse une valeur secrète en second argument de `SetValue` (l'animation) : seulement en premier.
- Pour montrer ou cacher selon un booléen secret (soin qui dépasse la vie, par exemple) : `SetAlphaFromBoolean`.
- Un cadre rogné (`SetClipsChildren`) dont un bord suit une valeur secrète ne s'affiche plus du tout : couper avec
  un masque porté par la barre elle-même (`LostMask` dans `Frames.lua`, vu en jeu le 28 novembre 2026).

## Ajouter une classe

Tout se fait dans `Data.lua` (mode d'emploi en tête du fichier). Aucun autre fichier n'est à modifier.

## Ajouter un thème

Copier un bloc dans `Themes.lua`, changer `id`, `name` et les valeurs. Il apparaît seul dans les options.

## Ajouter un réglage

1. Valeur par défaut dans `Z.defaults` (`Core.lua`).
2. Élément dans `Options.lua` (`UI.Check`, `UI.Stepper` ou `UI.Cycle`).
3. Règle d'import dans la table `shared` de `Share.lua` si le réglage doit se partager.

## Tests

Les tests font tourner le vrai code dans un faux client, hors du jeu :

```
pip install lupa
python tests/run.py .
```

Chaque ligne doit commencer par `OK`. Les tests ne remplacent pas un essai en jeu : ils ne connaissent
ni les valeurs secrètes ni le comportement réel des boutons sécurisés.

## Cohabitation avec les autres addons

Lyorune ne modifie, ne masque et ne déplace aucun cadre du jeu ou d'un autre addon. Il ne crée que des
cadres nommés `Lyorune...` et trois variables globales : `Lyorune`, `LyoruneDB`, `Lyorune_OnAddonCompartmentClick`.
Les cases s'inscrivent dans `ClickCastFrames` (Clique) et les textures de LibSharedMedia sont proposées si présentes.

## Ajouts de la version 1.2

| Fichier | Rôle |
|---|---|
| `Locales/enUS.lua` | Traduction anglaise (clé = texte français du code) |
| `Changes.lua` | Nouveautés par version, affichées en jeu ; source de `CHANGELOG.md` |
| `Comm.lua` | Messages entre joueurs : version, envoi de configuration |
| `Preview.lua` | Mode test (faux groupe) |

Les réglages sont décrits une seule fois dans `Core.lua` (`Z.defaults`, `Z.limits`, `Z.choices`) :
la fenêtre d'options, le partage et la réinitialisation s'appuient dessus.

Outils :

| Commande | Rôle |
|---|---|
| `python outils/publier.py 1.4.0 --nouveau "..." --ameliore "..." --corrige "..."` | Tests, numéro de version, `Changes.lua`, `CHANGELOG.md`, archive dans `dist/` (détails dans `docs/PUBLICATION.md`) |
| `python outils/etiquettes.py` | Crée sur GitHub les étiquettes de `.github/labels.yml` |
| `python outils/telechargements.py` | Téléchargements par version sur GitHub |
| `python outils/verifier_api.py` | Compare les fonctions du jeu utilisées par Lyorune à celles des addons de référence installés |
| `python outils/site.py github` (ou `cloudflare`) | Fabrique le site de présentation (voir `docs/DEPLOIEMENT.md`) ; `python tests/site.py` le vérifie |
| `python outils/images_partage.py` | Redessine les images de partage du site (1200 sur 630, une par langue) |
| `outils\tester.bat`, `outils\installer.bat` | Tests, copie dans le dossier AddOns |
| `.github/workflows/` | Tests à chaque envoi sur GitHub, publication à chaque étiquette `v1.3.0` |

Le travail restant est suivi dans `docs/FEUILLE_DE_ROUTE.md`.

## Code de création d'une case : jamais d'attribut « _ »

Le code `CONFIG_SNIPPET` de `Frames.lua` est exécuté par le jeu pour chaque nouvelle case. Dans ce code, le jeu refuse
`self:SetAttribute` sur tout attribut dont le nom commence par `_` (erreur « Invalid attribute name »), et la case
n'est alors jamais créée : le cadre reste vide, sans aucune erreur au nom de Lyorune (défaut des versions 1.2 à 1.5.1).
Les attributs `_onenter` et `_onleave` passent par `_initialAttributeNames` et `_initialAttribute-...` sur l'en-tête.
Un test le contrôle. En cas de cadre vide, lire la table `frameState` du fichier `SavedVariables\Lyorune.lua`.
