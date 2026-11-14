# Mirror and verification

The maker publishes signed archives, so FreeSynergy mirrors them unchanged (ADR 0068):

1. `mirror.toml` pins release `26.11_2`, the commit, and the **expected signer identity** (`https://github.com/zentinelproxy/zentinel/.github/workflows/release.yml@refs/tags/26.11_2`, issuer `https://token.actions.githubusercontent.com`) and the commit, repository and ref the signing certificate must carry (cosign flags `--certificate-github-workflow-sha/-repository/-ref`; the maker's certificate holds them as OIDs 1.3.6.1.4.1.57264.1.3/.5/.6).
2. GitHub Actions downloads the archives, checks SHA-256 and runs `cosign verify-blob --bundle` (Sigstore, keyless: no fixed key exists; trust is the identity above plus the public Rekor log). Anything that fails stops the run.
3. The source tarball of the same version (git archive of the pinned commit), the licence and the maker's SBOMs are added.
4. Every file gets an OpenPGP signature (`.asc`) from the FreeSynergy release key, `SHA256SUMS.txt` lists the files.

Check a FreeSynergy release yourself:

```sh
scripts/verify-mirror.sh <directory-with-the-release-files>
```

To check the maker's own signature, download the archive and its `.bundle` from the maker's release and run `cosign verify-blob` with the identity from `mirror.toml`.

## Packages (.deb)

Besides the maker's tarballs the release carries Debian packages `zentinel_26.11.2-1_amd64.deb` and `zentinel_26.11.2-1_arm64.deb`. They are a **repackaging**: nothing is compiled by FreeSynergy. `scripts/make-deb.sh` puts the verified maker binary, the maker's own systemd unit, sysusers file and starter configuration into a package; the only change is `ExecStart=/usr/bin/zentinel` (upstream says `/usr/local/bin`). The Debian version is the upstream version with `_` written as `.` (Debian forbids the underscore) plus the package revision (`26.11.2-1`).

- Installing does not enable or start the service. `apt remove` keeps `/etc/zentinel` and `/var/lib/zentinel`.
- **`apt purge zentinel` deletes `/var/lib/zentinel` and `/var/log/zentinel`**, that is the ACME account key and all issued certificates and private keys, and the logs. The system user stays.
- Minimum platform: glibc 2.34 (the maker's binary needs GLIBC up to 2.34, plus libgcc_s and libm): Debian 12 and 13, Ubuntu 22.04 and 24.04.
- Smoke test (job `smoke`, `scripts/smoke-deb.sh`, images pinned by digest in `mirror.toml`): the amd64 package is installed with apt on Debian 12, Debian 13, Ubuntu 22.04 and Ubuntu 24.04; the installed binary serves a static page as the user `zentinel`; remove keeps the configuration, purge removes the state. The job `sign` runs only after it is green. The arm64 package is only built (binary architecture checked), **not started** anywhere.
- `verify-mirror.sh` additionally checks that every `.deb` is a well-formed Debian archive.

Not mirrored yet: the control-plane node agent `zentinel-cp-agent`. Its protocol is documented, but upstream calls the project Beta and gives no stability promise (see the [roadmap](../ROADMAP.md)).

Language: [Deutsch](../de/mirror.md)
