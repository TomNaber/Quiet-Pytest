# Quiet Pytest

Minimal pytest output for coding agents.

> In development, tests passing is not an event deserving attention. Them failing is.

`pytest -q` is not actually quiet: it still prints progress for each test item, which adds up with tests in a single repo easily reaching triple digits and pytest calls being done almost after every prompt. Quiet Pytest prints one summary line when tests pass and full pytest output when tests fail.

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
| Representative Repo (coverage) | 303 | 3,416 tokens | 15 tokens | 99.6% |

The representative repo used is a real project with output tokens measured from `pytest -q --tb=short` with its default coverage report enabled. A 300-test passing run is about 3,416 tokens raw, 15 tokens quiet, so 3,401 tokens saved each run.

In a representative coding session, the AI ran pytest 15 times: 6 focused runs and 9 full-suite runs. Based on the runs in that session, the measured savings were about 20,500 tokens: six full-suite coverage runs at about ~3,400 tokens saved each, plus nine focused runs at about 7 tokens saved each.

That session used about 911,000 active tokens, counting uncached input plus output. The pytest savings were about 2.3% of that active token load, saved consistently across normal development sessions. Expect a small but consistent saving for Python development.

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
