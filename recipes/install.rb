#
# Cookbook Name:: metrictank
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

node.set['metrictank']['instance'] = node['hostname']

packagecloud_repo node[:metrictank][:packagecloud_repo] do
  type "deb"
end

pkg_version = node['metrictank']['version']
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

directory "/etc/raintank" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

directory node['metrictank']['proftrigger']['path'] do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

kafkas = if Chef::Config[:solo]
    node['metrictank']['kafkas']
  else
    search("node", node['metrictank']['kafka_search']).map { |c| c.fqdn }.sort || node['metrictank']['kafkas']
  end
kafka_brokers = kafkas.map { |k| "#{k}:#{node['metrictank']['kafka']['kafka_port']}" }.join(",")
node['metrictank']['kafka_mdm_in_brokers'] = kafka_brokers
node['metrictank']['kafka_mdam_in_brokers'] = kafka_brokers
node['metrictank']['kafka_cluster_brokers'] = kafka_brokers


template "/etc/raintank/metrictank.ini" do
  source "metrictank.ini.erb"
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

tag("metric_tank")
tag("metrictank")
