# Test Strategy: `psf/requests`

## Test Suite Architecture

The Requests test suite (`tests/`) uses `pytest` and is divided into:
1. **Unit Tests (`tests/test_structures.py`, `tests/test_utils.py`, `tests/test_hooks.py`)**: Fast, memory-only tests verifying header casing, parameter quoting, and hook invocation.
2. **Integration Tests (`tests/test_requests.py`, `tests/test_adapters.py`)**: Tests that exercise request execution, redirect chains, cookie persistence, and proxy resolution.
3. **Local Threaded Test Server (`tests/testserver/`)**: An in-process HTTP server enabling network integration testing without calling out to external web services.

## Recommended Test Commands

```bash
# Run entire test suite
pytest

# Run fast unit tests only (no socket I/O)
pytest tests/test_structures.py tests/test_utils.py tests/test_hooks.py

# Run adapter & connection pooling tests
pytest tests/test_adapters.py

# Run low-level network and redirect tests
pytest tests/test_lowlevel.py tests/test_requests.py -k "redirect"
```

## Test Invariants
- Integration tests must not depend on internet access; tests make use of `tests/testserver/` or `httpbin` mocks.
- SSL tests rely on locally generated fixture certificates located in `tests/certs/`.
