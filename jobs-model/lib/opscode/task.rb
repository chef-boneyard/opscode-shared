module Opscode
  class Task
    attr_reader :task_id
    attr_reader :type
    attr_reader :data # task-specfic

    def initialize(hash)
      @task_id = hash[:task_id] || ("task-" + UUIDTools::UUID.random_create.to_s)
      @type = hash[:type]
      @data = hash[:data] || Hash.new

      raise ArgumentError, "Task: type must be set" unless @type
    end

    def self.json_create(hash)
      Task.new(:task_id => hash['task_id'],
               :type => hash['type'],
               :data => hash['data'])
    end

    def to_json(*args)
      result = {
        "task_id" => task_id,
        "type" => type,
        "data" => data,
        #"json_class" => self.class.name TODO tim 2011-5-11
      }
      result.to_json(*args)
    end
  end
end
