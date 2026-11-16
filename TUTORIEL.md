# Zenith : le guide du joueur

Tout ce qu'il faut savoir pour soigner avec Zenith. Aucune connaissance technique n'est nécessaire.
En jeu, le même parcours existe en version courte : tapez `/zenith tuto`.

## 1. Les cases

Chaque joueur de votre groupe a une case. La barre colorée est sa vie : plus elle est courte, plus il est blessé.

| Ce que vous voyez | Ce que cela veut dire |
|---|---|
| Vert clair au bout de la barre | Des soins sont déjà en route |
| Bande claire en bas de la barre | Il a un bouclier |
| Barre bleue sous la vie | Sa mana (soigneurs, par défaut) |
| Voile rouge qui clignote | Sa vie est basse |
| Bordure rouge | Il est attaqué |
| Bordure blanche | C'est votre cible |
| Cadre bleu, violet, brun ou vert | Une magie, une malédiction, une maladie ou un poison que VOUS pouvez retirer |
| Case estompée | Il est hors de portée |
| « Mort », « Fantôme », « Déco » | Il est mort, en fantôme, ou déconnecté (sa case reste en place) |
| Petites icônes en haut à gauche | Vos soins sur la durée posés sur lui |
| Icônes en bas à droite | Ses affaiblissements |
| Grande icône à gauche | Un affaiblissement important (boss, ou votre liste) |
| Icône grise en bas à gauche | Il lui manque votre buff de groupe (visible hors combat) |
| Icône de résurrection au centre | Quelqu'un est en train de le relever |

## 2. Soigner d'un clic

Cliquez sur une case : le sort part sur ce joueur, sans le cibler.

Pour choisir vos sorts : `/zenith`, onglet **Clics**. Cliquez sur une cellule du tableau (par exemple « Clic droit » + « Maj »), puis sur l'icône du sort voulu. Zenith ne propose que les sorts que votre personnage connaît à son niveau.

Exemple pour un prêtre : clic gauche pour Soins rapides, clic droit pour Rénovation, Maj + clic droit pour le bouclier, clic milieu pour dissiper.

Vos clics sont enregistrés par classe : chaque personnage garde les siens.

## 3. Touches au survol

Vous préférez le clavier, ou votre souris a beaucoup de boutons ? Dans l'onglet **Clics**, section « Touches au survol » :

1. Cliquez sur « Touche », puis appuyez sur la touche voulue : une lettre, un bouton de souris supplémentaire, la molette, avec ou sans Maj, Ctrl, Alt.
2. Cliquez sur « Sort » et choisissez le sort.

Passez ensuite la souris sur une case et appuyez sur la touche : le sort part sur ce joueur. La touche ne change de rôle que pendant le survol d'une case.

## 4. Relever un joueur

Avec l'option « Le même clic relève un joueur mort » (onglet Clics, cochée par défaut), cliquez simplement sur un joueur mort avec votre clic de soin habituel : Zenith lance votre résurrection à la place. Aucune touche supplémentaire.

## 5. Placer et dimensionner les cadres

- **Déplacer** : faites glisser la petite poignée « Zenith » au-dessus des cases. Une fois satisfait, cochez « Verrouiller la position » (onglet Cadres) : la poignée disparaît.
- **Taille** : onglet Cadres, « Largeur », « Hauteur », « Espacement ».
- **Rangement** : par groupe ou par rôle. Par rôle, choisissez l'ordre (tank, soin, dégâts, ou une autre des six combinaisons).
- **Tanks et familiers** : chacun peut avoir son propre cadre, déplaçable séparément.
- **Grand raid** : « Réduire les cases en grand raid » rétrécit les cases au-delà de 10 puis de 25 joueurs.

## 6. Essayer sans groupe : le mode test

Tapez `/zenith test`, ou cliquez sur « 5 joueurs », « 10 joueurs », « 25 joueurs » ou « 40 joueurs » dans l'onglet Cadres. Un faux groupe apparaît, avec des blessés, des soins en route et des affaiblissements : réglez l'apparence à votre goût, tout change en direct. Le mode test se ferme tout seul si un combat commence.

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

Onglet **Alertes** : Zenith peut annoncer que votre mana est faible, qu'elle est remontée, et que vous relevez un joueur. Chaque annonce s'active séparément et son texte est le vôtre. Écrivez `{mana}` pour votre pourcentage de mana et `{nom}` pour le joueur relevé.

À savoir : hors des donjons et des raids, le jeu interdit à un addon d'écrire en /dire tout seul. L'annonce part alors dans le canal du groupe.

## 10. Profils et partage

Onglet **Profils** :

- **Profils prêts à l'emploi** : Donjon, Raid, Compact, Grand et lisible. Un clic change la taille et la disposition ; vos clics sont conservés.
- **Donner sa configuration** : copiez le code affiché et envoyez-le à un ami, qui le colle dans « Recevoir une configuration ».
- **Envoi direct** : tapez le nom d'un joueur qui a Zenith. Il reçoit une demande et choisit d'accepter ou non.
- **Tout réinitialiser** : deux clics pour revenir aux réglages d'origine.

## 11. Entre joueurs qui ont Zenith

Zenith échange deux informations, de façon invisible, avec les autres joueurs du groupe qui l'utilisent : son numéro de version (pour vous prévenir une fois si une version plus récente existe) et les configurations que vous choisissez d'envoyer. Rien n'est jamais appliqué sans votre accord. Les deux se coupent dans l'onglet Profils, section « Entre joueurs ».

## 12. Retrouver un réglage

En haut à droite de la fenêtre d'options, tapez un mot (« mana », « tank », « thème »...) : Zenith vous emmène au bon réglage.

## 13. Un problème ?

Tapez `/zenith bug`. Répondez aux trois questions, cliquez sur « Tout sélectionner », copiez avec Ctrl+C, puis collez le rapport à l'adresse affichée dans la fenêtre. Pour un défaut d'affichage, joignez une capture d'écran.

Zenith ne vous dérange pas pour ses erreurs : au plus un message discret par session, que vous pouvez couper dans l'onglet Aide.

## Les commandes

| Commande | Effet |
|---|---|
| `/zenith` | Ouvrir les options |
| `/zenith test` | Mode test |
| `/zenith tuto` | Tutoriel en jeu |
| `/zenith verrou` | Verrouiller ou libérer la position |
| `/zenith reset` | Remettre les cadres au centre |
| `/zenith bug` | Signaler un problème |
| `/zenith nouveautes` | Voir les nouveautés de la version |
