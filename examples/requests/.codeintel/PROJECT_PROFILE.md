# Project Profile: `psf/requests`

## Domain Overview
`requests` is the standard Python synchronous HTTP library, designed around usability ("HTTP for Humans™"). It wraps low-level socket and connection-pool management in `urllib3` with a clean, pythonic object-oriented interface.

## Repository Vital Statistics
- **Analyzed Release:** `v2.32.3`
- **Analyzed Commit:** `0e322af87745eff34caffe4df68456ebc20d9068`
- **Primary Language:** Python 3.8+ (supports 3.8 - 3.13)
- **Source Root:** `src/requests/`
- **Test Suite:** `tests/` (pytest-based, featuring custom threaded local HTTP test server in `tests/testserver/`)
- **Package Management & Build:** `setuptools`, `pyproject.toml`, `setup.py`

## Core Dependencies
1. **`urllib3` (`>=1.21.1, <3`)**: The underlying transport engine managing connection pools, HTTP/HTTPS connection logic, SSL contexts, and low-level proxy tunneling.
2. **`certifi` (`>=2017.4.17`)**: Curated Mozilla root CA bundle for TLS certificate validation.
3. **`charset_normalizer` (`>=2, <4`)** or fallback **`chardet` (`>=3.0.2, <6`)**: Automatic character set detection for HTTP text responses (`response.text`).
4. **`idna` (`>=2.5, <4`)**: Internationalized Domain Names in Applications (RFC 5891) hostname encoding.

## Primary Invariants
1. **Synchronous Execution:** All network I/O in core `requests` is blocking. No `async`/`await` primitives exist in core.
2. **Strict Backwards Compatibility:** Public API signatures (`requests.get`, `Session.request`, `PreparedRequest`, `Response`) remain stable across minor versions.
3. **Prepared State Separation:** Network mutations only occur on `PreparedRequest` objects, never on un-prepared `Request` objects.
