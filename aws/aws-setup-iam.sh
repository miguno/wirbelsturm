#!/usr/bin/env bash
#
# File:         aws-setup-iam.sh
# Description:  This script creates two IAM users for Wirbelsturm.

MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MYDIR/../sh/common.sh

puts "+----------------------------------------+"
puts "| CREATING AWS IAM USERS FOR WIRBELSTURM |"
puts "+----------------------------------------+"

IAM_PATH="/wirbelsturm"
IAM_GROUP="wirbelsturm"
IN_INSTANCE_USER="wirbelsturm-ininstance"
IN_INSTANCE_USER_POLICY_FILE=$MYDIR/in-instance-iam-user.json
DEPLOY_USER="wirbelsturm-deploy"
DEPLOY_USER_POLICY_FILE=$MYDIR/deploy-iam-user.json
TIMESTAMP=`date +"%Y%m%d-%H%M%S"`

###
### IAM Group
###

puts "Creating Wirbelsturm IAM group..."
iam-groupcreate -g $IAM_GROUP -p $IAM_PATH || exit 1

###
### Deploy IAM user
###

puts "Creating deploy IAM user '$DEPLOY_USER'..."
iam-usercreate -u $DEPLOY_USER -g $IAM_GROUP -p $IAM_PATH || exit 1
KEYS=`iam-useraddkey -u $DEPLOY_USER`
DEPLOY_USER_ACCESS_KEY=`echo $KEYS | awk '{ print $1 }'`
DEPLOY_USER_SECRET_KEY=`echo $KEYS | awk '{ print $2 }'`

puts "Applying security policy to IAM user '$DEPLOY_USER'..."
iam-useruploadpolicy -u $DEPLOY_USER -f $DEPLOY_USER_POLICY_FILE \
  -p "Deploy_IAM_user_of_Wirbelsturm_v$TIMESTAMP" || exit 1

###
### In-instance IAM user
###

puts "Creating in-instance IAM user '$IN_INSTANCE_USER'..."
iam-usercreate -u $IN_INSTANCE_USER -g $IAM_GROUP -p $IAM_PATH || exit 1
KEYS=`iam-useraddkey -u $IN_INSTANCE_USER`
IN_INSTANCE_USER_ACCESS_KEY=`echo $KEYS | awk '{ print $1 }'`
IN_INSTANCE_USER_SECRET_KEY=`echo $KEYS | awk '{ print $2 }'`

puts "Applying security policy to IAM user '$IN_INSTANCE_USER'..."
iam-useruploadpolicy -u $IN_INSTANCE_USER -f $IN_INSTANCE_USER_POLICY_FILE \
  -p "In-instance_IAM_user_of_Wirbelsturm_v$TIMESTAMP" || exit 1

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
