# 🍎 Lab 06: macOS Architecture, Performance & Multi-Platform

> **Goal**: Master Docker on macOS (Apple Silicon M1/M2/M3/M4 & Intel), avoid the dreaded `exec format error`, talk to Mac localhost via `host.docker.internal`, and optimize filesystem speed.

---

## 🧠 1. The Visual Mental Model

### The Multi-Architecture Problem (Apple Silicon vs Cloud)
Your Mac has an **ARM64** processor.  
Most production cloud servers (AWS, GCP, DigitalOcean) run on **AMD64 (x86_64)** processors.

```
Mac M-Series (ARM64)                               Cloud / Production (x86_64)
┌────────────────────────┐                         ┌────────────────────────┐
│ docker build -t app .  │                         │ docker run app         │
│ (Produces linux/arm64) │ ──push to registry───►  │ 💥 exec format error!  │
└────────────────────────┘                         └────────────────────────┘
```

👉 **The Solution**: Cross-platform compilation with **Docker Buildx**:
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t username/my-app:1.0 .
```

---

### The "localhost" Trap on macOS

When an app inside a container tries to connect to `http://localhost:8000`:
- On Linux (host network), it might reach the host.
- On **macOS**, `localhost` inside the container refers to the **container's loopback interface**, NOT your Mac!

```
                    ┌────────────────────────────┐
                    │    macOS Host (Port 8000)  │
                    └──────────────▲─────────────┘
                                   │
                   Connect via `host.docker.internal:8000`
                                   │
             ┌─────────────────────┴─────────────────────┐
             │       Container Isolated Namespace        │
             │  `localhost:8000` ──► Checks inside only! │
             └───────────────────────────────────────────┘
```

---

## 🛠️ 2. Hands-on Missions

### 🎯 Mission 1: Verify Host-to-Container via `host.docker.internal`

1. **Verify your Mac's host DNS resolution from inside a container**:
   ```bash
   docker run --rm alpine ping -c 2 host.docker.internal
   ```
   Notice that it resolves to the gateway IP bridging macOS and the Docker VM!

2. **Test connecting from container to Mac**:
   If you have any service running directly on your Mac, containers can reach it using `host.docker.internal:<port>`.

---

### 🎯 Mission 2: Inspecting Image Architecture & Emulation

1. **Check the architecture of images on your machine**:
   ```bash
   docker inspect --format '{{.Architecture}}' hero-react:prod
   ```
   On Apple Silicon, this outputs `arm64`.

2. **Force build an AMD64 image on Apple Silicon using Rosetta emulation**:
   ```bash
   docker build --platform linux/amd64 -t hero-amd64-test - << 'EOF'
   FROM alpine:latest
   RUN uname -m > /arch.txt
   CMD cat /arch.txt
   EOF
   
   docker run --rm hero-amd64-test
   ```
   👉 Notice it outputs `x86_64`! Docker Desktop automatically ran the container through macOS Rosetta 2 emulation!

---

### 🎯 Mission 3: macOS Filesystem Speed (VirtioFS)

In Docker Desktop Settings:
- Navigate to **Settings ➔ General ➔ Virtual machine options**.
- Ensure **VirtioFS** is selected for File Sharing Implementation (up to **10x faster** than old osxfs/gRPC FUSE for large `node_modules` and git repositories).

---

## ⚡ 3. Revision Flashcard

| Concept | macOS Rule |
|---|---|
| **Host address** | Use `host.docker.internal` instead of `localhost` |
| **Cross-build for cloud** | `docker build --platform linux/amd64 -t <tag> .` |
| **Inspect CPU architecture** | `docker inspect -f '{{.Architecture}}' <image>` |
| **Multi-arch builder** | `docker buildx create --use` |
| **Volume speed** | Keep write-heavy caches inside named volumes or enable VirtioFS |

---

## 🧹 Clean up Lab 06
```bash
docker rmi -f hero-amd64-test 2>/dev/null || true
```
