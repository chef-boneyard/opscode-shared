$:.unshift(File.expand_path('../../lib', __FILE__))

require 'opscode/job'
require 'opscode/task'
require 'opscode/persistor/job_persistor'

include Opscode
include Opscode::Persistor

