class CallEvent

  include Mongoid::Document

  field :target_call_id, type: String
  field :timestamp,      type: String
  field :headers,        type: Hash

  default_scope -> { asc(:timestamp) }


  class << self

    def handle_update(data)
      puts data
    end
  end
end
