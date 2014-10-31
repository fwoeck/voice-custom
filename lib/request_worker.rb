class RequestWorker
  include Celluloid


  def perform_rpc_request(req)
    cmd = cmd_line(req)
    t0  = Time.now

    AmqpManager.rails_publish(execute_command req)
    puts "#{Time.now.utc} :: #{timestamp_for(t0)} :: Perform #{cmd}"
  rescue => e
    AmqpManager.rails_publish(error_for req, e)
    puts "#{Time.now.utc} :: An error happened for #{cmd}: #{e.message}"
  end


  def cmd_line(req)
    "#{req.klass}##{req.verb}(#{req.params.join(', ')})"
  end


  def timestamp_for(t0)
    "#{((Time.now - t0) * 1000).to_i}ms"
  end


  def execute_command(req)
    RemoteRequest.new.tap { |r|
      r.id     = req.id
      r.value  = req.klass.constantize.send(req.verb, *req.params)
      r.res_to = req.req_from
      r.status = 200
    }
  end


  def error_for(req, e)
    RemoteRequest.new.tap { |r|
      r.id     = req.id
      r.error  = e.message
      r.res_to = req.req_from
      r.status = 500
    }
  end


  def self.setup
    # TODO This will suppress warnings at exit, but could also
    #      mask potential problems. Try to remove after a while:
    #
    Celluloid.logger = nil
    Celluloid::Actor[:rpc] = RequestWorker.pool(size: 32)
  end


  def self.shutdown
    Celluloid.shutdown
  end
end
