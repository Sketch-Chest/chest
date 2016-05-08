require 'spec_helper'
require 'fileutils'

describe Chest::CLI do
  before :each do
    @plugin_repo_name = 'Sketch-StickyGrid'
    @plugin_name = 'StickyGrid'
    @plugin_version = '1.0.0'
    @plugin_folder_path = Chest::PluginFolder::SKETCH_PLUGIN_FOLDER_PATH
    FileUtils.mkdir_p(@plugin_folder_path)

    @expected_plugin_path = File.join(@plugin_folder_path, @plugin_repo_name)
  end

  context 'install' do
    let(:output) { capture(:stdout) { subject.install('uetchy/Sketch-StickyGrid') } }

    it 'install plugin' do
      expect(output).to include("installed")
    end

    it 'find out plugin in Sketch plugin folder' do
      expect(Dir.exist?(@expected_plugin_path)).to be true
    end
  end

  context 'info' do
    let(:output) { capture(:stdout) { subject.info(@plugin_name) } }

    it 'return plugin info' do
      expect(output).to include(@plugin_name)
    end
  end

  context 'list' do
    let(:output) { capture(:stdout) { subject.list } }

    it 'returns a list' do
      expect(output).to include(@plugin_name)
    end
  end
end
