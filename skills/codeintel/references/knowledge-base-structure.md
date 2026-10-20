# Knowledge Base Structure

Adapt this structure to the repository. Do not create empty boilerplate files.

```text
.codeintel/
├── INDEX.md
├── PROJECT_PROFILE.md
├── ARCHITECTURE.md
├── DIRECTORY_MAP.md
├── COMPONENT_CATALOG.md
├── DEPENDENCY_MAP.md
├── DATA_FLOW.md
├── DOMAIN_MODEL.md
├── API_AND_CONTRACTS.md
├── DESIGN_PRINCIPLES.md
├── CODING_CONVENTIONS.md
├── TEST_STRATEGY.md
├── TEST_COVERAGE_GAPS.md
├── KNOWN_ISSUES.md
├── TECHNICAL_DEBT.md
├── SECURITY_REVIEW.md
├── PERFORMANCE_REVIEW.md
├── OBSERVABILITY.md
├── FEATURE_IMPLEMENTATION_GUIDE.md
├── DEBUGGING_PLAYBOOK.md
├── DECISIONS.md
├── VERIFICATION_LOG.md
├── COVERAGE_MATRIX.md
├── agents/
│   ├── QUICK_START.md
│   ├── TASK_ROUTING.md
│   ├── CHANGE_PROTOCOL.md
│   └── REVIEW_CHECKLIST.md
├── components/
├── workflows/
├── maps/
├── findings/
├── manifests/
│   ├── source_inventory.json
│   ├── component_inventory.json
│   └── analysis_state.json
└── history/
```

## Suggested contents

- `INDEX.md`: project overview, links, task routing, highest risks, analysis status.
- `PROJECT_PROFILE.md`: purpose, use cases, stack, runtime, constraints.
- `ARCHITECTURE.md`: actual architecture, layers, boundaries, startup, critical paths.
- `DIRECTORY_MAP.md`: important directories and responsibilities.
- `COMPONENT_CATALOG.md`: component inventory and ownership.
- `DEPENDENCY_MAP.md`: high-value relationships and change-impact notes.
- `DATA_FLOW.md`: important data paths and transformations.
- `DOMAIN_MODEL.md`: entities, invariants, and domain relationships.
- `API_AND_CONTRACTS.md`: API, event, persistence, and compatibility contracts.
- `DESIGN_PRINCIPLES.md`: observed principles, justified exceptions, and recommendations.
- `CODING_CONVENTIONS.md`: naming, structure, error handling, tests, and framework idioms.
- `TEST_STRATEGY.md`: test types, commands, prerequisites, and verification guidance.
- `TEST_COVERAGE_GAPS.md`: behavior-level gaps, confidence, and recommended tests.
- `KNOWN_ISSUES.md`: evidence-backed defect/risk records.
- `TECHNICAL_DEBT.md`: maintainability concerns and prioritized remediation.
- `SECURITY_REVIEW.md`: scoped security observations and unverified areas.
- `PERFORMANCE_REVIEW.md`: measured findings and hypotheses to profile.
- `OBSERVABILITY.md`: logs, metrics, traces, health checks, and operational diagnosis.
- `FEATURE_IMPLEMENTATION_GUIDE.md`: safe feature workflow and reference patterns.
- `DEBUGGING_PLAYBOOK.md`: common investigation paths and commands.
- `DECISIONS.md`: important design decisions, evidence, trade-offs, and status.
- `VERIFICATION_LOG.md`: commands run, dates, results, and limitations.
- `COVERAGE_MATRIX.md`: components/behaviors mapped to tests.
- `agents/`: concise agent-facing onboarding, task routing, change protocol, and review checklist.
- `components/`: deep notes for complex or high-impact components.
- `workflows/`: end-to-end workflow traces.
- `maps/`: Mermaid diagrams and dependency maps.
- `findings/`: detailed audit findings if the top-level issue file becomes too large.
- `manifests/`: machine-readable inventories and analysis state.
- `history/`: concise summaries of meaningful knowledge updates.

## Finding record template

For each significant finding, capture:

- ID and title
- Category and severity
- Confidence and status (`open`, `resolved`, `mitigated`, `accepted`)
- Affected paths/symbols
- Evidence
- Observed behavior
- Expected behavior
- Trigger/reproduction conditions
- Impact
- Root-cause status
- Recommended remediation
- Regression tests
- Related components
- Verification status (`VERIFIED`, `OBSERVED`, `INFERRED`, `SUSPECTED`, `UNVERIFIED`, `STALE`)

## Analysis-state fields

`.codeintel/manifests/analysis_state.json` is the authoritative machine-readable manifest of what was analyzed, which source files each knowledge document depends on, and whether each artifact is current or stale. Start from [analysis-state-template.json](../templates/analysis-state-template.json).

### Schema v2 format

```json
{
  "schema_version": 2,
  "repository": {
    "root": ".",
    "branch": "main",
    "head_commit": "abc123",
    "analyzed_commit": "abc123",
    "working_tree_clean": true,
    "includes_uncommitted_changes": false
  },
  "analysis": {
    "status": "complete",
    "scope": "full",
    "last_successful_refresh": "2026-10-20T00:00:00Z",
    "unresolved_items": [],
    "excluded_paths": [],
    "commands_executed": [],
    "verification_results": [],
    "limitations": []
  },
  "artifacts": {
    "ARCHITECTURE.md": {
      "depends_on": [
        "src/app.ts",
        "src/routes.ts"
      ],
      "status": "current"
    },
    "TEST_STRATEGY.md": {
      "depends_on": [
        "package.json",
        "tests/"
      ],
      "status": "current"
    }
  },
  "claims": [
    {
      "claim_id": "claim-payment-retry-001",
      "statement": "Connection timeouts are retried up to three times; HTTP 5xx responses are not retried.",
      "status": "verified",
      "confidence": "high",
      "evidence": [
        {
          "path": "src/payments/retry.ts",
          "symbol": "retryPayment",
          "lines": "20-48"
        }
      ],
      "depends_on": [
        "src/payments/retry.ts",
        "src/payments/service.ts"
      ],
      "last_verified_commit": "abc123"
    }
  ]
}
```

*(Illustrative values only; populate only with truthful repository state. Never store secrets or sensitive environment data. See [evidence-model.md](evidence-model.md) for the full `claim.json` and `agent-result.json` schemas.)*

### Required fields and invariants

1. **`schema_version`**: Integer `2`.
2. **`repository`**:
   - `head_commit`: Commit SHA at the time of inspection (`null` if not a Git repository).
   - `analyzed_commit`: Last commit SHA for which a full or incremental refresh completed all required stages (`null` if not yet completed). **Invariant:** Must never advance when a refresh fails or completes only partially.
   - `working_tree_clean`: Boolean indicating whether the working tree had no staged/unstaged/untracked changes when inspected.
   - `includes_uncommitted_changes`: Boolean indicating whether uncommitted working-tree changes were folded into the analysis. If `true`, the knowledge base reflects `head_commit` plus local modifications, not a clean `head_commit` tree.
3. **`analysis`**:
   - `status`: One of `"complete"`, `"partial"`, or `"stale"`.
   - `scope`: Last executed refresh scope (`"full"`, `"incremental"`, or `"scoped"`).
   - `last_successful_refresh`: ISO-8601 UTC timestamp of the last successful analysis or refresh (`null` if none).
   - `unresolved_items`: Array of strings or objects describing unverified claims, dynamic dependencies, or incomplete refresh steps.
4. **`artifacts`**:
   - Keyed by path relative to `.codeintel/` (for example `"ARCHITECTURE.md"`, `"components/auth.md"`).
   - `depends_on`: Non-empty array of repository-relative file paths or directory prefixes (ending with `/`) that support the claims in that artifact.
   - `status`: One of `"current"`, `"stale"`, or `"unverified"`.
   - **Invariant:** `analysis.status` cannot be `"complete"` if any artifact in the declared scope has `status: "stale"`.

### Backward-compatible migration (Schema v1 -> Schema v2)

Existing `.codeintel/` knowledge bases using `"schema_version": 1` must **not** be discarded or rebuilt from scratch solely due to the schema upgrade. Migrate v1 manifests in place:

1. Map top-level v1 fields into v2 structure:
   - `commit` -> `repository.head_commit` and `repository.analyzed_commit`
   - `branch` -> `repository.branch`
   - `repository_root` -> `repository.root`
   - `analyzed_at` -> `analysis.last_successful_refresh`
   - `unresolved_questions` -> `analysis.unresolved_items`
   - Preserve `excluded_paths`, `commands_executed`, `verification_results`, and `limitations` under `analysis`.
2. Set `analysis.status` to `"complete"` if `commit` was non-null and `areas_partially_analyzed` / `areas_not_analyzed` were empty; otherwise set `"partial"`.
3. Scan existing `.codeintel/**/*.md` files to populate `artifacts`:
   - Extract referenced repository file/directory paths into `depends_on`.
   - Set `status` to `"current"` when `depends_on` is populated, or `"unverified"` if dependencies have not yet been mapped.
4. Validate the migrated v2 object and write it atomically via `manifests/analysis_state.json.tmp` -> `manifests/analysis_state.json`.
