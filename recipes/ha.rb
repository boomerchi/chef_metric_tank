#
# Cookbook Name:: chef_metric_tank
# Recipe:: ha
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

node.set['chef_metric_tank']['instance'] = node['hostname']

# zone format:  projects/417965514133/zones/us-central1-a.
# we split to us-central1-a, then split that to get just "a"
if node.attribute?('gce')
  gce_zone = node['gce']['instance']['zone'].split('/')[3].split("-")[2]
  node.set['chef_metric_tank']['channel'] = "tank#{gce_zone}"
else
  node.name =~ /(\d+)/
  num = $1 || "1"
  node.set['chef_metric_tank'']['channel'] = "tank#{num}"
end

tag("metric_tank")

logrotate_app "metric_tank-upstart" do
  path "/var/log/upstart/metric_tank.log"
  frequency "hourly"
  create "644 root root"
  rotate 6
  options %w(missingok compress copytruncate notifempty)
  enable true
end
cron "metric_tank-upstart-logrotate" do
  time :hourly
  command "/usr/sbin/logrotate /etc/logrotate.d/metric_tank-upstart"
end
