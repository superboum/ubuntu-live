#!/bin/bash

UBUNTU_VERSION=$1     # --> Version Ubuntu (ex: zesty)

# Création du dossier build si n'existe pas
mkdir -p build/

# Création du système de fichier de base dans le dossier build
debootstrap --arch=amd64 $UBUNTU_VERSION build/live_filesystem/ > /dev/null # Trop de logs pour Travis

# Copie le script de configuration dans le système de fichier
cp `dirname $0`/../embed/configure_system.sh ./build/live_filesystem/usr/local/sbin

# Bind /dev sur le futur chroot
#mount --bind /dev build/live_filesystem/dev
