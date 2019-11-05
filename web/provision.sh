#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
APT_NGINX_NAME=nginx
APT_JQ_NAME=jq
CERTBOT_CMD=certbot-auto

echo "[UPGRADE]"
./upgrade.sh

#
## create dirs
#

echo "[CREATE DIR]"
mkdir -p /var/www/sagyoipe.mushus.net
mkdir -p /var/log/sagyoipe
mkdir -p /etc/letsencrypt/live/sagyoipe.mushus.net/

#
## Install dependencies
#

echo "[INSTALL DEPENDENCIES]"

if [ $(dpkg-query -W -f='${Status}' $APT_NGINX_NAME 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt install $APT_NGINX_NAME -y
fi

if [ $(dpkg-query -W -f='${Status}' $APT_JQ_NAME 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt install $APT_JQ_NAME -y
fi

#
## Install Sagyoipe latest releases
#

echo "[INSTALL SAGYOIPE]"

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

echo "[UPDATE NGINX CONFIG]"

rm -rf /etc/nginx/sites-available/*
rm -rf /etc/nginx/sites-enabled/*

cp ${SCRIPT_DIR}/etc/nginx/sites-available/* /etc/nginx/sites-available

if [ -e /etc/letsencrypt/live/sagyoipe.mushus.net/fullchain.pem ]; then
  ln -s /etc/nginx/sites-available/sagyoipe.mushus.net /etc/nginx/sites-enabled/sagyoipe.mushus.net
else
  ln -s /etc/nginx/sites-available/nonssl.sagyoipe.mushus.net /etc/nginx/sites-enabled/dummy.sagyoipe.mushus.net
fi

cp -f ${SCRIPT_DIR}/etc/nginx/nginx.conf /etc/nginx/nginx.conf

service nginx restart

#
## Install certbot-auto
#

echo "[INSTALL CERTBOT]"

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

#
## Update nginx config file
#

echo "[RESTART NGINX]"

NEED_RESTART=false

if [ -e /etc/nginx/sites-enabled/dummy.sagyoipe.mushus.net ]; then
  unlink /etc/nginx/sites-available/dummy.sagyoipe.mushus.net /etc/nginx/sites-enabled/dummy.sagyoipe.mushus.net
  ln -s /etc/nginx/sites-available/sagyoipe.mushus.net /etc/nginx/sites-enabled/sagyoipe.mushus.net
  NEED_RESTART=true
fi

if "${NEED_RESTART}"; then
  service nginx restart
fi