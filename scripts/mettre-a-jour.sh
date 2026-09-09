#!/bin/sh
# Met Registre Foncier à jour vers la dernière version publiée.
# Les migrations de base de données sont appliquées automatiquement au démarrage.
set -e
cd "$(dirname "$0")/.."

echo "→ Conseil : faites une sauvegarde avant (sh scripts/sauvegarde.sh)."
echo "→ Récupération des dernières images…"
docker compose pull
echo "→ Redémarrage des services…"
docker compose up -d
docker image prune -f >/dev/null 2>&1 || true

echo "✓ Mise à jour terminée."
echo "  Vérifiez :  curl -k https://localhost/api/health"
