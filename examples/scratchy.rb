#!/usr/bin/env ruby
require 'dcell'

DCell.start
itchy_node = DCell::Node["itchy"]
itchy = itchy_node[:itchy]

puts "All itchy actors: #{itchy_node.all}"
puts "Fighting itchy! (check itchy's output)"

300.times do
  begin
    itchy.async.fight
    future = itchy.future.fight
    puts itchy_node[:itchy].fight
    puts itchy.fight
    puts future.value
  rescue Celluloid::DeadActorError
    puts "Itchy dying?"
    itchy = itchy_node[:itchy]
  rescue => e
    puts "Unknow error #{e}"
    break
  end
  sleep 1
end
