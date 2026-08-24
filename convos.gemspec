# frozen_string_literal: true

require_relative "lib/convos/version"

Gem::Specification.new do |spec|
  spec.name = 'convos'
  spec.version = Convos::VERSION
  spec.authors = ['Ruslan Ledesma Garza']
  spec.email = ['ruslanledesmagarza@gmail.com']

  spec.summary = 'Convos is a minimum feature comments system for blogs in Ruby.'
  # spec.description = spec.summary
  spec.homepage = 'https://github.com/mrrusof/convos'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 4.0.5'

  spec.metadata['allowed_push_host'] = 'NONE'

  spec.metadata['homepage_uri'] = spec.homepage
  # spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files          = `find lib -name '*.rb' -o -name '*.erb'`.split($\)
  [ 
    'db/schema.rb',
    `find db/migrate -name '*.rb'`.split($\)
  ].flatten.each { |f| spec.files << f }
  spec.bindir = 'bin'
  spec.executables = ['convos']
  spec.require_paths = ['config','lib']

  spec.add_dependency 'sinatra', '~> 4.2.1'
  spec.add_dependency 'rackup', '~> 2.3'
  spec.add_dependency 'puma', '~> 8.0.2'
  spec.add_dependency 'bundler', '~> 4.0.12'
  spec.add_dependency 'sinatra-activerecord', '~> 2.0.28'
  spec.add_dependency 'sqlite3', '~> 2.9.6'
  spec.add_dependency 'pg', '~> 1.6.3'
  spec.add_dependency 'bcrypt', '~> 3.1.22'
  spec.add_dependency 'altcha', '~> 2.0.1'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
