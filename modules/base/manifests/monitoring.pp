# monitoring clients
class base::monitoring {
  class { '::collectd':
    purge           => true,
    recurse         => true,
    purge_config    => true,
    minimum_version => '5.7',
    manage_repo     => false,
    package_ensure  => latest,
  }

  collectd::plugin::write_graphite::carbon {'influxdb':
    graphitehost   => 'influxdb.service.dc1.consul',
    graphiteport   => 2003,
    graphiteprefix => '',
    protocol       => 'tcp'
  }

  # default plugins
  class { '::collectd::plugin::cpu':
    # aggregate cpu stats into one metric
    reportbycpu => false,
  }
  class { '::collectd::plugin::df':
    # ignore disk size metrics of special type disks (/dev, /proc, etc)
    fstypes          => ['nfs','tmpfs','autofs','gpfs','proc','devpts', 'devtmpfs', 'aufs'],
    ignoreselected   => true,
    valuespercentage => true,
  }
  class { '::collectd::plugin::disk': }
  class { '::collectd::plugin::interface':
    # ignore virtual/container interfaces (eg: docker)
    interfaces     => ['/.*-.*/'],
    ignoreselected => true,
  }
  class { '::collectd::plugin::load':
    report_relative => true,
  }
  class { '::collectd::plugin::memory':
    valuespercentage => true,
  }
  class { '::collectd::plugin::processes': }
  class { '::collectd::plugin::swap': }
  class { '::collectd::plugin::users': }

  # add statsd listeren for local processes
  class { 'collectd::plugin::statsd':
    host => '127.0.0.1',
    port => 8125,
  }

  # realise virtual resources
  Collectd::Plugin::Tail::File <| |>
}