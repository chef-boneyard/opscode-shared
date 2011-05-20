require File.expand_path('../../spec_helper', __FILE__)

require 'uuidtools'

describe JobPersistor do
  before(:all) do
    begin
      RestClient.delete('http://localhost:5984/jobs_spec')
    rescue RestClient::ResourceNotFound
    end

    begin
      RestClient.put('http://localhost:5984/jobs_spec', "FUUUUU")
    rescue RestClient::PreconditionFailed
    end
  end

  before do
    @task0 = Opscode::Task.new(:type => 'trolling', :data => 'troll tim')
    @task1 = Opscode::Task.new(:type => 'lol', :data => 'trolol')
    @job = Opscode::Job.new(:tasks => [@task0, @task1], :username => 'moonpolysoft', :orgname => 'theinternet')
    @persistor = JobPersistor.new('http://localhost:5984/jobs_spec')
  end

  it "has the database URL configured" do
    @persistor.db_url.should == 'http://localhost:5984/jobs_spec'
  end

  it "generates the url for the object" do
    @persistor.url(@job.job_id).should == "http://localhost:5984/jobs_spec/#{@job.job_id}"
  end

  it "stores items in the database" do
    @persistor.save(@job)

    doc = Yajl::Parser.parse RestClient.get("http://localhost:5984/jobs_spec/#{@job.job_id}")
    doc['_id'].should == @job.job_id
    doc["_rev"].should_not be_nil
    doc["tasks"].should have(2).items
    doc['created_at'].should == @job.created_at.iso8601
    doc['updated_at'].should == @job.updated_at.iso8601
  end

  describe "when the object fails to save" do
    before do
      @persistor.instance_variable_set(:@db_url, "http://localhost:5984/trololololol")
    end

    it "raises a single exception class so it doesn't take 9000 hours to figure out which exceptions to catch" do
      lambda {@persistor.save(@job)}.should raise_error(CouchDBAngry)
    end

    it "embeds the causing exception in the specific exception" do
      begin
        @persistor.save(@job)
      rescue => e
        e.caused_by.should be_a_kind_of(RestClient::ResourceNotFound)
      end
    end
  end

  describe "after a job has been stored in the database" do
    before do
      @persistor.save(@job)
    end

    it "can find a job by id" do
      @persistor.find_by_id(@job.job_id).should == @job
    end

    it "can find a job by orgname" do
      # save a different job with a different orgname so we're sure
      # there's just one.
      job = Job.new(:orgname => "adifferentorg", :tasks => @tasks)
      @persistor.save(job)

      results = @persistor.find_by_orgname("adifferentorg")
      results.length.should == 1
      results.first.should == job
    end

    it "can find all jobs" do
      new_job_url = "http://localhost:5984/jobs_spec_findall"
      recreate_db(new_job_url)
      @persistor = JobPersistor.new(new_job_url)
      @persistor.save(@job)

      # should only be one
      results = @persistor.find_all()
      results.length.should == 1
      results.first.should == @job
    end

    it "can save it again and again" do
      @persistor.save(@job)
      @persistor.save(@job)
    end

    it "when saving, gets a new revision" do
      get_rev = lambda {
        # The etag (or _rev of the document) is JSON-encoded. Rly?
        headers = RestClient.head("http://localhost:5984/jobs_spec/#{@job.job_id}").headers
        Yajl::Parser.parse(headers[:etag])
      }

      first_rev = get_rev.call
      @persistor.save(@job)
      second_rev = get_rev.call
      first_rev.should_not == second_rev
    end
  end

end
