#!/usr/bin/env bash
# Selftest of render-config.sh: good input renders, bad input is refused, nothing is left unreplaced. Optional 5th check with a real
# zentinel binary: ZENTINEL=/path/to/zentinel ./test_render.sh runs `zentinel test -c` on the rendered file (config check only, no server).
# shellcheck disable=SC2015  # "A && ok || bad": ok and bad never fail, so this is if-then-else on purpose
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd); r="$here/render-config.sh"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
fail=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }
export SITE1=freesynergy.net SITE2=helfa.org SITE3=freeplanetearth.org ACME_EMAIL=admin@helfa.org

"$r" --staging "$t/a.kdl" >/dev/null && grep -q 'domains "helfa.org"' "$t/a.kdl" && grep -q 'staging #true' "$t/a.kdl" && ! grep -q '@[A-Z0-9_]*@' "$t/a.kdl" && ok "staging render" || bad "staging render"
"$r" --production "$t/b.kdl" >/dev/null && grep -q 'staging #false' "$t/b.kdl" && ok "production render" || bad "production render"
grep -q 'root "/srv/www/freeplanetearth.org"' "$t/a.kdl" && ok "document root per domain" || bad "document root per domain"
WEBROOT="$t/www" "$r" --install-pages "$t/c.kdl" >/dev/null && [ -f "$t/www/helfa.org/index.html" ] && ok "pages installed per domain" || bad "pages installed per domain"
SITE2='evil".org' "$r" "$t/x.kdl" 2>/dev/null && bad "quote in domain accepted" || ok "quote in domain refused"
SITE2=freesynergy.net "$r" "$t/x.kdl" 2>/dev/null && bad "duplicate domain accepted" || ok "duplicate domain refused"
ACME_EMAIL='a@b.org" evil' "$r" "$t/x.kdl" 2>/dev/null && bad "bad e-mail accepted" || ok "bad e-mail refused"
WEBROOT=/srv/../etc "$r" "$t/x.kdl" 2>/dev/null && bad "webroot with .. accepted" || ok "webroot with .. refused"
ACME_STAGING=maybe "$r" "$t/x.kdl" 2>/dev/null && bad "bad staging value accepted" || ok "bad staging value refused"
if [ -n "${ZENTINEL:-}" ]; then
  # Zentinel insists that the document roots exist; certificates are not needed for the config check (ACME fetches them at start)
  mkdir -p "$t/w/freesynergy.net" "$t/w/helfa.org" "$t/w/freeplanetearth.org"; WEBROOT="$t/w" "$r" --staging "$t/z.kdl" >/dev/null
  "$ZENTINEL" test -c "$t/z.kdl" >"$t/zt.log" 2>&1 && ok "zentinel test accepts the rendered configuration" || { bad "zentinel test refuses it"; cat "$t/zt.log"; }
fi
exit $fail
