# Data Flow & Lifecycle: `psf/requests`

## The Request Lifecycle

```text
1. Caller Invocation
   requests.get(url, params=..., headers=...)
         │
         ▼
2. Ephemeral Session Creation (in requests.api)
   session = Session()
   session.request('GET', url, ...)
         │
         ▼
3. Request Construction & Preparation
   req = Request(method='GET', url=url, headers=headers, files=..., data=..., json=..., params=...)
   prep = session.prepare_request(req)
   [prep.prepare_url: parameters encoded, idna resolved]
   [prep.prepare_headers: CaseInsensitiveDict initialized]
   [prep.prepare_auth: HTTPBasicAuth or custom auth applied]
   [prep.prepare_cookies: Session cookies merged with Request cookies]
         │
         ▼
4. Adapter Resolution
   adapter = session.get_adapter(url=prep.url)  # matches "http://" or "https://" prefix
         │
         ▼
5. Adapter Execution
   resp = adapter.send(prep, stream=stream, timeout=timeout, verify=verify, cert=cert, proxies=proxies)
   [urllib3 connection pool checked out]
   [Low-level urllib3.response.HTTPResponse received]
   [requests.models.Response constructed via adapter.build_response()]
         │
         ▼
6. Redirect Resolution (if resp.is_redirect and allow_redirects=True)
   generator = session.resolve_redirects(resp, prep, stream=stream, ...)
   [Loops through 301/302/303/307/308 responses up to max_redirects (default 30)]
   [History appended to final response.history]
         │
         ▼
7. Hook Dispatch & Return
   resp = dispatch_hook('response', prep.hooks, resp)
   return resp
```

## Response Body Consumption Flow

1. **Eager Mode (`stream=False`, default):**
   - `adapter.build_response()` does not read body immediately, but `Session.send()` does not close it.
   - Calling `response.content` invokes `response._content = b"".join(response.iter_content(CONTENT_CHUNK_SIZE))`, eagerly loading all bytes and releasing the connection back to the `urllib3` pool.
2. **Streaming Mode (`stream=True`):**
   - Socket connection stays open and attached to `response.raw`.
   - Caller must iterate via `response.iter_content()` or `response.iter_lines()`, or explicitly call `response.close()`.
