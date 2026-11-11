# Roadmap

Entries, not promises. Nothing here is built yet.

1. **Login agent for Zentinel (later).** A Zentinel agent that does forward-auth against Kanidm (OIDC authorisation-code flow, session cookie, identity headers to the upstream) for programs that have no login of their own. Programs with a login sign in to Kanidm themselves by OIDC; the gate stays free of login until this exists. The upstream auth agent only checks bearer tokens (experimental) and does not do this.
2. **HTTP to HTTPS redirect.** Zentinel 26.11_1 has no documented redirect handler (the `builtin` service type needs a handler); a plain-HTTP listener is therefore left out of `config/zentinel.kdl`. Revisit with the next release; ACME needs port 80.
3. **Control plane.** FreeSynergy rebuilds the Zentinel control-plane functions in Rust (functions only, no code is copied). Open: whether to speak the upstream node API with the unchanged upstream agent. The API is documented (`docs/PROXY-REGISTRATION.md`, `priv/static/openapi.yaml`, base `/api/v1`) but upstream calls the project Beta and makes no stability promise; decision pending with the strategy.
