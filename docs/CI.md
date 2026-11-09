# Continuous integration

Spike CI has one automatic trigger: **`push`**. The workflow does not also subscribe to `pull_request`; a commit pushed to a branch with an open PR therefore starts one CI run, not a second run for the PR event. Pushes to `main` use the same workflow. The workflow YAML provisions pinned tools and invokes `scripts/ci/run.py`; substantive checks and policy logic remain in Python.

## Required gates

| Gate | Checks |
|---|---|
| Repository hygiene | Tracked-file UTF-8/LF policy, final newlines, trailing whitespace, conflict markers, generated artifacts, required layout/configuration files, Python syntax, and CI helper unit tests |
| Secret detection | `detect-secrets` scans the repository and fails on potential credentials |
| Ada validation | GNAT/GPRbuild versions, strict Ada compilation, and execution of every API, VM, lexer, and proof-harness main |
| SPARK proof | SPARK legality, flow analysis, run-time safety checks, and contracts; unproved checks and warnings fail the gate |
| Workflow security | yamllint, actionlint, zizmor, full-SHA action pinning, least privilege, one-trigger policy, and minimum job timeouts |
| CI summary | One status table and a Security Hardening report |

All jobs use Ubuntu 24.04 and a 60-minute timeout. Workflow permissions default to empty and are granted per job. Checkout credentials are not persisted. GitHub Actions dependencies are pinned to full commit SHAs and Dependabot groups their updates.

## Ada and SPARK toolchain

The workflow uses the Alire setup action to install Alire, GNAT Native, and GPRbuild. It then installs GNATprove through Alire. The GPR project explicitly lists the source directories under `src/frontend/lexer`, `src/backend/quick/vm`, and the corresponding test/proof directories. The lexer no longer depends on GNATCOLL or a JSON token configuration.

The build uses Ada 2022, assertions, validity checks, overflow checks, all GNAT warnings, and warnings-as-errors. Its ten main programs are:

- Runtime tests: `test_spike_api`, `test_machine_state`, `test_virtual_memory`, `test_vm_instructions`, `test_vm_stack`, `test_lexer`, and `fuzz_lexer`.
- Proof harnesses: `prove_virtual_memory`, `prove_vm_stack`, and `prove_lexer_properties`.

GNATprove analyzes the bounded VM and lexer-property units plus their concrete SPARK harnesses. The lexer implementation itself is written in SPARK; the property harness currently proves the reusable character, token-span, and comma-position predicates. Runtime tests are compiled and executed separately; they are not treated as formal proof harnesses. The proof gate uses full legality/flow/proof mode, proof level 2, a bounded 60-second per-prover timeout, warnings-as-errors, and unproved-checks-as-errors.

The proof invocation records total elapsed time, maximum resident memory reported by GNU time when available, prover names, proved/justified/unproved counts, timed-out/interrupted attempts, maximum proof steps, per-unit check counts, requested/observed units, exact command, commit, and workflow run metadata. It writes machine-readable statistics and retains the full console log under `build/ci/`. CI uploads diagnostics for 90 days. Unavailable metrics are marked unavailable rather than estimated.

## Run locally

Install Alire, GNAT, GPRbuild, Python 3.12+, Go, actionlint, yamllint, and detect-secrets. Then run:

```sh
python -m pip install -r scripts/ci/requirements.txt
python scripts/ci/run.py hygiene
python scripts/ci/run.py secrets
alr -n update
alr exec -- python scripts/ci/run.py ada
alr exec -- python scripts/ci/run.py prove
python scripts/ci/run.py workflow-lint
```

The workflow-security gate additionally runs zizmor using its pinned GitHub Action.

## Scope boundary

CI validates the Phase 1 lexer, including typed token spans, structured lexical diagnostics, positive and negative rule tests, the golden fixture, and deterministic malformed-input fuzzing. It also validates the existing VM primitives. The verb-table loader, parser, symbol/scope resolver, type checker, IR, lowering, Quick interpreter loop, native assembler, encoder, object writer, linker, and CLI remain future gates until each phase is implemented with tests and contracts.
