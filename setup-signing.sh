#!/usr/bin/env bash
#
# Create a self-signed Code Signing certificate for local development.
#
# This certificate gives codesign a stable identity so that macOS TCC
# permissions (e.g., Accessibility) persist across rebuilds.
#
# Usage:
#   ./setup-signing.sh
#
# Run once per machine. Re-running is safe — it skips if the cert exists.

set -euo pipefail

CERT_CN="ClickEffect Dev"
CERT_DAYS=3650
KEY_SIZE=2048

# --- Check if identity already exists ---
if security find-identity -v -p codesigning 2>/dev/null | grep -q "${CERT_CN}"; then
    echo "Code signing identity '${CERT_CN}' already exists:"
    echo ""
    security find-identity -v -p codesigning | grep "${CERT_CN}"
    exit 0
fi

echo "==> Creating self-signed code signing certificate: '${CERT_CN}'"

TMPDIR_CERT="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_CERT}"' EXIT

OPENSSL_CNF="${TMPDIR_CERT}/codesign.cnf"
KEY_FILE="${TMPDIR_CERT}/key.pem"
CERT_FILE="${TMPDIR_CERT}/cert.pem"
P12_FILE="${TMPDIR_CERT}/codesign.p12"
# Temporary passphrase for the PKCS12 bundle. This is only used during
# the import and the .p12 file is deleted immediately after (via trap).
# Not a secret — safe to have in source.
P12_PASS="clickeffect-tmp"

# --- OpenSSL config with Code Signing EKU ---
cat > "${OPENSSL_CNF}" <<CNFEOF
[req]
default_bits       = ${KEY_SIZE}
distinguished_name = req_dn
x509_extensions    = codesign_ext
prompt             = no

[req_dn]
CN = ${CERT_CN}

[codesign_ext]
keyUsage               = critical, digitalSignature
extendedKeyUsage       = critical, codeSigning
basicConstraints       = critical, CA:false
subjectKeyIdentifier   = hash
CNFEOF

# --- Generate key + self-signed certificate ---
echo "==> Generating RSA key and self-signed certificate (valid ${CERT_DAYS} days)"
openssl req -x509 -newkey "rsa:${KEY_SIZE}" -nodes \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -days "${CERT_DAYS}" \
    -config "${OPENSSL_CNF}" 2>/dev/null

# --- Package as PKCS12 ---
echo "==> Packaging as PKCS12"
PKCS12_FLAGS=()
if openssl version 2>/dev/null | grep -q "^OpenSSL 3"; then
    PKCS12_FLAGS+=("-legacy")
fi
openssl pkcs12 -export \
    -inkey "${KEY_FILE}" \
    -in "${CERT_FILE}" \
    -out "${P12_FILE}" \
    -passout "pass:${P12_PASS}" \
    -name "${CERT_CN}" \
    "${PKCS12_FLAGS[@]+"${PKCS12_FLAGS[@]}"}"

# --- Import into login keychain ---
LOGIN_KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"
echo "==> Importing into login keychain"
security import "${P12_FILE}" \
    -k "${LOGIN_KEYCHAIN}" \
    -t agg \
    -f pkcs12 \
    -P "${P12_PASS}" \
    -T /usr/bin/codesign \
    -T /usr/bin/security

# --- Trust the certificate for code signing (user-level, no sudo) ---
echo "==> Setting certificate as trusted for code signing"
security add-trusted-cert \
    -p codeSign \
    -r trustRoot \
    -k "${LOGIN_KEYCHAIN}" \
    "${CERT_FILE}"

# --- Allow codesign to use the key without GUI prompt ---
echo "==> Updating key partition list"
security set-key-partition-list \
    -S "apple-tool:,apple:,codesign:" \
    -k "" \
    "${LOGIN_KEYCHAIN}" 2>/dev/null || {
    echo "  Note: If signing prompts for a password later, run:"
    echo "  security set-key-partition-list -S 'apple-tool:,apple:,codesign:' -k '<password>' ~/Library/Keychains/login.keychain-db"
}

echo ""
if security find-identity -v -p codesigning | grep -q "${CERT_CN}"; then
    echo "Done. Certificate '${CERT_CN}' is ready."
    echo "Run ./build-app.sh — it will use this identity automatically."
else
    echo "WARNING: Certificate was imported but not found as a valid code signing identity."
    echo "You may need to open Keychain Access and manually trust the certificate."
    exit 1
fi
