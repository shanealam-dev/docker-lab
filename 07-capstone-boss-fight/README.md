# 🏆 Lab 07: Capstone Boss Fight (Real-World Debugging Drill)

> **Scenario**: A junior developer submitted a PR for a 3-tier microservice stack.  
> It crashes, fails health checks, and won't respond to requests!  
> **Your Mission**: Identify and fix the 4 real-world bugs, run `./verify_fix.sh`, and earn your Docker Hero certification!

---

## 🕵️ The 4 Hidden Bugs

Look into `broken-stack/compose.broken.yaml` and discover:

1. **Bug 1: The `127.0.0.1` vs `0.0.0.0` Loopback Trap**  
   The API server inside the container was set to listen on `127.0.0.1`. Inside a container, `127.0.0.1` rejects any traffic coming across the Docker bridge virtual ethernet interface! (Must be `0.0.0.0`).

2. **Bug 2: The Network Partition (Silently Isolated Database)**  
   The Postgres database was placed on `db-net`, but the API was only joined to `frontend-net`. The API throws: `getaddrinfo ENOTFOUND postgres`.

3. **Bug 3: The False-Start Race Condition**  
   The API used `depends_on: [postgres]` without `condition: service_healthy`. The API attempts to query the database before Postgres has initialized its internal cluster catalog!

4. **Bug 4: The Missing Secret (`POSTGRES_PASSWORD`)**  
   The Postgres service is missing `POSTGRES_PASSWORD`, causing official PostgreSQL containers to exit with fatal initialization errors.

---

## 🛠️ Step-by-Step Challenge

1. **Launch the broken stack and observe the crash**:
   ```bash
   cd 07-capstone-boss-fight
   docker compose -f broken-stack/compose.broken.yaml up -d
   ```
2. **Diagnose the failure with your new Docker toolkit**:
   ```bash
   # Check which containers are Exited or Unhealthy:
   docker compose -f broken-stack/compose.broken.yaml ps
   
   # Read the crash logs:
   docker compose -f broken-stack/compose.broken.yaml logs postgres
   ```
3. **Compare with the production-ready solution in `solution/compose.fixed.yaml`**:
   ```bash
   diff -u broken-stack/compose.broken.yaml solution/compose.fixed.yaml
   ```
4. **Run the automated verification script**:
   ```bash
   ./verify_fix.sh
   ```

---

## 🎓 Next Stop: Kubernetes (`k8s-lab`)
Once you pass this capstone challenge, you are officially ready for Kubernetes!
In Kubernetes, we will map these exact concepts:
- **Docker Container** ➔ **K8s Pod**
- **Docker Compose Service** ➔ **K8s Deployment**
- **Docker User Bridge** ➔ **K8s ClusterIP Service**
- **Docker Named Volume** ➔ **PersistentVolumeClaim (PVC)**
- **Docker `.env`** ➔ **ConfigMap & Secret**
