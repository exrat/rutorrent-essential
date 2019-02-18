#!/bin/bash
#
# script de redirection vers nouveau script bonobox
# info ici:  https://mondedie.fr/d/5399-script-installation-automatique-rutorrent-nginx
#
cd /tmp
git clone https://github.com/exrat/rutorrent-bonobox
cd rutorrent-bonobox
chmod a+x bonobox.sh && ./bonobox.sh
