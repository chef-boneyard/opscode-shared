require 'opscode/job'
require 'uri'
require 'restclient'
require 'yajl'

module Opscode::Persistor
  class InstancePersistor < BasePersistor

    def self.inflate_object(data)
      # TODO: get clear on whether to symbolize keys or not.
      data = Mash.new(data)
      res = Instance.new(data)

      if data['_attachments'] && data['_attachments']['chef_log']
        res.chef_log = Base64.decode64(data['_attachments']['chef_log']['data'])
        res.db_rev = data['_rev']
      end
      res
    end

    def save(instance)
      # parse the output of the put, so we can get the revision ID, so
      # then we can include it in the attachment upload, since it's
      # required.
      res = RestClient.put(url(instance.db_id), instance.to_hash.to_json)
      res = Yajl::Parser.parse(res)
      instance.db_rev = res['rev']

      if instance.chef_log
        attachment_url = "#{url(instance.db_id)}/chef_log"
        if instance.db_rev
          attachment_url += "?rev=#{instance.db_rev}"
        end

        RestClient.put(attachment_url, instance.chef_log)
      end
    rescue Exception => e
      raise CouchDBAngry.new(e)
    end

  end
end
