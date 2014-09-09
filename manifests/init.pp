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

node 'rabbitmq-node1' {
include '::rabbitmq'

rabbitmq_user { 'admin':
  admin    => true,
  password => 'admin',
  tags     => ['administrator'],
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

  #class {'graylog2::web':
  #application_secret => 'fcZ62iGPR7a8WC7WhySGIhZdBtKCw4DxWQ2WuxgdyokZBJ7uyOZPpmsKMjP2l6lseYwOPUAvydcQsmgrsTr5yiIt9BQ729J1',
  #}
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

node 'dns-master-puppet' {

  class {'epel': }
  class { '::bind': chroot => true }
  bind::server::conf { '/etc/named.conf':
    listen_on_addr    => [ 'any' ],
    #listen_on_v6_addr => [ 'any' ],
    #forwarders        => [ '8.8.8.8', '8.8.4.4' ],
    allow_query       => [ 'localhost','172.16.0.0/16','192.168.2.0/24' ],
    zones             => {
      '5inova.com' => [
        'type master',
        'file "5inova.com.zone"',
      ],
    },
  }
  bind::server::file { '5inova.com.zone':
    source => 'puppet:///modules/bind/5inova.com.zone',
  }

  firewall { '000 accept all icmp':
    proto   => 'icmp',
    action  => 'accept',
  }->
  firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }->
  firewall { '002 accept dns transfer':
    proto  => 'tcp',
    port   => 53,
  }->
  firewall { '003 accpt dns query':
    proto  => 'udp',
    port  => 53,
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

