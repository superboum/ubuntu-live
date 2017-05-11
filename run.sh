#!/bin/bash

[ -z $UBUNTU_VERSION ]     && read -p "Entrez la version d'Ubuntu -> " UBUNTU_VERSION
[ -z $LIVE_USER ]          && read -p "Entrez le nom de l'utilisateur désiré -> " LIVE_USER

./scripts/create_live_filesystem.sh $UBUNTU_VERSION
./scripts/launch_configure_system.sh $LIVE_USER
./scripts/create_iso_filesystem.sh
