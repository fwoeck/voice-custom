module CustomerCrm

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


  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

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
