# Task Routing Guide: `psf/requests`

Use this routing table to jump directly to the exact file and lines responsible for a behavior:

| Developer Task | Relevant Source Files | Reference Lines |
| :--- | :--- | :--- |
| **Change how URLs or query parameters are parsed** | `src/requests/models.py` | `PreparedRequest.prepare_url` (~lines 380-450) |
| **Add or alter default request headers** | `src/requests/utils.py` | `default_headers`, `default_user_agent` |
| **Fix cookie jar merging between Session and Request** | `src/requests/sessions.py`<br>`src/requests/cookies.py` | `Session.request` (~lines 510-540)<br>`merge_cookies` |
| **Modify HTTP redirect behavior or header stripping** | `src/requests/sessions.py` | `SessionRedirectMixin.resolve_redirects`<br>`should_strip_auth` |
| **Update SSL certificate verification or CA paths** | `src/requests/adapters.py` | `HTTPAdapter.cert_verify` |
| **Adjust connection pooling defaults (size, block)** | `src/requests/adapters.py` | `HTTPAdapter.__init__`, `init_poolmanager` |
| **Add or change authentication scheme** | `src/requests/auth.py` | Subclass `AuthBase` |
| **Translate a new urllib3 error** | `src/requests/adapters.py` | `HTTPAdapter.send` exception handler block |
| **Change JSON deserialization behavior in Response** | `src/requests/models.py` | `Response.json` (~lines 950-1000) |
