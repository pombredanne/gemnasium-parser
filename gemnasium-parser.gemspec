# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name    = "gemnasium-parser"
  gem.version = "0.1.10"

  gem.authors     = "Erik Nilsen"
  gem.email       = "enilsen16@live.com"
  gem.description = "Safely parse Gemfiles and gemspecs"
  gem.summary     = gem.description
  gem.homepage    = "https://github.com/gemnasium/gemnasium-parser"

  gem.add_development_dependency "bundler", "~> 1.0"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(/^spec\//)
  gem.require_paths = ["lib"]
end
