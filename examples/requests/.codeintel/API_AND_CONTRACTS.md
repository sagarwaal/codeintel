# API & Contracts: `psf/requests`

## Top-Level Public Interface (`requests.*`)

The public interface exposed at `requests.*` maps directly to `requests.api`:

```python
requests.request(method, url, **kwargs)
requests.get(url, params=None, **kwargs)
requests.post(url, data=None, json=None, **kwargs)
requests.put(url, data=None, **kwargs)
requests.patch(url, data=None, **kwargs)
requests.delete(url, **kwargs)
requests.head(url, **kwargs)
requests.options(url, **kwargs)
```

### Accepted `**kwargs` Parameters
- `params`: Dictionary, list of tuples or bytes to append to query string.
- `data`: Dictionary, list of tuples, bytes, or file-like object to send in the body.
- `json`: A JSON-serializable python object to send in the body.
- `headers`: Dictionary of HTTP Headers to send with the `Request`.
- `cookies`: Dict or CookieJar object to send with the `Request`.
- `files`: Dictionary of `'name': file-like-objects` (or `('filename', fileobj)`) for multipart encoding.
- `auth`: Auth tuple or callable object for HTTP authentication.
- `timeout`: Float describing timeout of the request in seconds, or a `(connect_timeout, read_timeout)` tuple.
- `allow_redirects`: Boolean. Enable/disable GET/OPTIONS/POST/etc. redirection handling.
- `proxies`: Dictionary mapping protocol to the URL of the proxy.
- `verify`: Boolean (whether to verify SSL cert) or string (path to CA bundle).
- `stream`: Boolean. If `False`, response content will be immediately downloaded.
- `cert`: String (path to SSL client cert file) or tuple `('cert', 'key')`.

---

## Adapter Contract (`requests.adapters.BaseAdapter`)

Any transport adapter mounted via `session.mount(prefix, adapter)` must adhere to:

```python
class BaseAdapter:
    def send(self, request, stream=False, timeout=None, verify=True, cert=None, proxies=None):
        """Sends PreparedRequest object. Returns Response object."""
        raise NotImplementedError

    def close(self):
        """Cleans up adapter-specific resources."""
        raise NotImplementedError
```
