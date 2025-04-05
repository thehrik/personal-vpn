# Setup a personal VPN

how to setup 

- get your docker environment up and running

- create a .env file with the following content
  ```
  SERVER_IP=192.168.1.100 # this will be your server ip
  ```

- run this command in the root driectory of this project
  ```
  docker build -t personal-vpn .
  ```

  ```
  docker run -d -p 80:80 -p 443:443 --name personal-vpn personal-vpn
  ```

- copy the client.ovpn file from ```pdnetserver-data/clients/client.ovpn``` to your local machine or android device or ios device

- download OpenVPN client from https://openvpn.net/community-downloads/ or from play store or app store

- import the client.ovpn file into the OpenVPN client

- connect to the server