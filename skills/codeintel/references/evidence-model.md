# Shared Evidence Model & Write-Ownership Rules

Every analysis role (whether executed as an isolated subagent or sequentially in the main context) must produce findings and claims conforming to this shared evidence model. This prevents incompatible summaries, unsupported assertions, and conflicting file edits.

## 1. Strict Write-Ownership Model

Subagents investigate; the orchestrator owns scope, reconciliation, writing, and checkpointing.

| Component | Responsibility | Can update `.codeintel/`? |
|---|---|---|
| **Orchestrator** | Select mode/scope, dispatch roles, coordinate phases | Orchestration state only |
| **Analysis Agents** (`repository_mapper`, `behavior_tracer`, `test_quality_analyst`, `defect_consistency_auditor`) | Inspect source/tests and return structured evidence | **No** (read-only) |
| **Change Impact Analyst** (`change_impact_analyst`) | Expand drift plan across direct and transitive dependencies | **No** (read-only) |
| **Knowledge Reconciler** (`knowledge_reconciler`) | Resolve cross-agent conflicts, compare against existing claims, propose minimal patch plan | Produces proposed patch plan only (**no** direct writes) |
| **Knowledge Writer** (controlled phase of main skill) | Apply approved, scoped patches while preserving user notes | **Yes** |
| **Validator** (`scripts/codeintel-refresh.sh`, `scripts/validate.sh`) | Deterministically check JSON schemas, links, and invariants | **No** |
| **Checkpoint Manager** (`scripts/codeintel-refresh.sh`) | Promote staged `analysis_state.json.tmp` after validation | **Only after all required checks pass** |

Never use an LLM subagent for a task that a deterministic script (`scripts/codeintel-refresh.sh` or `scripts/validate.sh`) can perform predictably.

## 2. Agent Result Envelope (`agent-result.json`)

Every subagent or analysis pass returns a JSON payload matching [agent-result-template.json](../templates/agent-result-template.json):

```json
{
  "task_id": "refresh-001",
  "agent": "behavior_tracer",
  "scope": [
    "src/payments/"
  ],
  "findings": [],
  "claims": [],
  "dependencies": [
    {
      "from": "src/payments/controller.ts",
      "to": "src/payments/service.ts",
      "kind": "calls"
    }
  ],
  "recommended_updates": [
    "components/payments.md",
    "workflows/checkout.md"
  ],
  "unresolved_questions": [],
  "verification": {
    "source_inspected": true,
    "tests_executed": false,
    "commands_executed": [],
    "limitations": [
      "Gateway webhook callbacks are registered dynamically at runtime"
    ]
  }
}
```

### Envelope invariants
- `agent` must be one of: `repository_mapper`, `behavior_tracer`, `change_impact_analyst`, `test_quality_analyst`, `defect_consistency_auditor`, `knowledge_reconciler`.
- `scope` lists the repository-relative paths or components assigned to the agent.
- If `verification.tests_executed` is `false`, `verification.commands_executed` must not claim test passes, and findings/claims must reflect static inspection only.

## 3. Claim Schema (`claim.json`)

Engineering claims are atomic, falsifiable statements backed by source evidence and explicit file dependencies (see [claim-template.json](../templates/claim-template.json)):

```json
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
  "last_verified_commit": "abc123",
  "evidence_hash": "cksum:21948102-48"
}
```

### Claim fields, confidence vs. freshness, and selective usage
- **`claim_id`**: Stable kebab-case identifier (`claim-<domain>-<topic>-<nnn>`).
- **`statement`**: Precise behavioral or architectural claim. Avoid vague prose when a concrete invariant can be stated.
- **Distinguishing Freshness (`status`) from Confidence (`confidence`)**:
  - **Freshness / Verification (`status`)** answers *"Is the evidence still applicable to the current source?"*:
    - `verified` — directly established by current source inspection and/or executed verification.
    - `observed` — behavior observed, full mechanism not completely traced.
    - `inferred` — supported by strong indirect evidence.
    - `suspected` — plausible hypothesis requiring verification.
    - `unverified` — not checked in the current analysis.
    - `stale` — one or more `depends_on` or `evidence[].path` files changed (or `evidence_hash` drifted) and the claim has not yet been revalidated.
    - `contradicted` — current code or file deletion disproves the previous statement; requires immediate revision or defect filing.
  - **Confidence (`confidence`)** answers *"How strongly does the evidence support this statement?"* (`high`, `medium`, or `low`). A claim can have `high` confidence but become `stale` when its file changes; conversely, a freshly inspected claim may have `low` confidence if it depends on runtime configuration or dynamic dispatch.
- **`evidence`**: Non-empty array for `verified`, `observed`, or `inferred` claims. Line ranges (`lines`) help locate code quickly, but during refresh the implementation itself must be re-inspected rather than trusting line numbers alone.
- **`depends_on`**: Non-empty array of repository-relative paths or directory prefixes that, if modified or deleted, invalidate the claim.
- **`evidence_hash`** *(optional)*: Deterministic content fingerprint (`cksum:<crc>-<bytes>` or `sha256:...`) of the supporting source files so uncommitted working-tree edits invalidate the claim even when `last_verified_commit` matches `HEAD`.
- **Selective structured claims**: Do not create structured claim records for every sentence of descriptive Markdown. Reserve structured claims in `analysis_state.json` for high-consequence statements about:
  1. Security and authorization boundaries
  2. Public interfaces and external contracts
  3. Critical business rules and invariants
  4. Database operations and transaction boundaries
  5. Error handling, timeouts, and retry policies
  6. Confirmed defects
  7. Architectural constraints

## 4. Candidate & Confirmed Finding Schema

When `defect_consistency_auditor` or `behavior_tracer` identifies a potential issue, it records:

```json
{
  "id": "ISS-002",
  "severity": "high",
  "category": "error_handling",
  "title": "Payment failure may be reported as success",
  "status": "candidate",
  "confidence": "medium",
  "evidence": [
    {
      "path": "src/payments/service.ts",
      "symbol": "processPayment",
      "lines": "84-109"
    }
  ],
  "observed_behavior": "Gateway error is logged and function returns default result object.",
  "expected_behavior": "Gateway failure should propagate an error or return a failed status.",
  "verification_required": [
    "Trace the gateway error path into PaymentController",
    "Inspect controller HTTP status mapping",
    "Run the relevant payment integration test"
  ]
}
```

- Findings start as `candidate` (or `strongly_suspected` / `potential_risk` / `design_concern` / `maintainability_concern`) until every item in `verification_required` is checked, at which point `knowledge_reconciler` promotes confirmed defects to `confirmed` (with lifecycle state `open`, `resolved`, `mitigated`, or `accepted` in `KNOWN_ISSUES.md`).
- An existing `open` finding must never be marked `resolved` without direct source or test evidence proving the underlying defect was fixed.
