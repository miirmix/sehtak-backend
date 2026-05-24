# GigaChat Proxy — Deployment Guide

## Architecture

```
iPhone App  ──HTTPS──▶  FastAPI Proxy (Railway/Render)
                              │
              ┌───────────────┴────────────────┐
              │                                │
        POST /ai/chat                   POST /ai/analyze-image
              │                                │
              ▼                                ▼
        GigaChat API                    OpenAI Responses API
     (GIGACHAT_AUTH_KEY)            (OPENAI_API_KEY, OPENAI_VISION_MODEL)
```

> Text chat uses GigaChat only. Image analysis uses OpenAI Vision on the backend.
> API keys never ship in the iOS app.

---

## Step 1 — Build the CA certificate bundle locally

> You need `curl` and `openssl` installed (both are pre-installed on macOS/Linux).

```bash
cd backend/certs
chmod +x download_certs.sh
./download_certs.sh
```

Expected output:
```
✅ russian_ca_bundle.pem created successfully.
-rw-r--r-- 1 ...  4.2K russian_ca_bundle.pem
```

Commit the bundle:
```bash
git add backend/certs/russian_ca_bundle.pem
git commit -m "Add Russian CA bundle for GigaChat TLS"
git push
```

> **Why commit it?** It is a *public* root CA certificate, not a secret.
> It lets the server verify GigaChat's TLS identity securely.

---

## Option A — Deploy to Railway (recommended)

### 1. Create a Railway project
1. Go to [railway.app](https://railway.app) → **New Project** → **Deploy from GitHub repo**
2. Select this repository → Railway auto-detects `railway.json`

### 2. Set environment variables
In the Railway dashboard → your service → **Variables**:

| Variable              | Value                         |
|-----------------------|-------------------------------|
| `GIGACHAT_AUTH_KEY`   | Your Base64 key from GigaChat |
| `GIGACHAT_SCOPE`      | `GIGACHAT_API_PERS`           |
| `OPENAI_API_KEY`      | Your OpenAI API key           |
| `OPENAI_VISION_MODEL` | `gpt-4.1-mini` (optional)     |

> ⚠️ **Never** put `GIGACHAT_AUTH_KEY` or `OPENAI_API_KEY` in source code or the iOS app.
> `OPENAI_VISION_MODEL` defaults to `gpt-4.1-mini` when unset — change it in Railway if OpenAI model availability changes.

### 3. Get your public URL
After deploy: **Settings → Domains** → copy `https://your-service.railway.app`

### 4. Update the iOS app
Open `concept-pulse/AI/GigaChatConfig.swift` and set:
```swift
static let proxyBaseURL = "https://your-service.railway.app"
```

---

## Option B — Deploy to Render

### 1. Create a Render web service
1. Go to [render.com](https://render.com) → **New** → **Web Service**
2. Connect your GitHub repo
3. Render reads `render.yaml` automatically

### 2. Set the secret environment variable
In Render Dashboard → **Environment**:
- Add `GIGACHAT_AUTH_KEY` = your key

### 3. Get your URL
`https://gigachat-proxy.onrender.com` (or whatever name you chose)

> ⚠️ Render free tier spins down after 15 min of inactivity (cold start ~30s).
> Railway free tier has 500h/month — always-on is preferred.

---

## Step 2 — Update the iOS app

After getting your hosted URL, update one constant in Swift:

```
concept-pulse/AI/GigaChatConfig.swift
→ static let proxyBaseURL = "https://YOUR-DOMAIN.railway.app"
```

---

## Endpoints

| Method | Path                | Description                                    |
|--------|---------------------|------------------------------------------------|
| GET    | `/health`           | Health check — Railway/Render uptime monitor   |
| GET    | `/test`             | Diagnostic: OAuth + chat ping (debug tool)     |
| POST   | `/ai/chat`          | Text chat proxy (GigaChat) — iOS assistant     |
| POST   | `/ai/analyze-image` | Medical image analysis (OpenAI Vision)         |

---

## Local testing

```bash
cd backend

# Install deps
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Build cert bundle
bash certs/download_certs.sh

# Set env vars
export GIGACHAT_AUTH_KEY="your_key_here"
export GIGACHAT_SCOPE="GIGACHAT_API_PERS"
export OPENAI_API_KEY="your_openai_key_here"
export OPENAI_VISION_MODEL="gpt-4.1-mini"   # optional; defaults to gpt-4.1-mini

# Run
uvicorn main:app --reload --port 8080

# Test
curl http://localhost:8080/health
curl http://localhost:8080/test

# Image analysis (multipart/form-data)
curl -X POST http://localhost:8080/ai/analyze-image \
  -F "language=ar" \
  -F "image=@/path/to/image.jpg;type=image/jpeg"
```

---

## Security checklist

- [x] `GIGACHAT_AUTH_KEY` and `OPENAI_API_KEY` are only in hosting env vars — never in source code
- [x] `OPENAI_VISION_MODEL` is server-configurable (default `gpt-4.1-mini`)
- [x] TLS verification is always enabled (`verify=True` / CA bundle path)
- [x] `verify=False` is NOT used anywhere
- [x] CA bundle is public data — safe to commit
- [x] Swagger UI disabled in production (`docs_url=None`)
- [x] Message count capped at 50 to prevent abuse
- [x] Token cache avoids excessive OAuth calls
