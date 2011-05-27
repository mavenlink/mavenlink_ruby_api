require 'httparty'

module Mavenlink
  class Base
    include HTTParty
    headers 'Accept' => 'application/json'
    format :json

    attr_accessor :json, :path_params, :basic_auth, :errors

    def initialize(json, options = {})
      self.path_params = options[:path_params] || {}
      self.basic_auth = options[:basic_auth]
      set_json json
    end

    def id
      json['id']
    end
    
    def request_path
      p = self.class.request_path.to_s
      params = path_params.dup
      params[:id] = id if id
      params.each do |key, value|
        p = p.gsub(key.inspect, value.to_s)
      end
      p
    end
    
    def join_paths(original, append)
      original = original + "/" unless original =~ /\/$/
      original = "/" + original unless original =~ /^\//
      append = append.gsub(/^\//, '')
      uri = URI.parse("http://www.example.com#{original}")
      (uri + append).path.gsub(/\/$/, '')
    end
    
    def get_request(path, options = {})
      puts "GET #{path}" if self.class.debug
      self.class.get path, :query => options, :basic_auth => basic_auth
    end

    def put_request(path, options = {})
      puts "PUT #{path}" if self.class.debug
      self.class.put path, :body => options, :basic_auth => basic_auth
    end

    def post_request(path, options = {})
      puts "POST #{path}" if self.class.debug
      self.class.post path, :body => options, :basic_auth => basic_auth
    end

    def delete_request(path, options = {})
      puts "DELETE #{path}" if self.class.debug
      self.class.delete path, :query => options, :basic_auth => basic_auth
    end

    def update(changes)
      response = put_request(request_path, self.class.class_name => changes)
      if response.code == 200
        set_json response.parsed_response
        true
      elsif response.code == 422
        self.errors = response.parsed_response['errors']
        false
      else
        raise "Server error code #{response.code}"
      end
    end

    def destroy
      response = delete_request(request_path)
      if response.code == 200
        true
      elsif response.code == 422
        self.errors = response.parsed_response['errors']
        false
      else
        raise "Server error code #{response.code}"
      end
    end

    def reload(options = {})
      result = get_request(request_path, options)
      if result.code == 200
        set_json result.parsed_response
      else
        raise "Server error code #{result.code}"
      end
      self
    end
    
    protected

    def set_json(j)
      self.errors = []
      self.json = j
      wrap_contained_objects
    end

    def wrap_contained_objects
      (self.class.contains || {}).keys.each do |method|
        json[method.to_s] = if !json.has_key?(method.to_s)
                              nil
                            elsif json[method.to_s].is_a?(Array)
                              json[method.to_s].map do |data|
                                options = get_contains_options(method.to_sym, data)
                                options[:class].new(data, :basic_auth => basic_auth, :path_params => options[:path_params] || {})
                              end
                            else
                              options = get_contains_options(method.to_sym, json[method.to_s])
                              options[:class].new(json[method.to_s], :basic_auth => basic_auth, :path_params => options[:path_params] || {})
                            end
      end
    end

    def build(path, klass, options, new_path_params = {})
      response = post_request(join_paths(request_path, path), klass.class_name => options)
      if response.code == 200
        klass.new(response.parsed_response, :basic_auth => basic_auth, :path_params => handle_proc(new_path_params, response.parsed_response))
      elsif response.code == 422
        k = klass.new(response.parsed_response, :basic_auth => basic_auth, :path_params => handle_proc(new_path_params, response.parsed_response))
        k.errors = response.parsed_response['errors']
        k
      else
        raise "Server error code #{response.code}"
      end
    end

    def fetch(path, klass, options, new_path_params = {})
      result = get_request(join_paths(request_path, path), options)
      if result.code == 200
        if result.parsed_response.is_a?(Array)
          result.parsed_response.map { |data| klass.new(data, :basic_auth => basic_auth, :path_params => handle_proc(new_path_params, data)) }
        else
          klass.new(result.parsed_response, :basic_auth => basic_auth, :path_params => handle_proc(new_path_params, result.parsed_response))
        end
      else
        raise "Server error code #{result.code}"
      end
    end
    
    def handle_proc(possibly_proc, *args)
      (possibly_proc && possibly_proc.is_a?(Proc) && possibly_proc.call(*args)) || possibly_proc
    end

    def get_contains_options(method, data)
      if self.class.contains[method].is_a?(Class)
        { :class => self.class.contains[method] }
      elsif self.class.contains[method].is_a?(Proc)
        self.class.contains[method].call(self, data)
      elsif self.class.contains[method].is_a?(Hash)
        self.class.contains[method]
      else
        nil
      end
    end

    def method_missing(method)
      json.has_key?(method.to_s) ? json[method.to_s] : super
    end

    def self.contains(c = nil)
      @contains = c if c
      @contains
    end

    def self.request_path(p = nil)
      @request_path = p if p
      @request_path
    end

    def self.class_name(c = nil)
      @class_name = c if c
      @class_name
    end

    def self.debug(state = :not_set)
      @@debug = state unless state == :not_set
      @@debug
    end
  end
end
