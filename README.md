# MeshRace Simulator

A browser-based simulator that generates realistic GPS position beacons for race events and publishes them as Meshtastic-formatted MQTT packets. Load a KML or GPX track, configure participants, and watch them move across a live map while the simulator transmits position data your mesh network can consume.

![idle](https://img.shields.io/badge/status-active-brightgreen)

## Features

- **Track loading** — import any KML or GPX route file
- **Race types** — Runner, Hiker, Bicyclist, Dirt Bike (each with realistic speed ranges)
- **Up to 200 participants** with randomized pacing, DNF events, and beacon drop simulation
- **Live map** — dark-themed Leaflet map with per-participant markers and finish/DNF states
- **MQTT output** — publishes Meshtastic-format JSON position packets; supports live broker connection (Paho over WebSocket) or simulate-only mode
- **Event log + MQTT packet viewer** with expandable JSON payloads
- **Sim speed multiplier** up to 200× for rapid testing

---

## Requirements

- Linux server with **nginx** and **git** (installer will apt-get both if missing)
- `sudo` / root access for initial setup
- Debian/Ubuntu nginx layout (`sites-available` / `sites-enabled`)

---

## Install

```bash
git clone https://github.com/jeepnjonny/meshtastic-race-simulator.git
cd meshtastic-race-simulator
sudo bash setup.sh
```

The script will:

1. Install `git` and `nginx` if not already present
2. Clone the repo to `/srv/meshtastic-race-simulator/`
3. Remove any legacy `conf.d/meshrace.conf` from older installs
4. Write `/etc/nginx/sites-available/meshrace` and symlink it to `sites-enabled`
5. Test and reload nginx

The app will be available at `http://<your-host>/MeshraceSim/`.

### Custom domain / server name

```bash
SERVER_NAME=mysite.example.com sudo bash setup.sh
```

### Sharing a server block with other apps

If you already have an nginx `server {}` block for your hostname, copy only the `location` block from [`nginx-meshrace.conf`](nginx-meshrace.conf) into that file instead of using the standalone config that `setup.sh` generates.

---

## Update

Pull the latest changes and apply them:

```bash
sudo git -C /srv/meshtastic-race-simulator pull
sudo bash /srv/meshtastic-race-simulator/update.sh
```

`update.sh` pulls the latest commit, resets file ownership (`root:www-data`), and corrects permissions. No nginx reload is needed — nginx serves the files directly from the repo directory.

---

## File overview

| File | Purpose |
|---|---|
| `index.html` | The application — single self-contained HTML file |
| `setup.sh` | One-time server setup: clone, nginx config, permissions |
| `update.sh` | Apply updates after `git pull` |
| `nginx-meshrace.conf` | Reference nginx config (written automatically by `setup.sh`) |

---

## MQTT

Open **MQTT Config** in the top bar to configure the broker. Two modes:

| Mode | Behaviour |
|---|---|
| **Simulate only** (default) | Packets are logged in the MQTT tab but not transmitted |
| **Live** | Connects to a broker via WebSocket (Paho MQTT) and publishes to `<topic>/<nodeId>/LongFast` |

Default topic prefix: `msh/US/2/json` — change to match your Meshtastic channel configuration.
