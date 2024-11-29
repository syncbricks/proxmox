#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
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

echo -e "Loading..."
APP="ERPNext"
var_disk="8"
var_cpu="2"
var_ram="4096"
var_os="ubuntu"
var_version="20.04"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function create_erpnext_container() {
  header_info
  echo -e "Creating ERPNext LXC Container...\n"
  
  CT_ID=$NEXTID
  HN="erpnext-container-${CT_ID}"
  CT_NAME="ERPNext-Container-${CT_ID}"
  CT_ROOTFS="/mnt/pve/lxc_templates"
  NETWORK_INTERFACE="eth0"
  
  # Network Configuration
  NETWORK=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "ERPNext LXC Network" --inputbox "Enter the network bridge (default: vmbr0):" 10 60 "vmbr0" 3>&1 1>&2 2>&3)
  if [ -z "$NETWORK" ]; then
    NETWORK="vmbr0"
  fi

  # Container Storage Selection
  STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "ERPNext LXC Storage" --inputbox "Enter the storage location for container (default: local-lvm):" 10 60 "local-lvm" 3>&1 1>&2 2>&3)
  if [ -z "$STORAGE" ]; then
    STORAGE="local-lvm"
  fi

  # Disk Size
  DISK_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "ERPNext LXC Disk Size" --inputbox "Enter disk size for ERPNext (default: 8GB):" 10 60 "8" 3>&1 1>&2 2>&3)
  if [ -z "$DISK_SIZE" ]; then
    DISK_SIZE="8"
  fi

  # CPU Allocation
  CPU=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "ERPNext LXC CPU Allocation" --inputbox "Enter number of CPU cores for ERPNext (default: 2):" 10 60 "2" 3>&1 1>&2 2>&3)
  if [ -z "$CPU" ]; then
    CPU="2"
  fi

  # Memory Allocation
  MEMORY=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "ERPNext LXC Memory Allocation" --inputbox "Enter RAM size for ERPNext (default: 4096MB):" 10 60 "4096" 3>&1 1>&2 2>&3)
  if [ -z "$MEMORY" ]; then
    MEMORY="4096"
  fi

  # Create LXC Container with ERPNext
  echo "Creating container ID: $CT_ID"
  echo "Using disk size: ${DISK_SIZE}GB"
  echo "Using 
