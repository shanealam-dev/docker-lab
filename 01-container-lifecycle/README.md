# 🧪 Lab 01: Container Lifecycle & CLI Mastery

> **Goal**: Develop unbreakable muscle memory for container states, process management, logs, debugging, and data extraction from dead containers.  
> **Tech in this lab**: Redis, Python 3, Alpine, Busybox.

---

## 🧠 1. Visual Mental Model: Container State Machine

A container is simply an **isolated Linux process** packaged with its own filesystem (rootfs).

```
                     ┌──────────────────┐
                     │   Image on Disk  │
                     └────────┬─────────┘
                              │ docker create / docker run
                              ▼
                        ┌───────────┐
      ┌────────────────►│  CREATED  │
      │                 └─────┬─────┘
      │                       │ docker start
      │                       ▼
      │  docker unpause ┌───────────┐  docker pause
      │  ─────────────  │  RUNNING  │ ─────────────► ┌──────────┐
      │                 │  (PID 1)  │ ◄───────────── │  PAUSED  │
      │                 └─────┬─────┘  docker resume └──────────┘
      │                       │
      │        ┌──────────────┴──────────────┐
      │        │                             │
      │ docker stop (SIGTERM, wait 10s)  docker kill (SIGKILL immediately)
      │        ▼                             ▼
      │  ┌───────────┐                 ┌───────────┐
      └──┤  EXITED   │                 │  EXITED   │
  docker │ (Code 0)  │                 │(Code 137) │
  start  └─────┬─────┘                 └─────┬─────┘
               │                             │
               └──────────────┬──────────────┘
                              │ docker rm (or automatic with --rm)
                              ▼
                        ┌───────────┐
                        │ DESTROYED │
                        └───────────┘
```

### The Difference Between `docker stop` and `docker kill`:
- `docker stop`: Sends `SIGTERM` to PID 1. Gives the app **10 seconds** grace period to close database connections and finish requests. If it doesn't shut down, Docker sends `SIGKILL`.
- `docker kill`: Sends `SIGKILL` immediately. The process dies instantly (exit code `137` = 128 + 9).

---

## 🛠️ 2. Hands-on Missions

### 🎯 Mission 1: The Redis & Ephemeral CLI Drill
*Learn: Background daemon (`-d`), Ephemeral containers (`--rm`), interactive CLI (`-it`), and intra-container communication.*

1. **Start a Redis container in detached mode**:
   ```bash
   docker run -d --name redis-lab -p 6379:6379 redis:7-alpine
   ```
2. **Verify it is running**:
   ```bash
   docker ps
   ```
3. **Use an ephemeral (`--rm`) container to talk to Redis without installing Redis on your Mac**:
   ```bash
   # Connects using Mac host networking bridge
   docker run --rm -it redis:7-alpine redis-cli -h host.docker.internal -p 6379 ping
   ```
   *Expected output: `PONG`*

4. **Set and retrieve a key using `redis-cli`**:
   ```bash
   docker run --rm -it redis:7-alpine redis-cli -h host.docker.internal -p 6379 set user:101 '{"name":"Shane","role":"Hero"}'
   docker run --rm -it redis:7-alpine redis-cli -h host.docker.internal -p 6379 get user:101
   ```
   > 💡 **Notice**: When the command finishes, the CLI container automatically disappears (`--rm`), keeping your machine 100% clean!

---

### 🎯 Mission 2: Real-time Inspection, Process Tree & Logs
*Learn: `docker logs`, `docker top`, `docker stats`, and `docker inspect` formatting.*

1. **Launch a Python one-liner HTTP server container**:
   ```bash
   docker run -d --name py-web -p 8080:8000 python:3.12-alpine python -m http.server 8000
   ```
2. **Test it from your Mac terminal**:
   ```bash
   curl -I http://localhost:8080
   ```
3. **Observe the real-time logs with timestamps**:
   ```bash
   docker logs --timestamps --tail 20 py-web
   ```
4. **Inspect the actual Linux process running inside the container**:
   ```bash
   docker top py-web
   ```
5. **Extract specific data with `docker inspect` format queries** (No grep needed!):
   ```bash
   # Get the container's internal IP address:
   docker inspect --format '{{ .NetworkSettings.IPAddress }}' py-web

   # Check restart policy and exit code:
   docker inspect --format '{{ .State.Status }} (ExitCode: {{ .State.ExitCode }})' py-web
   ```

---

### 🎯 Mission 3: The "Dead Container Rescue" Operation
*Scenario: A critical service crashed or exited. You need to extract files or logs from the dead container before deleting it!*

1. **Create an ephemeral data container and simulate a write followed by a crash**:
   ```bash
   docker run --name crash-box alpine sh -c "echo 'TOP_SECRET_REPORT_$(date)' > /app_report.txt && exit 1"
   ```
2. **Check its status**:
   ```bash
   docker ps -a --filter "name=crash-box"
   ```
   *Notice `STATUS: Exited (1)`.*

3. **See what changed in the container's filesystem since it was created**:
   ```bash
   docker diff crash-box
   ```
   *Notice `A /app_report.txt` (A = Added, C = Changed, D = Deleted).*

4. **Rescue the file from the dead container to your Mac**:
   ```bash
   docker cp crash-box:/app_report.txt ./rescued_report.txt
   cat ./rescued_report.txt
   ```
5. **Clean up**:
   ```bash
   docker rm crash-box
   rm -f ./rescued_report.txt
   ```

---

### 🎯 Mission 4: The Break & Fix Challenge (Muscle Memory Builder)

#### 💥 Drill A: The Port Collision Mystery
Run this:
```bash
docker run -d --name web-alpha -p 5000:80 nginx:alpine
docker run -d --name web-beta  -p 5000:80 nginx:alpine
```
👉 **What happened?**
The second command fails: `Bind for 0.0.0.0:5000 failed: port is already allocated`.

👉 **Fix & Diagnosis**:
```bash
# 1. Find which container owns port 5000:
docker ps --filter "publish=5000"

# 2. Stop or rebind:
docker rm -f web-alpha
docker run -d --name web-beta -p 5001:80 nginx:alpine
```

#### 💥 Drill B: The Stubborn Container (SIGTERM vs SIGKILL)
Some apps ignore `SIGTERM`. Let's see how Docker handles it:
```bash
# Run a trap script that ignores SIGTERM:
docker run -d --name stubborn-box alpine sh -c 'trap "" TERM; while true; do sleep 1; done'

# Try normal stop (watch the 10-second delay):
time docker stop stubborn-box
```
Notice it hung for **10 full seconds** before Docker sent `SIGKILL`!
To kill immediately when an unresponsive container is stuck:
```bash
docker start stubborn-box
time docker kill stubborn-box    # Instant!
docker rm stubborn-box
```

---

## ⚡ 3. Revision Flashcard (Memorize These 8 Commands)

| Command | Why you use it |
|---|---|
| `docker run -d --name <n> -p <h>:<c> <img:tag>` | Run detached container with custom name and mapped port |
| `docker run --rm -it <img:tag> sh` | Instant disposable sandbox that auto-cleans on exit |
| `docker exec -it <name> sh` | Jump inside a **running** container to debug |
| `docker logs -f --tail 50 <name>` | Stream last 50 log lines live |
| `docker inspect -f '{{.State.Status}}' <name>` | Extract specific property from JSON configuration |
| `docker diff <name>` | Show all files added/changed/deleted inside the container |
| `docker cp <name>:/path ./local` | Copy files in or out of a running **or stopped** container |
| `docker system prune -f` | Free up disk space by wiping stopped containers and dangling images |

---

## 🧹 Clean up Lab 01
When you finish exploring Lab 01, clean up your sandbox with:
```bash
docker rm -f redis-lab py-web web-beta
```
