require 'opscode/job'
require 'uri'
require 'restclient'
require 'yajl'

# for .to_json on Hash/Array
require 'json'

module Opscode::Persistor
  class CouchDBAngry < RuntimeError
    attr_reader :caused_by
    def initialize(caused_by)
      @caused_by = caused_by
      if caused_by.respond_to?(:message)
        super(caused_by.message)
        set_backtrace(caused_by.backtrace)
      else
        super(caused_by)
      end
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

    # Saves a new document, or saves over an existing document with
    # the given id. Returns the revision id of the document saved.
    def force_save(docid, hash)
      begin
        # Do a HEAD request and pull out the etag to determine the
        # current rev of the document. Then merge that in with the
        # hash so we can update it. The etag has quotes around it, so
        # is encoded as a JSON value.
        current_rev_str = RestClient.head(url(docid)).headers[:etag]
        current_rev = Yajl::Parser.parse(current_rev_str)
        hash = hash.merge(:_rev => current_rev)
      rescue RestClient::ResourceNotFound
        # New document; don't include _rev.
      end
      put_res_str = RestClient.put(url(docid), hash.to_json)
      put_res = Yajl::Parser.parse(put_res_str)

      # return the revision of the new document.
      put_res['rev']
    end

    def self.get_design_doc
      raise CouchDBAngry.new("design document not defined for #{self.class}: call #set_design_doc in class body!") unless @design_doc
      @design_doc
    end

    def self.set_design_doc(design_doc)
      @design_doc = design_doc
    end
    
    def execute_view(view_name, key)
      design_url = "#{db_url}/_design/#{self.class.name}"
      view_url = "#{design_url}/_view/#{view_name}?include_docs=true"
      if key
        view_url += "&key=#{URI.encode(key.to_json)}"
      end

      begin
        #puts "view_url = #{view_url}"
        rest_res = RestClient.get(view_url)
      rescue RestClient::ResourceNotFound => rnfx
        design_doc = self.class.get_design_doc
        RestClient.put(design_url, design_doc)

        begin
          rest_res = RestClient.get(view_url)
        rescue => e
          raise CouchDBAngry.new(e)
        end
      end

      rest_res = Yajl::Parser.parse(rest_res, :symbolize_keys => true)
      rows = rest_res[:rows]
      rows.map! { |row| self.class.inflate_object(row[:doc]) }
      rows
    end

    # Gets passed a hash table with symbols as keys.
    def self.inflate_object(data)
      raise "#{self.name}\#inflate_object must be defined!"
    end

  end
end
