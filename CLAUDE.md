# makerops-core

Self-hosted business stack for small maker/manufacturing businesses. Every
service is an isolated Docker Compose project in its own directory; nothing
is orchestrated globally. Public repo — never commit secrets or `.env`.

## Layout

- `shared/` n8n, Outline, Plane, trigger.dev, draw.io · `accounting/`
  Invoice Ninja · `sales/` FreeScout · `operations/` InvenTree
- `infrastructure/` — garage (S3), lan-dns, **name-proxy** (nginx mapping
  `*.localhost` subdomains → host ports; landing page at `root.localhost`)
- `remote_access/` — WireGuard (wg-easy), Cloudflare DDNS
- `ai/` — foundational GPU services only: **Ollama** (11434) and **ComfyUI**
  (8188). Requires NVIDIA Container Toolkit (see `ai/README.md`).
- `docs/env-conventions.md` — env-file conventions; each service README is
  its own source of truth (ports, setup, cheat sheet).

## Service conventions (follow these when adding/changing services)

- Each service dir: `docker-compose.yml`, `.env.example` (tracked) →
  `.env` (gitignored, created by `start.sh`), `start.sh` / `stop.sh` /
  `teardown.sh`, `README.md` with an Attribution section.
- Compose project name = directory name (`-p <dir>`); run scripts from the
  service's real directory.
- **`.env` footgun**: values are read via `env_file` — an inline comment
  after `=` becomes part of the value. Comments go on their own line.
- **`docker compose restart` does NOT re-read `.env`** — apply env changes
  with `docker compose -p <name> up -d` (recreate).
- Runtime state lives in gitignored `**/data/`, `**/config/`, `**/db_data/`.
- WSL2 quirks: containers needing outbound DNS set explicit
  `dns: [8.8.8.8, 1.1.1.1]`; image builds use `network: host`; services are
  reached cross-container via `host.docker.internal` (`extra_hosts:
  host.docker.internal:host-gateway`).

## name-proxy local drop-ins

The proxy renders every `nginx/templates/*.template` at container start, and
the landing page fetches an optional `html/local-services.json` (grouped
`{ "Category": [entries] }`, icons under `html/local-icons/`). Files matching
`local-*` there are gitignored — machine-local service entries can be added
without touching tracked config. Recreate the proxy container after route
(template) changes; the html mount is live.

## Git

Default branch `main`, remote `origin` (GitHub, public). Commit only what is
already conventional here; check a service's README before renaming its env
vars or ports (name-proxy defaults must stay in sync).
