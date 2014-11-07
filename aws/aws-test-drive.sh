#! /bin/sh

export EC2_PRIVATE_KEY=~/.ssh/wirbelsturm.pem
export INSTANCE_ID=`aws --profile redbull ec2 run-instances --region us-west-2 \
  --user-data file://cloud-init/aws/cloud-config.erb --key-name wirbelsturm \
  --instance-type t1.micro --image-id ami-fb8e9292 | jq --raw-output '.Instances[0].InstanceId'`