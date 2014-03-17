require 'ipaddr'
require 'json'
require 'yaml'

module Wirbelsturm

  # TODO: Properly implement this method (e.g. 1.1.1.254 will succ() to 1.1.1.1, which is not what we want)
  def gen_ip(ip_start_range, i)
    start_ip = IPAddr.new ip_start_range
    # We chain-call IPAddr.succ() because IPAddr lacks a '+' operator.
    i.times.inject(start_ip) { |curr_ip| curr_ip.send('succ')}.to_s
  end

  def compile_node_catalog(config_file='wirbelsturm.yaml')
    config = YAML.load_file(config_file)
    c = config['nodes']
    nodes = {}
    c.each do |node, opts|
      num_servers = opts['count']
      for i in 1..num_servers
        hostname = '%s%s' % [ opts['hostname_prefix'], i.to_s]
        nodes[hostname] = { 'ip' => gen_ip(opts['ip_range_start'], i), 'node_role' => opts['node_role'] }
        opts['providers'].each do |provider, provider_opts|
          nodes[hostname][provider] = provider_opts
        end
      end
    end
    JSON.dump(nodes)
  end

end
