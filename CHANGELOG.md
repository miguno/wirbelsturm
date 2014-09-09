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
