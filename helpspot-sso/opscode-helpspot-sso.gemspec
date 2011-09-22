Gem::Specification.new do |s|
  s.name = 'opscode-helpspot-sso'
  s.version = '0.0.1'
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.summary = ""
  s.description = ""
  s.author = "Noah Kantrowitz"
  s.email = "noah@opscode.com"

  s.add_dependency "opscode-json-session"
  s.add_dependency "sequel"

  s.require_path = 'lib'
  s.files = Dir.glob("{distro,lib}/**/*")
end
