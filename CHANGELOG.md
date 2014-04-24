# 0.6.1 (unreleased)

BACKWARDS INCOMPATIBILITIES

* Requires Vagrant 1.5.4 or later.

IMPROVEMENTS

* WIRBELSTURM-6: Fix Puppet installation on latest Amazon Linux AMI when creating custom AMIs
* WIRBELSTURM-5: `$MYDIR` in AWS scripts should be `$MY_DIR` (thanks pbwilmot)
* WIRBELSTURM-2: `bootstrap` now supports the `--skip-ruby` parameter.  If set, `bootstrap` will skip the installation
  of Ruby/rvm/bundler/gems. (thanks bzz)
* Environment `default_environment`:
    * Enforce 'UTC' timezone
    * Enforce the use of Puppet 3.3.1 to have more deterministic builds compared to the previous setup where we always
      installed the latest Puppet version currently available.
* Update puppet-diamond to 1.0.2.
* Update puppet-graphite to 0.0.4.
* Update puppet-kafka to 2.0.1, which e.g. adds experimental support for writing Kafka data to tmpfs.
* Update puppet-redis to 1.0.3.
* Update puppet-statsd to 1.0.4.
* Update puppet-storm to 1.0.10, which e.g. supports running the new
  [logviewer](http://storm.incubator.apache.org/2013/12/08/storm090-released.html) daemon.
* Update puppet-supervisor to 1.0.6.
* Update puppet-wirbelsturm_build to 1.0.2.
* Update puppet-wirbelsturm_common to 1.0.3, which hardens the NTP configuration (if NTP management is enabled).
* Update puppet-zookeeper to 1.0.7.

BUG FIXES

* `deploy` now correctly writes its log files to the directory `provisioning-logs/` in the base Wirbelsturm directory,
  even when `deploy` is executed from within sub-directories of Wirbelsturm.


# 0.6.0 (March 17, 2014)

* Initial release
