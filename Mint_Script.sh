#!/bin/bash

# TEAMVIEWER INSTALLATION COMMENTS
sudo apt update
sudo wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
sudo apt install ./teamviewer_amd64.deb -y
sudo apt update
sudo apt-get autoremove -y
# Boot Kernal disable ipv6
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash ipv6.disable=1"/g' /etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/g' /etc/default/grub
sudo sudo update-grub
#Disable IPV6 network interface
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sudo sysctl -p	
sysctl -a 2>/dev/null | grep disable_ipv6
