# Test Coverage Gaps: `psf/requests`

> **Note:** The following findings are based on static code inspection of the test suite and source paths in `v2.32.3`.

## 1. Streaming Teardown and Unconsumed Socket Edge Cases
- **Affected Path:** `src/requests/models.py:750-860` (`Response.iter_content`, `Response.close`)
- **Inspection Finding:** While `Response.close()` explicitly calls `self.raw.close()`, integration tests rarely verify connection pool health when an exception is raised mid-stream during an `iter_content(decode_unicode=True)` generator execution.
- **Risk:** Unconsumed raw sockets may remain checked out of the `urllib3` connection pool if caller fails to wrap the stream in a context manager, potentially causing connection pool starvation.
- **Confidence:** `INFERRED`

## 2. Dynamic Complex Proxy Configuration Combinations
- **Affected Path:** `src/requests/adapters.py:220-270` (`HTTPAdapter.proxy_headers`)
- **Inspection Finding:** Test coverage for socks proxies with mutual TLS authentication (mTLS) combined with HTTP fallback proxies is sparse due to lack of local mock infrastructure for multi-hop proxy tunnels.
- **Risk:** Regressions in urllib3 proxy tunneling upgrades may go undetected in pure unit tests.
- **Confidence:** `OBSERVED`

## 3. Redirect Strip Auth on Scheme Downgrade or Port Change
- **Affected Path:** `src/requests/sessions.py:220-300` (`SessionRedirectMixin.should_strip_auth`)
- **Inspection Finding:** Test cases cover stripping `Authorization` headers when redirecting from HTTPS to HTTP or cross-domain, but coverage for non-standard port shifts on the same hostname (e.g. `example.com:8443` -> `example.com:443`) is minimal.
- **Confidence:** `VERIFIED`
