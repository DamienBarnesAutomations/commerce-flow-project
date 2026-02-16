#!/bin/bash

# Exit on any error
set -e

# --- CONFIGURATION ---
# Default user is 'deploy_user', but you can override it:
# USAGE: ./setup-server.sh my_custom_name
NEW_USER=${1:-"deploy_user"}
# ---------------------

echo "--- Starting Setup for user: $NEW_USER ---"

# 1. Update and install dependencies
apt-get update && apt-get upgrade -y
apt-get install -y docker.io docker-compose-v2 git jq

# 2. Create the deployment user
if id "$NEW_USER" &>/dev/null; then
    echo "User $NEW_USER already exists. Skipping creation."
else
    adduser --disabled-password --gecos "" $NEW_USER
    usermod -aG sudo,docker $NEW_USER
    echo "User $NEW_USER created and added to docker/sudo groups."
fi

# 3. Setup SSH directory
USER_HOME="/home/$NEW_USER"
mkdir -p "$USER_HOME/.ssh"

# 4. Copy Authorized Keys from Root
# This ensures your current access carries over to the new user
if [ -f /root/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys "$USER_HOME/.ssh/"
    chown -R "$NEW_USER:$NEW_USER" "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    echo "SSH keys migrated from root to $NEW_USER."
fi

# 5. Grant Passwordless Sudo for CI/CD operations
# This specifically targets the commands used in your deploy.yml
cat <<EOF > /etc/sudoers.d/deploy-perms
$NEW_USER ALL=(ALL) NOPASSWD: /usr/bin/mkdir, /usr/bin/chown, /usr/bin/rm, /usr/bin/docker, /usr/bin/chmod
EOF
chmod 440 /etc/sudoers.d/deploy-perms

# 6. Prepare Application Directories
mkdir -p /app /app_tmp
chown -R "$NEW_USER:$NEW_USER" /app /app_tmp

echo "--- Setup Complete! ---"
echo "You can now update your GitHub Secrets:"
echo "SERVER_USER: $NEW_USER"
