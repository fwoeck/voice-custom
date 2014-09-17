class Customer

  include Mongoid::Document
  include Mongoid::Elasticsearch
  extend  CustomerSearch


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


  def manage_crmuser_account(par_crmuser_id)
    if par_crmuser_id == '...' # FIXME This is ugly.
      request_crmuser_id
    elsif crmuser_id.blank? && !par_crmuser_id.blank?
      self.crmuser_id = par_crmuser_id
      fetch_crmuser
    elsif !crmuser_id.blank?
      Thread.new { update_crmuser_record }
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


    def crmuser(user_id)
      Custom.crmclient.users.find(id: user_id)
    end


    def create_crmuser(opts)
      Custom.crmclient.users.create(opts)
    end


    def create_crmuser_ticket(opts)
      Custom.crmclient.tickets.create(opts)
    end
  end


  private

  def fetch_crmuser
    if (user = Customer.crmuser crmuser_id)
      self.full_name = user.name
      self.email     = user.email
    end
  end


  def update_crmuser_record
    user = Customer.crmuser crmuser_id

    if crmuser_needs_update?(user)
      user.name  = full_name
      user.phone = caller_ids.first
      user.email = email
      user.save
    end
  end


  def crmuser_needs_update?(user)
    return unless user
    user.name != full_name || user.email != email ||
      user.phone != caller_ids.first
  end


  def request_crmuser_id
    unless full_name.blank?
      opts         = {name: full_name}
      opts[:email] = email unless email.blank?
      opts[:phone] = caller_ids.first

      user = Customer.create_crmuser(opts)
      self.crmuser_id = user.id.to_s if user
    end
  end
end
