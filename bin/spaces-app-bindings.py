#!/usr/bin/env python3
"""Back up and restore app assignments using display roles and desktop positions."""

import argparse
import json
import plistlib
import subprocess
from pathlib import Path


DEFAULT_BACKUP = Path(__file__).resolve().parent.parent / 'spaces-app-bindings.json'


def displays(preferences):
    monitors = preferences['SpacesDisplayConfiguration']['Management Data']['Monitors']
    active = [m for m in monitors if m.get('Spaces')]
    main = [m for m in active if m['Display Identifier'] == 'Main']
    secondary = [m for m in active if m['Display Identifier'] != 'Main']
    if len(main) != 1:
        raise ValueError('Cannot identify the main display in Spaces preferences.')
    return {'main': main, 'secondary': secondary}


def desktops(display):
    return [s for s in display['Spaces'] if s.get('type') == 0]


def resolve(preferences, assignments):
    """Validate every target before producing a dictionary to write."""
    roles = displays(preferences)
    result = {}
    for app, target in assignments.items():
        if not isinstance(app, str) or not app:
            raise ValueError('App identifiers must be nonempty strings.')
        if target == 'all':
            result[app] = 'AllSpaces'
            continue
        if not isinstance(target, dict) or set(target) != {'display', 'desktop'}:
            raise ValueError(f'{app}: expected display and desktop, or "all".')
        role, index = target['display'], target['desktop']
        if role not in roles or type(index) is not int or index < 1:
            raise ValueError(f'{app}: invalid display role or desktop number.')
        candidates = roles[role]
        if len(candidates) != 1:
            raise ValueError(f'{app}: expected one {role} display, found {len(candidates)}. '
                             'Connect the intended display and disconnect extra displays.')
        spaces = desktops(candidates[0])
        if index > len(spaces):
            raise ValueError(f'{app}: {role} desktop {index} does not exist '
                             f'(found {len(spaces)}). Create the desktop in Mission Control first.')
        result[app] = spaces[index - 1]['uuid']
    return result


def backup(preferences):
    locations = {}
    for role, monitors in displays(preferences).items():
        if len(monitors) != 1:
            continue
        for index, space in enumerate(desktops(monitors[0]), 1):
            uuid = space['uuid']
            if uuid in locations:
                raise ValueError('Duplicate desktop identifiers; cannot back up unambiguously.')
            locations[uuid] = {'display': role, 'desktop': index}
    result = {}
    for app, uuid in preferences.get('app-bindings', {}).items():
        if uuid == 'AllSpaces':
            result[app] = 'all'
        elif uuid in locations:
            result[app] = locations[uuid]
        else:
            raise ValueError(f'{app}: assigned desktop is unavailable or its display is ambiguous.')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['backup', 'restore'])
    parser.add_argument('--file', type=Path, default=DEFAULT_BACKUP)
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    try:
        preferences = plistlib.loads(subprocess.check_output(
            ['/usr/bin/defaults', 'export', 'com.apple.spaces', '-']))
        if args.action == 'backup':
            contents = json.dumps(backup(preferences), indent=2, sort_keys=True) + '\n'
            if args.dry_run:
                print(contents, end='')
            else:
                args.file.write_text(contents)
                print(f'Saved assignments to {args.file}')
            return
        assignments = json.loads(args.file.read_text())
        if not isinstance(assignments, dict):
            raise ValueError('Backup must contain an object mapping app identifiers to desktops.')
        resolved = resolve(preferences, assignments)
        for app, uuid in sorted(resolved.items()):
            print(f'{app}: {assignments[app]} -> {uuid!r}')
        if args.dry_run or not resolved:
            return
        # Merge so apps absent from the backup keep their current assignments.
        merged = dict(preferences.get('app-bindings', {}), **resolved)
        command = ['/usr/bin/defaults', 'write', 'com.apple.spaces', 'app-bindings', '-dict']
        for app, uuid in sorted(merged.items()):
            command.extend([app, uuid])
        subprocess.run(command, check=True)
        subprocess.run(['/usr/bin/killall', 'Dock'], check=False)
    except (ValueError, KeyError, TypeError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    main()
