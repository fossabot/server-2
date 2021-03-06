# application independent generic docker daemon configuration
class base::docker (
  $ipv6_subnet=undef,
  $ipv6_ndpproxy=undef
){
  if $ipv6_subnet {
    $ipv6_parameters = ['--ipv6', "--fixed-cidr-v6=${ipv6_subnet}"]
  } else {
    $ipv6_parameters = []
  }

  class {'::docker':
    extra_parameters => $ipv6_parameters,
  }

  # use consul to provide service discovery and host->container DNS
  include base::consul

  # register docker container with consul for service discovery
  docker::run {'register':
    image   => 'gliderlabs/registrator:latest',
    net     => host,
    volumes => [
    '/var/run/docker.sock:/tmp/docker.sock',
    ],
    command => '-internal consul://localhost:8500',
  }

  # enable memory accounting for `docker stats`
  # http://awhitehatter.me/debian-jessie-wdocker/
  if ::lsbdistcodename == 'jessie' {
    file_line {'docker memory stats':
      line    => 'GRUB_CMDLINE_LINUX_DEFAULT="quiet cgroup_enable=memory swapaccount=1"',
      match   => 'GRUB_CMDLINE_LINUX_DEFAULT',
      replace => true,
      path    => '/etc/default/grub',
    } ~> exec {'update grub':
      command     => '/usr/sbin/update-grub',
      refreshonly => true,
    }
  }

  if $ipv6_ndpproxy {
    file { '/var/run/ndppd':
      ensure => directory,
    }
    file { '/var/lib/puppet/ndppd_0.2.5-1_amd64.deb':
      source => 'puppet:///modules/base/ndppd_0.2.5-1_amd64.deb',
    }
    ~> package {'ndppd':
      ensure   => latest,
      provider => dpkg,
      source   => '/var/lib/puppet/ndppd_0.2.5-1_amd64.deb',
    }
    -> file { '/etc/ndppd.conf':
      content => template('base/ndppd.conf.erb'),
    }
    ~> service {'ndppd': }
  }
}

