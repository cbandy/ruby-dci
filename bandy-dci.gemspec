# encoding: UTF-8

Gem::Specification.new do |s|
  s.name = 'bandy-dci'
  s.version = '0.0.4'
  s.summary = 'DCI'
  s.description = 'Facilitate DCI in Ruby'

  s.authors = ['Chris Bandy']
  s.email = ['bandy.chris@gmail.com']
  s.homepage = 'https://github.com/cbandy/ruby-dci'
  s.license = 'Apache License Version 2.0'

  s.files = ['lib/dci.rb', 'lib/dci/castable.rb', 'lib/dci/context.rb', 'lib/dci/role_lookup.rb']
  s.require_paths = ['lib']
  s.test_files = ['spec/dci/castable_spec.rb', 'spec/dci/context_spec.rb', 'spec/dci/role_lookup_spec.rb']

  s.required_ruby_version = '>= 1.9'
  s.add_development_dependency 'rspec', '>= 2.14'
end
