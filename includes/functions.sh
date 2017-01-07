#!/bin/bash

FONCCONTROL () {
	if [[ "$VERSION" =~ 7.* ]] || [[ "$VERSION" =~ 8.* ]]; then
		if [ "$(id -u)" -ne 0 ]; then
			echo ""; set "100"; FONCTXT "$1"; echo -e "${CRED}$TXT1${CEND}"; echo ""
			exit 1
		fi
	else
		echo ""; set "130"; FONCTXT "$1"; echo -e "${CRED}$TXT1${CEND}"; echo ""
		exit 1
	fi
}

FONCBASHRC () {
	unalias cp 2>/dev/null
	unalias rm 2>/dev/null
	unalias mv 2>/dev/null
}

FONCUSER () {
	read -r TESTUSER
	grep -w "$TESTUSER" /etc/passwd &> /dev/null
	if [ $? -eq 1 ]; then
		if [[ "$TESTUSER" =~ ^[a-z0-9]{3,}$ ]]; then
			USER="$TESTUSER"
			# shellcheck disable=SC2104
			break
		else
			echo ""; set "110"; FONCTXT "$1"; echo -e "${CRED}$TXT1${CEND}"; echo ""
		fi
	else
		echo ""; set "198"; FONCTXT "$1"; echo -e "${CRED}$TXT1${CEND}"; echo ""
	fi
}

FONCPASS () {
	read -r REPPWD
	if [ "$REPPWD" = "" ]; then
		AUTOPWD=$(tr -dc "1-9a-nA-Np-zP-Z" < /dev/urandom | head -c 8)
		echo ""; set "118" "120"; FONCTXT "$1" "$2"; echo -n -e "${CGREEN}$TXT1${CEND} ${CYELLOW}$AUTOPWD${CEND} ${CGREEN}$TXT2 ${CEND}"
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
			echo ""; set "122"; FONCTXT "$1"; echo -e "${CRED}$TXT1${CEND}"; echo ""
		fi
	fi
}

FONCIP () {
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

FONCPORT () {
	HISTO=$(wc -l < "$RUTORRENT"/histo_ess.log)
	# shellcheck disable=SC2034
	PORT=$(( 5001+HISTO ))
}

FONCYES () {
	[ "$1" = "y" ] || [ "$1" = "Y" ] || [ "$1" = "o" ] || [ "$1" = "O" ] || [ "$1" = "j" ] || [ "$1" = "J" ] || [ "$1" = "д" ] || [ "$1" = "s" ] || [ "$1" = "S" ]
}

FONCNO () {
	[ "$1" = "n" ] || [ "$1" = "N" ] || [ "$1" = "h" ] || [ "$1" = "H" ]
}

FONCTXT () {
	TXT1="$(grep "$1" "$ESSENTIAL"/lang/"$GENLANG".lang | cut -c5-)"
	TXT2="$(grep "$2" "$ESSENTIAL"/lang/"$GENLANG".lang | cut -c5-)"
	# shellcheck disable=SC2034
	TXT3="$(grep "$3" "$ESSENTIAL"/lang/"$GENLANG".lang | cut -c5-)"
}

FONCSERVICE () {
	if [[ $VERSION =~ 7. ]]; then
		service "$2" "$1"
	elif [[ $VERSION =~ 8. ]]; then
		systemctl "$1" "$2".service
	fi
} # FONCSERVICE $1 {start/stop/restart} $2 {nom service}

FONCFSUSER () {
	FSUSER=$(grep /home/"$1" /etc/fstab | cut -c 6-9)

	if [ "$FSUSER" = "" ]; then
		echo
	else
		tune2fs -m 0 /dev/"$FSUSER" &> /dev/null
		mount -o remount /home/"$1" &> /dev/null
	fi
}

FONCHTPASSWD () {
	htpasswd -bs "$NGINXPASS"/rutorrent_passwd "$1" "${PASSNGINX}"
	htpasswd -cbs "$NGINXPASS"/rutorrent_passwd_"$1" "$1" "${PASSNGINX}"
	chmod 640 "$NGINXPASS"/*
	chown -c "$WDATA" "$NGINXPASS"/*
}

FONCRTCONF () {
	cat <<- EOF >> "$NGINXENABLE"/rutorrent.conf

		        location /$1 {
		                include scgi_params;
		                scgi_pass 127.0.0.1:$2;
		                auth_basic "seedbox";
		                auth_basic_user_file "$NGINXPASS/rutorrent_passwd_$3";
		        }
		}
	EOF
}

FONCPHPCONF () {
	touch "$RUCONFUSER"/"$1"/config.php

	cat <<- EOF > "$RUCONFUSER"/"$1"/config.php
		<?php
		\$pathToExternals = array(
		    "curl"  => '/usr/bin/curl',
		    "stat"  => '/usr/bin/stat',
		    );
		\$topDirectory = '/home/$1';
		\$scgi_port = $2;
		\$scgi_host = '127.0.0.1';
		\$XMLRPCMountPoint = '/$3';
	EOF
}

FONCTORRENTRC () {
	cp -f "$FILES"/rutorrent/rtorrent.rc /home/"$1"/.rtorrent.rc
	sed -i "s/@USER@/$1/g;" /home/"$1"/.rtorrent.rc
	sed -i "s/@PORT@/$2/g;" /home/"$1"/.rtorrent.rc
	sed -i "s|@RUTORRENT@|$3|;" /home/"$1"/.rtorrent.rc
}

FONCSCRIPTRT () {
	cp -f "$FILES"/rutorrent/init.conf /etc/init.d/"$1"-rtorrent
	sed -i "s/@USER@/$1/g;" /etc/init.d/"$1"-rtorrent
	chmod +x /etc/init.d/"$1"-rtorrent
	update-rc.d "$1"-rtorrent defaults
}

FONCIRSSI () {
	IRSSIPORT=1"$2"
	mkdir -p /home/"$1"/.irssi/scripts/autorun
	cd /home/"$1"/.irssi/scripts || exit
	curl -sL http://git.io/vlcND | grep -Po '(?<="browser_download_url": ")(.*-v[\d.]+.zip)' | xargs wget --quiet -O autodl-irssi.zip
	unzip -o autodl-irssi.zip
	command rm autodl-irssi.zip
	cp -f /home/"$1"/.irssi/scripts/autodl-irssi.pl /home/"$1"/.irssi/scripts/autorun
	mkdir -p /home/"$1"/.autodl

	cat <<- EOF > /home/"$1"/.autodl/autodl.cfg
		[options]
		gui-server-port = $IRSSIPORT
		gui-server-password = $3
	EOF

	mkdir -p  "$RUCONFUSER"/"$1"/plugins/autodl-irssi

	cat <<- EOF > "$RUCONFUSER"/"$1"/plugins/autodl-irssi/conf.php
		<?php
		\$autodlPort = $IRSSIPORT;
		\$autodlPassword = "$3";
		?>
	EOF

	cp -f "$FILES"/rutorrent/irssi.conf /etc/init.d/"$1"-irssi
	sed -i "s/@USER@/$1/g;" /etc/init.d/"$1"-irssi
	chmod +x /etc/init.d/"$1"-irssi
	update-rc.d "$1"-irssi defaults
}

FONCMEDIAINFO () {
	cd /tmp || exit
	wget http://mediaarea.net/download/binary/libzen0/"$LIBZEN0"/libzen0_"$LIBZEN0"-1_"$SYS"."$DEBNUMBER"
	wget http://mediaarea.net/download/binary/libmediainfo0/"$LIBMEDIAINFO0"/libmediainfo0_"$LIBMEDIAINFO0"-1_"$SYS"."$DEBNUMBER"
	wget http://mediaarea.net/download/binary/mediainfo/"$MEDIAINFO"/mediainfo_"$MEDIAINFO"-1_"$SYS"."$DEBNUMBER"

	dpkg -i libzen0_"$LIBZEN0"-1_"$SYS"."$DEBNUMBER"
	dpkg -i libmediainfo0_"$LIBMEDIAINFO0"-1_"$SYS"."$DEBNUMBER"
	dpkg -i mediainfo_"$MEDIAINFO"-1_"$SYS"."$DEBNUMBER"
}

FONCGEN () {
	if [[ -f $RAPPORT ]]; then
		rm $RAPPORT
	fi
	touch $RAPPORT

	cat <<-EOF >> $RAPPORT

		### Report generated on $DATE ###

		Use ruTorrent --> $USERNAME
		Debian : $VERSION
		Kernel : $NOYAU
		nGinx : $NGINX_VERSION
		ruTorrent : $RUTORRENT_VERSION
		rTorrent : $RTORRENT_VERSION
		PHP : $PHP_VERSION
	EOF
}

FONCCHECKBIN () {
	if hash "$1" 2>/dev/null; then
		echo
	else
		apt-get -y install "$1"
		echo ""
	fi
}

FONCGENRAPPORT () {
	LINK=$(/usr/bin/pastebinit -b http://paste.ubuntu.com $RAPPORT)
	echo -e "${CBLUE}Report link:${CEND} ${CYELLOW}$LINK${CEND}"
	echo -e "${CBLUE}Report backup:${CEND} ${CYELLOW}$RAPPORT${CEND}"
}

FONCRAPPORT () {
	# $1 = Fichier
	if ! [[ -z $1 ]]; then
		if [[ -f $1 ]]; then
			if [[ $(wc -l < "$1") == 0 ]]; then
				FILE="--> Empty file"
			else
				FILE=$(cat "$1")
				# domain.tld
				if [[ "$1" = /etc/nginx/sites-enabled/* ]]; then
					SERVER_NAME=$(grep server_name < "$1" | cut -d';' -f1 | sed 's/ //' | cut -c13-)
					LETSENCRYPT=$(grep letsencrypt < "$1" | head -1 | cut -f 5 -d '/')
					if ! [[ "$SERVER_NAME" = _ ]]; then
						if [ -z "$LETSENCRYPT" ]; then
							FILE=$(sed "s/server_name[[:blank:]]${SERVER_NAME};/server_name domain.tld;/g;" "$1")
						else
							FILE=$(sed "s/server_name[[:blank:]]${SERVER_NAME};/server_name domain.tld;/g; s/$LETSENCRYPT/domain.tld/g;" "$1")
						fi
					fi
				fi
			fi
		else
			FILE="--> Invalid File"
		fi
	else
		FILE="--> Invalid File"
	fi

	# $2 = Nom à afficher
	if [[ -z $2 ]]; then
		NAME="No name given"
	else
		NAME=$2
	fi

	# $3 = Affichage header
	if [[ $3 == 1 ]]; then
		cat <<-EOF >> $RAPPORT

			.......................................................................................................................................
			## $NAME
			## File : $1
			.......................................................................................................................................
		EOF

		cat <<-EOF >> $RAPPORT

			$FILE
		EOF
	fi
}

FONCTESTRTORRENT () {
	SCGI="$(sed -n '/^scgi_port/p' /home/"$USERNAME"/.rtorrent.rc | cut -b 23-)"
	PORT_LISTENING=$(netstat -aultnp | awk '{print $4}' | grep -E ":$SCGI\$" -c)
	RTORRENT_LISTENING=$(netstat -aultnp | sed -n '/'$SCGI'/p' | grep rtorrent -c)

	cat <<-EOF >> $RAPPORT

		.......................................................................................................................................
		## Check rTorrent & sgci
		.......................................................................................................................................

	EOF

	# rTorrent lancé
	if [[ "$(ps uU "$USERNAME" | grep -e 'rtorrent' -c)" == [0-1] ]]; then
		echo -e "rTorrent down" >> $RAPPORT
	else
		echo -e "rTorrent Up" >> $RAPPORT
	fi

	# socket
	if (( PORT_LISTENING >= 1 )); then
		echo -e "A socket listens on the port $SCGI" >> $RAPPORT
		if (( RTORRENT_LISTENING >= 1 )); then
			echo -e "It is well rTorrent that listens on the port $SCGI" >> $RAPPORT
		else
			echo -e "It's not rTorrent listening on the port $SCGI" >> $RAPPORT
		fi
	else
		echo -e "No program listening on the port $SCGI" >> $RAPPORT
	fi

	# ruTorrent
	if [[ -f $RUTORRENT/conf/users/$USERNAME/config.php ]]; then
		if [[ $(cat "$RUTORRENT"/conf/users/"$USERNAME"/config.php) =~ "\$scgi_port = $SCGI" ]]; then
			echo -e "Good SCGI port specified in the config.php file" >> $RAPPORT
		else
			echo -e "Wrong SCGI port specified in config.php" >> $RAPPORT
		fi
	else
		echo -e "User directory found but config.php file does not exist" >> $RAPPORT
	fi

	# nginx
	if [[ $(cat $NGINXENABLE/rutorrent.conf) =~ $SCGI ]]; then
		echo -e "The ports nginx and the one indicated match" >> $RAPPORT
	else
		echo -e "The nginx ports and the specified ports do not match" >> $RAPPORT
	fi
}
