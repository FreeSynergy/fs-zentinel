# Known limits and open items

git-bug is not set up in the FreeSynergy repositories (no `refs/bugs`), so open items live here until it is. Each entry: what, how to reproduce, decision.

## 1. `ca-cert` in the KDL is not enough for a private CA (Zentinel 26.11_1)

- **What:** An upstream with `tls { sni "..." ca-cert "/path/ca.pem" }` still fails with `invalid peer certificate: UnknownIssuer` when the upstream (here Kanidm) uses a certificate from a private CA.
- **Reproduce:** Kanidm 1.12.0 with a certificate from a private CA; Zentinel 26.11_1 with `config/zentinel.kdl` plus `ca-cert` inside the upstream `tls` block; request any path through the gate: 502, log line `TLS connect() failed ... UnknownIssuer`. Same setup with the environment variable `SSL_CERT_FILE=<ca.pem>` on the Zentinel process: works. The local test (`fs-kanidm/scripts/test/podman-stack.sh`) uses the variable.
- **Decision:** Our template carries no `ca-cert`; on the real server Kanidm has a public certificate for its name, and the system roots verify it. Private CA: use `SSL_CERT_FILE`. If this proves a Zentinel bug beyond doubt (the config crate has `build_upstream_tls_config`, which may not be wired to the connection), a short upstream issue follows later; none now.

## 2. Control plane: protocol stability unknown

- **What:** The upstream control plane (`zentinelproxy/zentinel-control-plane`, Apache-2.0) has a documented node API (`/api/v1`, `docs/PROXY-REGISTRATION.md`, `priv/static/openapi.yaml`), but upstream calls the project Beta and gives no compatibility promise.
- **Decision:** The upstream agent `zentinel-cp-agent` is not mirrored. FreeSynergy builds its own control plane in Rust **after 3b** and checks the protocol again then. Until then fs-zentinel manages the KDL directly: validate with `zentinel test`, replace the file atomically, hot reload (SIGHUP).

## 3. No login in the gate (later)

- **What:** Programs without a login of their own cannot be protected by the gate yet. The upstream auth agent only checks bearer tokens (experimental), no browser login.
- **Decision:** Later a login agent for Zentinel (forward auth against Kanidm). Programs with a login sign in to Kanidm themselves by OIDC. See `ROADMAP.md`.

## 4. No documented HTTP to HTTPS redirect

- Zentinel 26.11_1 has no documented redirect handler, so the template has no plain-HTTP listener. See `ROADMAP.md`.
