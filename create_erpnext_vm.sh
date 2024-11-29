#!/bin/bash

# Display the SyncBricks Banner
echo "################################################################################"
echo " ________       ___    ___ ________   ________  ________  ________  ___  ________ "
echo "|\   ____\     |\  \  /  /|\   ___  \|\   ____\|\   __  \|\   __  \|\  \|\   ____\\"
echo "\ \  \___|_    \ \  \/  / | \  \\ \  \ \  \___|\ \  \|\ /\ \  \|\  \ \  \ \  \___|_ "
echo " \ \_____  \    \ \    / / \ \  \\ \  \ \  \    \ \   __  \ \   _  _\ \  \ \_____  \\"
echo "  \|____|\  \    \/  /  /   \ \  \\ \  \ \  \____\ \  \|\  \ \  \\  \\ \  \|____|\  \\"
echo "    ____\_\  \ __/  / /      \ \__\\ \__\ \_______\ \_______\ \__\\ _\\ \__\____\_\  \\"
echo "   |\_________\\___/ /        \|__| \|__|\|_______|\|_______|\|__|\|__|\|__|\_________\\"
echo "   \|_________\|___|/                                                          \|_______|"
echo "################################################################################"

# Step 1: Get the next available container ID
echo "Finding the next available container ID..."
NEXT_CT_ID=$(($(pvesh get /nodes/$(hostname)/lxc | jq '.[-1].vmid' | sed 's/"//g') + 1))

# Print the generated container ID
echo "Generated container ID: $NEXT_CT_ID"

# Step 2: Ask for container network configuration
echo "Choose the network configuration for the container:"
echo "1) Bridge Mode (default)"
echo "2) Static IP"
read -p "Enter your choice (1 or 2): " network_choice

if [[ "$network_choice" == "1" ]]; then
    NETWORK_CONFIG="bridge"
elif [[ "$network_choice" == "2" ]]; then
    read -p "Enter the static IP address (e.g., 192.168.1.100): " static_ip
    NETWORK_CONFIG="static"
else
    echo "Invalid choice. Defaulting to bridge mode."
    NETWORK_CONFIG="bridge"
fi

# Step 3: Ask for storage locations for container templates and VM templates
echo "Enter the storage location for the LXC container template:"
read -p "(default: /var/lib/vz/template/cache/): " CT_TEMPLATE_STORAGE
CT_TEMPLATE_STORAGE=${CT_TEMPLATE_STORAGE:-/var/lib/vz/template/cache/}

echo "Enter the storage location for the VM template:"
read -p "(default: /var/lib/vz/images/): " VM_TEMPLATE_STORAGE
VM_TEMPLATE_STORAGE=${VM_TEMPLATE_STORAGE:-/var/lib/vz/images/}

# Step 4: Ask for confirmation to create the container
read -p "Do you want to create the LXC container with ID $NEXT_CT_ID? (y/n): " user_choice
if [[ "$user_choice" != "y" && "$user_choice" != "Y" ]]; then
    echo "Aborting LXC container creation."
    exit 1
fi

# Step 5: Ask for the LXC container template
CT_TEMPLATE="ubuntu-24.04-standard_24.04-1_amd64.tar.gz"  # default template
read -p "Enter the LXC container template file name (default: $CT_TEMPLATE): " user_ct_template
CT_TEMPLATE=${user_ct_template:-$CT_TEMPLATE}

# Step 6: Create LXC container
echo "Creating LXC container for ERPNext..."
pveam update
pveam available | grep ubuntu-24.04
pveam download local $CT_TEMPLATE_STORAGE/$CT_TEMPLATE
pct create $NEXT_CT_ID $CT_TEMPLATE_STORAGE/$CT_TEMPLATE -hostname erpnext-lxc -memory 4096 -cores 2 -rootfs local-lvm:32G

# Step 7: Configure network
if [[ "$NETWORK_CONFIG" == "static" ]]; then
    echo "Configuring static IP $static_ip..."
    pct exec $NEXT_CT_ID -- bash -c "echo 'auto eth0' > /etc/network/interfaces && echo 'iface eth0 inet static' >> /etc/network/interfaces && echo 'address $static_ip' >> /etc/network/interfaces"
else
    echo "Using bridge mode for networking."
fi

# Step 8: Ask if the user wants to start the container
read -p "Do you want to start the LXC container now? (y/n): " start_choice
if [[ "$start_choice" == "y" || "$start_choice" == "Y" ]]; then
    pct start $NEXT_CT_ID
    echo "Container $NEXT_CT_ID started."
else
    echo "Container creation complete. You can start it manually later."
fi

# Step 9: Ask for confirmation to install ERPNext dependencies
read -p "Do you want to install ERPNext dependencies inside the container? (y/n): " install_choice
if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
    echo "Installing ERPNext dependencies inside the container..."
    pct exec $NEXT_CT_ID -- bash << 'EOF'
        # Update the package list and install necessary dependencies
        apt update -y
        apt upgrade -y
        apt install -y wget curl sudo git python3-pip python3-dev libmysqlclient-dev redis-server libssl-dev libffi-dev libjpeg-dev liblcms2-dev libblas-dev libatlas-base-dev mariadb-server supervisor

        # Configure MariaDB
        systemctl enable mariadb
        systemctl start mariadb
        mysql_secure_installation

        # Install Frappe Bench
        pip3 install frappe-bench

        # Create a new bench for ERPNext
        bench init erpnext-bench --frappe-branch version-15
        cd erpnext-bench

        # Install ERPNext
        bench get-app erpnext --branch version-15

        # Setup ERPNext site
        bench new-site erpnext.local --mariadb-root-password <DB_ROOT_PASSWORD> --admin-password <ADMIN_PASSWORD>

        # Install ERPNext on the site
        bench --site erpnext.local install-app erpnext

        # Set production mode and start ERPNext
        bench start
EOF
else
    echo "Skipping ERPNext dependency installation. You can install it manually later."
fi

# Final message
echo "###############################################################################"
echo "ERPNext installation completed successfully in container: erpnext-lxc."
echo "You can now access ERPNext via the IP address of the container."
echo "###############################################################################"
