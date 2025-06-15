#!/bin/bash
# Config builder with some base folders.
# For now compatible with prometheus on Ubuntu


# Check if the folder structure exists, if not create it
for dir in templates backups configs; do
    echo "Check if the folder $dir exists..."
    if [ -d "$dir" ]; then
        echo "Folder $dir exists, not touching."
    else
        echo "Folder $dir does not exist, creating it."
    fi
    [ -d "$dir" ] || mkdir -p "$dir"
    # Put some defaults in place.
    echo "Folder $dir is ready."
done

# Copy defaults
read -p "Do you want to copy some defaults? This will overwrite ALL. (yes/no): " ANSWER
    if [[ "$ANSWER" == "yes" ]]; then
        cp setup/base_prometheus.yml templates/prometheus.yml
        cp setup/base_config1.yml configs/config1.yml
        cp setup/base_config2.yml configs/config2.yml
    else
        echo "Nothing copied."
    fi

# Check if promtool is installed
if ! command -v promtool &> /dev/null; then
    echo "promtool could not be found. Please install Prometheus to use this script."
    exit 1
fi
 
# Variables
TOP_TEMPLATE="templates/base_prometheus.yml"
CONFIG_FILES=$(ls configs/*.yml)
CONFIG_FILE="prometheus.yml"
BACKUP_FILE="backups/`date +%d-%m-%Y-%T`-prometheus.yml"
TMP_CONFIG="prometheus.yml-tmp"
SERVICE="prometheus"

# Start with top template
cp "$TOP_TEMPLATE" "$TMP_CONFIG"

# Append each config file to the template file
for CONFIG in $CONFIG_FILES; do
    cat "$CONFIG" >> "$TMP_CONFIG"
done

# Validate 
if promtool check config "$TMP_CONFIG"; then
    echo "Configuration is valid, continuing."
    # Create a backup 
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$BACKUP_FILE"
    fi

    # Move file in place
    mv $TMP_CONFIG $CONFIG_FILE

    # Reload prometheus
    read -p "Do you want to reload $SERVICE? (yes/no): " ANSWER

    if [[ "$ANSWER" == "yes" ]]; then
        echo "Reloading $SERVICE..."
        systemctl reload "$SERVICE"
        echo "$SERVICE reloaded successfully."
    else
        echo "Prometheus not reloaded."
    fi

else
    echo "Configuration is invalid. Exiting..."
    rm $TMP_CONFIG
    exit 1
fi
