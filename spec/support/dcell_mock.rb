module DCellMock
  @lock  = Mutex.new
  include DCell
end
