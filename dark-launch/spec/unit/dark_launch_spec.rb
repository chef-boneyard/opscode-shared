$:.unshift(File.expand_path('../../../lib', __FILE__))
require 'chef/config'
require 'tempfile'
require 'opscode/dark_launch'

describe Opscode::DarkLaunch do
  before(:each) do
    Chef::Log.level = :fatal
    @valid_config_file = Tempfile.new("valid_dark_launch_config")
    @valid_config_file_contents = <<EOM
{
  "feature1":[
    "testorg1",
    "testorg2"
  ]
}
EOM
    @valid_config_file.write @valid_config_file_contents
    @valid_config_file.close
    
    @malformed_config_file = Tempfile.new("malformed_dark_launch_config")
    @malformed_config_file.write <<EOM
{
  "feature1":{
    "testorg1":"true"
  }
}
EOM
    @malformed_config_file.close

    @bad_json_config_file = Tempfile.new("bad_json_dark_launch_config")
    @bad_json_config_file.write <<EOM
this is not JSON
EOM
    @bad_json_config_file.close

    # Reset the cache of features configuration
    Opscode::DarkLaunch.reset_features_config
  end

  after(:each) do
    @valid_config_file.delete
    @bad_json_config_file.delete
    @malformed_config_file.delete
  end

  describe "is_feature_enabled?" do
    it "should return true for an org which is in a properly-formed config file" do
      Chef::Config[:dark_launch_config_filename] = @valid_config_file.path
      Opscode::DarkLaunch.is_feature_enabled?("feature1", "testorg1").should == true
    end

    it "should cache the results of a feature config load after the first call" do
      Chef::Config[:dark_launch_config_filename] = @valid_config_file.path

      IO.should_receive(:read).exactly(1).times.with(@valid_config_file.path).and_return(@valid_config_file_contents)
      Opscode::DarkLaunch.is_feature_enabled?("feature1", "testorg1").should == true
      Opscode::DarkLaunch.is_feature_enabled?("feature1", "testorg1").should == true
    end

    it "should return false with a non-existent config file" do
      Chef::Config[:dark_launch_config_filename] = "/does_not_exist"
      Opscode::DarkLaunch.is_feature_enabled?("feature1", "testorg1").should == false
    end

    it "should return false if Chef::Config[:dark_launch_config_filename] isn't set" do
      Chef::Config.delete(:dark_launch_config_filename)
      Opscode::DarkLaunch.is_feature_enabled?("feature1", "testorg1").should == false
    end

    it "should not spam the log if called repeatedly with a non-existent config file" do
      Chef::Config[:dark_launch_config_filename] = "/does_not_exist"
      Chef::Log.should_receive(:error).at_most(:twice)
      10.times do
        Opscode::DarkLaunch.is_feature_enabled?("feature1", "testorg1").should == false
      end
    end

    it "should return false for an org which is not in a properly-formed config file" do
      Chef::Config[:dark_launch_config_filename] = @valid_config_file.path
      Opscode::DarkLaunch.is_feature_enabled?("feature1", "testorg_notthere").should == false
    end

    it "should return false for a feature not in a properly-formed config file" do
      Chef::Config[:dark_launch_config_filename] = @valid_config_file.path
      Opscode::DarkLaunch.is_feature_enabled?("feature_notthere", "testorg1").should == false
    end

    it "should return false for a feature given an improperly-formed config file" do
      Chef::Config[:dark_launch_config_filename] = @malformed_config_file.path
      Opscode::DarkLaunch.is_feature_enabled?("feature1", "testorg1").should == false
    end

    it "should return false for a feature given an config file containing invalid JSON" do
      Chef::Config[:dark_launch_config_filename] = @bad_json_config_file.path
      Opscode::DarkLaunch.is_feature_enabled?("feature1", "testorg1").should == false
    end
  end
end


