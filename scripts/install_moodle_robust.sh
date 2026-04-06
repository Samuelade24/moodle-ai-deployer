#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Moodle AI Installation - Robust Version${NC}"
echo "=============================================="

# Function to retry commands
retry_command() {
    local max_attempts=5
    local attempt=1
    local delay=10
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "${YELLOW}Attempt $attempt of $max_attempts...${NC}"
        if eval "$1"; then
            echo -e "${GREEN}Success!${NC}"
            return 0
        fi
        echo -e "${RED}Failed. Retrying in $delay seconds...${NC}"
        sleep $delay
        attempt=$((attempt + 1))
        delay=$((delay * 2))
    done
    echo -e "${RED}Failed after $max_attempts attempts${NC}"
    return 1
}

# Get API key securely
if [ -f ~/.moodle_ai_key ]; then
    source ~/.moodle_ai_key
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${YELLOW}OpenAI API key not found${NC}"
    read -sp "Enter your OpenAI API key: " OPENAI_API_KEY
    echo ""
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" > ~/.moodle_ai_key
    chmod 600 ~/.moodle_ai_key
fi

# Update system
echo -e "${GREEN}[1/6] Updating system...${NC}"
sudo apt update && sudo apt upgrade -y

# Install packages (with retries)
echo -e "${GREEN}[2/6] Installing required packages...${NC}"
retry_command "sudo apt install -y apache2 mysql-server php php-cli php-curl php-zip php-gd php-intl php-xml php-mbstring php-mysql git curl wget unzip"

# Download Moodle using wget with retries
echo -e "${GREEN}[3/6] Downloading Moodle...${NC}"
cd /tmp
retry_command "wget --timeout=30 --tries=3 -c https://github.com/moodle/moodle/archive/MOODLE_405_STABLE.zip"

if [ -f MOODLE_405_STABLE.zip ]; then
    sudo rm -rf /var/www/html/moodle
    sudo mkdir -p /var/www/html
    sudo unzip -q MOODLE_405_STABLE.zip -d /var/www/html/
    sudo mv /var/www/html/moodle-MOODLE_405_STABLE /var/www/html/moodle
    rm MOODLE_405_STABLE.zip
else
    echo -e "${RED}Failed to download Moodle. Trying alternative mirror...${NC}"
    retry_command "wget --timeout=30 --tries=3 -c https://download.moodle.org/download.php/direct/stable405/moodle-latest-405.tgz"
    sudo tar -xzf moodle-latest-405.tgz -C /var/www/html/
    rm moodle-latest-405.tgz
fi

sudo chown -R www-data:www-data /var/www/html/moodle

# Configure database
echo -e "${GREEN}[4/6] Configuring database...${NC}"
DB_PASS=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
sudo mysql << MYSQL_SCRIPT
DROP DATABASE IF EXISTS moodle;
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'moodleuser'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Save credentials
cat > ~/moodle_db_credentials.txt << CRED
Moodle Database Credentials
===========================
Database: moodle
Username: moodleuser
Password: $DB_PASS
Connection: localhost

Save these credentials for future reference.
CRED
chmod 600 ~/moodle_db_credentials.txt

# Create data directory
echo -e "${GREEN}[5/6] Setting up Moodle data directory...${NC}"
sudo mkdir -p /var/moodledata
sudo chown -R www-data:www-data /var/moodledata
sudo chmod 755 /var/moodledata

# Create config.php
echo -e "${GREEN}[6/6] Creating Moodle configuration...${NC}"
sudo tee /var/www/html/moodle/config.php > /dev/null << PHP
<?php
unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = 'mysqli';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = 'localhost';
\$CFG->dbname    = 'moodle';
\$CFG->dbuser    = 'moodleuser';
\$CFG->dbpass    = '$DB_PASS';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array(
    'dbpersist' => false,
    'dbsocket'  => false,
    'dbport'    => '',
);

\$CFG->wwwroot   = 'http://' . \$_SERVER['HTTP_HOST'];
\$CFG->dataroot  = '/var/moodledata';
\$CFG->admin     = 'admin';

// AI configuration will be added after installation
// via the admin interface

require_once(__DIR__ . '/lib/setup.php');
PHP

sudo chown www-data:www-data /var/www/html/moodle/config.php
sudo chmod 644 /var/www/html/moodle/config.php

# Set all permissions
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 755 /var/www/html/moodle
sudo find /var/www/html/moodle -type f -exec chmod 644 {} \;

# Restart Apache
sudo systemctl restart apache2

# Get IP address
IP_ADDR=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e ""
echo -e "🌐 Access Moodle at: ${GREEN}http://$IP_ADDR${NC}"
echo -e "🔑 Database credentials: ${YELLOW}~/moodle_db_credentials.txt${NC}"
echo -e "📁 Moodle installed in: /var/www/html/moodle"
echo -e ""
echo -e "${GREEN}Next Steps:${NC}"
echo -e "1️⃣  Open http://$IP_ADDR in your browser"
echo -e "2️⃣  Complete the Moodle installation wizard"
echo -e "3️⃣  Create admin account when prompted"
echo -e "4️⃣  Go to Site Administration → Plugins → AI to configure OpenAI"
echo -e ""
echo -e "Database Password: ${YELLOW}$DB_PASS${NC}"
echo -e "${GREEN}========================================${NC}"

# Test Apache
if systemctl is-active --quiet apache2; then
    echo -e "${GREEN}✓ Apache is running${NC}"
else
    echo -e "${RED}✗ Apache failed to start. Checking logs...${NC}"
    sudo systemctl status apache2 --no-pager
fi
