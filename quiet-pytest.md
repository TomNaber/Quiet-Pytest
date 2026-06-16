# Quiet Pytest

Use `quiet-pytest` for pytest runs.

## Workflow

- Full suite:

  ```bash
  quiet-pytest
  ```

- Targeted test:

  ```bash
  quiet-pytest python3 -m pytest tests/path/test_file.py --no-cov
  ```

- RTK-managed repositories may call it through RTK:

  ```bash
  rtk quiet-pytest python3 -m pytest tests/path/test_file.py --no-cov
  ```

The wrapper prints only the final pytest summary line on success and full output on failure. In pytest-cov projects, include `--no-cov` when passing an explicit pytest command.
