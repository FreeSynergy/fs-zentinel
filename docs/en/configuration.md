# Configuration

Public default configuration in `config/zentinel.kdl`. It holds placeholders only: values for secrets come from the vault (ADR 0067) when the file is rendered on the server. Generated from `config/schema.toml`.

| Setting | Type | Default | Secret | Description |
|---|---|---|---|---|
| `schema-version` | string | `1.0` | no | Configuration schema version. |
| `system.worker-threads` | integer | `0` | no | Worker threads; 0 = one per CPU core. |
| `system.graceful-shutdown-timeout-secs` | integer | `30` | no | Seconds to finish running requests on shutdown. |
| `listeners.listener.https.address` | string | `0.0.0.0:443` | no | Public HTTPS address of the gate. |
| `tls.cert-file` | path | `/etc/zentinel/tls/fullchain.pem` | no | Public certificate chain (PEM). |
| `tls.key-file` | path | - | yes (from vault: `fs/zentinel/tls-key#file`) | Private TLS key file. The vault writes the file; the path in the template is a placeholder. |
| `upstreams.upstream.kanidm.target` | string | `127.0.0.1:8443` | no | Where Kanidm listens (loopback). |
| `upstreams.upstream.kanidm.tls.sni` | string | - | no | Server name for the TLS connection to Kanidm; the public domain of the login service (not a secret, differs per installation). |
| `routes.route.kanidm.matches.host` | string | - | no | Host name routed to Kanidm. |
