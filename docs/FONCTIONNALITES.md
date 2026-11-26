# Toutes les fonctionnalités de Lyorune

Le détail de tout ce que Lyorune fait pour vous. Le résumé est dans le [README](../README.md) ; pour apprendre à
tout régler pas à pas, voyez le [guide du joueur](TUTORIEL.md).

[English](FEATURES.en.md)

## Sommaire

- [Soigner d'un clic](#soigner-dun-clic)
- [Touches au survol](#touches-au-survol)
- [Tout voir d'un coup d'œil](#tout-voir-dun-coup-dœil)
- [Dissiper sans chercher](#dissiper-sans-chercher)
- [Relever sans changer de touche](#relever-sans-changer-de-touche)
- [À votre goût](#à-votre-goût)
- [Mode test](#mode-test)
- [Annonces](#annonces)
- [Profils et partage](#profils-et-partage)
- [Toujours sous la main](#toujours-sous-la-main)
- [Facile à régler](#facile-à-régler)
- [Les amis de Lyorune](#les-amis-de-lyorune)
- [Rien n'est obligatoire](#rien-nest-obligatoire)

## Soigner d'un clic

<img src="images/runes/s.png" alt="" width="40">

- Chaque bouton de souris, seul ou avec Maj, Ctrl, Alt, lance le sort de votre choix sur la case d'un joueur.
- Plus besoin de cibler : Alt + clic gauche cible quand même le joueur, Alt + clic droit ouvre son menu.
- Tous vos soins et buffs se choisissent, même sans cible (Feu intérieur, auras, totems), et `/lyorune sorts` dit
  pourquoi un sort manque.
- Chaque raccourci lance le rang le plus haut, ou, si vous l'allumez, le rang de votre choix (clic droit sur le sort :
  niveau et coût en mana de chaque rang), adapté au niveau du joueur soigné.

### Variantes

- Le « + » d'une ligne lui donne des variantes :
  - un autre sort sur un ennemi (case Cible ou Focalisation) ;
  - en champ de bataille ;
  - sur un tank (un gros rang sur lui, un rang économe ailleurs) ;
  - ou hors combat ;
- et aucun soin ne part sur un ennemi par erreur.

### Petits plus

- Un bijou peut partir avec le sort.
- Un autre clic arrête l'incantation.
- Un compteur montre quels clics vous servent vraiment.
- Lyorune vous prévient si le « clic pour lancer » du jeu prend la même combinaison.
- La touche de signal du jeu sur une case marque le joueur pour tout le groupe.
- Vos macros s'écrivent une fois dans Mes macros, puis se posent sur un clic ou se glissent dans une barre de sorts
  du jeu.

## Touches au survol

<img src="images/runes/t.png" alt="" width="40">

- Une touche du clavier, un bouton de souris supplémentaire ou la molette lance un sort sur la case survolée.

## Tout voir d'un coup d'œil

<img src="images/runes/u.png" alt="" width="40">

### Vie et protections

- Vie.
- Soins en route.
- Boucliers (en bande ou à la suite de la vie, avec au choix ce qui reste à absorber, même en combat).
- Absorption de soins.
- Vie basse (liseré rouge fixe, en combat).
- Joueurs en bonne santé estompés pour que les blessés ressortent.

### Mana

- Mana.
- Mana basse des autres soigneurs et leur boisson quand ils boivent.
- Quand votre mana baisse, un liseré bleu doux borde l'écran.
- Après un sort payé en mana, un trait sur votre case compte les 5 secondes avant que la mana reparte.

### Auras et état des joueurs

- Soins sur la durée et affaiblissements (dessinés par le jeu : visibles en plein combat, tous les rangs de vos
  sorts ; vos sorts externes comme Infusion de puissance et Innervation ; Âme affaiblie et Longanimité en gris au bout
  de vos soins, avec leurs secondes).
- Auras privées des boss.
- Gros défensifs des joueurs (Mur protecteur, Bouclier divin, Écorce...).
- Joueurs étourdis, apeurés ou métamorphosés.
- Invocation.
- Menace.
- Portée en trois paliers.
- Chef de groupe (jamais sur l'icône de rôle).
- Icônes de classe et des DPS au choix.

### Incantation et recharges

- Temps de recharge global et incantation (barre ou anneau au curseur).
- Vos sorts à recharge dans une rangée sous les cadres (balayage et secondes du jeu, même en combat).
- Vos totems de chaman avec leur temps.
- Et, dessous, les gros sorts de vos alliés qui ont Lyorune (Renaissance, Innervation, Imposition des mains...).
- Et un trait qui se vide sur la case du joueur qui reçoit votre soin canalisé (Pénitence).

### Buffs manquants

- Hors combat, un panneau lance tous vos buffs manquants (prêtre, paladin, chaman, druide : bénédictions, Feu
  intérieur, boucliers et arme du chaman, Bouclier de terre du tank, montré en temps réel avec ses charges et en gris
  dès qu'il tombe, même en combat), avec votre liste de buffs pour le JcE et une autre pour le JcJ.
- Et sur chaque case seulement vos buffs à reposer, en gris, la même rangée partout, hors combat, en combat, en donjon
  et en champ de bataille (un buff posé ne se montre pas ; il revient s'il manque ou finit bientôt, 75 secondes avant
  sa fin au départ).
- Hors combat, le prochain s'affiche sous vos cadres dans un bandeau fin, et un clic le pose.
- En combat et en champ de bataille, deux interrupteurs à part.
- En combat, une touche relance votre buff unique sur son porteur.

### Qui buffe qui

- Vos groupes à buffer en raid.
- La bénédiction de chaque type de joueur.
- Et les paladins ne reprennent jamais la bénédiction d'un autre (entente entre ceux qui ont Lyorune).
- Le chef peut aussi répartir les buffs.

## Dissiper sans chercher

<img src="images/runes/d.png" alt="" width="40">

- La case se colore quand vous pouvez retirer une magie, une malédiction, une maladie ou un poison.
- L'image du type (goutte de magie, crâne de malédiction...) s'y ajoute, et le liseré de chaque icône prend la
  couleur de son type.
- Jusqu'à 3 affaiblissements à dissiper par case, le plus important d'abord, avec leurs secondes restantes, même en
  combat.
- Les autres affaiblissements au choix :
  - tous ;
  - seulement les utiles (ceux que le jeu montre sur ses cadres de raid, sans Déserteur ni Épuisement) ;
  - ou aucun.
- Ceux de votre liste « À mettre en avant » toujours en tête (Maj-clic sur un sort pour l'y ajouter), et Lyorune vous
  dit s'il les reconnaît en combat.

## Relever sans changer de touche

<img src="images/runes/r.png" alt="" width="40">

- Sur un joueur mort, votre clic de soin lance votre résurrection. Personne ne reste au sol.
- Entre soigneurs : un trait doré marque les joueurs dont vous vous occupez, et le chef envoie la répartition à tous
  ceux qui ont Lyorune, avant le combat.

## À votre goût

<img src="images/runes/g.png" alt="" width="40">

- Cinq thèmes, contraste élevé, transparence, taille.
- Quatre formes de case aux icônes rangées à leur mesure.
- Icônes placées par défaut sans jamais se couvrir.
- Chaque élément de la case placé, agrandi, affiché ou masqué à votre idée (sa place profite alors aux autres).
- Placements propres à chaque personnage et copiables de l'un à l'autre.
- Rangement par groupe ou par rôle.
- Cadre séparé pour les tanks.
- Familiers en face de leur maître.
- Joueurs épinglés à part.
- Cases de la cible et de la focalisation.

## Mode test

<img src="images/runes/m.png" alt="" width="40">

- Un faux groupe de 5 à 40 joueurs pour tout régler tranquillement, sans déranger personne.

## Annonces

<img src="images/runes/a.png" alt="" width="40">

- Mana faible, mana remontée, résurrection, avec vos propres textes.
- Sur WoW Forever, où la mana est cachée aux addons, les annonces de mana faible et de mana remontée partent quand
  même toutes seules (seuil approché par le coût de vos sorts, remontée mesurée pendant que vous buvez).

## Profils et partage

<img src="images/runes/p.png" alt="" width="40">

- Un profil par taille de groupe, champ de bataille et spécialisation, appliqué tout seul.
- Copie d'une seule partie d'un profil à un autre.
- Envoyez votre configuration à un ami, par un code ou directement en jeu.

## Toujours sous la main

<img src="images/runes/b.png" alt="" width="40">

- Un bouton au bord de la mini-carte ouvre les options ou le mode test. Il se déplace, et se retire d'une case à
  cocher.
- Dans les raccourcis du jeu, des touches au choix ouvrent les options, masquent les cadres, posent le prochain buff
  manquant ou lancent le mode test.

## Facile à régler

<img src="images/runes/f.png" alt="" width="40">

- Une fenêtre d'options en douze chapitres, avec une case témoin qui montre chaque réglage en direct pendant que vous
  le changez.
- Une rune d'or marque ce que vous avez modifié (un clic le rétablit).
- Les réglages rares restent pliés.
- Une recherche retrouve n'importe quel réglage, jusque dans les explications.
- Une lumière de soin or et vert l'éclaire, et s'éteint d'une case à cocher.

## Les amis de Lyorune

<img src="images/runes/w.png" alt="" width="40">

Un chapitre à part :

- Lyorune en chiffres (mises à jour, téléchargements, Discord).
- Le canal des soigneurs en français et en anglais, pour échanger entre soigneurs sur vos façons de jouer et vos
  spécialisations (à rejoindre si vous le voulez).
- Votre carnet de soigneur (soins, résurrections et buffs réussis, par personnage, en tout et aujourd'hui, avec un
  bilan en sortant d'un donjon, gardé sur votre ordinateur).
- Un mot de l'auteur et un mur de remerciements.

## Rien n'est obligatoire

<img src="images/runes/n.png" alt="" width="40">

- Chaque élément a sa case à cocher : vous gardez seulement ce qui vous sert.

---

Lyorune ne modifie aucun cadre du jeu ni des autres addons : il fonctionne à côté d'ElvUI, de Clique ou de vos autres
addons d'interface.
