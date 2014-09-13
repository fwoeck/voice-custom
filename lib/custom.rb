module Custom

  cattr_reader :conf, :redis_db, :rails_env, :zendesk, :cache


  def self.read_config
    @@rails_env = ENV['RAILS_ENV'] || 'development'
    @@conf      = YAML.load(File.read(File.join('./config/app.yml')))
  end


  def self.setup_cache
    @@cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 5.minutes)
  end


  def self.setup_redis
    @@redis_db = ConnectionPool::Wrapper.new(size: 5, timeout: 3) {
      Redis.new(host: conf['redis_host'], port: conf['redis_port'], db: conf['redis_db'])
    }
  end


  def self.setup_mongodb
    Mongoid.load!('./config/mongoid.yml', rails_env.to_sym)
  end


  def self.setup_zendesk
    @@zendesk = ZendeskAPI::Client.new do |config|
      config.url      = "https://#{Custom.conf['zendesk_domain']}.zendesk.com/api/v2"
      config.username =  Custom.conf['zendesk_user']
      config.password =  Custom.conf['zendesk_pass']

      config.logger = Logger.new(STDOUT)
      config.logger.level = Logger::WARN
    end
  end


  def self.setup
    read_config
    setup_redis
    setup_cache
    setup_mongodb
    setup_zendesk
  end
end
