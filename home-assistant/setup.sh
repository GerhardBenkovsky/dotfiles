#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="/home/gary/data/homeassistant"
BACKUP_FILE="$SCRIPT_DIR/backup.tar"

# ─── Install Docker if missing ───────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  info "Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  success "Docker installed (group membership applies on next login)"
else
  success "Docker already installed"
fi

# ─── Restore backup ──────────────────────────────────────────────────────────
if [[ -d "$DATA_DIR" && "$(ls -A "$DATA_DIR" 2>/dev/null)" ]]; then
  info "Config directory already exists, skipping restore"
else
  if [[ ! -f "$BACKUP_FILE" ]]; then
    error "Backup file not found: $BACKUP_FILE"
  fi

  info "Extracting backup..."
  TMP_DIR=$(mktemp -d)
  tar xf "$BACKUP_FILE" -C "$TMP_DIR"

  if [[ ! -f "$TMP_DIR/backup.json" ]]; then
    rm -rf "$TMP_DIR"
    error "Not a valid Home Assistant backup (missing backup.json)"
  fi

  mkdir -p "$DATA_DIR"
  tar xzf "$TMP_DIR/homeassistant.tar.gz" -C "$DATA_DIR" --strip-components=1
  rm -rf "$TMP_DIR"
  success "Backup restored to $DATA_DIR"
fi

# ─── Start Home Assistant ─────────────────────────────────────────────────────
info "Starting Home Assistant..."
cd "$SCRIPT_DIR"
docker compose up -d
success "Home Assistant is running at http://$(hostname -I | awk '{print $1}'):8123"
