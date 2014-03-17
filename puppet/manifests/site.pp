# Configure deployment environment
if !$::node_env {
  notice("Deployment environment not defined yet => Setting deployment environment from Hiera")
  $node_env = hiera('node_env', 'default-environment')
}
notice("Deployment environment: '${::node_env}'")


if $::vagrant {
  notice("I am running within a Vagrant-controlled environment")

  notice("Disabling firewall...")
  class { 'firewall':
    ensure => 'stopped'
  }
}
else {
  notice("I am running within a bare metal (i.e. non-Vagrant) environment")
}

if $::node_role {
  notice("I have been assigned the role '${::node_role}'")
}
else {
  notice("I have not been assigned a role via the \$node_role fact.")
}


# Assign classes to nodes
hiera_include('classes')

# Ensure that all yumrepo types will get processed before any packages that don't have 'rpm' as their
# provider.  The latter exclusion is important so that we can use, for example, the EPEL RPM package
# to help install the yum repository.
node default {
  Yumrepo <| |> -> Package <| provider != 'rpm' |>
}
