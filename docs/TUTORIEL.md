# Lyorune : le guide du joueur

Tout ce qu'il faut savoir pour soigner avec Lyorune. Aucune connaissance technique n'est nécessaire.
En jeu, le même parcours existe en version courte : tapez `/lyorune tuto`.

[English version](GUIDE.en.md)

## 1. Les cases

Chaque joueur de votre groupe a une case. La barre colorée est sa vie : plus elle est courte, plus il est blessé.

| Ce que vous voyez | Ce que cela veut dire |
|---|---|
| Vert clair au bout de la barre | Des soins sont déjà en route |
| Bande claire en bas de la barre | Il a un bouclier |
| Barre bleue sous la vie | Sa mana (pour tous, par défaut ; hauteur réglable dans l'onglet Indicateurs) |
| Voile rouge qui clignote | Sa vie est basse |
| Bordure rouge | Il est attaqué |
| Bordure blanche | C'est votre cible |
| Contour et léger voile bleu, violet, brun ou vert | Une magie, une malédiction, une maladie ou un poison que VOUS pouvez retirer (le nom et la vie restent lisibles) |
| Case estompée | Il est hors de portée |
| « Mort », « Fantôme », « Déco » | Il est mort, en fantôme, ou déconnecté (sa case reste en place) |
| Petites icônes en haut à gauche | Vos soins sur la durée posés sur lui |
| Icônes en bas à droite | Ses affaiblissements |
| Grande icône à gauche | Un affaiblissement important (boss, ou votre liste) |
| Icône grise en bas à gauche | Il lui manque votre buff de groupe (visible hors combat) |
| Icône de résurrection au centre | Quelqu'un est en train de le relever |

## 2. Soigner d'un clic

Cliquez sur une case : le sort part sur ce joueur, sans le cibler.

Pour choisir vos sorts : `/lyorune`, onglet **Clics**. Cliquez sur une cellule du tableau (par exemple « Clic droit » + « Maj »), puis sur l'icône du sort voulu. Lyorune ne propose que les sorts que votre personnage connaît à son niveau.

Exemple pour un prêtre : clic gauche pour Soins rapides, clic droit pour Rénovation, Maj + clic droit pour le bouclier, clic milieu pour dissiper.

Vous pouvez aussi glisser un sort de votre grimoire directement sur une cellule.

Vos clics sont enregistrés par classe : chaque personnage garde les siens.

### Une spécialisation, des clics

Votre personnage a deux spécialisations (deux groupes de talents) ? Chacune a ses propres clics et ses propres touches. Quand vous changez de talents, Lyorune passe tout seul aux bons clics, même pour une macro.

- En haut à droite de l'onglet **Clics**, Lyorune indique la spécialisation dont vous voyez les clics.
- La première fois, votre seconde spécialisation reprend les clics de la première. Changez ensuite ce que vous voulez.
- « Copier l'autre spécialisation » reprend tous les clics et les touches de l'autre.
- Vous voulez les mêmes clics partout ? Décochez « Clics propres à chaque spécialisation ».

### Mes macros : plusieurs actions en un clic

Une macro fait plusieurs choses d'un seul clic : activer un bijou puis soigner, relever un mort ou soigner un vivant, attaquer un ennemi ou soigner un allié...

Lyorune garde vos macros dans une bibliothèque. Vous écrivez une macro une seule fois, puis vous la posez sur autant de clics et de touches que vous voulez, dans vos deux spécialisations. Si vous la modifiez, tous ses clics suivent. Elle ne prend aucune place dans la fenêtre `/macro` du jeu.

**Ouvrir la bibliothèque** : onglet **Clics**, bouton « Mes macros... » (ou le même bouton dans la fenêtre de choix d'un sort).

**Trois façons de créer une macro :**

1. **L'assistant** (bouton « Assistant... ») : choisissez votre sort de soin, puis cochez ce que vous voulez : arrêter le sort en cours, utiliser un bijou, relever le joueur s'il est mort, lancer un sort offensif s'il s'agit d'un ennemi. Lyorune écrit la macro pour vous.
2. **Écrire vous-même** (bouton « Nouvelle »), comme une macro du jeu, une commande par ligne.
3. **Reprendre une macro du jeu** (bouton « Importer de /macro... »), ou la glisser depuis la fenêtre `/macro` sur la liste.

**Viser le joueur de la case.** Vous n'avez rien à écrire : une commande sans cible part sur le joueur de la case.

```
/use 13
/cast Récupération
```

Une macro trouvée sur Internet avec `[@mouseover]` marche telle quelle. Pour placer le joueur de la case vous-même, écrivez `{cible}` : `/cast [@cible,dead] Résurrection; [@cible] Soins rapides`. Une cible écrite (`[@player]`) est toujours respectée. Si vous préférez que vos macros partent exactement comme écrites, décochez « Une commande sans cible vise la case » dans la bibliothèque.

**Une seule macro pour vos deux spécialisations.** La condition du jeu `[spec:1]` ou `[spec:2]` choisit le sort selon vos talents :

```
/cast [spec:1] Soins rapides; [spec:2] Rénovation
```

**La vérification, pendant que vous écrivez.** Sous la macro, Lyorune signale :

- une faute dans une condition (`[mod:shfit]`, `[ded]`) ;
- un crochet oublié, une ligne trop longue ;
- un sort que votre spécialisation active ne connaît pas (c'est peut-être celui de l'autre) ;
- une commande qui exécute du code (`/run`, `/script`).

Juste dessous, « Envoyé au jeu » montre le texte exact qui partira au clic, et « Posée sur » les clics qui utilisent la macro.

**Poser la macro sur un clic :**

- glissez-la de la liste sur une cellule de l'onglet **Clics** (ou sur le « Sort » d'une touche au survol) ;
- ou cliquez sur la cellule : vos macros sont listées sous vos sorts, à la ligne « Mes macros ».

Vos macros restent sur votre ordinateur : elles ne sont jamais envoyées ni reçues dans une configuration partagée, et « Tout réinitialiser » ne les efface pas. Quand un clic porte une macro, la résurrection automatique ne s'y ajoute pas : utilisez la case « Si le joueur est mort » de l'assistant.

Vous utilisiez déjà des macros avec une version précédente ? Elles sont rangées toutes seules dans la bibliothèque, sur les mêmes clics.

### Des macros toutes prêtes pour vos barres de sorts (facultatif)

Si vous le demandez, Lyorune crée une vraie macro du jeu pour chaque sort de vos clics. Rien n'est créé tant que la case n'est pas cochée.

1. Onglet **Clics**, cochez « Créer une macro par sort de mes clics » : une icône par macro apparaît.
2. Cliquez sur une icône, puis déposez-la dans une barre de sorts. Vous les retrouvez aussi dans `/macro`, onglet de votre personnage : leur nom commence par « Lyo: ».

La macro soigne le joueur sous votre souris (une case ou un personnage), sinon votre cible, sinon vous. Elle se met à jour quand vous changez vos clics. Lyorune ne touche jamais à vos autres macros. Pour vous en passer, décochez « Créer une macro par sort de mes clics » ou cliquez sur « Retirer les macros de Lyorune ».

## 3. Touches au survol

Vous préférez le clavier, ou votre souris a beaucoup de boutons ? Dans l'onglet **Clics**, section « Touches au survol » :

1. Cliquez sur « Touche », puis appuyez sur la touche voulue : une lettre, un bouton de souris supplémentaire, la molette, avec ou sans Maj, Ctrl, Alt.
2. Cliquez sur « Sort » et choisissez le sort.

Passez ensuite la souris sur une case et appuyez sur la touche : le sort part sur ce joueur. La touche ne change de rôle que pendant le survol d'une case.

## 4. Relever un joueur

Avec l'option « Le même clic relève un joueur mort » (onglet Clics, cochée par défaut), cliquez simplement sur un joueur mort avec votre clic de soin habituel : Lyorune lance votre résurrection à la place. Aucune touche supplémentaire.

## 5. Placer et dimensionner les cadres

- **Déplacer** : faites glisser l'étiquette « Groupe » au-dessus des cases. En raid, chaque groupe a sa colonne et son numéro (« Groupe 1 » à « Groupe 8 »), ou le nom du rôle en rangement par rôle : n'importe quelle étiquette déplace l'ensemble.
- **Verrou** : « Déplacement des cadres » (onglet Cadres) propose « Libre », « Verrouillé », ou « Avec Alt », « Avec Ctrl », « Avec Maj » : les cadres ne bougent alors que si vous maintenez la touche. Tant qu'ils sont libres, une petite mention « déverrouillé » apparaît au-dessus. On ne peut jamais les déplacer en combat.
- **Chaque personnage a sa place** : la position est gardée pour chaque personnage, même après une déconnexion. Un nouveau personnage part de la position par défaut.
- **Sans étiquettes** : décochez « Numéro de groupe au-dessus des cases ». Elles reviennent seulement le temps de déplacer les cadres.
- **Taille** : onglet Cadres, « Largeur », « Hauteur », « Espacement ».
- **Rangement** : par groupe ou par rôle. Par rôle, choisissez l'ordre (tank, soin, dégâts, ou une autre des six combinaisons).
- **Tanks et familiers** : chacun peut avoir son propre cadre, déplaçable séparément.
- **Quand les afficher** : « Afficher les cadres » (onglet Cadres) propose « Toujours » ou « En combat seulement ». « Toujours » garde les cadres à l'écran, en combat comme hors combat, y compris quand vous jouez seul en quête (avec « Mon cadre quand je suis seul » coché). « En combat seulement » les fait apparaître au début de chaque combat et disparaître à la fin. Les étiquettes s'affichent avec les cadres.
- **Un cadre reste vide ?** Tapez `/lyorune diag` : Lyorune écrit dans le chat l'état de chaque cadre. Copiez ces lignes dans votre signalement (`/lyorune bug`).
- **Grand raid** : « Réduire les cases en grand raid » rétrécit les cases au-delà de 10 puis de 25 joueurs.

## 6. Essayer sans groupe : le mode test

Tapez `/lyorune test`, ou cliquez sur « 5 joueurs », « 10 joueurs », « 25 joueurs » ou « 40 joueurs » dans l'onglet Cadres. Un faux groupe apparaît, avec des blessés, des soins en route et des affaiblissements : réglez l'apparence à votre goût, tout change en direct. Le mode test se ferme tout seul si un combat commence.

## 7. Apparence

Onglet **Apparence** :

- **Thème** : Néon, Épuré, Verre, Classique ou Héroïque.
- **Transparence** : trois préréglages en un clic, « Discret », « Semi-transparent », « Bien visible », puis les réglages fins (opacité des cadres, opacité hors de portée, luminosité).
- **Contraste élevé** : fond noir, bordure blanche, texte plus gros.
- **Texte de vie** : vie manquante, pourcentage, ou rien.

## 8. Choisir ce qui s'affiche

Onglet **Indicateurs** : chaque élément de la case a sa case à cocher. Rien n'est obligatoire. Vous pouvez par exemple n'afficher que les affaiblissements que vous pouvez dissiper, ou remplacer les icônes de soins sur la durée par des barres fines.

Onglet **Listes** : ajoutez un de vos sorts à suivre, un affaiblissement à ne jamais afficher, ou un affaiblissement à montrer en grand. Tapez le nom exact, puis Entrée. Cliquez sur un nom pour le retirer.

## 9. Annonces et sons

Onglet **Alertes** : Lyorune peut annoncer que votre mana est faible, qu'elle est remontée, et que vous relevez un joueur. Chaque annonce s'active séparément et son texte est le vôtre. Écrivez `{mana}` pour votre pourcentage de mana et `{nom}` pour le joueur relevé.

À savoir : hors des donjons et des raids, le jeu interdit à un addon d'écrire en /dire tout seul. L'annonce part alors dans le canal du groupe.

## 10. Profils et partage

Onglet **Profils** :

- **Profils prêts à l'emploi** : Donjon, Raid, Compact, Grand et lisible. Un clic change la taille et la disposition ; vos clics sont conservés.
- **Donner sa configuration** : copiez le code affiché et envoyez-le à un ami, qui le colle dans « Recevoir une configuration ».
- **Envoi direct** : tapez le nom d'un joueur qui a Lyorune. Il reçoit une demande et choisit d'accepter ou non.
- **Tout réinitialiser** : deux clics pour revenir aux réglages d'origine.

## 11. Entre joueurs qui ont Lyorune

Lyorune échange deux informations, de façon invisible, avec les autres joueurs du groupe qui l'utilisent : son numéro de version (pour vous prévenir une fois si une version plus récente existe) et les configurations que vous choisissez d'envoyer. Rien n'est jamais appliqué sans votre accord. Les deux se coupent dans l'onglet Profils, section « Entre joueurs ».

## 12. Retrouver un réglage

En haut à droite de la fenêtre d'options, tapez un mot (« mana », « tank », « thème »...) : Lyorune vous emmène au bon réglage.

## 13. Le bouton de la mini-carte

Un petit bouton rond aux couleurs de Lyorune se trouve au bord de la mini-carte.

- **Clic gauche** : ouvrir ou fermer les options.
- **Clic droit** : lancer ou fermer le mode test.
- **Glisser** : le déplacer autour de la mini-carte.

Vous n'en voulez pas ? Décochez « Bouton sur la mini-carte » dans l'onglet Aide. La commande `/lyorune` ouvre toujours les options.

## 14. L'inscription runique

Au bas de la fenêtre d'options, une ligne de runes dorées s'illumine de temps en temps, de gauche à droite. Passez la souris dessus : les runes s'éclairent et leur traduction apparaît. C'est la phrase que Muradin déchiffre sur le socle de Deuillegivre dans Warcraft III.

Elle ne sert à rien d'autre qu'au plaisir des yeux. Pour la retirer, décochez « Inscription runique au bas de cette fenêtre » dans l'onglet Aide.

## 15. Un problème ?

Tapez `/lyorune bug`. Répondez aux trois questions, cliquez sur « Tout sélectionner », copiez avec Ctrl+C, puis collez le rapport à l'adresse affichée dans la fenêtre. Pour un défaut d'affichage, joignez une capture d'écran.

Le pas à pas complet, avec la création du compte GitHub et l'envoi d'une image, est dans [SIGNALER_UN_BUG.md](SIGNALER_UN_BUG.md).

Lyorune ne vous dérange pas pour ses erreurs : au plus un message discret par session, que vous pouvez couper dans l'onglet Aide.

## Les commandes

| Commande | Effet |
|---|---|
| `/lyorune` | Ouvrir les options |
| `/lyorune test` | Mode test |
| `/lyorune tuto` | Tutoriel en jeu |
| `/lyorune verrou` | Verrouiller ou libérer la position |
| `/lyorune reset` | Remettre les cadres au centre |
| `/lyorune bug` | Signaler un problème |
| `/lyorune nouveautes` | Voir les nouveautés de la version |
