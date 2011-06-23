module Mavenlink
  class Base
    base_uri ENV['TESTING'] ? 'https://mavenlink.local/api/v0' : 'https://www.mavenlink.com/api/v0'
    debug ENV['DEBUG'] || false
  end

  # Wrapping objects that have no API endpoints yet

  class User < Base
    request_path "/not_available_yet"
    class_name :user
  end

  class Asset < Base
    request_path "/not_available_yet"
    class_name :asset
  end

  # Normal API objects

  class Client < Base
    def initialize(user_id, token)
      super({}, :basic_auth => {:username => user_id, :password => token})
    end

    def workspaces(options = {})
      fetch('workspaces', Workspace, options)
    end

    def workspace(workspace_id)
      fetch("workspaces/#{workspace_id}", Workspace, {})
    end


    def time_entries(options = {})
      fetch('time_entries', TimeEntry, options, lambda { |time_entry| {:workspace_id => time_entry['workspace_id']} })
    end

    def time_entry(time_entry_id)
      fetch("time_entries/#{time_entry_id}", TimeEntry, {}, lambda { |time_entry| {:workspace_id => time_entry['workspace_id']} })
    end


    def expenses(options = {})
      fetch('expenses', Expense, options, lambda { |expense| {:workspace_id => expense['workspace_id']} })
    end

    def expense(expense_id)
      fetch("expenses/#{expense_id}", Expense, {}, lambda { |expense| {:workspace_id => expense['workspace_id']} })
    end


    def invoices(options = {})
      fetch('invoices', Invoice, options, lambda { |invoice| {:workspace_id => invoice['workspace_id']} })
    end

    def invoice(invoice_id)
      fetch("invoices/#{invoice_id}", Invoice, {}, lambda { |invoice| {:workspace_id => invoice['workspace_id']} })
    end


    def events(options = {})
      fetch('events', Event, options)
    end
  end

  class Workspace < Base
    request_path "/workspaces/:id"
    class_name :workspace

    def posts(options = {})
      fetch('posts', Post, options, :workspace_id => id)
    end

    def post(post_id, options = {})
      fetch("posts/#{post_id}", Post, options, :workspace_id => id)
    end

    def create_post(options)
      build("posts", Post, options, :workspace_id => id)
    end


    def time_entries(options = {})
      fetch("time_entries", TimeEntry, options, :workspace_id => id)
    end

    def time_entry(time_entry_id, options = {})
      fetch("time_entries/#{time_entry_id}", TimeEntry, options, :workspace_id => id)
    end

    def create_time_entry(options)
      build("time_entries", TimeEntry, options, :workspace_id => id)
    end


    def expenses(options = {})
      fetch("expenses", Expense, options, :workspace_id => id)
    end

    def expense(expense_id, options = {})
      fetch("expenses/#{expense_id}", Expense, options, :workspace_id => id)
    end

    def create_expense(options)
      build("expenses", Expense, options, :workspace_id => id)
    end


    def invoices(options = {})
      fetch("invoices", Invoice, options, :workspace_id => id)
    end

    def invoice(invoice_id, options = {})
      fetch("invoice/#{invoice_id}", Invoice, options, :workspace_id => id)
    end


    def stories(options = {})
      fetch("stories", Story, options, :workspace_id => id)
    end

    def story(story_id, options = {})
      fetch("stories/#{story_id}", Story, options, :workspace_id => id)
    end

    def create_story(options)
      build("stories", Story, options, :workspace_id => id)
    end


    def participants(options = {})
      fetch("participants", Participant, options, :workspace_id => id)
    end
  end

  class Participant < Base
    request_path "/workspaces/:workspace_id/participants/:id"
    class_name :participant
  end

  class Post < Base
    request_path "/workspaces/:workspace_id/posts/:id"
    contains :user => User,
             :google_documents => Asset,
             :assets => Asset,
             :replies => lambda {|parent, child| { :class => Post, :path_params => { :workspace_id => child['workspace_id'] } } }
    class_name :post

    def story(options = {})
      fetch("../../stories/#{json['story_id']}", Story, options, :workspace_id => workspace_id) if json['story_id']
    end

    def workspace(options = {})
      fetch("../..", Workspace, options)
    end
  end

  class TimeEntry < Base
    request_path "/workspaces/:workspace_id/time_entries/:id"
    class_name :time_entry

    def story(options = {})
      fetch("../../stories/#{json['story_id']}", Story, options, :workspace_id => workspace_id) if json['story_id']
    end

    def workspace(options = {})
      fetch("../..", Workspace, options)
    end
  end

  class Expense < Base
    request_path "/workspaces/:workspace_id/expenses/:id"
    class_name :expense

    def workspace(options = {})
      fetch("../..", Workspace, options)
    end
  end

  class AdditionalItem < Base
    request_path "/not_available_yet"
    class_name :additional_item
  end

  class Invoice < Base
    request_path "/workspaces/:workspace_id/invoices/:id"
    class_name :invoice
    contains :time_entries => lambda { |time_entry, json| { :class => TimeEntry, :path_params => { :id => json['id'], :workspace_id => json['workspace_id'] } } },
             :expenses => lambda { |expense, json| { :class => Expense, :path_params => { :id => json['id'], :workspace_id => json['workspace_id'] } } },
             :additional_items => AdditionalItem

    def workspace(options = {})
      fetch("../..", Workspace, options)
    end
  end

  class Story < Base
    request_path "/workspaces/:workspace_id/stories/:id"
    contains :creator => User, :assignee => User
    class_name :story

    def workspace(options = {})
      fetch("../..", Workspace, options)
    end
  end

  class Event < Base
    request_path "/events/:id"
    contains :subject => lambda { |event, json|
      case event.subject_type
        when "Post"
          { :class => Post, :path_params => { :workspace_id => json['workspace_id'] } }
        when "Story"
          { :class => Story, :path_params => { :workspace_id => json['workspace_id'] } }
        else
          raise "Unknown event subject type: #{event.subject_type}"
      end
    }
    class_name :event
  end
end
