require File.expand_path('../../spec_helper', __FILE__)

class TestPersistor < BasePersistor
  set_design_doc <<-EOF
{
  "language":"javascript",
  "views":{
    "all": {
      "map": "function(doc) { emit(doc._id, doc._id); }"
    }
  }
}
EOF

  def self.inflate_object(doc, attachments)
    doc
  end

end

describe BasePersistor do
  before(:each) do
    @db_url = "http://localhost:5984/base-persistor-spec-" + Time.now.to_i.to_s
  end

  describe "when initializing" do
    after(:each) do
      # cleanup the database
      RestClient.delete(@db_url)
    end

    it "creates the database" do
      lambda { RestClient.get(@db_url) }.should raise_error RestClient::ResourceNotFound
      TestPersistor.new(@db_url)
      RestClient.get(@db_url)
    end
  end

  describe "when initialized" do
    before(:each) do
      @persistor = TestPersistor.new(@db_url)
    end

    after(:each) do
      RestClient.delete(@db_url)
    end

    it "save documents" do
      doc_hash = {"foo" => "bar", "baz" => "bat"}
      @persistor.force_save("foo-ID", doc_hash)

      expected = hash_including(doc_hash)

      # why does this only work one way?
      expected.should == JSON.parse(RestClient.get(@db_url + "/foo-ID"))
    end

    context "when populated with data" do
      before(:each) do
        @docs = {
          "id-1" => {:name => "one", :content => "uno"},
          "id-2" => {:name => "two", :content => "dos"},
          "id-3" => {:name => "three", :content => "tres"}
        }
        @docs.each { |id, doc| @persistor.force_save(id, doc)}
      end

      describe "when executing views" do
        it "allows you to specify a single key" do
          res = @persistor.execute_view("all", "id-1")
          res.length.should == 1
        end

        it "allows you to specify multiple keys for bulk views" do
          res = @persistor.execute_view("all", ["id-1", "id-2"])
          res.length.should == 2
        end

        it "allows you to specify no keys" do
          res = @persistor.execute_view("all", nil)
          res.length.should == 3
        end

      end
    end
  end
end
