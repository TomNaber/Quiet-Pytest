# Quiet Pytest

Quiet Pytest is a tiny pytest wrapper for coding agents.

> In development, tests passing is not an event deserving attention. Them failing is.

`pytest -q` is not actually quiet. It still prints progress for each test, and that output quickly adds up when every agent task runs tests repeatedly. Similar to how RTK filters commands like `grep` and `ls`, Quiet Pytest only presents the information required for tests: one summary line on success, full output on failure.

## What It Does

- Runs `pytest` through a small Bash wrapper.
- Prints only the final pytest summary line when tests pass.
- Prints full pytest output when tests fail.
- Uses `./.venv/bin/python -m pytest -q --tb=short` by default when a local venv exists.
- Adds `--no-cov` automatically for no-argument runs when `pytest-cov` is installed.
- Installs global instruction references for both Codex and Claude Code.

The wrapper intentionally stays minimal. Agent behavior lives in `quiet-pytest.md`, which `AGENTS.md` and `CLAUDE.md` reference the same way RTK installs `RTK.md`.

## Install

User-wide install, recommended for most people:

```bash
curl -fsSL https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main/install.sh | bash
```

System command install in `/usr/local/bin`:

```bash
curl -fsSL https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main/install.sh | sudo bash -s -- --system
```

From a local checkout:

```bash
./install.sh
```

The installer:

- installs `quiet-pytest` into `~/.local/bin` by default;
- installs `quiet-pytest.md` into `~/.codex/` and `~/.claude/`;
- appends `@quiet-pytest.md` to `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`;
- installs optional lightweight skill directories for Codex and Claude.

If `~/.local/bin` is not on `PATH`, either add it or use the `--system` install.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main/uninstall.sh | bash
```

For a system install:

```bash
curl -fsSL https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main/uninstall.sh | sudo bash -s -- --system
```

From a local checkout:

```bash
./uninstall.sh
```

## Usage

Run a full suite:

```bash
quiet-pytest
```

Run a targeted test:

```bash
quiet-pytest python3 -m pytest tests/test_api.py --no-cov
```

In repositories that require RTK-prefixed commands:

```bash
rtk quiet-pytest python3 -m pytest tests/test_api.py --no-cov
```

## Examples

`AGENTS.md`:

```md
@quiet-pytest.md
```

`CLAUDE.md`:

```md
@quiet-pytest.md
```

Successful run:

```text
8 passed in 0.34s
```

Failed run:

```text
full pytest output, including traceback and short summary
```

## Token Savings

Measured on this repository's passing suite with `tiktoken` `cl100k_base`:

```text
pytest -q --tb=short: 15 tokens
quiet-pytest:         9 tokens
saved:                6 tokens (40.0%)
```

This repo only has four tests, so the absolute number is small. The savings grow with every progress line, every repeated successful run, and every task where the agent needs tests only as a pass/fail signal.

## Repository Layout

```text
quiet-pytest/
  SKILL.md                 optional Codex/Claude skill
  quiet-pytest             Bash wrapper
  agents/openai.yaml       optional OpenAI skill manifest
install.sh                 automated install
uninstall.sh               automated uninstall
quiet-pytest.md            shared agent instructions
tests/                     wrapper and installer tests
examples/                  minimal agent config examples
```

## Development

```bash
uv run --no-project --with pytest python -m pytest tests
```

Or, after installing Quiet Pytest:

```bash
quiet-pytest uv run --no-project --with pytest python -m pytest tests
```
