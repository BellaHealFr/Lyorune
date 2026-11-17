# Lyorune : le guide du joueur

Tout ce qu'il faut savoir pour soigner avec Lyorune. Aucune connaissance technique n'est nécessaire.
En jeu, le même parcours existe en version courte : tapez `/lyorune tuto`.

Au tout premier lancement, un **assistant** pose trois questions avant la visite : votre rôle (soigneur, tank ou dégâts), la taille de groupe où vous jouez le plus (seul ou à 5, raid de 10 à 25, raid de 40) et la forme des cases, choisie sur des vignettes. Lyorune se règle d'après vos réponses ; tout se retouche ensuite dans les options. « Passer » garde les réglages d'origine. Pour le revoir : `/lyorune assistant`, ou « Assistant de départ » dans l'onglet Aide.

[English version](GUIDE.en.md)

## 1. Les cases

Chaque joueur de votre groupe a une case. La barre colorée est sa vie : plus elle est courte, plus il est blessé.

| Ce que vous voyez | Ce que cela veut dire |
|---|---|
| Vert clair au bout de la barre | Des soins sont déjà en route |
| Bande claire en bas de la barre | Il a un bouclier |
| Rouge sombre au bout de la vie | Un affaiblissement « mange » cette part de vie : vos soins la remplissent d'abord, avant de compter |
| Barre bleue sous la vie | Sa mana (pour tous, par défaut ; hauteur et couleur réglables dans l'onglet Indicateurs : bleu, bleu ciel, violet, turquoise ou blanc). Avec « Pourcentage de mana dans la barre », le % s'y écrit, même en combat |
| Voile rouge qui clignote | Sa vie est basse |
| Bordure rouge | Il est attaqué |
| Trait de couleur en haut de la vie (si vous l'activez) | Sa menace : jaune, il monte dans la liste d'un monstre ; orange, il va le prendre ; rouge, il l'a |
| Petit carré de couleur dans un coin | Un sort que vous avez placé dans ce coin (onglet Soins) : il se vide avec le temps |
| Bordure blanche | C'est votre cible |
| Contour et léger voile bleu, violet, brun ou vert | Une magie, une malédiction, une maladie ou un poison que VOUS pouvez retirer (le nom et la vie restent lisibles) |
| Case estompée | Il est hors de portée |
| « Mort », « Fantôme », « Déco » | Il est mort, en fantôme, ou déconnecté (sa case reste en place) |
| Petites icônes en haut à gauche | Vos soins sur la durée posés sur lui |
| Icônes en bas à droite | Ses affaiblissements |
| Grande icône à gauche | Un affaiblissement important (boss, ou votre liste) |
| Contour doré qui pulse | Un affaiblissement important est posé (avec un son pour ceux de votre liste, si vous l'activez) |
| Icônes dessinées par le jeu (au centre, par défaut) | Des affaiblissements de boss que le jeu cache aux addons : il les montre lui-même sur la case |
| Icône grise en bas à gauche | Il lui manque votre buff de groupe (visible hors combat) |
| Icône de résurrection au centre | Quelqu'un est en train de le relever |
| Icône d'invocation au centre | Une invocation lui est proposée, ou il l'a acceptée ou refusée |
| Icône de phase au centre | Il est dans une autre phase : il semble proche, mais vos sorts ne l'atteignent pas |

Survolez une case hors combat : l'infobulle montre le joueur, puis la liste de vos clics et touches avec le sort ou la macro de chacun.

## 2. Soigner d'un clic

Cliquez sur une case : le sort part sur ce joueur, sans le cibler.

Pour choisir vos sorts : `/lyorune`, onglet **Clics**. Tous vos raccourcis sont sur une seule liste, un par ligne : à gauche le clic ou la touche, au milieu le sort, à droite « x » pour le retirer.

**Ajouter un raccourci :**

1. Cliquez sur « + Ajouter un clic ou une touche ».
2. Faites sur ce même bouton la combinaison voulue : un clic (gauche, droit, milieu, boutons 4 et 5), avec ou sans Alt, Ctrl, Maj, et même plusieurs à la fois (Ctrl + Maj + clic droit). Une touche du clavier, un bouton de souris supplémentaire ou la molette marchent aussi.
3. Choisissez le sort dans la fenêtre qui s'ouvre. Lyorune ne propose que les sorts que votre personnage connaît à son niveau.

Il n'y a pas de limite : ajoutez autant de lignes que vous voulez. Quand la liste est longue, faites-la défiler avec la molette.

- **Changer le sort** : cliquez sur le sort de la ligne, ou glissez-y un sort de votre grimoire.
- **Changer le raccourci** : cliquez sur le clic ou la touche de la ligne, puis faites la nouvelle combinaison. Si elle était déjà prise, les deux sorts sont échangés : rien n'est perdu.
- Un clic gauche ou droit sans sort garde son rôle habituel : cibler le joueur, ouvrir son menu.

Exemple pour un prêtre : clic gauche pour Soins rapides, clic droit pour Rénovation, Maj + clic droit pour le bouclier, clic milieu pour dissiper, Ctrl + Maj + clic gauche pour Prière de soins.

### Un nouveau sort sans clic

Vous venez d'apprendre un sort utilisable sur un allié, et aucun de vos clics ni de vos touches ne le lance ? Lyorune vous le dit une fois dans la discussion, et le sort apparaît en haut de l'onglet **Clics** :

- « Attribuer » : faites ensuite sur le bouton « Ajouter » le clic ou la touche voulu, le sort y est posé directement ;
- « x » : Lyorune ne vous le propose plus.

Votre résurrection et vos buffs de groupe ne sont jamais signalés. Pour ne plus rien voir, décochez « Signaler un nouveau sort sans clic ».

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

- glissez-la de la liste sur le sort d'une ligne de l'onglet **Clics** ;
- ou cliquez sur ce sort : vos macros sont listées sous vos sorts, à la ligne « Mes macros ».

Vos macros restent sur votre ordinateur : elles ne sont jamais envoyées ni reçues dans une configuration partagée, et « Tout réinitialiser » ne les efface pas. Quand un clic porte une macro, la résurrection automatique ne s'y ajoute pas : utilisez la case « Si le joueur est mort » de l'assistant.

Vous utilisiez déjà des macros avec une version précédente ? Elles sont rangées toutes seules dans la bibliothèque, sur les mêmes clics.

### Des macros toutes prêtes pour vos barres de sorts (facultatif)

Si vous le demandez, Lyorune crée une vraie macro du jeu pour chaque sort de vos clics. Rien n'est créé tant que la case n'est pas cochée.

1. Onglet **Clics**, cochez « Créer une macro par sort de mes clics » : une icône par macro apparaît.
2. Cliquez sur une icône, puis déposez-la dans une barre de sorts. Vous les retrouvez aussi dans `/macro`, onglet de votre personnage : leur nom commence par « Lyo: ».

La macro soigne le joueur sous votre souris (une case ou un personnage), sinon votre cible, sinon vous. Elle se met à jour quand vous changez vos clics. Lyorune ne touche jamais à vos autres macros. Pour vous en passer, décochez « Créer une macro par sort de mes clics » ou cliquez sur « Retirer les macros de Lyorune ».

## 3. Touches au survol

Vous préférez le clavier, ou votre souris a beaucoup de boutons ? Les touches se règlent sur la même liste que les clics, onglet **Clics** :

1. Cliquez sur « + Ajouter un clic ou une touche ».
2. Appuyez sur la touche voulue : une lettre, un chiffre, un bouton de souris à partir du 6e, la molette, avec ou sans Maj, Ctrl, Alt (et leurs combinaisons). Échap annule.
3. Choisissez le sort.

Passez ensuite la souris sur une case et appuyez sur la touche : le sort part sur ce joueur. La touche ne change de rôle que pendant le survol d'une case. Le nombre de touches n'est pas limité.

## 4. Relever un joueur

Avec l'option « Le même clic relève un joueur mort » (onglet Clics, cochée par défaut), cliquez simplement sur un joueur mort avec votre clic de soin habituel : Lyorune lance votre résurrection à la place. Aucune touche supplémentaire.

## 5. Placer et dimensionner les cadres

- **Déplacer** : faites glisser l'étiquette « Groupe » au-dessus des cases. En raid, chaque groupe a sa colonne et son numéro (« Groupe 1 » à « Groupe 8 »), ou le nom du rôle en rangement par rôle : n'importe quelle étiquette déplace l'ensemble.
- **Verrou** : « Déplacement des cadres » (onglet Cadres) propose « Libre », « Verrouillé », ou « Avec Alt », « Avec Ctrl », « Avec Maj » : les cadres ne bougent alors que si vous maintenez la touche. Tant qu'ils sont libres, une petite mention « déverrouillé » apparaît au-dessus. On ne peut jamais les déplacer en combat.
- **Chaque personnage a sa place** : la position est gardée pour chaque personnage, même après une déconnexion. Un nouveau personnage part de la position par défaut.
- **Sans étiquettes** : décochez « Numéro de groupe au-dessus des cases ». Elles reviennent seulement le temps de déplacer les cadres.
- **Taille** : onglet Cadres, « Largeur », « Hauteur », « Espacement ».
- **Échelle générale** : onglet Cadres, « Échelle générale (%) », de 50 à 200 %. Tout grandit ou rapetisse ensemble (cases, icônes, textes, étiquettes), sans changer vos réglages de taille. Le mode test suit la même échelle. En combat, le changement attend la fin du combat.
- **Placer les éléments de la case** : onglet Cadres, bouton « Placer les éléments de la case... ». Une case d'exemple agrandie montre tous les éléments : nom, texte de vie, icône de rôle, marqueur de raid, icône centrale, vos soins sur la durée, affaiblissements, affaiblissement important, buff manquant et auras privées. Glissez un élément avec la souris, ou choisissez-le dans la liste et poussez-le avec « Gauche », « Haut », « Bas », « Droite » : un pixel par clic, cinq avec Maj. Le décalage s'affiche sous la case et vos vraies cases suivent aussitôt. « Remettre à sa place » annule pour l'élément choisi, « Tout remettre » pour tous. Chaque forme de case (Barre, Tuile, Carré, Bandeau) garde ses propres placements.
- **Rangement** : par groupe, par rôle ou en grille. Par rôle, choisissez l'ordre (tank, soin, dégâts, ou une autre des six combinaisons). En grille, tout le raid tient d'un seul bloc, sans trou entre les groupes : « Cases par colonne en grille » règle sa hauteur (8 cases par colonne donnent 5 colonnes pour 40 joueurs).
- **Ordre dans chaque bloc** : l'ordre du groupe, par nom, ou par classe puis par nom (tous les prêtres ensemble, puis tous les druides...). C'est le jeu qui tient cet ordre à jour, même en plein combat, quand quelqu'un arrive ou change de groupe. En rangement par rôle, « par classe » range par nom dans chaque rôle.
- **Chaque groupe garde sa place** : en rangement par groupe, le groupe 3 reste toujours en 3e colonne, même si le groupe 2 est vide. Pratique pour retrouver un joueur d'un coup d'œil. Décoché, les groupes se resserrent.
- **Tanks et familiers** : chacun peut avoir son propre cadre, déplaçable séparément.
- **Cible, cible de la cible, focalisation** : onglet Cadres, trois cases à cocher (« Case de ma cible », « Case de la cible de ma cible », « Case de ma focalisation »). Elles apparaissent dans un petit cadre « Cible », que l'on déplace par son étiquette comme les autres. Chaque case a vos clics et la même apparence que celles du groupe. Elle n'apparaît que si la cible ou la focalisation existe, même en combat. Un ennemi est en rouge, un personnage non joueur amical en vert, et ni l'un ni l'autre n'affiche d'icônes de soins ou d'affaiblissements. La cible de votre cible (par exemple le joueur que le boss frappe) est revue deux fois par seconde, car le jeu ne prévient pas quand elle change.
- **Quand les afficher** : « Afficher les cadres » (onglet Cadres) propose « Toujours » ou « En combat seulement ». « Toujours » garde les cadres à l'écran, en combat comme hors combat, y compris quand vous jouez seul en quête (avec « Mon cadre quand je suis seul » coché). « En combat seulement » les fait apparaître au début de chaque combat et disparaître à la fin. Les étiquettes s'affichent avec les cadres.
- **Un cadre reste vide ?** Tapez `/lyorune diag` : Lyorune écrit dans le chat l'état de chaque cadre. Copiez ces lignes dans votre signalement (`/lyorune bug`).
- **Grand raid** : « Réduire les cases en grand raid » rétrécit les cases au-delà de 10 puis de 25 joueurs.

## 6. Essayer sans groupe : le mode test

Tapez `/lyorune test`, ou cliquez sur « 5 joueurs », « 10 joueurs », « 25 joueurs » ou « 40 joueurs » dans l'onglet Cadres. Un faux groupe apparaît, avec des blessés, des soins en route et des affaiblissements : réglez l'apparence à votre goût, tout change en direct. Le mode test se ferme tout seul si un combat commence.

## 7. Apparence

Onglet **Apparence** :

- **Forme des cases** : quatre vignettes montrent chaque forme avec vos couleurs. **Barre** (le nom à gauche, la vie à droite), **Tuile** (la forme d'origine), **Carré** (petit, pour les grands raids) et **Bandeau** (une ligne longue et fine). Un clic suffit : la taille, le texte et la barre de mana suivent. Vous retouchez ensuite chaque valeur dans l'onglet Cadres. « Revenir » annule le dernier choix, « Voir en vrai » affiche un faux groupe de 10 joueurs.
- **Angles des cases** : droits ou arrondis, quelle que soit la forme.
- **Fond et bordure par groupe** : chaque groupe est posé sur son propre fond, aux couleurs du thème.
- **Couleurs de classe** : « Vives » (par défaut) pour des couleurs franches et lumineuses, ou « Naturelles » pour celles du jeu.
- **Thème** : Néon, Épuré, Verre, Classique ou Héroïque.
- **Transparence** : trois préréglages en un clic, « Discret », « Semi-transparent », « Bien visible », puis les réglages fins (opacité des cadres, opacité hors de portée, luminosité).
- **Contraste élevé** : fond noir, bordure blanche, texte plus gros. Il vaut aussi pour les fenêtres de Lyorune.
- **Texte de vie** : vie manquante, pourcentage, ou rien.

Rubrique **Fenêtres de Lyorune** (à droite du même onglet) : elle habille la fenêtre d'options, la visite guidée et les petites fenêtres, jamais les cases.

- **Thème des fenêtres** : trois habillages complets, chacun avec son cadre, ses boutons, ses cases à cocher et ses titres de rubrique. Le changement est immédiat, sans `/reload`, et l'en-tête (logo, nom, version) ne bouge pas.
  - **Moderne** (par défaut) : fond sombre et net aux angles arrondis, boutons plats, bleu givre et or du logo.
  - **Classique** : comme les fenêtres du jeu, avec le cadre de boîte de dialogue, les boutons rouges et les cases à cocher du jeu, des onglets en relief et des champs de saisie creusés.
  - **MMORPG** : un grimoire, avec un fond de pierre voilé derrière le texte, une bordure dorée, une rune gravée dans chaque angle, des plaques de bronze au biseau doré en guise de boutons (elles s'enfoncent au clic), des onglets ciselés, des champs de saisie creusés, des cases cerclées d'or et marquées d'une rune et des titres de rubrique en écriture ancienne.
- **Animations réduites** : les fenêtres s'ouvrent en simple fondu, les runes et le logo restent immobiles, rien ne bouge en boucle. Pratique si le mouvement vous gêne.
- **Effets magiques** (activés par défaut) : un cercle de runes tourne lentement derrière le logo et s'illumine à l'ouverture, de petites particules de lumière montent dans l'en-tête, et une étincelle s'élève quand vous changez un réglage. Ils prennent la couleur du thème (givre en Moderne, or en Classique, braise en MMORPG) et ne touchent jamais aux cases de soin. « Animations réduites » les coupe aussi.

Les fenêtres des macros, du rapport de bug, du journal et des nouveautés s'ouvrent à côté de la fenêtre d'options, sans la recouvrir.

## 8. Choisir ce qui s'affiche

Onglet **Indicateurs** : chaque élément de la case a sa case à cocher. Rien n'est obligatoire. Vous pouvez par exemple n'afficher que les affaiblissements que vous pouvez dissiper.

### Vos soins sur la durée (onglet Soins)

Lyorune s'adapte à votre classe (prêtre, druide, paladin ou chaman) : il suit vos soins sur la durée et vos boucliers, plus les sorts de votre liste.

- **Icônes ou barres fines** : choisissez l'affichage. Sur les icônes, quatre réglages se combinent comme vous voulez :
  - **Cercle qui se vide** : un voile tourne à mesure que le temps passe ;
  - **Décompte en secondes** : les secondes restantes, écrites par le jeu ;
  - **Icône qui s'efface à la fin** : pendant les 6 dernières secondes, l'icône pâlit. C'est le moment de relancer ;
  - **Nombre de charges** : un petit chiffre quand le soin en a plusieurs.
- **Coins de la case** : placez un de vos sorts dans chaque coin. Il devient un petit carré de couleur (vert, bleu, jaune, rose) qui se vide avec le temps, et quitte la rangée d'icônes. D'un coup d'œil, vous voyez qui n'a pas votre Rénovation ou votre Récupération. Chaque classe garde ses propres coins : votre druide et votre prêtre ne se mélangent pas.
- **Panneau des buffs manquants** (prêtre, druide, mage) : hors combat, une petite fenêtre liste les joueurs à qui manque votre buff de groupe (Robustesse, Marque du fauve, Intelligence des arcanes). Un clic sur un nom lui lance le buff, sans le cibler ; un clic droit lance la version de groupe. Quand trois joueurs d'un même groupe n'ont pas le buff, une seule ligne « Groupe N » lance directement la version de groupe. Un joueur hors de portée est estompé. Le panneau se cache en combat et revient après ; la croix le ferme jusqu'à la fin du prochain combat. Déplacez-le par son titre : sa place est gardée pour chaque personnage. Il a son propre interrupteur, séparé de la petite icône grise sur la case.

Tout marche en combat. Le jeu y cache le nom des auras, mais Lyorune reconnaît vos soins à leur numéro, ou au sort que vous venez de lancer. Un soin qu'il ne peut pas reconnaître reste dans la rangée d'icônes, jamais dans un mauvais coin.

Onglet **Listes** : ajoutez un de vos sorts à suivre, un affaiblissement à ne jamais afficher, ou un affaiblissement à montrer en grand. Tapez le nom exact, puis Entrée. Cliquez sur un nom pour le retirer.

### En donjon et en raid

- **Auras privées des boss** : certains affaiblissements de boss sont cachés aux addons. Le jeu accepte pourtant de les dessiner lui-même sur la case : choisissez leur taille et leur place (au centre, en haut, en bas, à gauche ou à droite). Deux au plus par joueur.
- **Absorption de soins** : la bande rouge sombre au bout de la vie montre ce qu'un affaiblissement « mange ». Vos soins la remplissent d'abord. Le montant vient du jeu, il reste juste en combat.
- **Contour lumineux et son** : un affaiblissement de votre liste « À mettre en avant », ou d'un boss, entoure la case d'un contour doré. Le son, à activer, part pour ceux de votre liste.
  À savoir : en combat, le jeu cache souvent le nom des affaiblissements de boss. Lyorune ne peut alors pas savoir lequel est posé : le contour reste possible (le jeu décide lui-même s'il s'agit d'un boss), le son non.

## 9. Annonces et sons

Onglet **Alertes** : Lyorune peut annoncer que votre mana est faible, qu'elle est remontée, et que vous relevez un joueur. Chaque annonce s'active séparément et son texte est le vôtre. Écrivez `{mana}` pour votre pourcentage de mana et `{nom}` pour le joueur relevé.

À savoir : hors des donjons et des raids, le jeu interdit à un addon d'écrire en /dire tout seul. L'annonce part alors dans le canal du groupe.

## 10. Profils et partage

Onglet **Profils** :

- **Mes profils** : réglez l'apparence comme vous l'aimez, tapez un nom (par exemple « Donjon ») et cliquez sur « Enregistrer sous ». Un profil garde la taille, la forme, les couleurs, les indicateurs, vos soins sur la durée et le placement des éléments. Il ne touche jamais à vos clics, vos macros, vos listes ni vos annonces. Choisissez un profil dans la liste, puis « Charger » ou « Supprimer » (deux clics). Ce que vous réglez pendant qu'un profil est en cours lui appartient : Lyorune l'enregistre tout seul avant de changer de profil et à la déconnexion. Jusqu'à 20 profils.
- **Profils automatiques** : cochez « Changer de profil tout seul », puis remplissez le petit tableau. Une colonne par taille de groupe (seul ou à 5, raid de 10, de 25, de 40) et une ligne par spécialisation : cliquez sur une case pour passer au profil suivant, clic droit pour revenir en arrière. « - » veut dire « garder les réglages du moment ». Sur la ligne de la 2e spécialisation, « comme 1 » reprend le choix de la 1re. Le changement se fait sans /reload, dès que le groupe change de taille ou que vous changez de spécialisation ; en combat, il attend la fin du combat. Un message dans le chat dit quel profil vient d'être appliqué.
- **Profils prêts à l'emploi** : Donjon, Raid, Compact, Grand et lisible. Un clic change la taille et la disposition ; vos clics sont conservés.
- **Donner sa configuration** : copiez le code affiché et envoyez-le à un ami, qui le colle dans « Recevoir une configuration ». Le code contient l'apparence (placements des éléments compris), les clics et les listes, mais jamais vos macros ni les phrases de vos annonces (mana, résurrection) : personne ne peut vous faire dire quelque chose dans le chat.
- **Envoi direct** : tapez le nom d'un joueur qui a Lyorune. Il reçoit une demande et choisit d'accepter ou non. Une demande n'arrive que d'un membre de votre groupe, de votre guilde ou de votre liste d'amis, une fois par minute au plus. La fenêtre affiche le nom et le royaume de l'expéditeur, et le bouton « Importer » ne s'active qu'au bout de deux secondes.
- **Annuler l'import** : un code collé ou une configuration reçue ne vous plaît pas ? Ce bouton (ou `/lyorune annuler`) remet vos réglages d'avant le dernier import : apparence, clics, touches et listes. Lyorune garde cette sauvegarde même après un /reload, jusqu'au prochain import.
- **Tout réinitialiser** : deux clics pour revenir aux réglages d'origine. Vos profils enregistrés sont gardés.

## 11. Entre joueurs qui ont Lyorune

Lyorune se parle de façon invisible avec les autres joueurs du groupe qui l'utilisent. Tout se règle dans l'onglet Profils, section « Entre joueurs » :

- **Synchronisation entre joueurs** : l'interrupteur général. Décoché, rien ne part et rien n'est lu ; les cases du dessous sont grisées.
- **Qui relève qui** (« Montrer qui relève qui ») : quand un soigneur commence une résurrection, son nom s'affiche en vert à la place de « Mort » sur la case du joueur, chez tous ceux qui ont Lyorune. Vous voyez d'un coup d'œil qui est déjà pris en charge : deux soigneurs ne relèvent plus le même joueur pendant qu'un autre attend. Le nom reste le temps du sort, puis une minute pendant que le joueur décide d'accepter. Pendant un combat de boss, le jeu bloque ces messages : seule l'icône de résurrection du jeu reste.
- **Qui a Lyorune** : sous les cases, Lyorune compte les joueurs du groupe qui l'utilisent. Passez la souris dessus pour la liste, avec la version de chacun, ou tapez `/lyorune groupe`.
- **Configurations** : vous recevez seulement celles que vous acceptez (voir le chapitre 10).
- **Nouvelle version** : Lyorune vous prévient une fois si une version plus récente existe.

Rien n'est jamais appliqué sans votre accord. Un joueur qui envoie trop de messages est ignoré un moment.

Une nouvelle version n'est signalée que si deux joueurs différents l'annoncent. Téléchargez Lyorune uniquement sur sa page officielle : [github.com/BellaHealFr/Lyorune](https://github.com/BellaHealFr/Lyorune/releases/latest). Un autre site, ou un joueur qui vous envoie un fichier, n'est pas une source sûre.

## 12. Retrouver un réglage

En haut à droite de la fenêtre d'options, tapez un mot (« mana », « tank », « thème »...) : Lyorune vous emmène au bon réglage.

## 13. Le bouton de la mini-carte

Un petit bouton rond aux couleurs de Lyorune se trouve au bord de la mini-carte.

- **Clic gauche** : ouvrir ou fermer les options.
- **Clic droit** : lancer ou fermer le mode test.
- **Glisser** : le déplacer autour de la mini-carte.

Vous n'en voulez pas ? Décochez « Bouton sur la mini-carte » dans l'onglet Aide. La commande `/lyorune` ouvre toujours les options.

## 14. L'inscription runique

Au bas de la fenêtre d'options, une ligne de runes s'écrit à l'ouverture, une rune après l'autre, puis une lueur la parcourt de temps en temps, de gauche à droite. Passez la souris dessus : une vague de lumière part du centre, puis la traduction apparaît. Ses couleurs suivent le thème des fenêtres : bleu givre, or doux, ou braise avec quelques étincelles. C'est la phrase que Muradin déchiffre sur le socle de Deuillegivre dans Warcraft III.

Elle ne sert à rien d'autre qu'au plaisir des yeux. Pour la retirer, décochez « Inscription runique au bas de cette fenêtre » dans l'onglet Aide.

## 15. Un problème ?

Tapez `/lyorune bug`. Répondez aux trois questions, cliquez sur « Tout sélectionner », copiez avec Ctrl+C, puis collez le rapport à l'adresse affichée dans la fenêtre. Le nom de votre personnage, de votre royaume et des membres de votre groupe y est remplacé par « (joueur) » et « (royaume) » : le rapport est public. Pour un défaut d'affichage, joignez une capture d'écran.

Le pas à pas complet, avec la création du compte GitHub et l'envoi d'une image, est dans [SIGNALER_UN_BUG.md](SIGNALER_UN_BUG.md).

Lyorune ne vous dérange pas pour ses erreurs : au plus un message discret par session, que vous pouvez couper dans l'onglet Aide.

## Les commandes

| Commande | Effet |
|---|---|
| `/lyorune` | Ouvrir les options |
| `/lyorune test` | Mode test |
| `/lyorune tuto` | Tutoriel en jeu |
| `/lyorune assistant` | Assistant de départ (trois questions) |
| `/lyorune verrou` | Verrouiller ou libérer la position |
| `/lyorune reset` | Remettre les cadres au centre |
| `/lyorune groupe` | Joueurs du groupe qui ont Lyorune |
| `/lyorune annuler` | Revenir à la configuration d'avant le dernier import |
| `/lyorune bug` | Signaler un problème |
| `/lyorune nouveautes` | Voir les nouveautés de la version |
