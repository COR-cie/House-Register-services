# Registre Foncier — Installation & intégration

Kit de **déploiement** de la plateforme **Registre Foncier** (République du Congo),
destiné aux organisations qui l'exploitent. Ce dépôt **ne contient pas le code
source** : il déploie les **images officielles** publiées par CORAF & Cie et se met à
jour à chaque nouvelle version.

> Édité par **CORAF & Cie**. Le code source est privé ; l'assistance et les nouvelles
> versions sont fournies par l'éditeur.

> 📘 **Déploiement complet (données privées, du début à la fin) :** voir
> [GUIDE-DEPLOIEMENT.md](GUIDE-DEPLOIEMENT.md). Ce README en est la version express.

---

## 1. Ce que fait ce kit

- Déploie 3 services avec Docker : **base PostgreSQL**, **API** (backend) et **serveur
  web/Nginx** (TLS + interface).
- Les **migrations de base** et la **création du compte administrateur** sont
  automatiques au démarrage.
- **Toujours à jour** : les images sont reconstruites et republiées à chaque
  modification/nouveauté de la plateforme ; une simple commande récupère la dernière
  version (voir § Mise à jour).

## 2. Prérequis

- Un serveur Linux (ou Windows Server) avec **Docker Engine** + **Docker Compose v2**.
- Les **ports 80 et 443** libres.
- Un **certificat TLS** (recommandé : autorité de confiance ou PKI de l'État). Un
  certificat auto-signé suffit pour un test.
- Un accès en lecture aux images (voir § 3).

## 3. Accès aux images

Les images sont hébergées sur **GitHub Container Registry** :

- `ghcr.io/cor-cie/house-register-backend`
- `ghcr.io/cor-cie/house-register-web`

Si les images sont **privées**, connectez Docker une fois avec un jeton fourni par
CORAF & Cie (droit `read:packages`) :

```bash
echo <VOTRE_JETON> | docker login ghcr.io -u <votre-utilisateur> --password-stdin
```

*(Si CORAF & Cie a rendu les images publiques, cette étape est inutile.)*

## 4. Installation

```bash
git clone https://github.com/COR-cie/House-Register-services.git
cd House-Register-services

# 1) Configuration
cp .env.example .env
#    Éditez .env : SECRET_KEY (openssl rand -hex 32), mots de passe, CORS_ORIGINS…

# 2) Certificat TLS
#    Test : sh scripts/generer-certs.sh registre.exemple.cg
#    Production : placez vos fichiers dans certs/fullchain.pem et certs/privkey.pem

# 3) Démarrage (récupère les images puis lance les services)
sh scripts/installer.sh
```

`installer.sh` vérifie Docker, crée `.env` si besoin, génère un certificat de test si
`certs/` est vide, puis fait `docker compose pull` et `docker compose up -d`.

## 5. Vérification

```bash
curl -k https://localhost/api/health      # -> {"status":"ok","env":"production"}
```

Ouvrez ensuite `https://<votre-domaine>/` et connectez-vous avec le compte
administrateur défini dans `.env`. **Changez son mot de passe** après la première
connexion.

## 6. Mise à jour (rester à la dernière version)

```bash
sh scripts/sauvegarde.sh        # recommandé avant toute mise à jour
sh scripts/mettre-a-jour.sh     # docker compose pull + up -d
```

La ligne d'images est choisie par `IMAGE_TAG` dans `.env` :

| `IMAGE_TAG` | Usage |
|-------------|-------|
| `latest`    | Version **stable** (production) — par défaut |
| `stage`     | Pré-production (test des nouveautés en avance) |

## 7. Sauvegarde & restauration

```bash
# Sauvegarde complète (base) horodatée -> sauvegardes/
sh scripts/sauvegarde.sh
```

> ⚠️ Sauvegardez **aussi** le volume des pièces jointes (`media`) et conservez
> **`SECRET_KEY`** : sans elle, les pièces chiffrées deviennent illisibles.

Restauration (exemple depuis un dump SQL compressé) :

```bash
gunzip -c sauvegardes/registre_foncier_AAAAMMJJ-HHMMSS.sql.gz \
  | docker compose exec -T db psql -U registre -d registre_foncier
```

## 8. Exploitation

```bash
docker compose ps               # état des services
docker compose logs -f          # journaux en direct
docker compose down             # arrêt (conserve les données)
docker compose up -d            # redémarrage
```

Les données persistent dans les volumes Docker `pgdata` (base) et `media` (pièces).

## 9. Sécurité & souveraineté

- Déploiement **sur site** : les serveurs et les données restent chez vous.
- Pièces **chiffrées au repos** ; l'État détient les données **et la clé**
  (`SECRET_KEY`).
- Ne partagez jamais `.env` ni `certs/` (ignorés par Git dans ce dépôt).

## 10. Dépannage

| Symptôme | Piste |
|---|---|
| `pull access denied` sur ghcr.io | Faites `docker login ghcr.io` (§ 3). |
| Le web ne répond pas sur 443 | Vérifiez `certs/fullchain.pem` et `certs/privkey.pem`, puis `docker compose logs web`. |
| `POSTGRES_PASSWORD` manquant | Renseignez-le dans `.env`. |
| Après mise à jour, erreur au démarrage | `docker compose logs backend` (migrations). Restaurez la sauvegarde si nécessaire. |

---

**Support :** CORAF & Cie — Registre Foncier.
