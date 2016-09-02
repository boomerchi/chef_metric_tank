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
  variables({
    :instance => node['chef_metric_tank']['instance'],
    :accounting_period => node['chef_metric_tank']['accounting_period'],
    :primary_node => node['chef_metric_tank']['primary_node'],
    :warm_up_period => node['chef_metric_tank']['warm_up_period'],
    :listen => node['chef_metric_tank']['listen'],
    :ttl => node['chef_metric_tank']['ttl'],
    :chunkspan => node['chef_metric_tank']['chunkspan'],
    :numchunks => node['chef_metric_tank']['numchunks'], 
    :cassandras => cassandra_addrs.join(','),
    :cassandra_write_concurrency => node['chef_metric_tank']['cassandra_write_concurrency'],
    :cassandra_write_queue_size => node['chef_metric_tank']['cassandra_write_queue_size'],
    :cassandra_read_concurrency => node['chef_metric_tank']['cassandra_read_concurrency'],
    :cassandra_read_queue_size => node['chef_metric_tank']['cassandra_read_queue_size'],
    :cassandra_consistency => node['chef_metric_tank']['cassandra_consistency'],
    :cassandra_timeout => node['chef_metric_tank']['cassandra_timeout'],
    :cassandra_keyspace => node['chef_metric_tank']['cassandra_keyspace'],
    :nsqds => nsqd_addrs.join(','),
    :log_min_dur => node['chef_metric_tank']['log_min_dur'],
    :log_level => node['chef_metric_tank']['log_level'],
    :gc_interval => node['chef_metric_tank']['gc_interval'],
    :chunk_max_stale => node['chef_metric_tank']['chunk_max_stale'],
    :metric_max_stale => node['chef_metric_tank']['metric_max_stale'],
    :statsd_addr => node['chef_metric_tank']['statsd_addr'],
    :statsd_type => node['chef_metric_tank']['statsd_type'],
    :agg_settings => node['chef_metric_tank']['agg_settings'],
    :proftrigger_heap => node['chef_metric_tank']['proftrigger']['heap_thresh'],
    :proftrigger_freq => node['chef_metric_tank']['proftrigger']['freq'],
    :proftrigger_path => node['chef_metric_tank']['proftrigger']['path'],
    :proftrigger_min_diff => node['chef_metric_tank']['proftrigger']['min_diff'],
    :block_profile_rate => node['chef_metric_tank']['block_profile_rate'],
    :mem_profile_rate => node['chef_metric_tank']['mem_profile_rate'],
    :kafka_topics => node['chef_metric_tank']['kafka']['topics'],
    :kafka_brokers => kafka_brokers,
    :kafka_group => node['chef_metric_tank']['kafka']['group'],
    :nsq_in_enabled => node['chef_metric_tank']['nsq_in']['enabled'].to_s,
    :nsq_cluster_enabled => node['chef_metric_tank']['nsq_cluster']['enabled'],
    :carbon_in_enabled => node['chef_metric_tank']['carbon_in']['enabled'],
    :kafka_mdm_in_enabled => node['chef_metric_tank']['kafka_mdm_in']['enabled'],
    :kafka_mdam_in_enabled => node['chef_metric_tank']['kafka_mdam_in']['enabled'],
    :kafka_cluster_enabled => node['chef_metric_tank']['kafka_cluster']['enabled'],
    :kafka_cluster_topic => node['chef_metric_tank']['kafka_cluster']['topic'],
    :es_index_enabled => node['chef_metric_tank']['elasticsearch_idx']['enabled'],
    :es_hosts => elasticsearch_host,
    :es_index =>  node['chef_metric_tank']['elasticsearch_idx']['index'],
    :es_retry_interval => node['chef_metric_tank']['elasticsearch_idx']['retry_interval'],
    :es_max_buffer_docs => node['chef_metric_tank']['elasticsearch_idx']['max_buffer_docs'],
    :es_max_conns => node['chef_metric_tank']['elasticsearch_idx']['max_conns'],
    :buffer_delay_max => node['chef_metric_tank']['elasticsearch_idx']['buffer_delay_max'],
    :cassandra_index_enabled => node['chef_metric_tank']['cassandra_idx']['enabled']
    :cassandra_idx_num_conns => node['chef_metric_tank']['cassandra_idx']['num_conns'],
    :cassandra_idx_write_queue => node['chef_metric_tank']['cassandra_idx']['write_queue_size']
  })
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
