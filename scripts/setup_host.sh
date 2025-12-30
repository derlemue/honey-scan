#!/bin/bash
set -e

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
dNC='\033[0m' # No Color

echo -e "${GREEN}>>> Starting Honey-Scan Host Setup (Debian 13) <<<${NC}"

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

# 1. Install Docker & Prerequisites
echo -e "${YELLOW}>>> Installing Docker & Dependencies...${NC}"
apt update && apt install -y ca-certificates curl gnupg git

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "${GREEN}>>> Docker Installed Successfully!${NC}"

# 2. Harden SSH (Port 22 -> 2222)
echo -e "${YELLOW}>>> Configuring SSH (Port 22 -> 2222)...${NC}"

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_CONFIG="/etc/ssh/sshd_config.bak.$(date +%F_%T)"

# Backup
cp "$SSHD_CONFIG" "$BACKUP_CONFIG"
echo "Backup created at $BACKUP_CONFIG"

# Modify Port
if grep -q "^Port 22" "$SSHD_CONFIG"; then
    sed -i 's/^Port 22/Port 2222/' "$SSHD_CONFIG"
elif grep -q "^#Port 22" "$SSHD_CONFIG"; then
    sed -i 's/^#Port 22/Port 2222/' "$SSHD_CONFIG"
else
    echo "Port 2222" >> "$SSHD_CONFIG"
fi

echo -e "${GREEN}>>> SSH Configuration Updated!${NC}"

# 3. ASCII Warning & Reboot
clear
echo -e "${RED}"
cat << "EOF"
################################################################################
#                                                                              #
#  WARNING: SSH PORT CHANGED TO 2222                                           #
#                                                                              #
#  The system will reboot to apply changes.                                    #
#  Next time you connect via SSH, you MUST use:                                #
#                                                                              #
#      ssh user@host -p 2222                                                   #
#                                                                              #
#  If you have a firewall, ensure Port 2222 is OPEN before disconnecting!      #
#                                                                              #
################################################################################
EOF
echo -e "${NC}"

echo "Rebooting in 30 seconds..."
echo "Press [ENTER] to reboot immediately, or Ctrl+C to cancel."

# Countdown
for i in {30..1}; do
    echo -ne "Rebooting in $i seconds... \r"
    read -t 1 -n 1 input && {
        if [ "$input" == "" ]; then
            break
        fi
    }
done
echo -e "\nRebooting now!"
reboot
