require 'httparty'

class Shrewdly
  include HTTParty

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
    Shrewdly.get(path, self.add_basic_auth(options))
  end

  # Gets specific opportunities. Pass one or more opportunity ID numbers.
  #
  def get_opportunities(ids)
    self.get_with_auth '/Opportunities',
      query: {
        ids: Array(ids).join(',') # The API is expecting a comma-separated list.
      }
  end

  # Gets all opportunities. If there are more than 20k results then tags and links are not included.
  #
  def get_all_opportunities
    self.get_with_auth '/Opportunities'
  end

protected

  def add_basic_auth(options)
    options[:basic_auth] = { username: self.api_key, password: '' }
    return options
  end

end
