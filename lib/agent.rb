class Agent

  attr_accessor :id, :name, :languages, :skills, :activity, :visibility, :call_id,
                :locked, :availability, :idle_since, :mutex, :unlock_scheduled


  def handle_update
    yield_to_call do |call|
      call.create_customer_history_entry(self)
      puts ":: #{Time.now.utc} Added history entry for #{call.call_id}."
    end
  end


  def yield_to_call(&block)
    if (tcid = call_id)
      if (call = Call.find tcid)
        block.call(call)
        return tcid
      end
    end
  end
end
