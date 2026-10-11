# 🌐 Lab 04: Docker Networking Deep Dive

> **Goal**: Master Docker DNS service discovery, user-defined bridges, multi-tier network isolation, and fix cross-network communication errors.  
> **Tech in this lab**: Node API, Redis, Python, Busybox/Alpine.

---

## 🧠 1. The Visual Mental Model

Docker provides automatic DNS resolution **only** on user-defined networks.

```
❌ DEFAULT BRIDGE (docker0):
   [Container A] ──ping "container-b"──► ❌ FAILS! (No automatic DNS, IP only)

✅ USER-DEFINED BRIDGE (e.g. "my-net"):
   [Container A] ──ping "container-b"──► 172.28.0.3 ✅ SUCCESS! (Embedded DNS 127.0.0.11)
```

---

### Multi-Tier Architecture: The DMZ Security Pattern

In production, your database and cache should **never** share a network with public-facing frontend containers.

```
       [ Public Internet ]
               │
               ▼
   ┌───────────────────────┐
   │    FRONTEND NETWORK   │
   │  ┌─────────────────┐  │
   │  │   React / Nginx │  │
   │  └────────┬────────┘  │
   └───────────┼───────────┘
               │
               ▼
   ┌───────────────────────────────────────────────┐
   │            BACKEND API (Node / Express)       │
   │  (Connected to BOTH Frontend & Data networks) │
   └───────────────────────┬───────────────────────┘
                           │
                           ▼
   ┌───────────────────────────────────────────────┐
   │                 DATA NETWORK                  │
   │      (Completely isolated from Frontend)      │
   │                                               │
   │   ┌───────────────┐       ┌───────────────┐   │
   │   │  Postgres DB  │       │  Redis Cache  │   │
   │   └───────────────┘       └───────────────┘   │
   └───────────────────────────────────────────────┘
```

> 🛡️ **Security Result**: Even if an attacker compromises the Frontend container, they cannot ping or reach PostgreSQL or Redis because they exist in physically separate bridge namespaces!

---

## 🛠️ 2. Hands-on Missions

### 🎯 Mission 1: The Default Bridge vs User-Defined Bridge Trap

1. **Try pinging by container name on the default bridge**:
   ```bash
   docker run -d --name box-a alpine sleep 1000
   docker run -d --name box-b alpine sleep 1000
   
   # Attempt to ping box-b from box-a:
   docker exec box-a ping -c 2 box-b || echo "FAILED! Default bridge has NO DNS!"
   ```
2. **Now create a user-defined bridge network**:
   ```bash
   docker network create hero-net
   
   docker run -d --name box-c --network hero-net alpine sleep 1000
   docker run -d --name box-d --network hero-net alpine sleep 1000
   
   # Ping by name on the user-defined network:
   docker exec box-c ping -c 2 box-d
   ```
   🎉 **Success!** Docker's embedded DNS server (`127.0.0.11`) resolves `box-d` instantly.

3. **Clean up**:
   ```bash
   docker rm -f box-a box-b box-c box-d
   ```

---

### 🎯 Mission 2: Building the 2-Tier Isolated DMZ
*Connect Node API to Redis securely.*

1. **Create two separate networks**:
   ```bash
   docker network create web-tier
   docker network create data-tier
   ```
2. **Start Redis on the isolated `data-tier`**:
   ```bash
   docker run -d --name private-redis --network data-tier redis:7-alpine
   ```
3. **Start a public client on `web-tier`**:
   ```bash
   docker run -d --name public-client --network web-tier alpine sleep 1000
   ```
4. **Verify public client CANNOT reach Redis**:
   ```bash
   docker exec public-client ping -c 1 -W 1 private-redis || echo "BLOCKED as expected!"
   ```
5. **Start your Node API on `web-tier`, then bridge it to `data-tier`**:
   ```bash
   docker run -d --name api-gateway --network web-tier alpine sleep 1000
   
   # Dynamically attach api-gateway to the data-tier:
   docker network connect data-tier api-gateway
   ```
6. **Verify `api-gateway` can talk to BOTH tiers**:
   ```bash
   docker exec api-gateway ping -c 1 public-client
   docker exec api-gateway ping -c 1 private-redis
   ```

---

### 💥 3. The "Break & Fix" Challenge (Your Previous Setup Bug!)

Remember in your original `03-python-redis` setup:
```yaml
services:
  redis:
    networks: [backend]
  app:
    networks: [frontend]
```
When `app` attempted to connect to `redis:6379`, Python threw:
`gaierror: [Errno -2] Name or service not known`

#### The Diagnostic Drill:
1. Inspect the container's networks:
   ```bash
   docker inspect --format '{{json .NetworkSettings.Networks}}' <container-name>
   ```
2. Inspect the network's connected containers:
   ```bash
   docker network inspect <network-name> --format '{{json .Containers}}'
   ```
3. Fix without restarting the container:
   ```bash
   docker network connect <network-name> <container-name>
   ```

---

## ⚡ 4. Revision Flashcard

| Command | Purpose |
|---|---|
| `docker network ls` | List all network interfaces |
| `docker network create <name>` | Create a custom bridge with built-in DNS |
| `docker network inspect <name>` | View subnets, gateways, and attached containers |
| `docker network connect <net> <container>` | Live-attach a running container to a new network |
| `docker network disconnect <net> <container>` | Detach a container from a network |
| `docker network prune -f` | Wipe unused networks |

---

## 🧹 Clean up Lab 04
```bash
docker rm -f private-redis public-client api-gateway 2>/dev/null || true
docker network rm hero-net web-tier data-tier 2>/dev/null || true
```
