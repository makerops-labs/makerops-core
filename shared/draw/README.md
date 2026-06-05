# draw.io — Self-hosted Diagramming

draw.io (diagrams.net) is a free, open-source diagramming and whiteboarding tool. It supports flowcharts, network diagrams, UML, ERDs, and general-purpose whiteboards, with an offline-capable editor and no account required.

- **Home page:** https://www.diagrams.net
- **GitHub:** https://github.com/jgraph/drawio
- **Docker image:** https://github.com/jgraph/docker-drawio

---

## Attribution

**draw.io** is open-source software developed and maintained by JGraph Ltd. It is licensed under the [Apache 2.0 License](https://github.com/jgraph/drawio/blob/dev/LICENSE).

- **Support draw.io:** [diagrams.net](https://www.diagrams.net) (free) or [draw.io for Confluence/Jira](https://www.diagrams.net/blog/atlassian-marketplace)

---

## Local Access

| | |
|---|---|
| **URL** | http://localhost:8085 |
| **LAN URL** | http://draw.localhost (via name-proxy) |
| **Auth** | None — draw.io has no built-in authentication |

draw.io is stateless. Diagrams are saved to the browser's local storage, downloaded as `.drawio` files, or saved to connected cloud storage (Google Drive, OneDrive — configure in `.env`).

---

## Scripts

### `./start.sh`

On **first run**: copies `.env.example` → `.env` and starts the container. No secrets are generated — draw.io requires no credentials.

Subsequent runs pull the latest image and start the container.

```bash
./start.sh
```

### `./stop.sh`

Stops the container. No data is lost (draw.io has no persistent volumes).

```bash
./stop.sh
```

### `./teardown.sh`

Interactive teardown: lists what will be removed, prompts for confirmation, then deletes the container, image, and network.

```bash
./teardown.sh
```

---

## Files

| File | Purpose |
|---|---|
| `.env` | Runtime config — URLs, version pin, optional cloud storage keys |
| `docker-compose.yml` | Single-container stack definition |
| `start.sh` | Start / first-run setup |
| `stop.sh` | Stop container |
| `teardown.sh` | Full wipe with confirmation |

### `.env` — values of interest

| Variable | Default | Notes |
|---|---|---|
| `DRAWIO_VERSION` | `latest` | Pin to a tag for reproducibility |
| `DRAWIO_BASE_URL` | `http://localhost:8085` | Must match the browser-facing URL |
| `DRAWIO_SERVER_URL` | `http://localhost:8085/` | Same as `DRAWIO_BASE_URL` with trailing slash |
| `DRAWIO_PORT_HOST` | `8085` | Host port; update both URL vars if changed |

---

## Architecture

```
Browser
  └─► localhost:8085
        └─► draw  (draw.io — Tomcat 9 + JRE 11; stateless)
```

**Containers:**

| Container | Image | Role |
|---|---|---|
| `draw` | `jgraph/drawio` | Diagram editor |

draw.io stores no server-side data. All diagram state lives in the browser, downloaded files, or optional cloud storage providers.

---

## Cheat Sheet

### Logs

```bash
docker compose -p draw logs -f
docker logs draw -f
```

### Upgrade draw.io

1. Update `DRAWIO_VERSION` in `.env` to the new tag
2. `./stop.sh`
3. `./start.sh` — pulls the new image

### Save diagrams

draw.io offers several local storage options from **File → Save As**:

- **Device** — downloads a `.drawio` file to your machine
- **Browser** — saves to browser local storage (lost if you clear storage)
- **GitHub / GitLab** — connect a repo in Extras → Edit Diagram

---

## Debugging

### Container not starting

```bash
docker logs draw --tail 50 -f
```

Tomcat initialisation takes 20–30 s on first start. Wait for `Server startup in` in the logs before opening the URL.

### Page loads but diagrams act unexpected

Check that `DRAWIO_BASE_URL` in `.env` matches exactly what you type in the browser (including port). Mismatch causes embed and export features to malfunction.

```bash
grep DRAWIO_BASE_URL .env
```

Restart after any `.env` change: `./stop.sh && ./start.sh`
