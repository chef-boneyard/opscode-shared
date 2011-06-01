require File.expand_path('../../spec_helper', __FILE__)
require 'chef/api_client'
require 'chef/node'
require 'couchrest'
require 'base64'


describe Instance do

  before(:each) do
    UUIDTools::UUID.stub!(:random_create) { "UUID-UUID" }
  end

  describe "when initialized with nothing" do
    before(:each) do
      @instance = Instance.new
    end

    it "has an id" do
      @instance.db_id.should == "instance-UUID-UUID"
    end

    it "has an empty hash of cloud objects" do
      @instance.cloud_objects.should == {}
    end
  end

  shared_examples_for "a fully created instance object" do
    it "has a database id" do
      @instance.db_id.should == 'instance-ID'
    end

    it "has a job id" do
      @instance.job_id.should == 'job-ID'
    end

    it "has a cloud instance id" do
      @instance.instance_id.should == 'i-42'
    end

    it "has a public ip address" do
      @instance.public_ipaddress.should == '1.2.3.4'
    end

    it "has a public hostname" do
      @instance.public_hostname.should == '1-2-3-4.dns.com'
    end

    it "has a creation time" do
      @instance.created_at.should == 'A long time ago'
    end

    it "has a chef log" do
      @instance.chef_log.should == 'I am a log'
    end

    it "specifies a cloud provider" do
      @instance.cloud_provider.should == 'AWS'
    end

    it "has cloud-provider-specific objects" do
      @instance.cloud_objects.should == {
        :security_group => 'sg-id',
        :key_pair => 'kp-id'
      }
    end

    it "has a node name" do
      @instance.node_name.should == 'i-42'
    end

    it "has a chef client name" do
      @instance.client_name.should == 'i-42'
    end
  end

  describe "when initialized with a hash" do
    before(:each) do
      @inst_data = {
        :_id => 'instance-ID',
        :job_id => 'job-ID',
        :instance_id => 'i-42',
        :public_ipaddress => '1.2.3.4',
        :public_hostname => '1-2-3-4.dns.com',
        :created_at => 'A long time ago',
        :chef_log => Base64.encode64('I am a log'),
        :cloud_provider => 'AWS',
        :cloud_objects => {
          :security_group => 'sg-id',
          :key_pair => 'kp-id'
        },
        :node_name => 'i-42',
        :client_name => 'i-42'
      }
      @instance = Instance.new(@inst_data)
    end
    
    it_behaves_like "a fully created instance object"
  end

  describe "when initialized with a block" do
    before(:each) do
      server_mocks = {
        :id => 'i-42',
        :public_ip_address => '1.2.3.4',
        :dns_name => '1-2-3-4.dns.com',
        :created_at => 'A long time ago'
      }
      server = mock('cloud-server', server_mocks)

      cloud_objects = {
        :key_pair => 'kp-id',
        :security_group => 'sg-id'
      }

      @instance = Instance.new do |i|
        i.from_db_id('instance-ID')
        i.from_job_id('job-ID')
        i.from_cloud_server(server)
        i.from_log('I am a log')
        i.from_cloud_provider('AWS')
        i.from_cloud_objects(cloud_objects)
        i.from_node_name('i-42')
        i.from_client_name('i-42')
      end
    end

    it_behaves_like "a fully created instance object"
  end

  describe "when initialized" do
    before(:each) do
      @instance = Instance.new
    end

    it "loads cloud server data from AWS servers" do
      mocks = {
        :id => 'i-42',
        :public_ip_address => '1.2.3.4',
        :dns_name => '1-2-3-4.dns.com',
        :created_at => 'Time to kill',
      }
      server = mock('aws-server', mocks)
      @instance.from_cloud_server(server)
      @instance.instance_id.should == 'i-42'
      @instance.public_ipaddress.should == '1.2.3.4'
      @instance.public_hostname.should == '1-2-3-4.dns.com'
      @instance.created_at.should == 'Time to kill'
    end

    it "loads cloud server data from Rackspace servers" do
      Time.stub!(:now) { 10101010 }
      mocks = {
        :id => 12345,
        :public_ip_address => '1.2.3.4'
      }
      server = mock('rs-server', mocks)
      @instance.from_cloud_server(server)
      @instance.instance_id.should == '12345'
      @instance.public_ipaddress.should == '1.2.3.4'
      @instance.public_hostname.should == '1.2.3.4'
      @instance.created_at.should == '10101010'
    end

    it "lets you set cloud objects at will" do
      @instance.cloud_objects[:pie_in_the_sky] = "yummy"
      @instance.cloud_objects[:pie_in_the_sky].should == "yummy"
    end
  end

end
