# Bekannte Grenzen und offene Punkte

git-bug ist in den FreeSynergy-Repos noch nicht eingerichtet (es wird später für alle drei Server-Repos einheitlich eingerichtet), deshalb stehen offene Punkte hier. Jeder Eintrag sagt, was wir gesehen haben, woher wir es wissen und was wir entschieden haben. „Geprüft“ heißt: im lokalen Test selbst ausgeführt (`fs-kanidm/scripts/test/podman-stack.sh`); „laut Hersteller-Doku“ heißt: nur gelesen, nicht getestet.

## 1. `ca-cert` im KDL half bei einer privaten CA nicht (Zentinel 26.11_1)

> Mit 26.11_2 (gepinnt seit 2026-11-14) nicht neu geprüft. Der Befund unten stammt von 26.11_1.

- **Geprüft:** Ein Upstream mit `tls { sni "..." ca-cert "/pfad/ca.pem" }` scheiterte weiter mit `invalid peer certificate: UnknownIssuer`, wenn der Upstream (Kanidm 1.12.0) ein Zertifikat einer privaten CA nutzte; das Tor antwortete 502. Mit der Umgebungsvariable `SSL_CERT_FILE=<ca.pem>` am Zentinel-Prozess funktionierte derselbe Aufbau; der lokale Test nutzt diese Variable.
- **Ungeprüft:** warum. Im Hauptzweig des Herstellers gibt es in `crates/proxy/src/tls.rs` eine Funktion `build_upstream_tls_config`, die `ca_cert` liest; ob sie in 26.11_1 an die echte Upstream-Verbindung angeschlossen ist, haben wir nicht geprüft.
- **Entscheidung:** Unsere Vorlage enthält kein `ca-cert`. Auf dem echten Server hat Kanidm ein öffentliches Zertifikat für seinen Namen, das die System-Wurzeln prüfen. Bei privater CA `SSL_CERT_FILE` nutzen. Erweist sich das als Zentinel-Fehler, folgt später ein kurzes Upstream-Issue; jetzt keins.

## 2. Control Plane: Stabilität des Protokolls unbekannt

- **Laut Hersteller-Doku (nicht von uns getestet):** Die Control Plane des Herstellers (`zentinelproxy/zentinel-control-plane`, Apache-2.0) dokumentiert eine Knoten-API unter `/api/v1` ([docs/PROXY-REGISTRATION.md](https://github.com/zentinelproxy/zentinel-control-plane/blob/main/docs/PROXY-REGISTRATION.md), [priv/static/openapi.yaml](https://github.com/zentinelproxy/zentinel-control-plane/blob/main/priv/static/openapi.yaml)). Ihre README nennt das Projekt „Beta“ ([README](https://github.com/zentinelproxy/zentinel-control-plane/blob/main/README.md)); in den gelesenen Dokumenten fanden wir kein Versprechen zu Kompatibilität oder Versionierung.
- **Entscheidung:** Der Agent `zentinel-cp-agent` des Herstellers wird nicht gespiegelt. FreeSynergy baut nach 3b eine eigene Control Plane in Rust und prüft das Protokoll dann erneut. Bis dahin verwaltet fs-zentinel die KDL direkt: mit `zentinel test -c` prüfen, die Datei atomar ersetzen, dann im Betrieb neu laden. Neuladen per SIGHUP nennt die README des Herstellers ([Funktionen, „Hot reload“](https://github.com/zentinelproxy/zentinel/blob/26.11_1/README.md)); wir haben es **noch nicht** getestet.

## 3. Kein Login im Tor (später)

- **Laut Hersteller-Doku:** Der Auth-Agent des Herstellers prüft nur Bearer-Tokens gegen ein JWKS (als experimentell gekennzeichnet) und macht keinen Browser-Login ([README von zentinel-agent-auth](https://github.com/zentinelproxy/zentinel-agent-auth/blob/v0.3.0/README.md)).
- **Entscheidung:** Später ein Login-Agent für Zentinel (Forward-Auth gegen Kanidm). Programme mit eigenem Login melden sich selbst per OIDC bei Kanidm an. Siehe [Roadmap](../ROADMAP.md).

## 4. Keine dokumentierte Weiterleitung von HTTP auf HTTPS

- **Geprüft:** Mit `service-type "builtin"` und ohne Handler warnte `zentinel test`, die Route werde als `web` bedient und die Einstellung ignoriert; einen dokumentierten Weiterleitungs-Handler fanden wir nicht. Die Vorlage hat deshalb keinen HTTP-Listener. Siehe [Roadmap](../ROADMAP.md).

Sprache: [English](../en/known-limits.md)
