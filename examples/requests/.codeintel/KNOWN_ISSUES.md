# Known Issues & Architectural Findings: `psf/requests`

### [Finding REQ-001] Synchronous Blocking I/O Prevents Native Concurrency
- **Category:** Architecture / Performance
- **Severity:** Informational / Design Invariant
- **Status:** Known Limitation / Working as Designed
- **Confidence:** `VERIFIED`
- **Location:** Throughout `src/requests/`
- **Description:** Requests was deliberately constructed before standard Python `asyncio` maturation. It uses synchronous blocking calls (`socket.recv`) via `urllib3`.
- **Remediation / Workaround:** Applications needing concurrent non-blocking I/O should use thread pools (`concurrent.futures.ThreadPoolExecutor`) or modern async libraries like `httpx` or `aiohttp`.

---

### [Finding REQ-002] Eager `response.content` Caches Entire Payload in Memory
- **Category:** Memory / Performance Risk
- **Severity:** Medium
- **Status:** Documented Behavior
- **Confidence:** `VERIFIED`
- **Location:** `src/requests/models.py:880-910`
- **Description:** Accessing `response.content` or `response.text` reads the entire socket stream into memory and saves it to `self._content`. Downloading multi-gigabyte files without `stream=True` and manual chunk consumption causes high memory spikes or out-of-memory crashes.
- **Remediation:** Always specify `stream=True` and iterate via `response.iter_content(chunk_size=...)` when transferring large files.

---

### [Finding REQ-003] Ephemeral `requests.get()` Bypasses Connection Pool Reuse
- **Category:** Operational / Performance
- **Severity:** Low
- **Status:** Documented Behavior
- **Confidence:** `VERIFIED`
- **Location:** `src/requests/api.py:14-30`
- **Description:** Top-level functions like `requests.get(...)` create a new `Session()` inside a context manager for each call and immediately tear it down on return. This closes the underlying connection pool and eliminates TCP/TLS handshake reuse benefits across successive calls to the same host.
- **Remediation:** Reuse a `requests.Session()` instance across multiple requests to identical origins.
