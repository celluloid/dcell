#!/usr/bin/env ruby

require 'optparse'

pids = Array.new
count = 1

OptionParser.new do |opts|
  opts.banner = "Usage: itchy-launcher.rb [options]"

  opts.on("--count COUNT", OptionParser::DecimalInteger, "Number of itchy instances") do |v|
    count = v
  end
end.parse!

Signal.trap(:INT) do
  pids.each do |pid|
    begin
      Process.kill :TERM, pid if pid
    rescue
    end
  end
end

count.times do |id|
  pid = Process.spawn Gem.ruby, File.expand_path("./examples/itchy.rb"), "--id", "itchy-#{Process.pid}-#{id}"
  unless pid
    STDERR.print "ERROR: Couldn't start test node."
  end
  pids << pid
end

Process.waitall
