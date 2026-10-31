# Component: `auth` (`requests.auth`)

## Overview
The `requests.auth` module defines the authentication framework for Requests. It centers around `AuthBase`, a callable interface invoked during `PreparedRequest` construction.

## Source Location
`src/requests/auth.py`

## Core Classes

### 1. `AuthBase` (line 62)
- Base class for all authentication handlers.
- **Contract:** Subclasses implement `__call__(self, r)` where `r` is a `PreparedRequest` instance. The handler modifies `r.headers` or other attributes and returns `r`.

### 2. `HTTPBasicAuth` (line 72)
- Standard HTTP Basic Authentication.
- Computes base64-encoded `'Basic ' + b64encode(username:password)` and attaches it to `r.headers['Authorization']`.

### 3. `HTTPDigestAuth` (line 104)
- Challenge-response HTTP Digest Authentication (RFC 2617).
- Stateful: catches initial 401 response in a response hook, parses `WWW-Authenticate: Digest` challenge headers, generates the digest hash, and replays the request with the `Authorization: Digest ...` header.

## Invariant
- Authentication handlers operate directly on `PreparedRequest` before transport dispatch, or register response hooks to handle authentication challenges (like Digest or OAuth refreshes).
