require 'json'
require 'rest_client'
require 'uri'
require 'fileutils'
require 'parseconfig'
require 'pp'

class Chest::Registry
  def initialize(token=nil, api: 'http://chest.pm/api')
    @token = token
    @api = api
  end

  def request_raw(method, path, params=nil)
    case method
    when :get
      RestClient.get(path, params: params)
    when :post
      RestClient.post(path, params, content_type: :json, accept: :json)
    when :delete
      RestClient.delete(path, params: params)
    end
  end

  def request(method, path, params=nil)
    params.merge! token: @token
    response = request_raw(method, URI.join(@api, path), params)
    return JSON.parse(response.body)
  end

  def fetch_package(package_name)
    request :get, "/packages/#{package_name}"
  end

  def download_package(package_name, version='latest', path)
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

  def publish_package(input_path=Dir.pwd)
    # Parse manifest.json
    unless Dir.glob('*.sketchplugin')[0]
      return false
    end
    manifest_path = File.join(input_path, Dir.glob('*.sketchplugin')[0], 'Contents', 'Sketch', 'manifest.json')
    unless File.exist?(manifest_path)
      return false
    end
    manifest = JSON.parse(File.read(manifest_path))

    # Parse README file
    readme_path = File.join(input_path, 'README.md')
    readme = File.exist?(readme_path) ? File.open(readme_path).read : ''
    manifest.merge! readme: readme

    # Parse repository
    unless manifest['repository']
      gitconfig_path = File.join(input_path, '.git', 'config')
      repository = ParseConfig.new(gitconfig_path)['remote "origin"']
      if repository
        repository_uri = URI.parse(repository['url'])
        case repository_uri.host
        when 'github.com'
          url = "https://github.com" + repository_uri.path
        else
          url = repository_uri.to_s
        end
        manifest.merge! repository: {type: 'git', url: url}
      end
    end

    request :post, "/packages", manifest: manifest
    return response
  end

  def unpublish_package(package_name)
    request :delete, "/packages/#{package_name}"
  end
end
