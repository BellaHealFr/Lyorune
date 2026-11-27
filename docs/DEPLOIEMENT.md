# Publier le site de présentation

Le site de Lyorune se fabrique à partir d'une seule source, `site/src`, pour deux hébergements :

| Cible | Adresse | Dossier produit |
|---|---|---|
| GitHub Pages | https://bellahealfr.github.io/Lyorune/ | `dist-github/` |
| Cloudflare | la racine de votre domaine | `dist-cloudflare/` |

Les deux sorties ont le même contenu. Elles ne diffèrent que par l'adresse, le compteur de visites et les fichiers
propres à chaque hébergeur (`.nojekyll` pour GitHub, `_headers` pour Cloudflare). Les dossiers `dist-*` ne sont
jamais envoyés sur GitHub : ils se fabriquent à la demande.

## Ce qui se change où

| Pour changer... | Fichier |
|---|---|
| un texte, en français ou en anglais | `site/src/textes/fr.json` et `site/src/textes/en.json` (les mêmes clés dans les deux) |
| la mise en page de la page | `site/src/page.html` (gabarit) et `outils/site.py` (les sections) |
| les couleurs, les polices | `site/src/style.css` |
| la démo, les animations | `site/src/site.js` |
| les codes de la galerie de profils | `site/src/profils.json` (le banc de test les importe comme en jeu) |
| les images de partage (1200 sur 630) | `site/src/images/partage-fr.png` et `partage-en.png`, à remplacer par n'importe quelle image de même nom et de même taille, ou à redessiner avec `python outils/images_partage.py` |
| la vidéo du jeu | déposez `site/src/medias/jeu.mp4` (15 à 20 secondes) : elle remplace toute seule la capture de la section « En jeu » |

Ce qui suit l'addon tout seul, sans rien recopier : la version (`Lyorune.toc`), les couleurs des thèmes de la démo
(`Themes.lua`), les trois dernières versions (`CHANGELOG.md`, `CHANGELOG.en.md`) et les images de `docs/images`.

## Essayer en local

```
python outils/site.py github
python outils/site.py cloudflare
python tests/site.py
```

Puis, pour regarder chaque cible dans le navigateur :

```
cd dist-github
python -m http.server 8000
```

Ouvrez http://localhost:8000/ (français) et http://localhost:8000/en/ (anglais). Même chose dans `dist-cloudflare`
avec un autre port (8001). En local, les chemins de la cible GitHub se lisent depuis la racine du petit serveur :
c'est normal, les liens de la page sont relatifs et marchent aux deux adresses.

## Cible A : GitHub Pages (automatique)

Rien à faire : à chaque envoi sur `main` qui touche le site, le circuit **Site** (`.github/workflows/site.yml`) lance
`python outils/site.py github public` et publie le résultat. Pour le relancer à la main : onglet Actions, « Site »,
« Run workflow ».

À vérifier après une publication : la page française, la page anglaise, le lien de langue, la version affichée, une
copie de code de profil, la démo (un clic soigne).

## Cible B : Cloudflare (à faire par vous, une fois)

Le dossier `dist-cloudflare/` est un site statique standard : aucun produit précis de Cloudflare n'est supposé.
Leur interface change souvent ; les noms ci-dessous sont ceux de novembre 2026, cherchez l'équivalent s'ils ont
bougé.

### 1. Le domaine

1. Choisissez le domaine (par exemple `lyorune.fr`) et ajoutez-le à votre compte Cloudflare.
2. Dans `outils/site.py`, l'adresse provisoire `https://lyorune.example/` est remplacée par la variable
   `SITE_URL_CLOUDFLARE`. Donnez-la à la fabrication, avec la barre finale : `https://lyorune.fr/`.

### 2. Publier

**Façon simple (envoi direct)** : sur votre ordinateur,

```
set SITE_URL_CLOUDFLARE=https://lyorune.fr/
python outils/site.py cloudflare
```

puis, dans Cloudflare, créez un site statique (rubrique de publication de pages ou de « Workers et Pages ») en
envoyant le dossier `dist-cloudflare`. À refaire à chaque nouvelle version.

**Façon automatique (dépôt connecté)** : dans Cloudflare, connectez le dépôt GitHub `BellaHealFr/Lyorune`, branche
`main`, avec :

- commande de fabrication : `python outils/site.py cloudflare`
- dossier de sortie : `dist-cloudflare`
- variable d'environnement : `SITE_URL_CLOUDFLARE` = `https://lyorune.fr/`

Le site se republie alors tout seul à chaque envoi sur `main`.

### 3. Vérifier dans Cloudflare

- Le domaine pointe bien vers le site (page française à la racine, anglaise sous `/en/`).
- Les en-têtes du fichier `_headers` sont appliqués (sécurité, cache) : outils de développement du navigateur,
  onglet Réseau, en-têtes de la page.
- Une adresse inconnue affiche la page « Hors de portée » (`404.html`).
- HTTPS est forcé.

### 4. Compteur de visites (facultatif)

Le site GitHub compte ses visites avec GoatCounter (`lyorune`), sans cookie. Pour compter aussi Cloudflare à part,
créez un second compteur sur goatcounter.com et donnez son nom par la variable `GOATCOUNTER_CLOUDFLARE`. Sans elle,
la cible Cloudflare n'a aucun compteur.

## Les deux adresses et les moteurs de recherche

Deux sites identiques se feraient concurrence. Une seule adresse est donc **principale** (réglage `principale` dans
`CIBLES`, `outils/site.py`) : l'autre garde tout son contenu mais indique la principale comme adresse de référence
(balise canonical et `og:url`). Aujourd'hui, la principale est GitHub Pages : c'est la seule adresse qui existe.
Le jour où le domaine Cloudflare devient l'adresse à faire connaître, passez `principale` de l'une à l'autre et
republiez les deux.

## Ce qui reste à fournir

- Le domaine Cloudflare (étape 1).
- La vidéo ou le GIF du jeu, de 15 à 20 secondes (`site/src/medias/jeu.mp4`).
- Les captures des cinq thèmes, si vous voulez les montrer à côté de la démo.
