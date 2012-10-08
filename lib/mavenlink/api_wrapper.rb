require_relative "config"
require 'json'

module Mavenlink
  class ApiWrapper
    attr_accessor :json, :path_params, :config, :errors

    def initialize(json, options = {})
      self.path_params = options[:path_params] || {}
      self.config = options[:config]
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
      config.make_request :get, path, options
    end

    def put_request(path, options = {})
      config.make_request :put, path, options
    end

    def post_request(path, options = {})
      config.make_request :post, path, options
    end

    def delete_request(path, options = {})
      config.make_request :delete, path, options
    end

    def update(changes)
      response = put_request(request_path, self.class.class_name => changes)
      if response.status == 200
        set_json JSON.parse(response.body)
        true
      elsif response.status == 422
        self.errors = JSON.parse(response.body)['errors']
        false
      else
        raise "Server error status #{response.status}"
      end
    end

    def destroy
      response = delete_request(request_path)
      if response.status == 200
        true
      elsif response.status == 422
        self.errors = JSON.parse(response.body)['errors']
        false
      else
        raise "Server error status #{response.status}"
      end
    end

    def reload(options = {})
      result = get_request(request_path, options)
      if result.status == 200
        set_json JSON.parse(result.body)
      else
        raise "Server error status #{result.status}"
      end
      self
    end

    # For Rails's as_json
    def as_json(*args)
      @json.as_json(*args)
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
                                options[:class].new(data, :config => config, :path_params => options[:path_params] || {})
                              end
                            else
                              options = get_contains_options(method.to_sym, json[method.to_s])
                              options[:class].new(json[method.to_s], :config => config, :path_params => options[:path_params] || {})
                            end
      end
    end

    def build(path, klass, options, new_path_params = {})
      response = post_request(join_paths(request_path, path), klass.class_name => options)
      if response.status == 200
        parsed_response = JSON.parse(response.body)
        klass.new(parsed_response, :config => config, :path_params => handle_proc(new_path_params, parsed_response))
      elsif response.status == 422
        parsed_response = JSON.parse(response.body)
        k = klass.new(parsed_response, :config => config, :path_params => handle_proc(new_path_params, parsed_response))
        k.errors = parsed_response['errors']
        k
      else
        raise "Server error status #{response.status}"
      end
    end

    def fetch(path, klass, options, new_path_params = {})
      result = get_request(join_paths(request_path, path), options)
      if result.status == 200
        parsed_response = JSON.parse(result.body)
        if parsed_response.is_a?(Array)
          parsed_response.map { |data| klass.new(data, :config => config, :path_params => handle_proc(new_path_params, data)) }
        else
          klass.new(parsed_response, :config => config, :path_params => handle_proc(new_path_params, parsed_response))
        end
      else
        raise "Server error status #{result.status}: #{result.body}"
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

    class << self
      def contains(c = nil)
        @contains = c if c
        @contains
      end

      def request_path(p = nil)
        @request_path = p if p
        @request_path
      end

      def class_name(c = nil)
        @class_name = c if c
        @class_name
      end
    end
  end
end
