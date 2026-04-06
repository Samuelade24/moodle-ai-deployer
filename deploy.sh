#!/bin/bash
# Moodle AI Deployer - Main Installation Script

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Moodle AI Deployer${NC}"
echo -e "${GREEN}========================================${NC}"

# Start services for WSL2
echo -e "${GREEN}Starting services...${NC}"
sudo service mysql start 2>/dev/null || true
sudo service apache2 start 2>/dev/null || true

# Check if already installed
if [ -f /var/www/html/config.php ]; then
    echo -e "${YELLOW}Moodle already installed!${NC}"
    echo -e "Access at: ${GREEN}http://$(hostname -I | awk '{print $1}')${NC}"
    exit 0
fi

# Download Moodle
echo -e "${GREEN}Downloading Moodle 4.5...${NC}"
cd /tmp
wget -q --show-progress https://github.com/moodle/moodle/archive/MOODLE_405_STABLE.zip

# Extract
echo -e "${GREEN}Extracting Moodle...${NC}"
sudo rm -rf /var/www/html/*
sudo unzip -q MOODLE_405_STABLE.zip -d /var/www/html/
sudo mv /var/www/html/moodle-MOODLE_405_STABLE/* /var/www/html/
sudo rm -rf /var/www/html/moodle-MOODLE_405_STABLE

# Generate random password
DB_PASS=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)

# Setup database
echo -e "${GREEN}Configuring database...${NC}"
sudo mysql << EOF
CREATE DATABASE IF NOT EXISTS moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'moodleuser'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
