require './lib/call'


class CallEvent

  include Mongoid::Document

  field :target_call_id, type: String
  field :timestamp,      type: String
  field :headers,        type: Hash

  default_scope -> { asc(:timestamp) }


  class << self

    def handle_update(data)
      handle_agent_update(data) || handle_call_update(data)
    end


    def handle_agent_update(data)
      if (agent = get_agent_from data)
        create_history_for(data, agent)
        return true
      end
    end


    def get_agent_from(data)
      if data['name'] == 'AgentEvent'
        data['headers']['Extension']
      end
    end


    def create_history_for(data, agent)
      yield_to_call(data) do |call|
        call.create_customer_history_entry(agent)
      end
    end


    def handle_call_update(data)
      if data['name'] == 'CallState'
        yield_to_call(data) do |call|
          call.create_history_entry_for_mailbox
        end
      end
    end


    def yield_to_call(data, &block)
      if (tcid = data['target_call_id'])
        if (call = Call.find tcid)
          block.call(call)
          return tcid
        end
      end
    end
  end
end
