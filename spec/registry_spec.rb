require 'spec_helper'

describe Chest::Registry do
  before :all do
    token = 'B9Tznck6iDSfpyu9dKd3hw'
    @registry = Chest::Registry.new(token, api: 'http://localhost:3000/api')
  end

  it 'can publish package' do
    status = @registry.publish_package('spec/fixtures/Sketch-StickyGrid')
    expect(status).to be_a_kind_of Hash
  end

  it 'can fetch package information' do
    name = 'StickyGrid'
    info = @registry.fetch_package(name)

    expect(info).to be_a_kind_of Hash
    expect(info).to have_key 'name'
    expect(info['name']).to eq name
  end

  it 'can download package' do
    name = 'StickyGrid'
    Dir.mktmpdir do |tmpdir|
      @registry.download_package(name, 'latest', tmpdir)
      expect(File.exist?(File.join(tmpdir, 'chest.json'))).to eq(true)
    end
  end

  # it 'can unpublish plugin' do
  #   status = @registry.unpublish_package('StickyGrid')
  #   pp status

  #   expect(status).to be_a_kind_of Hash
  # end
end
