# vpn-server/Dockerfile
FROM alpine:latest

# Install required packages
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache openvpn iptables ip6tables bash curl tar openssl && \
    apk add linux-headers alpine-sdk --no-cache 

# Download and set up EasyRSA directly - with more explicit error checking and permissions
RUN mkdir -p /etc/openvpn/easy-rsa && \
    curl -L https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.2/EasyRSA-3.1.2.tgz -o /tmp/easyrsa.tgz && \
    tar xzf /tmp/easyrsa.tgz -C /tmp && \
    cp -r /tmp/EasyRSA-3.1.2/* /etc/openvpn/easy-rsa/ && \
    chmod +x /etc/openvpn/easy-rsa/easyrsa && \
    rm -rf /tmp/EasyRSA-3.1.2 /tmp/easyrsa.tgz && \
    ls -la /etc/openvpn/easy-rsa/ # Verify the files exist

# Create directories for certificates and clients
RUN mkdir -p /etc/openvpn/certs && \
    mkdir -p /etc/openvpn/clients

# Copy configuration files
COPY ./server-config/server.conf /etc/openvpn/server.conf

# Copy scripts
COPY ./scripts/start.sh /start.sh
COPY ./scripts/genovpn.sh /genovpn.sh
COPY ./scripts/check-tun.sh /check-tun.sh
COPY ./scripts/setup-routing.sh /setup-routing.sh

# Set up permissions
RUN chmod +x /start.sh && \
    chmod +x /genovpn.sh && \
    chmod +x /check-tun.sh && \
    chmod +x /setup-routing.sh && \
    sed -i 's/\r$//' /start.sh && \
    sed -i 's/\r$//' /genovpn.sh && \
    sed -i 's/\r$//' /check-tun.sh && \
    sed -i 's/\r$//' /setup-routing.sh

# Create TUN device
RUN mkdir -p /dev/net && \
    mknod /dev/net/tun c 10 200 && \
    chmod 600 /dev/net/tun

# Expose OpenVPN port
EXPOSE 1194/udp

# Start OpenVPN
CMD ["/start.sh"]
