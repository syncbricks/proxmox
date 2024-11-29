#!/bin/bash
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
echo "This script will install ERPNext Verion 15 in Proxmox"
# Define Variables
VM_NAME="erpnext-vm"
VM_ID="100"  # Example ID, change according to your Proxmox setup
VM_MEMORY="4096"  # 4GB RAM
VM_CORES="2"  # 2 CPU cores
VM_DISK_SIZE="32G"  # Disk size for VM

# Update and install required dependencies
echo "Updating system and installing required dependencies..."
apt-get update -y
apt-get upgrade -y
apt-get install -y wget curl sudo lsb-release gnupg2 software-properties-common python3-pip python3-dev

# Install Proxmox Dependencies (If needed)
echo "Installing Proxmox dependencies..."
apt-get install -y proxmox-ve qemu-kvm libvirt-bin bridge-utils

# Download and Install Ubuntu 24.04 LTS Template
echo "Creating VM from Ubuntu 24.04 LTS template..."
pveam update
pveam available | grep ubuntu-24.04
pveam download local ubuntu-24.04-standard_24.04-1_amd64.tar.gz

# Create Proxmox VM for ERPNext
echo "Creating Proxmox VM for ERPNext..."
qm create $VM_ID --name $VM_NAME --memory $VM_MEMORY --cores $VM_CORES --net0 virtio,bridge=vmbr0 --boot order=cdrom
qm importdisk $VM_ID local:ubuntu-24.04-standard_24.04-1_amd64.tar.gz local-lvm
qm set $VM_ID --scsihw virtio-scsi-pci --virtio0 local-lvm:32
qm set $VM_ID --cdrom /var/lib/vz/template/iso/ubuntu-24.04.iso
qm set $VM_ID --ide2 local:cloudinit

# Start the VM and Open Console
echo "Starting the VM..."
qm start $VM_ID
echo "You can now connect to the VM console using Proxmox GUI or CLI."

# ERPNext Installation (VM is running Ubuntu 24.04)
echo "Installing ERPNext on Ubuntu 24.04 VM..."

# SSH into the VM and run ERPNext installation
ssh root@<VM_IP_ADDRESS> << 'EOF'
    # Update and install system dependencies
    apt update -y
    apt upgrade -y
    apt install -y git python3-pip python3-dev libmysqlclient-dev redis-server libssl-dev libffi-dev libjpeg-dev liblcms2-dev libblas-dev libatlas-base-dev

    # Install bench (Frappe CLI)
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

echo "ERPNext has been successfully installed on your Proxmox VM in production environment!"

# Final message
echo "###############################################################################"
echo "ERPNext installation completed successfully on VM: $VM_NAME."
echo "You can now access ERPNext via the IP address of the VM."
echo "###############################################################################"
