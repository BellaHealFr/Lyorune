# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Envoie une archive de Lyorune sur WoWInterface (page https://www.wowinterface.com/downloads/info27323).
#
#   python outils/wowinterface.py v1.51.0 .release/Lyorune-v1.51.0-forever.zip [RELEASE.md]
#
# L'outil d'empaquetage de GitHub (BigWigsMods/packager) ne relie pas le jeu « forever » à WoWInterface : il saute
# l'envoi et finit en erreur. WoWInterface connaît pourtant WoW Forever : sa liste des versions du jeu
# (addons/compatible.json) a une ligne « Forever » dont l'interface est celle de Lyorune.toc. Ce script prend donc
# dans cette liste les versions dont l'interface est celle du .toc (rien d'autre : pas de version Retail affichée),
# puis envoie l'archive avec le numéro de l'addon (## X-WoWI-ID du .toc).
# Le jeton vient de la variable WOWI_API_TOKEN (secret du dépôt) ; sans jeton, rien n'est envoyé.
# Code de sortie : 0 envoyé (ou rien à faire sans jeton), 1 refusé ou impossible.

import json
import os
import re
import sys
import urllib.error
import urllib.request
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSIONS_URL = 'https://api.wowinterface.com/addons/compatible.json'
UPLOAD_URL = 'https://api.wowinterface.com/addons/update'
AGENT = 'Lyorune-publication'


def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read()


def toc_values():
    toc = read(os.path.join(ROOT, 'Lyorune.toc'))
    addon = re.search(r'^## X-WoWI-ID:\s*(\d+)', toc, re.M)
    interface = re.search(r'^## Interface:\s*([\d, ]+)', toc, re.M)
    interfaces = [i.strip() for i in interface.group(1).split(',') if i.strip()] if interface else []
    return (addon.group(1) if addon else None), interfaces


def compatible(interfaces):
    request = urllib.request.Request(VERSIONS_URL, headers={'User-Agent': AGENT})
    with urllib.request.urlopen(request, timeout=30) as answer:
        versions = json.load(answer)
    found = [v['id'] for v in versions if isinstance(v, dict) and v.get('interface') in interfaces and v.get('id')]
    return ','.join(dict.fromkeys(found))  # sans doublon, dans l'ordre de la liste


def multipart(fields, file_field, file_path):
    boundary = uuid.uuid4().hex
    parts = []
    for name, value in fields.items():
        parts.append(('--%s\r\nContent-Disposition: form-data; name="%s"\r\n\r\n' % (boundary, name)).encode('utf-8'))
        parts.append(value.encode('utf-8') + b'\r\n')
    with open(file_path, 'rb') as f:
        data = f.read()
    parts.append(('--%s\r\nContent-Disposition: form-data; name="%s"; filename="%s"\r\n'
                  'Content-Type: application/zip\r\n\r\n' % (boundary, file_field, os.path.basename(file_path))).encode('utf-8'))
    parts.append(data + b'\r\n')
    parts.append(('--%s--\r\n' % boundary).encode('utf-8'))
    return b''.join(parts), 'multipart/form-data; boundary=' + boundary


def main(argv):
    if len(argv) < 3:
        print('Usage : python outils/wowinterface.py vX.Y.Z archive.zip [notes.md]')
        return 1
    tag, archive = argv[1], argv[2]
    notes_path = argv[3] if len(argv) > 3 else os.path.join(ROOT, 'RELEASE.md')
    token = os.environ.get('WOWI_API_TOKEN', '').strip()
    if not token:
        print('WoWInterface : pas de jeton (WOWI_API_TOKEN), rien envoyé.')
        return 0
    if not os.path.isfile(archive):
        print('WoWInterface : archive introuvable : %s' % archive)
        return 1
    addon, interfaces = toc_values()
    if not addon or not interfaces:
        print('WoWInterface : ## X-WoWI-ID ou ## Interface absent de Lyorune.toc.')
        return 1
    try:
        games = compatible(interfaces)
    except (urllib.error.URLError, ValueError, OSError) as error:
        print('WoWInterface : liste des versions du jeu illisible (%s).' % error)
        return 1
    if not games:
        print('WoWInterface : aucune version du jeu pour l\'interface %s dans %s.' % (', '.join(interfaces), VERSIONS_URL))
        return 1
    fields = {'id': addon, 'version': tag.lstrip('v'), 'compatible': games}
    if os.path.isfile(notes_path):
        fields['changelog'] = read(notes_path)
    body, kind = multipart(fields, 'updatefile', archive)
    request = urllib.request.Request(UPLOAD_URL, data=body, method='POST', headers={
        'User-Agent': AGENT, 'x-api-token': token, 'Content-Type': kind})
    print('WoWInterface : envoi de %s (%s), addon %s.' % (os.path.basename(archive), games, addon))
    try:
        with urllib.request.urlopen(request, timeout=120) as answer:
            code, text = answer.status, answer.read().decode('utf-8', 'replace')
    except urllib.error.HTTPError as error:
        code, text = error.code, error.read().decode('utf-8', 'replace')
    except (urllib.error.URLError, OSError) as error:
        print('WoWInterface : envoi impossible (%s).' % error)
        return 1
    if code == 202:
        print('WoWInterface : envoyé (202).')
        return 0
    why = {401: 'aucun addon à ce numéro, ou pas le droit d\'envoyer', 403: 'jeton refusé'}.get(code, 'refus')
    print('WoWInterface : %s (%d). %s' % (why, code, text[:500]))
    return 1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
