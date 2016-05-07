require 'spec_helper'

describe Chest::Registry do
  before :all do
    @endpoint = 'http://sketchchest.com/api'
    @token = 'dummytoken'
    @plugin = {
      name: 'StickyGrid',
      version: '1.0.0',
      license: 'MIT License'
    }

    stub_request(:get, URI.join(@endpoint, "packages/#{@plugin[:name]}.json"))
      .with(query: { token: @token })
      .to_return(body: @plugin.to_json)

    stub_request(:post, URI.join(@endpoint, '/packages.json'))
      .with(query: { token: @token })
      .to_return(body: @plugin.to_json)

    @registry = Chest::Registry.new(@token, endpoint: @endpoint)
  end

  it 'can fetch plugin information' do
    result = @registry.fetch_package(@plugin[:name])

    expect(result).to be_a_kind_of Hash
    expect(result['name']).to eq @plugin[:name]
    expect(result['version']).to eq @plugin[:version]
    expect(result['license']).to eq @plugin[:license]
  end

  it 'can publish package' do
    old_version = @registry.publish_package('spec/fixtures/Sketch-StickyGrid-0.1')
    expect(old_version).not_to have_key 'error'
    new_version = @registry.publish_package('spec/fixtures/Sketch-StickyGrid-1.0')
    expect(new_version).not_to have_key 'error'

    new_plugin = @registry.publish_package('spec/fixtures/New-Plugin-1.0')
    expect(new_plugin).not_to have_key 'error'
  end
  #
  # it 'cannot publish old package' do
  #   status = @registry.publish_package('spec/fixtures/Sketch-StickyGrid-0.1')
  #   pp status
  #   expect(status).to have_key 'error'
  # end
  #
  # it 'cannot publish a package that have same version of latest package' do
  #   status = @registry.publish_package('spec/fixtures/Sketch-StickyGrid-1.0')
  #   pp status
  #   expect(status).to have_key 'error'
  # end

  # it 'can fetch versions index' do
  #   name = 'StickyGrid'
  #   info = @registry.fetch_package_versions(name)
  #
  #   expect(info).to be_a_kind_of Hash
  #   expect(info).to have_key 'versions'
  #   expect(info['versions']).to be_a_kind_of Array
  #   expect(info['versions'].size).to eq 2
  # end
  #
  # it 'can download package' do
  #   name = 'StickyGrid'
  #   Dir.mktmpdir do |tmpdir|
  #     @registry.download_package(name, 'latest', tmpdir)
  #     expect(File.exist?(File.join(tmpdir, 'chest.json'))).to eq(true)
  #     expect(JSON.parse(File.open(File.join(tmpdir, 'chest.json')).read)['version']).to eq('1.0.0')
  #   end
  # end
  #
  # it 'can download old package' do
  #   name = 'StickyGrid'
  #   Dir.mktmpdir do |tmpdir|
  #     @registry.download_package(name, '0.1.0', tmpdir)
  #     expect(File.exist?(File.join(tmpdir, 'chest.json'))).to eq(true)
  #     expect(JSON.parse(File.open(File.join(tmpdir, 'chest.json')).read)['version']).to eq('0.1.0')
  #   end
  # end
  #
  # it 'will ignore files specified in .gitignore' do
  #   name = 'New-Plugin'
  #   Dir.mktmpdir do |tmpdir|
  #     @registry.download_package(name, 'latest', tmpdir)
  #     expect(Dir.exist?(File.join(tmpdir, 'assets'))).not_to eq true
  #   end
  # end
  #
  # it 'can unpublish plugin' do
  #   status = @registry.unpublish_package('StickyGrid')
  #   expect(status).to have_key 'status'
  #   status = @registry.unpublish_package('New-Plugin')
  #   expect(status).to have_key 'status'
  # end
end
