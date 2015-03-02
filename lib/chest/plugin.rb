module Chest
  PLUGINS_FOLDER = File.expand_path('~/Library/Containers/com.bohemiancoding.sketch3/Data/Library/Application Support/com.bohemiancoding.sketch3/Plugins')

  class Plugin
    attr_reader :path, :name, :kind

    def initialize(path)
      @path = path
      @name = File.basename(path)
      @kind = guess_kind(path)
    end

    def updatable?
      @kind != :local
    end

    def update
      case @kind
      when :git
        update_git
      else
        puts "#{@name} is kind of un-updatable plugin"
        false
      end
    end

    class << self
      def all
        Dir.glob(File.join(PLUGINS_FOLDER, '*')).collect do |path|
          Dir.exist?(path) ? Plugin.new(path) : nil
        end.compact
      end
    end

    private
    def guess_kind(path)
      if Dir.exist? File.join(path, '.git')
        :git
      else
        :local
      end
    end

    def update_git
      puts "Updating '#{@name}' ..."
      system "cd '#{@path}' && git pull"
    end
  end
end
