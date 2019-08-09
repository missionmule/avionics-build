#!/bin/bash -e

# Disable Bluetooth by appending to config file
echo "Disabling onboard Bluetooth"
echo "dtoverlay=pi3-disable-bt" >> /boot/config.txt

# Setting new hostname (muleOS)
echo "muleOS" > /etc/hostname
echo "127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       muleOS" > /etc/hosts

# Set up wireless access point
sudo apt install dnsmasq hostapd nginx -y

sudo systemctl stop dnsmasq
sudo systemctl stop hostapd

echo "Configuring wireless access point..."

echo "Installing dhcpcd.conf"
install -m 644 -v files/dhcpcd.conf "/etc/"
sudo service dhcpcd restart

echo "Installing dnsmasq.conf"
install -m 644 -v files/dnsmasq.conf  "/etc/"
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq
sudo systemctl reload dnsmasq

echo "Installing hostapd.conf"
sudo systemctl unmask hostapd.service
install -v -d	"/etc/hostapd"
install -m 644 -v files/hostapd.conf  "/etc/hostapd/"

echo "Installing hostapd"
install -m 755 -v files/hostapd "/etc/default/"
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd

echo "Installing sysctl.conf"
install -m 644 -v files/sysctl.conf "/etc/"

echo "Installing 72-wlan-geo-dependent.rules"
install -m 644 -v files/72-wlan-geo-dependent.rules "/etc/udev/rules.d/"

echo "Adding IP tables"
rm -rf "/etc/rc.local"
install -m 644 -v files/rc.local "/etc/"
sudo iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

echo "Wireless access point configuration complete"

echo "Setting up avionics firmware"

# Set up avionics firmware
sudo apt-get install python3-pip python3-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev software-properties-common -y

pip3 install future
pip3 install lxml
pip3 install paramiko
pip3 install pyserial

sudo mkdir -p /opt/mission-mule

sudo mkdir -p /home/pi/.ssh
sudo touch /home/pi/.ssh/known_hosts

cd /opt/mission-mule && git clone -v https://github.com/missionmule/firefly-mule.git
cd /opt/mission-mule/firefly-mule && pip3 install -r /opt/mission-mule/firefly-mule/requirements.txt

sudo mkdir -p /srv/
sudo chown pi:pi -R /srv/
sudo chmod 755 /srv/

echo "Avionics firmware setup complete"

echo "Setting up web server"

cd /opt/mission-mule && git clone -v https://github.com/missionmule/data-mule-server.git

sudo rm -rf /etc/nginx/sites-available/default

cd /home/pi/avionics-build
install -m 644 files/mission-mule-avionics.service   "/lib/systemd/system/"
install -m 644 files/mission-mule-client.service   "/lib/systemd/system/"
install -m 644 files/mission-mule-server.service   "/lib/systemd/system/"
install -m 644 files/default   "/etc/nginx/sites-available/"

sudo systemctl enable mission-mule-avionics
sudo systemctl disable hciuart
sudo systemctl enable mission-mule-client
sudo systemctl enable mission-mule-server
sudo systemctl enable nginx

# Add web server and client

sudo curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
sudo curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt-get remove cmdtest nodejs -y
sudo apt-get update
sudo apt-get install nodejs yarn -y

sudo yarn add global react-scripts serve

cd /opt/mission-mule/data-mule-server
sudo yarn setup
cd client
sudo yarn build

echo "Payload firmware successfully built"
