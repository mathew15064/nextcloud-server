#!/usr/bin/env bash
set -Eeuo pipefail

# ==============================================================================
# Script: End-to-end Nextcloud deployment from GitHub repository
# Repo:   mathew15064/nextcloud-server (Latest commit only via --depth 1)
# Stack:  PostgreSQL, Redis cache/locking, preview providers, cron
# ==============================================================================

REPO_URL="https://github.com/mathew15064/nextcloud-server.git"
TARGET_DIR="nextcloud-server"

echo "=========================================================="
echo "          STARTING NEXTCLOUD DEPLOYMENT SCRIPT            "
echo "=========================================================="

# 1. Clone only the latest commit if the repository is not already present
if [ ! -d "${TARGET_DIR}/.git" ]; then
    echo "[+] Cloning latest commit from ${REPO_URL}..."
    git clone --depth 1 "${REPO_URL}" "${TARGET_DIR}"
else
    echo "[+] Repository directory '${TARGET_DIR}' already exists. Skipping clone."
fi

cd "${TARGET_DIR}"

# 2. Ensure data directory exists and configure host permissions[cite: 1]
mkdir -p nc_data
chmod -R 777 nc_data config apps 2>/dev/null || chmod 777 nc_data

# 3. Spin up containers in the background using docker compose up -d
echo "[+] Starting containers with 'docker compose up -d'..."
docker compose up -d

# 4. Wait for Nextcloud to finish initial startup
echo "[+] Waiting for Nextcloud to initialize..."
until docker compose exec -u www-data app php occ status 2>/dev/null | grep -q "installed:"; do
    sleep 3
    echo -n "."
done
echo ""

# 5. Synchronize data directory ownership inside the container
echo "[+] Setting www-data ownership on /var/www/html/data..."
docker compose exec app chown -R www-data:www-data /var/www/html/data 2>/dev/null || true

# 6. Apply Redis and Preview optimizations once Nextcloud is installed
if docker compose exec -u www-data app php occ status 2>/dev/null | grep -q "installed: true"; then
    echo "[+] Applying Redis and media preview optimizations..."

    # Redis Cache & Locking configuration[cite: 1]
    docker compose exec -u www-data app php occ config:system:set memcache.local --value="\\OC\\Memcache\\APCu"[cite: 1]
    docker compose exec -u www-data app php occ config:system:set memcache.distributed --value="\\OC\\Memcache\\Redis"[cite: 1]
    docker compose exec -u www-data app php occ config:system:set memcache.locking --value="\\OC\\Memcache\\Redis"[cite: 1]

    docker compose exec -u www-data app php occ config:system:set redis host --value="redis"[cite: 1]
    docker compose exec -u www-data app php occ config:system:set redis port --value=6379 --type=integer[cite: 1]
    docker compose exec -u www-data app php occ config:system:set redis password --value="Nguyen@123"[cite: 1]

    # Preview Providers (MP4 video, HEIC, PNG, JPEG, GIF, BMP, TIFF, WebP)[cite: 1]
    docker compose exec -u www-data app php occ config:system:set enable_previews --value=true --type=boolean[cite: 1]
    docker compose exec -u www-data app php occ config:system:set preview_max_x --value=2048 --type=integer[cite: 1]
    docker compose exec -u www-data app php occ config:system:set preview_max_y --value=2048 --type=integer[cite: 1]
    docker compose exec -u www-data app php occ config:system:set preview_ffmpeg_path --value="/usr/bin/ffmpeg"[cite: 1]

    docker compose exec -u www-data app php occ config:system:set enabledPreviewProviders 0 --value="OC\\Preview\\Movie"[cite: 1]
    docker compose exec -u www-data app php occ config:system:set enabledPreviewProviders 1 --value="OC\\Preview\\PNG"[cite: 1]
    docker compose exec -u www-data app php occ config:system:set enabledPreviewProviders 2 --value="OC\\Preview\\JPEG"[cite: 1]
    docker compose exec -u www-data app php occ config:system:set enabledPreviewProviders 3 --value="OC\\Preview\\GIF"[cite: 1]
    docker compose exec -u www-data app php occ config:system:set enabledPreviewProviders 4 --value="OC\\Preview\\BMP"[cite: 1]
    docker compose exec -u www-data app php occ config:system:set enabledPreviewProviders 5 --value="OC\\Preview\\HEIC"[cite: 1]
    docker compose exec -u www-data app php occ config:system:set enabledPreviewProviders 6 --value="OC\\Preview\\TIFF"[cite: 1]
    docker compose exec -u www-data app php occ config:system:set enabledPreviewProviders 7 --value="OC\\Preview\\WebP"[cite: 1]

    # Enable viewer app and switch background jobs to system cron[cite: 1]
    docker compose exec -u www-data app php occ app:enable viewer 2>/dev/null || true
    docker compose exec -u www-data app php occ background:cron[cite: 1]
fi

echo "=========================================================="
echo "          NEXTCLOUD INSTANCE IS READY!                    "
echo "  Access URL: http://localhost:8088                       "
echo "=========================================================="
