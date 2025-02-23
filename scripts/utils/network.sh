#!/usr/bin/env bash

# Copyright (c) 2024 Proxionix
# License: MIT

# Configuration du réseau
setup_network() {
    local interface="eth0"
    local port="5000"
    
    # Vérification de la connectivité
    check_network_connectivity
    
    # Configuration du pare-feu
    setup_firewall "$port"
    
    # Configuration des DNS
    setup_dns
}

# Vérification de la connectivité
check_network_connectivity() {
    log "INFO" "Vérification de la connectivité réseau..."
    
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log "ERROR" "Pas de connexion Internet"
        exit 1
    fi
    
    if ! ping -c 1 github.com &> /dev/null; then
        log "ERROR" "Impossible d'accéder à GitHub"
        exit 1
    fi
}

# Configuration du pare-feu
setup_firewall() {
    local port=$1
    
    if command -v ufw &> /dev/null; then
        log "INFO" "Configuration du pare-feu UFW..."
        ufw allow $port/tcp comment "Frigate Web UI"
        ufw allow 1935/tcp comment "Frigate RTMP"
    fi
    
    if command -v firewall-cmd &> /dev/null; then
        log "INFO" "Configuration de FirewallD..."
        firewall-cmd --permanent --add-port=$port/tcp
        firewall-cmd --permanent --add-port=1935/tcp
        firewall-cmd --reload
    fi
}

# Configuration des DNS
setup_dns() {
    log "INFO" "Configuration des DNS..."
    
    # Vérification du fichier resolv.conf
    if ! grep -q "nameserver 8.8.8.8" /etc/resolv.conf; then
        cat << EOF > /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
    fi
}

# Configuration de la découverte réseau
setup_mdns() {
    log "INFO" "Configuration mDNS..."
    
    apt-get install -y avahi-daemon
    
    cat << EOF > /etc/avahi/services/frigate.service
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Frigate on %h</name>
  <service>
    <type>_http._tcp</type>
    <port>5000</port>
  </service>
</service-group>
EOF

    systemctl enable --now avahi-daemon
}
