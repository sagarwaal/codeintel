# Quick Start

## Project purpose
[Describe what the project does, based on verified evidence.]

## Architecture at a glance
[Describe major applications, packages, services, and boundaries.]

## Important entry points
| Concern | Source path | Notes |
|---|---|---|
| Application startup | | |
| Main routing / command entry | | |
| Core business logic | | |
| Persistence | | |
| External integrations | | |
| Tests | | |

## Critical workflows
- [Workflow]: [link to detailed workflow documentation]

## Engineering constraints
- [Verified invariant or architectural rule]
- [Compatibility or operational constraint]

## Fast verification
- Install/setup: [verified command or documentation]
- Focused test: [verified command]
- Full test suite: [verified command, if known]

## Common pitfalls
- [Evidence-backed pitfall and affected path]

## Workflow & subagent context pack
When running downstream workflows (planning, brainstorming, TDD, debugging, subagent execution, or code review) or spawning fresh subagents, pass the corresponding `.codeintel/` files into their context:

| Workflow / Subagent Role | Read First (`.codeintel/`) | Verify / Update After |
|---|---|---|
| **Brainstorming / Feature Planning** (`/plan`, `writing-plans`) | `INDEX.md`, `ARCHITECTURE.md`, `DEPENDENCY_MAP.md`, `FEATURE_IMPLEMENTATION_GUIDE.md`, owning `components/*.md` | Check blast radius & reference patterns before finalizing plan |
| **Implementer / TDD** (`test-driven-development`, `subagent-driven-development`) | `agents/TASK_ROUTING.md`, `DESIGN_PRINCIPLES.md`, `API_AND_CONTRACTS.md`, `TEST_STRATEGY.md`, owning `components/*.md` | Run focused tests; run incremental CodeIntel refresh on touched files |
| **Systematic Debugging** (`systematic-debugging`) | `KNOWN_ISSUES.md`, `DATA_FLOW.md`, relevant `workflows/*.md` and `components/*.md` | Update `KNOWN_ISSUES.md` / `findings/` with root-cause evidence |
| **Test Authoring / Coverage Audit** | `TEST_STRATEGY.md`, `TEST_COVERAGE_GAPS.md`, owning `components/*.md` | Update `TEST_COVERAGE_GAPS.md` once behavioral tests pass |
| **Code Review** (`requesting-code-review`, `receiving-code-review`) | `agents/REVIEW_CHECKLIST.md`, `DESIGN_PRINCIPLES.md`, `API_AND_CONTRACTS.md`, `DEPENDENCY_MAP.md` | Confirm invariants, contract compatibility, and manifest checkpoint |

## How to use this knowledge
Note: `.codeintel/` is Git-ignored, so standard `rg` / `git grep` searches skip it unless `.codeintel/` is passed explicitly as a path. Start with `INDEX.md`, then use `agents/TASK_ROUTING.md` to locate the relevant components, contracts, tests, and verification steps. Verify important claims against current source (`manifests/analysis_state.json`) before changing code, and run an incremental refresh after completing code changes.
