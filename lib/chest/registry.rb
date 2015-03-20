require 'json'
require 'rest_client'
require 'chest/helpers/zipfile'

class Chest::Registry
  def initialize(token=nil, api: 'http://chest.pm/api')
    @token = token
    @api = api
  end

  def request(method, path, params={})
    case method
    when :get
      JSON.parse(RestClient.get(@api + path, params: params).body)
    when :post
      JSON.parse(RestClient.post(@api + path, params, content_type: :json, accept: :json).body)
    when :delete
      JSON.parse(RestClient.delete(@api + path, params: params).body)
    end
  end

  def fetch_package(package_name)
    request :get, "/packages/#{package_name}"
  end

  def fetch_package_versions(package_name)
    request :get, "/packages/#{package_name}/versions"
  end

  def download_package(package_name, version='latest', path)
    Dir.mkdir path unless Dir.exist? path
    Dir.mktmpdir do |tmpdir|
      archive_path = File.join tmpdir, 'package.zip'
      open(archive_path, 'wb') do |f|
        f.write RestClient.get(@api + "/packages/#{package_name}/versions/#{version}/download").body
      end
      Zip::File.open archive_path do |zip_file|
        zip_file.each do |entry|
          entry.extract(File.join(path, entry.to_s))
        end
      end
    end
  end

  def publish_package(input_path=Dir.pwd)
    chest_config = JSON.parse(open(File.join(input_path, 'chest.json')).read)

    readme_path = File.join(input_path, 'README.md')
    readme = File.exist?(readme_path) ? File.open(readme_path).read : ''
    metadata = chest_config.merge readme: readme
    ignore_config_path = File.join(input_path, '.gitignore')
    ignored_files = File.exist?(ignore_config_path) ? File.open(ignore_config_path).read.split(/\r?\n/) : []
    ignored_files |= ['.', '..', '.git']

    response = nil

    Dir.mktmpdir do |tmpdir|
      archive_path = File.join tmpdir, "#{chest_config['name']}.zip"
      ZipFileGenerator.new(input_path, archive_path, ignored_files).write
      response = request :post, "/packages", token: @token, metadata: metadata, archive: File.new(archive_path, 'rb')
    end

    return response
  end

  def unpublish_package(package_name)
    request :delete, "/packages/#{package_name}", token: @token
  end
end
