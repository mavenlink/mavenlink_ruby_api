ENV['TESTING'] = 'true'

Bundler.require(:default, :development)
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'mavenlink'))
require 'webmock/rspec'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  def load_fixture(path)
    File.read(File.join(File.dirname(__FILE__), 'fixtures', path))
  end
  
  config.mock_with :rr
end

  
