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
| Candela (coverage) | 303 | 3,416 tokens | 15 tokens | 99.6% |

Candela is a real repository measured from `pytest -q --tb=short` with its default coverage report enabled. A 300-test passing run is roughly the same size: about 3,416 tokens raw, 15 tokens quiet, 3,401 tokens saved each run.

In a representative Candela color-deviation session, Codex ran pytest 22 times: 11 focused runs and 11 full-suite runs. Based on the passing runs in that session, the measured savings were about 20,500 tokens: six full-suite coverage runs at about 3,401 tokens saved each, plus nine focused runs at about 7 tokens saved each.

That session used about 911,000 active tokens, counting uncached input plus output. The pytest savings were about 2.3% of that active token load, saved consistently across normal development sessions without hiding failures.

## How It Works

Quiet Pytest is a wrapper around the test command. The agent calls `quiet-pytest` instead of calling pytest directly. The wrapper captures stdout and stderr, waits for pytest to finish, and then:

- prints only the final summary line when pytest exits successfully;
- prints the full captured output when pytest fails.

With no arguments, it runs:

```bash
./.venv/bin/python -m pytest -q --tb=short
```

It uses `python3` when no local venv exists and adds `--no-cov` automatically for no-argument runs when `pytest-cov` is installed. The token saving happens because only the wrapper's filtered output enters the agent context.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main/install.sh | bash -s -- --uninstall
```
