"""Regression tests; no macOS preference writes or Dock restarts."""
import importlib.util
import json
from pathlib import Path
import plistlib
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'bin' / 'spaces-app-bindings.py'
if not SCRIPT.exists():
    SCRIPT = Path(__file__).with_name('spaces-app-bindings.py')
spec = importlib.util.spec_from_file_location('bindings', SCRIPT)
bindings = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bindings)


def monitor(identifier, prefix, count=5):
    return {'Display Identifier': identifier,
            'Spaces': [{'uuid': f'{prefix}{i}', 'type': 0} for i in range(1, count + 1)]}


class AssignmentsTest(unittest.TestCase):
    def setUp(self):
        self.main = monitor('external', 'ext')
        self.laptop = monitor('laptop', 'lap')
        self.dual = bindings.displays([self.laptop, self.main], 'external')
        self.single = bindings.displays([self.laptop], 'laptop')
        self.apps = {
            'browser': {'display': 'main', 'desktop': 2},
            'codex': {'display': 'secondary', 'desktop': 1, 'single_desktop': 3},
            'chrome': {'display': 'main', 'desktop': 5},
            'everywhere': 'all',
        }

    def test_dual_uses_main_uuid_not_array_order(self):
        self.assertEqual(bindings.resolve(self.dual, self.apps),
                         {'browser': 'ext2', 'codex': 'lap1', 'chrome': 'ext5',
                          'everywhere': 'AllSpaces'})

    def test_single_remaps_all_apps_to_live_desktops(self):
        self.assertEqual(bindings.resolve(self.single, self.apps),
                         {'browser': 'lap2', 'codex': 'lap3', 'chrome': 'lap5',
                          'everywhere': 'AllSpaces'})

    def test_fullscreen_is_not_a_numbered_desktop(self):
        self.laptop['Spaces'].insert(0, {'uuid': 'fullscreen', 'type': 4})
        self.assertEqual(bindings.resolve(self.single, self.apps)['codex'], 'lap3')

    def test_empty_first_uuid_and_main_alias(self):
        self.laptop['Display Identifier'] = 'Main'
        self.laptop['Spaces'][0]['uuid'] = ''
        roles = bindings.displays([self.laptop], 'laptop')
        self.assertEqual(bindings.resolve(roles, {'terminal': {'display': 'main', 'desktop': 1}}),
                         {'terminal': ''})

    def run_main(self, args, roles, path, preferences):
        with patch.object(sys, 'argv', ['spaces-app-bindings', *args, '--file', str(path)]), \
             patch.object(bindings, 'live_displays', return_value=roles), \
             patch.object(bindings.subprocess, 'check_output', return_value=plistlib.dumps(preferences)), \
             patch.object(bindings, 'move_windows') as move, \
             patch.object(bindings.subprocess, 'run') as run:
            bindings.main()
            if args[0] == 'restore':
                move.assert_called_once_with(roles, bindings.resolve(roles, json.loads(path.read_text())),
                                             **({'dry_run': True} if '--dry-run' in args else {}))
            else:
                move.assert_not_called()
            return run

    def test_restore_ignores_stale_saved_monitor_layout_and_merges(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'apps.json'
            path.write_text(json.dumps(self.apps))
            prefs = {'SpacesDisplayConfiguration': {'Management Data': {'Monitors': [self.main]}},
                     'app-bindings': {'unrelated': 'keep'}}
            run = self.run_main(['restore'], self.single, path, prefs)
            command = run.call_args_list[0].args[0]
            self.assertEqual(dict(zip(command[5::2], command[6::2])),
                             dict(bindings.resolve(self.single, self.apps), unrelated='keep'))
            self.assertEqual(run.call_args_list[1].args[0], ['/usr/bin/killall', 'Dock'])

    def test_matching_assignments_skip_write_but_still_move_windows(self):
        for roles in (self.single, self.dual):
            with self.subTest(roles=roles), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / 'apps.json'
                path.write_text(json.dumps(self.apps))
                current = dict(bindings.resolve(roles, self.apps), unrelated='keep')
                run = self.run_main(['restore'], roles, path, {'app-bindings': current})
                run.assert_not_called()

    def test_missing_empty_uuid_is_not_already_assigned(self):
        self.laptop['Spaces'][0]['uuid'] = ''
        apps = {'terminal': {'display': 'main', 'desktop': 1}}
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'apps.json'
            path.write_text(json.dumps(apps))
            run = self.run_main(['restore'], self.single, path, {'app-bindings': {}})
            self.assertEqual(run.call_count, 2)
            self.assertEqual(run.call_args_list[0].args[0][-2:], ['terminal', ''])
            run = self.run_main(['restore'], self.single, path,
                                {'app-bindings': {'terminal': ''}})
            run.assert_not_called()

    def test_changed_assignment_still_writes_and_restarts(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'apps.json'
            path.write_text(json.dumps(self.apps))
            current = bindings.resolve(self.single, self.apps)
            current['browser'] = 'wrong-space'
            run = self.run_main(['restore'], self.single, path, {'app-bindings': current})
            self.assertEqual(run.call_count, 2)
            self.assertEqual(run.call_args_list[1].args[0], ['/usr/bin/killall', 'Dock'])

    def test_dry_run_plans_window_moves_without_writing(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'apps.json'
            path.write_text(json.dumps(self.apps))
            run = self.run_main(['restore', '--dry-run'], self.single, path, {})
            run.assert_not_called()

    def test_missing_desktop_fails_before_any_write(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'apps.json'
            path.write_text(json.dumps(self.apps))
            roles = bindings.displays([monitor('laptop', 'lap', 1)], 'laptop')
            with patch.object(bindings.subprocess, 'run') as run:
                with self.assertRaises(ValueError):
                    bindings.resolve(roles, self.apps)
                run.assert_not_called()

    def test_backup_retains_other_mode(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'apps.json'
            path.write_text(json.dumps(self.apps))
            self.run_main(['backup'], self.single, path,
                          {'app-bindings': bindings.resolve(self.single, self.apps)})
            saved = json.loads(path.read_text())
            self.assertEqual(saved['codex'], self.apps['codex'])
            self.assertEqual(bindings.resolve(self.dual, saved), bindings.resolve(self.dual, self.apps))
            self.run_main(['backup'], self.dual, path,
                          {'app-bindings': bindings.resolve(self.dual, saved)})
            self.assertEqual(json.loads(path.read_text())['codex']['single_desktop'], 3)

    def test_ambiguous_secondary_and_invalid_override_fail(self):
        roles = bindings.displays([self.main, self.laptop, monitor('third', 'third')], 'external')
        with self.assertRaises(ValueError):
            bindings.resolve(roles, self.apps)
        self.apps['codex']['single_desktop'] = True
        with self.assertRaises(ValueError):
            bindings.resolve(self.single, self.apps)


if __name__ == '__main__':
    unittest.main()
