#!/usr/bin/env bash
# Secure, full, interactive Git SSH linking script
# Supports: GitHub, GitLab, Bitbucket
# Author: Brutally production-safe

set -euo pipefail

echo "Git SSH Setup Wizard"
echo "---------------------------"

# Ensure ~/.ssh exists and has correct permissions
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Check required binaries
for cmd in ssh-keygen ssh-agent ssh-add; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' not found." >&2
    exit 1
  fi
done

# Prompt for email
read -rp "Enter email for SSH key (used as label): " EMAIL
if [[ -z "$EMAIL" ]]; then
  echo "Error: Email is required." >&2
  exit 1
fi

# Prompt for Git provider
read -rp "Git provider domain (e.g. github.com, gitlab.com): " GIT_HOST
if [[ -z "$GIT_HOST" ]]; then
  echo "Error: Git host is required." >&2
  exit 1
fi

# Prompt for optional custom key name
read -rp "SSH key filename (default: id_ed25519): " KEY_NAME
KEY_NAME="${KEY_NAME:-id_ed25519}"
KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Check if key already exists
if [[ -f "$KEY_PATH" ]]; then
  echo "Key already exists at $KEY_PATH"
  read -rp "Overwrite existing key? [y/N]: " OVERWRITE
  if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
    rm -f "$KEY_PATH" "$KEY_PATH.pub"
  else
    echo "Using existing key."
  fi
fi

# Generate key
if [[ ! -f "$KEY_PATH" ]]; then
  echo "Generating SSH key..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
fi

# Start ssh-agent if not running
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
  echo "Starting ssh-agent..."
  eval "$(ssh-agent -s)" >/dev/null
fi

# Add key to agent
ssh-add "$KEY_PATH"

# Set correct permissions
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

# Display public key
echo -e "\nCopy and paste this public key into your Git provider (GitHub/GitLab/etc):"
echo "----------------------------------------------------------------"
cat "$KEY_PATH.pub"
echo "----------------------------------------------------------------"
echo "Add it to: https://$GIT_HOST/settings/ssh_keys"

# Prompt to create SSH config entry
read -rp "Add to ~/.ssh/config for host '$GIT_HOST'? [Y/n]: " CONFIGURE
CONFIGURE="${CONFIGURE:-Y}"

if [[ "$CONFIGURE" =~ ^[Yy]$ ]]; then
  CONFIG_FILE="$HOME/.ssh/config"
  echo "Updating SSH config..."

  # Prevent duplicate entries
  if grep -q "Host $GIT_HOST" "$CONFIG_FILE" 2>/dev/null; then
    echo "SSH config already contains an entry for $GIT_HOST"
  else
    cat >> "$CONFIG_FILE" <<EOF

Host $GIT_HOST
  HostName $GIT_HOST
  User git
  IdentityFile $KEY_PATH
  IdentitiesOnly yes
EOF
    chmod 600 "$CONFIG_FILE"
    echo "SSH config updated."
  fi
fi

# Test connection
echo -e "\nTesting SSH connection to $GIT_HOST..."
ssh -T "git@$GIT_HOST" || echo "Warning: Auth test failed (may need manual approval in browser)."

echo -e "\nSSH setup complete. Use SSH to clone like:"
echo "  git clone git@$GIT_HOST:your-username/your-repo.git"
