# 0.7.0 (unreleased)

BACKWARDS INCOMPATIBILITIES

* Requires Vagrant 1.7.2 or later.
* Because of the upgrade to Vagrant 1.7.2, we were forced to change the locations/names of the Puppet manifests and
  modules directories on the target machines.  See the "BREAKING CHANGES" section in the
  [Vagrant Changelog for 1.7.2](https://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md#172-january-6-2015).
  Vagrant 1.7.2+ adds MD5-hash based suffixes to the manifests and modules directories, which broke our assumption
  on where to find these directories on the target machines (so we actually belong to the "minor number of people" who
  are affected by this change in Vagrant).  The new directories look like:
  `modules-8048a9ab32fda4a984b584e79dfe8cb7`.  Thankfully, in the current Vagrant implementation these suffixes are
  identical across deployments in our case, so the current fix simply renames the respective directory locations.
* We use Java 7 by default.


IMPROVEMENTS

* Update puppet_wirbelsturm-common to 1.0.5, which by default installs netcat on each machine.
* Update puppet-zookeeper to 1.0.8, which e.g. fixes ZK quorum deployments.

BUG FIXES

* `vagrant-scp.sh` now exits with a non-zero exit code in case of errors.


# 0.6.1 (September 09, 2014)

BACKWARDS INCOMPATIBILITIES

* Requires Vagrant 1.6.1 or later.
* Requires vagrant-hosts plugin 2.1.4 or later.

IMPROVEMENTS

* Add `ansible-playbook` wrapper script.
* bootstrap: Use new GitHub.com URL for retrieving raw user content.
* WS-10: source rvm script after ruby-bootstrap so that libarian-puppet is found (thanks neeleshs)
* WS-6: Fix Puppet installation on latest Amazon Linux AMI when creating custom AMIs
* WS-5: `$MYDIR` in AWS scripts should be `$MY_DIR` (thanks pbwilmot)
* WS-2: `bootstrap` now supports the `--skip-ruby` parameter.  If set, `bootstrap` will skip the installation
  of Ruby/rvm/bundler/gems. (thanks bzz)
* Improve `update-wirbelsturm.sh`
* Environment `default_environment`:
    * Enforce 'UTC' timezone
    * Enforce the use of Puppet 3.3.1 to have more deterministic builds compared to the previous setup where we always
      installed the latest Puppet version currently available.
* Update puppet-diamond to 1.0.2.
* Update puppet-graphite to 0.0.5.
* Update puppet-kafka to 2.0.3, which e.g. adds experimental support for writing Kafka data to tmpfs.
* Update puppet-redis to 1.0.4.
* Update puppet-statsd to 1.0.4.
* Update puppet-storm to 1.0.12, which e.g. supports running the new
  [logviewer](http://storm.incubator.apache.org/2013/12/08/storm090-released.html) daemon and
  [DRPC](https://storm.incubator.apache.org/documentation/Distributed-RPC.html) support.
* Update puppet-supervisor to 1.0.6.
* Update puppet-wirbelsturm_build to 1.0.3.
* Update puppet-wirbelsturm_common to 1.0.4, which hardens the NTP configuration (if NTP management is enabled).
* Update puppet-wirbelsturm_yumrepos to 1.0.2.
* Update puppet-zookeeper to 1.0.7.

BUG FIXES

* `deploy` now correctly writes its log files to the directory `provisioning-logs/` in the base Wirbelsturm directory,
  even when `deploy` is executed from within sub-directories of Wirbelsturm.
* Read `/etc/environment` to make `FACTER_*` env vars available on reboot.  This makes clusters work properly upon
  instance reboots on AWS. (thanks stevencdavis) [GH-20]


# 0.6.0 (March 17, 2014)

* Initial release
