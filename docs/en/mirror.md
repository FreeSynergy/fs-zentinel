# Mirror and verification

The maker publishes signed archives, so FreeSynergy mirrors them unchanged (ADR 0068):

1. `mirror.toml` pins release `26.11_1`, the commit, and the **expected signer identity** (`https://github.com/zentinelproxy/zentinel/.github/workflows/release.yml@refs/tags/26.11_1`, issuer `https://token.actions.githubusercontent.com`).
2. GitHub Actions downloads the archives, checks SHA-256 and runs `cosign verify-blob --bundle` (Sigstore, keyless: no fixed key exists; trust is the identity above plus the public Rekor log). Anything that fails stops the run.
3. The source tarball of the same version (git archive of the pinned commit), the licence and the maker's SBOMs are added.
4. Every file gets an OpenPGP signature (`.asc`) from the FreeSynergy release key, `SHA256SUMS.txt` lists the files.

Check a FreeSynergy release yourself:

```sh
scripts/verify-mirror.sh <directory-with-the-release-files>
```

To check the maker's own signature, download the archive and its `.bundle` from the maker's release and run `cosign verify-blob` with the identity from `mirror.toml`.

Not mirrored yet: the control-plane node agent `zentinel-cp-agent`. Its protocol is documented, but upstream calls the project Beta and gives no stability promise (see the [roadmap](../ROADMAP.md)).

Language: [Deutsch](../de/mirror.md)
