#!/bin/bash -e

# Getting permission to make admin changes
sudo su

# Update to the latest public packages
echo "Upgrading and updating packages"
apt-get update -y
apt-get upgrade -y

# Enable SSH
echo "Enabling SSH"
systemctl enable ssh
sudo systemctl start ssh

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

# Set up DHCP interfaces
echo "auto lo

iface lo inet loopback
iface eth0 inet dhcp" >> /etc/network/interfaces

# Set up IP tables
echo "iptables-restore < /etc/iptables.ipv4.nat

exit 0" > /etc/rc.local

# Set up wireless access point
apt-get install dnsmasq hostapd nginx -y

echo "Configuring wireless access point..."

echo "Installing dhcpcd.conf"
install -m 644 -v files/dhcpcd.conf "/etc/"

echo "Installing dnsmasq.conf"
install -m 644 -v files/dnsmasq.conf  "/etc/"

echo "Installing hostapd.conf"
install -v -d	"/etc/hostapd"
install -m 644 -v files/hostapd.conf  "/etc/hostapd/"

echo "Installing hostapd"
install -m 755 -v files/hostapd "/etc/default/"

echo "Installing sysctl.conf"
install -m 644 -v files/sysctl.conf "/etc/"

echo "Installing 72-wlan-geo-dependent.rules"
install -m 644 -v files/72-wlan-geo-dependent.rules "/etc/udev/rules.d/"

echo "Wireless access point configuration complete"

iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
sh -c "iptables-save > /etc/iptables.ipv4.nat"

systemctl enable hostapd
systemctl enable dnsmasq

# Set up avionics firmware
apt-get install python3-pip python3-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev software-properties-common -y

pip3 install future
pip3 install lxml
pip3 install paramiko
pip3 install pyserial

mkdir -p /opt/mission-mule

mkdir -p /home/pi/.ssh
touch /home/pi/.ssh/known_hosts

cd /opt/mission-mule && git clone -v https://github.com/missionmule/firefly-mule.git
cd /opt/mission-mule/firefly-mule && pip3 install -r /opt/mission-mule/firefly-mule/requirements.txt
cd /opt/mission-mule && git clone -v https://github.com/missionmule/data-mule-server.git

rm -rf /etc/nginx/sites-available/default

mkdir -p /srv/
chown pi:pi -R /srv/
chmod 755 /srv/

install -m 644 files/mission-mule-avionics.service   "/lib/systemd/system/"
install -m 644 files/mission-mule-client.service   "/lib/systemd/system/"
install -m 644 files/mission-mule-server.service   "/lib/systemd/system/"
install -m 644 files/default   "/etc/nginx/sites-available/"
install -m 644 files/setup.sh   "/opt/mission-mule/"

systemctl enable mission-mule-avionics
systemctl disable hciuart
systemctl enable mission-mule-client
systemctl enable mission-mule-server
systemctl enable nginx
systemctl enable hostapd
systemctl enable dnsmasq

# Add web server and client
apt-get install apache2 -y

curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

apt-get remove cmdtest nodejs -y
apt-get update
apt-get install nodejs yarn -y

yarn add global react-scripts serve

cd /opt/mission-mule/data-mule-server
yarn setup
cd client
yarn build

rm -rf /var/www/html
mkdir -p /var/www/html

cd /var/www/html && git clone -v https://github.com/missionmule/data-mule-server.git .

mkdir -p /srv/flight-data/field
mkdir -p /srv/flight-data/logs

rm -rf /etc/apache2/apache2.conf

install -m 755 files/apache2.conf   "/etc/apache2/apache2.conf"

chown pi:pi -R /srv/
chmod 755 /srv/
