#!/usr/bin/env bash
# Script d'installation de Frigate 0.15.0 sur un conteneur LXC Proxmox

APP="Frigate"
source <(curl -s https://raw.githubusercontent.com/proxionix/frigate-lxc/main/build.func)

var_tags="nvr"
var_cpu="4"  # Modifie selon tes besoins
var_ram="4096"
var_disk="20"
var_os="debian"
var_version="11"
var_unprivileged="0"

header_info "$APP"
variables
color
catch_errors

start
build_container
description

msg_info "Ajout du support matériel pour Frigate"
bash -c "$(wget -qLO - https://raw.githubusercontent.com/proxionix/frigate-lxc/main/frigate-support.sh)"

msg_ok "Installation de Frigate 0.15.0 terminée avec succès !"
echo -e "Accédez à Frigate via : http://${IP}:5000"
