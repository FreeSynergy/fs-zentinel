#!/usr/bin/env bash
# Builds the Debian packages (amd64, arm64) from the maker's VERIFIED release tarballs in <dist-dir>. REPACKAGING, no compilation.
#   make-deb.sh <dist-dir> <upstream-src-dir>
# <dist-dir> holds zentinel-<V>-linux-{amd64,arm64}.tar.gz (already checked by the workflow); <upstream-src-dir> is the checkout of the
# pinned commit (its deploy/ files are used unchanged except the binary path in the unit). Needs dpkg-deb, tar, readelf (runner: ubuntu-24.04).
# SOURCE_DATE_EPOCH is taken from the pinned commit; the files are written with that mtime, so the package is reproducible.
# Debian version: upstream "26.11_2" has an underscore, which Debian versions do not allow: "_" becomes "." (26.11.2) and the revision
# from mirror.toml follows: 26.11.2-1. Order stays right (26.11.2 > 26.11.1 > 26.10.11).
set -euo pipefail
die() { echo "::error::$*" >&2; exit 1; }
dist=$(cd "${1:?usage: make-deb.sh <dist-dir> <upstream-src-dir>}" && pwd)
src=$(cd "${2:?usage: make-deb.sh <dist-dir> <upstream-src-dir>}" && pwd)
root=$(cd "$(dirname "$0")/.." && pwd)
read -r V REV COMMIT < <(python3 -I -c 'import sys,tomllib; m=tomllib.load(open(sys.argv[1],"rb")); print(m["upstream"]["version"], m["build"]["deb_revision"], m["source"]["commit"])' "$root/mirror.toml")
[ "$(git -C "$src" rev-parse HEAD)" = "$COMMIT" ] || die "$src is not at the pinned commit $COMMIT"
SOURCE_DATE_EPOCH=$(git -C "$src" log -1 --format=%ct); export SOURCE_DATE_EPOCH
debver="${V//_/.}-$REV"
[[ $debver =~ ^[0-9][A-Za-z0-9.+~-]*$ ]] || die "bad Debian version $debver"

for f in deploy/zentinel.service deploy/sysusers.d/zentinel.conf deploy/zentinel.starter.kdl LICENSE; do [ -f "$src/$f" ] || die "missing in upstream checkout: $f"; done
[ "$(grep -c '^ExecStart=/usr/local/bin/zentinel ' "$src/deploy/zentinel.service")" = 1 ] || die "upstream unit changed: ExecStart line not as expected"

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
for arch in amd64 arm64; do
  tgz="$dist/zentinel-$V-linux-$arch.tar.gz"; [ -f "$tgz" ] || die "missing $tgz"
  stage="$work/$arch"; mkdir -p "$stage/bin" "$stage/pkg/DEBIAN"
  tar -xzf "$tgz" -C "$stage/bin" ./zentinel ./VERSION
  [ "$(cat "$stage/bin/VERSION")" = "$V" ] || die "VERSION file of the $arch tarball is not $V"
  want=$([ "$arch" = amd64 ] && echo "Advanced Micro Devices X86-64" || echo "AArch64")
  readelf -h "$stage/bin/zentinel" | grep -q "Machine:.*$want" || die "$arch tarball does not contain a $want binary"
  p="$stage/pkg"
  install -D -m 0755 "$stage/bin/zentinel" "$p/usr/bin/zentinel"
  install -d -m 0755 "$p/usr/lib/systemd/system" "$p/usr/lib/sysusers.d" "$p/etc/zentinel" "$p/usr/share/doc/zentinel"
  sed 's|^ExecStart=/usr/local/bin/zentinel |ExecStart=/usr/bin/zentinel |' "$src/deploy/zentinel.service" > "$p/usr/lib/systemd/system/zentinel.service"
  grep -q '^ExecStart=/usr/bin/zentinel ' "$p/usr/lib/systemd/system/zentinel.service" || die "unit patch did not apply"
  install -m 0644 "$src/deploy/sysusers.d/zentinel.conf" "$p/usr/lib/sysusers.d/zentinel.conf"
  install -m 0644 "$src/deploy/zentinel.starter.kdl" "$p/etc/zentinel/zentinel.kdl"
  install -m 0644 "$src/LICENSE" "$p/usr/share/doc/zentinel/LICENSE"
  cat > "$p/usr/share/doc/zentinel/copyright" <<COPY
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Zentinel
Source: https://github.com/zentinelproxy/zentinel (tag $V, commit $COMMIT)

Files: *
Copyright: the Zentinel authors
License: Apache-2.0
 The full text is in /usr/share/doc/zentinel/LICENSE. The source of this version is published next to the package (zentinel-$V-source.tar.gz).
COPY
  cat > "$p/usr/share/doc/zentinel/README.fs" <<RM
FreeSynergy repackaging of the Zentinel release $V ($arch).
Binary: the maker's release tarball, SHA-256 and Sigstore signature checked in CI (see mirror.toml in https://github.com/FreeSynergy/fs-zentinel).
Changed against upstream: the ExecStart path in zentinel.service (/usr/bin instead of /usr/local/bin). Everything else is upstream's.
WARNING: "apt purge zentinel" deletes /var/lib/zentinel and /var/log/zentinel (ACME account key, certificates, private keys, logs). "apt remove" keeps them.
Start:  systemctl enable --now zentinel   (not done by the installation). Configuration: /etc/zentinel/zentinel.kdl, test: zentinel test -c <file>.
RM
  find "$p" -type d -exec chmod 0755 {} +
  size=$(du -sk --exclude=DEBIAN "$p" | cut -f1)
  sed -e "s|@DEB_VERSION@|$debver|" -e "s|@ARCH@|$arch|" -e "s|@UPSTREAM@|$V|" -e "s|@SIZE@|$size|" "$root/packaging/deb/control.in" > "$p/DEBIAN/control"
  printf '/etc/zentinel/zentinel.kdl\n' > "$p/DEBIAN/conffiles"
  install -m 0755 "$root"/packaging/deb/{postinst,prerm,postrm} "$p/DEBIAN/"
  find "$p" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
  dpkg-deb --root-owner-group -Zxz -b "$p" "$dist/zentinel_${debver}_${arch}.deb" >/dev/null
  echo "built $dist/zentinel_${debver}_${arch}.deb"
done
