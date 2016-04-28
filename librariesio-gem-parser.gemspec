# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name    = "librariesio-gem-parser"
  gem.version = "1.0.0"

  gem.authors     = "Andrew Nesbitt"
  gem.email       = "andrewnez@gmail.com"
  gem.description = "Fork of gemnasium-parser"
  gem.summary     = gem.description
  gem.homepage    = "https://github.com/librariesio/gemnasium-parser"

  gem.add_development_dependency "bundler", "~> 1.0"
  gem.add_development_dependency "rake", ">= 0.8.7"
  gem.add_development_dependency "rspec", "~> 2.4"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(/^spec\//)
  gem.require_paths = ["lib"]
end
