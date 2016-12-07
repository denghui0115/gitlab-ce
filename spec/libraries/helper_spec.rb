require 'chef_helper'

describe PgHelper do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['gitlab']['postgresql']['data_dir'] = '/fakedir'
      node.set['package']['install-dir'] = '/fake/install/dir'
    end.converge('gitlab::default')
  end
  let(:node) { chef_run.node }

  before do
    allow(VersionHelper).to receive(:version).with(
      '/opt/gitlab/embedded/bin/psql --version'
    ).and_return('YYYYYYYY XXXXXXX')
    @helper = PgHelper.new(node)
  end

  it 'returns a valid version' do
    expect(@helper.version).to eq('XXXXXXX')
  end

  it 'returns a valid database_version' do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(
      '/fakedir/PG_VERSION'
    ).and_return(true)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(
      '/fakedir/PG_VERSION'
    ).and_return('111.222')
    allow(Dir).to receive(:glob).with(
      '/fake/install/dir/embedded/postgresql/*'
    ).and_return(['111.222.18', '222.333.11'])
    # We mock this in chef_helper.rb. Overide the mock to call the original
    allow_any_instance_of(PgHelper).to receive(:database_version).and_call_original
    expect(@helper.database_version).to eq('111.222')
  end
end

describe OmnibusHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'check if service is enabled' do
    it 'returns true for enabled services' do
      expect(OmnibusHelper.service_enabled?(chef_run.node, "unicorn")).to eq(true)
      expect(chef_run).to create_link("/opt/gitlab/service/unicorn").with(to: "/opt/gitlab/sv/unicorn")
    end
  end

  context 'check if service is disabled' do
    before do
      stub_gitlab_rb(unicorn: {enable: false})
    end
    it 'returns false for disabled services' do
      expect(OmnibusHelper.service_enabled?(chef_run.node, "unicorn")).to eq(false)
      expect(chef_run).not_to create_link("/opt/gitlab/service/unicorn").with(to: "/opt/gitlab/sv/unicorn")
    end
  end
end
