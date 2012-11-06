# -*- encoding: utf-8 -*-
require File.expand_path('../lib/google_anymote/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Richard Hurt"]
  gem.email         = ["rnhurt@gmail.com"]
  gem.description   = %q{Ruby implementation of the Google Anymote Protocol.}
  gem.summary       = %q{This library uses the Google Anymote protocol to send events to Google TV servers.}
  gem.homepage      = "https://github.com/rnhurt/google_anymote"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "google_anymote"
  gem.require_paths = ["lib"]
  gem.version       = GoogleAnymote::VERSION

  gem.add_development_dependency  'yard'
  gem.add_development_dependency  'redcarpet'
  gem.add_dependency              'ruby_protobuf', '~> 0.4.11'
end
