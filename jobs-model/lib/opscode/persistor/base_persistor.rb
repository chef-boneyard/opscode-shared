require 'opscode/job'
require 'uri'
require 'restclient'
require 'yajl'
require 'base64'

# for .to_json on Hash/Array
require 'json'
require 'rest-client'

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
        if e.is_a?(RestClient::ResourceNotFound) && force_create
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

      doc = Yajl::Parser.parse(rest_res, :symbolize_keys => true)
      doc_attachments = Hash.new

      # Handle attachments, which will be base64-encoded.
      if doc[:_attachments]
        doc[:_attachments].keys.each do |attachment_name|
          attachment_base64 = doc[:_attachments][attachment_name][:data]
          doc_attachments[attachment_name] = Base64.decode64(attachment_base64)
        end
        doc.delete(:_attachments)
      end

      self.class.inflate_object(doc, doc_attachments)
    rescue Exception => e
      raise CouchDBAngry.new(e)
    end

    # Saves a new document, or saves over an existing document with
    # the given id. Returns the revision id of the document saved.
    def force_save(docid, hash)
      begin
        # Do a HEAD request and pull out the etag to determine the
        # current rev of the document. Then merge that in with the
        # hash so we can update it.
        #
        # The etag has quotes around it as specified by the RFC.
        # The possibility of getting a "weak" etag is ignored
        current_rev = RestClient.head(url(docid)).headers[:etag][1..-2]
        hash = hash.merge(:_rev => current_rev)
      rescue RestClient::ResourceNotFound
        # New document; don't include _rev.
      end
      put_res_str = RestClient.put(url(docid), hash.to_json)
      put_res = Yajl::Parser.parse(put_res_str)

      # Return the revision of the just-saved document.
      put_res['rev']
    end

    def self.get_design_doc
      raise CouchDBAngry.new("design document not defined for #{self.class}: call #set_design_doc in class body!") unless @design_doc
      @design_doc
    end

    def self.set_design_doc(design_doc)
      @design_doc = design_doc
    end

    # Runs the named view with the named key and returns a list of
    # rows matching.
    #
    # Parameters:
    #   view_name: one of the views defined in set_design_doc
    #   key: string key or nil if no key to be passed
    #
    # Returns:
    #   Array of matching rows, which may be empty.
    #
    # TODO: revisit exceptions. Should only throw CouchDBAngry.
    def execute_view(view_name, key)
      design_url = "#{db_url}/_design/#{self.class.name}"
      view_url = "#{design_url}/_view/#{view_name}?include_docs=true"
      if key
        view_url += "&key=#{URI.encode(key.to_json)}"
      end

      # Try to query the view. If that fails with 404, try to create
      # the view and fetch it again. If that fails, puke.
      begin
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

      # Parse the response from above, and walk over each row,
      # inflating them.
      rest_res = Yajl::Parser.parse(rest_res, :symbolize_keys => true)
      rows = rest_res[:rows]
      rows.map! do |row|
        doc = row[:doc]
        doc_attachments = Hash.new

        # Unfortunately the couch view API doesn't allow
        # 'attachments=true', so we have to walk the attachments
        # manually when they come back from a view. Prepare them in
        # the format that inflate_object will expect.
        if doc[:_attachments]
          doc[:_attachments].each_key do |attachment_key|
            attachment_url = "#{db_url}/#{doc[:_id]}/#{attachment_key}"

            # attachment_data will not be base64-encoded.
            attachment_data = RestClient.get(attachment_url)
            doc_attachments[attachment_key] = attachment_data
          end
        end
        self.class.inflate_object(doc, doc_attachments)
      end
      rows
    end

    # Like #execute_view(view_name, key), but returns the first item
    # returned from the view, or nil if the list was empty.
    def execute_view_single(view_name, key)
      res = execute_view(view_name, key)
      if res.empty?
        nil
      else
        res.first
      end
    end

    # - data is the object itself, a hash table with symbols as keys.
    # - attachments is any attachments associated with the document,
    #   a hash table with symbols as keys.
    def self.inflate_object(data, attachments)
      raise "#{self.name}\#inflate_object must be defined!"
    end

  end
end
