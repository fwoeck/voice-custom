#!/usr/bin/env ruby
# encoding: utf-8

STDOUT.sync = true
STDERR.sync = true
ENV['TZ']   = 'UTC'

require 'bundler'
Bundler.require

require 'yaml'
require 'json'
require 'base64'
require 'logger'


Thread.abort_on_exception = false
require './lib/custom'
Custom.setup
Custom.wait_for_elasticsearch

require './lib/customer_search'
require './lib/request_worker'
require './lib/remote_request'
require './lib/history_entry'
require './lib/customer_crm'
require './lib/amqp_manager'
require './lib/crm_ticket'
require './lib/scheduler'
require './lib/customer'
require './lib/agent'
require './lib/call'


RequestWorker.setup
AmqpManager.start
Scheduler.start

at_exit do
  AmqpManager.shutdown
  RequestWorker.shutdown
  puts "#{Time.now.utc} :: Custom finished.."
end


puts "#{Time.now.utc} :: Custom started.."
if ENV['SUBSCRIBE_AMQP']
  sleep
else
  require 'hirb'
  Hirb.enable
end
