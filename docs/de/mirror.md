# Spiegel und Prüfung

Der Hersteller veröffentlicht signierte Archive, deshalb spiegelt FreeSynergy sie unverändert (ADR 0068):

1. `mirror.toml` legt Release `26.11_2`, den Commit und die **erwartete Signatur-Identität** fest (`https://github.com/zentinelproxy/zentinel/.github/workflows/release.yml@refs/tags/26.11_2`, Aussteller `https://token.actions.githubusercontent.com`) sowie Commit, Repository und Ref, die das Signaturzertifikat tragen muss (cosign-Optionen `--certificate-github-workflow-sha/-repository/-ref`; das Zertifikat des Herstellers enthält sie als OIDs 1.3.6.1.4.1.57264.1.3/.5/.6)..
2. GitHub Actions lädt die Archive, prüft SHA-256 und führt `cosign verify-blob --bundle` aus (Sigstore, schlüssellos: es gibt keinen festen Schlüssel; Vertrauen ist die Identität oben plus das öffentliche Rekor-Protokoll). Schlägt etwas fehl, bricht der Lauf ab.
3. Das Quellcode-Archiv derselben Version (git archive des festgelegten Commits), die Lizenz und die SBOMs des Herstellers kommen dazu.
4. Jede Datei bekommt eine OpenPGP-Signatur (`.asc`) vom FreeSynergy-Release-Schlüssel, `SHA256SUMS.txt` listet die Dateien.

FreeSynergy-Release selbst prüfen:

```sh
scripts/verify-mirror.sh <Verzeichnis-mit-den-Release-Dateien>
```

Die Signatur des Herstellers prüft man, indem man Archiv und `.bundle` aus dem Hersteller-Release lädt und `cosign verify-blob` mit der Identität aus `mirror.toml` ausführt.

## Pakete (.deb)

Neben den Tarballs des Herstellers enthält das Release die Debian-Pakete `zentinel_26.11.2-1_amd64.deb` und `zentinel_26.11.2-1_arm64.deb`. Sie sind ein **Repackaging**: FreeSynergy kompiliert nichts. `scripts/make-deb.sh` packt das geprüfte Binary des Herstellers, dessen eigene systemd-Unit, sysusers-Datei und Starterkonfiguration in ein Paket; geändert wird nur `ExecStart=/usr/bin/zentinel` (Upstream: `/usr/local/bin`). Die Debian-Version ist die Upstream-Version mit `.` statt `_` (Debian verbietet den Unterstrich) plus die Paket-Revision (`26.11.2-1`).

- Die Installation aktiviert und startet den Dienst nicht. `apt remove` behält `/etc/zentinel` und `/var/lib/zentinel`.
- **`apt purge zentinel` löscht `/var/lib/zentinel` und `/var/log/zentinel`**, also den ACME-Konto-Schlüssel, alle ausgestellten Zertifikate samt privaten Schlüsseln und die Protokolle. Der Systembenutzer bleibt.
- Mindestplattform: glibc 2.34 (das Binary des Herstellers braucht GLIBC bis 2.34, dazu libgcc_s und libm): Debian 12 und 13, Ubuntu 22.04 und 24.04.
- Smoke-Test (Job `smoke`, `scripts/smoke-deb.sh`, Images in `mirror.toml` per Digest festgelegt): Das amd64-Paket wird mit apt auf Debian 12, Debian 13, Ubuntu 22.04 und Ubuntu 24.04 installiert; das installierte Binary liefert als Benutzer `zentinel` eine statische Seite aus; remove behält die Konfiguration, purge entfernt den Zustand. Der Job `sign` läuft erst, wenn er grün ist. Das arm64-Paket wird nur gebaut (Architektur des Binaries geprüft) und **nirgends gestartet**.
- `verify-mirror.sh` prüft zusätzlich, dass jede `.deb` ein wohlgeformtes Debian-Archiv ist.

Noch nicht gespiegelt: der Knoten-Agent `zentinel-cp-agent` der Control-Plane. Sein Protokoll ist dokumentiert, aber der Hersteller nennt das Projekt Beta und sagt nichts zur Stabilität (siehe [Roadmap](../ROADMAP.md)).

Sprache: [English](../en/mirror.md)
