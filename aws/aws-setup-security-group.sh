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
VERSION="1.0"

warn
warn "Note: By default each Wirbelsturm machine runs its own local firewall."
warn "      For this reason we use only a single, simple AWS security group"
warn "      for Wirbelsturm."
warn

warn "Please configure the source CIDR. This sets the IP(s) which will be"
warn "    allowed SSH access to the servers deployed with Wirbelsturm. The"
warn "    default setting (0.0.0.0/0) allows SSH access from any IP."

read -e -p "Source CIDR [0.0.0.0/0]: " SOURCE_CIDR

if [ -z "$SOURCE_CIDR" ]; then
  SOURCE_CIDR="0.0.0.0/0"
fi

puts "Creating '$SECURITY_GROUP' security group for Wirbelsturm..."
aws ec2 create-security-group --group-name $SECURITY_GROUP --description "Wirbelsturm cluster (security policy v$VERSION)"
if [ $? -ne 0 ]; then
  warn "Note: If you want to delete the security group you can do so with:"
  warn
  warn "    $ aws ec2 delete-security-group --group-name $SECURITY_GROUP"
  warn
  warn "DELETING A GROUP WILL DELETE ALL OF ITS RULES AND IS NOT REVERSIBLE."
  exit 1
fi

puts "Enable SSH access"
aws ec2 authorize-security-group-ingress --protocol tcp --port 22 --cidr $SOURCE_CIDR --group-name $SECURITY_GROUP || exit 1

puts "Enable access to Storm master"
# 6627 (thrift/Nimbus)
# 8080 (UI)
aws ec2 authorize-security-group-ingress --protocol tcp --port 6627 --source-group $SECURITY_GROUP --group-name $SECURITY_GROUP || exit 1
aws ec2 authorize-security-group-ingress --protocol tcp --port 8080 --source-group $SECURITY_GROUP --group-name $SECURITY_GROUP || exit 1

puts "Enable access to Storm slaves"
# 3772 (drpc), 3773 (drpc invocations)
# 67xx supervisor ports
aws ec2 authorize-security-group-ingress --protocol tcp --port 3772-3773 --source-group $SECURITY_GROUP --group-name $SECURITY_GROUP || exit 1
aws ec2 authorize-security-group-ingress --protocol tcp --port 6700-6799 --source-group $SECURITY_GROUP --group-name $SECURITY_GROUP || exit 1

puts "Enable access to Kafka"
aws ec2 authorize-security-group-ingress --protocol tcp --port 9092 --source-group $SECURITY_GROUP --group-name $SECURITY_GROUP || exit 1

puts "Enable access to Zookeeper"
aws ec2 authorize-security-group-ingress --protocol tcp --port 2181 --source-group $SECURITY_GROUP --group-name $SECURITY_GROUP || exit 1

puts "Enable access to Redis"
aws ec2 authorize-security-group-ingress --protocol tcp --port 6379 --source-group $SECURITY_GROUP --group-name $SECURITY_GROUP || exit 1

puts "------------------------------------------------------------------------"
puts "Summary of security group:"
aws ec2 describe-security-groups --group-names $SECURITY_GROUP
puts "------------------------------------------------------------------------"

success "You can now use the AWS security group '$SECURITY_GROUP' for your Wirbelsturm cluster."
warn "Note: If you made any changes to the default port settings of Wirbelsturm you may need to adapt this script."
