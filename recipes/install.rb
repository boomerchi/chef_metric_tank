#
# Cookbook Name:: chef_metric_tank
# Recipe:: install
#
# Copyright (C) 2016 Raintank, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Chef::Recipe.send(:include, ::RaintankBase::Helpers)
Chef::Resource.send(:include, ::RaintankBase::Helpers)
Chef::Provider.send(:include, ::RaintankBase::Helpers)

node.set['chef_metric_tank']['instance'] = node['hostname']

# zone format:  projects/417965514133/zones/us-central1-a.
# we split to us-central1-a, then split that to get just "a"
node.name =~ /(\d+)/
num = $1 || "1"
if node.attribute?('gce')
  gce_zone = node['gce']['instance']['zone'].split('/')[3].split("-")[2]
  node.set['chef_metric_tank']['channel'] = "tank#{num}#{gce_zone}"
else
  node.set['chef_metric_tank']['channel'] = "tank#{num}"
end

packagecloud_repo node[:chef_metric_tank][:packagecloud_repo] do
  type "deb"
end

pkg_version = node['chef_metric_tank']['version']
pkg_action = if pkg_version.nil?
  :upgrade
else
  :install
end

package "metrictank" do
  version pkg_version
  action pkg_action
  options "-o Dpkg::Options::='--force-confnew'"
end

service "metrictank" do
  case node["platform"]
  when "ubuntu"
    if node["platform_version"].to_f >= 15.10
      provider Chef::Provider::Service::Systemd
    elsif node["platform_version"].to_f >= 9.10
      provider Chef::Provider::Service::Upstart
    end
  end
  action [ :enable, :start ]
end

nsqd_addrs = find_nsqd || node['chef_metric_tank']['nsqd_addr']
cassandra_addrs = find_cassandras
elasticsearch_host = find_haproxy || ""

elasticsearch_host = if elasticsearch_host == ""
  node['chef_metric_tank']['elasticsearch_idx']['hosts']
else
  elasticsearch_host + ":9200"
end

directory "/etc/raintank" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

directory node['chef_metric_tank']['proftrigger']['path'] do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

kafkas = if Chef::Config[:solo]
    node['chef_metric_tank']['kafkas']
  else
    search("node", node['chef_metric_tank']['kafka_search']).map { |c| c.fqdn }.sort || node['chef_metric_tank']['kafkas']
  end
kafka_brokers = kafkas.map { |k| "#{k}:#{node['chef_metric_tank']['kafka']['kafka_port']}" }.join(",")


template "/etc/raintank/metrictank.ini" do
  source "metrictank.ini.erb"
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

tag("metric_tank")
tag("metrictank")

#logrotate_app "metric_tank-upstart" do
#  path "/var/log/upstart/metric_tank.log"
#  frequency "hourly"
#  create "644 root root"
#  rotate 6
#  options %w(missingok compress copytruncate notifempty)
#  enable true
#end
#cron "metric_tank-upstart-logrotate" do
#  time :hourly
#  command "/usr/sbin/logrotate /etc/logrotate.d/metric_tank-upstart"
#end
