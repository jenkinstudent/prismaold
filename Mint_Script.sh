#!/bin/bash

# TEAMVIEWER INSTALLATION COMMENTS
sudo apt update
sudo wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
sudo apt install ./teamviewer_amd64.deb -y
sudo apt update
sudo apt-get autoremove -y 
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1