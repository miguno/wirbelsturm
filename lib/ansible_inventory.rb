#!/usr/bin/env ruby
#
# An external inventory script for Ansible that provides information about running Vagrant VMs.
#
# For background information please take a look at:
#
# - http://ansibleworks.com/docs/intro_inventory.html
# - http://www.ansibleworks.com/docs/developing_inventory.html
#

require 'json'
require 'yaml'

@@my_dir = File.expand_path(File.dirname(__FILE__))

def host_to_group(wirbelsturm_cfg_file = ENV.fetch('WIRBELSTURM_CONFIG_FILE', File.join(@@my_dir, '..', 'wirbelsturm.yaml')))
  # Returns a hash that maps a hostname of a Vagrant VM to its "group" in Wirbelsturm's wirbelsturm.yaml.
  #
  # Note: In Ansible a host can be a member of multiple groups.  Due to the current structure of wirbelsturm.yaml,
  # however, in the case of Wirbelsturm a host will only ever be a member of a single group.
  config = YAML.load_file(wirbelsturm_cfg_file)
  c = config['nodes']
  host2group = {}
  c.each do |group, opts|
    num_servers = opts['count']
    for i in 1..num_servers
      hostname = '%s%s' % [ opts['hostname_prefix'], i.to_s]
      host2group[hostname] = group
    end
  end
  host2group
end

def running_hosts()
  # Returns an array of hostnames of those Vagrant VMs that are up and running.
  `vagrant status --machine-readable | grep ",state,running$" | cut -d',' -f 2`.split("\n")
end

def compile_ansible_inventory(running_hosts, host2group)
  # Returns an Ansible-compatible inventory listing of all running Vagrant VMs.
  # See http://www.ansibleworks.com/docs/developing_inventory.html
  running_host2group = host2group.select { |h| running_hosts.include? h }
  hash = running_host2group.group_by { |h,g| g }
  group_to_hosts = hash.merge(hash) {|group,host2group_pairs| host2group_pairs.flat_map { |h,g| h } }
end

def host_info(host, running_hosts)
  # Returns an Ansible-compatible hash of host data of a (running) Vagrant VM.
  # See http://www.ansibleworks.com/docs/developing_inventory.html
  host_data = {}
  if running_hosts.include? host
    ssh_config = `vagrant ssh-config #{host}`
    if not ssh_config.empty?
      m = /HostName (?<ip>[\d.]+)(\n.*)*\sUser (?<user>[\w-]+)(\n.*)*\sPort (?<port>\d+)(\n.*)*\sIdentityFile (?<ssh_key>.*)\n/.match(ssh_config)
      host_data["ansible_ssh_host"] = m[:ip]
      host_data["ansible_ssh_port"] = m[:port]
      host_data["ansible_ssh_user"] = m[:user]
      host_data["ansible_ssh_private_key_file"] = m[:ssh_key]
    end
  end
  host_data
end

#
# CLI interface
#
if ARGV.length == 1 and ARGV[0] == "--list"
  puts JSON.pretty_generate(compile_ansible_inventory(running_hosts(), host_to_group()))
elsif ARGV.length == 2 and ARGV[0] == "--host"
  host = ARGV[1]
  puts JSON.pretty_generate(host_info(host, running_hosts()))
else
  puts "Usage: #{__FILE__} [--list|--host <hostname>]"
end
