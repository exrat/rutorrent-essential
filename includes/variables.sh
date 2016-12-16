#!/bin/bash

# variables
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CBLUE="${CSI}1;34m"

VERSION=$(cat /etc/debian_version)

if [[ $VERSION =~ 7. ]]; then
	DEBNUMBER="Debian_7.0.deb"
	DEBNAME="wheezy"
	PHPPATH="/etc/php5"
	PHPNAME="php5"
	PHPSOCK="/var/run/php5-fpm.sock"
elif [[ $VERSION =~ 8. ]]; then
	DEBNUMBER="Debian_8.0.deb"
	DEBNAME="jessie"
	# PHPPATH="/etc/php/7.0"
	# PHPNAME="php7.0"
	# PHPSOCK="/run/php/php7.0-fpm.sock"
	PHPPATH="/etc/php5"
	PHPNAME="php5"
	PHPSOCK="/var/run/php5-fpm.sock"
fi

if [[ $(uname -m) == i686 ]]; then
	SYS="i386"
elif [[ $(uname -m) == x86_64 ]]; then
	SYS="amd64"
fi

LIBTORRENT="0.13.6"
RTORRENT="0.9.6"
# DEBMULTIMEDIA="2016.8.1"
NVM="0.32.1"
NODE="7.2.0"
LIBZEN0="0.4.34"
LIBMEDIAINFO0="0.7.91"
MEDIAINFO="0.7.91"

RUTORRENT="/var/www/rutorrent"
RUPLUGINS="/var/www/rutorrent/plugins"
RUCONFUSER="/var/www/rutorrent/conf/users"
ESSENTIAL="/tmp/rutorrent-essential"
FILES="/tmp/rutorrent-essential/files"
SBM="/var/www/seedbox-manager"
SBMCONFUSER="/var/www/seedbox-manager/conf/users"
NGINX="/etc/nginx"
NGINXWEB="/var/www"
NGINXBASE="/var/www/base"
NGINXPASS="/etc/nginx/passwd"
NGINXENABLE="/etc/nginx/sites-enabled"
NGINXSSL="/etc/nginx/ssl"
NGINXCONFD="/etc/nginx/conf.d"
SOURCES="/etc/apt/sources.list.d"
WDATA="www-data:www-data"


RAPPORT="/tmp/rapport.txt"
NOYAU=$(uname -r)
DATE=$(date +"%d-%m-%Y à %H:%M")
NGINX_VERSION=$(2>&1 nginx -v | grep -Eo "[0-9.+]{1,}")
RTORRENT_VERSION=$(rtorrent -h | grep -E -o "[0-9]\.[0-9].[0-9]{1,}")
PHP_VERSION=$(php -v | cut -c 1-7 | grep PHP | cut -c 5-7)
