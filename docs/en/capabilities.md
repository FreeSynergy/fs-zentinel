# Capabilities

Capability tags for the FreeSynergy catalog (ADR 0068). `provides` = offers it, `requires` = needs it, `recommends` = can use it. Support is `yes`, `no` or `unstable`; every `yes` and `unstable` cites the upstream source. Generated from `capabilities.toml`; checked on version Zentinel 26.11_1 (2026-11-11).

| Tag | Relation | Support | Meaning | Source |
|---|---|---|---|---|
| `gateway.reverse-proxy` | provides | yes | Reverse proxy with TLS termination, routing by host and path, load balancing, health checks, rate limiting, hot reload (SIGHUP). | [link](https://github.com/zentinelproxy/zentinel/blob/26.11_1/README.md) |
| `identity.oidc` | provides | unstable | Only a check of OIDC bearer tokens against a JWKS in the separate auth agent, marked experimental; no browser login (no authorisation-code flow). Zentinel is a gate without login of its own for now. | [link](https://github.com/zentinelproxy/zentinel-agent-auth/blob/v0.3.0/README.md) |
| `identity.oauth2` | provides | unstable | Bearer/JWT validation (HS*, RS*, ES*) in the auth agent; SAML, mTLS and token exchange are refused by the agent because they do not verify what they trust. | [link](https://github.com/zentinelproxy/zentinel-agent-auth/blob/v0.3.0/README.md) |
| `identity.scim` | provides | unstable | A SCIM 2.0 user store in the auth agent that can block deactivated OIDC users; experimental. | [link](https://github.com/zentinelproxy/zentinel-agent-auth/blob/v0.3.0/README.md) |
| `identity.ldap` | provides | no | Not offered; a proxy has no directory. | - |
| `identity.radius` | provides | no | Not offered. | - |
| `identity.pam` | provides | no | Not offered. | - |
| `identity.ssh-keys` | provides | no | Not offered. | - |
| `identity.passkeys` | provides | no | Not offered; passkeys are handled by the login service behind the gate. | - |
| `identity.oidc` | recommends | yes | Zentinel does not need a login service, but programs behind it use one (Kanidm) for their own sign-in. | [link](https://github.com/FreeSynergy/fs-documentation/blob/main/conventions/decisions/0068-faehigkeiten-und-spiegel.md) |
