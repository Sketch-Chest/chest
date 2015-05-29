require 'json'

module Chest
  class Metadata
    attr_reader :metadata

    def initialize(path=Chest::Config.new.metadata_path)
      @path = path
      @metadata = load_metadata
    end

    def plugins
      @metadata.map{|k, v| Plugin.new(k, parse_option(v))}
    end

    def get_plugin(name)
      Plugin.new name.to_s, parse_option(@metadata[name.to_s])
    end

    def get_plugin_option(name)
      unless @metadata[name.to_s]
        return {}
      end
      parse_option(@metadata[name.to_s])
    end

    def add_plugin(name, args)
      @metadata[name.to_s] = args
    end

    def remove_plugin(name)
      @metadata.delete name.to_s
    end

    def save
      write_metadata
    end

    private
    def load_metadata
      File.exist?(@path) ? JSON.parse(File.open(@path).read) : {}
    end

    def write_metadata
      File.open(@path, 'w').write(JSON.pretty_generate(@metadata))
    end

    def parse_option(query)
      if query =~ /\.git$/
        {
          type: :git,
          url: query
        }
      elsif query =~ /\Ahttps?:\/\//
        {
          type: :direct,
          url: query
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
