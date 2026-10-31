# Code Review Checklist: `psf/requests`

Before accepting, committing, or proposing changes to `requests`, verify every item below:

---

## 1. Backwards Compatibility
- [ ] No public method signatures in `requests.api`, `Session`, `PreparedRequest`, or `Response` have had arguments removed or reordered.
- [ ] All new kwargs have safe default values (`None` or `False`).
- [ ] Existing exceptions remain subclasses of `requests.exceptions.RequestException`.

---

## 2. Transport Separation & Leak Prevention
- [ ] No `urllib3` internal objects or exceptions leak directly to caller without being wrapped or converted.
- [ ] In `HTTPAdapter.send()`, every new socket/urllib3 error condition maps to a corresponding `requests.exceptions.*` class.
- [ ] `PreparedRequest` does not initiate socket connections or invoke transport adapter methods.

---

## 3. Streaming & Resource Cleanup
- [ ] If changing `Response` or `HTTPAdapter.send`, verify that unstreamed requests automatically release connections back to the pool.
- [ ] Streaming requests (`stream=True`) leave the raw stream accessible until `.close()` or full generator exhaustion.

---

## 4. Security Invariants
- [ ] Cross-domain redirects strip sensitive headers (`Authorization`, `Cookie`) as defined in `SessionRedirectMixin.should_strip_auth`.
- [ ] HTTPS to HTTP downgrades strip credentials.
- [ ] Default `verify=True` remains intact across all entry points.

---

## 5. Verification
- [ ] Pytest suite executes and passes 100% offline.
- [ ] Regression test added under `tests/` reproducing the exact bug or exercising the new feature.
