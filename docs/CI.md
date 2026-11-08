# Continuous integration

Spike CI is intentionally split into small gates. The workflow YAML provisions pinned tools and calls the implementation in `scripts/ci/run.py`; substantive checks and policy logic live in Python so they can also be run locally.

## Required gates

| Gate | Checks |
|---|---|
| Repository hygiene | Tracked-file UTF-8/LF policy, final newlines, trailing whitespace, conflict markers, generated artifacts, required project files, Python syntax, and CI helper unit tests |
| Secret detection | detect-secrets scans the repository and fails on potential credentials |
| Ada validation | GNAT/GPRbuild versions, strict Ada compilation, and execution of every VM test main |
| SPARK proof | SPARK legality, flow analysis, run-time safety checks, and contracts; unproved checks and warnings fail the gate |
| Workflow security | yamllint, actionlint, zizmor, full-SHA action pinning, least privilege, and minimum job timeouts |
| CI summary | One status table and a Security Hardening report |

All jobs use Ubuntu 24.04 and a 60-minute timeout. Workflow permissions default to empty and are granted per job. Checkout credentials are not persisted. GitHub Actions dependencies are pinned to full commit SHAs and Dependabot groups their updates.

## Ada and SPARK toolchain

The workflow uses the Alire setup action to install Alire, GNAT Native, and GPRbuild. It then installs GNATprove through Alire. Alire provides the Ada toolchain as a matched GNAT/GPRbuild pair; GNATprove is the SPARK formal verification tool.

The build uses Ada 2022, assertions, validity checks, overflow checks, all GNAT warnings, and warnings-as-errors. The GPR project declares three test mains:

- `test_machine_state`
- `test_virtual_memory`
- `test_vm_instructions`

GNATprove analyzes the machine-state and instruction implementation units plus a concrete SPARK memory proof harness that instantiates the generic memory package. Runtime test mains are compiled and executed separately; they are not treated as formal proof harnesses. The proof gate uses full legality/flow/proof mode, proof level 2, warnings-as-errors, and unproved-checks-as-errors. It cannot pass merely because GNATprove exits successfully without proving its generated checks.

## Run locally

Install Alire, GNAT, GPRbuild, Python 3.12+, Go, actionlint, yamllint, and detect-secrets. The checked-in Alire manifest pins GNATprove; resolve it and run Ada commands through Alire's environment:

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

This CI validates the VM implementation only. It deliberately does not expect an interpreter, lexer, parser, frontend, instruction decoder, execution loop, or native backend. Those components must receive their own specifications and CI gates when they are designed and implemented.
