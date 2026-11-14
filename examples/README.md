# Example: three sites "we are rebuilding" with Zentinel alone

Template, not a production file. No secrets, no real keys. Domains are variables.

| File | What |
|---|---|
| `zentinel.kdl.in` | Zentinel configuration: ports 80 (redirect to HTTPS) and 443 (static sites), one ACME HTTP-01 certificate per domain, one document root per domain |
| `zentinel-dns01-hetzner.kdl.in` | Same with DNS-01 and wildcard certificates through the Hetzner DNS provider. **Does not work today** (see below) |
| `www/index.html` | The page, German and English, no external resources |
| `render-config.sh` | Fills the variables, checks them strictly, optionally copies the page into each document root |
| `test_render.sh`, `test_serve.sh` | Selftests (`ZENTINEL=/path/to/zentinel` runs `zentinel test` and a local serve/redirect test) |

## Monday, step by step (a person does this on the server)

1. DNS (Hetzner): A (and AAAA) records of the three domains point to server 2. Ports 80 and 443 must be reachable from the internet.
2. Install Zentinel (the `.deb` of this repository, or the tarball) and create the document roots.
3. Render and check:
   ```sh
   SITE1=freesynergy.net SITE2=helfa.org SITE3=freeplanetearth.org ACME_EMAIL=<contact address> \
     ./render-config.sh --staging --install-pages /etc/zentinel/zentinel.kdl
   zentinel test -c /etc/zentinel/zentinel.kdl      # must say "test is successful"
   ```
4. `systemctl enable --now zentinel`. With `--staging` Let's Encrypt issues untrusted test certificates (no rate limit). Check `journalctl -u zentinel`.
5. When the staging run worked: render again with `--production`, remove `/var/lib/zentinel/acme`, restart.

## What is proven and what is not

See `/srv/FreeSynergy/.scratch/zentinel-befund.md` for the sources. Short: static files, several hosts, per-domain ACME HTTP-01, redirect HTTP to HTTPS (namespace plus redirect filter) are in the upstream code and docs, and static serving, host routing and the redirect were run locally (`test_serve.sh`). The real ACME exchange with Let's Encrypt was NOT run (no internet test here): the staging run in step 4 is the proof.

## Hetzner DNS-01 (wildcards)

Zentinel's `hetzner` provider talks to `https://dns.hetzner.com/api/v1`. Hetzner removed that API on 2026-05-27 (status.hetzner.com, incident c2146c42). The new DNS lives in the Hetzner Console / Cloud API with other tokens and endpoints, which Zentinel 26.11_1 and 26.11_2 do not use. The DNS-01 file therefore only documents the configuration keys. The token would be a file (default `/etc/zentinel/secrets/hetzner-dns-token`, owner `zentinel`, mode `0600`, put there by the person, never in a repository); Zentinel only warns when the mode is looser.
