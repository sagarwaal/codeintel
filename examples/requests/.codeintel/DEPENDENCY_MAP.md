# Dependency Map & Blast Radius: `psf/requests`

## Internal Coupling Graph

```text
requests.api
  └── requests.sessions.Session
        ├── requests.models.Request
        │     └── requests.models.PreparedRequest
        ├── requests.adapters.HTTPAdapter (implements BaseAdapter)
        │     └── urllib3.PoolManager / ProxyManager
        ├── requests.cookies.RequestsCookieJar
        └── requests.auth (AuthBase, HTTPBasicAuth)
```

## Blast Radius Analysis

### High Blast Radius Components
1. **`requests.models.PreparedRequest`**
   - **Impact Level:** 🚨 Critical
   - **Reason:** Every adapter, hook, and authentication handler operates on `PreparedRequest`. Any modification to its internal attributes (`.url`, `.headers`, `.body`, `.hooks`) affects all transport adapters and session pipelines.
2. **`requests.sessions.Session.send`**
   - **Impact Level:** 🚨 Critical
   - **Reason:** Core dispatch pipeline responsible for resolving adapter targets, attaching cookies, and executing redirect loops. Changes here affect every HTTP request in the library.
3. **`requests.adapters.HTTPAdapter.send`**
   - **Impact Level:** 🚨 Critical
   - **Reason:** Direct bridge to `urllib3`. Handles exception translation, timeout mapping, proxy configuration, and certificate validation.

### Low Blast Radius Components
1. **`requests.status_codes`**: Static lookup dict; modifying entries affects only status symbol resolution (`codes.ok`).
2. **`requests.help`**: Informational module printing environment diagnostics; has zero runtime side effects on HTTP operations.
