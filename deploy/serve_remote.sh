#!/usr/bin/env bash
# 在 GPU-02 上启动静态站点 + localhost.run 公网隧道（公司 DNS 可解析）
set -euo pipefail

WEB_ROOT="${WEB_ROOT:-$HOME/benchmark_data/scratch/hobby_top100_web}"
PORT="${PORT:-18787}"
LOG_DIR="${LOG_DIR:-$HOME/benchmark_data/logs}"
HTTP_LOG="$LOG_DIR/hobby_top100_http.log"
TUNNEL_LOG="$LOG_DIR/hobby_top100_tunnel.log"
PID_HTTP="$LOG_DIR/hobby_top100_http.pid"
PID_TUNNEL="$LOG_DIR/hobby_top100_tunnel.pid"
URL_FILE="$LOG_DIR/hobby_top100_public_url.txt"

mkdir -p "$LOG_DIR"

stop_old() {
  for pf in "$PID_HTTP" "$PID_TUNNEL"; do
    if [[ -f "$pf" ]]; then
      old_pid=$(cat "$pf" 2>/dev/null || true)
      if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
        kill "$old_pid" 2>/dev/null || true
        sleep 1
      fi
      rm -f "$pf"
    fi
  done
  pkill -f "cloudflared tunnel --url http://127.0.0.1:$PORT" 2>/dev/null || true
}

stop_old

cd "$WEB_ROOT"
nohup python3 -m http.server "$PORT" --bind 127.0.0.1 >"$HTTP_LOG" 2>&1 &
echo $! >"$PID_HTTP"

: >"$TUNNEL_LOG"
nohup ssh \
  -o StrictHostKeyChecking=accept-new \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -R 80:127.0.0.1:"$PORT" \
  nokey@localhost.run >>"$TUNNEL_LOG" 2>&1 &
echo $! >"$PID_TUNNEL"

echo "等待公网隧道就绪..."
for _ in $(seq 1 60); do
  url=$(grep -oE 'https://[a-z0-9]+\.lhr\.life' "$TUNNEL_LOG" | tail -1 || true)
  if [[ -n "$url" ]]; then
    echo "$url" >"$URL_FILE"
    echo "公网地址: $url"
    exit 0
  fi
  sleep 1
done

echo "隧道启动超时，请查看: $TUNNEL_LOG" >&2
exit 1
