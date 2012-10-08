# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mavenlink/version"

Gem::Specification.new do |s|
  s.name = %q{mavenlink}
  s.version     = Mavenlink::VERSION
  s.authors = ["Mavenlink Team"]
  s.email = %q{support@mavenlink.com}
  s.homepage = %q{http://github.com/mavenlink/mavenlink_ruby_api}
  s.summary = %q{Ruby client for Mavenlink's API}
  s.description = %q{This is a Ruby API client for Mavenlink.  Mavenlink's project collaboration suite allows you to manage your business relationships, share files, and track project activity online from anywhere in the world. Within a project workspace in Mavenlink, you can agree on budget & schedule, track time, send invoices, get paid via PayPal, and complete work.}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.licenses = ["MIT"]

  s.add_runtime_dependency "faraday"
  s.add_runtime_dependency "json"
  s.add_development_dependency "webmock"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rr"
end
