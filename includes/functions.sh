#!/bin/bash

function FONCROOT ()
{
if [ "$(id -u)" -ne 0 ]; then
	echo "" ; set "100" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" 1>&2 ; echo ""
	exit 1
fi
}

function FONCUSER ()
{
read -r TESTUSER
if [[ "$TESTUSER" =~ ^[a-z0-9]{3,}$ ]];then
	USER="$TESTUSER"
	break
else
	echo "" ; set "110" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" ; echo ""
fi
}

function FONCPASS ()
{
read -r REPPWD
if [ "$REPPWD" = "" ]; then
	AUTOPWD=$(tr -dc "1-9a-nA-Np-zP-Z" < /dev/urandom | head -c 8)
	echo "" ; set "118" "120" ; FONCTXT "$1" "$2" ; echo -e "${CGREEN}$TXT1${CEND} ${CYELLOW}$AUTOPWD${CEND} ${CGREEN}$TXT2 ${CEND}"
        read -r REPONSEPWD
        if FONCNO "$REPONSEPWD"; then
		echo
        else
			USERPWD="$AUTOPWD"
			break
		fi

else
	if [[ "$REPPWD" =~ ^[a-zA-Z0-9]{6,}$ ]];then
		USERPWD="$REPPWD"
       	break
	else
		echo "" ; set "122" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}" ; echo ""
	fi
fi
}

function FONCYES ()
{
[ "$1" = "y" ] || [ "$1" = "Y" ] || [ "$1" = "o" ] || [ "$1" = "O" ] || [ "$1" = "j" ] || [ "$1" = "J" ] || [ "$1" = "д" ]
}

function FONCNO ()
{
[ "$1" = "n" ] || [ "$1" = "N" ] || [ "$1" = "H" ]
}

function FONCTXT ()
{
TXT1="$(grep "$1" "$ESSENTIAL"/lang/lang."$GENLANG" | cut -c5-)"
TXT2="$(grep "$2" "$ESSENTIAL"/lang/lang."$GENLANG" | cut -c5-)"
TXT3="$(grep "$3" "$ESSENTIAL"/lang/lang."$GENLANG" | cut -c5-)"
}

FONCFSUSER ()
{
FSUSER=$(grep /home/"$1" /etc/fstab | cut -c 6-9)

if [ "$FSUSER" = "" ]; then
	echo
else
    tune2fs -m 0 /dev/"$FSUSER"
    mount -o remount /home/"$1"
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
		if [[ "$INSTALLMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]*$ ]];then
			EMAIL="$INSTALLMAIL"
			break
		else
			echo "" ; set "126" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}"
		fi
	fi
done
fi

echo "" ; set "128" ; FONCTXT "$1" ; echo -n -e "${CGREEN}$TXT1 ${CEND}"
read -r SERVFTP
}

function FONCHTPASSWD ()
{
htpasswd -bs "$NGINXPASS"/rutorrent_passwd "$1" "${PASSNGINX}"
htpasswd -cbs "$NGINXPASS"/rutorrent_passwd_"$1" "$1" "${PASSNGINX}"
chmod 640 "$NGINXPASS"/*
chown -c www-data:www-data "$NGINXPASS"/*
service nginx restart
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
touch "$RUTORRENT"/conf/users/"$1"/config.php 
echo "<?php
\$pathToExternals = array(
    \"curl\"  => '/usr/bin/curl',
    \"stat\"  => '/usr/bin/stat',
    );
\$topDirectory = '/home/$1';
\$scgi_port = $2;
\$scgi_host = '127.0.0.1';
\$XMLRPCMountPoint = '/$3';" > "$RUTORRENT"/conf/users/"$1"/config.php 
}

function FONCTORRENTRC ()
{
cp -f "$FILES"/rutorrent/rtorrent.rc /home/"$1"/.rtorrent.rc
sed -i "s/@USER@/$1/g;" /home/"$1"/.rtorrent.rc
sed -i "s/@PORT@/$2/g;" /home/"$1"/.rtorrent.rc
sed -i "s|@RUTORRENT@|$3|;" /home/"$1"/.rtorrent.rc
}

function FONCSCRIPTRT ()
{
cp "$FILES"/rutorrent/init.conf /etc/init.d/"$1"-rtorrent
sed -i "s/@USER@/$1/g;" /etc/init.d/"$1"-rtorrent
chmod +x /etc/init.d/"$1"-rtorrent
update-rc.d "$1"-rtorrent defaults
service "$1"-rtorrent start
}

