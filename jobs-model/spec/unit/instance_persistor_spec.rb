require File.expand_path('../../spec_helper', __FILE__)

describe InstancePersistor do
  before do
    recreate_db("http://localhost:5984/instance_spec")

    @instance_persistor = InstancePersistor.new("http://localhost:5984/instance_spec")

    @instance = Instance.new({
                               :security_group_name => 'example-sg',
                               :key_pair_name => 'skynet-governator-qs-12345-kp',
                               :api_client_name => 'i-42',
                               :node_name => 'i-42',
                               :instance_id => 'i-42',
                               :public_hostname => 'ec2-123-45-67-89.compute-1.amazonaws.com',
                               :public_ipaddress => '123.45.67.89',
                               :created_at => '2011-05-10 20:15:47 UTC',
                               :chef_log => 'built yer infrastructure yo.',
                               :job_id => 'job-1234'
                             })

    @instance2 = Instance.new({
                                :security_group_name => 'example-sg',
                                :key_pair_name => 'skynet-governator-qs-12345-kp',
                                :api_client_name => 'i-42',
                                :node_name => 'i-42',
                                :instance_id => 'i-42',
                                :public_hostname => 'ec2-123-45-67-89.compute-1.amazonaws.com',
                                :public_ipaddress => '123.45.67.89',
                                :created_at => '2011-05-10 20:15:47 UTC',
                                :chef_log => 'built yer infrastructure yo.',
                                :job_id => 'job-2345'
                              })
  end

  it "can retrieve the instance by its id" do
    @instance_persistor.save(@instance)
    retrieved_instance = @instance_persistor.find_by_id(@instance.db_id)
    @instance.should == retrieved_instance
  end

  it "can save more than once" do
    @instance_persistor.save(@instance)
    @instance_persistor.save(@instance)
  end

  it "can fetch documents by job_id" do
    # save these new docs with different job id's than @instance, as
    # there will be many of those (however many steps are enclosed
    # in this 'describe' block)
    instance1 = Instance.new(@instance.to_hash.merge(:_id => "instance-job-fetch-1", :job_id => "job-fetch-1"))
    @instance_persistor.save(instance1)
    instance2 = Instance.new(@instance.to_hash.merge(:_id => "instance-job-fetch-2", :job_id => "job-fetch-2"))
    @instance_persistor.save(instance2)

    jobs1 = @instance_persistor.find_by_job_id('job-fetch-1')
    jobs1.length.should == 1
    jobs1.first.should == instance1

    jobs2 = @instance_persistor.find_by_job_id('job-fetch-2')
    jobs2.length.should == 1
    jobs2.first.should == instance2
  end

  it "can fetch documents by instance_id: #find_by_instance_id positive" do
    @instance_persistor.save(@instance)

    @instance_persistor.find_by_instance_id('i-42').should == @instance
  end

  it "will return nil if a non-existing instance_id is fetched: #find_by_instance_id negative" do
    @instance_persistor.find_by_instance_id('nonesuch').should == nil
  end

  it "can fetch all instances" do
    @instance_persistor.save(@instance)
    @instance_persistor.save(@instance2)
    @instance_persistor.find_all().length.should == 2
  end

end
