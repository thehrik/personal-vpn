#!/bin/sh

# vpn-server/scripts/start.sh

# Enable verbose output for debugging
set -x

# Check if the tun device exists
# if not then create it
/bin/sh /check-tun.sh
/bin/sh /setup-routing.sh

# Unset potentially conflicting environment variables
unset EASYRSA EASYRSA_PATH EASYRSA_PKI

# Debug: Show current directory and list contents
echo "setting up EASYRSA_PATH environment variable"
EASYRSA_PATH="/etc/openvpn/easy-rsa"

# Explicitly define log file
echo "setting up EASYRSA_LOG environment variable"
EASYRSA_LOG="$EASYRSA_PATH/easyrsa.log"

echo "setting up EASYRSA_PKI environment variable"
export EASYRSA_PKI="$EASYRSA_PATH/pki"

# Change to EasyRSA directory
cd "$EASYRSA_PATH" || {
  echo "Failed to change to EasyRSA directory"
  exit 1
}

echo "Current directory after cd: $(pwd)"
echo "Listing current directory contents:"
ls -la

# Define the desired vars content
desired_vars_content=$(
  cat <<EOF
set_var EASYRSA_REQ_COUNTRY     "IN"
set_var EASYRSA_REQ_PROVINCE    "West Bengal"
set_var EASYRSA_REQ_CITY        "Kolkata"
set_var EASYRSA_REQ_ORG         "PDNet"
set_var EASYRSA_REQ_EMAIL       "hrik05malakar@gmail.com"
set_var EASYRSA_REQ_OU          "PDNet VPN"
set_var EASYRSA_REQ_CN          "PDNet CA"
set_var EASYRSA_KEY_SIZE        2048
set_var EASYRSA_ALGO            rsa
set_var EASYRSA_CA_EXPIRE       3650
set_var EASYRSA_CERT_EXPIRE     3650
set_var EASYRSA_DIGEST          "sha256"
EOF
)

# Function to perform the EasyRSA setup
perform_easyrsa_setup() {
  echo "Performing EasyRSA setup..."

  # Create new variables directory if not exists
  if [ ! -d "$EASYRSA_PATH/variables" ]; then
    mkdir -p "$EASYRSA_PATH/variables" || {
      echo "Failed to create variables directory"
      exit 1
    }
  fi

  # Create or update vars file
  echo "$desired_vars_content" >"$EASYRSA_PATH/variables/vars" || {
    echo "Failed to create/update vars file"
    exit 1
  }

  # Removing vars.example if it exists
  if [ -f "$EASYRSA_PATH/vars.example" ]; then
    echo "Removing old vars.example file..."
    rm -f "$EASYRSA_PATH/vars.example"
  else
    echo "No existing vars.example file found."
  fi

  # Set up EasyRSA environment
  export EASYRSA="$EASYRSA_PATH"

  # Check OpenSSL version
  echo "OpenSSL version:"
  openssl version

  # Check EasyRSA version
  echo "EasyRSA version:"
  ./easyrsa --version

  # Initialize the PKI
  echo "Initializing PKI..."
  ./easyrsa --vars="$EASYRSA_PATH/variables/vars" init-pki || {
    echo "EasyRSA init-pki failed"
    exit 1
  }

  # Build the CA (with more detailed error output)
  echo "Building CA..."
  ./easyrsa --vars="$EASYRSA_PATH/variables/vars" --batch build-ca nopass 2>&1 | tee "$EASYRSA_LOG" || {
    echo "CA creation failed with exit code $?"
    echo "Checking for error logs:"
    cat "$EASYRSA_LOG" 2>/dev/null || echo "No log file found"
    exit 1
  }

  echo "Generating Server Certificate..."
  ./easyrsa --batch build-server-full server nopass 2>&1 | tee "$EASYRSA_LOG" || {
    echo "Server key generation failed"
    exit 1
  }

  echo "Generating DH parameters..."
  ./easyrsa --batch gen-dh 2>&1 | tee "$EASYRSA_LOG" || {
    echo "DH parameters generation failed"
    exit 1
  }

  echo "Generating Client Certificate..."
  ./easyrsa --batch build-client-full client nopass 2>&1 | tee "$EASYRSA_LOG" || {
    echo "Client key generation failed"
    exit 1
  }

  # Generate TLS auth key
  echo "Generating TLS auth key..."
  openvpn --genkey secret /etc/openvpn/ta.key || {
    echo "ta.key generation failed"
    exit 1
  }

  #Copy certificates and keys to OpenVPN directory
  echo "Copying certificates and keys to OpenVPN directory..."
  cp "$EASYRSA_PKI/ca.crt" \
    "$EASYRSA_PKI/dh.pem" \
    "$EASYRSA_PKI/issued/server.crt" \
    "$EASYRSA_PKI/private/server.key" \
    "$EASYRSA_PKI/issued/client.crt" \
    "$EASYRSA_PKI/private/client.key" \
    /etc/openvpn/ || {
    echo "File copy failed"
    exit 1
  }
  
  echo "Creating certs-and-keys directory..."
  mkdir -p /etc/openvpn/certs-and-keys

  echo "Copying certificates and keys to certs-and-keys directory..."
  cp "$EASYRSA_PKI/ca.crt" \
    "/etc/openvpn/ta.key" \
    "$EASYRSA_PKI/issued/client.crt" \
    "$EASYRSA_PKI/private/client.key" \
    /etc/openvpn/certs-and-keys/ || {
    echo "File copy failed"
    exit 1
  }
}

# Check if vars file exists and compare content
if [ -f "$EASYRSA_PATH/variables/vars" ]; then
  existing_vars_content=$(cat "$EASYRSA_PATH/variables/vars")
  if [ "$existing_vars_content" != "$desired_vars_content" ]; then
    echo "vars file content has changed. Recreating certificates..."
    perform_easyrsa_setup
  else
    echo "vars file content is the same. Skipping EasyRSA setup."
  fi
else
  echo "vars file does not exist. Creating certificates..."
  perform_easyrsa_setup
fi

# Generate client .ovpn file
echo "Generating client .ovpn file..."
/bin/sh /genovpn.sh &

# Start OpenVPN server
echo "Starting OpenVPN server..."
openvpn --config /etc/openvpn/server.conf || {
  echo "OpenVPN server failed to start"
  exit 1
}
