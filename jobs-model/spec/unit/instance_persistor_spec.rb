require File.expand_path('../../spec_helper', __FILE__)

describe InstancePersistor do
  before do
    recreate_db("http://localhost:5984/instance_spec")

    @instance_persistor = InstancePersistor.new("http://localhost:5984/instance_spec")

    @instance = Instance.new({
                               :_id => 'instance-ID',
                               :job_id => 'job-ID',
                               :instance_id => 'i-42',
                               :public_ipaddress => '1.2.3.4',
                               :public_hostname => '1-2-3-4.dns.com',
                               :created_at => 'A long time ago',
                               :chef_log => 'I am a log',
                               :cloud_provider => 'AWS',
                               :cloud_objects => {
                                 :security_group => 'sg-id',
                                 :key_pair => 'kp-id'
                               },
                               :node_name => 'i-42',
                               :client_name => 'i-42'
                             })

    @instance2 = Instance.new({
                                :_id => 'instance-ID2',
                                :job_id => 'job-ID2',
                                :instance_id => 'i-43',
                                :public_ipaddress => '1.2.3.5',
                                :public_hostname => '1-2-3-5.dns.com',
                                :created_at => 'A longer time ago',
                                :chef_log => 'I am a longer log',
                                :cloud_provider => 'AWS',
                                :cloud_objects => {
                                  :security_group => 'sg-id2',
                                  :key_pair => 'kp-id2'
                                },
                                :node_name => 'i-43',
                                :client_name => 'i-43'
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

    # fetching documents by job_id doens't return the chef_log attachment, nor do we want it to
    # this could be a more robust test by checking fields other than the instance_id and job_id
    instances1 = @instance_persistor.find_by_job_id('job-fetch-1')
    instances1.length.should == 1
    inst = instances1.first
    inst.instance_id.should == instance1.instance_id
    inst.job_id.should == instance1.job_id

    instances2 = @instance_persistor.find_by_job_id('job-fetch-2')
    instances2.length.should == 1
    inst = instances2.first
    inst.instance_id.should == instance2.instance_id
    inst.job_id.should == instance2.job_id
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
