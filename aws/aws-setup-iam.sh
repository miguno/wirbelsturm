#!/usr/bin/env bash
#
# File:         aws-setup-iam.sh
# Description:  This script creates two IAM users for Wirbelsturm.

MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/../sh/common.sh

puts "+----------------------------------------+"
puts "| CREATING AWS IAM USERS FOR WIRBELSTURM |"
puts "+----------------------------------------+"

IAM_PATH="/wirbelsturm/"
IAM_GROUP="wirbelsturm"
IN_INSTANCE_USER="wirbelsturm-ininstance"
IN_INSTANCE_USER_POLICY_FILE=file://$MY_DIR/in-instance-iam-user.json
DEPLOY_USER="wirbelsturm-deploy"
DEPLOY_USER_POLICY_FILE=file://$MY_DIR/deploy-iam-user.json
TIMESTAMP=`date +"%Y%m%d-%H%M%S"`

###
### IAM Group
###

puts "Creating Wirbelsturm IAM group..."
aws iam create-group --group-name $IAM_GROUP --path $IAM_PATH || exit 1

###
### Deploy IAM user
###

puts "Creating deploy IAM user '$DEPLOY_USER'..."
aws iam create-user --user-name $DEPLOY_USER --path $IAM_PATH || exit 1
aws iam add-user-to-group --user-name $DEPLOY_USER --group-name $IAM_GROUP
aws iam create-access-key --user-name $DEPLOY_USER
KEYS=`aws iam list-access-keys --user-name $DEPLOY_USER`
DEPLOY_USER_ACCESS_KEY=`echo $KEYS | awk '{ print $1 }'`
DEPLOY_USER_SECRET_KEY=`echo $KEYS | awk '{ print $2 }'`

puts "Applying security policy to IAM user '$DEPLOY_USER'..."
aws iam put-user-policy --user-name $DEPLOY_USER --policy-document $DEPLOY_USER_POLICY_FILE \
  --policy-name "Deploy_IAM_user_of_Wirbelsturm_v$TIMESTAMP" || exit 1

###
### In-instance IAM user
###

puts "Creating in-instance IAM user '$IN_INSTANCE_USER'..."
aws iam create-user --user-name $IN_INSTANCE_USER --path $IAM_PATH || exit 1
aws iam add-user-to-group --user-name $IN_INSTANCE_USER --group-name $IAM_GROUP
aws iam create-access-key --user-name $IN_INSTANCE_USER
KEYS=`aws iam list-access-keys --user-name $IN_INSTANCE_USER`
IN_INSTANCE_USER_ACCESS_KEY=`echo $KEYS | awk '{ print $1 }'`
IN_INSTANCE_USER_SECRET_KEY=`echo $KEYS | awk '{ print $2 }'`

puts "Applying security policy to IAM user '$IN_INSTANCE_USER'..."
aws iam put-user-policy --user-name $IN_INSTANCE_USER --policy-document $IN_INSTANCE_USER_POLICY_FILE \
  --policy-name "In-instance_IAM_user_of_Wirbelsturm_v$TIMESTAMP" || exit 1

###
### Post installation
###

success "AWS IAM setup of Wirbelsturm completed!"
puts
puts "Write down the following values and add them to the 'aws' section"
puts "in your wirbelsturm.yaml configuration."
puts
puts "  Deploy IAM user:"
puts "  ---------------------"
puts "  AWS Access Key: $DEPLOY_USER_ACCESS_KEY"
puts "  AWS Secret Key: $DEPLOY_USER_SECRET_KEY"
puts
puts "  In-instance IAM user:"
puts "  ---------------------"
puts "  AWS Access Key: $IN_INSTANCE_USER_ACCESS_KEY"
puts "  AWS Secret Key: $IN_INSTANCE_USER_SECRET_KEY"
puts
