# Lyorune : feuille de route

Le cahier des charges de l'auteur (14 points, novembre 2026) confronté à ce que fait Lyorune 1.3.0.
Règles permanentes : aucun code, texte, image ni structure repris d'un autre addon ; chaque fonction
a son interrupteur ; le tutoriel des joueurs est mis à jour à chaque changement.

État : **Fait**, **Partiel** (une partie existe), **À faire**, **À décider** (choix de l'auteur attendu).

## 1. Résurrection en un clic : Fait, sauf « par qui »
- Fait : option « Le même clic relève un joueur mort » (onglet Clics), sans touche de modification.
  Une icône de résurrection s'affiche sur la case quand quelqu'un relève ce joueur.
- À faire : afficher qui relève (dépend du point 13).

## 2. Personnalisation de l'interface : Partiel
- Fait : largeur, hauteur, espacement, taille du texte, réduction automatique en grand raid.
- À faire : échelle générale ; position de chaque élément (soins sur la durée, affaiblissements, rôle,
  marqueur, texte, nom) au pixel près, avec un éditeur visuel sur une case d'exemple.

## 3. Affichage des soins sur la durée : Partiel
- Fait : icônes avec cercle qui se vide, ou barres fines ; nombre de charges affiché à partir de 2.
- À faire : choix entre décompte chiffré, cercle, icône qui s'efface, charges ; combinaisons possibles.

## 4. Transparence : Fait
- Corrigé en 1.2.0 : Lyorune estompait la case du joueur lui-même comme s'il était hors de portée.
- Fait : opacité des cadres, opacité hors de portée, luminosité des barres, et depuis la 1.3.0 trois
  préréglages en un clic (discret, semi-transparent, bien visible).

## 5. Macros : Fait en 1.5.0, à essayer en jeu
- Dans le choix d'un clic ou d'une touche au survol, le bouton « Macro... » ouvre un éditeur : trois modèles prêts
  (bijou puis soin, interrompre puis soigner, annonce puis soin) et une saisie libre. `{cible}` désigne la case cliquée.
- Une macro n'est jamais exportée ni importée (un code reçu ne peut pas faire lancer une commande).
- À faire : une liste de macros nommées, réutilisables sur plusieurs clics, si l'auteur le souhaite.

## 6. Boutons et raccourcis : Partiel
- Fait : 5 boutons de souris × 4 modificateurs ; 8 touches au survol qui acceptent le clavier,
  les boutons supplémentaires des souris MMO (6 à 31) et la molette.
- À faire : nombre de touches illimité, combinaisons de modificateurs (Ctrl+Maj), présentation unique
  « souris / clavier » avec ajout ligne par ligne.

## 7. Icônes cliquables : Conservé
- Le choix d'un sort se fait en cliquant sur son icône. À confirmer : est-ce bien de cette fonction qu'il s'agit ?

## 8. Adaptation au niveau : Fait
- Lyorune lit le grimoire réel : seuls les sorts connus sont proposés, et la liste se met à jour quand un sort est appris.
- À faire : signaler discrètement un nouveau sort de soin qui n'a pas encore de clic.

## 9. Stabilité en cours de jeu : Partiel
- Fait par construction : les cases sont créées et rangées par le jeu lui-même, même en combat ; arrivées, départs,
  déconnexions (mention « Déco »), mort, résurrection, portée, passage groupe/raid ; changements interdits en combat
  remis à la fin du combat.
- Fait en 1.3.0 : changement de spécialisation ou de talents (Lyorune relit les sorts et repose les clics sans /reload),
  tests automatiques : départ, arrivée, passage en raid, déconnexion et reconnexion, départ en plein combat.
- Fait en 1.4.2 : l'affichage des cadres est confié au jeu (règle de visibilité), donc fiable en plein combat ;
  réglage « Afficher les cadres » (toujours, ou en combat seulement) ; `/lyorune diag` décrit l'état de chaque cadre.
- À faire : clics différents par spécialisation ; tests des échanges de sous-groupes et du raid réorganisé d'un coup.

## 10. Rapports d'erreurs : Fait
- Fait : capture des seules erreurs de Lyorune, regroupement des doublons avec compteur, 30 entrées au plus,
  contexte (versions, classe, combat, groupe, zone), une seule notification par session, `/lyorune erreurs`.
- Fait en 1.3.0 : `/lyorune bug` avec formulaire en trois questions et rapport compact, spécialisation et niveau dans
  chaque entrée, première erreur de la session mise en tête, option pour couper la notification, rappel de capture
  d'écran quand il n'y a pas d'erreur technique, lien vers la page GitHub du projet.
- Avis : pas d'envoi des rapports par message d'addon (il faudrait que l'auteur soit en ligne, dans le même groupe).

## 11. Taille du groupe : Partiel
- Fait : rangement par groupe ou par rôle (6 ordres), colonnes ou lignes, réduction automatique.
- À faire : mode panneau (un bloc par groupe) et mode grille, réglages par taille (5, 10, 15, 25, 40) appliqués
  automatiquement, tri par classe et par nom, regroupement des mises à jour en rafale.
- Limite technique : le jeu resserre lui-même les cases d'un groupe quand un joueur part. Des emplacements
  strictement fixes ne sont pas possibles en combat. Réalisable : chaque groupe garde sa colonne (mode panneau).

## 12. Flèche de direction : À décider après un test en jeu
- Constat : sur ce client, la position des autres joueurs n'est pas disponible en donjon ni en raid
  (VuhDo coupe lui-même sa flèche en instance). En extérieur, à vérifier, surtout en combat.
- Proposition : flèche en extérieur seulement ; en instance, l'indication « hors de portée » actuelle.
  La cible « joueur hors de portée le plus bas en vie » n'est pas réalisable en combat (vie secrète).
- Première étape, faite en 1.3.0 : `/lyorune position` affiche ce que le jeu fournit et le garde dans les données
  sauvegardées. À lancer en groupe : en extérieur, en donjon, puis en combat. La décision suit ces résultats.

## 13. Synchronisation entre joueurs : Partiel
- Fait : annonce de version (une notification par session, désactivable), envoi direct d'un profil avec accord
  du destinataire, messages inconnus ignorés.
- À faire : qui relève qui, liste des utilisateurs de Lyorune du groupe, sauvegarde avant import avec retour arrière,
  limite de messages acceptés par joueur, interrupteur général.
- Constat technique : canaux groupe, raid, instance, chuchotement, guilde ; 255 caractères par message ; débit
  limité par le jeu ; ce client bloque les messages d'addon pendant certains combats (rencontres de boss).

## 14. Performances et originalité : Partiel
- Fait : événements par joueur, une mise à jour d'auras par image, aucun balayage périodique sauf la portée.
- À faire : mode performance, commande de mesure (mémoire et processeur de Lyorune et des autres addons de soin,
  avec un faux groupe de 5, 25 et 40), tableau de résultats.

## Hors cahier des charges : fait en 1.4.0
- Nouveau nom : Lyorune (un autre addon s'appelait déjà Zenith). Commandes `/lyorune` et `/lyo`.
- Logo tiré du visuel de l'auteur : icône de l'addon et bouton de la mini-carte (déplaçable, désactivable).
- Inscription runique animée au bas de la fenêtre d'options, traduite au survol, désactivable.
- À faire : accorder les couleurs de l'interface (vert actuel) à l'or et au bleu du logo, si l'auteur le souhaite.

## Ordre de travail
1. Points 4, 9, 10 : faits en 1.3.0.
2. Points 2 et 3 : éditeur de placement et affichage des soins sur la durée.
3. Points 5 et 6 : macros et raccourcis.
4. Point 11 : panneau, grille, réglages par taille.
5. Points 13 et 14 : synchronisation, mesures.
6. Point 12 : selon le résultat du diagnostic.
