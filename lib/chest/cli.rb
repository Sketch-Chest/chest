require 'thor'
require 'fileutils'
require 'json'

class Chest::CLI < Thor
  def initialize(*args)
    super
    # TODO: add plugins, which are out of control, to manifest file
  end

  desc 'install QUERY [, ALIAS_NAME]', 'Install plugin'
  def install(query, alias_name=nil)
    plugin = Chest::Plugin.create_from_query(query, alias_name)

    say "Installing '#{plugin.name}' ...", :green
    begin
      plugin.install
    rescue => e
      fail "   #{e}"
    else
      say "   Successfully installed", :green
    end
  end

  desc 'uninstall NAME', 'Uninstall plugin'
  def uninstall(name)
    plugin = Chest::Plugin.new(name)

    say "Uninstalling '#{plugin.name}' ..."
    begin
      plugin.uninstall
    rescue => e
      fail "   #{e}"
    end
  end

  desc 'update [NAME]', 'Update plugins'
  def update(name=nil)
    puts "Updating plugins"

    plugins = name ? [Chest::Manifest.new.get_plugin(name)] : Chest::Manifest.new.plugins
    plugins.each do |plugin|
      begin
        plugin.update
      rescue => e
        fail "   #{e}"
      else
        say "Updated '#{plugin.name}'"
      end
    end
  end

  desc 'info NAME', 'Show plugin info'
  def info(name)
    plugin = Chest::Manifest.new.get_plugin(name)
    case plugin.type
    when :chest
      say "#{plugin.name} (#{plugin.options.version})"
    when :git
      say plugin.name
      say plugin.options.url
    when :direct
      say plugin.name
      say plugin.options.url
    end
  end

  desc 'list', 'List plugins'
  def list
    Chest::Manifest.new.plugins.each do |plugin|
      case plugin.type
      when :chest
        say "#{plugin.name} (#{plugin.options.version})"
      when :git
        say "#{plugin.name} (#{plugin.options.url})"
      when :direct
        say "#{plugin.name} (#{plugin.options.url})"
      end
    end
  end

  desc 'init', 'Create chest.json'
  def init
    package = {}

    say 'Creating chest.json ...'

    # Name
    package['name'] = ask 'name:', default: File.basename(Dir.pwd)

    # Version
    package['version'] = ask 'version:', default: '1.0.0'

    # Description
    package['description'] = ask 'description:'

    # Keywords
    package['keywords'] = [ask('keywords:')]

    # Authors
    git_user  = `git config --get user.name`.strip
    git_email = `git config --get user.email`.strip
    package['authors'] = [ask('authors:', default: "#{git_user} <#{git_email}>")]

    # License
    package['license'] = ask 'license:', default: 'MIT'

    # Homepage
    remote_url = `git config --get remote.origin.url`.strip
    package['homepage'] = ask 'homepage:', if remote_url =~ /github\.com[:\/]([a-zA-Z0-9_-]+?)\/([a-zA-Z0-9_\-]+?)\.git/
      { default: "https://github.com/#{$1}/#{$2}" }
    end

    # Repository
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
      fail 'Specify valid token' unless config.token
      config.save
    end

    registry = Chest::Registry.new config.token
    begin
      registry.publish_package(dir)
    rescue => e
      fail e
    else
      say "Published"
    end
  end

  desc 'open', 'Open plugins folder'
  def open
    config = Chest::Config.new
    system %{/usr/bin/open "#{config.plugins_folder}"}
  end
end
