Gem::Specification.new do |s|
  s.name = "bandy-dci"
  s.version = "0.0.3"

  s.authors = ["Chris Bandy"]
  s.email = ["bandy.chris@gmail.com"]
  s.homepage = %q{https://github.com/cbandy/ruby-dci}
  s.summary = "DCI"
  s.description = "Facilitate DCI in Ruby"

  s.files = Dir.glob('lib/**/*')
  s.require_paths = ['lib']
  s.test_files = Dir.glob('spec/**/*')

  s.add_development_dependency 'rspec', '>= 2.14'
end
