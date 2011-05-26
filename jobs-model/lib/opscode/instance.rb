require 'uuidtools'
require 'pp'

module Opscode
  class Instance

    # instance (cloud server) specific
    attr_reader :instance_id
    attr_reader :public_ipaddress
    attr_reader :public_hostname
    attr_reader :created_at
    attr_reader :chef_log

    # cloud provider specific
    attr_reader :cloud_provider
    attr_reader :cloud_objects

    # chef specific
    attr_reader :node_name
    attr_reader :client_name

    # job-worker/db specific
    attr_reader :db_id
    attr_reader :job_id

    def initialize(instance_data={})
      from_hash(instance_data)
      @cloud_objects ||= {}
      @db_id         ||= ("instance-" + UUIDTools::UUID.random_create.to_s)
      yield self if block_given?
    end

    def report
      out=<<-DANCANTDEFEND
CREATED QS INSTANCE:
instance_id:      #{instance_id}
public_ipaddress: #{public_ipaddress}
public_ipaddress: #{public_ipaddress}
created_at:       #{created_at}

cloud_provider: #{cloud_provider}
cloud_objects:
#{sexy_print(cloud_objects)}

node_name:   #{node_name}
client_name: #{client_name}

db_id:  #{db_id}
job_id: #{job_id}

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
      # from_hash wants the keys to be syms, not strings
      new(hash.inject({}) {|res, (k, v)| res[k.to_sym] = v; res })
    end

    def to_hash
      {
        :_id                  =>  @db_id,
        :instance_id          =>  @instance_id,
        :public_ipaddress     =>  @public_ipaddress,
        :public_hostname      =>  @public_hostname,
        :created_at           =>  @created_at,
        :cloud_provider       =>  @cloud_provider,
        :cloud_objects        =>  @cloud_objects,
        :node_name            =>  @node_name,
        :client_name          =>  @client_name,
        :job_id               =>  @job_id,
        :chef_log             =>  @chef_log
      }
    end

    def from_cloud_server(server)
      @instance_id      = server.id.to_s
      @public_ipaddress = server.public_ip_address
      @public_hostname  = if server.respond_to?(:dns_name)
                            server.dns_name
                          else
                            server.public_ip_address
                          end
      @created_at       = if server.respond_to?(:created_at)
                            server.created_at
                          else
                            Time.now.to_s # todo make this better
                          end
    end

    def from_log(log)
      @chef_log = log
    end

    def from_cloud_provider(provider)
      @cloud_provider = provider
    end

    def from_cloud_objects(objs)
      @cloud_objects = objs
    end

    def from_node_name(name)
      @node_name = name
    end

    def from_client_name(name)
      @client_name = name
    end

    def from_job_id(job_id)
      @job_id = job_id
    end

    def from_db_id(db_id)
      @db_id = db_id
    end

    def ==(rhs)
      # easy way out.
      rhs.kind_of?(self.class) &&
        self.to_hash == rhs.to_hash
    end

    private

    def from_hash(attr_hash)
      @instance_id          = attr_hash[:instance_id]
      @public_ipaddress     = attr_hash[:public_ipaddress]
      @public_hostname      = attr_hash[:public_hostname]
      @created_at           = attr_hash[:created_at]
      @chef_log             = attr_hash[:chef_log]
      @cloud_provider       = attr_hash[:cloud_provider]
      @cloud_objects        = attr_hash[:cloud_objects]
      @node_name            = attr_hash[:node_name]
      @client_name          = attr_hash[:client_name]
      @chef_log             = attr_hash[:chef_log]
      @job_id               = attr_hash[:job_id]
      @db_id                = attr_hash[:_id] # couch_specific
      self
    end

    def sexy_print(obj)
      res = StringIO.new
      PP.pp(obj, res)
      res.string
    end

  end

end
