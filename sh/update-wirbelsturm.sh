#!/usr/bin/env bash
#
# File:         update-wirbelsturm
# Description:  This script updates Wirbelsturm to the latest development version

MYSELF=`basename $0`
MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/common.sh

puts "+----------------------------------------------------+"
puts "| UPDATING WIRBELSTURM TO LATEST DEVELOPMENT VERSION |"
puts "+----------------------------------------------------+"

###
### Git
###
puts "Retrieving latest code from git repository..."
git pull

###
### Vagrant plugins
###
puts "Updating Vagrant plugins"
vagrant plugin update vagrant-aws
vagrant plugin update vagrant-awsinfo
vagrant plugin update vagrant-hosts

###
### Puppet
###
puts "Updating Puppet modules..."
cd $MY_DIR/../$PUPPET_DIR
librarian-puppet update
cd $MY_DIR

###
### Check required Vagrant version
###
VAGRANT_VERSION_RANGE=`grep '^Vagrant.require_version ' $MY_DIR/../Vagrantfile | sed 's/^Vagrant.require_version //'`
warn "Wirbelsturm requires Vagrant $VAGRANT_VERSION_RANGE -- make sure your Vagrant installation is compatible."
