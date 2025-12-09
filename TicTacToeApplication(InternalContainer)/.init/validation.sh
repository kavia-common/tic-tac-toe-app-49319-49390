#!/usr/bin/env bash
set -euo pipefail
# Validation script for TicTacToe application
DEFAULT_WS="/home/kavia/workspace/code-generation/tic-tac-toe-app-49319-49390/TicTacToeApplication(InternalContainer)"
WORKSPACE_PATH="${WORKSPACE_PATH:-$DEFAULT_WS}"
cd "$WORKSPACE_PATH"
VENV_PY="$WORKSPACE_PATH/.venv/bin/python"
if [ ! -x "$VENV_PY" ]; then echo "ERROR: venv python not executable; run deps-01" >&2; exit 3; fi
# install requirements if any (deps-01 should have done this; keep idempotent verify)
if [ -s requirements.txt ]; then
  "$VENV_PY" -m pip install --no-cache-dir -r requirements.txt >/tmp/pip_validate.log 2>&1 || { tail -n 200 /tmp/pip_validate.log >&2; echo "ERROR: failed to install requirements during validation" >&2; exit 4; }
fi
# run tests (will fail fast)
if "$VENV_PY" -c "import pytest" >/dev/null 2>&1; then
  "$VENV_PY" -m pytest -q || { echo 'ERROR: tests failed' >&2; exit 6; }
else
  "$VENV_PY" -m unittest -v || { echo 'ERROR: unittest failed' >&2; exit 7; }
fi
# Start app non-interactively with timeout to avoid hangs
OUTFILE=$(mktemp /tmp/tictactoe_run.XXXXXX)
trap 'rm -f "$OUTFILE" || true' EXIT
MOVES="0
4
1
3
2
"
TIMEOUT_SECONDS=10
# prefer GNU timeout if available
if command -v timeout >/dev/null 2>&1; then
  timeout "$TIMEOUT_SECONDS" env MOVES="$MOVES" "$WORKSPACE_PATH/run.sh" >"$OUTFILE" 2>&1 || true
else
  # fallback: run in background and kill after timeout
  env MOVES="$MOVES" "$WORKSPACE_PATH/run.sh" >"$OUTFILE" 2>&1 & PID=$!
  ( sleep "$TIMEOUT_SECONDS" && kill -0 "$PID" 2>/dev/null && kill "${PID}" 2>/dev/null ) & KILLER=$!
  wait "$PID" 2>/dev/null || true
  kill -0 "$KILLER" 2>/dev/null && kill "$KILLER" 2>/dev/null || true
fi
# Provide evidence
echo "--- validation output start ---"
cat "$OUTFILE" || true
echo "--- validation output end ---"
# verify expected token
if ! grep -qE 'draw|winner:' "$OUTFILE"; then echo "ERROR: expected outcome token not found in run output" >&2; exit 8; fi
# ensure no lingering processes from this workspace (best-effort)
pkill -f "$WORKSPACE_PATH/main.py" || true
exit 0
