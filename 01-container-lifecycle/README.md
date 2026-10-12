# 🧪 Lab 01: Container Lifecycle & CLI Mastery

> **Goal**: Develop unbreakable muscle memory for container states, process management, logs, debugging, and data extraction from dead containers.  
> **Tech in this lab**: Redis, Python 3, Alpine, Busybox.

---

> 💡 **Prerequisite**: If you need a refresher on essential Linux file operations (`cp`, `mv`, `rm`), user creation, user switching (`su`), or file permissions (`chown`, `chmod`), check out the dedicated [Lab 00: Linux Prerequisites for Docker](../00-linux-prerequisites/README.md).

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

### 🎯 Mission 3: The `docker cp` Mastery & Dead Container Rescue
*Learn: How to inject files into containers, rescue data from dead containers, and copy recursively without volume mounts.*

The `docker cp` command works just like `cp` or `scp`.
> ⚡ **Superpower of `docker cp`**: It works whether the container is **RUNNING**, **PAUSED**, or **EXITED (DEAD)** without requiring SSH or pre-configured volumes!

---

#### 📥 Action A: Copy from Mac Host ➔ INTO Container (Injecting / Hot-patching)
```bash
# 1. Start a lightweight Nginx web server
docker run -d --name copy-demo -p 8085:80 nginx:alpine

# 2. Create a custom HTML file on your Mac
echo "<h1>Hello from Mac via docker cp!</h1>" > custom_index.html

# 3. Copy the file directly into the running container
docker cp custom_index.html copy-demo:/usr/share/nginx/html/index.html

# 4. Verify the updated page immediately from your Mac
curl http://localhost:8085
```
*(Notice Nginx serves the updated page immediately without rebuilding the image!)*

---

#### 📤 Action B: Copy from Container ➔ OUT to Mac Host (Dead Container Rescue)
*Scenario: A critical service crashed or exited. You need to extract files or logs before deleting the container.*

```bash
# 1. Create a container that writes secret data and crashes (Exit code 1)
docker run --name crash-box alpine sh -c "echo 'CRITICAL_BACKUP_$(date)' > /app_report.txt && exit 1"

# 2. Verify the container is dead (Status: Exited 1)
docker ps -a --filter "name=crash-box"

# 3. Inspect the container filesystem changes
docker diff crash-box
# (Look for 'A /app_report.txt' — A = Added, C = Changed, D = Deleted)

# 4. Rescue the file from the dead container to your Mac
docker cp crash-box:/app_report.txt ./rescued_report.txt

# 5. Verify the extracted content on your Mac
cat ./rescued_report.txt
```

---

#### 📁 Action C: Copying Entire Directories Recursively
```bash
# Create a local test folder with multiple files
mkdir -p ./my_local_assets && echo "asset1" > ./my_local_assets/a.txt && echo "asset2" > ./my_local_assets/b.txt

# Copy entire local directory INTO container
docker cp ./my_local_assets copy-demo:/usr/share/nginx/html/assets

# Copy entire directory OUT from container to Mac
docker cp copy-demo:/etc/nginx ./extracted_nginx_config

# Inspect extracted config on Mac
ls -la ./extracted_nginx_config
```

---

#### 🧹 Cleanup Mission 3
```bash
docker rm -f copy-demo crash-box
rm -f custom_index.html rescued_report.txt
rm -rf my_local_assets extracted_nginx_config
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

### 🎯 Mission 5: Image Inspection, Tagging & The Removal Conflict Trap
*Learn: How images work under the hood, layer history, and how to fix image deletion errors.*

1. **Inspect image layer history and sizes**:
   ```bash
   docker image history redis:7-alpine
   ```
   *Notice the exact size added by each step (`WORKDIR`, `RUN`, `ENTRYPOINT`).*

2. **Tag an image (create an alias)**:
   ```bash
   docker tag redis:7-alpine my-cache:v1.0
   docker images | grep my-cache
   ```
   *(Notice both tags share the exact same `IMAGE ID` and consume zero extra disk space!)*

3. **Trigger the #1 Image Removal Error**:
   ```bash
   # Create a stopped container using this tag
   docker create --name locked-app my-cache:v1.0

   # Now try to delete the underlying image ID:
   IMG_ID=$(docker inspect --format '{{.Id}}' my-cache:v1.0)
   docker rmi $IMG_ID || echo "💥 FAILED: Docker blocked removal because locked-app exists!"
   ```

4. **The Proper Fix**:
   Remove the referencing container first, then delete the image:
   ```bash
   docker rm locked-app
   docker rmi my-cache:v1.0
   ```

5. **Prune dangling `<none>:<none>` images**:
   ```bash
   docker image prune -f
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
