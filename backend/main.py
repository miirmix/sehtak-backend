"""
GigaChat Proxy — FastAPI backend
Routes: /health  /test  /ai/chat
Secrets: GIGACHAT_AUTH_KEY, GIGACHAT_SCOPE (env vars only, never in code)
TLS: Russian Trusted Root CA + Sub CA bundle (certs/russian_ca_bundle.pem)
"""

from __future__ import annotations

import base64
import logging
import os
import time
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path

import httpx
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

# ── Logging ────────────────────────────────────────────────────────────────────
logging.basicConfig(level=logging.INFO, format="%(levelname)s  %(name)s  %(message)s")
log = logging.getLogger("gigachat-proxy")

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE_DIR = Path(__file__).parent
CERT_BUNDLE = BASE_DIR / "certs" / "russian_ca_bundle.pem"

# ── GigaChat endpoints ─────────────────────────────────────────────────────────
OAUTH_URL = "https://ngw.devices.sberbank.ru:9443/api/v2/oauth"
CHAT_URL  = "https://gigachat.devices.sberbank.ru/api/v1/chat/completions"

# ── Token cache ────────────────────────────────────────────────────────────────
_token_cache: dict[str, object] = {"access_token": None, "expires_at": 0.0}


def _build_ssl() -> httpx.SSLConfig | bool:
    """Return SSL context using Russian CA bundle if present, else system CAs."""
    if CERT_BUNDLE.exists():
        log.info("Using Russian CA bundle: %s", CERT_BUNDLE)
        return str(CERT_BUNDLE)
    log.warning(
        "Russian CA bundle NOT found at %s — falling back to system CAs. "
        "TLS to GigaChat may fail.",
        CERT_BUNDLE,
    )
    return True  # system CAs — TLS still enforced, never disabled


def _auth_header() -> str:
    raw_key = os.environ.get("GIGACHAT_AUTH_KEY", "")
    if not raw_key:
        raise RuntimeError("GIGACHAT_AUTH_KEY is not set")
    encoded = base64.b64encode(raw_key.encode()).decode()
    return f"Basic {encoded}"


async def _get_access_token() -> str:
    now = time.time()
    if _token_cache["access_token"] and now < float(_token_cache["expires_at"]) - 60:
        return str(_token_cache["access_token"])

    scope = os.environ.get("GIGACHAT_SCOPE", "GIGACHAT_API_PERS")
    import uuid
    rquid = str(uuid.uuid4())

    ssl_ctx = _build_ssl()
    async with httpx.AsyncClient(verify=ssl_ctx, timeout=20.0) as client:
        resp = await client.post(
            OAUTH_URL,
            headers={
                "Authorization": _auth_header(),
                "RqUID": rquid,
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json",
            },
            data={"scope": scope},
        )

    if resp.status_code != 200:
        log.error("OAuth failed: status=%d body=%s", resp.status_code, resp.text[:300])
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"GigaChat OAuth failed ({resp.status_code})",
        )

    data = resp.json()
    token = data.get("access_token")
    expires_at = data.get("expires_at", 0)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="OAuth response missing access_token",
        )

    _token_cache["access_token"] = token
    _token_cache["expires_at"] = float(expires_at) / 1000.0 if expires_at > 1e10 else float(expires_at)
    log.info("Token refreshed, expires_at=%s", _token_cache["expires_at"])
    return token


# ── App lifecycle ──────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    if CERT_BUNDLE.exists():
        size = CERT_BUNDLE.stat().st_size
        log.info("Cert bundle found: %s (%d bytes)", CERT_BUNDLE, size)
        # Count how many certs are in the bundle
        text = CERT_BUNDLE.read_text(errors="replace")
        count = text.count("BEGIN CERTIFICATE")
        log.info("Cert bundle contains %d certificate(s)", count)
        if count < 2:
            log.warning("Expected >=2 certs in bundle, found %d — TLS may fail", count)
    else:
        log.warning(
            "Cert bundle NOT found at %s — falling back to system CAs. "
            "Run certs/download_certs.sh to build it.",
            CERT_BUNDLE,
        )
    yield
    log.info("GigaChat proxy shutting down.")


# ── FastAPI app ────────────────────────────────────────────────────────────────
app = FastAPI(
    title="GigaChat Proxy",
    version="1.0.0",
    docs_url=None,   # disable Swagger UI in production
    redoc_url=None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # mobile app — no browser origin needed
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)


# ── Request / Response models ──────────────────────────────────────────────────
class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    model: str = Field(default="GigaChat")
    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(default=1024, ge=1, le=4096)


# ── Routes ─────────────────────────────────────────────────────────────────────

@app.get("/health")
async def health():
    """Lightweight health-check for Railway/Render uptime monitoring."""
    return {
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "cert_bundle": CERT_BUNDLE.exists(),
    }


@app.get("/test")
async def test_gigachat():
    """
    Diagnostic: tests OAuth + a one-sentence chat ping.
    Safe to call from the iOS debug tool.
    """
    result: dict[str, object] = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "cert_bundle_present": CERT_BUNDLE.exists(),
    }

    raw_key = os.environ.get("GIGACHAT_AUTH_KEY", "")
    result["has_auth_key"] = bool(raw_key)
    if raw_key:
        result["key_hint"] = raw_key[:6] + "..." + raw_key[-4:]

    # — OAuth —
    try:
        token = await _get_access_token()
        result["oauth_ok"] = True
        result["token_length"] = len(token)
    except Exception as exc:
        result["oauth_ok"] = False
        result["oauth_error"] = str(exc)
        return JSONResponse(content=result)

    # — Chat ping —
    try:
        ssl_ctx = _build_ssl()
        async with httpx.AsyncClient(verify=ssl_ctx, timeout=30.0) as client:
            resp = await client.post(
                CHAT_URL,
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                },
                json={
                    "model": "GigaChat",
                    "messages": [{"role": "user", "content": "Привет, ответь одним предложением."}],
                    "max_tokens": 50,
                },
            )
        result["chat_status"] = resp.status_code
        result["chat_ok"] = resp.status_code == 200
        if resp.status_code == 200:
            data = resp.json()
            reply = data.get("choices", [{}])[0].get("message", {}).get("content", "")
            result["chat_reply_preview"] = reply[:120]
        else:
            result["chat_error"] = resp.text[:300]
    except Exception as exc:
        result["chat_ok"] = False
        result["chat_error"] = str(exc)

    return JSONResponse(content=result)


@app.post("/ai/chat")
async def ai_chat(body: ChatRequest, request: Request):
    """
    Main proxy endpoint — called by the iOS app.
    Requires no secrets in the mobile app; GIGACHAT_AUTH_KEY lives only here.
    """
    # Lightweight rate-limit hint (real limiting should be at reverse-proxy / Railway)
    if len(body.messages) > 50:
        raise HTTPException(status_code=400, detail="Too many messages")

    token = await _get_access_token()

    ssl_ctx = _build_ssl()
    async with httpx.AsyncClient(verify=ssl_ctx, timeout=45.0) as client:
        resp = await client.post(
            CHAT_URL,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            json={
                "model": body.model,
                "messages": [m.model_dump() for m in body.messages],
                "temperature": body.temperature,
                "max_tokens": body.max_tokens,
            },
        )

    if resp.status_code != 200:
        log.error("GigaChat chat error: status=%d body=%s", resp.status_code, resp.text[:300])
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"GigaChat error ({resp.status_code})",
        )

    return resp.json()
