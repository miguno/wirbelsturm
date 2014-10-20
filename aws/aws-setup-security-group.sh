#!/usr/bin/env bash
#
# File:         aws-setup-security-group.sh
# Description:  This script creates a security group in AWS for a default Wirbelsturm cluster.

MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/../sh/common.sh

puts "+---------------------------------------------+"
puts "| CREATING AWS SECURITY GROUP FOR WIRBELSTURM |"
puts "+---------------------------------------------+"

SECURITY_GROUP="wirbelsturm"
VERSION="1.1"

warn
warn "Note: By default each Wirbelsturm machine runs its own local firewall."
warn "      For this reason we use only a single, simple AWS security group"
warn "      for Wirbelsturm."
warn

puts "Creating '$SECURITY_GROUP' security group for Wirbelsturm..."
ec2-create-group $SECURITY_GROUP -d "Wirbelsturm cluster (security policy v$VERSION)"
if [ $? -ne 0 ]; then
  warn "Note: If you want to delete the security group you can do so with:"
  warn
  warn "    $ ec2-delete-group $SECURITY_GROUP"
  warn
  warn "DELETING A GROUP WILL DELETE ALL OF ITS RULES AND IS NOT REVERSIBLE."
  exit 1
fi

puts "Enable SSH access"
ec2-authorize -P tcp -p 22 $SECURITY_GROUP || exit 1

puts "Enable access to Storm master"
# 6627 (thrift/Nimbus)
# 8080 (UI)
ec2-authorize -P tcp -p 6627 $SECURITY_GROUP || exit 1
ec2-authorize -P tcp -p 8080 $SECURITY_GROUP || exit 1

puts "Enable access to Storm slaves"
# 3772 (drpc), 3773 (drpc invocations)
# 67xx supervisor ports
ec2-authorize -P tcp -p 3772-3773 $SECURITY_GROUP || exit 1
ec2-authorize -P tcp -p 6700-6799 $SECURITY_GROUP || exit 1

puts "Enable access to Kafka"
ec2-authorize -P tcp -p 9092 $SECURITY_GROUP || exit 1

puts "Enable access to Zookeeper"
# 2181 (for client connections)
# 2888 (for communication between servers in the ZK ensemble)
# 3888 (for leader election, used only by servers in the ZK ensemble)
ec2-authorize -P tcp -p 2181 $SECURITY_GROUP || exit 1
ec2-authorize -P tcp -p 2888 $SECURITY_GROUP || exit 1
ec2-authorize -P tcp -p 3888 $SECURITY_GROUP || exit 1

puts "Enable access to Redis"
ec2-authorize -P tcp -p 6379 $SECURITY_GROUP || exit 1

puts "------------------------------------------------------------------------"
puts "Summary of security group:"
ec2-describe-group $SECURITY_GROUP
puts "------------------------------------------------------------------------"

success "You can now use the AWS security group '$SECURITY_GROUP' for your Wirbelsturm cluster."
warn "Note: If you made any changes to the default port settings of Wirbelsturm you may need to adapt this script."
