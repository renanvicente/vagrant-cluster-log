node 'linux-base' {

  if $::osfamily =~ /Debian|Ubuntu/ {
    stage { 'pre':
      before => Stage['main'],
    }
    class {'updatedebian':
      stage => 'pre',
    }
  }

  exec {'iptables -F':
    path => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin'],
  }

}

node 'graylog2-base' inherits linux-base {
  $packages = $::osfamily ? {
    /Debian|Ubuntu/ => ['vim','libaugeas-ruby','libaugeas-dev'],
    /RedHat|CentOS/ => ['vi'],
    default         => ['vi'],
  }

  package {$packages:
    ensure => installed,
    notify => Class['graylog2::repo'],
  }
}

node 'elasticsearch-base' inherits linux-base {

  $packages = $::osfamily ? {
    /Debian|Ubuntu/ => ['vim','libaugeas-ruby','libaugeas-dev'],
    /RedHat|CentOS/ => ['vi'],
    default         => ['vi'],
  }
  
  package {$packages:
    ensure  => installed,
    require => Class['elasticsearch'],
  }

}

node 'elasticsearch-node1' inherits elasticsearch-base {
  class { 'elasticsearch':
    config       => {
      'cluster.name'                         => 'graylog2',
      'script.disable_dynamic'               => true,
      'discovery.zen.ping.multicast.enabled' => true,
      'network.host'                         => '172.16.0.201',
    },
    version      => '0.90.10',
    manage_repo  => true,
    repo_version => '0.90',
    java_install => true,
  }
  elasticsearch::instance { 'es-01':
    config => { 'node.name' => 'node1' }
  }
  elasticsearch::plugin{'mobz/elasticsearch-head':
    module_dir => 'head',
    instances  => 'es-01'
  }
}

node 'elasticsearch-node2' inherits elasticsearch-base {
  class { 'elasticsearch':
    config       => {
      'cluster.name'                         => 'graylog2',
      'script.disable_dynamic'               => true,
      'discovery.zen.ping.multicast.enabled' => true,
      'network.host'                         => '172.16.0.202',
    },
    version      => '0.90.10',
    manage_repo  => true,
    repo_version => '0.90',
    java_install => true,
  }
  elasticsearch::instance { 'es-02':
    config => { 'node.name' => 'node2' }
  }
  elasticsearch::plugin{'mobz/elasticsearch-head':
    module_dir => 'head',
    instances  => 'es-02'
  }
}

node 'rabbitmq-node1' inherits linux-base {
  class {'::rabbitmq':
    delete_guest_user => true,
    admin_enable      => true,
  }
  
  rabbitmq_user { 'admin':
    admin    => true,
    password => 'admin',
    tags     => ['administrator'],
  }

  rabbitmq_user_permissions { 'admin@/':
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }

}

node 'graylog2-node1' inherits graylog2-base {

  class {'graylog2::repo':
      version => '0.20'
  }->
  class {'graylog2::server':
      password_secret            => 'fcZ62iGPR7a8WC7WhySGIhZdBtKCw4DxWQ2WuxgdyokZBJ7uyOZPpmsKMjP2l6lseYwOPUAvydcQsmgrsTr5yiIt9BQ729J1',
      root_password_sha2         => 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
      elasticsearch_shards       => 2,
      mongodb_host               => '172.16.0.209',
      rest_listen_uri            => 'http://172.16.0.200:12900/',
      rest_transport_uri         => 'http://172.16.0.200:12900/',
      elasticsearch_network_host => '172.16.0.200',
  }

}

node 'graylog2-web' inherits graylog2-base {

  class {'graylog2::repo':
      version => '0.20'
  }->
  class {'graylog2::web':
    application_secret   => 'fcZ62iGPR7a8WC7WhySGIhZdBtKCw4DxWQ2WuxgdyokZBJ7uyOZPpmsKMjP2l6lseYwOPUAvydcQsmgrsTr5yiIt9BQ729J1',
    graylog2_server_uris =>['http://172.16.0.200:12900/']
  }


}

node 'graylog2-radio-node1' inherits graylog2-base {

  class {'graylog2::repo':
      version => '0.20'
  }->
  class {'graylog2::radio':
    graylog2_server_uris =>['http://172.16.0.200:12900/'],
    rest_listen_uri      => 'http://172.16.0.205:12950/',
    rest_transport_uri   => 'http://172.16.0.205:12950/',
    amqp_broker_hostname => '172.16.0.207',
    amqp_broker_username => 'admin',
    amqp_broker_password => 'admin',
  }

}

node 'graylog2-radio-node2' inherits graylog2-base {

  class {'graylog2::repo':
      version => '0.20'
  }->
  class {'graylog2::radio':
    graylog2_server_uris =>['http://172.16.0.200:12900/'],
    rest_listen_uri      => 'http://172.16.0.206:12950/',
    rest_transport_uri   => 'http://172.16.0.206:12950/',
    amqp_broker_hostname => '172.16.0.207',
    amqp_broker_username => 'admin',
    amqp_broker_password => 'admin',
  }


}

node 'mongodb-node1' inherits linux-base {

  class {'::mongodb::globals':
    manage_package_repo => true,
  }->
  class {'::mongodb::server':
    bind_ip => ['0.0.0.0'],
  }->
  class {'::mongodb::client': }
}


class updatedebian {
  if $::osfamily =~ /Debian|Ubuntu/ {
    exec {'apt-get update':
      path => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
  }
}

