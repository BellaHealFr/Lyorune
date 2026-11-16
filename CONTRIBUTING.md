# Contribuer à Zenith

Merci de votre intérêt. Zenith est développé par BellaDroode ; les retours des joueurs et les corrections sont les bienvenus.

## Signaler un bug

1. En jeu, tapez `/zenith bug` et répondez aux trois questions.
2. Copiez le rapport (bouton « Tout sélectionner », puis Ctrl+C).
3. Ouvrez une [nouvelle demande](https://github.com/BellaDroode/Zenith/issues/new/choose) et collez-le.

Pour un défaut d'affichage, joignez une capture d'écran.

## Proposer une idée

Ouvrez une demande « Proposer une idée ». Décrivez d'abord la situation en jeu : c'est elle qui permet de trouver la bonne solution.

## Proposer une correction de code

Zenith est publié sous une licence « tous droits réservés » : le code peut être lu et corrigé à travers ce dépôt, mais pas redistribué modifié ailleurs (voir [LICENSE](LICENSE)). En proposant une modification, vous acceptez qu'elle soit publiée sous cette licence.

Avant de commencer un changement important, ouvrez une demande pour en discuter.

### Mise en place

```
pip install lupa
python tests/run.py .
```

Chaque ligne doit commencer par `OK`. Les tests font tourner le vrai code de l'addon dans un faux client, hors du jeu. Ils ne remplacent pas un essai en jeu.

### Règles du projet

- **Simple pour le joueur.** Un réglage se trouve à un seul endroit, avec un nom clair.
- **Rien n'est obligatoire.** Toute fonction visible a son interrupteur.
- **Léger.** Réagir aux événements du jeu, ne pas balayer en boucle. Ne mettre à jour que ce qui a changé.
- **Sûr en combat.** Ce que le jeu interdit en combat passe par `Z:Safe` et s'applique à la fin du combat.
- **Valeurs secrètes.** En combat, une valeur venue du jeu peut être secrète : la tester avec `Z.IsSecret` avant tout calcul ou comparaison.
- **Original.** Aucun code, texte, image ou structure repris d'un autre addon.
- **En français.** Commentaires et textes sont en français ; la clé de traduction est le texte français.

L'organisation des fichiers, l'ajout d'une classe, d'un thème ou d'un réglage sont décrits dans [docs/MAINTENANCE.md](docs/MAINTENANCE.md).

### Suivi

Les demandes sont classées par étiquettes et rattachées à un jalon, la version où elles seront livrées. Les versions suivent une numérotation sémantique et un journal classé en « Ajouté, Amélioré, Corrigé » : voir [docs/PUBLICATION.md](docs/PUBLICATION.md).

### Avant d'envoyer

- Ajoutez une étape de test dans `tests/run.py` pour ce que vous changez.
- Ajoutez les traductions dans `Locales/enUS.lua` (un test les réclame).
- Mettez à jour `docs/TUTORIEL.md` si le joueur voit une différence.
- Un message de commit court, en français, qui dit ce qui change pour le joueur, et cite la demande concernée (`Corrige #12`).
