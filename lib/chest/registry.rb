require 'json'
require 'rest_client'
require 'uri'
require 'fileutils'

class Chest::Registry
  def initialize(token = nil, endpoint: 'http://sketchchest.com/api/')
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
    request :get, "packages/#{package_name}.json"
  end

  def normalize_to_git_url(query)
    if query =~ /\.git$/
      return query
    elsif query =~ /\A([a-zA-Z0-9_\-]+)\/([a-zA-Z0-9_\-]+)\z/
      user = Regexp.last_match(1)
      repository = Regexp.last_match(2)
      url = "https://github.com/#{user}/#{repository}.git"
      return url
    else
      package = fetch_package(query)
      if package['error']
        raise InvalidArgumentError, "Specify valid query for #{query}"
      end
      return package['git_url']
    end
  end
end
