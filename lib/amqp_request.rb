class AmqpRequest

  attr_accessor :id, :verb, :klass, :params, :req_from, :res_to, :value


  def handle_update
    res = AmqpRequest.new.tap { |r|
      r.id     = id
      r.value  = klass.constantize.send(verb, *params)
      r.res_to = req_from
    }

    AmqpManager.rails_publish(res)
    puts ":: #{Time.now.utc} Performed request: #{klass}##{verb}(#{params.join(',')})."
  end
end
