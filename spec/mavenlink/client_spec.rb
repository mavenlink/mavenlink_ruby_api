require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Mavenlink::Client do
  before do
    @client = Mavenlink::Client.new("user_id", "token")
  end

  describe "time entries" do
    before do
      @time_entries_json = <<-JSON
        [
          {
            "workspace_id":1601,
            "story_id":1581,
            "creator_id":2,
            "currency":"USD",
            "created_at":"2010/08/02 09:39:01 -0700",
            "date_performed":"2010/08/02",
            "billable":false,
            "notes":"",
            "time_in_minutes":120,
            "rate_in_cents":0,
            "id":35
          },
          {
            "workspace_id":11746,
            "story_id":null,
            "creator_id":2,
            "currency":"GBP",
            "created_at":"2010/11/15 12:16:10 -0800",
            "date_performed":"2010/11/15",
            "billable":true,
            "notes":"",
            "time_in_minutes":60,
            "rate_in_cents":2000,
            "id":2060
          }
        ]
      JSON


      @story_json = <<-JSON
        {
          "workspace_id":1601,
          "state":  "not started",
          "description":  "",
          "story_type":  "task",
          "created_at":  "2001/03/11 15:01:04 -0800",
          "archived":false,
          "assignee":
            {
              "full_name":  "Some User",
              "id": 4000
            },
          "due_date":null,
          "position":1,
          "id":1581,
          "title":  "Some Story",
          "creator":
            {
              "full_name":  "Some Other User",
              "id": 4001
            }
        }
      JSON

      stub_request(:get, "https://user_id:token@mavenlink.local/api/v0/time_entries?per_page=5").
          with(:headers => {'Accept'=>'application/json'}).
          to_return(:status => 200, :body => @time_entries_json, :headers => {})

      stub_request(:get, "https://user_id:token@mavenlink.local/api/v0/workspaces/1601/stories/1581?").
          with(:headers => {'Accept'=>'application/json'}).
          to_return(:status => 200, :body => @story_json, :headers => {})

      @time_entries = @client.time_entries(:per_page => 5)
    end

    it "should do basic auth" do
      WebMock.should have_requested(:get, "https://user_id:token@mavenlink.local/api/v0/time_entries?per_page=5")
    end

    it "should have many time_entries" do
      @time_entries.length.should == 2
      @time_entries.first.should be_a(Mavenlink::TimeEntry)
      @time_entries.first.request_path.should == "/workspaces/1601/time_entries/35"
    end

    describe "the story on a time entry" do
      it "is a working story object" do
        story = @time_entries.first.story
        story.should be_a(Mavenlink::Story)
        story.title.should == "Some Story"
        story.request_path.should == "/workspaces/1601/stories/1581"
      end

      it "has a nested creator and assignee" do
        story = @time_entries.first.story
        story.creator.should be_a(Mavenlink::User)
        story.creator.full_name.should == "Some Other User"
        story.assignee.should be_a(Mavenlink::User)
        story.assignee.full_name.should == "Some User"
      end
    end
  end

  describe "events" do
    before do
      @story_json = <<-JSON
        {
          "title":"Story Title",
          "creator":{
            "id":354,
            "full_name":"Some Other User"
          },
          "archived":false,
          "id":7890,
          "story_type":"deliverable",
          "assignee":null,
          "due_date":"2011/03/31",
          "description":"",
          "workspace_id":5678,
          "state":"completed"
        }
      JSON

      @events_json = <<-JSON
        [
          {
            "subject_type":"Post",
            "event_type":"PostCreatedEvent",
            "subject": {
              "id":2345,
              "story_id":null,
              "reply_count":0,
              "workspace_id":1234,
              "message":"Some message",
              "user":{
                "id":14,
                "full_name":"Some User"
              }
            }
          },
          {
            "subject_type":"Story",
            "event_type":"StoryCreatedEvent",
            "subject": #{@story_json}
          }
        ]
      JSON

      stub_request(:get, "https://user_id:token@mavenlink.local/api/v0/events?per_page=5").
          with(:headers => {'Accept'=>'application/json'}).
          to_return(:status => 200, :body => @events_json, :headers => {})

      @events = @client.events(:per_page => 5)
    end

    it "should have many events with contained posts or stories" do
      @events.length.should == 2
      @events.first.should be_a(Mavenlink::Event)
      @events.last.should be_a(Mavenlink::Event)
      @events.first.subject_type.should == "Post"
      @events.last.subject_type.should == "Story"
      @events.first.subject.should be_a(Mavenlink::Post)
      @events.last.subject.should be_a(Mavenlink::Story)
      @events.first.subject.request_path.should == "/workspaces/1234/posts/2345"
      @events.last.subject.request_path.should == "/workspaces/5678/stories/7890"
      @events.first.subject.message.should == "Some message"
      @events.last.subject.title.should == "Story Title"
      @events.first.subject.user.full_name.should == "Some User"
      @events.last.subject.creator.full_name.should == "Some Other User"

      stub_request(:put, "https://user_id:token@mavenlink.local/api/v0/workspaces/5678/stories/7890").
          with(:body    => "story[title]=Some%20new%20title",
               :headers => {'Accept'=>'application/json'}).
          to_return(:status => 200, :body => @story_json.gsub(/Story Title/, 'Some new title'), :headers => {})

      subject = @events.last.subject
      subject.update(:title => "Some new title")
      subject.title.should == "Some new title"
    end
  end
end
