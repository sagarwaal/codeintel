# Workflow Trace: `requests.get()` End-to-End

This document traces the complete execution path of a call to `requests.get('https://example.com/api', params={'q': 'python'}, headers={'User-Agent': 'my-app'})`.

---

## Step 1: Top-Level Entry Point (`src/requests/api.py:64`)
```python
def get(url, params=None, **kwargs):
    return request("get", url, params=params, **kwargs)
```
- Calls `requests.api.request('get', url, params=params, **kwargs)`.
- Instantiates an ephemeral `Session` inside a context manager:
  ```python
  with sessions.Session() as session:
      return session.request(method=method, url=url, **kwargs)
  ```

---

## Step 2: Session Orchestration (`src/requests/sessions.py:510`)
1. `Session.request(...)` constructs an un-prepared `Request`:
   ```python
   req = Request(
       method=method.upper(),
       url=url,
       headers=headers,
       files=files,
       data=data or {},
       json=json,
       params=params or {},
       auth=auth,
       cookies=cookies,
       hooks=hooks,
   )
   ```
2. Passes `req` to `session.prepare_request(req)`.
   - Merges session headers, session cookies, and session authentication.
   - Instantiates `p = PreparedRequest()`.
   - Calls `p.prepare(...)`.
     - `prepare_url`: Encodes query params into `https://example.com/api?q=python`.
     - `prepare_headers`: Normalizes into `CaseInsensitiveDict`.
     - `prepare_cookies`: Encodes cookies into header string.
     - `prepare_auth`: Invokes auth callback.
3. Passes `p` to `session.send(prep, **send_kwargs)`.

---

## Step 3: Adapter Lookup & Transport Dispatch (`src/requests/sessions.py:734`)
1. `session.get_adapter(url=prep.url)` scans `self.adapters` keys by prefix length.
2. Matches `'https://'` prefix and returns the mounted `HTTPAdapter` instance.
3. Calls `adapter.send(prep, stream=False, timeout=None, verify=True, cert=None, proxies=...)`.

---

## Step 4: Urllib3 Pool Connection & Socket I/O (`src/requests/adapters.py:440`)
1. `adapter.get_connection(prep.url, proxies)` checks out a `urllib3.connectionpool.HTTPSConnectionPool` for `example.com:443`.
2. Formats headers and path.
3. Calls `conn.urlopen(method=prep.method, url=url, body=prep.body, headers=prep.headers, ...)` on `urllib3`.
4. `urllib3` establishes TLS handshake (verifying certificates using `certifi` CA bundle), sends HTTP headers and body over socket, and reads HTTP response status and headers.
5. `urllib3` returns a `urllib3.response.HTTPResponse` object.

---

## Step 5: Response Construction (`src/requests/adapters.py:600`)
1. `adapter.build_response(prep, raw_response)` creates a `requests.models.Response` object.
2. Sets `response.status_code`, `response.headers`, `response.raw = raw_response`, `response.url = prep.url`.
3. Attaches response cookies to `response.cookies`.

---

## Step 6: Redirect Check & Session Cleanup (`src/requests/sessions.py:660`)
1. Checks `response.is_redirect` (status codes 301, 302, 303, 307, 308).
   - If redirected and `allow_redirects=True`: calls `resolve_redirects()`, creating a generator that executes subsequent requests and appends intermediate responses to `response.history`.
   - If not redirected: proceeds to hook execution.
2. Executes any registered response event hooks (`dispatch_hook('response', ...)`).
3. Closes ephemeral session context, which calls `Session.close()` (closing adapters).
4. Returns `response` to caller.
