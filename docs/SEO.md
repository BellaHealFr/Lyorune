# Être trouvé : moteurs de recherche et réponses des IA

Ce document dit ce qui aide vraiment un joueur à tomber sur Lyorune, qu'il cherche sur Google, sur Bing ou en posant
la question à une IA (ChatGPT, Perplexity, Gemini, Copilot et les autres). Il sépare ce qui est vérifié de ce qui ne l'est
pas, puis liste ce qui change sur le site et ce que l'auteur doit faire lui-même.

## Sources consultées (27 novembre 2026)

Pages officielles lues directement :
- Google, [données structurées SoftwareApplication](https://developers.google.com/search/docs/appearance/structured-data/software-app)
- Google, [journal des mises à jour de la documentation](https://developers.google.com/search/docs/appearance/structured-data/faqpage)
  (entrées du 8 mai et du 15 juin 2026 sur la FAQ)
- Google, [fonctionnalités d'IA et votre site](https://developers.google.com/search/docs/appearance/ai-features)
- Google, [versions localisées (hreflang)](https://developers.google.com/search/docs/specialty/international/localized-versions)
- OpenAI, [robots d'exploration](https://developers.openai.com/api/docs/bots)
- Perplexity, [robots d'exploration](https://docs.perplexity.ai/guides/bots)
- Google, [vérifier la propriété d'un site](https://support.google.com/webmasters/answer/9008080)
- IndexNow, [documentation](https://www.indexnow.org/documentation) et [FAQ](https://www.indexnow.org/en_gb/faq)
- Bing, [sitemaps et recherche par IA](https://blogs.bing.com/webmaster/July-2025/Keeping-Content-Discoverable-with-Sitemaps-in-AI-Powered-Search)
  et [rapport « AI Performance »](https://blogs.bing.com/webmaster/February-2026/Introducing-AI-Performance-in-Bing-Webmaster-Tools-Public-Preview)

Articles de seconde main (résumés lus, chiffres à prendre avec prudence) :
- [Search Engine Journal, fin des résultats enrichis FAQ](https://www.searchenginejournal.com/google-drops-faq-rich-results-from-search/574429/)
- [Search Engine Roundtable, nouvelles règles de Bing (février 2026)](https://www.seroundtable.com/bing-webmaster-guidelines-updated-41002.html)
- [Ahrefs, pourquoi ChatGPT cite une page plutôt qu'une autre](https://ahrefs.com/blog/why-chatgpt-cites-pages/)
  et [recouvrement entre citations des IA et top 10 de Google](https://ahrefs.com/blog/ai-search-overlap/)
- [Project LLMs.txt, état réel de llms.txt en 2026](https://projectllmstxt.com/blog/llms-txt-adoption-2026)
- [DEV Community, IndexNow sur un site GitHub Pages de projet](https://dev.to/samtj/my-indexnow-submissions-returned-202-for-two-weeks-none-of-them-worked-2li0)

Les pages d'autres addons regardées pour les mots employés restent dans `refonte/sources-site.md` (local).

**Ce qui n'a pas pu être vérifié** : aucun outil de volume de recherche n'était disponible, donc les mots-clés plus bas
viennent du vocabulaire des pages d'addons et des guides, pas de chiffres mesurés ; les nouvelles règles de Bing n'ont
été lues qu'à travers des articles qui les citent ; personne ne publie comment une IA choisit ses sources, les études
sont des corrélations.

## Ce que la recherche a trouvé

### 1. Google et Bing : les bases suffisent

- Google le dit en toutes lettres : il n'y a « aucune exigence supplémentaire » ni « optimisation spéciale » pour
  apparaître dans les AI Overviews et le mode IA, ni données structurées particulières, ni « fichier texte pour IA ».
  Une page indexée, avec un extrait, suffit. Le site de Lyorune remplit déjà ces conditions (HTML statique complet
  dans chaque langue, titre et description, un seul H1).
- Bing a réécrit ses règles début 2026 pour couvrir Copilot et les réponses par IA. Il insiste sur le sitemap avec
  une date `lastmod` exacte (la vraie date du dernier changement) et propose IndexNow pour signaler un changement
  tout de suite. Le sitemap du site met déjà la date de la version publiée.
- La balise `keywords` ne sert plus à Google depuis longtemps. Elle ne gêne pas tant qu'elle reste courte et honnête.

### 2. Données structurées : ce qu'elles donnent vraiment

- **SoftwareApplication** : pour obtenir la fiche enrichie (étoiles, prix), Google exige `name`, `offers.price`
  (0 pour un addon gratuit) **et** une note (`aggregateRating`) ou un avis (`review`). Lyorune n'a ni note ni avis sur
  son site, et il est hors de question d'en inventer (règle D de `docs/ANTI-IA.md`). Donc **pas de fiche enrichie
  possible** aujourd'hui. Les données restent utiles : elles disent clairement aux moteurs et aux IA ce qu'est la page
  (un addon gratuit, sa version, son auteur, ses pages officielles).
- **FAQPage** : Google a cessé d'afficher les FAQ enrichies le 7 mai 2026 et a retiré leur documentation le 15 juin
  2026. Le balisage ne nuit pas. Ce qui compte désormais, c'est la FAQ visible : des questions écrites comme un
  joueur les pose, avec des réponses nettes, que les IA reprennent volontiers.
- **hreflang** : chaque langue doit se citer elle-même et citer l'autre, et les deux pages doivent se répondre,
  sinon Google ignore tout. C'est le cas sur GitHub Pages. **Point à corriger** : sur la cible Cloudflare, le
  canonical pointe vers GitHub mais les hreflang et le sitemap pointent vers Cloudflare, deux signaux contraires.
  Sans conséquence tant que le site Cloudflare n'est pas en ligne, à régler au lot 15b.

### 3. GitHub Pages : un piège propre aux sites de projet

Les robots ne lisent `robots.txt` qu'à la racine du domaine : `https://bellahealfr.github.io/robots.txt`. Celui de
`/Lyorune/robots.txt` n'est jamais lu (vérifié le 27/11 : la racine répond 404, ce qui veut dire « tout est permis »,
donc rien n'est bloqué). Conséquence : **la ligne `Sitemap:` du site n'est vue par personne**. Il faut envoyer le
sitemap à la main dans Google Search Console et Bing Webmaster Tools. Même chose pour `llms.txt`, attendu à la racine.
Seul moyen de l'éviter : un dépôt `BellaHealFr.github.io` (site de compte) qui publie un `robots.txt` à la racine, ou
le domaine Cloudflare, servi à la racine.

### 4. Les IA : qui laisser entrer

Chaque société sépare ses robots en trois familles. Les bloquer n'a aucun effet sur les autres.

| Rôle | OpenAI | Perplexity | Google |
|---|---|---|---|
| Recherche (être cité dans les réponses) | OAI-SearchBot | PerplexityBot | Googlebot (AI Overviews font partie de la recherche) |
| Lecture à la demande d'un utilisateur | ChatGPT-User | Perplexity-User | |
| Entraînement des modèles | GPTBot | | Google-Extended (n'a aucun effet sur la recherche) |

- OpenAI l'écrit : un site qui refuse OAI-SearchBot n'apparaît pas dans les réponses de ChatGPT avec recherche.
  Perplexity conseille de laisser entrer PerplexityBot. Les autres sociétés d'IA suivent le même découpage, avec
  des noms de robots différents.
- Le `robots.txt` du site (`User-agent: *` puis `Allow: /`) laisse déjà tout entrer, et la racine de github.io ne
  bloque rien. **Rien à débloquer.**
- Choix laissé à l'auteur : laisser aussi les robots d'entraînement (conseil : oui). Un modèle qui a lu la page sait
  ce qu'est Lyorune même sans faire de recherche, ce qui sert un addon gratuit qui veut être connu.

### 5. llms.txt : peu d'effet, mais rien à perdre

Aucune grande société d'IA ne s'est engagée à lire `llms.txt`. Google le compare à l'ancienne balise `keywords`.
Une étude sur les journaux de serveurs trouve que 97 % de ces fichiers ne reçoivent aucune visite de robot d'IA.
Il sert surtout aux outils de développement qui lisent une documentation. Le site le garde (il ne coûte rien et
reste exact), sans en attendre de miracle.

### 6. Ce qui fait citer une page par une IA

- Les IA cherchent plusieurs variantes de la question, lisent titre, extrait et adresse, puis n'ouvrent et ne citent
  qu'une partie des pages. Seules 12 % des pages citées sont aussi dans le top 10 de Google pour la même question.
- Les pages citées répondent à une question précise par un fait net et vérifiable : un nom, une version, une
  commande, une limite. La FAQ et la section « Pourquoi Lyorune » (avec ses limites assumées) sont les meilleures
  candidates.
- Les pages tierces comptent autant que le site : la page CurseForge, Wago, WoWInterface, le dépôt GitHub, les
  guides qui listent les addons de WoW Forever, les fils de discussion. Une IA qui trouve Lyorune décrit pareil à
  cinq endroits le cite avec plus d'assurance.

### 7. Les mots que les joueurs tapent

Vocabulaire repris des pages d'addons et des guides de WoW Forever (non mesuré, à confirmer par les requêtes réelles
de Search Console après quelques semaines) :

- **Anglais** : « WoW Forever healing addon », « WoW Forever healer addon », « healing frames », « raid frames »,
  « party frames », « click casting » et « click-casting », « mouseover healing », « healer addon priest / druid /
  paladin / shaman », « WoW Forever addons ».
- **Français** : « addon heal WoW Forever », « addon soigneur », « addon soin », « cadres de raid », « clic-soin »,
  « soin au clic », « addon healer ». Les joueurs français emploient souvent les mots anglais (heal, healer, raid
  frames) : le site les garde à côté des termes français.
- Les pages d'addons concurrentes mettent presque toutes « Forever » et « Healing Frames » dans leur titre. Le titre
  anglais du site et des plateformes doit contenir « WoW Forever » et « healing frames » en clair.

### 8. Les liens qui comptent

Déjà en place : le dépôt GitHub pointe vers le site et porte les bons sujets (`wow-forever`, `click-casting`,
`raid-frames`, `healer`…) ; le site renvoie vers les quatre plateformes officielles et le Discord.
À renforcer : un lien vers le site sur chaque page de plateforme ; une présence dans les guides et listes d'addons
de WoW Forever (le blog de CurseForge en publie une, des sites de guides de jeu aussi) ; la vidéo du lot 14 sur
YouTube, avec le lien du site dans sa description.

## Ce qui change sur le site (lot 15b)

1. Cible Cloudflare : hreflang et sitemap vers les adresses de la cible principale, comme le canonical.
2. FAQ : deux ou trois questions écrites comme un joueur les tape (« Quel addon de soin pour WoW Forever ? »,
   « Le clic-soin marche-t-il sur WoW Forever ? », « Lyorune marche-t-il avec ElvUI ? »), en français et en anglais,
   réponses vérifiées dans le code.
3. Titres et descriptions : « WoW Forever » et « healing frames » en clair dans les deux langues ; descriptions des
   plateformes (`docs/plateformes/`) relues avec la liste du point 7.
4. Données structurées : garder SoftwareApplication et FAQPage, sans note ni avis inventés.
5. Emplacement pour la balise de vérification de Google Search Console et de Bing (un réglage par cible, vide tant
   que l'auteur ne l'a pas donné).
6. IndexNow (facultatif) : un fichier clé dans `/Lyorune/` et un envoi par le circuit Site à chaque publication,
   avec `keyLocation` (indispensable sur un site de projet GitHub Pages).

## À faire par l'auteur

- [ ] **Google Search Console** : ajouter une propriété « préfixe d'URL » `https://bellahealfr.github.io/Lyorune/`
  (une propriété « domaine » est impossible sur github.io), vérifier par balise HTML (me donner le code), puis
  envoyer `https://bellahealfr.github.io/Lyorune/sitemap.xml`.
- [ ] **Bing Webmaster Tools** : importer le site depuis Search Console (ou vérifier par balise), envoyer le même
  sitemap, puis suivre le rapport « AI Performance » qui montre les citations dans Copilot.
- [ ] Choisir : robots d'entraînement des IA laissés entrer (conseil : oui) ou bloqués.
- [ ] Choisir : IndexNow, oui ou non.
- [ ] Mettre le lien du site sur les pages CurseForge, Wago et WoWInterface si ce n'est pas déjà fait.
- [ ] Proposer Lyorune aux guides et listes d'addons de WoW Forever, et en parler sur le Discord et les forums de
  joueurs (une présence réelle, jamais de faux messages).
- [ ] Le jour du domaine Cloudflare : il est servi à la racine, son `robots.txt` et son `llms.txt` seront lus.
