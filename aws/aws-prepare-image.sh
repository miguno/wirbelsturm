#!/usr/bin/env bash

MY_DIR=`echo $(cd $(dirname $0); pwd)`

### Configuration start  ###

PUPPET_REPO_FILE=/etc/yum.repos.d/puppetlabs.repo
SUDOERS_FILE=/etc/sudoers.d/999-vagrant-cloud-init-requiretty

### Configuration end ###

# Resize root partition
sudo resize2fs /dev/sda1

sudo yum update -y
# Base packages we want to have available in all instances
# sudo yum install wget screen git python-boto -y

###
### Puppet bootstrapping
###

# Install PuppetLabs official yum repository for RHEL6
sudo rpm -ivh https://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-11.noarch.rpm
# Ensure we get the latest version of Puppet (3.x) by adding a 'priority' setting to the PuppetLabs repo,
# otherwise we may end up with an outdated Puppet 2.7 version from the default Amazon yum repo.
sudo cp puppetlabs.repo $PUPPET_REPO_FILE
sudo chown root:root $PUPPET_REPO_FILE
sudo chmod 644 $PUPPET_REPO_FILE
# Ensure yum is aware of the new repo
sudo yum clean all

# The 'json' gem for Ruby 1.8 is required for Puppet.  We must manually install the gem as part of our workaround to get
# Puppet up and running on Amazon Linux, even though Amazon Linux has recently switched from Ruby 1.8 (that Puppet
# needs) to Ruby 2.0.
# sudo yum install ruby18 rubygem18-json -y
sudo yum install puppet facter wget screen git python-boto -y

# Set Ruby 1.8 again as the default Ruby version.
#
# The previous installation of puppet (see above) pulled in Ruby 2.0, and on Amazon Linux the 2.0 version will then be
# used as the default.  This however will break Puppet 3.x when installed via the PuppetLabs RHEL 6 RPM for Puppet
# because that version/RPM of Puppet is built against Ruby 1.8.
# echo "*****************************************************************************************"
# echo "[WIRBELSTURM] In the following prompt please select Ruby 1.8 as the default Ruby version."
# echo "*****************************************************************************************"
# sudo alternatives --config ruby

# Required to allow Vagrant to provision the box as ec2-user without a tty
# (cf. error message: 'mkdir -p /vagrant failed')
# This fixes the problem described at:
# - https://github.com/mitchellh/vagrant-aws/issues/83
# - https://github.com/mitchellh/vagrant-aws/issues/72
# - https://github.com/mitchellh/vagrant-aws/pull/70/files
sudo sh -c "echo 'Defaults:ec2-user !requiretty' > $SUDOERS_FILE"
sudo sh -c "echo 'Defaults:root !requiretty' >> $SUDOERS_FILE"
sudo chmod 440 $SUDOERS_FILE
