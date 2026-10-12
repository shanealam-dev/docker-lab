# 🐳 Docker: Zero to Hero (Mac Edition)
> **Practical, Unforgettable, Real-World Stack**  
> Tech Stack: **React • Node/Express • Python • PostgreSQL • Redis**  
> Host: **macOS (Apple Silicon M1/M2/M3/M4 & Intel)**

---

## 📋 0. Prerequisites & Mac Setup Checklist

Before diving into containers, ensure your Mac environment is verified:

### 1. Requirements
- **macOS Sonoma / Ventura / Sequoia** (Apple Silicon or Intel).
- **Docker Desktop for Mac** (Installed and running).
- Terminal of choice (`zsh`, `bash`, iTerm2, or IDE built-in terminal).

### 2. Sanity Check Commands
Run these in your terminal to verify Docker Engine is alive:
```bash
# Check CLI & Daemon versions
docker --version
docker compose version

# Check that the Docker Daemon is responsive
docker info
```
> [!TIP]
> If `docker info` fails with `Cannot connect to the Docker daemon`, start Docker Desktop from your `/Applications` folder or Spotlight (`Cmd + Space` ➔ "Docker").

---

## 🧠 1. Core Fundamentals: What is a Docker Image?

### The Mental Model: Blueprint vs House (Class vs Object)
If you know Object-Oriented Programming, this analogy makes it unforgettable:

```
┌────────────────────────────────────────┐
│             DOCKERFILE                 │  Source Code (The Recipe)
│       Instructions on how to build     │  "class UserServer { ... }"
└──────────────────┬─────────────────────┘
                   │ docker build
                   ▼
┌────────────────────────────────────────┐
│            DOCKER IMAGE                │  Compiled Class / Blueprint
│  - Static, Immutable snapshot          │  - Read-Only layers on disk
│  - Contains OS files, runtime, code    │  - Can be shared on Docker Hub
└──────────────────┬─────────────────────┘
                   │ docker run (instantiation)
                   ▼
┌────────────────────────────────────────┐
│          DOCKER CONTAINER              │  Live Object Instance
│  - An active, running Linux process    │  "const server = new UserServer()"
│  - Has its own CPU, RAM, & IP address  │  - Isolated from other containers
└────────────────────────────────────────┘
```

---

### The "Layer Cake" Architecture (UnionFS / OverlayFS)
An image is **not** a single heavy virtual disk (.vmdk or .iso).  
It is a **stack of read-only layers**, where each layer represents a change made in the Dockerfile.

```
┌─────────────────────────────────────────────────────────┐
│     TOP: Writable Container Layer (Thin R/W Scratchpad) │ ◄── Deleted on `docker rm`
├─────────────────────────────────────────────────────────┤
│ Layer 4: CMD ["node", "server.js"]            (Read-Only)│
│ Layer 3: COPY . /app                          (Read-Only)│ ◄── Reused across containers!
│ Layer 2: RUN npm install                      (Read-Only)│     Content-addressed by SHA256
│ Layer 1: FROM node:20-alpine                  (Read-Only)│
└─────────────────────────────────────────────────────────┘
```

#### Copy-on-Write (CoW) in Action:
When your container creates a file (e.g. `app.log`) or edits an existing config, Docker **does not modify the underlying image**. Instead:
1. Docker copies the original file up into the **Writable Container Layer**.
2. It modifies the copy there.
3. The underlying image layers remain **100% frozen and pristine**.

---

## ⚔️ 2. Image vs Container: Face-to-Face Comparison

| Characteristic | 📦 Docker Image | 🏃 Docker Container |
|---|---|---|
| **What is it?** | A frozen, packaged template on disk | A live running process in an isolated sandbox |
| **Mutability** | **100% Read-Only (Immutable)** | **Read-Write** (via thin top container layer) |
| **State** | Inert files stored in Docker local store | Dynamic: `Created`, `Running`, `Paused`, `Exited` |
| **Relationship** | 1 Image can spawn **hundreds** of containers | Every container is an instance of **1 Image** |
| **Resource Usage** | Disk space only | Disk + Active RAM + Active CPU cores |
| **Key Verbs** | `build`, `pull`, `push`, `tag`, `rmi`, `history` | `run`, `start`, `stop`, `restart`, `exec`, `rm`, `logs` |

---

## 🏷️ 3. Image Anatomy & Tagging Standards

Every image name follows a standard fully qualified format:

```
  docker.io / library / redis : 7-alpine
  └───────┬┘  └───┬───┘ └──┬──┘ └───┬───┘
          │       │        │        └─ Tag (Version or variant)
          │       │        └────────── Image Repository Name
          │       └─────────────────── Namespace (User or Organization)
          └─────────────────────────── Registry Host (Default: Docker Hub)
```

- **Default Registry**: If omitted, defaults to `docker.io`.
- **Default Namespace**: If omitted for official images, defaults to `library` (e.g., `redis`, `python`, `node`, `postgres`).
- **Default Tag**: If no tag is provided, Docker automatically appends `:latest`.

> [!WARNING]
> **The `:latest` Trap**: `:latest` does **NOT** automatically update or mean "the most recent version of software"! It is simply a default string label attached to the last build pushed without an explicit tag. In production, **always pin explicit tags** (e.g., `postgres:16-alpine`, `node:20-alpine`).

---

## 🗑️ 4. Image Lifecycle: Finding, Tagging & Removing Images

### 1. Listing Images
```bash
# List all locally cached images
docker images

# Equivalent modern command
docker image ls

# Display specific columns (clean output)
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
```

### 2. Inspecting Image Layers & History
Want to see how an image was built and which command added the most weight?
```bash
# View layer breakdown and size per step
docker image history redis:7-alpine

# View detailed JSON metadata (architecture, environment variables, entrypoint)
docker image inspect redis:7-alpine
```

### 3. Tagging an Image
Tagging creates an **alias** pointing to the exact same image ID (zero disk overhead):
```bash
# Create an alias: hero-app:v1.0 pointing to existing image
docker tag hero-node:1.0 myregistry.com/shane/hero-node:v1.0
```

### 4. Removing Images (`docker rmi` / `docker image rm`)
```bash
# Remove an image by tag or ID
docker rmi redis:7-alpine
docker image rm <IMAGE_ID>

# Remove multiple images at once
docker rmi image1:tag image2:tag
```

#### 💥 The #1 Image Removal Error:
```
Error response from daemon: conflict: unable to delete <ID> (must be forced) - image is being used by stopped container <CID>
```
👉 **Why?** Docker protects you from deleting an image if ANY container (even a stopped one!) was created from it.  
👉 **The Clean Fix**: Delete the container first, then the image:
```bash
# 1. Remove the stopped container
docker rm <CONTAINER_ID>

# 2. Remove the image cleanly
docker rmi <IMAGE_NAME>
```
👉 **The Force Fix** (decouples tags and forces deletion):
```bash
docker rmi -f <IMAGE_ID>
```

### 5. Cleaning Up: Dangling Images vs Unused Images

#### What is a Dangling Image (`<none>:<none>`)?
When you rebuild an image with the same name and tag (e.g., `docker build -t my-app .`), Docker moves the tag to the new image. The previous build loses its name and becomes an orphan **dangling** image (`<none>:<none>`).

```bash
# 1. View dangling images:
docker images -f "dangling=true"

# 2. Remove only dangling images (Safe):
docker image prune -f

# 3. Nuclear Cleanup: Remove ALL images not currently attached to a running container:
docker image prune -a -f
```

---

## 🗺️ Curriculum & Roadmap

Each lab follows the **4-Step Unforgettable Learning Cycle**:
1. 🧠 **Mental Model & Mac Architecture** (Why it works, Mac VM quirks)
2. 🛠️ **Hands-on Lab** (Step-by-step real code drills)
3. 💥 **"Break & Fix" Challenge** (Intentionally breaking things to build diagnostic intuition)
4. ⚡ **Revision Flashcard** (60-second summary table for quick refreshers)

| # | Lab Directory | Focus & Tech Stack | Key Skills Learned |
|---|---|---|---|
| **00** | [`00-linux-prerequisites`](./00-linux-prerequisites/README.md) | Linux, Alpine | Essential Linux: File ops (`cp`, `mv`, `rm`), users, switching (`su`), ownership (`chown`), permissions (`chmod`) |
| **01** | [`01-container-lifecycle`](./01-container-lifecycle/README.md) | Redis, Python, Busybox | Container states, interactive vs detached, `exec`, logs, inspection, dead container rescue |
| **02** | [`02-dockerfiles-multistage`](./02-dockerfiles-multistage/README.md) | React (Vite), Node/Express, Python | Layer caching, multi-stage builds (800MB ➔ 25MB), non-root security (`USER`), `.dockerignore` |
| **03** | [`03-storage-and-volumes`](./03-storage-and-volumes/README.md) | PostgreSQL, Node.js hot-reload | Named volumes (persistence proof), bind mounts (macOS dev performance), volume backups |
| **04** | [`04-networking-deepdive`](./04-networking-deepdive/README.md) | Node API + Redis + Postgres | Bridge vs Host, internal DNS by service name, network isolation (frontend vs backend) |
| **05** | [`05-compose-production`](./05-compose-production/README.md) | Full Multi-tier Stack | `compose.yaml`, healthchecks (`condition: service_healthy`), secrets, restart policies |
| **06** | [`06-mac-performance-arch`](./06-mac-performance-arch/README.md) | Multi-arch (ARM64 vs AMD64) | Apple Silicon Rosetta emulation, VirtioFS filesystem tuning, `host.docker.internal` |
| **07** | [`07-capstone-boss-fight`](./07-capstone-boss-fight/README.md) | Distributed Broken App | Real-world debugging: fix 4 hidden bugs across networking, volumes, and healthchecks |

---

## 🍎 The macOS Mental Model (What Every Mac Engineer Must Know)

On Linux, Docker containers share the host Linux kernel directly.  
On **macOS**, containers **cannot** run directly on the Darwin/XNU kernel!

```
┌────────────────────────────────────────────────────────┐
│                   macOS (Darwin Kernel)                │
│   ├── Terminal / Docker CLI (`docker run ...`)         │
│   └── Docker Desktop GUI                               │
└──────────────────────────┬─────────────────────────────┘
                           │ Hypervisor (Virtualization.framework)
┌──────────────────────────▼─────────────────────────────┐
│              Linux Virtual Machine (Alpine/Ubuntu)     │
│   ├── Linux Kernel                                     │
│   ├── Docker Daemon (`dockerd`)                        │
│   └── Container Runtime (containerd + runc)            │
│       ├── Container A (Node.js)                        │
│       ├── Container B (Postgres)                       │
│       └── Container C (Redis)                          │
└────────────────────────────────────────────────────────┘
```

### The 3 Big Mac Gotchas:
1. **Networking**: Container IP addresses (`172.17.x.x`) are inside the Linux VM, **not** reachable directly from macOS browser/terminal! You **must** publish ports (`-p 8080:8080`) or use `host.docker.internal`.
2. **Filesystem Speed**: Sharing folders between macOS and the Linux VM passes through a translation layer. Ensure Docker Desktop uses **VirtioFS** for maximum speed.
3. **Architecture (Apple Silicon)**: M1/M2/M3/M4 chips run `linux/arm64`. Older x86 images run via Rosetta 2 emulation, which is slower. Always prefer multi-arch or native ARM64 images.

---

## ⚡ Master Docker CLI Cheat Sheet (Revise in 60 Seconds)

```bash
# 1. Images
docker images                                            # List local images
docker pull <image>:<tag>                                # Download image from registry
docker rmi <image>                                       # Remove image
docker image history <image>                             # Inspect image layer history
docker image prune -f                                    # Remove dangling (<none>:<none>) images
docker image prune -a -f                                 # Remove ALL unused images

# 2. Lifecycle
docker run -d --name my-redis -p 6379:6379 redis:7-alpine  # Run detached & map port
docker run --rm -it alpine sh                            # Disposable interactive container
docker ps                                                # List running containers
docker ps -a                                             # List all (including stopped)
docker stop <name> && docker start <name>                # Stop / Start
docker rm -f <name>                                      # Force remove container

# 3. Debugging & Inspection
docker logs -f --tail 100 <name>                         # Follow logs
docker exec -it <name> sh                                # Interactive shell inside container
docker inspect <name>                                    # Complete JSON config & IP
docker stats                                             # Real-time CPU / Memory usage
docker top <name>                                        # View processes inside container

# 4. Clean up
docker system prune -f                                   # Clean stopped containers, dangling images
docker volume prune -f                                   # Clean unused volumes
```

---

## 🚀 Ready to Begin?
Head straight into [Lab 01: Container Lifecycle & CLI Mastery](./01-container-lifecycle/README.md).
