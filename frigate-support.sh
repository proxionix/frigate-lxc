#!/usr/bin/env bash
# Script d'installation de Frigate 0.15.0 sur LXC

msg_info "Mise à jour du système"
apt update && apt upgrade -y

msg_info "Installation des dépendances"
apt-get install -y curl sudo mc git gpg ca-certificates ffmpeg python3 python3-pip jq

msg_info "Installation de Frigate 0.15.0"
wget -q https://github.com/blakeblackshear/frigate/releases/download/v0.15.0/frigate_0.15.0_amd64.deb -O frigate.deb
dpkg -i frigate.deb
apt --fix-broken install -y

msg_info "Configuration du service systemd"
cat <<EOF >/etc/systemd/system/frigate.service
[Unit]
Description=Frigate NVR
After=network.target

[Service]
ExecStart=/usr/local/bin/frigate
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable frigate
systemctl start frigate

msg_ok "Frigate 0.15.0 installé avec succès !"
