require 'spec_helper'

describe Chest::PluginFolder do
  before :each do
    @endpoint = 'http://sketchchest.com/api/'
    @token = 'dummytoken'
    @plugin = {
      name: 'StickyGrid',
      version: '1.0.0',
      license: 'MIT License',
      git_url: 'https://github.com/uetchy/Sketch-StickyGrid.git'
    }
  end

  it 'can install package'
  # do
  #   plugin_names = [
  #     'StickyGrid', # index
  #     'uetchy/Sketch-StickyGrid', # github
  #     'https://github.com/uetchy/Sketch-StickyGrid.git' #git
  #   ]
  #   plugin_names.each do |plugin_name|
  #     Dir.mktmpdir do |tmpdir|
  #       @registry.install_package(plugin_name, tmpdir)
  #       expect(File.exist?(File.join(tmpdir, '*.sketchplugin/Contents/Sketch/manifest.json'))).to eq(true)
  #       # expect(JSON.parse(File.open(File.join(tmpdir, 'chest.json')).read)['version']).to eq('1.0.0')
  #     end
  #   end
  # end
end
