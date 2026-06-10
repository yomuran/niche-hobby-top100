#!/usr/bin/env bash
# 本地一键部署：同步静态文件到 GPU-02 并重启公网隧道
set -euo pipefail

REMOTE="${REMOTE:-my-remote-02}"
SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="~/benchmark_data/scratch/hobby_top100_web"

echo "==> 同步文件到 $REMOTE:$DEST"
rsync -avz --delete \
  --exclude 'api_keys.json' \
  --exclude 'logs/' \
  --exclude 'remote/' \
  --exclude 'deploy/' \
  --exclude '*.py' \
  --exclude '*.plist' \
  --exclude 'README.md' \
  --exclude '.git/' \
  "$SRC_DIR/" \
  "$REMOTE:$DEST/"

echo "==> 上传并启动远程服务"
scp "$SRC_DIR/deploy/serve_remote.sh" "$REMOTE:~/benchmark_data/scratch/hobby_top100_web/serve_remote.sh"
ssh "$REMOTE" 'chmod +x ~/benchmark_data/scratch/hobby_top100_web/serve_remote.sh && bash ~/benchmark_data/scratch/hobby_top100_web/serve_remote.sh'

echo ""
echo "==> 部署完成。公网地址："
ssh "$REMOTE" 'cat ~/benchmark_data/logs/hobby_top100_public_url.txt 2>/dev/null || true'
