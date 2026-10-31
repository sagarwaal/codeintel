# Design Principles & Reference Implementations: `psf/requests`

## Core Design Principles

1. **Explicit Ergonomics over Obscure Configuration:** The API defaults to what 99% of developers need (automatic redirect following on GET, JSON decoding helper, connection pooling, cert verification enabled by default).
2. **Defensive Translation of Underlying Exceptions:** Never leak `urllib3` exceptions directly to the user. Every `urllib3` error must be caught in `HTTPAdapter.send` and re-raised as a corresponding `requests.exceptions.RequestException` subclass.
3. **Pluggable Architecture via Adapters:** Transport-level variations (retries, UNIX domain sockets, mock backends) are extended via `HTTPAdapter` subclasses mounted to URL prefixes, keeping the `Session` orchestrator clean.

---

## Canonical Reference Patterns

### Pattern 1: Translation of Transport Exceptions
- **Reference:** `src/requests/adapters.py:510-600`
- **Why it is a good reference:** Demonstrates the canonical pattern for catching low-level socket/HTTP client errors and converting them into high-level user-friendly exceptions without losing traceback context.

### Pattern 2: Custom Authentication via `AuthBase`
- **Reference:** `src/requests/auth.py:72-102` (`HTTPBasicAuth`)
- **Implementation Guide:**
  ```python
  from requests.auth import AuthBase

  class CustomTokenAuth(AuthBase):
      def __init__(self, token):
          self.token = token

      def __call__(self, r):
          # Mutate PreparedRequest headers
          r.headers['X-Custom-Token'] = self.token
          return r
  ```
- **Why it is a good reference:** Shows how authentication handlers hook cleanly into `PreparedRequest` before network dispatch without tight coupling to the transport adapter.
