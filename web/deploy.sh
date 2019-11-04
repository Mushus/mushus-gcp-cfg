#!/bin/bash

./upgrade.sh

#
## Install nginx
#

if [ $(dpkg-query -W -f='${Status}' nano 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt install nginx -y
fi

#
## Update nginx config file
#

rm -rf /etc/nginx/sites-available/*
rm -rf /etc/nginx/sites-enabled/*

cp ./etc/nginx/sites-available/* /etc/nginx/sites-available
ls /etc/nginx/sites-available | xargs -I{} ln -s /etc/nginx/sites-available/{} /etc/nginx/sites-enabled/{}

cp -f ./etc/nginx/nginx.conf /etc/nginx/nginx.conf

service nginx restart

#
## Update startup script
#

cp -f ./etc/init.d/sagyoip /etc/init.d/sagyoip

#
## Install releases
#
DOWNLOAD_URL=$(curl https://api.github.com/repos/Mushus/sagyoip/releases/latest | jq -r '.assets[]|select(.name|test("sagyoip-linux-amd64")).browser_download_url')
wget $DOWNLOAD_URL -q -O /usr/local/bin/sagyoip
chmod 755 /usr/local/bin/sagyoip

service seagyoip restart