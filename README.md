# fs-zentinel

FreeSynergy.Zentinel: everything FreeSynergy needs to ship the [Zentinel](https://zentinelproxy.io) reverse proxy, the public gate in front of the programs.

- **Signed mirror** (ADR 0068): the maker's release `26.11_1` is mirrored unchanged. CI verifies it (Sigstore cosign with the expected GitHub Actions identity from `mirror.toml`, plus SHA-256), adds the source tarball of the same version, the licence and the SBOMs, and signs everything again with the FreeSynergy release key.
- **Public configuration** `config/zentinel.kdl` (KDL) with defaults. It is a template: secrets are `${vault:…}` placeholders filled from the vault (ADR 0067); no secret is ever stored here (ADR 0054).
- **Capability tags** `capabilities.toml` for the catalog (gateway, OIDC, OAuth2, SCIM, LDAP, RADIUS, PAM, SSH keys, passkeys: yes / no / unstable, each with its source).
- **Docs** in English and German (`docs/en`, `docs/de`) and an **export** of the configuration (`export/config-export.json`).
- `docs/ROADMAP.md`: later work (login agent against Kanidm, redirect, control plane). `docs/known-limits.md`: open items and decisions.

```sh
python3 -I scripts/repo_tool.py check    # validate everything; secrets must be placeholders
python3 -I scripts/repo_tool.py docs     # regenerate capabilities.md and configuration.md (en + de)
python3 -I scripts/repo_tool.py export   # regenerate export/config-export.json
scripts/verify-mirror.sh <release-dir>   # check checksums and our signatures of a downloaded release
```

Packages are release files, not Git content. Zentinel itself is not changed; fixes go upstream (ADR 0015).

Licence of this repository: MIT OR Apache-2.0. Zentinel is Apache-2.0 (`LICENSE-Apache-2.0` ships with every release).
