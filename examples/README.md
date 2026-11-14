# Example: three sites "we are rebuilding" with Zentinel alone

Template, not a production file. No secrets, no real keys. Domains are variables.

| File | What |
|---|---|
| `zentinel.kdl.in` | Zentinel configuration: ports 80 (redirect to HTTPS) and 443 (static sites), one ACME HTTP-01 certificate per domain, one document root per domain |
| `zentinel-dns01-hetzner.kdl.in` | Same with DNS-01 and wildcard certificates through the Hetzner DNS provider. **Does not work today** (see below) |
| `www/index.html` | The page, German and English, no external resources |
| `zentinel-http-only.kdl.in` | Interim configuration for the first start: the three sites over plain HTTP, no TLS |
| `render-config.sh` | Fills the variables, checks them strictly, optionally copies the page into each document root |
| `test_render.sh`, `test_serve.sh` | Selftests (`ZENTINEL=/path/to/zentinel` runs `zentinel test` and a local serve/redirect test) |

## Monday, step by step (a person does this on server 2)

Why this order: when the first certificate cannot be issued, Zentinel stops at start ("failing fast", `crates/proxy/src/main.rs`, upstream 26.11_2) and serves nothing. With ACME in the configuration it can therefore only be started once the DNS records already point to the server and port 80 is reachable. So the first start uses the plain-HTTP configuration.

0. Before anything else: stop the old web server program and check that ports 80 and 443 are free: `ss -tlnp | grep ':80\|:443'` must print nothing (server 2 is reinstalled anyway; this is the control).
1. Install Zentinel (the `.deb` of this repository or the tarball) and the document roots; render the interim configuration (HTTP only, no TLS):
   ```sh
   SITE1=<domain-1> SITE2=<domain-2> SITE3=<domain-3> ACME_EMAIL=<contact address> \
     ./render-config.sh --http-only --install-pages /etc/zentinel/zentinel.kdl
   zentinel test -c /etc/zentinel/zentinel.kdl      # must say "test is successful"
   systemctl enable --now zentinel
   ```
   Check from another machine with the server's IP address and a `Host:` header per domain that the page comes back. Port 80 must be reachable from the internet (firewall, provider).
2. DNS (Hetzner DNS, set by the user): A records of the three domains to server 2. Remove existing AAAA records (for example those of the old server) actively. Do not set AAAA records unless the listeners also bind IPv6: the examples bind `0.0.0.0` only (IPv4), and Let's Encrypt prefers IPv6 when a record exists (not tested here). Wait until the records are visible (`dig +short <domain> @1.1.1.1`).
3. Staging certificates: render the full configuration, restart:
   ```sh
   ./render-config.sh --staging /etc/zentinel/zentinel.kdl      # same variables as above
   zentinel test -c /etc/zentinel/zentinel.kdl && systemctl restart zentinel
   journalctl -u zentinel -n 50
   ```
   `staging #true` selects `https://acme-staging-v02.api.letsencrypt.org/directory` (upstream `crates/proxy/src/acme/client.rs`, constant `LETSENCRYPT_STAGING`). Staging certificates are not trusted by browsers; check them with `openssl s_client -connect <domain>:443 -servername <domain>` (issuer "(STAGING)"). If the start fails, the log names the domain; fix DNS or port 80 and start again.
4. Production: switching alone is NOT enough. Zentinel renews only when the stored certificate is close to expiry (`needs_renewal`, `renew-before-days`), and the ACME account file (`account.json`/`credentials.json`) belongs to the staging server. Stop the service, empty the ACME state, render for production, start:
   ```sh
   systemctl stop zentinel
   rm -rf /var/lib/zentinel/acme/*                  # certificates, keys and the staging account
   ./render-config.sh --production /etc/zentinel/zentinel.kdl
   zentinel test -c /etc/zentinel/zentinel.kdl && systemctl start zentinel
   ```
   Let's Encrypt limits production orders and failed validations (rate limits): do not repeat step 4 without need. The unit has `Restart=on-failure` (up to 3 restarts per minute): if the start fails, run `systemctl stop zentinel` at once and read `journalctl -u zentinel` before trying again, otherwise the automatic restarts burn the limit.
5. Way back: if step 3 or 4 fails, all three sites are offline. Return to the interim state with `./render-config.sh --http-only /etc/zentinel/zentinel.kdl && systemctl restart zentinel`, fix the cause, then repeat from step 3.

## What is proven and what is not

Proven in the upstream code and docs, and run locally (`test_serve.sh`): static files, routing by host, HTTP to HTTPS redirect (namespace plus redirect filter; the query string is lost). The ACME HTTP-01 configuration passes `zentinel test`. NOT run: the real ACME exchange with Let's Encrypt (no internet test here); the staging run in step 3 is the proof. Not proven: that a renewal on the port-80 listener with the redirect is answered before the redirect (upstream docs say the challenge is answered before everything else).

## Hetzner DNS-01 (wildcards)

Zentinel's `hetzner` provider talks to `https://dns.hetzner.com/api/v1`. Hetzner removed that API on 2026-05-27 (status.hetzner.com, incident c2146c42). The new DNS lives in the Hetzner Console / Cloud API with other tokens and endpoints, which Zentinel 26.11_1 and 26.11_2 do not use. The DNS-01 file therefore only documents the configuration keys. The token would be a file (default `/etc/zentinel/secrets/hetzner-dns-token`, owner `zentinel`, mode `0600`, put there by the person, never in a repository); Zentinel only warns when the mode is looser.

Language: [Deutsch](README.de.md)
