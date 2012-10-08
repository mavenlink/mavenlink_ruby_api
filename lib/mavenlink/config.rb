require 'faraday'

module Mavenlink
  class Config
    attr_accessor :debug, :domain, :root_path, :skip_ssl_verification,
                  :faraday_adaptor, :timeout, :open_timeout,
                  :basic_auth_username, :basic_auth_password,
                  :access_token

    def initialize
      # Set defaults
      self.timeout = 50                 # open/read timeout in seconds
      self.open_timeout = 5             # connection open timeout in seconds
      self.skip_ssl_verification = false
      self.debug = false
    end

    def connection
      @conn ||= Faraday.new(:url => domain) do |faraday|
        faraday.request  :multipart               # if files are included, use multi-part encoding
        faraday.request  :url_encoded             # form-encode POST params
        faraday.response :logger if debug         # log requests to STDOUT
        faraday.adapter  faraday_adaptor || :net_http
        faraday.ssl[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if skip_ssl_verification && defined?(OpenSSL)
      end
    end

    def make_request(type, path, options)
      puts "#{type.to_s.upcase} #{path}" if debug

      connection.send(type) do |req|
        req.url root_path + "/" + path

        if basic_auth_username && basic_auth_password
          req.headers['Authorization'] = Faraday::Request::BasicAuthentication.header(basic_auth_username, basic_auth_password)
          options[:bearer_token] = access_token if access_token
        else
          req.headers['Authorization'] = "Bearer %s" % access_token if access_token
        end

        req.headers['Accept'] = 'application/json'
        if type == :get || type == :delete
          req.params = options
        else
          req.body = options
        end
        req.options[:timeout] = timeout
        req.options[:open_timeout] = open_timeout
      end
    end
  end
end
