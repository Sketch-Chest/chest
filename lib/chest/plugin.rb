require 'json'
require 'fileutils'
require 'ostruct'
require 'semantic'
require 'rest_client'

module Chest
  class Plugin
    attr_reader :name, :options

    SKETCH_APPSTORE = File.expand_path('~/Library/Containers/com.bohemiancoding.sketch3/Data/Library/Application Support/com.bohemiancoding.sketch3/Plugins')
    SKETCH_BETA = File.expand_path('~/Library/Application Support/com.bohemiancoding.sketch3/Plugins')
    PLUGINS_FOLDER_PATH = File.exist?(SKETCH_APPSTORE) ? SKETCH_APPSTORE : SKETCH_BETA

    class InvalidArgumentError < StandardError; end

    def initialize(name, options=nil)
      @name = name
      @options = OpenStruct.new(options)

      @registry = Chest::Registry.new
    end

    def path
      File.join(PLUGINS_FOLDER_PATH, @name)
    end

    def type
      @options.type
    end

    def install
      fetch_method = "fetch_#{type}"
      if respond_to?(fetch_method, true)
        begin
          self.send(fetch_method)
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

    def uninstall
      if Dir.exist?(path) && FileUtils.rm_r(path)
        manifest = Manifest.new
        manifest.remove_plugin(@name)
        manifest.save
      else
        raise "#{@name} doesn't exist"
      end
    end

    def update
      fetch_method = "update_#{type}"
      if respond_to?(fetch_method, true)
        begin
          self.send(fetch_method)
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

    def outdated?
      case type
      when :chest
        package = @registry.fetch_package(name)
        return true unless package['version']
        return Semantic::Version.new(@options.version) < Semantic::Version.new(package['version'])
      when :git
        true
      when :direct
        true
      end
    end

    class << self
      def create_from_query(query, alias_name=nil)
        name, options = parse_query(query)
        new(alias_name || name, options)
      end

      def parse_query(query)
        if query =~ /\.git$/
          name = File.basename(query, '.*')
          url  = query
          [
            name,
            {
              type: :git,
              url: query
            }
          ]
        elsif query =~ /\A([a-zA-Z0-9_\-]+)\/([a-zA-Z0-9_\-]+)\z/
          name = $2
          url  = "https://github.com/#{$1}/#{$2}.git"
          [
            name,
            {
              type: :git,
              url: url
            }
          ]
        elsif query =~ /\A([a-zA-Z0-9_\-]+)(?:@([a-zA-Z0-9\-\.]+))?\z/
          name = $1
          version = $2
          [
            name,
            {
              type: :chest,
              version: version
            }
          ]
        elsif query =~ /\Ahttps?:\/\//
          unescaped_url = CGI.unescape(query)
          name = File.basename(unescaped_url, File.extname(unescaped_url))
          [
            name,
            {
              type: :direct,
              url: query
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
      end
    end

    def latest_version
      @registry.fetch_package(@name)['version']
    end

    def fetch_chest
      raise 'already exists' if Dir.exist?(path)
      @options.version = latest_version
      @registry.download_package(@name, @options.version, path)
    end

    def update_chest
      raise 'already updated to latest version' unless outdated?
      FileUtils.rm_r(path) if Dir.exist?(path)
      @options.version = latest_version
      @registry.download_package(@name, @options.version, path)
    end

    def fetch_git
      if @options.branch
        command = "git clone -b #{@options.branch} '#{@options.url}' '#{path}'"
      else
        command = "git clone '#{@options.url}' '#{path}'"
      end

      unless system command
        raise "Failed to install #{@options.url}"
      end
    end

    def update_git
      unless system "cd '#{path}' && git pull"
        raise "Failed to update #{@name}"
      end
    end

    def fetch_direct
      Dir.mktmpdir do |tmpdir|
        archive_path = File.join(tmpdir, 'package.zip')
        unpacked_path = File.join(tmpdir, @name)
        Dir.mkdir unpacked_path
        open(archive_path, 'wb') do |f|
          f.write RestClient.get(@options.url).body
        end
        Zip::File.open archive_path do |zip_file|
          zip_file.each do |entry|
            entry.extract(File.join(unpacked_path, entry.to_s))
          end
        end

        if Dir.exist?(path)
          FileUtils.rm_r path
        end

        FileUtils.cp_r unpacked_path, path
      end
    end

    def update_direct
      unless system "curl -L '#{@options.url}' -o '#{path}'"
        raise "Failed to update #{@name}"
      end
    end
  end
end
