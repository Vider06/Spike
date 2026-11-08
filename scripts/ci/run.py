#!/usr/bin/env python3
"""Repository CI orchestration for Spike.

Keep substantive CI logic here; GitHub workflow YAML should only provision
pinned tools and invoke these checks.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[2]
LOG_DIR = ROOT / "build" / "ci"
MAX_TEXT_FILE_BYTES = 1_000_000
REQUIRED_FILES = (
    ".editorconfig",
    ".gitattributes",
    ".gitignore",
    ".yamllint",
    ".github/workflows/ci.yml",
    ".github/dependabot.yml",
    "alire.toml",
    "scripts/ci/requirements.txt",
    "tests/prove_virtual_memory.adb",
)
ADA_TESTS = (
    "test_machine_state",
    "test_virtual_memory",
    "test_vm_instructions",
    "prove_virtual_memory",
)
SPARK_UNITS = (
    "machine_state.adb",
    "vm_instructions.adb",
    "prove_virtual_memory.adb",
)


class CIError(RuntimeError):
    """Raised when a CI gate detects a failure."""


def execute(
    label: str,
    command: list[str],
    *,
    log_name: str | None = None,
    env: dict[str, str] | None = None,
) -> None:
    """Run a command while streaming and optionally preserving its output."""
    print(f"\n## {label}\n$ {' '.join(command)}", flush=True)
    log_file = None
    if log_name:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        log_file = (LOG_DIR / log_name).open("w", encoding="utf-8")

    try:
        process = subprocess.Popen(
            command,
            cwd=ROOT,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
        )
        assert process.stdout is not None
        for line in process.stdout:
            print(line, end="", flush=True)
            if log_file:
                log_file.write(line)
        return_code = process.wait()
    except FileNotFoundError as error:
        raise CIError(f"Required command not found: {command[0]}") from error
    finally:
        if log_file:
            log_file.close()

    if return_code != 0:
        raise CIError(f"{label} failed with exit code {return_code}")


def tracked_paths() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    return [
        ROOT / os.fsdecode(item)
        for item in result.stdout.split(b"\0")
        if item
    ]


def inspect_text_file(relative_path: str, content: bytes) -> list[str]:
    """Return deterministic hygiene findings for one tracked text file."""
    findings: list[str] = []
    if len(content) > MAX_TEXT_FILE_BYTES:
        findings.append(f"{relative_path}: exceeds the 1 MB source-file limit")
    if b"\0" in content:
        findings.append(f"{relative_path}: binary content is not allowed in this source repository")
        return findings
    try:
        decoded = content.decode("utf-8")
    except UnicodeDecodeError:
        findings.append(f"{relative_path}: file is not valid UTF-8")
        return findings

    if b"\r" in content:
        findings.append(f"{relative_path}: CR characters found; use LF line endings")
    if content and not content.endswith(b"\n"):
        findings.append(f"{relative_path}: missing final newline")

    for number, line in enumerate(decoded.splitlines(), start=1):
        if line.endswith((" ", "\t")):
            findings.append(f"{relative_path}:{number}: trailing whitespace")
        if line.startswith(("<<<<<<< ", ">>>>>>> ")) or line == "=======":
            findings.append(f"{relative_path}:{number}: unresolved merge-conflict marker")
    return findings


def workflow_policy_findings(content: str, relative_path: str) -> list[str]:
    """Enforce least privilege, pinned actions, and bounded CI execution."""
    findings: list[str] = []
    if not re.search(r"(?m)^permissions:\s*\{\}\s*$", content):
        findings.append(f"{relative_path}: workflow-level permissions must default to empty")
    if re.search(r"(?m)^\s*(pull_request_target|workflow_run):", content):
        findings.append(f"{relative_path}: privileged trigger is not allowed in this CI workflow")

    action_refs = re.findall(r"(?m)^\s*(?:-\s*)?uses:\s*([^\s#]+)", content)
    for reference in action_refs:
        if "@" not in reference:
            findings.append(f"{relative_path}: action reference is missing a revision: {reference}")
            continue
        revision = reference.rsplit("@", 1)[1]
        if not re.fullmatch(r"[0-9a-f]{40}", revision):
            findings.append(f"{relative_path}: action must be pinned to a full commit SHA: {reference}")

    job_timeouts = [
        int(value)
        for value in re.findall(r"(?m)^\s+timeout-minutes:\s*(\d+)\s*$", content)
    ]
    if not job_timeouts:
        findings.append(f"{relative_path}: no job timeout was declared")
    elif any(timeout < 60 for timeout in job_timeouts):
        findings.append(f"{relative_path}: every job timeout must be at least 60 minutes")

    job_permissions = re.findall(r"(?m)^    permissions:\s*$", content)
    if len(job_permissions) != len(job_timeouts):
        findings.append(f"{relative_path}: every job must declare its own permissions")
    if re.search(r"(?m)^\s+write-all\s*$", content):
        findings.append(f"{relative_path}: broad write-all permissions are forbidden")
    return findings


def inspect_repository() -> list[str]:
    findings: list[str] = []
    paths = tracked_paths()
    if not paths:
        return ["git ls-files returned no tracked files"]

    for required in REQUIRED_FILES:
        if not (ROOT / required).is_file():
            findings.append(f"required repository hygiene file is missing: {required}")

    for path in paths:
        relative = path.relative_to(ROOT).as_posix()
        if path.is_symlink():
            findings.append(f"{relative}: symbolic links are not allowed in the VM source repository")
            continue
        if any(part in {"__pycache__", ".pytest_cache", ".mypy_cache"} for part in path.parts):
            findings.append(f"{relative}: generated Python cache directory is tracked")
        if path.suffix == ".pyc" or relative.startswith(("build/", ".alire/")):
            findings.append(f"{relative}: generated build/cache artifact is tracked")
        if not path.is_file():
            findings.append(f"{relative}: tracked path is missing from the checkout")
            continue
        findings.extend(inspect_text_file(relative, path.read_bytes()))

    for workflow in sorted((ROOT / ".github" / "workflows").glob("*.yml")):
        findings.extend(
            workflow_policy_findings(
                workflow.read_text(encoding="utf-8"),
                workflow.relative_to(ROOT).as_posix(),
            )
        )
    return findings


def report_findings(title: str, findings: Iterable[str]) -> None:
    items = list(findings)
    if items:
        print(f"\n{title}: {len(items)} finding(s)")
        for item in items:
            print(f" - {item}")
        raise CIError(f"{title} failed")
    print(f"{title}: clean")


def run_hygiene() -> None:
    report_findings("Repository hygiene", inspect_repository())
    execute("Compile CI Python", [sys.executable, "-m", "compileall", "-q", "scripts/ci"])
    execute(
        "Run CI helper unit tests",
        [sys.executable, "-m", "unittest", "discover", "-s", "scripts/ci/tests", "-t", ".", "-v"],
    )


def run_secrets() -> None:
    command = [
        "detect-secrets",
        "scan",
        "--all-files",
        "--exclude-files",
        r"(^|/)(\.git|build|\.alire|__pycache__|\.pytest_cache)(/|$)",
        "--exclude-lines",
        r"uses:\s*[^@\s]+@[0-9a-f]{40}",
    ]
    result = subprocess.run(
        command,
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr, file=sys.stderr)
        raise CIError(f"detect-secrets exited with code {result.returncode}")
    try:
        baseline = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise CIError("detect-secrets did not return valid JSON") from error

    findings = baseline.get("results", {})
    paths = [
        path
        for path, detectors in findings.items()
        if detectors
    ]
    if paths:
        print("Potential secrets detected (values are intentionally not printed):")
        for path in sorted(paths):
            print(f" - {path}")
        raise CIError("secret scan found potential credentials")
    print("detect-secrets: no findings")


def run_workflow_lint() -> None:
    execute("YAML lint", ["yamllint", "-s", ".github"])
    execute("GitHub Actions workflow lint", ["actionlint", "-color"])
    report_findings("Workflow security policy", inspect_repository())


def run_ada() -> None:
    execute("GNAT compiler version", ["gnat", "--version"])
    execute("GPRbuild version", ["gprbuild", "--version"])
    execute(
        "Compile every VM test and proof-harness target",
        ["gprbuild", "-P", "spike.gpr", "-p", "-f", "-j0"],
        log_name="ada-build.log",
    )
    for test_name in ADA_TESTS:
        executable = ROOT / "build" / "bin" / test_name
        if not executable.is_file():
            raise CIError(f"expected test executable was not produced: {executable}")
        execute(f"Run {test_name}", [str(executable)], log_name=f"{test_name}.log")


def run_proofs() -> None:
    execute("GNATprove version", ["gnatprove", "--version"])
    command = [
        "gnatprove",
        "-P",
        "spike.gpr",
        "-k",
        "-j0",
        "--mode=all",
        "--level=2",
        "--timeout=120",
        "--checks-as-errors=on",
        "--warnings=error",
        "--report=all",
        "--output-header",
        "-u",
        *SPARK_UNITS,
    ]
    execute(
        "SPARK legality, flow, run-time safety, and contracts",
        command,
        log_name="gnatprove.log",
    )


def write_summary() -> None:
    gates = (
        ("Repository hygiene and secret detection", os.getenv("HYGIENE_RESULT", "unknown")),
        ("Ada build, tests, and SPARK proof", os.getenv("ADA_RESULT", "unknown")),
        ("Workflow lint and security audit", os.getenv("WORKFLOW_SECURITY_RESULT", "unknown")),
    )
    lines = [
        "# Spike CI summary",
        "",
        "| Gate | Result |",
        "|---|---|",
    ]
    for name, result in gates:
        lines.append(f"| {name} | **{result.upper()}** |")
    lines.extend(
        [
            "",
            "## Security hardening",
            "",
            "- Least-privilege GitHub Actions permissions; every job declares its permissions.",
            "- Third-party workflow actions pinned to full commit SHAs.",
            "- actionlint and yamllint validate workflow configuration.",
            "- zizmor audits GitHub Actions for security footguns.",
            "- detect-secrets scans repository files for accidental credentials.",
            "- Ada compiler warnings are promoted to errors; SPARK warnings and unproved checks fail CI.",
            "",
            "## VM scope",
            "",
            "This workflow validates the implemented VM core only. It does not build or test an interpreter, parser, frontend, or native backend.",
            "",
        ]
    )
    summary_path = os.getenv("GITHUB_STEP_SUMMARY")
    if summary_path:
        with Path(summary_path).open("a", encoding="utf-8") as stream:
            stream.write("\n".join(lines))
    print("\n".join(lines))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "gate",
        choices=("hygiene", "secrets", "workflow-lint", "ada", "prove", "summary"),
    )
    gate = parser.parse_args().gate
    actions = {
        "hygiene": run_hygiene,
        "secrets": run_secrets,
        "workflow-lint": run_workflow_lint,
        "ada": run_ada,
        "prove": run_proofs,
        "summary": write_summary,
    }
    try:
        actions[gate]()
    except CIError as error:
        print(f"CI ERROR: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
