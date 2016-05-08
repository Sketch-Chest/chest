require 'spec_helper'

describe Chest::Registry do
  before :each do
    @endpoint = 'http://sketchchest.com/api/'
    @token = 'dummytoken'
    @plugin = {
      name: 'StickyGrid',
      version: '1.0.0',
      license: 'MIT License',
      git_url: 'https://github.com/uetchy/Sketch-StickyGrid.git'
    }

    stub_request(:any, URI.join(@endpoint, "packages/#{@plugin[:name]}.json"))
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

  it 'can normalize query to git URL' do
    plugin_names = [
      'StickyGrid', # index
      'uetchy/Sketch-StickyGrid', # github
      'https://github.com/uetchy/Sketch-StickyGrid.git' #git
    ]
    plugin_names.each do |plugin_name|
      result = @registry.normalize_to_git_url(plugin_name)
      expect(result).to eq 'https://github.com/uetchy/Sketch-StickyGrid.git'
    end
  end
end
