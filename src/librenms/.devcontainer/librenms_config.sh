#!/bin/bash

set -e
set -u

# Variables
USERNAME="librenms"
LIBRENMS_DIR="/opt/librenms"
MYSQL_HOST="localhost"
MYSQL_DB="librenms"
MYSQL_USER="librenms"
MYSQL_PASSWORD="password"


# Grant the LibreNMS user sudo privileges securely
if ! sudo grep -q "^$USERNAME " /etc/sudoers.d/$USERNAME 2>/dev/null; then
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USERNAME > /dev/null
    sudo chmod 0440 /etc/sudoers.d/$USERNAME
fi

# Set ownership & permissions
echo "Setting group ownership for LibreNMS..."
chown -R "$USERNAME":"$USERNAME" "$LIBRENMS_DIR"
chmod 771 "$LIBRENMS_DIR"

# Apply ACL permissions only if ACLs are available
if command -v setfacl >/dev/null 2>&1; then
    echo "Setting ACL permissions..."
    for dir in rrd logs bootstrap/cache storage; do
        setfacl -d -m g::rwx "$LIBRENMS_DIR/$dir"
        setfacl -R -m g::rwx "$LIBRENMS_DIR/$dir"
    done
else
    echo "ACL tools not found. Skipping ACL configuration."
fi

# Install Composer dependencies with a fallback
echo "Running Composer install..."
if ! ./scripts/composer_wrapper.php install; then
    echo "Composer install failed. Please check the logs."
    exit 1
fi

# Start MariaDB service
sudo service mariadb start

# Wait for MariaDB to be ready
for i in {1..10}; do
    if sudo mysqladmin ping -h"localhost" --silent; then
        echo "MariaDB is ready!"
        break
    fi
    echo "Waiting for MariaDB to be ready... ($i)"
    sleep 2
done

# MariaDB Setup: Create Database & User
echo "Configuring MariaDB..."
sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'$MYSQL_HOST' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'$MYSQL_HOST';
FLUSH PRIVILEGES;
EOF

echo "MariaDB setup complete."

# Enable lnms command completion
ln -s $LIBRENMS_DIR/lnms /usr/bin/lnms
cp $LIBRENMS_DIR/misc/lnms-completion.bash /etc/bash_completion.d/

# Start the development web server for LibreNMS
echo "If you want to start the development server, use the following command:"
echo "./lnms serve"
echo "Development server will start at http://localhost:8000"
echo "Setup complete."