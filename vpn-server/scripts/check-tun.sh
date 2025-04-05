#!/bin/sh

# vpn-server/scripts/check-tun.sh

# Create the TUN device if it doesn't exist
if [ ! -c /dev/net/tun ]; then
  echo "Creating TUN device..."
  mkdir -p /dev/net
  mknod /dev/net/tun c 10 200
  chmod 600 /dev/net/tun
fi

# Verify the TUN device exists
if [ ! -c /dev/net/tun ]; then
  echo "Error: TUN device creation failed"
  exit 1
fi

echo "TUN device is ready"
