# This gemfile will be used by the cucumber process running features #

source "http://rubygems.org"

gem "chef", :git => "git://github.com/opscode/chef.git", :branch => "pl-master"
gem "uuidtools"
gem "rake"
gem "rest-client", "~> 1.6.0"
gem "json", '1.4.6'

# Concern and Let
gem "rlet", "~> 0.5.1"

  # OPSCODE PATCHED GEMS
gem "couchrest", :git => "git://github.com/opscode/couchrest.git"

group(:integration_test) do
  gem "opscode-cucumber", :git => "git@github.com:opscode/opscode-cucumber.git"
  gem "ci_reporter", '1.6.2'
  gem "rspec", "~> 2.5.0"
end
