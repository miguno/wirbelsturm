#!/usr/bin/env bash

MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/../sh/common.sh

puts "+-------------------------------------------+"
puts "| CREATING LAUNCH LINUX AMI FOR WIRBELSTURM |"
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
    --instance-type m3.medium \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":true,\"VolumeSize\":40,\"VolumeType\":\"io1\",\"Iops\":400}}]" \
    --security-groups wirbelsturm \
    --image-id $AMI` || exit 1
INSTANCE_ID=`echo $SI_OUT | jq --raw-output '.Instances[0].InstanceId'`
puts "InstanceId: $INSTANCE_ID"

puts "Waiting for instance to assign public DNS name"

HN="null"
while [ $HN=="null" ] 
do
  sleep 1

  DI_OUT=`aws --profile $PROFILE ec2 --region $REGION describe-instances --instance-ids $INSTANCE_ID`
  puts $DI_OUT

  HN=`echo $DI_OUT | jq --raw-output '.Reservations[0].Instances[0].PublicDnsName'`
  puts $HN
done
puts $HN

puts "Hostname: '$HN'"
puts "Waiting for '$HN' to become available"
until scp -i ~/.ssh/wirbelsturm.pem aws-prepare-image.sh puppetlabs.repo ec2-user@$HN:~ > /dev/null 2>&1
  do sleep 1
done
ssh -t -i ~/.ssh/wirbelsturm.pem ec2-user@$HN '~/aws-prepare-image.sh'

puts "Creating image..."
CI_OUT=`aws --profile $PROFILE ec2 --region $REGION create-image --name wirbelsturm-base-$AMI-$INSTANCE_ID \
	--description 'Amazon Linux 2014.09.1 with Puppet 3.7.x and fix for vagrant-aws issue #72' \
	--instance-id $INSTANCE_ID`
IMAGE_ID=`echo $CI_OUT | jq --raw-output '.ImageId'`

puts "Waiting to verify image '$IMAGE_ID'"
sleep 120
aws --profile $PROFILE ec2 --region $REGION describe-images --image-ids $IMAGE_ID

puts "Terminating instance"
aws --profile $PROFILE ec2 --region $REGION terminate-instances --instance-ids $INSTANCE_ID

puts "Update your wirbelsturm.conf with image id '$IMAGE_ID'"

