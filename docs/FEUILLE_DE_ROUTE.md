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
| 7 | 1.13.0 | Clics et raccourcis | À faire |
| 8 | 1.14.0 | Profils automatiques, cible et focalisation | À faire |
| 9 | 1.15.0 | Mode panneau, mode grille, tri | À faire |
| 10 | 1.16.0 | Confort | À faire |
| 11 | 1.17.0 | Synchronisation entre joueurs | À faire |
| 12 | 1.18.0 | Performances | À faire |
| 13 | 1.19.0 | Flèche de direction | Selon le test en jeu |

États possibles : **À faire**, **En cours**, **Prête, à publier**, **Publiée (vX.Y.Z)**, **Abandonnée** (avec la raison).

## Étape 0 : vérification en jeu (1.5.5)
- [ ] Les cases s'affichent, les clics et les macros fonctionnent, aucune erreur au journal (#3)

Si tout est bon, l'étape se ferme sans nouvelle version. Sinon, les corrections sortent en 1.5.5.

## Étape 1 : bibliothèque de macros, clics par spécialisation (1.6.0)
- [x] Bibliothèque « Mes macros » : macros nommées, réutilisables sur plusieurs clics, assistant, import depuis
  /macro, glisser-déposer, vérification pendant la saisie, visée automatique de la case (#23)
- [x] Clics et touches propres à chaque spécialisation, copie d'une spécialisation à l'autre (#21)

À vérifier en jeu : glisser d'une macro de la liste vers une case, changement de talents, longueur maximale d'une
macro sur une case (1023 caractères retenus).

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
- [ ] Écran unique « souris / clavier », combinaisons Ctrl+Maj, touches illimitées (#20)
- [ ] Alerte « nouveau sort de soin sans clic » (#22)

## Étape 8 : profils automatiques, cible et focalisation (1.14.0)
- [ ] Profils automatiques par taille de groupe et par spécialisation (#24)
- [ ] Cases cible, cible de la cible et focalisation (#25)

## Étape 9 : mode panneau, mode grille, tri (1.15.0)
- [ ] Un bloc par groupe, une grille, tri par classe et par nom (#26)

## Étape 10 : confort (1.16.0)
- [ ] Panneau des buffs manquants cliquable (#27)
- [ ] Assistant au premier lancement (#28)

## Étape 11 : synchronisation entre joueurs (1.17.0)
- [ ] Qui relève qui, joueurs du groupe qui ont Lyorune, sauvegarde avant import, limites, interrupteur (#29)

## Étape 12 : performances (1.18.0)
- [ ] Mode performance et commande de mesure avec un faux groupe de 5, 25 et 40 (#30)

## Étape 13 : flèche de direction (1.19.0)
- [ ] Flèche en extérieur seulement, selon les résultats de `/lyorune position` (#31)

Le jeu ne donne pas la position des autres joueurs en donjon ni en raid : là, l'indication « hors de portée » reste.

## Fin d'une étape
1. Tests hors jeu : `python tests/run.py .`, avec une étape de test pour chaque fonction nouvelle.
2. Guide des joueurs (`docs/TUTORIEL.md`, `docs/GUIDE.en.md`), visite guidée en jeu, traduction anglaise.
3. Cases cochées et état de l'étape mis à jour ci-dessus.
4. Publication : `python outils/publier.py X.Y.Z --nouveau "..." --en "..."`, avec le numéro de chaque demande
   (`(#12)`) dans le texte du changement.
5. Essai en jeu : `outils\installer.bat`, puis `/reload`.
6. Commit, étiquette `vX.Y.Z`, envoi sur GitHub : la version est publiée avec son archive.
7. Demandes de l'étape fermées, jalon fermé.

## Déjà fait (jusqu'à la 1.5.4)
Résurrection en un clic, transparence avec préréglages, sorts lus dans le grimoire, rapports d'erreurs et
`/lyorune bug`, macros personnelles sur les clics, soins en route, bouclier, menace, rôle, marqueur, dissipation,
buffs manquants, appel « Prêt ? », résurrection en cours, alertes de mana, partage de profil, mode test.

## Écarté
- Alertes « si la vie passe sous X % » : la vie est une valeur secrète en combat.
- Conseiller de soins de zone et suivi des sorts lancés : indisponibles sur ce client.
- Bouton de monture, cadres aimantés, protection contre les déconnexions : peu de gain pour la complexité ajoutée.
- Conseil de rang de sort : en attente, tant qu'il n'est pas sûr que les rangs existent sur ce client.
