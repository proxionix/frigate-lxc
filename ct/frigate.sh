#!/usr/bin/env bash

# Copyright (c) 2024 Proxionix
# License: MIT
# https://github.com/proxionix/frigate-lxc

# Variables du conteneur
APP="Frigate"
var_version="12"
var_os="debian"
var_ram="4096"
var_cpu="4"
var_disk="20"
var_unprivileged="1"
NSAPP=$(echo ${APP,,} | tr -d ' ')

# Source des fonctions communes
source <(curl -s https://raw.githubusercontent.com/proxionix/frigate-lxc/main/misc/build.func)

# En-tête ASCII
function header_info {
clear
cat <<"EOF"
   ____    _           __        
  / __/___(_)__ ____ _/ /____   
 / _// __/ / _ `/ _ `/ __/ -_) 
/_/ /_/ /_/\_, /\_,_/\__/\__/  
          /___/                 
EOF
}

# Vérifications initiales
color
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
catch_errors
root_check
arch_check
pve_check
ssh_check
maxkeys_check

# Installation
header_info
if ! (whiptail --backtitle "Proxmox VE Helper Scripts" --title "Installation de Frigate" --yesno "Ceci va créer un conteneur LXC pour Frigate v0.15.0. Continuer?" 10 58); then
    clear
    exit
fi

# Exécution du script d'installation
install_script
build_container
description
