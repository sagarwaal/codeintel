# Component: `models` (`Request`, `PreparedRequest`, `Response`)

## Overview
The `requests.models` module defines the data transfer objects passed across the library layers.

## Source Location
`src/requests/models.py`

## Core Classes

### 1. `Request` (line 204)
- **Role:** Pure container holding user-specified configuration (method, url, headers, files, data, params, auth, cookies, hooks, json).
- **Invariants:** Not transmitted over the wire. Must be converted into a `PreparedRequest` via `req.prepare()` or `session.prepare_request(req)`.

### 2. `PreparedRequest` (line 277)
- **Role:** Complete, mutable wire representation of an HTTP request.
- **Attributes:**
  - `method`: HTTP verb (e.g. `'GET'`, `'POST'`).
  - `url`: Canonical URL string with query parameters encoded and host IDNA-encoded.
  - `headers`: `CaseInsensitiveDict` of HTTP headers.
  - `body`: Serialized byte string or file-like stream.
  - `hooks`: Event hook callbacks.
- **Methods:** `prepare(method, url, headers, files, data, params, auth, cookies, hooks, json)`.

### 3. `Response` (line 601)
- **Role:** Represents the received HTTP response.
- **Key Attributes:**
  - `status_code`: Integer HTTP status code.
  - `headers`: Case-insensitive response headers.
  - `raw`: Underlying `urllib3.response.HTTPResponse` object.
  - `history`: List of prior `Response` objects generated during redirects.
  - `encoding`: Guessed or declared text encoding (uses `charset_normalizer` or `chardet`).
- **Key Properties / Methods:**
  - `content`: Returns entire response body as bytes, caching it in `_content`.
  - `text`: Decodes `content` using `encoding`.
  - `json(**kwargs)`: Parses `text` using standard `json.loads`.
  - `raise_for_status()`: Raises `HTTPError` if `400 <= status_code < 600`.
