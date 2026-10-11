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
- **`healthcheck`**: Uses `pg_isready` for Postgres and `redis-cli ping` for Redis.
- **`depends_on.condition: service_healthy`**: API waits until DB and Cache are genuinely listening.
- **`secrets & .env`**: No hardcoded passwords in git.
- **`restart: unless-stopped`**: Production resilience.
- **`deploy.resources.limits`**: Prevents runaway memory leaks from freezing your Mac.

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
   docker compose up -d
   ```
3. **Watch the health checks initialize in real-time**:
   ```bash
   docker compose ps
   ```
   *Notice `STATUS: Up (health: starting)` transition to `Up (healthy)`.*

4. **Test the services**:
   - React Frontend: `curl -I http://localhost:3000`
   - Node API: `curl http://localhost:4000/api/health`
   - Python Worker: `curl http://localhost:5000/health`

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

## 🧹 Clean up Lab 05
```bash
docker compose down -v
```
