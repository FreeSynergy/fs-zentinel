# Beispiel: drei Seiten "Wir bauen um" mit Zentinel allein

Vorlage, keine fertige Produktionsdatei. Keine Geheimnisse, keine echten Schlüssel. Die Domains sind Variablen.

| Datei | Inhalt |
|---|---|
| `zentinel.kdl.in` | Zentinel-Konfiguration: Port 80 (Weiterleitung auf HTTPS) und 443 (statische Seiten), je Domain ein ACME-HTTP-01-Zertifikat, je Domain ein eigenes Wurzelverzeichnis |
| `zentinel-http-only.kdl.in` | Übergangskonfiguration für den ersten Start: die drei Seiten über reines HTTP, ohne TLS |
| `zentinel-dns01-hetzner.kdl.in` | Dasselbe mit DNS-01 und Wildcard-Zertifikaten über den Hetzner-DNS-Anbieter. **Funktioniert heute nicht** (siehe unten) |
| `www/index.html` | Die Seite, deutsch und englisch, ohne externe Ressourcen |
| `render-config.sh` | Setzt die Variablen ein, prüft sie streng, kopiert auf Wunsch die Seite in jedes Wurzelverzeichnis |
| `test_render.sh`, `test_serve.sh` | Selbsttests (`ZENTINEL=/Pfad/zu/zentinel` führt zusätzlich `zentinel test` und einen lokalen Auslieferungs- und Weiterleitungstest aus) |

## Montag, Schritt für Schritt (ein Mensch führt das auf Server 2 aus)

Warum diese Reihenfolge: Kann das erste Zertifikat nicht ausgestellt werden, bricht Zentinel beim Start ab ("failing fast", `crates/proxy/src/main.rs`, Upstream 26.11_2) und liefert nichts aus. Mit ACME in der Konfiguration lässt es sich also erst starten, wenn die DNS-Einträge schon auf den Server zeigen und Port 80 erreichbar ist. Der erste Start nutzt deshalb die Konfiguration nur mit HTTP.

0. Vor allem anderen: das alte Webserver-Programm stoppen und prüfen, dass die Ports 80 und 443 frei sind: `ss -tlnp | grep ':80\|:443'` darf nichts ausgeben (Server 2 wird zwar neu installiert, dies ist die Kontrolle).
1. Zentinel installieren (das `.deb` dieses Repositories oder den Tarball), Wurzelverzeichnisse anlegen, die Übergangskonfiguration (nur HTTP, kein TLS) erzeugen:
   ```sh
   SITE1=<domain-1> SITE2=<domain-2> SITE3=<domain-3> ACME_EMAIL=<kontaktadresse> \
     ./render-config.sh --http-only --install-pages /etc/zentinel/zentinel.kdl
   zentinel test -c /etc/zentinel/zentinel.kdl      # muss "test is successful" melden
   systemctl enable --now zentinel
   ```
   Von einem anderen Rechner mit der IP-Adresse des Servers und je einem `Host:`-Kopf prüfen, dass die Seite kommt. Port 80 muss aus dem Internet erreichbar sein (Firewall, Anbieter).
2. DNS (Hetzner-DNS, setzt der Nutzer): A-Einträge der drei Domains auf Server 2. Vorhandene AAAA-Einträge (z. B. die des alten Servers) aktiv entfernen. Keine AAAA-Einträge setzen, solange die Listener nicht auch IPv6 binden: Die Beispiele binden nur `0.0.0.0` (IPv4), und Let's Encrypt bevorzugt IPv6, wenn ein Eintrag existiert (hier nicht getestet). Warten, bis die Einträge sichtbar sind (`dig +short <domain> @1.1.1.1`).
3. Staging-Zertifikate: die volle Konfiguration erzeugen, neu starten:
   ```sh
   ./render-config.sh --staging /etc/zentinel/zentinel.kdl      # dieselben Variablen wie oben
   zentinel test -c /etc/zentinel/zentinel.kdl && systemctl restart zentinel
   journalctl -u zentinel -n 50
   ```
   `staging #true` wählt `https://acme-staging-v02.api.letsencrypt.org/directory` (Upstream `crates/proxy/src/acme/client.rs`, Konstante `LETSENCRYPT_STAGING`). Staging-Zertifikate sind für Browser nicht vertrauenswürdig; prüfen mit `openssl s_client -connect <domain>:443 -servername <domain>` (Aussteller "(STAGING)"). Schlägt der Start fehl, nennt das Protokoll die Domain; DNS oder Port 80 beheben und neu starten.
4. Produktion: Umschalten allein genügt NICHT. Zentinel erneuert nur, wenn das gespeicherte Zertifikat bald abläuft (`needs_renewal`, `renew-before-days`), und die ACME-Konto-Datei (`account.json`/`credentials.json`) gehört zum Staging-Server. Dienst anhalten, ACME-Ablage leeren, für Produktion erzeugen, starten:
   ```sh
   systemctl stop zentinel
   rm -rf /var/lib/zentinel/acme/*                  # Zertifikate, Schlüssel und das Staging-Konto
   ./render-config.sh --production /etc/zentinel/zentinel.kdl
   zentinel test -c /etc/zentinel/zentinel.kdl && systemctl start zentinel
   ```
   Let's Encrypt begrenzt Bestellungen in der Produktion (Rate Limits): Schritt 4 nicht ohne Not wiederholen. Die Unit hat `Restart=on-failure` (bis zu 3 Neustarts pro Minute): Schlägt der Start fehl, sofort `systemctl stop zentinel` und `journalctl -u zentinel` lesen, bevor man es erneut versucht; sonst verbrauchen die automatischen Neustarts das Limit für fehlgeschlagene Prüfungen.
5. Rückweg: Scheitert Schritt 3 oder 4, sind alle drei Seiten offline. Zurück zum Übergangszustand mit `./render-config.sh --http-only /etc/zentinel/zentinel.kdl && systemctl restart zentinel`, Ursache beheben, dann ab Schritt 3 wiederholen.

## Was belegt ist und was nicht

Belegt im Upstream-Code und in der Doku, und lokal gelaufen (`test_serve.sh`): statische Dateien, Routing nach Host, Weiterleitung HTTP auf HTTPS (Namespace plus Redirect-Filter; der Query-String geht dabei verloren). Die ACME-HTTP-01-Konfiguration besteht `zentinel test`. NICHT ausgeführt: der echte ACME-Austausch mit Let's Encrypt (kein Internettest hier), der Staging-Lauf in Schritt 3 ist der Beweis. Nicht belegt: ob die Erneuerung über den Namespace-Listener auf Port 80 vor der Weiterleitung beantwortet wird (laut Upstream-Doku wird die Challenge vor allem anderen beantwortet).

## Hetzner DNS-01 (Wildcards)

Der `hetzner`-Anbieter von Zentinel spricht `https://dns.hetzner.com/api/v1`. Hetzner hat diese API am 2026-05-27 entfernt (status.hetzner.com, Incident c2146c42). Die neue DNS-Verwaltung liegt in der Hetzner-Konsole mit anderen Token und Endpunkten, die Zentinel 26.11_1 und 26.11_2 nicht benutzen. Die DNS-01-Datei zeigt deshalb nur die Konfigurationsschlüssel. Der Token wäre eine Datei (Standard `/etc/zentinel/secrets/hetzner-dns-token`, Besitzer `zentinel`, Modus `0600`, vom Menschen angelegt, nie in einem Repository); Zentinel warnt nur bei zu offenem Modus.

Sprache: [English](README.md)
