# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.4.3", "< 1.5.0"

require 'yaml'
require_relative 'lib/aws_bootstrap'
require_relative 'lib/wirbelsturm'
include AwsBootstrap
include Wirbelsturm

vagrantfile_dir = File.expand_path(File.dirname(__FILE__))
config_file = ENV['WIRBELSTURM_CONFIG_FILE'] || File.join(vagrantfile_dir, 'wirbelsturm.yaml')
wirbelsturmConfig = YAML.load_file(config_file)
nodes = JSON.parse(compile_node_catalog(config_file), :symbolize_names => true)

###
### Main Vagrant
###
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # TODO: Verify whether hostmanager also works when deploying to Amazon AWS
  config.hostmanager.enabled = true
  #config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  nodes.each_pair do |node_name,node_opts|
    config.vm.define node_name do |c|
      c.vm.hostname = node_name.to_s
      c.vm.box = "centos6-compatible"
      c.vm.network :private_network, ip: node_opts[:ip]
      c.vm.synced_folder "./", "/vagrant", disabled: true
      c.vm.synced_folder "shared/", "/shared"
      # TODO: We can also try to move hieradata into a separate location (i.e. out of puppet/manifests/).
      # For the following example to work, we would need to add sth like "--environment #{ROLE}" to puppet.options:
      #config.vm.synced_folder "hieradata", "/etc/puppet/environments/#{ROLE}/hieradata"

      ###
      ### VirtualBox provider
      ###
      c.vm.provider :virtualbox do |vb, override|
        vb.customize [
            'modifyvm', :id,
            '--memory', node_opts[:virtualbox][:memory],
        ]
        # Use hostmanager as provisioner to make sure /etc/hosts is managed before all other provisioners run.
        # Note: `config.vm.provision ...` must be used, not `c.vm.provision ...`.
        config.vm.provision :hostmanager

        # Configure port forwarding if needed (does not work on AWS)
        if node_opts[:virtualbox][:forwarded_ports]
          forward_ports = node_opts[:virtualbox][:forwarded_ports]
          forward_ports.each { |ports|
            guest_port = ports[:guest]
            host_port = ports[:host]
            c.vm.network :forwarded_port, guest: guest_port, host: host_port
          }
        end
      end

      ###
      ### AWS provider
      ###
      c.vm.provider :aws do |aws, override|
        aws.access_key_id = wirbelsturmConfig['aws']['deploy_user']['aws_access_key']
        aws.secret_access_key = wirbelsturmConfig['aws']['deploy_user']['aws_secret_key']
        aws.keypair_name = wirbelsturmConfig['aws']['keypair_name']
        override.ssh.private_key_path = wirbelsturmConfig['aws']['private_key_path']
        override.ssh.username = wirbelsturmConfig['aws']['local_user']
        override.ssh.pty = true # Enable pty/tty to prevent sudo problems on RHEL OS family

        aws.region = "us-east-1"
        aws.region_config "us-east-1", :ami => node_opts[:aws][:ami]
        aws.instance_type = node_opts[:aws][:instance_type]
        aws.security_groups = node_opts[:aws][:security_groups]
        aws.tags = {
          'Name' => c.vm.hostname,
          'role' => node_opts[:node_role],
          'environment' => wirbelsturmConfig['environment'],
        }
        aws.user_data = aws_cloud_config(c.vm.hostname, node_opts[:node_role], base_dir=vagrantfile_dir)

        # The 'elastic_ip' parameter requires vagrant-aws >= 0.3.0.
        # See https://github.com/mitchellh/vagrant-aws/pull/65.
        #aws.elastic_ip = true
      end

      ###
      ### Puppet provisioning
      ###
      c.vm.provision :puppet do |puppet|
        puppet.module_path = 'puppet/modules'
        puppet.manifests_path = 'puppet/manifests'
        puppet.manifest_file  = 'site.pp'
        puppet.hiera_config_path = 'puppet/manifests/hiera.yaml'
        # Do not add a counter suffix to the `temp_dir` value of Vagrant's Puppet module.  While the counter may be
        # prevent issues for Vagrant setups in general it causes problems for how Wirbelsturm uses Vagrant(file).
        # `temp_dir` is undocumented, see plugins/provisioners/puppet/config/puppet.rb in Vagrant.
        puppet.temp_dir = '/tmp/vagrant-puppet'
        puppet.working_directory = puppet.temp_dir

        # Note: Facts injected by puppet.facter ARE NOT available in the VM when you run `facter`.
        puppet.facter = {
          'node_role' => node_opts[:node_role],
          'node_env'  => wirbelsturmConfig['environment'],
          'vagrant'  => true,
        }
      end

    end
  end
end
