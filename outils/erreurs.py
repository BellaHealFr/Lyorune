# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Rassemble les erreurs de Lyorune gardées sur l'ordinateur, pour les corriger vite.
#
#   python outils/erreurs.py                      dossier du jeu par défaut
#   python outils/erreurs.py "D:\...\_forever_"   autre dossier du jeu
#   python outils/erreurs.py --pile               avec la pile d'appels de chaque erreur
#
# Deux sources :
#   1. Logs/General.log (et General.log.old) : le jeu y écrit TOUTES les erreurs Lua, même quand un autre addon
#      a pris le gestionnaire d'erreurs. Le fichier est réécrit au lancement du jeu : le lire avant de relancer.
#   2. WTF/Account/*/SavedVariables/Lyorune.lua, table errors : le journal de Lyorune (contexte : version,
#      combat, groupe, zone, donjon, auras secrètes). Écrit au /reload ou à la déconnexion.
# Chaque erreur n'apparaît qu'une fois, avec son nombre, sa première et sa dernière heure.
import glob, io, os, re, sys

DOSSIER_JEU = r'D:\Program Files\World of Warcraft\_forever_'
DEBUT = re.compile(r'^(\d\d/\d\d \d\d:\d\d:\d\d)\.\d+\s+\[E\]\[Lua\] Lua Error: (.*)$')
HEURE = re.compile(r'^\d\d/\d\d \d\d:\d\d:\d\d')


def lire(chemin):
    with io.open(chemin, encoding='utf-8', errors='replace') as f:
        return f.read().splitlines()


def erreurs_du_jeu(dossier):
    """Erreurs Lua du journal du jeu qui citent Lyorune : {message: {nombre, premiere, derniere, pile, fichier}}"""
    trouvees = {}
    for nom in ('General.log.old', 'General.log'):
        chemin = os.path.join(dossier, 'Logs', nom)
        if not os.path.exists(chemin):
            continue
        lignes = lire(chemin)
        i = 0
        while i < len(lignes):
            m = DEBUT.match(lignes[i])
            i += 1
            if not m:
                continue
            heure, message = m.group(1), m.group(2).strip()
            pile = []
            while i < len(lignes) and not HEURE.match(lignes[i]):
                if lignes[i].strip():
                    pile.append(lignes[i].strip())
                i += 1
            if 'Lyorune' not in message and not any('Lyorune' in ligne for ligne in pile):
                continue
            e = trouvees.setdefault(message, {'nombre': 0, 'premiere': heure, 'derniere': heure, 'pile': pile, 'fichier': nom})
            e['nombre'] += 1
            e['derniere'] = heure
    return trouvees


def champ(bloc, nom):
    m = re.search(r'\["%s"\] = (?:"((?:[^"\\]|\\.)*)"|([^,\n]+)),' % nom, bloc)
    if not m:
        return ''
    texte = m.group(1) if m.group(1) is not None else m.group(2)
    return texte.replace('\\n', '\n').replace('\\"', '"').strip()


def journal_lyorune(dossier):
    """Entrées de LyoruneDB.errors, de chaque compte"""
    entrees = []
    for chemin in glob.glob(os.path.join(dossier, 'WTF', 'Account', '*', 'SavedVariables', 'Lyorune.lua')):
        texte = '\n'.join(lire(chemin))
        debut = texte.find('["errors"] = {')
        if debut < 0:
            continue
        profondeur, fin = 0, debut
        for j in range(debut, len(texte)):
            if texte[j] == '{':
                profondeur += 1
            elif texte[j] == '}':
                profondeur -= 1
                if profondeur == 0:
                    fin = j
                    break
        for bloc in re.split(r'\n\},?\n?\{', texte[debut:fin]):
            message = champ(bloc, 'message')
            if message:
                entrees.append({k: champ(bloc, k) for k in
                                ('message', 'kind', 'count', 'first', 'last', 'lyorune', 'combat', 'group', 'zone',
                                 'instance', 'stack')})
    return entrees


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    avec_pile = '--pile' in sys.argv
    dossier = args[0] if args else DOSSIER_JEU
    if not os.path.isdir(dossier):
        sys.exit('Dossier du jeu introuvable : %s' % dossier)

    jeu = erreurs_du_jeu(dossier)
    print('=== Journal du jeu (Logs/General.log) : %d erreur(s) différente(s) de Lyorune ===' % len(jeu))
    for message, e in sorted(jeu.items(), key=lambda kv: kv[1]['derniere'], reverse=True):
        print('\n[x%d] %s -> %s  (%s)' % (e['nombre'], e['premiere'], e['derniere'], e['fichier']))
        print('  ' + message)
        for ligne in (e['pile'] if avec_pile else e['pile'][:3]):
            print('    ' + ligne)

    journal = journal_lyorune(dossier)
    print('\n=== Journal de Lyorune (SavedVariables) : %d entrée(s) ===' % len(journal))
    for e in journal:
        print('\n[x%s] %s -> %s, Lyorune %s, %s, %s, %s (%s)' % (
            e['count'] or '?', e['first'], e['last'], e['lyorune'],
            'en combat' if e['combat'] == 'true' else 'hors combat', e['group'], e['zone'], e['instance'] or '?'))
        print('  %s : %s' % (e['kind'], e['message']))
        pile = [l for l in e['stack'].split('\n') if l.strip()]
        for ligne in (pile if avec_pile else pile[:3]):
            print('    ' + ligne)
    if not jeu and not journal:
        print('\nAucune erreur de Lyorune trouvée.')


if __name__ == '__main__':
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    main()
