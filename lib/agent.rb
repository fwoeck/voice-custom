class Agent

  attr_accessor :id, :name, :languages, :skills, :activity, :visibility, :call_id,
                :locked, :availability, :idle_since, :mutex, :unlock_scheduled


  def handle_update
    if (call = Call.find call_id)
      call.create_customer_history_entry(name)
      puts ":: #{Time.now.utc} Added history entry for #{call.call_id}."
    end
  end
end
