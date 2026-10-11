# 🐳 Lab 02: Bulletproof Dockerfiles & Multi-Stage Builds

> **Goal**: Master Dockerfile layer caching, security with non-root users, and multi-stage builds to slash image sizes by 95%.  
> **Tech in this lab**: Python (FastAPI/Flask), Node.js (Express), React (Vite) + Nginx.

---

## 🧠 1. The Visual Mental Model

### Layer Caching: Why Order Matters
Docker builds images layer by layer. If layer $N$ changes, **every single layer after $N$ is rebuilt from scratch**.

```
❌ BAD ORDER (Reinstalls node_modules on EVERY code edit):
   FROM node:20-alpine
   WORKDIR /app
   COPY . .               <-- Any file change busts the cache here!
   RUN npm install        <-- Runs every single time (SLOW on Mac!)
   CMD ["node", "server.js"]

✅ BULLETPROOF ORDER (Instant rebuilds using cache):
   FROM node:20-alpine
   WORKDIR /app
   COPY package*.json ./  <-- Only busts cache if dependencies change!
   RUN npm ci             <-- Reused 99% of the time (FAST!)
   COPY . .               <-- Code updates only invalidate this quick layer
   CMD ["node", "server.js"]
```

---

### Multi-Stage Builds: The 800MB ➔ 25MB Transformation

Why ship a full Node.js compiler, npm, TypeScript, and gigabytes of build tooling to production just to serve static HTML, CSS, and JS?

```
┌────────────────────────────────────────┐
│  STAGE 1: BUILDER (node:20-alpine)     │
│  - Installs npm packages               │
│  - Runs `npm run build`                │
│  - Generates minified `/app/dist`      │
└──────────────────┬─────────────────────┘
                   │ COPY --from=builder /app/dist /usr/share/nginx/html
                   ▼
┌────────────────────────────────────────┐
│  STAGE 2: RUNTIME (nginx:alpine)       │
│  - Zero Node.js runtime                │
│  - Zero devDependencies                │
│  - Lightning-fast static file serving  │
│  - Result: ~25 MB total image!         │
└────────────────────────────────────────┘
```

---

## 📁 Lab Structure

```
02-dockerfiles-multistage/
├── README.md
├── python-app/       # Lightweight Python API + non-root security
├── node-app/         # Express API with layer-cached dependencies
└── react-app/        # Multi-stage Vite React build -> Nginx
```

---

## 🛠️ 2. Hands-on Missions

### 🎯 Mission 1: The Python API (Caching + Security)
Navigate to `python-app/`:
```bash
cd 02-dockerfiles-multistage/python-app
```
1. **Notice the Dockerfile features**:
   - Uses `python:3.12-slim` (minimal debian base).
   - Copies `requirements.txt` first.
   - Creates a dedicated non-root user `appuser` (preventing container escape exploits).
2. **Build and Tag**:
   ```bash
   docker build -t hero-python:1.0 .
   ```
3. **Run and Verify the non-root user**:
   ```bash
   docker run -d --name py-service -p 5050:5000 hero-python:1.0
   curl http://localhost:5050/
   
   # Check who is running the process inside:
   docker exec py-service whoami
   # Output: appuser (NOT root!)
   ```

---

### 🎯 Mission 2: The Node/Express API (Cached & Clean)
Navigate to `node-app/`:
```bash
cd ../node-app
```
1. **Build the image**:
   ```bash
   docker build -t hero-node:1.0 .
   ```
2. **Test Cache Hit**:
   Edit `index.js` (e.g. change version string). Run the build again:
   ```bash
   docker build -t hero-node:1.1 .
   ```
   👉 Notice `CACHED` appears on the `RUN npm install` step. The build finishes in under **0.5 seconds**!

3. **Run the API**:
   ```bash
   docker run -d --name node-service -p 4000:4000 hero-node:1.0
   curl http://localhost:4000/api/health
   ```

---

### 🎯 Mission 3: The React Multi-Stage Build (Size Slasher)
Navigate to `react-app/`:
```bash
cd ../react-app
```
1. **Build the production React image**:
   ```bash
   docker build -t hero-react:prod .
   ```
2. **Compare image sizes**:
   ```bash
   docker images | grep hero-
   ```
   Look at `hero-react:prod`! It is around **25–40MB**, compared to typical un-optimized 800MB+ Node images.

3. **Run the production React app**:
   ```bash
   docker run -d --name react-ui -p 3000:80 hero-react:prod
   curl -I http://localhost:3000
   ```
   Open `http://localhost:3000` in your Mac browser — you have a blazing fast Nginx server serving your compiled React app.

---

## 💥 3. "Break & Fix" Drill: The Cache-Busting Trap

**Symptom**: Developer says: *"I updated my `.env` or my code, but Docker isn't picking up changes!"* OR *"Why is Docker rebuilding all npm packages every time I change a comment in README?!"*

**The Culprit**: Missing `.dockerignore` file!  
Without `.dockerignore`, Docker copies your local `node_modules/`, `.git/`, `.env`, and cache folders into the build context.

**The Fix**:
Always include `.dockerignore`:
```
node_modules
.git
.env
Dockerfile
.dockerignore
dist
```

---

## ⚡ 4. Revision Flashcard (60-Second Refresh)

| Rule | Golden Best Practice |
|---|---|
| **Layer Caching** | Copy `package*.json` / `requirements.txt` *before* source code. |
| **Slim Base Images** | Use `-alpine` or `-slim` instead of default bloated OS images. |
| **Multi-Stage** | Use one stage for building (`node`), and a lightweight stage for runtime (`nginx` or `alpine`). |
| **Never Run as Root** | Add `USER node` or `RUN useradd -m appuser && USER appuser`. |
| **`.dockerignore`** | Always exclude `node_modules`, `.git`, `.DS_Store`, and secrets. |
| **Exec Form CMD** | Use `CMD ["node", "index.js"]` (exec form), **not** `CMD node index.js` (shell form hides signals). |

---

## 🧹 Clean up Lab 02
```bash
docker rm -f py-service node-service react-ui
```
