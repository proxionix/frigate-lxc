#!/usr/bin/env bash

# Copyright (c) 2024 Proxionix
# License: MIT

# Variables du conteneur
APP="Frigate"
var_version="12"
var_os="debian"
var_ram="4096"
var_cpu="4"
var_disk="20"
var_unprivileged="1"
NSAPP=$(echo ${APP,,} | tr -d ' ')

# Fonctions de vérification
arch_check() {
    if [ "$(dpkg --print-architecture)" != "amd64" ]; then
        echo -e "\n Ce script ne fonctionne qu'avec l'architecture amd64 \n"
        exit 1
    fi
}

# Vérification root
root_check() {
    if [[ "$(id -u)" -ne 0 || $(ps -o comm= -p $PPID) == "sudo" ]]; then
        echo "Ce script doit être exécuté en tant que root"
        exit 1
    fi
}

# Vérification PVE
pve_check() {
    if ! pveversion | grep -Eq "pve-manager/8\.[0-9]"; then
        echo "Ce script nécessite Proxmox VE 8.0 ou supérieur"
        exit 1
    fi
}

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

# Installation
header_info
echo -e "\nCe script va créer un conteneur LXC pour Frigate v0.15.0"
read -p "Continuer? (y/n):" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    root_check
    arch_check
    pve_check
    
    # Suite du script...
    echo "Configuration en cours..."
else
    echo "Installation annulée"
    exit 0
fi
