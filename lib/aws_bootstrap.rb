require 'erb'
require 'yaml'

module AwsBootstrap
  def aws_cloud_config(hostname, role,
                       base_dir="", config_file="wirbelsturm.yaml", template_file="cloud-init/aws/cloud-config.erb")
    effective_config_file = File.join(base_dir, config_file)
    effective_template_file = File.join(base_dir, template_file)
    config = YAML.load_file(effective_config_file)

    @fqdn = "#{hostname}.#{config['domain']}"
    @role = role
    @aws_access_key = config['aws']['in_instance_user']['aws_access_key']
    @aws_secret_key = config['aws']['in_instance_user']['aws_secret_key']
    @aws_rclocal_url = config['aws']['rclocal_url']
    @user = config['aws']['local_user']

    template = ERB.new File.new(effective_template_file).read
    return template.result(binding)
  end
end
