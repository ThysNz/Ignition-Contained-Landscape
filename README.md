# Ignition Contained Landscape

A self-contained Docker setup for local Ignition development: two Ignition gateways,
a browser-based tools desktop, SQL Server and MongoDB, all on one shared network.

| Folder | What it runs | Container | Host ports |
|---|---|---|---|
| `Frontend/` | Ignition 8.1.55 gateway | `ignition-frontend` | 8088, 8043, 8060 |
| `Backend/` | Ignition 8.3.10 gateway | `ignition-backend` | 9088, 9043, 9060 |
| `Tools/` | Linux desktop in the browser (draw.io, Designer Launcher) | `ignition-tools` | 3000, 3001 |
| `SQL/` | SQL Server 2022 Developer | `mssql` | 1433 |
| `MongoDB/` | MongoDB 7 | `mongo` | 27017 |

All containers join the external Docker network `ignition-net` and reach each other
by container name (for example `mssql:1433`, `http://ignition-backend:8088`).

## Quick start

Requires Docker Desktop (Compose v2).

1. Create the shared network (once):
   ```bash
   docker network create ignition-net
   ```
2. In each folder, copy `.env.example` to `.env` and set real values. The `.env` files are git-ignored.
3. Start the stacks, SQL Server and MongoDB first:
   ```bash
   cd SQL && docker compose up -d
   cd ../MongoDB && docker compose up -d
   cd ../Backend && docker compose up -d
   cd ../Frontend && docker compose up -d
   cd ../Tools && docker compose up -d --build
   ```
4. Open the web UIs:
   - Frontend gateway: http://localhost:8088
   - Backend gateway: http://localhost:9088
   - Tools desktop: https://localhost:3001 (accept the self-signed certificate warning)

## Not in this repo

These are excluded on purpose, so you need to supply them:

- **`.env` files:** copy from `.env.example` and fill in your own passwords.
- **`Tools/launcher/designerlauncher.tar.gz`:** the Linux Designer Launcher, downloaded from the 8.3.10 gateway. The Tools image build needs it.
- **Gateway backups (`.gwbk`) and database backups:** they contain secrets and data. Put them in each `backups/` folder when restoring.
- **Ignition installers** (`_unused/`): not needed for the Docker setup.

## Documentation

- [`Deployment-Guide.md`](Deployment-Guide.md): full deployment steps, database setup, addressing between containers, backups and troubleshooting.
- `Frontend/Ignition-Docker-Guide.md`, `Backend/Ignition-Docker-Guide.md`, `Tools/Tools-Guide.md`: per-component notes.

## Notes

- SQL Server Developer Edition is licensed for development and testing only.
- The settings here (published database ports, `trustServerCertificate=true`, `db_owner` login) are for local development, not production.
