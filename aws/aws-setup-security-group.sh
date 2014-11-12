#!/usr/bin/env bash
#
# File:         aws-setup-security-group.sh
# Description:  This script creates a security group in AWS for a default Wirbelsturm cluster.

MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/../sh/common.sh

puts "+---------------------------------------------+"
puts "| CREATING AWS SECURITY GROUP FOR WIRBELSTURM |"
puts "+---------------------------------------------+"

VERSION="1.1"

warn
warn "Note: By default each Wirbelsturm machine runs its own local firewall."
warn "      For this reason we use only a single, simple AWS security group"
warn "      for Wirbelsturm."
warn

warn "Please configure the source CIDR. This sets the IP(s) which will be"
warn "    allowed SSH access to the servers deployed with Wirbelsturm. The"
warn "    default setting (0.0.0.0/0) allows SSH access from any IP."

read -e -p "AWS profile [default]: " PROFILE

if [ -z $PROFILE ]; then
  PROFILE="default"
fi

read -e -p "AWS region [us-west-2]: " REGION

if [ -z $REGION ]; then
  REGION="us-west-2"
fi

read -e -p "Source CIDR [0.0.0.0/0]: " SOURCE_CIDR

if [ -z $SOURCE_CIDR ]; then
  SOURCE_CIDR="0.0.0.0/0"
fi

read -e -p "Security group name [wirbelsturm]: " SECURITY_GROUP

if [ -z $SECURITY_GROUP ]; then
  SECURITY_GROUP="wirbelsturm"
fi

read -e -p "VPC ID (Optional) []: " VPC_ID

puts "Creating '$SECURITY_GROUP' security group for Wirbelsturm..."
if [ -z $VPC_ID ]; then
	SG_OUT=`aws --profile $PROFILE ec2 --region $REGION create-security-group --group-name $SECURITY_GROUP --description "Wirbelsturm cluster (security policy v$VERSION)"`
else
	SG_OUT=`aws --profile $PROFILE ec2 --region $REGION create-security-group --group-name $SECURITY_GROUP --description "Wirbelsturm cluster (security policy v$VERSION)" --vpc-id $VPC_ID`
fi

if [ $? -ne 0 ]; then
  warn "Note: If you want to delete the security group you can do so with:"
  warn
  warn "    $ aws ec2 --region $REGION delete-security-group --group-name $SECURITY_GROUP"
  warn
  warn "Note: VPC security groups cannot be deleted by group name. Instead use the following command substituting the secruity group ID for GROUP_ID:"
  warn
  warn "    $ aws ec2 --region $REGION delete-security-group --group-id GROUP_ID"
  warn
  warn "DELETING A GROUP WILL DELETE ALL OF ITS RULES AND IS NOT REVERSIBLE."
  exit 1
fi

GROUP_ID=`echo $SG_OUT | jq --raw-output '.GroupId'`

puts "Enable SSH access"
aws --profile $PROFILE ec2 --region $REGION authorize-security-group-ingress --protocol tcp --port 22 --cidr $SOURCE_CIDR --group-id $GROUP_ID > /dev/null || exit 1

puts "Enable access to Storm master"
# 6627 (thrift/Nimbus)
# 8080 (UI)
# 8081 (logs)
aws --profile $PROFILE ec2 --region $REGION authorize-security-group-ingress --protocol tcp --port 6627 --source-group $GROUP_ID --group-id $GROUP_ID > /dev/null || exit 1
aws --profile $PROFILE ec2 --region $REGION authorize-security-group-ingress --protocol tcp --port 8080 --source-group $GROUP_ID --group-id $GROUP_ID > /dev/null || exit 1
aws --profile $PROFILE ec2 --region $REGION authorize-security-group-ingress --protocol tcp --port 8081 --source-group $GROUP_ID --group-id $GROUP_ID > /dev/null || exit 1

puts "Enable access to Storm slaves"
# 3772 (drpc), 3773 (drpc invocations)
# 67xx supervisor ports
aws --profile $PROFILE ec2 --region $REGION authorize-security-group-ingress --protocol tcp --port 3772-3773 --source-group $GROUP_ID --group-id $GROUP_ID > /dev/null || exit 1
aws --profile $PROFILE ec2 --region $REGION authorize-security-group-ingress --protocol tcp --port 6700-6799 --source-group $GROUP_ID --group-id $GROUP_ID > /dev/null || exit 1

puts "Enable access to Kafka"
aws --profile $PROFILE ec2 --region $REGION authorize-security-group-ingress --protocol tcp --port 9092 --source-group $GROUP_ID --group-id $GROUP_ID > /dev/null || exit 1

puts "Enable access to Zookeeper"
aws --profile $PROFILE ec2 --region $REGION authorize-security-group-ingress --protocol tcp --port 2181 --source-group $GROUP_ID --group-id $GROUP_ID > /dev/null || exit 1

puts "Enable access to Redis"
aws --profile $PROFILE ec2 --region $REGION authorize-security-group-ingress --protocol tcp --port 6379 --source-group $GROUP_ID --group-id $GROUP_ID > /dev/null || exit 1

puts "------------------------------------------------------------------------"
puts "Summary of security group:"
aws --profile $PROFILE ec2 --region $REGION describe-security-groups --group-ids $GROUP_ID
puts "------------------------------------------------------------------------"

success "You can now use the AWS security group '$SECURITY_GROUP' for your Wirbelsturm cluster."
warn "Note: If you made any changes to the default port settings of Wirbelsturm you may need to adapt this script."
