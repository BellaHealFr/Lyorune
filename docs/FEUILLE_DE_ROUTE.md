# Lyorune : feuille de route

Le plan de Lyorune, étape par étape. Chaque étape sort en une nouvelle version publiée sur GitHub.
Le suivi en ligne se fait par les [jalons](https://github.com/BellaHealFr/Lyorune/milestones) : un jalon par version,
une demande par fonction, fermée quand la fonction est publiée.

Règles permanentes : chaque fonction a son interrupteur ; chaque réglage existe une seule fois ; rien n'est repris
d'un autre addon ; le guide des joueurs et la traduction anglaise suivent chaque changement.

## Tableau de suivi

| Étape | Version | Contenu | État |
|---|---|---|---|
| 0 | 1.5.5 | Vérification en jeu des versions 1.4.2 à 1.5.4 | En cours |
| 1 | 1.6.0 | Bibliothèque de macros, clics par spécialisation | Publiée |
| 2 | 1.7.0 | Bases de l'interface | Publiée |
| 3 | 1.8.0 | Utile en donjon | Publiée |
| 3 bis | 1.8.1 | Échanges entre joueurs plus sûrs | Publiée (v1.8.1) |
| 4 | 1.9.0 | Forme des cases, angles, couleurs de classe | Publiée (v1.9.0) |
| 4 bis | 1.10.0 | Fenêtre d'options et tutoriel : 3 thèmes, runes animées | Publiée (v1.10.0) |
| 5 | 1.11.0 | Soins sur la durée et indicateurs | Publiée (v1.11.0) |
| 6 | 1.12.0 | Échelle, éditeur de placement | Publiée (v1.12.0) |
| 7 | 1.13.0 | Clics et raccourcis | Publiée (v1.13.0) |
| 8 | 1.14.0 | Profils automatiques, cible et focalisation | Publiée (v1.14.0) |
| 9 | 1.15.0 | Mode panneau, mode grille, tri | Publiée (v1.15.0) |
| 10 | 1.16.0 | Confort | Publiée (v1.16.0) |
| 11 | 1.17.0 | Synchronisation entre joueurs | Publiée (v1.17.0) |
| 12 | 1.18.0 | Performances | Publiée (v1.18.0) |
| 13 | 1.19.0 | Distance en trois paliers, soin refusé hors de vue (la flèche est abandonnée) | Publiée (v1.19.0) |
| 14 | 1.20.0 | Joueurs épinglés, signal sur une case, chef et assistants | Publiée (v1.20.0) |
| 15 | 1.21.0 | Clics plus sûrs : clics du jeu en conflit, bijou et arrêt d'incantation | Publiée (v1.21.0) |
| 16 | 1.22.0 | Buffs à poser sur une seule personne, temps de recharge global | Publiée (v1.22.0) |
| 17 | 1.23.0 | Profils : copie d'une partie, profils JcJ | Publiée (v1.23.0) |
| 18 | 1.24.0 | Demande d'Innervation ou d'Infusion de puissance | Abandonnée (le jeu bloque les messages entre addons pendant un combat de boss) |
| 19 | 1.23.x | Revue complète du code, par lots ; une version corrective par lot qui corrige un bug | Publiée (v1.23.8) |
| 20 | 1.26.0 | Nouvelle fenêtre d'options : chapitres, case témoin, réglages changés, lumière de soin | Publiée (v1.26.0) |
| 21 | 1.27.0 | Icônes à la mesure de chaque forme de case, taille réglable dans l'éditeur de placement | Publiée (v1.27.0) |
| 22 | 1.28.0 | Défensifs et contrôles sur les cases, raccourcis du jeu (le rang adapté, déjà fait par le jeu, est abandonné) | Publiée (v1.28.0) |
| 23 | 1.29.0 | Trois affaiblissements à dissiper, mes sorts externes, joueur qui boit, mana basse au bord de l'écran, règle des 5 secondes | Publiée (v1.29.0) |
| 23 bis | 1.30.0 | Animation du logo au choix ; règle des 5 secondes éteinte au départ, trait au-dessus de la barre de mana, pêche corrigée | Publiée (v1.30.0) |
| 24 | 1.31.0 | Joueurs en bonne santé estompés, statistiques de mes clics | À faire |
| 25 | 1.32.0 | Répartition entre soigneurs, marquée sur les cases | À faire |

États possibles : **À faire**, **En cours**, **Prête, à publier**, **Publiée (vX.Y.Z)**, **Abandonnée** (avec la raison).

## Étape 0 : vérification en jeu (1.5.5)
- [ ] Les cases s'affichent, les clics et les macros fonctionnent, aucune erreur au journal (#3)

Si tout est bon, l'étape se ferme sans nouvelle version. Sinon, les corrections sortent en 1.5.5.

## Étape 1 : bibliothèque de macros, clics par spécialisation (1.6.0)
- [x] Bibliothèque « Mes macros » : macros nommées, réutilisables sur plusieurs clics, assistant, import depuis
  /macro, glisser-déposer, vérification pendant la saisie, visée automatique de la case (#23)
- [x] Clics et touches propres à chaque spécialisation, copie d'une spécialisation à l'autre (#21)

À vérifier en jeu : glisser d'une macro de la liste vers une case, changement de talents, longueur maximale d'une
macro sur une case (1023 caractères retenus ; 255 depuis la 1.26.0, limite du jeu depuis son patch 11.0.2).

## Étape 2 : bases de l'interface (1.7.0)
- [x] Le cadre de dissipation ne cache plus le nom ni la vie (#4)
- [x] Position des cadres gardée par personnage ; un personnage neuf part de la position par défaut (#5)
- [x] Numéro de groupe au-dessus de chaque colonne, ou le rôle en rangement par rôle (#6)
- [x] Verrou au choix : libre, verrouillé, ou déplaçable en maintenant Alt, Ctrl ou Maj (#7)
- [x] Barre de mana affichée par défaut, de la largeur de la barre de vie, hauteur réglable (#8)
- [x] Bouton de la mini-carte à la taille des autres boutons (signalé en cours d'étape)

À vérifier en jeu : un cadre par groupe en raid (filtres du jeu), étiquettes, Alt/Ctrl/Maj, position par personnage.

## Étape 3 : utile en donjon (1.8.0)
- [x] Auras privées des boss sur les cases (#9)
- [x] Absorption de soins sur la barre de vie (#10)
- [x] Icônes d'invocation et d'autre phase (#11)
- [x] Infobulle des clics au survol d'une case (#12)
- [x] Sons et lueurs par affaiblissement (#13) : contour pour la liste « À mettre en avant » et les affaiblissements
  de boss (même en combat, le jeu décide) ; son pour ceux de la liste, seulement quand le jeu laisse lire le nom.

À vérifier en jeu : place et taille des auras privées, bande d'absorption de soins, icônes d'invocation et de phase,
contour et son en donjon.

## Étape 3 bis : échanges entre joueurs plus sûrs (1.8.1)
- [x] Configurations reçues : contrôle renforcé et accord plus clair (#34)
- [x] Avis de nouvelle version plus fiable (#35)
- [x] Rapport de bogue sans informations personnelles (#36)
- [x] Macros de barres : ne jamais toucher une macro du joueur (#37)
- [x] Contrôles de sécurité avant chaque publication (#38)

## Étape 4 : forme des cases, angles, couleurs de classe (1.9.0)
- [x] Barre, Tuile, Carré, Bandeau, avec vignettes de démonstration et bouton « Voir en vrai » (#14)
- [x] Angles droits ou arrondis (#15), fond et bordure par groupe
- [x] Couleurs de classe plus vives, intensité au choix (#32)
- Animation des runes (#33) : reportée à l'étape 4 bis.

## Étape 4 bis : fenêtre d'options et tutoriel, 3 thèmes et runes animées (1.10.0)
Prioritaire. Seules la fenêtre d'options, la visite guidée et les petites fenêtres de Lyorune changent : les cases
de soin et leurs 5 habillages restent tels quels.
- [x] 3 thèmes de fenêtre au choix : Moderne (par défaut), Classique, MMORPG (pierre sombre et or), changés en
  direct, contraste du texte vérifié pour chacun, mode contraste élevé conservé (#39)
- [x] Couleurs de l'interface accordées à l'or et au bleu du logo (#19)
- [x] Inscription runique : même phrase, runes qui s'écrivent à l'ouverture, lueur et halo, respiration au repos,
  vague au survol avant la traduction, couleurs selon le thème (#33)
- [x] Animations douces de la fenêtre (ouverture, onglets, survol) et du tutoriel (étapes qui glissent, une rune
  par étape, élément présenté entouré de runes) ; séparateurs runiques et logo dans l'en-tête (#39)
- [x] Réglage « Animations réduites » : fondus courts seulement, runes fixes (#39)
- [x] Effets magiques (interrupteur) : cercle runique derrière le logo, particules de l'en-tête, étincelle de soin, couleur du thème, au plus 3 éclairs par seconde (#39)
- [x] Après l'essai en jeu : barre de mana bleue (elle restait blanche) et sa couleur au choix, bord des cases à
  cocher complet à toute échelle

## Étape 5 : soins sur la durée et indicateurs (1.11.0)
- [x] À corriger en premier : le texte de vie (%) s'affiche par-dessus la barre de mana ; il doit rester dans la
  barre de vie (demande de l'auteur, 17 novembre 2026)
- [x] Barre de mana au choix : barre simple (comme aujourd'hui) ou barre avec le pourcentage de mana affiché
  (demande de l'auteur, 17 novembre 2026, #40)
- [x] Décompte chiffré, cercle, icône qui s'efface, charges, et combinaisons (#16)
- [x] Indicateurs libres dans les coins de la case, barres fines (#17) : carrés par sort et par classe, reconnus en
  combat ; barre fine de menace (le bouclier avait déjà sa bande) ; nouvel onglet « Soins »

## Étape 6 : échelle, éditeur de placement (1.12.0)
- [x] Échelle générale et placement au pixel près sur une case d'exemple (#18) : échelle de 50 à 200 %, éditeur
  (glisser, flèches, Maj : 5 pixels), dix éléments, placements gardés par forme et partagés avec le code
- Couleurs de l'interface (#19) : passées à l'étape 4 bis.

## Étape 7 : clics et raccourcis (1.13.0)
- [x] Écran unique « souris / clavier », combinaisons Ctrl+Maj, touches illimitées (#20)
- [x] Alerte « nouveau sort de soin sans clic » (#22)

## Étape 8 : profils automatiques, cible et focalisation (1.14.0)
- [x] Profils automatiques par taille de groupe et par spécialisation (#24)
- [x] Cases cible, cible de la cible et focalisation (#25)

## Étape 9 : mode panneau, mode grille, tri (1.15.0)
- [x] Un bloc par groupe, une grille, tri par classe et par nom (#26)

## Étape 10 : confort (1.16.0)
- [x] Panneau des buffs manquants cliquable (#27)
- [x] Assistant au premier lancement (#28)

## Étape 11 : synchronisation entre joueurs (1.17.0)
- [x] Qui relève qui, joueurs du groupe qui ont Lyorune, sauvegarde avant import, limites, interrupteur (#29)

## Étape 12 : performances (1.18.0)
- [x] Mode performance et commande de mesure avec un faux groupe de 5, 25 et 40 (#30)

## Étape 13 : distance et vue (1.19.0)
- [x] Distance en trois paliers (à portée, proche, très loin avec empreintes) et œil quand un soin est refusé
  car le joueur est hors de vue (#31)

Flèche de direction abandonnée (décision de l'auteur, 17 novembre 2026) : le jeu ne donne pas la position des
autres joueurs en donjon ni en raid. Ces deux indices marchent partout, même en combat.

## Étapes 14 à 18 : idées retenues par l'auteur (17 novembre 2026)
Choisies après une comparaison avec VuhDo, HealBot et les addons de soin récents : on prend l'idée, jamais le code.
Les points marqués « à vérifier » se décident avec l'auteur avant tout codage.

## Étape 14 : joueurs épinglés, signal, chef de groupe (1.20.0)
- [x] Joueurs épinglés : un petit cadre de plus où l'on ajoute qui on veut par son nom (un 2e tank, un joueur à
  surveiller). Le menu du clic droit appartient au jeu (règle : ne jamais modifier un cadre du jeu) : on épingle
  donc depuis la case survolée (`/lyorune epingler`), la cible (« Épingler ma cible ») ou la liste de l'onglet Listes
- [x] Signal du jeu (ping) sur une case : marquer un joueur pour le groupe sans viser son personnage
- [x] Icônes de chef de groupe et d'assistant sur les cases
- [x] En plus (demande de l'auteur) : l'avis de nouvelle version donne la page de cette version, avec ses nouveautés

## Étape 15 : clics plus sûrs (1.21.0)
- [x] Avertir quand un raccourci du « clic pour lancer » du jeu prend la même combinaison qu'un clic de Lyorune
- [x] Bijou dans un clic (emplacement 13 ou 14 avant le sort) et clic « arrêter l'incantation » ; vérifié dans
  HealBot porté sur Forever (`/use 13` dans la macro de ses boutons sécurisés), à confirmer par un essai en combat

## Étape 16 : buffs uniques, temps de recharge global (1.22.0)
- [x] Buffs à ne poser que sur une personne (Bouclier de terre, Épines ; Guide de lumière n'existe pas sur Forever) :
  le panneau des buffs manquants propose le tank, ou le joueur choisi (`/lyorune porteur`) ; hors combat seulement,
  selon la classe jouée (`Data.lua`, `Z.uniqueBuffs`)
- [x] Temps de recharge global et incantation en cours : fine barre sous les cadres ou anneau autour du curseur,
  au choix (`Cast.lua`, coupé au départ)

## Étape 17 : profils (1.23.0)
- [x] Copier seulement une partie d'un profil vers un autre, avec un choix par partie : Cadres, Apparence,
  Indicateurs, Soins (les onglets dont un profil garde les réglages ; les clics n'en font pas partie). Bouton
  « Copier... » de l'onglet Profils
- [x] Profils automatiques en champ de bataille et en arène, en plus de la taille du groupe et de la spécialisation
  (tableau en 6 lignes et 2 colonnes ; sans choix, la règle de la taille du groupe s'applique)

## Étape 18 : demandes d'aide entre joueurs (1.24.0), abandonnée
- [x] Vérifié (17 novembre 2026) : pendant un combat de boss, une clé mythique+ et le JcJ coté, le jeu bloque les
  messages entre addons et les messages du chat écrits par un addon (`C_ChatInfo.InChatMessagingLockdown()`).
  La demande ne partirait pas au moment où elle sert. Décision de l'auteur : étape écartée.

## Étape 19 : revue complète du code (versions correctives 1.23.x)
Demande de l'auteur (17 novembre 2026) : relire tout l'addon (environ 11 500 lignes, 24 fichiers) sans survoler.
Méthode : une vérification automatique, puis une lecture ligne par ligne par lots de 800 lignes environ, tous avec
la même grille. Chaque erreur trouvée reçoit une étape de test dans `tests/run.py`. Un lot qui corrige au moins un
bug sort tout de suite en version corrective (1.23.1, 1.23.2...) envoyée sur GitHub ; un lot sans bug ne publie rien.
Deux ou trois lots par session au plus.

Grille de chaque lot :
- combat : valeurs secrètes (vie, auras), actions bloquées, boutons sécurisés ;
- valeurs vides : joueur absent, sort inconnu, réglage manquant ;
- événements et minuteurs : rien qui tourne sans fin (seule la portée, 2 fois par seconde) ;
- règles de l'addon : chaque réglage une seule fois, aucun cadre du jeu touché, ajout de classes possible ;
- textes : français et anglais présents et justes, aucun tiret cadratin.

- [x] Vérification automatique de tout l'addon : fonctions appelées mais absentes, réglages absents de
  `Z.defaults`, événements écoutés sans traitement, valeurs secrètes comparées, tirets cadratins. Gardée dans
  `tests/run.py` (étape « revue »). Bug trouvé : le mode test à 25 ou 40 ne réduisait pas les cases (1.23.1)
- [x] Lot 1 : Core, Log, Data. Bugs : une action en erreur à la fin du combat bloquait les suivantes ;
  « Vider le journal » laissait /lyorune bug signaler l'erreur effacée (1.23.2)
- [x] Lot 2 : Frames, 1re moitié. Bug : l'œil « hors de vue » restait sur une case donnée à un autre joueur (1.23.3)
- [x] Lot 3 : Frames, 2e moitié. Bug : un appel « Prêt ? » relancé dans les 5 secondes perdait ses réponses (1.23.3)
- [x] Lot 4 : Auras, Alerts. Bug : « Son quand ma mana est faible » restait muet sans annonce de mana cochée (1.23.4)
- [x] Lot 5 : Clicks. Aucun bug
- [x] Lot 6 : Macros. Bugs : « [:shift] » pendant la frappe faisait une erreur Lua ; la fenêtre d'import gardait
  « aucune macro » une fois des macros créées (1.23.5)
- [x] Lot 7 : Buffs, Cast, Preview. Bugs : un sort refusé pendant une incantation cachait la barre ou l'anneau ;
  couronne du chef absente du mode test et de la fenêtre de placement (chemin d'image abîmé) (1.23.5)
- [x] Lot 8 : Share, Comm. Bug : 80 résurrections réussies dont le joueur avait quitté le groupe remplissaient
  la liste « qui relève qui » pour toute la session (1.23.6)
- [x] Lot 9 : UI. Aucun bug
- [x] Lot 10 : Options, 1re moitié. Bug : la liste des coins de la case restait figée (sort ajouté dans l'onglet
  Listes absent, sort retiré affiché « Aucun » alors que le coin restait pris) (1.23.7)
- [x] Lot 11 : Options, 2e moitié. Bug : « Reprendre les clics proposés » en 2e spécialisation effaçait les clics
  de la 1re sans toucher ceux en cours (1.23.7)
- [x] Lot 12 : Placement, Perf, Bug, Minimap. Bug : après /lyorune mesure, le marqueur de raid ou la coche
  « Prêt ? » de mon personnage restait sur les cases du mode test (1.23.8)
- [x] Lot 13 : Runes, Wizard, Tutorial, Themes, Changes. Bugs : « Passer » dans l'assistant gardait la forme
  posée par la page des formes ; la visite guidée laissait les cadres déverrouillés (1.23.8)

Les boutons sécurisés ne sont pas simulés hors jeu : ce qui touche aux clics en combat reste à confirmer en jeu.

## Étape 20 : nouvelle fenêtre d'options (1.26.0)
Demande de l'auteur (20 novembre 2026) : une fenêtre d'options plus lisible et plus facile à régler, modernisée,
avec un côté magique qui rappelle le soin. Le fonctionnement de l'addon ne change pas, ni aucun réglage : seule leur
place change. La phrase en runes est gardée. Travail par lots, un lot par session, publié en une seule fois.
- [x] Barre latérale à 11 chapitres rangés par tâche (Accueil, Disposition, Apparence, Vie et portée, Mes soins,
  Affaiblissements, Joueurs, Sorts et raccourcis, Alertes, Profils et partage, Fenêtre et aide), une colonne qui défile
- [x] Réglages courants d'abord, « Réglages fins » repliables, réglages dépendants grisés, explication visible
  sous le nom quand il ne suffit pas
- [x] Case témoin qui suit chaque réglage en direct, avec le faux groupe et le mode test à côté
- [x] Rune d'or sur chaque réglage changé (un clic le rétablit), liste des réglages changés dans l'Accueil,
  « Rétablir cette page »
- [x] Recherche dans les noms et les explications, qui mène au réglage
- [x] Lumière de soin dans l'en-tête, rune du chapitre ouvert, étincelle sur la case témoin ; 3 thèmes, contraste
  élevé, « Effets magiques » et « Animations réduites » respectés
- [x] Tutoriel, visite guidée et traduction anglaise à jour

## Étape 21 : icônes à la mesure de chaque forme (1.27.0)
Demande de l'auteur (20 novembre 2026) : régler la taille des icônes, pas seulement leur place, et des icônes qui
s'adaptent à la forme de case choisie. Aujourd'hui, le nom, la vie et le rôle suivent la forme, mais les soins sur
la durée (en haut à gauche) et les affaiblissements (en bas à droite) gardent la même place dans les 4 formes, avec
une taille tirée de la seule hauteur de la case. Lu dans le code, à confirmer en jeu : en Barre et en Bandeau, ils
recouvrent le rôle, le nom et la vie ; en Carré, une rangée de 4 soins (72 pixels) dépasse de la case (54 pixels).
Décisions (carte blanche de l'auteur) : étape à part, après la 1.26.0 ; les auras privées gardent leur réglage de
taille en pixels (un seul réglage), l'éditeur de placement les déplace seulement et renvoie à ce réglage.
- [x] Lot 1 : maquette des 4 formes avec la place et la taille des icônes (décidé avec carte blanche de l'auteur,
  20 novembre 2026) : Tuile, icônes de 26 % de la hauteur, soins en haut à gauche jusqu'à l'icône de rôle,
  affaiblissements en bas à droite jusqu'au buff manquant ; Carré, pareil à 19 %, la rangée trop longue passe à la
  ligne (2 lignes au plus) ; Barre, soins et affaiblissements collés aux bords haut et bas de la barre de vie, côté
  droit, à une taille qui laisse libre la ligne du texte ; Bandeau, les deux rangées en bloc au bout de la case, le
  chiffre de vie rangé à leur gauche. Décalages des soins et affaiblissements (et du chiffre de vie en Bandeau)
  remis à zéro une fois en Barre, Bandeau et Carré
- [x] Lot 2 : place et taille d'origine des icônes écrites pour chaque forme dans `Z.shapes` (une forme ajoutée =
  une ligne) ; une rangée trop large rapetisse ses icônes pour tenir dans la case au lieu d'en déborder (Carré :
  passe d'abord à la ligne, `SetFlowLayoutMaximumLineSize`, repli « rapetisser » si le jeu refuse) ; place du
  chiffre de vie en Bandeau d'après les nombres réglés ; remise à zéro unique des décalages ; mêmes règles dans
  `Placement.lua` (bornes de l'éditeur) ; test des 4 formes avec 1 à 6 soins et 2 à 5 affaiblissements, grand
  raid compris. Fait le 21 novembre 2026 : un seul calcul, `Z.AuraRows` (Themes.lua), lu par Auras.lua,
  Containers.lua, Frames.lua et Placement.lua ; passage à la ligne du jeu détecté sur un premier conteneur
  (`Z.boxWrap`) ; remise à zéro à la première connexion en 1.27.0 (`Migrate`, Core.lua). Limite admise : en raid
  de 40, la Barre (21 pixels) garde des icônes de 5 pixels qui mordent d'un pixel sur la ligne du texte, restée
  devant elles
- [x] Lot 3 : taille de l'élément choisi dans l'éditeur de placement (molette ou « - » et « + », de 50 à 200 %),
  gardée par forme avec son décalage dans `Z.db.placement`, bornes dans `Z.limits`, partage de profil
  (`Share.lua`) ; en combat, une taille changée attend la sortie du combat (conteneurs d'auras du jeu reconstruits
  seulement hors combat) ; test. Fait le 21 novembre 2026 : entrée `{ x, y, taille }` (taille absente à 100 %),
  borne `Z.limits.placement.size` ; `Z.ElementSize` (jamais plus grand que la case) et `Z.ElementScale` lus par
  Frames.lua, Auras.lua, Containers.lua, Themes.lua (`Z.AuraRows`, chaque rangée a son facteur) et Placement.lua.
  Décidé (carte blanche) : seules les icônes ont une taille ici ; le nom et le texte de vie suivent « Taille du
  texte », les auras privées leur réglage, les barres fines gardent 3 pixels. « Remettre à sa place » rend aussi la
  taille. En Barre et Bandeau, les rangées agrandies s'arrêtent à la moitié de la barre de vie (elles ne se
  recouvrent pas). En combat, la case attend avec les rangées de ses boutons d'avant (`b.boxRows`). Code de
  partage `sX,Y,T`, sans T à 100 % (lisible par les anciennes versions). Guides fr et en à jour
- [x] Lot 4 : essai en jeu en groupe de 5 et en raid, en combat ; guide du joueur, une ligne dans une carte
  existante de la visite, anglais, `## Notes`, README, site, publication. Textes faits le 21 novembre 2026 : carte
  « Ce que disent les couleurs » (place selon la forme, « Placer les éléments de la case... » règle la taille),
  tableau « Lire une case » du guide fr et en, rubrique « À votre goût » du README et du site, `## Notes`. Restent
  l'essai en jeu par l'auteur et la publication. Essai de l'auteur : chiffres du décompte qui se chevauchaient en
  Bandeau (C9), corrigés ; puis « tout est ok ». Publiée le 21 novembre 2026

## Étapes 22 et 23 : idées retenues par l'auteur (21 novembre 2026)
Choisies après une comparaison avec les addons de soin portés sur WoW Forever : on prend l'idée, jamais le code.
Les points marqués « à vérifier » se décident avec l'auteur avant tout codage. Chaque fonction a son interrupteur.

## Étape 22 : rangs, défensifs, contrôles, raccourcis (1.28.0)
- [x] Lot 1 : vérifications techniques, décidées avec l'auteur avant tout codage. Rangs : règle du jeu entre le
  niveau d'un rang et celui de la cible, fonction qui donne le niveau d'apprentissage d'un rang, niveau d'un
  joueur lisible en combat ou non. Contrôles : filtre « CROWD_CONTROL » des conteneurs d'auras sur ce client.
  Défensifs : conteneur « HELPFUL » avec une liste de sorts, quel que soit le lanceur, visible en combat.
  Raccourcis : `Bindings.xml` et touche qui lance le panneau des buffs manquants (bouton sécurisé)
  - Vérifié dans le code du jeu de ce client (21 novembre 2026) : `C_Spell.GetSpellLevelLearned` existe et
    n'est pas secret, `UnitLevel` non plus ; un bouton sécurisé lance un rang précis quand l'attribut « spell »
    est un numéro (`CastSpellByID`) ; `Bindings.xml` se charge tout seul, et une touche `CLICK Bouton:LeftButton`
    clique un bouton sécurisé (forme déjà utilisée sur ce client). Le filtre « CROWD_CONTROL » et les listes de
    sorts sont lus par le jeu lui-même : seul un essai en jeu les confirme.
  - Règle des rangs (celle de Classic) : un sort qui pose une aura (buff, soin sur la durée, bouclier,
    bénédiction) échoue sur un joueur qui a plus de 10 niveaux de moins que le niveau d'apprentissage du rang.
    Les soins directs ne sont pas concernés. À confirmer pendant l'essai.
  - Les catégories toutes faites du jeu pour les défensifs laissent passer tous les buffs d'un joueur dans une
    autre zone : liste de sorts à nous, numéros de Forever trouvés par une recherche dans le jeu.
  - Décidé (carte blanche de l'auteur, 21 novembre 2026) : le rang adapté vaut aussi pour le panneau des buffs
    (rangs des buffs de groupe ajoutés à `Data.lua`) ; son interrupteur est activé au départ (il ne lance jamais
    plus fort que le rang choisi, il évite seulement l'échec) ; essai en jeu court avant les lots 2 et 3, avec un
    petit addon d'essai local jamais publié (`essais/LyoruneEssai`) : niveaux des rangs, règle des 10 niveaux,
    filtre des contrôles, listes de sorts sur un allié (affaiblissements et buffs), recherche des numéros des
    défensifs et des rangs des buffs. L'essai vérifie aussi la liste « À mettre en avant », déjà publiée : une
    liste de numéros ne trouverait pas les affaiblissements d'un allié (signalé dans HealKit).
  - Touche du prochain buff : poser `useOnKeyDown` sur les lignes du panneau (comme C11) et vider les lignes
    cachées, pour qu'une touche ne lance jamais un ancien buff. Afficher ou masquer les cadres : hors combat.
  - Résultat de l'essai en jeu (21 novembre 2026, druide niveau 22, build 1.60.1.71037) : le niveau
    d'apprentissage d'un rang suit celui de Classic (Récupération 4, 10, 16...) et reste lisible en combat, comme
    le niveau du joueur, de party1 et de la cible. Un conteneur « HELPFUL » avec une liste de numéros montre un
    buff posé par un autre joueur, sur moi comme sur party1 : la méthode des défensifs marche. Le filtre
    « HARMFUL|CROWD_CONTROL » est accepté sans erreur, mais aucun contrôle n'était actif pendant l'essai.
    Numéros des défensifs et des rangs des buffs de groupe trouvés (ceux de Classic, plus quelques doubles
    propres à Forever) ; absents du jeu : Cape d'ombre, Suppression de la douleur, Esprit gardien, Écorce de fer,
    Instincts de survie, Rage du chaman, Bénédiction de salut (1038, 25895). Pas encore vu : la règle des
    10 niveaux (aucun joueur de bas niveau ciblé ; l'essai ne retrouvait pas la cible, car sur Forever le nom reçu
    au lancement porte le nom de famille, corrigé) et un affaiblissement sur un allié pour la liste
    « À mettre en avant ». Complément d'essai court demandé à l'auteur.
  - Complément d'essai (21 novembre 2026, 12:15) : Marque du fauve lancée normalement (par son nom) sur des
    joueurs de niveau 1 à 17 : le jeu a lancé tout seul le rang 2 (appris au niveau 10) sur les niveaux 1 à 8 et
    le rang 3 (appris au niveau 20) sur les niveaux 13 et 17. **Le jeu baisse déjà le rang** selon la règle de
    Classic (niveau d'apprentissage moins 10). Le filtre « CROWD_CONTROL » montre bien Sonner ou Racines
    empoignantes sur un monstre (vu par l'auteur). Reste à voir pendant l'essai du lot 5 : un affaiblissement
    sur un allié dans la liste « À mettre en avant ».
  - Décidé (carte blanche, 21 novembre 2026) : le lot 2 est abandonné. Les clics de Lyorune (`Clicks.lua`) et
    le panneau des buffs (`Buffs.lua`) lancent les sorts par leur nom : le jeu choisit déjà le meilleur rang que
    le joueur peut recevoir. Une phrase du guide le dira aux joueurs. Les lots 3 et 4 restent prévus.
- [x] Lot 2 (abandonné : le jeu le fait déjà, voir le lot 1) : rang adapté au niveau du joueur soigné. Un clic sur un joueur de trop bas niveau lance le meilleur
  rang qu'il peut recevoir, jamais plus fort que le rang choisi ; calculé hors combat, case par case, à chaque
  changement de niveau ou de groupe ; en combat, la case garde le rang calculé (`Clicks.lua`, interrupteur)
- [x] Lot 3 : gros défensifs des autres joueurs sur la case (Mur protecteur, Bouclier divin, Bénédiction de
  protection, Écorce, Évasion, Bloc de glace...), liste par classe dans `Data.lua` (`Z.defensives`) ; joueurs
  étourdis, apeurés ou métamorphosés sur la case. Icônes dessinées par le jeu (`Containers.lua`), visibles en
  combat, placées dans l'éditeur de placement, chacune son interrupteur
  - Fait le 21 novembre 2026 (tests passés, installé, à essayer en jeu au lot 5). Décidé avec carte blanche :
    deux conteneurs de plus par case, « defensives » (filtre « HELPFUL », numéros de `Z.defensiveIds`, deux
    icônes au plus, `Z.DEFENSIVE_COUNT`) et « controls » (filtre « HARMFUL|CROWD_CONTROL », une icône) ;
    réglages `showDefensives` (chapitre Joueurs, Sur la case) et `showControls` (Affaiblissements, Importants),
    allumés au départ ; éléments « defensives » et « controls » dans l'éditeur de placement, taille réglable.
  - Places d'origine (`Z.AuraRows`, Themes.lua) : défensifs au milieu du bord droit en Tuile et Carré, sur la
    ligne du texte juste avant le chiffre de vie en Barre et Bandeau, à la taille des soins ; contrôle au centre
    de la case (de la barre de vie en Barre et Bandeau), 1,2 fois l'icône de rôle. Liseré bleu clair pour les
    défensifs, rouge pour le contrôle (`Z.DEFENSIVE_EDGE`, `Z.CONTROL_EDGE`, posés par `SetColorTexture` à la
    création du bouton). Un de mes sorts suivis qui est aussi un défensif (Bénédiction de protection) quitte la
    rangée de mes soins tant que les défensifs sont allumés : jamais montré deux fois.
  - Numéros vérifiés par leur nom dans le jeu (`Z:BuildData`), comme les rangs. Ancien affichage (client sans
    conteneurs), mode test (défensif sur la case témoin, contrôle sur un faux joueur sur onze) et case
    d'exemple de l'éditeur suivent. Guide fr et en et une ligne dans la carte « Ce que disent les couleurs »
    de la visite déjà faits.
  - À voir pendant l'essai en jeu : le liseré de couleur (`SetColorTexture` sur un bouton du jeu), un
    contrôle sur un allié (le filtre a été vu sur un monstre), un défensif d'un autre joueur en combat, la
    place en Barre et en Bandeau (le chiffre de vie ne doit pas être couvert).
- [x] Lot 4 : raccourcis du jeu (Options, Raccourcis, AddOns) : ouvrir Lyorune, afficher ou masquer les cadres,
  poser le prochain buff manquant (hors combat), mode test. Aucune touche posée au départ
  - Fait le 21 novembre 2026 (tests passés, installé, à essayer en jeu au lot 5). `Bindings.xml` (chargé tout
    seul par le jeu, absent du .toc : `publier.py` l'ajoute à l'archive, le paquet CurseForge le prend déjà),
    rubrique AddOns, en-tête « Lyorune ». Noms traduits dans `Z.bindingNames` (Core.lua), posés par
    `Z.NameBindings` à la fin de `Z:SetLanguage` ; actions par `Lyorune_Binding("OPTIONS" | "FRAMES" | "TEST")`.
  - Décidé (carte blanche) : cadres masqués par `Z.framesHidden` (règle de visibilité « hide », Frames.lua),
    hors combat seulement (le jeu interdit de changer la règle en combat), masqués même en combat, jamais
    sauvé (retour à la connexion ou après /reload) ; aussi `/lyorune cadres` (`frames`), ajouté à la liste
    des commandes. Prochain buff : bouton sécurisé caché `LyoruneNextBuff` (Buffs.lua, créé au chargement),
    copie de la première ligne du panneau, même panneau fermé par la croix ; vidé quand plus rien ne manque,
    panneau éteint, et à l'entrée en combat ; sens de la touche comme les cases (`useOnKeyDown`, C11) ; un mot
    dans le chat si on appuie en combat ou sans buff à poser. Phrase des raccourcis sous « Commandes » et dans
    la description du panneau des buffs ; guide fr et en (section « Les raccourcis du jeu »).
  - À voir pendant l'essai en jeu : la rubrique Lyorune dans les raccourcis (noms en français), une touche
    sur le prochain buff (bouton caché cliqué par le jeu), « lancer à l'appui » du jeu allumé puis éteint.
- [x] Lot 5 : tests, guide du joueur fr et en, une ligne dans une carte existante de la visite, `## Notes`,
  README, site, essai en jeu par l'auteur, publication
  - Fait le 21 novembre 2026 : tests passés (89 étapes), phrase des rangs dans le guide fr et en (section
    « Soigner d'un clic »), raccourcis du jeu ajoutés à la carte « C'est parti » de la visite (fr et en),
    `## Notes`, README fr et en, site (liste, carte « Tout voir », llms.txt), installé. Reste : essai en jeu
    par l'auteur (points des lots 3 et 4, et un affaiblissement d'un allié dans « À mettre en avant ») : « tout est ok »,
    description GitHub, publication, retrait de `essais/LyoruneEssai` de `Interface\AddOns`.

## Étape 23 : dissipation, sorts externes, mana (1.29.0)
Classées par intérêt pour les joueurs, puis par coût.

Découpage décidé le 21 novembre 2026, avec l'auteur pour les points techniques :
- Lot 0 (addon d'essai prêt et installé, recherche à lancer par l'auteur) : recherche des numéros dans le jeu par l'addon d'essai (`essais/LyoruneEssai`, `/lyessai recherche`) :
  Boisson, Infusion de puissance, Innervation, Âme affaiblie. Les numéros trouvés vont dans `Data.lua`,
  vérifiés par leur nom au chargement comme les défensifs.
- Lot 1 : jusqu'à 3 affaiblissements à dissiper. Décidé (carte blanche) : réglage `dispelCount` (1 à 3, 2 au
  départ), groupe « dispellable » de cette taille, tri « Default » du jeu (les affaiblissements prioritaires
  du jeu d'abord, vu dans `AuraUtil.DefaultAuraCompare`, branche `forever`) ; la rangée garde
  `debuffCount - 1` places pour les autres, elle s'allonge donc de `dispelCount - 1` ; en mode « Dissipables
  par moi », `dispelCount` places. Ancien affichage (lecture des auras), mode test et éditeur suivent.
  - Fait le 21 novembre 2026 (tests passés) : `Z.DispelCount()` et `Z.DebuffSlots()` (Themes.lua), réglage
    « Affaiblissements à dissiper » (chapitre Affaiblissements, Icônes), deux à dissiper sur la case témoin,
    guide fr et en. À voir en jeu : deux affaiblissements à dissiper sur un joueur, les deux montrés.
- Lot 2 : mes sorts externes (Infusion de puissance, Innervation) dans `Z.trackedSpells`, et Âme affaiblie :
  nouvelle liste `Z.lockouts` (Data.lua) des affaiblissements qui m'empêchent de relancer un de mes sorts,
  posés par n'importe qui (filtre « HARMFUL »), montrés dans la rangée de mes soins, assombris.
  - Fait le 21 novembre 2026 (tests passés, installé), avec les numéros connus (10060, 29166, 6788), vérifiés par
    leur nom au chargement : un numéro faux est écarté tout seul ; la recherche en jeu confirmera. Réglage
    `showLockouts` (allumé, chapitre Mes soins, Mes soins sur la durée). Décidé (carte blanche) : Âme affaiblie
    prend la DERNIÈRE place de la rangée (`Z.HotCount()` mes soins, `Z.HotSlots()` toutes les places, Themes.lua) ;
    une place en plus rétrécissait les icônes décidées (Bandeau 9 px, Tuile) et passait sous l'icône de rôle en
    Carré de raid de 40. Avec un seul soin réglé, elle s'ajoute après lui. Elle quitte la rangée des
    affaiblissements. Barre grise en style Barres. Ancien affichage, mode test, éditeur suivent. À voir en jeu :
    Âme affaiblie grise après un bouclier (le jeu garde-t-il l'icône grise ?), en combat aussi.
- Lot 3 : joueur qui boit. Décidé avec l'auteur : liste de numéros « Boisson » (`Z.drinkSpells`, Data.lua),
  conteneur du jeu (marche partout, même en donjon où le détail des auras peut être caché), à côté de la mana
  basse des soigneurs, sur les soigneurs seulement, interrupteur.
  - Fait le 21 novembre 2026 (tests passés, installé) : `Z.drinkSpells` (15 numéros de boisson connus, ceux dont
    le nom n'est pas « Boisson » sont écartés), septième conteneur « drink » collé à droite de la mana basse (même
    taille, même décalage de l'éditeur ; à gauche si elle est poussée au bord, `Z.DrinkPlace`), montré seulement
    si le joueur est soigneur (`b.drinkShown`, Frames.lua). Réglage `drinkHealers` (allumé, partie Mana). Ancien
    affichage et mode test suivent. Complété par la recherche en jeu du 21 novembre 2026 (18 numéros « Boisson » ; variante 456195 d'Innervation ajoutée à ses rangs). À voir
    en jeu : la boisson d'un soigneur qui boit, avec le temps qui reste.
- Lot 4 : liseré bleu doux au bord de l'écran quand ma mana baisse : cadre de Lyorune sur `UIParent`, jamais
  cliquable, texture de Lyorune (dégradé tga), opacité donnée par `UnitPowerPercent` et une courbe, interrupteur.
  - Fait le 21 novembre 2026 (tests passés, installé) : nouveau fichier `Mana.lua`, quatre bandes en dégradé de
    couleur unie (`SetGradient`, aucune image : plus simple qu'un tga), strate « BACKGROUND », jamais cliquable ;
    réglage `manaEdge` (Non, sous 10, 20, 30 ou 40 %, 20 au départ), chapitre Vie et portée, partie Mana ;
    jamais pour une classe sans mana (`Z.classPower`). Guide fr et en (section 10). À voir en jeu : le liseré
    sous 20 % de mana, en combat aussi, et qu'il ne gêne ni les fenêtres ni les clics.
- Lot 5 : règle des 5 secondes, confirmée en jeu par l'auteur. Décidé avec l'auteur : un trait fin sur la
  barre de mana de ma propre case, qui se vide en 5 secondes après un sort qui coûte de la mana.
  - Fait le 21 novembre 2026 (tests passés, installé) : `Mana.lua`, réglage `fiveSecondRule` (allumé au départ,
    même partie Mana) ; `UNIT_SPELLCAST_SUCCEEDED` du joueur, coût lu par `C_Spell.GetSpellPowerCost` (sort
    sans mana : rien ; numéro secret : compté comme payé). Le numéro de mes sorts est lisible en combat (journal
    de l'addon d'essai, étape 22). Trait de 2 pixels juste au-dessus de la barre de mana (1.29.1 ; en haut de la barre dans la 1.29.0) (au bas de la vie si la barre
    est cachée), vidé par une animation d'échelle du jeu, aucune boucle. Guide fr et en. À voir en jeu : le
    trait après un soin, rien après un tir de baguette, sa fin au moment où la mana repart.
- Lot 6 : tests, guide fr et en, visite, `## Notes`, README, site, essai en jeu, publication.
  - Fait le 21 novembre 2026 (tests passés, installé) : visite (carte « Une case par joueur » : une phrase de
    mana selon les réglages allumés et la classe ; carte des couleurs : l'icône grise d'Âme affaiblie), `## Notes`
    fr et en, README fr et en, site fr et en, `llms.txt`. Recherche en jeu faite (14 h 48), essai en jeu (« tout est ok »), publiée le 21 novembre 2026.
- [x] Jusqu'à 3 affaiblissements à dissiper par case, le plus important d'abord (aujourd'hui 1 seul : le
  deuxième reste caché tant que le premier est là). Nombre réglable (`Containers.lua`)
- [x] Mes sorts externes sur la case : Infusion de puissance, Innervation ; vérifier Âme affaiblie après un
  bouclier (`Data.lua`, `Z.trackedSpells`)
- [x] Joueur qui boit : un signe sur la case des soigneurs qui boivent, hors combat (auras lisibles), à côté de
  la mana basse des soigneurs
- [x] Mana basse au bord de l'écran : un liseré bleu doux quand ma mana baisse, par une courbe (mana cachée :
  aucune comparaison), texture de Lyorune seulement
- [x] Règle des 5 secondes : un trait sur ma case ou sur la barre d'incantation jusqu'au retour de la
  régénération (le moment est déjà calculé dans `Alerts.lua`)
- [x] Tests, guide fr et en, visite, `## Notes`, README, site, essai en jeu, publication
- Ajouté le 21 novembre 2026 (demande de l'auteur, cercle de runes jugé trop rapide et peu esthétique), pour la
  1.29.1 : réglage « Animation du logo » (`logoAnimation`, Fenêtre et aide), trois animations aux couleurs des
  classes de soin (classes de `Z.trackedSpells`, couleurs du jeu) dans `Logo.lua`, images de `outils/runes.py` :
  Aurore (par défaut : lueurs en trajectoire lente, reflet sous masque rond, étincelles), Sceau (anneau fixe,
  gemmes, traînée qui passe de l'une à l'autre, halo en fondu enchaîné), Souffle (onde qui s'élargit toutes les
  4 s), ou Aucune. Choix de l'auteur sur un aperçu animé : les trois, au choix du joueur. Bonnes pratiques
  suivies : boucles lentes, courbes douces, rien ne tourne sur lui-même, rien ne clignote, coupé par
  « Animations réduites ». Vu en jeu le 21 novembre 2026 (captures d'écran, 10 images par seconde) : une animation
  de rotation tournait bien plus vite que demandé sur ce client (traînée du sceau : plusieurs tours en 1 s au lieu
  d'un quart de tour ; c'était aussi la cause de l'ancien cercle de runes « trop rapide ») : plus aucune rotation,
  la traînée est une rangée de points fixes qui s'allument l'un après l'autre. Trajectoire de l'aurore en points
  reliés en ligne droite (la courbe lissée accélérait à chaque tour). Les trois vérifiées ensuite en jeu : traînée
  régulière, aurore sans à-coup, onde toutes les 4,0 s à vitesse égale. Attention pendant les essais : l'application
  CurseForge remplace le dossier de l'addon par la version publiée dès qu'elle est approuvée (vu à 16 h 13).

En réserve, après l'étape 23 : clics « Assister » et « Focaliser » ; clics différents en combat et hors
combat ; totems du chaman sur les cases ; cases estompées hors combat ; moi en premier ou en dernier dans mon
groupe ; infobulle des icônes d'auras ; préréglages « Épuré, Standard, Complet » ; texte « Vie » et « Vie et % » ;
priorité de dissipation ; icône de classe ; « Me montrer » dans les nouveautés ; bilan de la soirée ; vérifier en
jeu si « Incantation sur soi automatique » gêne les clics.

## Étapes 24 et 25 : idées retenues par l'auteur (21 novembre 2026)
Choisies après une recherche des demandes des joueurs (forums Blizzard, demandes de Cell, Grid2 et FrameSort,
feuille de route de HealKit et ses 98 idées de joueurs, pages de DandersFrames et des addons de Forever) : des idées
qu'aucun addon de cadres ne propose sous cette forme. On prend l'idée, jamais le code. Les points marqués
« à vérifier » se décident avec l'auteur avant tout codage. Chaque fonction a son interrupteur.

## Étape 24 : joueurs en bonne santé estompés, statistiques de mes clics (1.31.0)
- [ ] Joueurs en bonne santé estompés, **éteint au départ** (demande de l'auteur) : au-dessus d'un seuil de vie
  réglable (90 % au départ par exemple), la case devient plus transparente, ceux qui ont besoin de soins ressortent.
  Marche en combat : `UnitHealthPercent` avec une courbe, passée à `SetAlpha` (même méthode que le texte caché à
  pleine vie, `hideWhenFullCurve`, Frames.lua), aucune comparaison de la vie. Vérifié dans le code du jeu de ce
  client (branche `forever`, 21 novembre 2026) : `UnitHealthPercent` prend une courbe (`SecretWhenCurveSecret`).
  - À décider : la portée règle déjà l'opacité de toute la case (`b:SetAlpha`, Frames.lua) ; l'estompage se
    pose donc sur un cadre intérieur pour que les deux se multiplient (un joueur loin et en bonne santé reste
    lisible comme « loin »). Ne jamais estomper une case survolée, ni ma cible si elle est mise en avant.
  - Réglage dans le chapitre Vie et portée, un seul endroit ; case témoin et mode test suivent.
- [ ] Statistiques de mes clics, éteint au départ : chaque clic et chaque touche au survol qui part depuis une case
  est compté (bouton et touches Alt, Ctrl, Maj, par spécialisation). Dans la liste des clics, à côté de chaque
  ligne : nombre d'utilisations, ligne grisée si jamais utilisée, bouton « Remettre à zéro ».
  Rien de secret n'est lu : seulement le bouton et les touches au moment du clic (hook après le clic du bouton
  sécurisé, jamais avant : le sort part comme aujourd'hui). Compté par personnage dans les variables enregistrées.
  - À voir : compter les clics (simple, sûr) et non les sorts réussis ; le dire dans le guide.
- [ ] Tests, guide fr et en, visite (une ligne sur une carte existante), `## Notes`, README, site, essai en jeu,
  publication

## Étape 25 : répartition entre soigneurs (1.32.0)
- [ ] Lot 1, sans aucun message : je choisis les groupes ou les joueurs dont je m'occupe (fenêtre simple, par
  groupe de raid ou par tank). Leurs cases portent un repère discret « pour moi » ; option : estomper un peu les
  autres. Utile même si je suis le seul à avoir Lyorune.
- [ ] Lot 2, partage : le chef ou un assistant propose une répartition à tous les soigneurs qui ont Lyorune
  (Comm.lua, échanges de l'étape 3 bis). Chacun voit ses joueurs, et le nom du soigneur prévu au survol d'une case.
  - **À vérifier, à décider avec l'auteur avant tout codage (synchronisation)** : les messages entre addons sont
    bloqués pendant un combat de boss, une clé mythique+ et le JcJ coté (étape 18 abandonnée pour cette raison).
    La répartition se partage donc avant le combat, jamais pendant : envoi refusé et message clair si
    `C_ChatInfo.InChatMessagingLockdown()` est vrai (déjà testé dans Comm.lua), rien n'est attendu en combat. Une
    fois reçue, elle reste valable tout le combat sans aucun message. À essayer en jeu : qui peut proposer (chef,
    assistants), accepter ou refuser, ce qui se passe quand un soigneur quitte le groupe.
- [ ] Tests, guide fr et en, visite, `## Notes`, README, site, essai en jeu, publication

### Vérifié avant ajout : alerte de la chronologie des boss (21 novembre 2026), non retenue pour l'instant
Idée : avant une grosse technique de boss, les cases s'éclairent ou affichent « dans 5 s ».
- La chronologie existe sur ce client : `C_EncounterTimeline` et les modules `Blizzard_EncounterTimeline` et
  `Blizzard_EncounterWarnings` sont dans le code du jeu (branche `forever`). DBM installé l'utilise.
- Mais pour une technique de boss, tout ce qui dit de quoi il s'agit est secret (`SecretWhenEncounterEvent`) :
  nom, numéro du sort, icônes « soigneur », « tank », « mortel », gravité, couleur. Seuls le numéro de l'évènement,
  sa source, sa durée et le temps qui reste sont lisibles. Lyorune ne peut donc pas choisir « dégâts de groupe »
  lui-même ; il pourrait seulement faire dessiner par le jeu l'icône « soigneur » d'une technique sur une texture
  (`SetEventIconTextures`), à la façon des courbes.
- Le jeu ne dit pas sur qui tombe la technique : l'alerte serait la même pour toutes les cases, presque un double
  de la chronologie que le jeu affiche déjà.
- Inconnu le plus important : WoW Forever reprend des combats de l'époque Vanilla ; rien ne dit que le jeu leur
  donne une chronologie. À essayer en jeu avant d'en reparler : pendant un combat de boss,
  `/dump C_EncounterTimeline.IsFeatureAvailable()` puis `/dump C_EncounterTimeline.HasActiveEvents()`.
  Si les deux sont vrais, on en reparle ; sinon l'idée passe dans « Écarté ».

## Fin d'une étape
1. Tests hors jeu : `python tests/run.py .`, avec une étape de test pour chaque fonction nouvelle.
2. Guide des joueurs (`docs/TUTORIEL.md`, `docs/GUIDE.en.md`), visite guidée en jeu, traduction anglaise.
   Visite guidée courte : compléter une carte existante d'une ligne plutôt qu'ajouter une carte ; elle ne doit
   jamais devenir longue au point de lasser.
3. Description de ce que sait faire l'addon, tenue à jour : `## Notes` du `Lyorune.toc` (français et anglais),
   `README.md` et `README.en.md`, description du dépôt GitHub (`gh repo edit --description`).
4. Cases cochées et état de l'étape mis à jour ci-dessus.
5. Publication : `python outils/publier.py X.Y.Z --nouveau "..." --en "..."`, avec le numéro de chaque demande
   (`(#12)`) dans le texte du changement.
6. Essai en jeu : `outils\installer.bat`, puis `/reload`.
7. Commit, étiquette `vX.Y.Z`, envoi sur GitHub : la version est publiée avec son archive.
8. Demandes de l'étape fermées, jalon fermé.

## Déjà fait (jusqu'à la 1.5.4)
Résurrection en un clic, transparence avec préréglages, sorts lus dans le grimoire, rapports d'erreurs et
`/lyorune bug`, macros personnelles sur les clics, soins en route, bouclier, menace, rôle, marqueur, dissipation,
buffs manquants, appel « Prêt ? », résurrection en cours, alertes de mana, partage de profil, mode test.

## Écarté
- Alertes « si la vie passe sous X % » : la vie est une valeur secrète en combat.
- Conseiller de soins de zone et suivi des sorts lancés : indisponibles sur ce client.
- Bouton de monture, cadres aimantés, protection contre les déconnexions : peu de gain pour la complexité ajoutée.
- Conseil de rang de sort : les rangs existent bien sur ce client (reconnus depuis la 1.25.0) ; repris à
  l'étape 22 sous la forme du rang adapté au niveau du joueur soigné.
- Demande d'Innervation ou d'Infusion de puissance : le jeu bloque les messages entre addons pendant un combat de
  boss, une clé mythique+ et le JcJ coté (vérifié le 17 novembre 2026).
