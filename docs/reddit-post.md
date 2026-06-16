# Reddit Draft

Title:

```text
I made a tiny pytest wrapper for coding agents: passing tests become one line, failures stay full output
```

Body:

```md
I kept watching coding agents burn context on successful pytest runs.

In development, tests passing is not an event deserving attention. Them failing is.

`pytest -q` is not actually quiet. It still prints progress for each test, and that output adds up quickly because every task runs tests. Quiet Pytest is a tiny Bash wrapper that prints only the final summary line on success, but keeps full pytest output on failure.

It installs a global `quiet-pytest` command and a shared `quiet-pytest.md` instruction file for Codex and Claude Code, referenced from `AGENTS.md` / `CLAUDE.md` the same way RTK references `RTK.md`.

On the repo's own tiny four-test suite, `pytest -q --tb=short` was 15 `cl100k_base` tokens and Quiet Pytest was 9 tokens, saving 40%. The absolute number is small there, but the point is the repeated successful run: passing tests should be a one-line signal.

Install:

```bash
curl -fsSL https://raw.githubusercontent.com/TomNaber/Quiet-Pytest/main/install.sh | bash
```

Usage:

```bash
quiet-pytest
quiet-pytest python3 -m pytest tests/test_api.py --no-cov
```

Repo:
https://github.com/TomNaber/Quiet-Pytest
```
