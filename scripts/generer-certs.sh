#!/bin/sh
# Génère un certificat TLS AUTO-SIGNÉ (pour tester). En production, remplacez
# certs/fullchain.pem et certs/privkey.pem par un certificat d'une autorité de
# confiance (Let's Encrypt, PKI de l'administration…).
#
# Usage : sh scripts/generer-certs.sh [nom-de-domaine]
set -e

DOMAINE="${1:-registre.local}"
DEST="$(dirname "$0")/../certs"
mkdir -p "$DEST"

echo "→ Certificat auto-signé pour : $DOMAINE (test uniquement)"
openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
  -keyout "$DEST/privkey.pem" \
  -out "$DEST/fullchain.pem" \
  -subj "/C=CG/O=Republique du Congo/CN=$DOMAINE" \
  -addext "subjectAltName=DNS:$DOMAINE,DNS:localhost,IP:127.0.0.1"

chmod 600 "$DEST/privkey.pem" 2>/dev/null || true
echo "✓ Écrit : certs/fullchain.pem et certs/privkey.pem"
echo "  (Un certificat auto-signé déclenchera un avertissement navigateur : normal en test.)"
