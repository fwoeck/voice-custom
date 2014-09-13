class Customer

  include Mongoid::Document

  field :email,      type: String,   default: ""
  field :full_name,  type: String,   default: ""
  field :caller_ids, type: Array,    default: -> { [] }
  field :zendesk_id, type: String,   default: ""
  field :created_at, type: DateTime, default: -> { Time.now.utc }

  embeds_many :history_entries
  index(caller_ids: 1)


  def update_with(par)
    tap { |c|
      c.full_name = (par[:full_name] || "").strip
      c.email     = (par[:email] || "").strip.downcase

      c.manage_zendesk_account(par[:zendesk_id])
      c.save
    }
  end


  def update_history_with(par)
    if (entry = history_entries.find par[:entry_id])
      entry.remarks = (par[:remarks] || "").strip
      entry.save
    end
  end


  def manage_zendesk_account(par_zendesk_id)
    if par_zendesk_id == '...' # FIXME This is ugly.
      request_zendesk_id
    elsif zendesk_id.blank? && !par_zendesk_id.blank?
      self.zendesk_id = par_zendesk_id
      fetch_zendesk_user
    elsif !zendesk_id.blank?
      update_zendesk_record
    end
  end


  def self.update_with(par)
    cust = Customer.find(par[:id])
    cust.update_with(par) if cust
  end


  def self.update_history_with(par)
    cust = Customer.find(par[:customer_id])
    cust.update_history_with(par) if cust
  end


  def self.zendesk_user(uid)
    Custom.zendesk.users.find(id: uid)
  end


  def self.create_zendesk_user(opts)
    Custom.zendesk.users.create(opts)
  end


  def self.create_zendesk_ticket(opts)
    Custom.zendesk.tickets.create(opts)
  end


  private

  def fetch_zendesk_user
    if (user = Customer.zendesk_user zendesk_id)
      self.full_name = user.name
      self.email     = user.email
    end
  end


  def update_zendesk_record
    user = Customer.zendesk_user zendesk_id

    if zendesk_needs_update?(user)
      user.name  = full_name
      user.phone = caller_ids.first
      user.email = email
      user.save
    end
  end


  def zendesk_needs_update?(user)
    return unless user
    user.name != full_name || user.email != email ||
      user.phone != caller_ids.first
  end


  def request_zendesk_id
    unless full_name.blank?
      opts         = {name: full_name}
      opts[:email] = email unless email.blank?
      opts[:phone] = caller_ids.first

      user = Customer.create_zendesk_user(opts)
      self.zendesk_id = user.id.to_s if user
    end
  end
end
