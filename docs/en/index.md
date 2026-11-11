# FreeSynergy.Zentinel

Zentinel is the gate of a FreeSynergy server: it receives all public connections, ends TLS and passes requests to the programs behind it. Zentinel starts first, then Kanidm (the login service) behind it.

- [Capabilities](capabilities.md): what Zentinel offers and what it does not, with sources.
- [Configuration](configuration.md): the public KDL defaults and what comes from the vault.
- [Mirror](mirror.md): where the package comes from and how it is verified.

Zentinel has no login of its own for now: programs sign in to Kanidm by OIDC themselves. A login agent for programs without one is on the [roadmap](../ROADMAP.md).

Language: [Deutsch](../de/index.md)
