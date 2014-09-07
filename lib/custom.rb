module Custom

  cattr_reader :custom_conf, :rails_env


  def self.read_config
    @@rails_env   = ENV['RAILS_ENV'] || 'development'
    @@custom_conf = YAML.load(File.read(File.join('./config/app.yml')))
  end


  def self.setup_mongodb
    Mongoid.load!('./config/mongoid.yml', rails_env.to_sym)
  end


  def self.setup
    read_config
    setup_mongodb
  end
end
