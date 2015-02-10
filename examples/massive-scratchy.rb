#!/usr/bin/env ruby
require 'dcell'
require_relative 'registry'

DCell.start :registry => registry

itchies = DCell[:itchy].cycle
puts "Making itchy work hard everywhere!"

start = Time.now
futures = Array.new
1000.times do |i|
  itchy = itchies.next
  futures << itchy.future.work(i)
end

res = 0
futures.each do |f|
  res += f.value
end
puts "Test result #{res}"
stop = Time.now
puts "Test executed at #{stop-start}"
