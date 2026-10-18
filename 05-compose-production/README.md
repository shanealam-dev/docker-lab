# 🏗️ Lab 05: Production-Grade Docker Compose

> **Goal**: Orchestrate a complete full-stack microservice system with healthchecks, dependency gates, environment variables, network tiers, and resource limits.  
> **Full Stack**: **React + Node/Express + Python + PostgreSQL + Redis**

---

## 🧠 1. The Visual Mental Model

### The Startup Race Condition Trap
In simple Compose files, developers use `depends_on: [db]`.  
**The Catch**: `depends_on` only waits for the database container to **start**, NOT for the database engine to finish initializing!  
Result: Node API boots up in 500ms, tries to connect to port 5432, gets `ECONNREFUSED` because Postgres is still replaying WAL logs, and crashes!

```
❌ OLD WAY (Race Condition):
   db: starts -> (initializing...) -> ready (5s later)
   api: starts -> connects immediately -> 💥 CRASH!

✅ PRODUCTION WAY (Healthcheck Gate):
   db: starts -> healthcheck polling -> 🟢 HEALTHY
   api: waits until condition: service_healthy -> connects cleanly! 🚀
```

---

## 🗺️ System Topology

```
                  [ Browser / Port 3000 ]
                             │
                             ▼
                    ┌─────────────────┐
                    │  React Frontend │ (frontend-net)
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Node / Express │ (frontend-net + backend-net)
                    └────────┬────────┘
                             │
         ┌───────────────────┴───────────────────┐
         │ (backend-net)                         │ (backend-net)
         ▼                                       ▼
  ┌──────────────┐                       ┌──────────────┐
  │  PostgreSQL  │                       │  Redis Cache │
  │   (Healthy)  │                       │   (Healthy)  │
  └──────────────┘                       └──────────────┘
```

---

## 🛠️ 2. Production Compose Spec (`compose.yaml`)

Look at `compose.yaml` in this directory:
- **`build` vs `image`**:
  * `build.context`: Path containing the source files and Dockerfile.
  * `image: hero-node:1.0`: Assigns an explicit tag name to the built image instead of an auto-generated random default.
  * *Workflow*: Compose checks if the image exists or builds it from source (`docker compose build` or `docker compose up --build`).
- **`healthcheck` Mechanics**:
  * `test: ["CMD-SHELL", "..."]`: Uses a subshell (`/bin/sh -c`) to allow environment variable expansion (e.g., `${POSTGRES_USER}`). Direct `["CMD", ...]` does not expand `$VARS`.
  * `interval: 3s`: How frequently Docker checks the container health.
  * `timeout: 2s`: Max time allowed for a single healthcheck command to complete.
  * `retries: 5`: Consecutive failures required before declaring container `unhealthy`.
  * `start_period: 3s`: Grace period during container boot where failed checks don't count towards the retry limit.
- **`depends_on.condition: service_healthy`**: The Node API will **block** until Postgres and Redis health checks return status `healthy`.
- **`secrets & .env`**: Interpolates credentials safely without committing raw secrets into Git.
- **`restart: unless-stopped`**: Production resilience (restarts on failure or daemon reboot).
- **`deploy.resources.limits`**: Hard cgroup limits (`cpus: "0.50"`, `memory: 256M`) preventing runaway memory leaks from crashing your Mac.

---

## 🛠️ 3. Hands-on Missions

### 🎯 Mission 1: Bootstrapping the Full Stack
Navigate to this lab directory:
```bash
cd 05-compose-production
```

1. **Review the environment file**:
   ```bash
   cat .env
   ```
2. **Start the entire 5-service stack in detached mode**:
   ```bash
   docker compose up -d --build
   ```
3. **Watch the health checks initialize in real-time**:
   ```bash
   docker compose ps
   ```
   *Notice `STATUS: Up (health: starting)` transition to `Up (healthy)`.*

4. **Test the services**:
   - React Frontend: `curl -I http://localhost:3000`
   - Node API: `curl http://localhost:4000/api/health`
   - Python Worker: `curl http://localhost:5500/health`

5. **Stream logs for a single service**:
   ```bash
   docker compose logs -f --tail 20 api
   ```

6. **View real-time resource utilization across all containers**:
   ```bash
   docker stats --no-stream
   ```

---

### 💥 4. The Break & Fix Drill: Scaling Services Live
Need to handle more traffic on the worker service?
```bash
# Scale the python worker to 3 replicas dynamically:
docker compose up -d --scale python-worker=3
docker compose ps
```
Observe 3 separate worker containers running in parallel!

---

## ⚡ 5. Revision Flashcard

| Command | Action |
|---|---|
| `docker compose up -d` | Build and start all services in background |
| `docker compose up -d --build` | Force rebuild of images before starting |
| `docker compose ps` | Show state, ports, and healthcheck status |
| `docker compose logs -f <service>` | Follow logs of a specific service |
| `docker compose exec <service> sh` | Jump into a running service container |
| `docker compose down` | Stop and remove containers and networks |
| `docker compose down -v` | Stop and **wipe named volumes** too (clean state) |

---

## 🚨 6. Production War Stories & Troubleshooting

### Case Study A: `Bind for 0.0.0.0:5432 failed: port is already allocated`
#### Why it happens:
Docker tried to bind port `5432` on your Mac, but another process already owns it:
- A local macOS Postgres installation running via Homebrew (`brew services list`).
- An old dangling Docker container from a previous lab.

#### Diagnosis:
```bash
# Check if a native Mac service holds the port:
lsof -nP -iTCP:5432 -sTCP:LISTEN

# Check if another Docker container is publishing 5432:
docker ps -a --filter publish=5432
```

#### Production Architecture Fix:
In a microservices architecture, **PostgreSQL and Redis should NOT expose host ports to your Mac**.
The Node API and Python worker communicate with Postgres over the internal bridge network (`backend-net`) using DNS: `postgres:5432`.
* Solution: Remove `ports: - "5432:5432"` from `postgres` in `compose.yaml`.
* If you need local database GUI access (e.g. TablePlus/DBeaver), map to an alternate port: `"5433:5432"`.

---

### Case Study B: `curl: (56) Recv failure: Connection reset by peer`
#### What it means:
A TCP `RST` (Reset) packet was sent back to your client. The connection was accepted or established, but the server abruptly destroyed the socket before sending HTTP headers.

#### The 5 Primary Causes in Docker:
1. **Port Mismatch**: Docker forwards `host:container` (e.g., `"5500:5500"`). If the app inside is configured to listen on a different port (e.g., `3003` or `5000`), Docker forwards traffic into a void, triggering a reset.
2. **OOM Killer (Resource Limits)**: Your compose file limits memory (`memory: 256M`). If Node.js or Python hits the ceiling while handling a request, the Linux kernel terminates the process instantly with `SIGKILL` (`exit code 137`).
3. **Loopback Interface Binding**: If an app calls `listen(4000, '127.0.0.1')`, it only accepts requests from inside its own container. It **must** bind to `0.0.0.0` to receive forwarded host traffic.
4. **Missing Environment Variables**: Missing `.env` values (e.g., `${PORT}` or `${POSTGRES_PASSWORD}`) causing the server process to crash on boot or immediately on first request.
5. **HTTPS vs HTTP**: Sending `curl https://localhost:4000` to a plaintext HTTP Express server will cause the HTTP parser to immediately reset the socket.

#### The 4-Step Diagnostic Protocol:
```bash
# Step 1: Check container status and restart counts
docker compose ps

# Step 2: Check exit code and if the container was OOM killed
docker inspect prod-api --format 'Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOM: {{.State.OOMKilled}}'

# Step 3: Check app logs right before the crash
docker compose logs --tail=50 api

# Step 4: Run verbose curl to inspect the handshake
curl -v http://localhost:4000/api/health
```

---

## 🧹 Clean up Lab 05
```bash
docker compose down -v
```
