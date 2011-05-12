$:.unshift(File.expand_path('../../../lib/', __FILE__))
require 'opscode/job'

describe Opscode::Job do
  before(:each) do
    # Time.at/to_i to round down to closest second.
    @time_now = Time.at(Time.now.to_i)
    @task_args = ({ :task_id => "task-123",
                    :data => "some_data",
                    :type => "test_type" })
    @job_args = ({ :job_id => "job-test123",
                   :tasks => [Opscode::Task.new(@task_args)],
                   :created_at => @time_now,
                   :updated_at => @time_now,
                   :username => "test_username",
                   :orgname => "test_orgname" })
    @job = Opscode::Job.new(@job_args)

    @job_hash = {
      "_id" => "job-test123",
      "tasks" => [{ "task-id" => "task-123",
                    "data" => "some_data",
                    "type" => "test_type" }],
      "created_at" => @time_now.to_i,
      "updated_at" => @time_now.to_i,
      "username" => "test_username",
      "orgname" => "test_orgname"
    }
  end

  describe "the ruby language works" do
    it "should respond to its public API" do
      @job.job_id.should == "job-test123"
      @job.created_at.should == @time_now
      @job.updated_at.should == @time_now
      @job.username.should == "test_username"
      @job.orgname.should == "test_orgname"

      @job.tasks.length.should == 1
      @job.tasks[0].task_id.should == "task-123"
    end
  end

  describe "==" do
    it "should return equal for reflexive equals" do
      @job.should == @job
    end

    it "should return equal for equivalent equals" do
      job2 = Opscode::Job.new(@job_args)
      @job.should == job2
    end

    it "should return not equal for different jobs: job_id" do
      job2 = Opscode::Job.new(@job_args.merge(:job_id => "different_jobid"))
      @job.should_not == job2
    end

    it "should return not equal for different jobs: created_at" do
      job2 = Opscode::Job.new(@job_args.merge(:created_at => Time.at(0)))
      @job.should_not == job2
    end

    it "should return not equal for different Jobs: updated_at" do
      job2 = Opscode::Job.new(@job_args.merge(:updated_at => Time.at(0)))
      @job.should_not == job2
    end

    it "should return not equal for different Jobs: username" do
      job2 = Opscode::Job.new(@job_args.merge(:username => "different_username"))
      @job.should_not == job2
    end
    
    it "should return not equal for different Jobs: orgname" do
      job2 = Opscode::Job.new(@job_args.merge(:orgname => "different_orgname"))
      @job.should_not == job2
    end

    it "should return not equal for different Jobs: tasks number" do
      job2 = Opscode::Job.new(@job_args.merge(:tasks => []))

      @job.should_not == job2
    end

    it "should return not equal for different Jobs: tasks content" do
      task = Opscode::Task.new(@task_args.merge(:task_id => "different_taskid"))
      job2 = Opscode::Job.new(@job_args.merge(:tasks => [task]))
      @job.should_not == job2
    end
  end

  describe "initialize" do
    it "should throw argument error with non-Array tasks" do
      lambda {
        Opscode::Job.new(@job_args.merge(:tasks => "this is not an array"))
      }.should raise_error(ArgumentError)
    end

    it "should throw argument error with tasks Array containing non-Tasks" do
      lambda {
        Opscode::Job.new(@job_args.merge(:tasks => ["this is not an array"]))
      }.should raise_error(ArgumentError)
    end

    it "should throw argument error with non-Time created_at" do
      lambda {
        Opscode::Job.new(@job_args.merge(:created_at => "this is not a Time"))
      }.should raise_error(ArgumentError)
    end

    it "should throw argument error with non-Time updated_at" do
      lambda {
        Opscode::Job.new(@job_args.merge(:updated_at => "this is not a Time"))
      }.should raise_error(ArgumentError)
    end
  end

  describe "serialization" do
    it "should serialize to and back from a hash and be equal" do
      fromhash_job = Opscode::Job.json_create(@job.to_hash)
      fromhash_job.job_id.should == @job.job_id
      fromhash_job.created_at.should == @job.created_at
      fromhash_job.updated_at.should == @job.updated_at
      fromhash_job.username.should == @job.username
      fromhash_job.orgname.should == @job.orgname
      fromhash_job.tasks.should == @job.tasks

      fromhash_job.should == @job
    end
  end
end
