#!/usr/bin/env bash
set -Eeuo pipefail

# Deploy thomann-affiliate static app to virya-home.
# Usage: bash deploy/deploy.sh

REMOTE="${THOMANN_DEPLOY_HOST:-virya-home}"
REMOTE_DIR="${THOMANN_DEPLOY_REMOTE_DIR:-/srv/thomann-affiliate}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$SCRIPT_DIR"

log() { printf '[thomann-affiliate] %s\n' "$*"; }
die() { printf '[thomann-affiliate] ERROR: %s\n' "$*" >&2; exit 1; }

command -v scp >/dev/null 2>&1 || die "scp not found"
command -v ssh >/dev/null 2>&1 || die "ssh not found"

[[ -f index.html ]] || die "index.html not found in $SCRIPT_DIR"

log "syncing index.html to ${REMOTE}:${REMOTE_DIR}/"
ssh "$REMOTE" "mkdir -p ${REMOTE_DIR}"
scp index.html "$REMOTE:${REMOTE_DIR}/index.html"

log "reloading nginx"
ssh "$REMOTE" "sudo nginx -t && sudo systemctl reload nginx"

log "deployed to https://thomann.virya.music/"
