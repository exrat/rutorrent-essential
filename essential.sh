#!/bin/bash -i
#
# Script d'installation ruTorrent / Nginx
# Auteur : Ex_Rat
#
# Nécessite Debian 7 ou 8 (32/64 bits) & un serveur fraîchement installé
#
# Multi-utilisateurs
# Inclus VsFTPd (ftp & ftps sur le port 21), Fail2ban (avec conf nginx, ftp & ssh)
# Seedbox-Manager, Auteurs: Magicalex, Hydrog3n et Backtoback
#
# Tiré du tutoriel de Magicalex pour mondedie.fr disponible ici:
# http://mondedie.fr/viewtopic.php?id=5302
#
# Merci Aliochka & Meister pour les conf de Munin et VsFTPd
# à Albaret pour le coup de main sur la gestion d'users, LetsGo67 pour ses rectifs et
# Jedediah pour avoir joué avec le html/css du thème.
# Aux traducteurs: Sophie, Spectre, Hardware, Zarev, SirGato, MiguelSam, Hierra.
#
# Installation:
#
# apt-get update && apt-get upgrade -y
# apt-get install git-core -y
#
# cd /tmp
# git clone https://github.com/exrat/rutorrent-essential
# cd rutorrent-essential
# chmod a+x essential.sh && ./essential.sh
#
# Pour gérer vos utilisateurs ultérieurement, il vous suffit de relancer le script
#
# This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License


#  includes
INCLUDES="includes"
# shellcheck source=/dev/null
. "$INCLUDES"/variables.sh
# shellcheck source=/dev/null
. "$INCLUDES"/langues.sh
# shellcheck source=/dev/null
. "$INCLUDES"/functions.sh

# contrôle droits utilisateur & OS
FONCCONTROL
FONCBASHRC
clear

# Contrôle installation
if [ ! -f "$NGINXENABLE"/rutorrent.conf ]; then

# log de l'installation
exec > >(tee "/tmp/install.log")  2>&1

####################################
# lancement installation ruTorrent #
####################################

# message d'accueil
echo "" ; set "102" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}" ; echo ""
# shellcheck source=/dev/null
. "$INCLUDES"/logo.sh

echo "" ; set "298" ; FONCTXT "$1" ; echo -e "${CYELLOW}$TXT1${CEND}"
set "106" ; FONCTXT "$1" ; echo -e "${CYELLOW}$TXT1${CEND}" ; echo ""

# demande nom et mot de passe
while :; do
set "108" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1 ${CEND}"
FONCUSER
done

echo ""
while :; do
set "112" "114" "116" ; FONCTXT "$1" "$2" "$3" ; echo -e "${CGREEN}$TXT1${CEND}${CYELLOW}$TXT2${CEND}${CGREEN}$TXT3 ${CEND}"
FONCPASS
done

PORT=5001

# choix installation vsftpd & seedbox-manager
echo "" ; set "300" ; FONCTXT "$1" ; echo -n -e "${CGREEN}$TXT1 ${CEND}"
FONCCHOISE

# récupération 5% root sur /home ou /home/user si présent
FSHOME=$(df -h | grep /home | cut -c 6-9)
if [ "$FSHOME" = "" ]; then
	echo
else
	tune2fs -m 0 /dev/"$FSHOME" &> /dev/null
	mount -o remount /home &> /dev/null
fi

FONCFSUSER "$USER"

# variable passe nginx
PASSNGINX=${USERPWD}

# ajout utilisateur
useradd -M -s /bin/bash "$USER"

# création du mot de passe utilisateur
echo "${USER}:${USERPWD}" | chpasswd

# anti-bug /home/user déjà existant
mkdir -p /home/"$USER"
chown -R "$USER":"$USER" /home/"$USER"

# variable utilisateur majuscule
USERMAJ=$(echo "$USER" | tr "[:lower:]" "[:upper:]")

#récupération ip serveur
FONCIP

# récupération threads & sécu -j illimité
THREAD=$(grep -c processor < /proc/cpuinfo)
if [ "$THREAD" = "" ]; then
    THREAD=1
fi

# ajout depots
# shellcheck source=/dev/null
. "$INCLUDES"/deb.sh

# bind9 & dhcp
if [ ! -d /etc/bind ]; then
	rm /etc/init.d/bind9 &> /dev/null
	apt-get install -y bind9
fi

if [ -f /etc/dhcp/dhclient.conf ]; then
	sed -i "s/#prepend domain-name-servers 127.0.0.1;/prepend domain-name-servers 127.0.0.1;/g;" /etc/dhcp/dhclient.conf
fi

cp -f "$FILES"/bind/named.conf.options /etc/bind/named.conf.options

sed -i '/127.0.0.1/d' /etc/resolv.conf # pour éviter doublon
echo "nameserver 127.0.0.1" >> /etc/resolv.conf
FONCSERVICE restart bind9

# installation des paquets
apt-get update && apt-get upgrade -y
echo "" ; set "132" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

apt-get install -y htop openssl apt-utils python build-essential libssl-dev pkg-config automake libcppunit-dev libtool whois libcurl4-openssl-dev libsigc++-2.0-dev libncurses5-dev vim nano ccze screen subversion apache2-utils curl "$PHPNAME" "$PHPNAME"-cli "$PHPNAME"-fpm "$PHPNAME"-curl "$PHPNAME"-geoip  unrar rar zip buildtorrent fail2ban ntp ntpdate ffmpeg aptitude dnsutils irssi  libarchive-zip-perl  libjson-perl libjson-xs-perl libxml-libxslt-perl nginx

#if [[ $VERSION =~ 8. ]]; then
#apt-get install -y "$PHPNAME"-xml "$PHPNAME"-mbstring
#fi

echo "" ; set "136" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

# génération clé 2048 bits
openssl dhparam -out dhparams.pem 2048 >/dev/null 2>&1 &

# téléchargement complément favicon
wget -T 10 -t 3 http://www.bonobox.net/script/favicon.tar.gz || wget -T 10 -t 3 http://alt.bonobox.net/favicon.tar.gz
tar xzfv favicon.tar.gz

# Config ntp & réglage heure fr
if [ "$BASELANG" = "fr" ]; then
echo "Europe/Paris" > /etc/timezone
cp -f /usr/share/zoneinfo/Europe/Paris /etc/localtime

sed -i "s/server 0/#server 0/g;" /etc/ntp.conf
sed -i "s/server 1/#server 1/g;" /etc/ntp.conf
sed -i "s/server 2/#server 2/g;" /etc/ntp.conf
sed -i "s/server 3/#server 3/g;" /etc/ntp.conf

echo "
server 0.fr.pool.ntp.org
server 1.fr.pool.ntp.org
server 2.fr.pool.ntp.org
server 3.fr.pool.ntp.org">> /etc/ntp.conf

ntpdate -d 0.fr.pool.ntp.org
fi

# installation XMLRPC LibTorrent rTorrent
# svn checkout http://svn.code.sf.net/p/xmlrpc-c/code/advanced xmlrpc-c
svn checkout http://svn.code.sf.net/p/xmlrpc-c/code/stable xmlrpc-c
if [ ! -d /tmp/xmlrpc-c ]; then
	wget http://bonobox.net/script/xmlrpc-c.tar.gz
	tar xzfv xmlrpc-c.tar.gz
fi

cd xmlrpc-c || exit
./configure #--disable-cplusplus
make -j "$THREAD"
make install
echo "" ; set "140" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

# clone rTorrent et libTorrent
cd .. || exit
git clone https://github.com/rakshasa/libtorrent.git
git clone https://github.com/rakshasa/rtorrent.git

# libTorrent compilation
if [ ! -d /tmp/libtorrent ]; then
	wget http://rtorrent.net/downloads/libtorrent-"$LIBTORRENT".tar.gz
	tar xzfv libtorrent-"$LIBTORRENT".tar.gz
	mv libtorrent-"$LIBTORRENT" libtorrent
	cd libtorrent || exit
else
	cd libtorrent || exit
	git checkout "$LIBTORRENT"
fi

./autogen.sh
./configure
make -j "$THREAD"
make install
echo "" ; set "142" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1 $LIBTORRENT${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

# rTorrent compilation
if [ ! -d /tmp/rtorrent ]; then
	cd /tmp || exit
	wget http://rtorrent.net/downloads/rtorrent-"$RTORRENT".tar.gz
	tar xzfv rtorrent-"$RTORRENT".tar.gz
	mv rtorrent-"$RTORRENT" rtorrent
	cd rtorrent || exit
else
cd ../rtorrent || exit
git checkout "$RTORRENT"
fi

./autogen.sh
./configure --with-xmlrpc-c
make -j "$THREAD"
make install
ldconfig
echo "" ; set "144" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1 $RTORRENT${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

# création des dossiers
su "$USER" -c 'mkdir -p ~/watch ~/torrents ~/.session '

# création accueil serveur
mkdir -p "$NGINXWEB"
cp -R "$ESSENTIAL"/base "$NGINXBASE"

# téléchargement et déplacement de rutorrent
git clone https://github.com/Novik/ruTorrent.git "$RUTORRENT"
echo "" ; set "146" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

# installation des Plugins
cd "$RUPLUGINS" || exit

for PLUGINS in 'logoff' 'chat' 'lbll-suite' 'nfo' 'titlebar' 'filemanager' 'fileshare' 'ratiocolor' 'pausewebui'; do
cp -R "$ESSENTIAL"/plugins/"$PLUGINS" "$RUPLUGINS"/; done

# ajout thèmes
git clone git://github.com/Phlooo/ruTorrent-MaterialDesign.git "$RUPLUGINS"/theme/themes/MaterialDesign

# configuration filemanager
cp -f "$FILES"/rutorrent/filemanager.conf "$RUPLUGINS"/filemanager/conf.php

# configuration create
# shellcheck disable=SC2154
sed -i "s#$useExternal = false;#$useExternal = 'buildtorrent';#" "$RUPLUGINS"/create/conf.php
# shellcheck disable=SC2154
sed -i "s#$pathToCreatetorrent = '';#$pathToCreatetorrent = '/usr/bin/buildtorrent';#" "$RUPLUGINS"/create/conf.php

# configuration fileshare
chown -R "$WDATA" "$RUPLUGINS"/fileshare
ln -s "$RUPLUGINS"/fileshare/share.php "$NGINXBASE"/share.php

# configuration share.php
cp -f "$FILES"/rutorrent/fileshare.conf "$RUPLUGINS"/fileshare/conf.php
sed -i "s/@IP@/$IP/g;" "$RUPLUGINS"/fileshare/conf.php

# configuration logoff
sed -i "s/scars,user1,user2/$USER/g;" "$RUPLUGINS"/logoff/conf.php

# configuration autodl-irssi
git clone https://github.com/autodl-community/autodl-rutorrent.git autodl-irssi
cp -f autodl-irssi/_conf.php autodl-irssi/conf.php
touch autodl-irssi/css/materialdesign.min.css
FONCIRSSI "$USER" "$PORT" "$USERPWD"

# mediainfo
cd "$ESSENTIAL" || exit
# shellcheck source=/dev/null
. "$INCLUDES"/mediainfo.sh

# favicons trackers
cp -f /tmp/favicon/*.png "$RUPLUGINS"/tracklabels/trackers/

echo "" ; set "148" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

# liens symboliques et permissions
ldconfig
chown -R "$WDATA" "$RUTORRENT"
chmod -R 777 "$RUPLUGINS"/filemanager/scripts
chown -R "$WDATA" "$NGINXBASE"

# php
sed -i "s/2M/10M/g;" "$PHPPATH"/fpm/php.ini
sed -i "s/8M/10M/g;" "$PHPPATH"/fpm/php.ini
sed -i "s/expose_php = On/expose_php = Off/g;" "$PHPPATH"/fpm/php.ini

if [ "$BASELANG" = "fr" ]; then
	sed -i "s/^;date.timezone =/date.timezone = Europe\/Paris/g;" "$PHPPATH"/fpm/php.ini
	sed -i "s/^;date.timezone =/date.timezone = Europe\/Paris/g;" "$PHPPATH"/cli/php.ini
else
	sed -i "s/^;date.timezone =/date.timezone = UTC/g;" "$PHPPATH"/fpm/php.ini
	sed -i "s/^;date.timezone =/date.timezone = UTC/g;" "$PHPPATH"/cli/php.ini
fi

sed -i "s/^;listen.owner = www-data/listen.owner = www-data/g;" "$PHPPATH"/fpm/pool.d/www.conf
sed -i "s/^;listen.group = www-data/listen.group = www-data/g;" "$PHPPATH"/fpm/pool.d/www.conf
sed -i "s/^;listen.mode = 0660/listen.mode = 0660/g;" "$PHPPATH"/fpm/pool.d/www.conf

FONCSERVICE restart "$PHPNAME"-fpm
echo "" ; set "150" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

mkdir -p "$NGINXPASS" "$NGINXSSL"
touch "$NGINXPASS"/rutorrent_passwd
chmod 640 "$NGINXPASS"/rutorrent_passwd

# configuration serveur web
mkdir "$NGINXENABLE"
cp -f "$FILES"/nginx/nginx.conf "$NGINX"/nginx.conf
cp -f "$FILES"/nginx/php.conf "$NGINXCONFD"/php.conf
sed -i "s|@PHPSOCK@|$PHPSOCK|g;" "$NGINXCONFD"/php.conf
cp -f "$FILES"/nginx/cache.conf "$NGINXCONFD"/cache.conf
cp -f "$FILES"/nginx/ciphers.conf "$NGINXCONFD"/ciphers.conf

cp -f "$FILES"/rutorrent/rutorrent.conf "$NGINXENABLE"/rutorrent.conf
for VAR in "${!NGINXCONFD@}" "${!NGINXBASE@}" "${!NGINXSSL@}" "${!NGINXPASS@}" "${!NGINXWEB@}" "${!SBM@}"; do
sed -i "s|@${VAR}@|${!VAR}|g;" "$NGINXENABLE"/rutorrent.conf; done

echo "" ; set "152" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

# ssl configuration #

#!/bin/bash

openssl req -new -x509 -days 3658 -nodes -newkey rsa:2048 -out "$NGINXSSL"/server.crt -keyout "$NGINXSSL"/server.key<<EOF
RU
Russia
Moskva
wtf
wtf LTD
wtf.org
contact@wtf.org
EOF

rm -R "${NGINXWEB:?}"/html &> /dev/null
rm "$NGINXENABLE"/default &> /dev/null

# installation Seedbox-Manager
if FONCYES "$SEEDBOXMANAGER"; then

## composer
cd /tmp || exit
curl -s http://getcomposer.org/installer | php
mv /tmp/composer.phar /usr/bin/composer
chmod +x /usr/bin/composer
echo "" ; set "156" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

## nodejs
cd /tmp || exit
curl -o- https://raw.githubusercontent.com/creationix/nvm/v"$NVM"/install.sh | bash
# shellcheck source=/dev/null
source ~/.bashrc
FONCBASHRC
nvm install v"$NODE"
echo "" ; set "158" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

## bower
npm install -g bower
echo "" ; set "160" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

## app
cd "$NGINXWEB" || exit
composer create-project magicalex/seedbox-manager
cd seedbox-manager || exit
bower install --allow-root --config.interactive=false
chown -R "$WDATA" "$SBM"
## conf app
cd source-reboot-rtorrent || exit
chmod +x install.sh
./install.sh

cp -f "$FILES"/nginx/php-manager.conf "$NGINXCONFD"/php-manager.conf
sed -i "s|@SBM@|$SBM|g;" "$NGINXCONFD"/php-manager.conf
sed -i "s|@PHPSOCK@|$PHPSOCK|g;" "$NGINXCONFD"/php-manager.conf

echo "        ## début config seedbox-manager ##

        location ^~ /seedbox-manager {
            alias $SBM/public;
            include $NGINXCONFD/php-manager.conf;
            include $NGINXCONFD/cache.conf;
        }

        ## fin config seedbox-manager ##">> "$NGINXENABLE"/rutorrent.conf

## conf user
cd "$SBMCONFUSER" || exit
mkdir "$USER"
cp -f "$FILES"/sbm/config-root.ini "$SBMCONFUSER"/"$USER"/config.ini

sed -i "s/\"\/\"/\"\/home\/$USER\"/g;" "$SBMCONFUSER"/"$USER"/config.ini
sed -i "s/RPC1/$USERMAJ/g;" "$SBMCONFUSER"/"$USER"/config.ini
sed -i "s/contact@mail.com/$EMAIL/g;" "$SBMCONFUSER"/"$USER"/config.ini

# verrouillage option parametre seedbox-manager
cp -f "$FILES"/sbm/header.html "$SBM"/public/themes/default/template/header.html

chown -R "$WDATA" "$SBMCONFUSER"
chown -R "$WDATA" "$SBM"/public/themes/default/template/header.html

# plugin seedbox-manager
cd "$RUPLUGINS" || exit
git clone https://github.com/Hydrog3n/linkseedboxmanager.git
sed -i "2i\$host = \$_SERVER['HTTP_HOST'];\n" "$RUPLUGINS"/linkseedboxmanager/conf.php
sed -i "s/http:\/\/seedbox-manager.ndd.tld/\/\/'. \$host .'\/seedbox-manager\//g;" "$RUPLUGINS"/linkseedboxmanager/conf.php

echo "" ; set "162" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""
fi

# logrotate
cp -f "$FILES"/nginx/logrotate /etc/logrotate.d/nginx

# ssh config
sed -i "s/Subsystem[[:blank:]]sftp[[:blank:]]\/usr\/lib\/openssh\/sftp-server/Subsystem sftp internal-sftp/g;" /etc/ssh/sshd_config
sed -i "s/UsePAM/#UsePAM/g;" /etc/ssh/sshd_config

# chroot user
echo "Match User $USER
ChrootDirectory /home/$USER">> /etc/ssh/sshd_config

# config .rtorrent.rc
FONCTORRENTRC "$USER" "$PORT" "$RUTORRENT"

# permissions
chown -R "$USER":"$USER" /home/"$USER"
chown root:"$USER" /home/"$USER"
chmod 755 /home/"$USER"

FONCSERVICE restart ssh
echo "" ; set "166" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

# config user rutorrent.conf
FONCRTCONF "$USERMAJ"  "$PORT" "$USER"

# config.php
FONCPHPCONF "$USER" "$PORT" "$USERMAJ"

# plugin.ini
cp -f "$FILES"/rutorrent/plugins.ini "$RUCONFUSER"/"$USER"/plugins.ini

# script rtorrent
FONCSCRIPTRT "$USER"
FONCSERVICE start "$USER"-rtorrent
FONCSERVICE start "$USER"-irssi

# htpasswd
FONCHTPASSWD "$USER"

echo "" ; set "168" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

# conf fail2ban
cp -f "$FILES"/fail2ban/nginx-auth.conf /etc/fail2ban/filter.d/nginx-auth.conf
cp -f "$FILES"/fail2ban/nginx-badbots.conf /etc/fail2ban/filter.d/nginx-badbots.conf

cp -f /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed  -i "/ssh/,+6d" /etc/fail2ban/jail.local

echo "
[ssh]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
banaction = iptables-multiport
maxretry = 5

[nginx-auth]
enabled  = true
port  = http,https
filter   = nginx-auth
logpath  = /var/log/nginx/*error.log
banaction = iptables-multiport
maxretry = 10

[nginx-badbots]
enabled  = true
port  = http,https
filter = nginx-badbots
logpath = /var/log/nginx/*access.log
banaction = iptables-multiport
maxretry = 5" >> /etc/fail2ban/jail.local

FONCSERVICE restart fail2ban
echo "" ; set "170" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""

# installation vsftpd
if FONCYES "$SERVFTP"; then
apt-get install -y vsftpd
\
if [[ $VERSION =~ 7. ]]; then
	sed -i "s/seccomp_sandbox=NO/#seccomp_sandbox=NO/g;" /etc/vsftpd.conf
fi

# récupèration certificats nginx
cp -f "$NGINXSSL"/server.crt  /etc/ssl/private/vsftpd.cert.pem
cp -f "$NGINXSSL"/server.key  /etc/ssl/private/vsftpd.key.pem

touch /etc/vsftpd.chroot_list
touch /var/log/vsftpd.log
chmod 600 /var/log/vsftpd.log
FONCSERVICE restart vsftpd

sed  -i "/vsftpd/,+10d" /etc/fail2ban/jail.local

echo "
[vsftpd]

enabled  = true
port     = ftp,ftp-data,ftps,ftps-data
filter   = vsftpd
logpath  = /var/log/vsftpd.log
banaction = iptables-multiport
# or overwrite it in jails.local to be
# logpath = /var/log/auth.log
# if you want to rely on PAM failed login attempts
# vsftpd's failregex should match both of those formats
maxretry = 5" >> /etc/fail2ban/jail.local

FONCSERVICE restart fail2ban
echo "" ; set "172" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""
fi

# déplacement clé 2048
cp -f /tmp/dhparams.pem "$NGINXSSL"/dhparams.pem
chmod 600 "$NGINXSSL"/dhparams.pem
FONCSERVICE restart nginx
# Contrôle
if [ ! -f "$NGINXSSL"/dhparams.pem ]; then
kill -HUP "$(pgrep -x openssl)"
echo "" ; set "174" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
set "176" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" ; echo ""
cd "$NGINXSSL" || exit
openssl dhparam -out dhparams.pem 2048
chmod 600 dhparams.pem
FONCSERVICE restart nginx
echo "" ; set "178" "134" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}" ; echo ""
fi

# log users
echo "maillog">> "$RUTORRENT"/histo_ess.log
echo "userlog">> "$RUTORRENT"/histo_ess.log
sed -i "s/maillog/$EMAIL/g;" "$RUTORRENT"/histo_ess.log
sed -i "s/userlog/$USER:5001/g;" "$RUTORRENT"/histo_ess.log

echo "" ; set "180" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}" ; echo ""
set "182" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1${CEND}"
set "184" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND}"
set "186" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND} ${CYELLOW}${PASSNGINX}${CEND}"
set "188" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1${CEND}" ; echo ""

# ajout utilisateur supplémentaire

while :; do
set "190" ; FONCTXT "$1" ; echo -n -e "${CGREEN}$TXT1 ${CEND}"
read -r REPONSE

if FONCNO "$REPONSE"; then
	# fin d'installation
	echo "" ; set "192" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
	cp -f /tmp/install.log "$RUTORRENT"/install.log
	ccze -h < "$RUTORRENT"/install.log > "$RUTORRENT"/install.html
	> /var/log/nginx/rutorrent-error.log
	echo "" ; set "194" ; FONCTXT "$1" ; echo -n -e "${CGREEN}$TXT1 ${CEND}"
	read -r REBOOT

	if FONCNO "$REBOOT"; then
		echo "" ; set "196" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
		echo -e "${CYELLOW}https://$IP/rutorrent/install.html${CEND}"
		echo "" ; set "200" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}"
		echo "" ; set "202" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
		echo -e "${CYELLOW}https://$IP/rutorrent/${CEND}"
		echo "" ; set "302" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
		echo -e "${CYELLOW}https://$IP/seedbox-manager/${CEND}"
		echo "" ; echo "" ; set "210" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
		echo -e "${CBLUE}                          Ex_Rat - http://mondedie.fr${CEND}" ; echo ""
		break
	fi

	if FONCYES "$REBOOT"; then
		echo "" ; set "196" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
		echo -e "${CYELLOW}https://$IP/rutorrent/install.html${CEND}"
		echo "" ; set "202" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
		echo -e "${CYELLOW}https://$IP/rutorrent/${CEND}"
		echo "" ; set "302" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
		echo -e "${CYELLOW}https://$IP/seedbox-manager/${CEND}"
		echo "" ; echo "" ; set "210" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
		echo -e "${CBLUE}                          Ex_Rat - http://mondedie.fr${CEND}" ; echo ""
		reboot
		break
	fi
fi

if FONCYES "$REPONSE"; then

# demande nom et mot de passe
echo ""
while :; do
set "214" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1 ${CEND}"
FONCUSER
done

echo ""
while :; do
set "112" "114" "116" ; FONCTXT "$1" "$2" "$3" ; echo -e "${CGREEN}$TXT1${CEND}${CYELLOW}$TXT2${CEND}${CGREEN}$TXT3 ${CEND}"
FONCPASS
done

# récupération 5% root sur /home/user si présent
FONCFSUSER "$USER"

# variable passe nginx
PASSNGINX=${USERPWD}

# ajout utilisateur
useradd -M -s /bin/bash "$USER"

# création du mot de passe pour cet utilisateur
echo "" ; echo "${USER}:${USERPWD}" | chpasswd

# anti-bug /home/user déjà existant
mkdir -p /home/"$USER"
chown -R "$USER":"$USER" /home/"$USER"

# variable utilisateur majuscule
USERMAJ=$(echo "$USER" | tr "[:lower:]" "[:upper:]")

# variable mail
EMAIL=$(sed -n "1 p" "$RUTORRENT"/histo_ess.log)

# création de dossier
su "$USER" -c 'mkdir -p ~/watch ~/torrents ~/.session '

# calcul port
FONCPORT

# config .rtorrent.rc
FONCTORRENTRC "$USER" "$PORT" "$RUTORRENT"

# config user rutorrent.conf
sed -i '$d' "$NGINXENABLE"/rutorrent.conf
FONCRTCONF "$USERMAJ"  "$PORT" "$USER"

# config.php
mkdir "$RUCONFUSER"/"$USER"
FONCPHPCONF "$USER" "$PORT" "$USERMAJ"

# chroot user supplèmentaire
echo "Match User $USER
ChrootDirectory /home/$USER">> /etc/ssh/sshd_config

FONCSERVICE restart ssh

## conf user seedbox-manager
if [ -f "$SBM"/public/themes/default/template/header.html ]; then
cd "$SBMCONFUSER" || exit
mkdir "$USER"
cp -f "$FILES"/sbm/config-user.ini "$SBMCONFUSER"/"$USER"/config.ini
sed -i "s/\"\/\"/\"\/home\/$USER\"/g;" "$SBMCONFUSER"/"$USER"/config.ini
sed -i "s/RPC1/$USERMAJ/g;" "$SBMCONFUSER"/"$USER"/config.ini
sed -i "s/contact@mail.com/$EMAIL/g;" "$SBMCONFUSER"/"$USER"/config.ini
chown -R "$WDATA" "$SBMCONFUSER"
fi

# plugin.ini
cp -f "$FILES"/rutorrent/plugins.ini "$RUCONFUSER"/"$USER"/plugins.ini

# configuration autodl-irssi
FONCIRSSI "$USER" "$PORT" "$USERPWD"

# permission
chown -R "$WDATA" "$RUTORRENT"
chown -R "$USER":"$USER" /home/"$USER"
chown root:"$USER" /home/"$USER"
chmod 755 /home/"$USER"

# script rtorrent
FONCSCRIPTRT "$USER"
FONCSERVICE start "$USER"-rtorrent
FONCSERVICE start "$USER"-irssi

# htpasswd
FONCHTPASSWD "$USER"
FONCSERVICE restart nginx

# log users
echo "userlog">> "$RUTORRENT"/histo_ess.log
sed -i "s/userlog/$USER:$PORT/g;" "$RUTORRENT"/histo_ess.log

echo "" ; set "218" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}" ; echo ""

set "182" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1${CEND}"
set "184" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND}"
set "186" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND} ${CYELLOW}${PASSNGINX}${CEND}"
set "188" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1${CEND}" ; echo ""
fi
done

else

################################################
# lancement gestion des utilisateurs ruTorrent #
################################################

clear

# Contrôle installation
if [ ! -f "$RUTORRENT"/histo_ess.log ]; then
	echo "" ; set "220" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}"
	set "222" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" ; echo ""
	exit 1
fi

# message d'accueil
echo "" ; set "224" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}" ; echo ""
# shellcheck source=/dev/null
. "$INCLUDES"/logo.sh

# mise en garde
echo "" ; set "226" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}"
set "228" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}"
set "230" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}"
echo "" ; set "232" ; FONCTXT "$1" ; echo -n -e "${CGREEN}$TXT1 ${CEND}"
read -r VALIDE

if FONCNO "$VALIDE"; then
	echo "" ; set "210" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
	echo -e "${CBLUE}                          Ex_Rat - http://mondedie.fr${CEND}" ; echo ""
	exit 1
fi

if FONCYES "$VALIDE"; then

# Boucle ajout/suppression utilisateur
while :; do

# menu gestion multi-utilisateurs
echo "" ; set "234" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
set "236" "248" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}"
set "238" "256" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}"
set "240" "254" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}"
set "242" "258" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}"
set "260" ; FONCTXT "$1" ; echo -n -e "${CBLUE}$TXT1 ${CEND}"
read -r OPTION

case $OPTION in
1)

# demande nom et mot de passe
while :; do
echo "" ; set "214" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1 ${CEND}"
FONCUSER
done

echo ""
while :; do
set "112" "114" "116" ; FONCTXT "$1" "$2" "$3" ; echo -e "${CGREEN}$TXT1${CEND}${CYELLOW}$TXT2${CEND}${CGREEN}$TXT3${CEND}"
FONCPASS
done

# récupération 5% root sur /home/user si présent
FONCFSUSER "$USER"

# variable email (rétro compatible)
TESTMAIL=$(sed -n "1 p" "$RUTORRENT"/histo_ess.log)
if [[ "$TESTMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]*$ ]];then
        EMAIL="$TESTMAIL"
else
        EMAIL=contact@exemple.com
fi

# variable passe nginx
PASSNGINX=${USERPWD}

# ajout utilisateur
useradd -M -s /bin/bash "$USER"

# création du mot de passe pour cet utilisateur
echo "${USER}:${USERPWD}" | chpasswd

# anti-bug /home/user déjà existant
mkdir -p /home/"$USER"
chown -R "$USER":"$USER" /home/"$USER"

# variable utilisateur majuscule
USERMAJ=$(echo "$USER" | tr "[:lower:]" "[:upper:]")

#récupération ip serveur
FONCIP

su "$USER" -c 'mkdir -p ~/watch ~/torrents ~/.session '

# calcul port
FONCPORT

# config .rtorrent.rc
FONCTORRENTRC "$USER" "$PORT" "$RUTORRENT"

# config user rutorrent.conf
sed -i '$d' "$NGINXENABLE"/rutorrent.conf
FONCRTCONF "$USERMAJ"  "$PORT" "$USER"

# config.php
mkdir "$RUCONFUSER"/"$USER"
FONCPHPCONF "$USER" "$PORT" "$USERMAJ"

# plugin.ini
cp -f "$FILES"/rutorrent/plugins.ini "$RUCONFUSER"/"$USER"/plugins.ini

# configuration autodl-irssi
if [ -f "/etc/irssi.conf" ]; then
	FONCIRSSI "$USER" "$PORT" "$USERPWD"
fi

# chroot user supplémentaire
echo "Match User $USER
ChrootDirectory /home/$USER">> /etc/ssh/sshd_config
FONCSERVICE restart ssh

# permission
chown -R "$WDATA" "$RUTORRENT"
chown -R "$USER":"$USER" /home/"$USER"
chown root:"$USER" /home/"$USER"
chmod 755 /home/"$USER"

# script rtorrent
FONCSCRIPTRT "$USER"

# htpasswd
FONCHTPASSWD "$USER"

# seedbox-manager conf user

if [ -f "$SBM"/public/themes/default/template/header.html ]; then
cd "$SBMCONFUSER" || exit
mkdir "$USER"
cp -f "$FILES"/sbm/config-user.ini "$SBMCONFUSER"/"$USER"/config.ini
sed -i "s/\"\/\"/\"\/home\/$USER\"/g;" "$SBMCONFUSER"/"$USER"/config.ini
sed -i "s/RPC1/$USERMAJ/g;" "$SBMCONFUSER"/"$USER"/config.ini
sed -i "s/contact@mail.com/$EMAIL/g;" "$SBMCONFUSER"/"$USER"/config.ini
chown -R "$WDATA" "$SBMCONFUSER"
fi
FONCSERVICE restart nginx
FONCSERVICE start "$USER"-rtorrent
if [ -f "/etc/irssi.conf" ]; then
	FONCSERVICE start "$USER"-irssi
fi

# log users
echo "userlog">> "$RUTORRENT"/histo_ess.log
sed -i "s/userlog/$USER:$PORT/g;" "$RUTORRENT"/histo_ess.log
echo "" ; set "218" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}" ; echo ""

set "182" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1${CEND}"
set "184" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND}"
set "186" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND} ${CYELLOW}${PASSNGINX}${CEND}"
set "188" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1${CEND}" ; echo ""
;;

# suppression utilisateur
2)

echo "" ; set "214" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1 ${CEND}"
read -r USER
set "282" "284" ; FONCTXT "$1" "$2" ; echo -n -e "${CGREEN}$TXT1${CEND} ${CYELLOW}$USER${CEND} ${CGREEN}$TXT2 ${CEND}"
read -r SUPPR

if FONCNO "$SUPPR"; then
	echo

else
	echo "" ; set "286" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}" ; echo ""

	# variable utilisateur majuscule
	USERMAJ=$(echo "$USER" | tr "[:lower:]" "[:upper:]")
	#echo -e "$USERMAJ"

	# crontab (pour rétro-compatibilité)
	crontab -l > /tmp/rmuser
	sed -i "s/* \* \* \* \* if ! ( ps -U $USER | grep rtorrent > \/dev\/null ); then \/etc\/init.d\/$USER-rtorrent start; fi > \/dev\/null 2>&1//g;" /tmp/rmuser
	crontab /tmp/rmuser
	rm /tmp/rmuser

	# stop user
	FONCSERVICE stop "$USER"-rtorrent
	if [ -f "/etc/irssi.conf" ]; then
		FONCSERVICE stop "$USER"-irssi
	fi
	killall --user "$USER" rtorrent
	killall --user "$USER" screen

	# suppression script
	if [ -f "/etc/irssi.conf" ]; then
		rm /etc/init.d/"$USER"-irssi
		update-rc.d "$USER"-irssi remove
	fi
	rm /etc/init.d/"$USER"-rtorrent
	update-rc.d "$USER"-rtorrent remove

	# supression rc.local (pour retro-compatibilité)
	sed -i "/$USER/d" /etc/rc.local

	# suppression conf rutorrent
	rm -R "${RUCONFUSER:?}"/"$USER"
	rm -R "${RUTORRENT:?}"/share/users/"$USER"

	# suppression pass
	sed -i "/^$USER/d" "$NGINXPASS"/rutorrent_passwd
	rm "$NGINXPASS"/rutorrent_passwd_"$USER"

	# suppression nginx
	sed -i '/location \/'"$USERMAJ"'/,/}/d' "$NGINXENABLE"/rutorrent.conf
	FONCSERVICE restart nginx

	# suppression seebbox-manager
	if [ -f "$SBM"/public/themes/default/template/header.html ]; then
	rm -R "${SBMCONFUSER:?}"/"$USER"
	fi

	# suppression user
	deluser "$USER" --remove-home

	echo "" ; set "264" "288" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND} ${CBLUE}$TXT2${CEND}"
	fi
;;

# modification mot de passe utilisateur
3)

echo "" ; set "214" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1 ${CEND}"
read -r USER
echo ""
while :; do
set "274" "114" "116" ; FONCTXT "$1" "$2" "$3" ; echo -e "${CGREEN}$TXT1${CEND}${CYELLOW}$TXT2${CEND}${CGREEN}$TXT3${CEND}"
FONCPASS
done

echo "" ; set "276" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}" ; echo ""

# variable passe nginx
PASSNGINX=${USERPWD}

# modification du mot de passe pour cet utilisateur
echo "${USER}:${USERPWD}" | chpasswd

# htpasswd
FONCHTPASSWD "$USER"

echo "" ; set "278" "280" ; FONCTXT "$1" "$2" ; echo -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND} ${CBLUE}$TXT2${CEND}" ; echo ""
set "182" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1${CEND}"
set "184" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND}"
set "186" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND} ${CYELLOW}${PASSNGINX}${CEND}"
set "188" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1${CEND}" ; echo ""
;;

# sortir gestion utilisateurs
4)
echo "" ; set "290" ; FONCTXT "$1" ; echo -n -e "${CGREEN}$TXT1 ${CEND}"
read -r REBOOT

if FONCNO "$REBOOT"; then
	echo "" ; set "200" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" ; echo ""
	set "210" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
	echo -e "${CBLUE}                          Ex_Rat - http://mondedie.fr${CEND}" ; echo ""
	exit 1
fi

if FONCYES "$REBOOT"; then
	echo "" ; set "210" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
	echo -e "${CBLUE}                          Ex_Rat - http://mondedie.fr${CEND}" ; echo ""
	reboot
fi

break
;;

*)
set "292" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}"
;;
esac
done
fi
fi
