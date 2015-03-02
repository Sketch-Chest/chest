require 'json'
require 'ostruct'
require 'fileutils'

module Chest

  CONFIG_NAME = '.chestrc'
  CONFIG_PATH = File.expand_path(CONFIG_NAME, '~')

  class FileMissingError < StandardError; end

  class Config < OpenStruct
    attr_reader :file_path

    def initialize(file_path=CONFIG_PATH)
      super({})
      @file_path = file_path
      self.load!
    end

    def load!
      begin
        if File.exist? @file_path
          File.open(@file_path, 'r') do |f|
            self.marshal_load(symbolize_keys(JSON(f.read)))
          end
        end
      rescue Errno::ENOENT, IOError
        raise FileMissingError
      end
    end

    def update!(attributes={})
      attributes_with!(attributes)
    end

    def attributes_with!(attributes={})
      attributes.each do |key, value|
        self.send(key.to_s + "=", value) if self.respond_to?(key.to_s + "=")
      end
    end

    def save
      FileUtils.mkpath(File.dirname(@file_path))
      File.open(@file_path, 'w') {|f| f.puts self.to_json }
    end

    def to_hash
      table.to_h
    end

    def to_json
      JSON.pretty_generate(to_hash)
    end

    private

    def symbolize_keys(hash)
      hash.inject({}){|res, (k,v)| res[k.to_sym] = v; res}
    end
  end
end
