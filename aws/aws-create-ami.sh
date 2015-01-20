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

read -e -p "AWS region [us-east-1]: " REGION

if [ -z $REGION ]; then
  REGION="us-east-1"
fi

read -e -p "Linux AMI (default HVM EBS-Backed 64-bit, US East N.Virginia) [ami-b66ed3de]: " AMI

if [ -z $AMI ]; then
  AMI="ami-b66ed3de"
fi

SI_OUT=`aws --profile $PROFILE ec2 --region $REGION run-instances \
    --key-name wirbelsturm \
    --instance-type t2.micro \
    --block-device-mappings "[{\"DeviceName\":\"/dev/xvda\",\"Ebs\":{\"DeleteOnTermination\":true,\"VolumeSize\":40,\"VolumeType\":\"io1\",\"Iops\":400}}]" \
    --security-groups wirbelsturm \
    --image-id $AMI` || exit 1
INSTANCE_ID=`echo $SI_OUT | jq --raw-output '.Instances[0].InstanceId'`
puts "InstanceId: $INSTANCE_ID"

puts "Waiting for instance to assign a public DNS name"
HN=''
while [[ -z "$HN" || "$HN" == *null* ]]
do
  sleep 2
  DI_OUT=`aws --profile $PROFILE ec2 --region $REGION describe-instances --instance-ids $INSTANCE_ID`
  HN=`echo $DI_OUT | jq --raw-output '.Reservations[0].Instances[0].PublicDnsName'`
done

puts "Hostname: '$HN'"
puts "Waiting for SSH on '$HN' to become available"
until scp -i ~/.ssh/wirbelsturm.pem aws-prepare-image.sh puppetlabs.repo ec2-user@$HN:~ > /dev/null 2>&1
  do sleep 2
done
ssh -t -i ~/.ssh/wirbelsturm.pem ec2-user@$HN '~/aws-prepare-image.sh'

puts "Creating image..."
CI_OUT=`aws --profile $PROFILE ec2 --region $REGION create-image --name wirbelsturm-base-$AMI-$INSTANCE_ID \
	--description 'Amazon Linux 2014.09.1 with Puppet 3.7.x and fix for vagrant-aws issue #72' \
	--instance-id $INSTANCE_ID`
IMAGE_ID=`echo $CI_OUT | jq --raw-output '.ImageId'`

puts "Waiting to verify image '$IMAGE_ID'"
STATUS=''
while [[ -z "$STATUS" || "$STATUS" != *available* ]]
do
  sleep 5
  ST_OUT=`aws --profile $PROFILE ec2 --region $REGION describe-images --image-ids $IMAGE_ID`
  STATUS=`echo $ST_OUT | jq --raw-output '.Images[0].State'`
done
puts "Image verified"

puts "Terminating instance"
STATUS=''
while [[ -z "$STATUS" || "$STATUS" != *terminated* ]]
do
  sleep 2
  ST_OUT=`aws --profile $PROFILE ec2 --region $REGION terminate-instances --instance-ids $INSTANCE_ID`
  STATUS=`echo $ST_OUT | jq --raw-output '.TerminatingInstances[0].CurrentState.Name'`
done
puts "Instance terminated"
puts "Update your wirbelsturm.conf with image id '$IMAGE_ID'"

