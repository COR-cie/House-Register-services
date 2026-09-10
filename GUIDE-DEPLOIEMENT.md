# Guide de déploiement — Registre Foncier

**Déployer la plateforme sur site, avec des données privées et souveraines — du serveur vierge à la mise en service.**

Ce guide s'adresse à l'**équipe technique d'une organisation** (administration, entreprise) qui exploite Registre Foncier sur sa propre infrastructure. Il détaille tout le cycle : préparation du serveur, configuration, mise en service, exploitation et maintenance.

> Pour une installation express, voir le [README](README.md). Ce guide en est la version complète, orientée **données privées / on-premise**.

---

## 0. Principe : des données privées, chez vous, chiffrées

Registre Foncier se déploie **sur les serveurs de l'organisation**. Aucune donnée ne part vers un cloud tiers.

- **Souveraineté** — la base et les pièces justificatives restent sur votre infrastructure.
- **Chiffrement au repos** des pièces jointes ; la clé (`SECRET_KEY`) est **détenue par vous seul**.
- **Accès par rôle** (agent / superviseur / administrateur) et **journal d'audit** inaltérable.
- **Sans code source** — ce déploiement tire les **images officielles** publiées par CORAF & Cie et se met à jour à chaque nouvelle version.

> ⚠️ **Règle d'or.** Générez `SECRET_KEY` une seule fois et conservez-la en lieu sûr. Sans elle, les pièces déjà chiffrées deviennent **illisibles**. Ne la modifiez **jamais** après la première mise en service.

---

## 1. Prérequis

| Élément | Recommandation |
|---|---|
| **Serveur** | Linux (Ubuntu Server 22.04+ conseillé) — 2 vCPU, 4 Go RAM, 40 Go disque pour démarrer ; prévoir davantage selon le volume de pièces. |
| **Logiciels** | **Docker Engine** + plugin **Docker Compose v2**. |
| **Réseau** | Ports **80** et **443** libres ; un nom (DNS interne, ex. `registre.mon-organisation.cg`). |
| **TLS** | Un certificat (PKI de l'organisation ou autorité de confiance). Auto-signé accepté pour un test. |
| **Accès images** | Un jeton de lecture GHCR fourni par CORAF & Cie (si les images sont privées). |

---

## 2. Étape 1 — Préparer le serveur

Sur un serveur Ubuntu à jour, installez Docker puis vérifiez :

```bash
# Installation de Docker (méthode officielle)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # puis reconnectez-vous
docker --version && docker compose version
```

Restreignez l'accès réseau : n'exposez le service qu'au réseau interne de l'organisation.

```bash
# Exemple avec ufw : autoriser 80/443, refuser le reste par défaut
sudo ufw allow 80,443/tcp
sudo ufw enable
```

---

## 3. Étape 2 — Récupérer le kit & les images

Le kit ne contient **pas** le code source : c'est un `docker-compose.yml` qui tire les images officielles.

```bash
git clone https://github.com/COR-cie/House-Register-services.git
cd House-Register-services
```

Si les images sont **privées**, connectez Docker à GHCR avec le jeton fourni (droit `read:packages`) :

```bash
echo <JETON> | docker login ghcr.io -u <utilisateur> --password-stdin
```

Les images sont `ghcr.io/cor-cie/house-register-backend` et `…-web`. Elles sont republiées à chaque évolution de la plateforme ; la mise à jour se fait plus tard en une commande.

---

## 4. Étape 3 — Configurer (`.env`)

```bash
cp .env.example .env
openssl rand -hex 32        # génère une SECRET_KEY — copiez-la dans .env
nano .env
```

Renseignez au minimum :

| Variable | Rôle |
|---|---|
| `SECRET_KEY` | Clé JWT + chiffrement des pièces. **À ne jamais changer** ensuite. |
| `POSTGRES_PASSWORD` | Mot de passe fort de la base. |
| `FIRST_ADMIN_IDENTIFIANT` / `FIRST_ADMIN_PASSWORD` | Compte administrateur initial (créé au 1er démarrage). |
| `CORS_ORIGINS` | URL publique/interne, ex. `https://registre.mon-organisation.cg`. |
| `IMAGE_TAG` | `latest` (stable) ou `stage` (pré-production). |
| `MAX_UPLOAD_MB` | Taille max d'une pièce jointe. |

> ⚠️ **Confidentialité.** Le fichier `.env` contient des secrets : droits `600`, jamais versionné, jamais partagé par messagerie en clair.
>
> ```bash
> chmod 600 .env
> ```

---

## 5. Étape 4 — Certificat TLS (HTTPS obligatoire)

**Production** — placez les fichiers de votre autorité de confiance :

```
certs/fullchain.pem   # certificat + chaîne
certs/privkey.pem     # clé privée (droits 600)
```

**Test uniquement** — un certificat auto-signé :

```bash
sh scripts/generer-certs.sh registre.mon-organisation.cg
```

---

## 6. Étape 5 — Démarrer

```bash
sh scripts/installer.sh
# équivaut à : docker compose pull && docker compose up -d
```

Au premier démarrage, le backend applique automatiquement les **migrations de base** et crée le **compte administrateur** défini dans `.env`.

---

## 7. Étape 6 — Vérifier

```bash
curl -k https://localhost/api/health   # -> {"status":"ok","env":"production"}
docker compose ps                       # les 3 services "Up"
```

Ouvrez `https://<votre-domaine>/`, connectez-vous en administrateur, puis **changez immédiatement le mot de passe administrateur**.

---

## 8. Étape 7 — Paramétrer pour l'organisation

Dans l'interface (menu **Administration**), aucune ligne de commande :

- **Utilisateurs & rôles** — créez les comptes agents, superviseurs, administrateurs.
- **Zones** et **types de pièces** — adaptez les référentiels au territoire.
- **Apparence** — nom de l'application, couleurs, logo de l'organisation.

---

## 9. Étape 8 — Reprise des données existantes (le cas échéant)

Deux voies selon le volume :

- **Saisie assistée** — les agents enregistrent les dossiers papier via la plateforme (numérisation des pièces incluse).
- **Reprise encadrée** — pour un gros volume, CORAF & Cie accompagne une reprise structurée au périmètre convenu.

> ⚠️ **Données personnelles.** N'importez que les données nécessaires, sur le réseau interne, avec les accès restreints.

---

## 10. Confidentialité des données privées

| Mesure | Mise en œuvre |
|---|---|
| **Isolement** | Serveur sur réseau interne ; ni base ni backend exposés sur Internet ; seul le web (443) est publié. |
| **Chiffrement au repos** | Pièces chiffrées ; clé = `SECRET_KEY`, détenue par vous. |
| **Chiffrement en transit** | HTTPS/TLS de bout en bout ; redirection 80→443. |
| **Moindre privilège** | Accès par rôle ; comptes nominatifs ; désactivation des départs. |
| **Traçabilité** | Journal d'audit inaltérable (utilisateur, IP, appareil) exportable. |
| **Secrets** | `.env` et `certs/` en droits restreints, hors versionnement, sauvegardés à part. |
| **Sauvegardes chiffrées** | Stocker les sauvegardes sur un support chiffré, à accès restreint. |

---

## 11. Sauvegardes — et test de restauration

```bash
sh scripts/sauvegarde.sh   # base -> sauvegardes/…​.sql.gz (données personnelles !)
```

> ⚠️ **Ne suffit pas.** Sauvegardez **aussi** le volume des pièces jointes (`media`) et conservez `SECRET_KEY` ailleurs. Une sauvegarde de base seule, sans la clé, ne permet pas de relire les pièces chiffrées.

Restauration (exemple depuis un dump SQL) :

```bash
gunzip -c sauvegardes/registre_foncier_AAAAMMJJ-HHMMSS.sql.gz \
  | docker compose exec -T db psql -U registre -d registre_foncier
```

Planifiez une sauvegarde quotidienne (cron) et **testez une restauration** à blanc régulièrement :

```bash
# Exemple cron : sauvegarde chaque nuit à 1h
0 1 * * * cd /opt/House-Register-services && sh scripts/sauvegarde.sh
```

---

## 12. Mises à jour — rester à la dernière version

```bash
sh scripts/sauvegarde.sh       # toujours avant
sh scripts/mettre-a-jour.sh    # pull + up -d ; migrations appliquées automatiquement
```

Choisissez la ligne d'images via `IMAGE_TAG` dans `.env` : `latest` (stable) ou `stage` (nouveautés en avance).

---

## 13. Durcissement en production

- Certificat d'une **autorité de confiance** (pas d'auto-signé en production).
- Mots de passe forts ; rotation ; **changer** le mot de passe admin initial.
- Pare-feu : n'exposer que 443 (et 80 pour la redirection), au réseau autorisé.
- Mises à jour système régulières du serveur hôte.
- Accès SSH par clé, sudo restreint, surveillance des journaux.

---

## 14. Remise à l'organisation — checklist de mise en service

- [ ] Serveur préparé, Docker installé, pare-feu configuré
- [ ] `.env` renseigné ; `SECRET_KEY` générée et archivée en lieu sûr
- [ ] Certificat TLS de confiance installé dans `certs/`
- [ ] Plateforme démarrée ; `/api/health` = ok
- [ ] Mot de passe administrateur initial changé
- [ ] Utilisateurs, rôles, zones, types de pièces créés
- [ ] Apparence (nom, logo) paramétrée
- [ ] Sauvegarde testée + restauration testée + planification (cron)
- [ ] Procédure de mise à jour transmise à l'équipe
- [ ] Contacts support & contrat de maintenance communiqués

---

## 15. Dépannage

| Symptôme | Piste |
|---|---|
| `pull access denied` (ghcr.io) | Refaire `docker login ghcr.io` avec le jeton fourni. |
| Le site ne répond pas sur 443 | Vérifier `certs/fullchain.pem` + `privkey.pem`, puis `docker compose logs web`. |
| Backend qui ne démarre pas | `docker compose logs backend` (migrations). Restaurer la dernière sauvegarde si besoin. |
| `POSTGRES_PASSWORD` manquant | Le renseigner dans `.env` puis relancer. |
| Pièces illisibles après restauration | `SECRET_KEY` différente : remettre la clé d'origine. |

---

**Édité par CORAF & Cie — Registre Foncier.** Le code source est privé ; l'assistance et les nouvelles versions sont fournies par l'éditeur.
