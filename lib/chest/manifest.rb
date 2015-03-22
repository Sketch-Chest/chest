require 'json'

module Chest
  class Manifest
    attr_reader :manifest

    def initialize(path=Chest::Config.new.manifest_path)
      @path = path
      @manifest = load_manifest
    end

    def plugins
      @manifest.map{|k, v| Plugin.new(k, parse_option(v))}
    end

    def get_plugin(name)
      Plugin.new name.to_s, parse_option(@manifest[name.to_s])
    end

    def get_plugin_option(name)
      unless @manifest[name.to_s]
        return {}
      end
      parse_option(@manifest[name.to_s])
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

    def parse_option(query)
      if query =~ /\.git$/
        {
          type: :git,
          url: query
        }
      elsif query =~ /\A(http:\/\/.+)\z/
        {
          type: :direct,
          url: $1
        }
      elsif query =~ /\A([a-zA-Z0-9\-\.]+)\z/
        {
          type: :chest,
          version: $1 || 'latest'
        }
      else
        raise InvalidArgumentError, "Specify valid query: #{query}"
      end
    end
  end
end
