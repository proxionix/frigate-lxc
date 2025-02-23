#!/usr/bin/env bash
# Script d'installation de Frigate 0.15.0 sur un conteneur LXC Proxmox
# Utilise les fonctions communautaires Proxmox VE (build.func)

APP="Frigate"
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Définition des variables
var_tags="nvr"
var_cpu="4"
var_ram="4096"
var_disk="20"
var_os="debian"
var_version="12"
var_unprivileged="0"

header_info "$APP"
variables
color
catch_errors

start
build_container
description

msg_ok "Installation de Frigate 0.15.0 terminée avec succès !\n"
echo -e "${INFO}${YW} Accès à Frigate : ${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
