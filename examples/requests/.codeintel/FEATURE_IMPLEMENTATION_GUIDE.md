# Feature Implementation Guide: `psf/requests`

Use this guide when adding features or fixing bugs in `psf/requests` to adhere to project invariants.

---

## 1. Locate Owning Layer
- Adding a high-level user API parameter (e.g. new keyword arg) ➔ `requests.api`, `requests.sessions.Session.request`, and `requests.models.Request`.
- Modifying how headers/body/params are prepared ➔ `requests.models.PreparedRequest.prepare_*`.
- Modifying transport, retries, SSL verification, or proxies ➔ `requests.adapters.HTTPAdapter`.
- Adding auth mechanism ➔ `requests.auth.AuthBase`.

---

## 2. Parameter Propagation Invariant
When adding any new parameter to `requests.get()` or `requests.post()`:
1. Add it to `requests/api.py` in the appropriate wrapper function and propagate to `session.request()`.
2. Update `Session.request()` in `src/requests/sessions.py` to accept the parameter.
3. Pass it to `Session.prepare_request()` or `Session.send()` depending on whether it affects the payload or transport.
4. If it affects the transport, ensure `HTTPAdapter.send()` in `src/requests/adapters.py` accepts and processes it.

---

## 3. Preserving Backwards Compatibility
- Never remove or re-order positional arguments on public methods.
- Default all new options to values that preserve existing behavior (e.g. `feature_enabled=False` or `None`).
- Return types must remain `Response` instances.

---

## 4. Testing Checklist
- Add unit tests in `tests/test_requests.py` verifying both default behavior and new option behavior.
- Ensure all tests run offline without remote internet access.
- Run `pytest` locally to confirm 0 regressions across the existing test suite.
