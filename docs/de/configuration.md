# Konfiguration

Öffentliche Voreinstellungen in `config/zentinel.kdl`. Die Datei enthält nur Platzhalter: Werte für Geheimnisse kommen aus dem Tresor (ADR 0067), wenn die Datei auf dem Server erzeugt wird. Erzeugt aus `config/schema.toml`.

| Einstellung | Typ | Standard | Geheimnis | Beschreibung |
|---|---|---|---|---|
| `schema-version` | string | `1.0` | nein | Version des Konfigurationsschemas. |
| `system.worker-threads` | integer | `0` | nein | Arbeits-Threads; 0 = einer je CPU-Kern. |
| `system.graceful-shutdown-timeout-secs` | integer | `30` | nein | Sekunden, um laufende Anfragen beim Beenden abzuschließen. |
| `listeners.listener.https.address` | string | `0.0.0.0:443` | nein | Öffentliche HTTPS-Adresse des Tores. |
| `tls.cert-file` | path | `/etc/zentinel/tls/fullchain.pem` | nein | Öffentliche Zertifikatskette (PEM). |
| `tls.key-file` | path | - | ja (aus dem Tresor: `fs/zentinel/tls-key#file`) | Datei mit dem privaten TLS-Schlüssel. Der Tresor schreibt die Datei; der Pfad im Muster ist ein Platzhalter. |
| `upstreams.upstream.kanidm.target` | string | `127.0.0.1:8443` | nein | Wo Kanidm lauscht (Loopback). |
| `upstreams.upstream.kanidm.tls.sni` | string | - | nein | Servername für die TLS-Verbindung zu Kanidm; die öffentliche Domain des Anmeldedienstes (kein Geheimnis, je Installation verschieden). |
| `routes.route.kanidm.matches.host` | string | - | nein | Hostname, der an Kanidm geleitet wird. |
