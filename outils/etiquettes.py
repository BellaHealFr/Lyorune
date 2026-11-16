# Zenith (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Crée ou met à jour sur GitHub les étiquettes décrites dans .github/labels.yml.
#
#   python outils/etiquettes.py
#
# Demande l'outil « gh » connecté au compte propriétaire du dépôt. A lancer une fois après la création
# du dépôt, puis à chaque modification de labels.yml.
import io, os, re, subprocess, sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))


def main():
    text = io.open(os.path.join(ROOT, '.github', 'labels.yml'), encoding='utf-8').read()
    labels = re.findall(r'- name: (.+)\n  color: (\w+)\n  description: (.+)', text)
    if not labels:
        sys.exit('Aucune étiquette lue dans .github/labels.yml')
    for name, color, description in labels:
        command = ['gh', 'label', 'create', name.strip(), '--color', color, '--description', description.strip(), '--force']
        result = subprocess.run(command, cwd=ROOT)
        if result.returncode != 0:
            sys.exit('Echec sur « %s » : gh est-il installé et connecté au bon compte ?' % name)
    print('%d étiquettes à jour.' % len(labels))


if __name__ == '__main__':
    main()
