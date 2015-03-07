#!/usr/bin/env ruby

require 'optparse'

pids = Array.new
count = 1
indexed = false

args = []
scratchy = 'scratchy.rb'

OptionParser.new do |opts|
  opts.banner = "Usage: scratchy-launcher.rb [options]"

  opts.on("--count COUNT", OptionParser::DecimalInteger, "Number of massive-scratchy instances") do |v|
    count = v
  end
  opts.on("--indexed", "Connect to itchy actor with index") do
    indexed = true
  end
  opts.on("--massive", "execute massive scratchy instead of generic") do
    args = ['--no-local']
    scratchy = 'massive-scratchy.rb'
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
  pargs = args
  pargs += ["--actor", "itchy-#{id}"] if indexed
  pid = Process.spawn Gem.ruby, File.expand_path("./examples/#{scratchy}"), *pargs
  unless pid
    STDERR.print "ERROR: Couldn't start test node."
  end
  pids << pid
end

start = Time.now
Process.waitall
stop = Time.now
puts "All scratchies completed within #{stop-start} seconds"
