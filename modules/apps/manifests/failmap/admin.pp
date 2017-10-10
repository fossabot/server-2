# Configure the Admin frontend as well as the basic service requirements (database, queue broker)
class apps::failmap::admin {
  include common

  $hostname = 'admin.faalkaart.nl'
  $appname = 'failmap-admin'

  $db_name = 'failmap'
  $db_user = $db_name

  # database
  $random_seed = file('/var/lib/puppet/.random_seed')
  $db_password = fqdn_rand_string(32, '', "${random_seed}${db_user}")
  mysql::db { $db_name:
    user     => $db_user,
    password => $db_password,
    host     => 'localhost',
    grant    => ['SELECT', 'UPDATE', 'INSERT', 'DELETE', 'CREATE', 'INDEX', 'DROP', 'ALTER'],
  }

  file { "/srv/${appname}/":
    ensure => directory,
  } ->
  exec { "docker-volume-${appname}-static":
    command => "/usr/bin/docker volume create --name ${appname}-static --opt type=none --opt device=/srv/${appname}/ --opt o=bind",
    unless  => "/usr/bin/docker volume inspect ${appname}-static",
  } -> Docker::Run[$appname]

  $secret_key = fqdn_rand_string(32, '', "${random_seed}secret_key")
  docker::run { $appname:
    image   => 'registry.gitlab.com/failmap/admin:latest',
    command => 'runuwsgi',
    volumes => [
      # make mysql accesible from within container
      '/var/run/mysqld/mysqld.sock:/var/run/mysqld/mysqld.sock',
      # expose static files to host for direct serving by webserver
      "${appname}-static:/srv/${appname}",
    ],
    env     => [
      'DB_ENGINE=mysql',
      'DB_HOST=/var/run/mysqld/mysqld.sock',
      "DB_NAME=${db_name}",
      "DB_USER=${db_user}",
      "DB_PASSWORD=${db_password}",
      "SECRET_KEY=${secret_key}",
      "ALLOWED_HOSTS=${hostname}",
      # name by which service is known to service discovery (consul)
      "SERVICE_NAME=${appname}",
    ],
    expose => [8000],
  }
  # ensure containers are up before restarting nginx
  # https://gitlab.com/failmap/server/issues/8
  Docker::Run[$appname] -> Service['nginx']

  sites::vhosts::proxy { $hostname:
    proxy            => "${appname}.service.${base::consul::dc}.consul:8000",
    webroot          => "/srv/${appname}/",
    nowww_compliance => class_c,
    # use consul as proxy resolver
    resolver         => ['localhost:8600'],
  }
}
