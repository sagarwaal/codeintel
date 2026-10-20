# Change-Impact Analysis & Dependency Propagation

Deterministic file matching (`artifacts.<doc>.depends_on` and `claims[].depends_on`) is only the starting point for refresh. `change_impact_analyst` expands the initial change set into a complete impact graph before investigation begins.

## 1. Direct vs. Indirect Impact

When a file changes, classify impact into three tiers:

1. **Directly affected**
   - Component documentation, claims, and findings whose `depends_on` includes the changed, deleted, or renamed path.
   - Workflows that step through the modified function or handler.

2. **Indirectly affected (transitive propagation)**
   - **Callers and consumers:** Components that invoke a modified function, instantiate a changed class, or read a modified state store.
   - **Contracts and shared types:** API routes, serializers, event payloads, database models, and UI consumers that depend on a changed type or status enum.
   - **Cross-cutting boundaries:** If an authentication, authorization, validation, transaction, retry, or error-handling helper changes, every entry point or workflow relying on that boundary must be reconsidered even if its own source file is untouched.
   - **Test strategy & coverage:** Test suites covering the modified behavior or its downstream callers.

3. **Needs targeted investigation**
   - Behavioral invariants (idempotency, retry semantics, ordering, rollback guarantees, caching assumptions) that could be altered by the change.
   - Dynamic dispatch, reflection, dependency-injection containers, plugin registries, or event buses where static imports do not reveal all consumers.

## 2. Propagation Rules by Change Type

| Change category | Direct impact | Transitive propagation required |
|---|---|---|
| **Entry point / bootstrap** (`src/app.*`, `main.*`, `cmd/*`) | `ARCHITECTURE.md`, `agents/QUICK_START.md` | Middleware ordering, global error handlers, lifecycle hooks, configuration loading |
| **Shared type / interface / contract** (`types/*`, `contracts/*`, `*.proto`, `openapi.*`) | `API_AND_CONTRACTS.md`, `COMPONENT_CATALOG.md` | All implementing services, API controllers, client consumers, contract/integration tests |
| **Auth / security / validation middleware** | Owning component doc, `SECURITY_REVIEW.md` | Protected routes, alternate entry points, negative authorization tests, open security findings |
| **Persistence / schema / migration** | `DOMAIN_MODEL.md`, `DATA_FLOW.md` | Repositories, domain services, transaction boundaries, rollback behavior, data-integrity invariants |
| **Business logic / domain service** | Owning `components/*.md`, `workflows/*.md` | Upstream controllers/jobs, downstream events/side effects, domain invariants, `KNOWN_ISSUES.md` |
| **Test suite / test config** | `TEST_STRATEGY.md`, `TEST_COVERAGE_GAPS.md`, `COVERAGE_MATRIX.md` | Verification status of claims previously backed by modified or deleted tests |
| **File or symbol deletion / rename** | All references in `INDEX.md`, catalogs, maps, and `depends_on` | Callers that imported the symbol, task-routing tables, onboarding examples |

## 3. Output Format for Impact Analysis

`change_impact_analyst` returns a structured result (conforming to [evidence-model.md](evidence-model.md)) that categorizes:

- `recommended_scope`: `"incremental"`, `"scoped"`, or `"full"` with explicit justification.
- `directly_affected_artifacts`: Markdown files in `.codeintel/` requiring update.
- `indirectly_affected_artifacts`: Downstream docs and contracts requiring revalidation.
- `stale_claims`: Claim IDs whose `depends_on` or upstream invariants changed.
- `deleted_or_renamed_references`: Paths and symbols that must be purged or updated.
- `agents_to_dispatch`: Which specialist roles (`behavior_tracer`, `test_quality_analyst`, `defect_consistency_auditor`, `repository_mapper`) should run in Phase 3 (Investigate) and with what file scope.
- `unresolved_questions`: Dynamic or external dependencies that could not be statically resolved.
