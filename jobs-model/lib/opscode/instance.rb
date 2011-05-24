require 'uuidtools'

module Opscode
  class Instance

    attr_reader :db_id
    attr_reader :job_id
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
      @db_id ||= ("instance-" + UUIDTools::UUID.random_create.to_s)
      yield self if block_given?
    end

    def report
      out=<<-DANCANTDEFEND
CREATED QS NODE:
db_id: #{db_id}
instance_id: #{instance_id}
job_id: #{job_id}
node_name: #{node_name}
public_hostname: #{public_hostname}
public_ipaddress: #{public_ipaddress}
key_pair_name: #{key_pair_name}
security_group_name: #{security_group_name}
chef_log:

#{chef_log}
DANCANTDEFEND
    end

    def to_json(*args)
      data = to_hash
      data['json_class'] = self.class.name
      data.to_json(*args)
    end

    def self.json_create(hash)
      new(hash)
    end

    def to_hash
      {
        :security_group_name  =>  @security_group_name,
        :key_pair_name        =>  @key_pair_name,
        :instance_id          =>  @instance_id,
        :public_hostname      =>  @public_hostname,
        :public_ipaddress     =>  @public_ipaddress,
        :created_at           =>  @created_at,
        :api_client_name      =>  @api_client_name,
        :node_name            =>  @node_name,
        :job_id               =>  @job_id,
        :_id                  =>  @db_id
      }
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

    def from_job_id(job_id)
      @job_id = job_id
    end

    private

    def from_hash(attr_hash)
      @security_group_name  = attr_hash[:security_group_name]
      @key_pair_name        = attr_hash[:key_pair_name]
      @instance_id          = attr_hash[:instance_id]
      @public_hostname      = attr_hash[:public_hostname]
      @public_ipaddress     = attr_hash[:public_ipaddress]
      @created_at           = attr_hash[:created_at]
      @api_client_name      = attr_hash[:api_client_name]
      @node_name            = attr_hash[:node_name]
      @chef_log             = attr_hash[:chef_log]
      @job_id               = attr_hash[:job_id]

      # couch-specific stuff.
      @db_id                = attr_hash[:_id]
      self
    end

    def ==(rhs)
      # easy way out.
      rhs.kind_of?(self.class) &&
        self.to_hash == rhs.to_hash
    end

  end

end
