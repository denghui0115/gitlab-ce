#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
account_helper = AccountHelper.new(node)

user = account_helper.haproxy_user
group = account_helper.haproxy_group
haproxy_uid = node['gitlab']['haproxy']['uid']
haproxy_gid = node['gitlab']['haproxy']['gid']

working_dir = node['gitlab']['haproxy']['dir']
log_directory = node['gitlab']['haproxy']['log_directory']

account "Docker registry user and group" do
  username user
  uid haproxy_uid
  ugid group
  groupname group
  gid haproxy_gid
  shell '/bin/sh'
  home working_dir
  manage node['gitlab']['manage-accounts']['enable']
end

[
  working_dir,
  log_directory,
].each do |dir|
  directory dir do
    owner user
    group group
    mode '0700'
    recursive true
  end
end

template File.join(working_dir, "haproxy.cfg") do
  source "haproxy.cfg.erb"
  owner user
  group group
  variables(
    global: node['gitlab']['load-balancer-role']['global'],
    defaults: node['gitlab']['load-balancer-role']['defaults'],
    frontend: node['gitlab']['load-balancer-role']['frontend'],
    backend: node['gitlab']['load-balancer-role']['backend'],
    listen: node['gitlab']['load-balancer-role']['listen']
  )
  mode "0644"
  notifies :restart, "service[haproxy]"
end

runit_service 'haproxy' do
  down node['gitlab']['haproxy']['ha']
  options({
    :log_directory => log_directory
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['haproxy'].to_hash)
end

file File.join(working_dir, "VERSION") do
  content VersionHelper.version("/opt/gitlab/embedded/sbin/haproxy -v")
  notifies :restart, "service[haproxy]"
end
