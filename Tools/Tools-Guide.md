# Ignition Tools Desktop — Step-by-Step Guide

A full Linux desktop (XFCE) that runs in a Docker container and opens in your **browser**.
Contains **draw.io** (pre-installed) and the **Ignition Designer** (via the Designer Launcher).

Folder: `D:\ignition\Tools`
Open: <https://localhost:3001>

## What's in this folder

| File / folder | Purpose |
|---|---|
| `Dockerfile` | Recipe for the image: linuxserver *webtop* (Ubuntu + XFCE) + latest draw.io desktop |
| `docker-compose.yml` | Container settings: ports, login, storage, access to the gateways |
| `.env` | Login for the browser desktop |
| `shared\` | Shared folder — appears inside the desktop as `/config/shared` |
| `start-tools.ps1` | Optional helper: builds + starts, logs to `start.log` |

---

## 1. Set the desktop login

Edit `.env` and change `TOOLS_PASSWORD` (and `TOOLS_USER` if you like).
*Purpose:* the desktop is protected by this username/password in the browser.

## 2. Build and start

```powershell
cd D:\ignition\Tools
docker compose up -d --build
```
*Purpose:* `--build` creates the image from the `Dockerfile` (downloads the desktop image and installs draw.io — first time takes several minutes), then starts the container in the background (`-d`).

Or run the helper: `powershell -ExecutionPolicy Bypass -File .\start-tools.ps1`

## 3. Open the desktop

Browse to <https://localhost:3001>, accept the certificate warning (self-signed), log in with `.env` credentials.
*Why HTTPS:* clipboard and some features only work over HTTPS. Port 3000 (HTTP) also works for basic use.

---

## 4. draw.io

Applications menu → **Graphics → draw.io**.
Save diagrams to `/config/shared` so they also appear in `D:\ignition\Tools\shared` on Windows.

## 5. Ignition Designer

The Designer Launcher is **pre-installed** (`/opt/designerlauncher`, from `launcher\designerlauncher.tar.gz`, taken from the 8.3.10 gateway).
Start it from Applications menu → **Development → Ignition Designer Launcher**, then **Add Designer** with a gateway URL (`http://host.docker.internal:9088` or `:8088`) and **Open Designer**.

<details><summary>Manual install (only if you ever need to re-download it)</summary>

Inside the desktop:

1. Open the web browser (Applications menu → Internet).
2. Go to a gateway:
   - 8.3.10 Backend: `http://host.docker.internal:9088`
   - 8.1.55 Frontend: `http://host.docker.internal:8088`
3. On the gateway home page click **Download Designer Launcher** → choose **Linux**.
4. Open a terminal (Applications menu → System → Terminal) and run:

   ```bash
   cd ~/Downloads
   tar -xzf designerlauncher*.tar.gz -C ~/
   ~/designerlauncher/app/designerlauncher.sh
   ```
   *Purpose:* unpacks the launcher into your desktop home (kept in the `tools-home` volume, so this is one-time) and starts it.
   (If the folder name differs, run `ls ~` to see it.)
5. In the launcher, **Add Designer** → enter the gateway URL from step 2 manually → **Open Designer** and log in with that gateway's admin account.

Add both gateways to the launcher so you can switch between 8.1 and 8.3 projects.
</details>

> `host.docker.internal` is your Windows PC as seen from inside a container, so `host.docker.internal:8088` reaches the gateway exposed on your PC's port 8088.

---

## 6. Day-to-day commands (run in `D:\ignition\Tools`)

| Command | Purpose |
|---|---|
| `docker compose stop` / `start` | Stop / start the desktop. Everything is kept. |
| `docker compose logs --tail 50 tools` | Recent container log. |
| `docker compose up -d --build` | Rebuild after editing the `Dockerfile` (e.g. to pick up a newer draw.io). Home folder is kept. |
| `docker compose down` | Remove the container; the `tools-home` volume (launcher, settings) is kept. |
| `docker compose down -v` | Remove container **and** home volume (Designer Launcher, settings). Files in `shared\` are safe. |

## 7. Adding more tools later

Add lines to the `RUN` step in the `Dockerfile` (e.g. `apt-get install -y code` style packages), then `docker compose up -d --build`.

## 8. All your containers

| Container | Purpose | URL |
|---|---|---|
| `ignition-frontend` | Ignition 8.1.55 gateway | <http://localhost:8088> |
| `ignition-backend` | Ignition 8.3.10 gateway | <http://localhost:9088> |
| `ignition-tools` | Browser desktop: Designer + draw.io | <https://localhost:3001> |

## 9. Troubleshooting

| Symptom | Fix |
|---|---|
| Build fails at draw.io step | Network/GitHub hiccup — rerun `docker compose up -d --build`. |
| Black/blank screen | Refresh the browser tab; check `docker compose logs tools`. |
| draw.io doesn't open | Run `drawio --no-sandbox` in the desktop terminal to see the error. |
| Launcher can't reach gateway | Check the gateway container is running and use `host.docker.internal:<port>`, not `localhost`. |
| Port 3000/3001 in use | Change the left-hand numbers in `docker-compose.yml`, e.g. `"3443:3001"`. |
