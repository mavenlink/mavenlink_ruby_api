require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mavenlink"
  gem.homepage = "http://github.com/mavenlink/mavenlink_ruby_api"
  gem.license = "MIT"
  gem.summary = %Q{Ruby client for Mavenlink's API}
  gem.description = %Q{This is a Ruby API client for Mavenlink.  Mavenlink's project collaboration suite allows you to manage your business relationships, share files, and track project activity online from anywhere in the world. Within a project workspace in Mavenlink, you can agree on budget & schedule, track time, send invoices, get paid via PayPal, and complete work.}
  gem.email = "support@mavenlink.com"
  gem.authors = ["Mavenlink Team"]

  gem.add_runtime_dependency "httparty", "0.7.4"

  gem.add_development_dependency "webmock", "~> 1.6.2"
  gem.add_development_dependency "rspec", "~> 2.3.0"
  gem.add_development_dependency "jeweler", "~> 1.6.2"
  gem.add_development_dependency "rr", "~> 1.0.2"
  gem.add_development_dependency "json", "~> 1.5.1"
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mavenlink #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
