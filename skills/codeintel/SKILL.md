---
name: codeintel
description: Deeply analyze a software repository and create or incrementally maintain a local, Git-ignored project intelligence knowledge base for architecture understanding, navigation, debugging, consistency reviews, test-gap discovery, change-impact analysis, and safe feature implementation. Use when onboarding to an existing codebase, auditing a project, investigating a complex bug, planning a feature, or refreshing repository knowledge. Not for small single-file questions or quick edits.
---

# CodeIntel

## Purpose

Build and maintain a durable, evidence-based knowledge layer over an existing software repository. The knowledge should help future developers and coding agents understand the project quickly, navigate to the right implementation, diagnose defects, assess change impact, find test gaps, and implement features consistently.

The source repository is the source of truth. Project intelligence is derived knowledge and must be verified against current code whenever it matters.

## Operating modes

Select the mode that fits the request:

1. **Deep Analysis** — establish a comprehensive initial understanding of the repository and create the knowledge base.
2. **Task Investigation** — use existing knowledge to investigate a specific bug, feature, refactor, or design question; inspect relevant source and dependencies rather than reanalyzing everything.
3. **Knowledge Refresh** — update affected knowledge after code changes, structural changes, or detected staleness.
4. **Audit** — focus on correctness, architecture, consistency, security, performance, maintainability, and test coverage.

If the user's intent is ambiguous, infer the narrowest useful mode and explain the scope.

| Mode | Run | Skip unless needed |
|---|---|---|
| Deep Analysis | Steps 0–15 | — |
| Task Investigation | Step 0, then Steps 5, 6, 7 scoped to the task; update affected docs (Step 14) | Broad reconnaissance and repo-wide audits |
| Knowledge Refresh | Step 0, Step 14, then targeted Steps 3–7 for changed areas; Step 15 | Unchanged areas |
| Audit | Step 0, Steps 6, 7, 9, 10, 13, 15 | Feature guidance (Step 11) |

Scale the work to the request. A knowledge base that covers part of the repository accurately is better than one that covers all of it superficially.

## Non-negotiable safeguards

- Start by identifying the repository root, current branch/commit when available, and Git working-tree status.
- Preserve user changes. Never reset, clean, overwrite, or discard unrelated work.
- Do not modify application source code during a knowledge-only analysis unless explicitly authorized.
- Do not run destructive commands, migrations, deployment operations, or scripts with external side effects without explicit authorization.
- Inspect existing `.gitignore` and agent instructions before editing them.
- Do not overwrite existing project documentation or agent instructions. Make minimal additive changes.
- Never copy secrets, credentials, access tokens, private keys, sensitive environment values, or sensitive production data into the knowledge base.
- Treat a Git-ignored directory as excluded from normal Git tracking, not as a security boundary.
- Do not claim a test, command, scan, or verification passed unless it was actually run and passed.
- Distinguish verified facts from inference, suspicion, and unknowns.
- Do not claim exhaustive coverage when parts of the repository were not inspected.
- If the directory is not a Git repository, skip Git-specific steps, say so, and do not initialize Git.
- For large repositories or monorepos, work in phases, prioritize high-impact areas, checkpoint progress in `manifests/analysis_state.json`, and report partial coverage honestly instead of exhausting the context budget.

## Step 0 — Reuse existing knowledge

Before analyzing anything, check whether `.codeintel/` (or an equivalent) already exists.

If it does:

1. Read `INDEX.md` and `manifests/analysis_state.json`.
2. Compare the recorded commit with the current `HEAD` (for example `git diff --name-status <recorded_commit>..HEAD` plus `git status --porcelain`) to find what may be stale.
3. Use the existing knowledge as a map, but verify any claim that matters for the current task against current source.
4. Choose the narrowest mode that satisfies the request.

If it does not exist and the request is not Deep Analysis, do the task-scoped work first and offer to create the knowledge base rather than creating it unprompted.

## Step 1 — Reconnaissance

Inspect enough of the repository to establish its shape before drawing conclusions.

Identify, where applicable:

- Applications, packages, services, modules, and bounded contexts.
- Languages, frameworks, package managers, lockfiles, build systems, and runtime targets.
- Entry points, startup and shutdown paths, routing, middleware, dependency injection, and lifecycle hooks.
- Domain models, database schemas, repositories, migrations, and persistence boundaries.
- APIs, events, background jobs, external integrations, and public contracts.
- UI structure, routes, state management, and shared components.
- Test frameworks, test directories, CI workflows, build/deploy configuration, and operational tooling.
- Existing docs, `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, or equivalent instructions.
- Generated code, vendored dependencies, build output, and caches that should generally be excluded from broad analysis.

Use manifests, repository search, symbol references, static analysis, and test discovery where available. Avoid blindly reading every file or scanning dependencies and build artifacts without a reason.

Record what was inspected and what was excluded.

## Step 2 — Create the local knowledge base

Create `.codeintel/` at the repository root unless an equivalent project-specific knowledge location already exists and is suitable.

Exclude the directory from Git without creating a tracked change, unless it is already covered:

1. **Default — local exclude.** Append the rule to `.git/info/exclude` (resolve the path with `git rev-parse --git-path info/exclude` so worktrees work). This is untracked and affects only this clone.
2. **Shared — `.gitignore`.** Add the rule to `.gitignore` only if the user asks, or if the repository already ignores similar local AI/tooling directories there. This is a tracked change; mention it in the final response.

```gitignore
# Local AI-generated code intelligence and repository analysis
/.codeintel/
```

Verify the rule with:

```bash
git check-ignore -v .codeintel/INDEX.md
```

If files inside the directory are already tracked, explain that ignore rules do not untrack them. Do not untrack or remove them without authorization.

Use the structure in [knowledge-base-structure.md](references/knowledge-base-structure.md) as a guide. Adapt it to repository scale; do not create empty boilerplate files.

At minimum, create a useful `INDEX.md`, `PROJECT_PROFILE.md`, `ARCHITECTURE.md`, `DIRECTORY_MAP.md`, `COMPONENT_CATALOG.md`, `DEPENDENCY_MAP.md`, `TEST_STRATEGY.md`, `TEST_COVERAGE_GAPS.md`, `KNOWN_ISSUES.md`, `DESIGN_PRINCIPLES.md`, `FEATURE_IMPLEMENTATION_GUIDE.md`, and `manifests/analysis_state.json` when justified by project complexity.

## Step 3 — Reconstruct architecture and behavior

Document architecture as implemented, not as assumed.

Trace:

- Application startup and shutdown.
- Critical user and system workflows from entry point through validation, authorization, business logic, persistence/integrations, response, errors, and cleanup.
- Architectural layers, responsibilities, allowed dependencies, interfaces, and boundaries.
- Important data flows, state transitions, invariants, and side effects.
- External contracts, compatibility constraints, and runtime assumptions.

Compare intended architecture with actual dependencies. Record discrepancies rather than silently choosing between conflicting documentation and code.

Use Mermaid diagrams when they materially improve understanding. Diagrams must reflect verified relationships.

## Step 4 — Analyze components

For high-impact, complex, shared, security-sensitive, or frequently changed components, record:

- Purpose, location, layer, and ownership.
- Public interfaces and important symbols.
- Callers, dependencies, shared state, and external interactions.
- Preconditions, postconditions, invariants, side effects, error behavior, and boundary cases.
- Validation, authorization, concurrency, lifecycle, and resource-management assumptions.
- Relevant tests and test gaps.
- Change-impact considerations.
- Known weaknesses and recommended patterns.

Assess cohesion, coupling, encapsulation, naming, readability, error contracts, duplication, abstraction quality, testability, and consistency. Do not mistake personal style preferences for defects; account for domain requirements and legitimate exceptions.

Create component-specific notes only when they add meaningful value. Avoid one document per trivial file.

## Step 5 — Build dependency and change-impact knowledge

For important symbols and components, identify relevant relationships:

- Calls, imports, implements, depends on.
- Reads/writes shared data.
- Publishes/consumes events.
- Validates or transforms contracts.
- Tests or mocks behavior.
- Is affected by or violates a constraint.

Distinguish compile-time, runtime, data, and conceptual dependencies. Identify high-blast-radius components such as shared abstractions, public interfaces, authorization boundaries, persistence layers, and critical workflows.

When static analysis cannot resolve reflection, dynamic registration, generated code, runtime dispatch, or external consumers, state the limitation.

## Step 6 — Audit correctness and consistency

Inspect for both local and cross-component defects, including:

- Incorrect conditions, boundary errors, invalid state transitions, missing validation, null-handling problems, and incorrect defaults.
- Lost or swallowed errors, incorrect retries, resource leaks, partial updates, and unsafe transaction boundaries.
- Race conditions, async sequencing errors, stale caches, and concurrency assumptions.
- API/model/frontend contract mismatches.
- Inconsistent interpretations of statuses, types, errors, or domain invariants.
- Duplicated business rules and divergent implementations.
- Alternate entry points that bypass authorization or validation.
- UI assumptions about optional or malformed responses.
- Dead code or compatibility paths, where evidence supports the claim.

For every significant finding, record an ID, severity, confidence, category, affected paths/symbols, evidence, observed and expected behavior, reproduction conditions if known, impact, root-cause status, recommended remediation, regression tests, related components, and verification status.

Classify findings as **confirmed**, **strongly suspected**, **potential risk**, **design concern**, or **maintainability concern**. A suspicious pattern is not automatically a defect.

## Step 7 — Test and coverage intelligence

Map important components and behaviors to existing tests.

Inspect unit, integration, API, contract, component, end-to-end, property-based, performance, and security tests as applicable. Record actual commands and prerequisites from project configuration.

Assess behavioral coverage, not just line coverage. Look for missing boundary cases, error paths, authorization-denial paths, rollback behavior, integration contracts, concurrency behavior, and regression tests.

Distinguish “not found in inspected tests” from “no tests exist.” If coverage reports are unavailable, label coverage assessments as inspection-based rather than measured.

Provide focused test commands and explain which suites should run after common change types. Do not weaken tests just to accommodate incorrect behavior.

## Step 8 — Derive design principles and reference patterns

Document established project conventions before recommending new ones.

Identify real reference implementations for patterns such as a well-structured service, API handler, business rule, persistence operation, UI component, error-handling path, integration, and meaningful test.

Explain why each is a good example and where it applies. Also record anti-patterns when that prevents repeated mistakes.

Prioritize existing contracts, domain correctness, security, simplicity, established language/framework idioms, and maintainability. Do not introduce fashionable patterns or abstractions without a concrete need.

## Step 9 — Review security, performance, and operations proportionately

Review relevant risks such as authorization, trust boundaries, injection, unsafe deserialization, secret handling, sensitive logs, file access, SSRF, XSS/CSRF where applicable, unsafe defaults, dependency risks, rate limiting, and cryptographic misuse.

Inspect likely performance issues such as N+1 queries, unbounded queries, repeated expensive work, blocking operations, excessive allocations, unnecessary network calls, cache misuse, unbounded concurrency, and UI rendering/bundle concerns.

Inspect reliability concerns such as timeouts, retries, health checks, graceful shutdown, migrations, background jobs, configuration validation, observability, cleanup, and rollback procedures.

Separate confirmed findings from hypotheses requiring runtime tests, profiling, or specialist review. Do not describe static inspection as a complete security audit.

## Step 10 — Document issues and recommendations

Maintain actionable issue records with severity, confidence, status, affected paths, evidence, impact, root cause if established, remediation, regression tests, dependencies, and relative effort.

Prioritize based on impact, likelihood, security exposure, affected workflows, regression risk, and cost of leaving the issue unresolved. Keep confirmed defects separate from optional improvements.

## Step 11 — Document feature implementation guidance

Create a practical guide that helps future contributors:

1. Identify the domain concepts and owning components.
2. Find the closest valid reference implementation.
3. Trace callers, contracts, persistence, and downstream consumers.
4. Preserve architectural boundaries and invariants.
5. Identify authorization, validation, error, and compatibility requirements.
6. Add focused unit and integration tests.
7. Consider observability, performance, migrations, and operational effects.
8. Update relevant documentation and knowledge.
9. Run focused tests first, then broader verification as appropriate.

Prefer the smallest coherent change. Avoid unrelated refactors, duplicated business logic, hidden global state, unnecessary dependencies, bypassed validation, weakened tests, and broad rewrites without evidence.

## Step 12 — Make the knowledge easy to navigate

`INDEX.md` is the entry point. It should link to major documents and route common tasks to the right source locations, docs, tests, and verification commands.

Create these agent-facing files when useful, starting from the bundled templates. Tailor them to the real repository; never leave generic examples presented as repository facts.

| File | Start from |
|---|---|
| `agents/QUICK_START.md` | [templates/quick-start-template.md](templates/quick-start-template.md) |
| `agents/TASK_ROUTING.md` | [templates/task-routing-template.md](templates/task-routing-template.md) |
| `agents/CHANGE_PROTOCOL.md` | [references/change-protocol.md](references/change-protocol.md) |
| `agents/REVIEW_CHECKLIST.md` | [templates/review-checklist.md](templates/review-checklist.md) |

The quick start should explain project purpose, architecture, entry points, core components, business-logic location, persistence, tests, critical workflows, common pitfalls, and the fastest way to verify a change.

To help future sessions discover the knowledge base, you may propose adding a single line such as `Project knowledge: see .codeintel/INDEX.md (local, not committed).` to an existing `AGENTS.md`, `CLAUDE.md`, or equivalent. Add it only with the user's permission, and never create or rewrite those files for this purpose.

## Step 13 — Record evidence and uncertainty

Use repository-relative paths and real symbol names. Add line numbers for important details when available, but do not invent them.

Label claims where helpful:

- **VERIFIED** — established by direct inspection or executed verification.
- **OBSERVED** — behavior directly observed, but its full mechanism is not established.
- **INFERRED** — evidence-supported conclusion.
- **SUSPECTED** — plausible issue needing further investigation.
- **UNVERIFIED** — not checked.
- **STALE** — may no longer match current code.

Phrase negative findings carefully. For example: “No direct tests for the denial branch were found in the inspected test files; dynamic test registration and coverage instrumentation were not verified.”

## Step 14 — Support incremental refresh

Record analysis metadata in `manifests/analysis_state.json`, including commit/branch when available, timestamp, included/excluded areas, completed phases, commands executed, verification results, unresolved questions, and limitations. Follow the field list in [knowledge-base-structure.md](references/knowledge-base-structure.md#analysis-state-fields) so other sessions and agents can read it. Do not store secrets.

Maintain a deterministic source inventory with relative paths, categories, content hashes where useful, and links to related component docs/findings.

On refresh (see also [change-protocol.md](references/change-protocol.md)):

1. Identify added, modified, renamed, and deleted files.
2. Map changes to components and contracts.
3. Inspect relevant callers and downstream dependencies.
4. Update affected docs, maps, tests, findings, and indexes.
5. Revalidate claims that may now be stale.
6. Record the update and unresolved work.

Do not regenerate everything after every small change. Broaden the review for public interfaces, shared data models, core abstractions, or architectural boundaries. Preserve concise update summaries under `history/` where useful.

## Step 15 — Validate the result

Check:

- Index links and document paths are valid.
- Findings have evidence and actionable next steps.
- Architecture and dependency claims match inspected code.
- Test commands reflect actual configuration.
- Coverage statements are appropriately scoped.
- Contradictions and stale claims are marked.
- The ignore rule works.
- User changes remain untouched.
- The analysis state accurately reflects work completed.
- Important areas not analyzed are explicitly listed.

As a usability test, use the knowledge base as the starting point to locate a core business rule, identify the impact of a public interface change, find relevant tests, plan a feature, and understand a known defect. Improve navigation if these tasks are difficult.

## Final response

Report:

1. Repository purpose and main architecture.
2. Knowledge-base location and key documents.
3. How Git exclusion was applied (`.git/info/exclude` or `.gitignore`) and whether it was verified.
4. Highest-priority findings with evidence.
5. Recommended next actions.
6. Areas analyzed deeply, partially, or not at all.
7. Commands/tests actually executed and their results.
8. Outstanding uncertainty and limitations.

Never claim complete analysis solely because the documents exist.

## Success criteria

The result is successful when a future agent can quickly determine where a feature belongs, understand the existing implementation, identify affected components and missing tests, and plan a coherent fix without rediscovering the entire repository.
