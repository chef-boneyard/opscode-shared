Gem::Specification.new do |s|
  s.name = 'opscode-jobs-model'
  s.version = '0.0.1'
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.summary = "Model for jobs/tasks for Opscode Quick Start job system"
  s.description = s.summary
  s.author = "Tim Hinderliter"
  s.email = "tim@opscode.com"

  s.add_dependency "couchrest"

  s.require_path = 'lib'
  s.files = Dir.glob("{distro,lib}/**/*")
end
