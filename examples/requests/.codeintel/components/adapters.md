# Component: `HTTPAdapter` (`requests.adapters`)

## Overview
`HTTPAdapter` is the built-in transport adapter that connects `requests` to `urllib3`. It manages the creation and pooling of socket connections through `urllib3.PoolManager` and handles proxy tunneling through `urllib3.ProxyManager`.

## Source Location
`src/requests/adapters.py:54`

## Key Responsibilities
1. **Connection Pool Management:** Instantiates and configures `urllib3.PoolManager` with pool sizing (`pool_connections`, `pool_maxsize`), max retries, and SSL certificate context.
2. **Proxy Resolution:** Detects environment proxies (`get_environ_proxies`) and mounts `ProxyManager` instances as needed.
3. **PreparedRequest Execution:** Takes a `PreparedRequest`, extracts target connection host/port, checks out a connection from `PoolManager`, and issues the low-level `urlopen()` call.
4. **Exception Translation:** Catches all `urllib3` errors (e.g. `MaxRetryError`, `SSLError`, `TimeoutError`, `ProtocolError`) and re-raises them as unified `requests.exceptions.*` errors.
5. **Response Packaging:** Takes the `urllib3.response.HTTPResponse` and wraps it into a `requests.models.Response` instance via `build_response()`.

## Customization Patterns
Subclassing `HTTPAdapter` is the official mechanism in Requests for:
- Implementing custom retry logic using `urllib3.util.Retry`.
- Adjusting socket timeout defaults or TCP keepalive options.
- Binding connections to specific network interfaces or SSL ciphers.
