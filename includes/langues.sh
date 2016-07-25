#!/bin/bash

# langues
OPTS=$(getopt -o vhns: --long en,fr,it,de,ru,es,pt -n 'parse-options' -- "$@")
eval set -- "$OPTS"
while true; do
  case "$1" in
	--en) GENLANG="en" ; break ;;
	--fr) GENLANG="fr" ; break ;;
	--de) GENLANG="de" ; break ;;
	--ru) GENLANG="ru" ; break ;;
	--es) GENLANG="es" ; break ;;
	--pt) GENLANG="pt" ; break ;;
	*|\?)
		BASELANG="${LANG:0:2}"
		# detection auto
		if   [ "$BASELANG" = "en" ]; then GENLANG="en"
		elif [ "$BASELANG" = "fr" ]; then GENLANG="fr"
		elif [ "$BASELANG" = "de" ]; then GENLANG="de"
		elif [ "$BASELANG" = "ru" ]; then GENLANG="ru"
		elif [ "$BASELANG" = "es" ]; then GENLANG="es"
		elif [ "$BASELANG" = "pt" ]; then GENLANG="pt"
		else
			GENLANG="en" ; fi ; break ;;
	esac
done

# fix langue shell root
echo "export LANG=$LANG" >> /root/.bashrc

