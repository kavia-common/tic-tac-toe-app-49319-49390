#!/usr/bin/env bash
set -euo pipefail
# dependencies step: create/validate .venv, install requirements, ensure pytest when required
DEFAULT_WS="/home/kavia/workspace/code-generation/tic-tac-toe-app-49319-49390/TicTacToeApplication(InternalContainer)"
WORKSPACE_PATH="${WORKSPACE_PATH:-$DEFAULT_WS}"
cd "$WORKSPACE_PATH"
VENV_DIR="$WORKSPACE_PATH/.venv"
REQUIRED_TEST_RUNNER="${REQUIRED_TEST_RUNNER:-}"
PIP_LOG="/tmp/pip_install_$(basename "$WORKSPACE_PATH").log"
# helper to check venv integrity
check_venv() {
  [ -x "$VENV_DIR/bin/python" ] && [ -x "$VENV_DIR/bin/pip" ] && "$VENV_DIR/bin/python" -c 'import sys' >/dev/null 2>&1
}
# create workspace if missing
mkdir -p "$WORKSPACE_PATH"
# create or repair venv
if ! check_venv; then
  rm -rf "$VENV_DIR" || true
  command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found" >&2; exit 2; }
  python3 -m venv "$VENV_DIR"
fi
if ! check_venv; then echo "ERROR: failed to create functional venv" >&2; exit 3; fi
VENV_PY="$VENV_DIR/bin/python"
VENV_PIP="$VENV_DIR/bin/pip"
# upgrade pip non-verbosely
"$VENV_PY" -m pip install --upgrade pip --disable-pip-version-check >"$PIP_LOG" 2>&1 || { tail -n +1 "$PIP_LOG" >&2; echo "ERROR: pip upgrade failed" >&2; exit 4; }
# install requirements if present and non-empty
if [ -s requirements.txt ]; then
  "$VENV_PY" -m pip install --no-cache-dir -r requirements.txt >>"$PIP_LOG" 2>&1 || { tail -n 200 "$PIP_LOG" >&2; echo "ERROR: failed to install requirements.txt" >&2; exit 5; }
fi
# Determine if pytest is required
WANT_PYTEST=0
if grep -qiE "^pytest(==|>=|~=|<=|\s|$)" requirements.txt 2>/dev/null || [ "${REQUIRED_TEST_RUNNER:-}" = "pytest" ]; then
  WANT_PYTEST=1
fi
if [ "$WANT_PYTEST" -eq 1 ]; then
  if ! "$VENV_PY" -c "import pytest" >/dev/null 2>&1; then
    "$VENV_PY" -m pip install --no-cache-dir pytest >>"$PIP_LOG" 2>&1 || { tail -n 200 "$PIP_LOG" >&2; echo "ERROR: pytest installation failed and is required" >&2; exit 6; }
  fi
fi
# record installed packages for traceability
"$VENV_PY" -m pip freeze > "$VENV_DIR/requirements-installed.txt" 2>/dev/null || true
# final integrity check
if ! check_venv; then echo "ERROR: venv became invalid after operations" >&2; exit 7; fi
exit 0
