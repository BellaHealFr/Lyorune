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
| 21 | 1.27.0 | Icônes à la mesure de chaque forme de case, taille réglable dans l'éditeur de placement | À faire |

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
- [ ] Lot 1 : maquette des 4 formes avec la place et la taille des icônes, validée par l'auteur avant de coder
- [ ] Lot 2 : place et taille d'origine des icônes écrites pour chaque forme dans `Z.shapes` (une forme ajoutée =
  une ligne) ; une rangée trop large rapetisse ses icônes pour tenir dans la case au lieu d'en déborder ; test des
  4 formes avec 1 à 6 soins et 2 à 5 affaiblissements, grand raid compris
- [ ] Lot 3 : taille de l'élément choisi dans l'éditeur de placement (molette ou « - » et « + », de 50 à 200 %),
  gardée par forme avec son décalage dans `Z.db.placement`, bornes dans `Z.limits`, partage de profil
  (`Share.lua`) ; en combat, une taille changée attend la sortie du combat (conteneurs d'auras du jeu reconstruits
  seulement hors combat) ; test
- [ ] Lot 4 : essai en jeu en groupe de 5 et en raid, en combat ; guide du joueur, une ligne dans une carte
  existante de la visite, anglais, `## Notes`, README, site, publication

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
- Conseil de rang de sort : en attente, tant qu'il n'est pas sûr que les rangs existent sur ce client.
- Demande d'Innervation ou d'Infusion de puissance : le jeu bloque les messages entre addons pendant un combat de
  boss, une clé mythique+ et le JcJ coté (vérifié le 17 novembre 2026).
