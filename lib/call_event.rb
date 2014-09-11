class CallEvent

  include Mongoid::Document

  field :call_id,   type: String
  field :headers,   type: Hash
  field :timestamp, type: Time

  default_scope -> { asc(:timestamp) }


  class << self

    def handle_update(data)
      if data.is_a?(Call)
        handle_call_update(data)
      else
        handle_agent_update(data)
      end
    end


    def handle_agent_update(data)
      agent = data[:headers][:extension]
      create_history_for(data, agent)
    end


    def create_history_for(data, agent)
      yield_to_call(data) do |call|
        call.create_customer_history_entry(agent)
        puts ":: #{Time.now.utc} Added history entry for #{call.call_id}."
      end
    end


    def handle_call_update(call)
      call.create_history_entry_for_mailbox
      puts ":: #{Time.now.utc} Added mailbox entry for #{call.call_id}."
    end


    def yield_to_call(data, &block)
      if (tcid = data[:call_id])
        if (call = Call.find tcid)
          block.call(call)
          return tcid
        end
      end
    end
  end
end
