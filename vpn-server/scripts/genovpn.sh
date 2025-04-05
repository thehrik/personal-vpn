#!/bin/sh

# vpn-server/scripts/genovpn.sh

# Get SERVER_IP from environment variable or use default
SERVER_IP="${SERVER_IP:-192.168.0.104}"
CLIENT_NAME="myclient"

if [ ! -f /etc/openvpn/ca.crt ] || [ ! -f /etc/openvpn/client.crt ] || [ ! -f /etc/openvpn/client.key ] || [ ! -f /etc/openvpn/ta.key ]; then
  echo "Error: Missing required certificate or key files."
  exit 1
fi

cat > "/etc/openvpn/client.ovpn" << EOF
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
verb 3
mute 20
connect-retry 5
connect-retry-max 8
explicit-exit-notify 2
pull
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/client.crt)
</cert>
<key>
$(cat /etc/openvpn/client.key)
</key>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
key-direction 1
EOF

echo "Client configuration saved to /etc/openvpn/client.ovpn"

cp "/etc/openvpn/client.ovpn" "/etc/openvpn/clients/client.ovpn" || {
  echo "Failed to copy client configuration file"
  exit 1
}

