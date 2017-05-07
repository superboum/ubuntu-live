UBUNTU_VERSION=zesty
ROOT_PASSWORD=test
LIVE_USER=toto
LIVE_USER_PASSWORD=toto

./scripts/create_live_filesystem.sh $UBUNTU_VERSION
chroot ./build/live_filesystem bash -c "/usr/local/sbin/configure_system.sh $ROOT_PASSWORD $LIVE_USER $LIVE_USER_PASSWORD"
./scripts/create_iso_filesystem.sh
