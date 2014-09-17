node 'elasticsearch-base' {

  stage { 'pre':
   before => Stage['main'],
  }

  class {'update-debian':
    stage => 'pre',
  }

  $packages = ['vim','libaugeas-ruby','libaugeas-dev']

  package {$packages:
    ensure => installed,
    require => Class['elasticsearch'],
  }


}

node 'elasticsearch-node1' inherits elasticsearch-base {
 
   class { 'elasticsearch':
    config => {
      'cluster.name' => 'graylog2',
      'script.disable_dynamic' => true,
      'discovery.zen.ping.multicast.enabled' => true,
      'network.host' => '172.16.0.201',
    },
    version => '0.90.10',
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
    config => {
      'cluster.name' => 'graylog2',
      'script.disable_dynamic' => true,
      'discovery.zen.ping.multicast.enabled' => true,
      'network.host' => '172.16.0.202',
    },
    version => '0.90.10',
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

node 'rabbitmq-node1','rabbitmq-node2' {
  class {'::rabbitmq':
    delete_guest_user => true,
    admin_enable      => true,
    config_kernel_variables  => {
      'inet_dist_listen_min' => 9100,
      'inet_dist_listen_max' => 9105,
      },
    config_variables => {
      collect_statistics_interval => 10000,
      heartbeat => 30,
      },
    config_cluster    => true,
    cluster_nodes     => ['rabbitmq-node1', 'rabbitmq-node2'],
    cluster_node_type => 'disc',
    wipe_db_on_cookie_change => true,
    require => Host['rabbitmq-node1.renanvicente.com','rabbitmq-node2.renanvicente.com','localhost.localdomain'],
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
  rabbitmq_plugin {'rabbitmq_shovel':
    ensure => present,
  }
  rabbitmq_plugin {'rabbitmq_shovel_management':
    ensure => present,
  }

  host {'rabbitmq-node1.renanvicente.com':
    ip => '172.16.0.207',
    host_aliases => 'rabbitmq-node1',
  }
  host {'rabbitmq-node2.renanvicente.com':
    ip => '172.16.0.208',
    host_aliases => 'rabbitmq-node2',
  }
  host {'localhost.localdomain':
    ip => '127.0.0.1',
    host_aliases => 'localhost',
  }


}

node 'graylog2-node1' {

  stage { 'pre':
   before => Stage['main'],
  }

  class {'update-debian':
    stage => 'pre',
  }

  $packages = ['vim','libaugeas-ruby','libaugeas-dev']

  package {$packages:
    ensure => installed,
    notify => Class['graylog2::server'],
  }

  class {'graylog2::repo':
      version => '0.20'
  }->
  class {'graylog2::server':
      password_secret    => 'fcZ62iGPR7a8WC7WhySGIhZdBtKCw4DxWQ2WuxgdyokZBJ7uyOZPpmsKMjP2l6lseYwOPUAvydcQsmgrsTr5yiIt9BQ729J1',
      root_password_sha2 => 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
      elasticsearch_shards => 2,
      mongodb_host         => '172.16.0.209',
      rest_listen_uri      => 'http://172.16.0.200:12900/',
      rest_transport_uri   => 'http://172.16.0.200:12900/',
      elasticsearch_network_host => '172.16.0.200',
  }

}

node 'graylog2-web' {

  stage { 'pre':
   before => Stage['main'],
  }

  class {'update-debian':
    stage => 'pre',
  }

  $packages = ['vim','libaugeas-ruby','libaugeas-dev']

  package {$packages:
    ensure => installed,
    notify => Class['graylog2::repo'],
  }
  class {'graylog2::repo':
      version => '0.20'
  }->
  class {'graylog2::web':
    application_secret => 'fcZ62iGPR7a8WC7WhySGIhZdBtKCw4DxWQ2WuxgdyokZBJ7uyOZPpmsKMjP2l6lseYwOPUAvydcQsmgrsTr5yiIt9BQ729J1',
    graylog2_server_uris =>['http://172.16.0.200:12900/']
  }


}

node 'graylog2-radio-node1' {

  #  stage { 'pre':
  # before => Stage['main'],
  #}

  #class {'update-debian':
  #  stage => 'pre',
  #}

  #$packages = ['vim','libaugeas-ruby','libaugeas-dev']

  #package {$packages:
  #  ensure => installed,
  #  notify => Class['graylog2::repo'],
  #}
  class {'graylog2::repo':
      version => '0.20'
  }->
  class {'graylog2::radio':
    graylog2_server_uris =>['http://172.16.0.200:12900/'],
    rest_listen_uri => 'http://172.16.0.205:12950/',
    rest_transport_uri => 'http://172.16.0.205:12950/',
    amqp_broker_hostname => '172.16.0.207',
    amqp_broker_username => 'admin',
    amqp_broker_password => 'admin',
  }

}

node 'graylog2-radio-node2' {

#  stage { 'pre':
#   before => Stage['main'],
#  }

#  class {'update-debian':
#    stage => 'pre',
#  }

#  $packages = ['vim','libaugeas-ruby','libaugeas-dev']

#  package {$packages:
#    ensure => installed,
#    notify => Class['graylog2::repo'],
#  }
  class {'graylog2::repo':
      version => '0.20'
  }
   class {'graylog2::radio':
    graylog2_server_uris =>['http://172.16.0.200:12900/'],
    rest_listen_uri => 'http://172.16.0.206:12950/',
    rest_transport_uri => 'http://172.16.0.206:12950/',
    amqp_broker_hostname => '172.16.0.207',
    amqp_broker_username => 'admin',
    amqp_broker_password => 'admin',
  }

  exec {'iptables -F':
    path => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin'],
  }

}

node 'mongodb-node1' {

 stage { 'pre':
  before => Stage['main'],
 }

class {'update-debian':
  stage => 'pre',
}
  
 class {'::mongodb::globals':
   manage_package_repo => true,
 }->
 class {'::mongodb::server':
   bind_ip => ['0.0.0.0'],
 }->
 class {'::mongodb::client':
 }
  
}


class update-debian {
  if $::osfamily =~ /Debian|Ubuntu/ {
    exec {'apt-get update':
      path => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
  }
}

node 'haproxy-node1','haproxy-node2' {

  class { 'haproxy': }
  haproxy::frontend { 'rabbitmq00':
    ipaddress        => '172.16.0.213',
    ports            => '5672',
    mode             => 'tcp',
    options => { 
    'option' => 'tcplog',
    'default_backend'  => 'rabbitmq_backend00',
    }
  }
  haproxy::backend {'rabbitmq_backend00':
    collect_exported => false,
    options => {
      'balance' => 'roundrobin',
    },
  }
  haproxy::balancermember {'rabbitmq-node1':
    listening_service => 'rabbitmq_backend00',
    server_names      => 'rabbitmq-node1.renanvicente.com',
    ipaddresses       => '172.16.0.207',
    ports             => '5672',
    options           => 'check',
  }
  haproxy::balancermember {'rabbitmq-node2':
    listening_service => 'rabbitmq_backend00',
    server_names      => 'rabbitmq-node2.renanvicente.com',
    ipaddresses       => '172.16.0.208',
    ports             => '5672',
    options           => 'check',
  }
  haproxy::listen { 'stats':
    collect_exported  => false,
    ports             => '1936',
    ipaddress         => '172.16.0.213',
    mode              => 'http',
    options           => {
      'stats'         => ['enable','hide-version','realm Haproxy\ Statistics','uri /stats','auth renan:renan'],
    },
  }
  class { 'corosync':
    enable_secauth    => true,
    authkey           => '/vagrant/authkey',
    bind_address      => '0.0.0.0',
    multicast_address => '239.1.1.2',
  }
  corosync::service { 'pacemaker':
    version => '0',
  }
  cs_primitive { 'haproxy_vip':
    primitive_class => 'ocf',
    primitive_type  => 'IPaddr2',
    provided_by     => 'heartbeat',
    parameters      => { 'ip' => '172.16.0.190', 'cidr_netmask' => '24' },
    operations      => { 'monitor' => { 'interval' => '10s' } },
  }
  cs_primitive { 'haproxy_service':
    primitive_class => 'lsb',
    primitive_type  => 'haproxy',
    provided_by     => 'heartbeat',
    operations      => {
      'monitor' => { 'interval' => '10s', 'timeout' => '30s' },
      'start'   => { 'interval' => '0', 'timeout' => '30s', 'on-fail' => 'restart' }
    },
    require         => Cs_primitive['haproxy_vip'],
  }
    cs_location { 'haproxy_service_location':
    primitive => 'haproxy_service',
    node_name => 'hostname',
    score     => 'INFINITY',
  }
  cs_colocation { 'vip_with_service':
    primitives => [ 'haproxy_vip', 'haproxy_service' ],
  }
  cs_order { 'vip_before_service':
    first   => 'haproxy_vip',
    second  => 'haproxy_service',
    require => Cs_colocation['vip_with_service'],
  }


}
