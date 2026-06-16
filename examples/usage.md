# Usage Examples

Full suite:

```bash
quiet-pytest
```

Targeted test:

```bash
quiet-pytest python3 -m pytest tests/test_wrapper.py --no-cov
```

RTK-managed repository:

```bash
rtk quiet-pytest python3 -m pytest tests/test_wrapper.py --no-cov
```
