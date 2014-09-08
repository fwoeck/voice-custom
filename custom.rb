#!/usr/bin/env ruby
# encoding: utf-8

STDOUT.sync = true
STDERR.sync = true
ENV['TZ']   = 'UTC'

require 'bundler'
Bundler.require

require 'yaml'
require 'json'

Thread.abort_on_exception = true
require './lib/custom'
Custom.setup

require './lib/amqp_manager'
AmqpManager.start

require './lib/customer'
require './lib/server'
