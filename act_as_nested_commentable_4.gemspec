# Maintain your gem's version:
require "act_as_nested_commentable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "act_as_nested_commentable"
  s.version     = ActAsNestedCommentable::VERSION
  s.authors     = ["Xue Wenfei"]
  s.email       = ["286xwf@163.com"]
  s.homepage    = %q{http://xzlearning.com}
  s.summary     = "Summary of ActAsNestedCommentable."
  s.description = "Description of ActAsNestedCommentable."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.required_ruby_version = ">= 1.9.3"
  s.add_runtime_dependency 'activerecord', '>= 4.0.0', '< 5'

  s.add_dependency "awesome_nested_set"
end
