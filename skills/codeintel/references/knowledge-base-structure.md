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
- Confidence and status
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
- Verification status

## Analysis-state fields

Use JSON fields such as:

```json
{
  "schema_version": 1,
  "repository_root": ".",
  "commit": null,
  "branch": null,
  "analyzed_at": null,
  "phases_completed": [],
  "areas_analyzed": [],
  "areas_partially_analyzed": [],
  "areas_not_analyzed": [],
  "excluded_paths": [],
  "commands_executed": [],
  "verification_results": [],
  "unresolved_questions": [],
  "limitations": []
}
```

Populate only with truthful values. Never include secrets or sensitive environment data.
