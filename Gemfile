source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

gem 'redcarpet', '>= 3.5.1'

group :web do
  gem 'puma', '~> 4.3.12'
  gem 'sinatra', '>= 2.2.3'
  gem 'sinatra-contrib', '>= 2.2.3'
  gem 'rack-cors'
  gem 'rack-ssl-enforcer', '~> 0.2.9'
  gem 'sentry-raven', '~> 2.9.0'
  gem 'travis-config', '~> 1.1.3'
  gem 'travis-metrics', git: 'https://github.com/travis-ci/travis-metrics', ref: 'sf-unfork'
end

group :test do
  gem 'dpl', git: 'https://github.com/travis-ci/dpl.git'
  gem 'json-schema'
  gem 'rack-test', '>= 2.0.0'
  gem 'rake'
  gem 'rspec'
  gem 'webmock'
end

gemspec
