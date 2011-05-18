require 'couchrest'

module Opscode
  class Instance

    attr_reader :chef_log
    attr_reader :security_group_name
    attr_reader :key_pair_name
    attr_reader :api_client_name
    attr_reader :node_name
    attr_reader :instance_id
    attr_reader :public_hostname
    attr_reader :public_ipaddress
    attr_reader :created_at
    attr_accessor :chef_log

    def initialize(instance_data={})
      from_hash(instance_data)
      yield self if block_given?
    end

    def report
      out=<<-DANCANTDEFEND
CREATED QS NODE:
id: #{instance_id}
node_name: #{node_name}
public_hostname: #{public_hostname}
public_ipaddress: #{public_ipaddress}
key_pair_name: #{key_pair_name}
security_group_name: #{security_group_name}
chef_log:

#{chef_log}
DANCANTDEFEND
    end

    def to_hash
      { :security_group_name  =>  @security_group_name,
        :key_pair_name        =>  @key_pair_name,
        :instance_id          =>  @instance_id,
        :public_hostname      =>  @public_hostname,
        :public_ipaddress     =>  @public_ipaddress,
        :created_at           =>  @created_at,
        :api_client_name      =>  @api_client_name,
        :node_name            =>  @node_name }
    end

    def from_security_group(security_group)
      @security_group_name = security_group.name
    end

    def from_key_pair(key_pair)
      @key_pair_name = key_pair.name
    end

    def from_cloud_server(server)
      @instance_id = server.id
      @public_hostname = server.dns_name
      @public_ipaddress = server.public_ip_address
      @created_at = server.created_at
    end

    def from_api_client(api_client)
      @api_client_name = api_client.name
    end

    def from_node(node)
      @node_name = node.name
    end

    def from_log(log)
      @chef_log = log
    end

    private

    def from_hash(attr_hash)
      @security_group_name  = attr_hash['security_group_name']
      @key_pair_name        = attr_hash['key_pair_name']
      @instance_id          = attr_hash['instance_id']
      @public_hostname      = attr_hash['public_hostname']
      @public_ipaddress     = attr_hash['public_ipaddress']
      @created_at           = attr_hash['created_at']
      @api_client_name      = attr_hash['api_client_name']
      @node_name            = attr_hash['node_name']
      @chef_log             = attr_hash['chef_log']
      self
    end

  end

  # Store an Instance in CouchDB.
  #
  # Uses couch's attachments feature to keep the chef log outside of
  # the primary object in order to relieve some strain from the js
  # view servers.
  class InstancePersistor < CouchRest::ExtendedDocument
    ID = '_id'

    timestamps!

    attr_reader :chef_log

    # Create an InstanceModel object from a instance of class Instance.
    # overrides the normal CouchRest::ExtendedDocument initializer.
    def initialize(couchdb_url, instance_object)
      on(CouchRest::Server.new(couchdb_url))

      # this branch when fetching a doc from the db
      if instance_object.kind_of?(CouchRest::Document)
        self['instance'] = Instance.new(instance_object)
        super(instance_object)

        @chef_log = read_attachment('chef_log')
        instance.chef_log = @chef_log

      else # this branch when creating new doc from data
        self['instance'] = instance_object.to_hash
        @chef_log = instance_object.chef_log
      end
    end

    def db_id
      self[ID]
    end

    def instance
      self['instance']
    end

    def create(*args)
      attach_log
      super
    end

    def save(*args)
      attach_log
      super
    end

    # Adds the (probably pretty large) chef log for the instance to the couchrest
    # document as an attachment.
    #--
    # Have to wrap it in a StringIO because couchrest assumes for some reason that
    # you will only create attachments from files. why, god, why?
    def attach_log
      if new_document?
        create_attachment(:name => 'chef_log', :file => StringIO.new(@chef_log), :content_type => 'text/plain')
      else
        update_attachment(:name => 'chef_log', :file => StringIO.new(@chef_log), :content_type => 'text/plain')
      end
    end

  end

end
