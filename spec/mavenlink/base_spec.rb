require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Mavenlink::Base do
  describe "request_path and join_paths" do
    class Example < Mavenlink::Base
      request_path "/:something/blah/foo/:id"
    end

    describe "request_path" do
      it "should interpolate id and any path_params into the request_path string" do
        Example.new({ 'id' => 2 }, :path_params => { :something => "hello" }).request_path.should == "/hello/blah/foo/2"
      end
    end

    describe "join_paths" do
      it "should combine paths, respecting leading ..'s" do
        Example.new({}).join_paths("/hello/world", "").should == "/hello/world"
        Example.new({}).join_paths("", "hi").should == "/hi"
        Example.new({}).join_paths("", "/hi").should == "/hi"
        Example.new({}).join_paths("/hello/world", "../there").should == "/hello/there"
        Example.new({}).join_paths("/", "there").should == "/there"
        Example.new({}).join_paths("/hello/world", "/again").should == "/hello/world/again"
        Example.new({}).join_paths("/hello/world/", "/again").should == "/hello/world/again"
        Example.new({}).join_paths("/hello/world/", "again").should == "/hello/world/again"
        Example.new({}).join_paths("/hello/world", "../../../there").should == "/there"
        Example.new({}).join_paths("hi", "there").should == "/hi/there"
      end
    end
  end

  describe "example usage with a test client and some widgets with many prongs" do
    class TestBase < Mavenlink::Base
      base_uri 'http://www.example.com/api/v0'
      debug false
    end

    class TestClient < TestBase
      def initialize(username, password)
        super({}, :basic_auth => { :username => username, :password => password })
      end

      def widgets(options = {})
        fetch('widgets', Widget, options)
      end
    end

    class User < TestBase; end

    class Prong < TestBase
      request_path "/widgets/:widget_id/prongs/:id"
      class_name "prong"
    end

    class Widget < TestBase
      request_path "/widgets/:id"
      contains :owners => User
      class_name "widget"

      def prongs(options = {})
        fetch("prongs", Prong, options, :widget_id => id)
      end

      def prong(prong_id)
        fetch("prongs/#{prong_id}", Prong, {}, :widget_id => id)
      end

      def create_prong(options)
        build("prongs", Prong, options, :widget_id => id)
      end
    end

    before do
      stub_request(:get, "http://user:password@www.example.com/api/v0/widgets?limit=5").
        with(:headers => {'Accept'=>'application/json'}).
        to_return(:status => 200, :body => [{ :kind => "sprocket", :id => 1, :owners => [{ :name => "Bob" }, { :name => "Sam" }] }, { :kind => "gizmo", :id => 2 }].to_json, :headers => {})
    end

    describe "the test client" do
      it "should do basic auth" do
        client = TestClient.new("user", "password")
        client.widgets(:limit => 5)
        WebMock.should have_requested(:get, "http://user:password@www.example.com/api/v0/widgets?limit=5")
      end

      it "should have many widgets" do
        client = TestClient.new("user", "password")
        widgets = client.widgets(:limit => 5)
        widgets.length.should == 2
        widgets.first.kind.should == "sprocket"
        widgets.first.owners.length.should == 2
        widgets.first.owners.first.should be_a(User)
        widgets.first.owners.first.name.should == "Bob"
        widgets.last.owners.should be_nil
      end
    end

    describe "widgets" do
      before do
        @client = TestClient.new("user", "password")
        @widget = @client.widgets(:limit => 5).first
        @widget.should be_a(Widget)
      end

      it "should be reloadable" do
        stub_request(:get, "http://user:password@www.example.com/api/v0/widgets/1?some=option").
          with(:headers => {'Accept'=>'application/json'}).
          to_return(:status => 200, :body => { :kind => "sprocket_updated", :id => 1, :owners => [{ :name => "Bob_updated" }, { :name => "Sam" }] }.to_json, :headers => {})

        @widget.reload(:some => :option)
        @widget.kind.should == "sprocket_updated"
        @widget.owners.first.name.should == "Bob_updated"
      end

      describe "#prongs" do
        before do
          stub_request(:get, "http://user:password@www.example.com/api/v0/widgets/1/prongs?exclude=gears").
            with(:headers => {'Accept'=>'application/json'}).
            to_return(:status => 200, :body => [{ :price => "$5", :id => 100 }, { :price => "$10", :id => 101 }].to_json, :headers => {})

          @prongs = @widget.prongs(:exclude => "gears")
        end

        it "should return prongs" do
          @prongs.length.should == 2
          @prongs.first.should be_a(Prong)
          @prongs.first.price.should == "$5"
          @prongs.first.id.should == 100
          @prongs.first.request_path.should == "/widgets/1/prongs/100"
          @prongs.first.path_params.should == { :widget_id => 1 }
        end

        describe "#update" do
          it "updates the local model when successful" do
            stub_request(:put, "http://user:password@www.example.com/api/v0/widgets/1/prongs/100").
              with(:headers => {'Accept'=>'application/json'}, :body => "prong[price]=%248.50").
              to_return(:status => 200, :body => { :price => "$8.50", :id => 100 }.to_json, :headers => {})

            prong = @prongs.first
            prong.update(:price => "$8.50")
            prong.price.should == "$8.50"
            prong.errors.should be_empty
          end

          it "doesn't update the local model but adds errors when unsuccessful" do
            stub_request(:put, "http://user:password@www.example.com/api/v0/widgets/1/prongs/100").
              with(:headers => {'Accept'=>'application/json'}, :body => "prong[price]=%248.50").
              to_return(:status => 422, :body => { :errors => ["error 1", "error 2"] }.to_json, :headers => {})

            prong = @prongs.first
            prong.update(:price => "$8.50")
            prong.price.should == "$5"
            prong.errors.should == ["error 1", "error 2"]
          end
        end

        describe "#destroy" do
          it "returns true when successful" do
            stub_request(:delete, "http://user:password@www.example.com/api/v0/widgets/1/prongs/100?").
              with(:headers => {'Accept'=>'application/json'}).
              to_return(:status => 200, :body => '', :headers => {})

            prong = @prongs.first
            prong.destroy.should be_true
          end

          it "returns false and sets errors on failure" do
            stub_request(:delete, "http://user:password@www.example.com/api/v0/widgets/1/prongs/100?").
              with(:headers => {'Accept'=>'application/json'}).
              to_return(:status => 422, :body => { :errors => ["error 1", "error 2"] }.to_json, :headers => {})

            prong = @prongs.first
            prong.destroy.should be_false
            prong.errors.should == ["error 1", "error 2"]
          end
        end
      end

      describe "#prong" do
        it "should return a single prong by id" do
          stub_request(:get, "http://user:password@www.example.com/api/v0/widgets/1/prongs/100?").
            with(:headers => {'Accept'=>'application/json'}).
            to_return(:status => 200, :body => { :price => "$5", :id => 100 }.to_json, :headers => {})
          prong = @widget.prong(100)
          prong.should be_a(Prong)
          prong.price.should == "$5"
        end
      end

      describe "#create_prong" do
        it "should return the new prong object when successful" do
          stub_request(:post, "http://user:password@www.example.com/api/v0/widgets/1/prongs").
            with(:headers => {'Accept'=>'application/json'}, :body => "prong[price]=%24100").
            to_return(:status => 200, :body => { :price => "$100", :id => 102 }.to_json, :headers => {})

          prong = @widget.create_prong(:price => "$100")
          prong.request_path.should == "/widgets/1/prongs/102"
          prong.should be_a(Prong)
          prong.price.should == "$100"
          prong.id.should == 102
          prong.errors.should be_empty

          stub_request(:put, "http://user:password@www.example.com/api/v0/widgets/1/prongs/102").
            with(:headers => {'Accept'=>'application/json'}, :body => "prong[price]=%2490").
            to_return(:status => 200, :body => { :price => "$90", :id => 102 }.to_json, :headers => {})
          prong.update(:price => "$90")
          prong.price.should == "$90"
          prong.errors.should be_empty
          prong.request_path.should == "/widgets/1/prongs/102"
        end

        it "should return the new prong object with errors when unsuccessful" do
          stub_request(:post, "http://user:password@www.example.com/api/v0/widgets/1/prongs").
            with(:headers => {'Accept'=>'application/json'}, :body => "prong[price]=%24100").
            to_return(:status => 422, :body => { :errors => ["error 1", "error 2"] }.to_json, :headers => {})

          prong = @widget.create_prong(:price => "$100")
          prong.should be_a(Prong)
          prong.errors.should == ["error 1", "error 2"]
        end
      end
    end
  end
end
