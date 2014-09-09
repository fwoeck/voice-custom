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
      data = payload.to_json
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


    def perform_action_on(data)
      val = data['class'].constantize.send(data['verb'], *data['params'])
      enc = Base64.encode64 Marshal.dump(val)
      {res_to: data['req_from'], id: data['id'], value: enc}
    end


    def handle_request(data)
      AmqpManager.rails_publish(perform_action_on data)
      puts "#{Time.now.utc} Performed request: #{data['class']}##{data['verb']}."
    end


    def start
      establish_connection

      custom_queue.bind(custom_xchange, routing_key: 'voice.custom')
      custom_queue.subscribe { |delivery_info, metadata, payload|
        data = JSON.parse(payload)

        if data['req_from']
          handle_request data
        else
          CallEvent.handle_update data
        end
      }
    end
  end
end
