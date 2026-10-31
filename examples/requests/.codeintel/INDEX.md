# CodeIntel Knowledge Base: `psf/requests`

> **Repository:** [psf/requests](https://github.com/psf/requests)  
> **Analyzed Version:** `v2.32.3` (`0e322af87745eff34caffe4df68456ebc20d9068`)  
> **Schema Version:** 2  
> **Analysis Mode:** Deep Analysis (Offline showcase)

Welcome to the CodeIntel knowledge base for **Requests: HTTP for Humans™**. This directory is an evidence-backed architectural and engineering map generated to ground AI coding agents and engineers navigating, extending, or debugging `requests`.

---

## 🗺️ Key Documents & Entry Points

| Document | Purpose & Key Takeaways |
| :--- | :--- |
| **[`PROJECT_PROFILE.md`](PROJECT_PROFILE.md)** | Core domain overview, ecosystem role, target environments, and external runtime dependencies (`urllib3`, `certifi`, `charset_normalizer`/`chardet`, `idna`). |
| **[`ARCHITECTURE.md`](ARCHITECTURE.md)** | End-to-end architecture diagram, separation between user-facing `Session`/`Request` models and transport `HTTPAdapter`/`urllib3` layer. |
| **[`DIRECTORY_MAP.md`](DIRECTORY_MAP.md)** | Directory tree annotated with responsibilities, entry points, and test harnesses. |
| **[`COMPONENT_CATALOG.md`](COMPONENT_CATALOG.md)** | Component directory indexing `Session`, `PreparedRequest`, `Response`, `HTTPAdapter`, `AuthBase`, and utility helpers. |
| **[`DEPENDENCY_MAP.md`](DEPENDENCY_MAP.md)** | Internal coupling and blast radius matrix; downstream consumer impact. |
| **[`DATA_FLOW.md`](DATA_FLOW.md)** | Request lifecycle state machine: un-prepared `Request` ➔ `PreparedRequest` ➔ `send()` ➔ raw socket response ➔ `Response`. |
| **[`API_AND_CONTRACTS.md`](API_AND_CONTRACTS.md)** | Public top-level API contracts (`requests.api`), session contracts, and adapter mount interfaces. |
| **[`DESIGN_PRINCIPLES.md`](DESIGN_PRINCIPLES.md)** | Human-centric design, backwards compatibility rules, error hierarchy conventions, and reference implementations. |
| **[`TEST_STRATEGY.md`](TEST_STRATEGY.md)** | Test runner harness, test server patterns (`tests/testserver/`), and recommended test commands for regression prevention. |
| **[`TEST_COVERAGE_GAPS.md`](TEST_COVERAGE_GAPS.md)** | Behavioral coverage gaps identified by static inspection (e.g. streaming teardown edge cases, custom proxy auth permutations). |
| **[`KNOWN_ISSUES.md`](KNOWN_ISSUES.md)** | Evidence-backed audit findings, historical architectural invariants, and gotchas. |
| **[`FEATURE_IMPLEMENTATION_GUIDE.md`](FEATURE_IMPLEMENTATION_GUIDE.md)** | Step-by-step recipe for safely extending `requests` without breaking public API invariants. |

---

## 🤖 Agent Guides

- **[`agents/QUICK_START.md`](agents/QUICK_START.md)**: 60-second orientation for autonomous coding agents.
- **[`agents/TASK_ROUTING.md`](agents/TASK_ROUTING.md)**: Task-to-file lookup table (e.g. "Modifying cookie handling", "Adding default adapter headers", "Adding proxy authentication").
- **[`agents/REVIEW_CHECKLIST.md`](agents/REVIEW_CHECKLIST.md)**: Pre-commit / PR sanity checks for changes to `requests`.

---

## 🔍 Deep-Dive Specifications

### Components (`components/`)
- [`components/sessions.md`](components/sessions.md): `requests.sessions.Session` state management, cookie merging, redirect loops, and adapter routing.
- [`components/adapters.md`](components/adapters.md): `requests.adapters.HTTPAdapter` connection pooling, proxy resolution, and urllib3 bridging.
- [`components/models.md`](components/models.md): `Request`, `PreparedRequest`, and `Response` representations, encoding detection, and hook triggers.
- [`components/auth.md`](components/auth.md): Authentication dispatch (`HTTPBasicAuth`, `HTTPDigestAuth`, and custom `AuthBase` implementations).

### Workflows (`workflows/`)
- [`workflows/get-request-trace.md`](workflows/get-request-trace.md): Step-by-step trace of `requests.get()` from call-site to HTTPAdapter socket read and `Response` return.

---

## 📊 Manifest

- **[`manifests/analysis_state.json`](manifests/analysis_state.json)**: Schema v2 manifest tracking analyzed commit hash, claim verification statuses, and file-dependency graph.
