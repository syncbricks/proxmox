#!/usr/bin/env bash

# Copyright (c) 2021-2024 SyncBricks
# Author: SyncBricks
# License: MIT
# https://syncbricks.com

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

echo "Starting SyncBricks Proxmox Script to Create Ubuntu 24.04 LXC Container..."

# Default values
CT_TYPE="1"         # LXC container type
CT_ID=$NEXTID       # Container ID, Proxmox automatically assigns this
HN="ubuntu-24-04"   # Hostname of the container
DISK_SIZE="8"       # Disk size (GB)
CPU="2"             # CPU cores
RAM_SIZE="4096"     # RAM size (MB)
OS_VERSION="ubuntu-24.04"  # OS version for the container
NETWORK="vmbr0"     # Network bridge
STORAGE="local-lvm" # Storage location for container

# Setting default values
echo "Container Hostname: $HN"
echo "Container Disk Size: $DISK_SIZE GB"
echo "Container CPU Allocation: $CPU cores"
echo "Container RAM Size: $RAM_SIZE MB"
# Create the LXC container
create_lxc_container() {
  echo "Creating LXC container with ID: $CT_ID"

  # Create the container using Proxmox `pct` command
  pct create $CT_ID /var/lib/vz/template/cache/ubuntu-24.04-standard_*.tar.gz \
    -hostname $HN \
    -memory $RAM_SIZE \
    -cores $CPU \
    -net0 name=eth0,bridge=$NETWORK,ip=dhcp,tag=50 \
    -storage $STORAGE \
    -rootfs $STORAGE:$DISK_SIZE \
    -unprivileged 1 \
    -features nesting=1 \
    -ostype ubuntu \
    -osversion 24.04

  if [ $? -eq 0 ]; then
    echo "Container $CT_ID created successfully with Ubuntu 24.04."
  else
    echo "Error: Failed to create LXC container."
    exit 1
  fi
}
# Start the container
start_container() {
  echo "Starting the container with ID: $CT_ID..."
  pct start $CT_ID
  if [ $? -eq 0 ]; then
    echo "Container $CT_ID started successfully."
  else
    echo "Error: Failed to start the container."
    exit 1
  fi
}
