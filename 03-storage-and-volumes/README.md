# 💾 Lab 03: Storage, Volumes & Bind Mounts

> **Goal**: Master Docker data persistence, understand the critical difference between Named Volumes and Bind Mounts, and solve the #1 macOS hot-reloading trap.  
> **Tech in this lab**: PostgreSQL 16, Node/Express live dev, Alpine utilities.

---

## 🧠 1. The Visual Mental Model

By default, any file written inside a container lives in the **writable container layer**.  
When the container is removed (`docker rm`), **that layer is destroyed forever**.

```
                ┌──────────────────────────────────────┐
                │          CONTAINER RUNTIME           │
                │                                      │
                │  /var/lib/postgresql/data (Postgres) │
                │  /app/src                 (Node.js)  │
                └──────────────┬──────────────┬────────┘
                               │              │
           Named Volume (Managed)             Bind Mount (Direct Host Path)
                               │              │
                               ▼              ▼
           ┌───────────────────────┐      ┌───────────────────────┐
           │ Docker Managed Storage│      │   Your Mac Hard Drive │
           │ /var/lib/docker/vols/ │      │   $(pwd)/src          │
           │ (High speed inside VM)│      │   (Hot Reloading Dev) │
           └───────────────────────┘      └───────────────────────┘
```

| Type | Syntax | Best Used For | macOS Performance |
|---|---|---|---|
| **Named Volume** | `-v pgdata:/var/lib/postgresql/data` | Databases (Postgres, Redis, Mongo), production data | **Blazing fast** (native inside Linux VM) |
| **Bind Mount** | `-v $(pwd):/app` | Local development, source code hot-reload | Moderate (crosses macOS Hypervisor VM layer) |
| **Anonymous Volume**| `-v /app/node_modules` | Masking host folders from overwriting container files | High |

---

## 🍎 The #1 macOS Dev Trap: "The `node_modules` Overwrite"

When you bind mount your project folder on macOS:
```bash
docker run -v $(pwd):/app hero-node
```
👉 Your Mac's local `node_modules/` (or lack thereof) **overwrites** the container's internal `/app/node_modules/`!  
If you built native Linux binaries inside the container, your Mac just replaced them with macOS binaries (or an empty folder), crashing the app!

### The Unforgettable Solution: Anonymous Volume Masking
```bash
docker run -v $(pwd):/app -v /app/node_modules hero-node
```
By adding `-v /app/node_modules`, Docker mounts a dedicated anonymous volume over `/app/node_modules`, protecting the container's Linux packages from being overwritten by the host!

---

## 🛠️ 2. Hands-on Missions

### 🎯 Mission 1: The PostgreSQL Persistence Proof
*Prove that data survives container deletion.*

1. **Create a named volume and start Postgres**:
   ```bash
   docker volume create pg_hero_data
   
   docker run -d --name pg-server \
     -e POSTGRES_PASSWORD=supersecret \
     -e POSTGRES_DB=herodb \
     -v pg_hero_data:/var/lib/postgresql/data \
     -p 5432:5432 postgres:16-alpine
   ```
2. **Wait 3 seconds, then insert a test record**:
   ```bash
   docker exec -i pg-server psql -U postgres -d herodb << 'EOF'
   CREATE TABLE heroes (id SERIAL PRIMARY KEY, name VARCHAR(50), superpower VARCHAR(50));
   INSERT INTO heroes (name, superpower) VALUES ('Shane', 'Docker Mastery'), ('Batman', 'Wealth');
   SELECT * FROM heroes;
   EOF
   ```
3. **Now DESTROY the container completely**:
   ```bash
   docker rm -f pg-server
   ```
4. **Spin up a BRAND NEW container using the same volume**:
   ```bash
   docker run -d --name pg-server-v2 \
     -e POSTGRES_PASSWORD=supersecret \
     -e POSTGRES_DB=herodb \
     -v pg_hero_data:/var/lib/postgresql/data \
     -p 5432:5432 postgres:16-alpine
   ```
5. **Verify the data is 100% intact**:
   ```bash
   docker exec -i pg-server-v2 psql -U postgres -d herodb -c "SELECT * FROM heroes;"
   ```
   🎉 **Proof complete**: The container died, but the data lived on!

---

### 🎯 Mission 2: Live Hot-Reloading Development on macOS
Navigate to `node-hotreload/`:
```bash
cd 03-storage-and-volumes/node-hotreload
```
1. **Start the dev container with bind mount**:
   ```bash
   docker run -d --name node-dev \
     -p 4500:4500 \
     -v "$(pwd)":/app \
     -v /app/node_modules \
     node:20-alpine sh -c "cd /app && npm install && npx nodemon index.js"
   ```
2. **Verify it is running**:
   ```bash
   curl http://localhost:4500
   ```
3. **Change the code in `index.js` on your Mac**:
   Edit `index.js` and save it.
4. **Observe nodemon reloading live without rebuilding the Docker image**:
   ```bash
   docker logs --tail 10 node-dev
   curl http://localhost:4500
   ```

---

### 🎯 Mission 3: Backup & Export a Docker Volume
*How to backup a production database volume to a tarball on macOS.*

```bash
docker run --rm \
  -v pg_hero_data:/source_data:ro \
  -v "$(pwd)":/backup \
  alpine tar czf /backup/pg_backup.tar.gz -C /source_data .
```
You now have `pg_backup.tar.gz` directly on your Mac desktop/folder!

---

## ⚡ 3. Revision Flashcard

| Task | Command |
|---|---|
| Create volume | `docker volume create <vol_name>` |
| Inspect location | `docker volume inspect <vol_name>` |
| Mount named volume | `-v <vol_name>:/container/path` |
| Bind mount host dir | `-v $(pwd):/container/path` |
| Protect node_modules | `-v $(pwd):/app -v /app/node_modules` |
| Read-only mount | `-v $(pwd)/config:/etc/config:ro` |
| Clean orphan volumes | `docker volume prune -f` |

---

## 🧹 Clean up Lab 03
```bash
docker rm -f pg-server-v2 node-dev 2>/dev/null || true
docker volume rm pg_hero_data 2>/dev/null || true
rm -f pg_backup.tar.gz
```
