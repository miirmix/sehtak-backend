#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# download_certs.sh
# Downloads Russian Trusted Root CA and Sub CA from the official Gosuslugi URL,
# converts from DER to PEM, and concatenates into russian_ca_bundle.pem.
# Run once locally before deploying, OR as a Railway/Render build step.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ROOT_URL="https://gu-st.ru/content/Other/doc/russian_trusted_root_ca.cer"
SUB_URL="https://gu-st.ru/content/Other/doc/russian_trusted_sub_ca.cer"

echo "→ Downloading russian_trusted_root_ca.cer …"
curl -sSL -o russian_trusted_root_ca.cer "$ROOT_URL"

echo "→ Downloading russian_trusted_sub_ca.cer …"
curl -sSL -o russian_trusted_sub_ca.cer "$SUB_URL"

echo "→ Converting DER → PEM …"
openssl x509 -inform DER -in russian_trusted_root_ca.cer -out russian_trusted_root_ca.pem
openssl x509 -inform DER -in russian_trusted_sub_ca.cer  -out russian_trusted_sub_ca.pem

echo "→ Creating bundle …"
cat russian_trusted_root_ca.pem russian_trusted_sub_ca.pem > russian_ca_bundle.pem

echo "→ Verifying …"
openssl verify -CAfile russian_ca_bundle.pem russian_trusted_sub_ca.pem

echo "✅ russian_ca_bundle.pem created successfully."
ls -lh russian_ca_bundle.pem
