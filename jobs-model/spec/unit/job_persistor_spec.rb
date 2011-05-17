require File.expand_path('../../spec_helper', __FILE__)

require 'uuidtools'

describe JobPersistor do
  before(:all) do
    begin
      RestClient.put('http://localhost:5984/jobs_spec', "FUUUUU")
    rescue RestClient::PreconditionFailed
    end
  end

  before do
    JobPersistor.use_database('http://localhost:5984/jobs_spec')
    @task0 = Opscode::Task.new(:type => 'trolling', :data => 'troll tim')
    @task1 = Opscode::Task.new(:type => 'lol', :data => 'trolol')
    @job = Opscode::Job.new(:tasks => [@task0, @task1], :username => 'moonpolysoft', :orgname => 'theinternet')
    @persistor = JobPersistor.new(@job)
  end

  it "has the database URI configured" do
    JobPersistor.db_uri.should == 'http://localhost:5984/jobs_spec'
    @persistor.db_uri.should == 'http://localhost:5984/jobs_spec'
  end

  it "generates the uri for the object" do
    @persistor.uri.should == "http://localhost:5984/jobs_spec/#{@job.job_id}"
  end

  it "stores items in the database" do
    @persistor.create
    doc = Yajl::Parser.parse RestClient.get("http://localhost:5984/jobs_spec/#{@job.job_id}")
    doc['_id'].should == @job.job_id
    doc["_rev"].should_not be_nil
    doc["tasks"].should have(2).items
    doc['created_at'].should == @job.created_at.to_i
    doc['updated_at'].should == @job.updated_at.to_i
  end

  describe "when the object fails to save" do
    before do
      JobPersistor.instance_variable_set(:@db_uri, "http://localhost:5984/trololololol")
    end

    it "raises a single exception class so it doesn't take 9000 hours to figure out which exceptions to catch" do
      lambda {@persistor.create}.should raise_error(CouchDBAngry)
    end

    it "embeds the causing exception in the specific exception" do
      begin
        @persistor.create
      rescue => e
        e.caused_by.should be_a_kind_of(RestClient::ResourceNotFound)
      end
    end
  end

  describe "after a job has been stored in the database" do
    before do
      @persistor.create
    end

    it "can fetch the item by id" do
      JobPersistor.find_by_id(@job.job_id).should == @job
    end
  end

end
