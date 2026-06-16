from __future__ import annotations

import os
import re
import stat
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / "quiet-pytest" / "quiet-pytest"


def run_command(
    args: list[str],
    cwd: Path,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def write_test_file(project: Path, body: str) -> None:
    (project / "tests").mkdir()
    (project / "tests" / "test_sample.py").write_text(body, encoding="utf-8")


def test_success_output_is_only_the_summary_line(tmp_path: Path) -> None:
    write_test_file(
        tmp_path,
        """
def test_one():
    assert 1 == 1


def test_two():
    assert "quiet".upper() == "QUIET"
""".lstrip(),
    )

    result = run_command(
        [str(WRAPPER), sys.executable, "-m", "pytest", "-q", "--tb=short"],
        cwd=tmp_path,
    )

    assert result.returncode == 0
    output = result.stdout.strip()
    assert output.count("\n") == 0
    assert re.fullmatch(r"2 passed in .+", output)
    assert "[100%]" not in output


def test_failure_output_is_preserved(tmp_path: Path) -> None:
    write_test_file(
        tmp_path,
        """
def test_failure():
    assert 1 == 2
""".lstrip(),
    )

    result = run_command(
        [str(WRAPPER), sys.executable, "-m", "pytest", "-q", "--tb=short"],
        cwd=tmp_path,
    )

    assert result.returncode == 1
    assert "FAILED" in result.stdout
    assert "assert 1 == 2" in result.stdout
    assert "short test summary info" in result.stdout


def test_no_args_runs_pytest_in_current_directory(tmp_path: Path) -> None:
    write_test_file(
        tmp_path,
        """
def test_default_invocation():
    assert True
""".lstrip(),
    )

    result = run_command([str(WRAPPER)], cwd=tmp_path)

    assert result.returncode == 0
    assert re.fullmatch(r"1 passed in .+", result.stdout.strip())


def test_install_and_uninstall_are_idempotent(tmp_path: Path) -> None:
    home = tmp_path / "home"
    prefix = tmp_path / "prefix"
    env = os.environ.copy()
    env.update(
        {
            "HOME": str(home),
            "QUIET_PYTEST_HOME": str(home),
            "PREFIX": str(prefix),
            "PATH": os.environ.get("PATH", ""),
        }
    )

    for _ in range(2):
        result = run_command(["bash", str(ROOT / "install.sh")], cwd=ROOT, env=env)
        assert result.returncode == 0, result.stdout

    installed_command = prefix / "bin" / "quiet-pytest"
    assert installed_command.exists()
    assert installed_command.stat().st_mode & stat.S_IXUSR

    codex_agents = home / ".codex" / "AGENTS.md"
    claude_md = home / ".claude" / "CLAUDE.md"
    codex_lines = codex_agents.read_text(encoding="utf-8").splitlines()
    claude_lines = claude_md.read_text(encoding="utf-8").splitlines()
    assert codex_lines.count("@quiet-pytest.md") == 1
    assert claude_lines.count("@quiet-pytest.md") == 1
    assert (home / ".codex" / "quiet-pytest.md").exists()
    assert (home / ".claude" / "quiet-pytest.md").exists()
    assert (home / ".codex" / "skills" / "quiet-pytest" / "SKILL.md").exists()
    assert (home / ".claude" / "skills" / "quiet-pytest" / "SKILL.md").exists()

    for _ in range(2):
        result = run_command(["bash", str(ROOT / "uninstall.sh")], cwd=ROOT, env=env)
        assert result.returncode == 0, result.stdout

    assert not installed_command.exists()
    assert "@quiet-pytest.md" not in codex_agents.read_text(encoding="utf-8")
    assert "@quiet-pytest.md" not in claude_md.read_text(encoding="utf-8")
    assert not (home / ".codex" / "quiet-pytest.md").exists()
    assert not (home / ".claude" / "quiet-pytest.md").exists()
