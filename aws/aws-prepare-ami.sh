#! /bin/sh

aws ec2-run-instances \
    --region us-east-1 \
    --key data-services \
    --instance-type t1.micro \
    --block-device-mapping '/dev/sda1=:40:true:io1:400' \
    --group wirbelsturm \
    ami-55a7ea65

