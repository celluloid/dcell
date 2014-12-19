module DCellMock
  @config_lock  = Mutex.new
  include DCell
end
