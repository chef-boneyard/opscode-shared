require 'opscode/task'
require 'uuidtools'

module Opscode
  class Job
    attr_reader :job_id
    attr_accessor :status
    attr_reader :tasks
    attr_reader :cloud_credentials
    attr_reader :created_at  # Time
    attr_reader :updated_at  # Time

    attr_reader :username
    attr_reader :orgname

    # orgdb has to get set from service side after creation
    attr_accessor :orgdb

    # TODO tim 2011-5-11: "id" instead of job_id/task_id?
    # TODO tim 2011-5-19: move into from_hash, consolidate.

    # status is updatable
    attr_accessor :status

    def initialize(hash)
      @job_id = hash[:job_id] || ("job-" + UUIDTools::UUID.random_create.to_s)
      @tasks = hash[:tasks] || Array.new
      @cloud_credentials = hash[:cloud_credentials]
      @created_at = hash[:created_at] || Time.now
      @updated_at = hash[:updated_at] || Time.now
      @username = hash[:username]
      @orgname = hash[:orgname]
      @orgdb = hash[:orgdb]
      @status = hash[:status]

      # TODO tim 2011-5-11: duck-typing for these checks?
      raise ArgumentError, "Job: tasks must be an Array: #{@tasks.class}" unless @tasks.kind_of?(Array)
      raise ArgumentError, "Job: tasks must be an Array of Tasks" unless @tasks.select {|o| o.kind_of?(Task)}.length == @tasks.length
      raise ArgumentError, "Job: created_at must be a Time: #{@created_at.class}" unless @created_at.kind_of?(Time)
      raise ArgumentError, "Job: updated_at must be a Time: #{@updated_at.class}" unless @updated_at.kind_of?(Time)

      # created_at and updated_at are rounded down to nearest second.
      @created_at = Time.at(@created_at.to_i)
      @updated_at = Time.at(@updated_at.to_i)
    end

    def updated!
      @updated_at = Time.at(Time.now.to_i)
    end

    def ==(rhs)
      rhs.kind_of?(self.class) &&
        job_id == rhs.job_id &&
        tasks == rhs.tasks &&
        cloud_credentials == rhs.cloud_credentials &&
        created_at == rhs.created_at &&
        updated_at == rhs.updated_at &&
        username == rhs.username &&
        orgname == rhs.orgname &&
        orgdb == rhs.orgdb &&
        status == rhs.status
    end

    def self.json_create(hash)
      from_hash(hash)
    end

    def self.from_hash(hash)
      # convert array of hashes to array of Task's if needed.
      if hash['tasks'] && hash['tasks'].kind_of?(Array)
        tasks = Array.new
        hash['tasks'].each do |task|
          if task.kind_of?(Opscode::Task)
            tasks << task
          else
            tasks << Task.json_create(task)
          end
        end
      else
        tasks = hash['tasks'] || Array.new
      end

      created_at = hash['created_at']
      updated_at = hash['updated_at']
      Job.new(:job_id => hash['_id'],
              :tasks => tasks,
              :cloud_credentials => hash['cloud_credentials'],
              :created_at => created_at ? Time.parse(created_at) : Time.now,
              :updated_at => updated_at ? Time.parse(updated_at) : Time.now,
              :username => hash['username'],
              :orgname => hash['orgname'],
              :orgdb => hash['orgdb'],
              :status => hash['status'])
    end

    def to_json(*args)
      to_hash.to_json(*args)
    end

    def to_hash
      {
        "_id" => job_id,
        "tasks" => tasks,
        "cloud_credentials" => cloud_credentials,
        "created_at" => created_at.iso8601,
        "updated_at" => updated_at.iso8601,
        "username" => username,
        "orgname" => orgname,
        "orgdb" => orgdb,
        "status" => status
      }
    end
  end
end
