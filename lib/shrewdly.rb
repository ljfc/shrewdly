require 'httparty'

class Shrewdly
  include HTTParty

  class Error < StandardError
  end

  class HTTPFailureResponse < Error
  end

  class Opportunity
    attr_accessor :data

    def self.wrap(opportunities)
      Array(opportunities).reduce([]) do |a, o|
        a << Opportunity.new(o)
      end
    end

    def initialize(opportunity_data)
      self.data = opportunity_data
    end

    def raw_data
      data
    end

    # Most accessors will follow the same pattern, so generate them automatically.
    [
      :opportunity_id,
      :opportunity_name
    ].each do |k|
      define_method(k) do
        self.data.fetch(k.to_s.upcase)
      end
    end

    # Datetime accessors follow a consistent pattern, so generate the automatically too.
    [
      :date_updated_utc
    ].each do |k|
      define_method(k) do
        self.data.fetch(k.to_s.upcase).to_datetime
      end
    end

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
    self.debug_get path, options
    response = Shrewdly.get(path, self.add_basic_auth(options))
    self.debug_response(response) 
    if !response.success?
      raise HTTPFailureResponse, response.response.inspect
    end
    return response
  end

  # Gets specific opportunities. Pass one or more opportunity ID numbers.
  #
  def get_opportunities(ids_or_options = {})
    case ids_or_options
    when Array, Fixnum
      options = { query: { ids: Array(ids_or_options).join(',') } } # The API is expecting a comma-separated list.
    when Hash
      options = ids_or_options
    end

    Opportunity.wrap self.get_with_auth('/Opportunities', options).parsed_response
  end

  # Get opportunities changed more recently than a given datetime.
  #
  def get_opportunities_changed_since(point_in_time)
    Opportunity.wrap self.get_with_auth('/Opportunities', {
      query: {
        '$filter' => ['DATE_UPDATED_UTC', 'gt', "DateTime'#{self.datetime_format(point_in_time)}'"].join(' ')
      }
    })
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

  def datetime_format(datetime)
    datetime.strftime('%FT%T') # The Insightly API takes a not-quite-ISO8601-formatted datetime.
  end

  def add_basic_auth(options)
    options[:basic_auth] = { username: self.api_key, password: '' }
    return options
  end

  def debug(message)
    # If we are in the Rails console, it’s useful to see what’s going on right there in STDOUT.
    if defined?(Rails::Console)
      @logger ||= Logger.new(STDOUT)
      @logger.debug(self.white("Shrewdly: #{message}"))
    end
  end

  def debug_get(path, options)
    self.debug "#{self.green('GET')} #{self.blue(path)}, #{options}"
  end

  def debug_response(response)
    self.debug "#{self.yellow(response.request.last_uri)} => #{debug_code(response.code)} #{response.headers.content_type}"
  end

  def debug_code(code)
    case code
    when 200
      green(code)
    else
      red(code)
    end
  end

  def colour(text, color_code)
      "\e[#{color_code}m#{text}\e[0m"
  end

  def red(text); colour(text, 31); end
  def green(text); colour(text, 32); end
  def yellow(text); colour(text, 33); end
  def blue(text); colour(text, 34); end
  def magenta(text); colour(text, 35); end
  def cyan(text); colour(text, 36); end
  def white(text); colour(text, 37); end

end
