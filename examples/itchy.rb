#!/usr/bin/env ruby
require 'dcell'
require_relative 'registry'

class Itchy
  include Celluloid

  def initialize
    puts "Ready for mayhem!"
    @n = 0
  end

  def fight
    @n += 1
    if @n % 6 == 0
      puts "Bite!"
    else
      puts "Fight!"
    end
    @n
  end
end
Itchy.supervise_as :itchy

DCell.start :id => "itchy", :registry => registry

sleep
