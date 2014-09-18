class Customer

  include Mongoid::Document
  include Mongoid::Elasticsearch

  extend  CustomerSearch
  include CustomerCrm


  elasticsearch! index_mappings: {
    'email'      => {type: 'string', analyzer: 'snowball'},
    'full_name'  => {type: 'string', analyzer: 'snowball'},
    'caller_ids' => {type: 'string', analyzer: 'snowball'},
    'crmuser_id' => {type: 'string'}
  }


  field :email,      type: String,   default: ""
  field :full_name,  type: String,   default: ""
  field :caller_ids, type: Array,    default: -> { [] }
  field :crmuser_id, type: String,   default: ""
  field :created_at, type: DateTime, default: -> { Time.now.utc }

  embeds_many :history_entries
  index(caller_ids: 1)


  def update_with(par)
    tap { |c|
      c.full_name = (par[:full_name] || "").strip
      c.email     = (par[:email] || "").strip.downcase

      c.manage_crmuser_account(par[:crmuser_id])
      c.save
    }
  end


  def update_history_with(par)
    if (entry = history_entries.find par[:entry_id])
      entry.tags    =  par[:tags]
      entry.remarks = (par[:remarks] || "").strip
      entry.save
    end
  end


  class << self

    def update_with(par)
      cust = Customer.find(par[:id])
      cust.update_with(par) if cust
    end


    def update_history_with(par)
      cust = Customer.find(par[:customer_id])
      cust.update_history_with(par) if cust
    end
  end
end
