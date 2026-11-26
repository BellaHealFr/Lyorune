# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Publie une nouvelle version de Lyorune.
#
#   python outils/publier.py 1.4.0 --nouveau "Une fonction." --ameliore "Un réglage." --corrige "Un bug (#12)."
#       1. lance les tests (arrêt si un test échoue)
#       2. met le numéro de version dans Lyorune.toc et Core.lua
#       3. ajoute la version en tête de Changes.lua, rangée en trois rubriques (affichées en jeu)
#       4. régénère CHANGELOG.md à partir de Changes.lua
#       5. crée dist/Lyorune-1.4.0.zip, prêt à diffuser
#     Chaque rubrique est facultative, mais il en faut au moins une. « (#12) » renvoie à la demande GitHub n° 12.
#     Pour les joueurs anglophones, faites suivre chaque changement de sa traduction : "Un réglage." --en "A setting."
#     Elle est rangée dans Locales/enUS.lua (nouveautés en jeu) et sert au journal anglais CHANGELOG.en.md.
#     Avant les tests, About.lua est réécrit pour la page « Les amis de Lyorune » : téléchargements GitHub et
#     membres du Discord et total CurseForge lus sur internet (CurseForge par cfwidget, sans clé ; --curseforge 1234
#     impose un chiffre ; s'il est illisible, il est demandé, Entrée garde l'ancien), noms du mur de remerciements
#     lus dans outils/amis.txt. Sans réponse d'internet, les anciens chiffres restent.
#     Depuis Git Bash, une note qui commence par « /lyorune » devient un chemin de fichier (C:/Program Files/Git/...) :
#     la publication est alors refusée. Lancer depuis PowerShell, ou préfixer la commande par MSYS_NO_PATHCONV=1.
#
#   python outils/publier.py
#       sans argument : refait seulement CHANGELOG.md et le zip de la version actuelle
#
#   python outils/publier.py --notes 1.4.0
#       écrit RELEASE.md : les notes de cette seule version, pour la page de publication GitHub
#       (précédées du mot d'ouverture docs/annonces/1.4.0.md et docs/annonces/1.4.0.en.md s'ils existent)
#
# Numérotation (versions sémantiques) : MAJEUR.MINEUR.CORRECTIF
#   CORRECTIF (1.3.0 -> 1.3.1) : uniquement des corrections
#   MINEUR    (1.3.1 -> 1.4.0) : des fonctions en plus, les réglages des joueurs restent valables
#   MAJEUR    (1.4.0 -> 2.0.0) : un changement qui oblige les joueurs à refaire des réglages
import datetime, io, os, re, subprocess, sys, zipfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DEPOT = 'https://github.com/BellaHealFr/Lyorune'
BADGES = 'docs/badges/'  # chiffres des badges des README, lus par shields.io
PREMIERE_PUBLIEE = (1, 4, 0)  # première version qui existe sur GitHub (les précédentes n'ont pas d'étiquette)
RUBRIQUES = [('added', '--nouveau', 'Ajouté'), ('improved', '--ameliore', 'Amélioré'), ('fixed', '--corrige', 'Corrigé')]
RUBRIQUES_EN = {'added': 'Added', 'improved': 'Improved', 'fixed': 'Fixed'}


def read(name):
    return io.open(os.path.join(ROOT, name), encoding='utf-8').read()


def write(name, text):
    io.open(os.path.join(ROOT, name), 'w', encoding='utf-8', newline='\n').write(text)


def numero(version):
    return tuple(int(part) for part in version.split('.'))


def current_version():
    return re.search(r'## Version: (\S+)', read('Lyorune.toc')).group(1)


def run_tests():
    env = dict(os.environ, PYTHONIOENCODING='utf-8')
    result = subprocess.run([sys.executable, os.path.join(ROOT, 'tests', 'run.py'), ROOT], env=env, capture_output=True, text=True, encoding='utf-8')
    echecs = [line for line in result.stdout.splitlines() if 'ERREUR' in line]
    if result.returncode != 0:
        sys.exit('Publication annulée : des tests échouent.\n' + '\n'.join(echecs or [result.stdout[-2000:], result.stderr[-2000:]]))
    print('Tests : %d étapes OK' % sum(1 for line in result.stdout.splitlines() if line.strip().startswith('OK')))


def lua_string(text):
    return '"%s"' % text.replace('\\', '\\\\').replace('"', '\\"')


def changes():
    """Lit Changes.lua : liste de (version, date, {rubrique: [notes]}), la plus récente en premier."""
    text = read('Changes.lua')
    body = text[text.index('Z.changes = {'):]
    entries = []
    for entry in re.finditer(r'version = "([^"]+)", date = "([^"]+)",(.*?)\n\t\},\n', body, re.S):
        notes = {}
        for key, _, _ in RUBRIQUES:
            block = re.search(key + r' = \{(.*?)\n\t\t\}', entry.group(3), re.S)
            found = re.findall(r'^\t\t\t"((?:[^"\\]|\\.)*)",', block.group(1), re.M) if block else []
            notes[key] = [note.replace('\\"', '"').replace('\\\\', '\\') for note in found]
        entries.append((entry.group(1), entry.group(2), notes))
    return entries


def traductions():
    """Lit Locales/enUS.lua : {texte français: texte anglais}, pour les entrées écrites sur une seule ligne."""
    decode = lambda text: text.replace('\\"', '"').replace('\\\\', '\\')
    pairs = re.findall(r'\["((?:[^"\\]|\\.)*)"\] = "((?:[^"\\]|\\.)*)"', read('Locales/enUS.lua'))
    return {decode(french): decode(english) for french, english in pairs}


def add_translations(english):
    """Ajoute à la fin de Locales/enUS.lua la traduction des nouvelles notes."""
    if not english:
        return
    text = read('Locales/enUS.lua').rstrip()
    if not text.endswith('}'):
        sys.exit('Locales/enUS.lua : accolade finale introuvable.')
    lines = ''.join('\t[%s] = %s,\n' % (lua_string(french), lua_string(translation)) for french, translation in english.items())
    write('Locales/enUS.lua', text[:-1].rstrip() + '\n' + lines + '}\n')


def set_version(version, notes):
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        sys.exit('Numéro de version attendu sous la forme 1.4.0')
    if numero(version) <= numero(current_version()):
        sys.exit('La version %s doit être supérieure à la version actuelle (%s).' % (version, current_version()))
    write('Lyorune.toc', re.sub(r'## Version: \S+', '## Version: ' + version, read('Lyorune.toc')))
    write('Core.lua', re.sub(r'(GetAddOnMetadata\(ADDON, "Version"\)\) or ")[^"]+', r'\g<1>' + version, read('Core.lua')))
    block = '\t{\n\t\tversion = "%s", date = "%s",\n' % (version, datetime.date.today().isoformat())
    for key, _, _ in RUBRIQUES:
        block += '\t\t%s = {\n%s\t\t},\n' % (key, ''.join('\t\t\t%s,\n' % lua_string(note) for note in notes[key]))
    block += '\t},\n'
    text = read('Changes.lua')
    marker = 'Z.changes = {\n'
    if marker not in text:
        sys.exit('Changes.lua : la ligne « Z.changes = { » est introuvable.')
    write('Changes.lua', text.replace(marker, marker + block, 1))


DISCORD_INVITE = 'uRaEPTGePu'
ABOUT_HEAD = """-- Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
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
"""


def old_about(key):
    found = re.search(r'\b%s = (\d+)' % key, read('About.lua'))
    return int(found.group(1)) if found else 0


def discord_members():
    import json, urllib.request
    url = 'https://discord.com/api/v9/invites/%s?with_counts=true' % DISCORD_INVITE
    request = urllib.request.Request(url, headers={'User-Agent': 'lyorune-stats'})
    return int(json.load(urllib.request.urlopen(request, timeout=20))['approximate_member_count'])


def curseforge_downloads():
    """Total CurseForge du projet (numéro X-Curse-Project-ID du .toc), lu par le service public cfwidget, sans clé."""
    import json, urllib.request
    project = re.search(r'## X-Curse-Project-ID: (\d+)', read('Lyorune.toc')).group(1)
    request = urllib.request.Request('https://api.cfwidget.com/%s' % project, headers={'User-Agent': 'lyorune-stats'})
    return int(json.load(urllib.request.urlopen(request, timeout=20))['downloads']['total'])


CLASSES = {'guerrier': 'WARRIOR', 'voleur': 'ROGUE', 'chasseur': 'HUNTER', 'paladin': 'PALADIN', 'chaman': 'SHAMAN',
           'druide': 'DRUID', 'prêtre': 'PRIEST', 'pretre': 'PRIEST', 'mage': 'MAGE', 'démoniste': 'WARLOCK',
           'demoniste': 'WARLOCK'}


def thank_names():
    """Lignes de outils/amis.txt : « Nom ; Classe ; Mode de jeu » (classe et mode facultatifs) -> liste de dict."""
    path = os.path.join(ROOT, 'outils', 'amis.txt')
    if not os.path.exists(path):
        return []
    friends = []
    for line in io.open(path, encoding='utf-8'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        parts = [part.strip() for part in line.split(';')] + ['', '']
        name, classe, mode = parts[0], parts[1], parts[2]
        token = CLASSES.get(classe.lower(), classe.upper()) if classe else ''
        if token and token not in CLASSES.values():
            sys.exit('outils/amis.txt : classe inconnue pour %s : %r (attendu : %s)' % (name, classe, ', '.join(sorted(set(CLASSES) - {'pretre', 'demoniste'}))))
        friends.append({'name': name, 'class': token, 'mode': mode})
    return friends


def write_badge(name, label, message):
    """Badge des README (version, téléchargements) lu par shields.io : une seule petite lecture, toujours rapide,
    au lieu de faire interroger GitHub par shields.io (trop lent avec beaucoup de versions, le badge s'affichait cassé)."""
    import json
    write(BADGES + name + '.json', json.dumps({'schemaVersion': 1, 'label': label, 'message': message, 'color': 'd4a94e'},
                                              ensure_ascii=False) + '\n')


def write_about(curseforge=None):
    """Réécrit About.lua : chiffres du jour (ou les anciens si internet ne répond pas) et noms de remerciements."""
    if os.path.join(ROOT, 'outils') not in sys.path:
        sys.path.insert(0, os.path.join(ROOT, 'outils'))
    import telechargements
    numbers = {}
    for key, fetch in (('github', telechargements.total), ('discord', discord_members)):
        try:
            numbers[key] = fetch()
        except Exception as error:
            numbers[key] = old_about(key)
            print('%s illisible (%s) : ancien chiffre gardé (%d).' % (key, error, numbers[key]))
    if curseforge is None:
        try:
            curseforge = curseforge_downloads()
        except Exception as error:
            print('curseforge illisible (%s).' % error)
    if curseforge is None and sys.stdin.isatty():
        try:
            typed = input('Total des téléchargements CurseForge (Entrée : garder %d) : ' % old_about('curseforge')).strip()
        except EOFError:  # aucune réponse possible (commande lancée sans clavier)
            typed = ''
        typed = typed.replace(' ', '').replace('.', '')
        if typed and not typed.isdigit():
            print('Nombre illisible (%r) : ancien chiffre CurseForge gardé.' % typed)
        curseforge = int(typed) if typed.isdigit() else None
    numbers['curseforge'] = old_about('curseforge') if curseforge is None else curseforge
    write_badge('telechargements', 'téléchargements', str(numbers['github']))
    noms = thank_names()
    names = ''.join('\t\t{ name = %s, class = %s, mode = %s },\n' % (lua_string(f['name']), lua_string(f['class']), lua_string(f['mode']))
                    for f in noms)
    write('About.lua', ABOUT_HEAD + '\nZ.about = {\n\tdate = "%s",\n\tgithub = %d,\n\tcurseforge = %d,\n\tdiscord = %d,\n\tnames = {\n%s\t},\n}\n'
          % (datetime.date.today().isoformat(), numbers['github'], numbers['curseforge'], numbers['discord'], names))
    print('About.lua : %d téléchargements GitHub, %d CurseForge, %d sur le Discord, %d nom(s) de remerciement.'
          % (numbers['github'], numbers['curseforge'], numbers['discord'], len(noms)))


def with_links(note):
    # « (#12) » devient un lien vers la demande n° 12
    return re.sub(r'#(\d+)', r'[#\1](%s/issues/\1)' % DEPOT, note)


def section(notes, english=None):
    # english : la table des traductions pour écrire la version anglaise (une note sans traduction reste en français)
    lines = []
    for key, _, title in RUBRIQUES:
        if notes[key]:
            if english is not None:
                title = RUBRIQUES_EN[key]
            lines += ['### ' + title, ''] + ['- ' + with_links(note if english is None else english.get(note, note)) for note in notes[key]] + ['']
    return lines


def write_changelog(english=None):
    entries = changes()
    out = ['# Journal des versions', '',
           'Tous les changements notables de Lyorune, version par version. [English version](CHANGELOG.en.md)', '',
           'Présentation inspirée de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) ; '
           'numérotation en [versions sémantiques](https://semver.org/lang/fr/).', '',
           ] if english is None else [
           '# Changelog', '',
           'All notable changes to Lyorune, version by version. [Version française](CHANGELOG.md)', '',
           'Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); '
           'numbering follows [semantic versioning](https://semver.org/).', '',
           ]
    out += [
           '<!-- Fichier généré par outils/publier.py à partir de Changes.lua. Ne pas le modifier à la main. -->', '']
    links = []
    for index, (version, date, notes) in enumerate(entries):
        published = numero(version) >= PREMIERE_PUBLIEE
        out += ['## %s - %s' % ('[%s]' % version if published else version, date), ''] + section(notes, english)
        if published:
            previous = entries[index + 1][0] if index + 1 < len(entries) else None
            if previous and numero(previous) >= PREMIERE_PUBLIEE:
                links.append('[%s]: %s/compare/v%s...v%s' % (version, DEPOT, previous, version))
            else:
                links.append('[%s]: %s/releases/tag/v%s' % (version, DEPOT, version))
    write('CHANGELOG.md' if english is None else 'CHANGELOG.en.md', '\n'.join(out + links) + '\n')


def annonce(version, langue=''):
    """Mot d'ouverture facultatif de la page de publication : docs/annonces/X.Y.Z.md (et X.Y.Z.en.md en anglais)."""
    name = os.path.join('docs', 'annonces', version + langue + '.md')
    if not os.path.exists(os.path.join(ROOT, name)):
        return []
    return [read(name).strip(), '']


def write_release_notes(version):
    for entry_version, date, notes in changes():
        if entry_version == version.lstrip('v'):
            lines = ['# Lyorune %s' % entry_version, ''] + annonce(entry_version) + section(notes)
            lines += ["**Installation** : téléchargez l'archive `.zip` ci-dessous et décompressez-la dans `World of Warcraft\\_forever_\\Interface\\AddOns\\`.",
                      '', 'Un bug ? [Comment le signaler](%s/blob/main/docs/SIGNALER_UN_BUG.md)' % DEPOT,
                      '', 'Journal complet : [CHANGELOG.md](%s/blob/main/CHANGELOG.md)' % DEPOT, '']
            english = traductions()
            if all(note in english for key, _, _ in RUBRIQUES for note in notes[key]):
                lines += ['---', '', '# Lyorune %s (English)' % entry_version, ''] + annonce(entry_version, '.en') + section(notes, english)
                lines += ['**Installation**: download the `.zip` archive below and unzip it into `World of Warcraft\\_forever_\\Interface\\AddOns\\`.',
                          '', 'A bug? [How to report it](%s/blob/main/docs/SIGNALER_UN_BUG.md#reporting-a-bug-english)' % DEPOT,
                          '', 'Full changelog: [CHANGELOG.en.md](%s/blob/main/CHANGELOG.en.md)' % DEPOT, '']
            write('RELEASE.md', '\n'.join(lines))
            print('RELEASE.md écrit pour la version', entry_version)
            return
    sys.exit('Version %s introuvable dans Changes.lua.' % version)


def addon_files():
    # Exactement les fichiers chargés par le jeu : le .toc, ce qu'il cite, les images du dossier Media, et la licence
    # (Bindings.xml n'est pas cité dans le .toc : le jeu le charge tout seul)
    files = ['Lyorune.toc', 'LICENSE', 'Bindings.xml']
    files += ['Media/' + name for name in sorted(os.listdir(os.path.join(ROOT, 'Media'))) if name.endswith('.tga')]
    for line in read('Lyorune.toc').splitlines():
        line = line.strip()
        if line.endswith(('.lua', '.xml')) and not line.startswith('#'):
            files.append(line.replace('\\', '/'))
    return files


def make_zip(version):
    os.makedirs(os.path.join(ROOT, 'dist'), exist_ok=True)
    path = os.path.join(ROOT, 'dist', 'Lyorune-%s.zip' % version)
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in addon_files():
            archive.write(os.path.join(ROOT, name), 'Lyorune/' + name)
    check_zip(path)
    return path


def check_zip(path):
    """Relit l'archive avant diffusion : exactement les fichiers de l'addon, rien de caché, rien de privé."""
    attendus = sorted('Lyorune/' + name for name in addon_files())
    problemes = []
    with zipfile.ZipFile(path) as archive:
        noms = sorted(archive.namelist())
        if noms != attendus:
            problemes.append('fichiers en trop : %s ; manquants : %s' % (sorted(set(noms) - set(attendus)), sorted(set(attendus) - set(noms))))
        for name in noms:
            if '..' in name or name.startswith('/') or '\\' in name:
                problemes.append('chemin suspect : ' + name)
            if not name.endswith(('.lua', '.xml', '.toc', 'LICENSE')):
                continue
            texte = archive.read(name).decode('utf-8', 'replace')
            if archive.read(name) != io.open(os.path.join(ROOT, name[len('Lyorune/'):]), 'rb').read():
                problemes.append('contenu différent du dépôt : ' + name)
            # un chemin de mon ordinateur, ou un tiret cadratin
            for motif in (r'[A-Za-z]:\\Users\\', r'(?<![A-Za-z])[A-Za-z]:/', chr(0x2014)):
                if re.search(motif, texte):
                    problemes.append('%s contient %r' % (name, motif))
    if problemes:
        os.remove(path)
        sys.exit('Archive refusée, rien n\'est publié :\n  ' + '\n  '.join(problemes))
    print('Archive vérifiée : %d fichiers, rien de privé.' % len(noms))


def parse(args):
    """1.4.0 --nouveau "a" "b" --corrige "c"  ->  version et notes par rubrique."""
    version, notes, current = args[0], {key: [] for key, _, _ in RUBRIQUES}, 'added'
    options = {option: key for key, option, _ in RUBRIQUES}
    english, last, translate = {}, None, False
    for arg in args[1:]:
        if translate:
            if last is None:
                sys.exit('--en doit suivre le changement qu\'il traduit.')
            english[last], translate = arg, False
        elif arg == '--en':
            translate = True
        elif arg in options:
            current = options[arg]
        elif arg.startswith('--'):
            sys.exit('Option inconnue : %s (attendu : --nouveau, --ameliore, --corrige, --en)' % arg)
        else:
            notes[current].append(arg)
            last = arg
    for note in [n for rubrique in notes.values() for n in rubrique] + list(english.values()):
        if re.search(r'(?<![A-Za-z])[A-Za-z]:/', note):
            sys.exit('Note transformée en chemin de fichier (Git Bash) : %r\n'
                     'Relancez depuis PowerShell, ou avec MSYS_NO_PATHCONV=1 devant la commande.' % note)
        # numéros du suivi interne des corrections (C20...) : jamais dans les notes des joueurs (demande de l'auteur)
        if re.search(r'\bC\d+\b', note):
            sys.exit('Note refusée : numéro de suivi interne (C20...) à retirer : %r' % note)
    if not any(notes.values()):
        sys.exit('Indiquez au moins un changement : python outils/publier.py 1.4.0 --corrige "Ce qui est corrigé."')
    return version, notes, english


def main():
    args = sys.argv[1:]
    if args and args[0] == '--notes':
        return write_release_notes(args[1] if len(args) > 1 else current_version())
    curseforge = None
    if '--curseforge' in args:
        at = args.index('--curseforge')
        if at + 1 >= len(args) or not args[at + 1].isdigit():
            sys.exit('--curseforge attend un nombre : --curseforge 1234')
        curseforge = int(args[at + 1])
        del args[at:at + 2]
        if not args:
            sys.exit('--curseforge ne sert qu\'avec une nouvelle version : python outils/publier.py 1.4.0 --curseforge 1234 --nouveau "..."')
    if args:
        version, notes, english = parse(args)
        run_tests()
        set_version(version, notes)
        write_badge('version', 'version', 'v' + version)
        add_translations(english)
        write_about(curseforge)
    run_tests()
    write_changelog()
    write_changelog(traductions())
    manquantes = [note for _, _, notes in changes() for key, _, _ in RUBRIQUES for note in notes[key] if note not in traductions()]
    if manquantes:
        print('Sans traduction anglaise (à ajouter dans Locales/enUS.lua, puis relancer cette commande sans argument) :')
        for note in manquantes:
            print('  -', note)
    version = current_version()
    print('Lyorune %s : CHANGELOG.md à jour, archive %s' % (version, make_zip(version)))
    if args:
        print('Reste à faire : git add -A, git commit -m "Lyorune %s", git tag v%s, git push --follow-tags' % (version, version))


if __name__ == '__main__':
    main()
