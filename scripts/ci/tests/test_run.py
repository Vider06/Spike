"""Unit tests for the repository CI policy helpers."""

from __future__ import annotations

import unittest

from run import inspect_text_file, workflow_policy_findings


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
