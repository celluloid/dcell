#!/usr/bin/env ruby

pid = nil
turn = true

Signal.trap(:TERM) do
  turn = false
  begin
    Process.kill :TERM, pid if pid
  rescue Errno::ESRCH
  ensure
    Process.wait pid rescue nil if pid
  end
  Process.waitall
  Process.exit 0
end

while turn do
  pid = Process.spawn Gem.ruby, File.expand_path("./spec/test_node.rb")
  unless pid
    STDERR.print "ERROR: Couldn't start test node."
    exit 1
  end
  Process.wait pid rescue nil
end

sleep
