Gem::Specification.new do |s|
  s.name = 'opscode-dark-launch'
  s.version = '0.0.2'
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.summary = "Dark Launch manages features that are enabled only for specific organizations"
  s.description = "Dark Launch manages features that should be enabled only for specific organizations. Organizations cannot use a dark-launch enabled feature unless their organization name is in the dark-launch config file, Chef::Config[:dark_launch_features_filename]"
  s.author = "Tim Hinderliter"
  s.email = "tim@opscode.com"

  s.add_dependency "chef"

  s.require_path = 'lib'
  s.files = Dir.glob("{distro,lib}/**/*")
end
