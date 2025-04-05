#!/bin/bash

# vpn-server/scripts/setup-routing.sh

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Identify interfaces
DOCKER_INTERFACE="docker0"
EXTERNAL_INTERFACE=$(ip route | grep default | awk '{print $5}')
echo "Using $EXTERNAL_INTERFACE as external interface"

# Clear existing rules
iptables -F
iptables -t nat -F
iptables -X

# Default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# NAT for VPN clients to access internet
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $EXTERNAL_INTERFACE -j MASQUERADE

# Allow forwarding between VPN and internet
iptables -A FORWARD -i tun0 -o $EXTERNAL_INTERFACE -j ACCEPT
iptables -A FORWARD -i $EXTERNAL_INTERFACE -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow forwarding between Docker and VPN
iptables -A FORWARD -i tun0 -o $DOCKER_INTERFACE -j ACCEPT
iptables -A FORWARD -i $DOCKER_INTERFACE -o tun0 -j ACCEPT

# Print the routing table and iptables rules for debugging
echo "Routing table:"
ip route
echo "NAT rules:"
iptables -t nat -L -v
echo "Forward rules:"
iptables -L FORWARD -v
