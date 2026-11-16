# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Surveille la compatibilité de Lyorune avec le jeu, sans lancer le jeu.
#
#   python outils/verifier_api.py
#
# Principe : VuhDo, ElvUI et Decursive sont mis à jour très vite après chaque version du jeu. Si une fonction
# du jeu utilisée par Lyorune n'apparaît plus dans AUCUN de ces addons, elle a probablement été retirée ou
# renommée. Le script compare aussi le numéro d'interface de Lyorune à celui de ces addons.
# A lancer après chaque mise à jour du jeu ou de ces addons. En jeu, /lyorune diag fait le contrôle définitif.
import io, os, re, sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
GAME = r'D:\Program Files\World of Warcraft\_forever_'
ADDONS = os.path.join(GAME, 'Interface', 'AddOns')
REFERENCES = ['VuhDo', 'ElvUI', 'ElvUI_Libraries', 'Decursive']


def read(path):
    try:
        return io.open(path, encoding='utf-8', errors='replace').read()
    except OSError:
        return ''


def lua_files(folder):
    for base, _, names in os.walk(folder):
        if os.sep + 'tests' in base or os.sep + 'dist' in base:
            continue
        for name in names:
            if name.endswith('.lua'):
                yield os.path.join(base, name)


def main():
    if not os.path.isdir(ADDONS):
        sys.exit('Dossier du jeu introuvable : ' + ADDONS + ' (modifiez GAME en tête de ce script).')

    # 1. Fonctions du jeu utilisées par Lyorune
    used = set()
    for path in lua_files(ROOT):
        text = read(path)
        used.update(re.findall(r'\b(C_[A-Z]\w+\.\w+)', text))
        used.update(re.findall(r'\b(Enum\.\w+\.\w+)', text))
    required = re.search(r'Z\.requiredAPI = \{(.*?)\n\}', read(os.path.join(ROOT, 'Log.lua')), re.S)
    used.update(re.findall(r'"([\w.]+)"', required.group(1)))

    # 2. Texte des addons de référence
    reference, versions = [], []
    for name in REFERENCES:
        folder = os.path.join(ADDONS, name)
        if not os.path.isdir(folder):
            continue
        reference.append('\n'.join(read(path) for path in lua_files(folder)))
        toc = read(os.path.join(folder, name + '.toc')) or read(os.path.join(folder, name + '_Camelot.toc'))
        version = re.search(r'## Version: (.+)', toc)
        interface = re.search(r'## Interface: (.+)', toc)
        versions.append('  %-16s version %-12s interface %s' % (name, version.group(1).strip() if version else '?',
                                                                 interface.group(1).strip() if interface else '?'))
    everything = '\n'.join(reference)

    # 3. Rapport
    build = read(os.path.join(GAME, '.flavor.info')).split()
    lyorune_toc = read(os.path.join(ROOT, 'Lyorune.toc'))
    print('Jeu installé      :', build[-1] if build else '?')
    print('Lyorune            : version %s, interface %s' % (re.search(r'## Version: (\S+)', lyorune_toc).group(1),
                                                           re.search(r'## Interface: (.+)', lyorune_toc).group(1).strip()))
    print('Addons de référence :')
    print('\n'.join(versions) or '  aucun trouvé')

    missing = sorted(name for name in used if name.split('.')[-1] not in everything)
    print('\nFonctions du jeu utilisées par Lyorune : %d' % len(used))
    if missing:
        print('A VERIFIER : absentes de tous les addons de référence (retirées, renommées, ou simplement rares) :')
        for name in missing:
            print('  -', name)
        print('Vérifiez en jeu avec /lyorune diag avant de conclure.')
    else:
        print('Toutes sont encore utilisées par au moins un addon de référence.')

    interface = re.search(r'## Interface: (\d+)', lyorune_toc).group(1)
    if interface not in ' '.join(versions):
        print("\nATTENTION : l'interface %s de Lyorune n'est plus citée par les addons de référence : "
              "le jeu a peut-être changé de version (voir MAINTENANCE.md)." % interface)
    return 1 if missing else 0


if __name__ == '__main__':
    sys.exit(main())
