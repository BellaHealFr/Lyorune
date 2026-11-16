# Zenith (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Publie une nouvelle version de Zenith.
#
#   python outils/publier.py 1.3.0 "Première nouveauté." "Deuxième nouveauté."
#       1. lance les tests (arrêt si un test échoue)
#       2. met le numéro de version dans Zenith.toc et Core.lua
#       3. ajoute la version et ses nouveautés en tête de Changes.lua (affichées en jeu)
#       4. régénère CHANGELOG.md à partir de Changes.lua
#       5. crée dist/Zenith-1.3.0.zip, prêt à diffuser
#
#   python outils/publier.py
#       sans argument : refait seulement CHANGELOG.md et le zip de la version actuelle
import datetime, io, os, re, subprocess, sys, zipfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))


def read(name):
    return io.open(os.path.join(ROOT, name), encoding='utf-8').read()


def write(name, text):
    io.open(os.path.join(ROOT, name), 'w', encoding='utf-8', newline='\n').write(text)


def current_version():
    return re.search(r'## Version: (\S+)', read('Zenith.toc')).group(1)


def run_tests():
    env = dict(os.environ, PYTHONIOENCODING='utf-8')
    result = subprocess.run([sys.executable, os.path.join(ROOT, 'tests', 'run.py'), ROOT], env=env)
    if result.returncode != 0:
        sys.exit('Publication annulée : des tests échouent.')


def set_version(version, notes):
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        sys.exit('Numéro de version attendu sous la forme 1.3.0')
    write('Zenith.toc', re.sub(r'## Version: \S+', '## Version: ' + version, read('Zenith.toc')))
    write('Core.lua', re.sub(r'(GetAddOnMetadata\(ADDON, "Version"\)\) or ")[^"]+', r'\g<1>' + version, read('Core.lua')))
    lines = ''.join('\t\t"%s",\n' % note.replace('\\', '\\\\').replace('"', '\\"') for note in notes)
    block = '\t{\n\t\tversion = "%s", date = "%s",\n%s\t},\n' % (version, datetime.date.today().isoformat(), lines)
    changes = read('Changes.lua')
    marker = 'Z.changes = {\n'
    if marker not in changes:
        sys.exit('Changes.lua : la ligne « Z.changes = { » est introuvable.')
    write('Changes.lua', changes.replace(marker, marker + block, 1))


def write_changelog():
    text = read('Changes.lua')
    body = text[text.index('Z.changes = {'):text.index('\n}\n', text.index('Z.changes = {'))]
    out = ['# Journal des versions de Zenith', '',
           'Fichier généré par `outils/publier.py` à partir de `Changes.lua`. Ne pas le modifier à la main.', '']
    for entry in re.finditer(r'version = "([^"]+)", date = "([^"]+)",(.*?)\n\t\},', body, re.S):
        out.append('## %s (%s)' % (entry.group(1), entry.group(2)))
        out.append('')
        for note in re.findall(r'^\t\t"((?:[^"\\]|\\.)*)",', entry.group(3), re.M):
            out.append('- ' + note.replace('\\"', '"').replace('\\\\', '\\'))
        out.append('')
    write('CHANGELOG.md', '\n'.join(out))


def addon_files():
    # Exactement les fichiers chargés par le jeu : le .toc et ce qu'il cite
    files = ['Zenith.toc']
    for line in read('Zenith.toc').splitlines():
        line = line.strip()
        if line.endswith('.lua') and not line.startswith('#'):
            files.append(line.replace('\\', '/'))
    return files


def make_zip(version):
    os.makedirs(os.path.join(ROOT, 'dist'), exist_ok=True)
    path = os.path.join(ROOT, 'dist', 'Zenith-%s.zip' % version)
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in addon_files():
            archive.write(os.path.join(ROOT, name), 'Zenith/' + name)
    return path


def main():
    args = sys.argv[1:]
    if args:
        if len(args) < 2:
            sys.exit('Indiquez au moins une nouveauté : python outils/publier.py 1.3.0 "Ce qui change."')
        run_tests()
        set_version(args[0], args[1:])
    run_tests()
    write_changelog()
    version = current_version()
    print('\nZenith %s : CHANGELOG.md à jour, archive %s' % (version, make_zip(version)))


if __name__ == '__main__':
    main()
