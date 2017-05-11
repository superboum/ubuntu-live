#!/bin/bash

# Assure que tout est bien démonté
umount -l build/live_filesystem/proc
umount -l build/live_filesystem/dev/pts
umount -l build/live_filesystem/sys
rm -r build/live_filesystem/sys/*
rm -r build/live_filesystem/dev/pts/*
rm -r build/live_filesystem/proc/*

# Créer le dossier pour la clé USB
mkdir -p build/iso_filesystem/{live,isolinux}

# Copie du noyau linux et l'initrd dans la partition iso
cp build/live_filesystem/boot/vmlinuz* build/iso_filesystem/live/vmlinuz
cp build/live_filesystem/initrd* build/iso_filesystem/live/initrd

bash -c "while true; do sleep 300; echo Création en cours de filesystem.squashfs...; done" &
# Compression de l'arborescence live dans un fichier squashfs
mksquashfs \
  build/live_filesystem \
  build/iso_filesystem/live/filesystem.squashfs \
  -comp xz \
  -e boot \
  -noappend \
  -no-progress > /dev/null # Trop de logs pour Travis
kill $!

# Ajout du chargeur d'amorçage BIOS. On utilise syslinux.
# Obligé de mettre une condition en fonction de si l'image est générée depuis
# un système Fedora ou Debian/Ubuntu
lsb_release -a
ISOHYBRID_MBR=""
if (( $(lsb_release -s -i) == "Fedora" )); then
  # Fedora
  ISOHYBRID_MBR="/usr/share/syslinux/isohdpfx.bin"
  cp /usr/share/syslinux/isolinux.bin  build/iso_filesystem/isolinux/
  cp /usr/share/syslinux/menu.c32      build/iso_filesystem/isolinux/
  cp /usr/share/syslinux/ldlinux.c32   build/iso_filesystem/isolinux/
  cp /usr/share/syslinux/libutil.c32   build/iso_filesystem/isolinux/
elif (( $(lsb_release -s -i) == "Ubuntu" && $(lsb_release -s -c) == "trusty" )); then
  # Ubuntu Trusty (vieille version utilisée par Travis)
  ISOHYBRID_MBR="/usr/lib/syslinux/isohdpfx.bin"
  cp /usr/lib/syslinux/isolinux.bin  build/iso_filesystem/isolinux/
  cp /usr/lib/syslinux/menu.c32      build/iso_filesystem/isolinux/
  cp /usr/lib/syslinux/ldlinux.c32   build/iso_filesystem/isolinux/
else
  # Debian ou Ubuntu actuel. Nécessite les paquets syslinux et isolinux
  ISOHYBRID_MBR="/usr/lib/ISOLINUX/isohdpfx.bin"
  cp /usr/lib/ISOLINUX/isolinux.bin               build/iso_filesystem/isolinux/
  cp /usr/lib/syslinux/modules/bios/menu.c32      build/iso_filesystem/isolinux/
  cp /usr/lib/syslinux/modules/bios/ldlinux.c32   build/iso_filesystem/isolinux/
  cp /usr/lib/syslinux/modules/bios/libutil.c32   build/iso_filesystem/isolinux/
fi

# Configuration de syslinux
cat > build/iso_filesystem/isolinux/isolinux.cfg <<EOF
ui menu.c32
prompt 0
menu title Menu de demarrage
timeout 1

label live-amd64
  menu label ^Ubuntu Custom Live (amd64)
  menu default
  linux /live/vmlinuz
  append initrd=/live/initrd boot=live persistence

endtext
EOF

# Ajout du chargeur d'amorçage EFI
# Pour l'instant c'est un "hack", on a copié collé les dossiers à la main
# depuis l'ISO d'ubuntu
# @TODO Ajouter un gestionnaire d'amorçage correctement
cp -r third_party/{.disk,boot,EFI} build/iso_filesystem/

# Création de l'image
# @TODO Expliquer les options de xorriso
xorriso -as mkisofs \
  -o build/ubuntu-live-custom.iso \
  -isohybrid-mbr $ISOHYBRID_MBR \
  -c isolinux/boot.cat \
  -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img  \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  ./build/iso_filesystem \
  > /dev/null # Trop de logs pour Travis
