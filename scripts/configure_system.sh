LIVE_USER=$1          # --> Nom de l'utilisateur principal (ex: fabriqueurs)

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

# Configuration de APT pour ajouter des dépôts supplémentaires
#  - universe : paquets libres maintenus par la communauté
#  - multiverse : paquets non libres maintenus par la communauté
#  - restricted : paquets non libres maintenus par Canonical

sed -i "s/main$/main universe multiverse restricted/" /etc/apt/sources.list

# Installation des logiciels via APT
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get dist-upgrade -y

apt-get install -y \
  linux-generic \
  ubuntu-minimal \
  xubuntu-desktop \
  language-pack-fr \
  live-boot \
  \
  vim \
  git \
  sudo \
  man \
  wget \
  tar \
  \
  arduino \
  inkscape \
  blender \
  freecad \
  openscad \
  git \
  kicad \
  gimp \

# Le paquet blueman est buggué
apt-get purge -y blueman

# Configuration de la langue et du clavier
debconf-set-selections <<EOF
locales	locales/locales_to_be_generated	multiselect	fr_FR.UTF-8 UTF-8
locales	locales/default_environment_locale	select	fr_FR.UTF-8
keyboard-configuration	keyboard-configuration/switch	select	No temporary switch
keyboard-configuration	keyboard-configuration/layoutcode	string	fr
keyboard-configuration	keyboard-configuration/unsupported_config_options	boolean	true
keyboard-configuration	keyboard-configuration/unsupported_layout	boolean	true
keyboard-configuration	keyboard-configuration/variantcode	string
keyboard-configuration	keyboard-configuration/xkb-keymap	select
keyboard-configuration	console-setup/detect	detect-keyboard
keyboard-configuration	keyboard-configuration/unsupported_options	boolean	true
keyboard-configuration	keyboard-configuration/altgr	select	The default for the keyboard layout
keyboard-configuration	keyboard-configuration/toggle	select	No toggling
keyboard-configuration	keyboard-configuration/store_defaults_in_debconf_db	boolean	true
keyboard-configuration	keyboard-configuration/unsupported_config_layout	boolean	true
keyboard-configuration	keyboard-configuration/optionscode	string	terminate:ctrl_alt_bksp
keyboard-configuration	keyboard-configuration/compose	select	No compose key
keyboard-configuration	keyboard-configuration/variant	select	French
keyboard-configuration	keyboard-configuration/modelcode	string	pc105
keyboard-configuration	keyboard-configuration/model	select	Generic 105-key (Intl) PC
keyboard-configuration	console-setup/detected	note
keyboard-configuration	console-setup/ask_detect	boolean	false
keyboard-configuration	keyboard-configuration/layout	select	French
keyboard-configuration	keyboard-configuration/ctrl_alt_bksp	boolean	true
EOF

dpkg-reconfigure locales
dpkg-reconfigure keyboard-configuration

# Création de l'utilisateur non privilégié et d'un group a son nom
#  - sudo: Permet d'utiliser la commande sudo pour des tâches administratives
#  - dialout: Nécessaire pour la communication Arduino et Repetier
useradd $LIVE_USER --create-home 
usermod -a -G dialout,sudo $LIVE_USER

# Autorisation sudo sans mdp (il n'y a pas de mdp sur le système)
sed -i 's/%sudo\s*ALL=(ALL:ALL)\s*ALL/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Activation de la connexion automatique au démarrage
cat > /etc/lightdm/lightdm.conf.d/01_autologin.conf <<EOF
[SeatDefaults]
autologin-user=$LIVE_USER
autologin-user-timeout=0
EOF

# Téléchargement de snap! (depth 1 -> on ne télécharge pas l'historique des modifications)
git clone --depth 1 https://github.com/jmoenig/Snap--Build-Your-Own-Blocks /opt/snap

# Téléchargement et installation de Repetier
apt-get install -y mono-reference-assemblies-2.0 mono-devel
rm -rf /opt/repetier
wget http://download.repetier.com/files/host/linux/repetierHostLinux_2_0_0.tgz -O /tmp/repetier.tgz
tar xzf /tmp/repetier.tgz --directory /opt/
rm -r /tmp/repetier.tgz
/opt/RepetierHost/installDependenciesDebian

# Création de raccourcis
# @TODO

# Nettoie le système de fichier
rm -f /var/lib/dbus/machine-id
apt-get clean
umount -l /proc
umount -l /sys
umount -l /dev/pts
