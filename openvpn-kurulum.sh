#!/bin/bash

# Install OpenVPN server and easy-rsa package
sudo apt-get update
sudo apt-get install openvpn easy-rsa -y

# Copy easy-rsa files to OpenVPN server directory
sudo cp -r /usr/share/easy-rsa/ /etc/openvpn/

# Set up EasyRSA variables and generate CA certificate
cd /etc/openvpn/easy-rsa/
source vars
./clean-all
./build-ca

# Generate server certificate and key
./build-key-server server

# Generate Diffie-Hellman parameters
./build-dh

# Generate HMAC signature
openvpn --genkey --secret /etc/openvpn/ta.key

# Generate client certificate and key
./build-key client

# Create server configuration file
sudo touch /etc/openvpn/server.conf
echo "port 1194" | sudo tee -a /etc/openvpn/server.conf
echo "proto udp" | sudo tee -a /etc/openvpn/server.conf
echo "dev tun" | sudo tee -a /etc/openvpn/server.conf
echo "ca /etc/openvpn/easy-rsa/keys/ca.crt" | sudo tee -a /etc/openvpn/server.conf
echo "cert /etc/openvpn/easy-rsa/keys/server.crt" | sudo tee -a /etc/openvpn/server.conf
echo "key /etc/openvpn/easy-rsa/keys/server.key" | sudo tee -a /etc/openvpn/server.conf
echo "dh /etc/openvpn/easy-rsa/keys/dh2048.pem" | sudo tee -a /etc/openvpn/server.conf
echo "tls-auth /etc/openvpn/ta.key 0" | sudo tee -a /etc/openvpn/server.conf
echo "server 10.8.0.0 255.255.255.0" | sudo tee -a /etc/openvpn/server.conf
echo "ifconfig-pool-persist ipp.txt" | sudo tee -a /etc/openvpn/server.conf
echo "push \"redirect-gateway def1 bypass-dhcp\"" | sudo tee -a /etc/openvpn/server.conf
echo "push \"dhcp-option DNS 8.8.8.8\"" | sudo tee -a /etc/openvpn/server.conf
echo "keepalive 10 120" | sudo tee -a /etc/openvpn/server.conf
echo "cipher AES-256-CBC" | sudo tee -a /etc/openvpn/server.conf
echo "comp-lzo" | sudo tee -a /etc/openvpn/server.conf
echo "max-clients 10" | sudo tee -a /etc/openvpn/server.conf
echo "user nobody" | sudo tee -a /etc/openvpn/server.conf
echo "group nogroup" | sudo tee -a /etc/openvpn/server.conf
echo "persist-key" | sudo tee -a /etc/openvpn/server.conf
echo "persist-tun" | sudo tee -a /etc/openvpn/server.conf
echo "status openvpn-status.log" | sudo tee -a /etc/openvpn/server.conf
echo "verb 3" | sudo tee -a /etc/openvpn/server.conf

# Enable IP forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p

# Enable NAT on server
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Save NAT rules

sudo sh -c "iptables-save > /etc/iptables.rules"

# Add iptables-restore command to /etc/rc.local
sudo sed -i '$i \iptables-restore < /etc/iptables.rules' /etc/rc.local

# Restart OpenVPN service and enable it on startup
sudo systemctl restart openvpn.service
sudo systemctl enable openvpn.service

# Generate client configuration file
cd /etc/openvpn/easy-rsa/
./build-key client
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/easy-rsa/keys/client.ovpn
sudo sed -i 's/remote my-server-1 1194/remote <server-ip> 1194/g' /etc/openvpn/easy-rsa/keys/client.ovpn
sudo sed -i 's/proto udp/proto tcp/g' /etc/openvpn/easy-rsa/keys/client.ovpn
echo "" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "<ca>" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
cat /etc/openvpn/easy-rsa/keys/ca.crt | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "</ca>" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "<cert>" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
cat /etc/openvpn/easy-rsa/keys/client.crt | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "</cert>" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "<key>" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
cat /etc/openvpn/easy-rsa/keys/client.key | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "</key>" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "<tls-auth>" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
cat /etc/openvpn/ta.key | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn
echo "</tls-auth>" | sudo tee -a /etc/openvpn/easy-rsa/keys/client.ovpn

# Print success message
echo "OpenVPN Sunucusu kurulumu tamamlanmıştır. Bağlantı dosyası şurada yer almaktadır => /etc/openvpn/easy-rsa/keys/client.ovpn."