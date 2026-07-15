# cloudflared — Cloudflare Tunnel

cloudflared runs an outbound-only connection from this host to Cloudflare's
edge. No port is exposed by this container and no router port-forward is
needed — Cloudflare terminates public HTTPS for the hostname(s) configured
in `config/config.yml` and relays traffic over the tunnel to whatever local
service that file's ingress rules point at. Currently used for exactly one
thing: the Alexa custom-skill backend (`../../../makerops-ai/alexa-bridge/`)
— see `docs/alexa-voice-setup.md` in that repo for the full walkthrough
this README is one piece of.

- **Home page / docs:** <https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/>
- **GitHub:** <https://github.com/cloudflare/cloudflared>
- **Docker image:** `cloudflare/cloudflared`

---

## Attribution

**cloudflared** is developed and maintained by Cloudflare, Inc. and made
available under the [Apache License 2.0](https://github.com/cloudflare/cloudflared/blob/master/LICENSE).

---

## Setup (one-time, before first start)

Requires a Cloudflare account with the domain you're routing through
already added as a zone (the same one `remote_access/cloudflare-ddns`
already manages).

1. **Authenticate the CLI** — this opens a browser to authorize:

   ```bash
   docker run --rm -it -v "$(pwd)/config:/etc/cloudflared" cloudflare/cloudflared \
     tunnel login
   ```

   (Or use a locally-installed `cloudflared` binary if you have one — the
   result lands in the same `config/` either way; adjust the `-v` mount to
   wherever it writes `cert.pem`.)

2. **Create the tunnel:**

   ```bash
   docker run --rm -it -v "$(pwd)/config:/etc/cloudflared" cloudflare/cloudflared \
     tunnel create alexa-bridge
   ```

   This writes `config/<tunnel-id>.json` (the credentials file) and prints
   the tunnel ID — note it for the next step.

3. **Supply the ingress config** — copy the private template from
   `makerops-ai/proxy/cloudflared-config.yml.template` into
   `config/config.yml` and fill in the tunnel ID and credentials filename
   from step 2. This file is private (routes to internal service ports)
   and gitignored here — see `makerops-ai/proxy/README.md` for why this
   lives in the private repo instead of being hardcoded in this public one.

4. **Route DNS** — creates the CNAME record in the zone this tunnel targets:

   ```bash
   docker run --rm -it -v "$(pwd)/config:/etc/cloudflared" cloudflare/cloudflared \
     tunnel route dns alexa-bridge alexa.<your-domain>
   ```

   Confirm `<your-domain>` is the zone `remote_access/cloudflare-ddns`
   already manages (Cloudflare dashboard → DNS) before running this.

5. **Start it:**

   ```bash
   ./start.sh
   ```

6. **Verify from outside your LAN** (mobile data, not home WiFi):

   ```bash
   curl -s https://alexa.<your-domain>/healthz
   ```

---

## Scripts

### `./start.sh`

Validates `config/config.yml` exists, then starts the container.

### `./stop.sh`

Stops the container. `config/` (tunnel identity + credentials) is preserved.

### `./teardown.sh`

Interactive removal of the container/image/network. Does **not** delete the
tunnel from your Cloudflare account or `config/` on disk — see the script's
header comment for how to fully retire a tunnel.

---

## Architecture

```text
Echo device → Amazon Alexa cloud → https://alexa.<domain> (Cloudflare edge, TLS terminated)
                                          └─► outbound tunnel (this container)
                                                └─► http://host.docker.internal:8103 (alexa-bridge)
```

No inbound port is ever opened on this host or router — the tunnel is
initiated outbound from here to Cloudflare, the reverse of a normal
port-forward.

---

## Cheat Sheet

### Logs

```bash
docker compose -p cloudflared logs -f
```

### Check tunnel status

```bash
docker run --rm -v "$(pwd)/config:/etc/cloudflared" cloudflare/cloudflared \
  tunnel info alexa-bridge
```

### Add another route later

Add another `hostname:`/`service:` pair to `config/config.yml`'s `ingress:`
list (before the catch-all `service: http_status:404` entry, which must
stay last), then `docker compose -p cloudflared up -d --force-recreate` and
`tunnel route dns alexa-bridge <new-hostname>` for the new hostname.
