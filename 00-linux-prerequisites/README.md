# 🐧 Lab 00: Linux Prerequisites for Docker

> **Goal**: Master essential Linux file handling, directory navigation, users, user switching, and permissions needed for Dockerfiles and container administration.  
> **Environment**: Alpine Linux / Ubuntu sandbox.

---

## 🧠 Why Linux Matters in Docker

Containers are **isolated Linux environments**. Every command you write in a Dockerfile (`RUN`, `COPY`, `USER`, `WORKDIR`) or run inside a container (`docker exec`) relies on fundamental Linux file and user operations.

```
┌────────────────────────────────────────────────────────┐
│                   DOCKER CONTAINER                     │
│                                                        │
│  Filesystem: Linux Root Tree (/app, /etc, /tmp, /var)  │
│  User Context: root (UID 0) vs unprivileged (UID 1001) │
│  Processes: Linux PID namespace (PID 1 entrypoint)     │
└────────────────────────────────────────────────────────┘
```

---

## 📂 1. File & Directory Operations

| Action | Command | What it does | Real Docker / Dockerfile Example |
|---|---|---|---|
| **Create Folder** | `mkdir -p /app/src/logs` | Create folder + parent folders if missing (`-p`) | `RUN mkdir -p /app/data` (prepares directory structure) |
| **Create File** | `touch .env` | Create empty file or update timestamp | `RUN touch /var/log/app.log` (creates log target) |
| **Copy File** | `cp app.conf app.conf.bak` | Copy a single file | Duplicating default configs inside container |
| **Copy Folder** | `cp -r /src /dist` | Copy entire folder recursively (`-r`) | Copying assets before build |
| **Move / Rename** | `mv server.js index.js` | Move or rename file/folder | Renaming `.env.example` ➔ `.env` |
| **Delete File** | `rm file.txt` | Delete a single file | Removing temporary download artifacts |
| **Delete Folder** | `rm -rf /tmp/build` | Force recursive delete without prompting (`-rf`) | `RUN rm -rf /var/lib/apt/lists/*` (keeps images slim!) |
| **List Files** | `ls -la /app` | List all files including hidden (`.`) with permissions & owner | Verifying volume mounts or installed files |
| **View Content** | `cat /etc/os-release` | Output entire file content to terminal | Inspecting Linux distro inside container |
| **Current Path** | `pwd` | Print working directory | Debugging where `WORKDIR` placed you |

### 🧪 Hands-on Test inside a Disposable Container:
```bash
docker run --rm -it alpine sh -c "
  mkdir -p /app/logs && cd /app
  echo 'hello=world' > config.env
  cp config.env config.env.bak
  mv config.env.bak config.env.old
  ls -la /app
  rm -rf /app/logs
  echo 'File operations verified!'
"
```

---

## 👤 2. Linux Users & Groups (UID, GID & Security)

### Why Users Matter in Docker:
By default, Docker containers execute as **`root` (UID 0)**.  
If an attacker exploits an application vulnerability inside your container while running as `root`, they could potentially break out and compromise the host machine. Production Docker images always run under an unprivileged user (e.g. `node`, `appuser`, `nginx`).

```
┌────────────────────────────────────────────────────────┐
│  root (UID: 0, GID: 0)        ⚠️ FULL PRIVILEGES       │
│  ├── Full access to container system (/etc, /bin)      │
│  └── High security risk if compromised                 │
├────────────────────────────────────────────────────────┤
│  appuser (UID: 1001, GID: 1001) 🔒 UNPRIVILEGED        │
│  ├── Can only read/write assigned /app folder          │
│  └── Production gold standard                          │
└────────────────────────────────────────────────────────┘
```

### Identity & Inspection Commands:
```bash
whoami        # Prints current username (e.g. root, node, appuser)
id            # Prints full identity: UID (User ID), GID (Group ID), and groups
id -u         # Prints numeric UID only (0 = root, 1000+ = normal users)
```

### Creating Users: Debian/Ubuntu vs Alpine Linux
Different base images use different package managers and user commands:

| Distro / Base Image | Create Group | Create Unprivileged User |
|---|---|---|
| **Debian / Ubuntu** (`python:slim`, `node`, `ubuntu`) | `groupadd -g 1001 appgroup` | `useradd -u 1001 -g appgroup -m -s /bin/bash appuser` |
| **Alpine Linux** (`alpine`, `node:alpine`) | `addgroup -g 1001 -S appgroup` | `adduser -u 1001 -G appgroup -s /bin/sh -D appuser` |

> 💡 **Flags Explained**:
> - `-u 1001`: Explicit numeric User ID (ensures identical permissions across environments).
> - `-m` (Debian): Creates home directory (`/home/appuser`).
> - `-D` (Alpine): Do not set a password (disables interactive login).
> - `-S` (Alpine): System group.

---

## 🔄 3. Switching Users (`su`, `sudo`, `USER`, `--user`)

### Inside a Container Shell:
```bash
# Switch to another user (keeps current directory):
su appuser

# Switch to another user WITH their full login profile (HOME, PATH, ~/.profile):
su - appuser

# Exit back to the previous user (or exit shell):
exit
```

> [!NOTE]
> `sudo` is usually **not installed** in minimal Docker images (Alpine/Slim) to minimize attack surface and image size. To switch users inside a container, use `su` or Docker's `-u` flag.

### In a Dockerfile (`USER`):
```dockerfile
# 1. Everything before this runs as root (system installs)
RUN apt-get update && apt-get install -y curl
RUN useradd -m -u 1001 appuser

# 2. Switch context to unprivileged user
USER appuser

# 3. Everything after this runs as appuser!
CMD ["python", "app.py"]
```

### Overriding User from Docker CLI (`-u` / `--user`):
You can choose which user runs the container **from the outside** without rebuilding the image:

```bash
# Run container directly as a specific UID/GID:
docker run --rm -u 1001:1001 alpine whoami
# Output: 1001

# Emergency Debugging: Jump into a running non-root container as ROOT (UID 0):
docker exec -u 0 -it <container_name> sh
# You now have root access inside to install debug tools (curl, ping, netstat)!
```

---

## 🛡️ 4. File Ownership & Permissions (`chown` & `chmod`)

When you create files as `root` and switch to `appuser`, `appuser` will get **`Permission denied`** unless you grant ownership.

### Changing Ownership (`chown` = Change Owner):
```bash
# Change owner and group of a single file:
chown appuser:appgroup /app/config.json

# Change owner of an entire directory tree recursively (-R):
chown -R appuser:appgroup /app
```

> [!TIP]
> **Dockerfile Best Practice**:  
> Running `RUN chown -R appuser:appgroup /app` after `COPY . /app` duplicates all files in an extra layer and doubles image size!  
> Instead, use: `COPY --chown=appuser:appgroup . /app`

### Changing Permissions (`chmod` = Change Mode):
Permissions are grouped into 3 digits: **Owner**, **Group**, **Others**.  
Values: `r` (Read) = 4, `w` (Write) = 2, `x` (Execute) = 1.

| Mode | Symbolic | Meaning | Typical Docker Use-Case |
|---|---|---|---|
| `chmod +x entrypoint.sh` | `rwxr-xr-x` | Make script executable | Container entrypoint scripts |
| `chmod 755 /app/bin` | `rwxr-xr-x` | Owner can edit; others can read/execute | Application folders & binaries |
| `chmod 644 /app/config.json` | `rw-r--r--` | Owner can edit; others can only read | Source code & configuration files |
| `chmod 600 /app/id_rsa` | `rw-------` | Only owner can read/write | SSH private keys & database credentials |

---

## 🎮 5. The 60-Second Linux Practice Drill

Run this single command in your terminal to see files, user creation, ownership, and user switching in action:

```bash
docker run --rm -it alpine sh -c "
  echo '=== 1. Current user ===' && whoami && id
  echo '=== 2. Create unprivileged user appuser ==='
  adduser -u 1001 -s /bin/sh -D appuser
  echo '=== 3. Create folder & set ownership ==='
  mkdir -p /app && echo 'Hello Linux' > /app/data.txt
  chown -R appuser:appuser /app
  ls -ld /app && ls -l /app/data.txt
  echo '=== 4. Test non-root execution via su ==='
  su appuser -c 'whoami && cat /app/data.txt'
  echo '=== Linux Drill Completed Successfully! ==='
"
```

---

## ⚡ 6. Revision Flashcard (Revise in 30 Seconds)

| Task | Command |
|---|---|
| Create nested directories | `mkdir -p /path/to/dir` |
| Remove folder forcefully | `rm -rf /path/to/dir` |
| View file details & permissions | `ls -la` |
| Print current user identity | `whoami && id` |
| Switch user inside shell | `su <username>` |
| Run container as non-root | `docker run -u 1001:1001 <image>` |
| Jump into container as root | `docker exec -u 0 -it <name> sh` |
| Change owner recursively | `chown -R user:group /dir` |
| Make script executable | `chmod +x script.sh` |

---

## 🚀 Next Step
Proceed to [Lab 01: Container Lifecycle & CLI Mastery](../01-container-lifecycle/README.md).
