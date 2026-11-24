-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
-- Lyorune - About.lua : les chiffres et les noms de la page « Les amis de Lyorune » (Options.lua).
-- Fichier écrit par outils/publier.py à chaque publication : un addon n'a pas accès à internet, ces chiffres
-- sont donc ceux du jour où la version installée a été publiée. Ne pas le modifier à la main : les noms du mur
-- de remerciements se rangent dans outils/amis.txt (un par ligne, seulement des joueurs d'accord).
--   names      : { name, class (PRIEST... : nom anglais du jeu, ou vide), mode (« Soins, JcJ », ou vide) }
--   date       : jour où les chiffres ont été lus
--   github     : téléchargements des archives publiées sur GitHub
--   curseforge : total CurseForge (lu par cfwidget, sinon demandé à l'auteur)
--   discord    : membres du serveur Discord de Lyorune
-- Le nombre de mises à jour n'est pas écrit ici : c'est le nombre de versions de Changes.lua.

local _, Z = ...

Z.about = {
	date = "2026-11-24",
	github = 915,
	curseforge = 312,
	discord = 10,
	names = {
		{ name = "Elesyio", class = "PRIEST", mode = "Soins, JcJ" },
	},
}
