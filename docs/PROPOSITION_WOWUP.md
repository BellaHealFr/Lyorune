# Lyorune et le Hub WowUp : état et propositions

Relevé du 27 novembre 2026, d'après les pages officielles de WowUp
(https://wowup.io/guide/wowup/hub et https://wowup.io/guide/get-addons/overview) et la release `v1.51.0`.
Ce fichier ne change rien : chaque proposition attend l'accord de l'auteur.

## Ce que demande le Hub

- Des releases GitHub (ou GitLab), chacune avec l'addon dans un zip.
- Dans le zip, le dossier de l'addon à la racine.
- Un seul `Addon.toc`, ou un fichier TOC par version du jeu (`Addon_Forever.toc` pour WoW Forever). Le Hub lit le
  TOC pour savoir quelles versions du jeu une release prend en charge.
- Facultatif : le `release.json` de l'outil d'empaquetage BigWigs, que le Hub lit pour savoir quel zip va avec quelle
  version du jeu.
- Pour une installation par l'adresse GitHub, WowUp cherche pour WoW Forever un zip dont le nom finit par `-forever`.
- Icône : l'image de prévisualisation sociale du dépôt. Captures : le dossier `.previews` de la branche étiquetée.
  Liens de soutien : `.github/FUNDING.yml`. Catégories : les topics du dépôt.
- La page ne décrit aucune inscription : le Hub « prend chaque nouvelle release ». Aucun minimum d'étoiles n'est
  indiqué.

## Vérification point par point

| Point | État | Détail |
|---|---|---|
| Release étiquetée avec un zip | conforme | `v1.51.0` : `Lyorune-v1.51.0-forever.zip`, fait par la publication automatique (`.github/workflows/publication.yml`, outil BigWigs) |
| Dossier à la racine du zip | conforme | un seul dossier `Lyorune/`, avec `Lyorune.toc` dedans, aucun fichier à côté |
| Nom de zip en `-forever` | conforme | `Lyorune-v1.51.0-forever.zip` |
| `release.json` | conforme | joint à la release : `"flavor": "forever"`, `"interface": 16001` |
| TOC | conforme | un seul `Lyorune.toc`, `## Interface: 16001`, titre, notes FR et EN, auteur, version 1.51.0 |
| Icône | conforme | `docs/images/apercu-github.png`, 1280 × 640, logo doré au centre sur fond étoilé : lisible en petit |
| Captures `.previews/` | conforme | voir plus bas |
| `.github/FUNDING.yml` | absent | facultatif, modèle plus bas |
| Topics | à compléter | `unit-frames` et `buffs-debuffs` déjà posés ; `combat` et les classes à ajouter (voir `docs/GITHUB_REGLAGES.md`) |
| Présence sur https://wowup.io/addons | inconnue | la recherche du site ne s'affiche pas sans navigateur : à vérifier à la main (voir `docs/WOWUP.md`) |

### Une seconde archive dans la release

La release `v1.51.0` contient aussi `Lyorune-1.51.0.zip`, sans suffixe, avec le même dossier `Lyorune/` à la racine.
Le Hub s'appuie sur `release.json`, qui ne cite que le zip `-forever`, et l'installation par adresse GitHub cherche le
suffixe `-forever` : cette seconde archive ne gêne pas WowUp. Elle peut seulement faire hésiter un joueur qui
télécharge à la main. Rien à changer pour WowUp.

## TOC : garder `Lyorune.toc` seul (conseillé)

Le Hub accepte un seul `Addon.toc`. Avec `Lyorune.toc` seul, la release `v1.51.0` est déjà reconnue comme une version
pour WoW Forever par `release.json`.

Ajouter ou renommer en `Lyorune_Forever.toc` :

- **Risque pour le jeu** : un client ne charge un TOC à suffixe que s'il reconnaît ce suffixe. Rien dans le dépôt ne
  vérifie que le client WoW Forever lit `_Forever`. Si ce n'est pas le cas et que `Lyorune.toc` disparaît, l'addon
  ne se charge plus. Si les deux fichiers existent, ils doivent rester identiques à chaque version (liste des
  fichiers, notes, version) : un oubli et le jeu charge l'un, WowUp lit l'autre.
- **Risque pour la publication** : la vérification de version de `publication.yml` lit `Lyorune.toc` ; `outils/publier.py`
  et `tests/run.py` le lisent aussi. Un second fichier demanderait de les adapter.
- **Gain** : aucun aujourd'hui, le Hub reconnaît déjà le jeu grâce à `release.json`.

Proposition : ne rien changer. À reconsidérer seulement si l'équipe de WowUp le demande.

## Captures `.previews/`

| Fichier | Taille | Poids |
|---|---|---|
| `1-banniere.jpg` | 1536 × 1024 | 555 Ko |
| `2-cases.jpg` | 1492 × 1054 | 375 Ko |
| `3-options.png` | 1059 × 696 | 341 Ko |

Formats courants, dimensions nettes, poids raisonnable. Le dossier est exclu de l'archive de l'addon (`.pkgmeta`).
Les nouvelles captures prévues (voir `docs/images/captures/LISEZMOI.md`) pourront y être copiées.

## Modèle de `.github/FUNDING.yml` (à créer seulement si vous le voulez)

Ne créez ce fichier que si vous avez une page de soutien. Remplacez le nom d'exemple par le vôtre et supprimez les
lignes inutiles. GitHub affiche alors un bouton « Sponsor », et le Hub WowUp montre le lien.

```yaml
# Liens de soutien de Lyorune (lus par GitHub et par le Hub WowUp).
# ko_fi: VOTRE_NOM_KO_FI          # page https://ko-fi.com/VOTRE_NOM_KO_FI
# patreon: VOTRE_NOM_PATREON      # page https://www.patreon.com/VOTRE_NOM_PATREON
# github: VOTRE_COMPTE_GITHUB     # GitHub Sponsors, s'il est activé sur le compte
# custom: ["https://exemple.org"] # toute autre adresse
```

## Ce que l'auteur doit faire à la main

1. Ajouter les topics de `docs/GITHUB_REGLAGES.md` (`combat`, `priest`, `paladin`, `shaman`, `druid`).
2. Vérifier la présence de Lyorune sur https://wowup.io/addons (filtre « WoW Forever ») et l'installation par
   adresse GitHub (`docs/WOWUP.md`).
3. Si Lyorune n'apparaît pas, poster le message de `docs/WOWUP.md` sur le Discord de WowUp.
4. Facultatif : créer `.github/FUNDING.yml` à partir du modèle.
