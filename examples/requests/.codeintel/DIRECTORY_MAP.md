# Directory Map: `psf/requests`

| Path | Purpose | Key Files & Entry Points |
| :--- | :--- | :--- |
| `src/requests/` | Core package source root. | `__init__.py` |
| `src/requests/api.py` | Top-level convenience functions (`get`, `post`, `request`). | `request()`, `get()`, `post()` |
| `src/requests/sessions.py` | State persistence, connection reuse, redirect loops, adapter mounting. | `Session`, `SessionRedirectMixin` |
| `src/requests/adapters.py` | Transport layer mapping `PreparedRequest` to `urllib3.PoolManager`. | `BaseAdapter`, `HTTPAdapter` |
| `src/requests/models.py` | Request/Response data models and data serialization. | `Request`, `PreparedRequest`, `Response` |
| `src/requests/auth.py` | Authentication handlers. | `AuthBase`, `HTTPBasicAuth`, `HTTPDigestAuth` |
| `src/requests/cookies.py` | CookieJar compatibility, extraction, and merging helpers. | `RequestsCookieJar`, `cookiejar_from_dict` |
| `src/requests/exceptions.py` | Exception hierarchy rooted in `RequestException`. | `RequestException`, `HTTPError`, `ConnectionError`, `Timeout` |
| `src/requests/structures.py` | Internal specialized data structures. | `CaseInsensitiveDict`, `LookupDict` |
| `src/requests/utils.py` | Common utility functions (URL quoting, header parsing, proxy discovery). | `get_environ_proxies`, `super_len`, `urldefragauth` |
| `src/requests/compat.py` | Python standard library compatibility shims. | `urlparse`, `str`, `bytes` imports |
| `src/requests/status_codes.py` | HTTP status code lookup dict (`codes.ok`, `codes.not_found`). | `_codes`, `codes` |
| `tests/` | Pytest test suite covering unit and integration scenarios. | `test_requests.py`, `conftest.py` |
| `tests/testserver/` | Threaded socket server used to test HTTP behavior without internet access. | `server.py` |
| `tests/certs/` | Test certificates (valid, expired, and mTLS certificates). | `certs/valid/`, `certs/expired/`, `certs/mtls/` |
