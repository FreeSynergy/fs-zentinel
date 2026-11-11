# Fähigkeiten

Fähigkeiten-Tags für den FreeSynergy-Katalog (ADR 0068). `provides` = bietet an, `requires` = braucht, `recommends` = kann nutzen. Unterstützung ist `yes`, `no` oder `unstable` (ja, nein, instabil); jedes `yes` und `unstable` nennt die Quelle beim Hersteller. Erzeugt aus `capabilities.toml`; geprüft für Version Zentinel 26.11_1 (2026-11-11).

| Tag | Beziehung | Unterstützung | Bedeutung | Quelle |
|---|---|---|---|---|
| `gateway.reverse-proxy` | provides | ja | Reverse-Proxy mit TLS-Abschluss, Routing nach Host und Pfad, Lastverteilung, Gesundheitsprüfung, Ratenbegrenzung, Neuladen im Betrieb (SIGHUP). | [link](https://github.com/zentinelproxy/zentinel/blob/26.11_1/README.md) |
| `identity.oidc` | provides | instabil | Nur die Prüfung von OIDC-Bearer-Tokens gegen ein JWKS im getrennten Auth-Agenten, als experimentell gekennzeichnet; kein Browser-Login (kein Authorization-Code-Ablauf). Zentinel ist vorerst ein Tor ohne eigenen Login. | [link](https://github.com/zentinelproxy/zentinel-agent-auth/blob/v0.3.0/README.md) |
| `identity.oauth2` | provides | instabil | Bearer-/JWT-Prüfung (HS*, RS*, ES*) im Auth-Agenten; SAML, mTLS und Token-Exchange lehnt der Agent ab, weil sie das Vertraute nicht prüfen. | [link](https://github.com/zentinelproxy/zentinel-agent-auth/blob/v0.3.0/README.md) |
| `identity.scim` | provides | instabil | Ein SCIM-2.0-Nutzerspeicher im Auth-Agenten, der deaktivierte OIDC-Nutzer sperren kann; experimentell. | [link](https://github.com/zentinelproxy/zentinel-agent-auth/blob/v0.3.0/README.md) |
| `identity.ldap` | provides | nein | Wird nicht angeboten; ein Proxy hat kein Verzeichnis. | - |
| `identity.radius` | provides | nein | Wird nicht angeboten. | - |
| `identity.pam` | provides | nein | Wird nicht angeboten. | - |
| `identity.ssh-keys` | provides | nein | Wird nicht angeboten. | - |
| `identity.passkeys` | provides | nein | Wird nicht angeboten; Passkeys übernimmt der Anmeldedienst hinter dem Tor. | - |
| `identity.oidc` | recommends | ja | Zentinel braucht keinen Anmeldedienst, aber die Programme dahinter nutzen einen (Kanidm) für ihre Anmeldung. | [link](https://github.com/FreeSynergy/fs-documentation/blob/main/conventions/decisions/0068-faehigkeiten-und-spiegel.md) |
