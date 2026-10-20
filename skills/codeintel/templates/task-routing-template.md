# Task Routing

Replace these examples with actual paths and commands from this repository.

| Task | Starting point | Also inspect | Knowledge docs (`.codeintel/`) | Verification |
|---|---|---|---|---|
| Add an API endpoint | Route/controller | Validation, authorization, service, contract, consumers | `API_AND_CONTRACTS.md`, `DESIGN_PRINCIPLES.md`, `FEATURE_IMPLEMENTATION_GUIDE.md` | API/integration tests + incremental refresh |
| Change a business rule | Domain/service | Callers, invariants, related workflows | `components/<domain>.md`, `workflows/<flow>.md`, `DEPENDENCY_MAP.md` | Unit/regression tests + incremental refresh |
| Change a database model | Schema/model | Migrations, repositories, consumers | `DATA_FLOW.md`, `API_AND_CONTRACTS.md`, `DEPENDENCY_MAP.md` | Migration/integration tests + incremental refresh |
| Fix a UI defect | UI component | State, shared components, API response contract | `components/<ui>.md`, `API_AND_CONTRACTS.md`, `KNOWN_ISSUES.md` | Component/E2E tests + incremental refresh |
| Fix authorization | Auth boundary | Alternate entry points and policies | `ARCHITECTURE.md`, `API_AND_CONTRACTS.md`, `KNOWN_ISSUES.md` | Positive and negative auth tests + incremental refresh |
| Improve performance | Measured hotspot | Callers, queries, cache, concurrency | `DATA_FLOW.md`, `workflows/<flow>.md`, `DEPENDENCY_MAP.md` | Profiling and regression tests + incremental refresh |
| Refactor shared code | Shared abstraction | All consumers and compatibility contracts | `DEPENDENCY_MAP.md`, `COMPONENT_CATALOG.md`, `DESIGN_PRINCIPLES.md` | Focused plus broader tests + incremental refresh |

For each row, record real repository paths, key symbols, `.codeintel/` documentation links, and verified commands. Do not leave generic examples as if they were repository facts.
