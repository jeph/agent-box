#!/usr/bin/env bash
set -euo pipefail

fallback_term="xterm-256color"

if [ -z "${TERM:-}" ]; then
  export TERM="${fallback_term}"
elif command -v infocmp >/dev/null 2>&1; then
  if ! infocmp "${TERM}" >/dev/null 2>&1; then
    export TERM="${fallback_term}"
  fi
elif [ "${TERM}" = "xterm-ghostty" ]; then
  export TERM="${fallback_term}"
fi

exec "$@"
