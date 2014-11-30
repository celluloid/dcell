#!/usr/bin/env ruby
require 'dcell'

DCell.start
itchy_node = DCell::Node["itchy"]

puts "Fighting itchy! (check itchy's output)"

300.times do
  puts itchy_node[:itchy].fight
  sleep 1
end
