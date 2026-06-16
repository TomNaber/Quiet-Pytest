# Quiet Pytest

Minimal pytest output for coding agents.

> In development, tests passing is not an event deserving attention. Them failing is.

`pytest -q` is not actually quiet: it still prints progress for each test item. Quiet Pytest prints one summary line when tests pass and full pytest output when tests fail.

## Install

All agents:

```bash
curl -fsSL https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main/install.sh | bash
```

Claude only:

```bash
curl -fsSL https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main/install.sh | bash -s -- --claude
```

Codex only:

```bash
curl -fsSL https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main/install.sh | bash -s -- --codex
```

Installs `quiet-pytest`, `quiet-pytest.md`, and `@quiet-pytest.md` agent references. Restart the agent after installing.

## Usage

```bash
quiet-pytest
quiet-pytest python3 -m pytest tests/test_api.py --no-cov
```

RTK-managed repositories can use:

```bash
rtk quiet-pytest
```

## Savings

Quiet Pytest follows the same idea as RTK command filters: only send information the agent needs.

| Repository | Tests | Raw pytest | Quiet Pytest | Savings |
| --- | ---: | ---: | ---: | ---: |
| Quiet Pytest | 4 | 15 tokens | 9 tokens | 40.0% |
| Candela (coverage) | 303 | 3,416 tokens | 15 tokens | 99.6% |

Candela is a real Python GUI/tooling repo measured from `pytest -q --tb=short` with its default coverage report enabled. A 300-test passing run is roughly the same size: about 3,416 tokens raw, 15 tokens quiet, 3,401 tokens saved each run.

## How It Works

With no arguments, `quiet-pytest` runs:

```bash
./.venv/bin/python -m pytest -q --tb=short
```

It uses `python3` when no local venv exists and adds `--no-cov` automatically for no-argument runs when `pytest-cov` is installed.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main/install.sh | bash -s -- --uninstall
```
