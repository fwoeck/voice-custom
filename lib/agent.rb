class Agent

  attr_accessor :id, :name, :languages, :skills, :activity, :visibility, :call_id,
                :locked, :availability, :idle_since, :mutex, :unlock_scheduled


  def handle_update
    if (call = Call.find call_id)
      case activity
        when :ringing then call.prefetch_zendesk_tickets
        when :talking then call.create_customer_history_entry(name)
      end
    end
  end
end
