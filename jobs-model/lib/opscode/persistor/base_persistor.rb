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

    # == find_by_id
    # fetch a document by id
    #
    # Parameters:
    #   obj_id:  the ID of the document in the database
    #   options: a ::Hash of options to pass to CouchDB i.e.
    #     * attachments    - fetch all attachments for the doc
    #                        default: true
    #
    # Returns: An inflated object or nil (if not found)
    def find_by_id(obj_id, options = {})
      default_options = {
        "attachments" => true
      }

      options = default_options.merge(options)

      url = url(obj_id) << options_string(options)
      rest_res = RestClient.get(url)

      doc = Yajl::Parser.parse(rest_res, :symbolize_keys => true)

      if options["attachments"]
        attachments = decode_attachments(doc[:_attachments])
        doc.delete(:_attachments)
      end

      self.class.inflate_object(doc, attachments)
    rescue RestClient::ResourceNotFound => rnf
      nil
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
    #   key:
    #     * ::String - key to get
    #     * ::Array  - array of keys for a bulk view
    #     * ::nil    - no key - all docs in view
    #   options: a ::Hash of options to pass to CouchDB
    #     * include_docs      - tell CouchDB to include the
    #                           documents in the response
    #                           default: true
    #     * attachments       - include attachments in response.
    #                           CouchDB doesn't support this, but
    #                           specifying it lets the method know
    #                           that we should fake it
    #
    # Returns:
    #   Array of matching rows, which may be empty.
    #
    # TODO: revisit exceptions. Should only throw CouchDBAngry.
    def execute_view(view_name, key, options={})
      default_options = {
        "include_docs" => true
      }

      options = default_options.merge(options)

      design_url = "#{db_url}/_design/#{self.class.name}"
      view_url = "#{design_url}/_view/#{view_name}"

      # TODO: make include_docs an option
      options["include_docs"] = true

      method, params = if key.is_a?(String)   # get one key
                         options["key"] = key
                         [:get, []]
                       elsif key.is_a?(Array) # bulk view
                         [:post, [{:keys => key}.to_json, {"Content-Type" => "application/json"}]]
                       else                   # all the docs in a view
                         [:get, []]
                       end

      view_url << options_string(options)

      resource = RestClient::Resource.new(view_url)

      # Try to query the view. If that fails with 404, try to create
      # the view and fetch it again. If that fails, puke.
      rest_res = begin
                   resource.send(method, *params)
                 rescue RestClient::ResourceNotFound => rnfx
                   design_doc = self.class.get_design_doc
                   RestClient.put(design_url, design_doc)

                   begin
                     resource.send(method, *params)
                   rescue => e
                     raise CouchDBAngry.new(e)
                   end
                 end

      rest_res = Yajl::Parser.parse(rest_res, :symbolize_keys => true)
      rows = rest_res[:rows]

      # if include_docs = true, inflate the rows
      if options["include_docs"]
        rows.map! do |row|
          doc = row[:doc]

          # TODO: DON'T DO THIS!
          # We shouldn't be doing this here.
          #
          # The only time we specify attachments=true to
          # a view is when we fetch an instance by its
          # cloud instance id. Let's not do that. Let's fetch
          # individual instance by the unique id that we
          # create for them so that we can use the built-in
          # attachments=true ability of CouchDB
          # Anyways... here goes nothing
          # [stephen 6/1/11]
          if options["attachments"] && doc[:_attachments]
            attachments = doc[:_attachments].inject({}) do |res, (key, value)|
              attachment_url = "#{db_url}/#{doc[:_id]}/#{key}"
              res[key] = RestClient.get(attachment_url) # response is not base64 encoded
              res
            end
          end

          self.class.inflate_object(doc, attachments)
        end
      end

      rows
    end

    # Like #execute_view(view_name, key), but returns the first item
    # returned from the view, or nil if the list was empty.
    def execute_view_single(view_name, key, options={})
      res = execute_view(view_name, key, options)
      if res.empty?
        nil
      else
        res.first
      end
    end

    # - data is the object itself, a hash table with symbols as keys.
    def self.inflate_object(data, attachments)
      raise "#{self.name}\#inflate_object must be defined!"
    end

    private

    def options_string(options)
      s = ""
      s << "?" if options.length != 0
      s << options.map { |k,v| "#{k}=#{URI.escape(v.to_json)}"}.join('&')
    end

    def decode_attachments(attachments)
      if attachments
        attachments.inject({}) do |res, (name, value)|
          res[name] = Base64.decode64(value[:data])
          res
        end
      else
        Hash.new
      end
    end

  end
end
