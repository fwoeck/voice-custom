class RequestWorker
  include Celluloid


  def perform_rpc_request(req)
    res = AmqpRequest.new.tap { |r|
      r.id     = req.id
      r.value  = req.klass.constantize.send(req.verb, *req.params)
      r.res_to = req.req_from
    }

    AmqpManager.rails_publish(res)
    puts ":: #{Time.now.utc} Performed #{req.klass}##{req.verb}(#{req.params.join(',')})"
  end


  def self.setup
    # TODO This will suppress warnings at exit, but could also
    #      mask potential problems. Try to remove after a while:
    #
    Celluloid.logger = nil
    Celluloid::Actor[:rpc] = RequestWorker.pool
  end


  def self.shutdown
    Celluloid.shutdown
  end
end
