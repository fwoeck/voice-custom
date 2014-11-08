$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bundler'
Bundler.require

require 'yaml'
require 'custom'

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    ENV['RAILS_ENV'] = 'test'
    Custom.setup
  end
end
