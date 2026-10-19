# Repository Change Review Checklist

## Scope and design
- [ ] The correct owning component and architectural layer were identified.
- [ ] Existing contracts and invariants were inspected.
- [ ] A suitable reference implementation was considered.
- [ ] The change is the smallest coherent solution.
- [ ] Unrelated refactoring was avoided or separately justified.

## Correctness
- [ ] Happy path and boundary conditions are handled.
- [ ] Validation and authorization are enforced at the appropriate boundaries.
- [ ] Errors are propagated or handled according to project conventions.
- [ ] State transitions and data integrity are preserved.
- [ ] Concurrency, retries, and resource lifecycle are considered where relevant.
- [ ] Downstream consumers and alternate entry points were inspected.

## Tests
- [ ] Focused tests cover the changed behavior.
- [ ] Negative and boundary cases are covered.
- [ ] Regression tests cover the defect when applicable.
- [ ] Integration/contract tests were considered.
- [ ] Tests actually executed are recorded accurately.

## Operations and security
- [ ] Sensitive values are not logged or documented.
- [ ] Timeouts, resource limits, and failure modes were considered where relevant.
- [ ] Observability is sufficient for diagnosing failures.
- [ ] Migration, deployment, and compatibility effects were considered.

## Knowledge maintenance
- [ ] Affected architecture/component/contract docs were updated.
- [ ] Dependency and task-routing information was refreshed if needed.
- [ ] Findings and coverage gaps were updated.
- [ ] Analysis state and history accurately reflect the work.
- [ ] Stale or unverified claims are labeled.
