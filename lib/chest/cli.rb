require 'thor'
require 'fileutils'

class Chest::CLI < Thor
  PLUGINS_FOLDER = File.expand_path '~/Library/Containers/com.bohemiancoding.sketch3/Data/Library/Application Support/com.bohemiancoding.sketch3/Plugins'

  desc 'list', 'List plugins'
  def list
    plugins.each do |plugin|
      puts "(#{plugin.kind})\t#{plugin.name}"
    end
  end

  desc 'install URL', 'Install plugin'
  def install(url)
    name = File.basename url, '.*'
    path = File.join(PLUGINS_FOLDER, name)
    puts "Installing '#{name}' ..."
    system "git clone '#{url}' '#{path}'"
  end

  desc 'uninstall NAME', 'Uninstall plugin'
  def uninstall(name)
    path = File.join(PLUGINS_FOLDER, name)
    return unless Dir.exist? path
    puts "Uninstalling '#{name}' ..."
    FileUtils.rm_r(path)
  end

  desc 'update [NAME]', 'Update plugins'
  def update(name=nil)
    if name
      plugins.find{|x| name == x.name and x.update}
    else
      plugins.map(&:update)
    end
  end

  private

  def plugins
    Dir.glob(File.join(PLUGINS_FOLDER, '*')).collect do |path|
      Dir.exist?(path) ? Chest::Plugin.new(path) : nil
    end.compact
  end
end
