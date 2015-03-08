require 'net/http'
require 'uri'
require 'json'
require 'rest_client'

class Chest::Registry
  def initialize(token, api: 'http://chest.pm/api')
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

  def publish_package(metadata, file_obj)
    request :post, "/packages", token: @token, metadata: metadata.to_json, archive: file_obj
  end

  def unpublish_package(package_name)
    request :delete, "/packages/#{package_name}", token: @token
  end
end
