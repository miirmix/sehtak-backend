"""
GigaChat Proxy -- FastAPI backend
Routes: /health  /test  /ai/chat
Secrets: GIGACHAT_AUTH_KEY, GIGACHAT_SCOPE (env vars only, never in code)
TLS: Russian Trusted Root CA + Sub CA bundle (certs/russian_ca_bundle.pem)
"""

from __future__ import annotations

import logging
import os
import re
import time
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path

import httpx
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

# -- Logging -------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="%(levelname)s  %(name)s  %(message)s")
log = logging.getLogger("gigachat-proxy")

# -- Paths ---------------------------------------------------------------------
BASE_DIR = Path(__file__).parent
CERT_BUNDLE = BASE_DIR / "certs" / "russian_ca_bundle.pem"

# -- GigaChat endpoints --------------------------------------------------------
OAUTH_URL = "https://ngw.devices.sberbank.ru:9443/api/v2/oauth"
CHAT_URL  = "https://gigachat.devices.sberbank.ru/api/v1/chat/completions"

# -- Token cache ---------------------------------------------------------------
_token_cache: dict[str, object] = {"access_token": None, "expires_at": 0.0}


# -- Cert validation -----------------------------------------------------------

def _validate_cert_bundle() -> dict[str, object]:
    """
    Validate the PEM bundle with Python's ssl module.
    Returns: {present, valid, cert_count, error, first_100_chars_safe}
    """
    result: dict[str, object] = {
        "present": False,
        "valid": False,
        "cert_count": 0,
        "error": None,
        "first_100_chars_safe": None,
    }
    if not CERT_BUNDLE.exists():
        result["error"] = f"File not found: {CERT_BUNDLE}"
        return result

    result["present"] = True

    try:
        text = CERT_BUNDLE.read_text(errors="replace")
        result["cert_count"] = text.count("BEGIN CERTIFICATE")
        safe = "".join(c if 32 <= ord(c) < 127 else "?" for c in text[:100])
        result["first_100_chars_safe"] = safe
    except Exception as exc:
        result["error"] = f"Read error: {exc}"
        return result

    import ssl as _ssl
    ctx = _ssl.create_default_context()
    try:
        ctx.load_verify_locations(str(CERT_BUNDLE))
        result["valid"] = True
    except Exception as exc:
        result["error"] = f"ssl.load_verify_locations failed: {exc}"

    return result


def _build_ssl() -> str | bool:
    """Return SSL verify arg: CA bundle path if valid, else True (system CAs)."""
    v = _validate_cert_bundle()
    if v["valid"]:
        log.info("Using Russian CA bundle: %s (%d certs)", CERT_BUNDLE, v["cert_count"])
        return str(CERT_BUNDLE)
    if v["present"]:
        log.error(
            "Russian CA bundle EXISTS but INVALID: %s -- falling back to system CAs. First 100: %r",
            v["error"], v["first_100_chars_safe"],
        )
    else:
        log.warning("Russian CA bundle NOT found -- falling back to system CAs.")
    return True  # system CAs; TLS still enforced, never disabled


# -- Auth header ---------------------------------------------------------------

# Pre-compile base64 pattern (avoids $ in inline regex strings that confuse tools)
_B64_RE = re.compile(r"^[A-Za-z0-9+/]+=*$")


def _auth_header() -> tuple[str, dict[str, object]]:
    """
    Return (Authorization header value, diagnostics dict).

    The GIGACHAT_AUTH_KEY obtained from Sberbank Studio is already a
    Base64-encoded credential (base64(clientID:clientSecret)).
    Use it DIRECTLY in 'Authorization: Basic <key>' -- do NOT re-encode.
    Strip any accidental 'Basic ' prefix that may be in the env var.
    """
    raw_key = os.environ.get("GIGACHAT_AUTH_KEY", "").strip()
    if not raw_key:
        raise RuntimeError("GIGACHAT_AUTH_KEY is not set")

    key_value = raw_key
    had_prefix = False
    if key_value.lower().startswith("basic "):
        key_value = key_value[6:].strip()
        had_prefix = True

    is_base64 = bool(_B64_RE.match(key_value)) and len(key_value) % 4 == 0

    diag: dict[str, object] = {
        "auth_header_prefix": "Basic",
        "auth_key_len": len(key_value),
        "auth_key_looks_base64": is_base64,
        "had_basic_prefix_in_env": had_prefix,
        "key_hint": (key_value[:6] + "..." + key_value[-4:]) if len(key_value) > 10 else "***",
    }

    return f"Basic {key_value}", diag


# -- Token fetch ---------------------------------------------------------------

async def _get_access_token() -> str:
    now = time.time()
    if _token_cache["access_token"] and now < float(_token_cache["expires_at"]) - 60:
        return str(_token_cache["access_token"])

    scope = os.environ.get("GIGACHAT_SCOPE", "GIGACHAT_API_PERS")
    rquid = str(uuid.uuid4())

    auth_header, auth_diag = _auth_header()

    log.info(
        "OAuth request: url=%s scope=%s rquid=%s "
        "auth_key_len=%d auth_key_looks_base64=%s had_basic_prefix=%s key_hint=%s",
        OAUTH_URL, scope, rquid,
        auth_diag["auth_key_len"],
        auth_diag["auth_key_looks_base64"],
        auth_diag["had_basic_prefix_in_env"],
        auth_diag["key_hint"],
    )

    ssl_ctx = _build_ssl()
    async with httpx.AsyncClient(verify=ssl_ctx, timeout=20.0) as client:
        resp = await client.post(
            OAUTH_URL,
            headers={
                "Authorization": auth_header,
                "RqUID": rquid,
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json",
            },
            data={"scope": scope},
        )

    log.info("OAuth response: status=%d", resp.status_code)

    if resp.status_code != 200:
        safe_body = resp.text[:500]
        log.error(
            "OAuth FAILED: status=%d scope=%s auth_key_len=%d auth_key_looks_base64=%s response_body=%s",
            resp.status_code, scope,
            auth_diag["auth_key_len"],
            auth_diag["auth_key_looks_base64"],
            safe_body,
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={
                "error": "GigaChat OAuth failed",
                "oauth_status": resp.status_code,
                "oauth_response_body": safe_body,
                "auth_key_len": auth_diag["auth_key_len"],
                "auth_key_looks_base64": auth_diag["auth_key_looks_base64"],
                "scope": scope,
                "rq_uid_is_uuid": True,
            },
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


# -- App lifecycle -------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    raw_key = os.environ.get("GIGACHAT_AUTH_KEY", "")
    raw_scope = os.environ.get("GIGACHAT_SCOPE", "")
    log.info("ENV CHECK: GIGACHAT_AUTH_KEY present=%s len=%d", bool(raw_key), len(raw_key))
    log.info("ENV CHECK: GIGACHAT_SCOPE    present=%s value=%r", bool(raw_scope), raw_scope or "(empty)")

    if raw_key:
        stripped = raw_key.strip()
        if stripped != raw_key:
            log.warning(
                "ENV WARNING: GIGACHAT_AUTH_KEY has leading/trailing whitespace! "
                "Stripped len=%d vs raw len=%d", len(stripped), len(raw_key)
            )
        log.info("ENV CHECK: key_prefix=%s key_suffix=%s", raw_key[:4], raw_key[-4:])
    else:
        known = [k for k in os.environ if "GIGA" in k.upper() or "AUTH" in k.upper()]
        log.warning("ENV CHECK: GIGACHAT_AUTH_KEY not found. Related keys: %s", known)
        log.info("ENV CHECK: All env var names: %s", sorted(os.environ.keys()))

    cv = _validate_cert_bundle()
    if cv["valid"]:
        log.info("Cert bundle: VALID -- %d cert(s), %d bytes", cv["cert_count"], CERT_BUNDLE.stat().st_size)
    elif cv["present"]:
        log.error("Cert bundle EXISTS but INVALID: %s | first_100=%r", cv["error"], cv["first_100_chars_safe"])
    else:
        log.warning("Cert bundle NOT found at %s -- GigaChat TLS will fail.", CERT_BUNDLE)

    yield
    log.info("GigaChat proxy shutting down.")


# -- FastAPI app ---------------------------------------------------------------

app = FastAPI(
    title="GigaChat Proxy",
    version="1.0.0",
    docs_url=None,
    redoc_url=None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)


# -- Models --------------------------------------------------------------------

class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    model: str = Field(default="GigaChat")
    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(default=1024, ge=1, le=4096)


# -- Routes --------------------------------------------------------------------

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
    """Diagnostic: tests cert bundle, OAuth, and a one-sentence chat ping."""
    result: dict[str, object] = {"timestamp": datetime.now(timezone.utc).isoformat()}

    # 1. Cert bundle
    cv = _validate_cert_bundle()
    result["cert_bundle_present"] = cv["present"]
    result["cert_bundle_valid"] = cv["valid"]
    result["cert_count"] = cv["cert_count"]
    result["first_100_chars_safe"] = cv["first_100_chars_safe"]
    if cv["error"]:
        result["cert_bundle_error"] = cv["error"]

    if cv["valid"]:
        try:
            from cryptography import x509 as _x509
            text = CERT_BUNDLE.read_text(errors="replace")
            subjects = []
            for chunk in text.split("-----BEGIN CERTIFICATE-----")[1:]:
                pem_block = "-----BEGIN CERTIFICATE-----" + chunk.split("-----END CERTIFICATE-----")[0] + "-----END CERTIFICATE-----"
                try:
                    cert = _x509.load_pem_x509_certificate(pem_block.encode())
                    subjects.append(cert.subject.rfc4514_string())
                except Exception:
                    pass
            result["cert_subjects"] = subjects
        except ImportError:
            result["cert_subjects"] = ["(cryptography package not installed)"]

    # 2. Auth key diagnostics
    raw_key = os.environ.get("GIGACHAT_AUTH_KEY", "")
    result["has_auth_key"] = bool(raw_key)
    result["key_raw_len"] = len(raw_key)
    if raw_key:
        stripped = raw_key.strip()
        result["key_has_whitespace"] = stripped != raw_key
        result["key_stripped_len"] = len(stripped)
        result["key_hint"] = raw_key[:4] + "..." + raw_key[-4:]
    else:
        result["env_keys_with_giga"] = [k for k in os.environ if "GIGA" in k.upper()]
        result["env_keys_with_auth"] = [k for k in os.environ if "AUTH" in k.upper()]

    scope_val = os.environ.get("GIGACHAT_SCOPE", "")
    result["has_scope"] = bool(scope_val)
    result["scope_value"] = scope_val or "(not set)"

    # 3. Gate OAuth behind cert validation
    if not cv["valid"]:
        result["oauth_ok"] = False
        result["oauth_error"] = (
            "Cert bundle is not valid -- refusing OAuth to protect TLS integrity. "
            f"cert_bundle_error={cv.get('error', 'unknown')}"
        )
        return JSONResponse(content=result)

    # 4. OAuth
    try:
        token = await _get_access_token()
        result["oauth_ok"] = True
        result["token_length"] = len(token)
    except HTTPException as exc:
        result["oauth_ok"] = False
        detail = exc.detail
        if isinstance(detail, dict):
            result["oauth_error"] = detail.get("error", "unknown")
            result["oauth_status"] = detail.get("oauth_status")
            result["oauth_response_body"] = detail.get("oauth_response_body")
            result["auth_key_len"] = detail.get("auth_key_len")
            result["auth_key_looks_base64"] = detail.get("auth_key_looks_base64")
            result["scope_used"] = detail.get("scope")
            result["rq_uid_is_uuid"] = detail.get("rq_uid_is_uuid")
        else:
            result["oauth_error"] = str(detail)
        return JSONResponse(content=result)
    except Exception as exc:
        result["oauth_ok"] = False
        result["oauth_error"] = str(exc)
        return JSONResponse(content=result)

    # 5. Chat ping
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
    Main proxy endpoint -- called by the iOS app.
    Requires no secrets in the mobile app; GIGACHAT_AUTH_KEY lives only here.
    """
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
