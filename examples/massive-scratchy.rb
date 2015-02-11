#!/usr/bin/env ruby
require 'dcell'
require_relative 'registry'

DCell.start :registry => registry
puts "Making itchy work hard everywhere!"

def reset(itchies)
  itchies.each do |itchy|
    itchy.res = 0
    itchy.n = 0
  end
end

def count(itchies)
  itchies.reduce(0) {|sum, itchy| sum + itchy.n}
end

def test_future(itchies)
  futures = Array.new
  barrel = itchies.cycle
  1000.times do |i|
    itchy = barrel.next
    futures << itchy.future.work(i)
  end
  futures.reduce(0) {|sum, f| sum + f.value}
end

def test_async(itchies)
  barrel = itchies.cycle
  1000.times do |i|
    itchy = barrel.next
    itchy.async.work(i)
  end
  itchies.reduce(0) {|sum, itchy| sum + itchy.res}
end

def run_test(itchies, name, args=[])
  puts "Running test: #{name}"
  reset itchies
  start = Time.now
  res = send "test_#{name}".to_sym, itchies, *args
  stop = Time.now
  puts "Test result #{res}, count #{count itchies}"
  puts "Test executed within #{stop-start}"
end

itchies = DCell[:itchy]

run_test itchies, "future"
run_test itchies, "async"
