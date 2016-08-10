require 'thor'
require 'fileutils'
require 'json'
require 'git'

class Chest::CLI < Thor
  def initialize(*args)
    super
  end

  desc 'version', "Prints the bundler's version information"
  def version
    say "Chest version #{Chest::VERSION}"
  end
  map %w(-v --version) => :version

  desc 'install NAME', 'Install plugin'
  def install(query)
    git_url = Chest::Registry.new.normalize_to_git_url(query)
    plugin_folder = Chest::PluginFolder.new

    begin
      say "===> Cloning #{git_url}"
      Dir.mktmpdir do |tmpdir|
        repo = Git.clone(git_url, 'p', path: tmpdir)
        remote_path = URI.parse(repo.remote.url).path
        repo_name = File.basename(remote_path, File.extname(remote_path))
        plugin_folder.install(File.join(tmpdir, 'p'), repo_name)
        info(repo_name)
      end
    rescue => e
      say '===> Error', :red
      raise e
    else
      say '💎  Successfully installed'
    end
  end

  desc 'uninstall NAME', 'Uninstall plugin'
  def uninstall(plugin_name)
    plugin_folder = Chest::PluginFolder.new

    begin
      plugin_path = plugin_folder.path_for(plugin_name, true)

      raise "#{plugin_name} doesn't exist" unless Dir.exist? plugin_path

      delete = yes? "Are you sure to uninstall '#{plugin_name}'? (y/n)"
      if delete
        say '===> Uninstalling'
        deleted_path = plugin_folder.uninstall(plugin_path)
        say "Deleted: #{deleted_path}"
      end
    rescue => e
      say '===> Error', :red
      raise e.to_s
    end
  end

  desc 'update [NAME]', 'Update plugins'
  def update(plugin_name = nil)
    plugin_folder = Chest::PluginFolder.new
    plugins = plugin_name ? [plugin_folder.path_for(plugin_name, true)] : plugin_folder.plugins

    say '===> Updating plugins'
    plugins.each do |plugin_path|
      begin
        manifest = plugin_folder.manifest_for(plugin_path)
        repo = Git.open(plugin_path)
        repo.pull
      rescue => e
        say "Error: #{e}", :red
      else
        new_manifest = plugin_folder.manifest_for(plugin_path)
        say "Updated #{manifest['name']} (#{manifest['version']} > #{new_manifest['version']})", :green
      end
    end
  end

  desc 'info NAME', 'Show plugin info'
  def info(plugin_name)
    plugin_folder = Chest::PluginFolder.new
    plugin_path = plugin_folder.path_for(plugin_name, true)
    raise "#{plugin_name} doesn't exist" unless Dir.exist? plugin_path

    manifest = plugin_folder.manifest_for(plugin_path)
    say "#{manifest['name']}: #{manifest['version']}"
    say manifest['description'].to_s
    say "Author: #{manifest['author']}"
    say manifest['homepage'].to_s
  end

  desc 'list', 'List plugins'
  def list
    plugin_folder = Chest::PluginFolder.new
    plugins = plugin_folder.plugins
    plugins.each do |plugin_path|
      manifest = plugin_folder.manifest_for(plugin_path)
      say "#{manifest['name']} (#{manifest['version']})"
    end
  end

  desc 'init', 'Create manifest.json'
  def init
    package = {}

    say 'Creating manifest.json ...'

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
    package['author'] = ask('author:', default: git_user)
    package['authorEmail'] = ask('authorEmail:', default: git_email)

    # License
    package['license'] = ask 'license:', default: 'MIT'

    # Homepage
    remote_url = `git config --get remote.origin.url`.strip
    package['homepage'] = ask 'homepage:', if remote_url =~ %r{github\.com[:\/]([a-zA-Z0-9_-]+?)\/([a-zA-Z0-9_\-]+?)\.git}
                                             { default: "https://github.com/#{Regexp.last_match(1)}/#{Regexp.last_match(2)}" }
      end

    # Repository
    package['repository'] = remote_url

    say "\n"
    json = JSON.pretty_generate(package)
    say json
    if yes? 'Looks good?', :green
      if File.exist?('manifest.json') && !file_collision('manifest.json')
        raise SystemExit
      end
      File.open('manifest.json', 'w').write(json)
    end
  end

  desc 'open', 'Open plugins folder'
  def open
    system %(/usr/bin/open "#{Chest::PluginFolder::SKETCH_PLUGIN_FOLDER_PATH}")
  end
end
