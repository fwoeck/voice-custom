class RemoteRequest

  attr_accessor :id, :verb, :klass, :params, :req_from, :res_to, :value, :status, :error


  def handle_message
    Celluloid::Actor[:rpc].async.perform_rpc_request(self)
  end
end
