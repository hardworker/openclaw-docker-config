#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/opt/config/skills-manifest.txt"
WORKDIR="/home/node/.openclaw/workspace"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/home/node/.config}"
GOG_CREDENTIALS_PATH="${GOG_CREDENTIALS_PATH:-$XDG_CONFIG_HOME/gogcli/credentials.json}"

###############################################################################
# Seed workspace templates (no-clobber — won't overwrite existing files)
###############################################################################
TEMPLATES="/opt/workspace-templates"
if [[ -d "$TEMPLATES" ]]; then
  echo "[entrypoint] Seeding workspace templates ..."
  cp -rn "$TEMPLATES"/. "$WORKDIR"/
fi

###############################################################################
# Auto-import gog OAuth client credentials if present
###############################################################################
if command -v gog >/dev/null 2>&1; then
  if [[ -f "$GOG_CREDENTIALS_PATH" ]]; then
    echo "[entrypoint] Importing gog OAuth client credentials from $GOG_CREDENTIALS_PATH ..."
    gog auth credentials set "$GOG_CREDENTIALS_PATH" || {
      echo "[entrypoint] WARNING: Failed to import gog credentials — continuing"
    }
  else
    echo "[entrypoint] No gog credentials file found at $GOG_CREDENTIALS_PATH — skipping gog credential import."
  fi
fi

###############################################################################
# Install ClawHub skills from the manifest (if present)
###############################################################################
if [[ -f "$MANIFEST" ]]; then
  echo "[entrypoint] Installing ClawHub skills from manifest ..."
  while IFS= read -r line; do
    # Skip blank lines and comments
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -z "$line" ]] && continue

    # Skip if already installed
    if [[ -d "$WORKDIR/skills/$line" ]]; then
      echo "[entrypoint]   ✓ $line (already installed)"
      continue
    fi

    echo "[entrypoint]   → installing $line"
    clawhub install "$line" --workdir "$WORKDIR" || {
      echo "[entrypoint] WARNING: Failed to install $line — continuing"
    }
  done < "$MANIFEST"
  echo "[entrypoint] Skill installation complete."
else
  echo "[entrypoint] No skills manifest found — skipping skill install."
fi

###############################################################################
# Hand off to the real command (CMD from docker-compose)
###############################################################################
exec "$@"
