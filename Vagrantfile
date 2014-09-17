# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
  'graylog2-node1' => [1,200],
  'graylog2-node2' => [1,201],
  'elasticsearch-node1' => [1,201],
  'elasticsearch-node2' => [1,202],
  'elasticsearch-node3' => [1,203],
  'elasticsearch-node4' => [1,204],
  'graylog2-radio-node1' => [1,205],
  'graylog2-radio-node2' => [1,206],
  'rabbitmq-node1' => [1,207],
  'rabbitmq-node2' => [1,208],
  'mongodb-node1' => [1,209],
  'mongodb-node2' => [1,210],
  'mongodb-node3' => [1,211],
  'graylog2-web' => [1,212],
  'haproxy-node1' => [1,213],
  'haproxy-node2' => [1,214],
}

Vagrant.configure("2") do |config|
  config.vm.box = "centos65"
  config.vm.box_url = "http://www.lyricalsoftware.com/downloads/centos65.box"
  # Forescount NAC workaround
  config.vm.usable_port_range = 2800..2900

  nodes.each do |prefix, (count, ip_start) |
    count.times do |i|
      hostname = "%s" % [prefix, (i+1)]
      config.vm.define "#{hostname}" do |box|
        box.vm.hostname = "#{hostname}.renanvicente.com"
        box.vm.network :private_network, ip:
          "172.16.0.#{ip_start+i}", :netmask =>
            "255.255.0.0"
        # Otherwise using VirtualBox
        box.vm.provision :puppet do |puppet|
          puppet.hiera_config_path = 'data/hiera.yaml'
          puppet.working_directory = '/vagrant/data'
          puppet.manifests_path = "manifests"
          puppet.module_path = "modules"
          puppet.manifest_file = "init.pp"
          puppet.options = [
           '--verbose',
           '--report',
           '--show_diff',
           '--pluginsync',
           '--summarize',
#          '--evaltrace',
#          #        '--debug',
#          #        '--parser future',
           ]
        end
        box.vm.provider :virtualbox do |vbox|
          # Defaults
          vbox.customize ["modifyvm", :id, "--memory", 1024]
          vbox.customize ["modifyvm", :id, "--cpus", 1]
        end
      end
    end
  end
end
