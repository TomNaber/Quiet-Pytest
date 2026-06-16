#!/usr/bin/env bash
set -euo pipefail

RAW_URL="${QUIET_PYTEST_RAW_URL:-https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main}"
REFERENCE="@quiet-pytest.md"

usage() {
    cat <<'USAGE'
Usage: install.sh [options]

Install Quiet Pytest globally for the current user and configure Codex/Claude.

Options:
  --prefix DIR           Install command under DIR/bin (default: ~/.local)
  --bin-dir DIR          Install command in DIR instead of PREFIX/bin
  --system               Install command in /usr/local/bin
  --no-agent-config      Do not update ~/.codex/AGENTS.md or ~/.claude/CLAUDE.md
  --no-skills            Do not install Codex/Claude skill directories
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

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR=""
if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
fi

fetch_asset() {
    local rel="$1"
    local dest="$2"

    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$rel" ]; then
        cp "$SCRIPT_DIR/$rel" "$dest"
        return
    fi

    if ! command -v curl >/dev/null 2>&1; then
        printf 'curl is required when install.sh is run remotely.\n' >&2
        exit 1
    fi

    curl -fsSL "$RAW_URL/$rel" -o "$dest"
}

add_reference() {
    local file="$1"

    mkdir -p "$(dirname "$file")"
    if [ ! -f "$file" ]; then
        : > "$file"
    fi

    if grep -Fxq "$REFERENCE" "$file"; then
        return
    fi

    if [ -s "$file" ]; then
        printf '\n%s\n' "$REFERENCE" >> "$file"
    else
        printf '%s\n' "$REFERENCE" >> "$file"
    fi
}

install_skill() {
    local skill_dir="$1"
    local tmp="$2"

    install -d "$skill_dir" "$skill_dir/agents"
    install -m 644 "$tmp/SKILL.md" "$skill_dir/SKILL.md"
    install -m 755 "$tmp/quiet-pytest" "$skill_dir/quiet-pytest"
    install -m 644 "$tmp/openai.yaml" "$skill_dir/agents/openai.yaml"
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fetch_asset "quiet-pytest/quiet-pytest" "$tmp_dir/quiet-pytest"
fetch_asset "quiet-pytest/SKILL.md" "$tmp_dir/SKILL.md"
fetch_asset "quiet-pytest/agents/openai.yaml" "$tmp_dir/openai.yaml"
fetch_asset "quiet-pytest.md" "$tmp_dir/quiet-pytest.md"

install -d "$BIN_DIR" "$SHARE_DIR"
install -m 755 "$tmp_dir/quiet-pytest" "$BIN_DIR/quiet-pytest"
install -m 644 "$tmp_dir/quiet-pytest.md" "$SHARE_DIR/quiet-pytest.md"

if [ "$CONFIG_AGENTS" = "1" ]; then
    install -d "$CLAUDE_HOME" "$CODEX_HOME"
    install -m 644 "$tmp_dir/quiet-pytest.md" "$CLAUDE_HOME/quiet-pytest.md"
    install -m 644 "$tmp_dir/quiet-pytest.md" "$CODEX_HOME/quiet-pytest.md"
    add_reference "$CLAUDE_HOME/CLAUDE.md"
    add_reference "$CODEX_HOME/AGENTS.md"
fi

if [ "$INSTALL_SKILLS" = "1" ]; then
    install_skill "$CODEX_HOME/skills/quiet-pytest" "$tmp_dir"
    install_skill "$CLAUDE_HOME/skills/quiet-pytest" "$tmp_dir"
fi

cat <<EOF
Quiet Pytest installed.

  Command:       $BIN_DIR/quiet-pytest
  Instructions:  $SHARE_DIR/quiet-pytest.md
  Claude ref:    $CLAUDE_HOME/CLAUDE.md -> $REFERENCE
  Codex ref:     $CODEX_HOME/AGENTS.md -> $REFERENCE

Restart Codex or Claude Code so they reload global instructions.
EOF

case ":${PATH:-}:" in
    *":$BIN_DIR:"*) ;;
    *)
        cat <<EOF

Note: $BIN_DIR is not on PATH for this shell.
Add it to PATH or install with --system.
EOF
        ;;
esac
