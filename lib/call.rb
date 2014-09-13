class Call

  FORMAT = %w{call_id call_tag language skill extension caller_id hungup called_at mailbox queued_at hungup_at dispatched_at}
           .map(&:to_sym)

  attr_accessor *FORMAT


  def handle_update
    add_customer_history_entry(nil, mailbox)
    puts ":: #{Time.now.utc} Add mailbox entry for #{call_id}."
  end


  def prefetch_zendesk_tickets
    cust = fetch_or_create_customer(caller_id)

    if (zid = cust.zendesk_id)
      ZendeskTicket.fetch(zid)
      puts ":: #{Time.now.utc} Prefetch Zendesk tickets for #{zid}."
    end
  end


  def add_customer_history_entry(extension, mailbox=nil)
    cust = fetch_or_create_customer(caller_id)
    entr = cust.history_entries

    create_entry(entr, extension, mailbox) unless call_has_entry?(entr)
  end


  def call_has_entry?(entr)
    entr.detect { |e| e.call_id == call_id }
  end


  def create_entry(entr, extension, mailbox)
    entr.create(
      mailbox:   mailbox,   call_id:   call_id,
      caller_id: caller_id, extension: extension
    )
    puts ":: #{Time.now.utc} Add history entry for #{caller_id}."
  end


  def fetch_or_create_customer(caller_id)
    Customer.where(caller_ids: caller_id).last ||
      Customer.create(caller_ids: [caller_id])
  end


  def self.call_keyname(id)
    "#{Custom.rails_env}.call.#{id}"
  end


  def self.find(tcid)
    return unless tcid
    call = Custom.redis_db.get(call_keyname tcid)
    Marshal.load(call) if call
  end
end
