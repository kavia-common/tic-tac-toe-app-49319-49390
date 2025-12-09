#!/usr/bin/env bash
set -euo pipefail
# Deterministic test runner that creates robust pytest/unittest tests and runs them
DEFAULT_WS="/home/kavia/workspace/code-generation/tic-tac-toe-app-49319-49390/TicTacToeApplication(InternalContainer)"
WORKSPACE_PATH="${WORKSPACE_PATH:-$DEFAULT_WS}"
cd "$WORKSPACE_PATH"
VENV_PY="$WORKSPACE_PATH/.venv/bin/python"
if [ ! -x "$VENV_PY" ]; then echo "ERROR: venv python not available; run deps-01" >&2; exit 3; fi
# pytest test: compute paths via __file__ and sys.executable
cat > "$WORKSPACE_PATH/test_tictactoe_pytest.py" <<'PYT'
import os
import subprocess
import sys

def test_draw():
    here = os.path.dirname(__file__)
    main_py = os.path.join(here, 'main.py')
    moves = b"0\n1\n2\n3\n4\n5\n6\n7\n8\n"
    p = subprocess.run([sys.executable, main_py], input=moves, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out = (p.stdout + p.stderr).decode()
    assert 'draw' in out
PYT
# unittest test
cat > "$WORKSPACE_PATH/test_tictactoe_unittest.py" <<'UT'
import os
import subprocess
import sys
import unittest

class TTTest(unittest.TestCase):
    def test_draw(self):
        here = os.path.dirname(__file__)
        main_py = os.path.join(here, 'main.py')
        moves = b"0\n1\n2\n3\n4\n5\n6\n7\n8\n"
        p = subprocess.run([sys.executable, main_py], input=moves, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out = (p.stdout + p.stderr).decode()
        self.assertIn('draw', out)

if __name__ == '__main__':
    unittest.main()
UT
# export for legacy contexts
export VENV_PY="$VENV_PY"
export WORKSPACE_PATH="$WORKSPACE_PATH"
# choose runner deterministically
if [ -x ".venv/bin/pytest" ]; then
  "$VENV_PY" -m pytest -q || { echo 'pytest run failed' >&2; exit 4; }
else
  "$VENV_PY" -m unittest -v || { echo 'unittest run failed' >&2; exit 5; }
fi
exit 0
