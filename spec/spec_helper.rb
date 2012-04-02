require 'rubygems'
require 'bundler/setup'
require 'json'
require 'webmock/rspec'

ENV['MAVENLINK_DEVELOPMENT'] = 'true'

$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'mavenlink'

def load_fixture(path)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', path))
end

RSpec.configure do |config|
  config.mock_with :rr
end
