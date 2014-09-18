class Agent

  attr_accessor :id, :name, :languages, :skills, :activity, :visibility, :call_id,
                :locked, :availability, :idle_since, :mutex, :unlock_scheduled


  def handle_message
    if (call = Call.find call_id)
      case activity
        when :ringing then call.prefetch_crmuser_tickets
        when :talking then call.add_customer_history_entry(id)
      end
    end
  end
end
