# Signaler un bug dans Lyorune

Vous avez vu quelque chose qui ne fonctionne pas, ou qui s'affiche mal ? Merci de le dire : c'est grâce à vos
signalements que Lyorune s'améliore. Cela prend environ trois minutes, et aucune connaissance technique n'est nécessaire.

[English version below](#reporting-a-bug-english).

## En résumé

1. En jeu, tapez `/lyorune bug` et répondez aux trois questions.
2. Copiez le rapport (bouton « Tout sélectionner », puis Ctrl+C).
3. Ouvrez le [formulaire de signalement](https://github.com/BellaHealFr/Lyorune/issues/new?template=bug.yml) et collez-le (Ctrl+V).

## Pas à pas

### 1. Préparer le rapport dans le jeu

Tapez `/lyorune bug` dans la fenêtre de discussion. Une fenêtre s'ouvre avec trois questions :

- **Que faisais-tu quand c'est arrivé ?** Par exemple : « en donjon à 5, en plein combat ».
- **Que s'est-il passé ?** Par exemple : « la case du tank est restée grise alors qu'il était vivant ».
- **Est-ce que ça se reproduit à chaque fois ?**

Sous vos réponses, Lyorune ajoute tout seul ce dont j'ai besoin : la version de l'addon et du jeu, votre classe,
votre niveau, la taille du groupe, et l'erreur technique s'il y en a une. Il n'y a rien de personnel dans ce rapport :
ni le nom de votre personnage, ni celui de votre compte.

Cliquez sur « Tout sélectionner », puis faites Ctrl+C.

### 2. Prendre une capture d'écran (pour un défaut d'affichage)

Si le problème se voit à l'écran (une case mal placée, une icône absente, un texte coupé), une image vaut mieux qu'une
longue explication. Appuyez sur la touche **Impr écran** en jeu : l'image est rangée dans le dossier
`World of Warcraft\_forever_\Screenshots`.

### 3. Envoyer le signalement

1. Ouvrez le [formulaire de signalement](https://github.com/BellaHealFr/Lyorune/issues/new?template=bug.yml).
2. GitHub demande de se connecter. Si vous n'avez pas de compte, cliquez sur « Create an account » : c'est gratuit,
   il suffit d'une adresse e-mail.
3. Dans la première case, collez le rapport avec Ctrl+V.
4. Remplissez les autres cases. Pour joindre une capture d'écran, faites glisser l'image dans la case « Captures d'écran ».
5. Cliquez sur le bouton vert en bas de la page pour envoyer.

### 4. Et ensuite ?

- Votre signalement reçoit l'étiquette **bug**. Je le lis et je vous réponds sur la même page.
- GitHub vous prévient par e-mail à chaque réponse.
- S'il manque une information pour reproduire le problème, l'étiquette **à confirmer** est ajoutée et une question vous est posée.
- Une fois le bug reproduit, il passe à **confirmé**, puis il est corrigé dans une version suivante. Le numéro de votre
  signalement est cité dans le journal des versions.

## Questions fréquentes

**La commande `/lyorune bug` ne répond pas.**
Lyorune n'a probablement pas pu se charger. Envoyez quand même le signalement : écrivez « commande indisponible » dans la
première case, et recopiez le message d'erreur affiché par le jeu s'il y en a un. Vérifiez aussi que le dossier s'appelle
bien `Interface\AddOns\Lyorune`.

**Je ne sais pas si c'est un bug ou un réglage.**
Regardez d'abord le [guide du joueur](TUTORIEL.md). Dans le doute, signalez-le : une question n'est jamais de trop.

**Quelqu'un a peut-être déjà signalé ce problème.**
Vous pouvez jeter un œil à la [liste des bugs ouverts](https://github.com/BellaHealFr/Lyorune/issues?q=is%3Aissue+is%3Aopen+label%3Abug).
Si vous le reconnaissez, ajoutez un commentaire avec votre rapport : chaque témoignage aide à le reproduire.

**J'ai une idée plutôt qu'un bug.**
Utilisez le [formulaire d'idée](https://github.com/BellaHealFr/Lyorune/issues/new?template=idee.yml).

**Je pense avoir trouvé une faille qui pourrait nuire à d'autres joueurs.**
Ne la publiez pas : suivez la procédure de [SECURITY.md](../SECURITY.md).

## Reporting a bug (English)

1. In game, type `/lyorune bug` and answer the three questions (answers in English are fine).
2. Click "Select all", then press Ctrl+C.
3. Open the [English bug form](https://github.com/BellaHealFr/Lyorune/issues/new?template=bug_en.yml) and paste the report with Ctrl+V.
4. For a display problem, drag a screenshot into the form (Print Screen key in game, saved in `World of Warcraft\_forever_\Screenshots`).

The report contains the addon and game versions, your class, level, group size and the technical error if there is one.
It contains neither your character name nor your account name. The full player guide in English is [GUIDE.en.md](GUIDE.en.md). You will get an answer on the same page, and GitHub
notifies you by e-mail.
