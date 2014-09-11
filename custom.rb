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

require './lib/zendesk_ticket'
require './lib/history_entry'
require './lib/amqp_manager'
require './lib/call_event'
require './lib/customer'
require './lib/agent'
require './lib/call'

AmqpManager.start
at_exit do
  AmqpManager.shutdown
  puts ":: #{Time.now.utc} Custom finished.."
end

puts ":: #{Time.now.utc} Custom started.."
sleep
