$:.unshift(File.expand_path('../../../lib', __FILE__))
require 'opscode/x_dark_launch'

describe Opscode::XDarkLaunch do
  class FakeDarklaunchController
    include Opscode::XDarkLaunch
  end

  let(:controller)          { FakeDarklaunchController.new.tap { |c| c.stub!(:raw_headers).and_return(headers) } }
  let(:headers)             { { Opscode::X_DARKLAUNCH_HEADER => encoded_features } }
  let(:encoded_features)    { darklaunch_features.to_a.map { |k,v| "#{k}=#{v}" }.join(';') }
  let(:darklaunch_features) { fail "Define let(:darklaunch_features)" }

  def self.when_feature_is(description, _features = {}, &examples)
    context "when feature is #{description}" do
      let(:darklaunch_features) { _features }
      it { instance_eval(&examples) }
    end
  end

  def self.feature; 'key' end
  let(:feature) { self.class.feature }

  describe "#x_darklaunch_enabled?" do
    subject { controller.x_darklaunch_enabled? feature }

    when_feature_is 'enabled',  { feature => 1 }   { should be_true }
    when_feature_is 'disabled', { feature => 0 }   { should be_false }

    context 'when feature is nil' do
      let(:darklaunch_features) { { feature => nil } }
      let(:darklaunch_fallback_response) { double('fallback_response') }

      it 'should fallback to DarkLaunch' do
        Opscode::DarkLaunch.should_receive(:is_feature_enabled?).with(feature, nil).and_return(darklaunch_fallback_response)
        should be darklaunch_fallback_response
      end
    end


    context 'when X-Ops-Darklaunch is corrupted' do
      let(:feature) { 'key' }

      def self.should_not_raise_error_with(_encoded_features)
        context "with #{_encoded_features.inspect}" do
          let(:encoded_features) { _encoded_features }
          it { expect { subject }.to_not raise_error }
          it { controller.x_darklaunch_features.should be_a_kind_of(Hash) }
        end
      end

      should_not_raise_error_with nil
      should_not_raise_error_with ''
      should_not_raise_error_with 'key='
      should_not_raise_error_with 'key=;'
      should_not_raise_error_with 'key;'
      should_not_raise_error_with 'key;;'
      should_not_raise_error_with ';;'
      should_not_raise_error_with ';key=;'
      should_not_raise_error_with ';key='
    end

  end

  describe "#x_darklaunch_features" do
    subject { controller.x_darklaunch_features }

    when_feature_is 'enabled',  { feature => 1 }   { should be_kind_of(Hash) }
    when_feature_is 'disabled', { feature => 0 }   { should be_kind_of(Hash) }
    when_feature_is 'nil',      { feature => nil } { should be_kind_of(Hash) }
  end

  describe "#x_set_darklaunch_flag" do
    # copy-pasta'ed from other tests
    subject { controller.x_darklaunch_features }
    let(:darklaunch_features) { { feature => nil } }

    context "when the user changes a key" do
      it "should mutate x_darklaunch_features" do
        controller.x_set_darklaunch_flag("new_key", "1")
        (controller.x_darklaunch_features["new_key"]).should eq("1")
      end
    end
  end

end
