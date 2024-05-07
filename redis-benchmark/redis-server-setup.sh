#!/usr/bin/env bash

# Exit on any error
set -e

# Add the Redis repository key
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

# Add the Redis repository to sources.list.d
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

# Update package lists
sudo apt-get update

# Install Redis
sudo apt-get install redis -y

# Define the new password and configuration values
new_password='GF84e%FBAQ8X5Lk#rtxriLWPSrzQ!yzmr*oYxCQSaAR27Wc4YP3QJ6Y^Pdn@C*g'
requirepass_line="requirepass $new_password"
protected_mode_line="protected-mode no"

# Replace the lines in the redis.conf file
sudo sed -i "s/# requirepass foobared/$requirepass_line/g" /etc/redis/redis.conf
sudo sed -i "s/protected-mode yes/$protected_mode_line/g" /etc/redis/redis.conf
sudo sed -i "s/bind\s127.0.0.1/bind 0.0.0.0/g" /etc/redis/redis.conf

# Restart the server
sudo systemctl restart redis
