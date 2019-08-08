#!/bin/bash -e

# Fix unreliable hostapd service causing failed access point
sudo systemctl enable hostapd

sudo curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
sudo curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
sudo echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt-get remove cmdtest nodejs -y
sudo apt-get update
sudo apt-get install nodejs yarn -y

sudo yarn add global react-scripts serve

cd /opt/mission-mule/data-mule-server
sudo yarn setup
cd client
sudo yarn build
