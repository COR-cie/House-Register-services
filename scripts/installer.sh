#!/bin/sh
# Installation guidée de Registre Foncier sur ce serveur.
set -e
cd "$(dirname "$0")/.."

command -v docker >/dev/null 2>&1 || {
  echo "✗ Docker est requis. Installez Docker Engine puis relancez."
  exit 1
}
docker compose version >/dev/null 2>&1 || {
  echo "✗ Le plugin Docker Compose v2 est requis (docker compose …)."
  exit 1
}

if [ ! -f .env ]; then
  cp .env.example .env
  echo "→ Fichier .env créé depuis .env.example."
  echo "  ÉDITEZ .env (SECRET_KEY, mots de passe, CORS_ORIGINS…) PUIS relancez ce script."
  exit 1
fi

if [ ! -f certs/fullchain.pem ] || [ ! -f certs/privkey.pem ]; then
  echo "→ Aucun certificat TLS trouvé dans certs/. Génération d'un certificat auto-signé (test)…"
  sh scripts/generer-certs.sh
  echo "  En production, remplacez certs/ par un certificat de confiance."
fi

echo "→ Récupération des images officielles…"
docker compose pull
echo "→ Démarrage des services…"
docker compose up -d

echo ""
echo "✓ Registre Foncier est déployé."
echo "  Vérifiez :  curl -k https://localhost/api/health   → {\"status\":\"ok\",...}"
echo "  Puis ouvrez https://<votre-domaine>/ et connectez-vous avec le compte administrateur"
echo "  défini dans .env. CHANGEZ son mot de passe après la première connexion."
