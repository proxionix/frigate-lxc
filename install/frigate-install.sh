#!/usr/bin/env bash

# Copyright (c) 2024 Proxionix
# License: MIT
# https://github.com/proxionix/frigate-lxc

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installation des dépendances"
$STD apt-get install -y curl sudo mc git gpg ca-certificates \
    automake build-essential xz-utils libtool ccache pkg-config \
    python3 python3-pip nodejs npm ffmpeg v4l-utils \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev \
    libtiff-dev gfortran libatlas-base-dev libssl-dev \
    libusb-1.0-0-dev jq moreutils
msg_ok "Dépendances installées"

msg_info "Installation de go2rtc"
mkdir -p /usr/local/go2rtc/bin
cd /usr/local/go2rtc/bin
wget -qO go2rtc "https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_linux_amd64"
chmod +x go2rtc
$STD ln -svf /usr/local/go2rtc/bin/go2rtc /usr/local/bin/go2rtc
msg_ok "go2rtc installé"

msg_info "Configuration de l'accélération matérielle"
$STD apt-get install -y va-driver-all ocl-icd-libopencl1 intel-opencl-icd vainfo intel-gpu-tools
if [[ "$CTTYPE" == "0" ]]; then
    setup_privileged_gpu
else
    setup_unprivileged_gpu
fi
msg_ok "Accélération matérielle configurée"

msg_info "Installation de Frigate v0.15.0"
cd ~
mkdir -p /opt/frigate/models
wget -q https://github.com/blakeblackshear/frigate/archive/refs/tags/v0.15.0.tar.gz -O frigate.tar.gz
tar -xzf frigate.tar.gz -C /opt/frigate --strip-components 1
rm -rf frigate.tar.gz

# Configuration
cd /opt/frigate
$STD pip3 wheel --wheel-dir=/wheels -r requirements.txt
$STD pip3 install -r requirements.txt

# Build interface web
cd web
$STD npm install
$STD npm run build

# Configuration par défaut
setup_default_config
setup_services

msg_ok "Installation de Frigate terminée"

# Configuration des services
setup_services() {
    msg_info "Configuration des services systemd"
    
    # Service Frigate
    cat > /etc/systemd/system/frigate.service << 'EOF'
[Unit]
Description=Frigate NVR
After=network.target

[Service]
Type=simple
User=frigate
WorkingDirectory=/opt/frigate
Environment="FRIGATE_CONFIG_PATH=/config/config.yml"
ExecStart=/usr/bin/python3 -m frigate
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now frigate
    msg_ok "Services configurés"
}

# Nettoyage final
msg_info "Nettoyage"
$STD apt-get autoremove -y
$STD apt-get autoclean
msg_ok "Nettoyage terminé"
