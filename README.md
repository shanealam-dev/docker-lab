# 🐳 Docker: Zero to Hero (Mac Edition)
> **Practical, Unforgettable, Real-World Stack**  
> Tech Stack: **React • Node/Express • Python • PostgreSQL • Redis**  
> Host: **macOS (Apple Silicon / Intel)**

---

## 🗺️ Curriculum & Roadmap

Each lab follows the **4-Step Unforgettable Learning Cycle**:
1. 🧠 **Mental Model & Mac Architecture** (Why it works, Mac VM quirks)
2. 🛠️ **Hands-on Lab** (Step-by-step real code drills)
3. 💥 **"Break & Fix" Challenge** (Intentionally breaking things to build diagnostic intuition)
4. ⚡ **Revision Flashcard** (60-second summary table for quick refreshers)

| # | Lab Directory | Focus & Tech Stack | Key Skills Learned |
|---|---|---|---|
| **01** | [`01-container-lifecycle`](./01-container-lifecycle/README.md) | Redis, Python, Busybox | Container states, interactive vs detached, `exec`, logs, inspection, dead container rescue |
| **02** | `02-dockerfiles-multistage` | React (Vite), Node/Express, Python | Layer caching, multi-stage builds (800MB ➔ 25MB), non-root security (`USER`), `.dockerignore` |
| **03** | `03-storage-and-volumes` | PostgreSQL, Node.js hot-reload | Named volumes (persistence proof), bind mounts (macOS dev performance), volume backups |
| **04** | `04-networking-deepdive` | Node API + Redis + Postgres | Bridge vs Host, internal DNS by service name, network isolation (frontend vs backend) |
| **05** | `05-compose-production` | Full Multi-tier Stack | `compose.yaml`, healthchecks (`condition: service_healthy`), secrets, restart policies |
| **06** | `06-mac-performance-arch` | Multi-arch (ARM64 vs AMD64) | Apple Silicon Rosetta emulation, VirtioFS filesystem tuning, `host.docker.internal` |
| **07** | `07-capstone-boss-fight` | Distributed Broken App | Real-world debugging: fix 4 hidden bugs across networking, volumes, and healthchecks |

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
# 1. Lifecycle
docker run -d --name my-redis -p 6379:6379 redis:7-alpine  # Run detached & map port
docker ps                                                # List running containers
docker ps -a                                             # List all (including stopped)
docker stop <name> && docker start <name>                # Stop / Start
docker rm -f <name>                                      # Force remove container

# 2. Debugging & Inspection
docker logs -f --tail 100 <name>                         # Follow logs
docker exec -it <name> sh                                # Interactive shell inside container
docker inspect <name>                                    # Complete JSON config & IP
docker stats                                             # Real-time CPU / Memory usage
docker top <name>                                        # View processes inside container

# 3. Clean up
docker system prune -f                                   # Clean stopped containers, dangling images
docker volume prune -f                                   # Clean unused volumes
docker image prune -a                                    # Clean unused images
```

---

## 🚀 Ready to Begin?
Head straight into [Lab 01: Container Lifecycle & CLI Mastery](./01-container-lifecycle/README.md).
# docker-lab
