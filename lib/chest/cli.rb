require 'thor'
require 'fileutils'
require 'json'

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
    else
      # chest repository
      name = query
      url = "http://localhost:3000/api/packages/#{name}/download"
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

  desc 'init', 'Create chest.json'
  def init
    package = {}

    say 'Creating chest.json ...'
    package['name'] = ask 'name:', default: File.basename(Dir.pwd)

    package['version'] = ask 'version:', default: '1.0.0'

    package['description'] = ask 'description:'

    package['keywords'] = ask 'keywords:'

    git_user = `git config --get user.name`.strip
    git_email = `git config --get user.email`.strip
    package['authors'] = [ask('authors:', default: "#{git_user} <#{git_email}>")]

    package['license'] = ask 'license:', default: 'MIT'

    remote_url = `git config --get remote.origin.url`.strip
    package['homepage'] = ask 'homepage:', if remote_url =~ /github\.com[:\/]([a-zA-Z0-9_-]+?)\/([a-zA-Z0-9_\-]+?)\.git/
      { default: "https://github.com/#{$1}/#{$2}" }
    end

    say "\n"

    json = JSON.pretty_generate(package)
    say json
    if yes? 'Looks good?', :green
      if File.exist?('chest.json') && !file_collision('chest.json')
        fail SystemExit
      end
      File.open('chest.json', 'w').write(json)
    end
  end
end
