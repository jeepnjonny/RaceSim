# RaceSim

A browser-based simulator that generates realistic GPS position beacons for race events and publishes them as Meshtastic-formatted MQTT packets. Load a KML or GPX track, configure participants, and watch them move across a live map while the simulator transmits position data your mesh network can consume.

![idle](https://img.shields.io/badge/status-active-brightgreen)

## Features

- **Track loading** — import any KML or GPX route file
- **Race types** — Runner, Hiker, Bicyclist, Dirt Bike, Jet Boat (each with realistic speed ranges)
- **Up to 200 participants** with randomized pacing, DNF events, and beacon drop simulation
- **Live map** — dark-themed Leaflet map with per-participant markers and finish/DNF states
- **MQTT output** — publishes Meshtastic-format JSON and encrypted protobuf packets; supports live broker connection (Paho over WebSocket) or simulate-only mode
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
git clone https://github.com/jeepnjonny/meshtastic-race-simulator.git RaceSim
cd RaceSim
sudo bash setup.sh
```

The script will:

1. Install `git` and `nginx` if not already present
2. Clone the repo to `/srv/RaceSim/`
3. Remove any legacy `conf.d/racesim.conf` from older installs
4. Write `/etc/nginx/sites-available/racesim` and symlink it to `sites-enabled`
5. Test and reload nginx

The app will be available at `http://<your-host>/RaceSim/`.

### Custom domain / server name

```bash
SERVER_NAME=mysite.example.com sudo bash setup.sh
```

### Sharing a server block with other apps

If you already have an nginx `server {}` block for your hostname, copy only the `location /RaceSim/` block that `setup.sh` generates into that file instead of using the standalone config.

---

## Update

Pull the latest changes and apply them:

```bash
sudo bash /srv/RaceSim/update.sh
```

`update.sh` pulls the latest commit, resets file ownership (`root:www-data`), and corrects permissions. No nginx reload is needed — nginx serves the files directly from the repo directory.

---

## File overview

| File | Purpose |
|---|---|
| `index.html` | The application — single self-contained HTML file |
| `setup.sh` | One-time server setup: clone, nginx config, permissions |
| `update.sh` | Apply updates after `git pull` |

---

## MQTT

Open **MQTT Config** in the top bar to configure the broker. Two modes:

| Mode | Behaviour |
|---|---|
| **Simulate only** (default) | Packets are logged in the MQTT tab but not transmitted |
| **Live** | Connects to a broker via WebSocket (Paho MQTT) and publishes Meshtastic JSON and encrypted protobuf packets |

Default channel: `RaceTracker` on `msh/US` — change to match your Meshtastic channel configuration.
