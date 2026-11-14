#!/usr/bin/env bash
# Local proof that Zentinel serves a separate document root per Host name over plain HTTP (no TLS, no ACME, no network beyond 127.0.0.1).
#   ZENTINEL=/path/to/zentinel ./test_serve.sh
# Starts the proxy as the current user on 127.0.0.1:$PORT with a temporary config and temporary roots, asks it with Python, stops it.
set -euo pipefail
: "${ZENTINEL:?set ZENTINEL to the zentinel binary}"
here=$(cd "$(dirname "$0")" && pwd); port=${PORT:-18480}
t=$(mktemp -d); pid=""
cleanup() { [ -z "$pid" ] || { kill "$pid" 2>/dev/null && wait "$pid" 2>/dev/null; } || true; rm -rf "$t"; }; trap cleanup EXIT
for s in one.test two.test; do mkdir -p "$t/www/$s"; sed "s/rebuilding/rebuilding $s/" "$here/www/index.html" > "$t/www/$s/index.html"; done
cat > "$t/z.kdl" <<KDL
schema-version "1.0"
system { worker-threads 1 }
listeners { listener "http" { address "127.0.0.1:$port"
 protocol "http" }
 listener "plain" { address "127.0.0.1:$((port+1))"
 protocol "http"
 namespace "redirect" } }
namespace "redirect" {
  filters { filter "to-https" { type "redirect"
 scheme "https"
 status-code 301 } }
  routes { route "all" { matches { path-prefix "/" }
 service-type "web"
 filters "to-https" } }
}
routes {
  route "one" { matches { host "one.test"
 path-prefix "/" }
 service-type "static"
 static-files { root "$t/www/one.test" } }
  route "two" { matches { host "two.test"
 path-prefix "/" }
 service-type "static"
 static-files { root "$t/www/two.test" } }
}
KDL
"$ZENTINEL" test -c "$t/z.kdl" >/dev/null 2>&1
HOME="$t" "$ZENTINEL" -c "$t/z.kdl" >"$t/log" 2>&1 & pid=$!
python3 -I - "$port" "$pid" <<'PY'
import sys, time, http.client
port, pid = int(sys.argv[1]), int(sys.argv[2])
def get(host, path="/", p=None):
    c = http.client.HTTPConnection("127.0.0.1", p or port, timeout=5); c.request("GET", path, headers={"Host": host})
    r = c.getresponse(); return r.status, r.read().decode("utf-8", "replace"), dict(r.getheaders())
for _ in range(50):
    try: get("one.test"); break
    except OSError: time.sleep(0.2)
else: sys.exit("proxy did not come up")
ok = True
def check(name, cond): 
    global ok; print(("ok   " if cond else "FAIL ") + name); ok = ok and cond
s, b, h = get("one.test"); check("one.test -> 200 and its own page", s == 200 and "rebuilding one.test" in b)
s, b, h = get("two.test"); check("two.test -> 200 and its own page", s == 200 and "rebuilding two.test" in b)
s, b, h = get("one.test", "/index.html"); check("explicit index.html", s == 200)
s, b, h = get("one.test", "/../two.test/index.html"); check("path traversal does not reach the other root", "rebuilding two.test" not in b)
s, b, h = get("one.test", "/%2e%2e/two.test/index.html"); check("encoded traversal does not reach the other root", "rebuilding two.test" not in b)
s, b, h = get("one.test", "/missing.html"); check("missing file -> 404", s == 404)
s, b, h = get("other.test"); check("unknown host does not get a page", "rebuilding" not in b)
s, b, h = get("one.test", "/a/b", port + 1)
check("port-80 style listener redirects to https (301, same host and path)", s == 301 and h.get("Location") == "https://one.test/a/b")
s, b, h = get("one.test", "/", port); check("main listener is not redirected", s == 200)
sys.exit(0 if ok else 1)
PY
