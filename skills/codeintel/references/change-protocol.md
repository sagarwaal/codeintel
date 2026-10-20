# Change Protocol for CodeIntel

Use this protocol whenever synchronizing `.codeintel/` after code changes, investigating a task against a modified repository, or performing a knowledge refresh.

## Two-Phase Refresh Architecture

Refresh is split into two explicit operations so drift inspection never mutates state or advances checkpoints prematurely:

### Phase A — Check Drift (Read-Only)
1. Validate `.codeintel/manifests/analysis_state.json` (migrating Schema v1 to Schema v2 in memory if needed).
2. Inspect repository identity, current `HEAD`, and working-tree status without disturbing user changes.
3. Detect all committed, staged, unstaged, untracked, deleted, and renamed files since `repository.analyzed_commit`.
4. Match changed paths against each artifact's `depends_on` list and apply the invalidation rules below.
5. Produce a **Proposed Refresh Plan** listing:
   - Changed files and change types (`A`, `M`, `D`, `R`, `U`/untracked)
   - Recommended refresh scope (`incremental`, `scoped`, or `full`) and rationale
   - Artifacts and engineering claims marked `stale` or requiring revalidation
   - Deleted/renamed symbols and references to purge
   - Relevant tests and contracts to inspect or run
   - Unresolved dynamic dependencies
6. **Invariant:** Phase A must not modify any file in `.codeintel/` or advance `analyzed_commit`.

### Phase B — Refresh Knowledge (Writes Approved Scope)
1. **Investigate (Phase 3):** Dispatch or execute the relevant read-only specialist roles (`behavior_tracer`, `test_quality_analyst`, `defect_consistency_auditor`, `repository_mapper`) on the impacted scope, collecting structured results per [evidence-model.md](evidence-model.md).
2. **Reconcile (Phase 4):** Run `knowledge_reconciler` to compare new evidence against existing `.codeintel/` claims and findings, resolve cross-agent contradictions, narrow overly broad statements, and produce a minimal patch plan.
3. **Update (Phase 5):** The single Knowledge Writer applies minimal patches to affected Markdown documents while preserving unrelated sections and user-authored content, and removes or flags references to deleted components/files.
4. **Validate (Phase 6):** Run deterministic checks (`scripts/codeintel-refresh.sh validate-manifest`, link/path checks, and safe repository tests when applicable).
5. **Commit the Checkpoint (Phase 7):** Stage the updated manifest to `manifests/analysis_state.json.tmp`, verify all invariants, and atomically replace `manifests/analysis_state.json` **only after** all required steps in the scope succeed.

### 7-Phase End-to-End Refresh Pipeline Summary

| Phase | Sub-phase | Owner | Mutates `.codeintel/`? |
|---|---|---|---|
| **Phase A (Read-Only)** | **1. Detect** | Deterministic script / Orchestrator | No |
| **Phase A (Read-Only)** | **2. Plan** | Orchestrator + `change_impact_analyst` ([impact-analysis.md](impact-analysis.md)) | No |
| **Phase B (Scoped Write)** | **3. Investigate** | Specialist roles (`behavior_tracer`, `test_quality_analyst`, `defect_consistency_auditor`, `repository_mapper`) | No (returns `agent-result.json`) |
| **Phase B (Scoped Write)** | **4. Reconcile** | `knowledge_reconciler` | No (produces proposed patch plan) |
| **Phase B (Scoped Write)** | **5. Update** | Knowledge Writer (controlled main-skill phase) | **Yes** (patches stale artifacts only) |
| **Phase B (Scoped Write)** | **6. Validate** | Deterministic validator (`scripts/codeintel-refresh.sh`) | No |
| **Phase B (Scoped Write)** | **7. Commit Checkpoint** | Checkpoint Manager (`scripts/codeintel-refresh.sh`) | **Yes** (promotes `analysis_state.json.tmp` on success) |

## Refresh Scopes

- **`incremental`**: Refresh only the documents, claims, components, workflows, and findings affected by changes since `analyzed_commit`. Default when `analysis_state.json` is valid and `analyzed_commit` is a valid ancestor of `HEAD`.
- **`scoped`**: Refresh only the specific files, components, workflows, or findings needed for the current task. Records partial coverage in `analysis_state.json` without advancing the repo-wide `analyzed_commit`.
- **`full`**: Rebuild the knowledge model when `.codeintel/` is missing, `analysis_state.json` is corrupted, `analyzed_commit` is missing/unreachable, or structural changes invalidate the majority of the codebase.

Do not force a `full` analysis when a developer makes a small or localized change.

## Step 1 — Detect Repository Changes

Never rely on `git diff HEAD~1`, which misses multi-commit ranges and uncommitted work.

1. **Verify baseline commit**
   - Read `BASE_SHA` from `repository.analyzed_commit` (or `commit` in Schema v1).
   - Check reachability: `git cat-file -e "${BASE_SHA}^{commit}"` and `git merge-base --is-ancestor "$BASE_SHA" HEAD`.
   - If `BASE_SHA` is missing or not an ancestor (e.g., history rewrite), record the divergence, compute diff against `git merge-base "$BASE_SHA" HEAD` if available, or escalate scope to `full`.

2. **Collect all change sets without double-counting**
   - Working-tree summary: `git status --short`
   - Committed changes since baseline: `git diff --name-status -M "${BASE_SHA}...HEAD"`
   - Staged changes: `git diff --cached --name-status -M`
   - Unstaged changes: `git diff --name-status -M`
   - Untracked files (excluding ignored): `git ls-files --others --exclude-standard`

3. **Normalize change classifications**
   - Deduplicate paths across committed, staged, unstaged, and untracked sets.
   - Track deletions (`D`) and renames (`R<score> old_path new_path`) explicitly so old path references are purged or updated in both Markdown documents and `depends_on` arrays.
   - Never reset, clean, checkout, or overwrite uncommitted user changes.

## Step 2 — Map Changed Files to Knowledge (Invalidation Rules)

First, mark any artifact in `analysis_state.json` as `stale` if a changed, deleted, or renamed path matches an entry in its `depends_on` array (exact path match or directory prefix match ending in `/`).

Second, apply these structural invalidation rules and propagate impact through known dependencies:

| Change detected | Knowledge to reconsider |
|---|---|
| Application entry point changes | `ARCHITECTURE.md`, initialization, runtime flows, `agents/QUICK_START.md` |
| Public function or interface changes | `COMPONENT_CATALOG.md`, `DEPENDENCY_MAP.md`, callers, contracts |
| Database schema changes | `DOMAIN_MODEL.md`, `DATA_FLOW.md`, migrations, persistence flows |
| API route changes | `API_AND_CONTRACTS.md`, request/response contracts, integration tests |
| Business logic changes | Relevant `workflows/`, `components/`, domain invariants, `KNOWN_ISSUES.md` |
| Test changes | `TEST_STRATEGY.md`, `TEST_COVERAGE_GAPS.md`, `COVERAGE_MATRIX.md`, verification status |
| Dependency manifest changes | `PROJECT_PROFILE.md`, runtime requirements, `DEPENDENCY_MAP.md`, build instructions |
| Configuration changes | Environment variables, feature flags, operational/deployment notes |
| File or directory deletion | All references to the deleted component across `INDEX.md`, catalogs, maps, and `depends_on` |
| CI or build configuration changes | Verification commands in `TEST_STRATEGY.md`, `agents/QUICK_START.md`, and build assumptions |

**Transitive & dynamic propagation:** A change to a shared helper (e.g., authorization middleware, validation library, error handler, or shared type) invalidates downstream workflows and contracts that depend on it, even when those workflows' own files did not change. When static analysis cannot resolve reflection, dynamic registration, or runtime dispatch, record the uncertainty in `analysis.unresolved_items`.

## Step 3 — Revalidate Claims, Not Just Documents

Do not merely summarize the Git diff into Markdown. For every affected engineering claim or finding:

1. **Inspect source evidence** at the changed files, plus relevant callers, routes, consumers, and contracts.
2. **Inspect associated tests** to verify whether behavioral coverage still holds or has gaps.
3. **Evaluate claim truth:**
   - Still holds -> keep claim, update file/line evidence if shifted, keep or set `VERIFIED` / `INFERRED`.
   - Behavior changed -> update the claim, dependent workflows, and `depends_on` paths.
   - Contradicted -> correct the claim and check whether the discrepancy is an intentional change or a defect.
   - Cannot be verified -> label `STALE` or `UNVERIFIED` and add to `analysis.unresolved_items`.
4. **Reassess findings in `KNOWN_ISSUES.md` / `findings/`:**
   - Never mark a defect `resolved` unless current code and/or executed tests provide direct evidence that the root cause is fixed.
   - Unrelated source changes must never alter the status of existing open findings.
   - If a refresh uncovers a new critical correctness or security defect, record it with evidence rather than treating the refresh as documentation-only.

## Step 4 — Apply a Minimal Knowledge Patch

- Update only artifacts whose `status` is `stale` or that gained/lost dependencies.
- Preserve unaffected sections, history entries, and user-authored notes verbatim.
- Remove or update links and `depends_on` entries pointing to deleted or renamed files.
- Never claim a test or verification command passed unless it was actually executed in the current session.

## Step 5 — Atomic Checkpoint & Working-Tree Invariants

1. **Never advance on failure or partial completion**
   - Stage updates in `.codeintel/manifests/analysis_state.json.tmp` and validate JSON syntax, schema version, required fields, and artifact path existence before replacing `analysis_state.json`.
   - If any required revalidation stage fails or is interrupted, **preserve the previous `repository.analyzed_commit`**, set `analysis.status` to `"partial"`, mark unrefreshed impacted artifacts as `"stale"`, and list remaining work in `analysis.unresolved_items`.

2. **Working-tree dirtiness accounting**
   - An unchanged `HEAD` commit does not mean the repository is unchanged.
   - Record `repository.working_tree_clean` (`true`/`false`) and `repository.includes_uncommitted_changes` (`true`/`false`).
   - Only advance `repository.analyzed_commit` to `HEAD` when all committed changes up to `HEAD` within the full repository scope have been revalidated.
   - If uncommitted changes exist and were analyzed, set `repository.includes_uncommitted_changes: true` and note that the knowledge state reflects `HEAD` plus dirty working-tree modifications (not a clean `HEAD` snapshot). If uncommitted changes exist and were excluded, do not mark the affected artifacts `"current"` against the working tree.

3. **History log**
   - Append a concise summary under `.codeintel/history/` when meaningful architectural claims, contracts, or findings change.
