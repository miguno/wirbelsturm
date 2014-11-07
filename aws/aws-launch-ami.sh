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
    --instance-type t1.micro \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":true,\"VolumeSize\":40,\"VolumeType\":\"io1\",\"Iops\":400}}]" \
    --security-groups wirbelsturm \
    --image-id $AMI` || exit 1
INSTANCE_ID=`echo $SI_OUT | jq --raw-output '.Instances[0].InstanceId'`
puts "InstanceId: $INSTANCE_ID"

sleep 20

DI_OUT=`aws --profile $PROFILE ec2 --region $REGION describe-instances --instance-ids $INSTANCE_ID` || exit 1
HN=`echo $DI_OUT | jq --raw-output '.Reservations[0].Instances[0].PublicDnsName'`

puts "Hostname: '$HN'"
puts "+-------------------------------------------------------------------------------+"
puts "scp -i ~/.ssh/wirbelsturm.pem aws-prepare-image.sh puppetlabs.repo ec2-user@$HN:~"
puts "ssh -i ~/.ssh/wirbelsturm.pem ec2-user@$HN"
puts "./aws-prepare-image.sh"
puts "exit"
puts "ssh -i ~/.ssh/wirbelsturm.pem ec2-user@$HN"
puts "rm ~/.bash_history"
puts "exit"

# aws --profile redbull ec2 --region us-west-2 create-image --name wirbelsturm-base-2014.11 \
# --description 'Stock ami-55a7ea65 (Amazon Linux 2014.09.1) with Puppet 3.5.x and fix for vagrant-aws issue #72' \
# --instance-id i-9d1fd991

# {
#     "ImageId": "ami-6d105b5d"
# }

# aws --profile redbull ec2 --region us-west-2 describe-images --image-ids ami-6d105b5d

# {
#     "Images": [
#         {
#             "VirtualizationType": "paravirtual", 
#             "Name": "wirbelsturm-base-2014.11", 
#             "Hypervisor": "xen", 
#             "ImageId": "ami-6d105b5d", 
#             "RootDeviceType": "ebs", 
#             "State": "available", 
#             "BlockDeviceMappings": [
#                 {
#                     "DeviceName": "/dev/sda1", 
#                     "Ebs": {
#                         "VolumeSize": 40, 
#                         "Encrypted": false, 
#                         "VolumeType": "io1", 
#                         "DeleteOnTermination": true, 
#                         "SnapshotId": "snap-f6c5687c", 
#                         "Iops": 400
#                     }
#                 }
#             ], 
#             "Architecture": "x86_64", 
#             "ImageLocation": "670813696354/wirbelsturm-base-2014.11", 
#             "KernelId": "aki-fc8f11cc", 
#             "OwnerId": "670813696354", 
#             "RootDeviceName": "/dev/sda1", 
#             "Public": false, 
#             "ImageType": "machine", 
#             "Description": "Stock ami-55a7ea65 (Amazon Linux 2014.09.1) with Puppet 3.5.x and fix for vagrant-aws issue #72"
#         }
#     ]
# }

# aws --profile redbull ec2 --region us-west-2 terminate-instances --instance-ids i-9d1fd991

# {
#     "TerminatingInstances": [
#         {
#             "InstanceId": "i-9d1fd991", 
#             "CurrentState": {
#                 "Code": 32, 
#                 "Name": "shutting-down"
#             }, 
#             "PreviousState": {
#                 "Code": 16, 
#                 "Name": "running"
#             }
#         }
#     ]
# }
