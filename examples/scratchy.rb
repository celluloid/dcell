#!/usr/bin/env ruby
require 'dcell'

DCell.start
itchy_node = DCell::Node["itchy"]
itchy = itchy_node[:itchy]

puts "Fighting itchy! (check itchy's output)"

300.times do
  begin
    puts itchy_node[:itchy].fight
    puts itchy.fight
  rescue Celluloid::DeadActorError
    puts "Itchy dying?"
    itchy = itchy_node[:itchy]
  rescue => e
    puts e
    break
  end
  sleep 1
end
