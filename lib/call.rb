class Call

  FORMAT = %w{call_id call_tag language skill extension caller_id hungup called_at mailbox queued_at hungup_at dispatched_at}
           .map(&:to_sym)

  attr_accessor *FORMAT


  def handle_update
    create_history_entry_for_mailbox
    puts ":: #{Time.now.utc} Added mailbox entry for #{call_id}."
  end


  def create_history_entry_for_mailbox
    create_customer_history_entry(nil, mailbox)
  end


  def create_customer_history_entry(agent, mailbox=nil)
    cust = fetch_or_create_customer(caller_id)
    entr = cust.history_entries

    entr.detect { |e|
      e.call_id == call_id
    } || entr.create(
      mailbox:   mailbox,   call_id:   call_id,
      caller_id: caller_id, agent_ext: agent
    )
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
