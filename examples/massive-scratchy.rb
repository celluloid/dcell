#!/usr/bin/env ruby

require 'dcell'
require_relative 'options'
require_relative 'itchy'
require 'optparse'

local = true
actor = :itchy

OptionParser.new do |opts|
  opts.banner = "Usage: massive-scratchy.rb [options]"

  opts.on("--no-local", "Do not run local celluloid actor tests") do
    local = false
  end
  opts.on("--actor ACTOR", "Actor name to stress") do |a|
    actor = a.to_sym
  end
end.parse!

DCell.start registry: registry
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

def test_future(itchies, repeat)
  futures = Array.new
  barrel = itchies.cycle
  repeat.times do |i|
    itchy = barrel.next
    futures << itchy.future.work(i)
  end
  futures.reduce(0) {|sum, f| sum + f.value}
end

def test_async(itchies, repeat)
  barrel = itchies.cycle
  repeat.times do |i|
    itchy = barrel.next
    itchy.async.work(i)
  end
  itchies.reduce(0) {|sum, itchy| sum + itchy.res}
end

def run_test(itchies, method, info, args=[])
  puts "Running test: #{info}"
  reset itchies
  start = Time.now
  res = send "test_#{method}".to_sym, itchies, *args
  stop = Time.now
  puts "Test result #{res}, count #{count itchies}"
  puts "Test executed within #{stop-start}"
end

Celluloid.logger = nil

itchies = DCell[actor]
max = itchies.count
puts "Found #{itchies.count} instances of #{actor}"
exit if itchies.count == 0
repeat = 1000

run_test itchies, :future, "remote futures", repeat
run_test itchies, :async, "remote async", repeat
itchies.each {|itchy| itchy.terminate}

exit unless local

itchies = max.times.map {Itchy.new}
run_test itchies, :future, "local futures", repeat
run_test itchies, :async, "local async", repeat
itchies.each {|itchy| itchy.terminate}

itchies = Itchy.pool size: max
run_test [itchies], :future, "local futures in pool", repeat
itchies.terminate
