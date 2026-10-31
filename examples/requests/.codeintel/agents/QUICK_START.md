# Agent Quick Start: `psf/requests`

Welcome, AI Agent! Use this quick-start guide to navigate `psf/requests` without re-reading the entire codebase.

---

## ⚡ 60-Second Orientation
- **Core Orchestrator:** `src/requests/sessions.py` (`Session`).
- **Data Models:** `src/requests/models.py` (`Request`, `PreparedRequest`, `Response`).
- **Network Transport:** `src/requests/adapters.py` (`HTTPAdapter`).
- **Top-Level Entry Point:** `src/requests/api.py`.
- **Underlying Engine:** `urllib3` (manages connections and pools).

---

## 🧭 Workflow Handoff Table

| When You Are Doing... | Start By Reading... | Key Rule to Remember |
| :--- | :--- | :--- |
| **Planning a feature** | `.codeintel/FEATURE_IMPLEMENTATION_GUIDE.md` | Any new parameter must be threaded through `api.py` ➔ `sessions.py` ➔ `models.py`/`adapters.py`. |
| **Debugging network errors** | `src/requests/adapters.py:510-600` | All `urllib3` errors must be caught and converted to `requests.exceptions`. |
| **Working on Cookies** | `src/requests/cookies.py` | Requests uses `RequestsCookieJar`, which subclasses Python's standard `http.cookiejar.CookieJar`. |
| **Reviewing PRs / Changes** | `.codeintel/agents/REVIEW_CHECKLIST.md` | Ensure backwards compatibility and verify no network requests leak in unit tests. |

---

## 🛠️ Verification Command
```bash
pytest
```
Run tests locally before concluding any implementation task.
