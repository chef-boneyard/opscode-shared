require 'opscode/job'
require 'uri'
require 'restclient'
require 'yajl'

require 'opscode/persistor/base_persistor'

module Opscode::Persistor
  # Puts job objects in the database and gets them out.
  #--
  # I guess this is actually a mapper according to PoEAA but that book is
  # written in java and therefore irrelevant.
  class JobPersistor < BasePersistor

    set_design_doc <<-EOD
{
  "language": "javascript",
  "views":
  {
    "all": {
      "map": "function(doc) { if (doc.type == 'job') emit(doc.id, doc.id) }"
    },
    "by_orgname": {
      "map": "function(doc) { if (doc.type == 'job') emit(doc.orgname, doc.id) }"
    }
  }
}
    EOD

    def self.inflate_object(data)
      job_spec = data
      job_spec[:tasks].map! {|t| Opscode::Task.new(t)}
      job_spec[:created_at] = Time.at(job_spec[:created_at])
      job_spec[:updated_at] = Time.at(job_spec[:updated_at])
      job_spec.merge!(:job_id => data[:'_id'])
      Opscode::Job.new(job_spec)
    end

    def find_by_orgname(orgname)
      execute_view("by_orgname", orgname)
    end

    def find_all()
      execute_view("all", nil)
    end

    def save(job)
      hash = job.to_hash.merge(:type => "job")
      force_save(job.job_id, hash)
    rescue Exception => e
      raise CouchDBAngry.new(e)
    end

  end
end
