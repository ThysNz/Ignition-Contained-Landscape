# Ignition Stack - Deployment Guide

How to stand up the full stack on a fresh machine: two Ignition gateways, the
browser-based Tools desktop, SQL Server and MongoDB, all on one shared Docker network.

## Layout

```
D:\ignition\
  Frontend\   Ignition 8.1.55 gateway   (container: ignition-frontend)
  Backend\    Ignition 8.3.10 gateway   (container: ignition-backend)
  Tools\      Browser Linux desktop     (container: ignition-tools) - draw.io + Designer Launcher
  SQL\        SQL Server 2022 Developer (container: mssql)
  MongoDB\    MongoDB 7                 (container: mongo)
```

Each folder is its own compose project with its own `docker-compose.yml` and `.env`.
All five containers join one external network, **`ignition-net`**, so they reach each
other by container name.

## Ports

| Service | Container port | Host port | Use |
|---|---|---|---|
| ignition-frontend | 8088 / 8043 / 8060 | 8088 / 8043 / 8060 | HTTP / HTTPS / Gateway Network |
| ignition-backend | 8088 / 8043 / 8060 | 9088 / 9043 / 9060 | HTTP / HTTPS / Gateway Network |
| ignition-tools | 3000 / 3001 | 3000 / 3001 | Desktop (use https://localhost:3001) |
| mssql | 1433 | 1433 | SQL Server |
| mongo | 27017 | 27017 | MongoDB |

## Prerequisites

- Docker Desktop (Compose v2) running.
- Internet access for the first image pulls and the Tools build.
- `Tools\launcher\designerlauncher.tar.gz` present (Linux Designer Launcher, taken from the 8.3.10 gateway). The Tools image build copies it in.

## Environment files

Create each `.env` **before first start**. Gateway credentials only apply when the gateway is first commissioned.

| File | Variables |
|---|---|
| `Frontend\.env`, `Backend\.env` | `GATEWAY_ADMIN_USERNAME`, `GATEWAY_ADMIN_PASSWORD` |
| `Tools\.env` | `TOOLS_USER`, `TOOLS_PASSWORD` (login for https://localhost:3001) |
| `SQL\.env` | `MSSQL_SA_PASSWORD` (must meet SQL Server complexity rules), `IGNITION_DB_PASSWORD` |
| `MongoDB\.env` | `MONGO_ROOT_USER`, `MONGO_ROOT_PASSWORD` |

Keep `.env` files out of version control and do not reuse these passwords elsewhere.

## Deployment steps

1. **Create the shared network (once):**
   ```bash
   docker network create ignition-net
   ```

2. **Start SQL Server:**
   ```bash
   cd D:/ignition/SQL && docker compose up -d
   ```
   Wait for "SQL Server is now ready for client connections" in `docker logs mssql`.

3. **Create the Ignition database and login:**
   ```bash
   export MSYS_NO_PATHCONV=1   # Git Bash only: stops it rewriting /opt/... paths
   docker exec mssql /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "<SA password>" \
     -Q "CREATE DATABASE ignition; CREATE LOGIN ignition_app WITH PASSWORD='<IGNITION_DB_PASSWORD>', CHECK_POLICY=OFF;"
   docker exec mssql /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "<SA password>" -d ignition \
     -Q "CREATE USER ignition_app FOR LOGIN ignition_app; ALTER ROLE db_owner ADD MEMBER ignition_app;"
   ```

4. **Start the gateways:**
   ```bash
   cd D:/ignition/Backend  && docker compose up -d
   cd D:/ignition/Frontend && docker compose up -d
   ```
   Allow a couple of minutes for first commissioning.
   Web UIs: Backend http://localhost:9088, Frontend http://localhost:8088.

5. **Build and start Tools:**
   ```bash
   cd D:/ignition/Tools && docker compose up -d --build
   ```
   Open https://localhost:3001 and accept the self-signed certificate warning.

6. **Restore gateway backups (optional):** put `.gwbk` files in each gateway's `backups\` folder
   (mounted at `/backups`), then restore from the gateway web UI. Copies of recent backups are also in `Tools\shared\`.

7. **Add the database connection in each gateway:**
   Config -> Databases -> Connections -> Create new -> Microsoft SQL Server.
   - Connect URL: `jdbc:sqlserver://mssql:1433;databaseName=ignition;encrypt=true;trustServerCertificate=true`
   - Username: `ignition_app`
   - Password: `IGNITION_DB_PASSWORD` from `SQL\.env`
   - Status should read **Valid**.

## Addressing between containers

Use container names and the **container** ports (not the published host ports).

| Target | From another container |
|---|---|
| Frontend gateway | `http://ignition-frontend:8088`, `https://ignition-frontend:8043` |
| Backend gateway | `http://ignition-backend:8088`, `https://ignition-backend:8043` |
| SQL Server | `mssql:1433` |
| MongoDB | `mongodb://<user>:<password>@mongo:27017/?authSource=admin` |

Fallback: `host.docker.internal` with the published host ports (e.g. `http://host.docker.internal:9088` for the backend). Tools has this mapped via `extra_hosts`.

## Day-to-day

```bash
docker compose stop      # stop, keep everything
docker compose start     # start again, no recreate
docker compose up -d     # apply compose/.env changes (recreates the container)
docker compose down      # remove containers, KEEP volumes
docker compose down -v   # remove containers AND volumes (deletes data, irreversible)
```

Run these from the relevant folder. `docker start <name>` only restarts an existing container and ignores compose/.env edits.

## Data and persistence

| Data | Where |
|---|---|
| Frontend gateway state | volume `ignition-frontend_ignition-data` |
| Backend gateway state | volume `ignition-backend_ignition-backend-data` |
| SQL Server databases | volume `sql_mssql_data` |
| MongoDB data | volume `ignition-mongo_mongo_data` (backups in `MongoDB\backups`) |
| Tools desktop home | volume `ignition-tools_tools-home` |
| Gateway backups | `Frontend\backups`, `Backend\backups` (bind mounts) |
| Tools shared files | `Tools\shared` (bind mount, also `/config/shared` in the desktop) |

Confirm exact volume names with `docker volume ls`.

## Backup and migration

- **MongoDB:** start with `cd D:/ignition/MongoDB && docker compose up -d` (after the network exists). Back up and restore with:
  ```bash
  docker exec mongo mongodump -u admin -p "<password>" --authenticationDatabase admin --archive=/backups/mongo.archive
  docker exec mongo mongorestore -u admin -p "<password>" --authenticationDatabase admin --archive=/backups/mongo.archive
  ```

- **Gateways:** take a `.gwbk` from the gateway web UI (Config -> Backup/Restore) and keep it in `backups\`.
- **SQL Server:** back up with
  ```bash
  docker exec mssql /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "<SA password>" \
    -Q "BACKUP DATABASE ignition TO DISK='/var/opt/mssql/data/ignition.bak'"
  docker cp mssql:/var/opt/mssql/data/ignition.bak .
  ```
- To move to a new machine: copy the `D:\ignition` folder, recreate the network (step 1), restore the `.bak` into SQL Server and the `.gwbk` files into the gateways, then follow steps 2-7.

## Troubleshooting

- **Containers cannot reach each other:** `docker network inspect ignition-net` should list all four. If one is missing, check its compose file has the `ignition-net` network (external) and run `docker compose up -d`.
- **`network ignition-net not found`:** run step 1.
- **Changed gateway or SA password has no effect:** these apply only on first initialisation. Change them inside the product, or recreate the volume (data loss).
- **Git Bash errors about `C:/Program Files/Git/opt/...`:** set `MSYS_NO_PATHCONV=1`.
- **Designer cannot connect using container names:** use the `host.docker.internal` address instead.
- **Connection keeps "reconnecting" with `Failed to open the explicitly specified database 'test'` in `docker logs mssql`:** the gateway's **Extra Connection Properties** field contains its own `databaseName=` value that overrides the Connect URL. Clear it or set it to `databaseName=ignition`, then save. Use `docker logs mssql --since 1m | grep "Login failed"` to see which database and which client IP (`docker network inspect ignition-net` maps IPs to containers).
- **Database connection shows a fault:** check `docker logs mssql`, confirm the login with `sqlcmd -U ignition_app`, and confirm the URL host is `mssql`.

## Security notes

- Developer Edition of SQL Server is licensed for development and test only; use Express or a licensed edition in production.
- `trustServerCertificate=true` skips certificate validation. Fine for local dev, not for production.
- `ignition_app` is `db_owner` on the `ignition` database only. Prefer least privilege for production.
- Port 1433 is published to the host. Remove the `ports:` entry in `SQL\docker-compose.yml` if only containers need access.
