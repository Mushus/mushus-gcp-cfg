#!/bin/bash

#
## Update Latest Packages
#

apt update -y
apt upgrade -y
sudo apt autoremove -y
