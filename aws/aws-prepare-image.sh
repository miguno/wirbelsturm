#!/usr/bin/env bash

MY_DIR=`echo $(cd $(dirname $0); pwd)`

### Configuration start  ###

PUPPET_REPO_FILE=/etc/yum.repos.d/puppetlabs.repo
SUDOERS_FILE=/etc/sudoers.d/999-vagrant-cloud-init-requiretty

### Configuration end ###

# Resize root partition
sudo resize2fs /dev/sda1

sudo yum update -y
sudo rpm -ivh https://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-7.noarch.rpm
# Ensure we get the latest version of Puppet (3.x) by adding a 'priority' setting to the main Puppet repo
sudo cp puppetlabs.repo $PUPPET_REPO_FILE
sudo chown root:root $PUPPET_REPO_FILE
sudo chmod 644 $PUPPET_REPO_FILE
sudo yum clean all
sudo yum install puppet facter wget screen git python-boto -y

# Required to allow Vagrant to provision the box as ec2-user without a tty
# (cf. error message: 'mkdir -p /vagrant failed')
# This fixes the problem described at:
# - https://github.com/mitchellh/vagrant-aws/issues/83
# - https://github.com/mitchellh/vagrant-aws/issues/72
# - https://github.com/mitchellh/vagrant-aws/pull/70/files
sudo sh -c "echo 'Defaults:ec2-user !requiretty' > $SUDOERS_FILE"
sudo sh -c "echo 'Defaults:root !requiretty' >> $SUDOERS_FILE"
sudo chmod 440 $SUDOERS_FILE
