# include base configuration applying only to hosted environment and which don't fit easily in hiera
# generic system configuration (users, accounts, ntp, ssh, security, etc)
class base::env::hosted (
  $docker=false,
){

  # enable apt unattended security upgrades
  class { '::unattended_upgrades': }

  class { 'base::firewall':
    docker => $docker,
  }

  # enable ntp
  class { '::ntp':
      servers => [
          '0.pool.ntp.org', '1.pool.ntp.org',
          '2.pool.ntp.org', '3.pool.ntp.org'
      ],
  }

  # enable ssh server
  class { '::ssh':
    storeconfigs_enabled => false,
    server_options       => {
      'PasswordAuthentication' => no,
    }
  }

  # let sudoers know not to change anything outside of puppet
  file {
      '/etc/sudoers.lecture':
            content => "THIS HOST IS MANAGED BY PUPPET. Please only make permanent changes\nthrough puppet and do not expect manual changes to be maintained!\nMore info: https://github.com/failmap/server\n\n";

      '/etc/sudoers.d/lecture':
            content => "Defaults\tlecture=\"always\"\nDefaults\tlecture_file=\"/etc/sudoers.lecture\"\n";
  }

  swap_file::files { 'default':
      ensure   => present,
  }

  # pam sudo ssh agent auth and user accounts
  class { 'pam_ssh_agent_auth': }
  class { 'accounts': }
}
