require 'json'
require 'fileutils'
require 'ostruct'

module Chest
  PLUGINS_FOLDER = File.expand_path('~/Library/Containers/com.bohemiancoding.sketch3/Data/Library/Application Support/com.bohemiancoding.sketch3/Plugins')
  MANIFEST_PATH = File.join(PLUGINS_FOLDER, 'plugins.json')

  class Manifest
    attr_reader :manifest

    def initialize(path)
      @path = path
      @manifest = load_manifest
    end

    def get_plugin_option(name)
      unless @manifest[name.to_s]
        return {}
      end
      Chest::Plugin.parse_option_string(@manifest[name.to_s]).last
    end

    def add_plugin(name, args)
      @manifest[name.to_s] = args
    end

    def remove_plugin(name)
      @manifest.delete name.to_s
    end

    def save
      write_manifest
    end

    private
    def load_manifest
      File.exist?(@path) ? JSON.parse(File.open(@path).read) : {}
    end

    def write_manifest
      File.open(@path, 'w').write(JSON.pretty_generate(@manifest))
    end
  end

  class Plugin
    attr_reader :name, :options

    class InvalidArgumentError < StandardError; end

    def initialize(name, options=nil)
      @name = name
      @options = OpenStruct.new(options ? options : Manifest.new(MANIFEST_PATH).get_plugin_option(name))
    end

    def path
      File.join(PLUGINS_FOLDER, @name)
    end

    def type
      @options.type
    end

    def install
      fetch_method = "fetch_#{type}"
      if respond_to?(fetch_method, true) && self.send(fetch_method)
        manifest = Manifest.new(MANIFEST_PATH)
        manifest.add_plugin(@name, generate_option_string)
        manifest.save
      else
        raise "Unknown strategy type: #{type}"
      end
    end

    def uninstall
      if Dir.exist?(path) && FileUtils.rm_r(path)
        manifest = Manifest.new(MANIFEST_PATH)
        manifest.remove_plugin(@name)
        manifest.save
      else
        raise "#{@name} doesn't exist"
      end
    end

    def updatable?
      type != :local
    end

    def update
      fetch_method = "update_#{type}"
      if respond_to?(fetch_method, true) && self.send(fetch_method)
        manifest = Manifest.new(MANIFEST_PATH)
        manifest.add_plugin(@name, generate_option_string)
        manifest.save
      else
        raise "Unknown strategy type: #{type}"
      end
    end

    class << self
      def create_from_query(query, alias_name=nil)
        name, options = parse_option_string(query)
        new(alias_name || name, options)
      end

      def all
        manifest = Manifest.new(MANIFEST_PATH)
        manifest.manifest.map{|k,v| new(k, parse_option_string(v).last)}
      end

      def parse_option_string(query)
        if query =~ /\.git$/
          [
            File.basename(query, '.*'),
            {
              type: :git,
              url: query
            }
          ]
        elsif query =~ /\A([a-zA-Z0-9_\-]+)\/([a-zA-Z0-9_\-]+)\z/
          [
            $2,
            {
              type: :git,
              url: "https://github.com/#{$1}/#{$2}.git"
            }
          ]
        elsif query =~ /\A([a-zA-Z0-9_\-]+)(?:#([a-zA-Z0-9\-\.]+))?\z/
          [
            $1,
            {
              type: :chest,
              version: $2
            }
          ]
        else
          raise InvalidArgumentError, "Specify valid query: #{query}"
        end
      end
    end

    private

    def generate_option_string
      case type
      when :chest
        @options.version
      when :git
        @options.url
      when :direct
        @options.url
      else
        ''
      end
    end

    def fetch_chest
      conn = Chest::Connector.new
      conn.download_package(@name, 'latest', path)
      # TODO
    end

    def update_chest
      # TODO
    end

    def fetch_git
      if system "git clone '#{@options.url}' '#{path}'"
        true
      else
        raise "Failed to install #{@options.url}"
      end
    end

    def update_git
      if system "cd '#{path}' && git pull"
        true
      else
        raise "Failed to update #{@name}"
      end
    end

    def fetch_direct
      system "curl -L '#{@options.url}' -o '#{path}'"
    end

    def update_direct
      system "curl -L '#{@options.url}' -o '#{path}'"
    end
  end
end
