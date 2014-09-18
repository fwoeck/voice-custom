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


    def rails_channel
      Thread.current[:rails_channel] ||= @connection.create_channel
    end

    def rails_xchange
      Thread.current[:rails_xchange] ||= rails_channel.topic('voice.rails', auto_delete: false)
    end

    def rails_publish(payload)
      data = Marshal.dump(payload)
      rails_xchange.publish(data, routing_key: 'voice.rails')
    end


    def shutdown
      @connection.close
    end


    def establish_connection
      @connection = Bunny.new(
        host:     Custom.conf['rabbit_host'],
        user:     Custom.conf['rabbit_user'],
        password: Custom.conf['rabbit_pass']
      ).tap { |c| c.start }
    rescue Bunny::TCPConnectionFailed
      sleep 1
      retry
    end


    def start
      establish_connection

      custom_queue.bind(custom_xchange, routing_key: 'voice.custom')
      custom_queue.subscribe { |delivery_info, metadata, payload|
        Marshal.load(payload).handle_message
      } if ENV['SUBSCRIBE_AMQP']
    end
  end
end
