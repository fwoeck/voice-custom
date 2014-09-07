module AmqpManager
  class << self


    def custom_channel
      Thread.current[:custom_channel] ||= @connection.create_channel
    end

    def custom_xchange
      Thread.current[:custom_xchange] ||= custom_channel.topic('voice.custom', auto_delete: false)
    end

    def custom_queue
      Thread.current[:custom_queue] ||= custom_channel.queue('voice.custom', auto_delete: false)
    end


    def shutdown
      @connection.close
    end


    def establish_connection
      @connection = Bunny.new(
        host:     Custom.custom_conf['rabbit_host'],
        user:     Custom.custom_conf['rabbit_user'],
        password: Custom.custom_conf['rabbit_pass']
      ).tap { |c| c.start }
    rescue Bunny::TCPConnectionFailed
      sleep 1
      retry
    end


    def start
      establish_connection

      custom_queue.bind(custom_xchange, routing_key: 'voice.custom')
      custom_queue.subscribe { |delivery_info, metadata, payload|
        CallEvent.log(payload)
      }
    end
  end
end
