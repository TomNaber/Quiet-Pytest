#!/usr/bin/env bash
set -euo pipefail

RAW_URL="${QUIET_PYTEST_RAW_URL:-https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main}"
REFERENCE="@quiet-pytest.md"

usage() {
    cat <<'USAGE'
Usage: install.sh [--uninstall]

Installs quiet-pytest to ~/.local/bin and configures Codex/Claude.
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
BIN_DIR="$PREFIX/bin"
SHARE_DIR="$PREFIX/share/quiet-pytest"
CLAUDE_HOME="${CLAUDE_HOME:-$TARGET_HOME/.claude}"
CODEX_HOME="${CODEX_HOME:-$TARGET_HOME/.codex}"
UNINSTALL=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --uninstall)
            UNINSTALL=1
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

if [ "$UNINSTALL" = "1" ]; then
    remove_command "$BIN_DIR/quiet-pytest"
    rm -rf "$SHARE_DIR"
    remove_reference "$CLAUDE_HOME/CLAUDE.md"
    remove_reference "$CODEX_HOME/AGENTS.md"
    rm -f "$CLAUDE_HOME/quiet-pytest.md" "$CODEX_HOME/quiet-pytest.md"
    rm -rf "$CODEX_HOME/skills/quiet-pytest" "$CLAUDE_HOME/skills/quiet-pytest"
    printf 'Quiet Pytest uninstalled.\n'
    exit 0
fi

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

install -d "$CLAUDE_HOME" "$CODEX_HOME"
install -m 644 "$tmp_dir/quiet-pytest.md" "$CLAUDE_HOME/quiet-pytest.md"
install -m 644 "$tmp_dir/quiet-pytest.md" "$CODEX_HOME/quiet-pytest.md"
add_reference "$CLAUDE_HOME/CLAUDE.md"
add_reference "$CODEX_HOME/AGENTS.md"
install_skill "$CODEX_HOME/skills/quiet-pytest" "$tmp_dir"
install_skill "$CLAUDE_HOME/skills/quiet-pytest" "$tmp_dir"

cat <<EOF
Quiet Pytest installed.

  Command:       $BIN_DIR/quiet-pytest
  Instructions:  $SHARE_DIR/quiet-pytest.md
  Agent ref:     $REFERENCE

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
