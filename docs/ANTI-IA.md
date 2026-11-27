# Le site de Lyorune : ce qui fait « site généré », et comment on l'évite

Ce document sert de garde-fou pour le site de présentation (`site/`). Il liste les défauts que l'on reproche le plus
souvent aux sites et aux textes produits à la chaîne, et dit pour chacun ce que le site de Lyorune fait à la place.
Il se relit avant chaque changement du site.

## Sources consultées (27 novembre 2026)

Recherche web, résultats lus sous forme de résumés et d'extraits. Plusieurs articles sont réservés aux abonnés : leur
titre et leur résumé ont été lus, pas leur texte complet.

- Visuel : [925 Studios, « AI Slop Fonts and Gradients »](https://www.925studios.co/blog/ai-slop-design-tells),
  [DEV Community, « Why every AI built website looks the same »](https://dev.to/alanwest/why-every-ai-built-website-looks-the-same-blame-tailwinds-indigo-500-3h2p),
  [DEV Community, « How to fix the AI generated look in your frontend »](https://dev.to/alanwest/how-to-fix-the-ai-generated-look-in-your-frontend-1ahh),
  [Utsubo, « The Built with AI Tell: 12 Signals That Drop Trust in 2026 »](https://www.utsubo.com/blog/built-with-ai-trust-signals-2026),
  [Search Engine Journal, « 7 common AI website mistakes »](https://searchenginejournal.com/7-common-ai-website-mistakes-that-are-easy-to-avoid/574196/).
- Écriture en anglais : [TechCrunch, sur le guide de Wikipédia](https://techcrunch.com/2025/11/20/the-best-guide-to-spotting-ai-writing-comes-from-wikipedia/),
  [FlowingData, « Signs of AI writing on Wikipedia »](https://flowingdata.com/2025/10/20/signs-of-ai-writing-on-wikipedia/),
  [Rolling Stone, sur le tiret long](https://www.rollingstone.com/culture/culture-features/chatgpt-hypen-em-dash-ai-writing-1235314945/).
- Écriture en français : [Projet Celsius](https://projetcelsius.com/ia/analyses/a-quoi-reconnait-on-un-texte-ecrit-par-une-ia/),
  [Pangram (français)](https://www.pangram.com/fr/signs-of-ai-writing),
  [L'Éclaireur Fnac](https://leclaireur.fnac.com/article/545110-debusquer-lia-derriere-les-textes-que-vous-lisez/),
  [Fondation Mozilla](https://www.mozillafoundation.org/fr/nothing-personal/superficial-intelligence-ai-writing/).

**Ce qui n'a pas pu être vérifié** : le guide de Wikipédia lui-même n'a été lu qu'à travers deux articles qui le
résument ; aucune étude sérieuse sur les tournures propres au français n'a été trouvée (Projet Celsius le dit aussi) ;
les sites d'autres addons n'ont pas été étudiés ici, pour ne citer aucun autre addon.

Toutes les sources s'accordent sur un point : **aucun signe pris seul ne prouve rien**. C'est l'accumulation (dégradé
violet, police par défaut, trois cartes identiques, phrases creuses) qui trahit un site fait à la chaîne.

## Visuel

| Piège | Ce que fait le site de Lyorune |
|---|---|
| Dégradé indigo vers violet (valeurs par défaut des kits) | Palette tirée du logo et des runes : bleu nuit, or du logo, bleu des runes. Les seules autres couleurs sont celles du jeu : couleurs de classe, couleurs de dissipation (bleu magie, violet malédiction, brun maladie, vert poison, les mêmes que dans `Auras.lua`) et couleurs de rareté des objets. |
| Inter partout, ou police système | Cinzel pour les titres (déjà l'identité de Lyorune), Alegreya Sans pour le texte : une police humaniste aux formes calligraphiques, qui va avec l'univers des runes. |
| Hero centré, badge pilule « Nouveau » | Accueil asymétrique : le texte et le téléchargement à gauche, un vrai petit groupe de cases à droite. Aucun badge. |
| Trois cartes identiques avec un emoji | Pas de grille de cartes jumelles. Les quatre fonctions phares sont présentées comme des infobulles d'objet du jeu (nom en couleur de rareté, ligne « Utiliser : »), le reste en liste compacte avec les runes de Lyorune. Aucun emoji. |
| Verre dépoli et ombres partout | Cadres fins façon métal, une seule lueur dorée réservée au logo et au bouton de téléchargement. |
| Même animation d'apparition sur chaque bloc | Aucun bloc n'apparaît en glissant. Ce qui bouge a un sens : la démo (un combat), la couronne du logo, les effets des quatre classes, et une seule lueur qui parcourt l'inscription runique quand elle arrive à l'écran, comme en jeu. Tout s'arrête avec « réduire les animations ». |
| Mise en page symétrique du début à la fin | Ruptures de rythme : une démo pleine largeur, une case agrandie annotée, une liste serrée, une bande de runes. |
| Illustrations de banque d'images | Seulement les vraies images de Lyorune (logo, captures, runes, piliers) et des cases dessinées d'après le code des thèmes (`Themes.lua`). |

## Écriture (français et anglais)

| Piège | Ce que fait le site de Lyorune |
|---|---|
| Tiret long et demi-cadratin décoratif | Interdits partout ; un test les cherche dans tout le site produit. |
| Formules creuses (« Découvrez », « Plongez », « L'expérience ultime », « seamless », « elevate », « unleash », « dive into », « not just X, but Y ») | Liste noire vérifiée par le test du site, en français et en anglais. |
| Règle de trois par réflexe, gras partout | Les listes ont le nombre d'éléments qu'il faut. Gras rare. |
| Importance gonflée (« un tournant », « révolutionnaire ») | Aucun superlatif sans preuve : on dit ce que fait l'addon, avec les noms de sorts et les chiffres du code (jusqu'à 3 dissipations par case, 5 à 40 joueurs en mode test, portée revue deux fois par seconde). |
| Ton lisse et trop poli, rythme mécanique | La voix de l'auteur est gardée telle quelle (le tank qui tient par miracle, « Qui suis-je ? »). Phrases courtes et longues mêlées. |
| Calques de l'anglais en français, anglais traduit mot à mot | Chaque langue est écrite pour elle-même, avec les noms de sorts officiels de chaque langue (Rénovation et Renew, Récupération et Rejuvenation). |

## Contenu et technique

| Piège | Ce que fait le site de Lyorune |
|---|---|
| Faux avis, faux compteurs, faux logos de presse | Aucun. Les seuls chiffres sont réels : version et date (API GitHub, avec la version du dépôt en secours), visiteurs comptés par GoatCounter. |
| Texte d'exemple, liens « # », TODO visibles, alt « image » | Le test du site refuse « lorem », `href="#"`, « TODO » et les alt vides sur une image qui porte du sens. |
| Fonction inventée ou exagérée | Chaque fonction citée vient de `docs/FONCTIONNALITES.md`, du CHANGELOG ou du code. Les codes de profil de la galerie sont importés par le banc de test de l'addon : un code refusé fait échouer les tests. |
| Composants copiés-collés | Les blocs répétés (fonctions, classes, profils) sont produits par le script de génération à partir d'une seule liste, chacun avec son propre contenu. |
| Dépendances inutiles, suivi caché | Aucun framework, aucune bibliothèque. Le compteur de visites GoatCounter (sans cookie) est annoncé dans le pied de page. Aucun cookie. |
| Traduction faite par JavaScript | Chaque langue est une page HTML complète, produite à l'avance. |

## Audit final (27 novembre 2026)

Vérifié à chaque lancement par `tests/site.py`, sur les deux cibles : aucun tiret long, aucune formule de la liste
noire, aucun « lorem », aucun lien `#`, aucun TODO visible, aucun nom d'autre addon ; chaque image a son texte
alternatif et ses dimensions ; un seul titre principal par page ; liens internes, canonical, hreflang et données
structurées valides ; mêmes sections, dans le même ordre, en français et en anglais ; mêmes clés dans les deux
fichiers de textes. Les codes de la galerie sont importés par `tests/run.py` comme en jeu.

Relu à l'écran (bureau et téléphone, captures du navigateur) :

- **Trouvé et corrigé** :
  - la menace était décrite comme un contour : c'est d'abord un trait coloré en haut de la vie ;
  - la légende de la capture ne décrivait pas ce qu'elle montre ;
  - les sections perdaient leur marge verticale ;
  - sur téléphone, un long chemin de dossier élargissait la page ;
  - des styles écrits dans le HTML auraient été bloqués par la politique de sécurité de Cloudflare.
- **Laissé à l'appréciation de l'auteur** :
  - les images `banniere.jpg` et `cases.jpg` portent le logo de World of Warcraft. Elles sont gardées parce que la
    demande dit de conserver vos images, mais la règle « aucun asset Blizzard » voudrait qu'elles soient refaites sans
    ce logo. Elles ne servent plus que dans le kit presse ; la section « En jeu » montre `options.png` ;
  - les infobulles « Légendaire, Lié au compte » des quatre fonctions phares : un clin d'œil aux objets du jeu, à garder
    ou non ;
  - les noms du groupe de la démo : le premier groupe reprend ceux de vos captures (Bella, Yops, Traqueuse, Orion,
    Azuriel), les 35 autres sont inventés ;
  - le texte anglais a été relu le 27 novembre 2026 : orthographe britannique comme l'anglais de l'addon
    (« colour », « recognises », mais « specialization », terme du jeu), noms de sorts et de réglages du jeu, tournures
    traduites reprises. Un avis de joueur anglophone reste le bienvenu, surtout sur les noms des quatre fonctions
    phares.
