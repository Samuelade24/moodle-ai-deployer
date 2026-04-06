#!/bin/bash
# Clone and deploy script with error handling

ENV=${1:-production}
CONFIG_FILE="config/${ENV}.env"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Warning: Config file $CONFIG_FILE not found!"
    echo "Creating default config..."
    mkdir -p config
    cat > "$CONFIG_FILE" << DEFAULT
# Auto-generated config for $ENV environment
MOODLE_VERSION=4.5
DB_NAME=moodle_${ENV}
DB_USER=moodle_user
AI_PROVIDER=openai
DEFAULT
    echo "Created $CONFIG_FILE"
fi

# Source the config file
source "$CONFIG_FILE"

# Run the installer
if [ -f "./install_moodle_ai.sh" ]; then
    ./install_moodle_ai.sh
else
    echo "Error: install_moodle_ai.sh not found!"
    exit 1
fi
