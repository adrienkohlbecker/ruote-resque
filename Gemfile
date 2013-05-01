source 'https://rubygems.org'

# Specify your gem's dependencies in ruote-resque.gemspec
gemspec

gem "ruote", :git => 'git://github.com/adrienkohlbecker/ruote.git'

platforms :ruby_18, :jruby do
  gem 'json' unless RUBY_VERSION > '1.9' # is there a jruby but 1.8 only selector?
end
