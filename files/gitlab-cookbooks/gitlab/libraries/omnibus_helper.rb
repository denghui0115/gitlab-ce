require 'mixlib/shellout'
require_relative 'helper'

class OmnibusHelper
  include ShellOutHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def should_notify?(service_name)
    File.symlink?("/opt/gitlab/service/#{service_name}") && service_up?(service_name) && service_enabled?(service_name)
  end

  def not_listening?(service_name)
    File.exists?("/opt/gitlab/service/#{service_name}/down") && service_down?(service_name)
  end

  def service_enabled?(service_name)
    # Check if service is explicitly disabled in the node.
    # This method doesn't apply if node argument is given and hence defaults
    # to true for preventing abrupt exit.
    node ? node['gitlab'][service_name]['enable'] : true
  end

  def service_up?(service_name)
    success?("/opt/gitlab/embedded/bin/sv status #{service_name}")
  end

  def service_down?(service_name)
    failure?("/opt/gitlab/embedded/bin/sv status #{service_name}")
  end

  def user_exists?(username)
    success?("id -u #{username}")
  end
end
