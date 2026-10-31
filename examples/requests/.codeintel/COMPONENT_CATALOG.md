# Component Catalog: `psf/requests`

### 1. `Session` (`requests.sessions.Session`)
- **Location:** `src/requests/sessions.py:348`
- **Role:** Central orchestrator for request execution and client-side state (cookies, headers, authentication, adapter registry).
- **Key Methods:** `request()`, `send()`, `mount()`, `prepare_request()`, `resolve_redirects()`.
- **Contracts:** Inherits from `SessionRedirectMixin`. Must be closed via `.close()` or used as a context manager (`with Session() as s:`) to properly dispose underlying connection pools.

### 2. `PreparedRequest` (`requests.models.PreparedRequest`)
- **Location:** `src/requests/models.py:277`
- **Role:** Holds the fully evaluated request payload. Prepared requests contain canonicalized headers, serialized body streams, and full URLs.
- **Key Methods:** `prepare()`, `prepare_url()`, `prepare_headers()`, `prepare_body()`, `prepare_auth()`, `copy()`.
- **Invariants:** Does not execute network I/O. Safe to clone and inspect before execution.

### 3. `Response` (`requests.models.Response`)
- **Location:** `src/requests/models.py:601`
- **Role:** Encapsulates server HTTP response metadata and body content.
- **Key Attributes / Methods:** `status_code`, `headers`, `content` (raw bytes), `text` (decoded str), `json()`, `iter_content()`, `raise_for_status()`.
- **Contracts:** `response.raw` holds the raw `urllib3.response.HTTPResponse` object. Accessing `.content` caches all bytes in memory.

### 4. `HTTPAdapter` (`requests.adapters.HTTPAdapter`)
- **Location:** `src/requests/adapters.py:54`
- **Role:** Bridges `requests` with `urllib3.PoolManager`. Manages socket connection pools, TLS configurations (`cert`, `verify`), and translates `urllib3` exceptions into `requests.exceptions`.
- **Key Methods:** `send()`, `build_response()`, `get_connection()`, `close()`.
- **Invariants:** Owns connection pool lifecycles. Can be subclassed to implement custom retry logic, circuit breakers, or custom transports.

### 5. `CaseInsensitiveDict` (`requests.structures.CaseInsensitiveDict`)
- **Location:** `src/requests/structures.py:13`
- **Role:** Specialized mapping structure for HTTP headers where lookup is case-insensitive, while preserving the casing of original keys when iterated over.
