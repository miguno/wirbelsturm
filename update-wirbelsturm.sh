#!/usr/bin/env bash
#
# File:         update-wirbelsturm.sh
# Description:  This script helps to update an existing checkout of Wirbelsturm.

MYSELF=`basename $0`
MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/sh/common.sh

puts "+----------------------------------------------------+"
puts "| UPDATING WIRBELSTURM TO LATEST DEVELOPMENT VERSION |"
puts "+----------------------------------------------------+"

puts
puts "*** WARNING: This script is not fully tested yet!***"
puts


###
### Wirbelsturm itself
###
puts -n "Updating Wirbelsturm code to latest code from git repository..."
GIT_MSG=`git pull`
if [ $? -ne 0 ]; then
  error "FAILED"
  error "There were problems when retrieving the latest Wirbelsturm code."
  error "Please fix those problems and re-run this script."
  exit 1
else
  success "OK"
fi
echo $GIT_MSG


###
### Vagrant
###
puts -n "Updating Vagrant environment..."
VAGRANT_MSG=`vagrant plugin update`
if [ $? -ne 0 ]; then
  error "FAILED"
  error $VAGRANT_MSG
else
  success "OK"
fi


###
### Puppet
###
puts -n "Updating Puppet environment..."
cd $MY_DIR/$PUPPET_DIR && LP_MSG=`librarian-puppet update 2>&1`
# librarian-puppet does not return proper exit codes on errors, hence we parse its output for typical problems even when
# it returns success (exit code 0).
if [[ $? -ne 0 ]] || [[ $LP_MSG == Could\ not\ find\ command* ]]; then
  error "FAILED"
else
  success "OK"
fi
cd $MY_DIR
echo $LP_MSG


###
### Check required Vagrant version
###
VAGRANT_VERSION_RANGE=`grep '^Vagrant.require_version ' $MY_DIR/Vagrantfile | sed 's/^Vagrant.require_version //'`
warn "Wirbelsturm requires Vagrant $VAGRANT_VERSION_RANGE -- make sure your Vagrant installation is compatible."
