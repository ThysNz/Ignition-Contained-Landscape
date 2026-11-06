# Ignition 8.1.55 in Docker (Linux container) — Step-by-Step Guide

Folder: `D:\ignition\Frontend`
Gateway URL: <http://localhost:8088>

## What's in this folder

| File / folder | Purpose |
|---|---|
| `docker-compose.yml` | Defines the Ignition container: image version, ports, settings, storage |
| `.env` | Admin username and password (only applied on the very first start) |
| `backups\` | Shared with the container as `/backups` — put `.gwbk` backups here |
| `start-linux.ps1` | Optional helper: starts the gateway and writes output to `start.log` |
| `_unused\` | Old Windows installer/files — safe to delete |

---

## 1. Prerequisites (one-time)

1. **Docker Desktop installed and running** (whale icon in the system tray).
2. **Linux containers mode** — this is Docker's default. Check it:

   ```powershell
   docker version --format '{{.Server.Os}}'
   ```
   *Purpose:* shows which container engine Docker is using. It must print `linux`.
   If it prints `windows`, right-click the Docker tray icon → **Switch to Linux containers…**

3. **Set the admin password** — open `.env` in Notepad and change `GATEWAY_ADMIN_PASSWORD`.
   *Purpose:* this becomes the gateway login. It is only read the first time the gateway is created.

---

## 2. Open PowerShell in the folder

```powershell
cd D:\ignition\Frontend
```
*Purpose:* all `docker compose` commands read `docker-compose.yml` from the current folder, so you must run them here.

---

## 3. Start the gateway

```powershell
docker compose up -d
```
*Purpose:* downloads the `inductiveautomation/ignition:8.1.55` image (first time only), creates the container and starts it.
`-d` (detached) runs it in the background so you get your prompt back.

**Alternative:** `powershell -ExecutionPolicy Bypass -File .\start-linux.ps1` does the same, waits 60 s and saves everything to `start.log`.

---

## 4. Check it's running

```powershell
docker compose ps
```
*Purpose:* lists the container and its state. Look for `Up ... (healthy)`.

```powershell
docker compose logs -f ignition
```
*Purpose:* streams the gateway log live. Wait for `Gateway started in XX seconds`. Press `Ctrl+C` to stop watching (the gateway keeps running).

---

## 5. Open the gateway

Browse to <http://localhost:8088> and log in with the username/password from `.env`.
From there you can launch the **Designer**, open **Perspective** sessions, configure devices, etc.

| Port | Used for |
|---|---|
| 8088 | HTTP — web interface, Designer, Perspective |
| 8043 | HTTPS |
| 8060 | Gateway Network (gateway-to-gateway) |

---

## 6. Day-to-day commands

| Command | Purpose |
|---|---|
| `docker compose stop` | Stops the gateway. Settings and projects are kept. |
| `docker compose start` | Starts it again after a stop. |
| `docker compose restart` | Restarts the gateway (e.g. after a module install). |
| `docker compose logs --tail 100 ignition` | Shows the last 100 log lines. |
| `docker stats ignition-frontend` | Live CPU / memory usage. `Ctrl+C` to exit. |
| `docker exec -it ignition-frontend bash` | Opens a shell inside the container for troubleshooting. Type `exit` to leave. |

You can also start/stop the container from the **Containers** tab in Docker Desktop.

---

## 7. Backups and restores

**Take a backup:** Gateway web page → **Config → Backup/Restore → Download Backup**, then save the `.gwbk` into `D:\ignition\Frontend\backups`.

**Restore:** same page → **Restore**, and choose the `.gwbk` file.

*Why:* the gateway's own data lives in a Docker volume (`ignition-data`), not as visible files in this folder. A `.gwbk` is your portable copy.

---

## 8. Removing / resetting

| Command | Purpose |
|---|---|
| `docker compose down` | Removes the container. **Data is kept** in the volume; `docker compose up -d` brings it back as it was. |
| `docker compose down -v` | Removes the container **and deletes all gateway data** (projects, tags, settings). Factory reset — back up first! |
| `docker image rm inductiveautomation/ignition:8.1.55` | Deletes the downloaded image (~1–2 GB) after a `down`. |

---

## 9. Changing settings

Edit `docker-compose.yml`, then run:

```powershell
docker compose up -d
```
*Purpose:* Docker sees the change and recreates the container with the new settings. Data in the volume is kept.

Common changes:

- **Only allow access from this PC:** change `"8088:8088"` to `"127.0.0.1:8088:8088"` (same for 8043/8060).
- **More memory:** change `-m 2048` to e.g. `-m 4096` (MB).
- **Different port on your PC:** `"9088:8088"` → gateway at <http://localhost:9088>.
- **Upgrade Ignition:** change the image tag (e.g. `8.1.56`) — **take a backup first**.

---

## 10. Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| `port is already allocated` | Something else uses 8088. Stop it, or change the left-hand port in `docker-compose.yml`. |
| `docker: command not found` / cannot connect | Docker Desktop isn't running — start it and wait for "Engine running". |
| `no matching manifest for windows` | Docker is in Windows containers mode — switch to Linux containers (step 1). |
| Login fails with `.env` password | `.env` is only applied on first creation. Use the original password, or reset with `docker compose down -v` (loses data). |
| Red `NativeCommandError` in `start.log` | Harmless — PowerShell labels Docker's progress output as an error. |
| Trial expired banner | Normal for unlicensed gateways: the 2-hour trial can be reset from the gateway web page. |
