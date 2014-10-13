module Custom

  cattr_reader :conf, :redis, :rails_env, :crmclient, :cache


  def self.read_config
    @@rails_env = ENV['RAILS_ENV'] || 'development'
    @@conf      = YAML.load(File.read(File.join('./config/app.yml')))
  end


  def self.setup_cache
    @@cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 5.minutes)
  end


  def self.setup_redis
    @@redis = ConnectionPool.new(size: 5, timeout: 3) {
      Redis.new(host: conf['redis_host'], port: conf['redis_port'], db: conf['redis_db'])
    }
  end


  def self.setup_mongodb
    Mongoid.load!('./config/mongoid.yml', rails_env.to_sym)
    Mongoid.raise_not_found_error = false
  end


  def self.setup_crmclient
    return unless Custom.conf['crm_active']

    @@crmclient = ZendeskAPI::Client.new do |config|
      config.url      = Custom.conf['crm_api_url']
      config.username = Custom.conf['crm_user']
      config.password = Custom.conf['crm_pass']

      config.logger = Logger.new(STDOUT)
      config.logger.level = Logger::WARN
    end
  end


  def self.setup
    read_config
    setup_redis
    setup_cache
    setup_mongodb
    setup_crmclient
  end


  def self.wait_for_elasticsearch
    sleep 1 while `lsof -i :9200 | grep LISTEN | wc -l`.to_i < 1
  end
end
