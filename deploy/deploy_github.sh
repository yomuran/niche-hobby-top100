#!/usr/bin/env bash
# 可选：部署到 GitHub Pages（固定域名，需先 gh auth login）
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SRC_DIR"

if ! gh auth status >/dev/null 2>&1; then
  echo "请先运行: gh auth login" >&2
  exit 1
fi

git branch -M main 2>/dev/null || true

if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create niche-hobby-top100 --public --source=. --remote=origin
fi

git push -u origin main
gh api repos/{owner}/{repo}/pages -X POST -f build_type=legacy -f source[branch]=main -f source[path]=/ 2>/dev/null \
  || gh api repos/{owner}/{repo}/pages -X PUT -f build_type=legacy -f source[branch]=main -f source[path]=/

owner=$(gh api user -q .login)
echo ""
echo "GitHub Pages 地址（启用后约 1-2 分钟生效）："
echo "https://${owner}.github.io/niche-hobby-top100/"
