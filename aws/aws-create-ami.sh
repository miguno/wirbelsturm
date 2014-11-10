#!/usr/bin/env bash

MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/../sh/common.sh

puts "+-------------------------------------------+"
puts "| CREATING CUSTOM LINUX AMI FOR WIRBELSTURM |"
puts "+-------------------------------------------+"

read -e -p "AWS profile [default]: " PROFILE

if [ -z $PROFILE ]; then
  PROFILE="default"
fi

read -e -p "AWS region [us-west-2]: " REGION

if [ -z $REGION ]; then
  REGION="us-west-2"
fi

read -e -p "Linux AMI (default PV EBS-Backed 64-bit, US West Oregon) [ami-55a7ea65]: " AMI

if [ -z $AMI ]; then
  AMI="ami-55a7ea65"
fi

SI_OUT=`aws --profile $PROFILE ec2 --region $REGION run-instances \
    --key-name wirbelsturm \
    --instance-type t1.micro \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":true,\"VolumeSize\":40,\"VolumeType\":\"io1\",\"Iops\":400}}]" \
    --security-groups wirbelsturm \
    --image-id $AMI` || exit 1
INSTANCE_ID=`echo $SI_OUT | jq --raw-output '.Instances[0].InstanceId'`
puts "InstanceId: $INSTANCE_ID"
puts "Waiting for instance to resolve host"
sleep 20

DI_OUT=`aws --profile $PROFILE ec2 --region $REGION describe-instances --instance-ids $INSTANCE_ID` || exit 1
HN=`echo $DI_OUT | jq --raw-output '.Reservations[0].Instances[0].PublicDnsName'`

puts "Hostname: '$HN'"
puts "Waiting for '$HN' to become available"
sleep 60

scp -i ~/.ssh/wirbelsturm.pem aws-prepare-image.sh puppetlabs.repo ec2-user@$HN:~
ssh -t -i ~/.ssh/wirbelsturm.pem ec2-user@$HN '~/aws-prepare-image.sh'

puts "Creating image..."
CI_OUT=`aws --profile $PROFILE ec2 --region $REGION create-image --name wirbelsturm-base-$INSTANCE_ID \
	--description 'Stock ami-55a7ea65 (Amazon Linux 2014.09.1) with Puppet 3.7.x and fix for vagrant-aws issue #72' \
	--instance-id $INSTANCE_ID`
IMAGE_ID=`echo $CI_OUT | jq --raw-output '.ImageId'`

puts "Waiting to verify image '$IMAGE_ID'"
sleep 120
aws --profile $PROFILE ec2 --region $REGION describe-images --image-ids $IMAGE_ID

puts "Terminating instance"
aws --profile $PROFILE ec2 --region $REGION terminate-instances --instance-ids $INSTANCE_ID

puts "Update your wirbelsturm.conf with image id '$IMAGE_ID'"

