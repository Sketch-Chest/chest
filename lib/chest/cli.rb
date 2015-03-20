require 'thor'
require 'fileutils'
require 'json'

class Chest::CLI < Thor
  def initialize(*args)
    super
    # TODO: add plugins that out of control into manifest
  end

  desc 'list', 'List plugins'
  def list
    Chest::Plugin.all.each do |plugin|
      puts "(#{plugin.type})\t#{plugin.name}"
    end
  end

  desc 'install QUERY [, ALIAS_NAME]', 'Install plugin'
  def install(query, alias_name=nil)
    plugin = Chest::Plugin.create_from_query(query, alias_name)

    if Dir.exist? plugin.path
      fail "#{plugin.name} was already installed."
    end

    say "Installing '#{plugin.name}' ...", :green
    if plugin.install
      say "Successfully installed", :green
    else
      fail "Error happend"
    end
  end

  desc 'uninstall NAME', 'Uninstall plugin'
  def uninstall(name)
    plugin = Chest::Plugin.new(name)

    unless Dir.exist? plugin.path
      fail "#{plugin.name} doesn't exist"
    end

    say "Uninstalling '#{plugin.name}' ..."
    plugin.uninstall
  end

  desc 'update [NAME]', 'Update plugins'
  def update(name=nil)
    if name
      Chest::Plugin.all.find{|x| name == x.name and x.update}
    else
      Chest::Plugin.all.map(&:update)
    end
  end

  desc 'info NAME', 'Show plugin info'
  def info(name)
    plugin = Chest::Plugin.new(name)
    case plugin.type
    when :chest
      puts plugin.name
      puts plugin.version
    when :git
      puts plugin.name
      puts plugin.options.url
    when :direct
    end
  end

  desc 'init', 'Create chest.json'
  def init
    package = {}

    say 'Creating chest.json ...'
    package['name'] = ask 'name:', default: File.basename(Dir.pwd)

    package['version'] = ask 'version:', default: '1.0.0'

    package['description'] = ask 'description:'

    package['keywords'] = [ask('keywords:')]

    git_user = `git config --get user.name`.strip
    git_email = `git config --get user.email`.strip
    package['authors'] = [ask('authors:', default: "#{git_user} <#{git_email}>")]

    package['license'] = ask 'license:', default: 'MIT'

    remote_url = `git config --get remote.origin.url`.strip
    package['homepage'] = ask 'homepage:', if remote_url =~ /github\.com[:\/]([a-zA-Z0-9_-]+?)\/([a-zA-Z0-9_\-]+?)\.git/
      { default: "https://github.com/#{$1}/#{$2}" }
    end

    package['repository'] = remote_url

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

  desc 'publish', 'Publish package'
  def publish(dir=Dir.pwd)
    config = Chest::Config.new

    unless config.token
      config.token = ask 'Chest registry token:'
      fail SystemExit unless config.token
      config.save
    end

    registry = Chest::Registry.new config.token, api: 'http://localhost:3000/api'
    say registry.publish_package dir
  end
end
