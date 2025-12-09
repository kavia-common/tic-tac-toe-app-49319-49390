#!/usr/bin/env bash
set -euo pipefail
# Scaffold minimal tic-tac-toe project in authoritative workspace
DEFAULT_WS="/home/kavia/workspace/code-generation/tic-tac-toe-app-49319-49390/TicTacToeApplication(InternalContainer)"
WORKSPACE_PATH="${WORKSPACE_PATH:-$DEFAULT_WS}"
mkdir -p "$WORKSPACE_PATH" && cd "$WORKSPACE_PATH"
# Persist PYTHONUNBUFFERED=1 to /etc/profile.d idempotently
PROFILE_FILE="/etc/profile.d/python_unbuffered.sh"
TMPFILE="/tmp/python_unbuffered.$$"
echo "export PYTHONUNBUFFERED=1" > "$TMPFILE"
if [ "$(id -u)" -eq 0 ]; then
  install -m 0644 "$TMPFILE" "$PROFILE_FILE"
else
  sudo install -m 0644 "$TMPFILE" "$PROFILE_FILE"
fi
rm -f "$TMPFILE"
# source for current shell if possible
# shellcheck disable=SC1090
if [ -r "$PROFILE_FILE" ]; then . "$PROFILE_FILE" || true; fi
# Create main.py
cat > "$WORKSPACE_PATH/main.py" <<'PY'
#!/usr/bin/env python3
import sys

def print_board(board):
    for r in range(0, 9, 3):
        print('|'.join(board[r:r+3]))

def check_win(board, player):
    wins = [(0,1,2),(3,4,5),(6,7,8),(0,3,6),(1,4,7),(2,5,8),(0,4,8),(2,4,6)]
    return any(all(board[i]==player for i in combo) for combo in wins)

def main():
    board = [' ']*9
    moves = []
    # read newline-separated moves from stdin
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        moves.append(line)
    player = 'X'
    for m in moves:
        try:
            i = int(m)
        except Exception:
            print('invalid', file=sys.stderr)
            continue
        if i < 0 or i > 8 or board[i] != ' ':
            print('invalid', file=sys.stderr)
            continue
        board[i] = player
        if check_win(board, player):
            print(f'winner:{player}')
            print_board(board)
            return 0
        player = 'O' if player == 'X' else 'X'
    print('draw')
    print_board(board)
    return 0

if __name__ == '__main__':
    rc = main()
    sys.exit(rc)
PY
chmod +x "$WORKSPACE_PATH/main.py"
# Create run.sh: ensures .venv exists and runs app (no pip ops)
cat > "$WORKSPACE_PATH/run.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WD="$(cd "$(dirname "$0")" && pwd)"
VENV="$WD/.venv"
if [ ! -d "$VENV" ]; then python3 -m venv "$VENV"; fi
PYTHON="$VENV/bin/python"
if [ ! -x "$PYTHON" ]; then echo "ERROR: venv python not executable" >&2; exit 4; fi
# Accept MOVES env (newline-separated) or default sequence
if [ -n "${MOVES-}" ]; then
  printf "%s" "$MOVES" | "$PYTHON" "$WD/main.py"
else
  printf "0\n1\n2\n3\n4\n5\n6\n7\n8\n" | "$PYTHON" "$WD/main.py"
fi
SH
chmod +x "$WORKSPACE_PATH/run.sh"
# Empty requirements.txt
: > "$WORKSPACE_PATH/requirements.txt"
# Deterministic Makefile using .venv test runner when present
cat > "$WORKSPACE_PATH/Makefile" <<'MK'
.PHONY: run test
run:
	./run.sh
test:
	if [ -x .venv/bin/pytest ]; then .venv/bin/python -m pytest -q; else .venv/bin/python -m unittest -v; fi
MK
# README
cat > "$WORKSPACE_PATH/README.md" <<'RD'
Minimal Tic-Tac-Toe console app. Use run.sh to run. Workspace path: /home/kavia/workspace/code-generation/tic-tac-toe-app-49319-49390/TicTacToeApplication(InternalContainer). Set MOVES env (newline-separated) to pass custom moves.
RD

# Ensure correct permissions
chmod 644 "$WORKSPACE_PATH/requirements.txt" "$WORKSPACE_PATH/Makefile" "$WORKSPACE_PATH/README.md"
# Final check: list created files
echo "scaffolded:"
ls -la "$WORKSPACE_PATH" | sed -n '1,200p'
