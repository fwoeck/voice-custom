class AmqpManager
  include Celluloid

  USE_JRB = RUBY_PLATFORM =~ /java/
  TOPICS  = [:rails, :custom]


  TOPICS.each { |name|
    class_eval %Q"
      def #{name}_channel
        @#{name}_channel ||= connection.create_channel
      end
    "

    class_eval %Q"
      def #{name}_xchange
        @#{name}_xchange ||= #{name}_channel.topic('voice.#{name}', auto_delete: false)
      end
    "

    class_eval %Q"
      def #{name}_queue
        @#{name}_queue ||= #{name}_channel.queue('voice.#{name}', auto_delete: false)
      end
    "
  }


  def rails_publish(payload)
    data = Marshal.dump(payload)
    rails_xchange.publish(data, routing_key: 'voice.rails')
  end


  def connection
    establish_connection unless @@connection
    @@connection
  end


  def shutdown
    connection.close
  end


  def establish_connection
    USE_JRB ? establish_marchhare_connection : establish_bunny_connection
  end


  def establish_marchhare_connection
    @@connection = MarchHare.connect(amqp_config)
  rescue MarchHare::ConnectionRefused
    sleep 1
    retry
  end


  def establish_bunny_connection
    @@connection = Bunny.new(amqp_config).tap { |c| c.start }
  rescue Bunny::TCPConnectionFailed
    sleep 1
    retry
  end


  def amqp_config
    { host:     Custom.conf['rabbit_host'],
      user:     Custom.conf['rabbit_user'],
      password: Custom.conf['rabbit_pass']
    }
  end


  def start
    establish_connection

    custom_queue.bind(custom_xchange, routing_key: 'voice.custom')
    custom_queue.subscribe(blocking: false) { |*args|
      Marshal.load(USE_JRB ? args[0] : args[2]).handle_message
    } if ENV['SUBSCRIBE_AMQP']
  end


  class << self

    def start
      Celluloid.logger.level = 3
      Celluloid::Actor[:amqp] = AmqpManager.pool(size: 32)
      @@manager ||= new.tap { |m| m.start }
    end


    def shutdown
      @@manager.shutdown
    end


    def rails_publish(*args)
      Celluloid::Actor[:amqp].async.rails_publish(*args)
    end
  end
end
