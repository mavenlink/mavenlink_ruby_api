require 'faraday'

module Mavenlink
  class Config
    attr_accessor :debug, :domain, :root_path, :skip_ssl_verification,
                  :faraday_adaptor, :timeout, :open_timeout,
                  :user_id, :api_token

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
        req.headers[Faraday::Request::Authorization::KEY] = Faraday::Request::BasicAuthentication.header(user_id, api_token)
        req.headers['Accept'] = 'application/json'
        if type == :get || type == :delete
          req.params = options
        else
          req.body = options
        end
        req.options[:timeout] = timeout || 50          # open/read timeout in seconds
        req.options[:open_timeout] = open_timeout || 5 # connection open timeout in seconds
      end
    end
  end
end
