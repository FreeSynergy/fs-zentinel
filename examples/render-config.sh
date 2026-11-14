#!/usr/bin/env bash
# Render zentinel.kdl.in into a Zentinel configuration and (optionally) copy the placeholder page into each site's document root.
#   SITE1=freesynergy.net SITE2=helfa.org SITE3=freeplanetearth.org ACME_EMAIL=admin@helfa.org \
#     ./render-config.sh [--staging|--production] [--install-pages] <output.kdl>
# Environment (all required except the last two): SITE1 SITE2 SITE3 (domains), ACME_EMAIL (contact for Let's Encrypt),
#   ACME_STAGING (default true: Let's Encrypt staging, no rate limits, untrusted certificates; --production sets it to false),
#   WEBROOT (default /srv/www; one directory per domain below it; with --install-pages the page is copied there, needs write access).
# No secrets are read or written. Values are checked strictly because they end up inside a KDL file.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
die() { echo "error: $*" >&2; exit 2; }

staging=${ACME_STAGING:-true}; install=0; out=""
for a in "$@"; do
  case $a in
    --staging) staging=true ;;
    --production) staging=false ;;
    --install-pages) install=1 ;;
    -*) die "unknown option $a" ;;
    *) [ -z "$out" ] || die "only one output file"; out=$a ;;
  esac
done
[ -n "$out" ] || die "usage: render-config.sh [--staging|--production] [--install-pages] <output.kdl>"
: "${SITE1:?SITE1 is not set}" "${SITE2:?SITE2 is not set}" "${SITE3:?SITE3 is not set}" "${ACME_EMAIL:?ACME_EMAIL is not set}"
webroot=${WEBROOT:-/srv/www}

dom='^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$'
for s in "$SITE1" "$SITE2" "$SITE3"; do [[ $s =~ $dom ]] || die "'$s' is not a plain lower-case domain name"; done
[ "$SITE1" != "$SITE2" ] && [ "$SITE1" != "$SITE3" ] && [ "$SITE2" != "$SITE3" ] || die "the three domains must differ (upstream: one domain, one acme block)"
[[ $ACME_EMAIL =~ ^[A-Za-z0-9._+-]+@([a-z0-9-]+\.)+[a-z]{2,63}$ ]] || die "ACME_EMAIL is not a plain e-mail address"
[[ $staging = true || $staging = false ]] || die "ACME_STAGING must be true or false"
[[ $webroot =~ ^/[A-Za-z0-9._/-]*$ ]] && [[ $webroot != */ ]] && [[ $webroot != *..* ]] || die "WEBROOT must be an absolute path of plain characters, without trailing slash"

text=$(cat "$here/zentinel.kdl.in")
for pair in "SITE1=$SITE1" "SITE2=$SITE2" "SITE3=$SITE3" "ACME_EMAIL=$ACME_EMAIL" "ACME_STAGING=$staging" "WEBROOT=$webroot"; do
  text=${text//"@${pair%%=*}@"/${pair#*=}}
done
if grep -q -E '@[A-Z0-9_]+@' <<<"$text"; then die "unreplaced marker left in the template"; fi
printf '%s\n' "$text" > "$out"
echo "wrote $out (staging=$staging, webroot=$webroot)"

if [ "$install" = 1 ]; then
  for s in "$SITE1" "$SITE2" "$SITE3"; do
    install -d -m 0755 "$webroot/$s"
    install -m 0644 "$here/www/index.html" "$webroot/$s/index.html"
    echo "page installed: $webroot/$s/index.html"
  done
fi
