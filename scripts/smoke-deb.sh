#!/usr/bin/env bash
# Smoke test of the amd64 .deb on the platforms named in mirror.toml ([platform] smoke_images, each pinned by digest). No secrets, nothing is signed here.
#   smoke-deb.sh <dist-dir>          starts one container per image (docker, or CONTAINER_TOOL=podman) and runs this script inside it
# Inside the container (INSIDE=1) it does what a person does: installs the package the way apt does, then checks it:
#   metadata and file list, version from mirror.toml, no missing shared library (on the unpacked binary BEFORE anything else is installed),
#   user and group zentinel made by the package's postinst, unit file (ExecStart path, User=zentinel, CAP_NET_BIND_SERVICE), the starter
#   configuration passes `zentinel test`, the installed binary really serves a static page (as the user zentinel, on a high port, bash only),
#   removal keeps /etc/zentinel, purge removes the ACME state. systemd itself is NOT started in the container.
set -euo pipefail
die() { echo "::error::$*" >&2; exit 1; }

if [ -z "${INSIDE:-}" ]; then
  dist=$(cd "${1:?usage: smoke-deb.sh <dist-dir>}" && pwd)
  root=$(cd "$(dirname "$0")/.." && pwd)
  mapfile -t images < <(python3 -I -c 'import sys,tomllib; print("\n".join(tomllib.load(open(sys.argv[1],"rb"))["platform"]["smoke_images"]))' "$root/mirror.toml")
  read -r want up < <(python3 -I -c 'import sys,tomllib; m=tomllib.load(open(sys.argv[1],"rb")); print(m["upstream"]["version"].replace("_",".")+"-"+str(m["build"]["deb_revision"]), m["upstream"]["version"])' "$root/mirror.toml")
  [ "${#images[@]}" -gt 0 ] || die "mirror.toml lists no smoke_images"
  for i in "${images[@]}"; do
    case $i in *@sha256:*) ;; *) die "image $i is not pinned by digest" ;; esac
    echo "=== $i"
    # shellcheck disable=SC2086  # CONTAINER_ARGS is a word list on purpose
    ${CONTAINER_TOOL:-docker} run --rm ${CONTAINER_ARGS:-} -e INSIDE=1 -e WANT_VERSION="$want" -e UPSTREAM="$up" -v "$dist:/dist:ro" -v "$root/scripts/smoke-deb.sh:/smoke-deb.sh:ro" \
      "$i" bash /smoke-deb.sh
  done
  echo "smoke ok on ${#images[@]} platform(s)"
  exit 0
fi

# ---- inside the container -----------------------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
debs=(/dist/zentinel_*_amd64.deb)
[ "${#debs[@]}" = 1 ] && [ -f "${debs[0]}" ] || die "expected exactly one /dist/zentinel_*_amd64.deb, found: ${debs[*]}"
deb=${debs[0]}
# shellcheck disable=SC1091
. /etc/os-release; echo "platform: $PRETTY_NAME, glibc $(ldd --version | head -n1 | awk '{print $NF}')"

dpkg-deb -I "$deb"
dpkg-deb -c "$deb"
[ "$(dpkg-deb -f "$deb" Package)" = zentinel ] || die "package name is not zentinel"
[ "$(dpkg-deb -f "$deb" Architecture)" = amd64 ] || die "architecture is not amd64"
[ "$(dpkg-deb -f "$deb" Version)" = "$WANT_VERSION" ] || die "version is $(dpkg-deb -f "$deb" Version), mirror.toml says $WANT_VERSION"
list=$(dpkg-deb -c "$deb")
for p in ./usr/bin/zentinel ./usr/lib/sysusers.d/zentinel.conf ./etc/zentinel/zentinel.kdl ./usr/share/doc/zentinel/copyright ./usr/share/doc/zentinel/LICENSE; do
  grep -q -F " $p" <<<"$list" || die "$p is not in the package"
done
grep -q -E ' \./usr/lib/systemd/system/zentinel\.service$' <<<"$list" || die "zentinel.service is not in the package"
dpkg-deb -f "$deb" Depends | grep -q -w systemd || die "Depends of the package does not name systemd"

# shared libraries of the binary as shipped, in the bare image (before apt installs anything)
tmp=$(mktemp -d); dpkg-deb -x "$deb" "$tmp"
ldd "$tmp/usr/bin/zentinel"
if ldd "$tmp/usr/bin/zentinel" | grep 'not found'; then die "zentinel needs shared libraries this platform lacks (see above); add them to Depends"; fi
rm -rf "$tmp"
apt-get update -qq >/dev/null
apt-get install -y --no-install-recommends "$deb" >/dev/null           # apt resolves the dependencies (libc6, libgcc-s1, systemd), like a person would

getent passwd zentinel >/dev/null || die "user zentinel does not exist: the postinst did not create it"
getent group zentinel >/dev/null || die "group zentinel does not exist"
unit=/usr/lib/systemd/system/zentinel.service
[ -f "$unit" ] || die "unit file $unit missing after install"
grep -q '^ExecStart=/usr/bin/zentinel ' "$unit" || die "unit does not start /usr/bin/zentinel"
grep -q '^User=zentinel' "$unit" || die "unit lost User=zentinel"
grep -q '^AmbientCapabilities=CAP_NET_BIND_SERVICE' "$unit" || die "unit lost CAP_NET_BIND_SERVICE"
[ ! -e /etc/systemd/system/multi-user.target.wants/zentinel.service ] || die "the package enabled the service; it must not"

out=$(runuser -u zentinel -- /usr/bin/zentinel --version 2>&1) || die "zentinel --version failed: $out"
echo "started: $out"
grep -q -F "release $UPSTREAM" <<<"$out" || die "zentinel --version does not say release $UPSTREAM: $out"
install -d -o zentinel -g zentinel /var/lib/zentinel /var/log/zentinel
runuser -u zentinel -- /usr/bin/zentinel test -c /etc/zentinel/zentinel.kdl >/dev/null 2>&1 || die "starter configuration does not pass 'zentinel test'"

# serve a static page with the installed binary, as the service user, on a high port (what the unit does, minus systemd and ports < 1024)
www=$(mktemp -d); echo 'smoke page' > "$www/index.html"; chmod -R a+rX "$www"; chmod a+x "$www"
cat > /tmp/smoke.kdl <<KDL
schema-version "1.0"
system { worker-threads 1 }
listeners { listener "http" { address "127.0.0.1:18080"
 protocol "http" } }
routes { route "site" { matches { host "smoke.test"
 path-prefix "/" }
 service-type "static"
 static-files { root "$www" } } }
KDL
chmod a+r /tmp/smoke.kdl
# the shell writes its own pid and then becomes zentinel (exec): the pid file names the real server process (the image has no pkill)
runuser -u zentinel -- sh -c 'echo $$ > /tmp/smoke.pid; HOME=/var/lib/zentinel exec /usr/bin/zentinel -c /tmp/smoke.kdl' >/tmp/smoke.log 2>&1 &
pid=$!
got=""
for _ in $(seq 1 50); do
  if got=$( { exec 3<>/dev/tcp/127.0.0.1/18080 && printf 'GET / HTTP/1.1\r\nHost: smoke.test\r\nConnection: close\r\n\r\n' >&3 && timeout 3 cat <&3; } 2>/dev/null ) && [ -n "$got" ]; then break; fi
  sleep 0.2
done
kill -TERM "$(cat /tmp/smoke.pid)" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
if ! { grep -q '^HTTP/1.1 200' <<<"$got" && grep -q 'smoke page' <<<"$got"; }; then echo "$got"; cat /tmp/smoke.log; die "the installed binary did not serve the static page"; fi
echo "served the static page"

apt-get remove -y zentinel >/dev/null
! command -v zentinel >/dev/null || die "zentinel is still there after removal"
[ -f /etc/zentinel/zentinel.kdl ] || die "remove deleted the conffile (only purge may)"
apt-get purge -y zentinel >/dev/null
[ ! -e /var/lib/zentinel ] || die "purge left /var/lib/zentinel"
echo "deb ok on $PRETTY_NAME"
