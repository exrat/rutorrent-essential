#!/bin/bash

# variables
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CBLUE="${CSI}1;34m"

VERSION=$(cat /etc/debian_version)
LIBTORRENT="0.13.6"
RTORRENT="0.9.6"
DEBMULTIMEDIA="2016.8.1"
NVM="0.31.3"
NODE="6.3.0"

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

