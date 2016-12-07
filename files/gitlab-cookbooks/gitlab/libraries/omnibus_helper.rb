require 'mixlib/shellout'
require_relative 'helper'

class OmnibusHelper
  extend ShellOutHelper

  def self.should_notify?(node=nil, service_name)
    File.symlink?("/opt/gitlab/service/#{service_name}") && service_up?(service_name) && service_enabled?(node, service_name)
  end

  def self.not_listening?(service_name)
    File.exists?("/opt/gitlab/service/#{service_name}/down") && service_down?(service_name)
  end

  def self.service_enabled?(node, service_name)
    # Check if service is explicitly disabled in the node.
    # This method doesn't apply if node argument is given and hence defaults
    # to true for preventing abrupt exit.
    node ? node['gitlab'][service_name]['enable'] : true
  end

  def self.service_up?(service_name)
    success?("/opt/gitlab/embedded/bin/sv status #{service_name}")
  end

  def self.service_down?(service_name)
    failure?("/opt/gitlab/embedded/bin/sv status #{service_name}")
  end

  def self.user_exists?(username)
    success?("id -u #{username}")
  end
end
