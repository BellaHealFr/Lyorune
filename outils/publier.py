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
#
#   python outils/publier.py
#       sans argument : refait seulement CHANGELOG.md et le zip de la version actuelle
#
#   python outils/publier.py --notes 1.4.0
#       écrit RELEASE.md : les notes de cette seule version, pour la page de publication GitHub
#
# Numérotation (versions sémantiques) : MAJEUR.MINEUR.CORRECTIF
#   CORRECTIF (1.3.0 -> 1.3.1) : uniquement des corrections
#   MINEUR    (1.3.1 -> 1.4.0) : des fonctions en plus, les réglages des joueurs restent valables
#   MAJEUR    (1.4.0 -> 2.0.0) : un changement qui oblige les joueurs à refaire des réglages
import datetime, io, os, re, subprocess, sys, zipfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DEPOT = 'https://github.com/BellaHealFr/Lyorune'
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


def write_release_notes(version):
    for entry_version, date, notes in changes():
        if entry_version == version.lstrip('v'):
            lines = ['# Lyorune %s' % entry_version, ''] + section(notes)
            lines += ["**Installation** : téléchargez l'archive `.zip` ci-dessous et décompressez-la dans `World of Warcraft\\_forever_\\Interface\\AddOns\\`.",
                      '', 'Un bug ? [Comment le signaler](%s/blob/main/docs/SIGNALER_UN_BUG.md)' % DEPOT,
                      '', 'Journal complet : [CHANGELOG.md](%s/blob/main/CHANGELOG.md)' % DEPOT, '']
            english = traductions()
            if all(note in english for key, _, _ in RUBRIQUES for note in notes[key]):
                lines += ['---', '', '# Lyorune %s (English)' % entry_version, ''] + section(notes, english)
                lines += ['**Installation**: download the `.zip` archive below and unzip it into `World of Warcraft\\_forever_\\Interface\\AddOns\\`.',
                          '', 'A bug? [How to report it](%s/blob/main/docs/SIGNALER_UN_BUG.md#reporting-a-bug-english)' % DEPOT,
                          '', 'Full changelog: [CHANGELOG.en.md](%s/blob/main/CHANGELOG.en.md)' % DEPOT, '']
            write('RELEASE.md', '\n'.join(lines))
            print('RELEASE.md écrit pour la version', entry_version)
            return
    sys.exit('Version %s introuvable dans Changes.lua.' % version)


def addon_files():
    # Exactement les fichiers chargés par le jeu : le .toc, ce qu'il cite, les images du dossier Media, et la licence
    files = ['Lyorune.toc', 'LICENSE']
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
            for motif in (r'[A-Za-z]:\\Users\\', chr(0x2014)):
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
    if not any(notes.values()):
        sys.exit('Indiquez au moins un changement : python outils/publier.py 1.4.0 --corrige "Ce qui est corrigé."')
    return version, notes, english


def main():
    args = sys.argv[1:]
    if args and args[0] == '--notes':
        return write_release_notes(args[1] if len(args) > 1 else current_version())
    if args:
        version, notes, english = parse(args)
        run_tests()
        set_version(version, notes)
        add_translations(english)
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
