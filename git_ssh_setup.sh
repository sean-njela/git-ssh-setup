#!/bin/bash

# Secure, full, interactive Git SSH linking script
# Supports: GitHub, GitLab, Bitbucket
# Author: Brutally production-safe

set -euo pipefail

echo "🛠️ Git SSH Setup Wizard"
echo "---------------------------"

# Prompt for email
read -rp "📧 Enter email for SSH key (used as label): " EMAIL
if [[ -z "$EMAIL" ]]; then
  echo "❌ Email is required."
  exit 1
fi

# Prompt for Git provider
read -rp "🌐 Git provider domain (e.g. github.com, gitlab.com): " GIT_HOST
if [[ -z "$GIT_HOST" ]]; then
  echo "❌ Git host is required."
  exit 1
fi

# Prompt for optional custom key name
read -rp "🔑 SSH key filename (default: id_ed25519): " KEY_NAME
KEY_NAME=${KEY_NAME:-id_ed25519}
KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Check if key already exists
if [[ -f "$KEY_PATH" ]]; then
  echo "⚠️ Key already exists at $KEY_PATH"
  read -rp "🔁 Overwrite existing key? [y/N]: " OVERWRITE
  if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
    rm -f "$KEY_PATH" "$KEY_PATH.pub"
  else
    echo "✅ Using existing key."
  fi
fi

# Generate key
if [[ ! -f "$KEY_PATH" ]]; then
  echo "🔐 Generating SSH key..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
fi

# Start ssh-agent
echo "🚀 Starting ssh-agent..."
eval "$(ssh-agent -s)" > /dev/null

# Add key to agent
ssh-add "$KEY_PATH"

# Set correct permissions
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

# Display public key
echo -e "\n📋 Copy and paste this public key into your Git provider (GitHub/GitLab/etc):"
echo "----------------------------------------------------------------"
cat "$KEY_PATH.pub"
echo "----------------------------------------------------------------"

# Suggest where to paste it
echo "📝 Add it to: https://$GIT_HOST/settings/ssh_keys"

# Prompt to create SSH config entry
read -rp "⚙️  Add to ~/.ssh/config for host '$GIT_HOST'? [Y/n]: " CONFIGURE
CONFIGURE=${CONFIGURE:-Y}

if [[ "$CONFIGURE" =~ ^[Yy]$ ]]; then
  CONFIG_FILE="$HOME/.ssh/config"
  echo -e "\n🔧 Updating SSH config..."
  
  # Prevent duplicate entries
  if grep -q "Host $GIT_HOST" "$CONFIG_FILE" 2>/dev/null; then
    echo "⚠️ SSH config already contains an entry for $GIT_HOST"
  else
    cat >> "$CONFIG_FILE" <<EOF

Host $GIT_HOST
  HostName $GIT_HOST
  User git
  IdentityFile $KEY_PATH
  IdentitiesOnly yes
EOF
    echo "✅ SSH config updated."
  fi
fi

# Test connection
echo -e "\n🔍 Testing SSH connection to $GIT_HOST..."
ssh -T git@"$GIT_HOST" || echo "⚠️ Auth test failed (may need to approve GitHub prompt in browser)."

echo -e "\n🎉 SSH setup complete. Use SSH to clone like:"
echo "  git clone git@$GIT_HOST:your-username/your-repo.git"
