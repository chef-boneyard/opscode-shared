# This gemfile will be used by the cucumber process running features #

source "http://rubygems.org"

gem "chef", :git => "git://github.com/opscode/chef.git", :branch => "pl-master"
gem "uuidtools"
gem "rake"
gem "rest-client", "~> 1.6.0"
gem "json", '1.4.6'


# OPSCODE PATCHED GEMS
gem "couchrest", :git => "git://github.com/opscode/couchrest.git"

group(:integration_test) do
  gem "opscode-cucumber", :git => "git@github.com:opscode/opscode-cucumber.git"
  #gem "opscode-cucumber", :path => "../opscode-cucumber"
  gem "webrat", "0.7.0"
  gem "rack-test", '0.5.4'
  gem "cucumber", '0.9.4'
  gem "gherkin"
  gem "ci_reporter", '1.6.2'
  gem "rspec", "~> 2.5.0"
  gem "rspec-rails", "~> 2.5.0"
  gem "activesupport", '~> 3.0.0'
  #gem "activesupport", '2.3.8'
  #gem "actionpack", "2.3.8"
end
