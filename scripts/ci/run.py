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
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
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
    "tests/prove_vm_stack.adb",
)
ADA_TESTS = (
    "test_machine_state",
    "test_virtual_memory",
    "test_vm_instructions",
    "test_vm_stack",
    "test_dynamic_lexer",
    "prove_virtual_memory",
    "prove_vm_stack",
)
SPARK_UNITS = (
    "machine_state.adb",
    "vm_instructions.adb",
    "prove_virtual_memory.adb",
    "prove_vm_stack.adb",
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


def _proof_report_metrics(log_text: str, project_report_text: str = "") -> dict[str, object]:
    """Extract only statistics explicitly present in GNATprove/time output."""
    combined_text = log_text + "\n" + project_report_text
    prover_names = sorted(
        {
            match.group(0)
            for match in re.finditer(r"\b(?:Alt-Ergo|CVC5|Z3)\b", combined_text, re.IGNORECASE)
        },
        key=str.casefold,
    )
    observed_units = sorted(
        {
            unit
            for unit in SPARK_UNITS
            if re.search(rf"(?<![\w-]){re.escape(unit)}(?![\w-])", combined_text, re.IGNORECASE)
        }
    )

    def reported_count(patterns: tuple[str, ...]) -> int | None:
        for pattern in patterns:
            match = re.search(pattern, combined_text, re.IGNORECASE)
            if match:
                return int(match.group(1).replace(",", ""))
        return None

    maximum_rss = re.search(
        r"Maximum resident set size \(kbytes\):\s*(\d+)", combined_text, re.IGNORECASE
    )
    summary_lines = [
        line.strip()
        for line in combined_text.splitlines()
        if re.search(
            r"statistics|checks? proved|checks? not proved|checks? unproved|"
            r"timed? out|timeout|proof attempts|prover|verification condition",
            line,
            re.IGNORECASE,
        )
    ]
    per_unit_counts: dict[str, dict[str, int]] = {}
    check_message = re.compile(
        r"^(?P<unit>.+?\.ad[bs]):\d+:\d+:\s*"
        r"(?P<level>info|low|medium|high):\s*(?P<message>.*)$",
        re.IGNORECASE,
    )
    for line in log_text.splitlines():
        match = check_message.match(line.strip())
        if not match:
            continue
        message = match.group("message")
        level = match.group("level").casefold()
        if level == "info" and "proved" in message.casefold():
            result_key = "proved"
        elif level in {"low", "medium", "high"} and re.search(
            r"might fail|could fail|not proved|unproved", message, re.IGNORECASE
        ):
            result_key = "not_proved"
        else:
            continue
        unit_name = Path(match.group("unit")).name
        counts = per_unit_counts.setdefault(
            unit_name, {"proved": 0, "not_proved": 0}
        )
        counts[result_key] += 1

    time_limit_events = len(
        re.findall(
            r"\[provers reached [^\]]*time[^\]]*limit before completing the proof\]",
            log_text,
            re.IGNORECASE,
        )
    )
    interrupted_events = len(
        re.findall(
            r"\[provers reached [^\]]*(?:time|step|memory)[^\]]*limit before completing the proof\]"
            r"|\[provers gave up before completing the proof\]"
            r"|\b(?:proof|prover) (?:was )?interrupted\b",
            log_text,
            re.IGNORECASE,
        )
    )
    total_row = re.search(r"(?m)^\s*Total\s+(.+)$", project_report_text)
    summary_cells: list[str] = []
    if total_row:
        summary_cells = [
            cell
            for cell in total_row.group(1).split()
            if not cell.startswith("(")
        ]

    def cell_count(index: int) -> int | None:
        if index >= len(summary_cells) or summary_cells[index] == ".":
            return None
        token = summary_cells[index].replace(",", "")
        return int(token) if token.isdigit() else None

    flow_count = cell_count(1)
    interval_count = cell_count(2)
    prover_count = cell_count(3)
    proved_parts = [value for value in (flow_count, interval_count, prover_count) if value is not None]
    unproved_count = cell_count(5)
    if len(summary_cells) >= 6 and summary_cells[5] == ".":
        unproved_count = 0
    justified_count = cell_count(4)
    if len(summary_cells) >= 5 and summary_cells[4] == ".":
        justified_count = 0
    return {
        "provers_detected": prover_names,
        "requested_units": list(SPARK_UNITS),
        "units_mentioned_in_output": observed_units,
        "per_unit_check_counts": per_unit_counts,
        "checks_total": cell_count(0),
        "checks_proved": sum(proved_parts) if len(summary_cells) >= 6 else reported_count(
            (r"(\d[\d,]*)\s+checks?\s+proved", r"proved\s+checks?:\s*(\d[\d,]*)")
        ),
        "checks_justified": justified_count,
        "checks_not_proved": unproved_count if len(summary_cells) >= 6 else reported_count(
            (
                r"(\d[\d,]*)\s+checks?\s+(?:not proved|unproved)",
                r"(?:not proved|unproved)\s+checks?:\s*(\d[\d,]*)",
            )
        ),
        "proofs_timed_out": time_limit_events,
        "proofs_interrupted": interrupted_events,
        "max_steps_used": reported_count((r"max steps used for successful proof:\s*(\d[\d,]*)",)),
        "maximum_rss_kib": int(maximum_rss.group(1)) if maximum_rss else None,
        "gnatprove_report_excerpt": summary_lines[-80:],
        "project_summary_table": project_report_text.splitlines()[:55],
    }


def _publish_proof_statistics(report: dict[str, object]) -> None:
    """Publish a concise, honest summary; unavailable metrics remain unavailable."""
    elapsed = float(report["duration_seconds"])
    status = "passed" if report["exit_code"] == 0 else "failed"
    lines = [
        "# GNATprove proof statistics",
        "",
        f"- **Result:** {status}",
        f"- **Elapsed time:** {elapsed:.2f} seconds",
        f"- **Proof level:** 2",
        f"- **Per-prover timeout:** 60 seconds",
    ]
    memory_kib = report["maximum_rss_kib"]
    if memory_kib is None:
        lines.append("- **Maximum resident memory:** unavailable from this run")
    else:
        lines.append(f"- **Maximum resident memory:** {int(memory_kib) / 1024:.1f} MiB")
    provers = report["provers_detected"]
    lines.append(
        f"- **Provers observed in output:** {', '.join(provers) if provers else 'not reported'}"
    )
    for label, key in (
        ("Checks proved", "checks_proved"),
        ("Checks justified", "checks_justified"),
        ("Checks not proved", "checks_not_proved"),
        ("Proof attempts timed out", "proofs_timed_out"),
        ("Proof attempts interrupted", "proofs_interrupted"),
    ):
        value = report[key]
        lines.append(f"- **{label}:** {value if value is not None else 'not reported by GNATprove'}")
    per_unit = report["per_unit_check_counts"]
    if per_unit:
        lines.extend(
            [
                "",
                "### Per-unit proof checks",
                "",
                "| Ada unit | Proved | Not proved |",
                "|---|---:|---:|",
            ]
        )
        for unit, counts in sorted(per_unit.items()):
            lines.append(
                "| " + unit + " | " + str(counts["proved"]) + " | "
                + str(counts["not_proved"]) + " |"
            )
    if report["checks_total"] is not None:
        lines.append(f"- **Total checks in GNATprove project summary:** {report['checks_total']}")
    if report["max_steps_used"] is not None:
        lines.append(f"- **Maximum steps used by a successful proof:** {report['max_steps_used']}")
    lines.extend(
        [
            "",
            f"- **Units requested:** {', '.join(report['requested_units'])}",
            "- **Per-check prover timings and steps:** captured by GNATprove statistics and retained in the raw report; per-unit check counts are aggregated below, while per-unit wall-clock timings are not emitted.",
            "- **Detailed output and machine-readable statistics:** retained in the spark-proof-report workflow artifact.",
            "",
        ]
    )
    summary_path = os.getenv("GITHUB_STEP_SUMMARY")
    if summary_path:
        with Path(summary_path).open("a", encoding="utf-8") as stream:
            stream.write("\n".join(lines))
    print("\n".join(lines))


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
        "--timeout=60",
        "--checks-as-errors=on",
        "--warnings=error",
        "--report=statistics",
        "--output-header",
        "-u",
        *SPARK_UNITS,
    ]

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOG_DIR / "gnatprove.log"
    project_report_path = ROOT / "build" / "obj" / "gnatprove" / "gnatprove.out"
    stale_summary_path = LOG_DIR / "gnatprove-summary.out"
    for stale_path in (project_report_path, stale_summary_path):
        if stale_path.is_file():
            stale_path.unlink()
    timed_command = command
    time_binary = Path("/usr/bin/time")
    if time_binary.is_file():
        timed_command = [str(time_binary), "-v", *command]

    started = time.monotonic()
    exit_code = 0
    failure: CIError | None = None
    try:
        execute(
            "SPARK legality, flow, run-time safety, and contracts",
            timed_command,
            log_name="gnatprove.log",
        )
    except CIError as error:
        exit_code = 1
        failure = error

    elapsed = time.monotonic() - started
    log_text = log_path.read_text(encoding="utf-8", errors="replace") if log_path.exists() else ""
    project_report_text = (
        project_report_path.read_text(encoding="utf-8", errors="replace")
        if project_report_path.is_file()
        else ""
    )
    if project_report_text:
        shutil.copyfile(project_report_path, LOG_DIR / "gnatprove-summary.out")
    metrics = _proof_report_metrics(log_text, project_report_text)
    report: dict[str, object] = {
        "schema_version": 1,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "commit": os.getenv("GITHUB_SHA"),
        "workflow_run_id": os.getenv("GITHUB_RUN_ID"),
        "workflow_run_attempt": os.getenv("GITHUB_RUN_ATTEMPT"),
        "command": command,
        "proof_level": 2,
        "timeout_seconds": 60,
        "exit_code": exit_code,
        "duration_seconds": round(elapsed, 3),
        **metrics,
    }
    report_path = LOG_DIR / "gnatprove-statistics.json"
    report_path.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    _publish_proof_statistics(report)
    if failure is not None:
        raise failure


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
            "This workflow validates the VM core and the native Ada JSON-driven lexer foundation. It does not yet validate a complete parser, interpreter, or native backend.",
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
