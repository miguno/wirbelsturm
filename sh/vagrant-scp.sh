#!/bin/bash
#
# File:         vagrant-scp.sh
# Description:  A convenience script to allow scp'ing between the host machine and a Vagrant-controlled guest.
#
# Known limitations:
# - scp'ing from guest to guest is not supported (e.g. '... nimbus1:/foo zookeeper1:/bar' does not work)

MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/common.sh

case $OS in
  $OS_MAC)
    SED_OPTIONS="-En"
    ;;
  $OS_LINUX)
    SED_OPTIONS="-rn"
    ;;
  $OS_UNKNOWN)
    SED_OPTIONS="-rn"
    echo "WARNING: Could not detect your OS flavor, so I am trying with sed options '$SED_OPTIONS'."
    ;;
esac

# Detect guest hostname
VAGRANT_HOSTNAME=`echo $@ | sed $SED_OPTIONS 's/^(.*[[:space:]]+)*([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*):.*$/\2/p'`
if [ -z "$VAGRANT_HOSTNAME" ]; then
  VAGRANT_HOSTNAME="default"
fi

SCP_OPTIONS=`vagrant ssh-config $VAGRANT_HOSTNAME | awk -v ORS=" " '{print "-o " $1 "=" $2}'`
scp $SCP_OPTIONS "$@" || echo "ERROR: Transfer failed." ; exit 1
