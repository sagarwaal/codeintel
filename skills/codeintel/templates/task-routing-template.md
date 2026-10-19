# Task Routing

Replace these examples with actual paths and commands from this repository.

| Task | Starting point | Also inspect | Verification |
|---|---|---|---|
| Add an API endpoint | Route/controller | Validation, authorization, service, contract, consumers | API/integration tests |
| Change a business rule | Domain/service | Callers, invariants, related workflows | Unit/regression tests |
| Change a database model | Schema/model | Migrations, repositories, consumers | Migration/integration tests |
| Fix a UI defect | UI component | State, shared components, API response contract | Component/E2E tests |
| Fix authorization | Auth boundary | Alternate entry points and policies | Positive and negative auth tests |
| Improve performance | Measured hotspot | Callers, queries, cache, concurrency | Profiling and regression tests |
| Refactor shared code | Shared abstraction | All consumers and compatibility contracts | Focused plus broader tests |

For each row, record real repository paths, key symbols, documentation links, and verified commands. Do not leave generic examples as if they were repository facts.
