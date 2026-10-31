# Component: `Session` (`requests.sessions`)

## Overview
`Session` is the stateful HTTP client object in `requests`. It preserves cookie jars across requests, holds persistent configuration (authentication, default headers, proxies, SSL verification settings), and manages transport adapter routing via mounted URL prefixes.

## Source Location
`src/requests/sessions.py:348`

## Key Responsibilities
1. **Cookie Jar Maintenance:** Merges incoming `Set-Cookie` response headers into `self.cookies` (`RequestsCookieJar`) and attaches them to subsequent outgoing requests.
2. **Adapter Routing:** Maintains `self.adapters` mapping prefix strings (e.g., `'https://'`, `'http://'`) to `BaseAdapter` implementations.
3. **Redirect Loop Execution:** Implements `SessionRedirectMixin.resolve_redirects` to handle HTTP 301, 302, 303, 307, and 308 response codes up to `self.max_redirects` (default 30).
4. **Auth Persistence:** Holds `self.auth` which is applied to any request where caller does not specify per-call `auth`.

## Critical Public Methods
- `request(method, url, ...)`: Constructs `Request`, passes to `prepare_request()`, sends via `send()`.
- `prepare_request(request)`: Merges session settings with the given `Request` and returns a `PreparedRequest`.
- `send(request, **kwargs)`: Dispatches `PreparedRequest` to the matching adapter, processes redirects, runs response hooks.
- `mount(prefix, adapter)`: Registers a transport adapter for a given URL scheme or domain prefix.
- `close()`: Closes all mounted adapters, flushing and closing underlying connection pools.

## Invariants
- A `Session` is not thread-safe for simultaneous mutating requests using shared cookies, though underlying `urllib3` connection pools are thread-safe.
- Must be used as a context manager (`with requests.Session() as s:`) or explicitly closed to avoid lingering open sockets.
