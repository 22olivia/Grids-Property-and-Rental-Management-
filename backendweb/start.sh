#!/usr/bin/env bash
# Railway free-tier safe boot:
# 1) Bind HTTP ASAP (so health checks don't kill the deploy)
# 2) Wait for MySQL, migrate with retries (don't crash-loop forever on one blip)
# 3) Optional seed once via SEED_ON_BOOT=1
set -uo pipefail

PORT="${PORT:-8080}"
export LOG_CHANNEL="${LOG_CHANNEL:-stderr}"
export APP_ENV="${APP_ENV:-production}"

echo "[rental] Booting GPMS API on 0.0.0.0:${PORT}"

if [[ -z "${APP_KEY:-}" ]]; then
  export APP_KEY="base64:$(php -r 'echo base64_encode(random_bytes(32));')"
  echo "[rental] WARNING: APP_KEY missing — generated ephemeral key for this boot only. Set APP_KEY in Railway Variables."
fi

# Keep PHP light on free/trial RAM (~0.5GB shared with MySQL).
export PHP_CLI_SERVER_WORKERS="${PHP_CLI_SERVER_WORKERS:-1}"
php -d memory_limit="${PHP_MEMORY_LIMIT:-128M}" -v >/dev/null 2>&1 || true

wait_for_mysql() {
  if [[ "${DB_CONNECTION:-mysql}" != "mysql" || -z "${DB_HOST:-}" ]]; then
    return 0
  fi
  echo "[rental] Waiting for MySQL at ${DB_HOST}:${DB_PORT:-3306}…"
  for i in $(seq 1 45); do
    if php -d memory_limit=64M -r '
      $host = getenv("DB_HOST") ?: "127.0.0.1";
      $port = getenv("DB_PORT") ?: "3306";
      $db = getenv("DB_DATABASE") ?: "";
      $user = getenv("DB_USERNAME") ?: "";
      $pass = getenv("DB_PASSWORD") ?: "";
      try {
        new PDO("mysql:host={$host};port={$port};dbname={$db}", $user, $pass, [
          PDO::ATTR_TIMEOUT => 3,
        ]);
        exit(0);
      } catch (Throwable $e) {
        fwrite(STDERR, $e->getMessage() . PHP_EOL);
        exit(1);
      }
    ' 2>/tmp/rental-mysql-wait.err; then
      echo "[rental] MySQL is ready"
      return 0
    fi
    if [[ $((i % 5)) -eq 0 ]]; then
      echo "[rental] Still waiting for MySQL (attempt ${i}/45)…"
      tail -n 1 /tmp/rental-mysql-wait.err 2>/dev/null || true
    fi
    sleep 2
  done
  echo "[rental] ERROR: MySQL not reachable. Check DB_HOST/DB_PASSWORD on the API service."
  return 1
}

run_migrate() {
  local attempt
  for attempt in 1 2 3 4 5; do
    echo "[rental] migrate attempt ${attempt}/5"
    if php -d memory_limit="${PHP_MEMORY_LIMIT:-128M}" artisan migrate --force --no-ansi; then
      echo "[rental] migrate OK"
      return 0
    fi
    sleep $((attempt * 3))
  done
  echo "[rental] ERROR: migrate failed after retries"
  return 1
}

# Bind port early so Railway health checks succeed while DB/migrate catch up.
php -d memory_limit="${PHP_MEMORY_LIMIT:-128M}" artisan serve --host=0.0.0.0 --port="${PORT}" --no-reload &
SERVER_PID=$!
echo "[rental] HTTP server pid=${SERVER_PID}"

cleanup() {
  if kill -0 "${SERVER_PID}" 2>/dev/null; then
    kill "${SERVER_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

sleep 1
if ! kill -0 "${SERVER_PID}" 2>/dev/null; then
  echo "[rental] FATAL: HTTP server exited immediately — check APP_KEY / PHP errors above"
  wait "${SERVER_PID}" || true
  exit 1
fi

BOOT_OK=1
if ! wait_for_mysql; then
  BOOT_OK=0
fi

if [[ "${BOOT_OK}" == "1" ]]; then
  if ! run_migrate; then
    BOOT_OK=0
  fi
fi

if [[ "${BOOT_OK}" == "1" && "${SEED_ON_BOOT:-0}" == "1" ]]; then
  echo "[rental] SEED_ON_BOOT=1 — seeding (turn this OFF after first success)"
  if ! php -d memory_limit="${PHP_MEMORY_LIMIT:-192M}" artisan db:seed --force --no-ansi; then
    echo "[rental] WARNING: seed failed — API still running. Set SEED_ON_BOOT=0 and fix logs."
  fi
elif [[ "${SEED_ON_BOOT:-0}" == "1" ]]; then
  echo "[rental] Skipping seed because MySQL/migrate was not ready"
fi

if [[ "${BOOT_OK}" != "1" ]]; then
  echo "[rental] WARNING: booted with DB problems — /up may work but /api/v1/login will fail until DB_* is fixed"
fi

# Keep container alive with the HTTP server.
trap - EXIT
wait "${SERVER_PID}"
