require 'httparty'

class Shrewdly
  include HTTParty

  class Error < StandardError
  end

  class HTTPFailureResponse < Error
  end

  base_uri 'https://api.insight.ly/v2.1'

  attr_accessor :api_key

  # Sets up an object for querying the API. The config_options must contain the appropriate :api_key
  #
  def initialize(config_options)
    self.api_key = config_options.fetch('api_key')
  end

  # Basic utility function to perform GET requests against the API.
  #
  def get_with_auth(path, options = {})
    puts "Insightly GET #{path}, #{options}"
    response = Shrewdly.get(path, self.add_basic_auth(options))
    puts "#{response.request.last_uri} => #{response.code} #{response.headers.content_type}"
    if !response.success?
      raise HTTPFailureResponse, response.response.inspect
    end
    return response
  end

  # Gets specific opportunities. Pass one or more opportunity ID numbers.
  #
  def get_opportunities(ids_or_options)
    self.get_with_auth '/Opportunities',
      query: {
        ids: Array(ids).join(',') # The API is expecting a comma-separated list.
      }
  end

  # Makes a small request of some kind
  #
  def test_connection
    self.get_with_auth '/Opportunities',
      query: {
        tag: 'Design',
        '$top' => 1
      }
  end


protected

  def add_basic_auth(options)
    options[:basic_auth] = { username: self.api_key, password: '' }
    return options
  end

end
