# Roadmap

Entries, not promises. Nothing here is built yet.

1. **Login agent for Zentinel (later).** A Zentinel agent that does forward-auth against Kanidm (OIDC authorisation-code flow, session cookie, identity headers to the upstream) for programs that have no login of their own. Programs with a login sign in to Kanidm themselves by OIDC; the gate stays free of login until this exists. The upstream auth agent only checks bearer tokens (experimental) and does not do this.
2. **HTTP to HTTPS redirect in the default configuration.** Zentinel has no redirect handler, but a `redirect` filter in a namespace bound to the port-80 listener works (tested locally with 26.11_2, see `examples/zentinel.kdl.in`; the query string is not carried over). `config/zentinel.kdl` still has no plain-HTTP listener; adopt the example once the real ACME run on a server has been seen. ACME HTTP-01 needs port 80.
3. **Control plane.** FreeSynergy rebuilds the Zentinel control-plane functions in Rust (functions only, no code is copied). Open: whether to speak the upstream node API with the unchanged upstream agent. The API is documented (`docs/PROXY-REGISTRATION.md`, `priv/static/openapi.yaml`, base `/api/v1`) but upstream calls the project Beta and makes no stability promise; decision pending with the strategy.
