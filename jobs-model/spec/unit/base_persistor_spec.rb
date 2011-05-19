require File.expand_path('../../spec_helper', __FILE__)

describe BasePersistor do
  before do
    @db_url = "http://localhost:5984/base-persistor-spec-" + Time.now.to_i.to_s

  end

  after do
    begin
      # cleanup
      RestClient.delete(@db_url)
    rescue
    end
  end

  it "creates the database if it doesn't already exist" do
    lambda { RestClient.get(@db_url) }.should raise_error RestClient::ResourceNotFound
    BasePersistor.new(@db_url)
    RestClient.get(@db_url)
  end
end
