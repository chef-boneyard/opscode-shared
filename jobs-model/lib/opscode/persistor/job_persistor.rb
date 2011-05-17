require 'opscode/job'
require 'uri'
require 'restclient'
require 'yajl'

module Opscode::Persistor
  class ConfigurationError < ArgumentError
  end

  class ConfigureTheDatabase < ConfigurationError
  end

  class CouchDBAngry < RuntimeError
    attr_reader :caused_by
    def initialize(caused_by)
      super(caused_by.message)
      @caused_by = caused_by
      set_backtrace(caused_by.backtrace)
    end
  end

  # Puts job objects in the database and gets them out.
  #--
  # I guess this is actually a mapper according to PoEAA but that book is
  # written in java and therefore irrelevant.
  class JobPersistor

    # Configures this class for the database uri to use.
    def self.use_database(db_uri)
      RestClient.get(db_uri)
      @db_uri = db_uri
    end

    def self.database!(db_uri)
      use_database(db_uri)
    rescue RestClient::ResourceNotFound
      RestClient.put(db_uri, "FUUU")
      @db_uri = db_uri
    end

    def self.db_uri
      @db_uri || raise(ConfigureTheDatabase, "#{self.name}.use_database('http://HOST:5984/DB_NAME') <- try it.")
    end

    def self.uri_for(id)
      File.join(db_uri, id)
    end

    def self.find_by_id(job_id)
      inflate_object(Yajl::Parser.parse(RestClient.get(uri_for(job_id)), :symbolize_keys => true))
    rescue Exception => e
      raise CouchDBAngry.new(e)
    end

    def self.inflate_object(data)
      job_spec = data
      job_spec[:tasks].map! {|t| Opscode::Task.new(t)}
      job_spec[:created_at] = Time.at(job_spec[:created_at])
      job_spec[:updated_at] = Time.at(job_spec[:updated_at])
      job_spec.merge!(:job_id => data[:'_id'])
      Opscode::Job.new(job_spec)
    end

    class << self
      alias :public_static_final_void_beige :find_by_id # for use by tim
    end

    attr_reader :rev

    def initialize(job)
      @job = job
    end

    def id
      @job.job_id
    end

    def create
      RestClient.put(uri, @job.to_json) && @job
    rescue Exception => e
      raise CouchDBAngry.new(e)
    end

    def db_uri
      self.class.db_uri
    end

    def uri
      @uri ||= File.join(db_uri, id).to_s
    end

    def dbclient
      self.class.dbclient
    end

  end
end
