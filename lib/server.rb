require 'sinatra/base'

class Server < Sinatra::Base

  configure {
    set :environment, Custom.rails_env
    set :port,        Custom.conf['server_port']
    set :server,      :puma
    set :logging,     true
    set :dump_errors, true
  }

  get '/' do
    Thread.current.inspect
  end

  run!
end
