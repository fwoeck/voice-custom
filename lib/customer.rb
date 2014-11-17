class Customer

  include Mongoid::Document
  include Mongoid::Elasticsearch
  include CustomerCrm


  elasticsearch! index_mappings: {
    'email'      => {type: 'string', analyzer: 'snowball'},
    'full_name'  => {type: 'string', analyzer: 'snowball'},
    'caller_ids' => {type: 'string', analyzer: 'snowball'},
    'crmuser_id' => {type: 'string'}
  }


  field :email,      type: String, default: ""
  field :full_name,  type: String, default: ""
  field :caller_ids, type: Array,  default: -> { [] }
  field :crmuser_id, type: String, default: ""
  field :created_at, type: Time,   default: -> { Time.now.utc }

  embeds_many :history_entries
  index(caller_ids: 1)


  def update_with(par)
    tap { |c|
      c.full_name = (par[:full_name] || "").strip
      c.email     = (par[:email] || "").strip.downcase

      manage_crmuser_account(par[:crmuser_id])
      save
    }
  end


  def update_history_with(par)
    fetch_entry_for(par).tap { |e|
      e.tags    =  par[:tags]
      e.remarks = (par[:remarks] || "").strip
      e.user_id =  par[:user_id] if par[:user_id]
      e.save
    }
  end


  def wipe_old_entries
    history_entries.select { |entry|
      entry.created_at < gracetime(entry.caller_id).days.ago
    }.map(&:destroy)
  end


  private

  def fetch_entry_for(par)
    if (id = par[:entry_id])
      find_by_id_or_newest_entry(id)
    else
      history_entries.build
    end
  end


  def find_by_id_or_newest_entry(id)
    history_entries.find(id) || history_entries.asc(:created_at).last
  end


  def gracetime(caller_id)
    caller_id == Custom.conf['admin_name'] ? 1 : Custom.conf['gracetime']
  end


  class << self

    def search(opts)
      CustomerSearch.search(opts)
    end


    def update_with(par)
      cust = Customer.find(par[:id])
      cust.update_with(par) if cust
    end


    def update_history_with(par)
      cust = Customer.find(par[:customer_id])
      cust.update_history_with(par) if cust
    end


    def wipe_old_history_entries
      # TODO We should scope this to customers with old entries.
      #      This requires an index on history_entries.created_at:
      #
      Customer.where(history_entries: {'$ne' => []}).each { |cust|
        cust.wipe_old_entries
      }
    end
  end
end
