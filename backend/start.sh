#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8080}"

echo "[rental] Starting on 0.0.0.0:${PORT}"
php artisan migrate --force

# Optional one-shot seed: set SEED_ON_BOOT=1 in Railway vars after first deploy only.
if [[ "${SEED_ON_BOOT:-0}" == "1" ]]; then
  echo "[rental] SEED_ON_BOOT=1 — running db:seed"
  php artisan db:seed --force
fi

exec php artisan serve --host=0.0.0.0 --port="${PORT}"
