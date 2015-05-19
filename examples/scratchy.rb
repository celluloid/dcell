#!/usr/bin/env ruby
require 'dcell'
require_relative 'options'

DCell.start registry: registry

def connect(attempts=10)
  attempts.times do
    itchy_node = DCell::Node["itchy"]
    if itchy_node
      itchy = itchy_node[:itchy]
      return itchy, itchy_node if itchy
    end
    sleep 1
  end
  return nil, nil
end

itchy, itchy_node = connect

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
    puts "Itchy dying? Attempting to reconnect"
    itchy, itchy_node = connect
    unless itchy
      puts "Itchy is dead =/."
      break
    end
  rescue => e
    puts "Unknow error #{e.class} => #{e}"
    break
  end
  sleep 1
end
