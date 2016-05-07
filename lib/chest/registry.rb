require 'json'
require 'rest_client'
require 'uri'
require 'fileutils'
require 'parseconfig'

class Chest::Registry
  def initialize(token = nil, endpoint: 'http://sketchchest.com/api')
    @token = token
    @endpoint = endpoint
  end

  def request_raw(method, path, params = {})
    case method
    when :get
      RestClient.get path, params: params
    when :post
      RestClient.post(path, params, content_type: :json, accept: :json)
    when :delete
      RestClient.delete(path, params: params)
    end
  end

  def request(method, path, params = {})
    params[:token] = @token
    response = request_raw(method, URI.join(@endpoint, path).to_s, params)
    JSON.parse(response.body)
  end

  def fetch_package(package_name)
    request :get, "/packages/#{package_name}.json"
  end

  def download_package(package_name, _version = 'latest', path)
    Dir.mktmpdir do |tmpdir|
      manifest = fetch_package(package_name)
      repo_url = manifest['repository']['url']
      suc = system "git clone #{repo_url} #{tmpdir}"
      if suc
        FileUtils.cp_r tmpdir, path
      else
        return false
      end
    end
  end

  def publish_package(git_url)
    # Parse manifest.json
    manifest_path = '*.sketchplugin/Contents/Sketch/manifest.json'
    manifest = JSON.parse(File.read(manifest_path))

    # Parse README file
    readme_path = File.join(input_path, 'README.md')
    readme = File.exist?(readme_path) ? File.open(readme_path).read : ''
    manifest[:readme] = readme

    # Parse repository
    unless manifest['repository']
      gitconfig_path = File.join(input_path, '.git', 'config')
      repository = ParseConfig.new(gitconfig_path)['remote "origin"']
      if repository
        repository_uri = URI.parse(repository['url'])
        url = case repository_uri.host
              when 'github.com'
                'https://github.com' + repository_uri.path
              else
                repository_uri.to_s
              end
        manifest[:repository] = { type: 'git', url: url }
      end
    end

    request :post, '/packages', manifest: manifest
    response
  end

  def unpublish_package(package_name)
    request :delete, "/packages/#{package_name}"
  end
end
