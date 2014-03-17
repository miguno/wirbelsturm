# Wirbelsturm-less deployment: using the Puppet/Hiera setup of Wirbelsturm standalone

Several users have asked how they can re-use their existing Wirbelsturm setup that they created for local development
and testing in order to deploy "real" environments, e.g. backed by a couple of bare-metal machines.  A different but
related use case is situations where you cannot or are not allwed to use Wirbelsturm and/or Vagrant to deploy to
non-local environments (i.e. to anything but your local computer).

Taking a step back there are two main approaches to perform such deployments if you already have a working Wirbelsturm
setup.  In both scenarios will make use only of the Puppet/Hiera code in your Wirbelsturm setup.

* Option 1: Follow the approach described in this document.  Here, you will create a snapshot file of your Wirbelsturm
  setup (including all Puppet/Hiera related code but excluding everything Vagrant related), transfer those snapshots
  to the target machines, and run `puppet apply`.
* Option 2: Alternatively you can leverage your existing Puppet infrastructure (if you have one).  Here, you migrate
  your Puppet module setup as configured in `Puppetfile` and your Hiera configuration and data.  Describing how to do
  this is beyond the scope of this document.  However if you already have a working Puppet infrastructure you should
  know what you need to do.

In the following sections of this document we describe how your Puppet setup in Wirbelsturm can be used without
Wirbelsturm/Vagrant according to option 1 above.

---

Table of Contents

* <a href="#overview">Overview</a>
* <a href="#packaging">Package the Puppet code for standalone use</a>
* <a href="#deploying">Perform the actual deployment</a>
* <a href="#notes">Notes</a>

---


<a name="overview"></a>

# Overview of deployment process

1. Package the Puppet code -- manifests, modules, Hiera data -- for standalone use via the included
   [puppet-packager.sh](sh/puppet-packager.sh) script.
2. Perform the actual deployment.


<a name="packaging"></a>

# Package the Puppet code for standalone use

Run the command to package the Puppet code in Wirbelsturm for standalone use:

```bash
$ sh/puppet-packager.sh
```

This will create a ready-to-use standalone snapshot file that can be uploaded to the target machine.

The snapshot files are named as follows:

    # timestamp of file creation -------.           .---- most recent git commit in Wirbelsturm repository
    #                                   |           |     (code version identifier)
    #                             |-----+------| |--+--|
    wirbelsturm-puppet-standalone-20130830163446-ecefd0b.tgz

The naming scheme was deliberately chosen so that commands such as `ls -l` will properly sort the snapshot files by
timestamp.  The code version identifier helps to identify, well, which code version was actually packaged for
deployment.


<a name="deploying"></a>

# Perform the actual deployment

1. Copy the standalone snapshot file to the target box.  You can use tools like `scp` for that.
2. Extract the tarball to `/tmp/vagrant-puppet/` and perform the deployment via `puppet apply`.
   * At the moment the Puppet code MUST be rooted at `/tmp/vagrant-puppet/` (with sub-directories such as
     `/tmp/vagrant-puppet/manifests/`).  This is for technical reasons due to how Puppet/Hiera integrates with Vagrant.

Normally you should inject at least the `node_env` Puppet fact to the shell environment in which you run `puppet apply`
so that the Hiera settings of Wirbelsturm can be properly detected for the target machine.  To achieve this you must
set an environment variable named `FACTER_node_env`, whose value is the name of the target deployment environment you
configured under `environments/<environment-name>.yaml` in Hiera (see
[environments/](puppet/manifests/hieradata/environments/)).  See the example below for details.

**Tip:** If you want to perform a dry-run of the Puppet code on the target you only need to add the `--noop`
parameter to `puppet apply`.

Here are example instructions for the fictitious deployment environment `storm-production-nyc`:

```bash
# WARNING: Make sure that
#
#    1) You are on the correct target box.
#    2) You have configured the correct deployment environment via FACTER_node_env.

$ rm -rf /tmp/vagrant-puppet/
$ cd /tmp
$ tar -xzf /path/to/wirbelsturm-puppet-standalone-<SNAPSHOT-IDENTIFIER>.tgz
$ cd vagrant-puppet/

# Here: Deploying a machine in the environment 'storm-production-nyc'.  We are also manually setting the `fqdn` fact,
#       in case the target machine is not properly configured in that regard.
$ sudo FACTER_node_env='storm-production-nyc' FACTER_fqdn=`hostname --fqdn` \
    puppet apply \
    --hiera_config /tmp/vagrant-puppet/manifests/hiera.yaml \
    --modulepath /tmp/vagrant-puppet/modules-0 \
    --detailed-exitcodes /tmp/vagrant-puppet/manifests/site.pp
```

**IMPORTANT:** Make sure you configure the _correct deployment environment_ via the environment variable
`FACTER_node_env`.   This environment variable injects the custom Puppet fact `node_env` which is used to determine the
correct Hiera files that need to be loaded by the Puppet code.  See
[environments/](puppet/manifests/hieradata/environments/) for existing environments that ship with Wirbelsturm.


<a name="notes"></a>

# Notes

In this type of deployments you must somehow inject any required Puppet facts such as `node_env` or `node_role`,
typically through `FACTOR_*` shell environment variables.  If you deploy manually however it is easy to make mistakes:
you may misspell variable names and/or values, you may forget to add those variables at all, you may use the wrong
value for the target machine, etc.  Also, you may find it difficult to correctly put injecting those shell variables
under version control (unlike data in your Hiera YAML files, for instance, which should reside in, say, a git
repository).

One simple approach to reduce the risk of mistakes is to make use only of the `node_env` fact, and skip using
`node_role` completely.  If you follow that approach you should create per-host YAML files under
`hieradata/environments/<environment-name>/hosts/<hostname>.yaml`, and put any required configuration into those
files.

* Example: `environments/storm-production-nyc/hosts/server21.yaml`

The drawback of this approach, however, is that you will need to duplicate Hiera configuration data if you have
multiple machines of the same role/purpose.
