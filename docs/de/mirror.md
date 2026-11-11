# Spiegel und Prüfung

Der Hersteller veröffentlicht signierte Archive, deshalb spiegelt FreeSynergy sie unverändert (ADR 0068):

1. `mirror.toml` legt Release `26.11_1`, den Commit und die **erwartete Signatur-Identität** fest (`https://github.com/zentinelproxy/zentinel/.github/workflows/release.yml@refs/tags/26.11_1`, Aussteller `https://token.actions.githubusercontent.com`).
2. GitHub Actions lädt die Archive, prüft SHA-256 und führt `cosign verify-blob --bundle` aus (Sigstore, schlüssellos: es gibt keinen festen Schlüssel; Vertrauen ist die Identität oben plus das öffentliche Rekor-Protokoll). Schlägt etwas fehl, bricht der Lauf ab.
3. Das Quellcode-Archiv derselben Version (git archive des festgelegten Commits), die Lizenz und die SBOMs des Herstellers kommen dazu.
4. Jede Datei bekommt eine OpenPGP-Signatur (`.asc`) vom FreeSynergy-Release-Schlüssel, `SHA256SUMS.txt` listet die Dateien.

FreeSynergy-Release selbst prüfen:

```sh
scripts/verify-mirror.sh <Verzeichnis-mit-den-Release-Dateien>
```

Die Signatur des Herstellers prüft man, indem man Archiv und `.bundle` aus dem Hersteller-Release lädt und `cosign verify-blob` mit der Identität aus `mirror.toml` ausführt.

Noch nicht gespiegelt: der Knoten-Agent `zentinel-cp-agent` der Control-Plane. Sein Protokoll ist dokumentiert, aber der Hersteller nennt das Projekt Beta und sagt nichts zur Stabilität (siehe [Roadmap](../ROADMAP.md)).

Sprache: [English](../en/mirror.md)
