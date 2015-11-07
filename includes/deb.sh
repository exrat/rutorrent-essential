#!/bin/bash

# contrôle version debian & function
VERSION=$(cat /etc/debian_version)

function FONCDEP ()
{
echo "#depot paquet propriétaire
deb http://ftp2.fr.debian.org/debian/ "$1" main non-free
deb-src http://ftp2.fr.debian.org/debian/ "$1" main non-free" >> /etc/apt/sources.list.d/non-free.list

echo "# depot nginx
deb http://nginx.org/packages/mainline/debian/ "$1" nginx
deb-src http://nginx.org/packages/mainline/debian/ "$1" nginx" >> /etc/apt/sources.list.d/nginx.list

# clés
wget http://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg

wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
}

function FONCDEPNGINX ()
{
#apt-get install -y nginx=1.9.6-1~"$1"
apt-get install -y nginx
echo "# depot nginx
deb http://nginx.org/packages/debian/ $1 nginx
deb-src http://nginx.org/packages/debian/ $1 nginx" > /etc/apt/sources.list.d/nginx.list
}

# ajout depots
cd /tmp || exit

if [[ $VERSION =~ 7. ]]; then

DEBNUMBER="Debian_7.0.deb"
DEBNAME="wheezy"

echo "# depot dotdeb php 5.6
deb http://packages.dotdeb.org "$DEBNAME"-php56 all
deb-src http://packages.dotdeb.org "$DEBNAME"-php56 all" >> /etc/apt/sources.list.d/dotdeb-php56.list

elif [[ $VERSION =~ 8. ]]; then

DEBNUMBER="Debian_8.0.deb"
DEBNAME="jessie"

echo "# depot dotdeb
deb http://packages.dotdeb.org "$DEBNAME" all
deb-src http://packages.dotdeb.org "$DEBNAME" all" >> /etc/apt/sources.list.d/dotdeb.list

echo "# depot multimedia
deb http://www.deb-multimedia.org "$DEBNAME" main non-free" >> /etc/apt/sources.list.d/multimedia.list

# clé ffmpeg
wget http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/"$MULTIMEDIA"
dpkg -i "$MULTIMEDIA"

else
	set "130" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" ; echo ""
	exit 1
fi

# depots standard
FONCDEP "$DEBNAME"
