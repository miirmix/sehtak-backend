# Russian CA Certificate Bundle

This folder must contain `russian_ca_bundle.pem` — a combined PEM of the two
Russian Trusted Root CA certificates issued by the Ministry of Digital Development (Минцифры).

## How to create the bundle

```bash
# Download from official Gosuslugi source
wget https://gu-st.ru/content/Other/doc/russian_trusted_root_ca.cer
wget https://gu-st.ru/content/Other/doc/russian_trusted_sub_ca.cer

# Convert DER → PEM (the .cer files are DER-encoded)
openssl x509 -inform DER -in russian_trusted_root_ca.cer -out russian_trusted_root_ca.pem
openssl x509 -inform DER -in russian_trusted_sub_ca.cer  -out russian_trusted_sub_ca.pem

# Concatenate into a single bundle
cat russian_trusted_root_ca.pem russian_trusted_sub_ca.pem > russian_ca_bundle.pem

# Verify the bundle (optional)
openssl verify -CAfile russian_ca_bundle.pem russian_trusted_sub_ca.pem
```

After running the above, copy `russian_ca_bundle.pem` into this `certs/` folder.

## Certificate validity (as of 2025)
| File                      | Valid until  |
|---------------------------|--------------|
| russian_trusted_root_ca   | 2032-02-27   |
| russian_trusted_sub_ca    | 2027-03-06   |

## Security note
These certificates are ONLY used server-side (Python httpx) to validate that the
server at `ngw.devices.sberbank.ru` is genuine. TLS is always enforced — we never
set `verify=False`.

The bundle is committed to source control because it is a **public root CA** —
not a secret. The `GIGACHAT_AUTH_KEY` is never stored here.
