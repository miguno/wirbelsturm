#!/usr/bin/env bash
#
# File:         update-wirbelsturm.sh
# Description:  This script helps to update an existing checkout of Wirbelsturm.

MYSELF=`basename $0`
MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/sh/common.sh

puts "+----------------------+"
puts "| UPDATING WIRBELSTURM |"
puts "+----------------------+"

puts
puts "*** WARNING: This module is a quick hack and is not fully tested yet!***"
puts

###
### Wirbelsturm itself
###
puts -n "Updating Wirbelsturm code..."
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
# TODO: Update Vagrant plugins once Vagrant 1.5.0 is released via `vagrant plugin update`
if [ $? -ne 0 ]; then
  error "FAILED"
else
  success "OK"
fi
echo "(Not implemented yet.)"


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
