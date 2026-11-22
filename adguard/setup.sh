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
CERT_DIR="$SCRIPT_DIR/certs"

# ─── Install Docker if missing ───────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  info "Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  success "Docker installed (group membership applies on next login)"
else
  success "Docker already installed"
fi

# ─── Generate self-signed certs ──────────────────────────────────────────────
if [[ -f "$CERT_DIR/cert.pem" ]]; then
  success "Certs already exist"
else
  info "Generating self-signed certs..."
  mkdir -p "$CERT_DIR"
  openssl req -x509 -nodes -days 3650 \
    -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
    -keyout "$CERT_DIR/key.pem" \
    -out "$CERT_DIR/cert.pem" \
    -subj "/CN=AdGuard Home" \
    -addext "subjectAltName=DNS:gimli.local,IP:127.0.0.1"
  success "Certs generated"
fi

# ─── Start AdGuard Home ──────────────────────────────────────────────────────
info "Starting AdGuard Home..."
cd "$SCRIPT_DIR"
docker compose up -d
success "AdGuard Home setup wizard at http://$(hostname -I | awk '{print $1}'):8053"
