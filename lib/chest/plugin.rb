require 'json'
require 'fileutils'
require 'ostruct'

module Chest
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
        manifest.add_plugin(@name, to_option)
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
        manifest.add_plugin(@name, to_option)
        manifest.save
      else
        raise "Unknown strategy type: #{type}"
      end
    end

    class << self
      def create_from_query(query, alias_name=nil)
        name, options = parse_query(query)
        new(alias_name || name, options)
      end

      def all
        manifest = Manifest.new(MANIFEST_PATH)
        manifest.manifest.map{|k,v| new(k, parse_query(v).last)}
      end

      def parse_query(query)
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
        elsif query =~ /\A([a-zA-Z0-9_\-]+)(?:@([a-zA-Z0-9\-\.]+))?\z/
          [
            $1,
            {
              type: :chest,
              version: $2 || 'latest'
            }
          ]
        else
          raise InvalidArgumentError, "Specify valid query: #{query}"
        end
      end
    end

    private

    def to_option
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
      registry = Chest::Registry.new
      registry.download_package(@name, @options.version, path)
    end

    def update_chest
      FileUtil.rm_r path if Dir.exist? path
      registry = Chest::Registry.new
      registry.download_package(@name, @options.version, path)
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
