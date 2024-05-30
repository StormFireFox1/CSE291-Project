#!/usr/bin/env bash

# Exit on any error
set -e

# Variables
REDIS_KEYRING="/usr/share/keyrings/redis-archive-keyring.gpg"
REDIS_SOURCE_LIST="/etc/apt/sources.list.d/redis.list"
REDIS_CONF="/etc/redis/redis.conf"
NEW_PASSWORD='GF84e%FBAQ8X5Lk#rtxriLWPSrzQ!yzmr*oYxCQSaAR27Wc4YP3QJ6Y^Pdn@C*g'
REQUIREPASS_LINE="requirepass $NEW_PASSWORD"
PROTECTED_MODE_LINE="protected-mode no"
ATOP_LOG="/var/log/atop.log"

# Function to add Redis repository key
add_redis_repo_key() {
    echo "Adding Redis repository key..."
    curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o "$REDIS_KEYRING"
}

# Function to add Redis repository to sources list
add_redis_repo() {
    echo "Adding Redis repository to sources list..."
    echo "deb [signed-by=$REDIS_KEYRING] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee "$REDIS_SOURCE_LIST"
}

# Function to update package lists
update_package_lists() {
    echo "Updating package lists..."
    sudo apt-get update
}

# Function to install Redis and atop
install_redis_and_atop() {
    echo "Installing Redis and atop..."
    sudo apt-get install redis atop -y
}

# Function to configure Redis
configure_redis() {
    echo "Configuring Redis..."
    sudo sed -i "s/# requirepass foobared/$REQUIREPASS_LINE/g" "$REDIS_CONF"
    sudo sed -i "s/protected-mode yes/$PROTECTED_MODE_LINE/g" "$REDIS_CONF"
    sudo sed -i "s/bind\s127.0.0.1/bind 0.0.0.0/g" "$REDIS_CONF"
}

# Function to start atop in the background
start_atop() {
    echo "Starting atop in the background..."
    sudo atop -a 5 -w "$ATOP_LOG" &
}

# Function to restart Redis server
restart_redis() {
    echo "Restarting Redis server..."
    sudo systemctl restart redis-server.service
}

# Main script execution
main() {
    add_redis_repo_key
    add_redis_repo
    update_package_lists
    install_redis_and_atop
    configure_redis
    start_atop
    restart_redis
    echo "Redis installation and configuration complete, atop started."
}

# Run the main function
main
