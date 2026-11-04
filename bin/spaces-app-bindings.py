#!/usr/bin/env python3
"""Back up and restore app assignments using display roles and desktop positions."""

import argparse
import ctypes as c
import json
import plistlib
import subprocess
from pathlib import Path


DEFAULT_BACKUP = Path(__file__).resolve().parent.parent / 'spaces-app-bindings.json'


def bind(library, name, arguments, result):
    function = getattr(library, name)
    function.argtypes, function.restype = arguments, result
    return function


cf = c.CDLL('/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation')
CFRelease = bind(cf, 'CFRelease', [c.c_void_p], None)
CFPropertyListCreateData = bind(
    cf, 'CFPropertyListCreateData',
    [c.c_void_p, c.c_void_p, c.c_long, c.c_ulong, c.c_void_p], c.c_void_p)
CFDataGetLength = bind(cf, 'CFDataGetLength', [c.c_void_p], c.c_long)
CFDataGetBytePtr = bind(cf, 'CFDataGetBytePtr', [c.c_void_p], c.c_void_p)
CFUUIDCreateString = bind(cf, 'CFUUIDCreateString', [c.c_void_p, c.c_void_p], c.c_void_p)


def live_displays():
    """Read WindowServer: saved preferences can include disconnected monitors.

    SkyLight is private API; fail without writing if it becomes unavailable.
    Identify the main display by UUID rather than relying on array order.
    """
    cg = c.CDLL('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
    sky = c.CDLL('/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight')

    connection = bind(sky, 'CGSMainConnectionID', [], c.c_uint32)
    copy_spaces = bind(sky, 'CGSCopyManagedDisplaySpaces', [c.c_uint32], c.c_void_p)
    main_display = bind(cg, 'CGMainDisplayID', [], c.c_uint32)
    display_uuid = bind(sky, 'CGDisplayCreateUUIDFromDisplayID', [c.c_uint32], c.c_void_p)

    def read_plist(value):
        if not value:
            raise ValueError('Cannot read live display layout; run in a logged-in desktop session.')
        data = None
        try:
            data = CFPropertyListCreateData(None, value, 100, 0, None)
            if not data:
                raise ValueError('Cannot decode live display layout.')
            return plistlib.loads(c.string_at(CFDataGetBytePtr(data), CFDataGetLength(data)))
        finally:
            if data:
                CFRelease(data)
            CFRelease(value)

    uuid = display_uuid(main_display())
    if not uuid:
        raise ValueError('Cannot identify the active main display.')
    try:
        main_identifier = read_plist(CFUUIDCreateString(None, uuid))
    finally:
        CFRelease(uuid)
    return displays(read_plist(copy_spaces(connection())), main_identifier)


def displays(monitors, main_identifier):
    active = [m for m in monitors if m.get('Spaces')]
    main = [m for m in active if m['Display Identifier'] in ('Main', main_identifier)]
    secondary = [m for m in active if m not in main]
    if len(main) != 1:
        raise ValueError('Cannot identify the main display in the live Spaces layout.')
    return {'main': main, 'secondary': secondary}


def desktops(display):
    return [s for s in display['Spaces'] if s.get('type') == 0]


def resolve(roles, assignments):
    """Validate every target before producing a dictionary to write."""
    result = {}
    for app, target in assignments.items():
        if not isinstance(app, str) or not app:
            raise ValueError('App identifiers must be nonempty strings.')
        if target == 'all':
            result[app] = 'AllSpaces'
            continue
        if (not isinstance(target, dict) or not {'display', 'desktop'} <= set(target)
                or set(target) - {'display', 'desktop', 'single_desktop'}):
            raise ValueError(f'{app}: expected display and desktop, or "all".')
        role, index = target['display'], target['desktop']
        if role not in roles or type(index) is not int or index < 1:
            raise ValueError(f'{app}: invalid display role or desktop number.')
        single_index = target.get('single_desktop', index)
        if type(single_index) is not int or single_index < 1:
            raise ValueError(f'{app}: invalid single-monitor desktop number.')
        if not roles['secondary']:
            role, index = 'main', single_index
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


def backup(preferences, roles):
    locations = {}
    for role, monitors in roles.items():
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
        roles = live_displays()
        if args.action == 'backup':
            saved = backup(preferences, roles)
            # Keep the other display mode's assignments when updating a backup.
            previous = json.loads(args.file.read_text()) if args.file.exists() else {}
            if not isinstance(previous, dict):
                raise ValueError('Existing backup must contain an object mapping app identifiers to desktops.')
            for app, target in saved.items():
                old = previous.get(app)
                if isinstance(target, dict) and isinstance(old, dict):
                    if not roles['secondary']:
                        saved[app] = dict(old, single_desktop=target['desktop'])
                    elif 'single_desktop' in old:
                        target['single_desktop'] = old['single_desktop']
            contents = json.dumps(saved, indent=2, sort_keys=True) + '\n'
            if args.dry_run:
                print(contents, end='')
            else:
                args.file.write_text(contents)
                print(f'Saved assignments to {args.file}')
            return
        assignments = json.loads(args.file.read_text())
        if not isinstance(assignments, dict):
            raise ValueError('Backup must contain an object mapping app identifiers to desktops.')
        resolved = resolve(roles, assignments)
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
    except (AttributeError, ValueError, KeyError, TypeError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    main()
