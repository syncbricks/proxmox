#!/bin/bash

# Update system to ensure all packages are up to date
echo "Updating the system..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install essential packages for ERPNext and dependencies
echo "Installing essential packages for ERPNext..."

# Install dependencies for Python, Node.js, MariaDB, Redis, and other necessary tools
sudo apt-get install -y \
    python3-dev python3-setuptools python3-pip python3-distutils \
    build-essential libssl-dev libffi-dev python3.11-venv \
    libmysqlclient-dev libfontconfig wkhtmltopdf redis-server \
    git curl libmysqlclient-dev npm ca-certificates \
    software-properties-common

# Install Node.js (version 20 recommended for ERPNext)
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Yarn
echo "Installing Yarn..."
sudo npm install -g yarn

# Install MariaDB server
echo "Installing MariaDB..."
sudo apt-get install -y mariadb-server mariadb-client

# Run mysql_secure_installation for MariaDB setup
echo "Running mysql_secure_installation to secure MariaDB..."
sudo mysql_secure_installation

# Install Redis server
echo "Installing Redis server..."
sudo apt-get install -y redis-server

# Install Python dependencies for Frappe and ERPNext
echo "Installing Python dependencies for Frappe and ERPNext..."
sudo pip3 install frappe-bench

# Install Bench CLI tool globally
echo "Installing Bench globally..."
sudo pip3 install bench

# Install wkhtmltopdf for PDF generation
echo "Installing wkhtmltopdf..."
sudo apt-get install -y wkhtmltopdf

# Create a new user for the bench environment
echo "Creating a new user for ERPNext installation..."
sudo useradd -m -s /bin/bash erpnext
sudo passwd erpnext
sudo usermod -aG sudo erpnext

# Switch to the erpnext user to continue with ERPNext installation
echo "Switching to the 'erpnext' user..."
su - erpnext

# Install Frappe Bench
echo "Installing Frappe Bench..."
bench init frappe-bench --frappe-branch version-15

# Change to the frappe-bench directory
cd frappe-bench

# Install ERPNext (version-15)
echo "Installing ERPNext app..."
bench get-app erpnext --branch version-15

# Create a new site for ERPNext
echo "Creating ERPNext site..."
bench new-site erp.syncbricks.com --mariadb-root-password <your-mariadb-root-password> --admin-password <your-admin-password>

# Install ERPNext on the site
echo "Installing ERPNext on the site..."
bench --site erp.syncbricks.com install-app erpnext

# Set up Supervisor for background jobs and Redis integration
echo "Setting up Supervisor..."

# Install Supervisor if not already installed
sudo apt-get install -y supervisor

# Set up Supervisor config for ERPNext
echo "Setting up Supervisor config for ERPNext..."
sudo bash -c "cat > /etc/supervisor/conf.d/frappe.conf <<EOF
[program:frappe]
command=/home/erpnext/frappe-bench/env/bin/python3 /home/erpnext/frappe-bench/apps/frappe/frappe/commands/bench.py start
directory=/home/erpnext/frappe-bench
autostart=true
autorestart=true
stderr_logfile=/var/log/frappe.err.log
stdout_logfile=/var/log/frappe.out.log
EOF"

# Reload supervisor to apply the changes
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start frappe

# Configure Nginx to serve ERPNext
echo "Configuring Nginx for ERPNext..."

# Install Nginx
sudo apt-get install -y nginx

# Configure Nginx for ERPNext
sudo bash -c "cat > /etc/nginx/sites-available/erp.syncbricks.com <<EOF
server {
    listen 80;
    server_name erp.syncbricks.com;

    root /home/erpnext/frappe-bench/sites;
    index index.html index.htm;

    location / {
        try_files \$uri @backend;
    }

    location @backend {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF"

# Enable Nginx site and restart it
sudo ln -s /etc/nginx/sites-available/erp.syncbricks.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Finalize installation
echo "Finalizing installation..."
bench update --patch
bench upgrade

# Start ERPNext
echo "Starting ERPNext..."
bench start &

# Output the ERPNext site URL
echo "ERPNext has been successfully installed! You can access it at http://erp.syncbricks.com"

# Optionally, install SSL certificates (using Let's Encrypt or any other preferred method)
# echo "Installing SSL certificates using Let's Encrypt..."
# sudo apt-get install certbot python3-certbot-nginx
# sudo certbot --nginx -d erp.syncbricks.com
