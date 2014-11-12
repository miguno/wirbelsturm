#!/usr/bin/env bash

MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/../sh/common.sh

HN=""
while [ -z $HN ]; do
  puts "about to sleep"
  sleep 2
done
puts "after while"