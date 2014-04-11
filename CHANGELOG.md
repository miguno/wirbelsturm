# 0.6.1 (unreleased)

IMPROVEMENTS

* WIRBELSTURM-2: `bootstrap` now supports the `--skip-ruby` parameter.  If set, `bootstrap` will skip the installation
  of Ruby/rvm/bundler/gems. (thanks bzz)
* Environment `default_environment`: enforce setting timezone to 'UTC'
* Update puppet-diamond to 1.0.2.
* Update puppet-graphite to 0.0.4.
* Update puppet-kafka to 2.0.0, which e.g. adds experimental support for writing Kafka data to tmpfs.
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
