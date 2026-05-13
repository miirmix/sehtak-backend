#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# download_certs.sh  v3
#
# Builds russian_ca_bundle.pem from Russian Trusted Root CA + Sub CA.
# Uses Python (guaranteed in the Railway/Render build env) for all
# download and DER→PEM conversion work — avoids every shell/openssl quirk.
#
# If the bundle is already present and valid (committed to the repo),
# this script validates it and exits 0 without re-downloading.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log()  { echo "[certs] $*"; }
info() { echo "[certs] ✅ $*"; }
warn() { echo "[certs] ⚠️  $*"; }
fail() { echo "[certs] ❌ ERROR: $*" >&2; exit 1; }

BUNDLE="russian_ca_bundle.pem"

# ──────────────────────────────────────────────────────────────────────────────
# If a pre-committed bundle exists, validate it and exit early.
# ──────────────────────────────────────────────────────────────────────────────
if [ -f "$BUNDLE" ]; then
    COUNT=$(grep -c "BEGIN CERTIFICATE" "$BUNDLE" 2>/dev/null || echo "0")
    if [ "$COUNT" -ge 2 ]; then
        info "Pre-committed $BUNDLE found with $COUNT certificate(s) — skipping download."
        python3 -c "
import ssl, os
ctx = ssl.create_default_context()
try:
    ctx.load_verify_locations('$BUNDLE')
    print('[certs] ✅ Python ssl.create_default_context validated bundle OK')
except Exception as e:
    print(f'[certs] ❌ Python ssl validation failed: {e}')
    exit(1)
"
        exit 0
    else
        warn "Existing $BUNDLE has only $COUNT cert(s) — will re-download."
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# Download and convert via Python — handles DER/PEM transparently.
# ──────────────────────────────────────────────────────────────────────────────
log "=== Russian Trusted CA bundle builder v3 ==="
log "Working directory: $SCRIPT_DIR"

python3 - << 'PYEOF'
import sys
import ssl
import urllib.request
import urllib.error
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent if "__file__" in dir() else Path(".")

# Certificate sources: (label, [url1, url2, ...])
CERT_SOURCES = [
    (
        "Russian Trusted Root CA",
        [
            "https://gu-st.ru/content/Other/doc/russian_trusted_root_ca.cer",
            "https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt",
            "https://www.gosuslugi.ru/crt/russian_trusted_root_ca.cer",
        ],
    ),
    (
        "Russian Trusted Sub CA",
        [
            "https://gu-st.ru/content/Other/doc/russian_trusted_sub_ca.cer",
            "https://gu-st.ru/content/lending/russian_trusted_sub_ca_pem.crt",
            "https://www.gosuslugi.ru/crt/russian_trusted_sub_ca.cer",
        ],
    ),
]

def log(msg):   print(f"[certs] {msg}", flush=True)
def info(msg):  print(f"[certs] ✅ {msg}", flush=True)
def warn(msg):  print(f"[certs] ⚠️  {msg}", flush=True)
def error(msg): print(f"[certs] ❌ ERROR: {msg}", file=sys.stderr, flush=True)

def download(url: str, timeout: int = 30) -> bytes:
    """Download URL, no SSL verify needed for CA cert download itself."""
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (compatible; cert-downloader/3.0)"},
    )
    with urllib.request.urlopen(req, timeout=timeout, context=ctx) as r:
        return r.read()

def to_pem(data: bytes, label: str) -> str:
    """Convert DER or PEM bytes to a clean PEM string."""
    from cryptography import x509
    from cryptography.hazmat.primitives import serialization

    # Try PEM first (already ASCII-armored)
    if b"BEGIN CERTIFICATE" in data:
        log(f"{label}: detected PEM format")
        # Validate by parsing
        try:
            cert = x509.load_pem_x509_certificate(data)
            pem_str = cert.public_bytes(serialization.Encoding.PEM).decode()
            log(f"{label}: subject = {cert.subject.rfc4514_string()}")
            log(f"{label}: not_before = {cert.not_valid_before_utc}")
            log(f"{label}: not_after  = {cert.not_valid_after_utc}")
            return pem_str
        except Exception as e:
            warn(f"{label}: PEM parse failed ({e}), trying DER ...")

    # Try DER
    try:
        cert = x509.load_der_x509_certificate(data)
        pem_str = cert.public_bytes(serialization.Encoding.PEM).decode()
        log(f"{label}: detected DER format — converted to PEM")
        log(f"{label}: subject = {cert.subject.rfc4514_string()}")
        log(f"{label}: not_before = {cert.not_valid_before_utc}")
        log(f"{label}: not_after  = {cert.not_valid_after_utc}")
        return pem_str
    except Exception as e:
        raise ValueError(f"Cannot parse {label} as DER or PEM: {e}")

# Check if cryptography package is available; install if missing
try:
    from cryptography import x509
    from cryptography.hazmat.primitives import serialization
except ImportError:
    log("cryptography package not installed — installing ...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "cryptography", "-q"])
    from cryptography import x509
    from cryptography.hazmat.primitives import serialization

pem_parts = []

for label, urls in CERT_SOURCES:
    data = None
    for url in urls:
        log(f"Trying {url} ...")
        try:
            data = download(url)
            if len(data) < 100:
                warn(f"Response too small ({len(data)} bytes) — skipping")
                data = None
                continue
            if data[:1] in (b"<", b"{"):
                warn(f"Response looks like HTML/JSON ({data[:40]!r}) — skipping")
                data = None
                continue
            info(f"{label}: downloaded {len(data)} bytes from {url}")
            break
        except Exception as e:
            warn(f"Download failed: {e}")
            data = None

    if data is None:
        error(f"All URLs failed for {label}.")
        sys.exit(1)

    try:
        pem_str = to_pem(data, label)
        pem_parts.append((label, pem_str))
        info(f"{label}: converted to PEM OK")
    except Exception as e:
        error(f"PEM conversion failed for {label}: {e}")
        sys.exit(1)

# Write bundle
bundle_path = Path("russian_ca_bundle.pem")
with open(bundle_path, "w") as f:
    for label, pem_str in pem_parts:
        f.write(f"# {label}\n")
        f.write(pem_str)
        f.write("\n")

cert_count = bundle_path.read_text().count("BEGIN CERTIFICATE")
info(f"Bundle written: {bundle_path} ({bundle_path.stat().st_size} bytes, {cert_count} certs)")

# Final Python SSL validation
import ssl as ssl_mod
ctx = ssl_mod.create_default_context()
try:
    ctx.load_verify_locations(str(bundle_path))
    info("Python ssl.create_default_context() validated bundle — READY")
except Exception as e:
    error(f"Python ssl validation failed: {e}")
    sys.exit(1)

print("[certs] === Done ===", flush=True)
PYEOF
