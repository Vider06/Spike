"""Unit tests for the repository CI policy helpers."""

from __future__ import annotations

import unittest

from scripts.ci.run import (
    _proof_report_metrics,
    inspect_text_file,
    workflow_policy_findings,
)


class TextHygieneTests(unittest.TestCase):
    def test_clean_utf8_lf_file_passes(self) -> None:
        self.assertEqual(inspect_text_file("sample.adb", b"procedure Sample is\nbegin\n   null;\nend Sample;\n"), [])

    def test_trailing_whitespace_is_rejected(self) -> None:
        findings = inspect_text_file("sample.adb", b"null; \n")
        self.assertTrue(any("trailing whitespace" in item for item in findings))

    def test_missing_final_newline_is_rejected(self) -> None:
        findings = inspect_text_file("sample.adb", b"null;")
        self.assertTrue(any("missing final newline" in item for item in findings))

    def test_binary_content_is_rejected(self) -> None:
        findings = inspect_text_file("sample.bin", b"\x00\x01")
        self.assertTrue(any("binary content" in item for item in findings))

    def test_invalid_utf8_is_rejected(self) -> None:
        findings = inspect_text_file("sample.txt", b"\xff")
        self.assertTrue(any("valid UTF-8" in item for item in findings))



class ProofStatisticsTests(unittest.TestCase):
    def test_extracts_only_reported_proof_statistics(self) -> None:
        report = _proof_report_metrics(
            "GNATprove: 12 checks proved\n"
            "GNATprove: 2 checks not proved\n"
            "Prover: Z3\n"
            "Maximum resident set size (kbytes): 4096\n"
            "machine_state.adb"
        )
        self.assertEqual(report["checks_proved"], 12)
        self.assertEqual(report["checks_not_proved"], 2)
        self.assertEqual(report["provers_detected"], ["Z3"])
        self.assertEqual(report["maximum_rss_kib"], 4096)
        self.assertIn("machine_state.adb", report["units_mentioned_in_output"])

    def test_unreported_statistics_are_not_fabricated_as_zero(self) -> None:
        report = _proof_report_metrics("GNATprove completed.")
        self.assertIsNone(report["checks_proved"])
        self.assertIsNone(report["checks_not_proved"])
        self.assertEqual(report["proofs_timed_out"], 0)
        self.assertEqual(report["proofs_interrupted"], 0)
        self.assertIsNone(report["maximum_rss_kib"])
        self.assertEqual(report["provers_detected"], [])

    def test_parses_gnatprove_project_summary_table(self) -> None:
        project_report = (
            "SPARK Analysis results        Total          Flow   Interval"
            "                         Provers   Justified   Unproved\n"
            "Total                          2025    1201 (59%)          ."
            "                       805 (40%)     19 (1%)          .\n"
            "max steps used for successful proof: 1234\n"
        )
        report = _proof_report_metrics("", project_report)
        self.assertEqual(report["checks_total"], 2025)
        self.assertEqual(report["checks_proved"], 2006)
        self.assertEqual(report["checks_justified"], 19)
        self.assertEqual(report["checks_not_proved"], 0)
        self.assertEqual(report["max_steps_used"], 1234)

    def test_aggregates_proof_checks_per_ada_unit(self) -> None:
        report = _proof_report_metrics(
            "src/vm_stack.adb:42:10: info: precondition proved (CVC5: 1 VC, 0.01s, 4 steps)\n"
            "src/vm_stack.adb:55:10: medium: postcondition might fail\n"
        )
        self.assertEqual(
            report["per_unit_check_counts"],
            {"vm_stack.adb": {"proved": 1, "not_proved": 1}},
        )

    def test_counts_explicitly_interrupted_proof_attempts(self) -> None:
        report = _proof_report_metrics(
            "vm_stack.adb:55:10: medium: precondition might fail "
            "[provers reached time and step limit before completing the proof]\n"
        )
        self.assertEqual(report["proofs_timed_out"], 1)
        self.assertEqual(report["proofs_interrupted"], 1)


class WorkflowPolicyTests(unittest.TestCase):
    def test_unpinned_action_is_rejected(self) -> None:
        content = """permissions: {}
jobs:
  test:
    permissions:
      contents: read
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v6
"""
        findings = workflow_policy_findings(content, ".github/workflows/ci.yml")
        self.assertTrue(any("full commit SHA" in item for item in findings))

    def test_short_timeout_is_rejected(self) -> None:
        content = """permissions: {}
jobs:
  test:
    permissions:
      contents: read
    timeout-minutes: 15
"""
        findings = workflow_policy_findings(content, ".github/workflows/ci.yml")
        self.assertTrue(any("at least 60" in item for item in findings))

    def test_sha_pinned_workflow_passes_policy(self) -> None:
        content = """permissions: {}
jobs:
  test:
    permissions:
      contents: read
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803
"""
        self.assertEqual(workflow_policy_findings(content, ".github/workflows/ci.yml"), [])


if __name__ == "__main__":
    unittest.main()
