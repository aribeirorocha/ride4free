#!/usr/bin/env bash
# Start API + Cloudflare quick tunnel. Updates app_test/lib/app_config.dart with the new URL.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_CONFIG="${ROOT}/../app_test/lib/app_config.dart"
HOST="127.0.0.1"
PORT="8000"
API_URL="http://${HOST}:${PORT}"
LOG="${TMPDIR:-/tmp}/ride4free-cloudflared.log"

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "Install cloudflared: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
  exit 1
fi
if ! command -v uvicorn >/dev/null 2>&1; then
  echo "From backend/: pip install -r requirements.txt"
  exit 1
fi

update_app_config() {
  local url="$1"
  if [[ ! -f "$APP_CONFIG" ]]; then
    echo "Could not find $APP_CONFIG"
    return 1
  fi
  
  local escaped
  escaped=$(printf '%s' "$url" | sed 's/[&/\]/\\&/g')

  # Verifica se o sistema operativo é macOS (darwin) ou Linux
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # Versão para macOS (BSD sed)
    sed -i '' "s|static const String apiBaseUrl = .*|static const String apiBaseUrl = '${escaped}';|" "$APP_CONFIG"
  else
    # Versão para Linux (GNU sed)
    sed -i "s|static const String apiBaseUrl = .*|static const String apiBaseUrl = '${escaped}';|" "$APP_CONFIG"
  fi
}

cleanup() {
  [[ -n "${UVICORN_PID:-}" ]] && kill "$UVICORN_PID" 2>/dev/null || true
  [[ -n "${TUNNEL_PID:-}" ]] && kill "$TUNNEL_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

cd "$ROOT"

if ! curl -sf "${API_URL}/docs" >/dev/null 2>&1; then
  echo "Starting API on ${API_URL} ..."
  uvicorn main:app --host "$HOST" --port "$PORT" &
  UVICORN_PID=$!
  for _ in $(seq 1 30); do
    curl -sf "${API_URL}/docs" >/dev/null 2>&1 && break
    sleep 0.5
  done
  curl -sf "${API_URL}/docs" >/dev/null 2>&1 || { echo "API failed to start."; exit 1; }
fi

: >"$LOG"
echo "Starting tunnel (logs: $LOG) ..."
cloudflared tunnel --url "$API_URL" >>"$LOG" 2>&1 &
TUNNEL_PID=$!

PUBLIC_URL=""
for _ in $(seq 1 60); do
  PUBLIC_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' "$LOG" | head -1 || true)
  [[ -n "$PUBLIC_URL" ]] && break
  sleep 0.5
done

if [[ -z "$PUBLIC_URL" ]]; then
  echo "Tunnel URL not found yet. Check $LOG"
  echo "When you see the URL, set it in app_test/lib/app_config.dart → apiBaseUrl"
  wait "$TUNNEL_PID"
  exit 0
fi

update_app_config "$PUBLIC_URL"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  API:    ${API_URL}  (local)"
echo "  Public: ${PUBLIC_URL}"
echo "  Updated: app_test/lib/app_config.dart"
echo ""
echo "  Phones: hot-restart / rebuild the Flutter app"
echo "  Docs:   ${PUBLIC_URL}/docs"
echo "  Stop:   Ctrl+C"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

wait "$TUNNEL_PID"
