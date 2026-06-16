---
name: quiet-pytest
description: Run Python pytest suites through the quiet-pytest wrapper. Use whenever Codex needs to run tests in Python projects, especially pytest or pytest-cov projects, so successful runs return only the final summary line and failures return full output.
---

# Quiet Pytest

Use the quiet wrapper for test commands.

## Workflow

- Full suite:

  ```bash
  quiet-pytest
  ```

- Targeted test:

  ```bash
  quiet-pytest ./.venv/bin/python -m pytest tests/path/test_file.py --no-cov
  ```

The wrapper prints only the summary line on success and full output on failure. With no arguments it uses `./.venv/bin/python -m pytest -q --tb=short` when available and adds `--no-cov` if `pytest-cov` is installed. In RTK-managed repositories, call it as `rtk quiet-pytest`.
