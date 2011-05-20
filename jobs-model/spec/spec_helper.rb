$:.unshift(File.expand_path('../../lib', __FILE__))

require 'opscode/job'
require 'opscode/task'
require 'opscode/persistor/job_persistor'
require 'opscode/persistor/instance_persistor'
require 'opscode/instance'

include Opscode
include Opscode::Persistor

def recreate_db(db_url)
  begin
    RestClient.delete(db_url)
  rescue RestClient::ResourceNotFound
  end
  
  begin
    RestClient.put(db_url, "")
  rescue RestClient::PreconditionFailed
  end
end

