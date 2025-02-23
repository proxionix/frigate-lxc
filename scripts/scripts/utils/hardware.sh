#!/usr/bin/env bash

# Copyright (c) 2024 Proxionix
# License: MIT

# Détection du GPU
detect_gpu() {
    if lspci | grep -i nvidia &>/dev/null; then
        echo "nvidia"
    elif lspci | grep -i amd &>/dev/null; then
        echo "amd"
    elif lspci | grep -i intel &>/dev/null; then
        echo "intel"
    else
        echo "none"
    fi
}

# Configuration du GPU
detect_and_setup_gpu() {
    local gpu_type=$(detect_gpu)
    
    case $gpu_type in
        "nvidia")
            setup_nvidia
            ;;
        "intel")
            setup_intel
            ;;
        "amd")
            setup_amd
            ;;
        *)
            log "WARN" "Aucun GPU compatible détecté, utilisation du CPU uniquement"
            ;;
    esac
}

# Configuration NVIDIA
setup_nvidia() {
    log "INFO" "Configuration du GPU NVIDIA..."
    apt-get install -y nvidia-container-toolkit
}

# Configuration Intel
setup_intel() {
    log "INFO" "Configuration du GPU Intel..."
    apt-get install -y \
        intel-media-va-driver-non-free \
        vainfo \
        intel-gpu-tools
}

# Configuration AMD
setup_amd() {
    log "INFO" "Configuration du GPU AMD..."
    apt-get install -y \
        mesa-va-drivers \
        vainfo
}

# Configuration pour conteneur privilégié
configure_privileged_container() {
    log "INFO" "Configuration du conteneur privilégié..."
    
    # Configuration des groupes et permissions
    chgrp video /dev/dri
    chmod 755 /dev/dri
    chmod 660 /dev/dri/*
    
    # Configuration USB
    cat << EOF >> /etc/udev/rules.d/99-frigate.rules
SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666"
EOF
}

# Configuration pour conteneur non privilégié
configure_unprivileged_container() {
    log "INFO" "Configuration du conteneur non privilégié..."
    
    # Configuration des groupes
    groupadd -f video
    usermod -aG video frigate
    
    if [[ -e "/dev/dri/renderD128" ]]; then
        if [[ -e "/dev/dri/card0" ]]; then
            cat << EOF >> /etc/pve/lxc/${CTID}.conf
# VAAPI hardware transcoding
dev0: /dev/dri/card0,gid=44
dev1: /dev/dri/renderD128,gid=104
EOF
        else
            cat << EOF >> /etc/pve/lxc/${CTID}.conf
# VAAPI hardware transcoding
dev0: /dev/dri/card1,gid=44
dev1: /dev/dri/renderD128,gid=104
EOF
        fi
    fi
}
