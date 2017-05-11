#!/bin/bash
LIVE_USER=$1
chroot ./build/live_filesystem bash -c "/usr/local/sbin/configure_system.sh $LIVE_USER"

exit 0
