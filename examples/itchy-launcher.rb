#!/usr/bin/env ruby

require 'optparse'

pids = Array.new
count = 1
threaded = false
mass = false

OptionParser.new do |opts|
  opts.banner = "Usage: itchy-launcher.rb [options]"

  opts.on("--count COUNT", OptionParser::DecimalInteger, "Number of itchy instances") do |v|
    count = v
  end
  opts.on("--threaded", "Start itchy with many actors") do
    threaded = true
  end
  opts.on("--mass", "Start many itchies with many actors") do
    mass = true
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

def spawn_itchy(pids, args)
  pid = Process.spawn Gem.ruby, File.expand_path("./examples/itchy.rb"), *args
  unless pid
    STDERR.print "ERROR: Couldn't start test node."
  end
  pids << pid
end

if threaded and not mass
  spawn_itchy pids, ["--count", "#{count}"]
else
  count.times do |id|
    pargs = ["--id", "itchy-#{Process.pid}-#{id}"]
    pargs += ["--count", "#{count}"] if threaded
    spawn_itchy pids, pargs
  end
end

Process.waitall
