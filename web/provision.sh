#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
APT_NGINX_NAME=nginx
APT_JQ_NAME=jq
CERTBOT_CMD=certbot-auto
./upgrade.sh

#
## create dirs
#

mkdir -p /var/www/sagyoipe.mushus.net
mkdir -p /var/log/sagyoipe

#
## Install nginx
#

if [ $(dpkg-query -W -f='${Status}' $APT_NGINX_NAME 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt install $APT_NGINX_NAME -y
fi

if [ $(dpkg-query -W -f='${Status}' $APT_JQ_NAME 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt install $APT_JQ_NAME -y
fi

#
## Install Sagyoipe latest releases
#

DOWNLOAD_URL=$( \
  curl -s https://api.github.com/repos/Mushus/sagyoipe/releases/latest | \
  jq -r '.assets[]|select(.name|test("sagyoipe-linux-amd64")).browser_download_url' \
)
curl -s -L -o /usr/local/bin/sagyoipe $DOWNLOAD_URL
chmod 755 /usr/local/bin/sagyoipe

cp -f ${SCRIPT_DIR}/etc/systemd/system/sagyoipe.service /etc/systemd/system/sagyoipe.service
systemctl enable sagyoipe

service sagyoipe restart

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
## Install certbot-auto
#

if !(type $CERTBOT_CMD > /dev/null 2>&1); then
  curl -s -L -o /usr/local/bin/$CERTBOT_CMD https://dl.eff.org/certbot-auto
  chmod a+x /usr/local/bin/$CERTBOT_CMD
  certbot-auto certonly \
    --non-interactive \
    --agree-tos \
    --email mushus.wynd@gmail.com \
    --webroot \
    --webroot-path /var/www/sagyoipe.mushus.net \
    --domain sagyoipe.mushus.net
fi