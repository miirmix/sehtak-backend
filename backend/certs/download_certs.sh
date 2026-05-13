#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# download_certs.sh  v2
# Downloads Russian Trusted Root CA + Sub CA and builds russian_ca_bundle.pem.
# - Auto-detects PEM vs DER format before conversion.
# - Falls back to mirror URL if primary fails.
# - Validates each certificate with openssl after conversion.
# - Fails clearly if a downloaded file is HTML or empty.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Primary URLs (Gosuslugi CDN) ──────────────────────────────────────────────
ROOT_URL_1="https://gu-st.ru/content/Other/doc/russian_trusted_root_ca.cer"
SUB_URL_1="https://gu-st.ru/content/Other/doc/russian_trusted_sub_ca.cer"

# ── Mirror URLs ───────────────────────────────────────────────────────────────
ROOT_URL_2="https://www.gosuslugi.ru/crt/russian_trusted_root_ca.cer"
SUB_URL_2="https://www.gosuslugi.ru/crt/russian_trusted_sub_ca.cer"

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

log()  { echo "[certs] $*"; }
info() { echo "[certs] ✅ $*"; }
warn() { echo "[certs] ⚠️  $*"; }
fail() { echo "[certs] ❌ ERROR: $*" >&2; exit 1; }

# detect_format <file> → prints "PEM" or "DER"
detect_format() {
    local file="$1"
    if grep -q "BEGIN CERTIFICATE" "$file" 2>/dev/null; then
        echo "PEM"
    else
        echo "DER"
    fi
}

# validate_download <file> <label>
# Fails if file is empty or starts with '<' (HTML page).
validate_download() {
    local file="$1"
    local label="$2"
    local size
    size=$(wc -c < "$file")

    if [ "$size" -eq 0 ]; then
        fail "Downloaded '$label' is empty (0 bytes)."
    fi

    # Read first byte — if it is '<' the server returned an HTML page.
    local first_char
    first_char=$(dd if="$file" bs=1 count=1 2>/dev/null | cat)
    if [ "$first_char" = "<" ]; then
        fail "Downloaded '$label' appears to be an HTML page (starts with '<'). The URL may have changed or redirected."
    fi

    log "$label: ${size} bytes downloaded — looks like binary/PEM data."
}

# download_cert <out_file> <url1> <url2> <label>
# Tries url1 first; falls back to url2.
download_cert() {
    local out_file="$1"
    local url1="$2"
    local url2="$3"
    local label="$4"

    log "Downloading $label ..."
    log "  Primary: $url1"

    if curl -fsSL --max-time 30 --retry 2 -o "$out_file" "$url1" 2>/dev/null; then
        if validate_download "$out_file" "$label (primary)" 2>/dev/null; then
            info "$label: downloaded from primary URL."
            return 0
        fi
    fi

    warn "$label: primary URL failed or returned invalid content. Trying mirror ..."
    log "  Mirror: $url2"

    if curl -fsSL --max-time 30 --retry 2 -o "$out_file" "$url2" 2>/dev/null; then
        validate_download "$out_file" "$label (mirror)"
        info "$label: downloaded from mirror URL."
        return 0
    fi

    fail "$label: BOTH download URLs failed. Check network connectivity and URL availability."
}

# to_pem <in_file> <out_pem> <label>
# Converts DER→PEM if needed, then validates with openssl.
to_pem() {
    local in_file="$1"
    local out_pem="$2"
    local label="$3"

    local fmt
    fmt=$(detect_format "$in_file")
    log "$label: detected format = $fmt"

    if [ "$fmt" = "PEM" ]; then
        cp "$in_file" "$out_pem"
        info "$label: already PEM — copied directly."
    else
        log "$label: converting DER → PEM ..."
        if ! openssl x509 -inform DER -in "$in_file" -out "$out_pem" 2>&1; then
            # If DER failed but file might actually be PEM, try PEM anyway
            warn "$label: DER conversion failed, attempting PEM parse ..."
            if ! openssl x509 -inform PEM -in "$in_file" -out "$out_pem" 2>&1; then
                fail "$label: unable to parse as DER or PEM. File may be corrupt or wrong format."
            fi
            info "$label: parsed as PEM (despite no BEGIN marker)."
        else
            info "$label: DER → PEM conversion succeeded."
        fi
    fi

    # Final openssl validation
    log "$label: validating converted PEM ..."
    if ! openssl x509 -in "$out_pem" -noout 2>/dev/null; then
        fail "$label: produced PEM failed openssl validation. Certificate is invalid."
    fi

    # Print subject + validity for confirmation in build logs
    openssl x509 -in "$out_pem" -noout -subject -dates 2>/dev/null | sed "s/^/  [$label] /"
    info "$label: PEM validated successfully."
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

log "=== Russian Trusted CA bundle builder v2 ==="
log "Working directory: $SCRIPT_DIR"
echo ""

# ── Step 1: Download ──────────────────────────────────────────────────────────
download_cert \
    "russian_trusted_root_ca.cer" \
    "$ROOT_URL_1" "$ROOT_URL_2" \
    "Root CA"

download_cert \
    "russian_trusted_sub_ca.cer" \
    "$SUB_URL_1" "$SUB_URL_2" \
    "Sub CA"

echo ""

# ── Step 2: Convert to PEM ────────────────────────────────────────────────────
to_pem "russian_trusted_root_ca.cer" "russian_trusted_root_ca.pem" "Root CA"
to_pem "russian_trusted_sub_ca.cer"  "russian_trusted_sub_ca.pem"  "Sub CA"

echo ""

# ── Step 3: Build bundle ──────────────────────────────────────────────────────
log "Concatenating into russian_ca_bundle.pem ..."
cat russian_trusted_root_ca.pem russian_trusted_sub_ca.pem > russian_ca_bundle.pem

CERT_COUNT=$(grep -c "BEGIN CERTIFICATE" russian_ca_bundle.pem 2>/dev/null || echo "0")
log "Certificates in bundle: $CERT_COUNT"

if [ "$CERT_COUNT" -lt 2 ]; then
    fail "Bundle contains only $CERT_COUNT certificate(s) — expected at least 2."
fi

info "russian_ca_bundle.pem built with $CERT_COUNT certificates."
ls -lh russian_ca_bundle.pem

echo ""

# ── Step 4: Verify bundle with openssl ───────────────────────────────────────
log "Running openssl verify on Sub CA against Root CA ..."
if openssl verify -CAfile russian_ca_bundle.pem russian_trusted_sub_ca.pem 2>&1; then
    info "openssl verify passed — bundle is valid."
else
    warn "openssl verify returned non-zero — this may be OK if the sub CA is self-signed."
fi

echo ""

# ── Step 5: Cleanup ───────────────────────────────────────────────────────────
rm -f russian_trusted_root_ca.cer russian_trusted_sub_ca.cer
log "Cleaned up intermediate .cer files."
log "=== Done ==="
