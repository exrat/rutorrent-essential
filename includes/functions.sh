#!/bin/bash

function FONCCONTROL ()
{
if [[ "$VERSION" =~ 7.* ]] || [[ "$VERSION" =~ 8.* ]]; then
	if [ "$(id -u)" -ne 0 ]; then
		echo "" ; set "100" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" 1>&2 ; echo ""
		exit 1
	fi
else
		echo "" ; set "130" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" ; echo ""
	exit 1
fi
}

function FONCUSER ()
{
read -r TESTUSER
grep -w "$TESTUSER" /etc/passwd &> /dev/null
if [ $? -eq 1 ]; then
	if [[ "$TESTUSER" =~ ^[a-z0-9]{3,}$ ]]; then
		USER="$TESTUSER"
		# shellcheck disable=SC2104
		break
	else
		echo "" ; set "110" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" ; echo ""
	fi
else
	echo "" ; set "198" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" ; echo ""
fi
}

function FONCPASS ()
{
read -r REPPWD
if [ "$REPPWD" = "" ]; then
	AUTOPWD=$(tr -dc "1-9a-nA-Np-zP-Z" < /dev/urandom | head -c 8)
	echo "" ; set "118" "120" ; FONCTXT "$1" "$2" ; echo -n -e "${CGREEN}$TXT1${CEND} ${CYELLOW}$AUTOPWD${CEND} ${CGREEN}$TXT2 ${CEND}"
        read -r REPONSEPWD
        if FONCNO "$REPONSEPWD"; then
		echo
        else
			USERPWD="$AUTOPWD"
			# shellcheck disable=SC2104
			break
		fi

else
	if [[ "$REPPWD" =~ ^[a-zA-Z0-9]{6,}$ ]]; then
		# shellcheck disable=SC2034
		USERPWD="$REPPWD"
		# shellcheck disable=SC2104
       	break
	else
		echo "" ; set "122" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" ; echo ""
	fi
fi
}

function FONCIP ()
{
IP=$(ifconfig | grep "inet ad" | cut -f2 -d: | awk '{print $1}' | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
if [ "$IP" = "" ]; then
	IP=$(wget -qO- ipv4.icanhazip.com)
		if [ "$IP" = "" ]; then
			IP=$(wget -qO- ipv4.bonobox.net)
			if [ "$IP" = "" ]; then
				IP=x.x.x.x
			fi
		fi
fi
}

function FONCPORT ()
{
HISTO=$(wc -l < "$RUTORRENT"/histo_ess.log)
# shellcheck disable=SC2034
PORT=$(( 5001+HISTO ))
}

function FONCYES ()
{
[ "$1" = "y" ] || [ "$1" = "Y" ] || [ "$1" = "o" ] || [ "$1" = "O" ] || [ "$1" = "j" ] || [ "$1" = "J" ] || [ "$1" = "д" ] || [ "$1" = "s" ] || [ "$1" = "S" ]
}

function FONCNO ()
{
[ "$1" = "n" ] || [ "$1" = "N" ] || [ "$1" = "h" ] || [ "$1" = "H" ]
}

function FONCTXT ()
{
TXT1="$(grep "$1" "$ESSENTIAL"/lang/"$GENLANG".lang | cut -c5-)"
TXT2="$(grep "$2" "$ESSENTIAL"/lang/"$GENLANG".lang | cut -c5-)"
# shellcheck disable=SC2034
TXT3="$(grep "$3" "$ESSENTIAL"/lang/"$GENLANG".lang | cut -c5-)"
}

# FONCSERVICE $1 start/stop/...  $2 nom
function FONCSERVICE ()
{
if [[ $VERSION =~ 7. ]]; then
	service "$2" "$1"
elif [[ $VERSION =~ 8. ]]; then
	systemctl "$1" "$2".service
fi
}

function FONCFSUSER ()
{
FSUSER=$(grep /home/"$1" /etc/fstab | cut -c 6-9)

if [ "$FSUSER" = "" ]; then
	echo
else
    tune2fs -m 0 /dev/"$FSUSER" &> /dev/null
    mount -o remount /home/"$1" &> /dev/null
fi
}

function FONCCHOISE ()
{
read -r SEEDBOXMANAGER

if FONCYES "$SEEDBOXMANAGER"; then
	while :; do
	echo "" ; set "124" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1 ${CEND}"
	read -r INSTALLMAIL
	if [ "$INSTALLMAIL" = "" ]; then
		EMAIL=contact@exemple.com
		break
	else
		if [[ "$INSTALLMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]*$ ]]; then
			# shellcheck disable=SC2034
			EMAIL="$INSTALLMAIL"
			break
		else
			echo "" ; set "126" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}"
		fi
	fi
done
fi

echo "" ; set "128" ; FONCTXT "$1" ; echo -n -e "${CGREEN}$TXT1 ${CEND}"
# shellcheck disable=SC2034
read -r SERVFTP
}

function FONCHTPASSWD ()
{
htpasswd -bs "$NGINXPASS"/rutorrent_passwd "$1" "${PASSNGINX}"
htpasswd -cbs "$NGINXPASS"/rutorrent_passwd_"$1" "$1" "${PASSNGINX}"
chmod 640 "$NGINXPASS"/*
chown -c "$WDATA" "$NGINXPASS"/*
}

function FONCRTCONF ()
{
echo "
        location /$1 {
            include scgi_params;
            scgi_pass 127.0.0.1:$2; #ou socket : unix:/home/username/.session/username.socket
            auth_basic \"seedbox\";
            auth_basic_user_file \"$NGINXPASS/rutorrent_passwd_$3\";
        }
}">> "$NGINXENABLE"/rutorrent.conf
}

function FONCPHPCONF ()
{
touch "$RUCONFUSER"/"$1"/config.php
echo "<?php
\$pathToExternals = array(
    \"curl\"  => '/usr/bin/curl',
    \"stat\"  => '/usr/bin/stat',
    );
\$topDirectory = '/home/$1';
\$scgi_port = $2;
\$scgi_host = '127.0.0.1';
\$XMLRPCMountPoint = '/$3';" > "$RUCONFUSER"/"$1"/config.php
}

function FONCTORRENTRC ()
{
\cp -f "$FILES"/rutorrent/rtorrent.rc /home/"$1"/.rtorrent.rc
sed -i "s/@USER@/$1/g;" /home/"$1"/.rtorrent.rc
sed -i "s/@PORT@/$2/g;" /home/"$1"/.rtorrent.rc
sed -i "s|@RUTORRENT@|$3|;" /home/"$1"/.rtorrent.rc
}

function FONCSCRIPTRT ()
{
\cp -f "$FILES"/rutorrent/init.conf /etc/init.d/"$1"-rtorrent
sed -i "s/@USER@/$1/g;" /etc/init.d/"$1"-rtorrent
chmod +x /etc/init.d/"$1"-rtorrent
update-rc.d "$1"-rtorrent defaults
}

function FONCIRSSI ()
{
IRSSIPORT=1"$2"
mkdir -p /home/"$1"/.irssi/scripts/autorun
cd /home/"$1"/.irssi/scripts || exit
curl -sL http://git.io/vlcND | grep -Po '(?<="browser_download_url": ")(.*-v[\d.]+.zip)' | xargs wget --quiet -O autodl-irssi.zip
unzip -o autodl-irssi.zip
\rm autodl-irssi.zip
\cp -f /home/"$1"/.irssi/scripts/autodl-irssi.pl /home/"$1"/.irssi/scripts/autorun
mkdir -p /home/"$1"/.autodl
echo "[options]
gui-server-port = $IRSSIPORT
gui-server-password = $3" > /home/"$1"/.autodl/autodl.cfg
mkdir -p  "$RUCONFUSER"/"$1"/plugins/autodl-irssi
echo "<?php
\$autodlPort = $IRSSIPORT;
\$autodlPassword = \"$3\";
?>" >> "$RUCONFUSER"/"$1"/plugins/autodl-irssi/conf.php
\cp -f "$FILES"/rutorrent/irssi.conf /etc/init.d/"$1"-irssi
sed -i "s/@USER@/$1/g;" /etc/init.d/"$1"-irssi
chmod +x /etc/init.d/"$1"-irssi
update-rc.d "$1"-irssi defaults
}

