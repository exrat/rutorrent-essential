#!/bin/bash

# variables
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CBLUE="${CSI}1;34m"

LIBTORRENT="0.13.6"
RTORRENT="0.9.6"
MULTIMEDIA="deb-multimedia-keyring_2016.3.7_all.deb"
NVM="0.31.0"
NODE="5.3.0"

RUTORRENT="/var/www/rutorrent"
ESSENTIAL="/tmp/rutorrent-essential"
FILES="/tmp/rutorrent-essential/files"
SBM="/var/www/seedbox-manager"
NGINX="/etc/nginx"
NGINXPASS="/etc/nginx/passwd"
NGINXENABLE="/etc/nginx/sites-enabled"
NGINXSSL="/etc/nginx/ssl"

