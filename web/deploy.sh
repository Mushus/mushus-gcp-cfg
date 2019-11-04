#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)

./upgrade.sh

#
## Install nginx
#

APT_NGINX_NAME=nginx
if [ $(dpkg-query -W -f='${Status}' $APT_NGINX_NAME 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt install $APT_NGINX_NAME -y
fi

#
## Update nginx config file
#

rm -rf /etc/nginx/sites-available/*
rm -rf /etc/nginx/sites-enabled/*

cp ${SCRIPT_DIR}/etc/nginx/sites-available/* /etc/nginx/sites-available
ls /etc/nginx/sites-available | xargs -I{} ln -s /etc/nginx/sites-available/{} /etc/nginx/sites-enabled/{}

cp -f ${SCRIPT_DIR}/etc/nginx/nginx.conf /etc/nginx/nginx.conf

service nginx restart

#
## Update startup script
#

cp -f ${SCRIPT_DIR}/etc/init.d/sagyoipe /etc/init.d/sagyoipe

#
## Install releases
#
DOWNLOAD_URL=$(curl https://api.github.com/repos/Mushus/sagyoipe/releases/latest | jq -r '.assets[]|select(.name|test("sagyoipe-linux-amd64")).browser_download_url')
wget -q -O /usr/local/bin/sagyoipe $DOWNLOAD_URL
chmod 755 /usr/local/bin/sagyoipe

service seagyoip restart