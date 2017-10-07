# Configure the Admin frontend as well as the basic service requirements (database, queue broker)
class apps::failmap::admin {
  $hostname = 'admin.faalkaart.nl'

  $db_name = 'failmap'
  $db_user = $db_name

  # database
  $random_seed = file('/var/lib/puppet/.random_seed')
  $db_password = fqdn_rand_string(32, '', "${random_seed}${db_user}")
  mysql::db { $db_name:
    user     => $db_user,
    password => $db_password,
    host     => 'localhost',
    grant    => ['SELECT', 'UPDATE', 'INSERT', 'DELETE'],
  }

  $secret_key = fqdn_rand_string(32, '', "${random_seed}secret_key")
  docker::image { 'registry.gitlab.com/failmap/admin':
    ensure    => latest,
    image_tag => latest,
  }
  docker::run { 'failmap-admin':
    image   => 'registry.gitlab.com/failmap/admin:latest',
    command => 'runuwsgi',
    volumes => [
      '/var/run/mysqld/mysqld.sock:/var/run/mysqld/mysqld.sock',
    ],
    env     => [
      'DB_ENGINE=mysql',
      'DB_HOST=/var/run/mysqld/mysqld.sock',
      "DB_NAME=${db_name}",
      "DB_USER=${db_user}",
      "DB_PASSWORD=${db_password}",
      "SECRET_KEY=${secret_key}",
      "ALLOWED_HOSTS=${hostname}",
    ]
  }

  sites::vhosts::proxy { $hostname:
    proxy => 'failmap-admin.docker:8000'
  }
}