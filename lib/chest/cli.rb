require 'thor'
require 'fileutils'

class Chest::CLI < Thor
  desc 'list', 'List plugins'
  def list
    Chest::Plugin.all.each do |plugin|
      puts "(#{plugin.kind})\t#{plugin.name}"
    end
  end

  desc 'install QUERY', 'Install plugin'
  def install(query)
    if query =~ /\.git$/
      # just url
      name = File.basename query, '.*'
      url = query
    elsif query =~ /([^\/]+)\/([^\/]+)/
      # user/repo
      name = $2
      url = "https://github.com/#{$1}/#{$2}.git"
    end

    path = File.join(Chest::PLUGINS_FOLDER, name)
    if Dir.exist? path
      puts "#{name} was already installed."
      exit
    end

    puts "Installing '#{name}' ..."
    system "git clone '#{url}' '#{path}'"
  end

  desc 'uninstall NAME', 'Uninstall plugin'
  def uninstall(name)
    path = File.join(Chest::PLUGINS_FOLDER, name)
    return unless Dir.exist? path

    puts "Uninstalling '#{name}' ..."
    FileUtils.rm_r(path)
  end

  desc 'update [NAME]', 'Update plugins'
  def update(name=nil)
    if name
      Chest::Plugin.all.find{|x| name == x.name and x.update}
    else
      Chest::Plugin.all.map(&:update)
    end
  end
end
