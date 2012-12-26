#!/usr/bin/env ruby
require 'dcell'

DCell.start :id => "itchy", :addr => "tcp://127.0.0.1:9001"

class Itchy
  include Celluloid

  def initialize
    puts "Ready for mayhem!"
    @n = 0
  end

  def fight
    @n = (@n % 6) + 1
    if @n <= 3
      puts "Bite!"
    else
      puts "Fight!"
    end
  end
end

Itchy.supervise_as :itchy
sleep
