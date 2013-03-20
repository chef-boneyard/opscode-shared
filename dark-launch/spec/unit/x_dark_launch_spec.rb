$:.unshift(File.expand_path('../../../lib', __FILE__))
require 'opscode/x_dark_launch'

describe Opscode::XDarkLaunch do
  class FakeDarklaunchController
    include Opscode::XDarkLaunch
  end

  let(:controller)          { FakeDarklaunchController.new.tap { |c| c.stub!(:raw_headers).and_return(headers) } }
  let(:headers)             { { Opscode::X_DARKLAUNCH_HEADER => encoded_features } }
  let(:encoded_features)    { JSON.generate(darklaunch_features) }
  let(:darklaunch_features) { fail "Define let(:darklaunch_features)" }

  describe "#x_darklaunch_enabled?" do
    subject { controller.x_darklaunch_enabled? feature }
    let(:feature) { 'private-chef' }

    context "with feature enabled" do
      let(:darklaunch_features) { { feature => true } }
      it { should be_true }
    end

    context "with feature disabled" do
      let(:darklaunch_features) { { feature => false } }
      it { should_not be_true }
    end

    context "when feature is nil" do
      let(:darklaunch_features) { { feature => nil } }
      it { should_not be_true }
    end

    context "when feature is missing" do
      let(:darklaunch_features) { { } }
      it { should_not be_true }
    end
  end

end
