require 'opscode/instance'
require 'opscode/persistor/base_persistor'
require 'uri'
require 'restclient'
require 'yajl'

module Opscode::Persistor
  class InstancePersistor < BasePersistor

    set_design_doc <<-EOD
{
  "language": "javascript",
  "views":
  {
    "all": {
      "map": "function(doc) { if (doc.type == 'instance') emit(doc._id, doc._id) }"
    },
    "by_job_id": {
      "map": "function(doc) { if (doc.type == 'instance') emit(doc.job_id, doc._id) }"
    },
    "by_instance_id": {
      "map": "function(doc) { if (doc.type == 'instance') emit(doc.instance_id, doc._id) }"
    }
  }
}
    EOD

    # This method is passed a hash with symbols as keys!
    def self.inflate_object(data, attachments)
      res = Opscode::Instance.new(data)
      if attachments
        res.from_log(attachments[:chef_log])
      end
      res
    end

    # Returns an array of instances with the given job_id.
    # returns attachments as well if attachments=true
    def find_by_job_id(job_id, attachments=false)
      execute_view("by_job_id", job_id, "attachments" => attachments)
    end

    # Returns all instances in the database.
    def find_all()
      execute_view("all", nil)
    end

    # Returns a single Instance document with the given instance_id, or
    # nil.
    #
    # Populates the attachments as well
    def find_by_instance_id(instance_id)
      execute_view_single("by_instance_id", instance_id, "attachments" => true)
    end

    def save(instance)
      # parse the output of the put, so we can get the revision ID, so
      # then we can include it in the attachment upload, since it's
      # required.
      hash = instance.to_hash.merge(:type => "instance")
      hash.delete(:chef_log)
      db_rev = force_save(instance.db_id, hash)

      if instance.chef_log
        attachment_url = "#{url(instance.db_id)}/chef_log?rev=#{db_rev}"
        RestClient.put(attachment_url, instance.chef_log)
      end
    rescue Exception => e
      raise CouchDBAngry.new(e)
    end

  end
end
