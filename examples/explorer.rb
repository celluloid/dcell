#!/usr/bin/env ruby

require 'dcell/explorer'
require_relative 'options'

explorer_host = 'localhost'
explorer_port = 7778

DCell.start registry: registry
DCell::Explorer.new explorer_host, explorer_port

puts "Visit explorer page at http://#{explorer_host}:#{explorer_port}"
sleep
