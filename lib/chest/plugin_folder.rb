require 'fileutils'

module Chest
  class PluginFolder
    SKETCH_PLUGIN_FOLDER_PATH = File.expand_path('~/Library/Application Support/com.bohemiancoding.sketch3/Plugins/').freeze
    SKETCH_APPSTORE_PLUGIN_FOLDER_PATH = File.expand_path('~/Library/Containers/com.bohemiancoding.sketch3/Data/Library/Application Support/com.bohemiancoding.sketch3/Plugins/').freeze

    class InvalidArgumentError < StandardError; end

    def initialize
      @registry = Chest::Registry.new
    end

    def manifest_for(plugin_path)
      manifest_path = Dir.glob(File.join(plugin_path, '*.sketchplugin/Contents/Sketch/manifest.json')).first
      JSON.parse(File.open(manifest_path).read)
    end

    def path_for(name, include_manifest = false)
      exact_plugin_path = File.join(SKETCH_PLUGIN_FOLDER_PATH, name)
      return exact_plugin_path unless include_manifest
      plugins.each do |plugin_path|
        if manifest_for(plugin_path)['name'] == name || File.identical?(plugin_path, exact_plugin_path)
          return plugin_path
        end
      end

      nil
    end

    def plugins
      Dir.glob(File.join(SKETCH_PLUGIN_FOLDER_PATH, '*/'))
    end

    def install(source_path, plugin_name)
      destination_path = path_for(plugin_name)
      raise "#{plugin_name} already installed" if Dir.exist? destination_path
      FileUtils.cp_r(source_path, destination_path)
    end

    def uninstall(plugin_path)
      if Dir.exist? plugin_path
        FileUtils.rm_rf(plugin_path)
        return plugin_path
      else
        raise "#{plugin_path} doesn't exist"
      end
    end

    def update
      fetch_method = "update_#{type}"
      if respond_to?(fetch_method, true)
        begin
          send(fetch_method)
        rescue => e
          raise "#{@name}: #{e}"
        else
          manifest = Manifest.new
          manifest.add_plugin(@name, to_option)
          manifest.save
        end
      else
        raise "Unknown strategy type: #{type}"
      end
    end
  end
end
