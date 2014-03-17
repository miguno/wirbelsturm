#!/usr/bin/env bash
#
# File:         standalone-packager.sh
# Description:  This script packages Wirbelsturm's Puppet code for standalone
#               use, i.e. for use without Wirbelsturm/Vagrant

MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/common.sh

puts "Creating standalone Puppet package..."

### Prepare environment
OLD_PWD=`pwd`
WIRBELSTURM_BASE_DIR=$MY_DIR/..
cd $WIRBELSTURM_BASE_DIR

# The packaged files will be stored under this top-level directory in the tarball
TARBALL_EMBEDDED_BASE_DIR="vagrant-puppet"

# Generate package filename
FILE_PREFIX="wirbelsturm-puppet-standalone"
GIT_COMMIT=`git log -n 1 --oneline | awk '{ print $1 }'`
TIMESTAMP=`date +%Y%m%d%H%M%S`
FILE_NAME="${FILE_PREFIX}-${TIMESTAMP}-${GIT_COMMIT}.tgz"
ABS_FILE_NAME="${OLD_PWD}/$FILE_NAME"

BUILD_DIR=`mktemp -d /tmp/wirbelsturm-standalone-packager.XXXXXXXXXX`
TARBALL_BASE_DIR=$BUILD_DIR/${TARBALL_EMBEDDED_BASE_DIR}
mkdir $TARBALL_BASE_DIR
cd $BUILD_DIR

cleanup_and_exit() {
  local exitCode=$1
  rm -rf $BUILD_DIR
  cd $OLD_PWD
  exit $exitCode
}

### Package Puppet files
cp -a $WIRBELSTURM_BASE_DIR/puppet/* $TARBALL_BASE_DIR || cleanup_and_exit 1
# Vagrant uses a '-0' suffix
mv $TARBALL_BASE_DIR/modules $TARBALL_BASE_DIR/modules-0 || cleanup_and_exit 2
tar -czf $ABS_FILE_NAME `basename $TARBALL_BASE_DIR` || cleanup_and_exit 3

puts "Package available at $ABS_FILE_NAME"

### Cleanup
cleanup_and_exit 0
