require 'sinatra/base'

class Server < Sinatra::Base

  configure {
    set :environment, Custom.rails_env
    set :port,        Custom.port
    set :server,      :puma
  }

  get '/' do
    Thread.current.inspect
  end

  run!
end
