#!/usr/bin/env bash
set -euo pipefail

REFERENCE="@quiet-pytest.md"

usage() {
    cat <<'USAGE'
Usage: uninstall.sh [options]

Remove Quiet Pytest and its Codex/Claude global references.

Options:
  --prefix DIR           Remove command from DIR/bin (default: ~/.local)
  --bin-dir DIR          Remove command from DIR instead of PREFIX/bin
  --system               Remove command from /usr/local/bin
  --no-agent-config      Do not update ~/.codex/AGENTS.md or ~/.claude/CLAUDE.md
  --no-skills            Do not remove Codex/Claude skill directories
  -h, --help             Show this help

Environment:
  QUIET_PYTEST_HOME      Home directory whose agent config should be updated
  CLAUDE_HOME            Claude config directory (default: $HOME/.claude)
  CODEX_HOME             Codex config directory (default: $HOME/.codex)
  PREFIX                 Install prefix (default: ~/.local)
USAGE
}

target_home() {
    if [ -n "${QUIET_PYTEST_HOME:-}" ]; then
        printf '%s\n' "$QUIET_PYTEST_HOME"
        return
    fi

    if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        eval "printf '%s\n' ~${SUDO_USER}"
        return
    fi

    printf '%s\n' "${HOME:?HOME is not set}"
}

TARGET_HOME="$(target_home)"
PREFIX="${PREFIX:-$TARGET_HOME/.local}"
BIN_DIR="${QUIET_PYTEST_BIN_DIR:-$PREFIX/bin}"
SHARE_DIR="${QUIET_PYTEST_SHARE_DIR:-$PREFIX/share/quiet-pytest}"
CLAUDE_HOME="${CLAUDE_HOME:-$TARGET_HOME/.claude}"
CODEX_HOME="${CODEX_HOME:-$TARGET_HOME/.codex}"
CONFIG_AGENTS="${QUIET_PYTEST_CONFIG_AGENTS:-1}"
INSTALL_SKILLS="${QUIET_PYTEST_INSTALL_SKILLS:-1}"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --prefix)
            PREFIX="${2:?--prefix requires a directory}"
            BIN_DIR="${QUIET_PYTEST_BIN_DIR:-$PREFIX/bin}"
            SHARE_DIR="${QUIET_PYTEST_SHARE_DIR:-$PREFIX/share/quiet-pytest}"
            shift 2
            ;;
        --bin-dir)
            BIN_DIR="${2:?--bin-dir requires a directory}"
            shift 2
            ;;
        --system)
            PREFIX="/usr/local"
            BIN_DIR="${QUIET_PYTEST_BIN_DIR:-/usr/local/bin}"
            SHARE_DIR="${QUIET_PYTEST_SHARE_DIR:-/usr/local/share/quiet-pytest}"
            shift
            ;;
        --no-agent-config)
            CONFIG_AGENTS=0
            shift
            ;;
        --no-skills)
            INSTALL_SKILLS=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

remove_reference() {
    local file="$1"
    local tmp

    [ -f "$file" ] || return 0
    tmp="$(mktemp)"
    grep -Fxv "$REFERENCE" "$file" > "$tmp" || true
    cat "$tmp" > "$file"
    rm -f "$tmp"
}

remove_command() {
    local path="$1"

    [ -e "$path" ] || return 0

    if [ -L "$path" ]; then
        rm -f "$path"
        return
    fi

    if [ -f "$path" ] \
        && grep -q 'Run a test command; print only the summary line' "$path" \
        && grep -q 'pytest_cov' "$path"; then
        rm -f "$path"
        return
    fi

    printf 'Skipped %s because it does not look like Quiet Pytest.\n' "$path" >&2
}

remove_command "$BIN_DIR/quiet-pytest"
rm -rf "$SHARE_DIR"

if [ "$CONFIG_AGENTS" = "1" ]; then
    remove_reference "$CLAUDE_HOME/CLAUDE.md"
    remove_reference "$CODEX_HOME/AGENTS.md"
    rm -f "$CLAUDE_HOME/quiet-pytest.md" "$CODEX_HOME/quiet-pytest.md"
fi

if [ "$INSTALL_SKILLS" = "1" ]; then
    rm -rf "$CODEX_HOME/skills/quiet-pytest" "$CLAUDE_HOME/skills/quiet-pytest"
fi

cat <<EOF
Quiet Pytest uninstalled.

  Command removed from: $BIN_DIR/quiet-pytest
  Instructions removed from: $SHARE_DIR
  Claude/Codex references removed when present.
EOF
