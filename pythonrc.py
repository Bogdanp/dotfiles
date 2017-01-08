import os
import pprint
import readline
import rlcompleter  # noqa
import sys

from code import InteractiveConsole
from tempfile import mkstemp

readline.parse_and_bind("tab: complete")

EDITOR = "emacsclient"
EDITOR_COMMAND = r"\e"


class REPL(InteractiveConsole):
    def __init__(self, *args, **kwargs):
        self.last_buffer = []
        InteractiveConsole.__init__(self, *args, **kwargs)

    def runsource(self, source, *args, **kwargs):
        self.last_buffer = [source.encode("utf-8")]
        return InteractiveConsole.runsource(self, source, *args, **kwargs)

    def raw_input(self, *args, **kwargs):
        line = InteractiveConsole.raw_input(self, *args, **kwargs)
        if line == EDITOR_COMMAND:
            fd, filename = mkstemp(".py")

            os.write(fd, b"\n".join(self.last_buffer))
            os.close(fd)
            os.system("%s %s" % (EDITOR, filename))

            with open(filename) as f:
                lines = f.readlines()
                if not lines:
                    return ""

                for i, line in enumerate(lines):
                    if i == len(lines) - 1:
                        break

                    self.push(line)

            os.unlink(filename)

        return line


def displayhook(value):
    if value is not None:
        try:
            import __builtin__

            __builtin__._ = value
        except ImportError:
            __builtins__._ = value

        pprint.pprint(value)


sys.ps1 = "\033[0;34m>>> \033[0m"
sys.ps2 = "\033[1;34m... \033[0m"
sys.displayhook = displayhook

c = REPL(locals=locals())
sys.exit(c.interact(banner=""))
