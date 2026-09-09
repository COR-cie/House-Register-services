#!/bin/sh
# Sauvegarde COMPLÈTE de la base (structure + données), horodatée et compressée.
# ⚠️ Contient des données personnelles : stockez-la de façon sécurisée.
# Pensez à sauvegarder AUSSI le volume des pièces jointes (media) et à conserver
# SECRET_KEY (sans elle, les pièces chiffrées sont illisibles).
set -e
cd "$(dirname "$0")/.."

BASE="$(grep -E '^POSTGRES_DB=' .env 2>/dev/null | cut -d= -f2)"
UTIL="$(grep -E '^POSTGRES_USER=' .env 2>/dev/null | cut -d= -f2)"
BASE="${BASE:-registre_foncier}"
UTIL="${UTIL:-registre}"

DEST="sauvegardes"
mkdir -p "$DEST"
FICHIER="$DEST/${BASE}_$(date +%Y%m%d-%H%M%S).sql.gz"

echo "→ Sauvegarde de « $BASE »…"
docker compose exec -T db pg_dump -U "$UTIL" -d "$BASE" --no-owner --no-privileges | gzip > "$FICHIER"
echo "✓ Écrit : $FICHIER"
