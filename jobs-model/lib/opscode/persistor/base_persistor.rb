require 'opscode/job'
require 'uri'
require 'restclient'
require 'yajl'

module Opscode::Persistor
  class CouchDBAngry < RuntimeError
    attr_reader :caused_by
    def initialize(caused_by)
      super(caused_by.message)
      @caused_by = caused_by
      set_backtrace(caused_by.backtrace)
    end
  end

  class BasePersistor
    attr_reader :db_url

    def initialize(db_url, force_create = true)
      begin
        RestClient.get(db_url)
      rescue => e
        if e.is_a?(RestClient::ResourceNotfound) && force_create
          RestClient.put(db_url, "meaningless")
        else
          raise e
        end
      end
      @db_url = db_url
    end

    def url(id)
      self.class.url_db(db_url, id)
    end

    def self.url_db(db_url, id)
      "#{db_url}/#{id}"
    end

    def find_by_id(obj_id)
      # TODO: tim, 2011-5-18: always including attachments=true may be
      # bad. revisit?
      rest_res = RestClient.get(url(obj_id) + "?attachments=true")
      self.class.inflate_object(Yajl::Parser.parse(rest_res, :symbolize_keys => true))
    rescue Exception => e
      raise CouchDBAngry.new(e)
    end

    def self.inflate_object(data)
      raise "#{self.name}\#inflate_object must be defined!"
    end

  end
end
